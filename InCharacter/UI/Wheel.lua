local _, IC = ...
local unpack = unpack or table.unpack
-- Two-ring radial wheel. Inner ring: categories (pointing at one switches the outer ring, never executes).
-- Outer ring: actions. Click (or release the held key in hold mode) uses the highlighted action.
IC.Wheel = { inner = {}, outer = {}, stack = {} }
local W, M, U = IC.Wheel, IC.WheelModel, IC.UI
local C = U.Colors
local SOUND_TINT = { 0.31, 0.76, 0.97, 1 }
function W.Current() return W.stack[#W.stack] and W.stack[#W.stack].node or W.categories[W.category] end
function W.Enter(node)
    if node.type ~= "submenu" then return false end
    W.stack[#W.stack + 1] = { node = node, parentPage = W.page }
    W.page = 1; W.Render(); return true
end
function W.Back()
    local entry = table.remove(W.stack)
    if not entry then W.Close(); return false end
    W.page = entry.parentPage; W.Render(); return true
end

local function slot(parent, size, labelled)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(size, size)
    frame.glow = U.Circle(frame, "BACKGROUND", size * 1.5, { C.accent[1], C.accent[2], C.accent[3], 0.55 })
    frame.glow:SetPoint("CENTER"); frame.glow:Hide()
    frame.icon = frame:CreateTexture(nil, "ARTWORK"); frame.icon:SetAllPoints()
    local mask = frame:CreateMaskTexture()
    mask:SetTexture(U.CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE"); mask:SetAllPoints(frame.icon)
    frame.icon:AddMaskTexture(mask)
    frame.ring = U.Circle(frame, "BORDER", size + 6, { 1, 1, 1, 1 }); frame.ring:SetPoint("CENTER")
    frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.label:SetPoint("TOP", frame, "BOTTOM", 0, -2); frame.label:SetWidth(84); frame.label:SetWordWrap(false)
    frame.label:SetShown(labelled == true)
    return frame
end
local function fill(frame, action, active)
    frame.action = action
    U.SetIcon(frame.icon, action.icon, IC.Icons[1])
    frame.label:SetText(IC.ShortText(action.name or action.label, 60) .. (action.type == "submenu" and " >" or ""))
    local audible = action.type == "emote" and IC.Emotes.IsAudible(action)
    frame.ring:SetVertexColor(unpack(active and C.accent or (audible and SOUND_TINT or C.border)))
    frame.glow:SetShown(active == true)
    frame:Show()
end
local function highlight(frame, on)
    if not frame then return end
    frame.glow:SetShown(on)
    frame.label:SetTextColor(unpack(on and C.accent or C.text))
end

function W.Close()
    W.open, W.held, W.hover = false, false, nil
    if W.catcher then W.catcher:Hide() end
    if GameTooltip then GameTooltip:Hide() end
end

function W.Layout()
    local radius = IC.Profile().wheel.radius
    W.geometry = M.Geometry(radius)
    local size = math.max(420, radius * 2 + 110)
    W.frame:SetSize(size, size)
    W.discOuter:SetSize(radius * 2 + 80, radius * 2 + 80)
    W.discInner:SetSize(W.geometry.split * 2, W.geometry.split * 2)
    W.discHub:SetSize(W.geometry.hub * 2, W.geometry.hub * 2)
end

function W.SetHover(kind, index)
    local frame = kind == "outer" and W.outer[index] or nil
    if W.hover == frame then return end
    highlight(W.hover, false); W.hover = frame; highlight(frame, true)
    W.hoverSince = frame and GetTime() or nil
    GameTooltip:Hide()
    if frame and frame.action.type == "line" then
        GameTooltip:SetOwner(W.info, "ANCHOR_BOTTOM"); GameTooltip:SetText(frame.action.label)
        GameTooltip:AddLine(IC.Actions.Description(frame.action), 1, 1, 1, true); GameTooltip:Show()
    end
    W.RenderHub()
end

function W.SelectCategory(index)
    if not index or index == W.category then return end
    W.category, W.page, W.hover = index, 1, nil
    W.stack = {}
    W.Render()
end

function W.RenderHub()
    local action = W.hover and W.hover.action
    local category = W.Current()
    W.backHint:SetText(#W.stack > 0 and "< Back" or "Cancel")
    local path = { W.categories[W.category].label }
    for _, entry in ipairs(W.stack) do path[#path + 1] = entry.node.label end
    W.breadcrumb:SetText(IC.ShortText(table.concat(path, " > "), 96))
    if action then
        U.SetIcon(W.hubIcon, action.icon, IC.Icons[1])
        W.hubTitle:SetText(action.name or action.label)
        if action.type == "submenu" then
            W.hubDetail:SetText("Click to open this group. Hover and key release never enter a submenu.")
        elseif action.type == "emote" then
            local badge, info = IC.Emotes.Badge(action)
            W.hubDetail:SetText(badge .. "  /" .. action.command .. "\n|cffbbbbbb" .. info.help .. "|r")
        else
            W.hubDetail:SetText(IC.ShortText(IC.Actions.Description(action), 150))
        end
    else
        U.SetIcon(W.hubIcon, category.icon, IC.Icons[1])
        W.hubTitle:SetText(category.label)
        local pages = M.Pages(category)
        local count = #M.Children(category)
        W.hubDetail:SetText(count == 0 and "|cffbbbbbbNothing here yet.|r"
            or ("|cffbbbbbb" .. count .. " entries" .. (pages > 1 and ("  -  page " .. W.page .. "/" .. pages .. ", scroll for more") or "") .. "|r"))
    end
end

function W.Render()
    local geometry, categories = W.geometry, W.categories
    for i, frame in ipairs(W.inner) do frame:Hide() end
    for i, category in ipairs(categories) do
        local frame = W.inner[i] or slot(W.frame, 34, false); W.inner[i] = frame
        local x, y = M.Position(i, #categories, geometry.inner)
        frame:ClearAllPoints(); frame:SetPoint("CENTER", W.frame, "CENTER", x, y)
        fill(frame, { icon = category.icon, name = category.label }, i == W.category)
    end
    for _, frame in ipairs(W.outer) do frame:Hide(); highlight(frame, false) end
    local items = M.Items(W.Current(), W.page)
    W.items = items
    for i, action in ipairs(items) do
        local frame = W.outer[i] or slot(W.frame, 42, true); W.outer[i] = frame
        local x, y = M.Position(i, #items, geometry.outer)
        frame:ClearAllPoints(); frame:SetPoint("CENTER", W.frame, "CENTER", x, y)
        -- Keep neighbouring labels apart on small wheels with a full ring.
        frame.label:SetWidth(math.max(44, math.min(84, 2 * math.pi * geometry.outer / math.max(1, #items) - 6)))
        fill(frame, action, false)
    end
    W.hover = nil
    W.hoverSince = nil; W.readyAt = GetTime() + 0.15
    GameTooltip:Hide()
    W.RenderHub()
end

function W.Use()
    local action = W.hover and W.hover.action
    if not action then return false end
    if action.type == "submenu" then return W.Enter(action) end
    W.Close()
    IC.Actions.Dispatch(action)
    return true
end

-- A wheel bound to a mouse button: the catcher swallows that button, so route it to the binding here.
local function wheelButton(mouse)
    local key = U.MOUSE_KEYS[mouse]
    if not key or not GetBindingKey then return false end
    local combo = U.Modifiers() .. key
    for _, bound in ipairs({ GetBindingKey("INCHARACTER_WHEEL") }) do if bound == combo or bound == key then return true end end
    return false
end
local function cursorOffset()
    local x, y = GetCursorPosition()
    local scale = W.frame:GetEffectiveScale()
    local cx, cy = W.frame:GetCenter()
    return x / scale - cx, y / scale - cy
end
function W.Track()
    if not W.open then return end
    local dx, dy = cursorOffset()
    if not W.moved and W.start and math.abs(dx - W.start[1]) + math.abs(dy - W.start[2]) > 12 then W.moved = true end
    local kind, index = M.Hit(dx, dy, W.geometry, #W.categories, #W.items)
    if kind == "inner" then
        if #W.stack == 0 then W.SelectCategory(index) end
        W.SetHover(nil)
    else W.SetHover(kind, index) end
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
        if button == "RightButton" then W.Close(); return end
        if button ~= "LeftButton" then return end
        W.Track()
        local dx, dy = cursorOffset()
        local kind, index = M.Hit(dx, dy, W.geometry, #W.categories, #W.items)
        if kind == "inner" and #W.stack > 0 then
            W.stack = {}; W.category = nil; W.SelectCategory(index); return
        end
        if not W.Use() and not W.hover then
            if kind == "hub" then W.Back() end
        end
    end)
    catcher:SetScript("OnMouseWheel", function(_, delta)
        local pages = M.Pages(W.Current())
        W.page = (W.page - 1 - delta) % pages + 1; W.Render(); W.Track()
    end)
    local frame = CreateFrame("Frame", nil, catcher); W.frame = frame
    frame:SetClampedToScreen(true)
    frame:SetClampRectInsets(0, 0, 0, -116) -- include breadcrumbs, info and help under the wheel
    W.discOuter = U.Circle(frame, "BACKGROUND", 100, { 0.03, 0.03, 0.05, 0.72 }); W.discOuter:SetPoint("CENTER")
    W.discInner = U.Circle(frame, "BORDER", 100, { 0.1, 0.1, 0.14, 0.9 }); W.discInner:SetPoint("CENTER")
    W.discHub = U.Circle(frame, "ARTWORK", 100, { 0.02, 0.02, 0.03, 0.95 }); W.discHub:SetPoint("CENTER")
    -- The hub only shows an icon; names and explanations go in the info strip under the wheel.
    W.hubIcon = frame:CreateTexture(nil, "OVERLAY"); W.hubIcon:SetSize(40, 40); W.hubIcon:SetPoint("CENTER")
    local hubMask = frame:CreateMaskTexture()
    hubMask:SetTexture(U.CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE"); hubMask:SetAllPoints(W.hubIcon)
    W.hubIcon:AddMaskTexture(hubMask)
    W.hubIcon:SetSize(24, 24); W.hubIcon:ClearAllPoints(); W.hubIcon:SetPoint("CENTER", 0, 8)
    W.backHint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); W.backHint:SetPoint("CENTER", 0, -14)
    W.info = U.Panel(frame, 400, 86, { 0.03, 0.03, 0.05, 0.9 }); W.info:SetPoint("TOP", frame, "BOTTOM", 0, 8)
    W.breadcrumb = W.info:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    W.breadcrumb:SetPoint("TOP", 0, -6); W.breadcrumb:SetWidth(380); W.breadcrumb:SetWordWrap(false)
    W.hubTitle = W.info:CreateFontString(nil, "OVERLAY", "GameFontNormal"); W.hubTitle:SetPoint("TOP", 0, -24)
    W.hubTitle:SetWidth(320); W.hubTitle:SetWordWrap(false)
    W.hubDetail = W.info:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); W.hubDetail:SetPoint("TOP", W.hubTitle, "BOTTOM", 0, -3)
    W.hubDetail:SetWidth(320)
    W.help = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); W.help:SetPoint("TOP", W.info, "BOTTOM", 0, -4)
    W.help:SetTextColor(unpack(C.muted))
    frame:SetScript("OnUpdate", W.Track)
    table.insert(UISpecialFrames, "InCharacterWheel")
end

function W.Open(held)
    if not IC.db then return end
    if not W.frame then W.Create() end
    W.categories = M.Categories()
    W.category = #W.categories[1].items > 0 and 1 or 2
    W.stack = {}
    W.page, W.open, W.held = 1, true, held == true
    W.Layout()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    W.frame:SetScale(math.min(1, (UIParent:GetHeight() - 20) / (W.frame:GetHeight() + 116), (UIParent:GetWidth() - 20) / W.frame:GetWidth()))
    local fx = x / scale / W.frame:GetScale()
    local fy = y / scale / W.frame:GetScale()
    W.frame:ClearAllPoints(); W.frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", fx, fy)
    local hold = W.held and IC.Profile().wheel.mode == "hold"
    W.help:SetText(hold and "Click groups; pause on an action, release to use. Centre: Back. Right-click / Esc: cancel."
        or "Hover root categories; click groups or actions. Centre: Back. Scroll: pages. Right-click / Esc: cancel.")
    W.catcher:Show(); W.Render()
    -- Clamping near a screen edge can put the cursor over an action; release only counts after moving.
    local dx, dy = cursorOffset(); W.start, W.moved = { dx, dy }, false
end
function W.Toggle() if W.open then W.Close() else W.Open(false) end end
function W.Binding(keystate)
    if keystate == "down" then
        if W.open then W.Close() else W.Open(true) end
    elseif keystate == "up" and W.open and W.held then
        W.held = false
        if IC.Profile().wheel.mode == "hold" then
            W.Track()
            local action = W.hover and W.hover.action
            local ready = action and action.type ~= "submenu" and W.hoverSince and GetTime() - W.hoverSince >= 0.15 and GetTime() >= W.readyAt
            if not (W.moved and ready and W.Use()) then W.Close() end
        end
        -- Click mode stays open after the key is released; the next key press closes it.
    end
end

_G.InCharacter_WheelBinding = W.Binding
_G.InCharacter_ToggleEditor = function() if IC.db and IC.Editor then IC.Editor.Toggle() end end
_G.InCharacter_FavoriteBinding = function(index)
    if IC.db then IC.Actions.Dispatch(IC.Actions.List("favorites")[index]) end
end
_G.InCharacter_MenuBinding = function() if IC.db and IC.Menu then IC.Menu.OpenAtCursor() end end
BINDING_HEADER_INCHARACTER = "In Character"
BINDING_NAME_INCHARACTER_EDITOR = "Open In Character"
BINDING_NAME_INCHARACTER_WHEEL = "Radial wheel"
BINDING_NAME_INCHARACTER_MENU = "Emote menu at cursor"
for i = 1, 4 do _G["BINDING_NAME_INCHARACTER_FAVORITE" .. i] = "Use favorite " .. i end
