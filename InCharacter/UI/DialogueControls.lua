local _, IC = ...
local E, U, D, A = IC.Editor, IC.UI, IC.Dialogue, IC.Actions
IC.DialogueUI = {}
local UI = IC.DialogueUI
local function status(text) if E.status then E.status:SetText(text) end end
local function submit(action, label)
    local ok, reason = A.Dispatch(action)
    local message = ok and "Submitted one action to the client; server acceptance is not acknowledged." or (reason or "Nothing submitted. See chat for the pool/client restriction.")
    if label then label:SetText(message) else status(message) end
    return ok
end

function E.ShowPreview(text, title)
    if not E.preview then
        local frame = U.Panel(E.frame, 680, 380, U.Colors.bg, "InCharacterPreview")
        frame:SetPoint("CENTER"); frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:EnableMouse(true)
        frame.heading = U.Heading(frame, "", 14, -14, 560)
        frame.text = U.TextArea(frame, 14, -48, 652, 310)
        U.Button(frame, "Close", 584, -10, 80, function() frame:Hide() end)
        E.preview = frame
        table.insert(UISpecialFrames, "InCharacterPreview")
    end
    E.preview.heading:SetText(title or "Preview only — nothing sent or saved")
    E.preview.text:SetText(text); E.preview:Show(); E.preview:Raise()
end
function E.PreviewAction(action)
    if type(action) == "string" then action = A.Resolve(action) end
    if not action then return end
    local pool = IC.Profile().pools[action.payload]
    local text
    if action.type == "line" and pool then text = D.Line(pool, action.lineID)
    elseif action.type == "pool" and pool then text = D.Preview(pool, action.selectionMode)
    else text = A.Description(action) .. "\n" .. IC.Emotes.KindInfo[action.kind or "unknown"].help end
    E.ShowPreview(text or "This pool is empty.", "Preview only — nothing sent")
end
local function savedPool()
    E.StoreDraft()
    local profile = IC.Profile()
    if E.poolID and E.drafts[profile] and E.drafts[profile][E.poolID] then
        status("Save or discard the pool draft before playing or editing saved messages."); return nil
    end
    return E.poolID and profile.pools[E.poolID]
end
function UI.Attach(p, parent, width)
    local gap, buttonWidth = 4, (width - 8) / 3
    U.Button(parent, "Play next", 0, -368, buttonWidth, function()
        local pool = savedPool(); if pool then submit("pool:" .. pool.id) end
    end, "accent").tooltip = "Send one saved line using this pool's selected mode."
    U.Button(parent, "Random message", buttonWidth + gap, -368, buttonWidth, function()
        local pool = savedPool(); if pool then submit("play:random:" .. pool.id) end
    end).tooltip = "Send a uniformly random saved line. Does not consume the pool's normal shuffle/order state."
    p.browse = U.Button(parent, "Browse / edit messages", (buttonWidth + gap) * 2, -368, buttonWidth, function()
        local pool = savedPool(); if pool then E.OpenMessages(pool.id) end
    end)
end

local function poolFor(frame)
    if frame.profile ~= IC.Profile() then frame.notice:SetText("Profile changed; reopen this message browser from the active profile."); return nil end
    local pool = frame.profile.pools[frame.poolID]
    if not pool then frame.notice:SetText("This pool was removed.") end
    return pool
end
local function draftKey(frame) return frame.lineID or "new" end
local function drafts(frame)
    E.messageDrafts = E.messageDrafts or setmetatable({}, { __mode = "k" })
    E.messageDrafts[frame.profile] = E.messageDrafts[frame.profile] or {}
    local profileDrafts = E.messageDrafts[frame.profile]
    profileDrafts[frame.poolID] = profileDrafts[frame.poolID] or {}
    return profileDrafts[frame.poolID]
end
local function storeMessage(frame)
    if not frame.profile or not frame.loaded then return end
    local pool = frame.profile.pools[frame.poolID]
    local saved = pool and frame.lineID and D.Line(pool, frame.lineID) or ""
    drafts(frame)[draftKey(frame)] = frame.edit:GetText() ~= saved and frame.edit:GetText() or nil
end
local function syncPoolForm(frame)
    if frame.profile == IC.Profile() and E.poolID == frame.poolID then
        E.formID = nil; E.RefreshDialogue()
    end
end
local function messageAction(frame)
    local pool = poolFor(frame)
    if not pool or not frame.lineID then return nil end
    return A.Resolve("line:" .. pool.id .. ":" .. frame.lineID)
end
local function updateMessageControls(frame)
    local pool = poolFor(frame)
    local saved = pool and frame.lineID and D.Line(pool, frame.lineID)
    local text = frame.edit:GetText()
    local dirty = text ~= (saved or "")
    local bytes = #A.ChatText(text)
    local valid = IC.Trim(text) ~= "" and not text:find("[%z\1-\31\127]")
    frame.count:SetText(bytes .. " / 255 encoded bytes" .. (dirty and " · unsaved edit" or "") .. (bytes > 255 and " · shorten before sending" or "") .. (not valid and " · enter one non-empty message" or ""))
    frame.send:SetEnabled(saved ~= nil and not dirty and bytes <= 255 and valid)
    frame.pin:SetEnabled(saved ~= nil and not dirty)
    frame.bar:SetEnabled(saved ~= nil and not dirty)
    frame.pin:SetText(saved and A.IsFavorite("line:" .. frame.poolID .. ":" .. frame.lineID) and "Unpin message" or "Pin message")
    local action = messageAction(frame)
    frame.icon:SetEnabled(action ~= nil); frame.icon:SetIcon(action and action.icon or IC.Icons[1])
end
local function selectMessage(frame, lineID)
    storeMessage(frame)
    frame.lineID, frame.loaded = lineID, false
    local pool = poolFor(frame); if not pool then return end
    local text = lineID and D.Line(pool, lineID) or ""
    frame.edit:SetText(drafts(frame)[draftKey(frame)] or text or "")
    frame.loaded = true; updateMessageControls(frame)
    frame.delete.confirming = nil; frame.delete:SetText("Delete selected message")
    frame.notice:SetText(lineID and ("Message ID: " .. lineID .. ". Specific-message buttons keep this ID when you edit or reorder here.") or "New message: write one message, then Save message. Nothing is sent by saving.")
    for _, row in ipairs(frame.rows) do row:SetSelected(row.lineID == lineID) end
end
local function refreshMessages(frame, selected)
    local pool = poolFor(frame); if not pool then return end
    D.EnsureLines(pool)
    frame.heading:SetText(IC.DisplayText(IC.ShortText(pool.name, 68)))
    frame.channel:SetValue(pool.channel); frame.mode:SetValue(pool.mode)
    for _, row in ipairs(frame.rows) do row:Hide() end
    for i, lineID in ipairs(pool.lineIDs) do
        local row = frame.rows[i]
        if not row then
            row = U.Button(frame.list.content, "", 0, 0, 238, function(self) selectMessage(frame, self.lineID) end)
            row.label:SetJustifyH("LEFT"); frame.rows[i] = row
        end
        row.lineID = lineID; row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -(i - 1) * 30)
        row:SetText(i .. ". " .. IC.DisplayText(IC.ShortText(pool.lines[i], 54)))
        row.tooltip = IC.DisplayText(pool.lines[i]); row:Show()
    end
    frame.list:SetContentHeight(#pool.lines * 30)
    frame.loaded = false; selectMessage(frame, selected)
end
local function createMessages()
    local frame = U.Panel(E.frame, 760, 540, U.Colors.bg, "InCharacterMessages")
    E.messages = frame; frame:SetPoint("CENTER"); frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:EnableMouse(true)
    frame.rows = {}; frame.heading = U.Heading(frame, "Messages", 14, -14, 640)
    U.Button(frame, "Close", 666, -10, 80, function() storeMessage(frame); frame:Hide() end)
    local function configure()
        local pool = poolFor(frame); if not pool then return end
        D.Save(pool, pool.name, frame.channel.value, frame.mode.value, pool.icon, pool.lines)
        syncPoolForm(frame)
    end
    frame.channel = U.Dropdown(frame, 14, -48, 250, U.Options({ "SAY", "YELL", "EMOTE" }), configure)
    frame.mode = U.Dropdown(frame, 290, -48, 456, {
        { value = "random", label = "Pool playback: random" }, { value = "shuffle", label = "Pool playback: shuffle" },
        { value = "sequential", label = "Pool playback: in order" },
    }, configure)
    frame.list = U.Scroll(frame, 14, -90, 260, 320)
    U.Button(frame, "+ New message", 14, -420, 260, function() selectMessage(frame, nil) end, "accent")
    U.Button(frame, "Move up", 14, -452, 126, function()
        local pool = poolFor(frame); if pool and frame.lineID then storeMessage(frame); D.MoveLine(pool, frame.lineID, -1); syncPoolForm(frame); refreshMessages(frame, frame.lineID) end
    end)
    U.Button(frame, "Move down", 148, -452, 126, function()
        local pool = poolFor(frame); if pool and frame.lineID then storeMessage(frame); D.MoveLine(pool, frame.lineID, 1); syncPoolForm(frame); refreshMessages(frame, frame.lineID) end
    end)
    U.Label(frame, "Selected message (wraps visually; one message per entry)", 290, -90, 456)
    frame.edit = U.TextArea(frame, 290, -112, 404, 132)
    frame.icon = U.IconButton(frame, 36, false); frame.icon:SetPoint("TOPLEFT", 708, -112)
    frame.icon:SetScript("OnClick", function()
        local action = messageAction(frame); if not action then return end
        local profile, id = frame.profile, action.id
        E.PickIcon(action.icon, function(icon)
            if profile == IC.Profile() then A.SetIcon(id, icon); updateMessageControls(frame) end
        end)
    end)
    U.Muted(frame, "Icon", 708, -154, 38)
    U.Button(frame, "Reset", 702, -180, 44, function()
        local action = messageAction(frame); if action then A.SetIcon(action.id, nil); updateMessageControls(frame) end
    end)
    frame.count = U.Muted(frame, "", 290, -252, 456)
    frame.edit.changed = function() if frame.profile then updateMessageControls(frame) end end
    U.Button(frame, "Save message", 290, -276, 222, function()
        local pool = poolFor(frame); if not pool then return end
        local key = draftKey(frame)
        local ok, problem, id = D.SaveLine(pool, frame.lineID, frame.edit:GetText())
        if not ok then frame.notice:SetText(problem); return end
        drafts(frame)[key] = nil; drafts(frame)[id] = nil; frame.loaded = false
        syncPoolForm(frame); refreshMessages(frame, id); frame.notice:SetText("Saved message " .. id .. ". Nothing sent.")
    end, "accent")
    U.Button(frame, "Discard edit", 524, -276, 222, function()
        drafts(frame)[draftKey(frame)] = nil; frame.loaded = false; selectMessage(frame, frame.lineID)
    end)
    frame.send = U.Button(frame, "Send this message", 290, -316, 284, function()
        local action = messageAction(frame)
        local pool = poolFor(frame)
        if not action or not pool or frame.edit:GetText() ~= D.Line(pool, frame.lineID) then frame.notice:SetText("Save or discard this edit before sending."); return end
        submit(action, frame.notice)
    end, "accent")
    U.Button(frame, "Preview only", 586, -316, 160, function() E.ShowPreview(frame.edit:GetText(), "Message preview — nothing sent") end)
    frame.pin = U.Button(frame, "Pin message", 290, -352, 222, function()
        local action = messageAction(frame); local pool = poolFor(frame)
        if action and pool and frame.edit:GetText() == D.Line(pool, frame.lineID) then A.Favorite(action.id); updateMessageControls(frame) end
    end)
    frame.bar = U.Button(frame, "Create message bar", 524, -352, 222, function()
        local action = messageAction(frame); local pool = poolFor(frame)
        if action and pool and frame.edit:GetText() == D.Line(pool, frame.lineID) then IC.Bars.Pin(action); frame.notice:SetText("Created a bar for this exact message. Configure it under Layouts.") end
    end)
    U.Button(frame, "Play next from pool", 290, -392, 222, function() local pool = poolFor(frame); if pool then submit("pool:" .. pool.id, frame.notice) end end)
    U.Button(frame, "Random from pool", 524, -392, 222, function() local pool = poolFor(frame); if pool then submit("play:random:" .. pool.id, frame.notice) end end)
    frame.delete = U.Button(frame, "Delete selected message", 290, -452, 456, function(self)
        local pool = poolFor(frame); if not pool or not frame.lineID then return end
        U.Confirm(self, "Delete message", function()
            local id = frame.lineID; D.DeleteLine(pool, id); drafts(frame)[id] = nil; frame.loaded = false
            syncPoolForm(frame); refreshMessages(frame, pool.lineIDs[1])
        end)
    end)
    frame.notice = U.Muted(frame, "", 14, -496, 732)
    frame:SetScript("OnHide", function() storeMessage(frame) end)
    table.insert(UISpecialFrames, "InCharacterMessages")
    frame:Hide()
    return frame
end
function E.OpenMessages(poolID)
    local pool = IC.Profile().pools[poolID]; if not pool then return end
    local frame = E.messages or createMessages()
    storeMessage(frame)
    frame.profile, frame.poolID, frame.loaded = IC.Profile(), poolID, false
    D.EnsureLines(pool); refreshMessages(frame, pool.lineIDs[1]); frame:Show(); frame:Raise()
end

function UI.CreateFavorites(page)
    U.Heading(page, "Favorite actions", 0, 0)
    U.Muted(page, "Order controls the bar, menu and favorite keys 1–4. Pin pools, playback modes or specific messages from their menus.", 0, -26, 780)
    page.list = U.Scroll(page, 0, -66, 786, 470); page.rows = {}
end
function E.RefreshFavorites()
    local page = E.pages.Favorites; local favorites = IC.Profile().favorites
    for _, row in ipairs(page.rows) do row:Hide() end
    for index, id in ipairs(favorites) do
        local row = page.rows[index]
        if not row then
            row = U.Panel(page.list.content, 766, 58, U.Colors.raised)
            row.icon = U.IconButton(row, 32, false); row.icon:SetPoint("LEFT", 4, 0); row.icon:EnableMouse(false)
            row.name = U.Label(row, "", 44, -8, 330)
            row.detail = U.Muted(row, "", 44, -30, 330)
            U.Button(row, "Up", 390, -16, 40, function() A.MoveFavorite(row.id, -1); E.RefreshFavorites() end)
            U.Button(row, "Down", 434, -16, 50, function() A.MoveFavorite(row.id, 1); E.RefreshFavorites() end)
            U.Button(row, "Preview", 490, -16, 72, function() E.PreviewAction(row.id) end)
            U.Button(row, "Play", 568, -16, 58, function() submit(row.id) end, "accent")
            U.Button(row, "Unpin", 632, -16, 70, function() A.Favorite(row.id); E.RefreshFavorites() end)
            U.Button(row, "Bar", 708, -16, 54, function() IC.Bars.Pin(row.id) end)
            page.rows[index] = row
        end
        local action = A.Resolve(id); row.id = id
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -(index - 1) * 62)
        row.name:SetText(index .. ". " .. (action and (action.name or action.label) or "Removed action"))
        row.detail:SetText(action and IC.ShortText(A.Description(action), 90) or id)
        row.icon:SetIcon(action and action.icon, IC.Icons[1]); row:Show()
    end
    page.list:SetContentHeight(#favorites * 62)
end
