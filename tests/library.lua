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
    test("library copies preserve edits on repeat install and addon update", function()
        local db = open(); local _, _, first = IC.Library.Install("office-stanley", true)
        local pool = IC.Profile().pools[first]; eq(#pool.lines, 5); pool.lines[1] = "My own greeting"
        local _, _, second = IC.Library.Install("office-stanley", false)
        assert(first ~= second); eq(pool.lines[1], "My own greeting")
        local original = IC.Library.packs["office-stanley"].pools[1].lines[1]
        eq(original, "Leave me alone."); open(db); eq(IC.Profile().pools[first].lines[1], "My own greeting")
        -- The copy loaded as a character fills its Greeting role and keeps a clean name.
        eq(IC.Personas.RolePool("greetings"), first); eq(IC.Profile().pools[first].name, "Greetings")
        eq(IC.Actions.Resolve("role:greetings").name, "Greeting")
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
end
