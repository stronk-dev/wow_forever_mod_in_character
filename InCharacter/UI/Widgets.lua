local _, IC = ...
local unpack = unpack or table.unpack
-- Shared Blizzard templates and artwork; custom lists retain the same fonts and palette.
IC.UI = {}
local U = IC.UI
local WHITE = "Interface\\Buttons\\WHITE8X8"
U.CIRCLE_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
U.Colors = {
    bg = { 0.05, 0.05, 0.05, 0.97 }, panel = { 0.09, 0.09, 0.08, 1 }, raised = { 0.14, 0.13, 0.11, 1 },
    hover = { 0.23, 0.2, 0.14, 1 }, border = { 0.32, 0.29, 0.23, 1 }, accent = { 1, 0.82, 0, 1 },
    accentDim = { 0.35, 0.28, 0.1, 1 }, text = { 1, 1, 1, 1 }, muted = { 0.65, 0.65, 0.65, 1 },
}
local C = U.Colors

function U.Backdrop(frame, color, border)
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(unpack(color or C.panel))
    frame:SetBackdropBorderColor(unpack(border or C.border))
end
function U.GameBackdrop(frame, dialog)
    frame:SetBackdrop({ bgFile = dialog and "Interface\\DialogFrame\\UI-DialogBox-Background" or "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = dialog and "Interface\\DialogFrame\\UI-DialogBox-Border" or "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = dialog and 16 or 10, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    local tint = dialog and 1 or 0.06
    frame:SetBackdropColor(tint, tint, tint, 0.96); frame:SetBackdropBorderColor(1, 1, 1, 1)
end
function U.Panel(parent, width, height, color, name)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    if width then frame:SetSize(width, height) end
    U.GameBackdrop(frame, true)
    return frame
end
function U.Label(parent, text, x, y, width, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    label:SetPoint("TOPLEFT", x or 0, y or 0); label:SetJustifyH("LEFT")
    if width then label:SetWidth(width); label:SetWordWrap(true) end
    label:SetText(text or "")
    return label
end
function U.Heading(parent, text, x, y, width) return U.Label(parent, text, x, y, width, "GameFontNormalLarge") end
function U.Muted(parent, text, x, y, width)
    local label = U.Label(parent, text, x, y, width, "GameFontHighlightSmall")
    label:SetTextColor(unpack(C.muted))
    return label
end

-- Best-effort fallback for explicit SetTexture rejection. A nil return is inconclusive;
-- real client assets still belong on the live checklist.
function U.SetIcon(texture, path, fallback)
    local question = "Interface\\Icons\\INV_Misc_QuestionMark"
    local chosen = path or fallback or question
    local ok, result = pcall(texture.SetTexture, texture, chosen)
    if not ok or result == false then
        -- A newer icon the client may lack names an older stand-in (Data/Icons.lua).
        local replacement = (IC.IconFallback and IC.IconFallback[chosen]) or fallback or question
        ok, result = pcall(texture.SetTexture, texture, replacement)
        if not ok or result == false then pcall(texture.SetTexture, texture, question) end
    end
end
function U.Circle(parent, layer, size, color)
    local texture = parent:CreateTexture(nil, layer or "BACKGROUND")
    texture:SetSize(size, size); texture:SetTexture(WHITE)
    texture:SetVertexColor(unpack(color))
    local mask = parent:CreateMaskTexture()
    mask:SetTexture(U.CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(texture); texture:AddMaskTexture(mask)
    texture.mask = mask
    return texture
end

-- Native panel buttons; style = "flat" only for explicitly custom-painted cards.
function U.Button(parent, text, x, y, width, click, style)
    local native = UIPanelButtonHeightScaledMixin and "UIPanelButtonHeightScaledTemplate" or "UIPanelButtonTemplate"
    local isNative = style ~= "flat"
    local button = CreateFrame("Button", nil, parent, isNative and native or "BackdropTemplate")
    button:SetSize(width or 120, 26)
    if x then button:SetPoint("TOPLEFT", x, y) end
    button.style, button.native = style, isNative
    if not isNative then U.Backdrop(button, C.raised, C.border) end
    button.label = isNative and button.GetFontString and button:GetFontString() or button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.label:ClearAllPoints()
    button.label:SetPoint("LEFT", 8, 0); button.label:SetPoint("RIGHT", -8, 0)
    button.label:SetJustifyH("CENTER"); button.label:SetWordWrap(false)
    function button:SetText(value) self.text = value; self.label:SetText(value) end
    function button:GetText() return self.text or "" end
    function button:SetSelected(selected)
        self.selected = selected
        if self.native then
            if self.LockHighlight then if selected then self:LockHighlight() else self:UnlockHighlight() end end
            return
        end
        U.Backdrop(self, selected and C.accentDim or (self.style == "accent" and C.accentDim or C.raised),
            selected and C.accent or (self.style == "accent" and C.accent or C.border))
    end
    button:SetScript("OnEnter", function(self)
        if not self.selected and not self.native then self:SetBackdropColor(unpack(C.hover)) end
        if self.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(self.tooltip, 1, 1, 1, 1, true); GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self) self:SetSelected(self.selected); GameTooltip:Hide() end)
    button:SetScript("OnClick", click)
    button:SetText(text)
    return button
end
-- Toggle chip used for filters.
function U.Chip(parent, text, x, y, width, click)
    local chip = U.Button(parent, text, x, y, width, click)
    chip:SetHeight(22)
    return chip
end

-- Square or round icon button. Returns the button; button.icon is the texture.
function U.IconButton(parent, size, round)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    button.icon = button:CreateTexture(nil, "ARTWORK"); button.icon:SetAllPoints()
    if round then
        -- Drawn ring (a slightly larger circle behind the masked icon) and a round hover glow.
        button.ring = U.Circle(button, "BACKGROUND", size + 6, C.accent); button.ring:SetPoint("CENTER")
        button.icon:ClearAllPoints(); button.icon:SetPoint("CENTER"); button.icon:SetSize(size, size)
        button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local mask = button:CreateMaskTexture()
        mask:SetTexture(U.CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE"); mask:SetAllPoints(button.icon)
        button.icon:AddMaskTexture(mask)
        button.glow = U.Circle(button, "HIGHLIGHT", size, { 1, 1, 1, 0.25 }); button.glow:SetPoint("CENTER")
        function button:SetRoundSize(value)
            self:SetSize(value, value); self.icon:SetSize(value, value)
            self.ring:SetSize(value + 6, value + 6); self.glow:SetSize(value, value)
        end
    else
        button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
        local normal = button:GetNormalTexture()
        normal:ClearAllPoints(); normal:SetPoint("CENTER"); normal:SetSize(size * 1.7, size * 1.7)
        button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    end
    function button:SetIcon(path, fallback) U.SetIcon(self.icon, path, fallback) end
    return button
end

-- Dropdown: a button that opens a list of { value, label, icon? } choices.
local popup
local function Popup()
    if popup then return popup end
    popup = CreateFrame("Frame", "InCharacterDropdownList", UIParent, "BackdropTemplate")
    U.GameBackdrop(popup); popup:SetFrameStrata("FULLSCREEN_DIALOG"); popup:SetClampedToScreen(true)
    popup:EnableMouse(true); popup:EnableMouseWheel(true); popup.rows = {}; popup.offset = 0; popup:Hide()
    popup:SetScript("OnMouseWheel", function(self, delta)
        self.offset = math.max(0, math.min(#self.options - #self.rows, self.offset - delta)); self:Render()
    end)
    function popup:Render()
        for i, row in ipairs(self.rows) do
            local option = self.options[i + self.offset]
            row:SetShown(option ~= nil)
            if option then
                row.option = option; row:SetText(option.label)
                row:SetSelected(option.value == self.owner.value)
            end
        end
    end
    table.insert(UISpecialFrames, "InCharacterDropdownList")
    return popup
end
function U.Dropdown(parent, x, y, width, options, changed)
    local button = U.Button(parent, "", x, y, width)
    button.label:SetJustifyH("LEFT")
    button.arrow = button:CreateFontString(nil, "OVERLAY", "GameFontNormal"); button.arrow:SetPoint("RIGHT", -8, 0); button.arrow:SetText("v")
    button.label:SetPoint("RIGHT", -22, 0)
    button.values = options or {}
    function button:SetOptions(values) self.values = values; self:SetValue(self.value) end
    function button:SetValue(value)
        self.value = value
        local label = value ~= nil and tostring(value) or ""
        for _, option in ipairs(self.values) do if option.value == value then label = option.label; break end end
        self:SetText(label)
    end
    function button:Choose(value) self:SetValue(value); if changed then changed(value) end end
    button:SetScript("OnClick", function(self)
        local list = Popup()
        if list:IsShown() and list.owner == self then list:Hide(); return end
        list.owner, list.options, list.offset = self, self.values, 0
        local count = math.min(#self.values, 12)
        for i = #list.rows + 1, count do
            local row = U.Button(list, "", 2, -2 - (i - 1) * 24, 100, function(r)
                list:Hide(); list.owner:Choose(r.option.value)
            end)
            row:SetHeight(24); row.label:SetJustifyH("LEFT"); list.rows[i] = row
        end
        for i, row in ipairs(list.rows) do row:SetWidth(self:GetWidth() - 4); if i > count then row:Hide() end end
        list:SetSize(self:GetWidth(), count * 24 + 4)
        list:ClearAllPoints(); list:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        list:Render(); list:Show(); list:Raise()
    end)
    if button.values[1] then button:SetValue(button.values[1].value) end
    return button
end
function U.Options(values)
    local result = {}
    for _, value in ipairs(values) do result[#result + 1] = { value = value, label = value } end
    return result
end

function U.Check(parent, text, x, y, changed)
    local button = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    button:SetPoint("TOPLEFT", x, y); button:SetSize(24, 24)
    button.caption = U.Label(button, text, 28, -5, 300)
    button:SetScript("OnClick", function(self) changed(self:GetChecked() == true) end)
    return button
end

-- Horizontal slider with a caption that shows the current value.
function U.Slider(parent, text, x, y, width, minimum, maximum, step, changed)
    local caption = U.Label(parent, text, x, y, width)
    local slider = CreateFrame("Slider", nil, parent, "UISliderTemplate")
    slider:SetPoint("TOPLEFT", x, y - 20); slider:SetSize(width, 14)
    slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(minimum, maximum); slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true); slider:EnableMouse(true)
    if not slider:GetThumbTexture() then slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal") end
    local thumb = slider:GetThumbTexture(); thumb:SetSize(24, 30)
    slider.caption, slider.text = caption, text
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        self.caption:SetText(self.text .. ": " .. value)
        if self.ready and changed then changed(value) end
    end)
    function slider:Set(value) self.ready = false; self:SetValue(value); self.caption:SetText(self.text .. ": " .. value); self.ready = true end
    slider.ready = true
    return slider
end

function U.Input(parent, x, y, width)
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetPoint("TOPLEFT", x + 6, y); input:SetSize(width - 6, 24); input:SetAutoFocus(false)
    input:SetScript("OnEscapePressed", input.ClearFocus); input:SetScript("OnEnterPressed", input.ClearFocus)
    return input
end

-- Vertical scrolling: mouse wheel plus a thin draggable bar. content is the scroll child.
function U.Scroll(parent, x, y, width, height)
    local holder = U.Panel(parent, width, height, C.bg)
    holder:SetPoint("TOPLEFT", x, y)
    local scroll = CreateFrame("ScrollFrame", nil, holder)
    scroll:SetPoint("TOPLEFT", 4, -4); scroll:SetPoint("BOTTOMRIGHT", -14, 4)
    local content = CreateFrame("Frame", nil, scroll); content:SetSize(width - 18, 1)
    scroll:SetScrollChild(content)
    local bar = CreateFrame("Slider", nil, holder)
    bar:SetPoint("TOPRIGHT", -3, -4); bar:SetPoint("BOTTOMRIGHT", -3, 4); bar:SetWidth(8)
    bar:SetOrientation("VERTICAL"); bar:SetMinMaxValues(0, 0); bar:SetValueStep(1); bar:EnableMouse(true)
    bar:SetThumbTexture(WHITE); local thumb = bar:GetThumbTexture(); thumb:SetSize(8, 30); thumb:SetVertexColor(unpack(C.border))
    bar:SetScript("OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)
    holder.scroll, holder.content, holder.bar = scroll, content, bar
    function holder:SetContentHeight(contentHeight)
        content:SetHeight(math.max(1, contentHeight))
        local range = math.max(0, contentHeight - (height - 8))
        bar:SetMinMaxValues(0, range); bar:SetShown(range > 0)
        if bar:GetValue() > range then bar:SetValue(range) end
    end
    function holder:ScrollTo(value) bar:SetValue(value) end
    holder:EnableMouseWheel(true)
    holder:SetScript("OnMouseWheel", function(_, delta) bar:SetValue(bar:GetValue() - delta * 40) end)
    return holder
end

-- Multi-line text field inside a scroll area.
function U.TextArea(parent, x, y, width, height)
    local area = U.Scroll(parent, x, y, width, height)
    local edit = CreateFrame("EditBox", nil, area.content)
    edit:SetPoint("TOPLEFT", 4, -2); edit:SetWidth(width - 30); edit:SetMultiLine(true)
    edit:SetAutoFocus(false); edit:SetFontObject("GameFontHighlight"); edit:SetTextInsets(0, 0, 2, 2)
    local measure = area:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    measure:SetWidth(width - 30); measure:SetWordWrap(true); measure:Hide()
    edit:SetScript("OnEscapePressed", edit.ClearFocus)
    edit:SetScript("OnTextChanged", function(self)
        measure:SetText(self:GetText())
        local textHeight = math.max(height - 12, measure:GetStringHeight() + 24)
        self:SetHeight(textHeight); area:SetContentHeight(textHeight)
        if self.changed then self.changed(self:GetText()) end
    end)
    edit:SetScript("OnCursorChanged", function(_, _, cursorY, _, cursorHeight)
        local top = area.bar:GetValue(); cursorY = -cursorY
        if cursorY < top then area:ScrollTo(cursorY)
        elseif cursorY + cursorHeight > top + height - 8 then area:ScrollTo(cursorY + cursorHeight - height + 8) end
    end)
    area:EnableMouse(true); area:SetScript("OnMouseDown", function() edit:SetFocus() end)
    area.content:EnableMouse(true); area.content:SetScript("OnMouseDown", function() edit:SetFocus() end)
    edit:SetText(""); edit.area = area
    return edit
end

-- Two clicks to confirm destructive buttons.
function U.Confirm(button, text, action)
    if button.confirming then button.confirming = nil; button:SetText(text); action()
    else button.confirming = true; button:SetText("Click again: " .. text) end
end

-- Key capture for one of the addon's bindings. Writes the binding with SetBinding/SaveBindings.
local MODIFIER_KEYS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true,
    LMETA = true, RMETA = true, UNKNOWN = true }
U.MOUSE_KEYS = { MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }
local MOUSE_KEYS = U.MOUSE_KEYS
local stopCapture
function U.Modifiers()
    return IC.Platform.Modifiers()
end
function U.KeyLabel(action)
    local key = IC.Platform.BindingKeys(action)
    return key or "not set"
end
function U.KeyCapture(parent, x, y, width, action, caption, changed)
    local button = U.Button(parent, "", x, y, width)
    local function refresh() button:SetText(caption .. ": " .. U.KeyLabel(action)); button:SetSelected(false) end
    local function restorePropagation()
        if not IC.InCombat() then button:SetPropagateKeyboardInput(true) end
        button:SetScript("OnUpdate", nil)
    end
    local function finish(consumeKey)
        button.capturing = false
        button:SetScript("OnKeyDown", nil); button:SetScript("OnUpdate", nil)
        button:EnableKeyboard(false)
        -- Propagation cannot be changed in combat. With keyboard input disabled
        -- and the handler removed, this widget cannot consume a key either way.
        -- Keep this key consumed until dispatch ends; otherwise assigning a key
        -- could immediately run its new binding. Restore propagation next frame.
        if consumeKey then button:SetScript("OnUpdate", restorePropagation)
        else restorePropagation() end
        if stopCapture == button.StopCapture then stopCapture = nil end
        refresh()
    end
    button.StopCapture = finish
    local function safely(change, consumeKey)
        -- Release input before any client API or callback that could throw.
        finish(consumeKey)
        local ok, problem = pcall(change)
        refresh()
        if not ok then IC.Print("Key binding change failed: " .. tostring(problem)) end
    end
    local function assign(key, consumeKey)
        safely(function()
            if IC.InCombat() then IC.Print("Key bindings cannot be changed in combat."); return end
            local combo = U.Modifiers() .. key
            local previous = IC.Platform.BindingAction(combo)
            local old = { IC.Platform.BindingKeys(action) }
            if not IC.Platform.SetBinding(combo, action) then IC.Print("Binding was refused; existing keys were kept."); return end
            for _, key in ipairs(old) do if key ~= combo then IC.Platform.SetBinding(key) end end
            IC.Platform.SaveBindings()
            if previous and previous ~= "" and previous ~= action then
                IC.Print(combo .. " replaced " .. (_G["BINDING_NAME_" .. previous] or previous) .. ".")
            end
            if changed then changed(combo) end
        end, consumeKey)
    end
    local function keyDown(self, key)
        if not self.capturing then finish(); return end
        if key == "ESCAPE" then finish(true); return end
        if MODIFIER_KEYS[key] then return end
        assign(key, true)
    end
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(self, mouse)
        if self.capturing then finish(); return end
        if IC.InCombat() then IC.Print("Key bindings cannot be changed in combat."); return end
        if stopCapture then stopCapture() end
        if mouse == "RightButton" then
            safely(function()
                local old, guard = IC.Platform.BindingKeys(action), 0
                while old and guard < 4 do IC.Platform.SetBinding(old); old = IC.Platform.BindingKeys(action); guard = guard + 1 end
                IC.Platform.SaveBindings(); refresh()
                if changed then changed() end
            end)
            return
        end
        IC.Platform.ClearKeyboardFocus()
        stopCapture = finish
        self.capturing = true; self:SetSelected(true)
        self:SetText("Press a key... (Esc / click cancels)")
        self:SetScript("OnKeyDown", keyDown)
        self:SetPropagateKeyboardInput(false); self:EnableKeyboard(true)
        local deadline = IC.Platform.Time() + 15
        self:SetScript("OnUpdate", function() if IC.Platform.Time() >= deadline then finish() end end)
    end)
    button:SetScript("OnMouseDown", function(self, mouse)
        if self.capturing and MOUSE_KEYS[mouse] then assign(MOUSE_KEYS[mouse]) end
    end)
    button:SetScript("OnHide", function(self) if self.capturing then finish() end end)
    U.captures = U.captures or {}; table.insert(U.captures, finish)
    button.tooltip = "Click, then press a key within 15 seconds. Escape or another click cancels. Right-click clears an existing binding. You can also use WoW's Key Bindings > In Character."
    button.Refresh = refresh
    -- Idle binding buttons must never register a keyboard handler or consume input.
    finish()
    return button
end
