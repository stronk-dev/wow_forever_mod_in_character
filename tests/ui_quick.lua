return function(test, eq, page)
    local function card(IC, id)
        for _, button in ipairs(IC.QuickActions.cards) do if button:IsShown() and button.action.id == id then return button end end
        error("No quick action: " .. id)
    end
    local function pool(IC, name, lines, mode)
        local result = IC.Dialogue.Create(name); IC.Dialogue.Save(result, name, "SAY", mode or "sequential", result.icon, lines); return result
    end
    test("quick panel opens from the launcher and old binding without consuming typing or key release", function(IC, Stub, env)
        IC.Launcher.button:Click(); assert(IC.QuickActions.open); assert(not IC.Wheel.open)
        assert(Stub.KeyDown("W")); env.InCharacter_WheelBinding("up"); assert(IC.QuickActions.open)
        eq(#Stub.emotes + #Stub.sends, 0); IC.QuickActions.catcher:Hide(); assert(not IC.QuickActions.open)
        env.InCharacter_WheelBinding("down"); assert(IC.QuickActions.open); env.InCharacter_WheelBinding("down"); assert(not IC.QuickActions.open)
        eq(#Stub.emotes + #Stub.sends, 0)
    end)
    test("pinned action buttons execute once and keep their order when reopened", function(IC, Stub)
        IC.QuickActions.Open(); local before = IC.QuickActions.items[1].id
        local button = card(IC, before); button:Fire("OnEnter"); button:Fire("OnLeave"); eq(#Stub.emotes, 0)
        button:Click(); eq(#Stub.emotes, 1); assert(not IC.QuickActions.open)
        IC.QuickActions.Open(); eq(IC.QuickActions.items[1].id, before); eq(#Stub.emotes, 1)
    end)
    test("arbitrary joke and differently toned pools play directly without shortcut categories", function(IC, Stub)
        local names = { "Terrible jokes", "A warm goodbye", "An annoyed goodbye", "Unrelated observations" }
        for _, name in ipairs(names) do pool(IC, name, { name .. " first", name .. " second" }) end
        for _, name in ipairs(names) do
            local p = IC.Dialogue.Find(name); IC.QuickActions.Open(); IC.QuickActions.Select("Roleplay")
            card(IC, "pool:" .. p.id):Click(); eq(Stub.sends[#Stub.sends][1], name .. " first")
        end
        eq(#Stub.sends, #names); eq(next(IC.Profile().shortcuts), nil)
    end)
    test("pool line choice opens without sending then sends an exact stable message", function(IC, Stub)
        local p = pool(IC, "Jokes", { "first", "the exact one", "third" })
        IC.QuickActions.Open(); IC.QuickActions.Select("Roleplay"); card(IC, "pool:" .. p.id).browse:Click()
        eq(#Stub.sends, 0); eq(IC.QuickActions.poolID, p.id)
        card(IC, "line:" .. p.id .. ":" .. p.lineIDs[2]):Click(); eq(#Stub.sends, 1); eq(Stub.sends[1][1], "the exact one")
        eq(IC.Dialogue.states[p.id], nil)
    end)
    test("any named pool can send random without changing its normal sequence", function(IC, Stub)
        local p = pool(IC, "Friendly introductions", { "a", "b" })
        IC.QuickActions.Open(); IC.QuickActions.Select("Roleplay"); card(IC, "pool:" .. p.id).browse:Click()
        IC.QuickActions.random:Click(); eq(#Stub.sends, 1); eq(IC.Dialogue.states[p.id], nil)
        IC.QuickActions.Open(); IC.QuickActions.Select("Roleplay"); card(IC, "pool:" .. p.id):Click(); eq(Stub.sends[2][1], "a")
    end)
    test("pool counts are unlimited by the quick panel and every page is reachable", function(IC, Stub)
        for i = 1, 27 do pool(IC, "Pool " .. i, { "line " .. i }) end
        IC.QuickActions.Open(); IC.QuickActions.Select("Roleplay")
        local seen = {}
        for _ = 1, 4 do
            for _, button in ipairs(IC.QuickActions.cards) do if button:IsShown() then seen[button.action.payload] = true end end
            IC.QuickActions.next:Click()
        end
        for _, id in ipairs(IC.Profile().poolOrder) do assert(seen[id], id) end
        eq(#Stub.sends, 0)
    end)
    test("empty and client-blocked sends keep the panel open without queued playback", function(IC, Stub, env)
        IC.QuickActions.Open(); IC.QuickActions.Select("Roleplay"); card(IC, "pool:quotes"):Click()
        assert(IC.QuickActions.open); eq(#Stub.sends, 0)
        local p = pool(IC, "Blocked jokes", { "never queue me" }); env.C_ChatInfo.InChatMessagingLockdown = function() return true end
        card(IC, "pool:" .. p.id):Click(); assert(IC.QuickActions.open); eq(IC.Dialogue.states[p.id], nil)
        env.C_ChatInfo.InChatMessagingLockdown = function() return false end; eq(#Stub.sends, 0)
    end)
    test("panel group choices follow actual pack provenance and custom pools", function(IC, Stub)
        local ok, _, first = IC.Library.Install("office-stanley", false); assert(ok)
        pool(IC, "My original joke", { "hello" })
        IC.QuickActions.Open(); IC.QuickActions.Select("Roleplay"); IC.QuickActions.groupChoice:Choose("office-stanley")
        assert(#IC.QuickActions.items > 0)
        for _, action in ipairs(IC.QuickActions.items) do eq(IC.Profile().pools[action.payload].provenance.pack, "office-stanley") end
        IC.QuickActions.groupChoice:Choose("custom"); for _, action in ipairs(IC.QuickActions.items) do assert(not IC.Profile().pools[action.payload].provenance) end
        eq(#Stub.sends, 0); assert(first)
    end)
    test("quick actions respect item visibility and close safely on a profile switch", function(IC, Stub)
        IC.Profile().wheel.hiddenActions["emote:wave"] = true; IC.QuickActions.Open()
        for _, action in ipairs(IC.QuickActions.items) do assert(action.id ~= "emote:wave") end
        IC.Profiles.SetScope("character"); assert(not IC.QuickActions.open); eq(#Stub.sends + #Stub.emotes, 0)
    end)
    test("opening and navigating the quick panel in combat never queues chat", function(IC, Stub, env, event)
        local p = pool(IC, "In combat", { "a" }); Stub.combat = true; event("PLAYER_REGEN_DISABLED")
        IC.QuickActions.Open(); IC.QuickActions.Select("Roleplay"); assert(IC.QuickActions.open)
        env.C_ChatInfo.InChatMessagingLockdown = function() return true end; card(IC, "pool:" .. p.id):Click()
        assert(IC.QuickActions.open); IC.QuickActions.catcher:Fire("OnMouseDown", "RightButton"); assert(not IC.QuickActions.open)
        Stub.combat = false; event("PLAYER_REGEN_ENABLED"); eq(#Stub.sends, 0); eq(IC.Dialogue.states[p.id], nil)
    end)
    test("legacy circle remains opt-in and binding aliases still reach it", function(IC, Stub, env)
        IC.Profile().quick.style = "ring"; env.InCharacter_WheelBinding("down"); assert(IC.Wheel.open)
        env.InCharacter_WheelBinding("up"); eq(#Stub.emotes + #Stub.sends, 0)
        IC.Wheel.Close(); IC.Profile().quick.style = "panel"; IC.Slash("wheel"); assert(IC.QuickActions.open)
    end)
    test("quick actions never expose unavailable emotes even while editing all definitions", function(IC, Stub)
        IC.Profile().hideUnverified = false; IC.Profile().emoteScope = "all"
        IC.QuickActions.Open(); IC.QuickActions.Select("emotes")
        for _, action in ipairs(IC.QuickActions.items) do assert(action.verified) end
        assert(#IC.QuickActions.items < #IC.Actions.List("all", true)); eq(#Stub.emotes + #Stub.sends, 0)
    end)
end
