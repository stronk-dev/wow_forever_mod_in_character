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
        -- hiddenActions / hiddenCategories are read only by the persona migration of older saves.
        wheel = { mode = "click", root = "main", iconSize = 30, hiddenActions = {}, hiddenCategories = {} },
        menu = { root = "main", hiddenActions = {}, hiddenCategories = {} },
        emoteScope = "essentials", emoteReview = {},
        emoteFilter = "all", hideUnverified = true,
        installedPacks = {},
        shortcuts = {},
        emoteOverrides = {},
    }
end
function IC.Defaults.Bar(index)
    return { name = "Bar " .. (index or 1), collection = "favorites", size = 28, perRow = 0, vertical = false, labels = false,
        hidden = false, locked = false, x = 0, y = -330 + ((index or 1) - 1) * 40 }
end
-- One compact bar showing a collection (Services/Collections.lua). Default: the combined main collection.
function IC.Defaults.CollectionBar(index, collection)
    local bar = IC.Defaults.Bar(index)
    bar.name, bar.collection, bar.y = "Main bar", collection or "main", -330
    return bar
end
function IC.Defaults.Launcher()
    return { shown = true, click = "menu", rightClick = "editor", middleClick = "edit", size = 36, x = -420, y = 180 }
end
function IC.Defaults.Layout()
    return { bars = { IC.Defaults.CollectionBar(1) }, launcher = IC.Defaults.Launcher(), collectionBarIntroduced = true }
end
