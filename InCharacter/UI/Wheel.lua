local _, IC = ...
-- Radial wheel at the cursor, after OPie and ConsolePort:
--   * at most 8 slices; the whole wedge selects (by angle), the centre is back / close;
--   * a slice with children (category, RP character, pool) shows a corner badge; choosing it
--     replaces the ring with that level, with a short zoom. No fans, no preview chips;
--   * one label, outside the ring beside the pointed slice, with the full name. At rest the same
--     label names the level above the ring. Nothing is ever squeezed into the centre.
-- Pointing never sends: only a click, or releasing the key in hold mode, does.
IC.Wheel = { slots = {}, stack = {} }
local W, M, U = IC.Wheel, IC.WheelModel, IC.UI
local unpack = unpack or table.unpack
local ZOOM = 0.12
local LABEL_WIDTH = 240

local function settings() return IC.Profile().wheel end
local function iconSize() return math.max(32, math.min(48, math.floor(tonumber(settings().iconSize) or M.ICON))) end
function W.Root() return settings().root or "main" end

local function slot(parent)
    local button = U.ActionButton(parent)
    button:EnableMouse(false); button.arrow:EnableMouse(false)
    return button
end
local function cursorOffset()
    local x, y = IC.Platform.Cursor()
    local scale = W.frame:GetEffectiveScale()
    local cx, cy = W.frame:GetCenter()
    return x / scale - cx, y / scale - cy
end
W.CursorOffset = cursorOffset
function W.Current() return W.stack[#W.stack] end

local function detail(node)
    if node.type == "group" then return #IC.Collections.Nodes(node.collection) .. " items" end
    if node.type == "character" then return "switch character" end
    if node.type == "persona" then return node.active and "playing now" or "play as" end
    if node.type == "pool" then
        node = IC.Actions.Current(node)
        if node.empty then return "no lines yet" end
        local pool = IC.Profile().pools[node.payload]
        return pool and (#pool.lines .. " lines · right-click: pick one") or nil
    end
    if node.type == "emote" then return "/" .. node.command end
end

-- The single label: the pointed slice outside the ring, or the level name above it.
local function label(button)
    local g = W.geometry
    W.label:ClearAllPoints(); W.sub:ClearAllPoints()
    if button then
        local x, y, justify = M.LabelPoint(button.angle, g)
        local point = justify == "LEFT" and "LEFT" or justify == "RIGHT" and "RIGHT" or (y > 0 and "BOTTOM" or "TOP")
        W.label:SetPoint(point, W.frame, "CENTER", x, y); W.label:SetJustifyH(justify)
        W.label:SetText(button.node.name or button.node.label or "")
        local text = detail(button.node)
        W.sub:SetText(text or ""); W.sub:SetJustifyH(justify)
        if point == "BOTTOM" then W.sub:SetPoint("BOTTOM", W.label, "TOP", 0, 1)
        else W.sub:SetPoint(justify == "RIGHT" and "TOPRIGHT" or justify == "LEFT" and "TOPLEFT" or "TOP", W.label, justify == "RIGHT" and "BOTTOMRIGHT" or justify == "LEFT" and "BOTTOMLEFT" or "BOTTOM", 0, -1) end
    else
        local node = W.Current()
        W.label:SetPoint("BOTTOM", W.frame, "CENTER", 0, M.LabelEdge(g)); W.label:SetJustifyH("CENTER")
        local trail = {}
        for index, entry in ipairs(W.stack) do if index > 1 then trail[#trail + 1] = entry.name or entry.label end end
        W.label:SetText(#trail > 0 and table.concat(trail, " › ") or "")
        W.sub:SetText(W.pages > 1 and ("page " .. W.page .. " of " .. W.pages .. " · scroll") or "")
        W.sub:SetPoint("BOTTOM", W.label, "TOP", 0, 1); W.sub:SetJustifyH("CENTER")
        if node and #trail == 0 and W.pages > 1 then W.label:SetText(" ") end
    end
    W.label:SetHeight(math.max(1, W.label:GetStringHeight()))
    W.sub:SetHeight(math.max(1, W.sub:GetStringHeight()))
end

function W.Render()
    local node = W.Current()
    local all = IC.Collections.Children(node)
    W.pages = M.Pages(#all)
    W.page = math.max(1, math.min(W.pages, W.page or 1))
    local items = M.Slice(all, W.page)
    W.items = items
    local g = M.Geometry(math.max(1, #items), iconSize()); W.geometry = g
    W.frame:SetSize(g.size, g.size)
    -- Keep room on screen for the label beside the ring.
    W.frame:SetClampRectInsets(-LABEL_WIDTH - 12, LABEL_WIDTH + 12, 100, -100)
    W.disc:SetSize(g.radius * 2 + g.icon + 14, g.radius * 2 + g.icon + 14)
    W.hub:SetSize(g.hub * 2, g.hub * 2)
    for _, button in ipairs(W.slots) do button:Hide() end
    for index, item in ipairs(items) do
        local button = W.slots[index] or slot(W.frame); W.slots[index] = button
        button:SetNode(item, g.icon, "UP", false); button:SetScale(1)
        button.arrow:SetShown(IC.Collections.HasChildren(item))
        local x, y, angle = M.Position(index, #items, g.radius)
        button.angle = angle
        button:ClearAllPoints(); button:SetPoint("CENTER", W.frame, "CENTER", x, y)
    end
    W.back:SetText(#W.stack > 1 and "‹" or "×")
    W.hover = false; W.SetHover(nil)
end

function W.SetHover(button)
    if W.hover == button then return end
    if W.hover then W.hover:SetScale(1) end
    W.hover = button
    W.highlight:SetShown(button ~= nil)
    if button then
        button:SetScale(1.1)
        local size = W.geometry.icon * 1.1 + 6
        W.highlight:SetSize(size, size); W.highlight:ClearAllPoints(); W.highlight:SetPoint("CENTER", button, "CENTER")
        W.hoverSince = IC.Platform.Time()
    end
    W.backGlow:SetShown(button == nil and W.inHub == true)
    label(button)
end

function W.Track()
    if not W.open then return end
    if W.zoomFrom then
        local t = math.min(1, (IC.Platform.Time() - W.zoomFrom) / ZOOM)
        W.frame:SetScale(0.7 + 0.3 * t); if t >= 1 then W.zoomFrom = nil end
    end
    local dx, dy = cursorOffset()
    if not W.moved and W.start and math.abs(dx - W.start[1]) + math.abs(dy - W.start[2]) > 8 then W.moved = true end
    W.inHub = M.Zone(dx, dy, W.geometry) == "hub"
    if W.inHub or #W.items == 0 then W.SetHover(nil); W.backGlow:SetShown(W.inHub); return end
    W.SetHover(W.slots[M.Sector(M.Angle(dx, dy), #W.items)])
end

function W.Enter(node)
    for _, ancestor in ipairs(W.stack) do if ancestor.id == node.id then return end end
    W.stack[#W.stack + 1] = node; W.page = 1; W.Render()
    W.zoomFrom = IC.Platform.Time(); W.frame:SetScale(0.7)
end
function W.Back()
    if #W.stack <= 1 then W.Close(); return end
    table.remove(W.stack); W.page = 1; W.Render()
end
function W.Page(delta)
    if not W.open or (W.pages or 1) < 2 then return end
    W.page = (W.page - 1 + delta) % W.pages + 1; W.Render()
end

-- Uses the pointed slice. Groups and the character switcher open; pools play their next line
-- (right-click opens their lines); everything else sends and closes.
function W.Use(mouse)
    local button = W.hover
    if not button then return false end
    local node = button.node
    if node.type == "group" or node.type == "character" then W.Enter(node); return true end
    if mouse == "RightButton" then
        if node.type == "pool" and IC.Collections.HasChildren(node) then W.Enter(node); return true end
        return false
    end
    U.PerformAction(node, W.Close)
    return true
end

-- A wheel bound to a mouse button: the catcher swallows that button, so route it to the binding here.
local function wheelButton(mouse)
    local key = U.MOUSE_KEYS[mouse]
    if not key or not IC.Platform.BindingKeys then return false end
    local combo = U.Modifiers() .. key
    for _, bound in ipairs({ IC.Platform.BindingKeys("INCHARACTER_WHEEL") }) do if bound == combo or bound == key then return true end end
    return false
end

function W.Create()
    local catcher = CreateFrame("Frame", "InCharacterWheel", UIParent)
    W.catcher = catcher
    catcher:SetAllPoints(UIParent); catcher:SetFrameStrata("FULLSCREEN_DIALOG"); catcher:EnableMouse(true)
    catcher:EnableMouseWheel(true); catcher:Hide()
    catcher:SetScript("OnHide", function() W.open, W.held, W.hover = false, false, nil end)
    catcher:SetScript("OnMouseUp", function(_, button) if wheelButton(button) then W.Binding("up") end end)
    catcher:SetScript("OnMouseDown", function(_, button)
        if wheelButton(button) then W.Binding("down"); return end
        W.Track()
        if button == "LeftButton" or button == "RightButton" then
            if W.Use(button) then return end
            local dx, dy = cursorOffset()
            if button == "RightButton" or M.Zone(dx, dy, W.geometry) == "hub" then W.Back() end
        end
    end)
    catcher:SetScript("OnMouseWheel", function(_, delta) W.Page(-delta) end)
    local frame = CreateFrame("Frame", nil, catcher); W.frame = frame
    frame:SetClampedToScreen(true)
    W.disc = U.Circle(frame, "BACKGROUND", 100, { 0, 0, 0, 0.5 }); W.disc:SetPoint("CENTER")
    W.hub = U.Circle(frame, "BORDER", 40, { 0.02, 0.02, 0.02, 0.85 }); W.hub:SetPoint("CENTER")
    W.backGlow = U.Circle(frame, "ARTWORK", 30, { 1, 0.82, 0, 0.25 }); W.backGlow:SetAllPoints(W.hub); W.backGlow:Hide()
    W.back = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); W.back:SetPoint("CENTER", 0, 1)
    W.highlight = frame:CreateTexture(nil, "BORDER"); W.highlight:SetColorTexture(unpack(U.Colors.accent)); W.highlight:Hide()
    W.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    W.label:SetWidth(LABEL_WIDTH); W.label:SetWordWrap(true)
    W.sub = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    W.sub:SetWidth(LABEL_WIDTH); W.sub:SetWordWrap(true)
    frame:SetScript("OnUpdate", W.Track)
    table.insert(UISpecialFrames, "InCharacterWheel")
end

function W.Close()
    W.open, W.held, W.hover = false, false, nil
    if W.catcher then W.catcher:Hide() end
    if GameTooltip then GameTooltip:Hide() end
end

function W.Open(held)
    if not IC.db then return end
    if IC.Flyout then IC.Flyout.Close() end
    if not W.frame then W.Create() end
    local root = IC.Collections.Get(W.Root()) or IC.Collections.Get("main")
    W.stack = { { id = "set:" .. root.id, type = "group", collection = root.id, name = root.name, icon = root.icon } }
    W.page, W.open, W.held, W.zoomFrom = 1, true, held == true, nil
    W.frame:SetScale(1)
    W.catcher:Show(); W.Render()
    local x, y = IC.Platform.Cursor()
    local scale = UIParent:GetEffectiveScale()
    W.frame:ClearAllPoints(); W.frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    -- Clamping near a screen edge can put the cursor over a slice; release only counts after moving.
    local dx, dy = cursorOffset(); W.start, W.moved = { dx, dy }, false
    W.Track()
end
function W.Toggle() if W.open then W.Close() else W.Open(false) end end
function W.Binding(keystate)
    if keystate == "down" then
        if W.open then W.Close() else W.Open(true) end
    elseif keystate == "up" and W.open and W.held then
        W.held = false
        if settings().mode == "hold" then
            W.Track()
            local node = W.hover and W.hover.node
            -- Releasing on a group or the character opens it and leaves the ring open for a click.
            if W.moved and node and (node.type == "group" or node.type == "character") then W.Enter(node); return end
            if not (W.moved and node and W.Use("LeftButton")) then W.Close() end
        end
        -- Click mode stays open after the key is released; the next key press closes it.
    end
end

_G.InCharacter_WheelBinding = W.Binding
_G.InCharacter_ToggleEditor = function() if IC.db and IC.Editor then IC.Editor.Toggle() end end
_G.InCharacter_FavoriteBinding = function(index)
    if IC.db then
        local action = IC.Actions.List("favorites")[index]
        if action then if action.type == "group" or action.type == "character" then IC.Menu.OpenAtCursor(action) else IC.Actions.Dispatch(action) end end
    end
end
_G.InCharacter_MenuBinding = function() if IC.db and IC.Menu then IC.Menu.OpenAtCursor() end end
BINDING_HEADER_INCHARACTER = "In Character"
BINDING_NAME_INCHARACTER_EDITOR = "Open In Character"
BINDING_NAME_INCHARACTER_WHEEL = "Radial wheel"
BINDING_NAME_INCHARACTER_MENU = "Emote menu at cursor"
BINDING_NAME_INCHARACTER_BARS = "Show / hide bars"
BINDING_NAME_INCHARACTER_EDITMODE = "Move and edit bars"
for i = 1, 4 do _G["BINDING_NAME_INCHARACTER_FAVORITE" .. i] = "Use favorite " .. i end
