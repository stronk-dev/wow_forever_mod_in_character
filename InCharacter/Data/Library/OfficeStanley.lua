local _, IC = ...
IC.Library.Register({
    id = "office-stanley", title = "The Office: Stanley Hudson", version = 1,
    culture = "The Office (US)", locale = "enUS", author = "Project owner",
    source = "Verbatim phrases supplied by the project owner (2026-11-08); not independently transcribed.",
    contentNote = "Optional character quotation preset; contains profanity. Text only, no recorded audio.",
    pools = {
        { id = "greetings", name = "Greetings", shortcut = "greetings", mode = "random", channel = "SAY", lines = {
            "Leave me alone.", "What do you want?", "Oh, for the love of God.",
            "I'll give you a billion Stanley Nickels if you never talk to me again.", "Why don't you mind your business?",
        } },
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "random", channel = "SAY", lines = {
            "Did I stutter?", "And shove it up your butt!", "Boy, have you lost your mind? 'Cause I'll help you find it!",
            "You are a professional idiot.", "You've been meatballed!",
        } },
        { id = "farewells", name = "Farewells", shortcut = "farewells", mode = "random", channel = "SAY", lines = {
            "Night, everybody.", "It is five o'clock. I will see you all tomorrow.", "Good day.", "Leave me alone, damn it!",
        } },
    },
})
