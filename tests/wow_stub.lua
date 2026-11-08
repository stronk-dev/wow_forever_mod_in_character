-- Deliberately limited widget surface: unknown methods fail instead of silently succeeding.
-- This exercises callbacks/data flow, not rendering or Blizzard's protected-action rules.
local Stub = { frames = {}, clock = 0, combat = false, sends = {}, emotes = {}, bindings = {}, missing = {}, modifiers = {} }
local methods = {}
local function noop() end
for _, name in ipairs({ "SetJustifyH", "SetFontObject", "SetWordWrap", "SetAutoFocus", "SetMultiLine", "SetBackdrop",
    "SetBackdropColor", "SetBackdropBorderColor", "SetFrameStrata", "SetFrameLevel", "SetClampedToScreen", "SetMovable",
    "EnableMouse", "EnableMouseWheel", "RegisterForDrag", "RegisterForClicks", "SetTexCoord", "SetVertexColor",
    "SetColorTexture", "StartMoving", "StopMovingOrSizing", "ClearFocus", "SetFocus", "SetTextInsets", "SetTextColor",
    "SetToplevel", "Raise", "SetOrientation", "SetValueStep", "SetObeyStepOnDrag", "SetPropagateKeyboardInput",
    "SetPushedTexture", "SetClampRectInsets", "SetBlendMode", "SetAlpha" }) do methods[name] = noop end
function methods:GetRight() local x = self:GetCenter(); return x + self:GetWidth() / 2 end
local widget
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetWidth() return self.width or 100 end
function methods:GetHeight() return self.height or 24 end
function methods:SetPoint(point, relative, relativePoint, x, y)
    if type(relative) == "number" or relative == nil then
        self.x, self.y = relative or 0, relativePoint or 0; self.relative = self.parent; self.point = point
    else self.x, self.y, self.relative, self.point, self.relativePoint = x or 0, y or 0, relative, point, relativePoint or point end
end
function methods:ClearAllPoints() self.x, self.y, self.relative = 0, 0, nil end
function methods:SetAllPoints(relative) self.relative = type(relative) == "table" and relative or self.parent; self.x, self.y = 0, 0 end
-- Centers are modelled for CENTER anchors only (the wheel and bars), which is what the tests measure.
function methods:GetCenter()
    if self == UIParent then return 960, 540 end
    local parent = self.relative or self.parent or UIParent
    local x, y = parent:GetCenter()
    if self.relativePoint == "BOTTOMLEFT" and parent == UIParent then x, y = 0, 0 end
    return x + (self.x or 0), y + (self.y or 0)
end
function methods:SetScale(value) self.scale = value end
function methods:GetScale() return self.scale or 1 end
function methods:GetEffectiveScale() return (self.scale or 1) * (self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:GetScript(name) return self.scripts[name] end
function methods:GetParent() return self.parent end
function methods:Show()
    local wasShown = self.shown; self.shown = true
    if not wasShown and self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:Hide()
    local wasShown = self.shown; self.shown = false
    if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown and (not self.parent or self.parent:IsShown()) end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:SetText(value)
    self.text = value
    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self, false) end
end
function methods:GetText() return self.text or "" end
function methods:SetTexture(value)
    if value ~= nil and Stub.missing[value] then return false end
    self.texture = value; return true
end
function methods:SetDesaturated(value) self.desaturated = value end
function methods:AddMaskTexture(mask) self.mask = mask end
function methods:CreateMaskTexture() return widget("MaskTexture", nil, self) end
function methods:SetHighlightTexture(path) self.highlight = path end
function methods:SetNormalTexture(path) self.normal = widget("Texture", nil, self); self.normal:SetTexture(path) end
function methods:GetNormalTexture() return self.normal end
function methods:SetThumbTexture(path) self.thumb = widget("Texture", nil, self); self.thumb:SetTexture(path) end
function methods:GetThumbTexture() return self.thumb end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked or false end
function methods:SetEnabled(value) self.enabled = value end
function methods:IsEnabled() return self.enabled ~= false end
function methods:EnableKeyboard(value) self.keyboard = value end
function methods:SetMinMaxValues(low, high) self.low, self.high = low, high end
function methods:SetValue(value)
    value = math.max(self.low or value, math.min(self.high or value, value)); self.value = value
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
end
function methods:GetValue() return self.value or 0 end
function methods:SetScrollChild(child) self.scrollChild = child end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:SetVerticalScroll(value) self.scroll = value end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:Fire(event, ...) if self.scripts[event] then return self.scripts[event](self, ...) end end
function methods:Click(mouse) return self:Fire("OnClick", mouse or "LeftButton") end
widget = function(kind, name, parent)
    local object = { kind = kind, name = name, parent = parent, scripts = {}, events = {}, shown = true, children = {} }
    setmetatable(object, { __index = function(_, method)
        if methods[method] then return methods[method] end
        if method == "GetStringHeight" and kind == "FontString" then return function(self)
            local rows = 1; for _ in self:GetText():gmatch("\n") do rows = rows + 1 end; return rows * 14
        end end
        if method == "CreateFontString" then return function(self) return widget("FontString", nil, self) end end
        if method == "CreateTexture" then return function(self) return widget("Texture", nil, self) end end
        -- Unknown keys are nil, as on real frames; calling an unknown method still errors.
        return nil
    end })
    Stub.frames[#Stub.frames + 1] = object
    if parent then parent.children[#parent.children + 1] = object end
    if name then _G[name] = object end
    return object
end
function Stub.Install()
    UIParent = widget("Frame", "UIParent"); UIParent:SetSize(1920, 1080)
    UISpecialFrames, SlashCmdList = {}, {}
    GameTooltip = { SetOwner = noop, SetText = noop, AddLine = noop, Show = noop, Hide = noop }
    DEFAULT_CHAT_FRAME = { AddMessage = noop }
    CreateFrame = function(kind, name, parent) return widget(kind, name, parent) end
    GetTime = function() return Stub.clock end
    InCombatLockdown = function() return Stub.combat end
    GetCursorPosition = function() return Stub.cursorX or 960, Stub.cursorY or 540 end
    UnitFullName = function() return "Tester", "Realm" end
    UnitName = function() return "Tester" end
    GetRealmName = function() return "Realm" end
    IsShiftKeyDown = function() return Stub.modifiers.shift end
    IsControlKeyDown = function() return Stub.modifiers.ctrl end
    IsAltKeyDown = function() return Stub.modifiers.alt end
    GetBindingKey = function(action) for key, bound in pairs(Stub.bindings) do if bound == action then return key end end end
    GetBindingAction = function(key) return Stub.bindings[key] or "" end
    SetBinding = function(key, action) Stub.bindings[key] = action; return true end
    GetCurrentBindingSet = function() return 1 end
    SaveBindings = function() Stub.savedBindings = (Stub.savedBindings or 0) + 1 end
    GetMacroIcons = function(t) t[#t + 1] = 134400; t[#t + 1] = 136243 end
    Settings = {
        RegisterCanvasLayoutCategory = function(frame, name) Stub.settingsPanel = frame; return { name = name } end,
        RegisterAddOnCategory = function(category) Stub.settingsCategory = category end,
    }
    C_ChatInfo = { SendChatMessage = function(text, channel) Stub.sends[#Stub.sends + 1] = { text, channel } end }
    DoEmote = function(token) Stub.emotes[#Stub.emotes + 1] = token end
    EMOTE1_TOKEN, EMOTE1_CMD1 = "WAVE", "/wave"
    EMOTE2_TOKEN, EMOTE2_CMD1 = "CHEER", "/cheer"
    EMOTE3_TOKEN, EMOTE3_CMD1 = "CHICKEN", "/chicken"
    EMOTE4_TOKEN, EMOTE4_CMD1 = "DANCE", "/dance"
    EMOTE5_TOKEN, EMOTE5_CMD1, EMOTE5_CMD2 = "SILLY", "/silly", "/joke"
    EMOTE6_TOKEN, EMOTE6_CMD1 = "CHARGE", "/charge"
    EMOTE7_TOKEN, EMOTE7_CMD1 = "FORVEREXCLUSIVE", "/foreveronly"
end
-- Finds a descendant button by its text.
function Stub.Button(parent, text)
    local function search(node)
        for _, child in ipairs(node.children) do
            if child.kind == "Button" and child.GetText and child:GetText() == text then return child end
            local found = search(child); if found then return found end
        end
    end
    return search(parent) or error("Button not found: " .. text)
end
return Stub
