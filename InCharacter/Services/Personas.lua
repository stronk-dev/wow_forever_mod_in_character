local _, IC = ...
IC.Personas = {}
local R = IC.Personas
-- Slots ("roles" in the save): Greeting, Quote and Farewell, plus any the player adds (Joke,
-- Sarcastic farewell...). Slots are shared by every character. Bars, the wheel, the menu and
-- /ic greet|quote|bye|say use a slot, so switching character keeps the layout and only changes
-- which lines are sent. A slot plays the loaded character's own pool for it, or else the shared
-- pool for it: a preset character can be fully customised, or lean on the shared lines.
-- Pools belong to one character (actor.poolIDs) or are shared by all (profile.sharedPoolIDs).
R.ROLES = {
    { id = "greetings", label = "Greeting", command = "greet" },
    { id = "quotes", label = "Quote", command = "quote" },
    { id = "farewells", label = "Farewell", command = "bye" },
}
R.ROLE = {}; for _, role in ipairs(R.ROLES) do R.ROLE[role.id] = role end
local function shared(profile)
    profile = profile or IC.Profile()
    profile.slots = type(profile.slots) == "table" and profile.slots or {}
    profile.sharedPoolIDs = type(profile.sharedPoolIDs) == "table" and profile.sharedPoolIDs or {}
    profile.sharedRoles = type(profile.sharedRoles) == "table" and profile.sharedRoles or {}
    return profile
end
-- Every slot in order: the three built-ins, then the player's own.
function R.Slots()
    local result = {}
    for _, role in ipairs(R.ROLES) do result[#result + 1] = role end
    for _, slot in ipairs(shared().slots) do result[#result + 1] = slot end
    return result
end
function R.Slot(id)
    if R.ROLE[id] then return R.ROLE[id] end
    for _, slot in ipairs(shared().slots) do if slot.id == id then return slot end end
end
local function labelTaken(label, except)
    for _, slot in ipairs(R.Slots()) do if slot.id ~= except and slot.label:lower() == label:lower() then return true end end
end
function R.CreateSlot(label)
    label = IC.Trim(label or ""); if label == "" then return nil, "Enter a slot name." end
    if labelTaken(label) then return nil, "There is already a slot called " .. label .. "." end
    local p = shared(); p.nextSlotID = p.nextSlotID or 1
    local id
    repeat id = "slot-" .. p.nextSlotID; p.nextSlotID = p.nextSlotID + 1 until not R.Slot(id)
    local slot = { id = id, label = label, custom = true }
    p.slots[#p.slots + 1] = slot; IC.Changed(); return slot
end
function R.RenameSlot(id, label)
    local slot = R.Slot(id); label = IC.Trim(label or "")
    if not slot or not slot.custom then return false, "Built-in slots keep their names." end
    if label == "" then return false, "Enter a slot name." end
    if labelTaken(label, id) then return false, "There is already a slot called " .. label .. "." end
    slot.label = label; IC.Changed(); return true
end
-- Removes a slot the player made, its pool assignments and every button for it.
function R.DeleteSlot(id)
    local slot = R.Slot(id); if not slot or not slot.custom then return false, "Built-in slots cannot be deleted." end
    local p = shared()
    for i = #p.slots, 1, -1 do if p.slots[i].id == id then table.remove(p.slots, i) end end
    p.sharedRoles[id] = nil
    for _, actor in pairs(p.personas or {}) do
        if actor.roles then actor.roles[id] = nil end; if actor.rolesSet then actor.rolesSet[id] = nil end
    end
    local ref = "role:" .. id
    for i = #p.favorites, 1, -1 do if p.favorites[i] == ref then table.remove(p.favorites, i) end end
    for _, collection in pairs(p.collections or {}) do
        for i = #(collection.items or {}), 1, -1 do if collection.items[i] == ref then table.remove(collection.items, i) end end
    end
    IC.Changed(); return true
end
function R.IsShared(poolID)
    for _, id in ipairs(shared().sharedPoolIDs) do if id == poolID then return true end end
    return false
end
function R.SharedPools() return shared().sharedPoolIDs end
-- Moves a pool between the loaded character and "shared by all characters". Its slot moves too.
function R.SetShared(poolID, value)
    local p, actor = shared(), R.Active()
    if not p.pools[poolID] or not actor then return false end
    local role = R.RoleOf(poolID)
    for _, a in pairs(p.personas) do
        for i = #a.poolIDs, 1, -1 do if a.poolIDs[i] == poolID then table.remove(a.poolIDs, i) end end
        for r, id in pairs(a.roles or {}) do if id == poolID then a.roles[r] = nil end end
    end
    for i = #p.sharedPoolIDs, 1, -1 do if p.sharedPoolIDs[i] == poolID then table.remove(p.sharedPoolIDs, i) end end
    for r, id in pairs(p.sharedRoles) do if id == poolID then p.sharedRoles[r] = nil end end
    if value then p.sharedPoolIDs[#p.sharedPoolIDs + 1] = poolID; if role then p.sharedRoles[role] = poolID end
    else actor.poolIDs[#actor.poolIDs + 1] = poolID; if role then actor.roles[role] = poolID end end
    R.cachedActor = nil; IC.Changed(); return true
end
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
        for roleID, current in pairs(actor.roles) do if not mine[current] then actor.roles[roleID] = nil end end
        for _, role in ipairs(R.ROLES) do
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
    local p = shared(profile)
    local isShared = {}; for _, id in ipairs(p.sharedPoolIDs) do if p.pools[id] then isShared[id] = true end end
    for roleID, current in pairs(p.sharedRoles) do if not isShared[current] then p.sharedRoles[roleID] = nil end end
end
-- The pool a slot plays now: the loaded character's own, else the shared one, else nil.
-- Second value: "own" or "shared".
function R.RolePool(role)
    local actor, p = R.Active(), shared()
    local id = actor and actor.roles and actor.roles[role]
    if id and p.pools[id] then return id, "own" end
    id = p.sharedRoles[role]
    if id and p.pools[id] then return id, "shared" end
end
-- The slot a pool fills: for the loaded character's pools its own slot, for shared pools the
-- shared slot.
function R.RoleOf(poolID)
    local actor = R.Active()
    for role, id in pairs(actor and actor.roles or {}) do if id == poolID then return role end end
    for role, id in pairs(shared().sharedRoles) do if id == poolID then return role end end
end
-- "No slot (extra)": empties the slot for good; reloads do not refill it.
function R.ClearRole(poolID)
    local actor, p, role = R.Active(), shared(), R.RoleOf(poolID)
    if not role then return false end
    if p.sharedRoles[role] == poolID then p.sharedRoles[role] = nil
    elseif actor then actor.rolesSet = actor.rolesSet or {}; actor.roles[role], actor.rolesSet[role] = nil, true end
    IC.Changed(); return true
end
function R.SetRole(role, poolID)
    local actor, p = R.Active(), shared()
    if not R.Slot(role) or not p.pools[poolID] then return false end
    local target
    if R.IsShared(poolID) then target = p.sharedRoles
    elseif actor then actor.roles = actor.roles or {}; actor.rolesSet = actor.rolesSet or {}; target = actor.roles end
    if not target then return false end
    for other, id in pairs(target) do if id == poolID then target[other] = nil end end
    target[role] = poolID
    if target ~= p.sharedRoles then actor.rolesSet[role] = true end
    IC.Changed(); return true
end
-- Pools that fill no slot: the loaded character's, then the shared ones.
function R.Extras()
    local result, actor = {}, R.Active()
    for _, id in ipairs(actor and actor.poolIDs or {}) do if not R.RoleOf(id) then result[#result + 1] = id end end
    for _, id in ipairs(shared().sharedPoolIDs) do if not R.RoleOf(id) then result[#result + 1] = id end end
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
    return R.members[id] == true or R.IsShared(id)
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
    if R.Slot(alias) then return (R.RolePool(alias)) end
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
