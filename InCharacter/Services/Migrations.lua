local _, IC = ...
-- One-time upgrades to the clean 0.14 interface. Earlier versions generated lists the player
-- never made ("My wheel", "Wheel / Combat callouts", one copy per old bar). Unused ones move to
-- profile.retired.collections and every surface goes back to the built-in lists. A generated
-- list that the player's own lists or favorites point to is kept as an ordinary list. Pools,
-- lines, characters, favorites and the player's own lists are kept. Old bar layouts stay in the
-- save under layout.retired, unused. Nothing here runs twice.
IC.Migrations = {}
local M = IC.Migrations

-- Preset pools used to be named "<preset title> / <pool name>". The source belongs in
-- pool.provenance and tooltips, not in the name every surface shows.
-- Only the exact title of the pack the pool came from is removed, so a name the player typed
-- ("Jokes / Deadpan") is never touched.
function M.PoolName(pool)
    local pack = pool.provenance and IC.Library and IC.Library.packs[pool.provenance.pack]
    local prefix = pack and (pack.title .. " / ")
    if prefix and pool.name:sub(1, #prefix) == prefix and #pool.name > #prefix then pool.name = pool.name:sub(#prefix + 1) end
end

local function roleRef(profile, ref)
    local id = type(ref) == "string" and ref:match("^pool:(.+)$")
    if not id then return ref end
    for _, actor in pairs(profile.personas or {}) do
        for role, poolID in pairs(actor.roles or {}) do if poolID == id then return "role:" .. role end end
    end
    return ref
end
local function rewrite(profile, refs, removed)
    local result, seen = {}, {}
    for _, ref in ipairs(refs) do
        local target = type(ref) == "string" and ref:match("^%a+:(.+)$")
        local dropped = type(ref) == "string" and (ref:match("^set:") or ref:match("^all:")) and removed[target]
        ref = roleRef(profile, ref)
        if not dropped and not seen[ref] then result[#result + 1] = ref; seen[ref] = true end
    end
    return result
end

local function pointsAt(refs, id)
    for _, ref in ipairs(refs or {}) do if ref == "set:" .. id or ref == "all:" .. id then return true end end
end
function M.Profile(profile)
    if profile.cleanInterface then return end
    for _, pool in pairs(profile.pools) do M.PoolName(pool) end
    local removed, used = {}, {}
    for id, collection in pairs(profile.collections) do
        if collection.migrated then
            if pointsAt(profile.favorites, id) then used[id] = true end
            for _, other in pairs(profile.collections) do
                if not other.migrated and not other.builtin and pointsAt(other.items, id) then used[id] = true end
            end
        end
    end
    profile.retired = profile.retired or {}; profile.retired.collections = profile.retired.collections or {}
    for id, collection in pairs(profile.collections) do
        if collection.migrated and used[id] then collection.migrated = nil
        elseif collection.migrated then removed[id] = true; profile.retired.collections[id] = collection; profile.collections[id] = nil end
    end
    local order = {}
    for _, id in ipairs(profile.collectionOrder) do if not removed[id] then order[#order + 1] = id end end
    profile.collectionOrder = order
    -- Starter and preset pools pinned anywhere become the matching role of the loaded character.
    profile.favorites = rewrite(profile, profile.favorites, removed)
    for _, collection in pairs(profile.collections) do
        if collection.items then collection.items = rewrite(profile, collection.items, removed) end
    end
    for _, settings in ipairs({ profile.wheel, profile.menu }) do
        if not settings.root or not profile.collections[settings.root] and settings.root ~= "rp" then settings.root = "main" end
    end
    if profile.wheel.root == "main" then profile.wheel.root = "ring" end
    if (tonumber(profile.wheel.iconSize) or 0) < 32 then profile.wheel.iconSize = 40 end
    profile.shortcuts = {}
    profile.cleanInterface = 1
end

function M.Layout(layout)
    if layout.modeVersion then return end
    if layout.bars and #layout.bars > 0 then
        layout.retired = { bars = layout.bars, launcher = IC.Copy(layout.launcher or {}) }
    end
    local keep, visible
    for _, bar in ipairs(layout.bars or {}) do
        if not keep and bar.collection == "main" and not bar.automaticUpgradeBar then keep = bar end
        if not bar.hidden then visible = true end
    end
    local main = IC.Defaults.CollectionBar(1)
    if keep then for _, field in ipairs({ "x", "y", "size", "vertical", "labels", "perRow", "hidden", "locked" }) do if keep[field] ~= nil then main[field] = keep[field] end end end
    -- A player who had no bars, or hid them all, keeps a hidden bar instead of a new one popping up.
    if layout.bars and not visible then main.hidden = true end
    layout.bars, layout.mode, layout.stash, layout.modeVersion = { main }, "one", {}, 1
    if layout.launcher then layout.launcher.click, layout.launcher.rightClick, layout.launcher.middleClick = nil, nil, nil end
    for _, field in ipairs({ "preFoundation", "foundationVersion", "collectionBarIntroduced", "collectionUID" }) do layout[field] = nil end
end
