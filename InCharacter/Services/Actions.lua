local _, IC = ...
IC.Actions = {}
local A = IC.Actions
function A.Resolve(id)
    if IC.Emotes.byID[id] then return IC.Emotes.byID[id] end
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
            if (source == "all" or action.categories[source]) and IC.Emotes.Visible(action, profile) then result[#result + 1] = action end
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
        if type(DoEmote) ~= "function" then IC.Print("DoEmote is unavailable."); return false end
        local ok, err = pcall(DoEmote, known.payload)
        if not ok then IC.Print("Client blocked the emote: " .. tostring(err)) end
        return ok
    elseif action.type == "pool" then
        local pool = IC.Profile().pools[action.payload]
        if not pool or #pool.lines == 0 then IC.Print("This pool is empty. Add lines or install a library preset in /ic."); return false end
        if pool.channel ~= "SAY" and pool.channel ~= "YELL" and pool.channel ~= "EMOTE" then IC.Print("Invalid chat channel."); return false end
        local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
        if type(send) ~= "function" then IC.Print("Chat API is unavailable."); return false end
        local state = IC.Copy(IC.Dialogue.states[pool.id])
        local text = IC.Dialogue.Select(pool)
        if not text or IC.Trim(text) == "" then return false end
        -- Store unlimited quote lengths, but never split/truncate/spam the live channel.
        if #text > 255 or text:find("[%z\1-\31\127]") then
            IC.Dialogue.states[pool.id] = state
            IC.Print("Selected line cannot be sent (255 UTF-8 bytes maximum per message; no control characters). Edit or preview it in /ic.")
            return false
        end
        local ok, err = pcall(send, text, pool.channel)
        if not ok then
            IC.Dialogue.states[pool.id] = state
            IC.Print("Client blocked chat: " .. tostring(err) .. ". Nothing is queued for later.")
        end
        return ok
    end
    IC.Print("Unsupported action type.")
    return false
end
