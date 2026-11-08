local _, IC = ...
IC.Wheel = { buttons = {}, quick = {} }
local W, M = IC.Wheel, IC.WheelModel
local function now() return GetTime() end

function W.Close()
    W.open, W.hover, W.hoverSince, W.held = false, nil, nil, false
    if W.catcher then W.catcher:Hide() end
end
local function selectHover(button)
    if W.hover == button then return end
    if W.hover then W.hover:SetBackdropBorderColor(0.5, 0.5, 0.6, 1) end
    W.hover, W.hoverSince = button, button and now() or nil
    if button then button:SetBackdropBorderColor(1, 0.82, 0.3, 1) end
end
local function activate(action)
    if not W.open then return end
    if IC.InCombat() then W.Close(); return end
    if action.type == "submenu" then
        M.Enter(W.state, action); W.Render()
    else
        W.Close(); IC.Actions.Dispatch(action)
    end
end
local function actionButton(parent)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(116, 38)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    button:SetBackdropColor(0.08, 0.08, 0.11, 0.97); button:SetBackdropBorderColor(0.5, 0.5, 0.6, 1)
    button.icon = button:CreateTexture(nil, "ARTWORK"); button.icon:SetSize(22, 22); button.icon:SetPoint("LEFT", 4, 0)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("LEFT", 30, 0); button.label:SetPoint("RIGHT", -4, 0); button.label:SetWordWrap(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(self, mouse)
        if mouse == "RightButton" then W.Close() else activate(self.action) end
    end)
    button:SetScript("OnEnter", function(self)
        selectHover(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(self.action.label)
        GameTooltip:AddLine(self.action.type == "submenu" and "Click to enter" or (self.action.type .. ": " .. self.action.payload), 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self) if W.hover == self then selectHover(nil) end; GameTooltip:Hide() end)
    return button
end
local function content(button, action)
    button.action = action; button.icon:SetTexture(action.icon); button.label:SetText(action.label .. (action.type == "submenu" and " >" or ""))
    button:SetBackdropBorderColor(0.5, 0.5, 0.6, 1); button:Show()
end
function W.Render()
    selectHover(nil); W.generation = (W.generation or 0) + 1; W.renderedAt = now()
    local state = W.state
    local entries, pages = M.Items(state, 8)
    local radius = IC.Profile().wheel.radius
    for i = 1, 8 do
        local button = W.buttons[i]; local action = entries[i]
        button:Hide()
        if action then
            content(button, action)
            local angle = math.rad(90 - (i - 1) * 360 / #entries)
            button:ClearAllPoints(); button:SetPoint("CENTER", W.frame, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
        end
    end
    local current = M.Current(state)
    W.title:SetText(current.label .. (#entries == 0 and "\n(empty)" or ""))
    local root = #state.stack == 1
    W.back:SetText(root and "Cancel" or "< Back")
    W.back:ClearAllPoints(); W.back:SetPoint("CENTER", W.frame, "CENTER", 0, root and -104 or 20)
    W.title:ClearAllPoints(); W.title:SetPoint("CENTER", W.frame, "CENTER", 0, root and 92 or 65)
    W.previous:SetShown(pages > 1); W.next:SetShown(pages > 1)
    W.page:SetText(pages > 1 and (state.page .. "/" .. pages) or "")
    for _, button in ipairs(W.quick) do button:Hide() end
    local favorites = state.stack[1].children[1].children
    local favoritePages = math.max(1, math.ceil(#favorites / 4))
    state.favoritePage = math.max(1, math.min(state.favoritePage, favoritePages))
    if root then
        for i = 1, 4 do
            local action = favorites[(state.favoritePage - 1) * 4 + i]
            if action then content(W.quick[i], action) end
        end
    end
    W.favoriteNext:SetShown(root and favoritePages > 1)
    W.favoriteNext:SetText("Favorites " .. state.favoritePage .. "/" .. favoritePages .. " >")
end
function W.Create()
    local catcher = CreateFrame("Frame", "InCharacterWheelCatcher", UIParent)
    W.catcher = catcher; catcher:SetAllPoints(UIParent); catcher:SetFrameStrata("FULLSCREEN_DIALOG"); catcher:SetFrameLevel(40)
    catcher:EnableMouse(true); catcher:Hide()
    catcher:SetScript("OnMouseDown", function(_, button) if button == "RightButton" then W.Close() end end)
    catcher:SetScript("OnHide", function() W.open, W.hover, W.held = false, nil, false; GameTooltip:Hide() end)
    local frame = CreateFrame("Frame", nil, catcher); W.frame = frame
    frame:SetSize(540, 540); frame:SetPoint("CENTER", UIParent, "CENTER"); frame:SetFrameLevel(41)
    W.title = IC.UI.Label(frame, "", 0, 0, 140); W.title:SetJustifyH("CENTER")
    W.back = IC.UI.Button(frame, "Cancel", 0, 0, 130, function()
        if M.Back(W.state) then W.Render() else W.Close() end
    end)
    W.previous = IC.UI.Button(frame, "<", 0, 0, 40, function() M.Page(W.state, -1, 8); W.Render() end)
    W.previous:ClearAllPoints(); W.previous:SetPoint("CENTER", frame, "CENTER", -52, -34)
    W.next = IC.UI.Button(frame, ">", 0, 0, 40, function() M.Page(W.state, 1, 8); W.Render() end)
    W.next:ClearAllPoints(); W.next:SetPoint("CENTER", frame, "CENTER", 52, -34)
    W.page = IC.UI.Label(frame, "", 0, 0, 40); W.page:ClearAllPoints(); W.page:SetPoint("CENTER", frame, "CENTER", 0, -34); W.page:SetJustifyH("CENTER")
    for i = 1, 8 do W.buttons[i] = actionButton(frame) end
    for i = 1, 4 do
        local button = actionButton(frame); button:SetSize(140, 26); button:SetPoint("CENTER", frame, "CENTER", 0, 56 - (i - 1) * 30)
        W.quick[i] = button
    end
    W.favoriteNext = IC.UI.Button(frame, "", 0, 0, 140, function()
        local count = #W.state.stack[1].children[1].children
        W.state.favoritePage = W.state.favoritePage % math.max(1, math.ceil(count / 4)) + 1; W.Render()
    end)
    W.favoriteNext:ClearAllPoints(); W.favoriteNext:SetPoint("CENTER", frame, "CENTER", 0, -70)
    local help = IC.UI.Label(frame, "Click a group to enter. Escape / right-click cancels.", 50, -514, 440); help:SetJustifyH("CENTER")
    frame:SetScript("OnUpdate", function()
        -- Updating selection never executes actions. Rectangular hit targets leave gaps/dead zones.
        if not W.open then return end
        local x, y = GetCursorPosition(); local scale = frame:GetEffectiveScale(); x, y = x / scale, y / scale
        local candidate
        for _, list in ipairs({ W.buttons, W.quick }) do
            for _, button in ipairs(list) do
                if button:IsShown() then
                    local bx, by = button:GetCenter()
                    if bx and math.abs(x - bx) <= button:GetWidth() / 2 and math.abs(y - by) <= button:GetHeight() / 2 then candidate = button end
                end
            end
        end
        selectHover(candidate)
    end)
    table.insert(UISpecialFrames, "InCharacterWheelCatcher")
end
function W.Open(binding)
    if not IC.db then return end
    if IC.InCombat() then IC.Print("Open the wheel after combat."); return end
    if not W.frame then W.Create() end
    W.state = M.New(M.Tree()); W.open = true; W.held = binding == true
    W.frame:SetScale(math.min(1, (UIParent:GetHeight() - 24) / 540, (UIParent:GetWidth() - 24) / 540))
    W.catcher:Show(); W.Render()
end
function W.Toggle() if W.open then W.Close() else W.Open(false) end end
function W.Binding(keystate)
    if keystate == "down" then
        if W.open then W.Close() else W.Open(true) end
    elseif keystate == "up" and W.open and W.held then
        W.held = false
        if IC.Profile().wheel.mode == "hold" then
            local button = W.hover
            local action = button and button.action
            local ready = action and action.type ~= "submenu" and W.hoverSince and now() - W.hoverSince >= 0.15 and now() - W.renderedAt >= 0.15
            W.Close()
            if ready and not IC.InCombat() then IC.Actions.Dispatch(action) end
        end
        -- Click mode stays open after key release; the next key press toggles it closed.
    end
end
_G.InCharacter_WheelBinding = W.Binding
_G.InCharacter_ToggleEditor = function() if IC.db then IC.Editor.Toggle() end end
_G.InCharacter_FavoriteBinding = function(index)
    if IC.db then IC.Actions.Dispatch(IC.Profile().favorites[index]) end
end
BINDING_HEADER_INCHARACTER = "In Character"
BINDING_NAME_INCHARACTER_EDITOR = "Open editor"
BINDING_NAME_INCHARACTER_WHEEL = "Radial wheel (click / experimental hold)"
for i = 1, 4 do _G["BINDING_NAME_INCHARACTER_FAVORITE" .. i] = "Use favorite " .. i end
