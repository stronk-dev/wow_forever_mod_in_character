local _, IC = ...
IC.Icons = {
    "Interface\\Icons\\INV_Misc_Book_09", "Interface\\Icons\\INV_Misc_Note_01",
    "Interface\\Icons\\INV_Misc_QuestionMark", "Interface\\Icons\\Ability_Warrior_RallyingCry",
    "Interface\\Icons\\INV_Misc_Beer_01", "Interface\\Icons\\INV_Misc_Food_33",
    "Interface\\Icons\\Spell_Holy_Silence", "Interface\\Icons\\INV_ValentinesCandy",
}
IC.Defaults = {}
function IC.Defaults.Pool(id, name)
    return { id = id, name = name, icon = IC.Icons[1], mode = "shuffle", channel = "SAY", lines = {}, revision = 1 }
end
function IC.Defaults.Profile()
    return {
        pools = {
            greetings = IC.Defaults.Pool("greetings", "Greetings"),
            quotes = IC.Defaults.Pool("quotes", "Quotes"),
            farewells = IC.Defaults.Pool("farewells", "Farewells"),
        },
        poolOrder = { "greetings", "quotes", "farewells" },
        favorites = { "emote:wave", "pool:greetings", "pool:quotes", "pool:farewells" },
        wheel = { mode = "click", radius = 165 },
        emoteFilter = "all", hideUnverified = false,
        installedPacks = {},
    }
end
function IC.Defaults.Bar(index)
    return { name = "Quick bar " .. (index or 1), source = "favorites", vertical = false,
        size = 36, locked = false, hidden = false, collapsed = false, page = 1,
        x = 0, y = -160 - ((index or 1) - 1) * 70 }
end
function IC.Defaults.Layout() return { bars = { IC.Defaults.Bar(1) } } end
