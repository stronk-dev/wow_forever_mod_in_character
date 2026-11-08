-- Deliberately limited widget surface: unknown methods fail instead of silently succeeding.
-- This exercises callbacks/data flow, not rendering or Blizzard's protected-action rules.
local Stub = { frames = {}, clock = 0, combat = false, sends = {}, emotes = {} }
local methods = {}
local function noop() end
for _, name in ipairs({ "SetJustifyH", "SetFontObject", "SetWordWrap", "SetAutoFocus", "SetMultiLine", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetFrameStrata", "SetFrameLevel", "SetClampedToScreen", "SetMovable", "EnableMouse", "EnableMouseWheel", "RegisterForDrag", "RegisterForClicks", "SetHighlightTexture", "SetTexCoord", "SetVertexColor", "SetColorTexture", "UpdateScrollChildRect", "StartMoving", "StopMovingOrSizing", "ClearFocus" }) do methods[name] = noop end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:GetWidth() return self.width or 100 end
function methods:GetHeight() return self.height or 24 end
function methods:SetPoint(point, relative, relativePoint, x, y)
    if type(relative) == "number" then
        self.x, self.y = relative, relativePoint; self.relative = self.parent; self.point = point
    else self.x, self.y, self.relative, self.point, self.relativePoint = x or 0, y or 0, relative or self.parent, point, relativePoint or "CENTER" end
end
function methods:ClearAllPoints() self.x, self.y, self.relative = 0, 0, nil end
function methods:SetAllPoints(relative) self.relative = relative or self.parent end
function methods:GetCenter()
    if self == UIParent then return 960, 540 end
    local parent = self.relative or self.parent or UIParent
    local x, y = parent:GetCenter()
    return x + (self.x or 0), y + (self.y or 0)
end
function methods:SetScale(value) self.scale = value end
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
function methods:SetTexture(value) self.texture = value end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked or false end
function methods:SetScrollChild(child) self.scrollChild = child end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:SetVerticalScroll(value) self.scroll = value end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:Fire(event, ...) if self.scripts[event] then return self.scripts[event](self, ...) end end
function methods:Click(mouse) return self:Fire("OnClick", mouse or "LeftButton") end
local function widget(kind, name, parent)
    local object = setmetatable({ kind = kind, name = name, parent = parent, scripts = {}, events = {}, shown = true, children = {} }, { __index = function(_, method)
        error("Unsupported " .. kind .. " method: " .. tostring(method))
    end })
    -- Normal method lookup still fails for FontString-only methods on EditBox.
    setmetatable(object, { __index = function(_, method)
        if methods[method] then return methods[method] end
        if method == "GetStringHeight" and kind == "FontString" then return function(self)
            local rows = 1; for _ in self:GetText():gmatch("\n") do rows = rows + 1 end; return rows * 14
        end end
        if method == "CreateFontString" then return function(self) return widget("FontString", nil, self) end end
        if method == "CreateTexture" then return function(self) return widget("Texture", nil, self) end end
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
    CreateFrame = widget
    GetTime = function() return Stub.clock end
    InCombatLockdown = function() return Stub.combat end
    GetCursorPosition = function() return Stub.cursorX or 0, Stub.cursorY or 0 end
    UnitFullName = function() return "Tester", "Realm" end
    UnitName = function() return "Tester" end
    GetRealmName = function() return "Realm" end
    C_ChatInfo = { SendChatMessage = function(text, channel) Stub.sends[#Stub.sends + 1] = { text, channel } end }
    DoEmote = function(token) Stub.emotes[#Stub.emotes + 1] = token end
    EMOTE1_TOKEN, EMOTE1_CMD1 = "WAVE", "/wave"
end
function Stub.Button(parent, text)
    for _, child in ipairs(parent.children) do if child.kind == "Button" and child:GetText() == text then return child end end
    error("Button not found: " .. text)
end
return Stub
