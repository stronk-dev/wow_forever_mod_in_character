local _, IC = ...
IC.Presentation = {}
local P = IC.Presentation
function P.Filter(actions, config)
    local result = {}
    local hidden = config and config.hiddenActions or {}
    for _, action in ipairs(actions) do
        if not hidden[IC.Actions.CanonicalID(action.id)] then result[#result + 1] = action end
    end
    return result
end
function P.BarActions(config, raw)
    local actions = IC.Actions.List(config.source or "favorites", raw)
    return raw and actions or P.Filter(actions, config)
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
