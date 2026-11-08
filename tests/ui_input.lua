return function(test, eq, page)
    local function released(button)
        assert(not button.capturing)
        eq(button.keyboard, false)
        eq(button:GetScript("OnKeyDown"), nil)
    end

    test("ordinary keys reach the game at login and throughout every addon UI", function(IC, Stub)
        assert(Stub.KeyDown("W"))
        for _, tab in ipairs({ "Home", "Emotes", "Dialogue", "Favorites", "Layouts", "Profiles" }) do
            page(IC, tab)
            assert(Stub.KeyDown("W"), "Keyboard consumed on " .. tab)
            for _, stop in ipairs(IC.UI.captures) do assert(type(stop) == "function") end
        end
        IC.Editor.frame:Hide(); assert(Stub.KeyDown("ENTER"))
        IC.Menu.OpenAtCursor(); assert(Stub.KeyDown("W")); IC.Menu.Close()
        IC.Wheel.Open(false); assert(Stub.KeyDown("TAB")); IC.Wheel.Close()
        eq(#Stub.sends, 0); eq(#Stub.emotes, 0)
    end)

    test("key assignment consumes only the captured press and then releases keyboard input", function(IC, Stub)
        local key = page(IC, "Layouts").wKey
        released(key); eq(key.propagateKeyboard, true)
        key:Click(); assert(key.capturing); eq(key.keyboard, true)
        assert(not Stub.KeyDown("LSHIFT")); assert(key.capturing)
        Stub.modifiers.shift = true; assert(not Stub.KeyDown("F")); Stub.modifiers.shift = nil
        released(key); eq(Stub.bindings["SHIFT-F"], "INCHARACTER_WHEEL")
        eq(#Stub.worldKeys, 0) -- Assignment must not trigger the freshly bound wheel.
        Stub.Tick(); eq(key.propagateKeyboard, true)
        assert(Stub.KeyDown("W")); eq(Stub.worldKeys[1], "W")
    end)

    test("Escape and clicking cancel capture without binding or blocking subsequent keys", function(IC, Stub)
        local key = page(IC, "Layouts").wKey
        key:Click(); assert(not Stub.KeyDown("ESCAPE")); released(key)
        Stub.Tick(); eq(key.propagateKeyboard, true); assert(Stub.KeyDown("W"))
        for _, mouse in ipairs({ "LeftButton", "RightButton" }) do
            key:Click(); key:Click(mouse); released(key); assert(Stub.KeyDown("ENTER"))
        end
        eq(next(Stub.bindings), nil); eq(Stub.savedBindings, nil)
    end)

    test("capture is exclusive and closes on tab, parent window and settings panel hides", function(IC, Stub)
        local layout = page(IC, "Layouts")
        layout.wKey:Click(); layout.mKey:Click(); released(layout.wKey); assert(layout.mKey.capturing)
        page(IC, "Home"); released(layout.mKey); assert(Stub.KeyDown("W"))
        local key = IC.Editor.pages.Home.wheelKey
        key:Click(); IC.Editor.frame:Hide(); released(key); assert(Stub.KeyDown("W"))
        local settings = IC.SettingsPanel.panel
        settings:Show(); settings.wheelKey:Click(); settings:Hide()
        released(settings.wheelKey); assert(Stub.KeyDown("W"))
    end)

    test("abandoned capture expires without changing any bindings", function(IC, Stub)
        local key = page(IC, "Layouts").wKey
        key:Click(); Stub.Tick(14); assert(key.capturing)
        Stub.Tick(1); released(key); eq(key.propagateKeyboard, true)
        assert(Stub.KeyDown("W")); eq(next(Stub.bindings), nil); eq(Stub.savedBindings, nil)
    end)

    test("binding API errors cannot strand a keyboard listener", function(IC, Stub, env)
        local key = page(IC, "Layouts").wKey
        local set, save = env.SetBinding, env.SaveBindings
        for _, api in ipairs({ "SetBinding", "SaveBindings" }) do
            env.SetBinding, env.SaveBindings = set, save
            env[api] = function() error("test API failure") end
            key:Click(); assert(not Stub.KeyDown("G")); released(key)
            Stub.Tick(); assert(Stub.KeyDown("W"))
            assert(Stub.messages[#Stub.messages]:find("Key binding change failed", 1, true))
        end
    end)

    test("combat cancels active capture without touching restricted propagation or saving bindings", function(IC, Stub, env, event)
        local key = page(IC, "Layouts").wKey
        key:Click(); Stub.combat = true; event("PLAYER_REGEN_DISABLED")
        released(key); assert(Stub.KeyDown("W")); eq(Stub.savedBindings, nil)
        Stub.combat = false; event("PLAYER_REGEN_ENABLED")
        page(IC, "Layouts"); key:Click(); assert(not Stub.KeyDown("ESCAPE"))
        Stub.Tick(); released(key); assert(Stub.KeyDown("ENTER"))
    end)

    test("emote Try button uses Charades dispatch without false rejection messages", function(IC, Stub, env)
        local p = page(IC, "Emotes")
        IC.Editor.emoteCategory = "all"; p.search:SetText("wave"); p.tiles[1]:Click()
        local modernCalls = 0
        env.C_ChatInfo.PerformEmote = function() modernCalls = modernCalls + 1 end
        local before = #Stub.messages
        for _, result in ipairs({ "nil", false, true }) do
            env.DoEmote = function(token) eq(token, "WAVE"); Stub.emotes[#Stub.emotes + 1] = token; if result ~= "nil" then return result end end
            p.dTry:Click(); eq(#Stub.messages, before)
        end
        eq(#Stub.emotes, 3); eq(modernCalls, 0)
        env.DoEmote = function() error("client refused") end
        p.dTry:Click(); eq(#Stub.messages, before + 1); eq(modernCalls, 0)
        assert(Stub.messages[#Stub.messages]:find("Client blocked the emote", 1, true))
    end)
end
