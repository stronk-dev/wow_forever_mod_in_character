local _, IC = ...
-- Addon-managed action bars (not Blizzard action bars). Each bar shows one source:
-- favorites, an emote category, all dialogue pools, or one pool.
IC.Bars = { frames = {} }
local B, U = IC.Bars, IC.UI
local C = U.Colors
local unpack = unpack or table.unpack
local GAP, HEADER, MAX = 4, 16, 48
local modes = { "random", "shuffle", "sequential", "pool" }
local modeNames = { random = "Random", shuffle = "Shuffle", sequential = "In order", pool = "Pool mode" }
function B.GroupRows(config, width)
    if not config.catalog or config.hideCatalogTabs or config.collapsed then return 0 end
    local groups = IC.Presentation.CatalogGroups(config)
    if IC.Personas and #groups <= 1 then return 0 end
    local count = 1 + #groups
    return math.max(1, math.ceil(count / math.max(1, math.floor((width - GAP) / 112))))
end
function B.Capacity(config)
    if B.IsStrip and B.IsStrip(config) then
        local g = IC.Presentation.StripGeometry(config, #IC.Presentation.BarActions(config), UIParent:GetWidth())
        return g.capacity, g.size, g.columns, g.rows, g.size, g.cellHeight
    end
    local size = math.max(24, math.min(64, tonumber(config.size) or 36))
    local width = config.buttonStyle == "text" and math.max(100, math.min(320, tonumber(config.buttonWidth) or 148)) or size
    local cellHeight = size + GAP + (config.buttonStyle ~= "text" and config.labels and 14 or 0)
    local requested = math.max(1, math.min(12, math.floor(tonumber(config.columns) or 12)))
    local across = math.max(1, math.floor((UIParent:GetWidth() - 20) / (width + GAP)))
    local columns = config.width and math.max(1, math.min(12, math.floor((config.width - GAP) / (width + GAP)))) or math.min(requested, across)
    columns = math.min(columns, across)
    if config.width and config.buttonStyle == "text" then width = (config.width - GAP) / columns - GAP end
    local reserved = config.catalog and (24 + B.GroupRows(config, config.width or (columns * (width + GAP) + GAP)) * 26) or HEADER
    local down = math.max(1, math.floor(((config.height or UIParent:GetHeight()) - reserved - 32) / cellHeight))
    local rows = math.floor(tonumber(config.rows) or 0)
    rows = config.height and down or (rows > 0 and math.min(rows, down, 12) or down)
    return math.max(1, math.min(MAX, columns * rows)), size, columns, rows, width, cellHeight
end

local function tooltip(button)
    local action = button.action
    if button.textStyle and not button.native then button:SetBackdropColor(unpack(C.hover)) end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT"); GameTooltip:SetText(action.fullName or action.name or action.label, 1, 1, 1)
    if action.type == "emote" then
        local badge, info = IC.Emotes.Badge(action)
        GameTooltip:AddLine("/" .. action.command .. "   " .. badge, 0.8, 0.8, 0.8)
        GameTooltip:AddLine(info.help, 0.75, 0.75, 0.75, true)
        if not action.verified then GameTooltip:AddLine("This client does not recognize this emote.", 1, 0.4, 0.3, true) end
    else
        GameTooltip:AddLine(IC.Actions.Description(action), 0.75, 0.75, 0.75, true)
    end
    GameTooltip:AddLine(button.catalogPool and "Click: play once · Right-click: put specific lines on a bar · Shift-right-click: settings"
        or "Right-click: edit this bar's shown / hidden items", 0.7, 0.8, 0.7, true)
    if button.stripDrag and B.IsStrip(button:GetParent().config) then GameTooltip:AddLine("Shift-drag: move · /ic arrange: drag to resize", 0.7, 0.8, 0.7, true) end
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
        if B.editing then B.SelectBar(frame.index); return end
        if mouse == "RightButton" then B.SetEditing(true); B.SelectBar(frame.index); return end
        config.collapsed = not config.collapsed; B.Refresh()
    end)
    bar:SetScript("OnDragStart", function() if B.BeginStripDrag then B.BeginStripDrag(frame, false) elseif not frame.config.locked then frame:StartMoving() end end)
    bar:SetScript("OnDragStop", function()
        if frame.manipulation then B.EndStripDrag(frame, true); return end
        frame:StopMovingOrSizing()
        local x, y = frame:GetCenter(); local px, py = UIParent:GetCenter()
        frame.config.x = x - px
        frame.config.y = ((frame.config.catalog or frame.config.catalogCompanion) and frame:GetTop() or y) - py
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
    frame.index, frame.buttons, frame.iconButtons, frame.textButtons, frame.catalogTabs = index, {}, {}, {}, {}
    frame.header = header(frame)
    frame.previous = U.Button(frame, "<", nil, nil, 28, function() B.Page(frame.index, -1) end)
    frame.next = U.Button(frame, ">", nil, nil, 28, function() B.Page(frame.index, 1) end)
    frame.pageLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.previous:SetPoint("BOTTOMLEFT", 2, 2); frame.next:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.pageLabel:SetPoint("BOTTOM", 0, 8)
    frame.close = U.Button(frame, "×", nil, nil, 20, function() frame.config.hidden = true; IC.Changed() end)
    frame.close:SetHeight(20); frame.close:SetPoint("TOPRIGHT", -2, -2)
    frame.edit = U.Button(frame, "…", nil, nil, 24, function() B.SetEditing(true); B.SelectBar(frame.index) end)
    frame.edit:SetHeight(20); frame.edit:SetPoint("TOPRIGHT", -26, -2); frame.edit.tooltip = "Bar settings: size, rows, columns, playback and shown / hidden actions."
    frame.mode = U.Button(frame, "", nil, nil, 100, function()
        if IC.InCombat() then IC.Print("Change playback mode after combat."); return end
        local current = 0; for i, mode in ipairs(modes) do if mode == frame.config.poolMode then current = i; break end end
        frame.config.poolMode = modes[current % #modes + 1]; IC.Changed()
    end)
    frame.mode:SetHeight(20); frame.mode:SetPoint("TOPRIGHT", -54, -2)
    frame.mode.tooltip = "Change this bar's playback: Random, Shuffle, In order, or each pool's own mode. Changing mode sends nothing."
    frame.empty = U.Label(frame, "", 6, -54, 310, "GameFontHighlightSmall")
    frame:EnableMouseWheel(true); frame:SetScript("OnMouseWheel", function(_, delta) B.Page(frame.index, -delta) end)
    return frame
end
function B.EnsureCatalog()
    local bars = IC.Layout().bars
    for index, config in ipairs(bars) do if config.catalog then return config, index end end
    local config = IC.Defaults.CatalogBar(#bars + 1); bars[#bars + 1] = config
    return config, #bars, true
end
function B.IsEmoteConfig(config)
    return config.source == "favorites" or config.source == "favoriteEmotes" or config.source == "categories" or config.source == "all" or IC.Emotes.byCategory[config.source] ~= nil
end
function B.EnsureEmote()
    for index, config in ipairs(IC.Layout().bars) do if B.IsEmoteConfig(config) then return config, index end end
    local bars = IC.Layout().bars; bars[#bars + 1] = IC.Defaults.EmoteBar(#bars + 1, "categories")
    return bars[#bars], #bars
end
function B.ShowEmotes()
    IC.Profile().presentations.emotes.bar = true
    local first
    for index, config in ipairs(IC.Layout().bars) do
        if B.IsEmoteConfig(config) then config.hidden, config.collapsed = false, false; first = first or index end
    end
    if not first then local bars = IC.Layout().bars; bars[#bars + 1] = IC.Defaults.EmoteBar(#bars + 1, "categories"); first = #bars end
    IC.Changed(); return first
end
function B.MakeBare()
    local index = B.ShowEmotes(); local config = IC.Layout().bars[index]
    config.strip, config.buttonStyle, config.labels, config.stripRows = true, "icons", false, 1
    config.stripHeight, config.width, config.height = nil, nil, nil
    config.size = math.min(config.size, 24); IC.Changed(); return index
end
function B.ShowCatalog()
    IC.Profile().presentations.roleplay.bar = true
    local config = B.EnsureCatalog(); config.hidden, config.collapsed = false, false; IC.Changed()
end
function B.ToggleCatalog()
    local config, _, created = B.EnsureCatalog()
    if created or not IC.Presentation.Enabled("roleplay", "bar") then config.hidden = false else config.hidden = not config.hidden end
    IC.Profile().presentations.roleplay.bar = true
    IC.Changed()
end
function B.SelectCatalog(index, group)
    if IC.InCombat() then IC.Print("Switch catalogues after combat."); return end
    local config = IC.Layout().bars[index]; if not config then return end
    config.catalogGroup, config.page = group, 1; IC.Changed()
end
function B.OpenLines(index, poolID)
    if IC.InCombat() then IC.Print("Open the specific-line bar after combat."); return end
    local pool = IC.Profile().pools[poolID]; local parent = IC.Layout().bars[index]
    if not pool or not parent then return end
    local bars, config = IC.Layout().bars
    for _, bar in ipairs(bars) do if bar.catalogCompanion then config = bar; break end end
    if not config then
        config = IC.Defaults.Bar(#bars + 1); config.catalogCompanion = true
        config.buttonStyle, config.buttonWidth, config.size = "text", 260, 40
        config.columns, config.rows, config.poolMode = 2, 2, "pool"
        config.x, config.y = parent.x, parent.y - ((B.frames[index] and B.frames[index]:GetHeight()) or 100) - 16
        bars[#bars + 1] = config
    end
    config.name, config.source = pool.name .. " · specific lines", "lines:" .. poolID
    config.hidden, config.collapsed, config.page = false, false, 1
    IC.Changed()
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

local function click(frame, self, mouse)
    if B.editing then if B.SelectBar then B.SelectBar(frame.index) end; return end
    if frame.manipulation or (frame.suppressUntil and GetTime() < frame.suppressUntil) then return end
    if mouse == "RightButton" and self.catalogPool and not IsShiftKeyDown() then B.OpenLines(frame.index, self.action.payload)
    elseif mouse == "RightButton" then IC.LayoutUI.Open("bar", frame.index)
    else IC.Actions.Dispatch(self.action) end
end
local function button(frame, n, text)
    local list = text and frame.textButtons or frame.iconButtons
    local slot = list[n]
    if slot then return slot end
    if text then
        slot = U.Button(frame, "", nil, nil, 148, nil, "native"); slot.label:Hide()
        slot.icon = slot:CreateTexture(nil, "ARTWORK"); slot.icon:SetPoint("LEFT", 6, 0)
        function slot:SetIcon(path, fallback) U.SetIcon(self.icon, path, fallback) end
    else slot = U.IconButton(frame, 36, false) end
    slot.textStyle = text
    slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    slot:SetScript("OnClick", function(self, mouse) click(frame, self, mouse) end)
    slot:SetScript("OnEnter", tooltip)
    slot:SetScript("OnLeave", function(self) if self.textStyle then self:SetSelected(false) end; GameTooltip:Hide() end)
    slot.kind = slot:CreateTexture(nil, "OVERLAY"); slot.kind:SetSize(8, 8); slot.kind:SetPoint("TOPRIGHT", -2, -2)
    slot.kind:SetTexture("Interface\\Buttons\\WHITE8X8")
    slot.caption = slot:CreateFontString(nil, "OVERLAY", text and "GameFontHighlight" or "GameFontHighlightSmall")
    if text then slot.caption:SetPoint("LEFT", 36, 0); slot.caption:SetPoint("RIGHT", -6, 0); slot.caption:SetJustifyH("LEFT")
    else slot.caption:SetPoint("TOP", slot, "BOTTOM", 0, -2) end
    slot.caption:SetWordWrap(text == true)
    list[n] = slot
    return slot
end
B.CreateSlot = button

local function renderGrid(frame, config)
    if config.width and config.height and B.ClampBounds then config.width, config.height = B.ClampBounds(frame, config.width, config.height) end
    frame:EnableMouse(true); U.GameBackdrop(frame)
    local groups = config.catalog and IC.Presentation.CatalogGroups(config) or {}
    if config.catalogGroup and config.catalogGroup ~= "all" then
        local exists; for _, group in ipairs(groups) do if group.id == config.catalogGroup then exists = true end end
        if not exists then config.catalogGroup = "all" end
    end
    local actions = IC.Presentation.BarActions(config)
    frame.missing = config.source and config.source:match("^line:") and not IC.Actions.Resolve(config.source)
    local capacity, size, columns, rowLimit, buttonWidth, cellHeight = B.Capacity(config)
    local pages = math.max(1, math.ceil(#actions / capacity))
    config.page = math.max(1, math.min(pages, config.page or 1))
    local offset = (config.page - 1) * capacity
    local count = math.min(capacity, #actions - offset)
    local cols = math.min(columns, math.max(1, count))
    local rows = math.max(1, math.min(rowLimit, math.ceil(count / columns)))
    if (config.rows or 0) > 0 then rows, cols = rowLimit, columns end
    if config.catalog then cols = columns end
    local width = config.width or math.max(config.catalog and 320 or 90, cols * (buttonWidth + GAP) + GAP)
    width = math.min(width, UIParent:GetWidth() - 20)
    local showHeader = config.catalog or config.catalogCompanion or not config.locked or config.collapsed or frame.missing
    local headerHeight = (config.catalog or config.catalogCompanion) and 24 or HEADER
    local top = showHeader and headerHeight or 0
    local tabRows = B.GroupRows(config, width); top = top + tabRows * 26
    frame.header:SetShown(showHeader)
    frame.header:SetHeight(headerHeight)
    frame.header.text:SetPoint("RIGHT", config.catalog and -160 or ((config.catalogCompanion and -54) or -4), 0)
    local title = config.catalog and config.name == "Roleplay" and IC.Personas and IC.Personas.Name() or config.name
    frame.header.text:SetText((config.collapsed and "+ " or "") .. title .. (frame.missing and " (message removed)" or ""))
    local paged = pages > 1 and not config.collapsed
    frame:SetSize(width, config.collapsed and headerHeight or (config.height or (top + rows * cellHeight + GAP + (paged and 28 or 0))))
    frame.mode:SetShown(config.catalog == true); frame.mode:SetText(modeNames[config.poolMode] or "Pool mode")
    frame.close:SetShown(config.catalog or config.catalogCompanion)
    frame.edit:SetShown(config.catalog or config.catalogCompanion)
    for _, tab in ipairs(frame.catalogTabs) do tab:Hide() end
    if config.catalog and not config.hideCatalogTabs and not config.collapsed and tabRows > 0 then
        local tabs = { { id = "all", label = "All pools" } }; for _, group in ipairs(groups) do tabs[#tabs + 1] = group end
        local perRow = math.max(1, math.floor((width - GAP) / 112)); local tabWidth = (width - GAP) / perRow - GAP
        for n, group in ipairs(tabs) do
            local tab = frame.catalogTabs[n]
            if not tab then tab = U.Button(frame, "", 0, 0, 100, function(self) B.SelectCatalog(frame.index, self.groupID) end); frame.catalogTabs[n] = tab end
            tab.groupID = group.id; tab:SetText(group.label); tab.tooltip = (group.title or group.label) .. " · click to show these pools; nothing is sent."
            tab:ClearAllPoints(); tab:SetPoint("TOPLEFT", GAP + ((n - 1) % perRow) * (tabWidth + GAP), -headerHeight - math.floor((n - 1) / perRow) * 26)
            tab:SetSize(tabWidth, 22); tab:SetSelected(group.id == (config.catalogGroup or "all")); tab:Show()
        end
    end
    frame.previous:SetShown(paged); frame.next:SetShown(paged); frame.pageLabel:SetShown(paged)
    frame.previous:ClearAllPoints(); frame.next:ClearAllPoints()
    frame.previous:SetPoint("BOTTOMLEFT", 2, 2); frame.next:SetPoint("BOTTOMRIGHT", config.locked and -2 or -24, 2)
    frame.previous:SetSize(28, 26); frame.next:SetSize(28, 26)
    frame.pageLabel:SetText(config.page .. "/" .. pages)
    if not frame.manipulation then
        frame:ClearAllPoints(); frame:SetPoint((config.catalog or config.catalogCompanion) and "TOP" or "CENTER", UIParent, "CENTER", config.x, config.y)
    end
    for _, list in ipairs({ frame.iconButtons, frame.textButtons }) do for _, slot in ipairs(list) do slot:Hide() end end
    local text = config.buttonStyle == "text"; frame.buttons = text and frame.textButtons or frame.iconButtons
    frame.empty:SetShown((config.catalog or config.catalogCompanion) and #actions == 0 and not config.collapsed)
    frame.empty:ClearAllPoints(); frame.empty:SetPoint("TOPLEFT", 6, -top - 6); frame.empty:SetWidth(width - 12)
    frame.empty:SetText(config.catalogCompanion and "This pool has no saved lines." or "Add lines to any pool, or copy a preset in /ic. Its buttons appear here.")
    if not config.collapsed then
        for n = 1, count do
            local action = actions[offset + n]
            local slot = button(frame, n, text)
            local col, row = (n - 1) % cols, math.floor((n - 1) / cols)
            if config.vertical then col, row = math.floor((n - 1) / rows), (n - 1) % rows end
            slot.action = action
            slot:SetSize(buttonWidth, size); slot.catalogPool = action.type == "pool"
            local normal = slot:GetNormalTexture(); if normal and not text then normal:SetSize(size * 1.7, size * 1.7) end
            if text then slot.icon:SetSize(math.min(24, size - 8), math.min(24, size - 8)); slot.caption:SetHeight(size - 6) end
            slot:ClearAllPoints(); slot:SetPoint("TOPLEFT", GAP + col * (buttonWidth + GAP), -top - GAP - row * cellHeight)
            slot:SetIcon(action.icon, IC.Icons[1])
            slot.icon:SetDesaturated(action.type == "emote" and not action.verified)
            local audible = action.type == "emote" and IC.Emotes.IsAudible(action)
            slot.kind:SetShown(audible); slot.kind:SetVertexColor(0.31, 0.76, 0.97, 1)
            slot.caption:SetText(IC.ShortText(action.name or action.label, text and 120 or 16)); slot.caption:SetWidth(text and (buttonWidth - 42) or (size + GAP))
            slot.caption:SetShown(text or config.labels == true)
            slot:Show()
        end
    end
    frame:SetShown(not config.hidden)
end
B.RenderGrid = renderGrid
function B.RenderFrame(frame, config)
    frame.renderingLayout = true
    if B.IsStrip and B.IsStrip(config) then B.RenderStrip(frame, config) else renderGrid(frame, config) end
    if B.UpdateEditControls then B.UpdateEditControls(frame) end
    if not B.editing and IC.Personas then
        local raw, foreign = IC.Presentation.BarActions(config, true), true
        for _, action in ipairs(raw) do if IC.Personas.ActionAllowed(action) then foreign = false; break end end
        if #raw > 0 and foreign then frame:Hide() end
    end
    if not B.editing and #IC.Presentation.BarActions(config) == 0 and not IC.Presentation.Enabled(B.IsEmoteConfig(config) and "emotes" or "roleplay", "bar") then frame:Hide() end
    frame.renderingLayout = nil
end
function B.Refresh()
    if IC.InCombat() then IC.refreshPending = true; return end
    for _, frame in ipairs(B.frames) do frame:Hide() end
    for index, config in ipairs(IC.Layout().bars) do
        local frame = B.frames[index] or createFrame(index); B.frames[index] = frame
        frame.config, frame.index = config, index
        B.RenderFrame(frame, config)
    end
    if B.RefreshInspector then B.RefreshInspector() end
end
