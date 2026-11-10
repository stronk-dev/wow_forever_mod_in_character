local _, IC = ...
IC.Personas = {}
local R = IC.Personas
-- Every RP character has the same three roles. Bars, the wheel and /ic greet|quote|bye use the
-- role, so switching character keeps the layout and only changes which lines are sent.
R.ROLES = {
    { id = "greetings", label = "Greeting", command = "greet" },
    { id = "quotes", label = "Quote", command = "quote" },
    { id = "farewells", label = "Farewell", command = "bye" },
}
R.ROLE = {}; for _, role in ipairs(R.ROLES) do R.ROLE[role.id] = role end
local function shortTitle(pack, fallback)
    return pack and (pack.title:match(":%s*(.+)$") or pack.title) or fallback
end
function R.Migrate(profile)
    if not profile.personas then
        profile.personas, profile.personaOrder = {}, {}
        local custom, groups = {}, {}
        for _, id in ipairs(profile.poolOrder) do
            local pool = profile.pools[id]; local packID = pool.provenance and pool.provenance.pack
            if packID then groups[packID] = groups[packID] or {}; table.insert(groups[packID], id)
            else custom[#custom + 1] = id end
        end
        profile.personas.custom = { id = "custom", name = "My character", poolIDs = custom }
        profile.personaOrder[1] = "custom"
        local packs = {}; for id in pairs(groups) do packs[#packs + 1] = id end; table.sort(packs)
        for _, id in ipairs(packs) do
            local pack = IC.Library and IC.Library.packs[id]
            local installed = profile.installedPacks[id]
            local current, older = {}, {}
            local latest = {}; for _, poolID in ipairs(installed and installed.pools or groups[id]) do latest[poolID] = true end
            for _, poolID in ipairs(groups[id]) do
                table.insert(latest[poolID] and current or older, poolID)
                if pack then
                    for _, definition in ipairs(pack.pools) do
                        if poolID == id .. "-" .. definition.id or poolID:sub(1, #id + #definition.id + 2) == id .. "-" .. definition.id .. "-" then profile.pools[poolID].shortcut = definition.shortcut end
                    end
                end
            end
            local actorID = "preset-" .. id
            profile.personas[actorID] = { id = actorID, name = shortTitle(pack, id), pack = id, poolIDs = current }
            profile.personaOrder[#profile.personaOrder + 1] = actorID
            if installed then installed.persona = actorID end
            if #older > 0 then
                local oldID = actorID .. "-saved"
                profile.personas[oldID] = { id = oldID, name = shortTitle(pack, id) .. " (saved copies)", pack = id, poolIDs = older }
                profile.personaOrder[#profile.personaOrder + 1] = oldID
            end
        end
    end
    local order, seen = {}, {}
    for _, id in ipairs(profile.personaOrder or {}) do if profile.personas[id] and not seen[id] then order[#order + 1] = id; seen[id] = true end end
    local missing = {}; for id in pairs(profile.personas) do if not seen[id] then missing[#missing + 1] = id end end; table.sort(missing)
    for _, id in ipairs(missing) do order[#order + 1] = id end
    profile.personaOrder = order
    for id, actor in pairs(profile.personas) do
        actor.id = id; local pools, used = {}, {}
        for _, poolID in ipairs(actor.poolIDs or {}) do if profile.pools[poolID] and not used[poolID] then pools[#pools + 1] = poolID; used[poolID] = true end end
        actor.poolIDs = pools
    end
    if not profile.personaVisibilityMigrated then
        for _, settings in ipairs({ profile.menu, profile.wheel }) do
            for id, pool in pairs(profile.pools) do
                local group = pool.provenance and pool.provenance.pack or "custom"
                if settings.hiddenActions["group:" .. group] then settings.hiddenActions["browse:" .. id] = true end
            end
        end
        profile.personaVisibilityMigrated = true
    end
    R.EnsureRoles(profile)
end
-- Fills each character's empty role slots from its own pools: a preset's tagged pool, the
-- starter pool with the role's id, or the old global /ic greet|quote|bye mapping. Each slot is
-- filled automatically at most once (actor.rolesSet); a slot the player emptied stays empty.
function R.EnsureRoles(profile)
    for id, actor in pairs(profile.personas) do
        actor.roles = type(actor.roles) == "table" and actor.roles or {}
        actor.rolesSet = type(actor.rolesSet) == "table" and actor.rolesSet or {}
        local mine = {}; for _, poolID in ipairs(actor.poolIDs) do mine[poolID] = true end
        for _, role in ipairs(R.ROLES) do
            local current = actor.roles[role.id]
            if current and not mine[current] then actor.roles[role.id] = nil end
            if actor.roles[role.id] then actor.rolesSet[role.id] = true end
            if not actor.roles[role.id] and not actor.rolesSet[role.id] then
                for _, poolID in ipairs(actor.poolIDs) do
                    local pool = profile.pools[poolID]
                    if pool and not actor.roles[role.id] and (pool.shortcut == role.id or poolID == role.id or (profile.shortcuts or {})[role.id] == poolID) then
                        actor.roles[role.id] = poolID; actor.rolesSet[role.id] = true
                    end
                end
            end
        end
    end
end
-- The loaded character's pool for a role, or nil when the slot is empty.
function R.RolePool(role)
    local actor = R.Active(); local id = actor and actor.roles and actor.roles[role]
    return id and IC.Profile().pools[id] and id or nil
end
-- "No role (extra)": empties the slot for good; reloads do not refill it.
function R.ClearRole(poolID)
    local actor, role = R.Active(), R.RoleOf(poolID)
    if not actor or not role then return false end
    actor.rolesSet = actor.rolesSet or {}; actor.roles[role], actor.rolesSet[role] = nil, true
    IC.Changed(); return true
end
function R.RoleOf(poolID)
    local actor = R.Active()
    for role, id in pairs(actor and actor.roles or {}) do if id == poolID then return role end end
end
function R.SetRole(role, poolID)
    local actor = R.Active(); if not actor or not R.ROLE[role] then return false end
    actor.roles = actor.roles or {}
    actor.rolesSet = actor.rolesSet or {}
    for other, id in pairs(actor.roles) do if id == poolID then actor.roles[other] = nil; actor.rolesSet[other] = true end end
    actor.roles[role] = poolID; actor.rolesSet[role] = true; IC.Changed(); return true
end
-- The loaded character's pools that are not in a role slot.
function R.Extras()
    local result, actor = {}, R.Active()
    for _, id in ipairs(actor and actor.poolIDs or {}) do if not R.RoleOf(id) then result[#result + 1] = id end end
    return result
end
function R.Active()
    local profile, character = IC.Profile(), IC.Profiles.Character()
    if not profile.personas then R.Migrate(profile) end
    character.personaSelections = character.personaSelections or {}
    local scope = character.scope; local selected = character.personaSelections[scope]
    if selected and profile.personas[selected] then return profile.personas[selected] end
    local candidates = {}
    for _, id in ipairs(profile.personaOrder) do
        local actor = profile.personas[id]
        for _, poolID in ipairs(actor.poolIDs) do
            for _, shortcut in pairs(profile.shortcuts) do
                if shortcut == poolID then candidates[id] = true end
            end
        end
    end
    local inferred, count; count = 0; for id in pairs(candidates) do inferred, count = id, count + 1 end
    selected = count == 1 and inferred or (profile.personas.custom and "custom") or profile.personaOrder[1]
    character.personaSelections[scope] = selected
    return selected and profile.personas[selected]
end
function R.Name() local actor = R.Active(); return actor and actor.name or "No character loaded" end
function R.HasPool(id)
    local actor = R.Active(); if not actor then return false end
    if R.cachedActor ~= actor or R.cachedList ~= actor.poolIDs or R.cachedCount ~= #actor.poolIDs then
        R.cachedActor, R.cachedList, R.cachedCount, R.members = actor, actor.poolIDs, #actor.poolIDs, {}
        for _, poolID in ipairs(actor.poolIDs) do R.members[poolID] = true end
    end
    return R.members[id] == true
end
function R.ActionAllowed(action)
    return action.type ~= "pool" and action.type ~= "line" or R.HasPool(action.payload)
end
function R.Pools() local actor = R.Active(); return actor and actor.poolIDs or {} end
function R.Create(name, pools, pack)
    name = IC.Trim(name); if name == "" then return nil, "Enter a character name." end
    local p = IC.Profile(); if not p.personas then R.Migrate(p) end; p.nextPersonaID = p.nextPersonaID or 1
    local id
    repeat id = "character-" .. p.nextPersonaID; p.nextPersonaID = p.nextPersonaID + 1 until not p.personas[id]
    p.personas[id] = { id = id, name = name, poolIDs = IC.Copy(pools or {}), pack = pack, roles = {} }; p.personaOrder[#p.personaOrder + 1] = id
    R.EnsureRoles(p)
    return p.personas[id]
end
function R.PoolLabel(pool) return pool.name end
-- Where a pool came from, for a dimmed tooltip line (never part of its name).
function R.Source(pool)
    local pack = pool and pool.provenance and IC.Library and IC.Library.packs[pool.provenance.pack]
    return pack and pack.title or nil
end
function R.Load(id)
    if not IC.Profile().personas[id] then return false, "Character not found." end
    local c = IC.Profiles.Character(); c.personaSelections = c.personaSelections or {}; c.personaSelections[c.scope] = id
    if IC.Editor and IC.Editor.OnCharacterLoaded then IC.Editor.OnCharacterLoaded() end
    if IC.Flyout then IC.Flyout.Close() end; if IC.Wheel then IC.Wheel.Close() end
    IC.Changed(); return true
end
function R.AddPool(id)
    local actor = R.Active()
    if not actor then actor = R.Create("My character"); R.Load(actor.id) end
    for _, existing in ipairs(actor.poolIDs) do if existing == id then return end end
    actor.poolIDs[#actor.poolIDs + 1] = id
end
function R.Assign(poolID, actorID)
    local p = IC.Profile(); if not p.pools[poolID] or not p.personas[actorID] then return false end
    for _, actor in pairs(p.personas) do for i = #actor.poolIDs, 1, -1 do if actor.poolIDs[i] == poolID then table.remove(actor.poolIDs, i) end end end
    p.personas[actorID].poolIDs[#p.personas[actorID].poolIDs + 1] = poolID; IC.Changed(); return true
end
function R.Shortcut(alias)
    local p = IC.Profile()
    if R.ROLE[alias] then return R.RolePool(alias) end
    local found
    for _, id in ipairs(R.Pools()) do
        local pool = p.pools[id]
        if pool and (pool.shortcut == alias or id == alias or IC.Normalize(pool.name) == alias) then if found then return nil end; found = id end
    end
    return found
end
function R.FindPool(name)
    local normalized, found = IC.Normalize(name)
    for _, id in ipairs(R.Pools()) do
        local pool = IC.Profile().pools[id]
        if name == id then return pool end
        local short = pool.name:match(" / (.+)$") or pool.name
        if normalized == IC.Normalize(pool.name) or normalized == IC.Normalize(short) then
            if found then return nil, "Ambiguous pool name; use its exact ID." end; found = pool
        end
    end
    return found, found and nil or ("No matching pool for " .. R.Name() .. ".")
end
function R.Options(library)
    local result = {}
    R.Active()
    for _, id in ipairs(IC.Profile().personaOrder) do local a = IC.Profile().personas[id]; result[#result + 1] = { value = id, label = a.name } end
    if library and IC.Library then
        local installed = {}; for _, a in pairs(IC.Profile().personas) do if a.pack then installed[a.pack] = true end end
        for _, id in ipairs(IC.Library.order) do if not installed[id] then result[#result + 1] = { value = "preset:" .. id, label = "Load " .. shortTitle(IC.Library.packs[id], id) } end end
    end
    return result
end
function R.Choose(value)
    if value:sub(1, 7) == "preset:" then return IC.Library.Load(value:sub(8)) end
    return R.Load(value)
end
function R.Resolve(value)
    if IC.Profile().personas[value] then return value end
    if IC.Library and IC.Library.packs[value] then return "preset:" .. value end
    local found
    for _, option in ipairs(R.Options(true)) do
        if IC.Normalize(option.label:gsub("^Load ", "")) == IC.Normalize(value) then
            if found then return nil, "Ambiguous character name; choose one in Options." end
            found = option.value
        end
    end
    return found, found and nil or "Choose a character in Options."
end
