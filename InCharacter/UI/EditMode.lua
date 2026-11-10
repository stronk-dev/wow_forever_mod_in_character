local _, IC = ...
-- Move & edit bars. Like Blizzard's Edit Mode, Bartender4 and Dominos: every bar gets a tinted
-- overlay with its name centred on it (never above it), clicks select instead of playing, and a
-- small panel docks beside the selected bar. Names exist only here; in play bars are just icons.
-- The corner grip (edit mode only) reshapes a bar by setting "Per row" while dragging; the
-- bar's top-left corner stays put.
local B, U = IC.Bars, IC.UI
local BLUE = { 0.25, 0.62, 0.95, 1 }
local PANEL_W, PANEL_H = 240, 318

local function attach(frame)
    if frame.moveHandle then return end
    local overlay = CreateFrame("Button", nil, frame, "BackdropTemplate"); frame.moveHandle = overlay
    overlay:SetAllPoints(frame); overlay:SetFrameLevel(frame:GetFrameLevel() + 20); overlay:EnableMouse(true)
    overlay:RegisterForClicks("LeftButtonUp", "RightButtonUp"); overlay:RegisterForDrag("LeftButton")
    overlay.title = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    overlay.title:SetPoint("LEFT", 2, 0); overlay.title:SetPoint("RIGHT", -2, 0); overlay.title:SetWordWrap(false)
    overlay:SetScript("OnClick", function() B.SelectBar(frame.index) end)
    overlay:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(frame.config.name, 1, 1, 1)
        GameTooltip:AddLine("Drag to move · click to change", 0.8, 0.8, 0.8); GameTooltip:Show()
    end)
    overlay:SetScript("OnLeave", function() GameTooltip:Hide() end)
    overlay:SetScript("OnDragStart", function()
        if IC.InCombat() or frame.config.locked then return end
        -- Start moving first; selecting must not hide or rebuild the frame being dragged.
        frame.moving = true; frame:StartMoving(); B.SelectBar(frame.index, true)
    end)
    overlay:SetScript("OnDragStop", function() B.StopDrag(frame); if not IC.InCombat() then B.Refresh() end end)
    local grip = CreateFrame("Button", nil, overlay); frame.resizeGrip = grip
    grip:SetSize(14, 14); grip:SetPoint("BOTTOMRIGHT", 2, -2); grip:SetFrameLevel(overlay:GetFrameLevel() + 2)
    grip:EnableMouse(true); grip:RegisterForDrag("LeftButton")
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Drag to reshape", 1, 1, 1)
        GameTooltip:AddLine("Sets how many icons go in each row.", 0.8, 0.8, 0.8); GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    grip:SetScript("OnDragStart", function()
        if IC.InCombat() or frame.config.locked then return end
        B.SelectBar(frame.index, true)
        frame.reshape = { left = frame:GetLeft(), top = frame:GetTop() }
        grip:SetScript("OnUpdate", function() B.Reshape(frame) end)
    end)
    grip:SetScript("OnDragStop", function() B.StopReshape(frame) end)
end
-- One step of a corner drag: the cursor's distance from the bar's fixed top-left corner sets
-- "Per row"; the bar is re-laid out and moved so that corner does not shift.
function B.Reshape(frame, cursorX, cursorY)
    local r, c = frame.reshape, frame.config; if not r or not c then return end
    if not cursorX then
        local scale = frame:GetEffectiveScale(); cursorX, cursorY = GetCursorPosition()
        cursorX, cursorY = cursorX / scale, cursorY / scale
    end
    local length = c.vertical and (r.top - cursorY) or (cursorX - r.left)
    local perRow = IC.BarModel.PerRowFor(c, #(frame.nodes or {}), length)
    if perRow == (math.floor(tonumber(c.perRow) or 0)) then return end
    c.perRow = perRow; IC.CollectionBar.Render(frame, c)
    local px, py = UIParent:GetCenter()
    c.x = math.floor(r.left + frame:GetWidth() / 2 - px + 0.5)
    c.y = math.floor(r.top - frame:GetHeight() / 2 - py + 0.5)
    frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", c.x, c.y)
    B.UpdateEditControls(frame); B.RefreshInspector()
end
function B.StopReshape(frame)
    if frame.resizeGrip then frame.resizeGrip:SetScript("OnUpdate", nil) end
    if not frame.reshape then return end
    frame.reshape = nil
    if not IC.InCombat() then IC.Changed() end
end
function B.UpdateEditControls(frame)
    attach(frame)
    frame.moveHandle:SetShown(B.editing == true)
    frame.resizeGrip:SetShown(not frame.config.locked)
    local selected = B.selectedBar == frame.index
    U.Backdrop(frame.moveHandle, selected and { 0.4, 0.32, 0.05, 0.75 } or { 0.05, 0.22, 0.4, 0.7 }, selected and U.Colors.accent or BLUE)
    frame.moveHandle.title:SetText(frame.config.name .. (frame.config.hidden and " (hidden)" or "") .. (frame.config.locked and " (locked)" or ""))
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
-- light: only recolour overlays and update the panel (used while a drag starts).
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

-- Docks the panel beside what is selected, on the side with room.
local function dock(p)
    local target = B.selectedLauncher and IC.Launcher.button or (B.selectedBar and B.frames[B.selectedBar])
    p:ClearAllPoints()
    if not target or not target:IsShown() then p:SetPoint("CENTER", UIParent, "CENTER", 0, 120); return end
    local _, y = target:GetCenter(); local _, cy = UIParent:GetCenter()
    if (y or 0) < (cy or 0) then p:SetPoint("BOTTOM", target, "TOP", 0, 24)
    else p:SetPoint("TOP", target, "BOTTOM", 0, -24) end
end

function B.RefreshInspector()
    local p = B.inspector; if not p or not B.editing or p.refreshing then return end
    p.refreshing = true
    p.mode:SetValue(B.Mode())
    if not active() and not B.selectedLauncher then B.selectedBar = IC.Layout().bars[1] and 1 or nil; B.selectedLauncher = B.selectedBar == nil end
    local c = active()
    p.form:SetShown(c ~= nil); p.launcherForm:SetShown(B.selectedLauncher == true)
    p.title:SetText(B.selectedLauncher and "Launcher button" or (c and c.name) or "")
    if c then
        local lists = {}
        for _, list in ipairs(IC.Collections.List()) do lists[#lists + 1] = { value = list.id, label = "Shows: " .. (list.dynamic and "RP character" or list.name) } end
        p.source:SetOptions(lists); p.source:SetValue(c.collection)
        p.size:Set(IC.CollectionBar.Size(c)); p.perRow:Set(math.floor(tonumber(c.perRow) or 0))
        p.vertical:SetChecked(c.vertical == true); p.labels:SetChecked(c.labels == true)
        p.hidden:SetChecked(c.hidden == true); p.locked:SetChecked(c.locked == true)
        p.delete.confirming = nil; p.delete:SetText("Delete bar")
    end
    if B.selectedLauncher then
        local l = IC.Layout().launcher
        p.launcherShown:SetChecked(l.shown ~= false); p.launcherSize:Set(l.size or 36)
    end
    dock(p)
    p.refreshing = nil
end

local function createInspector()
    local p = U.Panel(UIParent, PANEL_W, PANEL_H, nil, "InCharacterEditLayouts"); B.inspector = p
    p:SetFrameStrata("DIALOG"); p:EnableMouse(true); p:SetClampedToScreen(true)
    p.title = U.Label(p, "", 12, -14, PANEL_W - 90, "GameFontNormal"); p.title:SetWordWrap(false)
    U.Button(p, "Done", PANEL_W - 76, -8, 64, function() B.SetEditing(false) end, "accent")
    p.mode = U.Dropdown(p, 12, -36, PANEL_W - 24, { { value = "one", label = "Layout: one bar" }, { value = "separate", label = "Layout: separate bars" } },
        function(value) if not p.refreshing then B.SetMode(value) end end)
    p.form = CreateFrame("Frame", nil, p); p.form:SetPoint("TOPLEFT", 0, -68); p.form:SetSize(PANEL_W, PANEL_H - 68)
    local f, w = p.form, PANEL_W - 24
    p.source = U.Dropdown(f, 12, 0, w, {}, function(value) change(function(c)
        c.collection = value
        local list = IC.Collections.Get(value); if list then c.name = list.dynamic and "RP character" or list.name end
    end) end)
    p.size = U.Slider(f, "Size", 12, -30, w, 12, 48, 2, function(value) change(function(c) c.size = value end) end)
    p.perRow = U.Slider(f, "Per row (0 = all)", 12, -72, w, 0, 24, 1, function(value) change(function(c) c.perRow = value end) end)
    p.vertical = U.Check(f, "Vertical", 12, -112, function(value) change(function(c) c.vertical = value end) end)
    p.labels = U.Check(f, "Names", 124, -112, function(value) change(function(c) c.labels = value end) end)
    p.hidden = U.Check(f, "Hidden", 12, -138, function(value) change(function(c) c.hidden = value end) end)
    p.locked = U.Check(f, "Locked", 124, -138, function(value) change(function(c) c.locked = value end) end)
    for _, check in ipairs({ p.vertical, p.labels, p.hidden, p.locked }) do check.caption:SetWidth(80) end
    p.delete = U.Button(f, "Delete bar", 12, -172, (w - 6) / 2, function(self)
        U.Confirm(self, "Delete bar", function() if B.selectedBar then B.Delete(B.selectedBar) end end)
    end)
    U.Button(f, "+ Bar", 18 + (w - 6) / 2, -172, (w - 6) / 2, function() B.selectedBar = B.Add("favorites"); B.selectedLauncher = false; B.Refresh() end)
    p.launcherForm = CreateFrame("Frame", nil, p); p.launcherForm:SetPoint("TOPLEFT", 0, -68); p.launcherForm:SetSize(PANEL_W, 120)
    local l = p.launcherForm
    local function launcherChange(key, value) if p.refreshing then return end; IC.Layout().launcher[key] = value; IC.Changed() end
    p.launcherShown = U.Check(l, "Show the launcher", 12, 0, function(value) launcherChange("shown", value) end)
    p.launcherSize = U.Slider(l, "Size", 12, -34, w, 24, 64, 2, function(value) launcherChange("size", value) end)
    U.Button(p, "Undo all", 12, -(PANEL_H - 36), 90, function() B.UndoLayout() end)
    p:SetScript("OnHide", function() if B.editing then B.SetEditing(false) end end)
    p:RegisterEvent("PLAYER_REGEN_DISABLED"); p:SetScript("OnEvent", function()
        for _, frame in ipairs(B.frames) do
            B.StopDrag(frame); B.StopReshape(frame); if frame.moveHandle then frame.moveHandle:Hide() end
            if frame.config and (frame.config.hidden or IC.Layout().barsHidden) then frame:Hide() end
        end
        B.editing = false; p:Hide(); IC.refreshPending = true
        if IC.Launcher.button and IC.Layout().launcher.shown == false then IC.Launcher.button:Hide() end
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
