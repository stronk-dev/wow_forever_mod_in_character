return function(IC, test, eq, open)
    local function actor(pack) assert(IC.Library.Load(pack)); return IC.Personas.Active() end
    local function contains(list, id) for _, value in ipairs(list) do if value == id then return true end end end
    test("loaded RP characters own arbitrary pools while presets stay separate", function()
        open(); local custom = IC.Personas.Active(); local joke = IC.Dialogue.Create("Dry jokes")
        assert(contains(custom.poolIDs, joke.id)); local stanley = actor("office-stanley")
        eq(stanley.name, "Stanley Hudson"); eq(#stanley.poolIDs, 3); assert(not IC.Personas.HasPool(joke.id))
        local dutch = actor("dutch-mastermovies"); eq(dutch.name, "Michael Nicht"); eq(#dutch.poolIDs, 3)
        for _, id in ipairs(stanley.poolIDs) do assert(not IC.Personas.HasPool(id)) end
        IC.Personas.Load(custom.id); assert(IC.Personas.HasPool(joke.id))
    end)
    test("loading a preset reuses edited character data instead of copying or replacing it", function()
        open(); local first = actor("office-stanley"); local pool = IC.Profile().pools[first.poolIDs[1]]
        pool.lines[1] = "My edited line"; local count = #IC.Profile().poolOrder
        actor("dutch-mastermovies"); local again = actor("office-stanley")
        eq(again.id, first.id); eq(IC.Profile().pools[first.poolIDs[1]].lines[1], "My edited line")
        eq(#IC.Profile().poolOrder, count + 3)
    end)
    test("RP playback rejects foreign pools exact messages and mode overrides before selection", function()
        open(); local a = actor("office-stanley"); local p = IC.Profile().pools[a.poolIDs[1]]
        actor("dutch-mastermovies"); local calls = 0
        C_ChatInfo = { SendChatMessage = function() calls = calls + 1 end }
        for _, id in ipairs({ "pool:" .. p.id, "play:random:" .. p.id, "line:" .. p.id .. ":" .. p.lineIDs[1] }) do
            local ok, reason = IC.Actions.Dispatch(id); assert(not ok); assert(reason:find("another character", 1, true))
        end
        eq(calls, 0); eq(next(IC.Dialogue.states), nil); C_ChatInfo = nil
    end)
    test("shortcuts never fall back to a different loaded character's missing line type", function()
        open(); actor("office-stanley"); local onlyQuotes = actor("office-michael"); local sends = {}
        C_ChatInfo = { SendChatMessage = function(text) sends[#sends + 1] = text end }
        IC.Slash("greet"); IC.Slash("bye"); eq(#sends, 0)
        IC.Slash("quote"); eq(#sends, 1); eq(sends[1], IC.Profile().pools[onlyQuotes.poolIDs[1]].lines[1]); C_ChatInfo = nil
    end)
    test("the loaded character persists separately for each WoW character and profile scope", function()
        local db = open(); local stanley = actor("office-stanley")
        open(db, "Realm:Other"); eq(IC.Personas.Active().id, "custom"); local dutch = actor("dutch-mastermovies")
        open(db); eq(IC.Personas.Active().id, stanley.id)
        IC.Profiles.SetScope("character"); eq(IC.Personas.Active().id, stanley.id)
        IC.Personas.Load("custom"); IC.Profiles.SetScope("account"); eq(IC.Personas.Active().id, stanley.id)
        open(db, "Realm:Other"); eq(IC.Personas.Active().id, dutch.id)
    end)
    test("legacy preset migration preserves current and older edited copies and infers explicit shortcuts", function()
        local db = open(); local _, _, oldPool = IC.Library.Install("office-stanley", false)
        IC.Profile().pools[oldPool].lines[1] = "Old edit preserved"
        local _, _, latest = IC.Library.Install("office-stanley", true)
        IC.Library.Install("dutch-mastermovies", false)
        local p, c = IC.Profile(), IC.Profiles.Character(); p.personas, p.personaOrder, c.personaSelections = nil, nil, nil
        db.version = 9; open(db); eq(db.version, 10)
        eq(IC.Personas.Active().name, "Stanley Hudson"); assert(IC.Personas.HasPool(latest)); assert(not IC.Personas.HasPool(oldPool))
        eq(IC.Profile().pools[oldPool].lines[1], "Old edit preserved")
        local owned = {}; for _, a in pairs(IC.Profile().personas) do for _, id in ipairs(a.poolIDs) do assert(not owned[id]); owned[id] = true end end
        for _, id in ipairs(IC.Profile().poolOrder) do assert(owned[id], id) end
    end)
    test("copying an additional library character does not change the loaded identity", function()
        open(); local a = actor("office-stanley"); local _, _, _, copy = IC.Library.Install("dutch-mastermovies", false)
        eq(IC.Personas.Active().id, a.id); assert(IC.Profile().personas[copy]); assert(not IC.Personas.Load("missing"))
        eq(IC.Personas.Active().id, a.id)
    end)
    test("moving and deleting pools keeps membership lookup current and never modifies text", function()
        open(); local p = IC.Dialogue.Create("Warm farewell"); IC.Dialogue.SaveLine(p, nil, "See you, 'friend'.")
        assert(IC.Personas.HasPool(p.id)); local a = IC.Personas.Create("Custom actor")
        assert(IC.Personas.Assign(p.id, a.id)); assert(not IC.Personas.HasPool(p.id)); IC.Personas.Load(a.id)
        assert(IC.Personas.HasPool(p.id)); eq(p.lines[1], "See you, 'friend'.")
        IC.Dialogue.Delete(p.id); assert(not IC.Personas.HasPool(p.id)); eq(#a.poolIDs, 0)
    end)
    test("resetting a profile cannot silently activate a new preset under a stale character ID", function()
        open(); actor("office-stanley"); IC.Profiles.Reset(); IC.Library.Install("office-michael", false)
        eq(IC.Personas.Active().id, "custom")
    end)
    test("character resolution accepts names or preset IDs and refuses ambiguous custom names", function()
        open(); eq(IC.Personas.Resolve("Stanley Hudson"), "preset:office-stanley")
        eq(IC.Personas.Resolve("office-stanley"), "preset:office-stanley")
        IC.Personas.Create("Twin"); IC.Personas.Create("Twin"); local id, reason = IC.Personas.Resolve("Twin")
        eq(id, nil); assert(reason:find("Ambiguous", 1, true))
    end)
    test("legacy hidden RP groups migrate once into restorable pool visibility without touching text", function()
        local db = open(); actor("office-stanley"); local p = IC.Profile(); local id = IC.Personas.Pools()[1]
        p.personaVisibilityMigrated = nil; p.wheel.hiddenActions["group:office-stanley"] = true
        local line = p.pools[id].lines[1]; open(db)
        assert(p.wheel.hiddenActions["browse:" .. id]); eq(p.pools[id].lines[1], line)
        p.wheel.hiddenActions["browse:" .. id] = nil; open(db); eq(p.wheel.hiddenActions["browse:" .. id], nil)
    end)
end
