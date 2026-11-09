local _, IC = ...
-- One draggable button: left-click toggles quick access, right-click opens settings.
IC.Launcher = {}
local L, U = IC.Launcher, IC.UI

local function config() return IC.Layout().launcher end
L.choices = { { value = "wheel", label = "Radial wheel" }, { value = "menu", label = "Context menu" },
    { value = "bars", label = "Show / hide RP bar" }, { value = "quick", label = "Optional quick style" },
    { value = "edit", label = "Edit layouts" }, { value = "editor", label = "Settings" } }
function L.Activate(action, anchor)
    if action == "wheel" then IC.Wheel.Toggle()
    elseif action == "menu" then if IC.Menu.IsOpen() then IC.Menu.Close() elseif anchor then IC.Menu.Open(anchor) else IC.Menu.OpenAtCursor() end
    elseif action == "bars" then IC.Bars.ToggleCatalog()
    elseif action == "edit" then IC.Bars.SetEditing(not IC.Bars.editing)
    elseif action == "editor" then IC.Editor.Open("Home")
    else IC.QuickActions.Toggle() end
end

function L.Create()
    local button = U.IconButton(UIParent, 40, true)
    L.button = button
    button:SetFrameStrata("MEDIUM"); button:SetClampedToScreen(true); button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp"); button:RegisterForDrag("LeftButton")
    button:SetIcon(IC.AddonIcon)
    button:SetScript("OnClick", function(self, mouse)
        if self.suppressUntil and GetTime() < self.suppressUntil then return end
        if IC.Bars.editing then IC.Bars.SelectLauncher(); return end
        if mouse == "RightButton" and IsShiftKeyDown() then IC.Editor.Open("Home"); return end
        L.Activate(mouse == "RightButton" and config().rightClick or (mouse == "MiddleButton" and config().middleClick or config().click), self)
    end)
    button:SetScript("OnDragStart", function(self)
        if IC.InCombat() then return end
        if IC.Bars.editing then IC.Bars.SelectLauncher() end
        if IC.Bars.editing or IsShiftKeyDown() then self:StartMoving() end
    end)
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter(); local px, py = UIParent:GetCenter()
        config().x, config().y = x - px, y - py
        self.suppressUntil = GetTime() + 0.15
        IC.Bars.RefreshInspector()
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:SetText("In Character", 1, 1, 1)
        for _, entry in ipairs({ { "Left-click", config().click }, { "Right-click", config().rightClick }, { "Middle-click", config().middleClick } }) do
            local label = entry[2]; for _, choice in ipairs(L.choices) do if choice.value == entry[2] then label = choice.label end end
            GameTooltip:AddLine(entry[1] .. ": " .. label, 0.8, 0.8, 0.8)
        end
        GameTooltip:AddLine("Shift-right-click: settings", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift-drag: move", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:RegisterEvent("PLAYER_REGEN_DISABLED"); button:SetScript("OnEvent", function(self) self:StopMovingOrSizing() end)
end

function L.Refresh()
    if not L.button then L.Create() end
    local settings = config()
    local size = math.max(28, math.min(64, tonumber(settings.size) or 40))
    L.button:SetRoundSize(size)
    local tint = IC.Bars.editing and { 0.25, 0.62, 0.95, 1 } or U.Colors.accent
    L.button.ring:SetVertexColor((unpack or table.unpack)(tint))
    L.button:ClearAllPoints(); L.button:SetPoint("CENTER", UIParent, "CENTER", settings.x, settings.y)
    L.button:SetShown(settings.shown ~= false)
end
