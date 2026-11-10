local _, IC = ...
-- Client integration boundary. Domain services never submit directly to Blizzard APIs.
IC.Platform = {}
local P = IC.Platform
function P.InCombat() return InCombatLockdown and InCombatLockdown() end
function P.Version(name) return C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(name, "Version") or "development" end
function P.Cursor() return GetCursorPosition() end
function P.Time() return GetTime() end
function P.Player() return UnitName("player"), GetRealmName() end
function P.Build() return GetBuildInfo and select(2, GetBuildInfo()) end
function P.Emote(token)
    local fn = type(DoEmote) == "function" and DoEmote or (C_ChatInfo and C_ChatInfo.PerformEmote)
    if type(fn) ~= "function" then return false, "Emote API is unavailable." end
    local ok, reason = pcall(fn, token)
    -- Forever/Charades submits the token through DoEmote; its return is not an observation.
    return ok, not ok and ("Client blocked the emote: " .. tostring(reason)) or nil
end
function P.SendChat(text, channel)
    local fn = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    if type(fn) ~= "function" then return false, "Chat API is unavailable." end
    local before = P.chatBlockSerial or 0
    -- Match Charades: submit directly on the user's click/key call stack. Do not put the
    -- restricted C function behind pcall/securecall, a timer, or a chat-box workaround.
    -- The dispatcher commits playback only after this returns successfully.
    local result = fn(text, channel)
    if (P.chatBlockSerial or 0) ~= before then
        local block = P.lastBlockedAction or {}
        local reason = "Client blocked " .. (block.functionName or "the chat action")
        if block.source then reason = reason .. " (chat API tainted by " .. block.source .. ")" end
        return false, reason .. "; playback is unchanged."
    end
    if result == false then return false, "Client declined chat." end
    return true
end
-- A protected-action failure can emit an event without throwing or returning false.
function P.RecordChatBlock(addon, functionName)
    if addon ~= IC.name then return end
    P.chatBlockSerial = (P.chatBlockSerial or 0) + 1
    local source
    -- Inspect the actual shared API, not addon-owned variables (which are always tainted).
    if type(issecurevariable) == "function" then
        local owner, key = C_ChatInfo, "SendChatMessage"
        if not owner or type(owner[key]) ~= "function" then owner = _G end
        local ok, secure, taintedBy = pcall(issecurevariable, owner, key)
        if ok and secure == false and type(taintedBy) == "string" then source = taintedBy end
    end
    local stack
    if type(debugstack) == "function" then
        local ok, value = pcall(debugstack, 2, 12, 0)
        if ok and type(value) == "string" then stack = value end
    end
    P.lastBlockedAction = { functionName = type(functionName) == "string" and functionName or "an unknown protected function", source = source, stack = stack }
end
function P.CursorInside(frame)
    if not frame or not frame:IsShown() then return false end
    local x, y = P.Cursor(); local scale = frame:GetEffectiveScale()
    local cx, cy = frame:GetCenter()
    return cx and x / scale >= cx - frame:GetWidth() / 2 and x / scale <= cx + frame:GetWidth() / 2
        and y / scale >= cy - frame:GetHeight() / 2 and y / scale <= cy + frame:GetHeight() / 2
end
function P.RegisterSettings(panel)
    if type(Settings) ~= "table" or type(Settings.RegisterCanvasLayoutCategory) ~= "function" then return end
    local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, "In Character")
    if not ok or not category then return end
    if type(Settings.RegisterAddOnCategory) == "function" then pcall(Settings.RegisterAddOnCategory, category) end
    return category
end
function P.CloseSettings() if SettingsPanel and SettingsPanel.Close then pcall(SettingsPanel.Close, SettingsPanel, true) end end
function P.MacroIcons(target)
    for _, name in ipairs({ "GetMacroIcons", "GetMacroItemIcons" }) do if type(_G[name]) == "function" then pcall(_G[name], target) end end
end
local function readBoolean(fn, ...)
    local ok, value = pcall(fn, ...)
    if not ok or (issecretvalue and issecretvalue(value)) or type(value) ~= "boolean" then return nil end
    return value
end

-- Permission queries belong to client lifecycle events, outside the hardware-input send stack.
-- The native chat API remains authoritative if restrictions change before an event is handled.
function P.ReadChatPermissions()
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

function P.RefreshChatPermissions()
    local allowed, reason = P.ReadChatPermissions()
    P.chatPermissions = { allowed = allowed, reason = reason }
    return allowed, reason
end

function P.ChatAllowed()
    local cached = P.chatPermissions
    if cached then return cached.allowed, cached.reason end
    -- Standalone domain users can query without installing the Core event integration.
    return P.ReadChatPermissions()
end


function P.EmoteCommands()
    local tokens, aliases, primary, clientAliases = {}, {}, {}, {}
    for index = 1, 1000 do
        local token = _G["EMOTE" .. index .. "_TOKEN"]
        if type(token) == "string" then
            tokens[token] = true
            clientAliases[token] = clientAliases[token] or {}
            for n = 1, 4 do
                local alias = _G["EMOTE" .. index .. "_CMD" .. n]
                if type(alias) == "string" then
                    alias = alias:lower():gsub("^/", "")
                    aliases[alias] = token; primary[token] = primary[token] or alias
                    clientAliases[token][#clientAliases[token] + 1] = alias
                end
            end
        end
    end
    return tokens, aliases, primary, clientAliases
end

function P.BindingKeys(action) if GetBindingKey then return GetBindingKey(action) end end
function P.BindingAction(key) return GetBindingAction and GetBindingAction(key) end
function P.SetBinding(key, action) return SetBinding(key, action) end
function P.SaveBindings() return SaveBindings(GetCurrentBindingSet()) end
function P.Shift() return IsShiftKeyDown() end
function P.Modifiers() return (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "") end
function P.ClearKeyboardFocus() local f = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus(); if f then f:ClearFocus() end end
function P.ConnectEditMode(enter, leave, owner)
    if not EventRegistry or type(EventRegistry.RegisterCallback) ~= "function" then return false end
    local ok1 = pcall(EventRegistry.RegisterCallback, EventRegistry, "EditMode.Enter", enter, owner)
    local ok2 = pcall(EventRegistry.RegisterCallback, EventRegistry, "EditMode.Exit", leave, owner)
    return ok1 and ok2
end
