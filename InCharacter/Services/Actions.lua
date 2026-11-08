local _, IC = ...
IC.Actions = {}
local A = IC.Actions
local function readBoolean(fn, ...)
    local ok, value = pcall(fn, ...)
    if not ok or (issecretvalue and issecretvalue(value)) or type(value) ~= "boolean" then return nil end
    return value
end

function A.ChatAllowed()
    local checks = {}
    if C_ChatInfo and type(C_ChatInfo.InChatMessagingLockdown) == "function" then
        checks[#checks + 1] = { fn = C_ChatInfo.InChatMessagingLockdown, blocked = true, reason = "Client chat messaging lockdown is active." }
    end
    local chat = Enum and Enum.AddOnRestrictionType and Enum.AddOnRestrictionType.Chat
    if chat ~= nil and C_RestrictedActions and type(C_RestrictedActions.IsAddOnRestrictionActive) == "function" then
        checks[#checks + 1] = { fn = C_RestrictedActions.IsAddOnRestrictionActive, argument = chat, blocked = true, reason = "Client addon chat restriction is active." }
    end
    if C_SocialRestrictions and type(C_SocialRestrictions.CanSendChat) == "function" then
        checks[#checks + 1] = { fn = C_SocialRestrictions.CanSendChat, blocked = false, reason = "Your account cannot send chat right now." }
    end
    for _, check in ipairs(checks) do
        local value
        if check.argument ~= nil then value = readBoolean(check.fn, check.argument) else value = readBoolean(check.fn) end
        if value == nil then return false, "Cannot establish current chat permissions; no message sent." end
        if value == check.blocked then return false, check.reason end
    end
    return true
end

function A.ChatText(text)
    -- Treat every quote as literal text, including WoW color/link/texture escapes.
    return (text:gsub("|", "||"))
end
function A.Resolve(id)
    if IC.Emotes.byID[id] then
        local action = IC.Copy(IC.Emotes.byID[id])
        local override = IC.Profile().emoteOverrides[id]
        if override then action.label = override.label or action.label; action.icon = override.icon or action.icon end
        return action
    end
    local poolID = type(id) == "string" and id:match("^pool:(.+)$")
    local pool = poolID and IC.Profile().pools[poolID]
    if pool then return { id = id, type = "pool", label = pool.name, icon = pool.icon, payload = poolID } end
end
function A.IsFavorite(id)
    for _, favorite in ipairs(IC.Profile().favorites) do if favorite == id then return true end end
    return false
end
function A.Favorite(id)
    local favorites = IC.Profile().favorites
    for i, favorite in ipairs(favorites) do
        if favorite == id then table.remove(favorites, i); IC.Changed(); return end
    end
    if A.Resolve(id) then favorites[#favorites + 1] = id; IC.Changed() end
end
function A.List(source)
    local result, profile = {}, IC.Profile()
    if source == "favorites" then
        for _, id in ipairs(profile.favorites) do
            local action = A.Resolve(id)
            if action and (action.type ~= "emote" or IC.Emotes.Visible(action, profile)) then result[#result + 1] = action end
        end
    elseif source == "pools" then
        for _, id in ipairs(profile.poolOrder) do
            local action = A.Resolve("pool:" .. id)
            if action then result[#result + 1] = action end
        end
    elseif source:match("^pool:") then
        local action = A.Resolve(source)
        if action then result[1] = action end
    else
        for _, action in ipairs(IC.Emotes.list) do
            if (source == "all" or action.categories[source]) and IC.Emotes.Visible(action, profile) then result[#result + 1] = A.Resolve(action.id) end
        end
    end
    return result
end

-- Only UI clicks, bindings and slash handlers call this. No event/timer calls it.
function A.Dispatch(action)
    if type(action) == "string" then action = A.Resolve(action) end
    if not action then return false, "Unknown action." end
    if action.type == "emote" then
        local known = IC.Emotes.byID[action.id]
        if not known then IC.Print("Unknown emote."); return false end
        if not known.verified then IC.Print(known.label .. " is unverified on this client; try it manually first."); return false end
        local modern = C_ChatInfo and type(C_ChatInfo.PerformEmote) == "function"
        local perform = modern and C_ChatInfo.PerformEmote or DoEmote
        if type(perform) ~= "function" then IC.Print("Emote API is unavailable."); return false end
        local ok, result = pcall(perform, known.payload)
        if not ok then IC.Print("Client blocked the emote: " .. tostring(result)); return false end
        if issecretvalue and issecretvalue(result) then IC.Print("Client did not expose the emote result."); return false end
        -- PerformEmote returns success; legacy DoEmote reports whether it was restricted.
        if (modern and result ~= true) or (not modern and result == true) then
            IC.Print("Client declined the emote."); return false
        end
        return true
    elseif action.type == "pool" then
        local pool = IC.Profile().pools[action.payload]
        if not pool or #pool.lines == 0 then IC.Print("This pool is empty. Add lines or install a library preset in /ic."); return false end
        if pool.channel ~= "SAY" and pool.channel ~= "YELL" and pool.channel ~= "EMOTE" then IC.Print("Invalid chat channel."); return false end
        local allowed, reason = A.ChatAllowed()
        if not allowed then IC.Print(reason .. " Selection unchanged; nothing queued."); return false end
        local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
        if type(send) ~= "function" then IC.Print("Chat API is unavailable."); return false end
        local state = IC.Copy(IC.Dialogue.states[pool.id])
        local text = IC.Dialogue.Select(pool)
        if not text or IC.Trim(text) == "" then IC.Dialogue.states[pool.id] = state; return false end
        text = A.ChatText(text)
        -- Store unlimited quote lengths, but never split/truncate/spam the live channel.
        if #text > 255 or text:find("[%z\1-\31\127]") then
            IC.Dialogue.states[pool.id] = state
            IC.Print("Selected line cannot be sent (255 UTF-8 bytes maximum per message; no control characters). Edit or preview it in /ic.")
            return false
        end
        local ok, result = pcall(send, text, pool.channel)
        if not ok or result == false then
            IC.Dialogue.states[pool.id] = state
            IC.Print(ok and "Client declined chat. Nothing is queued for later." or ("Client blocked chat: " .. tostring(result) .. ". Nothing is queued for later."))
            return false
        end
        return true
    end
    IC.Print("Unsupported action type.")
    return false
end
