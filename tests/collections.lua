return function(IC, test, eq, open)
    local C = IC.Collections
    local function known(...)
        for index, command in ipairs({ ... }) do _G["EMOTE" .. index .. "_TOKEN"], _G["EMOTE" .. index .. "_CMD1"] = command:upper(), "/" .. command end
        IC.Emotes.Validate()
    end
    local function forget()
        for index = 1, 20 do _G["EMOTE" .. index .. "_TOKEN"], _G["EMOTE" .. index .. "_CMD1"] = nil, nil end
        IC.Emotes.Validate()
    end
    local function ids(nodes) local result = {}; for i, node in ipairs(nodes) do result[i] = node.id end; return table.concat(result, " ") end

    test("fresh profiles seed the main bar, categories and favorites without copying favorites", function()
        open()
        eq(table.concat(C.Get("main").items, " "), table.concat(C.MAIN, " "))
        assert(C.Refs("favorites") == IC.Profile().favorites, "favorites stay stored in profile.favorites")
        local combat = {}; for _, action in ipairs(IC.Emotes.byCategory.Combat) do if IC.Curation.Included(action) then combat[#combat + 1] = action.id end end
        eq(table.concat(C.Get("Combat").items, " "), table.concat(combat, " "))
        eq(C.Get("Combat").name, "Combat callouts")
        eq(IC.Layout().bars[1].collection, "main"); eq(#IC.Layout().bars, 1); eq(IC.Layout().bars[1].size, 28)
    end)

    test("v10 profiles gain collections once; review-hidden emotes stay out of seeds but older settings are untouched", function()
        local profile = IC.Defaults.Profile(); profile.collections = nil; profile.collectionOrder = nil
        profile.emoteReview = { ["emote:charge"] = { choice = "hide" } }
        profile.favorites = { "emote:charge", "emote:joke" }; profile.wheel.hiddenActions = { ["emote:wave"] = true }
        local db = { version = 10, profiles = { account = profile } }
        open(db)
        assert(not C.Contains("Combat", "emote:charge")); assert(C.Contains("Combat", "emote:flee"))
        eq(IC.Profile().favorites[1], "emote:charge"); eq(IC.Profile().favorites[2], "emote:silly")
        assert(IC.Profile().wheel.hiddenActions["emote:wave"]); assert(IC.Emotes.byID["emote:charge"])
        C.Remove("Combat", "emote:flee"); open(db); assert(not C.Contains("Combat", "emote:flee"), "seeding never repeats")
    end)

    test("nodes inline favorites, group categories and skip unknown emotes without deleting them", function()
        open(); known("wave", "cheer", "charge")
        IC.Profile().favorites = { "emote:wave", "emote:dance", "emote:cheer", "pool:greetings" }
        IC.Profile().pools.greetings.lines = { "hello" }
        local nodes = C.Nodes("main")
        eq(ids(nodes), "emote:wave emote:cheer pool:greetings set:Combat set:Social set:Reactions set:Voice/Fun set:rp")
        eq(nodes[1].segment, 1); eq(nodes[3].segment, 1); eq(nodes[4].segment, 2); eq(nodes[4].type, "group")
        eq(IC.Profile().favorites[2], "emote:dance")
        eq(ids(C.Children(nodes[4])), "emote:charge")
        forget()
    end)

    test("pool children are its exact lines and other characters' pools are skipped", function()
        open(); local pool = IC.Profile().pools.quotes
        IC.Dialogue.Save(pool, "Quotes", "SAY", "sequential", pool.icon, { "first", "second" })
        local node = IC.Actions.Resolve("pool:quotes")
        local lines = C.Children(node); eq(#lines, 2); eq(lines[2].type, "line"); eq(IC.Dialogue.Line(pool, lines[2].lineID), "second")
        local other = IC.Personas.Create("Someone else", {}); IC.Personas.Load(other.id)
        eq(#C.Children(node), 0)
        -- The RP list always offers the switcher and the three role slots; empty slots are shown dimmed.
        eq(ids(C.Nodes("rp")), "character role:greetings role:quotes role:farewells")
        assert(C.Nodes("rp")[2].empty); eq(C.Nodes("rp")[2].name, "Greeting")
        IC.Profile().favorites = { "pool:quotes" }; eq(#C.Nodes("favorites"), 0); eq(IC.Profile().favorites[1], "pool:quotes")
    end)

    test("edits canonicalize aliases, reorder, report membership and refuse cycles into themselves", function()
        open(); known("wave", "silly")
        assert(C.Add("Combat", "emote:joke")); assert(C.Contains("Combat", "emote:silly"))
        eq(C.Refs("Combat")[#C.Refs("Combat")], "emote:silly"); assert(not C.Add("Combat", "emote:silly"), "no duplicates")
        local refs = C.Refs("Combat"); local last = refs[#refs]
        assert(C.Move("Combat", last, -1)); eq(C.Refs("Combat")[#refs - 1], last)
        local member = table.concat(C.Membership("emote:wave"), " ")
        assert(member:find("favorites") and member:find("Social"))
        local mine = C.Create("Tavern"); assert(not C.Add(mine.id, "set:" .. mine.id)); assert(not C.Add(mine.id, "set:nope"))
        assert(not C.Add(mine.id, "emote:doesnotexist"))
        local other = C.Create("Inn")
        assert(C.Add(mine.id, "set:" .. other.id)); assert(not C.Add(other.id, "set:" .. mine.id), "indirect cycles are refused")
        assert(not C.Add(other.id, "all:" .. mine.id), "inline cycles are refused too")
        assert(C.Add(other.id, "emote:wave")); C.Nodes(mine.id)
        assert(C.Add("main", "set:" .. mine.id))
        assert(not C.Delete("Combat"), "built-ins stay"); assert(C.Delete(mine.id))
        assert(not C.Contains("main", "set:" .. mine.id)); assert(not C.Contains(other.id, "set:" .. mine.id))
        forget()
    end)

    test("rp follows the loaded character and a profile reset re-seeds lazily", function()
        open()
        eq(C.Get("rp").name, IC.Personas.Name()); eq(#C.Refs("rp"), 1 + 3 + #IC.Personas.Extras())
        eq(C.Refs("rp")[2], "role:greetings"); eq(IC.Actions.Resolve("role:greetings").payload, "greetings")
        assert(not C.Add("rp", "pool:quotes"), "dynamic collections are not edited directly")
        IC.Profiles.Reset(); eq(C.List()[1].id, "main"); assert(C.Get("main")); assert(C.Contains("main", "set:Combat"))
    end)

    test("category seeds respect the trimmed selection and explicit keeps without reseeding edits", function()
        local profile = IC.Defaults.Profile()
        profile.emoteReview["emote:flirt"] = { choice = "keep" }
        open({ version = 10, profiles = { account = profile } })
        assert(C.Contains("Social", "emote:wave")); assert(C.Contains("Social", "emote:flirt"))
        for _, category in ipairs(IC.Emotes.categories) do
            for _, id in ipairs(C.Refs(category)) do assert(IC.Curation.Included(IC.Emotes.byID[id]), id) end
        end
        C.Remove("Social", "emote:wave"); C.Ensure(); assert(not C.Contains("Social", "emote:wave"))
    end)

    test("extra pools follow the character's pool order after the role slots", function()
        open()
        local a = IC.Dialogue.Create("Battle cry"); local b = IC.Dialogue.Create("Toast")
        eq(C.Refs("rp")[5], "pool:" .. a.id); eq(C.Refs("rp")[6], "pool:" .. b.id)
        IC.Dialogue.Move(b.id, -1)
        eq(C.Refs("rp")[5], "pool:" .. b.id); eq(C.Refs("rp")[6], "pool:" .. a.id)
    end)
end
