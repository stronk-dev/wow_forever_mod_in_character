local _, IC = ...
local B, U, P = IC.Bars, IC.UI, IC.Presentation
function B.IsStrip(config)
    return config.strip == true and config.buttonStyle == "icons" and not config.catalog and not config.catalogCompanion
end
function B.HideStripControls(frame)
    if frame.moveHandle then frame.moveHandle:Hide(); frame.resizeHandle:Hide() end
end
function B.EndStripDrag(frame, refresh)
    if not frame.manipulation then return end
    local resizing = frame.manipulation == "resize"
    frame.manipulation = nil; frame:StopMovingOrSizing()
    local x, y = frame:GetCenter(); local px, py = UIParent:GetCenter()
    frame.config.x, frame.config.y = x - px, y - py
    if resizing then frame.config.stripWidth = frame:GetWidth() end
    frame.suppressUntil = GetTime() + 0.15
    if refresh and not IC.InCombat() then B.Refresh() end
end
function B.BeginStripDrag(frame, resize)
    if not B.IsStrip(frame.config) or frame.manipulation or frame.config.locked or IC.InCombat() then return end
    if resize and not frame.StartSizing then IC.Print("Use the hotbar width slider on this client."); return end
    if resize then
        local left, top = frame:GetLeft(), frame:GetTop(); local px, py = UIParent:GetCenter()
        frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", UIParent, "CENTER", left - px, top - py)
        frame:SetResizable(true)
        if frame.SetResizeBounds then frame:SetResizeBounds(80, 20, math.max(80, UIParent:GetWidth() - 56), 500)
        elseif frame.SetMinResize then frame:SetMinResize(80, 20) end
        frame.manipulation = "resize"; frame:StartSizing("RIGHT")
    else frame.manipulation = "move"; frame:StartMoving() end
end
local function controls(frame)
    if frame.moveHandle then return end
    frame.moveHandle = U.Button(frame, "↔", nil, nil, 22)
    frame.moveHandle:SetPoint("RIGHT", frame, "LEFT", -2, 0); frame.moveHandle:SetHeight(22)
    frame.moveHandle.tooltip = "Drag to move this hotbar. Right-click for its settings."
    frame.resizeHandle = U.Button(frame, "↔", nil, nil, 22)
    frame.resizeHandle:SetPoint("LEFT", frame, "RIGHT", 2, 0); frame.resizeHandle:SetHeight(22)
    frame.resizeHandle.tooltip = "Drag horizontally to set the space for this hotbar. Icons fit automatically."
    for _, handle in ipairs({ frame.moveHandle, frame.resizeHandle }) do
        local resize = handle == frame.resizeHandle
        handle:RegisterForDrag("LeftButton"); handle:RegisterForClicks("RightButtonUp")
        handle:SetScript("OnMouseDown", function(_, mouse) if mouse == "LeftButton" then B.BeginStripDrag(frame, resize) end end)
        handle:SetScript("OnDragStart", function() B.BeginStripDrag(frame, resize) end)
        handle:SetScript("OnDragStop", function() B.EndStripDrag(frame, true) end)
        handle:SetScript("OnMouseUp", function(_, mouse) if mouse == "LeftButton" then B.EndStripDrag(frame, true) end end)
        handle:SetScript("OnClick", function() IC.Editor.Open("Layouts", frame.index) end)
    end
    frame:SetScript("OnSizeChanged", function(self)
        if self.manipulation == "resize" and not self.renderingStrip and not IC.InCombat() then
            self.config.stripWidth = self:GetWidth(); B.RenderStrip(self, self.config)
        end
    end)
    frame:SetScript("OnHide", function(self) B.EndStripDrag(self, false) end)
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:SetScript("OnEvent", function(self)
        B.EndStripDrag(self, false); B.HideStripControls(self)
    end)
end
function B.RenderStrip(frame, config)
    controls(frame); frame.renderingStrip = true
    local actions = P.BarActions(config); local g = P.StripGeometry(config, #actions, UIParent:GetWidth())
    local pages = math.max(1, math.ceil(#actions / g.capacity))
    config.page = math.max(1, math.min(pages, config.page or 1))
    local offset, editing = (config.page - 1) * g.capacity, B.editing and not config.locked
    frame.header:Hide(); frame.close:Hide(); frame.edit:Hide(); frame.mode:Hide(); frame.empty:Hide()
    for _, tab in ipairs(frame.catalogTabs) do tab:Hide() end
    for _, slots in ipairs({ frame.iconButtons, frame.textButtons }) do for _, slot in ipairs(slots) do slot:Hide() end end
    frame:SetSize(g.width, g.height); frame:EnableMouse(editing == true)
    U.Backdrop(frame, editing and { 0.04, 0.04, 0.06, 0.45 } or { 0, 0, 0, 0 }, editing and U.Colors.accent or { 0, 0, 0, 0 })
    if not frame.manipulation then
        frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", config.x, config.y)
    end
    frame.moveHandle:SetShown(editing and not config.collapsed)
    frame.resizeHandle:SetShown(editing and not config.collapsed)
    frame.buttons = frame.iconButtons
    frame.previous:ClearAllPoints(); frame.next:ClearAllPoints()
    frame.previous:SetPoint("RIGHT", -25, 0); frame.next:SetPoint("RIGHT", -3, 0)
    frame.previous:SetSize(20, 22); frame.next:SetSize(20, 22)
    frame.previous:SetShown(pages > 1 and not config.collapsed); frame.next:SetShown(pages > 1 and not config.collapsed)
    frame.previous.tooltip, frame.next.tooltip = "Previous page · " .. config.page .. "/" .. pages, "Next page · " .. config.page .. "/" .. pages
    frame.pageLabel:Hide()
    local count = math.min(g.capacity, #actions - offset)
    if not config.collapsed then
        for n = 1, count do
            local slot = B.CreateSlot(frame, n, false); local action = actions[offset + n]
            if not slot.stripDrag then
                slot.stripDrag = true; slot:RegisterForDrag("LeftButton")
                local original = slot:GetScript("OnClick")
                slot:SetScript("OnClick", function(self, mouse)
                    if frame.manipulation or (frame.suppressUntil and GetTime() < frame.suppressUntil) then return end
                    original(self, mouse)
                end)
                slot:SetScript("OnDragStart", function() if B.IsStrip(frame.config) and IsShiftKeyDown() then B.BeginStripDrag(frame, false) end end)
                slot:SetScript("OnDragStop", function() B.EndStripDrag(frame, true) end)
                slot:EnableMouseWheel(true); slot:SetScript("OnMouseWheel", function(_, delta) B.Page(frame.index, -delta) end)
            end
            slot.action, slot.catalogPool = action, false
            slot:SetSize(g.size, g.size); slot:GetNormalTexture():SetSize(g.size * 1.3, g.size * 1.3)
            slot:ClearAllPoints(); slot:SetPoint("TOPLEFT", g.padding + ((n - 1) % g.columns) * (g.size + g.gap), -g.padding - math.floor((n - 1) / g.columns) * g.cellHeight)
            slot:SetIcon(action.icon, IC.Icons[1]); slot.icon:SetDesaturated(action.type == "emote" and not action.verified)
            slot.kind:SetShown(action.type == "emote" and IC.Emotes.IsAudible(action)); slot.kind:SetVertexColor(0.31, 0.76, 0.97, 1)
            slot.caption:SetText(IC.ShortText(action.name or action.label, 16)); slot.caption:SetWidth(g.size + g.gap); slot.caption:SetShown(config.labels)
            slot:Show()
        end
    end
    if B.editing and (#actions == 0 or config.collapsed) then
        frame.empty:SetText(config.collapsed and "Collapsed · uncheck in settings" or "No enabled emotes · right-click a handle for settings")
        frame.empty:ClearAllPoints(); frame.empty:SetPoint("LEFT", 6, 0); frame.empty:SetWidth(g.width - 12); frame.empty:Show()
        frame.moveHandle:SetShown(not config.locked); frame.resizeHandle:SetShown(not config.locked)
    end
    frame:SetShown(not config.hidden); frame.renderingStrip = nil
end
function B.SetEditing(value)
    if IC.InCombat() then IC.Print("Arrange hotbars after combat."); return end
    B.editing = value == true
    if not B.arrange then
        local panel = U.Panel(UIParent, 400, 58, U.Colors.bg, "InCharacterBarArrange"); B.arrange = panel
        panel:SetPoint("TOP", 0, -80); panel:SetFrameStrata("DIALOG"); panel:EnableMouse(true)
        U.Label(panel, "Arrange emote hotbars", 12, -10)
        U.Muted(panel, "Left handle: move · right handle: resize · right-click: settings", 12, -34, 376)
        U.Button(panel, "Done", 310, -6, 78, function() B.SetEditing(false) end)
        panel:SetScript("OnHide", function() if B.editing then B.SetEditing(false) end end)
        panel:RegisterEvent("PLAYER_REGEN_DISABLED"); panel:SetScript("OnEvent", function()
            B.editing = false; panel:Hide(); IC.refreshPending = true
        end)
        table.insert(UISpecialFrames, "InCharacterBarArrange")
    end
    B.arrange:SetShown(B.editing); B.Refresh()
end
