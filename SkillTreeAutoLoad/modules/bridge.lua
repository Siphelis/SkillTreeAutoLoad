local NS = SkillTreeAutoLoad
local L = NS.L

local Bridge = {}
NS.Bridge = Bridge

local ADDON_PREFIX = "AAM0x9"
local CHUNK_TIMEOUT = 15
local MAX_CHUNKS = 64
local MAX_SOUL_ASHES = 1000000000

local loadoutId, loadoutName
local serverSpendable, serverCommitted

-- nil tant qu'aucun message de loadouts n'a ete lu. Une table vide dit « le
-- serveur n'a rien d'engage », nil dit « je ne sais pas encore » : confondre les
-- deux fait payer au joueur un arbre qu'il possede deja.
local serverNodes

local inflight = {}
local installed = false
local warnedForeign = false
local opLoadouts, opBalance

-- ProjectEbonhold s'envoie ses paquets a lui-meme en whisper. Tout ce qui vient
-- d'un autre expediteur est le message d'un joueur, pas une reponse du serveur —
-- et ces valeurs repartent ensuite dans la trame que l'on ecrit au serveur.
local function IsOwnClient(dist, sender)
    if dist and dist ~= "WHISPER" then return false end
    if sender and sender ~= UnitName("player") then
        if not warnedForeign then
            warnedForeign = true
            NS.LogWarn(string.format(L.MSG_FOREIGN_PAYLOAD, tostring(sender)))
        end
        return false
    end
    return true
end

local function StoreBalance(spendable, committed)
    local s, c = tonumber(spendable), tonumber(committed)
    if not (s and c) or s < 0 or c < 0 or s > MAX_SOUL_ASHES or c > MAX_SOUL_ASHES then
        NS.LogWarn(string.format(L.MSG_BAD_BALANCE,
            tostring(spendable), tostring(committed)))
        return false
    end

    -- Le solde annonce par le serveur est la seule base de verite : on le garde
    -- tel quel, sans jamais le recalculer ni l'accumuler.
    serverSpendable, serverCommitted = s, c
    return true
end

-- L'identite ne se devine pas. Meme regle de repli qu'ApplyLoadoutsFromServer
-- cote ProjectEbonhold : l'id annonce, sinon le loadout 0, sinon rien. Prendre
-- « le premier de la liste » ferait envoyer la build courante sous le nom d'un
-- autre loadout, que le serveur ecraserait sans rien demander.
local function PickLoadout(loadoutsPart, selectedId)
    local exact, fallback

    for loadoutString in loadoutsPart:gmatch("([^;]+)") do
        local parts = {}
        for part in loadoutString:gmatch("([^,]+)") do parts[#parts + 1] = part end

        if #parts >= 3 then
            local id = tonumber(parts[1])
            if id then
                if selectedId and id == selectedId then
                    exact = parts
                    break
                elseif id == 0 and not fallback then
                    fallback = parts
                end
            end
        end
    end

    return exact or fallback
end

local function ReadNodes(chosen)
    -- nil tant que TalentDatabase n'est pas chargee : on ne filtre que ce que
    -- l'on sait juger, sinon un demarrage tot viderait le loadout du joueur.
    local defs = NS.Core.GetNodeDefs()
    local nodes, dropped = {}, 0

    for i = 4, #chosen do
        local nodeId, rank = chosen[i]:match("(%d+):(%d+)")
        nodeId, rank = tonumber(nodeId), tonumber(rank)
        if nodeId and rank and rank > 0 then
            if defs and not defs[nodeId] then
                dropped = dropped + 1
            else
                nodes[nodeId] = rank
            end
        end
    end

    if dropped > 0 then NS.LogWarn(string.format(L.MSG_UNKNOWN_NODES, dropped)) end
    return nodes
end

-- Le serveur a parle et aucun loadout ne se laisse identifier : PE, dans ce cas,
-- repart d'un arbre vide sans identite. On dit la meme chose que lui.
local function ForgetIdentity()
    loadoutId, loadoutName = nil, nil
    serverNodes = {}
end

local function ParseLoadouts(body)
    if type(body) ~= "string" or body == "" then return end

    local globalPart, loadoutsPart = body:match("([^_]+)_?(.*)")
    if not globalPart then return end

    local spendable, committed = globalPart:match("^%d+,(%d+),(%d+)")
    if spendable then StoreBalance(spendable, committed) end

    local selectedId = tonumber(globalPart:match("^(%d+),"))

    if not loadoutsPart or loadoutsPart == "" then
        ForgetIdentity()
        return
    end

    local chosen = PickLoadout(loadoutsPart, selectedId)
    if not chosen then
        ForgetIdentity()
        NS.LogWarn(L.MSG_NO_LOADOUT_MATCH)
        return
    end

    local id, name = tonumber(chosen[1]), chosen[2]

    -- Le corps sortant se decoupe sur « | » : un nom qui en contient produirait
    -- une trame que le serveur relirait de travers. On refuse plutot que de
    -- renommer le loadout du joueur dans son dos.
    if not id or type(name) ~= "string" or name == "" or name:find("|", 1, true) then
        ForgetIdentity()
        NS.LogWarn(string.format(L.MSG_BAD_LOADOUT_IDENTITY, tostring(chosen[2])))
        return
    end

    loadoutId, loadoutName = id, name
    serverNodes = ReadNodes(chosen)
end

local function PurgeStaleChunks(now)
    for mid, rec in pairs(inflight) do
        if now - rec.started > CHUNK_TIMEOUT then inflight[mid] = nil end
    end
end

local function CollectChunk(mid, idx, tot, slice)
    local total, i = tonumber(tot, 16), tonumber(idx, 16)

    -- Sans ces bornes, un index hors plage gonfle le compteur sans remplir la
    -- case correspondante : le message se croit complet, et table.concat leve
    -- sur le trou. Le dispatch de PE fait le meme controle.
    if not (total and i) or total < 1 or total > MAX_CHUNKS or i < 1 or i > total then
        NS.LogWarn(string.format(L.MSG_BAD_CHUNK, tostring(idx), tostring(tot)))
        return nil
    end

    local now = GetTime()
    PurgeStaleChunks(now)

    local rec = inflight[mid]
    -- Deux messages differents sous le meme identifiant : on repart de zero
    -- plutot que de coudre ensemble deux corps qui n'ont rien a voir.
    if not rec or rec.total ~= total then
        rec = { total = total, got = 0, parts = {}, started = now }
        inflight[mid] = rec
    end

    if not rec.parts[i] then
        rec.parts[i] = slice
        rec.got = rec.got + 1
    end

    if rec.got < rec.total then return nil end
    inflight[mid] = nil

    for k = 1, rec.total do
        if rec.parts[k] == nil then
            NS.LogWarn(L.MSG_INCOMPLETE_MESSAGE)
            return nil
        end
    end

    return table.concat(rec.parts, "", 1, rec.total)
end

local function OnAddonMessage(prefix, payload, dist, sender)
    if prefix ~= ADDON_PREFIX or type(payload) ~= "string" then return end
    if not IsOwnClient(dist, sender) then return end

    local evtStr, rest = payload:match("^(%d+)\t(.*)$")
    if not evtStr then return end

    local evt = tonumber(evtStr)

    -- Le serveur annonce aussi la reserve hors loadout, quand le joueur gagne
    -- des cendres. Sans cette ecoute, notre solde reste celui du dernier
    -- loadout recu, et la remise a plat d'ApplyBuild effacerait de l'affichage
    -- tout ce qui a ete gagne depuis.
    if opBalance and evt == opBalance then
        local spendable, committed = rest:match("(%d+),(%d+)")
        if spendable then StoreBalance(spendable, committed) end
        return
    end

    if evt ~= opLoadouts then return end

    local mid, idx, tot, slice =
        rest:match("^@(%x%x%x%x)\t(%x%x%x)/(%x%x%x)\t(.*)$")

    if not mid then
        ParseLoadouts(rest)
        return
    end

    local body = CollectChunk(mid, idx, tot, slice)
    if body then ParseLoadouts(body) end
end

local function RestorePayload(body)
    local nodes = body:sub(4)

    local present = {}
    for nodeId in nodes:gmatch("(%d+):%d+") do
        present[tonumber(nodeId)] = true
    end

    local additions = {}
    for nodeId, rank in pairs(serverNodes or {}) do
        if not present[nodeId] then
            additions[#additions + 1] = nodeId .. ":" .. rank
        end
    end

    if #additions > 0 then
        local extra = table.concat(additions, ",")
        nodes = (nodes == "") and extra or (nodes .. "," .. extra)
    end

    return loadoutId .. "|" .. loadoutName .. "|" .. nodes, #additions
end

function Bridge.HasLoadoutIdentity()
    return loadoutId ~= nil and loadoutName ~= nil and loadoutName ~= ""
        and serverNodes ~= nil
end

function Bridge.GetServerNodes()
    return serverNodes
end

function Bridge.GetServerBalance()
    return serverSpendable, serverCommitted
end

function Bridge.Init()
    -- Deux installations poseraient deux enveloppes autour du meme envoi.
    if installed then return end

    if not (ProjectEbonhold and ProjectEbonhold.sendToServer and ProjectEbonhold.CS) then
        NS.LogError(L.MSG_NO_SENDTOSERVER)
        return
    end

    -- Les opcodes se lisent chez ProjectEbonhold, jamais recopies : une
    -- renumerotation cote serveur doit se voir, pas casser le pont en silence.
    local SS = ProjectEbonhold.SS
    opLoadouts = SS and SS.SEND_LOADOUTS
    opBalance = SS and SS.SEND_PLAYER_UPDATED_COMMITTED_SOUL_POINTS
    if not opLoadouts then
        NS.LogError(L.MSG_NO_OPCODE)
        return
    end

    local listener = CreateFrame("Frame")
    listener:RegisterEvent("CHAT_MSG_ADDON")
    listener:SetScript("OnEvent", function(_, _, prefix, payload, dist, sender)
        -- Une erreur de lecture ne doit pas remonter au joueur sous forme
        -- d'erreur Lua : PE protege deja ses propres handlers de la meme facon.
        local ok, err = pcall(OnAddonMessage, prefix, payload, dist, sender)
        if not ok then NS.LogError(string.format(L.MSG_BRIDGE_ERROR, tostring(err))) end
    end)

    local opcode = ProjectEbonhold.CS.REQUEST_LOADOUT_UPDATE
    local originalSend = ProjectEbonhold.sendToServer

    ProjectEbonhold.sendToServer = function(id, body)
        if id == opcode and type(body) == "string" and body:sub(1, 3) == "0||" then
            if Bridge.HasLoadoutIdentity() then
                body = (RestorePayload(body))
            else
                NS.LogWarn(L.MSG_NO_LOADOUT_ID)
            end
        end
        return originalSend(id, body)
    end

    -- Le serveur ne re-annonce pas le solde apres une validation reussie : on le
    -- lui redemande, exactement ce que provoque un reload.
    local onApplyResult = ProjectEbonhold.SkillTree
        and ProjectEbonhold.SkillTree.OnApplyChangesResult
    if onApplyResult and ProjectEbonhold.RequestLoadoutFromServer then
        ProjectEbonhold.SkillTree.OnApplyChangesResult = function(spellId, success)
            onApplyResult(spellId, success)
            if success then ProjectEbonhold.RequestLoadoutFromServer() end
        end
    end

    installed = true
end
