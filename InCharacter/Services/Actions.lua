local _, IC = ...
IC.Actions = {}
local A = IC.Actions
function A.ChatAllowed() return IC.Platform.ChatAllowed() end

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
-- Character-facing nodes: a role slot of the loaded character, the character switcher, a character.
local function roleNode(role)
    local info = IC.Personas.Slot(role)
    if not info then return nil end
    local poolID, from = IC.Personas.RolePool(role)
    local pool = poolID and IC.Profile().pools[poolID]
    return { id = "role:" .. role, type = "pool", role = role, payload = poolID, name = info.label, label = info.label, shared = from == "shared",
        icon = pool and pool.icon or IC.Defaults.Pool(role, info.label).icon, empty = not pool or #pool.lines == 0 }
end
local function personaNode(value)
    for _, option in ipairs(IC.Personas.Options(true)) do
        if option.value == value then
            local actor = IC.Profile().personas[value]
            local pack = IC.Library and IC.Library.packs[(value:match("^preset:(.+)$")) or (actor and actor.pack) or ""]
            return { id = "persona:" .. value, type = "persona", payload = value, name = option.label, label = option.label,
                icon = actor and actor.icon or (pack and pack.icon) or IC.AddonIcon, active = IC.Personas.Active() == actor and actor ~= nil }
        end
    end
end
function A.Resolve(id)
    if type(id) == "string" then
        local role = id:match("^role:(.+)$")
        if role then return roleNode(role) end
        if id == "character" then
            local actor = IC.Personas.Active()
            return { id = "character", type = "character", name = IC.Personas.Name(), label = IC.Personas.Name(),
                icon = actor and actor.icon or IC.AddonIcon }
        end
        local persona = id:match("^persona:(.+)$")
        if persona then return personaNode(persona) end
    end
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
-- Resolved actions for slash commands and favorite key bindings. Surfaces use IC.Collections.
function A.List(source)
    local result = {}
    if source == "favorites" or source == nil then
        for _, node in ipairs(IC.Collections.Nodes("favorites")) do result[#result + 1] = node end
    elseif source:match("^lines:") then
        local pool = IC.Profile().pools[source:sub(7)]
        if pool then result = A.Lines(pool) end
    end
    return result
end

-- A slot node may have been drawn for the previous character (bars cannot rebuild in combat).
-- Clicks, child lists and tooltips all use this, so a slot always means the loaded character.
function A.Current(node)
    return type(node) == "table" and node.role and A.Resolve("role:" .. node.role) or node
end
-- Only UI clicks, bindings and slash handlers call this. No event/timer calls it.
function A.Dispatch(action)
    if IC.Bars and IC.Bars.editing then return false, "Finish editing layouts before playing an action." end
    if type(action) == "string" then action = A.Resolve(action) end
    -- A role button may have been drawn for the previous character (bars cannot rebuild in
    -- combat); the role always means the character loaded now.
    action = A.Current(action)
    if not action then return false, "Unknown action." end
    if action.type == "emote" then
        local known = IC.Emotes.byID[action.id]
        if not known then IC.Print("Unknown emote."); return false end
        if not known.verified then IC.Print(known.label .. " is not recognized by this client."); return false end
        local ok, reason = IC.Platform.Emote(known.payload)
        if not ok then IC.Print(reason) end
        return ok, reason
    elseif action.type == "persona" then
        local ok, problem = IC.Personas.Choose(action.payload)
        if ok then IC.Print("Now playing " .. IC.Personas.Name() .. ".") elseif problem then IC.Print(problem) end
        return ok == true, problem
    elseif action.type == "character" then
        return false
    elseif action.type == "pool" and action.role and not action.payload then
        IC.Print(IC.Personas.Name() .. " has no " .. action.name .. " lines yet. Add them in /ic lines.")
        return false
    elseif action.type == "pool" or action.type == "line" then
        if IC.Personas and not IC.Personas.ActionAllowed(action) then
            local reason = "This pool belongs to another character. Loaded: " .. IC.Personas.Name() .. "."
            IC.Print(reason); return false, reason
        end
        local pool = IC.Profile().pools[action.payload]
        if not pool or #pool.lines == 0 then IC.Print("This pool is empty. Add lines or install a library preset in /ic."); return false end
        if pool.channel ~= "SAY" and pool.channel ~= "YELL" and pool.channel ~= "EMOTE" then IC.Print("Invalid chat channel."); return false end
        local allowed, reason = A.ChatAllowed()
        if not allowed then IC.Print(reason .. " Selection unchanged; nothing queued."); return false, reason end
        if action.selectionMode and action.selectionMode ~= "random" and action.selectionMode ~= "shuffle" and action.selectionMode ~= "sequential" then IC.Print("Invalid selection mode."); return false end
        local key = IC.Dialogue.StateKey(pool, action.selectionMode)
        local text, nextState
        if action.type == "line" then text = IC.Dialogue.Line(pool, action.lineID)
        else text, nextState = IC.Dialogue.Preview(pool, action.selectionMode) end
        if not text or IC.Trim(text) == "" then IC.Print("This message is no longer available."); return false end
        text = A.ChatText(text)
        -- Store unlimited quote lengths, but never split/truncate/spam the live channel.
        if #text > 255 or text:find("[%z\1-\31\127]") then
            IC.Print("Selected line cannot be sent (255 UTF-8 bytes maximum per message; no control characters). Edit or preview it in /ic.")
            return false
        end
        local ok, reason = IC.Platform.SendChat(text, pool.channel)
        if not ok then
            IC.Print(reason .. " Nothing is queued for later.")
            return false
        end
        if nextState then IC.Dialogue.states[key] = nextState end
        return true
    end
    IC.Print("Unsupported action type.")
    return false
end
