local _, IC = ...
local E, U, P, A = IC.Editor, IC.UI, IC.Presentation, IC.Actions
IC.LayoutUI = {}
local L = IC.LayoutUI

local function flatten(nodes, result, depth)
    result = result or {}; depth = depth or 0
    for _, node in ipairs(nodes) do
        local copy = IC.Copy(node); copy.depth = depth; result[#result + 1] = copy
        if node.type == "submenu" then flatten(node.children or node.items or {}, result, depth + 1) end
    end
    return result
end
local function config(frame)
    if frame.profile ~= IC.Profile() or frame.layout ~= IC.Layout() then frame:Hide(); return nil end
    if frame.kind == "bar" then return frame.layout.bars[frame.barIndex] end
    return frame.profile[frame.kind]
end
function L.Items(frame)
    if frame.kind == "bar" then
        local result = {}; for _, action in ipairs(P.BarActions(config(frame), true)) do if not IC.Personas or IC.Personas.ActionAllowed(action) then result[#result + 1] = action end end
        return result
    end
    if frame.source == "categories" then
        local result = {}
        for _, id in ipairs({ "Favorites", "Combat", "Social", "Reactions", "Idle", "Voice/Fun", "Roleplay", "all" }) do
            if id ~= "all" or frame.kind == "menu" then
                local info = IC.Emotes.CategoryInfo[id]
                result[#result + 1] = { id = id, label = info.label, icon = info.icon, isCategory = true }
            end
        end
        return result
    end
    if frame.source == "Roleplay" then return flatten(A.RoleplayGroups()) end
    return A.List(frame.source == "Favorites" and "favorites" or frame.source, true)
end
function L.Refresh()
    local frame = L.frame; if not frame then return end
    local settings = config(frame); if not settings then return end
    local all, shown, query = L.Items(frame), {}, IC.Trim(frame.search:GetText()):lower()
    for _, action in ipairs(all) do
        local name = action.name or action.label
        if query == "" or name:lower():find(query, 1, true) or (action.command and action.command:find(query, 1, true)) then shown[#shown + 1] = action end
    end
    frame.items, frame.allItems = shown, all
    for _, row in ipairs(frame.rows) do row:Hide() end
    local hiddenCount = 0
    for _, action in ipairs(all) do
        if (action.isCategory and settings.hiddenCategories or settings.hiddenActions)[action.id]
            or (frame.kind == "bar" and not P.BarEmoteIncluded(action, settings)) then hiddenCount = hiddenCount + 1 end
    end
    frame.count:SetText((#all - hiddenCount) .. " enabled / " .. #all .. " source entries · pages / preset tabs may show a subset")
    if frame.kind == "bar" then frame.emoteChoice:SetValue(settings.emoteView) end
    for index, action in ipairs(shown) do
        local row = frame.rows[index]
        if not row then
            row = CreateFrame("Frame", nil, frame.list.content); row:SetSize(708, 42)
            row.check = U.Check(row, "", 0, -8, function(value)
                local cfg = config(frame); if not cfg then return end
                local map = row.action.isCategory and cfg.hiddenCategories or cfg.hiddenActions
                if frame.kind == "bar" and row.action.type == "emote" then
                    if not row.action.verified then return end
                    cfg.includedActions[row.action.id] = value or nil
                end
                map[row.action.id] = not value or nil; cfg.page = 1; IC.Changed(); L.Refresh()
            end)
            row.check.caption:SetWidth(440)
            row.icon = U.IconButton(row, 30, false); row.icon:SetPoint("TOPLEFT", 490, -5)
            row.icon:SetScript("OnClick", function()
                if row.action.isCategory or row.action.type == "submenu" then return end
                local profile, id = frame.profile, row.action.id
                E.PickIcon(row.action.icon, function(icon) if profile == IC.Profile() then A.SetIcon(id, icon); L.Refresh() end end)
            end)
            row.reset = U.Button(row, "Reset icon", 534, -8, 104, function()
                if config(frame) then A.SetIcon(row.action.id, nil); L.Refresh() end
            end)
            frame.rows[index] = row
        end
        row.action = action; row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -(index - 1) * 42)
        local map = action.isCategory and settings.hiddenCategories or settings.hiddenActions
        row.check:SetChecked(not map[action.id] and (frame.kind ~= "bar" or P.BarEmoteIncluded(action, settings)))
        local unavailable = action.type == "emote" and not action.verified
        local filtered = frame.kind == "bar" and not unavailable and not P.BarEmoteIncluded(action, settings)
        row.check:SetEnabled(not (frame.kind == "bar" and unavailable))
        row.check.caption:SetText(string.rep("  ", action.depth or 0) .. (action.name or action.label) .. (action.command and ("  /" .. action.command) or "") .. (unavailable and " (not on this client)" or (filtered and " (filtered · check to include on this bar)" or "")))
        row.icon:SetIcon(action.icon); row.icon:SetEnabled(not action.isCategory and action.type ~= "submenu")
        row.reset:SetShown(not action.isCategory and action.type ~= "submenu"); row:Show()
    end
    frame.list:SetContentHeight(#shown * 42)
end
function L.Open(kind, index)
    if IC.InCombat() then IC.Print("Edit layout items after combat."); return end
    E.Open("Layouts", index)
    local frame = L.frame
    if not frame then
        frame = U.Panel(E.frame, 760, 530, U.Colors.bg, "InCharacterLayoutItems"); L.frame = frame
        frame:SetPoint("CENTER"); frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:EnableMouse(true)
        frame.title = U.Heading(frame, "", 14, -12, 630)
        U.Button(frame, "Close", 666, -10, 80, function() frame:Hide() end)
        local options = { { value = "categories", label = "Categories: show / hide" } }
        for _, id in ipairs({ "Favorites", "Combat", "Social", "Reactions", "Idle", "Voice/Fun", "Roleplay", "all" }) do
            options[#options + 1] = { value = id, label = IC.Emotes.CategoryInfo[id].label }
        end
        frame.sourceChoice = U.Dropdown(frame, 14, -48, 320, options, function(value) frame.source = value; frame.list:ScrollTo(0); L.Refresh() end)
        frame.emoteChoice = U.Dropdown(frame, 14, -48, 320, {
            { value = "profile", label = "Emotes: my profile choices" }, { value = "all", label = "Emotes: all recognized commands" }, { value = "kept", label = "Emotes: explicitly kept only" },
        }, function(value) local cfg = config(frame); if cfg then cfg.emoteView = value; cfg.page = 1; IC.Changed(); L.Refresh() end end)
        frame.search = U.Input(frame, 350, -48, 396)
        frame.search:SetScript("OnTextChanged", function() if frame.profile then L.Refresh() end end)
        frame.count = U.Muted(frame, "", 14, -84, 732)
        frame.list = U.Scroll(frame, 14, -108, 732, 330); frame.rows = {}
        local function setAll(hidden)
            local settings = config(frame); if not settings then return end
            for _, action in ipairs(frame.items) do
                (action.isCategory and settings.hiddenCategories or settings.hiddenActions)[action.id] = hidden or nil
                if frame.kind == "bar" and action.type == "emote" and action.verified then settings.includedActions[action.id] = not hidden or nil end
            end
            settings.page = 1; IC.Changed(); L.Refresh()
        end
        U.Button(frame, "Show listed", 14, -452, 140, function() setAll(false) end)
        U.Button(frame, "Hide listed", 164, -452, 140, function() setAll(true) end)
        U.Muted(frame, "Click an icon to replace it. Icons are shared across layouts; visibility affects only this bar, quick actions or menu. Nothing here sends chat.", 14, -492, 732)
        table.insert(UISpecialFrames, "InCharacterLayoutItems")
    end
    frame.kind, frame.barIndex, frame.profile, frame.layout = kind, index or E.barIndex, IC.Profile(), IC.Layout()
    frame.source = "categories"; frame.search:SetText("")
    frame.sourceChoice:SetShown(kind ~= "bar"); frame.sourceChoice:SetValue(frame.source); frame.emoteChoice:SetShown(kind == "bar")
    local settings = config(frame); if not settings then return end
    frame.title:SetText(kind == "bar" and ("Edit items · " .. settings.name) or ("Edit " .. (kind == "wheel" and "quick actions" or kind) .. " · categories & items"))
    frame.list:ScrollTo(0); L.Refresh(); frame:Show(); frame:Raise()
end
