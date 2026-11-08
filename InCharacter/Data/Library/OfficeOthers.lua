local _, IC = ...
-- Deliberately small sourced samples. Expand via PRs with episode/source details.
IC.Library.Register({
    id = "office-michael", title = "The Office: Michael Scott", version = 1,
    culture = "The Office (US)", locale = "enUS", author = "In Character contributors",
    source = "NBCUniversal: Celebrating 20 Years of The Office (2025), catchphrases section. https://www.nbcuniversal.com/article/celebrating-20-years-office",
    contentNote = "One short catchphrase; contains innuendo. Quotation, not original addon dialogue.",
    pools = { { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "random", channel = "SAY", lines = { "That's what she said." } } },
})
IC.Library.Register({
    id = "office-jim", title = "The Office: Jim Halpert", version = 1,
    culture = "The Office (US)", locale = "enUS", author = "In Character contributors",
    source = "Product Recall cold open: Jim impersonates Dwight. Phrase corroborated by NBCUniversal: https://www.nbcuniversal.com/article/celebrating-20-years-office ; attribution discussed by Rainn Wilson: https://www.aol.com/rainn-wilson-says-playing-dwight-000000582.html",
    contentNote = "Jim speaking while impersonating Dwight; do not reattribute this line to Dwight.",
    pools = { { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "random", channel = "SAY", lines = { "Bears, Beets, Battlestar Galactica" } } },
})
IC.Library.Register({
    id = "office-dwight", title = "The Office: Dwight Schrute", version = 1,
    culture = "The Office (US)", locale = "enUS", author = "In Character contributors",
    source = "Rainn Wilson discussing his own character's quotes, interview (2025); Product Recall cold open. https://www.aol.com/rainn-wilson-says-playing-dwight-000000582.html",
    contentNote = "One short quotation; not an invented character line.",
    pools = { { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "random", channel = "SAY", lines = { "Identity theft is not a joke, Jim!" } } },
})
