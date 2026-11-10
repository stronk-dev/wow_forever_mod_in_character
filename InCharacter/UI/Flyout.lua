local _, IC = ...
-- Compact item list opened from a group or pool button. Nested groups and pools open
-- sideways on hover (reveal only). Only a click sends. Right-click pins / unpins.
IC.Flyout = { levels = {} }
local F, U = IC.Flyout, IC.UI
local unpack = unpack or table.unpack
local ROW, ICON, MAX_ROWS, PAD = 20, 18, 14, 2
local WIDTH, LINE_WIDTH = 168, 300

local function catcher()
    if F.catcher then return F.catcher end
    local frame = CreateFrame("Frame", "InCharacterFlyout", UIParent)
    frame:SetAllPoints(UIParent); frame:SetFrameStrata("FULLSCREEN"); frame:EnableMouse(false)
    -- Observe outside clicks without a fullscreen mouse interceptor. The original
    -- hardware click still reaches another bar button (or the game) normally.
    frame:RegisterEvent("GLOBAL_MOUSE_DOWN")
    frame:SetScript("OnEvent", function()
        if not F.open then return end
        for _, level in ipairs(F.levels) do if IC.Platform.CursorInside(level) then return end end
        local root = F.levels[1]
        if root and IC.Platform.CursorInside(root.anchor) then return end
        F.Close()
    end)
    frame:SetScript("OnMouseDown", function() F.Close() end)
    frame:SetScript("OnHide", function() F.CloseFrom(1, true) end)
    frame:Hide()
    table.insert(UISpecialFrames, "InCharacterFlyout")
    F.catcher = frame
    return frame
end

local function rowClick(row, mouse)
    local node, depth = row.node, row.depth
    if mouse == "RightButton" then
        if IC.Collections.HasChildren(node) then F.Open(row, node, depth + 1); return end
        if node.type ~= "group" and node.type ~= "persona" and node.type ~= "character" and node.type ~= "family" then IC.Actions.Favorite(node.id); F.Reanchor(); for d = 1, #F.levels do F.Render(d) end end
        return
    end
    if node.type == "group" or node.type == "character" or node.type == "family" then F.Open(row, node, depth + 1); return end
    U.PerformAction(node, F.Close)
end

local function row(level, index)
    local button = level.rows[index]
    if button then return button end
    button = CreateFrame("Button", nil, level)
    button:SetHeight(ROW); button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    button.icon = button:CreateTexture(nil, "ARTWORK"); button.icon:SetSize(ICON, ICON); button.icon:SetPoint("LEFT", 1, 0)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.dot = button:CreateTexture(nil, "OVERLAY"); button.dot:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.dot:SetVertexColor(unpack(U.SOUND)); button.dot:SetSize(4, 4); button.dot:SetPoint("BOTTOMLEFT", button.icon, "BOTTOMLEFT", 1, 1)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.text:SetPoint("LEFT", ICON + 5, 0); button.text:SetPoint("RIGHT", -14, 0); button.text:SetJustifyH("LEFT"); button.text:SetWordWrap(false)
    button.more = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); button.more:SetPoint("RIGHT", -3, 0); button.more:SetText(">")
    button:SetScript("OnClick", rowClick)
    button:SetScript("OnEnter", function(self)
        if IC.Collections.HasChildren(self.node) then F.Open(self, self.node, self.depth + 1) else F.CloseFrom(self.depth + 1) end
        -- The tooltip goes on the side away from the nested list, so it never covers its items.
        local child, anchor = F.levels[self.depth + 1], "ANCHOR_RIGHT"
        if child and child:IsShown() and child.node and child.side == "RIGHT" then anchor = "ANCHOR_LEFT" end
        U.ActionTooltip(self, self.node, anchor)
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    level.rows[index] = button
    return button
end

local function levelFrame(depth)
    local level = F.levels[depth]
    if level then return level end
    level = CreateFrame("Frame", nil, catcher(), "BackdropTemplate")
    level:SetFrameStrata("FULLSCREEN_DIALOG"); level:SetFrameLevel(10 + depth * 5); level:EnableMouse(true); level:EnableMouseWheel(true); level:SetClampedToScreen(true)
    level:SetScript("OnMouseWheel", function(_, delta) F.Scroll(depth, -delta * 3) end)
    U.Backdrop(level, { 0.03, 0.03, 0.04, 0.94 }, { 0.22, 0.22, 0.26, 1 })
    level.rows, level.depth = {}, depth
    F.levels[depth] = level
    return level
end

-- One bounded column, including for unlimited dialogue pools. More items scroll;
-- they must never create an off-screen wall of extra columns.
F.Geometry = IC.MenuModel.Geometry

function F.Scroll(depth, delta)
    local level = F.levels[depth]
    if not level or not level.node then return end
    F.CloseFrom(depth + 1)
    level.offset = math.max(0, math.min(math.max(0, #level.items - level.geometry.rows), (level.offset or 0) + delta))
    F.Render(depth)
end

function F.Render(depth)
    local level = F.levels[depth]
    if not level or not level.node then return end
    local items = IC.Collections.Children(level.node)
    level.items = items
    local lines = level.node.type == "pool"
    local widest = 0
    if not level.measure then level.measure = level:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); level.measure:Hide() end
    if level.measure.GetStringWidth then
        for _, node in ipairs(items) do level.measure:SetText("* " .. (node.name or node.label or "")); widest = math.max(widest, level.measure:GetStringWidth() or 0) end
    end
    local g = F.Geometry(#items, lines, UIParent:GetWidth(), UIParent:GetHeight(), widest); level.geometry = g
    level.offset = math.max(0, math.min(level.offset or 0, math.max(0, #items - g.rows)))
    level:SetSize(g.width, g.height)
    for _, button in ipairs(level.rows) do button:Hide() end
    for index = 1, math.min(#items, g.rows) do
        local node = items[index + level.offset]
        local button = row(level, index)
        button.node, button.depth = node, depth
        button:ClearAllPoints(); button:SetPoint("TOPLEFT", PAD, -PAD - (index - 1) * ROW); button:SetWidth(g.rowWidth)
        U.SetIcon(button.icon, node.icon, IC.Icons[1])
        local pinned = node.type ~= "group" and node.type ~= "persona" and IC.Actions.IsFavorite(node.id)
        local mark = (node.type == "persona" and node.active) and "|cffffd100>|r " or (pinned and "|cffffd100*|r " or "")
        button.text:SetText(mark .. (node.name or node.label))
        button.icon:SetDesaturated(node.empty == true)
        button.dot:SetShown(node.type == "emote" and IC.Emotes.IsAudible(node))
        button.more:SetShown(IC.Collections.HasChildren(node))
        button:Show()
    end
    if not level.previous then
        level.previous = U.Button(level, "<", nil, nil, 24, function() F.Scroll(depth, -level.geometry.rows) end)
        level.previous:SetHeight(16); level.previous:SetPoint("BOTTOMLEFT", PAD, PAD)
        level.next = U.Button(level, ">", nil, nil, 24, function() F.Scroll(depth, level.geometry.rows) end)
        level.next:SetHeight(16); level.next:SetPoint("BOTTOMRIGHT", -PAD, PAD)
        level.range = U.Label(level, "", nil, nil, 100, "GameFontDisableSmall")
        level.range:ClearAllPoints(); level.range:SetPoint("BOTTOM", 0, PAD + 1); level.range:SetJustifyH("CENTER")
    end
    level.previous:SetShown(g.footer > 0); level.next:SetShown(g.footer > 0); level.range:SetShown(g.footer > 0)
    level.previous:SetEnabled(level.offset > 0); level.next:SetEnabled(level.offset + g.rows < #items)
    level.range:SetText((level.offset + 1) .. "–" .. math.min(#items, level.offset + g.rows) .. " / " .. #items)
    return #items
end

-- Pinning rebuilds bars, so the button a list was opened from may now show another item.
-- Follow the button that shows the same group, or close.
function F.Reanchor()
    local level = F.levels[1]
    if not level or not level:IsShown() or not level.anchor or not level.anchor.node or level.anchor.node.id == level.node.id then return end
    local parent = level.anchor:GetParent()
    for _, button in ipairs(parent and parent.actionButtons or {}) do
        if button:IsShown() and button.node and button.node.id == level.node.id then
            local point, _, relativePoint, x, y = "BOTTOMLEFT", nil, "TOPLEFT", 0, 2
            if button.side == "DOWN" then point, relativePoint, y = "TOPLEFT", "BOTTOMLEFT", -2
            elseif button.side == "LEFT" then point, relativePoint, x, y = "TOPRIGHT", "TOPLEFT", -2, 0
            elseif button.side == "RIGHT" then point, relativePoint, x, y = "TOPLEFT", "TOPRIGHT", 2, 0 end
            level.anchor = button; level:ClearAllPoints(); level:SetPoint(point, button, relativePoint, x, y)
            return
        end
    end
    F.Close()
end

function F.CloseFrom(depth, keepCatcher)
    for index = depth, #F.levels do
        local level = F.levels[index]
        level:Hide(); level.node, level.anchor = nil, nil
    end
    if depth <= 1 then
        F.open = false
        if not keepCatcher and F.catcher then F.catcher:Hide() end
    end
end
function F.Close() F.CloseFrom(1) end
function F.IsOpen() return F.open == true end

-- Opens the children of node next to anchor. Depth 1 opens away from the screen edge
-- (up from bars in the lower half); deeper levels open sideways.
function F.Open(anchor, node, depth)
    depth = depth or 1
    -- Protect interactions with older/manually edited cyclic collection data too.
    for index = 1, depth - 1 do
        if F.levels[index].node and F.levels[index].node.id == node.id then F.CloseFrom(depth); return nil end
    end
    local level = F.levels[depth]
    if level and level:IsShown() and level.node and level.node.id == node.id and level.anchor == anchor then return level end
    F.CloseFrom(depth, true)
    if #IC.Collections.Children(node) == 0 then
        if not F.open and F.catcher then F.catcher:Hide() end
        return nil
    end
    catcher():Show()
    level = levelFrame(depth)
    level.node, level.anchor, level.offset = node, anchor, 0
    F.Render(depth)
    level:ClearAllPoints()
    local side = depth == 1 and anchor.side or nil
    if depth == 1 and not side then
        local _, y = anchor:GetCenter(); local _, middle = UIParent:GetCenter()
        side = (y and middle and y > middle) and "DOWN" or "UP"
    end
    if side == "DOWN" then level:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    elseif side == "UP" then level:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
    elseif side == "LEFT" then level:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -2, 0)
    elseif side == "RIGHT" then level:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 2, 0)
    else
        -- Open beside the whole parent list (not the row), so its other columns stay visible.
        local parent = F.levels[depth - 1]
        local offset = PAD + ((anchor:GetTop() or 0) - (parent:GetTop() or 0))
        local right = parent:GetRight()
        if right and right + level:GetWidth() + 4 > UIParent:GetWidth() then level:SetPoint("TOPRIGHT", parent, "TOPLEFT", -2, offset); level.side = "LEFT"
        else level:SetPoint("TOPLEFT", parent, "TOPRIGHT", 2, offset); level.side = "RIGHT" end
    end
    level:Show()
    F.open = true
    return level
end
function F.Toggle(anchor, node)
    local level = F.levels[1]
    if level and level:IsShown() and level.anchor == anchor then F.Close(); return nil end
    return F.Open(anchor, node, 1)
end
