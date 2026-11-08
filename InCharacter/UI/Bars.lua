local _, IC = ...
-- Addon-managed action bars (not Blizzard action bars). Each bar shows one source:
-- favorites, an emote category, all dialogue pools, or one pool.
IC.Bars = { frames = {} }
local B, U = IC.Bars, IC.UI
local C = U.Colors
local GAP, HEADER, MAX = 4, 16, 48
function B.Capacity(config)
    local size = math.max(24, math.min(64, tonumber(config.size) or 36))
    local requested = math.max(1, math.min(12, math.floor(tonumber(config.columns) or 12)))
    local across = math.max(1, math.floor((UIParent:GetWidth() - 20) / (size + GAP)))
    local cellHeight = size + GAP + (config.labels and 14 or 0)
    local down = math.max(1, math.floor((UIParent:GetHeight() - HEADER - 48) / cellHeight))
    local columns = math.min(requested, across)
    local rows = math.floor(tonumber(config.rows) or 0)
    rows = rows > 0 and math.min(rows, down, 12) or down
    return math.max(1, math.min(MAX, columns * rows)), size, columns, rows
end

local function tooltip(button)
    local action = button.action
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT"); GameTooltip:SetText(action.name or action.label, 1, 1, 1)
    if action.type == "emote" then
        local badge, info = IC.Emotes.Badge(action)
        GameTooltip:AddLine("/" .. action.command .. "   " .. badge, 0.8, 0.8, 0.8)
        GameTooltip:AddLine(info.help, 0.75, 0.75, 0.75, true)
        if not action.verified then GameTooltip:AddLine("This client does not recognize this emote.", 1, 0.4, 0.3, true) end
    else
        GameTooltip:AddLine(IC.Actions.Description(action), 0.75, 0.75, 0.75, true)
    end
    GameTooltip:AddLine("Right-click: edit this bar's shown / hidden items", 0.7, 0.8, 0.7, true)
    GameTooltip:Show()
end

local function header(frame)
    local bar = CreateFrame("Button", nil, frame, "BackdropTemplate")
    U.Backdrop(bar, { 0.05, 0.05, 0.07, 0.85 }); bar:SetHeight(HEADER)
    bar:SetPoint("TOPLEFT"); bar:SetPoint("TOPRIGHT")
    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); bar.text:SetPoint("LEFT", 4, 0)
    bar.text:SetPoint("RIGHT", -4, 0); bar.text:SetJustifyH("LEFT"); bar.text:SetWordWrap(false)
    bar:RegisterForClicks("LeftButtonUp", "RightButtonUp"); bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnClick", function(self, mouse)
        local config = frame.config
        if mouse == "RightButton" then IC.Editor.Open("Layouts", frame.index); return end
        config.collapsed = not config.collapsed; B.Refresh()
    end)
    bar:SetScript("OnDragStart", function() if not frame.config.locked then frame:StartMoving() end end)
    bar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local x, y = frame:GetCenter(); local px, py = UIParent:GetCenter()
        frame.config.x, frame.config.y = x - px, y - py
    end)
    bar:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(frame.config.name, 1, 1, 1)
        if frame.missing then GameTooltip:AddLine("This message was removed. Right-click to choose another source; nothing can be sent from this bar.", 1, 0.5, 0.3, true) end
        GameTooltip:AddLine("Click: collapse / expand   Drag: move   Right-click: settings", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    bar:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return bar
end

local function createFrame(index)
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    U.Backdrop(frame, { 0.04, 0.04, 0.06, 0.55 }, { 0.2, 0.2, 0.25, 0.8 })
    frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true)
    frame.index, frame.buttons = index, {}
    frame.header = header(frame)
    frame.previous = U.Button(frame, "<", nil, nil, 28, function() B.Page(frame.index, -1) end)
    frame.next = U.Button(frame, ">", nil, nil, 28, function() B.Page(frame.index, 1) end)
    frame.pageLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.previous:SetPoint("BOTTOMLEFT", 2, 2); frame.next:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.pageLabel:SetPoint("BOTTOM", 0, 8)
    frame:EnableMouseWheel(true); frame:SetScript("OnMouseWheel", function(_, delta) B.Page(frame.index, -delta) end)
    return frame
end
function B.Page(index, delta)
    if IC.InCombat() then IC.Print("Bar page changes wait until after combat; the wheel can browse all actions now."); return end
    local config = IC.Layout().bars[index]
    if not config then return end
    local pages = math.max(1, math.ceil(#IC.Presentation.BarActions(config) / B.Capacity(config)))
    config.page = (math.max(1, config.page or 1) - 1 + delta) % pages + 1; B.Refresh()
end
function B.Pin(action)
    if type(action) == "string" then action = IC.Actions.Resolve(action) end
    if not action or action.type == "submenu" then return false end
    local bars = IC.Layout().bars; local config = IC.Defaults.Bar(#bars + 1)
    config.name, config.source, config.columns = IC.ShortText(action.name or action.label, 40), action.id, 1
    bars[#bars + 1] = config; IC.Changed(); return true
end

local function button(frame, n)
    local slot = frame.buttons[n]
    if slot then return slot end
    slot = U.IconButton(frame, 36, false)
    slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    slot:SetScript("OnClick", function(self, mouse)
        if mouse == "RightButton" then IC.LayoutUI.Open("bar", frame.index)
        else IC.Actions.Dispatch(self.action) end
    end)
    slot:SetScript("OnEnter", tooltip)
    slot:SetScript("OnLeave", function() GameTooltip:Hide() end)
    slot.kind = slot:CreateTexture(nil, "OVERLAY"); slot.kind:SetSize(8, 8); slot.kind:SetPoint("TOPRIGHT", -2, -2)
    slot.kind:SetTexture("Interface\\Buttons\\WHITE8X8")
    slot.caption = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slot.caption:SetPoint("TOP", slot, "BOTTOM", 0, -2); slot.caption:SetWordWrap(false)
    frame.buttons[n] = slot
    return slot
end

function B.Refresh()
    if IC.InCombat() then IC.refreshPending = true; return end
    for _, frame in ipairs(B.frames) do frame:Hide() end
    for index, config in ipairs(IC.Layout().bars) do
        local frame = B.frames[index] or createFrame(index); B.frames[index] = frame
        frame.config, frame.index = config, index
        local actions = IC.Presentation.BarActions(config)
        frame.missing = config.source and config.source:match("^line:") and not IC.Actions.Resolve(config.source)
        local capacity, size, columns, rowLimit = B.Capacity(config)
        local pages = math.max(1, math.ceil(#actions / capacity))
        config.page = math.max(1, math.min(pages, config.page or 1))
        local offset = (config.page - 1) * capacity
        local count = math.min(capacity, #actions - offset)
        local cols = math.min(columns, math.max(1, count))
        local rows = math.max(1, math.min(rowLimit, math.ceil(count / columns)))
        if (config.rows or 0) > 0 then rows, cols = rowLimit, columns end
        local cellHeight = size + GAP + (config.labels and 14 or 0)
        local width = math.max(90, cols * (size + GAP) + GAP)
        local showHeader = not config.locked or config.collapsed or frame.missing
        local top = showHeader and HEADER or 0
        frame.header:SetShown(showHeader)
        frame.header.text:SetText((config.collapsed and "+ " or "") .. config.name .. (frame.missing and " (message removed)" or ""))
        local paged = pages > 1 and not config.collapsed
        frame:SetSize(width, config.collapsed and HEADER or (top + rows * cellHeight + GAP + (paged and 28 or 0)))
        frame.previous:SetShown(paged); frame.next:SetShown(paged); frame.pageLabel:SetShown(paged)
        frame.pageLabel:SetText(config.page .. "/" .. pages)
        frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", config.x, config.y)
        for _, slot in ipairs(frame.buttons) do slot:Hide() end
        if not config.collapsed then
            for n = 1, count do
                local action = actions[offset + n]
                local slot = button(frame, n)
                local col, row = (n - 1) % cols, math.floor((n - 1) / cols)
                if config.vertical then col, row = math.floor((n - 1) / rows), (n - 1) % rows end
                slot.action = action
                slot:SetSize(size, size)
                local normal = slot:GetNormalTexture(); normal:SetSize(size * 1.7, size * 1.7)
                slot:ClearAllPoints(); slot:SetPoint("TOPLEFT", GAP + col * (size + GAP), -top - GAP - row * cellHeight)
                slot:SetIcon(action.icon, IC.Icons[1])
                slot.icon:SetDesaturated(action.type == "emote" and not action.verified)
                local audible = action.type == "emote" and IC.Emotes.IsAudible(action)
                slot.kind:SetShown(audible); slot.kind:SetVertexColor(0.31, 0.76, 0.97, 1)
                slot.caption:SetText(IC.ShortText(action.name or action.label, 16)); slot.caption:SetWidth(size + GAP)
                slot.caption:SetShown(config.labels == true)
                slot:Show()
            end
        end
        frame:SetShown(not config.hidden)
    end
end
