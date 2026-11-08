local _, IC = ...
local U, E, R, A = IC.UI, IC.Editor, IC.Curation, IC.Actions
IC.EmoteReview = {}
local V = IC.EmoteReview
local function current(frame)
    if frame.profile ~= IC.Profile() then frame:Hide(); return nil end
    return frame.ids[frame.index] and A.Resolve(frame.ids[frame.index])
end
function V.Refresh()
    local frame = V.frame; local action = current(frame)
    frame.form:SetShown(action ~= nil); frame.complete:SetShown(action == nil)
    frame.progress:SetText(math.min(frame.index, #frame.ids) .. " / " .. #frame.ids)
    frame.previous:SetEnabled(frame.index > 1); frame.skip:SetEnabled(action ~= nil)
    if not action then return end
    frame.id = action.id
    local record, seen = R.Record(action.id), R.Observation(action.id)
    frame.title:SetText(action.name .. "  /" .. action.command)
    frame.icon:SetIcon(action.icon)
    frame.iconReviewed:SetChecked(record.iconReviewed == true)
    local commands = {}; for _, alias in ipairs(action.clientAliases or action.aliases) do commands[#commands + 1] = "/" .. alias end
    frame.commands:SetText("Commands: " .. table.concat(commands, " · "))
    frame.reference:SetText((IC.Emotes.KindInfo[action.kind] or IC.Emotes.KindInfo.unknown).help .. " These reference labels do not determine your review.")
    frame.choice:SetValue(record.choice or "pending"); frame.sound:SetValue(seen.sound or "unknown"); frame.animation:SetValue(seen.animation or "unknown")
    frame.duplicate:SetText(record.duplicateOf and record.duplicateOf:gsub("^emote:", "/") or "")
    frame.notes:SetText(record.notes or ""); frame.notice:SetText("Try is the only control here that performs an emote. Mark what you actually see and hear.")
end
local function advance() V.frame.index = V.frame.index + 1; V.Refresh() end
function V.Save(choice)
    local frame = V.frame; local action = current(frame); if not action then return end
    local ok, reason = R.Save(action.id, choice or frame.choice.value, frame.sound.value, frame.animation.value,
        frame.duplicate:GetText(), frame.notes:GetText(), frame.iconReviewed:GetChecked())
    if not ok then frame.notice:SetText(reason); return end
    E.RefreshEmotes(); advance()
end
local function queue(mode, selected)
    local frame = V.frame; frame.ids, frame.index = R.Queue(mode), 1
    local selectedAction = selected and A.Resolve(selected)
    for i, id in ipairs(frame.ids) do
        if id == selected or (selectedAction and A.Resolve(id).payload == selectedAction.payload) then frame.index = i; break end
    end
    V.Refresh()
end
function V.Open(selected)
    if IC.InCombat() then IC.Print("Review emotes after combat."); return end
    E.Open("Emotes")
    local frame = V.frame
    if not frame then
        frame = U.Panel(E.frame, 780, 550, U.Colors.bg, "InCharacterEmoteReview"); V.frame = frame
        frame:SetPoint("CENTER"); frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:EnableMouse(true)
        U.Heading(frame, "Check emotes · one at a time", 14, -12, 600)
        U.Button(frame, "Close", 686, -8, 80, function() frame:Hide() end)
        frame.mode = U.Dropdown(frame, 14, -44, 470, {
            { value = "kept", label = "Everyday selection · start here" }, { value = "pending", label = "All commands still to review" },
            { value = "all", label = "All recognized commands" }, { value = "icons", label = "Icons still to review" },
        }, function(mode) queue(mode) end)
        frame.progress = U.Label(frame, "", 610, -50, 150)
        frame.complete = U.Muted(frame, "This pass is complete. Choose another review set, or close and try your quick actions.", 24, -110, 720)
        frame.form = CreateFrame("Frame", nil, frame); frame.form:SetSize(752, 430); frame.form:SetPoint("TOPLEFT", 14, -84)
        local form = frame.form
        frame.icon = U.IconButton(form, 64, false); frame.icon:SetPoint("TOPLEFT", 0, -4)
        frame.icon:SetScript("OnClick", function()
            local action = current(frame); if not action then return end
            local profile, id = frame.profile, action.id
            E.PickIcon(action.icon, function(icon)
                if profile ~= IC.Profile() then return end
                A.SetIcon(id, icon)
                if frame.id == id then frame.icon:SetIcon(icon); frame.iconReviewed:SetChecked(true) end
            end)
        end)
        frame.title = U.Heading(form, "", 80, -6, 470)
        frame.title:SetWordWrap(false)
        frame.commands = U.Muted(form, "", 80, -34, 470)
        frame.try = U.Button(form, "Try it now", 566, -8, 180, function()
            local action = current(frame); if not action then return end
            local ok = A.Dispatch(action.id)
            frame.notice:SetText(ok and ("Submitted /" .. action.command .. ". Observe the result; nothing has been marked automatically.") or "Client did not accept this request. See chat.")
        end, "accent")
        frame.iconReviewed = U.Check(form, "Icon matches (click artwork to change)", 80, -62, function() end)
        frame.iconReviewed.caption:SetWidth(420)
        U.Muted(form, "Keep it in everyday use?", 0, -106)
        frame.choice = U.Dropdown(form, 0, -126, 238, {
            { value = "pending", label = "Still deciding" }, { value = "keep", label = "Keep in everyday use" },
            { value = "hide", label = "Hide from everyday use" }, { value = "duplicate", label = "Duplicate / not worth another button" },
            { value = "text", label = "Text only · hide from everyday use" },
        })
        U.Muted(form, "Sound on this character", 254, -106)
        frame.sound = U.Dropdown(form, 254, -126, 238, {
            { value = "unknown", label = "Not checked" }, { value = "self", label = "I heard it" },
            { value = "nearby", label = "Another player heard it" }, { value = "silent", label = "No sound heard" },
        })
        U.Muted(form, "Animation on this character", 508, -106)
        frame.animation = U.Dropdown(form, 508, -126, 238, {
            { value = "unknown", label = "Not checked" }, { value = "yes", label = "Visible animation" }, { value = "no", label = "No animation" },
        })
        U.Muted(form, "Duplicate of /command (optional; no automatic redirection)", 0, -166, 470)
        frame.duplicate = U.Input(form, 0, -184, 470)
        U.Muted(form, "Your notes", 0, -220)
        frame.notes = U.TextArea(form, 0, -240, 746, 66)
        frame.reference = U.Muted(form, "", 0, -316, 746)
        frame.notice = U.Muted(form, "", 0, -364, 746)
        frame.previous = U.Button(frame, "< Previous", 14, -508, 120, function() frame.index = math.max(1, frame.index - 1); V.Refresh() end)
        U.Button(form, "Keep & next", 126, -424, 156, function() V.Save("keep") end, "accent")
        U.Button(form, "Hide & next", 292, -424, 156, function() V.Save("hide") end)
        U.Button(form, "Save & next", 458, -424, 156, function() V.Save() end)
        frame.skip = U.Button(frame, "Skip >", 646, -508, 120, advance)
        table.insert(UISpecialFrames, "InCharacterEmoteReview")
    end
    frame.profile = IC.Profile(); frame.mode:SetValue(selected and "all" or "kept")
    queue(frame.mode.value, selected); frame:Show(); frame:Raise()
end
