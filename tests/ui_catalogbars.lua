return function(test, eq, page)
    local function pool(IC, name, lines, mode)
        local p = IC.Dialogue.Create(name)
        IC.Dialogue.Save(p, name, "SAY", mode or "sequential", p.icon, lines)
        return p
    end
    local function slot(frame, payload)
        for _, button in ipairs(frame.buttons) do
            if button:IsShown() and button.action.payload == payload then return button end
        end
        error("Missing bar action " .. tostring(payload))
    end
    local function tab(frame, id)
        for _, button in ipairs(frame.catalogTabs) do if button:IsShown() and button.groupID == id then return button end end
        error("Missing bar tab " .. id)
    end
    test("login presents separate persistent emote and RP bars with no popup or keyboard listener", function(IC, Stub)
        eq(IC.Profile().quick.style, "bars"); eq(#IC.Layout().bars, 2)
        local emotes, rp = IC.Bars.frames[1], IC.Bars.frames[2]
        assert(emotes:IsShown() and rp:IsShown()); assert(rp.header:IsShown())
        for _, button in ipairs(emotes.buttons) do if button:IsShown() then eq(button.action.type, "emote") end end
        eq(#IC.Presentation.BarActions(rp.config), 0); assert(rp.empty:IsShown())
        assert(not IC.QuickActions.open and not IC.Wheel.open and not IC.Menu.IsOpen())
        assert(Stub.KeyDown("W")); assert(Stub.KeyDown("SPACE")); eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("any named pool becomes a direct labeled action and remains on screen after playback", function(IC, Stub)
        local p = pool(IC, "An exceptionally awkward joke", { "hello", "another joke" })
        local frame = IC.Bars.frames[2]; local button = slot(frame, p.id)
        eq(button.caption:GetText(), p.name); eq(button.action.selectionMode, "random")
        button:Fire("OnEnter"); button:Fire("OnLeave"); eq(#Stub.sends, 0)
        button:Click(); eq(#Stub.sends, 1); assert(Stub.sends[1][1] == "hello" or Stub.sends[1][1] == "another joke")
        assert(frame:IsShown() and button:IsShown()); assert(not IC.QuickActions.open); eq(next(IC.Profile().shortcuts), nil)
    end)
    test("loaded character switches RP pools without mixing actors or moving the bar", function(IC, Stub)
        assert(IC.Library.Install("office-stanley", false)); assert(IC.Library.Install("dutch-mastermovies", false))
        local p = pool(IC, "My terrible joke", { "hello" }); local frame = IC.Bars.frames[2]
        local x, y, width = frame.x, frame.y, frame:GetWidth()
        IC.Library.Load("office-stanley")
        eq(#IC.Presentation.BarActions(frame.config), 3)
        for _, action in ipairs(IC.Presentation.BarActions(frame.config)) do eq(IC.Profile().pools[action.payload].provenance.pack, "office-stanley") end
        eq(frame.header.text:GetText(), "Stanley Hudson"); eq(frame.point, "TOP"); eq(frame.x, x); eq(frame.y, y); eq(frame:GetWidth(), width)
        IC.Personas.Load("custom"); eq(#IC.Presentation.BarActions(frame.config), 1); slot(frame, p.id)
        eq(#Stub.sends + #Stub.emotes, 0)
    end)

    test("bar playback controls change modes without sending and preserve each pool's settings", function(IC, Stub)
        local p = pool(IC, "Jokes", { "one", "two", "three" }, "sequential"); local frame = IC.Bars.frames[2]
        frame.mode:Click(); eq(frame.config.poolMode, "shuffle")
        local seen = {}; for _ = 1, 3 do slot(frame, p.id):Click(); local text = Stub.sends[#Stub.sends][1]; assert(not seen[text]); seen[text] = true end
        frame.mode:Click(); eq(frame.config.poolMode, "sequential"); eq(#Stub.sends, 3)
        slot(frame, p.id):Click(); slot(frame, p.id):Click(); eq(Stub.sends[4][1], "one"); eq(Stub.sends[5][1], "two")
        frame.mode:Click(); eq(frame.config.poolMode, "pool"); slot(frame, p.id):Click(); eq(Stub.sends[6][1], "one")
        frame.mode:Click(); eq(frame.config.poolMode, "random"); eq(#Stub.sends, 6); eq(p.mode, "sequential")
    end)
    test("right-click opens a reusable persistent specific-line bar without advancing playback", function(IC, Stub)
        local p = pool(IC, "Warm farewell", { "first", "the exact one", "third" })
        local rp = IC.Bars.frames[2]; slot(rp, p.id):Click("RightButton"); eq(#Stub.sends, 0); eq(#IC.Layout().bars, 3)
        local lines = IC.Bars.frames[3]; assert(lines:IsShown() and rp:IsShown()); eq(lines.config.source, "lines:" .. p.id)
        lines.buttons[2]:Click(); eq(Stub.sends[1][1], "the exact one"); eq(IC.Dialogue.states[p.id], nil)
        assert(lines:IsShown() and rp:IsShown()); assert(not IC.QuickActions.open)
        lines.config.x, lines.config.y, lines.config.columns, lines.config.buttonWidth = 150, 215, 3, 200
        local other = pool(IC, "Annoyed farewell", { "leave" }); slot(rp, other.id):Click("RightButton")
        eq(#IC.Layout().bars, 3); eq(lines.config.source, "lines:" .. other.id)
        eq(lines.config.x, 150); eq(lines.config.y, 215); eq(lines.config.columns, 3); eq(lines.config.buttonWidth, 200)
        lines.close:Click(); assert(not lines:IsShown()); assert(rp:IsShown()); eq(#Stub.sends, 1)
    end)
    test("RP item controls hide and restore original pool IDs even with playback overrides", function(IC, Stub)
        local p = pool(IC, "A joke", { "hello" }); local frame = IC.Bars.frames[2]
        Stub.modifiers.shift = true; slot(frame, p.id):Click("RightButton"); Stub.modifiers.shift = nil
        local editor = IC.LayoutUI.frame; eq(editor.barIndex, 2)
        local row
        for _, item in ipairs(editor.rows) do if item:IsShown() and item.action.id == "pool:" .. p.id then row = item end end
        assert(row); row.check:SetChecked(false); row.check:Click(); eq(#IC.Presentation.BarActions(frame.config), 0)
        IC.LayoutUI.Open("bar", 2)
        for _, item in ipairs(editor.rows) do if item:IsShown() and item.action.id == "pool:" .. p.id then row = item end end
        row.check:SetChecked(true); row.check:Click(); eq(#IC.Presentation.BarActions(frame.config), 1)
        slot(frame, p.id); eq(#Stub.sends, 0)
    end)
    test("RP grid controls change width rows columns style and visible empty pools", function(IC, Stub)
        local p = page(IC, "Layouts"); p.which:Choose(2)
        p.bWidth:SetValue(200); p.bColumns:SetValue(2); p.bRows:SetValue(1); p.bSize:SetValue(44)
        local frame = IC.Bars.frames[2]; eq(frame.config.buttonWidth, 200); eq(IC.Bars.Capacity(frame.config), 2)
        p.bHideEmpty:SetChecked(false); p.bHideEmpty:Click(); assert(frame.next:IsShown()); eq(frame.buttons[1]:GetWidth(), 200)
        local first = frame.buttons[1].action.payload; frame.next:Click(); assert(frame.buttons[1].action.payload ~= first)
        p.bStyle:Choose("icons"); eq(frame.buttons, frame.iconButtons)
        for _, button in ipairs(frame.textButtons) do assert(not button:IsShown()) end
        p.bStyle:Choose("text"); eq(frame.buttons, frame.textButtons)
        for _, button in ipairs(frame.iconButtons) do assert(not button:IsShown()) end
        p.bPlayback:Choose("pool"); eq(frame.buttons[1].action.selectionMode, nil)
        eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("specific-line bars page all messages and follow stable IDs through edits and reorders", function(IC, Stub)
        local texts = {}; for i = 1, 9 do texts[i] = "line " .. i end
        local p = pool(IC, "Nine jokes", texts); slot(IC.Bars.frames[2], p.id):Click("RightButton")
        local frame, seen = IC.Bars.frames[3], {}
        for _ = 1, 3 do
            for _, button in ipairs(frame.buttons) do if button:IsShown() then button:Click(); seen[Stub.sends[#Stub.sends][1]] = true end end
            frame.next:Click()
        end
        for _, text in ipairs(texts) do assert(seen[text], text) end
        local id = p.lineIDs[9]; IC.Dialogue.SaveLine(p, id, "edited nine"); IC.Dialogue.MoveLine(p, id, -1)
        local actions = IC.Presentation.BarActions(frame.config); local found
        for _, action in ipairs(actions) do if action.id == "line:" .. p.id .. ":" .. id then found = action end end
        assert(found); assert(IC.Actions.Dispatch(found)); eq(Stub.sends[#Stub.sends][1], "edited nine")
        eq(IC.Dialogue.states[p.id], nil)
    end)
    test("deleting a pool hides its companion rather than retargeting it to unrelated actions", function(IC, Stub)
        local p = pool(IC, "Delete me", { "hello" }); slot(IC.Bars.frames[2], p.id):Click("RightButton")
        local companion = IC.Layout().bars[3]; IC.Dialogue.Delete(p.id)
        assert(companion.hidden); eq(companion.source, "lines:" .. p.id); assert(not IC.Bars.frames[3]:IsShown())
        eq(#IC.Presentation.BarActions(companion), 0); eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("explicit RP launcher and binding toggle only the RP bar; slash bars restores it expanded", function(IC, Stub, env)
        local frame = IC.Bars.frames[2]; IC.Layout().launcher.click = "bars"; IC.Launcher.button:Click(); assert(not frame:IsShown())
        IC.Bars.ToggleCatalog(); assert(frame:IsShown()); assert(frame:IsShown())
        frame.header:Click(); assert(frame.config.collapsed); frame.close:Click(); assert(not frame:IsShown())
        IC.Slash("bars"); assert(frame:IsShown()); assert(not frame.config.collapsed)
        assert(IC.Bars.frames[1]:IsShown()); assert(Stub.KeyDown("W")); eq(#Stub.sends + #Stub.emotes, 0)
        assert(not IC.QuickActions.open and not IC.Wheel.open and not IC.Menu.IsOpen())
    end)
    test("blocked RP sends leave queues unchanged and no combat reconfiguration replays them", function(IC, Stub, env, event)
        local p = pool(IC, "Combat quip", { "hello", "bye" }); local frame = IC.Bars.frames[2]
        env.C_ChatInfo.InChatMessagingLockdown = function() return true end
        Stub.combat = true; event("PLAYER_REGEN_DISABLED"); slot(frame, p.id):Click()
        eq(next(IC.Dialogue.states), nil); eq(#Stub.sends, 0)
        frame.mode:Click(); eq(frame.config.poolMode, "random")
        slot(frame, p.id):Click("RightButton"); eq(#IC.Layout().bars, 2)
        Stub.combat = false; env.C_ChatInfo.InChatMessagingLockdown = function() return false end
        event("PLAYER_REGEN_ENABLED"); eq(#Stub.sends, 0)
        slot(frame, p.id):Click(); eq(#Stub.sends, 1); assert(frame:IsShown())
    end)
    test("RP bar settings button and title drag preserve the top anchor when its row count changes", function(IC, Stub)
        local frame = IC.Bars.frames[2]; frame.edit:Click(); assert(IC.Bars.editing); eq(IC.Bars.selectedBar, 2); eq(IC.Editor.barIndex, 2)
        frame.x, frame.y = 180, 220; frame.header:Fire("OnDragStop")
        eq(frame.config.x, 180); eq(frame.config.y, 220)
        pool(IC, "Jokes", { "a" }); pool(IC, "Warm goodbyes", { "b" }); pool(IC, "Dry goodbyes", { "c" })
        frame.config.columns = 1; IC.Refresh(); local _, parentY = frame:GetParent():GetCenter()
        eq(frame:GetTop() - parentY, 220); eq(frame.config.x, 180)
        eq(#Stub.sends, 0)
    end)
    test("quick access recreates a deleted RP bar visibly on the first click", function(IC, Stub)
        table.remove(IC.Layout().bars, 2); IC.Refresh(); IC.Layout().launcher.click = "bars"; IC.Launcher.button:Click()
        eq(#IC.Layout().bars, 2); assert(IC.Layout().bars[2].catalog); assert(IC.Bars.frames[2]:IsShown())
        eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("changing an RP bar to an emote source removes irrelevant preset tabs", function(IC, Stub)
        local p = page(IC, "Layouts"); p.which:Choose(2); p.bSource:Choose("Social")
        local bar, frame = IC.Layout().bars[2], IC.Bars.frames[2]
        assert(not bar.catalog); eq(bar.catalogGroup, "all")
        for _, button in ipairs(frame.catalogTabs) do assert(not button:IsShown()) end
        for _, action in ipairs(IC.Presentation.BarActions(bar)) do eq(action.type, "emote") end
        p.bCatalog:SetChecked(true); p.bCatalog:Click(); eq(bar.source, "pools"); assert(bar.catalog); eq(bar.buttonStyle, "text")
        eq(#Stub.sends + #Stub.emotes, 0)
    end)
end
