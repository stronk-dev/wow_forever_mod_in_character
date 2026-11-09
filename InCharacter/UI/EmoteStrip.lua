local _, IC = ...
local B, U, P = IC.Bars, IC.UI, IC.Presentation
function B.IsStrip(config)
    return config.strip == true and config.buttonStyle == "icons" and not config.catalog and not config.catalogCompanion
end
function B.RenderStrip(frame, config)
    frame.renderingStrip = true
    local actions = P.BarActions(config); local g = P.StripGeometry(config, #actions, UIParent:GetWidth())
    local pages = math.max(1, math.ceil(#actions / g.capacity))
    config.page = math.max(1, math.min(pages, config.page or 1))
    local offset, editing = (config.page - 1) * g.capacity, B.editing and not config.locked
    local count = math.min(g.capacity, #actions - offset)
    local drawWidth = B.editing and g.width or (g.padding * 2 + math.min(g.columns, count) * (g.size + g.gap) - g.gap + g.controls)
    local drawHeight = B.editing and g.height or (g.padding * 2 + math.ceil(count / g.columns) * g.cellHeight - g.gap)
    frame.header:Hide(); frame.close:Hide(); frame.edit:Hide(); frame.mode:Hide(); frame.empty:Hide()
    for _, tab in ipairs(frame.catalogTabs) do tab:Hide() end
    for _, slots in ipairs({ frame.iconButtons, frame.textButtons }) do for _, slot in ipairs(slots) do slot:Hide() end end
    frame:SetSize(math.max(1, drawWidth), math.max(1, drawHeight)); frame:EnableMouse(editing == true)
    U.Backdrop(frame, editing and { 0.04, 0.04, 0.06, 0.45 } or { 0, 0, 0, 0 }, editing and U.Colors.accent or { 0, 0, 0, 0 })
    if not frame.manipulation then
        frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", UIParent, "CENTER", config.x - g.width / 2, config.y + g.height / 2)
    end
    frame.buttons = frame.iconButtons
    frame.previous:ClearAllPoints(); frame.next:ClearAllPoints()
    frame.previous:SetPoint("RIGHT", -25, 0); frame.next:SetPoint("RIGHT", -3, 0)
    frame.previous:SetSize(math.min(20, g.size), math.min(20, g.size)); frame.next:SetSize(math.min(20, g.size), math.min(20, g.size))
    frame.previous:SetShown(pages > 1 and not config.collapsed); frame.next:SetShown(pages > 1 and not config.collapsed)
    frame.previous.tooltip, frame.next.tooltip = "Previous page · " .. config.page .. "/" .. pages, "Next page · " .. config.page .. "/" .. pages
    frame.pageLabel:Hide()
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
            slot.action, slot.catalogPool = action, action.type == "pool"
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
    end
    frame:SetShown(not config.hidden and (count > 0 or B.editing)); frame.renderingStrip = nil
end
