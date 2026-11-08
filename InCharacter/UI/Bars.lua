local _, IC = ...
IC.Bars = { frames = {} }
local B = IC.Bars
function B.Refresh()
    if IC.InCombat() then IC.refreshPending = true; return end
    for _, frame in ipairs(B.frames) do frame:Hide() end
    for index, config in ipairs(IC.Layout().bars) do
        local frame = B.frames[index]
        if not frame then
            frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            frame:SetBackdropColor(0.06, 0.06, 0.08, 0.9)
            frame:SetClampedToScreen(true)
            frame:SetMovable(true)
            frame:EnableMouse(true)
            frame:RegisterForDrag("LeftButton")
            frame.buttons = {}
            frame.header = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
            frame.header:SetPoint("TOPLEFT", 2, -2)
            frame.header:SetScript("OnClick", function(self)
                if IC.InCombat() then return end
                self:GetParent().config.collapsed = not self:GetParent().config.collapsed
                B.Refresh()
            end)
            frame:SetScript("OnDragStart", function(self)
                if not self.config.locked and not IC.InCombat() then self:StartMoving() end
            end)
            frame:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()
                local x, y = self:GetCenter()
                local px, py = UIParent:GetCenter()
                self.config.x, self.config.y = x - px, y - py
            end)
            -- Dragging the title is convenient even when the expanded bar is full of buttons.
            frame.header:RegisterForDrag("LeftButton")
            frame.header:SetScript("OnDragStart", function(self) self:GetParent():GetScript("OnDragStart")(self:GetParent()) end)
            frame.header:SetScript("OnDragStop", function(self) self:GetParent():GetScript("OnDragStop")(self:GetParent()) end)
            B.frames[index] = frame
        end
        frame.config = config
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", config.x, config.y)
        local actions = IC.Actions.List(config.source)
        local pages = math.max(1, math.ceil(#actions / 12))
        config.page = math.max(1, math.min(config.page or 1, pages))
        local count = math.min(12, math.max(0, #actions - (config.page - 1) * 12))
        local size = math.max(24, math.min(64, tonumber(config.size) or 36))
        frame:SetSize(config.collapsed and 150 or (config.vertical and 150 or math.max(150, count * (size + 4) + 8)),
            config.collapsed and 26 or (config.vertical and count * (size + 4) + 32 or size + 36))
        frame.header:SetSize(frame:GetWidth() - 4, 22)
        frame.header:SetText((config.collapsed and "+ " or "- ") .. config.name .. (pages > 1 and " " .. config.page .. "/" .. pages or ""))
        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel", function(_, delta)
            if IC.InCombat() then return end
            config.page = math.max(1, math.min(pages, config.page - delta)); B.Refresh()
        end)
        for _, button in ipairs(frame.buttons) do button:Hide() end
        if not config.collapsed then
            for n = 1, count do
                local action = actions[(config.page - 1) * 12 + n]
                local button = frame.buttons[n]
                if not button then
                    button = CreateFrame("Button", nil, frame)
                    button.icon = button:CreateTexture(nil, "ARTWORK")
                    button.icon:SetAllPoints()
                    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
                    button:SetScript("OnClick", function(self) IC.Actions.Dispatch(self.action) end)
                    button:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetText(self.action.label)
                        GameTooltip:AddLine(self.action.type == "pool" and ("Pool: " .. self.action.payload) or ("Token: " .. self.action.payload), 1, 1, 1)
                        if self.action.type == "emote" and not self.action.verified then GameTooltip:AddLine("Unverified; disabled on this client", 1, 0.5, 0.3) end
                        GameTooltip:Show()
                    end)
                    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
                    frame.buttons[n] = button
                end
                button.action = action
                button:SetSize(size, size)
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", 4 + (config.vertical and 0 or (n - 1) * (size + 4)), -28 - (config.vertical and (n - 1) * (size + 4) or 0))
                button.icon:SetTexture(action.icon)
                button:Show()
            end
        end
        frame:SetShown(not config.hidden)
    end
end
