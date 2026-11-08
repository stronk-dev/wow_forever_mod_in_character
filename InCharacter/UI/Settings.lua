local _, IC = ...
-- Game menu integration: an "In Character" page under Options > AddOns and the addon compartment entry.
IC.SettingsPanel = {}
local S, U = IC.SettingsPanel, IC.UI

function S.Register()
    if S.category or type(Settings) ~= "table" or type(Settings.RegisterCanvasLayoutCategory) ~= "function" then return end
    local panel = CreateFrame("Frame")
    panel:SetSize(600, 400)
    local logo = U.IconButton(panel, 40, true); logo:SetPoint("TOPLEFT", 16, -16); logo:SetIcon(IC.AddonIcon); logo:EnableMouse(false)
    U.Heading(panel, "In Character", 68, -18)
    U.Muted(panel, "Emotes and roleplay lines from a button menu, a radial wheel or action bars.", 68, -40, 500)
    U.Button(panel, "Open In Character", 16, -76, 200, function()
        if SettingsPanel and SettingsPanel.Close then pcall(SettingsPanel.Close, SettingsPanel, true) end
        IC.Editor.Open("Home")
    end, "accent")
    U.Button(panel, "Emote library", 224, -76, 160, function()
        if SettingsPanel and SettingsPanel.Close then pcall(SettingsPanel.Close, SettingsPanel, true) end
        IC.Editor.Open("Emotes")
    end)
    panel.launcher = U.Check(panel, "Show the launcher button", 16, -116, function(value) IC.Layout().launcher.shown = value; IC.Changed() end)
    panel.wheelKey = U.KeyCapture(panel, 16, -150, 240, "INCHARACTER_WHEEL", "Radial wheel key")
    panel.menuKey = U.KeyCapture(panel, 264, -150, 240, "INCHARACTER_MENU", "Emote menu key")
    U.Muted(panel, "Commands: /ic opens the window, /ic wheel, /ic greet, /ic quote, /ic bye, /ic <pool name>.", 16, -190, 560)
    panel:SetScript("OnShow", function()
        if not IC.db then return end
        panel.launcher:SetChecked(IC.Layout().launcher.shown); panel.wheelKey.Refresh(); panel.menuKey.Refresh()
    end)
    local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, "In Character")
    if not ok or not category then return end
    if type(Settings.RegisterAddOnCategory) == "function" then pcall(Settings.RegisterAddOnCategory, category) end
    S.category, S.panel = category, panel
end

-- Declared in the TOC as AddonCompartmentFunc.
-- Newer clients pass a table with buttonName; older ones pass the button name.
function InCharacter_OnAddonCompartmentClick(_, mouse)
    if not IC.db then return end
    if type(mouse) == "table" then mouse = mouse.buttonName end
    if mouse == "RightButton" then IC.Editor.Open("Home") else IC.Menu.OpenAtCursor() end
end
function InCharacter_OnAddonCompartmentEnter(_, frame)
    if type(frame) == "table" and frame.GetObjectType then GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
    else GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR") end
    GameTooltip:SetText("In Character", 1, 1, 1)
    GameTooltip:AddLine("Left-click: emote menu", 0.8, 0.8, 0.8); GameTooltip:AddLine("Right-click: settings", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end
function InCharacter_OnAddonCompartmentLeave() GameTooltip:Hide() end
