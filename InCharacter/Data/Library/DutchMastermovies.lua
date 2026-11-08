local _, IC = ...
IC.Library.Register({
    id = "dutch-mastermovies", title = "Mastermovies: Michael Nicht", version = 1,
    culture = "Dutch / Mastermovies", locale = "nlNL", author = "Project owner",
    source = "Verbatim lines supplied by the project owner on 2026-11-08, extracted as data from three macros; attribution not independently verified.",
    contentNote = "Optional Dutch parody preset; explicit language and sexual insults, including homo used as an insult. Review before use. No audio.",
    icon = IC.Icons[5],
    pools = {
        { id = "greetings", name = "Begroetingen", shortcut = "greetings", mode = "random", channel = "SAY", lines = {
            "hallo klootviolen", "goeie middag klootviool", "nasi goreng biatch, sambal bij", "wat moet je kutt", "hoe gaat ie met jou?",
        } },
        { id = "quotes", name = "Uitspraken", shortcut = "quotes", mode = "random", channel = "SAY", lines = {
            "michael, wat zijn dat voor bloemen?", "ik douw bami pang pang in je reet", "ik ben homo met je ex",
            "Born to be Alive is niet van de Village People!", "krijg nou een bakkie pleur", "klootviool",
        } },
        { id = "farewells", name = "Afscheid", shortcut = "farewells", mode = "random", channel = "SAY", lines = {
            "ik check je later, homies for life, later!", "later klootviool",
        } },
    },
})
