local addonName, IC = ...
_G.InCharacter = IC
IC.name = addonName or "InCharacter"
IC.version = IC.Platform.Version(IC.name)

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
function IC.InCombat() return IC.Platform.InCombat() end
function IC.Profile() return IC.Profiles.Get() end
function IC.Layout() return IC.Profiles.Layout() end

function IC.Refresh()
    if IC.InCombat() then IC.refreshPending = true; return end
    IC.refreshPending = nil
    if IC.Bars then IC.Bars.Refresh() end
    if IC.Launcher then IC.Launcher.Refresh() end
end

function IC.Changed()
    IC.Refresh()
end

function IC.Help()
    IC.Print("/ic settings · /ic wheel · /ic menu · /ic edit moves bars · /ic bars hides or shows bars · /ic bars one|separate")
    IC.Print("/ic greet | quote | bye | joke | toast | battlecry | banter · /ic say <slot> · /ic character <name> · /ic <pool name> · /ic play random|shuffle|sequential <pool>")
end

function IC.Slash(input)
    if not IC.db then return end
    local command, rest = IC.Trim(input):match("^(%S*)%s*(.-)$")
    command = command:lower()
    if command == "" then
        if IC.Editor then IC.Editor.Toggle() else IC.Help() end
    elseif command == "help" then IC.Help()
    elseif command == "bars" then
        if rest == "one" or rest == "separate" then IC.Bars.SetMode(rest) else IC.Bars.ToggleAll() end
    elseif command == "character" then
        if rest == "" then IC.Print("Loaded: " .. IC.Personas.Name()); IC.Editor.Open("Lines")
        else
            local chosen, reason = IC.Personas.Resolve(rest)
            local ok; if chosen then ok, reason = IC.Personas.Choose(chosen) end
            if not ok then IC.Print(reason or "Choose a character in /ic options.") end
        end
    elseif command == "arrange" or command == "edit" then IC.Bars.SetEditing(not IC.Bars.editing)
    elseif command == "wheel" then IC.Wheel.Toggle()
    elseif command == "menu" then
        if IC.Menu then IC.Menu.OpenAtCursor() end
    elseif command == "emotes" or command == "lists" or command == "lines" or command == "layout" or command == "setup" or command == "settings" then
        if IC.Editor then IC.Editor.Open(({ lines = "Lines", layout = "Layout" })[command] or "Lists") end
    elseif command == "play" then
        local mode, name = rest:match("^(%S+)%s+(.+)$")
        local pool, problem
        if IC.Personas then pool, problem = IC.Personas.FindPool(name or "") else pool, problem = IC.Dialogue.Find(name or "") end
        if pool and (mode == "random" or mode == "shuffle" or mode == "sequential") then IC.Actions.Dispatch("play:" .. mode .. ":" .. pool.id)
        else IC.Print(problem or "Use /ic play random|shuffle|sequential <pool name>.") end
    elseif command == "message" then
        local poolID, lineID = rest:match("^(%S+)%s+(%S+)$")
        if poolID and lineID then IC.Actions.Dispatch("line:" .. poolID .. ":" .. lineID)
        else IC.Print("Use /ic message <pool ID> <message ID>, or choose a message in the menu.") end
    else
        -- /ic greet | quote | bye, or /ic say <slot name>: that slot for the loaded character.
        local aliases = {}
        for _, slot in ipairs(IC.Personas and IC.Personas.ROLES or {}) do aliases[slot.command] = slot.id end
        if aliases[command] then IC.Actions.Dispatch("role:" .. aliases[command]); return end
        if command == "say" and IC.Personas then
            local wanted = IC.Trim(rest or ""):lower()
            for _, slot in ipairs(IC.Personas.Slots()) do
                if slot.label:lower() == wanted or slot.id == wanted then IC.Actions.Dispatch("role:" .. slot.id); return end
            end
            local names = {}; for _, slot in ipairs(IC.Personas.Slots()) do names[#names + 1] = slot.label end
            IC.Print("Use /ic say <slot>. Slots: " .. table.concat(names, ", ") .. "."); return
        end
        local requested = input
        local pool, problem
        if IC.Personas then pool, problem = IC.Personas.FindPool(command == "pool" and rest or requested)
        else pool, problem = IC.Dialogue.Find(command == "pool" and rest or requested) end
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
    local name, realm = IC.Platform.Player()
    if not name or not realm then return {} end
    -- These keys are only for migration. Blizzard selects the live character DB.
    return { realm .. ":" .. name, realm:gsub("%s+", "") .. ":" .. name }
end

function IC.Initialize(database, characterDatabase)
    IC.db = IC.Profiles.Open(database, characterDatabase, IC.LegacyCharacterKeys())
    InCharacterDB = IC.db
    InCharacterCharDB = IC.Profiles.Character()
    IC.Platform.RefreshChatPermissions()
    IC.Emotes.Validate()
    -- Create the overlay frames out of combat; they are plain frames and work in combat afterwards.
    if IC.Wheel and not IC.Wheel.frame then IC.Wheel.Create() end
    if IC.SettingsPanel then IC.SettingsPanel.Register() end
    if IC.Bars.ConnectEditMode then IC.Bars.ConnectEditMode() end
    IC.Refresh()
end

if CreateFrame then
    local events = CreateFrame("Frame")
    events:SetScript("OnEvent", function(_, event, loaded, ...)
        if event == "PLAYER_ENTERING_WORLD" or event == "ADDON_RESTRICTION_STATE_CHANGED"
            or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
            IC.Platform.RefreshChatPermissions()
        end
        if event == "ADDON_LOADED" and IC.db and IC.Bars.ConnectEditMode then IC.Bars.ConnectEditMode() end
        if event == "ADDON_LOADED" and loaded == IC.name then
            IC.Initialize(InCharacterDB, InCharacterCharDB)
            RegisterSlash()
            IC.Print("Loaded. Use the small bar or the round button; /ic opens the settings.")
        elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
            IC.Platform.RecordChatBlock(loaded, ...)
        elseif event == "PLAYER_REGEN_ENABLED" and IC.refreshPending then IC.Refresh()
        elseif event == "PLAYER_REGEN_DISABLED" then
            for _, stop in ipairs(IC.UI and IC.UI.captures or {}) do stop() end
            if IC.Editor and IC.Editor.frame then IC.Editor.frame:Hide() end
        end
    end)
    for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "ADDON_RESTRICTION_STATE_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }) do
        pcall(events.RegisterEvent, events, event)
    end
end
