local _, IC = ...
local unpack = unpack or table.unpack
-- Cascading emote menu used by the launcher button and the "Emote menu at cursor" binding.
-- Left-click uses an entry; right-click pins/unpins it as a favorite.
IC.Menu = { levels = {} }
local Menu, U = IC.Menu, IC.UI
local C = U.Colors
local ROW, VISIBLE, WIDTH = 22, 22, 230

local function row(level, index)
    local button = level.rows[index]
    if button then return button end
    button = CreateFrame("Button", nil, level, "BackdropTemplate")
    button:SetSize(WIDTH - 8, ROW); button:SetPoint("TOPLEFT", 4, -4 - (index - 1) * ROW)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button.bg = button:CreateTexture(nil, "BACKGROUND"); button.bg:SetAllPoints(); button.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.bg:SetVertexColor(unpack(C.hover)); button.bg:Hide()
    button.icon = button:CreateTexture(nil, "ARTWORK"); button.icon:SetSize(18, 18); button.icon:SetPoint("LEFT", 2, 0)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); button.label:SetPoint("LEFT", 24, 0)
    button.label:SetPoint("RIGHT", -70, 0); button.label:SetJustifyH("LEFT"); button.label:SetWordWrap(false)
    button.right = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); button.right:SetPoint("RIGHT", -4, 0)
    button:SetScript("OnEnter", function(self)
        if self.entry.kind == "header" then Menu.CloseFrom(level.depth + 1); return end
        self.bg:Show()
        if self.entry.children then Menu.OpenLevel(level.depth + 1, self.entry, self)
        else Menu.CloseFrom(level.depth + 1) end
        local action = self.entry.action
        if action then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(action.name or action.label, 1, 1, 1)
            if action.type == "emote" then
                local badge, info = IC.Emotes.Badge(action)
                GameTooltip:AddLine("/" .. action.command .. "   " .. badge, 0.8, 0.8, 0.8)
                GameTooltip:AddLine(info.help, 0.75, 0.75, 0.75, true)
            else
                GameTooltip:AddLine(IC.Actions.Description(action), 0.75, 0.75, 0.75, true)
            end
            GameTooltip:AddLine((IC.Actions.IsFavorite(action.id) and "Right-click: unpin from" or "Right-click: pin to") .. " favorites", 0.5, 0.8, 0.5)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function(self) self.bg:Hide(); GameTooltip:Hide() end)
    button:SetScript("OnClick", function(self, mouse)
        local entry = self.entry
        if entry.action and mouse == "RightButton" then
            IC.Actions.Favorite(entry.action.id); Menu.Rebuild(); return
        end
        if mouse ~= "LeftButton" or entry.children or entry.kind == "header" then return end
        if entry.back then entry.run(); return end
        Menu.Close()
        if entry.action then IC.Actions.Dispatch(entry.action) elseif entry.run then entry.run() end
    end)
    level.rows[index] = button
    return button
end

local function levelFrame(depth)
    local level = Menu.levels[depth]
    if level then return level end
    level = CreateFrame("Frame", depth == 1 and "InCharacterMenu" or nil, Menu.catcher, "BackdropTemplate")
    U.Backdrop(level, C.bg, C.border); level:SetClampedToScreen(true); level:EnableMouse(true)
    level:EnableMouseWheel(true); level.depth, level.rows, level.offset = depth, {}, 0
    level:SetScript("OnMouseWheel", function(self, delta)
        self.offset = math.max(0, math.min(#self.entries - VISIBLE, self.offset - delta))
        Menu.CloseFrom(self.depth + 1); Menu.RenderLevel(self)
    end)
    Menu.levels[depth] = level
    return level
end

function Menu.RenderLevel(level)
    local count = math.min(#level.entries, VISIBLE)
    for i, button in ipairs(level.rows) do if i > count then button:Hide() end end
    for i = 1, count do
        local entry = level.entries[i + level.offset]
        local button = row(level, i)
        button.entry = entry
        button.icon:SetShown(entry.icon ~= nil)
        if entry.icon then U.SetIcon(button.icon, entry.icon, IC.Icons[1]) end
        if entry.kind == "header" then
            button.label:SetText("|cffd6b56c" .. entry.label .. "|r"); button.right:SetText("")
        else
            local star = entry.action and IC.Actions.IsFavorite(entry.action.id) and "|cffffd100*|r " or ""
            button.label:SetText(star .. entry.label)
            button.right:SetText(entry.children and ("|cff999999" .. #entry.children .. "|r  >") or (entry.right or ""))
        end
        button:Show()
    end
    level.more = level.more or level:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    level.more:SetPoint("BOTTOMRIGHT", -6, 2)
    level.more:SetText(#level.entries > VISIBLE and "|cff999999scroll for more|r" or "")
    level:SetSize(WIDTH, count * ROW + 8 + (#level.entries > VISIBLE and 12 or 0))
end

function Menu.CloseFrom(depth)
    for d = depth, #Menu.levels do Menu.levels[d]:Hide() end
end
function Menu.OpenLevel(depth, entry, anchor)
    local level = levelFrame(depth)
    if level:IsShown() and level.source == entry then return end
    Menu.CloseFrom(depth)
    level.source, level.entries, level.offset = entry, { { label = "< Back", run = function() Menu.CloseFrom(depth) end, back = true } }, 0
    for _, child in ipairs(entry.children) do level.entries[#level.entries + 1] = child end
    Menu.RenderLevel(level)
    level:ClearAllPoints()
    local right = anchor:GetRight()
    if right and right + WIDTH + 8 > UIParent:GetRight() then level:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -4, 4)
    else level:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 4, 4) end
    level:Show()
end

local function actionEntry(action)
    if action.type == "submenu" then
        local entry = { label = action.label, icon = action.icon, children = {} }
        for _, child in ipairs(action.children) do entry.children[#entry.children + 1] = actionEntry(child) end
        return entry
    end
    local right = action.type == "emote" and IC.Emotes.Badge(action) or (action.type == "line" and "|cffd6b56cmessage|r" or "|cffd6b56cpool|r")
    return { label = action.name or action.label, icon = action.icon, action = action, right = right }
end
function Menu.Entries()
    local entries, info = {}, IC.Emotes.CategoryInfo
    entries[1] = { kind = "header", label = "Favorites" }
    local favorites = IC.WheelModel.Categories()[1].items
    for i = 1, math.min(#favorites, 6) do entries[#entries + 1] = actionEntry(favorites[i]) end
    if #favorites == 0 then entries[#entries + 1] = { kind = "header", label = "  right-click any emote to pin it" } end
    if #favorites > 6 then
        local more = { label = "More favorites", icon = info.Favorites.icon, children = {} }
        for i = 7, #favorites do more.children[#more.children + 1] = actionEntry(favorites[i]) end
        entries[#entries + 1] = more
    end
    entries[#entries + 1] = { kind = "header", label = "Emotes" }
    for _, id in ipairs(IC.Emotes.categories) do
        local category = { label = info[id].label, icon = info[id].icon, children = {} }
        for _, action in ipairs(IC.Actions.List(id)) do
            if action.verified then category.children[#category.children + 1] = actionEntry(action) end
        end
        if #category.children > 0 then entries[#entries + 1] = category end
    end
    local all = { label = info.all.label, icon = info.all.icon, children = {} }
    for _, action in ipairs(IC.Emotes.list) do
        if action.verified and IC.Emotes.Matches(action, IC.Profile().emoteFilter) then all.children[#all.children + 1] = actionEntry(IC.Actions.Resolve(action.id)) end
    end
    entries[#entries + 1] = all
    entries[#entries + 1] = { kind = "header", label = "Roleplay" }
    for _, group in ipairs(IC.Actions.RoleplayGroups()) do entries[#entries + 1] = actionEntry(group) end
    entries[#entries + 1] = { label = "Radial wheel", icon = IC.AddonIcon, run = function() IC.Wheel.Open(false) end }
    entries[#entries + 1] = { label = "Open In Character...", icon = "Interface\\Icons\\INV_Misc_Book_09", run = function() IC.Editor.Open() end }
    return entries
end

function Menu.Create()
    local catcher = CreateFrame("Frame", "InCharacterMenuCatcher", UIParent)
    Menu.catcher = catcher
    catcher:SetAllPoints(UIParent); catcher:SetFrameStrata("FULLSCREEN_DIALOG"); catcher:EnableMouse(true); catcher:Hide()
    catcher:SetScript("OnMouseDown", function() Menu.Close() end)
    -- Esc hides only the catcher; make sure flyouts don't reappear on the next open.
    catcher:SetScript("OnHide", function() Menu.CloseFrom(1); GameTooltip:Hide() end)
    table.insert(UISpecialFrames, "InCharacterMenuCatcher")
end
function Menu.Close() if Menu.catcher then Menu.catcher:Hide(); Menu.CloseFrom(1) end; GameTooltip:Hide() end
function Menu.IsOpen() return Menu.catcher ~= nil and Menu.catcher:IsShown() end
function Menu.Rebuild()
    if not Menu.IsOpen() then return end
    -- Re-render in place so pinning from a flyout keeps it open.
    local root = levelFrame(1)
    root.entries = Menu.Entries(); root.offset = math.min(root.offset, math.max(0, #root.entries - VISIBLE))
    Menu.RenderLevel(root)
    for depth = 2, #Menu.levels do if Menu.levels[depth]:IsShown() then Menu.RenderLevel(Menu.levels[depth]) end end
end
-- anchor: a frame to open beside, or nil to open at the cursor.
function Menu.Open(anchor)
    if not IC.db then return end
    if not Menu.catcher then Menu.Create() end
    if Menu.IsOpen() then Menu.Close(); return end
    Menu.catcher:Show()
    local root = levelFrame(1)
    root.source, root.entries, root.offset = nil, Menu.Entries(), 0
    Menu.RenderLevel(root)
    root:ClearAllPoints()
    if anchor then
        root:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    else
        local x, y = GetCursorPosition(); local scale = UIParent:GetEffectiveScale()
        root:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    end
    root:Show()
end
function Menu.OpenAtCursor() Menu.Open(nil) end
