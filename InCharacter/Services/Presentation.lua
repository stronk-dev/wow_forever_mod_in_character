local _, IC = ...
IC.Presentation = {}
local P = IC.Presentation
function P.Filter(actions, config)
    local result = {}
    local hidden = config and config.hiddenActions or {}
    for _, action in ipairs(actions) do
        if not hidden[IC.Actions.CanonicalID(action.id)] and not (action.sourceID and hidden[action.sourceID]) then result[#result + 1] = action end
    end
    return result
end
function P.BarActions(config, raw)
    local actions = IC.Actions.List(config.source or "favorites", raw)
    if raw then return actions end
    actions = P.Filter(actions, config)
    local result = {}
    for _, action in ipairs(actions) do
        local pool = action.type == "pool" and IC.Profile().pools[action.payload]
        local group = pool and pool.provenance and pool.provenance.pack or "custom"
        if (not config.catalog or not config.catalogGroup or config.catalogGroup == "all" or config.catalogGroup == group)
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
                    if not config.catalogGroup or config.catalogGroup == "all" then
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
