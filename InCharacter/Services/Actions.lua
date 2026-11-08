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
function A.CanonicalID(id)
    local emote = IC.Emotes.byID[id]
    return emote and emote.id or id
end
function A.Description(action)
    if action.type == "emote" then return "/" .. action.command .. " — " .. (action.verified and "recognized by this client" or "unrecognized") end
    local pool = IC.Profile().pools[action.payload]
    if not pool then return "Removed pool" end
    if action.type == "line" then
        local text = IC.Dialogue.Line(pool, action.lineID)
        return pool.channel .. " · specific message · " .. pool.name .. (text and ("\n" .. IC.DisplayText(text)) or "\nMessage removed")
    end
    return pool.channel .. " · " .. (action.selectionMode or pool.mode) .. " · " .. pool.name
end
function A.Resolve(id)
    if IC.Emotes.byID[id] then
        local action = IC.Copy(IC.Emotes.byID[id])
        local override = IC.Profile().emoteOverrides[id]
        if override then action.label = override.label or action.label; action.name = override.label or action.name; action.icon = override.icon or action.icon end
        return action
    end
    if type(id) ~= "string" then return nil end
    local linePool, lineID = id:match("^line:(.*):([^:]+)$")
    if linePool then
        local pool = IC.Profile().pools[linePool]
        local text = pool and IC.Dialogue.Line(pool, lineID)
        if text then return { id = id, type = "line", payload = linePool, lineID = lineID,
            label = IC.DisplayText(IC.ShortText(text, 72)), icon = pool.lineIcons and pool.lineIcons[lineID] or pool.icon } end
        return nil
    end
    local mode, playPool = id:match("^play:(%a+):(.+)$")
    if mode and (mode == "random" or mode == "shuffle" or mode == "sequential") then
        local pool = IC.Profile().pools[playPool]
        if pool then return { id = id, type = "pool", payload = playPool, selectionMode = mode,
            label = pool.name .. " (" .. mode .. ")", icon = pool.icon } end
        return nil
    end
    local poolID = type(id) == "string" and id:match("^pool:(.+)$")
    local pool = poolID and IC.Profile().pools[poolID]
    if pool then return { id = id, type = "pool", label = pool.name, icon = pool.icon, payload = poolID } end
end
function A.SetIcon(id, icon)
    local action = A.Resolve(id)
    if not action then return false end
    if icon ~= nil and type(icon) ~= "string" and type(icon) ~= "number" then return false end
    local profile = IC.Profile()
    if action.type == "emote" then
        profile.emoteOverrides[action.id] = profile.emoteOverrides[action.id] or {}
        profile.emoteOverrides[action.id].icon = icon
    elseif action.type == "line" then
        local pool = profile.pools[action.payload]; pool.lineIcons = pool.lineIcons or {}; pool.lineIcons[action.lineID] = icon
    elseif action.type == "pool" then profile.pools[action.payload].icon = icon or IC.Icons[1]
    else return false end
    IC.Changed(); return true
end
function A.IsFavorite(id)
    id = A.CanonicalID(id)
    for _, favorite in ipairs(IC.Profile().favorites) do if A.CanonicalID(favorite) == id then return true end end
    return false
end
function A.Favorite(id)
    id = A.CanonicalID(id)
    local favorites = IC.Profile().favorites
    local removed
    for i = #favorites, 1, -1 do
        if A.CanonicalID(favorites[i]) == id then table.remove(favorites, i); removed = true end
    end
    if removed then IC.Changed(); return end
    if A.Resolve(id) then favorites[#favorites + 1] = id; IC.Changed() end
end
function A.MoveFavorite(id, delta)
    local favorites = IC.Profile().favorites; id = A.CanonicalID(id)
    for index, value in ipairs(favorites) do
        if A.CanonicalID(value) == id then
            local target = index + delta
            if target >= 1 and target <= #favorites then favorites[index], favorites[target] = favorites[target], favorites[index]; IC.Changed() end
            return
        end
    end
end
function A.Lines(pool)
    IC.Dialogue.EnsureLines(pool)
    local result = {}
    for index, lineID in ipairs(pool.lineIDs) do
        result[#result + 1] = { id = "line:" .. pool.id .. ":" .. lineID, type = "line", payload = pool.id,
            lineID = lineID, label = IC.DisplayText(IC.ShortText(pool.lines[index], 72)), icon = pool.lineIcons and pool.lineIcons[lineID] or pool.icon }
    end
    return result
end
function A.PoolNode(pool)
    local nextAction = A.Resolve("pool:" .. pool.id); nextAction.name = "Play next (" .. pool.mode .. ")"
    local children = { nextAction }
    for _, mode in ipairs({ "random", "shuffle", "sequential" }) do
        local action = A.Resolve("play:" .. mode .. ":" .. pool.id)
        action.name = ({ random = "Random message", shuffle = "Shuffle next", sequential = "In order next" })[mode]
        children[#children + 1] = action
    end
    children[#children + 1] = { id = "messages:" .. pool.id, type = "submenu", label = "Choose a specific message", icon = pool.icon, children = A.Lines(pool) }
    return { id = "browse:" .. pool.id, type = "submenu", label = pool.name, icon = pool.icon, children = children }
end
function A.RoleplayGroups()
    local result, groups = {}, {}
    for _, id in ipairs(IC.Profile().poolOrder) do
        local pool = IC.Profile().pools[id]
        local pack = pool.provenance and IC.Library.packs[pool.provenance.pack]
        local key = pack and pack.id or "custom"
        if not groups[key] then
            groups[key] = { id = "group:" .. key, type = "submenu", label = pack and pack.title or "My dialogue", icon = pool.icon, children = {} }
            result[#result + 1] = groups[key]
        end
        table.insert(groups[key].children, A.PoolNode(pool))
    end
    return result
end
function A.List(source, raw)
    source = source or "favorites"
    local result, profile = {}, IC.Profile()
    if source == "favorites" then
        for _, id in ipairs(profile.favorites) do
            local action = A.Resolve(id)
            if action and (raw or action.type ~= "emote" or IC.Emotes.Visible(action, profile)) then result[#result + 1] = action end
        end
    elseif source == "pools" then
        for _, id in ipairs(profile.poolOrder) do
            local action = A.Resolve("pool:" .. id)
            if action then result[#result + 1] = action end
        end
    elseif source:match("^lines:") then
        local pool = profile.pools[source:sub(7)]
        if pool then return A.Lines(pool) end
    elseif source:match("^pool:") or source:match("^line:") or source:match("^play:") then
        local action = A.Resolve(source)
        if action then result[1] = action end
    else
        local emotes = source == "all" and IC.Emotes.list or IC.Emotes.byCategory[source] or {}
        for _, action in ipairs(emotes) do
            if raw or IC.Emotes.Visible(action, profile) then result[#result + 1] = A.Resolve(action.id) end
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
        if not known.verified then IC.Print(known.label .. " is not recognized by this client."); return false end
        -- Follow Charades' Forever path: pass the client's token to DoEmote.
        -- Only use the namespaced API if that entry point does not exist.
        local perform = type(DoEmote) == "function" and DoEmote
            or (C_ChatInfo and C_ChatInfo.PerformEmote)
        if type(perform) ~= "function" then IC.Print("Emote API is unavailable."); return false end
        local ok, result = pcall(perform, known.payload)
        if not ok then IC.Print("Client blocked the emote: " .. tostring(result)); return false end
        -- Charades does not infer acceptance from this return. Forever's actual
        -- chat handler calls it "restricted", while generated docs call it
        -- "success". Do not invent a rejection or retry the action. A successful
        -- Lua call establishes submission only, not an observed animation.
        return true
    elseif action.type == "pool" or action.type == "line" then
        local pool = IC.Profile().pools[action.payload]
        if not pool or #pool.lines == 0 then IC.Print("This pool is empty. Add lines or install a library preset in /ic."); return false end
        if pool.channel ~= "SAY" and pool.channel ~= "YELL" and pool.channel ~= "EMOTE" then IC.Print("Invalid chat channel."); return false end
        local allowed, reason = A.ChatAllowed()
        if not allowed then IC.Print(reason .. " Selection unchanged; nothing queued."); return false, reason end
        local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
        if type(send) ~= "function" then IC.Print("Chat API is unavailable."); return false end
        if action.selectionMode and action.selectionMode ~= "random" and action.selectionMode ~= "shuffle" and action.selectionMode ~= "sequential" then IC.Print("Invalid selection mode."); return false end
        local key = IC.Dialogue.StateKey(pool, action.selectionMode)
        local state = IC.Copy(IC.Dialogue.states[key])
        local text
        if action.type == "line" then text = IC.Dialogue.Line(pool, action.lineID)
        else text = IC.Dialogue.Select(pool, action.selectionMode) end
        if not text or IC.Trim(text) == "" then IC.Dialogue.states[key] = state; IC.Print("This message is no longer available."); return false end
        text = A.ChatText(text)
        -- Store unlimited quote lengths, but never split/truncate/spam the live channel.
        if #text > 255 or text:find("[%z\1-\31\127]") then
            IC.Dialogue.states[key] = state
            IC.Print("Selected line cannot be sent (255 UTF-8 bytes maximum per message; no control characters). Edit or preview it in /ic.")
            return false
        end
        local ok, result = pcall(send, text, pool.channel)
        if not ok or result == false then
            IC.Dialogue.states[key] = state
            IC.Print(ok and "Client declined chat. Nothing is queued for later." or ("Client blocked chat: " .. tostring(result) .. ". Nothing is queued for later."))
            return false
        end
        return true
    end
    IC.Print("Unsupported action type.")
    return false
end
