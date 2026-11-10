local _, IC = ...
-- One button for every surface: icon in a 1px frame, a sound dot, and a small arrow on
-- items with children (groups, pools). The arrow opens their exact items.
local U = IC.UI
local unpack = unpack or table.unpack
local WHITE = "Interface\\Buttons\\WHITE8X8"
U.SOUND = { 0.31, 0.76, 0.97, 1 }
local ARROWS = { UP = "Interface\\Buttons\\Arrow-Up-Up", DOWN = "Interface\\Buttons\\Arrow-Down-Up" }
local GLYPHS = { UP = "^", DOWN = "v", RIGHT = ">", LEFT = "<" }

-- Arrow art with a text fallback when the client rejects the texture.
local function setArrow(arrow, direction)
    local ok, result = pcall(arrow.glyph.SetTexture, arrow.glyph, ARROWS[direction])
    local textured = ARROWS[direction] ~= nil and ok and result ~= false
    arrow.glyph:SetShown(textured); arrow.text:SetShown(not textured)
    arrow.text:SetText(GLYPHS[direction] or ">")
end

-- Title = what the action is. Second line = how it sends. A dimmed line names where it came from.
local function poolLines(node)
    node = IC.Actions.Current(node)
    local pool = node.payload and IC.Profile().pools[node.payload]
    if not pool then
        GameTooltip:AddLine(IC.Personas.Name() .. " has no lines here yet", 0.75, 0.75, 0.75)
        GameTooltip:AddLine("Add them in Settings > RP lines", 0.55, 0.55, 0.55); return
    end
    local channel = ({ SAY = "Say", YELL = "Yell", EMOTE = "Emote" })[pool.channel] or pool.channel
    local who = IC.Personas.IsShared(pool.id) and "Shared" or IC.Personas.Name()
    GameTooltip:AddLine(who .. " · " .. channel .. " · " .. #pool.lines .. " lines", 0.75, 0.75, 0.75)
    local source = IC.Personas.Source(pool)
    if source then GameTooltip:AddLine("from " .. source, 0.5, 0.5, 0.5) end
end
function U.ActionTooltip(owner, node, anchor)
    GameTooltip:SetOwner(owner, anchor or "ANCHOR_TOP")
    if node.type == "line" then
        local pool = IC.Profile().pools[node.payload]
        GameTooltip:SetText(pool and pool.name or "Line", 1, 1, 1)
        local text = pool and IC.Dialogue.Line(pool, node.lineID)
        if text then GameTooltip:AddLine(IC.DisplayText(text), 0.9, 0.9, 0.9, true) end
    else
        GameTooltip:SetText(node.fullName or node.name or node.label, 1, 1, 1)
        if node.type == "emote" then
            GameTooltip:AddLine("/" .. node.command, 0.75, 0.75, 0.75)
        elseif node.type == "pool" then poolLines(node)
        elseif node.type == "group" then GameTooltip:AddLine(#IC.Collections.Nodes(node.collection) .. " items", 0.75, 0.75, 0.75)
        elseif node.type == "character" then GameTooltip:AddLine("Your RP character · click to switch", 0.75, 0.75, 0.75)
        elseif node.type == "family" then GameTooltip:AddLine(node.count .. " preset characters", 0.75, 0.75, 0.75)
        elseif node.type == "persona" then GameTooltip:AddLine(node.active and "Playing now" or "Click to play as this character", 0.75, 0.75, 0.75) end
    end
    GameTooltip:Show()
end

function U.ActionButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    button.border = button:CreateTexture(nil, "BACKGROUND"); button.border:SetAllPoints(); button.border:SetColorTexture(0, 0, 0, 0.9)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 1, -1); button.icon:SetPoint("BOTTOMRIGHT", -1, 1); button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button.dot = button:CreateTexture(nil, "OVERLAY"); button.dot:SetTexture(WHITE); button.dot:SetVertexColor(unpack(U.SOUND))
    button.dot:SetSize(5, 5); button.dot:SetPoint("BOTTOMLEFT", 2, 2)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("TOP", button, "BOTTOM", 0, -1); button.label:SetWordWrap(false); button.label:Hide()

    local arrow = CreateFrame("Button", nil, button); button.arrow = arrow
    arrow:SetPoint("TOPRIGHT", 1, 1); arrow:SetFrameLevel(button:GetFrameLevel() + 2)
    arrow:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    arrow.bg = arrow:CreateTexture(nil, "BACKGROUND"); arrow.bg:SetAllPoints(); arrow.bg:SetColorTexture(0, 0, 0, 0.8)
    arrow.glyph = arrow:CreateTexture(nil, "ARTWORK"); arrow.glyph:SetAllPoints()
    arrow.text = arrow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); arrow.text:SetPoint("CENTER")
    arrow:SetScript("OnClick", function() if button.onArrow then button.onArrow(button) end end)
    arrow:SetScript("OnEnter", function() U.ActionTooltip(button, button.node) end)
    arrow:SetScript("OnLeave", function() GameTooltip:Hide() end)

    button:SetScript("OnEnter", function(self) if self.node then U.ActionTooltip(self, self.node) end end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- direction: where this button's flyout opens (UP / DOWN / LEFT / RIGHT).
    function button:SetNode(node, size, direction, showLabel)
        self.node = node
        self:SetSize(size, size)
        U.SetIcon(self.icon, node.icon, IC.Icons[1])
        self.icon:SetDesaturated((node.type == "emote" and not node.verified) or node.empty == true)
        self.dot:SetShown(node.type == "emote" and IC.Emotes.IsAudible(node))
        local children = IC.Collections.HasChildren(node)
        local arrowSize = math.max(6, math.floor(size * 0.35))
        self.arrow:SetSize(arrowSize, arrowSize); self.arrow:SetShown(children)
        if children then setArrow(self.arrow, direction or "UP") end
        self.label:SetShown(showLabel == true)
        self.label:SetWidth(math.max(size, IC.BarModel.LABEL_W)); self.label:SetText(node.short or node.name or node.label)
        self:Show()
    end
    return button
end

-- Keep the input surface alive through dispatch. Closing it first runs nested OnHide callbacks
-- before the restricted chat call; Charades' menu performs the action before hiding as well.
-- Failed sends retain both the user's selection and its surface. There are no deferred sends.
function U.PerformAction(node, close)
    local ok, reason = IC.Actions.Dispatch(node)
    if ok then close() end
    return ok, reason
end

-- Shared click rules. Groups open their flyout; pools play on left and open lines on right;
-- everything else is used on left-click. Returns true when something was opened or used.
function U.ActionClick(button, mouse)
    local node = button.node
    if not node then return false end
    if node.type == "group" or node.type == "character" or node.type == "family" or (node.type == "pool" and mouse == "RightButton") then
        IC.Flyout.Toggle(button, node); return true
    end
    if mouse ~= "LeftButton" then return false end
    U.PerformAction(node, IC.Flyout.Close)
    return true
end
