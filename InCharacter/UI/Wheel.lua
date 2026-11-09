local _, IC = ...
-- Compact radial ring centred on the cursor. It shows one collection (default: the main bar's).
-- Groups and pools show small previews of their contents; pointing at one fans its items out
-- beyond it. Pointing never sends: only a click (or releasing the key in hold mode) does.
IC.Wheel = { slots = {}, fanSlots = {}, stack = {} }
local W, M, U = IC.Wheel, IC.WheelModel, IC.UI
local unpack = unpack or table.unpack
local PREVIEW, PREVIEW_SIZE = 4, 10

local function settings() return IC.Profile().wheel end
local function iconSize() return math.max(24, math.min(40, math.floor(tonumber(settings().iconSize) or 30))) end
function W.Root() return settings().root or "main" end

local function slot(parent)
    local button = U.ActionButton(parent)
    button:EnableMouse(false); button.arrow:EnableMouse(false)
    button.previews = {}
    for i = 1, PREVIEW do
        local texture = button:CreateTexture(nil, "OVERLAY"); texture:SetSize(PREVIEW_SIZE, PREVIEW_SIZE)
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92); button.previews[i] = texture
    end
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

-- Lays out the ring for the current node and page.
function W.Render()
    W.CloseFan()
    local node = W.Current()
    local all = IC.Collections.Children(node)
    W.pages = M.Pages(#all)
    W.page = math.max(1, math.min(W.pages, W.page or 1))
    local items = M.Slice(all, W.page)
    W.items = items
    local g = M.Geometry(#items, iconSize()); W.geometry = g
    W.frame:SetSize(g.size, g.size)
    -- Reserve exactly the furthest extent of all fan rows, including icon corners.
    local positions = M.Fan(10000, 0, g)
    local extent = g.size / 2
    for _, p in ipairs(positions) do extent = math.max(extent, math.sqrt(p.x * p.x + p.y * p.y) + g.fanIcon / math.sqrt(2)) end
    local reach = math.max(0, extent - g.size / 2)
    W.frame:SetClampRectInsets(-reach, reach, reach, -reach)
    W.disc:SetSize(g.radius * 2 + g.icon + 12, g.radius * 2 + g.icon + 12)
    W.hub:SetSize(g.hub * 2, g.hub * 2)
    for _, button in ipairs(W.slots) do button:Hide() end
    for index, item in ipairs(items) do
        local button = W.slots[index] or slot(W.frame); W.slots[index] = button
        button:SetNode(item, g.icon, "UP", false); button.arrow:Hide()
        local x, y, angle = M.Position(index, #items, g.radius)
        button.angle = angle
        button:ClearAllPoints(); button:SetPoint("CENTER", W.frame, "CENTER", x, y)
        local children = IC.Collections.HasChildren(item) and IC.Collections.Children(item) or {}
        local distance = math.ceil((g.icon + PREVIEW_SIZE) / 2 * math.sqrt(2)) + 4
        local previewCount = math.min(PREVIEW, #children)
        local previewStep = math.min(0.16, ((math.pi * 2 / #items) * 0.85 - PREVIEW_SIZE / (g.radius + distance)) / math.max(1, previewCount - 1))
        for i, texture in ipairs(button.previews) do
            local child = children[i]
            texture:SetShown(child ~= nil)
            if child then
                local a = angle + (i - (previewCount + 1) / 2) * previewStep
                U.SetIcon(texture, child.icon, IC.Icons[1])
                texture:ClearAllPoints()
                texture:SetPoint("CENTER", W.frame, "CENTER", math.sin(a) * (g.radius + distance), math.cos(a) * (g.radius + distance))
            end
        end
    end
    W.pageText:SetText(W.pages > 1 and (W.page .. "/" .. W.pages) or "")
    W.title:SetWidth(math.max(60, (g.radius - g.icon / 2) * 2 - 8))
    W.SetHover(nil)
end

function W.CloseFan()
    for _, button in ipairs(W.fanSlots) do button:Hide() end
    if W.fanOwner then for _, texture in ipairs(W.fanOwner.previews) do if texture.wasShown then texture:Show() end end end
    W.fan, W.fanOwner, W.fanItems = nil, nil, nil
end
-- Reveals the items of a ring slot beyond it. Nothing is sent.
function W.OpenFan(button)
    if W.fanOwner == button then return end
    W.CloseFan()
    local children = IC.Collections.Children(button.node)
    if #children == 0 then return end
    local positions, placed = M.Fan(#children, button.angle, W.geometry)
    W.fan, W.fanOwner, W.fanItems = positions, button, {}
    for i = 1, placed do
        local child = children[i]
        if i == placed and placed < #children then
            child = { id = "more:" .. button.node.id, type = "more", target = button.node, name = "More (" .. (#children - placed + 1) .. ")", icon = "Interface\\Icons\\INV_Misc_QuestionMark" }
        end
        local fanButton = W.fanSlots[i] or slot(W.frame); W.fanSlots[i] = fanButton
        fanButton:SetNode(child, W.geometry.fanIcon, "UP", false); fanButton.arrow:Hide()
        for _, texture in ipairs(fanButton.previews) do texture:Hide() end
        fanButton:ClearAllPoints(); fanButton:SetPoint("CENTER", W.frame, "CENTER", positions[i].x, positions[i].y)
        W.fanItems[i] = child
    end
    for _, texture in ipairs(button.previews) do texture.wasShown = texture:IsShown(); texture:Hide() end
end

function W.SetHover(button)
    if W.hover == button then return end
    W.hover = button
    W.highlight:SetShown(button ~= nil)
    if button then
        local size = button:GetWidth() + 6
        W.highlight:SetSize(size, size); W.highlight:ClearAllPoints(); W.highlight:SetPoint("CENTER", button, "CENTER")
        W.title:SetText(button.node.name or button.node.label)
        W.hoverSince = IC.Platform.Time()
    else
        local node = W.Current()
        W.title:SetText(#W.stack > 1 and (node.name or node.label) or "")
    end
end

function W.Track()
    if not W.open then return end
    local dx, dy = cursorOffset()
    if not W.moved and W.start and math.abs(dx - W.start[1]) + math.abs(dy - W.start[2]) > 8 then W.moved = true end
    local zone = M.Zone(dx, dy, W.geometry)
    if zone == "hub" or #W.items == 0 then W.SetHover(nil); return end
    if zone == "ring" then
        local button = W.slots[M.Sector(M.Angle(dx, dy), #W.items)]
        W.SetHover(button)
        if IC.Collections.HasChildren(button.node) then W.OpenFan(button) elseif W.fanOwner ~= button then W.CloseFan() end
        return
    end
    if W.fan then
        local index = M.Nearest(dx, dy, W.fan, W.geometry.fanIcon * 0.8)
        W.SetHover(index and W.fanSlots[index] or nil)
    else W.SetHover(nil) end
end

function W.Enter(node)
    for _, ancestor in ipairs(W.stack) do if ancestor.id == node.id then return end end
    W.stack[#W.stack + 1] = node; W.page = 1; W.Render()
end
function W.Back()
    if #W.stack <= 1 then W.Close(); return end
    table.remove(W.stack); W.page = 1; W.Render()
end
function W.Page(delta)
    if not W.open or (W.pages or 1) < 2 then return end
    W.page = (W.page - 1 + delta) % W.pages + 1; W.Render()
end

-- Uses the hovered item. Groups and "more" enter; pools play their next line; everything else sends.
function W.Use(mouse)
    local button = W.hover
    if not button then return false end
    local node = button.node
    if node.type == "more" then W.Enter(node.target); return true end
    if node.type == "group" then W.Enter(node); return true end
    if mouse == "RightButton" then
        if node.type == "pool" then W.Enter(node); return true end
        return false
    end
    W.Close()
    IC.Actions.Dispatch(node)
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
    W.disc = U.Circle(frame, "BACKGROUND", 100, { 0, 0, 0, 0.45 }); W.disc:SetPoint("CENTER")
    W.hub = U.Circle(frame, "BORDER", 40, { 0.02, 0.02, 0.02, 0.85 }); W.hub:SetPoint("CENTER")
    W.highlight = frame:CreateTexture(nil, "BORDER"); W.highlight:SetColorTexture(unpack(U.Colors.accent)); W.highlight:Hide()
    W.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); W.title:SetPoint("CENTER", 0, 0); W.title:SetWordWrap(false)
    W.pageText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); W.pageText:SetPoint("CENTER", 0, -14)
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
    W.page, W.open, W.held = 1, true, held == true
    W.catcher:Show(); W.Render()
    local x, y = IC.Platform.Cursor()
    local scale = UIParent:GetEffectiveScale()
    W.frame:ClearAllPoints(); W.frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    -- Clamping near a screen edge can put the cursor over an item; release only counts after moving.
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
            -- Release only uses a plain action after the cursor moved; groups and the centre just close.
            local usable = node and node.type ~= "group" and node.type ~= "more"
            if not (W.moved and usable and W.Use("LeftButton")) then W.Close() end
        end
        -- Click mode stays open after the key is released; the next key press closes it.
    end
end

_G.InCharacter_WheelBinding = W.Binding
_G.InCharacter_ToggleEditor = function() if IC.db and IC.Editor then IC.Editor.Toggle() end end
_G.InCharacter_FavoriteBinding = function(index)
    if IC.db then
        local action = IC.Actions.List("favorites")[index]
        if action then if action.type == "group" then IC.Menu.OpenAtCursor(action) else IC.Actions.Dispatch(action) end end
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
