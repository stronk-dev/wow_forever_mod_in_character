local _, IC = ...
local unpack = unpack or table.unpack
-- Small widget kit. It only uses templates other Forever addons rely on (BackdropTemplate,
-- InputBoxTemplate, UICheckButtonTemplate); dropdowns, sliders, lists and scrolling are plain frames.
IC.UI = {}
local U = IC.UI
local WHITE = "Interface\\Buttons\\WHITE8X8"
U.CIRCLE_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
U.Colors = {
    bg = { 0.05, 0.05, 0.07, 0.97 }, panel = { 0.09, 0.09, 0.12, 1 }, raised = { 0.14, 0.14, 0.18, 1 },
    hover = { 0.2, 0.2, 0.26, 1 }, border = { 0.24, 0.24, 0.3, 1 }, accent = { 1, 0.78, 0.25, 1 },
    accentDim = { 0.45, 0.35, 0.12, 1 }, text = { 0.92, 0.92, 0.95, 1 }, muted = { 0.6, 0.6, 0.66, 1 },
}
local C = U.Colors

function U.Backdrop(frame, color, border)
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(unpack(color or C.panel))
    frame:SetBackdropBorderColor(unpack(border or C.border))
end
function U.GameBackdrop(frame)
    frame:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    frame:SetBackdropColor(0.06, 0.06, 0.08, 0.9); frame:SetBackdropBorderColor(0.65, 0.65, 0.65, 0.9)
end
function U.Panel(parent, width, height, color, name)
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    if width then frame:SetSize(width, height) end
    U.Backdrop(frame, color)
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
        local replacement = fallback or question
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

-- Flat button. style = "accent" for the main action on a page.
function U.Button(parent, text, x, y, width, click, style)
    local native = UIPanelButtonHeightScaledMixin and "UIPanelButtonHeightScaledTemplate" or "UIPanelButtonTemplate"
    local button = CreateFrame("Button", nil, parent, style == "native" and native or "BackdropTemplate")
    button:SetSize(width or 120, 26)
    if x then button:SetPoint("TOPLEFT", x, y) end
    button.style = style
    if style ~= "native" then U.Backdrop(button, style == "accent" and C.accentDim or C.raised, style == "accent" and C.accent or C.border) end
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.label:SetPoint("LEFT", 8, 0); button.label:SetPoint("RIGHT", -8, 0)
    button.label:SetJustifyH("CENTER"); button.label:SetWordWrap(false)
    function button:SetText(value) self.text = value; self.label:SetText(value) end
    function button:GetText() return self.text or "" end
    function button:SetSelected(selected)
        self.selected = selected
        if self.style == "native" then return end
        U.Backdrop(self, selected and C.accentDim or (self.style == "accent" and C.accentDim or C.raised),
            selected and C.accent or (self.style == "accent" and C.accent or C.border))
    end
    button:SetScript("OnEnter", function(self)
        if not self.selected and self.style ~= "native" then self:SetBackdropColor(unpack(C.hover)) end
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
    U.Backdrop(popup, C.bg, C.accent); popup:SetFrameStrata("FULLSCREEN_DIALOG"); popup:SetClampedToScreen(true)
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
        list:Render(); list:Show()
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
    local slider = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    slider:SetPoint("TOPLEFT", x, y - 20); slider:SetSize(width, 14)
    slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(minimum, maximum); slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true); U.Backdrop(slider, C.raised); slider:EnableMouse(true)
    slider:SetThumbTexture(WHITE)
    local thumb = slider:GetThumbTexture(); thumb:SetSize(10, 18); thumb:SetVertexColor(unpack(C.accent))
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
    return (IsAltKeyDown() and "ALT-" or "") .. (IsControlKeyDown() and "CTRL-" or "") .. (IsShiftKeyDown() and "SHIFT-" or "")
end
function U.KeyLabel(action)
    local key = GetBindingKey and GetBindingKey(action)
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
            local previous = GetBindingAction and GetBindingAction(combo)
            local old = { GetBindingKey(action) }
            if not SetBinding(combo, action) then IC.Print("Binding was refused; existing keys were kept."); return end
            for _, key in ipairs(old) do if key ~= combo then SetBinding(key) end end
            SaveBindings(GetCurrentBindingSet())
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
                local old, guard = GetBindingKey(action), 0
                while old and guard < 4 do SetBinding(old); old = GetBindingKey(action); guard = guard + 1 end
                SaveBindings(GetCurrentBindingSet()); refresh()
                if changed then changed() end
            end)
            return
        end
        local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
        if focus then focus:ClearFocus() end
        stopCapture = finish
        self.capturing = true; self:SetSelected(true)
        self:SetText("Press a key... (Esc / click cancels)")
        self:SetScript("OnKeyDown", keyDown)
        self:SetPropagateKeyboardInput(false); self:EnableKeyboard(true)
        local deadline = GetTime() + 15
        self:SetScript("OnUpdate", function() if GetTime() >= deadline then finish() end end)
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
