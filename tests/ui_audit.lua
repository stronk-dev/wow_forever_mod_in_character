-- Review regressions for the collection refactor; each receives an isolated fixture.
return function(test, eq, page)
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
