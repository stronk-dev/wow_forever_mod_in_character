local _, IC = ...
-- Settings window. Four pages:
--   Lists    what is in each list (favorites, categories, your own) + the emote library
--   Lines    RP characters, dialogue pools and presets
--   Layout   launcher, radial wheel, emote menu, bars and keys
--   Profiles shared or per-character data
-- Nothing here sends chat except the explicit Try / Preview-free buttons.
local U = IC.UI
local C = U.Colors
IC.Editor = { tab = "Lists", list = "favorites", search = "", kind = "all", category = "all", advanced = false,
    drafts = setmetatable({}, { __mode = "k" }), pages = {} }
local E = IC.Editor
local WIDTH, HEIGHT, NAV = 940, 600, 130
local PAGE_W, PAGE_H = WIDTH - NAV - 24, HEIGHT - 70
local ROW = 22
local TABS = { "Lists", "Lines", "Layout", "Profiles" }
local TAB_LABELS = { Lists = "Emotes & lists", Lines = "RP lines", Layout = "Layout & keys", Profiles = "Profiles" }
local ALIASES = { Home = "Lists", Emotes = "Lists", Favorites = "Lists", Dialogue = "Lines", Layouts = "Layout" }

local function status(text) if E.status then E.status:SetText(text or "") end end
E.Status = status
local function iconText(icon) return icon and tostring(icon) or IC.Icons[1] end
local function splitLines(text)
    local lines = {}; text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    for line in (text .. "\n"):gmatch("(.-)\n") do if IC.Trim(line) ~= "" then lines[#lines + 1] = line end end
    return lines
end
local function section(parent, title, x, y, width, height)
    local frame = U.Panel(parent, width, height, C.raised); frame:SetPoint("TOPLEFT", x, y)
    U.Label(frame, title, 12, -10, nil, "GameFontNormal")
    return frame
end
-- A reusable list row: icon, text, optional right-side text.
local function listRow(parent, width, click)
    local row = U.Button(parent, "", 0, 0, width, click, "flat")
    row:SetHeight(ROW - 1)
    row.label:ClearAllPoints(); row.label:SetPoint("LEFT", 24, 0); row.label:SetPoint("RIGHT", -34, 0); row.label:SetJustifyH("LEFT")
    row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(18, 18); row.icon:SetPoint("LEFT", 3, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.right:SetPoint("RIGHT", -6, 0); row.right:SetJustifyH("RIGHT")
    return row
end
local function rows(store, parent, count, width, click)
    for i = #store + 1, count do store[i] = listRow(parent, width, click) end
    for _, row in ipairs(store) do row:Hide() end
end

-- Icon picker -------------------------------------------------------------------------------------
local PICK_COLS, PICK_ROWS = 10, 6
function E.PickIcon(current, done)
    local picker = E.picker
    if not picker then
        picker = CreateFrame("Frame", "InCharacterIconPicker", UIParent, "BackdropTemplate")
        E.picker = picker; U.GameBackdrop(picker, true)
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
        IC.Platform.MacroIcons(picker.allIcons)
        local seen = {}; for _, icon in ipairs(picker.allIcons) do seen[icon] = true end
        for _, choice in ipairs(IC.IconChoices or {}) do
            if not seen[choice.path] then picker.allIcons[#picker.allIcons + 1] = choice.path; seen[choice.path] = true end
            local name = choice.label .. " · " .. choice.search
            picker.names[choice.path] = picker.names[choice.path] and (picker.names[choice.path] .. "; " .. name) or name
            picker.groups[choice.path] = picker.groups[choice.path] or {}; picker.groups[choice.path][choice.category] = true
        end
    end
    picker.done = done; picker.path:SetText(iconText(current)); picker.preview:SetIcon(current)
    picker.search:SetText(""); picker.category:SetValue("All"); picker:Filter(); picker:Show(); picker:Raise()
end

-- Name dialog (new list, new / renamed RP character) ----------------------------------------------
function E.AskName(title, current, done)
    local dialog = E.nameDialog
    if not dialog then
        dialog = U.Panel(E.frame, 360, 132, C.bg, "InCharacterNameDialog"); E.nameDialog = dialog
        dialog:SetPoint("CENTER"); dialog:SetFrameStrata("FULLSCREEN_DIALOG"); dialog:EnableMouse(true)
        dialog.title = U.Heading(dialog, "", 14, -12)
        dialog.name = U.Input(dialog, 14, -44, 332)
        dialog:SetScript("OnHide", function() dialog.name:ClearFocus() end)
        U.Button(dialog, "Cancel", 14, -90, 130, function() dialog:Hide() end)
        dialog.save = U.Button(dialog, "Save", 216, -90, 130, function()
            local name = IC.Trim(dialog.name:GetText()); if name == "" then status("Enter a name."); return end
            dialog:Hide(); dialog.done(name)
        end, "accent")
        dialog.name:SetScript("OnEnterPressed", function() dialog.save:Click() end)
        table.insert(UISpecialFrames, "InCharacterNameDialog")
    end
    dialog.title:SetText(title); dialog.done = done
    dialog.name:SetText(current or ""); dialog:Show(); dialog.name:SetFocus()
end

-- Lists -------------------------------------------------------------------------------------------
-- Slim by default: your lists, what is in the selected one, and a searchable library to add from.
-- "Advanced" adds nesting one list inside another. Emotes this client lacks are never listed.
local LA, LB, LC = 0, 210, 470
local function refName(ref)
    local kind, target = ref:match("^(%a+):(.+)$")
    if kind == "set" or kind == "all" then
        local list = IC.Collections.Get(target)
        return (list and (list.dynamic and "RP character" or list.name) or target), list and list.icon, kind == "set" and "group" or "inline"
    end
    local action = IC.Actions.Resolve(ref)
    if not action then return ref, nil, "removed" end
    local note = action.type == "emote" and (not action.verified and "not on client" or nil)
        or (action.role and "slot") or (action.type == "character" and "switcher")
        or (action.type == "pool" and "lines") or (action.type == "line" and "line") or nil
    return action.name or action.label, action.icon, note
end
-- The library: emotes by category, or the loaded character's lines.
local function libraryItems()
    local result = {}
    local query = IC.Trim(E.search or ""):lower()
    local function match(action, extra)
        return query == "" or ((action.name or action.label or "") .. " " .. (extra or "")):lower():find(query, 1, true)
    end
    if E.category == "rp" then
        for _, role in ipairs(IC.Personas.Slots()) do
            local action = IC.Actions.Resolve("role:" .. role.id)
            if match(action) then result[#result + 1] = action end
        end
        local pools = {}
        for _, id in ipairs(IC.Personas.Pools()) do pools[#pools + 1] = id end
        for _, id in ipairs(IC.Personas.SharedPools()) do pools[#pools + 1] = id end
        for _, id in ipairs(pools) do
            local pool = IC.Profile().pools[id]
            if not IC.Personas.RoleOf(id) and match(IC.Actions.Resolve("pool:" .. id)) then result[#result + 1] = IC.Actions.Resolve("pool:" .. id) end
            for _, line in ipairs(IC.Actions.Lines(pool)) do if match(line, pool.name) then result[#result + 1] = line end end
        end
        return result
    end
    local source = E.category == "all" and IC.Emotes.list or IC.Emotes.byCategory[E.category] or {}
    for _, emote in ipairs(source) do
        if emote.verified and IC.Emotes.Search(emote, query) then result[#result + 1] = IC.Actions.Resolve(emote.id) end
    end
    return result
end
local function listName(list) return list.dynamic and "RP character" or list.name end

function E.RefreshLists()
    local p = E.pages.Lists
    local lists = IC.Collections.List()
    if not IC.Collections.Get(E.list) then E.list = "favorites" end
    rows(p.listRows, p.lists.content, #lists, LB - LA - 30, function(self) E.list, E.item = self.id, nil; E.RefreshLists() end)
    for i, list in ipairs(lists) do
        local row = p.listRows[i]
        row.id = list.id; row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW)
        row:SetText(listName(list)); U.SetIcon(row.icon, list.icon, IC.Icons[1])
        row.right:SetText("|cff888888" .. #IC.Collections.Refs(list.id) .. "|r"); row:SetSelected(list.id == E.list); row:Show()
    end
    p.lists:SetContentHeight(#lists * ROW)
    local current = IC.Collections.Get(E.list)
    p.itemsTitle:SetText(listName(current))
    p.dynamicNote:SetShown(current.dynamic == true)
    p.listIcon:SetIcon(current.icon)
    local refs = IC.Collections.Refs(E.list)
    local offset = current.dynamic and 42 or 0
    rows(p.itemRows, p.items.content, #refs, LC - LB - 30, function(self) E.item = self.ref; if IC.Actions.Resolve(self.ref) then E.selected = self.ref end; E.RefreshLists() end)
    for i, ref in ipairs(refs) do
        local row = p.itemRows[i]
        local name, icon, note = refName(ref)
        row.ref = ref; row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW - offset)
        row:SetText(name); U.SetIcon(row.icon, icon, IC.Icons[1]); row.right:SetText(note and ("|cff888888" .. note .. "|r") or "")
        row:SetSelected(ref == E.item); row:Show()
    end
    p.items:SetContentHeight(#refs * ROW + offset)
    for _, control in ipairs(p.itemControls) do control:SetEnabled(not current.dynamic) end
    local options = {}
    for _, list in ipairs(lists) do if list.id ~= E.list then options[#options + 1] = { value = list.id, label = listName(list) } end end
    p.groupChoice:SetOptions(options); if not p.groupChoice.value or p.groupChoice.value == E.list then p.groupChoice:SetValue(options[1] and options[1].value) end
    for _, control in ipairs(p.advancedOnly) do control:SetShown(E.advanced == true) end
    p.delete.confirming = nil; p.delete:SetText("Delete list")
    p.delete:SetEnabled(not current.builtin and not current.dynamic); p.rename:SetEnabled(not current.dynamic)
    E.RefreshLibrary()
end

function E.RefreshLibrary()
    local p = E.pages.Lists
    local items = libraryItems(); p.shown = items
    rows(p.libRows, p.library.content, #items, PAGE_W - LC - 18, function(self, mouse)
        if mouse == "RightButton" then IC.Collections.Toggle(E.list, self.action.id); E.RefreshLists(); return end
        E.selected = self.action.id; E.RefreshLibrary()
    end)
    for i, action in ipairs(items) do
        local row = p.libRows[i]
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.action = action; row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW)
        local inList = IC.Collections.Contains(E.list, action.id)
        row:SetText((inList and "|cff66dd66+|r " or "") .. (action.name or action.label) .. (action.command and ("  |cff888888/" .. action.command .. "|r") or ""))
        U.SetIcon(row.icon, action.icon, IC.Icons[1]); row.icon:SetDesaturated((action.type == "emote" and not action.verified) or action.empty == true)
        row.right:SetText(action.role and "|cff888888slot|r" or "")
        row:SetSelected(action.id == E.selected); row:Show()
    end
    p.library:SetContentHeight(#items * ROW)
    local current = IC.Collections.Get(E.list)
    p.count:SetText(#items .. " shown" .. (current.dynamic and "" or " · right-click: add / remove"))
    E.RefreshDetail()
end

function E.RefreshDetail()
    local p = E.pages.Lists
    local action = E.selected and IC.Actions.Resolve(E.selected)
    p.detail:SetShown(action ~= nil); p.noDetail:SetShown(action == nil)
    if not action then return end
    local d = p.detail
    d.icon:SetIcon(action.icon, IC.Icons[1])
    d.name:SetText(action.name or action.label)
    local isEmote = action.type == "emote"
    if isEmote then
        d.info:SetText("/" .. action.command)
    else
        d.info:SetText("|cffbbbbbb" .. IC.Actions.Description(action) .. "|r")
    end
    d.rename:SetShown(isEmote); d.renameButton:SetShown(isEmote); d.reset:SetShown(isEmote)
    local override = IC.Profile().emoteOverrides[action.id]
    d.rename:SetText(override and override.label or "")
    d.editMessage:SetShown(action.type == "line" or action.role ~= nil)
    local current = IC.Collections.Get(E.list)
    d.add:SetEnabled(not current.dynamic)
    d.add:SetText(IC.Collections.Contains(E.list, action.id) and "Remove" or "Add")
    d.pin:SetText(IC.Actions.IsFavorite(action.id) and "Unfavorite" or "Favorite")
    d.try:SetEnabled(not (isEmote and not action.verified) and not action.empty)
end

local function createLists(p)
    p.listRows, p.itemRows, p.libRows, p.advancedOnly, p.itemControls = {}, {}, {}, {}, {}
    -- Column A: lists
    U.Label(p, "Lists", LA, 0, nil, "GameFontNormal")
    p.lists = U.Scroll(p, LA, -20, LB - LA - 10, 404)
    local half = (LB - LA - 14) / 2
    U.Button(p, "+ New list", LA, -432, LB - LA - 10, function()
        E.AskName("New list", "", function(name)
            local list = IC.Collections.Create(name); if list then E.list = list.id; E.RefreshLists(); status("Created " .. name .. ". Show it on a bar in Move & edit bars.") end
        end)
    end, "accent")
    p.rename = U.Button(p, "Rename", LA, -462, half, function()
        local list = IC.Collections.Get(E.list); if not list or list.dynamic then return end
        E.AskName("Rename list", list.name, function(name) list.name = name; IC.Changed(); E.RefreshLists() end)
    end)
    p.delete = U.Button(p, "Delete list", LA + half + 4, -462, half, function(self)
        U.Confirm(self, "Delete list", function() if IC.Collections.Delete(E.list) then E.list = "favorites"; E.RefreshLists(); status("List deleted.") end end)
    end)
    -- Column B: what is in the selected list
    p.itemsTitle = U.Label(p, "", LB, 0, LC - LB - 40, "GameFontNormal"); p.itemsTitle:SetWordWrap(false)
    p.listIcon = U.IconButton(p, 20, false); p.listIcon:SetPoint("TOPLEFT", LC - 32, 3)
    p.listIcon:SetScript("OnClick", function() local id = E.list; E.PickIcon(IC.Collections.Get(id).icon, function(icon) IC.Collections.SetIcon(id, icon); E.RefreshLists() end) end)
    p.items = U.Scroll(p, LB, -20, LC - LB - 10, 404)
    p.dynamicNote = U.Muted(p.items, "Follows the loaded RP character. Edit its lines on the RP lines page.", 6, -6, LC - LB - 30)
    local third = (LC - LB - 18) / 3
    local function move(delta) if E.item then IC.Collections.Move(E.list, E.item, delta); E.RefreshLists() end end
    p.itemControls[1] = U.Button(p, "Up", LB, -432, third, function() move(-1) end)
    p.itemControls[2] = U.Button(p, "Down", LB + third + 4, -432, third, function() move(1) end)
    p.itemControls[3] = U.Button(p, "Remove", LB + (third + 4) * 2, -432, third, function()
        if E.item then IC.Collections.Remove(E.list, E.item); E.item = nil; E.RefreshLists() end
    end)
    -- Advanced: put another list inside this one, as a group button or its items inline.
    p.groupChoice = U.Dropdown(p, LB, -462, LC - LB - 94, {})
    local addGroup = U.Button(p, "+ Group", LC - 92, -462, 82, function()
        if p.groupChoice.value and IC.Collections.Add(E.list, (p.inline:GetChecked() and "all:" or "set:") .. p.groupChoice.value) then E.RefreshLists() end
    end)
    p.inline = U.Check(p, "Its items inline", LB, -490, function() end); p.inline.caption:SetWidth(LC - LB - 40)
    for _, control in ipairs({ p.groupChoice, addGroup, p.inline }) do p.advancedOnly[#p.advancedOnly + 1] = control end
    -- Column C: the library
    U.Label(p, "Add from", LC, 0, nil, "GameFontNormal")
    p.advanced = U.Check(p, "Advanced", PAGE_W - 100, 4, function(value) E.advanced = value; E.RefreshLists() end)
    p.advanced.caption:SetWidth(70)
    p.search = U.Input(p, LC, -20, 170)
    p.search:SetScript("OnTextChanged", function(self) E.search = self:GetText(); if p:IsShown() then E.RefreshLibrary() end end)
    local categories = { { value = "all", label = "Every emote" } }
    for _, id in ipairs(IC.Emotes.categories) do categories[#categories + 1] = { value = id, label = IC.Emotes.CategoryInfo[id].label } end
    categories[#categories + 1] = { value = "rp", label = "RP character lines" }
    p.category = U.Dropdown(p, LC + 176, -20, PAGE_W - LC - 176, categories, function(value) E.category = value; E.RefreshLibrary() end)
    p.library = U.Scroll(p, LC, -52, PAGE_W - LC, 11 * ROW)
    p.count = U.Muted(p, "", LC, -306, PAGE_W - LC); p.count:SetWordWrap(false)
    -- Detail of the selected library entry
    p.noDetail = U.Muted(p, "Select an entry to try it, favorite it, rename it or change its icon.", LC, -342, PAGE_W - LC)
    local d = CreateFrame("Frame", nil, p); p.detail = d
    d:SetPoint("TOPLEFT", LC, -338); d:SetSize(PAGE_W - LC, 190)
    local DW = PAGE_W - LC
    d.icon = U.IconButton(d, 32, false); d.icon:SetPoint("TOPLEFT", 0, -2)
    d.icon:SetScript("OnClick", function() local id = E.selected; E.PickIcon(IC.Actions.Resolve(id).icon, function(icon) IC.Actions.SetIcon(id, icon); E.RefreshLists() end) end)
    d.name = U.Label(d, "", 40, 0, DW - 40, "GameFontNormal"); d.name:SetWordWrap(false)
    d.info = U.Label(d, "", 40, -20, DW - 40, "GameFontHighlightSmall"); d.info:SetWordWrap(false)
    local bw = (DW - 8) / 3
    d.try = U.Button(d, "Try it", 0, -40, bw, function()
        local ok = IC.Actions.Dispatch(E.selected); status(ok and "Sent." or "Not sent.")
    end)
    d.pin = U.Button(d, "Favorite", bw + 4, -40, bw, function() IC.Actions.Favorite(E.selected); E.RefreshLists() end)
    d.add = U.Button(d, "", (bw + 4) * 2, -40, bw, function() IC.Collections.Toggle(E.list, E.selected); E.RefreshLists() end)
    d.rename = U.Input(d, 0, -72, DW - 172)
    d.renameButton = U.Button(d, "Rename", DW - 168, -72, 80, function()
        local id = E.selected; local text = IC.Trim(d.rename:GetText())
        local overrides = IC.Profile().emoteOverrides
        overrides[id] = overrides[id] or {}; overrides[id].label = text ~= "" and text or nil
        IC.Changed(); E.RefreshLists()
    end)
    d.reset = U.Button(d, "Reset", DW - 84, -72, 84, function() IC.Profile().emoteOverrides[E.selected] = nil; IC.Changed(); E.RefreshLists() end)
    d.editMessage = U.Button(d, "Edit on the RP lines page", 0, -72, DW, function()
        local action = IC.Actions.Resolve(E.selected)
        if action and (action.type == "line" or action.role) and action.payload then
            E.Open("Lines"); E.SelectPool(action.payload)
            if action.type == "line" then E.SetMessageView(true); E.SelectMessage(action.lineID) end
        elseif action and action.role then E.Open("Lines") end
    end)
end

-- RP lines ----------------------------------------------------------------------------------------
-- Pick the character, then its pools. Slots (Greeting, Quote, Farewell and your own) are shared by
-- every character; bars, the wheel and /ic greet|quote|bye|say play the loaded character's pool
-- for a slot, or the shared pool when the character has none. A pool is this character's or shared.
local LIST_W, FORM_X = 230, 244
local function slotOptions(poolID)
    local options = { { value = "", label = "No slot (extra)" } }
    for _, slot in ipairs(IC.Personas.Slots()) do options[#options + 1] = { value = slot.id, label = "Slot: " .. slot.label } end
    options[#options + 1] = { value = "+new", label = "+ New slot..." }
    local current = poolID and IC.Personas.Slot(IC.Personas.RoleOf(poolID) or "")
    if current and current.custom then
        options[#options + 1] = { value = "+rename", label = "Rename " .. current.label .. "..." }
        options[#options + 1] = { value = "+delete", label = "Delete " .. current.label .. " slot" }
    end
    return options
end
function E.StoreDraft()
    if E.StoreMessageDraft then E.StoreMessageDraft() end
    if not E.formID or not E.formProfile or not E.pages.Lines then return end
    local p = E.pages.Lines
    local pool = E.formProfile.pools[E.formID]
    E.drafts[E.formProfile] = E.drafts[E.formProfile] or {}
    local draft = { name = p.name:GetText(), lines = p.lines:GetText(), mode = p.mode.value, channel = p.channel.value, icon = p.iconValue }
    local same = pool and draft.name == pool.name and draft.lines == table.concat(pool.lines, "\n") and draft.mode == pool.mode
        and draft.channel == pool.channel and draft.icon == pool.icon
    E.drafts[E.formProfile][E.formID] = (not same) and draft or nil
end
local function setFormIcon(icon) local p = E.pages.Lines; p.iconValue = icon; p.icon:SetIcon(icon, IC.Icons[1]) end
local function counter()
    local p = E.pages.Lines
    local lines, longest = splitLines(p.lines:GetText()), 0
    for _, line in ipairs(lines) do longest = math.max(longest, #IC.Actions.ChatText(line)) end
    p.count:SetText(#lines .. " lines   |   longest " .. longest .. " / 255 bytes" .. (longest > 255 and "  |cffff7755(too long to send)|r" or ""))
end
function E.SelectPool(id)
    E.StoreDraft()
    local p = E.pages.Lines
    local profile = IC.Profile()
    local pool = id and profile.pools[id]
    E.poolID, E.formProfile, E.formID = pool and id or nil, profile, pool and id or nil
    local draft = pool and E.drafts[profile] and E.drafts[profile][id]
    p.form:SetShown(pool ~= nil); p.noPool:SetShown(pool == nil)
    if not pool then E.RefreshPoolList(); return end
    p.name:SetText(draft and draft.name or pool.name)
    p.lines:SetText(draft and draft.lines or table.concat(pool.lines, "\n"))
    p.mode:SetValue(draft and draft.mode or pool.mode); p.channel:SetValue(draft and draft.channel or pool.channel)
    p.role:SetOptions(slotOptions(id)); p.role:SetValue(IC.Personas.RoleOf(id) or "")
    p.owner:SetOptions({ { value = "own", label = "Only " .. IC.Personas.Name() }, { value = "shared", label = "Shared by all characters" } })
    p.owner:SetValue(IC.Personas.IsShared(id) and "shared" or "own")
    setFormIcon(draft and draft.icon or pool.icon)
    p.delete.confirming = nil; p.delete:SetText("Delete pool")
    local source = IC.Personas.Source(pool)
    p.info:SetText((source and ("From the " .. source .. " preset; addon updates add its new lines, your edits stay") or "") .. (draft and ((source and "   |   " or "") .. "|cffffd100unsaved changes|r") or ""))
    counter()
    E.RefreshPoolList()
    if p.messages then E.RefreshMessages() end
end
function E.RefreshPoolList()
    local p, profile = E.pages.Lines, IC.Profile()
    local ids = {}
    -- This character's pools (slot pools first, in slot order), then the shared ones.
    local seen = {}
    local function add(id) if id and profile.pools[id] and not seen[id] then seen[id] = true; ids[#ids + 1] = id end end
    local actor = IC.Personas.Active()
    for _, slot in ipairs(IC.Personas.Slots()) do add(actor and actor.roles and actor.roles[slot.id]) end
    for _, id in ipairs(IC.Personas.Pools()) do add(id) end
    for _, slot in ipairs(IC.Personas.Slots()) do add(profile.sharedRoles and profile.sharedRoles[slot.id]) end
    for _, id in ipairs(IC.Personas.SharedPools()) do add(id) end
    rows(p.rows, p.list.content, #ids, LIST_W - 22, function(self) E.SelectPool(self.poolID) end)
    for i, id in ipairs(ids) do
        local row, pool = p.rows[i], profile.pools[id]
        local role = IC.Personas.RoleOf(id)
        row.poolID = id; row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW)
        local slot = role and IC.Personas.Slot(role)
        row:SetText(pool.name); row.right:SetText("|cff888888" .. (IC.Personas.IsShared(id) and "shared · " or "") .. (slot and (slot.label .. " · ") or "") .. #pool.lines .. "|r")
        U.SetIcon(row.icon, pool.icon, IC.Icons[1]); row:SetSelected(id == E.poolID); row:Show()
    end
    p.list:SetContentHeight(#ids * ROW)
    local missing = {}
    for _, role in ipairs(IC.Personas.Slots()) do if not IC.Personas.RolePool(role.id) then missing[#missing + 1] = role.label end end
    p.missingRoles:SetText(#missing > 0 and ("No " .. table.concat(missing, ", ") .. " yet: pick a pool and give it that slot.") or "")
    E.poolIDs = ids
end
function E.RefreshLines()
    local p = E.pages.Lines
    p.character:SetOptions(IC.Personas.Options(false)); p.character:SetValue(IC.Personas.Active() and IC.Personas.Active().id)
    p.deleteCharacter.confirming = nil; p.deleteCharacter:SetText("Delete character")
    E.RefreshPoolList()
    local id; for _, candidate in ipairs(E.poolIDs) do if candidate == E.poolID then id = candidate end end
    E.formID = nil
    E.SelectPool(id or E.poolIDs[1])
end
local function createLines(p)
    p.rows = {}
    U.Label(p, "Playing as", 0, -4, nil, "GameFontNormal")
    p.character = U.Dropdown(p, 84, 0, 256, {}, function(value)
        E.StoreDraft(); local ok, problem = IC.Personas.Choose(value)
        if ok then E.poolID = nil; E.RefreshLines(); status("Now playing " .. IC.Personas.Name() .. ".") else status(problem) end
    end)
    U.Button(p, "New character", 346, 0, 120, function()
        E.AskName("New RP character", "", function(name) local actor = IC.Personas.Create(name); IC.Personas.Load(actor.id); E.RefreshLines() end)
    end)
    U.Button(p, "Rename", 470, 0, 90, function()
        local actor = IC.Personas.Active(); if not actor then return end
        E.AskName("Rename RP character", actor.name, function(name) actor.name = name; IC.Changed(); E.RefreshLines() end)
    end)
    p.deleteCharacter = U.Button(p, "Delete character", 564, 0, 150, function(self)
        local actor = IC.Personas.Active(); if not actor then return end
        U.Confirm(self, "Delete character", function()
            local name, preset = actor.name, actor.pack
            E.StoreDraft(); E.formID, E.poolID = nil, nil
            IC.Personas.Delete(actor.id); E.RefreshLines()
            status(preset and (name .. " removed. The preset is still in its family if you want it back.") or (name .. " deleted."))
        end)
    end)
    local top = -34
    U.Muted(p, "This character's pools", 0, top - 2)
    p.list = U.Scroll(p, 0, top - 18, LIST_W, 248)
    U.Button(p, "+ New pool", 0, top - 272, LIST_W, function()
        E.StoreDraft()
        local pool = IC.Dialogue.Create("New pool"); E.formID = nil; E.SelectPool(pool.id)
        status("New empty pool. Name it, give it a role if you like, write one line per row, then Save.")
    end, "accent")
    p.missingRoles = U.Muted(p, "", 0, top - 302, LIST_W)
    p.noPool = U.Muted(p, "This character has no pools yet. Create one, or add a preset character below.", FORM_X, top, 300)
    local FW = PAGE_W - FORM_X
    p.form = CreateFrame("Frame", nil, p); p.form:SetPoint("TOPLEFT", FORM_X, top); p.form:SetSize(FW, 340)
    local f = p.form
    p.icon = U.IconButton(f, 36, false); p.icon:SetPoint("TOPLEFT", 0, -2)
    p.icon:SetScript("OnClick", function() E.PickIcon(p.iconValue, setFormIcon) end)
    U.Muted(f, "Name", 46, 0); p.name = U.Input(f, 46, -14, FW - 46 - 196)
    U.Muted(f, "Used by", FW - 190, 0)
    p.owner = U.Dropdown(f, FW - 190, -14, 190, {}, function(value)
        if E.poolID then
            E.StoreDraft(); IC.Personas.SetShared(E.poolID, value == "shared"); E.formID = nil; E.SelectPool(E.poolID)
            status(value == "shared" and "Shared: every character without its own pool for this slot uses it." or ("Now only " .. IC.Personas.Name() .. "'s."))
        end
    end)
    U.Muted(f, "Slot", 0, -44)
    p.role = U.Dropdown(f, 0, -58, 170, {}, function(value)
        local id = E.poolID; if not id then return end
        local current = IC.Personas.RoleOf(id)
        local function done() E.StoreDraft(); E.formID = nil; E.SelectPool(id) end
        if value == "+new" then
            E.AskName("New slot (for example Joke)", "", function(name)
                local slot, problem = IC.Personas.CreateSlot(name)
                if slot then IC.Personas.SetRole(slot.id, id); status(slot.label .. " is now a slot on every character's RP list.") else status(problem) end
                done()
            end)
            done(); return
        elseif value == "+rename" then
            local slot = IC.Personas.Slot(current or "")
            E.AskName("Rename slot", slot and slot.label or "", function(name)
                local ok, problem = IC.Personas.RenameSlot(current, name); status(ok and "Slot renamed." or problem); done()
            end)
            done(); return
        elseif value == "+delete" then
            if E.pendingSlotDelete == current then
                E.pendingSlotDelete = nil; IC.Personas.DeleteSlot(current); status("Slot deleted; its buttons were removed. The pools are kept.")
            else
                E.pendingSlotDelete = current; status("Choose Delete again to delete this slot for every character. Pools are kept.")
            end
            done(); return
        end
        E.pendingSlotDelete = nil
        if value == "" then IC.Personas.ClearRole(id) else IC.Personas.SetRole(value, id) end
        E.RefreshPoolList()
    end)
    U.Muted(f, "Sent as", 176, -44)
    p.channel = U.Dropdown(f, 176, -58, 150, {
        { value = "SAY", label = "Say (nearby)" }, { value = "YELL", label = "Yell (wide area)" }, { value = "EMOTE", label = "Emote text (/e)" },
    })
    U.Muted(f, "Which line a click sends", 332, -44)
    p.mode = U.Dropdown(f, 332, -58, FW - 332, {
        { value = "shuffle", label = "Shuffle: each once" }, { value = "random", label = "Random: may repeat" },
        { value = "sequential", label = "In order, then loop" },
    })
    p.messageToggle = U.Button(f, "Individual messages", FW - 150, -86, 150, function() E.SetMessageView(not E.messageView) end)
    p.messageToggle:SetHeight(20)
    p.lines = U.TextArea(f, 0, -110, FW, 166)
    p.lines.changed = counter
    E.CreateMessageControls(f, FW)
    p.count = U.Muted(f, "", 0, -280, FW)
    local bw = (FW - 12) / 4
    U.Button(f, "Save", 0, -298, bw, function()
        local pool = E.poolID and IC.Profile().pools[E.poolID]
        if not pool then return end
        local ok, problem = IC.Dialogue.Save(pool, p.name:GetText(), p.channel.value, p.mode.value, p.iconValue or IC.Icons[1], splitLines(p.lines:GetText()))
        if ok then
            if E.drafts[IC.Profile()] then E.drafts[IC.Profile()][E.poolID] = nil end
            E.formID = nil; E.SelectPool(E.poolID); status(problem or "Saved.")
        else status(problem) end
    end, "accent")
    U.Button(f, "Preview", bw + 4, -298, bw, function()
        local line = IC.Dialogue.Preview({ id = E.poolID or "draft", mode = p.mode.value, lines = splitLines(p.lines:GetText()) })
        status(line and ("Preview, not sent: " .. IC.DisplayText(IC.ShortText(line, 160))) or "This pool is empty.")
    end)
    U.Button(f, "Discard edits", (bw + 4) * 2, -298, bw, function()
        if E.drafts[IC.Profile()] and E.poolID then E.drafts[IC.Profile()][E.poolID] = nil end
        E.formID = nil; E.SelectPool(E.poolID); status("Edits discarded.")
    end)
    p.delete = U.Button(f, "Delete pool", (bw + 4) * 3, -298, bw, function(self)
        if not E.poolID then return end
        U.Confirm(self, "Delete pool", function()
            local drafts = E.drafts[IC.Profile()]; if drafts then drafts[E.poolID] = nil end
            E.formID = nil; IC.Dialogue.Delete(E.poolID); E.poolID = nil; E.RefreshLines(); status("Pool deleted.")
        end)
    end)
    p.info = U.Muted(f, "", 0, -328, FW); p.info:SetWordWrap(false)
    -- Preset characters
    local lib = U.Panel(p, PAGE_W, 120, C.panel); lib:SetPoint("TOPLEFT", 0, -400)
    U.Label(lib, "Preset characters", 12, -12, nil, "GameFontNormal")
    -- Family first (The Office, Dutch politics, ...), then a character in it.
    local families = {}
    for _, family in ipairs(IC.Library.FAMILIES) do
        if #IC.Library.Members(family.id) > 0 then families[#families + 1] = { value = family.id, label = family.label } end
    end
    p.packNote = U.Muted(lib, "", 12, -70, PAGE_W - 24)
    p.pack = U.Dropdown(lib, 178, -34, 200, {}, function(value)
        local pack = IC.Library.packs[value]
        p.packNote:SetText(IC.ShortText(pack.contentNote, 240)); p.pack.tooltip = pack.contentNote .. "\nSource: " .. pack.source
    end)
    p.family = U.Dropdown(lib, 12, -34, 160, families, function(value)
        local members = {}
        for _, id in ipairs(IC.Library.Members(value)) do members[#members + 1] = { value = id, label = IC.Library.ShortTitle(id) } end
        p.pack:SetOptions(members); if members[1] then p.pack:Choose(members[1].value) end
    end)
    p.family:Choose(families[1].value)
    U.Button(lib, "Play as this character", 384, -34, PAGE_W - 396, function()
        E.StoreDraft(); local ok, problem = IC.Library.Load(p.pack.value)
        if ok then E.poolID = nil; E.RefreshLines(); status("Now playing " .. IC.Personas.Name() .. ". Its lines are your own copy to edit.") else status(problem) end
    end, "accent")
    U.Muted(lib, "Copies the preset's lines as your own editable character. Never sends anything by itself.", 12, -92, PAGE_W - 24)
end
function E.OnCharacterLoaded()
    E.StoreDraft(); E.formID, E.poolID, E.formProfile = nil, nil, nil
    if E.frame and E.frame:IsShown() then E.SelectTab(E.tab) end
end

-- Layout & keys -----------------------------------------------------------------------------------
local function listOptions()
    local options = {}
    for _, list in ipairs(IC.Collections.List()) do options[#options + 1] = { value = list.id, label = list.dynamic and "RP character" or list.name } end
    return options
end
function E.RefreshLayout()
    local p = E.pages.Layout
    p.refreshing = true
    local launcher, wheel = IC.Layout().launcher, IC.Profile().wheel
    p.launcherShown:SetChecked(launcher.shown ~= false); p.launcherSize:Set(launcher.size or 36)
    p.barMode:SetValue(IC.Bars.Mode())
    p.wheelMode:SetValue(wheel.mode == "hold" and "hold" or "click")
    p.wheelRoot:SetOptions(listOptions()); p.wheelRoot:SetValue(wheel.root or "ring")
    p.wheelIcon:Set(math.floor(tonumber(wheel.iconSize) or 40))
    p.menuRoot:SetOptions(listOptions()); p.menuRoot:SetValue(IC.Profile().menu.root or "main")
    for _, key in ipairs(p.keys) do key.Refresh() end
    p.barsToggle:SetText(IC.Layout().barsHidden and "Show bars" or "Hide bars")
    p.refreshing = nil
end
local function createLayout(p)
    local half = (PAGE_W - 10) / 2
    local function set(fn) return function(value) if not p.refreshing then fn(value); IC.Changed() end end end
    local s = section(p, "Bars", 0, 0, half, 150)
    p.barMode = U.Dropdown(s, 12, -32, half - 24, { { value = "one", label = "One bar: favorites, categories, RP" }, { value = "separate", label = "Separate bars: one per list" } },
        function(value) if not p.refreshing then IC.Bars.SetMode(value); E.RefreshLayout() end end)
    U.Button(s, "Move & edit bars", 12, -64, 150, function() E.frame:Hide(); IC.Bars.SetEditing(true) end, "accent")
    p.barsToggle = U.Button(s, "", 168, -64, half - 180, function() IC.Bars.ToggleAll(); E.RefreshLayout() end)
    U.Muted(s, "Each mode keeps its own positions and sizes. Shift-right-click a bar to edit it.", 12, -98, half - 24)
    s = section(p, "Launcher button", half + 10, 0, half, 150)
    p.launcherShown = U.Check(s, "Show the launcher", 12, -30, set(function(v) IC.Layout().launcher.shown = v end))
    p.launcherSize = U.Slider(s, "Size", 12, -62, half - 24, 24, 64, 2, set(function(v) IC.Layout().launcher.size = v end))
    U.Muted(s, "Left-click: emote menu · Right-click: settings · Shift-drag: move", 12, -108, half - 24)
    s = section(p, "Radial wheel", 0, -160, half, 196)
    p.keys = {}
    p.keys[#p.keys + 1] = U.KeyCapture(s, 12, -32, half - 24, "INCHARACTER_WHEEL", "Key")
    p.wheelMode = U.Dropdown(s, 12, -64, half - 24, {
        { value = "click", label = "Press to open, click to use" }, { value = "hold", label = "Hold key, release over an item" },
    }, set(function(v) IC.Profile().wheel.mode = v end))
    U.Muted(s, "Shows", 12, -100)
    p.wheelRoot = U.Dropdown(s, 60, -94, half - 72, {}, set(function(v) IC.Profile().wheel.root = v end))
    p.wheelIcon = U.Slider(s, "Icon size", 12, -126, half - 120, 32, 48, 2, set(function(v) IC.Profile().wheel.iconSize = v end))
    U.Button(s, "Try it", half - 100, -144, 88, function() E.frame:Hide(); IC.Wheel.Open(false) end)
    s = section(p, "Emote menu at the cursor", half + 10, -160, half, 196)
    p.keys[#p.keys + 1] = U.KeyCapture(s, 12, -32, half - 24, "INCHARACTER_MENU", "Key")
    U.Muted(s, "Shows", 12, -70)
    p.menuRoot = U.Dropdown(s, 60, -64, half - 72, {}, set(function(v) IC.Profile().menu.root = v end))
    U.Muted(s, "The launcher's menu shows the same list.", 12, -100, half - 24)
    s = section(p, "More keys", 0, -366, PAGE_W, 150)
    local quarter = (PAGE_W - 36) / 2
    for i = 1, 4 do
        p.keys[#p.keys + 1] = U.KeyCapture(s, 12 + ((i - 1) % 2) * (quarter + 12), -32 - math.floor((i - 1) / 2) * 30, quarter, "INCHARACTER_FAVORITE" .. i, "Favorite " .. i)
    end
    p.keys[#p.keys + 1] = U.KeyCapture(s, 12, -92, quarter, "INCHARACTER_BARS", "Show / hide bars")
    p.keys[#p.keys + 1] = U.KeyCapture(s, 24 + quarter, -92, quarter, "INCHARACTER_EDITOR", "This window")
    U.Muted(s, "Right-click a key button to clear it. Keys also appear in WoW's Key Bindings > In Character.", 12, -124, PAGE_W - 24)
end

-- Profiles ----------------------------------------------------------------------------------------
function E.RefreshProfiles()
    local p = E.pages.Profiles
    p.scope:SetValue(IC.Profiles.Character().scope); p.layoutScope:SetValue(IC.Profiles.Character().layoutScope)
end
local function createProfiles(p)
    local s = section(p, "Emotes, lists, favorites and RP characters", 0, 0, PAGE_W, 130)
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
    U.Muted(s, "Saved in InCharacterDB (shared) and InCharacterCharDB (this character). Close WoW before backing up WTF/.../SavedVariables.", 12, -70, PAGE_W - 24)
end

-- Window ------------------------------------------------------------------------------------------
local creators = { Lists = createLists, Lines = createLines, Layout = createLayout, Profiles = createProfiles }
local refreshers = { Lists = "RefreshLists", Lines = "RefreshLines", Layout = "RefreshLayout", Profiles = "RefreshProfiles" }
local function hidePopups()
    if E.nameDialog then E.nameDialog:Hide() end
    if InCharacterDropdownList then InCharacterDropdownList:Hide() end
    if E.picker then E.picker:Hide() end
end
function E.SelectTab(name)
    name = ALIASES[name] or name
    if not creators[name] then name = "Lists" end
    E.StoreDraft(); hidePopups()
    E.tab = name
    for tab, page in pairs(E.pages) do page:SetShown(tab == name) end
    for _, button in ipairs(E.nav) do button:SetSelected(button.tab == name) end
    E[refreshers[name]]()
end
function E.Create()
    local frame = CreateFrame("Frame", "InCharacterEditor", UIParent, "BackdropTemplate"); E.frame = frame
    U.GameBackdrop(frame, true)
    frame:SetSize(WIDTH, HEIGHT); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetToplevel(true)
    frame:SetClampedToScreen(true); frame:EnableMouse(true); frame:SetMovable(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScale(math.min(1, (UIParent:GetHeight() - 40) / HEIGHT, (UIParent:GetWidth() - 40) / WIDTH))
    local logo = U.IconButton(frame, 26, true); logo:SetPoint("TOPLEFT", 14, -10); logo:SetIcon(IC.AddonIcon); logo:EnableMouse(false)
    U.Heading(frame, "In Character", 50, -14)
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
    frame:SetScript("OnHide", function() E.StoreDraft(); hidePopups() end)
end
function E.Open(tab)
    if IC.InCombat() then IC.Print("Open the settings after combat."); return end
    if not E.frame then E.Create() end
    if IC.Flyout then IC.Flyout.Close() end
    if IC.Wheel then IC.Wheel.Close() end
    E.frame:Show(); E.frame:Raise(); E.SelectTab(tab or E.tab)
end
function E.Toggle()
    if E.frame and E.frame:IsShown() then E.frame:Hide() else E.Open() end
end
