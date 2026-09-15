local NS = SkillTreeAutoLoad
local L = NS.L

local Data = {}
NS.Data = Data

local SCHEMA_VERSION = 1

local function IsTable(value)
    return type(value) == "table"
end

local function Migrate(db)
    for _, save in pairs(db.saves) do
        if IsTable(save) then
            save.nodeChoices = nil
            save.updatedAt = nil
        end
    end
    db.version = SCHEMA_VERSION
end

local function EnsureShape(db)
    if not IsTable(db.settings) then db.settings = {} end
    if not IsTable(db.groups) then db.groups = {} end
    if not IsTable(db.saves) then db.saves = {} end
    if not IsTable(db.imported) then db.imported = {} end
    if type(db.nextId) ~= "number" then db.nextId = 1 end
    return db
end

-- Un rang venu du disque n'est pas une donnee de confiance : un fichier abime ou
-- edite a la main y met ce qu'il veut, et un rang absurde se paie ailleurs, en
-- boucles de planification qui ne finissent pas. On repare ici, une fois, a la
-- lecture, plutot que de se defendre partout ensuite.
local MAX_RANK = 32

local function RepairRanks(nodeRanks)
    local fixed = 0
    for nodeId, rank in pairs(nodeRanks) do
        if type(nodeId) ~= "number" or type(rank) ~= "number"
            or rank ~= math.floor(rank) or rank <= 0 then
            nodeRanks[nodeId] = nil
            fixed = fixed + 1
        elseif rank > MAX_RANK then
            nodeRanks[nodeId] = MAX_RANK
            fixed = fixed + 1
        end
    end
    return fixed
end

local function Sanitize(db)
    for id, group in pairs(db.groups) do
        if not IsTable(group) or type(group.name) ~= "string" then
            db.groups[id] = nil
        elseif type(group.order) ~= "number" then
            group.order = 0
        end
    end

    local fixed = 0
    for id, save in pairs(db.saves) do
        if not IsTable(save) or type(save.name) ~= "string" then
            db.saves[id] = nil
        else
            if not IsTable(save.nodeRanks) then save.nodeRanks = {} end
            fixed = fixed + RepairRanks(save.nodeRanks)
            -- Absent vaut « complet » : le mode progressif ne s'ecrit que lorsqu'il
            -- est demande, et une base d'avant cette version reste lisible telle quelle.
            if save.progressive ~= true then save.progressive = nil end
        end
    end

    if fixed > 0 then NS.LogWarn(string.format(L.MSG_RANKS_FIXED, fixed)) end

    if db.version ~= SCHEMA_VERSION then Migrate(db) end
end

local function NewId(db)
    local id = "id" .. db.nextId
    db.nextId = db.nextId + 1
    return id
end

local function SortedGroupIds(db)
    local ids = {}
    for id in pairs(db.groups) do ids[#ids + 1] = id end
    table.sort(ids, function(a, b)
        local orderA, orderB = db.groups[a].order or 0, db.groups[b].order or 0
        if orderA == orderB then return a < b end
        return orderA < orderB
    end)
    return ids
end

local function SortedSaveIdsInGroup(db, groupId)
    local ids = {}
    for id, save in pairs(db.saves) do
        if save.groupId == groupId then ids[#ids + 1] = id end
    end
    table.sort(ids, function(a, b)
        local nameA, nameB = db.saves[a].name or "", db.saves[b].name or ""
        if nameA == nameB then return a < b end
        return nameA < nameB
    end)
    return ids
end

local function CreateGroupIn(db, name)
    local id = NewId(db)

    local maxOrder = 0
    for _, group in pairs(db.groups) do
        if (group.order or 0) > maxOrder then maxOrder = group.order end
    end

    db.groups[id] = { name = name, order = maxOrder + 1 }
    return id
end

-- Migration compte : les saves vivaient par personnage, elles vivent desormais sur
-- le compte. Le client ne peut lire que les SavedVariables du personnage connecte,
-- donc la reprise se fait a la premiere connexion de chacun, sans jamais rien
-- ecraser : un homonyme au contenu different est importe sous un nom suffixe.
--
-- Le marqueur « deja repris » vit dans la base COMPTE, pas dans celle du personnage.
-- L'inverse a coute les saves une premiere fois : la base compte n'etait pas encore
-- declaree dans le .toc, donc jamais ecrite, tandis que le marqueur, lui, etait
-- sauvegarde — le garde survivait a ce qu'il gardait et la reprise ne rejouait plus.
-- Marqueur et donnees dans le meme fichier : ils disparaissent ensemble ou pas du tout.
--
-- L'ancienne base n'est jamais modifiee, seulement lue. Elle reste le filet.

local function CopyRanks(source)
    local copy = {}
    for nodeId, rank in pairs(source) do
        if type(rank) == "number" and rank > 0 then copy[nodeId] = rank end
    end
    return copy
end

local function SameRanks(a, b)
    for nodeId, rank in pairs(a) do
        if b[nodeId] ~= rank then return false end
    end
    for nodeId in pairs(b) do
        if a[nodeId] == nil then return false end
    end
    return true
end

local function FindGroupByName(db, name)
    for id, group in pairs(db.groups) do
        if group.name == name then return id end
    end
end

local function FindSaveInGroup(db, groupId, name)
    for id, save in pairs(db.saves) do
        if save.groupId == groupId and save.name == name then return id end
    end
end

local function UniqueSaveName(db, groupId, baseName, charName)
    local candidate = baseName .. " (" .. charName .. ")"
    local n = 1
    while FindSaveInGroup(db, groupId, candidate) do
        n = n + 1
        candidate = baseName .. " (" .. charName .. ") " .. n
    end
    return candidate
end

-- Lectures filtrees de l'ancienne base : rien n'y est corrige ni supprime, les
-- entrees inexploitables sont seulement ignorees. Une liste plate de toutes les
-- saves valides, donc aucune ne peut echapper au balayage.
local function LegacyGroupIds(legacy)
    local groups = IsTable(legacy.groups) and legacy.groups or {}
    local ids = {}
    for id, group in pairs(groups) do
        if IsTable(group) and type(group.name) == "string" then ids[#ids + 1] = id end
    end
    table.sort(ids, function(a, b)
        local orderA = tonumber(groups[a].order) or 0
        local orderB = tonumber(groups[b].order) or 0
        if orderA == orderB then return a < b end
        return orderA < orderB
    end)
    return ids
end

local function LegacySaveIds(legacy)
    local saves = IsTable(legacy.saves) and legacy.saves or {}
    local ids = {}
    for id, save in pairs(saves) do
        if IsTable(save) and type(save.name) == "string" then ids[#ids + 1] = id end
    end
    table.sort(ids, function(a, b)
        local nameA, nameB = saves[a].name, saves[b].name
        if nameA == nameB then return a < b end
        return nameA < nameB
    end)
    return ids
end

local function CharacterKey()
    local name = UnitName("player")
    if not name or name == "" or name == UNKNOWNOBJECT then return nil end
    return name .. "-" .. (GetRealmName() or ""), name
end

local function MigrateCharacterDB(db)
    local legacy = SkillTreeAutoLoadDB
    if not IsTable(legacy) then return end

    -- Le nom du personnage sert de marqueur et nomme les doublons : sans lui on
    -- attend l'appel suivant, Data.Init() etant rejoue a PLAYER_LOGIN.
    local key, charName = CharacterKey()
    if not key or db.imported[key] then return end

    local groupIds = {}
    for _, oldId in ipairs(LegacyGroupIds(legacy)) do
        local name = legacy.groups[oldId].name
        groupIds[oldId] = FindGroupByName(db, name) or CreateGroupIn(db, name)
    end

    local imported, merged = 0, 0
    for _, oldId in ipairs(LegacySaveIds(legacy)) do
        local save = legacy.saves[oldId]
        local ranks = CopyRanks(IsTable(save.nodeRanks) and save.nodeRanks or {})
        local groupId = save.groupId and groupIds[save.groupId] or nil
        local twinId = FindSaveInGroup(db, groupId, save.name)

        if twinId and SameRanks(db.saves[twinId].nodeRanks, ranks) then
            merged = merged + 1
        else
            local name = save.name
            if twinId then name = UniqueSaveName(db, groupId, save.name, charName) end
            db.saves[NewId(db)] = {
                name = name,
                groupId = groupId,
                nodeRanks = ranks,
            }
            imported = imported + 1
        end
    end

    -- Le cote du panneau devient un reglage de compte : on adopte celui du premier
    -- personnage repris, les suivants ne le rediscutent plus.
    if not db.settings.adoptedFromCharacter then
        if IsTable(legacy.settings) and legacy.settings.panelSide == "LEFT" then
            db.settings.panelSide = "LEFT"
        end
        db.settings.adoptedFromCharacter = true
    end

    db.imported[key] = true

    if imported > 0 or merged > 0 then
        NS.Log(string.format(L.MSG_MIGRATED, charName, imported, merged))
    end
end

function Data.Init()
    if not IsTable(SkillTreeAutoLoadAccountDB) then SkillTreeAutoLoadAccountDB = {} end
    local db = EnsureShape(SkillTreeAutoLoadAccountDB)

    Sanitize(db)
    MigrateCharacterDB(db)

    if db.settings.panelSide ~= "LEFT" then db.settings.panelSide = "RIGHT" end

    return db
end

local function DB()
    if not IsTable(SkillTreeAutoLoadAccountDB) then return Data.Init() end
    -- EnsureShape est idempotent : le payer a chaque acces coute cinq tests, et
    -- ferme toute une classe de « attempt to index a nil value » le jour ou une
    -- base tronquee arrive du disque avant le premier Data.Init().
    return EnsureShape(SkillTreeAutoLoadAccountDB)
end

function Data.Persist()
    -- Les SavedVariables ne partent sur le disque qu'a la deconnexion ou au
    -- rechargement : on provoque le second. Le joueur doit savoir pourquoi son
    -- ecran se vide.
    NS.Log(L.MSG_RELOADING)
    ReloadUI()
end

function Data.CreateGroup(name)
    return CreateGroupIn(DB(), name)
end

function Data.RenameGroup(groupId, newName)
    local group = DB().groups[groupId]
    if not group then return false end
    group.name = newName
    return true
end

function Data.DeleteGroup(groupId)
    local db = DB()
    if not db.groups[groupId] then return false end

    db.groups[groupId] = nil
    for _, save in pairs(db.saves) do
        if save.groupId == groupId then save.groupId = nil end
    end
    return true
end

function Data.GetGroup(groupId)
    return DB().groups[groupId]
end

function Data.GetSortedGroupIds()
    return SortedGroupIds(DB())
end

function Data.CreateSave(name, groupId, nodeRanks)
    local db = DB()
    local id = NewId(db)
    db.saves[id] = {
        name = name or L.DEFAULT_SAVE_NAME,
        groupId = groupId,
        nodeRanks = nodeRanks or {},
    }
    return id
end

function Data.UpdateSaveContent(saveId, nodeRanks)
    local save = DB().saves[saveId]
    if not save then return false end
    save.nodeRanks = nodeRanks or {}
    return true
end

function Data.RenameSave(saveId, newName)
    local save = DB().saves[saveId]
    if not save then return false end
    save.name = newName
    return true
end

-- Le mode d'activation n'appelle pas Persist : il se bascule en cours de partie,
-- souvent, et un ReloadUI a chaque clic rendrait la bascule inutilisable. La valeur
-- part sur le disque a la prochaine deconnexion ou au prochain rechargement, comme
-- n'importe quel reglage. Au pire on reperd un basculement, jamais une save.
function Data.SetSaveProgressive(saveId, enabled)
    local save = DB().saves[saveId]
    if not save then return false end
    save.progressive = enabled and true or nil
    return true
end

function Data.IsSaveProgressive(saveId)
    local save = DB().saves[saveId]
    return (save and save.progressive) == true
end

function Data.MoveSaveToGroup(saveId, groupId)
    local save = DB().saves[saveId]
    if not save then return false end
    save.groupId = groupId
    return true
end

function Data.DeleteSave(saveId)
    local db = DB()
    if not db.saves[saveId] then return false end
    db.saves[saveId] = nil
    return true
end

function Data.GetSave(saveId)
    return DB().saves[saveId]
end

function Data.GetSortedSaveIdsInGroup(groupId)
    return SortedSaveIdsInGroup(DB(), groupId)
end

function Data.SetPanelSide(side)
    DB().settings.panelSide = (side == "LEFT") and "LEFT" or "RIGHT"
end

function Data.GetPanelSide()
    return DB().settings.panelSide
end

-- Reglages d'affichage : pas de Persist, comme le mode progressif. Ils se basculent
-- en jeu et partent sur le disque a la prochaine deconnexion ou au prochain
-- rechargement. Absent vaut desactive.
function Data.SetCompact(enabled)
    DB().settings.compact = enabled and true or nil
end

function Data.IsCompact()
    return DB().settings.compact == true
end

function Data.SetPanelCollapsed(collapsed)
    DB().settings.collapsed = collapsed and true or nil
end

function Data.IsPanelCollapsed()
    return DB().settings.collapsed == true
end

-- Actif par defaut : c'est la desactivation qui s'ecrit.
function Data.SetPreviewCamera(enabled)
    DB().settings.noPreviewCamera = (not enabled) and true or nil
end

function Data.IsPreviewCamera()
    return DB().settings.noPreviewCamera ~= true
end
