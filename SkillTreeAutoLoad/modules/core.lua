local NS = SkillTreeAutoLoad
local L = NS.L

local Core = {}
NS.Core = Core

local nodeDefsById
local nodeButtons = {}
local warnedMultiChoice = false
local buttonsReady = false
local snapshotCache, snapshotTime

local function GetNodeDefs()
    if nodeDefsById then return nodeDefsById end
    if not (TalentDatabase and TalentDatabase[0] and TalentDatabase[0].nodes) then
        return nil
    end
    nodeDefsById = {}
    for _, node in ipairs(TalentDatabase[0].nodes) do
        nodeDefsById[node.id] = node
    end
    return nodeDefsById
end

-- Le pont a besoin de savoir ce que l'arbre connait pour ne pas reinjecter dans
-- la trame sortante des noeuds qui n'existent plus. Rend nil tant que la base
-- n'est pas chargee : « je ne sais pas » ne doit pas se lire « il n'existe pas ».
function Core.GetNodeDefs()
    return GetNodeDefs()
end

local function GetNodeButton(nodeId)
    local btn = nodeButtons[nodeId]
    if btn then return btn end
    btn = _G["skillTreeNode" .. nodeId]
    if btn then nodeButtons[nodeId] = btn end
    return btn
end

-- Les boutons ne naissent qu'au premier affichage de l'arbre, dans InitTree.
-- Sans ce controle, « pas encore construit » se lit « rien d'appris » : une
-- capture ecraserait une save par du vide, et le ReloadUI qui suit graverait ce
-- vide sur le disque. Une fois vrai, toujours vrai : PE ne detruit pas ses noeuds.
local function TreeButtonsReady(defs)
    if buttonsReady then return true end
    for nodeId in pairs(defs) do
        if GetNodeButton(nodeId) then
            buttonsReady = true
            return true
        end
    end
    return false
end

local function WarnMultiChoice()
    if warnedMultiChoice then return end
    warnedMultiChoice = true
    NS.LogWarn(L.MSG_MULTICHOICE)
end

local function ReadNodeRank(node)
    if node.isMultipleChoice then
        WarnMultiChoice()
        return 0
    end

    local btn = GetNodeButton(node.id)
    if not btn or btn.state == "locked" then return 0 end

    local text = btn.rankText and btn.rankText:GetText()
    local current = text and tonumber(text:match("^(%d+)/%d+$"))
    if current then return current end

    return (btn.state == "active") and #(node.spells or {}) or 0
end

function Core.InvalidateSnapshot()
    snapshotCache = nil
end

function Core.GetTreeSnapshot()
    if snapshotCache and (GetTime() - snapshotTime) < NS.SNAPSHOT_TTL then
        return snapshotCache
    end

    local defs = GetNodeDefs()
    if not defs then return nil, L.ERR_NO_DATABASE end
    if not _G.skillTreeFrame then return nil, L.ERR_TREE_NOT_READY end
    if not TreeButtonsReady(defs) then return nil, L.ERR_TREE_NOT_READY end

    local snapshot = {}
    for nodeId, node in pairs(defs) do
        local rank = ReadNodeRank(node)
        if rank > 0 then snapshot[nodeId] = rank end
    end

    snapshotCache, snapshotTime = snapshot, GetTime()
    return snapshot
end

function Core.CaptureTreeState()
    Core.InvalidateSnapshot()
    local snapshot, err = Core.GetTreeSnapshot()
    if not snapshot then return nil, err end

    local copy = {}
    for nodeId, rank in pairs(snapshot) do copy[nodeId] = rank end
    return copy
end

function Core.GetAvailableSoulAshes()
    local frame = _G.skillTreeFrame
    local fs = frame and frame.pointsText
    if not fs then return nil end

    local text = fs:GetText()
    if type(text) ~= "string" or text == "" then return nil end

    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

    -- Le signe fait partie du nombre. ProjectEbonhold affiche un solde negatif
    -- des qu'une depense passe au-dela de la reserve, et le perdre ici, c'est
    -- croire le joueur riche de ce qu'il doit : le bouton s'allume, le plan
    -- depense un budget qui n'existe pas, le serveur refuse la validation.
    local sign, numberPart = text:match("(%-?)([%d][%d%s,%.]*)%s*$")
    if not numberPart then return nil end

    local digits = numberPart:gsub("%D", "")
    if digits == "" then return nil end

    local value = tonumber(digits)
    if not value then return nil end

    return (sign == "-") and -value or value
end

function Core.ComputeActivationPlan(saveNodeRanks, snapshot)
    local defs = GetNodeDefs()
    if not defs then return nil end

    snapshot = snapshot or Core.GetTreeSnapshot()
    if not snapshot then return nil end

    local totalCost = 0
    local actions = {}

    for nodeId, targetRank in pairs(saveNodeRanks or {}) do
        local node = defs[nodeId]
        if node then
            local currentRank = snapshot[nodeId] or 0
            if currentRank < targetRank then
                local costs = node.soulPointsCosts or {}
                local nodeCost = 0
                for rankIdx = currentRank + 1, targetRank do
                    nodeCost = nodeCost + (costs[rankIdx] or 0)
                end
                totalCost = totalCost + nodeCost
                actions[#actions + 1] = {
                    nodeId = nodeId,
                    toRank = targetRank,
                    cost = nodeCost,
                }
            end
        end
    end

    table.sort(actions, function(a, b) return a.nodeId < b.nodeId end)
    return totalCost, actions
end

-- La reserve ne se memorise pas : on la recalcule depuis la base annoncee par le
-- serveur, moins le cout de ce qui est a l'ecran en plus. Un clic manuel modifie
-- l'arbre, donc modifie le resultat, sans que l'addon ait a le surveiller.
function Core.GetEffectiveSpendable()
    local spendable = NS.Bridge.GetServerBalance()
    if not spendable then return nil, L.ERR_READ_BALANCE end

    -- « Pas encore recu » et « rien d'engage » ne se ressemblent que pour qui ne
    -- paie pas la difference : prendre le premier pour le second fait compter
    -- l'arbre entier comme une depense en attente, et ecrit dans PE un solde
    -- negatif qui bloque alors tous les clics du joueur.
    local committedNodes = NS.Bridge.GetServerNodes()
    if not committedNodes then return nil, L.ERR_NO_SERVER_NODES end

    local snapshot = Core.GetTreeSnapshot()
    if not snapshot then return nil, L.ERR_READ_TREE end

    local pendingCost = Core.ComputeActivationPlan(snapshot, committedNodes)
    if not pendingCost then return nil, L.ERR_READ_TREE end

    -- Le plan ne voit que les ajouts. Un retrait non valide a pourtant ete
    -- rembourse par PE, et ce credit disparait quand on repose la reserve : on
    -- le dit plutot que de laisser le joueur le deviner.
    for nodeId, committedRank in pairs(committedNodes) do
        if (snapshot[nodeId] or 0) < committedRank then
            NS.LogWarn(L.MSG_PENDING_REMOVAL)
            break
        end
    end

    local effective = spendable - pendingCost
    if effective < 0 then
        NS.LogWarn(string.format(L.MSG_NEGATIVE_BALANCE,
            NS.FormatCost(spendable), NS.FormatCost(pendingCost)))
        effective = 0
    end

    return effective
end

local function EncodeBuildCode(nodeRanks)
    if not (utils and utils.EncodeVarInt and utils.Base64Encode) then return nil end

    local list = {}
    for nodeId, rank in pairs(nodeRanks or {}) do
        if rank > 0 then list[#list + 1] = { id = nodeId, rank = rank } end
    end
    if #list == 0 then return nil end
    table.sort(list, function(a, b) return a.id < b.id end)

    local buffer = {}

    local function appendVarInt(value)
        local bytes = utils.EncodeVarInt(value)
        for i = 1, #bytes do buffer[#buffer + 1] = bytes[i] end
    end

    appendVarInt(#list)
    for i = 1, #list do
        appendVarInt(list[i].id)
        buffer[#buffer + 1] = list[i].rank
    end

    return utils.Base64Encode(buffer)
end

-- ApplyImportedLoadout compare la SOMME DES RANGS du build a la reserve restante
-- — un nombre de rangs face a des cendres. Comme on renvoie toujours le build
-- entier, un joueur presque a sec voit son import refuse par PE, et ce refus
-- nous revient deguise en « l'arbre ne correspond pas ». On compte pareil, avant.
local function CountKnownRanks(defs, nodeRanks)
    local total = 0
    for nodeId, rank in pairs(nodeRanks or {}) do
        if defs[nodeId] then total = total + rank end
    end
    return total
end

local function RunNativeImport(code)
    local button = _G.skillTreeImportButton
    local onClick = button and button:GetScript("OnClick")
    if not onClick then return false, L.ERR_NO_IMPORT_BUTTON end

    -- On appelle du code qui n'est pas le notre. S'il leve, l'erreur ne doit pas
    -- emporter ApplyBuild au passage : la reserve ne serait jamais reposee, PE
    -- garderait un solde perime trop haut, et le joueur depenserait dans le vide.
    local ok, err = pcall(onClick, button)
    if not ok then return false, tostring(err) end

    if StaticPopup_FindVisible then
        local dialog = StaticPopup_FindVisible("SKILLTREE_IMPORT_CODE")
        if dialog then dialog:Hide() end
    end

    local popup = StaticPopupDialogs["SKILLTREE_IMPORT_CODE"]
    if not (popup and popup.OnAccept) then return false, L.ERR_NO_IMPORT_POPUP end

    ok, err = pcall(popup.OnAccept, { editBox = { GetText = function() return code end } })
    if not ok then return false, tostring(err) end

    return true
end

local function MergeInto(target, source)
    for nodeId, rank in pairs(source or {}) do
        if rank > 0 and (not target[nodeId] or rank > target[nodeId]) then
            target[nodeId] = rank
        end
    end
    return target
end

function Core.ApplyBuild(saveNodeRanks)
    local setSoulAshes = ProjectEbonhold and ProjectEbonhold.SkillTree
        and ProjectEbonhold.SkillTree.UpdateTotalSoulPoints
    if not setSoulAshes then return nil, L.ERR_NO_SETTER end

    local defs = GetNodeDefs()
    if not defs then return nil, L.ERR_NO_DATABASE end

    Core.InvalidateSnapshot()

    local before = Core.GetTreeSnapshot()
    if not before then return nil, L.ERR_READ_TREE end

    local cost = Core.ComputeActivationPlan(saveNodeRanks, before)
    if not cost then return nil, L.ERR_READ_TREE end

    local _, serverCommitted = NS.Bridge.GetServerBalance()
    if not serverCommitted then return nil, L.ERR_READ_BALANCE end

    -- L'import de PE remet l'arbre a zero avant de le reconstruire : sans la
    -- liste des noeuds engages cote serveur, la regle « jamais de retrait » perd
    -- son filet, et un noeud permanent pourrait disparaitre de la trame.
    local committedNodes = NS.Bridge.GetServerNodes()
    if not committedNodes then return nil, L.ERR_NO_SERVER_NODES end

    local target = {}
    MergeInto(target, committedNodes)
    MergeInto(target, before)
    MergeInto(target, saveNodeRanks)

    local available = Core.GetAvailableSoulAshes()
    local rankTotal = CountKnownRanks(defs, target)
    if available and rankTotal > available then
        return nil, string.format(L.ERR_IMPORT_REFUSED, rankTotal, NS.FormatCost(available))
    end

    local code = EncodeBuildCode(target)
    if not code then return nil, L.ERR_ENCODE end

    local ok, err = RunNativeImport(code)
    if not ok then return nil, err end

    Core.InvalidateSnapshot()
    local after = Core.GetTreeSnapshot()
    if not after then return nil, L.ERR_REREAD_TREE end

    local _, remaining = Core.ComputeActivationPlan(target, after)
    if not remaining or #remaining > 0 then
        return nil, L.ERR_MISMATCH
    end

    -- Le chemin d'import de ProjectEbonhold ne debite pas la reserve, contrairement
    -- au clic. On repose donc la valeur, recalculee en absolu : l'affichage de PE et
    -- son blocage des clics redeviennent justes, sans derive possible.
    local effective, balanceErr = Core.GetEffectiveSpendable()
    if effective then
        setSoulAshes(effective, serverCommitted)
    else
        NS.LogWarn(string.format(L.MSG_ACTIVATION_FAILED, tostring(balanceErr)))
    end

    return cost
end
