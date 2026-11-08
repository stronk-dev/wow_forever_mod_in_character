local addonName, IC = ...
_G.InCharacter = IC
IC.name = addonName or "InCharacter"
IC.version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(IC.name, "Version") or "development"

function IC.Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = IC.Copy(v) end
    return result
end

-- Merge records, but treat lists (including intentionally empty lists) as atomic.
function IC.Merge(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            target[key] = IC.Copy(value)
        elseif type(target[key]) == "table" and type(value) == "table"
            and next(value) ~= nil and value[1] == nil then
            IC.Merge(target[key], value)
        end
    end
    return target
end

function IC.Trim(text) return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
function IC.Normalize(text)
    return (IC.Trim(text):lower():gsub("%s+", "-"):gsub("[^%w_\128-\255%-]", ""))
end
function IC.ShortText(text, limit)
    text, limit = tostring(text or ""):gsub("[\r\n]", " "), limit or 64
    if #text <= limit then return text end
    local stop = limit
    while stop > 0 and text:byte(stop + 1) and text:byte(stop + 1) >= 128 and text:byte(stop + 1) <= 191 do stop = stop - 1 end
    return text:sub(1, stop) .. "..."
end
function IC.DisplayText(text) return (tostring(text or ""):gsub("|", "||")) end
function IC.Print(text)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffd6b56cIn Character:|r " .. tostring(text)) end
end
function IC.InCombat() return InCombatLockdown and InCombatLockdown() end
function IC.Profile() return IC.Profiles.Get() end
function IC.Layout() return IC.Profiles.Layout() end

function IC.Refresh()
    if IC.InCombat() then IC.refreshPending = true; return end
    IC.refreshPending = nil
    if IC.Bars then IC.Bars.Refresh() end
    if IC.Launcher then IC.Launcher.Refresh() end
    if IC.Menu then IC.Menu.Rebuild() end
    if IC.QuickActions and IC.QuickActions.open then IC.QuickActions.Refresh() end
end

function IC.Changed()
    IC.Refresh()
end

function IC.Help()
    IC.Print("/ic bars shows the Roleplay bar; /ic opens settings; /ic review checks emotes; /ic quick toggles quick access.")
    IC.Print("/ic <pool name>; /ic play random|shuffle|sequential <pool name>; /ic message <pool ID> <message ID>.")
end

function IC.Slash(input)
    if not IC.db then return end
    local command, rest = IC.Trim(input):match("^(%S*)%s*(.-)$")
    command = command:lower()
    if command == "" then
        if IC.Editor then IC.Editor.Toggle() else IC.Help() end
    elseif command == "help" then IC.Help()
    elseif command == "bars" then IC.Bars.ShowCatalog()
    elseif command == "wheel" or command == "quick" then
        IC.QuickActions.Toggle()
    elseif command == "review" then
        IC.EmoteReview.Open()
    elseif command == "menu" then
        if IC.Menu then IC.Menu.OpenAtCursor() end
    elseif command == "emotes" or command == "setup" or command == "settings" then
        if IC.Editor then IC.Editor.Open(command == "emotes" and "Emotes" or "Home") end
    elseif command == "play" then
        local mode, name = rest:match("^(%S+)%s+(.+)$")
        local pool, problem = IC.Dialogue.Find(name or "")
        if pool and (mode == "random" or mode == "shuffle" or mode == "sequential") then IC.Actions.Dispatch("play:" .. mode .. ":" .. pool.id)
        else IC.Print(problem or "Use /ic play random|shuffle|sequential <pool name>.") end
    elseif command == "message" then
        local poolID, lineID = rest:match("^(%S+)%s+(%S+)$")
        if poolID and lineID then IC.Actions.Dispatch("line:" .. poolID .. ":" .. lineID)
        else IC.Print("Use /ic message <pool ID> <message ID>, or choose a message in the menu.") end
    else
        local aliases = { greet = "greetings", quote = "quotes", bye = "farewells" }
        local shortcut = aliases[command]
        local requested = shortcut and (IC.Profile().shortcuts[shortcut] or shortcut) or input
        local pool, problem = IC.Dialogue.Find(command == "pool" and rest or requested)
        if pool then IC.Actions.Dispatch({ type = "pool", payload = pool.id })
        else IC.Print(problem or "Unknown pool. Use /ic help.") end
    end
end

local function RegisterSlash()
    local taken = {}
    for key, value in pairs(_G) do
        if type(key) == "string" and key:match("^SLASH_") and type(value) == "string" then
            taken[value:lower()] = true
        end
    end
    SlashCmdList.INCHARACTER = IC.Slash
    local index = 0
    for _, alias in ipairs({ "/ic", "/incharacter" }) do
        if not taken[alias] then index = index + 1; _G["SLASH_INCHARACTER" .. index] = alias
        else IC.Print(alias .. " is already registered; leaving it with its owner.") end
    end
end

function IC.LegacyCharacterKeys()
    local name = UnitName("player")
    local realm = GetRealmName()
    if not name or not realm then return {} end
    -- These keys are only for migration. Blizzard selects the live character DB.
    return { realm .. ":" .. name, realm:gsub("%s+", "") .. ":" .. name }
end

function IC.Initialize(database, characterDatabase)
    IC.db = IC.Profiles.Open(database, characterDatabase, IC.LegacyCharacterKeys())
    InCharacterDB = IC.db
    InCharacterCharDB = IC.Profiles.Character()
    IC.Emotes.Validate()
    -- Create the overlay frames out of combat; they are plain frames and work in combat afterwards.
    if IC.Wheel and not IC.Wheel.frame then IC.Wheel.Create() end
    if IC.Menu and not IC.Menu.catcher then IC.Menu.Create() end
    if IC.SettingsPanel then IC.SettingsPanel.Register() end
    IC.Refresh()
end

if CreateFrame then
    local events = CreateFrame("Frame")
    events:SetScript("OnEvent", function(_, event, loaded)
        if event == "ADDON_LOADED" and loaded == IC.name then
            IC.Initialize(InCharacterDB, InCharacterCharDB)
            RegisterSlash()
            IC.Print("Loaded. Click the round button, or type /ic to set things up.")
        elseif event == "PLAYER_REGEN_ENABLED" and IC.refreshPending then IC.Refresh()
        elseif event == "PLAYER_REGEN_DISABLED" then
            for _, stop in ipairs(IC.UI and IC.UI.captures or {}) do stop() end
            if IC.Editor and IC.Editor.frame then IC.Editor.frame:Hide() end
        end
    end)
    for _, event in ipairs({ "ADDON_LOADED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED" }) do
        pcall(events.RegisterEvent, events, event)
    end
end
