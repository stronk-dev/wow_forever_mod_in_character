local _, IC = ...
-- One model behind every surface: a collection is an ordered list of entries.
--   action ids ("emote:wave", "pool:x", "play:random:x", "line:x:3"),
--   "set:<id>"  a group (flyout on bars, fan on the ring, submenu in menus),
--   "all:<id>"  that collection's items inline, as their own segment.
-- Surfaces show one collection; hiding something means removing it from a collection.
IC.Collections = {}
local C = IC.Collections
local MAX_DEPTH = 4
C.MAIN = { "all:favorites", "set:Combat", "set:Social", "set:Reactions", "set:Idle", "set:Voice/Fun", "set:rp" }
-- The wheel's default: 7 slices (marking menus stay at 8 or fewer); each one zooms into its list.
C.RING = { "set:favorites", "set:Combat", "set:Social", "set:Reactions", "set:Idle", "set:Voice/Fun", "set:rp" }

local function info(id) return IC.Emotes.CategoryInfo[id] or {} end
local function seeded(category, profile)
    local items = {}
    for _, action in ipairs(IC.Emotes.byCategory[category] or {}) do
        if not IC.Curation or IC.Curation.Included(action, profile) then items[#items + 1] = action.id end
    end
    return items
end

-- Adds collections once. Existing collections, favorites and every older setting are left untouched.
function C.Ensure(profile)
    profile = profile or IC.Profile()
    if type(profile.collections) ~= "table" then
        profile.collections = {}
        profile.collections.main = { id = "main", name = "Main bar", icon = IC.AddonIcon, items = IC.Copy(C.MAIN), builtin = true }
        profile.collections.favorites = { id = "favorites", name = "Favorites", icon = info("Favorites").icon, store = "favorites", builtin = true }
        for _, category in ipairs(IC.Emotes.categories) do
            profile.collections[category] = { id = category, name = info(category).label or category, icon = info(category).icon,
                items = seeded(category, profile), builtin = true }
        end
        profile.collectionOrder = { "main", "favorites" }
        for _, category in ipairs(IC.Emotes.categories) do profile.collectionOrder[#profile.collectionOrder + 1] = category end
    end
    if not profile.collections.ring then
        profile.collections.ring = { id = "ring", name = "Radial wheel", icon = IC.AddonIcon, items = IC.Copy(C.RING), builtin = true }
        profile.collectionOrder = profile.collectionOrder or {}
        table.insert(profile.collectionOrder, 2, "ring")
    end
    local order, seen = {}, {}
    for _, id in ipairs(type(profile.collectionOrder) == "table" and profile.collectionOrder or {}) do
        if profile.collections[id] and not seen[id] then order[#order + 1] = id; seen[id] = true end
    end
    local missing = {}
    for id, collection in pairs(profile.collections) do
        collection.id = id
        if collection.store ~= "favorites" and type(collection.items) ~= "table" then collection.items = {} end
        if not seen[id] then missing[#missing + 1] = id end
    end
    table.sort(missing); for _, id in ipairs(missing) do order[#order + 1] = id end
    profile.collectionOrder = order
    return profile.collections
end

-- The loaded RP character's pools. Not stored: it follows Personas.
-- First the character switcher, then the three role slots, then the character's extra pools.
local function roleplay(profile)
    local items, icon = { "character" }, nil
    for _, role in ipairs(IC.Personas.ROLES) do items[#items + 1] = "role:" .. role.id end
    for _, id in ipairs(IC.Personas.Extras()) do
        local pool = profile.pools[id]
        if pool then items[#items + 1] = "pool:" .. id; icon = icon or pool.icon end
    end
    return { id = "rp", name = IC.Personas and IC.Personas.Name() or "Roleplay", icon = (IC.Personas and IC.Personas.Active() and IC.Personas.Active().icon) or icon or info("Roleplay").icon, items = items, dynamic = true }
end

function C.Get(id)
    local profile = IC.Profile()
    if id == "rp" then return roleplay(profile) end
    local collection = C.Ensure(profile)[id]
    if not collection then return nil end
    return collection
end
function C.Refs(id)
    local collection = C.Get(id)
    if not collection then return {} end
    if collection.store == "favorites" then return IC.Profile().favorites end
    return collection.items
end
function C.List()
    C.Ensure()
    local result = {}
    for _, id in ipairs(IC.Profile().collectionOrder or {}) do result[#result + 1] = C.Get(id) end
    result[#result + 1] = C.Get("rp")
    return result
end

local function canonical(ref)
    if type(ref) ~= "string" then return ref end
    return IC.Actions.CanonicalID(ref)
end
local function playable(action)
    if action.type == "emote" then return action.verified == true end
    if action.role or action.type == "character" or action.type == "persona" then return true end
    local pool = IC.Profile().pools[action.payload]
    if action.type == "pool" and (not pool or #pool.lines == 0) then return false end
    return not IC.Personas or IC.Personas.ActionAllowed(action)
end

-- Resolves entries into play nodes. Groups and inline segments recurse; cycles and depth are bounded.
-- Unknown emotes, removed pools and other characters' pools are skipped, never removed from the data.
function C.Nodes(id, visiting, depth)
    visiting, depth = visiting or {}, depth or 0
    if visiting[id] or depth > MAX_DEPTH then return {} end
    visiting[id] = true
    local result, segment = {}, 1
    for _, ref in ipairs(C.Refs(id)) do
        local kind, target
        if type(ref) == "string" then kind, target = ref:match("^(%a+):(.+)$") end
        if kind == "set" then
            local group = C.Get(target)
            if group and not visiting[target] and #C.Nodes(target, visiting, depth + 1) > 0 then
                local short = info(target).short or (group.dynamic and group.name:match("^(%S+)")) or nil
                result[#result + 1] = { id = ref, type = "group", collection = target, label = group.name, name = group.name, short = short, icon = group.icon, segment = segment }
            end
        elseif kind == "all" then
            local inner = C.Nodes(target, visiting, depth + 1)
            if #inner > 0 then
                if #result > 0 then segment = segment + 1 end
                for _, node in ipairs(inner) do node.segment = segment; result[#result + 1] = node end
                segment = segment + 1
            end
        else
            local action = IC.Actions.Resolve(ref)
            if action and playable(action) then action.segment = segment; result[#result + 1] = action end
        end
    end
    visiting[id] = nil
    return result
end
function C.HasChildren(node)
    return node.type == "group" or node.type == "character" or (node.type == "pool" and not node.empty)
end
function C.Children(node)
    if node.type == "group" then return C.Nodes(node.collection) end
    if node.type == "character" then
        local result = {}
        for _, option in ipairs(IC.Personas.Options(true)) do result[#result + 1] = IC.Actions.Resolve("persona:" .. option.value) end
        return result
    end
    if node.type == "pool" then
        local pool = IC.Profile().pools[node.payload]
        if pool and (not IC.Personas or IC.Personas.ActionAllowed(node)) then return IC.Actions.Lines(pool) end
    end
    return {}
end

-- Editing. Built-in collections can be edited but not deleted.
local function editable(id)
    local collection = C.Get(id)
    if not collection or collection.dynamic then return nil end
    return collection
end
-- Reject indirect cycles too. Resolution is bounded, but a cyclic group could otherwise
-- keep opening fresh flyout levels because each interaction starts a new resolution.
local function reaches(id, target, seen)
    if id == target then return true end
    seen = seen or {}; if seen[id] then return false end; seen[id] = true
    for _, ref in ipairs(C.Refs(id)) do
        local kind, child = ref:match("^(%a+):(.+)$")
        if (kind == "set" or kind == "all") and reaches(child, target, seen) then return true end
    end
    return false
end
function C.Index(id, ref)
    ref = canonical(ref)
    for index, value in ipairs(C.Refs(id)) do if canonical(value) == ref then return index end end
end
function C.Contains(id, ref) return C.Index(id, ref) ~= nil end
function C.Add(id, ref, position)
    if not editable(id) or C.Contains(id, ref) then return false end
    ref = canonical(ref)
    local target = type(ref) == "string" and ref:match("^%a+:(.+)$")
    if type(ref) == "string" and (ref:match("^set:") or ref:match("^all:")) then
        if not C.Get(target) or reaches(target, id) then return false end
    elseif not IC.Actions.Resolve(ref) then return false end
    local refs = C.Refs(id)
    table.insert(refs, math.max(1, math.min(#refs + 1, position or #refs + 1)), ref)
    IC.Changed(); return true
end
function C.Remove(id, ref)
    if not editable(id) then return false end
    local refs, removed = C.Refs(id), false
    ref = canonical(ref)
    for index = #refs, 1, -1 do if canonical(refs[index]) == ref then table.remove(refs, index); removed = true end end
    if removed then IC.Changed() end
    return removed
end
function C.Toggle(id, ref)
    if C.Contains(id, ref) then return C.Remove(id, ref) end
    return C.Add(id, ref)
end
function C.Move(id, ref, delta)
    if not editable(id) then return false end
    local refs, index = C.Refs(id), C.Index(id, ref)
    local target = index and index + delta
    if not target or target < 1 or target > #refs then return false end
    refs[index], refs[target] = refs[target], refs[index]
    IC.Changed(); return true
end
function C.Membership(ref)
    local result = {}
    for _, collection in ipairs(C.List()) do
        if not collection.dynamic and C.Contains(collection.id, ref) then result[#result + 1] = collection.id end
    end
    return result
end
function C.Create(name, icon)
    name = IC.Trim(name or "")
    if name == "" then return nil, "Enter a name." end
    local profile = IC.Profile(); C.Ensure(profile)
    profile.nextCollectionID = profile.nextCollectionID or 1
    local id
    repeat id = "c" .. profile.nextCollectionID; profile.nextCollectionID = profile.nextCollectionID + 1 until not profile.collections[id]
    profile.collections[id] = { id = id, name = name, icon = icon or IC.Icons[1], items = {} }
    profile.collectionOrder[#profile.collectionOrder + 1] = id
    IC.Changed(); return profile.collections[id]
end
function C.Delete(id)
    local collection = editable(id)
    if not collection or collection.builtin then return false end
    local profile = IC.Profile()
    for _, settings in ipairs({ profile.wheel, profile.menu }) do if settings.root == id then settings.root = "favorites" end end
    for _, layout in ipairs({ IC.Profiles.Character().layout, IC.Profiles.db.sharedLayout }) do
        for _, bar in ipairs(layout.bars) do if bar.collection == id then bar.collection, bar.source = "favorites", nil end end
    end
    profile.collections[id] = nil
    for index = #profile.collectionOrder, 1, -1 do if profile.collectionOrder[index] == id then table.remove(profile.collectionOrder, index) end end
    -- Remove group references so nothing silently points at a deleted collection.
    for _, other in pairs(profile.collections) do
        local refs = other.store == "favorites" and profile.favorites or other.items
        for index = #refs, 1, -1 do if refs[index] == "set:" .. id or refs[index] == "all:" .. id then table.remove(refs, index) end end
    end
    IC.Changed(); return true
end

function C.Copy(id, name)
    local source = C.Get(id); if not source then return end
    local copy = C.Create(name or (source.name .. " copy"), source.icon)
    copy.items = IC.Copy(C.Refs(id)); IC.Changed(); return copy
end
function C.SetIcon(id, icon)
    local collection = C.Get(id); if not collection then return false end
    if collection.dynamic then local actor = IC.Personas.Active(); if actor then actor.icon = icon end
    else collection.icon = icon end
    IC.Changed(); return true
end
