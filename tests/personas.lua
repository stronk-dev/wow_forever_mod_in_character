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
        p.shortcuts = { greetings = latest } -- what pre-persona saves stored
        db.version = 9; open(db); eq(db.version, IC.Profiles.VERSION)
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
    test("a role slot the player empties stays empty after reload", function()
        open(); assert(IC.Library.Install("office-stanley", true))
        local pool = IC.Personas.RolePool("greetings"); assert(pool, "the preset fills Greeting")
        assert(IC.Personas.ClearRole(pool)); eq(IC.Personas.RolePool("greetings"), nil)
        IC.db = IC.Profiles.Open({ version = 13, profiles = { account = IC.Profile() } }, IC.Profiles.Character())
        eq(IC.Personas.RolePool("greetings"), nil, "No role sticks")
        assert(IC.Personas.SetRole("greetings", pool)); eq(IC.Personas.RolePool("greetings"), pool)
    end)
    test("a role button drawn for the previous character plays the character loaded now", function()
        open(); IC.Profile().pools.quotes.lines = { "old" }
        local sent = {}; C_ChatInfo = { SendChatMessage = function(text) sent[#sent + 1] = text end }
        local stale = IC.Actions.Resolve("role:quotes"); eq(stale.payload, "quotes")
        assert(IC.Library.Install("office-stanley", true))
        local quote = IC.Personas.RolePool("quotes"); assert(quote and quote ~= "quotes")
        local ok, reason = IC.Actions.Dispatch(stale); assert(ok, reason)
        eq(#sent, 1); assert(sent[1] ~= "old", "sent the new character's line, not the old one")
    end)
    test("your own slots appear for every character and play that character's pool, else the shared one", function()
        open(); local sent = {}; C_ChatInfo = { SendChatMessage = function(text) sent[#sent + 1] = text end }
        local joke = assert(IC.Personas.CreateSlot("Joke"))
        assert(not IC.Personas.CreateSlot("joke"), "names are unique"); assert(not IC.Personas.CreateSlot("Greeting"))
        assert(not IC.Personas.RenameSlot("greetings", "Hi"), "built-in slots keep their names")
        assert(IC.Collections.Contains("rp", "role:" .. joke.id))
        eq(IC.Actions.Resolve("role:" .. joke.id).name, "Joke")
        assert(not IC.Actions.Dispatch("role:" .. joke.id)); eq(#sent, 0)
        -- A shared Joke pool: every character without its own uses it.
        local general = IC.Dialogue.Create("General jokes"); general.lines = { "shared joke" }; IC.Dialogue.EnsureLines(general)
        assert(IC.Personas.SetShared(general.id, true)); assert(IC.Personas.SetRole(joke.id, general.id))
        assert(IC.Personas.IsShared(general.id)); eq(IC.Personas.RoleOf(general.id), joke.id)
        assert(IC.Library.Install("office-stanley", true))
        local id, from = IC.Personas.RolePool(joke.id); eq(id, general.id); eq(from, "shared")
        assert(IC.Actions.Dispatch("role:" .. joke.id)); eq(sent[1], "shared joke")
        -- Stanley gets his own Joke pool; it wins over the shared one for him only.
        local own = IC.Dialogue.Create("Stanley jokes"); own.lines = { "own joke" }; IC.Dialogue.EnsureLines(own)
        assert(IC.Personas.SetRole(joke.id, own.id)); id, from = IC.Personas.RolePool(joke.id); eq(id, own.id); eq(from, "own")
        IC.Slash("say joke"); eq(sent[2], "own joke")
        local stanley = IC.Personas.Active().id
        local other = IC.Personas.Create("Someone else"); IC.Personas.Load(other.id)
        eq((IC.Personas.RolePool(joke.id)), general.id, "other characters still fall back to the shared pool")
        -- Shared greeting fallback for a character with no greeting of its own.
        IC.Personas.Load(stanley); assert(IC.Personas.RolePool("greetings") ~= nil)
        IC.Personas.Load(other.id); eq(IC.Personas.RolePool("greetings"), nil)
        C_ChatInfo = nil
    end)
    test("renaming and deleting a slot you made updates every surface and keeps the pools", function()
        open(); local slot = assert(IC.Personas.CreateSlot("Sarcastic farewell"))
        local pool = IC.Dialogue.Create("Snark"); assert(IC.Personas.SetRole(slot.id, pool.id))
        IC.Collections.Add("favorites", "role:" .. slot.id); local list = IC.Collections.Create("Mine"); IC.Collections.Add(list.id, "role:" .. slot.id)
        assert(IC.Personas.RenameSlot(slot.id, "Snarky bye")); eq(IC.Actions.Resolve("role:" .. slot.id).name, "Snarky bye")
        assert(IC.Personas.DeleteSlot(slot.id)); assert(not IC.Personas.DeleteSlot("greetings"))
        assert(not IC.Collections.Contains("favorites", "role:" .. slot.id)); assert(not IC.Collections.Contains(list.id, "role:" .. slot.id))
        assert(not IC.Collections.Contains("rp", "role:" .. slot.id)); assert(IC.Profile().pools[pool.id], "the pool is kept")
        eq(IC.Personas.RoleOf(pool.id), nil)
        -- Survives reload, and moving a pool back to one character keeps its slot.
        local again = assert(IC.Personas.CreateSlot("Joke")); local shared = IC.Dialogue.Create("Shared")
        IC.Personas.SetShared(shared.id, true); IC.Personas.SetRole(again.id, shared.id)
        IC.db = IC.Profiles.Open({ version = 13, profiles = { account = IC.Profile() } }, IC.Profiles.Character())
        eq((IC.Personas.RolePool(again.id)), shared.id)
        IC.Personas.SetShared(shared.id, false); assert(not IC.Personas.IsShared(shared.id))
        local id, from = IC.Personas.RolePool(again.id); eq(id, shared.id); eq(from, "own")
        IC.Dialogue.Delete(shared.id); eq(IC.Personas.RolePool(again.id), nil); eq(#IC.Personas.SharedPools(), 0)
    end)
    test("slash commands find shared pools by name; an own pool wins, and two shared matches are ambiguous", function()
        open(); local sent = {}; C_ChatInfo = { SendChatMessage = function(text) sent[#sent + 1] = text end }
        local general = IC.Dialogue.Create("General jokes"); general.lines = { "shared joke" }; IC.Dialogue.EnsureLines(general)
        IC.Personas.SetShared(general.id, true)
        assert(IC.Library.Install("office-stanley", true))
        eq(IC.Personas.FindPool("General jokes"), general); eq(IC.Personas.FindPool(general.id), general)
        IC.Slash("General jokes"); eq(sent[1], "shared joke")
        IC.Slash("play random General jokes"); eq(sent[2], "shared joke")
        local own = IC.Dialogue.Create("General jokes"); own.lines = { "own joke" }; IC.Dialogue.EnsureLines(own)
        eq(IC.Personas.FindPool("General jokes"), own, "the character's own pool wins over a shared one")
        IC.Slash("General jokes"); eq(sent[3], "own joke")
        IC.Dialogue.Delete(own.id)
        local twin = IC.Dialogue.Create("General jokes"); IC.Personas.SetShared(twin.id, true)
        local found, problem = IC.Personas.FindPool("General jokes"); eq(found, nil); assert(problem:find("Ambiguous", 1, true))
        eq(IC.Personas.FindPool(general.id), general, "an exact ID still works")
        C_ChatInfo = nil
    end)
end
