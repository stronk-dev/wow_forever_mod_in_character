local _, IC = ...
-- A compact bar that shows one collection: icon buttons only, no backdrop, title only in Edit Mode.
-- Groups and pools carry an arrow that opens their exact items in a flyout.
IC.CollectionBar = {}
local CB, U = IC.CollectionBar, IC.UI
local M = IC.BarModel
CB.GAP, CB.SEGMENT = M.GAP, M.SEGMENT
CB.Size, CB.Geometry = M.Size, M.Geometry

local function direction(frame, config)
    local x, y = frame:GetCenter(); local cx, cy = UIParent:GetCenter()
    if config.vertical then return (x or 0) > (cx or 0) and "LEFT" or "RIGHT" end
    return (y or 0) > (cy or 0) and "DOWN" or "UP"
end

local function click(frame, button, mouse)
    if IC.Bars.editing then IC.Bars.SelectBar(frame.index); return end
    if mouse == "MiddleButton" and IC.Platform.Shift() then frame.config.collapsed = true; IC.Changed(); return end
    if mouse == "RightButton" and IC.Platform.Shift() then
        if IC.InCombat() then return end
        IC.Bars.SetEditing(true); IC.Bars.SelectBar(frame.index); return
    end
    U.ActionClick(button, mouse)
end

function CB.Render(frame, config)
    frame:EnableMouse(false)
    frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", config.x or 0, config.y or 0)
    local nodes = IC.Collections.Nodes(config.collection or "main")
    frame.nodes = nodes
    local g = CB.Geometry(config, nodes, UIParent:GetWidth(), UIParent:GetHeight())
    frame.geometry = g
    frame:SetSize(IC.Bars.editing and config.fitWidth and math.max(g.width, math.min(config.fitWidth, UIParent:GetWidth() - 32)) or g.width, IC.Bars.editing and config.fitHeight and math.max(g.height, math.min(config.fitHeight, UIParent:GetHeight() - 48)) or g.height)
    frame.actionButtons = frame.actionButtons or {}
    for _, button in ipairs(frame.actionButtons) do button:Hide() end
    local side = direction(frame, config)
    for index, entry in ipairs(g.positions) do
        local node = nodes[entry.index]
        local button = frame.actionButtons[index]
        if not button then
            button = U.ActionButton(frame)
            button:SetScript("OnClick", function(self, mouse) click(frame, self, mouse) end)
            button.onArrow = function(self) if IC.Bars.editing then IC.Bars.SelectBar(frame.index) else IC.Flyout.Toggle(self, self.node) end end
            frame.actionButtons[index] = button
        end
        button.side = side
        button:SetNode(node, g.size, side, config.labels == true)
        local p = entry
        button:ClearAllPoints(); button:SetPoint("TOPLEFT", frame, "TOPLEFT", p.x, -p.y)
    end
    if not frame.emptyHint then
        frame.emptyHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        frame.emptyHint:SetPoint("LEFT", 2, 0)
    end
    frame.emptyHint:SetText("Empty bar")
    frame.emptyHint:SetShown(#nodes == 0 and IC.Bars.editing == true)
    if not frame.pager then
        frame.pager = U.Button(frame, "", nil, nil, 46, function() frame.config.page = (frame.geometry.page % frame.geometry.pages) + 1; CB.Render(frame, frame.config) end)
        frame.pager:SetHeight(16); frame.pager:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 2)
    end
    frame.pager:SetShown(g.pages > 1); frame.pager:SetText(g.page .. "/" .. g.pages)
    if not frame.folded then
        frame.folded = U.ActionButton(frame)
        frame.folded.onArrow = function(self) IC.Flyout.Toggle(self, self.node) end
        frame.folded:SetScript("OnClick", function() frame.config.collapsed = false; IC.Changed() end)
    end
    frame.folded:Hide()
    if config.collapsed and not IC.Bars.editing then
        for _, button in ipairs(frame.actionButtons) do button:Hide() end
        local list = IC.Collections.Get(config.collection)
        frame.folded:SetNode({ id = "set:" .. config.collection, type = "group", collection = config.collection, name = "Expand " .. (list and list.name or config.name), icon = list and list.icon }, g.size, side, false)
        frame.folded:ClearAllPoints(); frame.folded:SetPoint("CENTER"); frame:SetSize(g.size, g.size); frame.pager:Hide()
    end
    frame:SetShown(not config.hidden or IC.Bars.editing == true)
end
