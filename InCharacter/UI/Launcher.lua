local _, IC = ...
-- One draggable round button: left-click opens the emote menu (or the wheel), right-click opens settings.
IC.Launcher = {}
local L, U = IC.Launcher, IC.UI

local function config() return IC.Layout().launcher end

function L.Create()
    local button = U.IconButton(UIParent, 40, true)
    L.button = button
    button:SetFrameStrata("MEDIUM"); button:SetClampedToScreen(true); button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp"); button:RegisterForDrag("LeftButton")
    button:SetIcon(IC.AddonIcon)
    button:SetScript("OnClick", function(self, mouse)
        if mouse == "RightButton" then IC.Editor.Open("Home"); return end
        if config().click == "wheel" then IC.Wheel.Toggle() else IC.Menu.Open(self) end
    end)
    button:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter(); local px, py = UIParent:GetCenter()
        config().x, config().y = x - px, y - py
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText("In Character", 1, 1, 1)
        GameTooltip:AddLine("Left-click: " .. (config().click == "wheel" and "radial wheel" or "emote menu"), 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right-click: settings", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift-drag: move", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function L.Refresh()
    if not L.button then L.Create() end
    local settings = config()
    local size = math.max(28, math.min(64, tonumber(settings.size) or 40))
    L.button:SetRoundSize(size)
    L.button:ClearAllPoints(); L.button:SetPoint("CENTER", UIParent, "CENTER", settings.x, settings.y)
    L.button:SetShown(settings.shown ~= false)
end
