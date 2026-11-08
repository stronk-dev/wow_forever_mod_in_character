return function(test, eq, page, point, pointAt)
    local function check(row, value) row.check:SetChecked(value); row.check:Click() end
    local function item(frame, id)
        for _, row in ipairs(frame.rows) do if row:IsShown() and row.action.id == id then return row end end
        error("Missing layout item: " .. id)
    end
    local function has(actions, id) for _, action in ipairs(actions) do if action.id == id then return true end end end
    local function wheelClick(IC, Stub, id)
        for _ = 1, IC.WheelModel.Pages(IC.Wheel.Current()) do
            for i, action in ipairs(IC.Wheel.items) do
                if action.id == id then pointAt(Stub, IC, IC.Wheel.outer[i]); IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton"); return end
            end
            IC.Wheel.next:Click()
        end
        error("Missing wheel item " .. id)
    end
    test("per-bar item editor hides and unhides one emote without affecting another bar", function(IC, Stub)
        local bars = IC.Layout().bars; bars[1].source = "Social"; bars[2] = IC.Defaults.Bar(2); bars[2].source = "Social"; IC.Refresh()
        IC.LayoutUI.Open("bar", 1); local frame = IC.LayoutUI.frame
        check(item(frame, "emote:wave"), false)
        assert(not has(IC.Presentation.BarActions(bars[1]), "emote:wave")); assert(has(IC.Presentation.BarActions(bars[2]), "emote:wave"))
        assert(item(frame, "emote:wave")); frame.search:SetText("wave"); eq(#frame.items, 1)
        check(item(frame, "emote:wave"), true); assert(has(IC.Presentation.BarActions(bars[1]), "emote:wave"))
        eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("wheel and menu category visibility is independent and categories can be restored", function(IC, Stub)
        IC.LayoutUI.Open("wheel"); local frame = IC.LayoutUI.frame
        check(item(frame, "Social"), false); IC.Wheel.Open(false)
        assert(not has(IC.Wheel.categories, "Social")); assert(has(IC.Menu.Entries(), "Social")); IC.Wheel.Close()
        IC.LayoutUI.Open("wheel"); check(item(frame, "Social"), true); IC.Wheel.Open(false)
        assert(has(IC.Wheel.categories, "Social")); eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("wheel action visibility filters favorites and categories while keeping restoration choices", function(IC, Stub)
        IC.LayoutUI.Open("wheel"); local frame = IC.LayoutUI.frame; frame.sourceChoice:Choose("Social")
        check(item(frame, "emote:wave"), false); IC.Wheel.Open(false); wheelClick(IC, Stub, "Favorites")
        assert(not has(IC.Wheel.items, "emote:wave")); IC.Wheel.Close()
        assert(has(IC.Actions.List("favorites"), "emote:wave"))
        IC.LayoutUI.Open("wheel"); frame.sourceChoice:Choose("Social"); assert(not item(frame, "emote:wave").check:GetChecked())
        check(item(frame, "emote:wave"), true); eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("hiding all wheel categories leaves a safe empty category chooser", function(IC, Stub)
        IC.LayoutUI.Open("wheel"); Stub.Button(IC.LayoutUI.frame, "Hide listed"):Click()
        IC.Wheel.Open(false); eq(#IC.Wheel.items, 0); IC.Wheel.Track(); eq(IC.Wheel.hover, nil)
        point(Stub, IC, 0, 0); IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton"); assert(not IC.Wheel.open)
        eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("bar rows columns labels and fill direction control the rendered grid and paging", function(IC, Stub)
        local p = page(IC, "Layouts"); p.bSource:Choose("all"); p.bColumns:SetValue(3); p.bRows:SetValue(2); p.bSize:SetValue(48)
        local bar, frame = IC.Layout().bars[1], IC.Bars.frames[1]
        eq(IC.Bars.Capacity(bar), 6); eq(frame.buttons[4].x, frame.buttons[1].x)
        assert(frame.buttons[4].y < frame.buttons[1].y); assert(frame.buttons[1].caption:IsShown())
        assert(frame.next:IsShown()); local first = frame.buttons[1].action.id; frame.next:Click(); assert(frame.buttons[1].action.id ~= first)
        p.bOrientation:Choose("vertical"); frame = IC.Bars.frames[1]
        eq(frame.buttons[2].x, frame.buttons[1].x); eq(frame.buttons[3].y, frame.buttons[1].y)
        p.bLabels:SetChecked(false); p.bLabels:Click(); assert(not frame.buttons[1].caption:IsShown()); eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("right-clicking a bar action opens its item controls without executing it", function(IC, Stub)
        IC.Bars.frames[1].buttons[1]:Click("RightButton")
        assert(IC.LayoutUI.frame:IsShown()); eq(IC.LayoutUI.frame.kind, "bar"); eq(IC.LayoutUI.frame.barIndex, 1)
        eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("wheel sizing and page controls apply without selecting the first option", function(IC, Stub)
        local p = page(IC, "Layouts"); p.wPageSize:SetValue(4); p.wButtonSize:SetValue(56); p.wRadius:SetValue(220); p.wDeadZone:SetValue(80)
        IC.Wheel.Open(false); eq(#IC.Wheel.items, 4); eq(IC.Wheel.outer[1]:GetWidth(), 56); eq(IC.Wheel.geometry.outer, 220)
        eq(IC.Wheel.hover, nil); eq(#IC.Wheel.stack, 0); assert(IC.Wheel.next:IsShown())
        IC.Wheel.next:Click(); eq(IC.Wheel.page, 2); eq(#IC.Wheel.items, 3); eq(IC.Wheel.hover, nil)
        point(Stub, IC, 0, 80); eq(IC.Wheel.hover, nil); eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("a stationary cursor over a newly rendered top slot cannot auto-select or release an action", function(IC, Stub)
        IC.Profile().wheel.mode = "hold"
        IC.Wheel.frame.GetCenter = function() return 960, 360 end
        IC.Wheel.Binding("down"); IC.Wheel.Track(); eq(IC.Wheel.hover, nil)
        IC.Wheel.catcher:Fire("OnMouseDown", "LeftButton"); eq(IC.Wheel.Current().id, "Favorites")
        IC.Wheel.Track(); eq(IC.Wheel.hover, nil); Stub.clock = Stub.clock + 1; IC.Wheel.Binding("up")
        eq(#Stub.sends + #Stub.emotes, 0); assert(not IC.Wheel.open)
    end)
    test("scaled wheel input remains neutral at centre and follows the displayed category", function(IC, Stub, env)
        env.UIParent:SetScale(0.75); env.UIParent:SetSize(800, 600); Stub.cursorX, Stub.cursorY = 310, 240
        IC.Wheel.Open(false); IC.Wheel.Track(); eq(IC.Wheel.hover, nil)
        point(Stub, IC, 0, 0); eq(IC.Wheel.hover, nil)
        wheelClick(IC, Stub, "Social"); eq(IC.Wheel.Current().id, "Social"); eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("large emote menus use semantic groups and alphabet ranges with reachable page controls", function(IC, Stub, env)
        for i, action in ipairs(IC.Emotes.list) do env["EMOTE" .. i .. "_TOKEN"] = action.payload; env["EMOTE" .. i .. "_CMD1"] = "/" .. action.command end
        IC.Emotes.Validate(); IC.Profile().menu.pageSize = 6; IC.Menu.OpenAtCursor()
        local entries = IC.Menu.Entries(); local social, all
        for _, entry in ipairs(entries) do if entry.id == "Social" then social = entry elseif entry.id == "all" then all = entry end end
        assert(social.children[1].children); assert(all.children[1].children); assert(#all.children[1].children <= 12)
        local root, seen = IC.Menu.levels[1], {}
        for _ = 1, #root.entries do
            for _, row in ipairs(root.rows) do if row:IsShown() then seen[row.entry.label] = true end end
            local previous = root.offset; root.next:Click(); if previous == root.offset then break end
        end
        for _, entry in ipairs(root.entries) do assert(seen[entry.label], entry.label) end
        eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("icon search and category choices update a bar action without sending", function(IC, Stub)
        IC.LayoutUI.Open("bar", 1); local f = IC.LayoutUI.frame; item(f, "emote:wave").icon:Click()
        local picker = IC.Editor.picker; picker.search:SetText("train"); assert(#picker.icons > 0)
        picker.category:Choose("Voice/Fun"); assert(#picker.icons > 0)
        local icon = picker.icons[1]; picker.slots[1]:Click(); Stub.Button(picker, "Use icon"):Click()
        eq(IC.Actions.Resolve("emote:wave").icon, icon); eq(IC.Bars.frames[1].buttons[1].action.icon, icon)
        eq(#Stub.sends + #Stub.emotes, 0); assert(Stub.KeyDown("W"))
        IC.Editor.PickIcon(icon, function() end); picker.search:SetText("followme"); picker.category:Choose("Combat")
        assert(#picker.icons > 0) -- A shared texture retains search terms from all of its semantic uses.
    end)
    test("individual message icons are editable independently of their pool icon", function(IC, Stub)
        local pool = IC.Profile().pools.quotes; IC.Dialogue.SaveLine(pool, nil, "specific message")
        page(IC, "Dialogue"); IC.Editor.SelectPool(pool.id); IC.Editor.pages.Dialogue.browse:Click()
        local frame = IC.Editor.messages; frame.icon:Click()
        IC.Editor.picker.path:SetText("123456"); Stub.Button(IC.Editor.picker, "Use icon"):Click()
        eq(IC.Actions.Resolve("line:quotes:" .. pool.lineIDs[1]).icon, 123456); assert(pool.icon ~= 123456)
        Stub.Button(frame, "Reset"):Click(); eq(IC.Actions.Resolve("line:quotes:" .. pool.lineIDs[1]).icon, pool.icon)
        eq(#Stub.sends, 0)
    end)
end
