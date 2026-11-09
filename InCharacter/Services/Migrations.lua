local _, IC = ...
-- Pure conversion of legacy presentation choices into explicit, editable collection lists.
-- No runtime validation: unavailable emotes and other actors' pools must survive migration.
IC.Migrations = {}
local M = IC.Migrations
local function put(profile, id, name, refs, icon)
    if not profile.collections[id] then
        profile.collections[id] = { id = id, name = name, items = refs, icon = icon or IC.Icons[1], migrated = true }
        profile.collectionOrder[#profile.collectionOrder + 1] = id
    end
    return id
end
local function poolFor(profile, ref)
    local id = ref:match('^pool:(.+)$') or ref:match('^play:%a+:(.+)$') or ref:match('^line:(.*):[^:]+$')
    return id and profile.pools[id]
end
function M.Items(profile, config, presentation, observations)
    local source, refs = config.source or 'favorites', {}
    local function emotes(list) for _, action in ipairs(list or {}) do refs[#refs + 1] = action.id end end
    if source == 'favorites' or source == 'favoriteEmotes' then
        for _, ref in ipairs(profile.favorites) do if source ~= 'favoriteEmotes' or IC.Emotes.byID[ref] then refs[#refs + 1] = ref end end
    elseif source == 'categories' then
        for _, id in ipairs(IC.Emotes.categories) do if config.categories and config.categories[id] then emotes(IC.Emotes.byCategory[id]) end end
    elseif source == 'all' then emotes(IC.Emotes.list)
    elseif IC.Emotes.byCategory[source] then emotes(IC.Emotes.byCategory[source])
    elseif source == 'pools' then for _, id in ipairs(profile.poolOrder) do refs[#refs + 1] = 'pool:' .. id end
    elseif source:match('^lines:') then
        local pool = profile.pools[source:sub(7)]
        if pool then for _, id in ipairs(pool.lineIDs) do refs[#refs + 1] = 'line:' .. pool.id .. ':' .. id end end
    elseif poolFor(profile, source) or IC.Emotes.byID[source] then refs[1] = source end
    local result, used = {}, {}
    for _, original in ipairs(refs) do
        local ref = IC.Actions.CanonicalID(original)
        local emote, pool = IC.Emotes.byID[ref], poolFor(profile, ref)
        local primitive = emote and 'emotes' or 'roleplay'
        local enabled = not profile.presentations or not profile.presentations[primitive] or profile.presentations[primitive][presentation] ~= false
        local hidden = config.hiddenActions or {}
        local included = not emote or (config.includedActions and config.includedActions[ref]) or config.emoteView == 'all'
            or (config.emoteView == 'kept' and IC.Curation.Record(ref, profile).choice == 'keep')
            or ((not config.emoteView or config.emoteView == 'profile') and
                ((profile.presentations and profile.presentations.emotes and profile.presentations.emotes.view == 'all') or IC.Curation.Included(emote, profile)))
        if emote and not (config.includedActions and config.includedActions[ref]) and config.emoteView ~= 'all' and config.emoteView ~= 'kept'
            and not (profile.presentations and profile.presentations.emotes and profile.presentations.emotes.view == 'all') then
            local seen, filter = (observations or {})[ref] or {}, profile.emoteFilter
            if filter == 'heard' then included = included and (seen.sound == 'self' or seen.sound == 'nearby')
            elseif filter == 'observed' then included = included and seen.animation == 'yes'
            elseif filter == 'textChecked' then included = included and seen.sound == 'silent' and seen.animation == 'no' end
        end
        local pack = pool and pool.provenance and pool.provenance.pack or 'custom'
        if enabled and included and not hidden[ref] and not hidden[original]
            and not (pool and (hidden['browse:' .. pool.id] or hidden['group:' .. pack]))
            and not (config.hideEmpty and pool and #pool.lines == 0)
            and (not config.catalog or not config.catalogGroup or config.catalogGroup == 'all' or config.catalogGroup == pack) then
            if pool and ref:match('^pool:') and config.poolMode and config.poolMode ~= 'pool' then ref = 'play:' .. config.poolMode .. ':' .. pool.id end
            if not used[ref] then result[#result + 1] = ref; used[ref] = true end
        end
    end
    return result
end
function M.Profile(profile, hadCollections, observations, legacyPresentation)
    if profile.foundationLists then return end
    if not hadCollections and legacyPresentation then
        for _, surface in ipairs({ 'wheel', 'menu' }) do
            local settings = profile[surface]
            local root, hidden = {}, settings.hiddenCategories or {}
            for _, source in ipairs({ 'favorites', 'Combat', 'Social', 'Reactions', 'Idle', 'Voice/Fun', 'pools' }) do
                local category = source == 'favorites' and 'Favorites' or source == 'pools' and 'Roleplay' or source
                if not hidden[category] then
                    local cfg = IC.Copy(settings); cfg.source = source
                    local id = put(profile, 'legacy-' .. surface .. '-' .. source, (surface == 'wheel' and 'Wheel / ' or 'Menu / ') .. (IC.Emotes.CategoryInfo[category] or {}).label, M.Items(profile, cfg, surface, observations), (IC.Emotes.CategoryInfo[category] or {}).icon)
                    root[#root + 1] = 'set:' .. id
                end
            end
            settings.root = put(profile, 'legacy-' .. surface, 'My ' .. surface, root, IC.AddonIcon)
        end
    end
    profile.foundationLists = true
end
function M.Layout(layout, profiles, db, observations)
    if layout.foundationVersion then
        for _, bar in ipairs(layout.bars or {}) do
            if bar.source and bar.collection and bar.collection:match('^layout%-') then
                for _, profile in ipairs(profiles) do
                    if not profile.collections[bar.collection] then put(profile, bar.collection, bar.name, M.Items(profile, bar, 'bar', observations)) end
                end
            end
        end
        return
    end
    layout.preFoundation = IC.Copy(layout)
    db.nextLayoutID = math.max(db.nextLayoutID or 0, tonumber(layout.collectionUID) or 0) + 1
    layout.collectionUID = layout.collectionUID or tostring(db.nextLayoutID)
    local upgraded = false
    for _, bar in ipairs(layout.bars or {}) do if bar.hiddenByUpgrade then upgraded = true end end
    for index, bar in ipairs(layout.bars or {}) do
        if bar.source then
            local id = 'layout-' .. layout.collectionUID .. '-bar-' .. index
            for _, profile in ipairs(profiles) do
                put(profile, id, bar.name or ('Bar ' .. index), M.Items(profile, bar, 'bar', observations))
            end
            bar.collection = id
            if bar.hiddenByUpgrade then bar.hidden = false end
            bar.perRow = bar.perRow or (bar.vertical and bar.rows or bar.columns) or 0
            bar.fitWidth = bar.fitWidth or (bar.strip and bar.stripWidth) or nil
            bar.fitHeight = bar.fitHeight or (bar.strip and bar.stripHeight) or nil
        elseif upgraded and bar.collection == 'main' and bar.name == 'Main bar' and bar.size == 28 and bar.x == 0 and bar.y == -330 then
            -- Undo only the untouched automatic extra bar introduced by 0.12. Keep it recoverable.
            bar.hidden = true; bar.automaticUpgradeBar = true
        end
    end
    layout.foundationVersion = 1
end
