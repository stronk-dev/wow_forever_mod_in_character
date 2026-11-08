local _, IC = ...
local unpack = unpack or table.unpack
local U = IC.UI
local C = U.Colors
IC.Editor = { tab = "Home", emoteCategory = "essentials", search = "", barIndex = 1,
    drafts = setmetatable({}, { __mode = "k" }), pages = {} }
local E = IC.Editor
local WIDTH, HEIGHT, NAV = 960, 620, 150
local PAGE_W, PAGE_H = WIDTH - NAV - 24, HEIGHT - 70
local TABS = { "Home", "Emotes", "Dialogue", "Favorites", "Layouts", "Profiles" }
local TAB_LABELS = { Home = "Home / setup", Emotes = "Emote library", Dialogue = "Dialogue & messages", Favorites = "Favorite actions", Layouts = "Bars, wheel & button", Profiles = "Profiles" }

local function status(text) if E.status then E.status:SetText(text or "") end end
local function changed() IC.Changed() end
local function iconText(icon) return icon and tostring(icon) or IC.Icons[1] end
local function splitLines(text)
    local lines = {}; text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    for line in (text .. "\n"):gmatch("(.-)\n") do if IC.Trim(line) ~= "" then lines[#lines + 1] = line end end
    return lines
end

-- Icon picker -------------------------------------------------------------------------------------
local PICK_COLS, PICK_ROWS = 10, 6
function E.PickIcon(current, done)
    local picker = E.picker
    if not picker then
        picker = CreateFrame("Frame", "InCharacterIconPicker", UIParent, "BackdropTemplate")
        E.picker = picker; U.Backdrop(picker, C.bg, C.accent)
        picker:SetSize(PICK_COLS * 40 + 24, PICK_ROWS * 40 + 162); picker:SetPoint("CENTER"); picker:SetFrameStrata("FULLSCREEN_DIALOG")
        picker:EnableMouse(true); picker:EnableMouseWheel(true)
        U.Heading(picker, "Choose an icon", 12, -10)
        U.Button(picker, "Close", 338, -6, 72, function() picker:Hide() end)
        picker.search = U.Input(picker, 12, -38, 260)
        picker.category = U.Dropdown(picker, 282, -38, 128, U.Options({ "All", "Combat", "Social", "Reactions", "Idle", "Voice/Fun" }), function() picker:Filter() end)
        picker.slots = {}
        for i = 1, PICK_COLS * PICK_ROWS do
            local slot = U.IconButton(picker, 36, false)
            slot:SetPoint("TOPLEFT", 12 + ((i - 1) % PICK_COLS) * 40, -78 - math.floor((i - 1) / PICK_COLS) * 40)
            slot:SetScript("OnClick", function(self) picker.path:SetText(iconText(self.value)); picker.preview:SetIcon(self.value) end)
            slot:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(picker.names[self.value] or tostring(self.value)); GameTooltip:Show()
            end)
            slot:SetScript("OnLeave", function() GameTooltip:Hide() end)
            picker.slots[i] = slot
        end
        picker.page = 0
        function picker:Filter()
            if not self.allIcons then return end
            self.icons, self.page = {}, 0
            local query = IC.Trim(self.search:GetText()):lower()
            for _, icon in ipairs(self.allIcons) do
                if (self.category.value == "All" or (self.groups[icon] and self.groups[icon][self.category.value]))
                    and (query == "" or ((self.names[icon] or "") .. " " .. tostring(icon)):lower():find(query, 1, true)) then self.icons[#self.icons + 1] = icon end
            end
            self:Render()
        end
        picker.search:SetScript("OnTextChanged", function() picker:Filter() end)
        function picker:Render()
            local per = PICK_COLS * PICK_ROWS
            local pages = math.max(1, math.ceil(#self.icons / per))
            self.page = math.max(0, math.min(pages - 1, self.page))
            for i, slot in ipairs(self.slots) do
                local value = self.icons[self.page * per + i]
                slot.value = value; slot:SetShown(value ~= nil)
                if value then slot:SetIcon(value) end
            end
            self.pageText:SetText("Page " .. (self.page + 1) .. " / " .. pages .. "  (scroll to browse)")
        end
        picker:SetScript("OnMouseWheel", function(self, delta) self.page = self.page - delta; self:Render() end)
        local y = -84 - PICK_ROWS * 40
        picker.pageText = U.Muted(picker, "", 12, y)
        U.Button(picker, "<", PICK_COLS * 40 - 76, y + 4, 40, function() picker.page = picker.page - 1; picker:Render() end)
        U.Button(picker, ">", PICK_COLS * 40 - 30, y + 4, 40, function() picker.page = picker.page + 1; picker:Render() end)
        picker.preview = U.IconButton(picker, 32, false); picker.preview:SetPoint("TOPLEFT", 12, y - 28)
        picker.path = U.Input(picker, 52, y - 32, PICK_COLS * 40 - 150)
        U.Button(picker, "Use icon", PICK_COLS * 40 - 86, y - 32, 96, function()
            local value = IC.Trim(picker.path:GetText()); picker:Hide()
            if value ~= "" and picker.done then picker.done(tonumber(value) or value) end
        end, "accent")
        U.Muted(picker, "Click an icon, or paste a texture path such as Interface\\Icons\\INV_Misc_Book_09.", 12, y - 62, PICK_COLS * 40)
        table.insert(UISpecialFrames, "InCharacterIconPicker")
    end
    if not picker.allIcons then
        picker.allIcons, picker.names, picker.groups = {}, {}, {}
        for _, icon in ipairs(IC.Icons) do picker.allIcons[#picker.allIcons + 1] = icon end
        for _, name in ipairs({ "GetMacroIcons", "GetMacroItemIcons" }) do
            local fn = _G[name]
            if type(fn) == "function" then pcall(fn, picker.allIcons) end
        end
        local seen = {}; for _, icon in ipairs(picker.allIcons) do seen[icon] = true end
        for _, choice in ipairs(IC.IconChoices) do
            if not seen[choice.path] then picker.allIcons[#picker.allIcons + 1] = choice.path; seen[choice.path] = true end
            local name = choice.label .. " · " .. choice.search
            picker.names[choice.path] = picker.names[choice.path] and (picker.names[choice.path] .. "; " .. name) or name
            picker.groups[choice.path] = picker.groups[choice.path] or {}; picker.groups[choice.path][choice.category] = true
        end
    end
    picker.done = done; picker.path:SetText(iconText(current)); picker.preview:SetIcon(current)
    picker.search:SetText(""); picker.category:SetValue("All"); picker:Filter(); picker:Show(); picker:Raise()
end

-- Home --------------------------------------------------------------------------------------------
local function card(page, x, y, icon, title, text)
    local frame = U.Panel(page, (PAGE_W - 12) / 2, 178, C.raised); frame:SetPoint("TOPLEFT", x, y)
    local art = U.IconButton(frame, 40, true); art:SetPoint("TOPLEFT", 14, -14); art:SetIcon(icon); art:EnableMouse(false)
    U.Heading(frame, title, 66, -16, frame:GetWidth() - 80)
    U.Muted(frame, text, 66, -40, frame:GetWidth() - 80)
    frame.state = U.Label(frame, "", 14, -150, frame:GetWidth() - 28, "GameFontHighlightSmall")
    return frame
end
local function categoryBars(create)
    local bars = IC.Layout().bars
    for i = #bars, 1, -1 do if bars[i].auto then table.remove(bars, i) end end
    if create then
        for n, id in ipairs(IC.Emotes.categories) do
            local bar = IC.Defaults.Bar(#bars + 1)
            bar.name, bar.source, bar.auto, bar.columns, bar.size = IC.Emotes.CategoryInfo[id].label, id, true, 8, 32
            bar.x, bar.y = 300, 240 - (n - 1) * 92
            bars[#bars + 1] = bar
        end
    end
    changed()
end
local function hasCategoryBars() for _, bar in ipairs(IC.Layout().bars) do if bar.auto then return true end end end
local function favoritesBar()
    for _, bar in ipairs(IC.Layout().bars) do if bar.source == "favorites" or bar.source == "favoriteEmotes" then return bar end end
end
local function catalogBar()
    for _, bar in ipairs(IC.Layout().bars) do if bar.catalog then return bar end end
end
function E.RefreshHome()
    local p = E.pages.Home
    local launcher = IC.Layout().launcher
    p.launcherToggle:SetText(launcher.shown and "Hide the button" or "Show the button")
    p.launcherClick:SetValue(launcher.click)
    p.launcher.state:SetText(launcher.shown and "|cff66dd66On|r - shift-drag it anywhere." or "|cff999999Off|r")
    p.wheelKey.Refresh(); p.wheelMode:SetValue(IC.Profile().quick.style)
    local fav = favoritesBar()
    p.favToggle:SetText(fav and not fav.hidden and "Hide favorites bar" or "Show favorites bar")
    p.fav.state:SetText(fav and not fav.hidden and ("|cff66dd66On|r - " .. #IC.Presentation.BarActions(fav) .. " visible pins.") or "|cff999999Off|r")
    local rp = catalogBar()
    p.rpToggle:SetText(rp and not rp.hidden and "Hide Roleplay bar" or "Show Roleplay bar")
    p.rp.state:SetText(rp and not rp.hidden and "|cff66dd66On|r - stays on screen between clicks." or "|cff999999Off|r")
end
local function createHome(p)
    U.Heading(p, "Your actions, one press away", 0, 0)
    U.Muted(p, "Start small. Pin what you use, keep useful emotes, and write any named pools you want.", 0, -22, PAGE_W)
    local half = (PAGE_W - 12) / 2 + 12
    p.launcher = card(p, 0, -48, IC.AddonIcon, "Launcher button",
        "A small show / hide button for the Roleplay bar. Your actions stay on screen; opening a menu is optional.")
    p.launcherToggle = U.Button(p.launcher, "", 66, -104, 150, function()
        local launcher = IC.Layout().launcher; launcher.shown = not launcher.shown; changed(); E.RefreshHome()
    end, "accent")
    p.launcherClick = U.Dropdown(p.launcher, 224, -104, 150, {
        { value = "quick", label = "Show / hide RP bar" }, { value = "menu", label = "Dropdown menu" }, { value = "wheel", label = "Quick access (old key)" },
    }, function(value) IC.Layout().launcher.click = value; E.RefreshHome() end)
    p.wheel = card(p, half, -48, "Interface\\Icons\\Spell_Holy_PowerInfusion", "Show / hide with a key",
        "Toggle the persistent RP bar. No typing is captured and no action is sent just by opening it. Other styles are optional.")
    p.wheelKey = U.KeyCapture(p.wheel, 66, -100, 200, "INCHARACTER_WHEEL", "Quick key", function() E.RefreshHome() end)
    p.wheelMode = U.Dropdown(p.wheel, 66, -128, 200, {
        { value = "bars", label = "Persistent RP bar" }, { value = "panel", label = "Optional popup panel" }, { value = "ring", label = "Legacy circle" },
    }, function(value) IC.Profile().quick.style = value end)
    U.Button(p.wheel, "Try it", 274, -128, 100, function() E.frame:Hide(); IC.QuickActions.Toggle() end)
    p.fav = card(p, 0, -238, "Interface\\Icons\\Spell_Holy_PowerInfusion", "Pinned emote bar",
        "Your familiar emote hotbar. New installs keep pinned emotes here, separate from RP. Its source can include all favorites if you prefer.")
    p.favToggle = U.Button(p.fav, "", 66, -104, 170, function()
        local bar = favoritesBar()
        if not bar then bar = IC.Defaults.Bar(#IC.Layout().bars + 1); bar.name, bar.source = "Emotes", "favoriteEmotes"; table.insert(IC.Layout().bars, bar)
        else bar.hidden = not bar.hidden end
        changed(); E.RefreshHome()
    end, "accent")
    p.rp = card(p, half, -238, "Interface\\Icons\\INV_Misc_Book_09", "Roleplay action bar",
        "Labeled buttons for any named pools. Click to play; right-click for a bar of specific lines. Visible tabs switch your preset sets.")
    p.rpToggle = U.Button(p.rp, "", 66, -104, 190, function() IC.Bars.ToggleCatalog(); E.RefreshHome() end, "accent")
    U.Button(p.rp, "Edit", 264, -104, 100, function()
        local _, index = IC.Bars.EnsureCatalog(); E.Open("Layouts", index)
    end)
    local legend = U.Panel(p, PAGE_W, 112, C.panel); legend:SetPoint("TOPLEFT", 0, -428)
    U.Label(legend, "Keep everyday use small", 12, -10, nil, "GameFontNormal")
    U.Muted(legend, "The emote list starts trimmed. All commands remain available in the editor; nothing is deleted.", 12, -34, PAGE_W - 24)
    U.Button(legend, "Check emotes one by one", 12, -68, 240, function() IC.EmoteReview.Open() end)
    U.Muted(legend, "Sound badges show your own character's checks. Nearby sound needs another player to confirm it.", 266, -72, PAGE_W - 282)
end

-- Emote library -----------------------------------------------------------------------------------
local TILE_W, TILE_H = 184, 42
local GRID_X = 160
local GRID_W = TILE_W * 2 + 4 + 22
local function emoteSource()
    local category = E.emoteCategory
    local profile, result = IC.Profile(), {}
    local list
    if category == "Favorites" then list = {}
        for _, id in ipairs(profile.favorites) do
            local action = IC.Emotes.byID[id]; if action then list[#list + 1] = action end
        end
    elseif category == "all" or category == "essentials" then list = IC.Emotes.list
    else list = IC.Emotes.byCategory[category] or {} end
    for _, action in ipairs(list) do
        action = IC.Actions.Resolve(action.id)
        local visible = category == "all" and (not profile.hideUnverified or action.verified) and IC.Emotes.Matches(action, profile.emoteFilter)
            or (category ~= "all" and IC.Emotes.Visible(action, profile))
        if visible and IC.Emotes.Search(action, E.search) then
            result[#result + 1] = action
        end
    end
    return result
end
local function tile(p, i)
    local t = p.tiles[i]
    if t then return t end
    t = CreateFrame("Button", nil, p.grid.content, "BackdropTemplate")
    t:SetSize(TILE_W, TILE_H); U.Backdrop(t, C.raised)
    t.icon = t:CreateTexture(nil, "ARTWORK"); t.icon:SetSize(32, 32); t.icon:SetPoint("LEFT", 5, 0); t.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    t.name = t:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); t.name:SetPoint("TOPLEFT", 44, -6); t.name:SetPoint("RIGHT", -6, 0)
    t.name:SetJustifyH("LEFT"); t.name:SetWordWrap(false)
    t.sub = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); t.sub:SetPoint("TOPLEFT", 44, -23)
    t.star = t:CreateFontString(nil, "OVERLAY", "GameFontNormal"); t.star:SetPoint("TOPRIGHT", -6, -5)
    t:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    t:SetScript("OnClick", function(self, mouse)
        if mouse == "RightButton" then IC.Actions.Favorite(self.action.id); E.RefreshEmotes(); return end
        E.emote = self.action; E.RefreshEmotes()
    end)
    t:SetScript("OnDoubleClick", function(self, mouse) if mouse == "LeftButton" then IC.Actions.Dispatch(self.action) end end)
    t:SetScript("OnEnter", function(self) self:SetBackdropColor(unpack(C.hover)) end)
    t:SetScript("OnLeave", function(self) self:SetBackdropColor(unpack(E.emote and self.action.id == E.emote.id and C.accentDim or C.raised)) end)
    p.tiles[i] = t
    return t
end
function E.RefreshEmotes()
    local p = E.pages.Emotes
    local profile = IC.Profile()
    for _, button in ipairs(p.categories) do
        button:SetSelected(button.id == E.emoteCategory)
    end
    for _, chip in ipairs(p.chips) do chip:SetSelected(chip.value == profile.emoteFilter) end
    p.hide:SetChecked(profile.hideUnverified)
    p.scope:SetValue(profile.emoteScope)
    local actions = emoteSource()
    p.shown = actions
    for _, t in ipairs(p.tiles) do t:Hide() end
    for i, action in ipairs(actions) do
        local t = tile(p, i)
        t.action = action
        t:ClearAllPoints(); t:SetPoint("TOPLEFT", ((i - 1) % 2) * (TILE_W + 4), -math.floor((i - 1) / 2) * (TILE_H + 4))
        U.SetIcon(t.icon, action.icon, IC.Icons[1]); t.icon:SetDesaturated(not action.verified)
        t.name:SetText(action.name)
        t.sub:SetText(IC.Emotes.Badge(action) .. "  |cff888888" .. action.label .. "|r")
        t.star:SetText(IC.Actions.IsFavorite(action.id) and "*" or "")
        t:SetBackdropColor(unpack(E.emote and action.id == E.emote.id and C.accentDim or C.raised))
        t:Show()
    end
    p.grid:SetContentHeight(math.ceil(#actions / 2) * (TILE_H + 4))
    local info = IC.Emotes.CategoryInfo[E.emoteCategory]
    p.title:SetText(info.label .. "  |cff888888(" .. #actions .. ")|r")
    p.hint:SetText(info.hint)
    p.empty:SetShown(#actions == 0)
    E.RefreshEmoteDetail()
end
function E.RefreshEmoteDetail()
    local p, action = E.pages.Emotes, E.emote
    p.detail:SetShown(action ~= nil); p.noDetail:SetShown(action == nil)
    if not action then return end
    action = IC.Actions.Resolve(action.id); E.emote = action
    p.dIcon:SetIcon(action.icon, IC.Icons[1])
    p.dName:SetText(action.name)
    local badge, info = IC.Emotes.Badge(action)
    p.dBadge:SetText(badge)
    p.dHelp:SetText(info.help)
    local aliases = {}
    for _, alias in ipairs(action.aliases) do aliases[#aliases + 1] = "/" .. alias end
    p.dCommand:SetText("Commands: " .. table.concat(aliases, "  "))
    p.dClient:SetText(action.verified and "|cff66dd66This client knows this emote.|r" or "|cffff7755This client does not recognize it, so it is disabled.|r")
    p.dTry:SetEnabled(action.verified)
    p.dPin:SetText(IC.Actions.IsFavorite(action.id) and "Unpin favorite" or "Pin to favorites")
    local review = IC.Curation.Record(action.id)
    p.dKeep:SetText((review.choice == "hide" or review.choice == "duplicate" or review.choice == "text") and "Keep in everyday use" or "Hide from everyday use")
    p.dReview:SetEnabled(action.verified)
    local override = IC.Profile().emoteOverrides[action.id] or {}
    p.dLabel:SetText(override.label or "")
end
local function createEmotes(p)
    p.categories, p.tiles, p.chips = {}, {}, {}
    local ids = { "essentials", "Favorites" }
    for _, id in ipairs(IC.Emotes.categories) do ids[#ids + 1] = id end
    ids[#ids + 1] = "all"
    for n, id in ipairs(ids) do
        local info = IC.Emotes.CategoryInfo[id]
        local button = U.Button(p, info.label, 0, -(n - 1) * 30, 150, function() E.emoteCategory = id; E.RefreshEmotes() end)
        button.label:SetJustifyH("LEFT"); button.id = id
        p.categories[n] = button
    end
    U.Muted(p, "Right-click a tile to pin it. Double-click to try it.", 0, -#ids * 30 - 8, 150)
    p.scope = U.Dropdown(p, 0, -#ids * 30 - 52, 150, {
        { value = "essentials", label = "Quick lists: trimmed" }, { value = "all", label = "Quick lists: all" },
    }, function(value) IC.Profile().emoteScope = value; changed(); E.RefreshEmotes() end)
    p.review = U.Button(p, "Check one by one", 0, -#ids * 30 - 88, 150, function() IC.EmoteReview.Open() end)
    p.search = U.Input(p, GRID_X, 0, 200)
    p.search:SetScript("OnTextChanged", function(self) E.search = self:GetText(); E.RefreshEmotes() end)
    U.Muted(p, "Search", GRID_X + 210, -6)
    p.hide = U.Check(p, "Hide unknown", GRID_X + 262, -2, function(value) IC.Profile().hideUnverified = value; changed(); E.RefreshEmotes() end)
    p.hide.caption:SetWidth(120)
    local x = GRID_X
    for _, filter in ipairs(IC.Emotes.Filters) do
        local width = #filter.label * 7 + 18
        local chip = U.Chip(p, filter.label, x, -30, width, function()
            IC.Profile().emoteFilter = filter.value; changed(); E.RefreshEmotes()
        end)
        chip.value = filter.value; p.chips[#p.chips + 1] = chip; x = x + width + 4
    end
    p.title = U.Label(p, "", GRID_X, -60, GRID_W, "GameFontNormal")
    p.hint = U.Muted(p, "", GRID_X, -76, GRID_W)
    p.grid = U.Scroll(p, GRID_X, -100, GRID_W, PAGE_H - 110)
    p.empty = U.Muted(p.grid, "Nothing matches. Try another filter or category.", 12, -12, GRID_W - 24)
    -- Detail panel
    local DX = GRID_X + GRID_W + 10
    local DW = PAGE_W - DX
    p.noDetail = U.Muted(p, "Select an emote to see what it does.", DX, -100, DW)
    p.detail = U.Panel(p, DW, PAGE_H - 60, C.raised); p.detail:SetPoint("TOPLEFT", DX, -60)
    local d = p.detail
    p.dIcon = U.IconButton(d, 48, false); p.dIcon:SetPoint("TOPLEFT", 12, -12)
    p.dName = U.Heading(d, "", 70, -14, DW - 80)
    p.dBadge = U.Label(d, "", 70, -38, DW - 80)
    p.dHelp = U.Muted(d, "", 12, -72, DW - 24)
    p.dCommand = U.Muted(d, "", 12, -132, DW - 24)
    p.dClient = U.Label(d, "", 12, -166, DW - 24, "GameFontHighlightSmall")
    p.dTry = U.Button(d, "Try it now", 12, -194, DW - 24, function() if E.emote then IC.Actions.Dispatch(E.emote) end end, "accent")
    p.dPin = U.Button(d, "", 12, -224, DW - 24, function()
        if E.emote then IC.Actions.Favorite(E.emote.id); E.RefreshEmotes() end
    end)
    U.Label(d, "Custom name on bars", 12, -264, DW - 24, "GameFontHighlightSmall")
    p.dLabel = U.Input(d, 12, -282, DW - 24)
    U.Button(d, "Change icon", 12, -312, (DW - 28) / 2, function()
        if not E.emote then return end
        local id = E.emote.id
        E.PickIcon(E.emote.icon, function(icon)
            local overrides = IC.Profile().emoteOverrides
            overrides[id] = overrides[id] or {}; overrides[id].icon = icon; changed(); E.RefreshEmotes()
        end)
    end)
    U.Button(d, "Save name", 16 + (DW - 28) / 2, -312, (DW - 28) / 2, function()
        if not E.emote then return end
        local overrides, label = IC.Profile().emoteOverrides, IC.Trim(p.dLabel:GetText())
        overrides[E.emote.id] = overrides[E.emote.id] or {}
        overrides[E.emote.id].label = label ~= "" and label or nil; changed(); E.RefreshEmotes(); status("Saved. The emote command itself is unchanged.")
    end)
    U.Button(d, "Reset look", 12, -342, DW - 24, function()
        if E.emote then IC.Profile().emoteOverrides[E.emote.id] = nil; changed(); E.RefreshEmotes() end
    end)
    p.dKeep = U.Button(d, "", 12, -380, DW - 24, function()
        local action = E.emote; if not action then return end
        local record, seen = IC.Curation.Record(action.id), IC.Curation.Observation(action.id)
        local hidden = record.choice == "hide" or record.choice == "duplicate" or record.choice == "text"
        IC.Curation.Save(action.id, hidden and "keep" or "hide", seen.sound or "unknown", seen.animation or "unknown", "", record.notes, record.iconReviewed)
        E.RefreshEmotes()
    end)
    p.dReview = U.Button(d, "Check sound / duplicates", 12, -414, DW - 24, function() if E.emote then IC.EmoteReview.Open(E.emote.id) end end)
end

-- Dialogue ----------------------------------------------------------------------------------------
local LIST_W, FORM_X = 200, 214
-- Unsaved edits survive switching pools, tabs or closing the window (until /reload).
function E.StoreDraft()
    if not E.formID or not E.formProfile or not E.pages.Dialogue then return end
    local p = E.pages.Dialogue
    local pool = E.formProfile.pools[E.formID]
    E.drafts[E.formProfile] = E.drafts[E.formProfile] or {}
    local draft = { name = p.name:GetText(), lines = p.lines:GetText(), mode = p.mode.value, channel = p.channel.value, icon = p.iconValue }
    local same = pool and draft.name == pool.name and draft.lines == table.concat(pool.lines, "\n") and draft.mode == pool.mode
        and draft.channel == pool.channel and draft.icon == pool.icon
    E.drafts[E.formProfile][E.formID] = (not same) and draft or nil
end
local function setFormIcon(icon) local p = E.pages.Dialogue; p.iconValue = icon; p.icon:SetIcon(icon, IC.Icons[1]) end
local function counter()
    local p = E.pages.Dialogue
    local lines, longest = splitLines(p.lines:GetText()), 0
    for _, line in ipairs(lines) do longest = math.max(longest, #IC.Actions.ChatText(line)) end
    p.count:SetText(#lines .. " lines   |   longest " .. longest .. " / 255 bytes" .. (longest > 255 and "  |cffff7755(too long to send)|r" or ""))
end
function E.SelectPool(id)
    E.StoreDraft()
    local p = E.pages.Dialogue
    local profile = IC.Profile()
    local pool = id and profile.pools[id]
    E.poolID, E.formProfile, E.formID = pool and id or nil, profile, pool and id or nil
    local draft = pool and E.drafts[profile] and E.drafts[profile][id]
    p.form:SetShown(pool ~= nil); p.noPool:SetShown(pool == nil)
    if not pool then return end
    p.name:SetText(draft and draft.name or pool.name)
    p.lines:SetText(draft and draft.lines or table.concat(pool.lines, "\n"))
    p.mode:SetValue(draft and draft.mode or pool.mode); p.channel:SetValue(draft and draft.channel or pool.channel)
    setFormIcon(draft and draft.icon or pool.icon)
    p.pin:SetText(IC.Actions.IsFavorite("pool:" .. id) and "Unpin" or "Pin")
    p.delete.confirming = nil; p.delete:SetText("Delete pool")
    local source = pool.provenance and IC.Library.packs[pool.provenance.pack]
    p.info:SetText("ID: " .. pool.id .. (source and ("   |   copied from " .. source.title) or "") .. (draft and "   |   |cffffd100unsaved changes|r" or ""))
    counter()
    E.RefreshPoolList()
end
function E.RefreshPoolList()
    local p, profile = E.pages.Dialogue, IC.Profile()
    for _, row in ipairs(p.rows) do row:Hide() end
    for i, id in ipairs(profile.poolOrder) do
        local row = p.rows[i]
        if not row then
            row = U.Button(p.list.content, "", 0, 0, LIST_W - 22, function(self) E.SelectPool(self.poolID) end)
            row.label:SetJustifyH("LEFT"); row.label:SetPoint("LEFT", 28, 0)
            row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(20, 20); row.icon:SetPoint("LEFT", 4, 0)
            p.rows[i] = row
        end
        local pool = profile.pools[id]
        row.poolID = id; row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -(i - 1) * 28)
        row:SetText(pool.name .. "  |cff888888" .. #pool.lines .. "|r"); U.SetIcon(row.icon, pool.icon, IC.Icons[1])
        row:SetSelected(id == E.poolID); row:Show()
    end
    p.list:SetContentHeight(#profile.poolOrder * 28)
end
function E.RefreshDialogue()
    local profile = IC.Profile()
    local id = E.poolID and profile.pools[E.poolID] and E.poolID or profile.poolOrder[1]
    E.formID = nil
    E.SelectPool(id); E.RefreshPoolList()
end
local function createDialogue(p)
    p.rows = {}
    U.Label(p, "Your dialogue pools", 0, 0, LIST_W, "GameFontNormal")
    p.list = U.Scroll(p, 0, -20, LIST_W, 300)
    U.Button(p, "+ New pool", 0, -326, LIST_W, function()
        E.StoreDraft()
        local pool = IC.Dialogue.Create("New pool"); E.formID = nil; E.SelectPool(pool.id)
        status("New empty pool. Give it a name, write one line per row, then Save.")
    end, "accent")
    U.Button(p, "Move up", 0, -356, (LIST_W - 4) / 2, function() if E.poolID then IC.Dialogue.Move(E.poolID, -1); E.RefreshPoolList() end end)
    U.Button(p, "Move down", (LIST_W + 4) / 2, -356, (LIST_W - 4) / 2, function() if E.poolID then IC.Dialogue.Move(E.poolID, 1); E.RefreshPoolList() end end)
    p.noPool = U.Muted(p, "Create a pool, or copy a preset below.", FORM_X, -24, 300)
    local FW = PAGE_W - FORM_X
    p.form = CreateFrame("Frame", nil, p); p.form:SetPoint("TOPLEFT", FORM_X, 0); p.form:SetSize(FW, 400)
    local f = p.form
    p.icon = U.IconButton(f, 40, false); p.icon:SetPoint("TOPLEFT", 0, -2)
    p.icon:SetScript("OnClick", function() E.PickIcon(p.iconValue, setFormIcon) end)
    p.icon:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Click to choose an icon"); GameTooltip:Show() end)
    p.icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    U.Muted(f, "Name", 50, 0); p.name = U.Input(f, 50, -14, FW - 50)
    U.Muted(f, "Sent as", 0, -48)
    p.channel = U.Dropdown(f, 0, -62, 150, {
        { value = "SAY", label = "Say (nearby)" }, { value = "YELL", label = "Yell (wide area)" }, { value = "EMOTE", label = "Emote text (/e)" },
    })
    U.Muted(f, "Which line is picked", 160, -48)
    p.mode = U.Dropdown(f, 160, -62, 210, {
        { value = "shuffle", label = "Shuffle: each line once" }, { value = "random", label = "Random: repeats possible" },
        { value = "sequential", label = "In order, then loop" },
    })
    U.Muted(f, "One line per row. Each click sends exactly one line.", 0, -96, FW)
    p.lines = U.TextArea(f, 0, -112, FW, 180)
    p.lines.changed = counter
    p.count = U.Muted(f, "", 0, -298, FW)
    local bw = (FW - 16) / 5
    U.Button(f, "Save", 0, -318, bw, function()
        local pool = E.poolID and IC.Profile().pools[E.poolID]
        if not pool then return end
        local ok, problem = IC.Dialogue.Save(pool, p.name:GetText(), p.channel.value, p.mode.value, p.iconValue or IC.Icons[1], splitLines(p.lines:GetText()))
        if ok then
            if E.drafts[IC.Profile()] then E.drafts[IC.Profile()][E.poolID] = nil end
            E.formID = nil; E.SelectPool(E.poolID); status(problem or "Saved.")
        else status(problem) end
    end, "accent")
    U.Button(f, "Preview", bw + 4, -318, bw, function()
        local line = IC.Dialogue.Preview({ id = E.poolID or "draft", mode = p.mode.value, lines = splitLines(p.lines:GetText()) })
        E.ShowPreview(line or "This pool is empty.", "Pool preview — nothing sent")
    end)
    p.pin = U.Button(f, "", (bw + 4) * 2, -318, bw, function()
        if E.poolID then IC.Actions.Favorite("pool:" .. E.poolID); E.SelectPool(E.poolID) end
    end)
    U.Button(f, "Discard edits", (bw + 4) * 3, -318, bw, function()
        if E.drafts[IC.Profile()] and E.poolID then E.drafts[IC.Profile()][E.poolID] = nil end
        E.formID = nil; E.SelectPool(E.poolID); status("Edits discarded.")
    end)
    p.delete = U.Button(f, "Delete pool", (bw + 4) * 4, -318, bw, function(self)
        if not E.poolID then return end
        U.Confirm(self, "Delete pool", function()
            local drafts = E.drafts[IC.Profile()]; if drafts then drafts[E.poolID] = nil end
            E.formID = nil; IC.Dialogue.Delete(E.poolID); E.poolID = nil; E.RefreshDialogue(); status("Pool deleted.")
        end)
    end)
    p.info = U.Muted(f, "", 0, -350, FW)
    p.info:SetWordWrap(false)
    IC.DialogueUI.Attach(p, f, FW)
    -- Library
    local lib = U.Panel(p, PAGE_W, 140, C.panel); lib:SetPoint("TOPLEFT", 0, -396)
    U.Label(lib, "Preset library", 12, -10, nil, "GameFontNormal")
    U.Muted(lib, "Copies editable pools into your list. Never sends anything by itself.", 120, -12, PAGE_W - 140)
    local packs = {}
    for _, id in ipairs(IC.Library.order) do packs[#packs + 1] = { value = id, label = IC.Library.packs[id].title } end
    p.packNote = U.Muted(lib, "", 12, -70, PAGE_W - 24)
    p.pack = U.Dropdown(lib, 12, -34, 280, packs, function(value)
        local pack = IC.Library.packs[value]
        p.packNote:SetText(pack.contentNote .. "\n|cff888888Source: " .. pack.source .. "|r")
    end)
    p.pack:Choose(IC.Library.order[1])
    local function install(shortcuts)
        E.StoreDraft()
        local _, message, first = IC.Library.Install(p.pack.value, shortcuts)
        E.formID = nil; if first then E.SelectPool(first) end
        status(message .. (shortcuts and " /ic greet, /ic quote and /ic bye now use these copies." or ""))
    end
    U.Button(lib, "Copy preset", 300, -34, 120, function() install(false) end)
    U.Button(lib, "Copy + use for /ic greet, quote, bye", 426, -34, PAGE_W - 438, function() install(true) end, "accent")
end

-- Layouts -----------------------------------------------------------------------------------------
local function currentBar() return IC.Layout().bars[E.barIndex] end
local function barSources()
    local sources = { { value = "favoriteEmotes", label = "Pinned emotes only" }, { value = "favorites", label = "All favorites" } }
    for _, id in ipairs(IC.Emotes.categories) do sources[#sources + 1] = { value = id, label = "Emotes: " .. IC.Emotes.CategoryInfo[id].label } end
    sources[#sources + 1] = { value = "pools", label = "All dialogue pools" }
    for _, id in ipairs(IC.Profile().poolOrder) do sources[#sources + 1] = { value = "pool:" .. id, label = "Pool: " .. IC.Profile().pools[id].name } end
    for _, id in ipairs(IC.Profile().poolOrder) do
        sources[#sources + 1] = { value = "lines:" .. id, label = "Individual messages: " .. IC.Profile().pools[id].name }
        sources[#sources + 1] = { value = "play:random:" .. id, label = "Random: " .. IC.Profile().pools[id].name }
    end
    local config = currentBar()
    if config and config.source:match("^line:") then
        local action = IC.Actions.Resolve(config.source)
        sources[#sources + 1] = { value = config.source, label = action and ("Message: " .. action.label) or "Message removed — choose another source" }
    end
    return sources
end
function E.RefreshLayouts()
    local p = E.pages.Layouts
    local launcher, wheel = IC.Layout().launcher, IC.Profile().wheel
    p.lShown:SetChecked(launcher.shown); p.lClick:SetValue(launcher.click); p.lSize:Set(launcher.size)
    p.wMode:SetValue(wheel.mode); p.wRadius:Set(wheel.radius); p.wKey.Refresh(); p.mKey.Refresh()
    p.wButtonSize:Set(wheel.buttonSize); p.wPageSize:Set(wheel.pageSize); p.wDeadZone:Set(wheel.deadZone)
    p.mPageSize:Set(IC.Profile().menu.pageSize)
    p.qStyle:SetValue(IC.Profile().quick.style); p.qColumns:Set(IC.Profile().quick.columns)
    local ring = IC.Profile().quick.style == "ring"
    for _, widget in ipairs({ p.wRadius, p.wButtonSize, p.wPageSize, p.wDeadZone }) do widget:SetShown(ring); widget.caption:SetShown(ring) end
    local panel = IC.Profile().quick.style == "panel"
    p.wMode:SetShown(ring); p.qColumns:SetShown(panel); p.qColumns.caption:SetShown(panel)
    local bars = IC.Layout().bars
    E.barIndex = math.max(1, math.min(#bars, E.barIndex))
    local options = {}
    for i, bar in ipairs(bars) do options[i] = { value = i, label = i .. ". " .. bar.name } end
    p.which:SetOptions(options); p.which:SetValue(#bars > 0 and E.barIndex or nil)
    local bar = currentBar()
    p.barForm:SetShown(bar ~= nil); p.noBars:SetShown(bar == nil)
    if not bar then return end
    p.bName:SetText(bar.name); p.bSource:SetOptions(barSources()); p.bSource:SetValue(bar.source)
    p.bSize:Set(bar.size); p.bColumns:Set(bar.columns or 12)
    p.bRows:Set(bar.rows or 0); p.bLabels:SetChecked(bar.labels == true)
    p.bStyle:SetValue(bar.buttonStyle); p.bWidth:Set(bar.buttonWidth)
    p.bPlayback:SetValue(bar.poolMode); p.bCatalog:SetChecked(bar.catalog == true); p.bHideEmpty:SetChecked(bar.hideEmpty == true)
    p.bWidth:SetShown(bar.buttonStyle == "text"); p.bWidth.caption:SetShown(bar.buttonStyle == "text")
    p.bSummary:SetText(#IC.Presentation.BarActions(bar) .. " shown / " .. #IC.Presentation.BarActions(bar, true) .. " source entries")
    p.bOrientation:SetValue(bar.vertical and "vertical" or "horizontal")
    for key, check in pairs(p.bChecks) do check:SetChecked(bar[key] == true) end
    p.bDelete.confirming = nil; p.bDelete:SetText("Delete bar")
end
local function section(parent, title, x, y, width, height)
    local frame = U.Panel(parent, width, height, C.raised); frame:SetPoint("TOPLEFT", x, y)
    U.Label(frame, title, 12, -10, nil, "GameFontNormal")
    return frame
end
local function createLayouts(p)
    p.layoutScroll = U.Scroll(p, 0, 0, PAGE_W, PAGE_H)
    p.layoutScroll:SetContentHeight(950)
    local canvas = p.layoutScroll.content
    local half = (PAGE_W - 34) / 2
    local s = section(canvas, "Launcher button & dropdown menu", 0, 0, half, 270)
    p.lShown = U.Check(s, "Show the launcher button", 12, -32, function(value) IC.Layout().launcher.shown = value; changed() end)
    p.lClick = U.Dropdown(s, 12, -62, half - 24, {
        { value = "quick", label = "Toggle quick access (RP bar by default)" }, { value = "menu", label = "Left-click opens the dropdown menu" }, { value = "wheel", label = "Quick access (old wheel setting)" },
    }, function(value) IC.Layout().launcher.click = value end)
    p.lSize = U.Slider(s, "Size", 12, -96, half - 120, 28, 64, 2, function(value) IC.Layout().launcher.size = value; changed() end)
    U.Button(s, "Reset", half - 100, -112, 88, function()
        local launcher = IC.Layout().launcher; local default = IC.Defaults.Launcher()
        launcher.x, launcher.y = default.x, default.y; changed()
    end)
    p.mPageSize = U.Slider(s, "Menu rows per page", 12, -150, half - 24, 6, 20, 1, function(value) IC.Profile().menu.pageSize = value; changed() end)
    p.editMenu = U.Button(s, "Edit menu categories / items", 12, -204, half - 24, function() IC.LayoutUI.Open("menu") end)
    s = section(canvas, "Quick actions", half + 10, 0, half, 310)
    p.wKey = U.KeyCapture(s, 12, -32, (half - 30) / 2, "INCHARACTER_WHEEL", "Quick")
    p.mKey = U.KeyCapture(s, 18 + (half - 30) / 2, -32, (half - 30) / 2, "INCHARACTER_MENU", "Menu")
    p.qStyle = U.Dropdown(s, 12, -62, half - 24, {
        { value = "bars", label = "Persistent Roleplay bar (default)" }, { value = "panel", label = "Optional popup panel" }, { value = "ring", label = "Legacy circle" },
    }, function(value) IC.Profile().quick.style = value; E.RefreshLayouts() end)
    p.wMode = U.Dropdown(s, 12, -264, half - 24, {
        { value = "click", label = "Press key, then click an action" }, { value = "hold", label = "Hold / release (experimental)" },
    }, function(value) IC.Profile().wheel.mode = value end)
    p.wRadius = U.Slider(s, "Ring radius", 12, -96, half - 120, 130, 260, 5, function(value) IC.Profile().wheel.radius = value end)
    p.qColumns = U.Slider(s, "Panel columns", 12, -96, half - 120, 2, 4, 1, function(value) IC.Profile().quick.columns = value end)
    U.Button(s, "Try it", half - 100, -112, 88, function() E.frame:Hide(); IC.QuickActions.Toggle() end)
    p.wButtonSize = U.Slider(s, "Icon size", 12, -150, (half - 36) / 2, 28, 64, 2, function(value) IC.Profile().wheel.buttonSize = value end)
    p.wPageSize = U.Slider(s, "Items per ring", half / 2 + 6, -150, (half - 36) / 2, 4, 12, 1, function(value) IC.Profile().wheel.pageSize = value end)
    p.wDeadZone = U.Slider(s, "Neutral centre", 12, -206, (half - 36) / 2, 30, 100, 2, function(value) IC.Profile().wheel.deadZone = value end)
    p.editWheel = U.Button(s, "Edit quick items", half / 2 + 6, -222, (half - 36) / 2, function() IC.LayoutUI.Open("wheel") end)
    s = section(canvas, "Action bars", 0, -322, PAGE_W - 24, 600)
    p.which = U.Dropdown(s, 12, -32, 260, {}, function(value) E.barIndex = value; E.RefreshLayouts() end)
    U.Button(s, "+ Add bar", 280, -32, 110, function()
        local bars = IC.Layout().bars; bars[#bars + 1] = IC.Defaults.Bar(#bars + 1); E.barIndex = #bars; changed(); E.RefreshLayouts()
    end, "accent")
    U.Button(s, "Bars per category", 396, -32, 150, function() categoryBars(not hasCategoryBars()); E.RefreshLayouts() end)
    p.noBars = U.Muted(s, "No bars yet. Add one, or create one bar per category.", 12, -70, PAGE_W - 24)
    p.barForm = CreateFrame("Frame", nil, s); p.barForm:SetPoint("TOPLEFT", 0, -64); p.barForm:SetSize(PAGE_W - 24, 526)
    local b = p.barForm
    U.Muted(b, "Name", 12, 0); p.bName = U.Input(b, 12, -14, 260)
    U.Button(b, "Rename", 280, -14, 110, function()
        local bar = currentBar(); if bar then bar.name = IC.Trim(p.bName:GetText()); changed(); E.RefreshLayouts() end
    end)
    p.bDelete = U.Button(b, "Delete bar", 396, -14, 150, function(self)
        if currentBar() then U.Confirm(self, "Delete bar", function() table.remove(IC.Layout().bars, E.barIndex); changed(); E.RefreshLayouts() end) end
    end)
    U.Muted(b, "Shows", 12, -46)
    p.bSource = U.Dropdown(b, 12, -60, 378, {}, function(value)
        local bar = currentBar(); if not bar then return end
        bar.source, bar.page = value, 1
        if value ~= "pools" then bar.catalog, bar.catalogGroup = false, "all" end
        changed(); E.RefreshLayouts()
    end)
    p.bOrientation = U.Dropdown(b, 396, -60, 150, {
        { value = "horizontal", label = "Fill rows first" }, { value = "vertical", label = "Fill columns first" },
    }, function(value) local bar = currentBar(); if bar then bar.vertical = value == "vertical"; changed() end end)
    p.bSize = U.Slider(b, "Button size", 12, -96, 250, 24, 64, 2, function(value) local bar = currentBar(); if bar then bar.size = value; changed() end end)
    p.bColumns = U.Slider(b, "Columns", 296, -96, 250, 1, 12, 1, function(value) local bar = currentBar(); if bar then bar.columns = value; bar.page = 1; changed() end end)
    p.bRows = U.Slider(b, "Rows (0 = automatic)", 12, -144, 250, 0, 12, 1, function(value) local bar = currentBar(); if bar then bar.rows = value; bar.page = 1; changed() end end)
    p.bLabels = U.Check(b, "Show action names", 296, -150, function(value) local bar = currentBar(); if bar then bar.labels = value; changed() end end)
    p.bChecks = {}
    for n, definition in ipairs({ { "collapsed", "Collapsed" }, { "locked", "Lock position" }, { "hidden", "Hidden" } }) do
        local key = definition[1]
        p.bChecks[key] = U.Check(b, definition[2], 12 + (n - 1) * 210, -194, function(value)
            local bar = currentBar(); if bar then bar[key] = value; changed() end
        end)
    end
    U.Button(b, "Reset position", 12, -234, 140, function()
        local bar = currentBar(); if bar then local default = bar.catalog and IC.Defaults.CatalogBar(E.barIndex) or IC.Defaults.Bar(E.barIndex); bar.x, bar.y = default.x, default.y; changed() end
    end)
    U.Muted(b, "Drag the title to move; click to collapse. Right-click a button to edit this bar's items.", 160, -238, PAGE_W - 210)
    p.editBar = U.Button(b, "Edit shown / hidden items", 12, -282, 230, function() if currentBar() then IC.LayoutUI.Open("bar", E.barIndex) end end, "accent")
    p.bSummary = U.Muted(b, "", 260, -288, PAGE_W - 300)
    U.Muted(b, "Button appearance", 12, -314); U.Muted(b, "Pool playback on this bar", 296, -314)
    p.bStyle = U.Dropdown(b, 12, -330, 250, {
        { value = "icons", label = "Icons with optional names" }, { value = "text", label = "Wide labeled buttons" },
    }, function(value) local bar = currentBar(); if bar then bar.buttonStyle = value; changed(); E.RefreshLayouts() end end)
    p.bPlayback = U.Dropdown(b, 296, -330, 250, {
        { value = "pool", label = "Each pool's saved mode" }, { value = "random", label = "Random" },
        { value = "shuffle", label = "Shuffle" }, { value = "sequential", label = "In order" },
    }, function(value) local bar = currentBar(); if bar then bar.poolMode = value; changed() end end)
    p.bWidth = U.Slider(b, "Labeled button width", 12, -376, 250, 100, 320, 4, function(value)
        local bar = currentBar(); if bar then bar.buttonWidth = value; changed() end
    end)
    p.bCatalog = U.Check(b, "Show preset / custom tabs", 296, -382, function(value)
        local bar = currentBar(); if not bar then return end
        bar.catalog, bar.catalogGroup, bar.page = value, "all", 1
        if value then bar.source, bar.buttonStyle = "pools", "text" end
        changed(); E.RefreshLayouts()
    end)
    p.bHideEmpty = U.Check(b, "Hide empty pools", 296, -416, function(value)
        local bar = currentBar(); if bar then bar.hideEmpty = value; bar.page = 1; changed() end
    end)
    U.Muted(b, "RP buttons: click to play once. Right-click a pool to put its exact lines on a second bar; Shift-right-click edits shown items. Both bars stay open after playing.", 12, -466, PAGE_W - 60)
end

-- Profiles ----------------------------------------------------------------------------------------
function E.RefreshProfiles()
    local p = E.pages.Profiles
    p.scope:SetValue(IC.Profiles.Character().scope); p.layoutScope:SetValue(IC.Profiles.Character().layoutScope)
end
local function createProfiles(p)
    local s = section(p, "Emotes, favorites and dialogue", 0, 0, PAGE_W, 130)
    p.scope = U.Dropdown(s, 12, -34, 320, {
        { value = "account", label = "Shared by all my characters" }, { value = "character", label = "Only this character" },
    }, function(value) IC.Profiles.SetScope(value); E.poolID = nil; status("Profile switched.") end)
    U.Muted(s, "A private copy is made from the shared profile the first time you choose Only this character. Switching back keeps both.", 12, -66, PAGE_W - 24)
    U.Button(s, "Copy shared profile to this character", 12, -96, 300, function(self)
        U.Confirm(self, "Copy shared", function() IC.Profiles.CopyAccount(); E.RefreshProfiles(); status("Shared profile copied to this character.") end)
    end)
    s = section(p, "Bar and button positions", 0, -140, PAGE_W, 90)
    p.layoutScope = U.Dropdown(s, 12, -34, 320, {
        { value = "character", label = "Separate for this character" }, { value = "account", label = "Shared by all my characters" },
    }, function(value) IC.Profiles.SetLayoutScope(value); status("Layout scope switched.") end)
    s = section(p, "Reset", 0, -240, PAGE_W, 110)
    U.Button(s, "Reset the active profile", 12, -34, 260, function(self)
        U.Confirm(self, "Reset profile", function() IC.Profiles.Reset(); E.poolID = nil; status("Active profile reset. Layouts were kept.") end)
    end)
    U.Button(s, "Reset /ic greet, quote, bye", 280, -34, 260, function()
        IC.Profile().shortcuts = {}; changed(); status("Shortcuts use your Greetings, Quotes and Farewells pools again.")
    end)
    U.Muted(s, "Saved in InCharacterDB (shared) and InCharacterCharDB (this character). Close WoW before backing up WTF/.../SavedVariables.", 12, -70, PAGE_W - 24)
end

-- Window ------------------------------------------------------------------------------------------
local creators = { Home = createHome, Emotes = createEmotes, Dialogue = createDialogue, Favorites = function(p) IC.DialogueUI.CreateFavorites(p) end, Layouts = createLayouts, Profiles = createProfiles }
local refreshers = { Home = "RefreshHome", Emotes = "RefreshEmotes", Dialogue = "RefreshDialogue", Favorites = "RefreshFavorites", Layouts = "RefreshLayouts", Profiles = "RefreshProfiles" }
function E.SelectTab(name)
    E.StoreDraft()
    if InCharacterDropdownList then InCharacterDropdownList:Hide() end
    if E.picker then E.picker:Hide() end
    if E.messages then E.messages:Hide() end
    if E.preview then E.preview:Hide() end
    if IC.LayoutUI and IC.LayoutUI.frame then IC.LayoutUI.frame:Hide() end
    if IC.EmoteReview and IC.EmoteReview.frame then IC.EmoteReview.frame:Hide() end
    E.tab = name
    for tab, page in pairs(E.pages) do page:SetShown(tab == name) end
    for _, button in ipairs(E.nav) do button:SetSelected(button.tab == name) end
    E[refreshers[name]]()
end
function E.Create()
    local frame = CreateFrame("Frame", "InCharacterEditor", UIParent, "BackdropTemplate"); E.frame = frame
    U.Backdrop(frame, C.bg, C.border)
    frame:SetSize(WIDTH, HEIGHT); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetToplevel(true)
    frame:SetClampedToScreen(true); frame:EnableMouse(true); frame:SetMovable(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScale(math.min(1, (UIParent:GetHeight() - 40) / HEIGHT, (UIParent:GetWidth() - 40) / WIDTH))
    local logo = U.IconButton(frame, 26, true); logo:SetPoint("TOPLEFT", 14, -10); logo:SetIcon(IC.AddonIcon); logo:EnableMouse(false)
    U.Heading(frame, "In Character", 50, -14)
    U.Muted(frame, "emotes and roleplay lines", 160, -18)
    U.Button(frame, "Close", WIDTH - 86, -10, 72, function() frame:Hide() end)
    E.nav = {}
    for n, name in ipairs(TABS) do
        local button = U.Button(frame, TAB_LABELS[name], 10, -52 - (n - 1) * 32, NAV - 10, function() E.SelectTab(name) end)
        button.label:SetJustifyH("LEFT"); button.tab = name; button:SetHeight(28)
        E.nav[n] = button
        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", NAV + 14, -52); page:SetSize(PAGE_W, PAGE_H)
        E.pages[name] = page; creators[name](page); page:Hide()
    end
    U.Muted(frame, "/ic help lists commands", 14, -HEIGHT + 30, NAV)
    E.status = U.Label(frame, "", NAV + 14, -HEIGHT + 26, PAGE_W, "GameFontHighlightSmall")
    table.insert(UISpecialFrames, "InCharacterEditor"); frame:Hide()
    frame:SetScript("OnHide", function()
        E.StoreDraft()
        if InCharacterDropdownList then InCharacterDropdownList:Hide() end
        if E.picker then E.picker:Hide() end
        if E.messages then E.messages:Hide() end
        if E.preview then E.preview:Hide() end
        if IC.LayoutUI and IC.LayoutUI.frame then IC.LayoutUI.frame:Hide() end
        if IC.EmoteReview and IC.EmoteReview.frame then IC.EmoteReview.frame:Hide() end
    end)
end
function E.Open(tab, barIndex)
    if IC.InCombat() then IC.Print("Open the settings after combat."); return end
    if not E.frame then E.Create() end
    if barIndex then E.barIndex = barIndex end
    if IC.Menu then IC.Menu.Close() end
    if IC.Wheel then IC.Wheel.Close() end
    if IC.QuickActions then IC.QuickActions.Close() end
    E.frame:Show(); E.frame:Raise(); E.SelectTab(tab or E.tab)
end
function E.Toggle()
    if E.frame and E.frame:IsShown() then E.frame:Hide() else E.Open() end
end
