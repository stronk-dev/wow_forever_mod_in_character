local _, IC = ...
IC.Library = { packs = {}, order = {} }
local L = IC.Library

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
        if pool.shortcut and pool.shortcut ~= "greetings" and pool.shortcut ~= "quotes" and pool.shortcut ~= "farewells" then return false, "Invalid shortcut" end
    end
    return true
end
function L.Register(pack)
    local valid, problem = L.Validate(pack)
    assert(valid, "In Character preset: " .. tostring(problem))
    assert(not L.packs[pack.id], "Duplicate preset " .. pack.id)
    L.packs[pack.id] = pack; L.order[#L.order + 1] = pack.id
end
-- Copies a preset's pools into the profile as a new RP character. load = also make it the active character.
function L.Install(id, load)
    local pack, profile = L.packs[id], IC.Profile()
    if not pack then return false, "Unknown preset." end
    local installed = { version = pack.version, pools = {} }
    for _, definition in ipairs(pack.pools) do
        local base = id .. "-" .. definition.id
        local poolID, suffix = base, 2
        while profile.pools[poolID] do poolID = base .. "-" .. suffix; suffix = suffix + 1 end
        local pool = IC.Defaults.Pool(poolID, definition.name)
        pool.lines, pool.channel, pool.mode = IC.Copy(definition.lines), definition.channel, definition.mode
        pool.icon = definition.icon or pack.icon or IC.Icons[1]
        pool.provenance = { pack = id, version = pack.version, source = pack.source }
        pool.shortcut = definition.shortcut
        profile.pools[poolID] = pool; profile.poolOrder[#profile.poolOrder + 1] = poolID
        IC.Dialogue.EnsureLines(pool)
        installed.pools[#installed.pools + 1] = poolID
    end
    profile.installedPacks[id] = installed
    if IC.Personas then
        local actor = IC.Personas.Create((pack.title:match(":%s*(.+)$") or pack.title), installed.pools, id)
        installed.persona = actor.id
        actor.icon = pack.icon or (installed.pools[1] and profile.pools[installed.pools[1]].icon)
        if load then IC.Personas.Load(actor.id) end
    end
    IC.Changed()
    return true, "Copied " .. pack.title .. ". Existing pools were preserved.", installed.pools[1], installed.persona
end
function L.Load(id)
    local installed = IC.Profile().installedPacks[id]
    if not installed or not installed.persona or not IC.Profile().personas[installed.persona] then
        local ok, reason = L.Install(id, false); if not ok then return false, reason end
        installed = IC.Profile().installedPacks[id]
    end
    return IC.Personas.Load(installed.persona)
end
