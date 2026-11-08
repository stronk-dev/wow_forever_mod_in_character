local _, IC = ...
IC.Emotes = { list = {}, byID = {}, categories = { "Combat", "Reactions", "Social", "Idle", "Voice/Fun" } }
local categories = {
    Combat = { "oom", "healme", "helpme", "charge", "flee", "incoming" },
    Social = { "wave", "bow", "salute", "hug", "flirt", "bye" },
    Reactions = { "laugh", "cry", "angry", "cheer", "applaud", "chicken" },
    Idle = { "sit", "sleep", "dance", "flex", "kneel" },
    ["Voice/Fun"] = { "train", "joke", "silly", "roar", "chicken" },
}
for _, category in ipairs(IC.Emotes.categories) do
    for _, command in ipairs(categories[category]) do
        local id = "emote:" .. command
        local action = IC.Emotes.byID[id]
        if not action then
            action = { id = id, type = "emote", label = "/" .. command, payload = command:upper(),
                command = command, icon = IC.Icons[4], categories = {}, verified = false }
            IC.Emotes.byID[id] = action
            table.insert(IC.Emotes.list, action)
        end
        action.categories[category] = true
    end
end

function IC.Emotes.Validate()
    local tokens, aliases = {}, {}
    for index = 1, 1000 do
        local token = _G["EMOTE" .. index .. "_TOKEN"]
        if type(token) == "string" then
            tokens[token:upper()] = true
            for n = 1, 4 do
                local alias = _G["EMOTE" .. index .. "_CMD" .. n]
                if type(alias) == "string" then aliases[alias:lower():gsub("^/", "")] = token end
            end
        end
    end
    for _, emote in ipairs(IC.Emotes.list) do
        -- /joke is commonly an alias for the SILLY token; use client data when present.
        emote.payload = aliases[emote.command] or (emote.command == "joke" and "SILLY" or emote.command:upper())
        emote.verified = tokens[emote.payload:upper()] == true
        -- Token presence establishes recognition only. Animation/audio remain unknown.
    end
end

function IC.Emotes.Visible(action, profile)
    if profile.hideUnverified and not action.verified then return false end
    local filter = profile.emoteFilter
    if filter == "animated" then return action.animated == true end
    if filter == "audible" then return action.audible == true end
    if filter == "text" then return action.textOnly == true end
    return true
end
