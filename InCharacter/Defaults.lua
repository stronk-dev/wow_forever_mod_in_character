local _, IC = ...
local I = "Interface\\Icons\\"
-- Quick choices for pool icons. The editor's icon picker also offers every macro icon the client has.
IC.Icons = {
    I .. "INV_Misc_Book_09", I .. "INV_Misc_Note_01", I .. "INV_Misc_QuestionMark", I .. "Ability_Warrior_RallyingCry",
    I .. "INV_Misc_Beer_01", I .. "INV_Misc_Food_33", I .. "Spell_Holy_Silence", I .. "INV_ValentinesCandy",
}
IC.AddonIcon = I .. "Ability_Warrior_RallyingCry"
IC.Defaults = {}
function IC.Defaults.Pool(id, name)
    local icons = { greetings = IC.EmoteIcons.wave, farewells = IC.EmoteIcons.bye, quotes = IC.Icons[2] }
    return { id = id, name = name, icon = icons[id] or IC.Icons[1], mode = "shuffle", channel = "SAY", lines = {}, lineIDs = {}, lineIcons = {}, nextLineID = 1, revision = 1 }
end
function IC.Defaults.Profile()
    return {
        pools = {
            greetings = IC.Defaults.Pool("greetings", "Greetings"),
            quotes = IC.Defaults.Pool("quotes", "Quotes"),
            farewells = IC.Defaults.Pool("farewells", "Farewells"),
        },
        poolOrder = { "greetings", "quotes", "farewells" },
        favorites = { "emote:wave", "emote:cheer", "emote:laugh", "emote:dance", "emote:charge", "emote:healme",
            "pool:greetings", "pool:quotes", "pool:farewells" },
        wheel = { mode = "click", radius = 180, buttonSize = 42, pageSize = 8, deadZone = 62, hiddenActions = {}, hiddenCategories = {} },
        menu = { hiddenActions = {}, hiddenCategories = {}, pageSize = 12 },
        quick = { style = "panel", columns = 3 },
        emoteScope = "essentials", emoteReview = {},
        emoteFilter = "all", hideUnverified = true,
        installedPacks = {},
        shortcuts = {},
        emoteOverrides = {},
    }
end
function IC.Defaults.Bar(index)
    return { name = "Quick bar " .. (index or 1), source = "favorites", vertical = false,
        size = 36, columns = 12, rows = 0, labels = true, hiddenActions = {}, locked = false, hidden = false, collapsed = false, page = 1,
        x = 0, y = -160 - ((index or 1) - 1) * 70 }
end
function IC.Defaults.Launcher()
    -- click = what a left click on the launcher button opens: the categorized menu or the wheel.
    return { shown = true, click = "quick", size = 40, x = -420, y = 180 }
end
function IC.Defaults.Layout() return { bars = { IC.Defaults.Bar(1) }, launcher = IC.Defaults.Launcher() } end
