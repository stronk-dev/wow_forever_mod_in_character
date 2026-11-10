local _, IC = ...
-- One round button with the convention every addon launcher follows: left-click opens the emote
-- menu, right-click opens the settings. Shift-drag moves it. Not configurable.
IC.Launcher = {}
local L, U = IC.Launcher, IC.UI
local unpack = unpack or table.unpack

local function config() return IC.Layout().launcher end

function L.StopDrag()
    local button = L.button
    if not button or not button.moving then return end
    button:StopMovingOrSizing(); button.moving = nil
    local x, y = button:GetCenter(); local px, py = UIParent:GetCenter()
    config().x, config().y = x - px, y - py
    button.suppressUntil = IC.Platform.Time() + 0.15
end

function L.Create()
    local button = U.IconButton(UIParent, 36, true)
    L.button = button
    button:SetFrameStrata("MEDIUM"); button:SetClampedToScreen(true); button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp"); button:RegisterForDrag("LeftButton")
    button:SetIcon(IC.AddonIcon)
    button:SetScript("OnClick", function(self, mouse)
        if self.suppressUntil and IC.Platform.Time() < self.suppressUntil then return end
        if IC.Bars.editing then IC.Bars.SelectLauncher(); return end
        if mouse == "RightButton" then IC.Editor.Toggle() elseif mouse == "LeftButton" then IC.Menu.Open(self) end
    end)
    button:SetScript("OnDragStart", function(self)
        if IC.InCombat() then return end
        if IC.Bars.editing then IC.Bars.SelectLauncher() end
        if IC.Bars.editing or IC.Platform.Shift() then self.moving = true; self:StartMoving() end
    end)
    button:SetScript("OnDragStop", L.StopDrag)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText("In Character", 1, 1, 1)
        GameTooltip:AddLine("Playing: " .. IC.Personas.Name(), 1, 0.82, 0)
        GameTooltip:AddLine("Left-click: emote menu", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right-click: settings", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift-drag: move", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:RegisterEvent("PLAYER_REGEN_DISABLED"); button:SetScript("OnEvent", function(self)
        L.StopDrag()
        if config().shown == false then self:Hide() end
    end)
end

function L.Refresh()
    if not L.button then L.Create() end
    local settings = config()
    local size = math.max(24, math.min(64, tonumber(settings.size) or 36))
    L.button:SetRoundSize(size)
    L.button.ring:SetVertexColor(unpack(IC.Bars.editing and { 0.25, 0.62, 0.95, 1 } or U.Colors.accent))
    L.button:ClearAllPoints(); L.button:SetPoint("CENTER", UIParent, "CENTER", settings.x, settings.y)
    L.button:SetShown(settings.shown ~= false or IC.Bars.editing == true)
end
