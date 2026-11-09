local _, IC = ...
-- Edit Mode: drag bars and the launcher, and change a bar in a small inspector.
-- While editing, clicks select instead of playing. Also follows Blizzard's Edit Mode.
local B, U = IC.Bars, IC.UI
local unpack = unpack or table.unpack
local BLUE = { 0.25, 0.62, 0.95, 1 }

local function attach(frame)
    if frame.moveHandle then return end
    local overlay = CreateFrame("Button", nil, frame, "BackdropTemplate"); frame.moveHandle = overlay
    overlay:SetAllPoints(frame); overlay:SetFrameLevel(frame:GetFrameLevel() + 20); overlay:EnableMouse(true)
    overlay:RegisterForClicks("LeftButtonUp", "RightButtonUp"); overlay:RegisterForDrag("LeftButton")
    overlay.title = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    overlay.title:SetPoint("BOTTOMLEFT", overlay, "TOPLEFT", 0, 2); overlay.title:SetWordWrap(false)
    overlay:SetScript("OnClick", function() B.SelectBar(frame.index) end)
    overlay:SetScript("OnDragStart", function()
        if IC.InCombat() or frame.config.locked then return end
        -- Start moving first; selecting must not hide or rebuild the frame being dragged.
        frame.moving = true; frame:StartMoving(); B.SelectBar(frame.index, true)
    end)
    overlay:SetScript("OnDragStop", function() B.StopDrag(frame); if not IC.InCombat() then B.Refresh() end end)
    local grip = CreateFrame("Button", nil, overlay); frame.resizeGrip = grip
    grip:SetSize(14, 14); grip:SetPoint("BOTTOMRIGHT", 2, -2); grip:RegisterForDrag("LeftButton")
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetScript("OnDragStart", function()
        if IC.InCombat() or frame.config.locked then return end
        B.SelectBar(frame.index, true); frame.resizing = true; frame:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnDragStop", function() B.StopResize(frame); if not IC.InCombat() then B.Refresh() end end)

end
function B.UpdateEditControls(frame)
    attach(frame)
    frame.moveHandle:SetShown(B.editing == true)
    U.Backdrop(frame.moveHandle, { 0.05, 0.22, 0.4, 0.35 }, B.selectedBar == frame.index and U.Colors.accent or BLUE)
    frame.moveHandle.title:SetText(frame.config.name .. (frame.config.hidden and " (hidden)" or "") .. (frame.config.locked and " · locked" or ""))
end

function B.StopResize(frame)
    if not frame.resizing then return end
    frame.resizing = nil; frame:StopMovingOrSizing()
    frame.config.fitWidth, frame.config.fitHeight = frame:GetWidth(), frame:GetHeight()
    frame.config.perRow = 0
    local x, y = frame:GetCenter(); local px, py = UIParent:GetCenter()
    frame.config.x, frame.config.y = x - px, y - py
end
function B.StopDrag(frame)
    if not frame.moving then return end
    frame.moving = nil; frame:StopMovingOrSizing()
    local x, y = frame:GetCenter(); local px, py = UIParent:GetCenter()
    frame.config.x, frame.config.y = math.floor(x - px + 0.5), math.floor(y - py + 0.5)
end
local function active() return B.selectedBar and IC.Layout().bars[B.selectedBar] end
local function change(fn)
    local c = active(); if not c or IC.InCombat() or B.inspector.refreshing then return end
    fn(c); IC.Changed()
end
-- light: only recolour overlays and update the inspector (used while a drag starts).
function B.SelectBar(index, light)
    B.selectedLauncher, B.selectedBar = false, index
    if not light then B.Refresh(); return end
    for _, frame in ipairs(B.frames) do if frame.moveHandle and frame.config then B.UpdateEditControls(frame) end end
    B.RefreshInspector()
end
function B.SelectLauncher()
    B.selectedLauncher, B.selectedBar = true, nil
    B.Refresh()
end

function B.RefreshInspector()
    local p = B.inspector; if not p or not B.editing or p.refreshing then return end
    p.refreshing = true
    local options = { { value = "launcher", label = "Launcher button" } }
    for i, c in ipairs(IC.Layout().bars) do options[#options + 1] = { value = i, label = c.name .. (c.hidden and " (hidden)" or "") } end
    p.which:SetOptions(options)
    if not active() and not B.selectedLauncher then B.selectedBar = IC.Layout().bars[1] and 1 or nil; B.selectedLauncher = B.selectedBar == nil end
    p.which:SetValue(B.selectedLauncher and "launcher" or B.selectedBar)
    local c = active()
    p.form:SetShown(c ~= nil); p.launcherForm:SetShown(B.selectedLauncher == true)
    if c then
        local lists = {}; for _, list in ipairs(IC.Collections.List()) do lists[#lists + 1] = { value = list.id, label = "Shows: " .. list.name } end
        p.source:SetOptions(lists); p.source:SetValue(c.collection)
        p.size:Set(IC.CollectionBar.Size(c)); p.perRow:Set(math.floor(tonumber(c.perRow) or 0))
        p.vertical:SetChecked(c.vertical == true); p.labels:SetChecked(c.labels == true)
        p.hidden:SetChecked(c.hidden == true); p.locked:SetChecked(c.locked == true); p.collapsed:SetChecked(c.collapsed == true)
        p.delete.confirming = nil; p.delete:SetText("Delete bar")
    end
    if B.selectedLauncher then
        local l = IC.Layout().launcher
        p.launcherShown:SetChecked(l.shown ~= false); p.launcherSize:Set(l.size or 36); p.launcherClick:SetValue(l.click)
    end
    p.refreshing = nil
end

local function createInspector()
    local p = U.Panel(UIParent, 280, 414, nil, "InCharacterEditLayouts"); B.inspector = p
    p:SetPoint("TOPRIGHT", -24, -120); p:SetFrameStrata("DIALOG"); p:EnableMouse(true); p:SetClampedToScreen(true)
    p:SetMovable(true); p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", p.StartMoving); p:SetScript("OnDragStop", p.StopMovingOrSizing)
    U.Label(p, "Move & edit bars", 12, -12, nil, "GameFontNormal")
    U.Button(p, "Done", 196, -8, 72, function() B.SetEditing(false) end, "accent")
    p.which = U.Dropdown(p, 12, -38, 182, {}, function(value) if value == "launcher" then B.SelectLauncher() else B.SelectBar(value) end end)
    U.Button(p, "+ Bar", 200, -38, 68, function() B.selectedBar = B.Add("favorites"); B.selectedLauncher = false; B.Refresh() end)
    p.form = CreateFrame("Frame", nil, p); p.form:SetPoint("TOPLEFT", 0, -70); p.form:SetSize(280, 300)
    local f = p.form
    p.source = U.Dropdown(f, 12, 0, 256, {}, function(value) change(function(c)
        c.collection = value
        local list = IC.Collections.Get(value); if list then c.name = list.name end
    end) end)
    p.size = U.Slider(f, "Button size", 12, -32, 256, 12, 64, 1, function(value) change(function(c) c.size = value end) end)
    p.perRow = U.Slider(f, "Buttons per row (0 = one line)", 12, -78, 256, 0, 24, 1, function(value) change(function(c) c.perRow = value end) end)
    p.vertical = U.Check(f, "Vertical", 12, -124, function(value) change(function(c) c.vertical = value end) end)
    p.labels = U.Check(f, "Names", 140, -124, function(value) change(function(c) c.labels = value end) end)
    p.hidden = U.Check(f, "Hidden", 12, -152, function(value) change(function(c) c.hidden = value end) end)
    p.locked = U.Check(f, "Locked", 140, -152, function(value) change(function(c) c.locked = value end) end)
    p.collapsed = U.Check(f, "Collapsed", 12, -180, function(value) change(function(c) c.collapsed = value end) end)
    U.Button(f, "Clear fit bounds", 140, -180, 128, function() change(function(c) c.fitWidth, c.fitHeight, c.perRow = nil, nil, 0 end) end)
    p.delete = U.Button(f, "Delete bar", 12, -214, 120, function(self)
        U.Confirm(self, "Delete bar", function() if B.selectedBar then B.Delete(B.selectedBar) end end)
    end)
    U.Button(f, "Edit lists", 140, -214, 128, function() B.SetEditing(false); IC.Editor.Open("Lists") end)
    U.Muted(f, "Drag the corner to fit rows/columns. Shift-middle-click a bar to collapse; click its icon to expand.", 12, -248, 256)
    p.launcherForm = CreateFrame("Frame", nil, p); p.launcherForm:SetPoint("TOPLEFT", 0, -70); p.launcherForm:SetSize(280, 200)
    local l = p.launcherForm
    local function launcherChange(key, value) if p.refreshing then return end; IC.Layout().launcher[key] = value; IC.Changed() end
    p.launcherShown = U.Check(l, "Show the launcher", 12, 0, function(value) launcherChange("shown", value) end)
    U.Muted(l, "Click opens", 12, -34)
    p.launcherClick = U.Dropdown(l, 12, -50, 256, IC.Launcher.choices, function(value) launcherChange("click", value) end)
    p.launcherSize = U.Slider(l, "Size", 12, -84, 256, 24, 64, 2, function(value) launcherChange("size", value) end)
    U.Muted(l, "Drag the launcher to move it.", 12, -130, 256)
    U.Button(p, "Undo", 12, -380, 80, function() B.UndoLayout() end)
    p:SetScript("OnHide", function() if B.editing then B.SetEditing(false) end end)
    p:RegisterEvent("PLAYER_REGEN_DISABLED"); p:SetScript("OnEvent", function()
        for _, frame in ipairs(B.frames) do
            B.StopDrag(frame); B.StopResize(frame); if frame.moveHandle then frame.moveHandle:Hide() end
            if frame.config and (frame.config.hidden or IC.Layout().barsHidden) then frame:Hide() end
        end
        B.editing = false; p:Hide(); IC.refreshPending = true
    end)
    table.insert(UISpecialFrames, "InCharacterEditLayouts")
end

function B.UndoLayout()
    local snapshot = B.editSnapshot
    if not snapshot or snapshot.target ~= IC.Layout() or IC.InCombat() then return end
    for key in pairs(snapshot.target) do snapshot.target[key] = nil end
    IC.Merge(snapshot.target, IC.Copy(snapshot.data)); B.selectedBar, B.selectedLauncher = nil, false; IC.Changed()
end
function B.SetEditing(value)
    if IC.InCombat() then IC.Print("Move bars after combat."); return end
    if value and not B.editing then B.editSnapshot = { target = IC.Layout(), data = IC.Copy(IC.Layout()) } end
    B.editing = value == true
    if B.editing then
        if IC.Flyout then IC.Flyout.Close() end
        if IC.Wheel then IC.Wheel.Close() end
        if IC.Editor and IC.Editor.frame then IC.Editor.frame:Hide() end
    end
    if not B.inspector then createInspector() end
    B.inspector:SetShown(B.editing); B.Refresh(); IC.Launcher.Refresh()
end
function B.ConnectEditMode()
    if B.editModeConnected then return end
    B.editModeConnected = IC.Platform.ConnectEditMode(function() if IC.db then B.SetEditing(true) end end,
        function() if B.editing and not IC.InCombat() then B.SetEditing(false) end end, B)
end
