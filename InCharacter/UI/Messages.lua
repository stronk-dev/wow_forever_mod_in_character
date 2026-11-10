local _, IC = ...
-- Individual message controls inside RP lines, using stable IDs and independent drafts.
local E, U = IC.Editor, IC.UI
E.messageDrafts = setmetatable({}, { __mode = 'k' })
local function key(pool, id) return pool .. ':' .. (id or 'new') end
function E.StoreMessageDraft()
    local p, profile = E.pages.Lines, E.messageProfile
    if not p or not p.messageText or not profile or not E.messagePool then return end
    local pool = profile.pools[E.messagePool]; if not pool then return end
    local text = E.messageID and IC.Dialogue.Line(pool, E.messageID) or ''
    E.messageDrafts[profile] = E.messageDrafts[profile] or {}
    E.messageDrafts[profile][key(pool.id, E.messageID)] = p.messageText:GetText() ~= (text or '') and p.messageText:GetText() or nil
end
function E.SelectMessage(id)
    E.StoreMessageDraft()
    local p, profile = E.pages.Lines, IC.Profile()
    local pool = E.poolID and profile.pools[E.poolID]; if not pool then return end
    E.messageProfile, E.messagePool, E.messageID = profile, pool.id, id
    local draft = E.messageDrafts[profile] and E.messageDrafts[profile][key(pool.id, id)]
    p.messageText:SetText(draft or (id and IC.Dialogue.Line(pool, id)) or '')
    p.messageID:SetText(id and ('Message ' .. id .. (draft and ' · unsaved' or '')) or 'New message')
    local action = id and IC.Actions.Resolve('line:' .. pool.id .. ':' .. id)
    p.messageIcon:SetIcon(action and action.icon or pool.icon)
    for _, row in ipairs(p.messageRows) do row:SetSelected(row.lineID == id) end
    p.messageDelete.confirming = nil; p.messageDelete:SetText("Delete")
    p.messageDelete:SetEnabled(id ~= nil)
end
function E.RefreshMessages()
    local p = E.pages.Lines; local pool = E.poolID and IC.Profile().pools[E.poolID]
    if not pool then return end
    IC.Dialogue.EnsureLines(pool)
    for _, row in ipairs(p.messageRows) do row:Hide() end
    for i, id in ipairs(pool.lineIDs) do
        local row = p.messageRows[i]
        if not row then
            row = U.Button(p.messageList.content, '', 0, 0, 174, function(self) E.SelectMessage(self.lineID) end, 'flat')
            row:SetHeight(21); row.label:SetJustifyH('LEFT'); p.messageRows[i] = row
        end
        row.lineID = id; row:ClearAllPoints(); row:SetPoint('TOPLEFT', 0, -(i - 1) * 22)
        row:SetText(IC.DisplayText(pool.lines[i])); row:Show()
    end
    p.messageList:SetContentHeight(#pool.lines * 22)
    local options = {}; for _, list in ipairs(IC.Collections.List()) do if not list.dynamic then options[#options + 1] = { value = list.id, label = list.name } end end
    p.messageDestination:SetOptions(options)
    if not IC.Collections.Get(p.messageDestination.value) then p.messageDestination:SetValue('favorites') end
    local id = E.messagePool == pool.id and E.messageID
    if not id or not IC.Dialogue.Line(pool, id) then id = pool.lineIDs[1] end
    E.SelectMessage(id)
    E.SetMessageView(E.messageView == true)
end
function E.SetMessageView(value)
    E.StoreMessageDraft()
    E.messageView = value == true
    local p = E.pages.Lines
    p.lines:SetShown(not E.messageView); p.messages:SetShown(E.messageView)
    p.messageToggle:SetText(E.messageView and 'Bulk lines' or 'Individual messages')
end
function E.CreateMessageControls(parent, width)
    local p = E.pages.Lines
    local f = CreateFrame('Frame', nil, parent); p.messages = f
    f:SetPoint('TOPLEFT', 0, -106); f:SetSize(width, 170); f:Hide()
    p.messageRows = {}; p.messageList = U.Scroll(f, 0, 0, 194, 138)
    U.Button(f, '+ New', 0, -142, 62, function() E.SelectMessage(nil) end)
    for i, delta in ipairs({ -1, 1 }) do
        U.Button(f, delta == -1 and 'Up' or 'Down', 66 + (i - 1) * 66, -142, 62, function()
            local pool = E.poolID and IC.Profile().pools[E.poolID]
            if pool and E.messageID then IC.Dialogue.MoveLine(pool, E.messageID, delta); E.RefreshMessages() end
        end)
    end
    local x, rw = 206, width - 206
    p.messageIcon = U.IconButton(f, 22, false); p.messageIcon:SetPoint('TOPLEFT', x, 0)
    p.messageIcon:SetScript('OnClick', function()
        local poolID, id, profile = E.poolID, E.messageID, IC.Profile()
        if id then E.PickIcon(IC.Actions.Resolve('line:' .. poolID .. ':' .. id).icon, function(icon)
            if profile == IC.Profile() and profile.pools[poolID] then IC.Actions.SetIcon('line:' .. poolID .. ':' .. id, icon); E.RefreshMessages() end
        end) end
    end)
    p.messageID = U.Muted(f, '', x + 28, -4, rw - 28)
    p.messageText = U.TextArea(f, x, -28, rw, 64)
    p.messageSave = U.Button(f, 'Save message', x, -98, 104, function()
        local pool = E.poolID and IC.Profile().pools[E.poolID]; if not pool then return end
        local ok, problem, id = IC.Dialogue.SaveLine(pool, E.messageID, p.messageText:GetText())
        if not ok then E.Status(problem); return end
        if E.messageDrafts[IC.Profile()] then E.messageDrafts[IC.Profile()][key(pool.id, E.messageID)] = nil end
        E.messageProfile, E.formID = nil, nil; E.messageID, E.messagePool = id, pool.id
        E.SelectPool(pool.id); E.Status('Message saved; existing buttons keep their ID.')
    end)
    U.Button(f, 'Preview', x + 108, -98, 84, function() E.Status('Preview, not sent: ' .. IC.DisplayText(p.messageText:GetText())) end)
    p.messageDelete = U.Button(f, 'Delete', x + 196, -98, rw - 196, function(self)
        local pool = E.poolID and IC.Profile().pools[E.poolID]
        if pool and E.messageID then U.Confirm(self, 'Delete', function()
            IC.Dialogue.DeleteLine(pool, E.messageID); E.messageProfile, E.formID, E.messageID = nil, nil, nil
            E.SelectPool(pool.id)
        end) end
    end)
    p.messageDestination = U.Dropdown(f, x, -136, rw - 110, {})
    p.messagePlace = U.Button(f, 'Add to list', x + rw - 106, -136, 106, function()
        if E.messageID then
            local ok = IC.Collections.Add(p.messageDestination.value, 'line:' .. E.poolID .. ':' .. E.messageID)
            E.Status(ok and 'Message added to the selected list.' or 'Already included, or select an editable list.')
        else E.Status('Save the new message first.') end
    end)
end
