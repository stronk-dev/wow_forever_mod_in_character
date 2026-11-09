local _, IC = ...
local B, U, P = IC.Bars, IC.UI, IC.Presentation
local BLUE = { 0.25, 0.62, 0.95, 1 }
function B.ClampBounds(frame, width, height)
    width, height = math.floor(width + 0.5), math.floor(height + 0.5)
    local c = frame.config
    if B.IsStrip(c) then return math.max(80, math.min(width, UIParent:GetWidth() - 56)), math.max(c.labels and 28 or 14, math.min(height, 500)) end
    local buttonWidth = c.buttonStyle == "text" and c.buttonWidth or c.size
    local minWidth = math.max(c.catalog and 240 or 96, buttonWidth + 8)
    width = math.max(minWidth, math.min(width, UIParent:GetWidth() - 40))
    local columns = math.max(1, math.floor((width - 4) / (buttonWidth + 4)))
    local labels = c.buttonStyle ~= "text" and c.labels and 14 or 0
    local header = (c.catalog or c.catalogCompanion) and 24 or (c.locked and 0 or 16)
    local minimum = header + B.GroupRows(c, width) * 26 + c.size + labels + 8
    if #P.BarActions(c) > columns then minimum = minimum + 28 end
    return width, math.max(minimum, math.min(height, UIParent:GetHeight() - 40))
end
function B.EndStripDrag(frame, refresh)
    if not frame.manipulation then return end
    frame.manipulation = nil; frame:StopMovingOrSizing()
    local x, y = frame:GetCenter(); local px, py = UIParent:GetCenter()
    if B.IsStrip(frame.config) and not B.editing then
        local g = P.StripGeometry(frame.config, #P.BarActions(frame.config), UIParent:GetWidth())
        frame.config.x, frame.config.y = frame:GetLeft() - px + g.width / 2, frame:GetTop() - py - g.height / 2
    else
        frame.config.x = x - px
        frame.config.y = ((frame.config.catalog or frame.config.catalogCompanion) and frame:GetTop() or y) - py
    end
    frame.suppressUntil = GetTime() + 0.15
    if refresh and not IC.InCombat() then B.Refresh() end
end
function B.BeginStripDrag(frame, resize)
    if frame.manipulation or frame.config.locked or IC.InCombat() then return end
    if resize and not frame.StartSizing then IC.Print("Use width / height in Edit layouts on this client."); return end
    if B.editing then B.SelectBar(frame.index) end
    if resize then
        local left, top = frame:GetLeft(), frame:GetTop(); local px, py = UIParent:GetCenter()
        frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", UIParent, "CENTER", left - px, top - py)
        local w, h = B.ClampBounds(frame, 0, 0)
        frame:SetResizable(true)
        if frame.SetResizeBounds then frame:SetResizeBounds(w, h, UIParent:GetWidth() - 40, UIParent:GetHeight() - 40) end
        frame.manipulation = "resize"; frame:StartSizing("BOTTOMRIGHT")
    else frame.manipulation = "move"; frame:StartMoving() end
end
local function attach(frame)
    if frame.moveHandle then return end
    local overlay = CreateFrame("Button", nil, frame, "BackdropTemplate"); frame.moveHandle = overlay
    overlay:SetAllPoints(frame); overlay:SetFrameLevel(frame:GetFrameLevel() + 20); overlay:EnableMouse(true)
    overlay:RegisterForClicks("LeftButtonUp", "RightButtonUp"); overlay:RegisterForDrag("LeftButton")
    overlay.title = U.Label(overlay, "", 6, -4, 220, "GameFontHighlightSmall")
    overlay:SetScript("OnClick", function(_, mouse)
        B.SelectBar(frame.index)
        if mouse == "RightButton" then IC.Editor.Open("Layouts", frame.index) end
    end)
    overlay:SetScript("OnDragStart", function() B.BeginStripDrag(frame, false) end)
    overlay:SetScript("OnDragStop", function() B.EndStripDrag(frame, true) end)
    local grip = CreateFrame("Button", nil, frame); frame.resizeHandle = grip
    grip:SetSize(18, 18); grip:SetPoint("BOTTOMRIGHT", -1, 1); grip:SetFrameLevel(overlay:GetFrameLevel() + 1)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:RegisterForDrag("LeftButton")
    grip:SetScript("OnMouseDown", function(_, mouse) if mouse == "LeftButton" then B.BeginStripDrag(frame, true) end end)
    grip:SetScript("OnMouseUp", function(_, mouse) if mouse == "LeftButton" then B.EndStripDrag(frame, true) end end)
    grip:SetScript("OnDragStart", function() B.BeginStripDrag(frame, true) end)
    grip:SetScript("OnDragStop", function() B.EndStripDrag(frame, true) end)
    grip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Drag to resize width and height. /ic edit opens all layout controls."); GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame:SetScript("OnSizeChanged", function(self)
        if self.manipulation ~= "resize" or self.renderingLayout or self.renderingStrip or IC.InCombat() then return end
        local w, h = B.ClampBounds(self, self:GetWidth(), self:GetHeight())
        if B.IsStrip(self.config) then self.config.stripWidth, self.config.stripHeight = w, h
        else self.config.width, self.config.height = w, h end
        B.RenderFrame(self, self.config); B.RefreshInspector()
    end)
    frame:SetScript("OnHide", function(self) B.EndStripDrag(self, false) end)
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:SetScript("OnEvent", function(self) B.EndStripDrag(self, false); self.moveHandle:Hide(); self.resizeHandle:Hide() end)
end
function B.UpdateEditControls(frame)
    attach(frame)
    frame.moveHandle:SetShown(B.editing == true)
    U.Backdrop(frame.moveHandle, { 0.05, 0.22, 0.4, 0.35 }, B.selectedBar == frame.index and U.Colors.accent or BLUE)
    frame.moveHandle.title:SetText(frame.config.name .. (frame.config.locked and " · locked" or " · drag to move"))
    frame.moveHandle.title:SetWidth(math.max(50, frame:GetWidth() - 12))
    frame.resizeHandle:SetShown(not frame.config.locked and not frame.config.collapsed and (B.editing or not B.IsStrip(frame.config)))
end
local function active()
    return B.selectedBar and IC.Layout().bars[B.selectedBar]
end
local function change(fn)
    local c = active(); if not c or IC.InCombat() then return end
    fn(c); c.page = 1; IC.Changed()
end
function B.SelectBar(index)
    B.selectedLauncher = false
    B.selectedBar = index
    if IC.Editor then IC.Editor.barIndex = index end
    for _, frame in ipairs(B.frames) do if frame.moveHandle then B.UpdateEditControls(frame) end end
    B.RefreshInspector()
end
function B.SelectLauncher()
    B.selectedLauncher, B.selectedBar = true, nil
    for _, frame in ipairs(B.frames) do B.UpdateEditControls(frame) end
    B.RefreshInspector()
end
function B.RefreshInspector()
    local panel = B.inspector; if not panel or not B.editing or panel.refreshing then return end
    panel.refreshing = true
    if B.editSnapshot and B.editSnapshot.target ~= IC.Layout() then B.editSnapshot = { target = IC.Layout(), data = IC.Copy(IC.Layout()) }; B.selectedBar, B.selectedLauncher = nil, false end
    local options = { { value = "launcher", label = "Launcher button" } }; for i, c in ipairs(IC.Layout().bars) do options[#options + 1] = { value = i, label = c.name .. (c.hidden and " (hidden)" or "") } end
    panel.which:SetOptions(options)
    if not active() and not B.selectedLauncher then B.selectedBar = IC.Layout().bars[1] and 1 or nil; B.selectedLauncher = B.selectedBar == nil end
    local c, frame = active(), B.frames[B.selectedBar or 0]
    panel.which:SetValue(B.selectedLauncher and "launcher" or B.selectedBar); panel.form:SetShown(c ~= nil)
    panel.launcherForm:SetShown(B.selectedLauncher == true)
    if B.selectedLauncher then
        local l = IC.Layout().launcher
        panel.launcherShown:SetChecked(l.shown); panel.launcherSize:Set(l.size)
        panel.launcherLeft:SetValue(l.click); panel.launcherRight:SetValue(l.rightClick); panel.launcherMiddle:SetValue(l.middleClick)
    end
    if c then
        panel.source:SetOptions(IC.Editor.BarSources()); panel.source:SetValue(c.source)
        panel.view:SetValue(c.emoteView); panel.style:SetValue(B.IsStrip(c) and "strip" or c.buttonStyle)
        local pools = not not (c.source == "pools" or c.source:match("^pool:") or c.source:match("^play:") or c.source == "favorites")
        panel.playback:SetShown(pools); panel.playback:SetValue(c.poolMode); panel.view:SetShown(not pools)
        panel.width:SetMinMaxValues(80, math.max(1200, UIParent:GetWidth() - 40)); panel.height:SetMinMaxValues(28, math.max(600, UIParent:GetHeight() - 40))
        panel.width:Set(frame and frame:GetWidth() or 388); panel.height:Set(frame and frame:GetHeight() or 100); panel.size:Set(c.size)
        panel.hidden:SetChecked(c.hidden); panel.locked:SetChecked(c.locked); panel.tabs:SetChecked(not c.hideCatalogTabs)
        panel.tabs:SetShown(c.catalog == true)
        panel.categories:SetShown(c.source == "categories")
        for id, check in pairs(panel.categoryChecks) do check:SetChecked(c.categories[id] == true) end
        local groups = { { value = "all", label = "All RP pools" } }
        for _, group in ipairs(P.CatalogGroups(c)) do groups[#groups + 1] = { value = group.id, label = group.title } end
        panel.group:SetOptions(groups); panel.group:SetValue(c.catalogGroup or "all"); panel.group:SetShown(c.catalog == true)
        panel.summary:SetText(#P.BarActions(c) .. " visible · " .. #P.BarActions(c, true) .. " in source")
    end
    panel.refreshing = nil
end
local function createInspector()
    local p = U.Panel(UIParent, 316, 630, U.Colors.bg, "InCharacterEditLayouts"); B.inspector, B.arrange = p, p
    U.GameBackdrop(p)
    p:SetPoint("TOPRIGHT", -24, -110); p:SetFrameStrata("DIALOG"); p:EnableMouse(true); p:SetClampedToScreen(true)
    p:SetScale(math.min(1, (UIParent:GetHeight() - 40) / 630))
    U.Heading(p, "Edit In Character layouts", 12, -12)
    U.Button(p, "Done", 12, -40, 88, function() B.SetEditing(false) end)
    U.Button(p, "Undo", 106, -40, 88, function() B.UndoLayout() end)
    U.Button(p, "Settings", 200, -40, 104, function() IC.Editor.Open("Layouts", B.selectedBar) end)
    p.which = U.Dropdown(p, 12, -76, 292, {}, function(index) if index == "launcher" then B.SelectLauncher() else B.SelectBar(index) end end)
    local function add(rp)
        local bars = IC.Layout().bars; bars[#bars + 1] = rp and IC.Defaults.CatalogBar(#bars + 1) or IC.Defaults.EmoteBar(#bars + 1, "categories")
        B.selectedBar, B.selectedLauncher = #bars, false; IC.Changed()
    end
    U.Button(p, "+ Emote bar", 12, -108, 142, function() add(false) end)
    U.Button(p, "+ RP bar", 162, -108, 142, function() add(true) end)
    p.form = CreateFrame("Frame", nil, p); p.form:SetPoint("TOPLEFT", 0, -142); p.form:SetSize(316, 484)
    local f = p.form
    p.source = U.Dropdown(f, 12, 0, 292, {}, function(value) change(function(c)
        c.source, c.catalogGroup = value, "all"
        if value ~= "pools" then c.catalog = false end
        if value == "categories" and not next(c.categories) then for _, id in ipairs(IC.Emotes.categories) do c.categories[id] = true end end
    end) end)
    p.view = U.Dropdown(f, 12, -32, 292, {
        { value = "profile", label = "Emotes: use my profile choices" }, { value = "all", label = "Emotes: all recognized by this client" }, { value = "kept", label = "Emotes: explicitly kept only" },
    }, function(value) change(function(c) c.emoteView = value end) end)
    p.playback = U.Dropdown(f, 12, -32, 292, {
        { value = "pool", label = "Playback: each pool's saved mode" }, { value = "random", label = "Playback: random" },
        { value = "shuffle", label = "Playback: shuffle" }, { value = "sequential", label = "Playback: in order" },
    }, function(value) change(function(c) c.poolMode = value end) end)
    p.style = U.Dropdown(f, 12, -64, 292, {
        { value = "strip", label = "Compact emote strip" }, { value = "icons", label = "Icon grid" }, { value = "text", label = "Labeled buttons" },
    }, function(value) change(function(c)
        c.strip, c.buttonStyle = value == "strip", value == "strip" and "icons" or value
        if c.strip then c.catalog, c.catalogCompanion, c.labels = false, false, false end
    end) end)
    local function dimension(value, height)
        if p.refreshing then return end
        change(function(c)
            local frame = B.frames[B.selectedBar]; local w, h = B.ClampBounds(frame, height and frame:GetWidth() or value, height and value or frame:GetHeight())
            if B.IsStrip(c) then c.stripWidth, c.stripHeight = w, h else c.width, c.height = w, h end
        end)
    end
    p.width = U.Slider(f, "Width", 12, -104, 138, 80, 1200, 1, function(value) dimension(value, false) end)
    p.height = U.Slider(f, "Height", 166, -104, 138, 28, 600, 1, function(value) dimension(value, true) end)
    p.size = U.Slider(f, "Button size / max icon size", 12, -152, 292, 12, 64, 2, function(value) if not p.refreshing then change(function(c) c.size = value end) end end)
    p.hidden = U.Check(f, "Hidden", 12, -202, function(value) change(function(c) c.hidden = value end) end)
    p.locked = U.Check(f, "Lock position", 146, -202, function(value) change(function(c) c.locked = value end) end)
    p.tabs = U.Check(f, "Show RP tabs", 12, -232, function(value) change(function(c) c.hideCatalogTabs = not value end) end)
    p.group = U.Dropdown(f, 146, -232, 158, {}, function(value) change(function(c) c.catalogGroup = value end) end)
    p.categories = CreateFrame("Frame", nil, f); p.categories:SetPoint("TOPLEFT", 12, -238); p.categories:SetSize(292, 92); p.categoryChecks = {}
    for n, id in ipairs(IC.Emotes.categories) do
        local check = U.Check(p.categories, id, ((n - 1) % 2) * 146, -math.floor((n - 1) / 2) * 28, function(value) change(function(c) c.categories[id] = value end) end)
        check.caption:SetWidth(108); p.categoryChecks[id] = check
    end
    U.Button(f, "Items / icons", 12, -340, 138, function() if active() then IC.LayoutUI.Open("bar", B.selectedBar) end end)
    U.Button(f, "Full bar settings", 166, -340, 138, function() IC.Editor.Open("Layouts", B.selectedBar) end)
    p.summary = U.Muted(f, "", 12, -374, 292)
    U.Button(f, "Radial items", 12, -398, 138, function() IC.LayoutUI.Open("wheel") end)
    U.Button(f, "Context items", 166, -398, 138, function() IC.LayoutUI.Open("menu") end)
    U.Muted(f, "Drag a highlighted bar to move. Drag its bottom-right corner to resize. Editing never plays an action.", 12, -434, 292)
    p.launcherForm = CreateFrame("Frame", nil, p); p.launcherForm:SetPoint("TOPLEFT", 0, -142); p.launcherForm:SetSize(316, 360)
    local l = p.launcherForm
    local function launcherChange(key, value) if p.refreshing then return end; IC.Layout().launcher[key] = value; IC.Changed() end
    p.launcherShown = U.Check(l, "Show launcher", 12, 0, function(value) launcherChange("shown", value) end)
    U.Muted(l, "Left-click", 12, -36)
    p.launcherLeft = U.Dropdown(l, 12, -52, 292, IC.Launcher.choices, function(value) launcherChange("click", value) end)
    U.Muted(l, "Right-click", 12, -88)
    p.launcherRight = U.Dropdown(l, 12, -104, 292, IC.Launcher.choices, function(value) launcherChange("rightClick", value) end)
    U.Muted(l, "Middle-click", 12, -140)
    p.launcherMiddle = U.Dropdown(l, 12, -156, 292, IC.Launcher.choices, function(value) launcherChange("middleClick", value) end)
    p.launcherSize = U.Slider(l, "Launcher size", 12, -200, 292, 28, 64, 2, function(value) launcherChange("size", value) end)
    U.Muted(l, "Drag the launcher to move it in Edit Mode. Each mouse button has its own action. Shift-right-click always opens settings outside Edit Mode.", 12, -256, 292)
    p:SetScript("OnHide", function() if B.editing then B.SetEditing(false) end end)
    p:RegisterEvent("PLAYER_REGEN_DISABLED"); p:SetScript("OnEvent", function()
        B.editing = false; p:Hide(); for _, frame in ipairs(B.frames) do frame.moveHandle:Hide(); frame.resizeHandle:Hide() end; IC.refreshPending = true
    end)
    table.insert(UISpecialFrames, "InCharacterEditLayouts")
end
function B.UndoLayout()
    local snapshot = B.editSnapshot
    if not snapshot or snapshot.target ~= IC.Layout() or IC.InCombat() then return end
    for key in pairs(snapshot.target) do snapshot.target[key] = nil end
    IC.Merge(snapshot.target, snapshot.data); B.selectedBar, B.selectedLauncher = nil, false; IC.Changed()
end
function B.SetEditing(value)
    if IC.InCombat() then IC.Print("Edit layouts after combat."); return end
    if value and not B.editing then B.editSnapshot = { target = IC.Layout(), data = IC.Copy(IC.Layout()) } end
    B.editing = value == true
    if B.editing then
        IC.Menu.Close(); IC.Wheel.Close(); IC.QuickActions.Close()
        if IC.Editor.frame then IC.Editor.frame:Hide() end
    end
    if not B.inspector then createInspector() end
    B.inspector:SetShown(B.editing); B.Refresh(); IC.Launcher.Refresh()
end
function B.ConnectEditMode()
    if B.editModeConnected or not EventRegistry or type(EventRegistry.RegisterCallback) ~= "function" then return end
    local enter = pcall(EventRegistry.RegisterCallback, EventRegistry, "EditMode.Enter", function() if IC.db then B.SetEditing(true) end end, B)
    local leave = pcall(EventRegistry.RegisterCallback, EventRegistry, "EditMode.Exit", function() if B.editing and not IC.InCombat() then B.SetEditing(false) end end, B)
    B.editModeConnected = enter and leave
end
BINDING_NAME_INCHARACTER_BARS = "Show / hide RP bar"
BINDING_NAME_INCHARACTER_EDITMODE = "Edit all In Character layouts"
