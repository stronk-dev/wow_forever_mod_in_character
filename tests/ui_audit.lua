-- Review regressions for the collection refactor; each receives an isolated fixture.
return function(test, eq, page)
    test("native permission queries run on lifecycle events, never during a flyout chat click", function(IC, Stub, env, event)
        local inClick, queries, sends, restricted = false, 0, 0, false
        local function query(value)
            assert(not inClick, 'permission API queried inside the input send path')
            queries = queries + 1; return value
        end
        env.C_ChatInfo.InChatMessagingLockdown = function() return query(restricted) end
        env.C_SocialRestrictions = { CanSendChat = function() return query(true) end }
        env.Enum = { AddOnRestrictionType = { Chat = 0 } }
        env.C_RestrictedActions = { IsAddOnRestrictionActive = function() return query(false) end }
        event('PLAYER_ENTERING_WORLD'); eq(queries, 3)
        local pool = IC.Profile().pools.quotes
        IC.Dialogue.Save(pool, pool.name, 'SAY', 'sequential', pool.icon, { 'one', 'two' })
        env.C_ChatInfo.SendChatMessage = function(text)
            assert(inClick); sends = sends + 1
        end
        local function clickLine()
            IC.Flyout.Open(IC.Launcher.button, IC.Actions.Resolve('pool:quotes'), 1)
            inClick = true; IC.Flyout.levels[1].rows[1]:Click(); inClick = false
        end
        clickLine(); eq(sends, 1); eq(queries, 3)
        restricted = true; event('ADDON_RESTRICTION_STATE_CHANGED')
        clickLine(); eq(sends, 1); assert(IC.Flyout.IsOpen()); eq(queries, 4)
        restricted = false; event('ADDON_RESTRICTION_STATE_CHANGED')
        clickLine(); eq(sends, 2); eq(queries, 7)
    end)
    test("an exact flyout line submits while its clicked row is visible, then closes once", function(IC, Stub, env)
        local pool = IC.Profile().pools.quotes
        IC.Dialogue.Save(pool, pool.name, 'SAY', 'sequential', pool.icon, { "Chosen line", "Another line" })
        IC.Flyout.Open(IC.Launcher.button, IC.Actions.Resolve('pool:quotes'), 1)
        local row, calls = IC.Flyout.levels[1].rows[2], 0
        env.C_ChatInfo.SendChatMessage = function(text)
            assert(row:IsShown() and IC.Flyout.IsOpen(), 'input row was hidden before dispatch')
            eq(text, 'Another line'); calls = calls + 1
        end
        row:Click(); eq(calls, 1); assert(not IC.Flyout.IsOpen()); eq(IC.Dialogue.states.quotes, nil)
    end)
    test("a blocked pool flyout click retains its visible row and playback until a new successful user click", function(IC, Stub, env, event)
        local pool = IC.Profile().pools.quotes
        IC.Dialogue.Save(pool, pool.name, 'SAY', 'sequential', pool.icon, { 'first', 'second' })
        IC.Flyout.Open(IC.Launcher.button, { id = 'set:rp', type = 'group', collection = 'rp' }, 1)
        local row
        for _, candidate in ipairs(IC.Flyout.levels[1].rows) do if candidate.node and candidate.node.id == 'role:quotes' then row = candidate end end
        assert(row); local calls = 0
        env.C_ChatInfo.SendChatMessage = function()
            assert(row:IsShown() and IC.Flyout.IsOpen()); calls = calls + 1
            event('ADDON_ACTION_BLOCKED', 'InCharacter', 'UNKNOWN()')
        end
        row:Click(); eq(calls, 1); assert(IC.Flyout.IsOpen() and row:IsShown()); eq(IC.Dialogue.states.quotes, nil)
        env.C_ChatInfo.SendChatMessage = function(text)
            assert(row:IsShown()); eq(text, 'first'); calls = calls + 1
        end
        row:Click(); eq(calls, 2); assert(not IC.Flyout.IsOpen()); eq(IC.Dialogue.states.quotes.cursor, 1)
    end)
    test("bar clicks finish chat submission before closing an existing flyout", function(IC, Stub, env)
        local pool = IC.Profile().pools.quotes
        IC.Dialogue.Save(pool, pool.name, 'SAY', 'sequential', pool.icon, { 'bar quote' })
        local button
        for _, b in ipairs(IC.Bars.frames[1].actionButtons) do if b.node and b.node.id == 'role:quotes' then button = b end end
        assert(button); IC.Flyout.Open(IC.Launcher.button, IC.Actions.Resolve('pool:quotes'), 1)
        local calls = 0
        env.C_ChatInfo.SendChatMessage = function(text)
            assert(button:IsShown() and IC.Flyout.IsOpen()); eq(text, 'bar quote'); calls = calls + 1
        end
        button:Click(); eq(calls, 1); assert(not IC.Flyout.IsOpen())
    end)
    test("wheel mouse-down dispatches once while visible and keeps a rejected action available", function(IC, Stub, env, event)
        local pool = IC.Profile().pools.quotes
        IC.Dialogue.Save(pool, pool.name, 'SAY', 'sequential', pool.icon, { 'wheel quote' })
        local list = IC.Collections.Create('Quote'); IC.Collections.Add(list.id, 'role:quotes')
        IC.Profile().wheel.root = list.id; IC.Wheel.Open(false); local slot = IC.Wheel.slots[1]; IC.Wheel.SetHover(slot)
        local calls, blocked = 0, true
        env.C_ChatInfo.SendChatMessage = function(text)
            assert(IC.Wheel.open and slot:IsShown() and IC.Wheel.catcher:IsShown())
            eq(text, 'wheel quote'); calls = calls + 1
            if blocked then event('ADDON_ACTION_BLOCKED', 'InCharacter', 'UNKNOWN()') end
        end
        local x, y = slot:GetCenter(); local scale = slot:GetEffectiveScale()
        Stub.cursorX, Stub.cursorY = x * scale, y * scale
        IC.Wheel.catcher:Fire('OnMouseDown', 'LeftButton')
        eq(calls, 1); assert(IC.Wheel.open); eq(IC.Dialogue.states.quotes, nil)
        blocked = false
        IC.Wheel.catcher:Fire('OnMouseDown', 'LeftButton')
        eq(calls, 2); assert(not IC.Wheel.open); eq(IC.Dialogue.states.quotes.cursor, 1)
    end)
    test("wheel captions wrap within a bounded width outside the square-icon envelope", function(IC)
        IC.Wheel.Open(false)
        assert(IC.Wheel.label.wordWrap and IC.Wheel.sub.wordWrap)
        eq(IC.Wheel.label:GetWidth(), 240); eq(IC.Wheel.sub:GetWidth(), 240)
        for _, slot in ipairs(IC.Wheel.slots) do
            if slot:IsShown() then
                IC.Wheel.SetHover(slot)
                local p = IC.Wheel.label.points.LEFT or IC.Wheel.label.points.RIGHT or IC.Wheel.label.points.BOTTOM or IC.Wheel.label.points.TOP
                local edge = IC.WheelModel.LabelEdge(IC.Wheel.geometry)
                assert(math.abs(p[3]) >= edge or math.abs(p[4]) >= edge)
            end
        end
    end)
    test("heard-nearby filtering uses character observations instead of Retail reference metadata", function(IC, Stub)
        local p = page(IC, "Lists"); p.advanced:SetChecked(true); p.advanced:Click()
        p.kind:Choose("nearby"); eq(#p.shown, 0)
        IC.Curation.Save("emote:wave", "keep", "nearby", "yes")
        IC.Curation.Save("emote:cheer", "keep", "self", "yes")
        IC.Editor.RefreshLibrary(); eq(#p.shown, 1); eq(p.shown[1].id, "emote:wave")
        p.kind:Choose("observed"); eq(#p.shown, 2)
        IC.Curation.Save("emote:dance", "keep", "silent", "no")
        p.kind:Choose("textChecked"); eq(#p.shown, 1); eq(p.shown[1].id, "emote:dance")
        eq(#Stub.sends + #Stub.emotes, 0)
    end)

    test("unlimited pools use a bounded scrolling flyout and the last line remains directly usable", function(IC, Stub)
        local pool = IC.Profile().pools.quotes
        local lines = {}; for i = 1, 120 do lines[i] = "Exact message " .. i end
        IC.Dialogue.Save(pool, pool.name, "SAY", "sequential", pool.icon, lines)
        local anchor = IC.Bars.frames[1].actionButtons[1]
        IC.Flyout.Open(anchor, IC.Actions.Resolve("pool:quotes"))
        local level = IC.Flyout.levels[1]
        eq(level:GetWidth(), 304); assert(level:GetHeight() <= 430); eq(#level.rows, 20)
        assert(level.next:IsShown()); eq(#Stub.sends, 0)
        level:Fire("OnMouseWheel", -100)
        eq(level.rows[20].node.label, "Exact message 120")
        level.rows[20]:Click(); eq(Stub.sends[1][1], "Exact message 120"); eq(#Stub.sends, 1)
        local g = IC.Flyout.Geometry(1000, false, 320, 240)
        assert(g.width < 320 and g.height < 240)
    end)

    test("scrolling closes a child flyout before reusing its anchor row", function(IC)
        local collection = IC.Collections.Create("Many groups")
        for i = 1, 30 do
            local pool = IC.Dialogue.Create("Pool " .. i)
            IC.Dialogue.Save(pool, pool.name, "SAY", "sequential", pool.icon, { "Message " .. i })
            IC.Collections.Add(collection.id, "pool:" .. pool.id)
        end
        IC.Flyout.Open(IC.Launcher.button, { id = "set:" .. collection.id, type = "group", collection = collection.id })
        local first = IC.Flyout.levels[1]; first.rows[1]:Fire("OnEnter")
        assert(IC.Flyout.levels[2]:IsShown())
        first:Fire("OnMouseWheel", -1)
        assert(not IC.Flyout.levels[2]:IsShown()); assert(IC.Flyout.IsOpen())
    end)

    test("a large pool opens as its own paged ring; no message is silently omitted", function(IC)
        local pool = IC.Profile().pools.quotes
        local lines = {}; for i = 1, 100 do lines[i] = "Line " .. i end
        IC.Dialogue.Save(pool, pool.name, "SAY", "sequential", pool.icon, lines)
        IC.Profile().wheel.root = "rp"; IC.Wheel.Open(false)
        local owner
        for _, slot in ipairs(IC.Wheel.slots) do if slot:IsShown() and slot.node.payload == pool.id then owner = slot end end
        IC.Wheel.SetHover(owner); IC.Wheel.Use("RightButton")
        eq(IC.Wheel.Current().payload, pool.id); eq(IC.Wheel.pages, 13)
        IC.Wheel.Page(12); eq(IC.Wheel.items[#IC.Wheel.items].label, "Line 100")
    end)

    test("old cyclic group data cannot keep opening flyout or ring ancestors", function(IC)
        local a = IC.Collections.Create("A"); local b = IC.Collections.Create("B")
        a.items = { "set:" .. b.id, "emote:wave" }; b.items = { "set:" .. a.id, "emote:wave" }
        local nodeA = { id = "set:" .. a.id, type = "group", collection = a.id }
        local nodeB = { id = "set:" .. b.id, type = "group", collection = b.id }
        IC.Flyout.Open(IC.Launcher.button, nodeA, 1)
        IC.Flyout.Open(IC.Flyout.levels[1].rows[1], nodeB, 2)
        assert(not IC.Flyout.Open(IC.Flyout.levels[2].rows[1], nodeA, 3))
        IC.Profile().wheel.root = a.id; IC.Wheel.Open(false)
        IC.Wheel.Enter(nodeB); IC.Wheel.Enter(nodeA); eq(#IC.Wheel.stack, 2)
    end)

    test("combat immediately hides surfaces that were visible only for layout editing", function(IC, Stub, env, event)
        IC.Layout().bars[1].hidden = true; IC.Layout().launcher.shown = false
        IC.Bars.SetEditing(true)
        local frame = IC.Bars.frames[1]; assert(frame:IsShown()); assert(IC.Launcher.button:IsShown())
        Stub.combat = true; event("PLAYER_REGEN_DISABLED")
        assert(not frame:IsShown()); assert(not IC.Launcher.button:IsShown()); assert(not IC.Bars.editing)
        eq(#Stub.sends + #Stub.emotes, 0)
    end)
end
