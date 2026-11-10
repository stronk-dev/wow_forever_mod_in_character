local _, IC = ...
-- A compact bar that shows one collection: icon buttons only, no backdrop and no title in play.
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
    frame:SetSize(g.width, g.height)
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
        button:ClearAllPoints(); button:SetPoint("TOPLEFT", frame, "TOPLEFT", entry.x, -entry.y)
    end
    if not frame.emptyHint then
        frame.emptyHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        frame.emptyHint:SetPoint("LEFT", 2, 0)
    end
    frame.emptyHint:SetText("Empty")
    frame.emptyHint:SetShown(#nodes == 0 and IC.Bars.editing == true)
    -- A bar too long for the screen pages; the page button sits at its end, never above it.
    if not frame.pager then
        frame.pager = U.ActionButton(frame)
        frame.pager:SetScript("OnClick", function() frame.config.page = (frame.geometry.page % frame.geometry.pages) + 1; CB.Render(frame, frame.config) end)
    end
    frame.pager:Hide()
    if g.pages > 1 then
        frame.pager:SetNode({ id = "page", type = "page", name = "Page " .. g.page .. " of " .. g.pages, icon = "Interface\\Icons\\INV_Misc_Book_09" }, math.floor(g.size * 0.6), side, false)
        frame.pager:ClearAllPoints()
        if config.vertical then frame.pager:SetPoint("TOP", frame, "BOTTOM", 0, -2) else frame.pager:SetPoint("LEFT", frame, "RIGHT", 2, 0) end
    end
    frame:SetShown(not config.hidden or IC.Bars.editing == true)
end
