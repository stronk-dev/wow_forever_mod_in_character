local _, IC = ...
IC.Library.Register({
    id = "dutch-everyday", title = "Dutch: alledaags", version = 1,
    culture = "Dutch", locale = "nlNL", author = "In Character contributors",
    source = "Common everyday Dutch expressions, curated for this addon; not attributed to a character or show.",
    contentNote = "General Dutch greetings and farewells, separate from the explicit Mastermovies pack.",
    pools = {
        { id = "greetings", name = "Begroetingen", shortcut = "greetings", mode = "shuffle", channel = "SAY", lines = {
            "Goedemorgen!", "Goedemiddag!", "Hoi, hoe gaat het?", "Gezellig!",
        } },
        { id = "farewells", name = "Afscheid", shortcut = "farewells", mode = "shuffle", channel = "SAY", lines = {
            "Tot ziens!", "Doei!", "Tot de volgende keer!", "Houdoe!",
        } },
    },
})
