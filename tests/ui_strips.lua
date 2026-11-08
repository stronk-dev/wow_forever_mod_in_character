return function(test, eq, page)
    local function enableAll(IC, env)
        for i, action in ipairs(IC.Emotes.list) do
            env["EMOTE" .. i .. "_TOKEN"], env["EMOTE" .. i .. "_CMD1"] = action.payload, "/" .. action.command
        end
        IC.Emotes.Validate(); IC.Profile().emoteScope = "all"
    end
    test("default emote strip is one compact row with hidden names background and editing handles", function(IC, Stub)
        local frame = IC.Bars.frames[1]; assert(IC.Bars.IsStrip(frame.config)); assert(frame:GetHeight() <= 44)
        assert(not frame.header:IsShown() and not frame.moveHandle:IsShown() and not frame.resizeHandle:IsShown())
        eq(frame.backdropColor[4], 0); eq(frame.mouseEnabled, false)
        for _, slot in ipairs(frame.buttons) do if slot:IsShown() then
            assert(not slot.caption:IsShown()); eq(slot:GetHeight(), 36); slot:Fire("OnEnter"); slot:Fire("OnLeave")
        end end
        assert(Stub.KeyDown("W")); eq(#Stub.emotes + #Stub.sends, 0)
    end)
    test("Arrange exposes width bounds and native resize updates fitting live while keeping its left edge", function(IC, Stub)
        local frame = IC.Bars.frames[1]; IC.Slash("arrange")
        assert(IC.Bars.editing and frame.resizeHandle:IsShown() and frame.moveHandle:IsShown())
        assert(frame.backdropColor[4] > 0); local left = frame:GetLeft()
        frame.resizeHandle:Fire("OnMouseDown", "LeftButton"); eq(frame.sizing, "RIGHT")
        frame:SetWidth(80); eq(frame:GetLeft(), left); eq(frame.config.stripWidth, 80)
        local g = IC.Presentation.StripGeometry(frame.config, #IC.Presentation.BarActions(frame.config), 1920)
        eq(frame.buttons[1]:GetWidth(), g.size); assert(g.size < frame.config.size)
        frame.resizeHandle:Fire("OnDragStop"); eq(frame.manipulation, nil); eq(frame.sizing, nil); eq(frame:GetLeft(), left)
        Stub.Button(IC.Bars.arrange, "Done"):Click(); assert(not frame.resizeHandle:IsShown() and not IC.Bars.editing)
        eq(#Stub.emotes + #Stub.sends, 0); assert(Stub.KeyDown("W"))
    end)
    test("native move handles and shift-drag save placement without executing an emote", function(IC, Stub)
        local frame = IC.Bars.frames[1]; IC.Bars.SetEditing(true)
        frame.moveHandle:Fire("OnMouseDown", "LeftButton"); assert(frame.moving)
        frame:SetPoint("CENTER", 140, -80); frame.moveHandle:Fire("OnMouseUp", "LeftButton")
        eq(frame.config.x, 140); eq(frame.config.y, -80); assert(not frame.moving)
        IC.Bars.SetEditing(false); Stub.modifiers.shift = true
        frame.buttons[1]:Fire("OnDragStart"); assert(frame.moving)
        frame.buttons[1]:Fire("OnDragStop"); frame.buttons[1]:Click(); eq(#Stub.emotes, 0)
        Stub.modifiers.shift = nil; Stub.Tick(0.2); frame.buttons[1]:Click(); eq(#Stub.emotes, 1)
    end)
    test("combined category checkboxes drive the actual strip and hiding one item still works", function(IC, Stub, env)
        enableAll(IC, env); local p = page(IC, "Layouts"); p.bSource:Choose("categories")
        assert(p.bCategories:IsShown()); assert(p.bStripWidth:IsShown()); assert(not p.bColumns:IsShown())
        for _, check in pairs(p.bCategoryChecks) do check:SetChecked(false); check:Click() end
        local bar = IC.Layout().bars[1]; eq(#IC.Presentation.BarActions(bar), 0)
        p.bCategoryChecks.Social:SetChecked(true); p.bCategoryChecks.Social:Click()
        local expected = #IC.Actions.List("Social"); eq(#IC.Presentation.BarActions(bar), expected)
        p.bCategoryChecks.Reactions:SetChecked(true); p.bCategoryChecks.Reactions:Click()
        local seen = {}; for _, action in ipairs(IC.Presentation.BarActions(bar)) do assert(not seen[action.payload]); seen[action.payload] = true end
        IC.LayoutUI.Open("bar", 1)
        for _, row in ipairs(IC.LayoutUI.frame.rows) do if row:IsShown() and row.action.id == "emote:wave" then row.check:SetChecked(false); row.check:Click(); break end end
        for _, action in ipairs(IC.Presentation.BarActions(bar)) do assert(action.id ~= "emote:wave") end
        eq(#Stub.emotes + #Stub.sends, 0)
    end)
    test("readable strip overflow pages reach every enabled emote in a fixed horizontal region", function(IC, Stub, env)
        enableAll(IC, env); local p = page(IC, "Layouts"); p.bSource:Choose("categories"); p.bStripWidth:SetValue(160)
        local frame, seen = IC.Bars.frames[1], {}; assert(frame.next:IsShown()); eq(frame:GetWidth(), 160)
        local pages = math.ceil(#IC.Presentation.BarActions(frame.config) / IC.Bars.Capacity(frame.config))
        for _ = 1, pages do
            for _, slot in ipairs(frame.buttons) do if slot:IsShown() then seen[slot.action.id] = true; assert(slot:GetWidth() >= 20) end end
            frame.next:Click(); eq(frame:GetWidth(), 160)
        end
        local count = 0; for _ in pairs(seen) do count = count + 1 end
        eq(count, #IC.Presentation.BarActions(frame.config)); eq(#Stub.emotes + #Stub.sends, 0)
    end)
    test("hotbar row and maximum size controls reflow buttons and classic grids remain selectable", function(IC, Stub, env)
        enableAll(IC, env); local p = page(IC, "Layouts"); p.bSource:Choose("categories")
        p.bStripWidth:SetValue(300); p.bStripRows:SetValue(2); p.bSize:SetValue(32)
        local frame = IC.Bars.frames[1]; local g = IC.Presentation.StripGeometry(frame.config, #IC.Presentation.BarActions(frame.config), 1920)
        eq(frame:GetHeight(), g.height); assert(frame.buttons[g.columns + 1].y < frame.buttons[1].y)
        p.bStyle:Choose("icons"); assert(p.bColumns:IsShown()); assert(not p.bStripWidth:IsShown()); assert(frame.header:IsShown())
        p.bStyle:Choose("strip"); assert(not frame.header:IsShown()); eq(frame.config.stripRows, 2)
        eq(#Stub.emotes + #Stub.sends, 0)
    end)
    test("new hotbar and Arrange setup buttons expose compact controls without changing RP bars", function(IC, Stub)
        local p = page(IC, "Layouts"); p.addStrip:Click(); local frame = IC.Bars.frames[3]
        assert(IC.Bars.IsStrip(frame.config)); eq(frame.config.source, "categories"); assert(p.bCategories:IsShown())
        assert(IC.Layout().bars[2].catalog and IC.Layout().bars[2].buttonStyle == "text")
        page(IC, "Home").favArrange:Click(); assert(IC.Bars.editing); assert(not IC.Editor.frame:IsShown())
        IC.Bars.arrange:Hide(); assert(not IC.Bars.editing); eq(#Stub.emotes + #Stub.sends, 0)
    end)
    test("locking hiding profile changes and combat stop native drag and release all editing input", function(IC, Stub, env, event)
        local frame = IC.Bars.frames[1]; IC.Bars.SetEditing(true); frame.config.locked = true; IC.Bars.Refresh()
        assert(not frame.moveHandle:IsShown()); frame.resizeHandle:Fire("OnMouseDown", "LeftButton"); eq(frame.manipulation, nil)
        frame.config.locked = false; IC.Bars.Refresh(); frame.resizeHandle:Fire("OnMouseDown", "LeftButton"); assert(frame.manipulation)
        Stub.combat = true; event("PLAYER_REGEN_DISABLED"); eq(frame.manipulation, nil); assert(not IC.Bars.editing)
        assert(not frame.resizeHandle:IsShown()); assert(Stub.KeyDown("W")); eq(#Stub.emotes + #Stub.sends, 0)
        Stub.combat = false; event("PLAYER_REGEN_ENABLED"); IC.Bars.SetEditing(true)
        frame.resizeHandle:Fire("OnMouseDown", "LeftButton"); frame.config.hidden = true; IC.Refresh(); eq(frame.manipulation, nil)
        frame.config.hidden = false; IC.Refresh(); frame.resizeHandle:Fire("OnMouseDown", "LeftButton")
        IC.Profiles.SetLayoutScope("account"); eq(frame.manipulation, nil); eq(#Stub.emotes + #Stub.sends, 0)
    end)
end
