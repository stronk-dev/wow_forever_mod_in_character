return function(IC, test, eq, open)
    test("v6 upgrade adds a separate RP bar once while preserving old bars and private layouts", function()
        local profile = IC.Defaults.Profile(); profile.quick = { style = "panel", columns = 4 }
        profile.pools.quotes.lines = { "keep my text" }; profile.favorites = { "pool:quotes", "emote:wave" }
        local old = { bars = { { name = "My old bar", source = "Social", x = 135, y = -45, columns = 3, hiddenActions = { ["emote:bow"] = true } } } }
        local db = { version = 6, profiles = { account = profile }, sharedLayout = IC.Copy(old) }
        local char = { version = 6, scope = "character", profile = IC.Copy(profile), layout = IC.Copy(old) }
        IC.Profiles.Open(db, char)
        eq(db.version, 10); eq(char.version, 10)
        for _, layout in ipairs({ db.sharedLayout, char.layout }) do
            eq(#layout.bars, 2); eq(layout.bars[1].name, "My old bar"); eq(layout.bars[1].x, 135)
            eq(layout.bars[1].source, "Social"); eq(layout.bars[1].columns, 3); assert(layout.bars[1].hiddenActions["emote:bow"])
            assert(layout.bars[2].catalog); eq(layout.bars[2].buttonStyle, "text")
        end
        eq(char.profile.quick.style, "panel"); eq(db.profiles.account.quick.previousStyle, nil)
        eq(char.profile.pools.quotes.lines[1], "keep my text"); eq(char.profile.favorites[1], "pool:quotes")
        IC.Profiles.Open(db, char); eq(#char.layout.bars, 2); eq(#db.sharedLayout.bars, 2)
        table.remove(char.layout.bars, 2); char.profile.quick.style = "panel"
        IC.Profiles.Open(db, char); eq(#char.layout.bars, 1); eq(char.profile.quick.style, "panel")
    end)
    test("RP upgrade respects deliberately empty bar collections and an opt-in circle", function()
        local profile = IC.Defaults.Profile(); profile.quick = { style = "ring", columns = 3 }
        local db = { version = 6, profiles = { account = profile }, sharedLayout = { bars = {} } }
        local char = { version = 6, layout = { bars = {} } }
        IC.Profiles.Open(db, char); eq(#char.layout.bars, 0); eq(#db.sharedLayout.bars, 0); eq(IC.Profile().quick.style, "ring")
        IC.Profiles.Open(db, char); eq(#char.layout.bars, 0)
    end)
    test("catalogue choices and grids persist per character and can be shared explicitly", function()
        local db = open(); local a = IC.Layout().bars[2]
        a.catalogGroup, a.buttonWidth, a.columns, a.rows, a.hidden = "office-stanley", 224, 3, 2, true
        open(db, "Realm:Other"); local b = IC.Layout().bars[2]
        eq(b.catalogGroup, "all"); eq(b.buttonWidth, 144); assert(not b.hidden)
        b.poolMode = "sequential"; open(db)
        eq(IC.Layout().bars[2].catalogGroup, "office-stanley"); eq(IC.Layout().bars[2].buttonWidth, 224)
        eq(IC.Layout().bars[2].rows, 2); assert(IC.Layout().bars[2].hidden)
        IC.Profiles.SetLayoutScope("account"); IC.Layout().bars[2].columns = 5
        open(db, "Realm:Other"); IC.Profiles.SetLayoutScope("account"); eq(IC.Layout().bars[2].columns, 5)
        IC.Profiles.SetLayoutScope("character"); eq(IC.Layout().bars[2].poolMode, "sequential")
    end)
    test("catalogue presentation keeps source IDs and custom names while disambiguating preset pools", function()
        open(); local ok, _, id, actorID = IC.Library.Install("office-stanley", false); assert(ok); IC.Personas.Load(actorID)
        local bar = IC.Defaults.CatalogBar(); local p = IC.Profile().pools[id]; local fullName = p.name
        local actions = IC.Presentation.BarActions(bar); local first = actions[1]
        eq(first.sourceID, "pool:" .. id); eq(first.label, "Greetings"); eq(p.name, fullName)
        bar.catalogGroup = "office-stanley"; actions = IC.Presentation.BarActions(bar); eq(actions[1].label, "Greetings")
        p.name = "Dry jokes, including terrible puns"; actions = IC.Presentation.BarActions(bar); eq(actions[1].label, p.name)
        bar.hiddenActions["pool:" .. id] = true
        for _, action in ipairs(IC.Presentation.BarActions(bar)) do assert(action.payload ~= id) end
        local found; for _, action in ipairs(IC.Presentation.BarActions(bar, true)) do if action.payload == id then found = true end end
        assert(found)
    end)
    test("pinning text never inserts it into the emote-only bar or changes pin order", function()
        open(); local profile = IC.Profile(); profile.favorites = { "pool:quotes", "emote:wave", "pool:greetings", "emote:cheer" }
        local raw = IC.Actions.List("favoriteEmotes", true); eq(#raw, 2); eq(raw[1].id, "emote:wave"); eq(raw[2].id, "emote:cheer")
        eq(#profile.favorites, 4); eq(profile.favorites[1], "pool:quotes"); eq(#IC.Actions.List("favorites", true), 4)
    end)
end
