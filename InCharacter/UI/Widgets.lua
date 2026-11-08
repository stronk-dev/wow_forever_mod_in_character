local _, IC = ...
IC.UI = {}
local U = IC.UI
function U.Label(parent, text, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y); label:SetJustifyH("LEFT")
    if width then label:SetWidth(width) end
    label:SetText(text)
    return label
end
function U.Button(parent, text, x, y, width, click)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", x, y); button:SetSize(width or 120, 24)
    button:SetText(text); button:SetScript("OnClick", click)
    return button
end
function U.Input(parent, x, y, width)
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetPoint("TOPLEFT", x, y); input:SetSize(width, 24); input:SetAutoFocus(false)
    input:SetScript("OnEscapePressed", input.ClearFocus); input:SetScript("OnEnterPressed", input.ClearFocus)
    return input
end
function U.Cycle(parent, x, y, width, values, changed)
    local button = U.Button(parent, "", x, y, width, function(self)
        if #self.values == 0 then return end
        local index = 1
        for i, option in ipairs(self.values) do if option.value == self.value then index = i % #self.values + 1; break end end
        self:SetValue(self.values[index].value)
        if changed then changed(self.value) end
    end)
    button.values = values
    function button:SetValue(value)
        self.value = value
        local label = tostring(value)
        for _, option in ipairs(self.values) do if option.value == value then label = option.label; break end end
        self:SetText(label .. " >")
    end
    if values[1] then button:SetValue(values[1].value) end
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
    button.caption = U.Label(button, text, 28, -5, 280)
    button:SetScript("OnClick", function(self) changed(self:GetChecked() == true) end)
    return button
end
function U.TextArea(parent, x, y, width, height)
    local border = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    border:SetPoint("TOPLEFT", x, y); border:SetSize(width, height)
    border:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    border:SetBackdropColor(0.03, 0.03, 0.04, 1)
    local scroll = CreateFrame("ScrollFrame", nil, border, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8); scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetWidth(width - 44); edit:SetHeight(height - 16); edit:SetMultiLine(true)
    edit:SetAutoFocus(false); edit:SetFontObject("GameFontHighlight")
    edit:SetScript("OnEscapePressed", edit.ClearFocus)
    edit:SetScript("OnTextChanged", function(self)
        self:SetHeight(math.max(height - 16, self:GetStringHeight() + 20)); scroll:UpdateScrollChildRect()
    end)
    edit:SetScript("OnCursorChanged", function(_, _, cursorY, _, cursorHeight)
        local top = scroll:GetVerticalScroll(); cursorY = -cursorY
        if cursorY < top then scroll:SetVerticalScroll(cursorY)
        elseif cursorY + cursorHeight > top + scroll:GetHeight() then scroll:SetVerticalScroll(cursorY + cursorHeight - scroll:GetHeight()) end
    end)
    scroll:SetScrollChild(edit); edit:SetText("")
    return edit
end
function U.Confirm(button, text, action)
    if button.confirming then button.confirming = nil; button:SetText(text); action()
    else button.confirming = true; button:SetText("Confirm " .. text .. "?") end
end
