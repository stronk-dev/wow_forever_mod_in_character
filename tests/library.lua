-- Loaded by run.lua; each module registers its pack through the production schema.
return function(IC, test, eq, open)
    assert(loadfile("InCharacter/Services/Library.lua"))("InCharacter", IC)
    for file in io.lines("InCharacter/InCharacter.toc") do
        if file:match("^Data/Library/.+%.lua$") then assert(loadfile("InCharacter/" .. file))("InCharacter", IC) end
    end
    test("all library packs validate with provenance", function()
        assert(#IC.Library.order >= 6)
        for _, id in ipairs(IC.Library.order) do assert(IC.Library.Validate(IC.Library.packs[id])) end
    end)
    test("preset characters are layers: your rewordings, hidden lines and own lines survive preset updates", function()
        local db = open(); local _, _, first = IC.Library.Install("office-stanley", true)
        local pool = IC.Profile().pools[first]; local def = IC.Library.packs["office-stanley"].pools[1]
        eq(#pool.lines, #def.lines); assert(pool.layer)
        local reworded = pool.lineIDs[1]
        assert(IC.Dialogue.SaveLine(pool, reworded, "My own greeting"))
        assert(IC.Dialogue.DeleteLine(pool, pool.lineIDs[2]))
        local ok, _, mine = IC.Dialogue.SaveLine(pool, nil, "A line I added"); assert(ok)
        eq(pool.lines[1], "My own greeting"); eq(pool.lines[#pool.lines], "A line I added")
        -- An addon update adds a preset line and rewords nothing of yours.
        table.insert(def.lines, "A new preset line")
        open(db); pool = IC.Profile().pools[first]
        eq(pool.lines[1], "My own greeting"); eq(pool.lineIDs[1], reworded, "same message ID, so buttons keep working")
        local seen = {}; for _, line in ipairs(pool.lines) do seen[line] = true end
        assert(not seen[def.lines[2]], "a hidden line stays hidden"); assert(seen["A new preset line"], "new preset lines appear")
        assert(seen["A line I added"]); eq(pool.lineIDs[#pool.lineIDs], mine)
        -- The preset drops the line you reworded: your rewording stays as your own line.
        local dropped = table.remove(def.lines, 1)
        open(db); pool = IC.Profile().pools[first]; seen = {}; for _, line in ipairs(pool.lines) do seen[line] = true end
        assert(seen["My own greeting"]); table.insert(def.lines, 1, dropped); table.remove(def.lines)
        -- Loading the preset again plays the same character; no second copy.
        local count = #IC.Profile().personaOrder; IC.Library.Load("office-stanley"); eq(#IC.Profile().personaOrder, count)
        eq(IC.Personas.RolePool("greetings"), first); eq(IC.Actions.Resolve("role:greetings").name, "Greeting")
    end)
    test("saving the whole text box on a preset pool hides removed lines and keeps added ones across reloads", function()
        local db = open(); local _, _, first = IC.Library.Install("office-stanley", true)
        local pool = IC.Profile().pools[first]; local lines = IC.Copy(pool.lines)
        local removed = table.remove(lines, 3); lines[#lines + 1] = "Typed in the box"
        assert(IC.Dialogue.Save(pool, pool.name, pool.channel, pool.mode, pool.icon, lines))
        open(db); pool = IC.Profile().pools[first]
        local seen = {}; for _, line in ipairs(pool.lines) do seen[line] = true end
        assert(not seen[removed]); assert(seen["Typed in the box"]); eq(#pool.lines, #lines)
        assert(pool.layer.hidden[removed])
    end)
    test("a character from an older full copy becomes a layer and gets the new preset slots and lines", function()
        local db = open(); assert(IC.Library.Load("office-stanley")); local actor = IC.Personas.Active()
        local profile = IC.Profile()
        -- Simulate a 0.14 save: plain copies of the three original pools, one edited, no layers.
        for i = #actor.poolIDs, 1, -1 do
            local pool = profile.pools[actor.poolIDs[i]]
            if pool.layer.def ~= "greetings" and pool.layer.def ~= "quotes" and pool.layer.def ~= "farewells" then
                IC.Dialogue.Delete(pool.id); table.remove(actor.poolIDs, i)
            else pool.layer = nil end
        end
        profile.installedPacks["office-stanley"].dropped = nil
        actor.rolesSet = { greetings = true, quotes = true, farewells = true } -- 0.14 had only these slots
        local greet = profile.pools[IC.Personas.RolePool("greetings")]; greet.lines[1] = "Edited in 0.14"
        open(db); local before = #actor.poolIDs
        for _, id in ipairs(IC.Personas.Active().poolIDs) do assert(IC.Profile().pools[id].layer, id) end
        assert(#IC.Personas.Active().poolIDs > 3, "new slots arrive")
        assert(IC.Personas.RolePool("jokes"), "the Joke slot fills from the preset")
        local lines = {}; for _, line in ipairs(IC.Profile().pools[greet.id].lines) do lines[line] = true end
        assert(lines["Edited in 0.14"], "an old edit is kept as your own line")
    end)
    test("old preset names lose their source prefix on upgrade; the source stays in provenance", function()
        local db = open(); local _, _, first = IC.Library.Install("office-stanley", true)
        IC.Profile().pools[first].name = "The Office: Stanley Hudson / Greetings"
        IC.Profile().cleanInterface = nil -- a save from before 0.14
        open(db); eq(IC.Profile().pools[first].name, "Greetings")
        eq(IC.Personas.Source(IC.Profile().pools[first]), "The Office: Stanley Hudson")
    end)
    test("user supplied Stanley and Mastermovies phrases remain verbatim", function()
        local stanley, dutch = IC.Library.packs["office-stanley"], IC.Library.packs["dutch-mastermovies"]
        local function slot(pack, id) for _, pool in ipairs(pack.pools) do if pool.shortcut == id then return pool.lines end end end
        local owner = {
            greetings = { "Leave me alone.", "What do you want?", "Oh, for the love of God.",
                "I'll give you a billion Stanley Nickels if you never talk to me again.", "Why don't you mind your business?" },
            quotes = { "Did I stutter?", "And shove it up your butt!", "Boy, have you lost your mind? 'Cause I'll help you find it!",
                "You are a professional idiot.", "You've been meatballed!" },
            farewells = { "Night, everybody.", "It is five o'clock. I will see you all tomorrow.", "Good day.", "Leave me alone, damn it!" },
        }
        for id, lines in pairs(owner) do
            for i, line in ipairs(lines) do eq(slot(stanley, id)[i], line, "owner line kept in place") end
        end
        eq(#dutch.pools[1].lines, 5); eq(#dutch.pools[2].lines, 6); eq(#dutch.pools[3].lines, 2)
        eq(dutch.pools[1].lines[4], "wat moet je kutt")
        eq(dutch.pools[2].lines[4], "Born to be Alive is niet van de Village People!")
        eq(dutch.pools[3].lines[1], "ik check je later, homies for life, later!")
    end)
    test("preset shortcuts send from their editable copies only", function()
        open(); local calls = {}; C_ChatInfo = { SendChatMessage = function(text, channel) calls[#calls + 1] = { text, channel } end }
        IC.Library.Install("dutch-mastermovies", true)
        for _, alias in ipairs({ "greet", "quote", "bye" }) do IC.Slash(alias) end
        eq(#calls, 3); eq(calls[1][2], "SAY")
        C_ChatInfo = nil
    end)
    test("library schema rejects invalid data without running text", function()
        local pack = IC.Copy(IC.Library.packs["office-stanley"])
        pack.pools[1].channel = "GUILD"; assert(not IC.Library.Validate(pack))
        pack.pools[1].channel = "SAY"; pack.pools[1].lines[1] = "bad\nline"; assert(not IC.Library.Validate(pack))
        pack.pools[1].lines[1] = "/run error('must stay text')"; assert(IC.Library.Validate(pack))
        pack.pools[2].id = pack.pools[1].id; assert(not IC.Library.Validate(pack))
    end)
    test("unrelated favorite/layout changes preserve pool playback", function()
        open(); local pool = IC.Profile().pools.quotes; pool.mode = "sequential"; pool.lines = { "a", "b" }
        eq(IC.Dialogue.Select(pool), "a"); IC.Actions.Favorite("pool:quotes")
        eq(IC.Dialogue.Select(pool), "b")
    end)
    test("a fresh game start loads a 0.14 save whose preset character gains new slots (cold start)", function()
        -- Build the save with this instance, then open it in a brand-new addon instance where
        -- nothing (IC.db, Profiles.db) is set up yet, like the game does on login.
        local db, char = {}, {}
        IC.db = IC.Profiles.Open(db, char, { "R:P" }); assert(IC.Library.Load("office-stanley"))
        local profile, actor = IC.Profile(), IC.Personas.Active()
        for i = #actor.poolIDs, 1, -1 do
            local pool = profile.pools[actor.poolIDs[i]]; pool.layer = nil
            if not (pool.shortcut == "greetings" or pool.shortcut == "quotes" or pool.shortcut == "farewells") then
                profile.pools[pool.id] = nil; table.remove(actor.poolIDs, i)
            end
        end
        actor.rolesSet = { greetings = true, quotes = true, farewells = true }
        for k in pairs(actor.roles) do if not IC.Personas.ROLE[k] or IC.Personas.ROLE[k].optional then actor.roles[k] = nil end end
        local fresh = {}
        for line in io.lines("InCharacter/InCharacter.toc") do
            if line:match("%.lua$") and not line:match("^UI/") then assert(loadfile("InCharacter/" .. line))("InCharacter", fresh) end
        end
        local ok, problem = pcall(function() fresh.db = fresh.Profiles.Open(db, char, { "R:P" }) end)
        assert(ok, problem)
        eq(fresh.Personas.Name(), "Stanley Hudson"); assert(fresh.Personas.RolePool("jokes"), "the new Joke slot arrived")
        IC.db = IC.Profiles.Open(db, char, { "R:P" })
    end)
end
