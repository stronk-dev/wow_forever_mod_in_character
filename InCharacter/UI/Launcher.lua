local _, IC = ...
-- One round button: left-click opens the emote menu (or the wheel), right-click opens the settings,
-- middle-click moves and edits bars. Shift-drag moves it.
IC.Launcher = {}
local L, U = IC.Launcher, IC.UI
local unpack = unpack or table.unpack
L.choices = { { value = "menu", label = "Emote menu" }, { value = "wheel", label = "Radial wheel" },
    { value = "editor", label = "Settings" }, { value = "edit", label = "Edit Mode" }, { value = "bars", label = "Show / hide bars" }, { value = "none", label = "Nothing" } }

local function config() return IC.Layout().launcher end

function L.Create()
    local button = U.IconButton(UIParent, 36, true)
    L.button = button
    button:SetFrameStrata("MEDIUM"); button:SetClampedToScreen(true); button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp"); button:RegisterForDrag("LeftButton")
    button:SetIcon(IC.AddonIcon)
    button:SetScript("OnClick", function(self, mouse)
        if self.suppressUntil and IC.Platform.Time() < self.suppressUntil then return end
        if IC.Bars.editing then IC.Bars.SelectLauncher(); return end
        local action = mouse == "RightButton" and config().rightClick or mouse == "MiddleButton" and config().middleClick or config().click
        if action == "editor" then IC.Editor.Open()
        elseif action == "edit" then IC.Bars.SetEditing(true)
        elseif action == "bars" then IC.Bars.ToggleAll()
        elseif action == "wheel" then IC.Wheel.Toggle()
        elseif action == "menu" then IC.Menu.Open(self) end
    end)
    button:SetScript("OnDragStart", function(self)
        if IC.InCombat() then return end
        if IC.Bars.editing then IC.Bars.SelectLauncher() end
        if IC.Bars.editing or IC.Platform.Shift() then self:StartMoving() end
    end)
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter(); local px, py = UIParent:GetCenter()
        config().x, config().y = x - px, y - py
        self.suppressUntil = IC.Platform.Time() + 0.15
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText("In Character", 1, 1, 1)
        GameTooltip:AddLine("Left: " .. (config().click or "menu") .. " · Right: " .. (config().rightClick or "editor"), 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Middle: " .. (config().middleClick or "edit") .. " · Shift-drag: move", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:RegisterEvent("PLAYER_REGEN_DISABLED"); button:SetScript("OnEvent", function(self)
        self:StopMovingOrSizing()
        if config().shown == false then self:Hide() end
    end)
end

function L.Refresh()
    if not L.button then L.Create() end
    local settings = config()
    local valid = {}; for _, option in ipairs(L.choices) do valid[option.value] = true end
    if not valid[settings.click] then settings.click = "menu" end
    local size = math.max(24, math.min(64, tonumber(settings.size) or 36))
    L.button:SetRoundSize(size)
    L.button.ring:SetVertexColor(unpack(IC.Bars.editing and { 0.25, 0.62, 0.95, 1 } or U.Colors.accent))
    L.button:ClearAllPoints(); L.button:SetPoint("CENTER", UIParent, "CENTER", settings.x, settings.y)
    L.button:SetShown(settings.shown ~= false or IC.Bars.editing == true)
end
