local _, IC = ...
local unpack = unpack or table.unpack
local U, A = IC.UI, IC.Actions
IC.QuickActions = { cards = {}, tabs = {}, page = 1, section = "favorites" }
local Q = IC.QuickActions
local PER_PAGE = 9
function Q.Close()
    Q.open = false
    if Q.catcher then Q.catcher:Hide() end
    GameTooltip:Hide()
end
function Q.Items()
    local settings = IC.Profile().wheel
    if Q.poolID then
        local pool = IC.Profile().pools[Q.poolID]
        return pool and IC.Presentation.Filter(A.Lines(pool), settings) or {}
    end
    if Q.section == "Roleplay" then
        local result = {}; if settings.hiddenCategories.Roleplay then return result end
        for _, id in ipairs(IC.Profile().poolOrder) do
            local pool = IC.Profile().pools[id]
            local group = pool.provenance and pool.provenance.pack or "custom"
            if (Q.group == "all" or Q.group == group) and not settings.hiddenActions["group:" .. group] and not settings.hiddenActions["browse:" .. id] then result[#result + 1] = A.Resolve("pool:" .. id) end
        end
        return IC.Presentation.Filter(result, settings)
    end
    if Q.section == "favorites" and settings.hiddenCategories.Favorites then return {} end
    local source = Q.section == "emotes" and (Q.group or "all") or "favorites"
    local result = {}
    for _, action in ipairs(A.List(source)) do
        if (action.type ~= "emote" or action.verified) and (Q.section ~= "emotes" or not settings.hiddenCategories[action.category]) then result[#result + 1] = action end
    end
    return IC.Presentation.Filter(result, settings)
end
local function send(id)
    local ok, reason = A.Dispatch(id)
    if ok then Q.Close() else Q.notice:SetText(reason or "Nothing submitted. See the client message in chat.") end
end
function Q.Select(section)
    Q.section, Q.group, Q.poolID, Q.page = section, "all", nil, 1
    Q.Refresh()
end
function Q.Browse(poolID)
    Q.poolID, Q.page = poolID, 1; Q.Refresh()
end
function Q.Back() Q.poolID, Q.page = nil, 1; Q.Refresh() end
local function card(index)
    local button = Q.cards[index]
    if button then return button end
    button = U.Button(Q.frame, "", 0, 0, 100, function(self, mouse)
        if mouse == "RightButton" then A.Favorite(self.action.id); return end
        send(self.action.id)
    end)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp"); button.label:Hide()
    button.icon = button:CreateTexture(nil, "ARTWORK"); button.icon:SetSize(24, 24); button.icon:SetPoint("TOPLEFT", 8, -9)
    button.name = U.Label(button, "", 40, -8, 110); button.name:SetWordWrap(true)
    button.name:SetHeight(32)
    button.detail = U.Muted(button, "", 8, -44, 130)
    button.browse = U.Button(button, "...", nil, nil, 28, function() Q.Browse(button.action.payload) end)
    button.browse:SetPoint("BOTTOMRIGHT", -4, 4); button.browse:SetHeight(20)
    button.browse.tooltip = "Choose a specific saved message from this pool. Nothing is sent by opening it."
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(U.Colors.hover)); GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.action.name or self.action.label)
        GameTooltip:AddLine(A.Description(self.action), 0.9, 0.9, 0.9, true)
        GameTooltip:AddLine("Click: use once · Right-click: pin / unpin", 0.6, 0.8, 0.6, true); GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self) self:SetSelected(false); GameTooltip:Hide() end)
    Q.cards[index] = button; return button
end
function Q.Refresh()
    if not Q.frame or not Q.open then return end
    if Q.profile ~= IC.Profile() then Q.Close(); return end
    local options = { { value = "all", label = Q.section == "Roleplay" and "All my pools" or (IC.Profile().emoteScope == "all" and "All enabled emotes" or "Everyday emotes") } }
    if Q.section == "Roleplay" then
        for _, group in ipairs(A.RoleplayGroups()) do options[#options + 1] = { value = group.id:sub(7), label = group.label } end
    elseif Q.section == "emotes" then
        for _, id in ipairs(IC.Emotes.categories) do if #A.List(id) > 0 and not IC.Profile().wheel.hiddenCategories[id] then options[#options + 1] = { value = id, label = IC.Emotes.CategoryInfo[id].label } end end
    end
    Q.groupChoice:SetOptions(options); Q.groupChoice:SetValue(Q.group)
    Q.groupChoice:SetShown(Q.section ~= "favorites" and not Q.poolID)
    Q.back:SetShown(Q.poolID ~= nil); Q.random:SetShown(Q.poolID ~= nil); Q.nextLine:SetShown(Q.poolID ~= nil)
    for _, tab in ipairs(Q.tabs) do tab:SetSelected(tab.section == Q.section) end
    local pool = Q.poolID and IC.Profile().pools[Q.poolID]
    Q.heading:SetText(pool and ("Choose a line · " .. IC.DisplayText(IC.ShortText(pool.name, 64))) or "In Character · quick actions")
    local items = Q.Items(); Q.items = items
    local pages = math.max(1, math.ceil(#items / PER_PAGE)); Q.page = math.max(1, math.min(pages, Q.page))
    local columns = Q.poolID and 2 or math.max(2, math.min(4, math.floor(tonumber(IC.Profile().quick.columns) or 3)))
    local width, height = (552 - (columns - 1) * 8) / columns, 72
    for _, button in ipairs(Q.cards) do button:Hide() end
    local offset, count = (Q.page - 1) * PER_PAGE, math.min(PER_PAGE, #items - (Q.page - 1) * PER_PAGE)
    for i = 1, count do
        local action, button = items[offset + i], card(i)
        button.action = action; button:SetSize(width, height)
        button:ClearAllPoints(); button:SetPoint("TOPLEFT", 14 + ((i - 1) % columns) * (width + 8), -122 - math.floor((i - 1) / columns) * (height + 8))
        U.SetIcon(button.icon, action.icon, IC.Icons[1]); button.name:SetText(action.name or action.label); button.name:SetWidth(width - 48)
        button.detail:SetWidth(width - (action.type == "pool" and 44 or 16))
        local source = action.type == "pool" and IC.Profile().pools[action.payload]
        local mode = source and (action.selectionMode or source.mode)
        local modeName = ({ random = "Random", shuffle = "Shuffle", sequential = "In order" })[mode]
        button.detail:SetText(source and ((modeName or mode) .. " · " .. #source.lines .. " lines")
            or (action.type == "emote" and ("/" .. action.command) or "Send this line"))
        button.browse:SetShown(action.type == "pool"); button:Show()
    end
    local rows = math.max(1, math.ceil(count / columns)); local frameHeight = 122 + rows * (height + 8) + 66
    Q.frame:SetSize(580, frameHeight)
    Q.frame:SetScale(math.min(1, (UIParent:GetWidth() - 20) / 580, (UIParent:GetHeight() - 20) / frameHeight))
    Q.previous:SetShown(pages > 1); Q.next:SetShown(pages > 1); Q.pageLabel:SetText(Q.page .. " / " .. pages)
    Q.empty:SetShown(#items == 0)
    Q.notice:SetText(#items == 0 and "Pin actions, keep emotes, or create any named dialogue pool in settings." or "Click uses once. Right-click pins. A pool's ... button lets you choose a line.")
end
local function page(delta)
    local pages = math.max(1, math.ceil(#Q.Items() / PER_PAGE))
    Q.page = (Q.page - 1 + delta) % pages + 1; Q.Refresh()
end
function Q.Create()
    Q.catcher = CreateFrame("Frame", "InCharacterQuickActions", UIParent)
    Q.catcher:SetAllPoints(UIParent); Q.catcher:SetFrameStrata("FULLSCREEN_DIALOG"); Q.catcher:EnableMouse(true); Q.catcher:Hide()
    Q.catcher:SetScript("OnHide", function() Q.open = false; GameTooltip:Hide() end)
    Q.catcher:SetScript("OnMouseDown", function() Q.Close() end)
    local frame = U.Panel(Q.catcher, 580, 450, U.Colors.bg); Q.frame = frame
    frame:SetClampedToScreen(true); frame:EnableMouse(true); frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta) page(-delta) end)
    frame:SetScript("OnMouseDown", function(_, mouse) if mouse == "RightButton" then Q.Close() end end)
    Q.heading = U.Heading(frame, "", 14, -12, 440)
    Q.heading:SetWordWrap(false); Q.heading:SetHeight(24)
    U.Button(frame, "×", 538, -8, 28, Q.Close)
    for i, definition in ipairs({ { "favorites", "Pinned" }, { "emotes", "Emotes" }, { "Roleplay", "My lines" } }) do
        local button = U.Button(frame, definition[2], 14 + (i - 1) * 128, -44, 120, function() Q.Select(definition[1]) end)
        button.section = definition[1]; Q.tabs[i] = button
    end
    U.Button(frame, "Settings", 450, -44, 116, function() Q.Close(); IC.Editor.Open() end)
    Q.groupChoice = U.Dropdown(frame, 14, -84, 552, {}, function(value) Q.group, Q.page = value, 1; Q.Refresh() end)
    Q.back = U.Button(frame, "< Back", 14, -84, 100, Q.Back)
    Q.random = U.Button(frame, "Random line", 122, -84, 180, function() if Q.poolID then send("play:random:" .. Q.poolID) end end)
    Q.nextLine = U.Button(frame, "Next in pool mode", 310, -84, 256, function() if Q.poolID then send("pool:" .. Q.poolID) end end)
    Q.empty = U.Muted(frame, "Nothing selected for this view yet.", 24, -132, 520)
    Q.previous = U.Button(frame, "<", nil, nil, 36, function() page(-1) end); Q.previous:SetPoint("BOTTOMLEFT", 14, 30)
    Q.next = U.Button(frame, ">", nil, nil, 36, function() page(1) end); Q.next:SetPoint("BOTTOMRIGHT", -14, 30)
    Q.pageLabel = U.Label(frame, "", nil, nil, 100); Q.pageLabel:ClearAllPoints(); Q.pageLabel:SetPoint("BOTTOM", 0, 38); Q.pageLabel:SetJustifyH("CENTER")
    Q.notice = U.Muted(frame, "", 14, nil, 552); Q.notice:ClearAllPoints(); Q.notice:SetPoint("BOTTOMLEFT", 14, 8)
    table.insert(UISpecialFrames, "InCharacterQuickActions")
end
function Q.Open()
    if not IC.db then return end
    if not Q.frame then Q.Create() end
    if IC.Wheel then IC.Wheel.Close() end
    if IC.Menu then IC.Menu.Close() end
    Q.profile, Q.section, Q.group, Q.poolID, Q.page, Q.open = IC.Profile(), "favorites", "all", nil, 1, true
    Q.catcher:Show(); Q.Refresh()
    local x, y = GetCursorPosition(); local scale = Q.frame:GetEffectiveScale()
    Q.frame:ClearAllPoints(); Q.frame:SetPoint("TOP", UIParent, "BOTTOMLEFT", x / scale, y / scale - 22)
end
function Q.Toggle()
    if not IC.db then return end
    if IC.Profile().quick.style == "bars" then Q.Close(); IC.Wheel.Close(); IC.Menu.Close(); IC.Bars.ToggleCatalog(); return end
    if IC.Profile().quick.style == "ring" then Q.Close(); IC.Wheel.Toggle(); return end
    if Q.open then Q.Close() else Q.Open() end
end
function Q.Binding(state)
    if not IC.db then return end
    if IC.Profile().quick.style == "ring" then IC.Wheel.Binding(state)
    elseif state == "down" then Q.Toggle() end
    -- Releasing a key never executes a panel action.
end
_G.InCharacter_QuickBinding = Q.Binding
BINDING_NAME_INCHARACTER_QUICK = "Optional quick panel / chosen style"
