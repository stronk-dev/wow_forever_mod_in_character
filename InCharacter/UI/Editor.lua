local _, IC = ...
local U = IC.UI
IC.Editor = { tab = "Dialogue Pools", poolPage = 1, emotePage = 1, barIndex = 1, drafts = setmetatable({}, { __mode = "k" }) }
local E = IC.Editor
local function status(text) E.status:SetText(text or "") end
local function changed() IC.Changed() end
local function splitLines(text)
    local lines = {}; text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    for line in (text .. "\n"):gmatch("(.-)\n") do if IC.Trim(line) ~= "" then lines[#lines + 1] = line end end
    return lines
end
function E.StoreDraft()
    if not E.formID or not E.formProfile then return end
    local panel = E.panels["Dialogue Pools"]
    E.drafts[E.formProfile] = E.drafts[E.formProfile] or {}
    E.drafts[E.formProfile][E.formID] = { name = panel.name:GetText(), lines = panel.lines:GetText(),
        mode = panel.mode.value, channel = panel.channel.value, icon = panel.icon:GetText() }
end
local function poolSelect(id)
    E.StoreDraft()
    local panel = E.panels["Dialogue Pools"]; E.poolID = id
    local profile = IC.Profile()
    E.formProfile, E.formID = profile, id
    local pool = id and profile.pools[id]
    local draft = pool and E.drafts[profile] and E.drafts[profile][id]
    panel.name:SetText(draft and draft.name or (pool and pool.name or ""))
    panel.lines:SetText(draft and draft.lines or (pool and table.concat(pool.lines, "\n") or ""))
    panel.mode:SetValue(draft and draft.mode or (pool and pool.mode or "shuffle")); panel.channel:SetValue(draft and draft.channel or (pool and pool.channel or "SAY"))
    local icon = draft and draft.icon or (pool and pool.icon or IC.Icons[1])
    panel.icon:SetText(tostring(icon)); panel.iconPreview:SetTexture(icon)
    panel.favorite:SetText(pool and IC.Actions.IsFavorite("pool:" .. id) and "Unfavorite" or "Favorite")
    panel.delete.confirming = nil; panel.delete:SetText("Delete pool")
    panel.info:SetText(pool and ("ID: " .. pool.id .. "   |   " .. #pool.lines .. " lines") or "Create a pool or copy a library preset below.")
end
local function poolRefresh(keepForm)
    local panel, profile = E.panels["Dialogue Pools"], IC.Profile()
    local pages = math.max(1, math.ceil(#profile.poolOrder / 8)); E.poolPage = math.max(1, math.min(pages, E.poolPage))
    for n, row in ipairs(panel.rows) do
        local id = profile.poolOrder[(E.poolPage - 1) * 8 + n]; row.poolID = id
        row:SetText(id and profile.pools[id].name or ""); row:SetShown(id ~= nil)
    end
    panel.page:SetText(E.poolPage .. "/" .. pages)
    if not keepForm then poolSelect(profile.pools[E.poolID] and E.poolID or profile.poolOrder[1]) end
end
local function createPools(panel)
    U.Label(panel, "Your pools", 14, -10); panel.rows = {}
    for n = 1, 8 do
        panel.rows[n] = U.Button(panel, "", 14, -32 - (n - 1) * 28, 185, function(self)
            poolSelect(self.poolID); status("Editing " .. IC.Profile().pools[self.poolID].name .. ". Drafts survive switching; Save to keep after /reload.")
        end)
    end
    U.Button(panel, "<", 14, -260, 40, function() E.poolPage = E.poolPage - 1; poolRefresh(true) end)
    panel.page = U.Label(panel, "1/1", 66, -265)
    U.Button(panel, ">", 155, -260, 44, function() E.poolPage = E.poolPage + 1; poolRefresh(true) end)
    U.Button(panel, "New pool", 14, -294, 185, function()
        local pool = IC.Dialogue.Create("New pool"); E.poolID = pool.id; E.poolPage = math.ceil(#IC.Profile().poolOrder / 8)
        poolRefresh(); status("New empty pool created. Edit its name and lines, then Save.")
    end)
    U.Button(panel, "Move up", 14, -326, 90, function() if E.poolID then IC.Dialogue.Move(E.poolID, -1); poolRefresh(true) end end)
    U.Button(panel, "Down", 109, -326, 90, function() if E.poolID then IC.Dialogue.Move(E.poolID, 1); poolRefresh(true) end end)
    U.Button(panel, "Discard draft", 14, -364, 185, function()
        local profile = IC.Profile()
        if E.drafts[profile] and E.poolID then E.drafts[profile][E.poolID] = nil end
        E.formID = nil; poolSelect(E.poolID); status("Draft discarded; showing saved pool.")
    end)
    U.Label(panel, "Name", 218, -10); panel.name = U.Input(panel, 218, -30, 456)
    panel.channel = U.Cycle(panel, 218, -62, 145, U.Options({ "SAY", "YELL", "EMOTE" }))
    panel.mode = U.Cycle(panel, 372, -62, 145, U.Options({ "random", "shuffle", "sequential" }))
    U.Button(panel, "Mode info", 526, -62, 148, function() status("Random: repeats possible. Shuffle: each line once per cycle. Sequential: in order, looping. State resets on edits or /reload.") end)
    U.Label(panel, "One saying per line. Edit, add, delete or reorder text, then Save.", 218, -98, 460)
    panel.lines = U.TextArea(panel, 218, -122, 456, 176)
    U.Label(panel, "Icon texture path (or cycle built-in icons)", 218, -308)
    panel.icon = U.Input(panel, 250, -330, 330)
    panel.iconPreview = panel:CreateTexture(nil, "ARTWORK"); panel.iconPreview:SetPoint("TOPLEFT", 218, -330); panel.iconPreview:SetSize(24, 24)
    U.Button(panel, "Next icon", 586, -330, 88, function()
        local nextIndex = 1
        for i, icon in ipairs(IC.Icons) do if icon == panel.icon:GetText() then nextIndex = i % #IC.Icons + 1; break end end
        panel.icon:SetText(IC.Icons[nextIndex]); panel.iconPreview:SetTexture(IC.Icons[nextIndex])
    end)
    U.Button(panel, "Save", 218, -366, 75, function()
        local pool = E.poolID and IC.Profile().pools[E.poolID]
        if not pool then status("Create a pool first."); return end
        local icon = IC.Trim(panel.icon:GetText()); if icon == "" then icon = IC.Icons[1] end
        local ok, problem = IC.Dialogue.Save(pool, panel.name:GetText(), panel.channel.value, panel.mode.value, icon, splitLines(panel.lines:GetText()))
        if ok then poolRefresh(); status("Saved. Stored sayings may exceed 255 bytes; oversized lines are preview-only until shortened.") else status(problem) end
    end)
    U.Button(panel, "Preview", 299, -366, 86, function()
        local draft = { id = E.poolID or "draft", mode = panel.mode.value, lines = splitLines(panel.lines:GetText()) }
        local line = IC.Dialogue.Preview(draft)
        E.ShowPreview(line and ("Preview (" .. #line .. " UTF-8 bytes; no chat sent):\n\n" .. line) or "This pool is empty.")
    end)
    panel.favorite = U.Button(panel, "Favorite", 391, -366, 98, function()
        if E.poolID then IC.Actions.Favorite("pool:" .. E.poolID); poolRefresh(true)
            panel.favorite:SetText(IC.Actions.IsFavorite("pool:" .. E.poolID) and "Unfavorite" or "Favorite") end
    end)
    panel.delete = U.Button(panel, "Delete pool", 495, -366, 179, function(self)
        if E.poolID then U.Confirm(self, "Delete pool", function()
            local drafts = E.drafts[IC.Profile()]; if drafts then drafts[E.poolID] = nil end
            E.formID = nil; IC.Dialogue.Delete(E.poolID); E.poolID = nil; poolRefresh(); status("Pool deleted.")
        end) end
    end)
    panel.info = U.Label(panel, "", 218, -402, 456)
    U.Label(panel, "Optional library (copies editable pools; never sends chat)", 14, -438, 660)
    local packs = {}; for _, id in ipairs(IC.Library.order) do packs[#packs + 1] = { value = id, label = IC.Library.packs[id].title } end
    panel.pack = U.Cycle(panel, 14, -462, 350, packs, function(value) panel.packNote:SetText(IC.Library.packs[value].contentNote) end)
    local function install(shortcuts)
        local _, message, id = IC.Library.Install(panel.pack.value, shortcuts)
        if id then E.poolID = id; E.poolPage = math.floor((#IC.Profile().poolOrder - #IC.Library.packs[panel.pack.value].pools) / 8) + 1 end
        poolRefresh(); status(message .. (shortcuts and " Available shortcuts now use the copies." or ""))
    end
    U.Button(panel, "Copy preset", 374, -462, 110, function() install(false) end)
    U.Button(panel, "Copy + greet/quote/bye", 492, -462, 182, function() install(true) end)
    panel.packNote = U.Label(panel, IC.Library.packs[IC.Library.order[1]].contentNote, 14, -496, 660)
    U.Button(panel, "Source / provenance", 14, -538, 185, function()
        local pack = IC.Library.packs[panel.pack.value]
        E.ShowPreview(pack.title .. "\nVersion " .. pack.version .. " | " .. pack.culture .. " | " .. pack.locale .. "\n\n" .. pack.source .. "\n\n" .. pack.contentNote)
    end)
end
local function emoteRefresh()
    local panel = E.panels.Emotes; local actions = IC.Actions.List(panel.category.value)
    local pages = math.max(1, math.ceil(#actions / 12)); E.emotePage = math.max(1, math.min(pages, E.emotePage))
    for n, row in ipairs(panel.rows) do
        local action = actions[(E.emotePage - 1) * 12 + n]; row.action = action; row:SetShown(action ~= nil)
        if action then row:SetText((IC.Actions.IsFavorite(action.id) and "* " or "") .. action.label .. "  [" .. (action.verified and "recognized" or "unverified") .. "]") end
    end
    panel.page:SetText(E.emotePage .. "/" .. pages); panel.hide:SetChecked(IC.Profile().hideUnverified); panel.filter:SetValue(IC.Profile().emoteFilter)
end
local function createEmotes(panel)
    U.Label(panel, "Select an emote. Preview shows local text; Try emote explicitly executes it.", 14, -14, 650)
    local sources = { "all" }; for _, category in ipairs(IC.Emotes.categories) do sources[#sources + 1] = category end
    panel.category = U.Cycle(panel, 14, -44, 230, U.Options(sources), function() E.emotePage = 1; emoteRefresh() end)
    panel.rows = {}
    for n = 1, 12 do panel.rows[n] = U.Button(panel, "", 14, -80 - (n - 1) * 30, 300, function(self)
        E.emote = self.action
        panel.labelInput:SetText(self.action.label); panel.iconInput:SetText(self.action.icon)
        panel.detail:SetText(self.action.label .. "\nToken: " .. self.action.payload .. "\n\n" .. (self.action.verified and "Recognized by client token table." or "Unverified: execution disabled.") .. "\n\nAnimation: " .. (self.action.animated and "listed by Charades (reference only)." or "unknown.") .. "\nNearby audio/text-only status: requires a live check.")
    end) end
    panel.detail = U.Label(panel, "Select an emote.", 340, -88, 320)
    U.Label(panel, "Custom label", 340, -250); panel.labelInput = U.Input(panel, 340, -272, 320)
    U.Label(panel, "Icon texture path", 340, -306); panel.iconInput = U.Input(panel, 340, -328, 320)
    U.Button(panel, "Save appearance", 340, -362, 155, function()
        if not E.emote then return end
        local label, icon = IC.Trim(panel.labelInput:GetText()), IC.Trim(panel.iconInput:GetText())
        IC.Profile().emoteOverrides[E.emote.id] = { label = label ~= "" and label or nil, icon = icon ~= "" and icon or nil }
        E.emote = IC.Actions.Resolve(E.emote.id); changed(); emoteRefresh(); status("Saved emote label and icon. Token remains unchanged.")
    end)
    U.Button(panel, "Next icon", 505, -362, 155, function()
        local index = 1
        for i, icon in ipairs(IC.Icons) do if icon == panel.iconInput:GetText() then index = i % #IC.Icons + 1; break end end
        panel.iconInput:SetText(IC.Icons[index])
    end)
    U.Button(panel, "Preview", 340, -402, 100, function() if E.emote then E.ShowPreview(E.emote.label .. "\nToken: " .. E.emote.payload .. "\nNo emote or chat sent.") end end)
    U.Button(panel, "Favorite / remove", 450, -402, 210, function() if E.emote then IC.Actions.Favorite(E.emote.id); emoteRefresh() end end)
    U.Button(panel, "Try emote", 340, -442, 320, function() if E.emote then IC.Actions.Dispatch(E.emote) end end)
    U.Button(panel, "<", 14, -446, 70, function() E.emotePage = E.emotePage - 1; emoteRefresh() end)
    panel.page = U.Label(panel, "", 120, -452)
    U.Button(panel, ">", 244, -446, 70, function() E.emotePage = E.emotePage + 1; emoteRefresh() end)
    panel.hide = U.Check(panel, "Hide unverified emotes", 14, -490, function(value) IC.Profile().hideUnverified = value; changed(); emoteRefresh() end)
    panel.filter = U.Cycle(panel, 14, -530, 300, {
        { value = "all", label = "All emotes" }, { value = "animated", label = "Animated (curated reference)" },
    }, function(value) IC.Profile().emoteFilter = value; changed(); emoteRefresh() end)
    U.Label(panel, "Animation metadata comes from Charades' curated list, not a Forever test. Nearby audio and text-only filters are unavailable until established.", 340, -490, 320)
end
local function barSources()
    local sources = { { value = "favorites", label = "Favorites" }, { value = "pools", label = "All dialogue pools" } }
    for _, category in ipairs(IC.Emotes.categories) do sources[#sources + 1] = { value = category, label = category } end
    for _, id in ipairs(IC.Profile().poolOrder) do sources[#sources + 1] = { value = "pool:" .. id, label = IC.Profile().pools[id].name } end
    return sources
end
local function currentBar() return IC.Layout().bars[E.barIndex] end
local function barRefresh()
    local panel, bars = E.panels.Bars, IC.Layout().bars; E.barIndex = math.max(1, math.min(#bars, E.barIndex))
    local config = currentBar()
    panel.which:SetText(#bars > 0 and ("Bar " .. E.barIndex .. " / " .. #bars .. " >") or "No bars")
    panel.name:SetText(config and config.name or "")
    panel.source.values = barSources(); panel.source:SetValue(config and config.source or "favorites"); panel.size:SetValue(config and config.size or 36)
    for key, check in pairs(panel.checks) do check:SetChecked(config and config[key] or false) end
    panel.delete.confirming = nil; panel.delete:SetText("Delete bar")
end
local function createBars(panel)
    U.Label(panel, "Bar configuration is saved separately for each character by default.", 14, -14, 650)
    panel.which = U.Button(panel, "", 14, -50, 300, function()
        local count = #IC.Layout().bars; if count > 0 then E.barIndex = E.barIndex % count + 1; barRefresh() end
    end)
    U.Button(panel, "Add bar", 330, -50, 160, function()
        local bars = IC.Layout().bars; bars[#bars + 1] = IC.Defaults.Bar(#bars + 1); E.barIndex = #bars; changed(); barRefresh()
    end)
    panel.delete = U.Button(panel, "Delete bar", 500, -50, 174, function(self)
        if currentBar() then U.Confirm(self, "Delete bar", function() table.remove(IC.Layout().bars, E.barIndex); changed(); barRefresh() end) end
    end)
    U.Label(panel, "Name", 14, -96); panel.name = U.Input(panel, 14, -118, 460)
    U.Button(panel, "Save name", 490, -118, 184, function() if currentBar() then currentBar().name = IC.Trim(panel.name:GetText()); changed(); barRefresh() end end)
    U.Label(panel, "Category or pool (click to cycle)", 14, -160)
    panel.source = U.Cycle(panel, 14, -184, 460, barSources(), function(value) if currentBar() then currentBar().source = value; currentBar().page = 1; changed() end end)
    U.Label(panel, "Button size", 14, -226)
    panel.size = U.Cycle(panel, 14, -250, 200, {
        { value = 24, label = "Small (24)" }, { value = 36, label = "Medium (36)" }, { value = 48, label = "Large (48)" }, { value = 64, label = "Extra large (64)" },
    }, function(value) if currentBar() then currentBar().size = value; changed() end end)
    panel.checks = {}
    for n, definition in ipairs({ { "vertical", "Vertical layout" }, { "collapsed", "Collapsed" }, { "locked", "Lock position" }, { "hidden", "Hide bar" } }) do
        local key = definition[1]
        panel.checks[key] = U.Check(panel, definition[2], 14, -294 - (n - 1) * 40, function(value) if currentBar() then currentBar()[key] = value; changed() end end)
    end
    U.Button(panel, "Reset position", 340, -294, 200, function() if currentBar() then currentBar().x = 0; currentBar().y = -160; changed() end end)
    U.Label(panel, "Drag a bar's title to move it. Click its title to collapse or expand. Scroll over a bar to change pages (12 buttons/page). Hidden bars are restored here. Pin pools directly as a bar source or add them to Favorites.", 340, -350, 320)
end
local function createWheel(panel)
    U.Label(panel, "Radial wheel", 14, -14)
    U.Label(panel, "Open with /ic wheel, or configure In Character bindings in WoW's Key Bindings. Click a group to enter it, then click an action to use it. Back returns one level. Escape or right-click cancels. Favorites are shown beside the root groups.", 14, -48, 640)
    panel.mode = U.Cycle(panel, 14, -156, 410, {
        { value = "click", label = "Click to confirm (recommended)" }, { value = "hold", label = "Experimental: point + release binding" },
    }, function(value) IC.Profile().wheel.mode = value; changed() end)
    U.Label(panel, "Experimental release mode requires a down/up binding supported by the client. Submenus always require a click; hover never enters them. Point at a visible action for at least 0.15 seconds before releasing. /ic wheel always uses click confirmation.", 14, -202, 640)
    panel.radius = U.Cycle(panel, 14, -296, 300, {
        { value = 140, label = "Compact radius" }, { value = 165, label = "Default radius" }, { value = 200, label = "Large radius" },
    }, function(value) IC.Profile().wheel.radius = value; changed() end)
    U.Button(panel, "Open wheel", 14, -348, 240, function() if IC.Wheel then E.frame:Hide(); IC.Wheel.Toggle() else status("Wheel module not loaded yet.") end end)
    U.Label(panel, "The wheel remains available in combat for direct emotes/chat, subject to client restrictions. Editor/layout rebuilds wait until safe. Chat permissions are checked before pool selection; nothing is queued. No secure action buttons or native action-bar drag/drop are used.", 14, -404, 640)
end
local function createProfiles(panel)
    U.Label(panel, "Dialogue, favorites and wheel settings", 14, -14)
    panel.scope = U.Cycle(panel, 14, -48, 500, {
        { value = "account", label = "Account-wide shared profile" }, { value = "character", label = "This character's profile" },
    }, function(value) IC.Profiles.SetScope(value); E.poolID = nil; status("Profile switched. Reopen other tabs to edit the selected profile.") end)
    U.Label(panel, "A private snapshot is created when you first select This character. Switching scopes keeps both profiles. Copy account explicitly to replace an existing private profile.", 14, -90, 640)
    U.Button(panel, "Copy account to this character", 14, -160, 320, function(self)
        U.Confirm(self, "Copy account", function() IC.Profiles.CopyAccount(); panel.scope:SetValue("character"); status("Account profile copied to character.") end)
    end)
    U.Label(panel, "Bar layouts", 14, -214)
    panel.layoutScope = U.Cycle(panel, 14, -250, 500, {
        { value = "character", label = "This character's bar layout" }, { value = "account", label = "Account-wide shared bar layout" },
    }, function(value) IC.Profiles.SetLayoutScope(value); status("Bar layout scope switched.") end)
    U.Button(panel, "Reset active profile", 14, -316, 320, function(self)
        U.Confirm(self, "Reset profile", function() IC.Profiles.Reset(); E.poolID = nil; status("Active profile reset. Other profiles and layouts retained.") end)
    end)
    U.Label(panel, "SavedVariables: InCharacterDB (shared) and InCharacterCharDB (this character). The reported beta loading bug was marked fixed in build 70009; verify reload/restart on your build. Export/import is not implemented.", 14, -382, 640)
    U.Button(panel, "Reset greet/quote/bye mapping", 14, -474, 320, function() IC.Profile().shortcuts = {}; changed(); status("Shortcuts now use the default Greetings, Quotes and Farewells pools.") end)
end
function E.ShowPreview(text)
    if not E.preview then
        local frame = CreateFrame("Frame", "InCharacterPreview", UIParent, "BackdropTemplate")
        frame:SetSize(580, 350); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG")
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }); frame:SetBackdropColor(0.07, 0.07, 0.09, 1)
        U.Label(frame, "Local preview / source notes — no chat sent", 14, -14)
        frame.text = U.TextArea(frame, 14, -44, 552, 252)
        U.Button(frame, "Close", 440, -310, 120, function() frame:Hide() end)
        table.insert(UISpecialFrames, "InCharacterPreview"); E.preview = frame
    end
    E.preview.text:SetText(text); E.preview:Show()
end
function E.SelectTab(name)
    E.StoreDraft()
    E.tab = name; status("Pool drafts survive switching until /reload. Save to persist. Click selectors to cycle choices.")
    for tab, panel in pairs(E.panels) do panel:SetShown(tab == name) end
    if name == "Dialogue Pools" then poolRefresh()
    elseif name == "Emotes" then emoteRefresh()
    elseif name == "Bars" then barRefresh()
    elseif name == "Wheel" then E.panels.Wheel.mode:SetValue(IC.Profile().wheel.mode); E.panels.Wheel.radius:SetValue(IC.Profile().wheel.radius)
    elseif name == "Profiles" then E.panels.Profiles.scope:SetValue(IC.Profiles.Character().scope); E.panels.Profiles.layoutScope:SetValue(IC.Profiles.Character().layoutScope) end
end
function E.Create()
    local frame = CreateFrame("Frame", "InCharacterEditor", UIParent, "BackdropTemplate"); E.frame = frame; E.panels = {}
    frame:SetSize(716, 710); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true); frame:EnableMouse(true); frame:SetMovable(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }); frame:SetBackdropColor(0.07, 0.07, 0.09, 0.98)
    frame:SetScale(math.min(1, (UIParent:GetHeight() - 30) / 710, (UIParent:GetWidth() - 30) / 716))
    U.Label(frame, "In Character", 16, -14); U.Button(frame, "Close", 604, -8, 96, function() frame:Hide() end)
    local creators = { Emotes = createEmotes, ["Dialogue Pools"] = createPools, Bars = createBars, Wheel = createWheel, Profiles = createProfiles }
    for n, name in ipairs({ "Emotes", "Dialogue Pools", "Bars", "Wheel", "Profiles" }) do
        U.Button(frame, name, 14 + (n - 1) * 138, -44, 132, function() E.SelectTab(name) end)
        local panel = CreateFrame("Frame", nil, frame); panel:SetPoint("TOPLEFT", 8, -82); panel:SetSize(700, 580)
        E.panels[name] = panel; creators[name](panel); panel:Hide()
    end
    E.status = U.Label(frame, "", 16, -666, 680); E.status:SetFontObject("GameFontHighlightSmall")
    table.insert(UISpecialFrames, "InCharacterEditor"); frame:Hide()
    frame:SetScript("OnHide", function() E.StoreDraft() end)
end
function E.Toggle()
    if IC.InCombat() then IC.Print("Open the editor after combat."); return end
    if not E.frame then E.Create() end
    if E.frame:IsShown() then E.frame:Hide() else E.SelectTab(E.tab); E.frame:Show() end
end
