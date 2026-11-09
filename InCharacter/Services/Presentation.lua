local _, IC = ...
IC.Presentation = {}
local P = IC.Presentation
function P.Enabled(primitive, presentation)
    local settings = IC.Profile().presentations
    return not settings or not settings[primitive] or settings[primitive][presentation] ~= false
end
function P.BarEmoteIncluded(action, config)
    if action.type ~= "emote" then return true end
    if action.verified and config.includedActions and config.includedActions[action.id] then return true end
    if config.emoteView == "all" then return action.verified end
    if config.emoteView == "kept" then return action.verified and IC.Curation.Record(action.id).choice == "keep" end
    return IC.Actions.EmoteVisible(action)
end
function P.Filter(actions, config)
    local result = {}
    local hidden = config and config.hiddenActions or {}
    for _, action in ipairs(actions) do
        local primitiveAllowed = not config or not config.presentation or action.type == "submenu" or P.Enabled(action.type == "emote" and "emotes" or "roleplay", config.presentation)
        if primitiveAllowed and (not IC.Personas or IC.Personas.ActionAllowed(action)) and not hidden[IC.Actions.CanonicalID(action.id)] and not (action.sourceID and hidden[action.sourceID]) then result[#result + 1] = action end
    end
    return result
end
function P.BarActions(config, raw)
    local actions
    if config.source == "categories" then
        actions = {}; local seen = {}
        for _, id in ipairs(IC.Emotes.categories) do
            if config.categories and config.categories[id] then
                for _, action in ipairs(IC.Actions.List(id, true)) do
                    local key = action.payload or action.id
                    if not seen[key] then actions[#actions + 1] = action; seen[key] = true end
                end
            end
        end
    else actions = IC.Actions.List(config.source or "favorites", true) end
    if raw then return actions end
    actions = P.Filter(actions, config)
    local result = {}
    for _, action in ipairs(actions) do
        local pool = action.type == "pool" and IC.Profile().pools[action.payload]
        local group = pool and pool.provenance and pool.provenance.pack or "custom"
        if P.Enabled(action.type == "emote" and "emotes" or "roleplay", "bar") and P.BarEmoteIncluded(action, config) and (not config.catalog or not config.catalogGroup or config.catalogGroup == "all" or config.catalogGroup == group)
            and (not config.hideEmpty or not pool or #pool.lines > 0) then
            if pool and config.poolMode and config.poolMode ~= "pool" then
                local override = IC.Actions.Resolve("play:" .. config.poolMode .. ":" .. pool.id)
                if override then override.sourceID, override.label, override.name = action.id, pool.name, pool.name; action = override end
            end
            if config.catalog and pool and pool.provenance then
                local pack = IC.Library and IC.Library.packs[pool.provenance.pack]
                local prefix = pack and (pack.title .. " / ")
                if prefix and pool.name:sub(1, #prefix) == prefix then
                    local label = pool.name:sub(#prefix + 1)
                    if not IC.Personas and (not config.catalogGroup or config.catalogGroup == "all") then
                        label = (pack.title:match(":%s*(.+)$") or pack.title) .. " · " .. label
                    end
                    action = IC.Copy(action); action.label, action.name, action.fullName = label, label, pool.name
                end
            end
            result[#result + 1] = action
        end
    end
    return P.Filter(result, config)
end
-- Pure geometry. Keep a readable minimum; overflow pages instead of shrinking indefinitely.
function P.StripGeometry(config, count, screenWidth)
    local gap, padding, minimum = 2, 1, 12
    local width = math.max(80, math.min(tonumber(config.stripWidth) or 388, math.max(80, (screenWidth or 1920) - 56)))
    local rows = math.max(1, math.min(4, math.floor(tonumber(config.stripRows) or 1)))
    local maximum = math.max(minimum, math.min(64, tonumber(config.size) or 36))
    local fixedHeight = tonumber(config.stripHeight)
    if fixedHeight then
        fixedHeight = math.max(config.labels and 28 or 14, math.min(500, fixedHeight))
        maximum = math.min(maximum, fixedHeight - 2 * padding - (config.labels and 14 or 0))
        rows = math.max(1, math.min(4, math.floor((fixedHeight - 2 * padding + gap) / (maximum + gap + (config.labels and 14 or 0)))))
    end
    local limit = math.min(48, math.floor((width - 2 * padding + gap) / (minimum + gap)) * rows)
    local controls = count > limit and 48 or 0
    local available = width - 2 * padding - controls
    local perRow = math.max(1, math.ceil(math.min(count, 48) / rows))
    local size = math.max(minimum, math.min(maximum, math.floor((available + gap) / perRow) - gap))
    local columns = math.max(1, math.floor((available + gap) / (size + gap)))
    local capacity = math.min(48, columns * rows)
    local cellHeight = size + gap + (config.labels and 14 or 0)
    local countShown = math.min(count, capacity)
    local usedColumns = math.min(columns, countShown)
    local usedRows = countShown > 0 and math.ceil(countShown / columns) or 0
    return { width = width, size = size, columns = columns, rows = rows, capacity = capacity, gap = gap, padding = padding,
        contentWidth = padding * 2 + math.max(0, usedColumns * (size + gap) - gap) + controls,
        contentHeight = padding * 2 + math.max(0, usedRows * cellHeight - gap),
        height = fixedHeight or (padding * 2 + rows * cellHeight - gap), cellHeight = cellHeight, controls = controls }
end
function P.CatalogGroups(config)
    local groups, byID = {}, {}
    for _, action in ipairs(P.Filter(IC.Actions.List("pools"), config)) do
        local pool = IC.Profile().pools[action.payload]
        if not config.hideEmpty or #pool.lines > 0 then
            local id = pool.provenance and pool.provenance.pack or "custom"
            if not byID[id] then
                local pack = IC.Library and IC.Library.packs[id]
                local title = pack and pack.title or (id == "custom" and "My lines" or id)
                byID[id] = { id = id, title = title, label = title:match(":%s*(.+)$") or title, count = 0 }
                groups[#groups + 1] = byID[id]
            end
            byID[id].count = byID[id].count + 1
        end
    end
    return groups
end
function P.Tree(nodes, config)
    local result = {}
    for _, node in ipairs(P.Filter(nodes, config)) do
        local copy = IC.Copy(node)
        if copy.type == "submenu" then
            copy.children = P.Tree(copy.children or copy.items or {}, config); copy.items = copy.children
            if #copy.children > 0 then result[#result + 1] = copy end
        else result[#result + 1] = copy end
    end
    return result
end
local subgroups = {
    Combat = {
        { "orders", "Orders & movement", "charge attacktarget openfire followme wait" },
        { "help", "Help & warnings", "helpme healme oom incoming flee" },
        { "battle", "Battle reactions", "threaten cower victory" },
    },
    Social = {
        { "greetings", "Greetings & farewells", "wave hello bye beckon welcome" },
        { "manners", "Respect & thanks", "bow salute curtsey thank congratulate nod no apologize highfive" },
        { "affection", "Affection", "kiss flirt hug" },
    },
    Reactions = {
        { "happy", "Laughter & celebration", "laugh cheer applaud rofl giggle gloat golfclap" },
        { "upset", "Upset & confrontational", "cry angry sigh mourn taunt rude beg" },
        { "surprised", "Surprise & confusion", "gasp shrug facepalm boggle blush oops confused whoa" },
    },
    Idle = {
        { "poses", "Poses & rest", "sit stand sleep lay laydown kneel lean shy bashful" },
        { "activities", "Activities", "dance flex point pray talk read eat drink" },
        { "thinking", "Thinking", "ponder think" },
    },
    ["Voice/Fun"] = {
        { "animals", "Animal sounds", "chicken roar moo" },
        { "fun", "Jokes & music", "train silly cackle guffaw rasp violin" },
        { "cheers", "Cheers & calls", "forthealliance forthehorde cheer laugh kiss" },
    },
}
function P.EmoteGroups(id, actions, force)
    if #actions <= 8 and not force then return actions end
    local result, used = {}, {}
    for _, definition in ipairs(subgroups[id] or {}) do
        local members = {}; for command in definition[3]:gmatch("%S+") do members[command] = true end
        local children = {}
        for _, action in ipairs(actions) do if members[action.command] then children[#children + 1] = action; used[action.id] = true end end
        if #children > 0 then result[#result + 1] = { id = "section:" .. id .. ":" .. definition[1], type = "submenu", label = definition[2], icon = children[1].icon, children = children } end
    end
    local other = {}; for _, action in ipairs(actions) do if not used[action.id] then other[#other + 1] = action end end
    if #result == 0 then return other end
    if #other > 0 then result[#result + 1] = { id = "section:" .. id .. ":other", type = "submenu", label = "More gestures", icon = other[1].icon, children = other } end
    return result
end
function P.Alphabetical(actions, chunk)
    local result = {}; chunk = chunk or 12
    for first = 1, #actions, chunk do
        local last = math.min(#actions, first + chunk - 1)
        local children = {}; for i = first, last do children[#children + 1] = actions[i] end
        result[#result + 1] = { id = "alphabet:" .. first, type = "submenu", label = "/" .. actions[first].command .. " – /" .. actions[last].command, icon = actions[first].icon, children = children }
    end
    return result
end
