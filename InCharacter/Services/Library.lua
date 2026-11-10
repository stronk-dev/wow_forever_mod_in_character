local _, IC = ...
IC.Library = { packs = {}, order = {} }
local L = IC.Library
-- Families group presets in the character switcher and on the RP lines page. A pack names its
-- family; older packs without one are placed by their id prefix. Order here is display order.
L.FAMILIES = {
    { id = "office", label = "The Office", icon = "Interface\\Icons\\inv_misc_paperbundle02a" },
    { id = "nlpolitics", label = "Dutch politics", icon = "Interface\\Icons\\ui_greenflag" },
    { id = "dutch", label = "Dutch", icon = "Interface\\Icons\\inv_shirt_orange_01" },
    { id = "world", label = "World", icon = "Interface\\Icons\\achievement_guildperk_hastyhearth" },
    { id = "fundubs", label = "Fundubs", icon = "Interface\\Icons\\achievement_halloween_smiley_01" },
    { id = "other", label = "Other", icon = "Interface\\Icons\\INV_Misc_Book_09" },
}
L.FAMILY = {}; for _, family in ipairs(L.FAMILIES) do L.FAMILY[family.id] = family end
local PREFIX = { ["office-"] = "office", ["nl-"] = "nlpolitics", ["world-"] = "world", ["dutch-mastermovies"] = "fundubs", ["dutch-"] = "dutch" }
function L.FamilyOf(id)
    local pack = L.packs[id]
    if pack and pack.family and L.FAMILY[pack.family] then return pack.family end
    for _, prefix in ipairs({ "dutch-mastermovies", "office-", "nl-", "world-", "dutch-" }) do
        if id:sub(1, #prefix) == prefix then return PREFIX[prefix] end
    end
    return "other"
end
-- The preset ids in one family, in registration order.
function L.Members(family)
    local result = {}
    for _, id in ipairs(L.order) do if L.FamilyOf(id) == family then result[#result + 1] = id end end
    return result
end
-- The character name a preset plays as ("The Office: Stanley Hudson" -> "Stanley Hudson").
function L.ShortTitle(id)
    local pack = L.packs[id]; return pack and (pack.title:match(":%s*(.+)$") or pack.title) or id
end

function L.Validate(pack)
    if type(pack) ~= "table" or type(pack.id) ~= "string" or not pack.id:match("^[a-z0-9%-]+$") then return false, "Invalid pack ID" end
    if type(pack.title) ~= "string" or pack.title == "" then return false, "Missing title" end
    if type(pack.version) ~= "number" or pack.version < 1 or pack.version % 1 ~= 0 then return false, "Invalid version" end
    for _, field in ipairs({ "culture", "locale", "author", "source", "contentNote" }) do
        if type(pack[field]) ~= "string" or pack[field] == "" then return false, "Missing " .. field end
    end
    if type(pack.pools) ~= "table" or #pack.pools == 0 then return false, "Missing pools" end
    local seen = {}
    for _, pool in ipairs(pack.pools) do
        if type(pool) ~= "table" then return false, "Invalid pool" end
        if type(pool.id) ~= "string" or not pool.id:match("^[a-z0-9%-]+$") or seen[pool.id] then return false, "Invalid/duplicate pool ID" end
        seen[pool.id] = true
        if type(pool.name) ~= "string" or pool.name == "" then return false, "Missing pool name" end
        if pool.channel ~= "SAY" and pool.channel ~= "YELL" and pool.channel ~= "EMOTE" then return false, "Invalid channel" end
        if pool.mode ~= "random" and pool.mode ~= "shuffle" and pool.mode ~= "sequential" then return false, "Invalid mode" end
        if type(pool.lines) ~= "table" or #pool.lines == 0 then return false, "Empty pool" end
        for _, line in ipairs(pool.lines) do
            if type(line) ~= "string" or IC.Trim(line) == "" or line:find("[%z\1-\31\127]") then return false, "Invalid line" end
        end
        if pool.shortcut and not (IC.Personas and IC.Personas.ROLE[pool.shortcut]) then return false, "Invalid shortcut" end
    end
    return true
end
function L.Register(pack)
    local valid, problem = L.Validate(pack)
    assert(valid, "In Character preset: " .. tostring(problem))
    assert(not L.packs[pack.id], "Duplicate preset " .. pack.id)
    L.packs[pack.id] = pack; L.order[#L.order + 1] = pack.id
end
-- Layers. A preset character's pool does not copy the preset's lines. It points at the preset
-- pool (layer.pack, layer.def) and keeps only the player's changes:
--   hidden[presetText] = true      a preset line the player removed
--   edits[presetText]  = "text"    a preset line the player reworded (keeps its message ID)
--   own = { {id, text} }           lines the player added
--   ids[presetText]    = lineID    stable message IDs for preset lines (buttons, favorites)
-- pool.lines / pool.lineIDs are rebuilt from preset + layer, so addon updates (new lines, new
-- slots) reach characters already in use while the player's changes always win. A preset line
-- removed by an update disappears; if the player had reworded it, the rewording stays as their own.
local function definition(layer)
    local pack = layer and L.packs[layer.pack]
    for _, def in ipairs(pack and pack.pools or {}) do if def.id == layer.def then return def end end
end
function L.Materialize(pool)
    local layer = pool.layer; local def = definition(layer)
    if not def then return false end
    layer.hidden, layer.edits, layer.own, layer.ids = layer.hidden or {}, layer.edits or {}, layer.own or {}, layer.ids or {}
    IC.Dialogue.EnsureLines(pool)
    local inPreset = {}; for _, text in ipairs(def.lines) do inPreset[text] = true end
    -- Rewordings of lines the preset dropped become the player's own lines (same message ID).
    for text, edited in pairs(layer.edits) do
        if not inPreset[text] then
            table.insert(layer.own, { id = layer.ids[text] or IC.Dialogue.NewLineID(pool), text = edited })
            layer.edits[text] = nil
        end
    end
    for text in pairs(layer.ids) do if not inPreset[text] then layer.ids[text] = nil end end
    for text in pairs(layer.hidden) do if not inPreset[text] then layer.hidden[text] = nil end end
    local lines, ids = {}, {}
    for _, text in ipairs(def.lines) do
        if not layer.hidden[text] then
            layer.ids[text] = layer.ids[text] or IC.Dialogue.NewLineID(pool)
            lines[#lines + 1] = layer.edits[text] or text; ids[#ids + 1] = layer.ids[text]
        end
    end
    for _, line in ipairs(layer.own) do lines[#lines + 1] = line.text; ids[#ids + 1] = line.id end
    local changed = #lines ~= #pool.lines
    for i = 1, #lines do if lines[i] ~= pool.lines[i] or ids[i] ~= pool.lineIDs[i] then changed = true end end
    pool.lines, pool.lineIDs = lines, ids
    if changed then pool.revision = (pool.revision or 0) + 1; IC.Dialogue.Clear(pool.id) end
    return changed
end
-- Reads the player's edit of pool.lines back into the layer, then rebuilds the lines.
function L.Capture(pool)
    local layer = pool.layer; local def = definition(layer)
    if not def then return end
    layer.hidden, layer.edits, layer.own, layer.ids = layer.hidden or {}, layer.edits or {}, layer.own or {}, layer.ids or {}
    local textOf = {}; for i, id in ipairs(pool.lineIDs) do textOf[id] = pool.lines[i] end
    local presetIDs = {}
    for _, text in ipairs(def.lines) do
        local id = layer.ids[text]
        if id and textOf[id] then
            presetIDs[id] = true; layer.hidden[text] = nil
            layer.edits[text] = textOf[id] ~= text and textOf[id] or nil
        elseif id then layer.hidden[text] = true; layer.edits[text] = nil end
    end
    local own = {}
    for i, id in ipairs(pool.lineIDs) do if not presetIDs[id] then own[#own + 1] = { id = id, text = pool.lines[i] } end end
    layer.own = own
    L.Materialize(pool)
end
-- Which preset pool an older full copy came from (its id was "<pack>-<pool>" or "-<n>").
local function definitionFor(pool)
    local pack = pool.provenance and L.packs[pool.provenance.pack]
    for _, def in ipairs(pack and pack.pools or {}) do
        local base = pack.id .. "-" .. def.id
        if pool.id == base or pool.id:match("^" .. base:gsub("%-", "%%-") .. "%-%d+$") then return def end
    end
    for _, def in ipairs(pack and pack.pools or {}) do if pool.shortcut and def.shortcut == pool.shortcut then return def end end
end
-- Turns a full copy (made before 0.15.1) into a layer. Lines matching the preset become preset
-- lines (keeping their message IDs); every other line is the player's own. Nothing is hidden:
-- an old copy cannot tell a line the player deleted from one the update added, so new lines show.
function L.Adopt(pool)
    if pool.layer or not pool.provenance then return end
    local def = definitionFor(pool); if not def then return end
    IC.Dialogue.EnsureLines(pool)
    local layer = { pack = pool.provenance.pack, def = def.id, hidden = {}, edits = {}, own = {}, ids = {} }
    local inPreset = {}; for _, text in ipairs(def.lines) do inPreset[text] = true end
    for i, text in ipairs(pool.lines) do
        if inPreset[text] and not layer.ids[text] then layer.ids[text] = pool.lineIDs[i]
        else layer.own[#layer.own + 1] = { id = pool.lineIDs[i], text = text } end
    end
    pool.layer = layer
    L.Materialize(pool)
end
local function newLayeredPool(profile, id, def)
    local pack = L.packs[id]
    local base = id .. "-" .. def.id
    local poolID, suffix = base, 2
    while profile.pools[poolID] do poolID = base .. "-" .. suffix; suffix = suffix + 1 end
    local pool = IC.Defaults.Pool(poolID, def.name)
    pool.channel, pool.mode = def.channel, def.mode
    pool.icon = def.icon or pack.icon or IC.Icons[1]
    pool.provenance = { pack = id, version = pack.version, source = pack.source }
    pool.shortcut = def.shortcut
    pool.layer = { pack = id, def = def.id, hidden = {}, edits = {}, own = {}, ids = {} }
    profile.pools[poolID] = pool; profile.poolOrder[#profile.poolOrder + 1] = poolID
    IC.Dialogue.EnsureLines(pool); L.Materialize(pool)
    return poolID
end
-- On every load: old copies become layers, every layered pool is rebuilt from the current
-- preset, and characters get preset pools (slots) that were added since, unless the player
-- deleted that pool.
function L.Sync(profile)
    for _, pool in pairs(profile.pools) do L.Adopt(pool) end
    for _, pool in pairs(profile.pools) do if pool.layer then L.Materialize(pool) end end
    for id, installed in pairs(profile.installedPacks or {}) do
        local pack, actor = L.packs[id], installed.persona and profile.personas and profile.personas[installed.persona]
        if pack and actor then
            local have = {}
            for _, poolID in ipairs(actor.poolIDs) do
                local pool = profile.pools[poolID]
                if pool and pool.layer and pool.layer.pack == id then have[pool.layer.def] = true end
            end
            for _, def in ipairs(pack.pools) do
                if not have[def.id] and not (installed.dropped and installed.dropped[def.id]) then
                    actor.poolIDs[#actor.poolIDs + 1] = newLayeredPool(profile, id, def)
                end
            end
            installed.version = pack.version
        end
    end
end
-- Starts playing a preset: a new character whose pools are layers on the preset. load = also make it the active character.
function L.Install(id, load)
    local pack, profile = L.packs[id], IC.Profile()
    if not pack then return false, "Unknown preset." end
    local installed = { version = pack.version, pools = {} }
    for _, def in ipairs(pack.pools) do installed.pools[#installed.pools + 1] = newLayeredPool(profile, id, def) end
    profile.installedPacks[id] = installed
    if IC.Personas then
        local actor = IC.Personas.Create(L.ShortTitle(id), installed.pools, id)
        installed.persona = actor.id
        actor.icon = pack.icon or (installed.pools[1] and profile.pools[installed.pools[1]].icon)
        if load then IC.Personas.Load(actor.id) end
    end
    IC.Changed()
    return true, "Now playing " .. L.ShortTitle(id) .. ". Your changes are kept on top of the preset.", installed.pools[1], installed.persona
end
function L.Load(id)
    local installed = IC.Profile().installedPacks[id]
    if not installed or not installed.persona or not IC.Profile().personas[installed.persona] then
        local ok, reason = L.Install(id, false); if not ok then return false, reason end
        installed = IC.Profile().installedPacks[id]
    end
    return IC.Personas.Load(installed.persona)
end
