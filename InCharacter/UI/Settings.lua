local _, IC = ...
-- Game menu integration: an "In Character" page under Options > AddOns and the addon compartment entry.
IC.SettingsPanel = {}
local S, U = IC.SettingsPanel, IC.UI

function S.Register()
    if S.category then return end
    local panel = CreateFrame("Frame")
    panel:SetSize(600, 400)
    local logo = U.IconButton(panel, 40, true); logo:SetPoint("TOPLEFT", 16, -16); logo:SetIcon(IC.AddonIcon); logo:EnableMouse(false)
    U.Heading(panel, "In Character", 68, -18)
    U.Muted(panel, "Emotes and roleplay lines from one small bar, an emote menu or a radial wheel.", 68, -40, 500)
    local function close() IC.Platform.CloseSettings() end
    U.Button(panel, "Emotes & lists", 16, -76, 150, function() close(); IC.Editor.Open("Lists") end, "accent")
    U.Button(panel, "RP lines", 172, -76, 120, function() close(); IC.Editor.Open("Lines") end)
    U.Button(panel, "Layout & keys", 298, -76, 130, function() close(); IC.Editor.Open("Layout") end)
    panel.editLayouts = U.Button(panel, "Move & edit bars", 434, -76, 140, function() close(); IC.Bars.SetEditing(true) end)
    panel.launcher = U.Check(panel, "Show the launcher button", 16, -116, function(value) IC.Layout().launcher.shown = value; IC.Changed() end)
    panel.wheelKey = U.KeyCapture(panel, 16, -150, 240, "INCHARACTER_WHEEL", "Radial wheel key")
    panel.menuKey = U.KeyCapture(panel, 264, -150, 240, "INCHARACTER_MENU", "Emote menu key")
    U.Muted(panel, "Commands: /ic opens the window, /ic wheel, /ic menu, /ic edit, /ic greet | quote | bye, /ic <pool name>.", 16, -190, 560)
    panel:SetScript("OnShow", function()
        if not IC.db then return end
        panel.launcher:SetChecked(IC.Layout().launcher.shown); panel.wheelKey.Refresh(); panel.menuKey.Refresh()
    end)
    local category = IC.Platform.RegisterSettings(panel)
    if not category then return end
    S.category, S.panel = category, panel
end

-- Declared in the TOC as AddonCompartmentFunc.
-- Newer clients pass a table with buttonName; older ones pass the button name.
function InCharacter_OnAddonCompartmentClick(_, mouse)
    if not IC.db then return end
    if type(mouse) == "table" then mouse = mouse.buttonName end
    if mouse == "RightButton" then IC.Editor.Open() else IC.Menu.OpenAtCursor() end
end
function InCharacter_OnAddonCompartmentEnter(_, frame)
    if type(frame) == "table" and frame.GetObjectType then GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
    else GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR") end
    GameTooltip:SetText("In Character", 1, 1, 1)
    GameTooltip:AddLine("Playing: " .. IC.Personas.Name(), 1, 0.82, 0)
    GameTooltip:AddLine("Left-click: emote menu", 0.8, 0.8, 0.8); GameTooltip:AddLine("Right-click: settings", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end
function InCharacter_OnAddonCompartmentLeave() GameTooltip:Hide() end
