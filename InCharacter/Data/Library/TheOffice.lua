local _, IC = ...
-- The Office (US) quotation presets. Every non-owner line is verbatim from the officequotes.net
-- transcript named above it (fetched via web.archive.org snapshots, 2023). Episode numbers follow
-- officequotes.net, which counts double-length episodes once. Stage directions are omitted; typographic
-- quotes/ellipses are rendered as ASCII. Excerpts are contiguous verbatim spans of the spoken line.

IC.Library.Register({
    id = "office-michael", title = "The Office: Michael Scott", version = 2,
    culture = "The Office (US)", locale = "enUS", author = "In Character contributors",
    source = "Transcripts: officequotes.net (e.g. https://www.officequotes.net/no4-12.php), read via web.archive.org snapshots; episode numbers follow officequotes.net. Catchphrase also listed by NBCUniversal: https://www.nbcuniversal.com/article/celebrating-20-years-office",
    contentNote = "Verbatim quotations from the show; contains innuendo (\"That's what she said\") and one mild insult (\"ignorant slut\"). Text only.",
    pools = {
        { id = "greetings", name = "Greetings", shortcut = "greetings", mode = "random", channel = "SAY", lines = {
            -- S2E13 "The Secret", officequotes.net/no2-13.php
            "What's up-dog?",
            -- S2E16 "Valentine's Day", officequotes.net/no2-16.php
            "There they are. What's up? Hey hey.",
        } },
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "random", channel = "SAY", lines = {
            -- S2E06 "The Fight", officequotes.net/no2-06.php
            "Would I rather be feared or loved? Um, easy. Both. I want people to be afraid of how much they love me.",
            -- S4E01 "Fun Run", officequotes.net/no4-01.php
            "I'm not superstitious, but... I'm... I am a little-stitious.",
            -- S5E11 "The Duel", officequotes.net/no5-11.php
            "Sometimes I'll start a sentence, and I don't even know where it's going. I just hope I find it along the way. Like an improv conversation. An improversation.",
            -- S3E02 "The Convention", officequotes.net/no3-02.php
            "I love inside jokes. I'd love to be a part of one someday.",
            -- S6E23 "The Chump", officequotes.net/no6-23.php
            "I am Beyonce always.",
        } },
        { id = "jokes", name = "Jokes", shortcut = "jokes", mode = "random", channel = "SAY", lines = {
            -- S2E17 "Dwight's Speech", officequotes.net/no2-17.php
            "That's what she said!",
            -- S2E03 "Office Olympics", officequotes.net/no2-03.php
            "I'm an early bird, and I'm a night owl. So I'm wise, and I have worms.",
            -- S3E12 "Traveling Salesmen", officequotes.net/no3-12.php
            "Fool me once, strike one. But fool me twice, strike three.",
        } },
        { id = "banter", name = "Banter", shortcut = "banter", mode = "random", channel = "SAY", lines = {
            -- S3E19 "Safety Training", officequotes.net/no3-19.php
            "Dwight, you ignorant slut.",
            -- S5E23 "Broke", officequotes.net/no5-23.php
            "Well, well, well. How the turntables...",
            -- S3E14 "Ben Franklin", officequotes.net/no3-14.php
            "What's up spinsters?",
        } },
        { id = "battlecries", name = "Battle cries", shortcut = "battlecries", mode = "random", channel = "SAY", lines = {
            -- S3E03 "The Coup", officequotes.net/no3-03.php
            "Let's gooooo! Let's go, let's go, let's go!",
            -- S4E04 "Money", officequotes.net/no4-04.php
            "I... DECLARE... BANKRUPTCY!",
        } },
        { id = "toasts", name = "Toasts", shortcut = "toasts", mode = "random", channel = "SAY", lines = {
            -- S4E09 "Dinner Party", officequotes.net/no4-09.php
            "How 'bout a toast. Shall I? Here's to good friends.",
            -- S2E10 "Christmas Party", officequotes.net/no2-10.php
            "Lampshade on head! It's happening!",
        } },
        { id = "farewells", name = "Farewells", shortcut = "farewells", mode = "random", channel = "SAY", lines = {
            -- S2E08 "Performance Review", officequotes.net/no2-08.php
            "Ok, great. Your performance has been adequate. You may leave; goodbye.",
        } },
    },
})
IC.Library.Register({
    id = "office-dwight", title = "The Office: Dwight Schrute", version = 2,
    culture = "The Office (US)", locale = "enUS", author = "In Character contributors",
    source = "Transcripts: officequotes.net (e.g. https://www.officequotes.net/no4-12.php), read via web.archive.org snapshots; episode numbers follow officequotes.net. Identity-theft line also discussed by Rainn Wilson: https://www.aol.com/rainn-wilson-says-playing-dwight-000000582.html",
    contentNote = "Verbatim quotations from the show; mild crude humour (\"cuckolded\", \"groin\"). Text only.",
    pools = {
        { id = "greetings", name = "Greetings", shortcut = "greetings", mode = "random", channel = "SAY", lines = {
            -- S1E01 "Pilot", officequotes.net/no1-01.php
            "Dwight Schrute, Assistant Regional Manager.",
            -- S2E18 "Take Your Daughter to Work Day", officequotes.net/no2-18.php
            "You can refer to me as Mister Schrute.",
        } },
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "random", channel = "SAY", lines = {
            -- S1E03 "Health Care", officequotes.net/no1-03.php
            "Through concentration, I can raise and lower my cholesterol at will.",
            -- S3E16 "Business School", officequotes.net/no3-16.php
            "Whenever I'm about to do something, I think, \"Would an idiot do that?\" And if they would, I do not do that thing.",
            -- S2E21 "Conflict Resolution", officequotes.net/no2-21.php
            "I never smile if I can help it. Showing one's teeth is a submission signal in primates. When someone smiles at me, all I see is a chimpanzee begging for its life.",
            -- S5E13 "Stress Relief", officequotes.net/no5-13.php
            "Nothing stresses me out. Except having to seek the approval of my inferiors.",
            -- S4E06 "Branch Wars", officequotes.net/no4-06.php
            "The eyes are the groin of the head.",
        } },
        { id = "jokes", name = "Jokes", shortcut = "jokes", mode = "random", channel = "SAY", lines = {
            -- S5E02 "Business Ethics", officequotes.net/no5-02.php
            "It's a trick question. The bread is poisoned. Also, it's not your real family. You've been cuckolded by a stronger, smarter male.",
            -- S2E21 "Conflict Resolution", officequotes.net/no2-21.php
            "I'd tell you, but then I'd have to kill you.",
        } },
        { id = "banter", name = "Banter", shortcut = "banter", mode = "random", channel = "SAY", lines = {
            -- S3E20 "Product Recall", officequotes.net/no3-20.php
            "Identity theft is not a joke, Jim! Millions of families suffer every year!",
            -- S3E20 "Product Recall", officequotes.net/no3-20.php
            "Bears do not- What is going on- What are you doing?!",
            -- S1E06 "Hot Girl", officequotes.net/no1-06.php
            "Assistant to the Regional Manager.",
            -- S6E18 "New Leads", officequotes.net/no6-18.php
            "You couldn't handle my undivided attention.",
        } },
        { id = "battlecries", name = "Battle cries", shortcut = "battlecries", mode = "random", channel = "SAY", lines = {
            -- S2E17 "Dwight's Speech", officequotes.net/no2-17.php
            "Salesman of Northeastern Pennsylvania, I ask you once more rise and be worthy of this historical hour!",
            -- S3E13 "The Return", officequotes.net/no3-13.php
            "I am ready to face any challenges that might be foolish enough to face me.",
            -- S2E21 "Conflict Resolution", officequotes.net/no2-21.php
            "I'm done talking. I am a Schrute. We don't back down.",
            -- S3E08 "The Merger", officequotes.net/no3-08.php
            "Fact - I am older. I am wiser. Do not mess with me.",
        } },
    },
})
IC.Library.Register({
    id = "office-jim", title = "The Office: Jim Halpert", version = 2,
    culture = "The Office (US)", locale = "enUS", author = "In Character contributors",
    source = "Transcripts: officequotes.net (e.g. https://www.officequotes.net/no4-12.php), read via web.archive.org snapshots; episode numbers follow officequotes.net. Bear/beets lines: Product Recall cold open, Jim impersonating Dwight; see also https://www.nbcuniversal.com/article/celebrating-20-years-office",
    contentNote = "Verbatim quotations. The bear/beets lines are Jim speaking while impersonating Dwight; keep them attributed to Jim. Contains innuendo. Text only.",
    pools = {
        { id = "greetings", name = "Greetings", shortcut = "greetings", mode = "random", channel = "SAY", lines = {
            -- S4E07 "Survivor Man", officequotes.net/no4-07.php
            "Hey guys, what're we talking about?",
            -- S5E01 "Weight Loss", officequotes.net/no5-01.php
            "Dwight says \"Hi.\"",
        } },
        { id = "jokes", name = "Jokes", shortcut = "jokes", mode = "random", channel = "SAY", lines = {
            -- S4E07 "Survivor Man", officequotes.net/no4-07.php
            "That's what she said.",
            -- S1E01 "Pilot", officequotes.net/no1-01.php
            "Dwight, I'm sorry, because I have always been your biggest flan.",
        } },
        { id = "banter", name = "Banter", shortcut = "banter", mode = "random", channel = "SAY", lines = {
            -- S3E20 "Product Recall", officequotes.net/no3-20.php -- impersonating Dwight
            "Question. What kind of bear is best?",
            -- S3E20 "Product Recall", officequotes.net/no3-20.php -- impersonating Dwight
            "False. Black bear.",
            -- S3E20 "Product Recall", officequotes.net/no3-20.php -- impersonating Dwight
            "Fact. Bears eat beets. Bears. Beets. Battlestar Galactica.",
            -- S1E04 "The Alliance", officequotes.net/no1-04.php
            "No one wants to be you, Dwight.",
            -- S2E20 "Drug Testing", officequotes.net/no2-20.php
            "You look cute today, Dwight.",
            -- S3E02 "The Convention", officequotes.net/no3-02.php
            "Oh, Dwight. I've missed you so much.",
        } },
        { id = "toasts", name = "Toasts", shortcut = "toasts", mode = "random", channel = "SAY", lines = {
            -- S4E03 "Launch Party", officequotes.net/no4-03.php
            "A toast, better make it good. To avoiding a class two felony charge.",
        } },
        { id = "farewells", name = "Farewells", shortcut = "farewells", mode = "random", channel = "SAY", lines = {
            -- S2E17 "Dwight's Speech", officequotes.net/no2-17.php
            "Oh, I should get back. Talk to you guys later.",
            -- S6E11 "Scott's Tots", officequotes.net/no6-11.php
            "See you tomorrow, Dwight.",
        } },
    },
})
IC.Library.Register({
    id = "office-stanley", title = "The Office: Stanley Hudson", version = 2,
    culture = "The Office (US)", locale = "enUS", author = "Project owner; In Character contributors",
    source = "Original phrases supplied by the project owner (2026-11-08), kept as given. Added lines: Transcripts: officequotes.net (e.g. https://www.officequotes.net/no4-12.php), read via web.archive.org snapshots; episode numbers follow officequotes.net.",
    contentNote = "Optional character quotation preset; contains mild profanity and innuendo. Text only, no recorded audio.",
    pools = {
        { id = "greetings", name = "Greetings", shortcut = "greetings", mode = "random", channel = "SAY", lines = {
            -- Supplied by the project owner (2026-11-08); kept exactly.
            "Leave me alone.",
            -- Supplied by the project owner (2026-11-08); kept exactly.
            "What do you want?",
            -- Supplied by the project owner (2026-11-08); kept exactly.
            "Oh, for the love of God.",
            -- Supplied by the project owner (2026-11-08); kept exactly.
            "I'll give you a billion Stanley Nickels if you never talk to me again.",
            -- Supplied by the project owner (2026-11-08); kept exactly.
            "Why don't you mind your business?",
        } },
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "random", channel = "SAY", lines = {
            -- Supplied by the project owner (2026-11-08); kept exactly.
            "Did I stutter?",
            -- Supplied by the project owner (2026-11-08); kept exactly.
            "And shove it up your butt!",
            -- Supplied by the project owner (2026-11-08); kept exactly.
            "Boy, have you lost your mind? 'Cause I'll help you find it!",
            -- Supplied by the project owner (2026-11-08); kept exactly.
            "You are a professional idiot.",
            -- Supplied by the project owner (2026-11-08); kept exactly.
            "You've been meatballed!",
            -- S2E03 "Office Olympics", officequotes.net/no2-03.php
            "Yeah, I got a game. It's called \"work hard so my kids can go to college.\"",
        } },
        { id = "jokes", name = "Jokes", shortcut = "jokes", mode = "random", channel = "SAY", lines = {
            -- S3E05 "Initiation", officequotes.net/no3-05.php
            "That's what she said.",
            -- S4E14 "Goodbye Toby", officequotes.net/no4-14.php
            "Corn dogs should be the standard. Corn dogs should be called hot dogs, and hot dogs should be called bad dogs.",
        } },
        { id = "banter", name = "Banter", shortcut = "banter", mode = "random", channel = "SAY", lines = {
            -- S4E12 "Did I Stutter?", officequotes.net/no4-12.php
            "Every day you do something stupider than you did the day before.",
        } },
        { id = "battlecries", name = "Battle cries", shortcut = "battlecries", mode = "random", channel = "SAY", lines = {
            -- S3E22 "Beach Games", officequotes.net/no3-22.php
            "I would rather work for an upturned broom with a bucket for a head than work for somebody else in this office besides myself. Game on!",
        } },
        { id = "farewells", name = "Farewells", shortcut = "farewells", mode = "random", channel = "SAY", lines = {
            -- Supplied by the project owner (2026-11-08); kept exactly.
            "Night, everybody.",
            -- Supplied by the project owner (2026-11-08); kept exactly.
            "It is five o'clock. I will see you all tomorrow.",
            -- Supplied by the project owner (2026-11-08); kept exactly.
            "Good day.",
            -- Supplied by the project owner (2026-11-08); kept exactly.
            "Leave me alone, damn it!",
            -- S3E05 "Initiation", officequotes.net/no3-05.php
            "Three hundred and sixty four days, 'till the next Pretzel Day.",
        } },
    },
})
IC.Library.Register({
    id = "office-andy", title = "The Office: Andy Bernard", version = 1,
    culture = "The Office (US)", locale = "enUS", author = "In Character contributors",
    source = "Transcripts: officequotes.net (e.g. https://www.officequotes.net/no4-12.php), read via web.archive.org snapshots; episode numbers follow officequotes.net.",
    contentNote = "Verbatim quotations from the show; mentions drinking. Text only.",
    pools = {
        { id = "greetings", name = "Greetings", shortcut = "greetings", mode = "random", channel = "SAY", lines = {
            -- S7E13 "The Seminar", officequotes.net/no7-13.php
            "Welcome everybody. Awesome to see you guys. My name is Andy Bernard but you can call me The Nard Dog.",
            -- S3E10 "A Benihana Christmas", officequotes.net/no3-10.php
            "Hey, what's the haps?",
        } },
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "random", channel = "SAY", lines = {
            -- S3E08 "The Merger", officequotes.net/no3-08.php
            "I'm always thinking one step ahead. Like a carpenter that makes stairs.",
            -- S3E01 "Gay Witch Hunt", officequotes.net/no3-01.php
            "I went to Cornell, you ever heard of it? I graduated in four years. I never studied once. I was drunk the whole time, and I sang in the acappella group, \"Here Comes Treble.\"",
            -- S9E23 "Finale", officequotes.net/no9-23.php
            "I wish there was a way to know you're in the good old days before you've actually left them.",
            -- S5E21 "Michael Scott Paper Company", officequotes.net/no5-21.php
            "Literally every song is better a cappella. Name a song.",
        } },
        { id = "jokes", name = "Jokes", shortcut = "jokes", mode = "random", channel = "SAY", lines = {
            -- S5E02 "Business Ethics", officequotes.net/no5-02.php
            "I'll drop an ethics bomb on you. Would you steal bread to feed your family? ... Boom!",
        } },
        { id = "banter", name = "Banter", shortcut = "banter", mode = "random", channel = "SAY", lines = {
            -- S3E08 "The Merger", officequotes.net/no3-08.php
            "Good luck over there, Tuna. Cross me and I will destroy you.",
            -- S3E01 "Gay Witch Hunt", officequotes.net/no3-01.php
            "Hey, Big Tuna! You're single right?",
            -- S5E14 "Season 5 - Episode 14 Lecture Circuit Part 1", officequotes.net/no5-14.php
            "This is the Nard-Dog.",
        } },
        { id = "battlecries", name = "Battle cries", shortcut = "battlecries", mode = "random", channel = "SAY", lines = {
            -- S5E13 "Stress Relief", officequotes.net/no5-13.php
            "Go, go, go, go, go!!",
            -- S9E05 "Here Comes Treble", officequotes.net/no9-05.php
            "Ladies and gentlemen, Here Comes Treble!",
        } },
        { id = "toasts", name = "Toasts", shortcut = "toasts", mode = "random", channel = "SAY", lines = {
            -- S8E04 "Garden Party", officequotes.net/no8-04.php
            "Toasts are great. I mean, you toast somebody, they toast you back. It just goes round and round. That's my favorite part about toasts, the reciprocity.",
            -- S3E13 "The Return", officequotes.net/no3-13.php
            "So here's to the future... Andy and the Tuna.",
        } },
        { id = "farewells", name = "Farewells", shortcut = "farewells", mode = "random", channel = "SAY", lines = {
            -- S3E13 "The Return", officequotes.net/no3-13.php
            "Gonna go home. Get my beer on. Get my \"Lost\" on.",
        } },
    },
})
IC.Library.Register({
    id = "office-kevin", title = "The Office: Kevin Malone", version = 1,
    culture = "The Office (US)", locale = "enUS", author = "In Character contributors",
    source = "Transcripts: officequotes.net (e.g. https://www.officequotes.net/no4-12.php), read via web.archive.org snapshots; episode numbers follow officequotes.net.",
    contentNote = "Verbatim quotations from the show; Kevin's deliberately broken grammar is as spoken. Text only.",
    pools = {
        { id = "greetings", name = "Greetings", shortcut = "greetings", mode = "random", channel = "SAY", lines = {
            -- S3E08 "The Merger", officequotes.net/no3-08.php
            "Hey, man. Good. Listen, my M&M's are under the desk if you want any.",
        } },
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "random", channel = "SAY", lines = {
            -- S8E02 "The Incentive", officequotes.net/no8-02.php
            "So me think: why waste time, say lot word when few word do trick?",
            -- S3E22 "Beach Games", officequotes.net/no3-22.php
            "I just want to lie on the beach and eat hot dogs. That's all I've ever wanted.",
        } },
        { id = "jokes", name = "Jokes", shortcut = "jokes", mode = "random", channel = "SAY", lines = {
            -- S9E09 "Dwight Christmas", officequotes.net/no9-09.php
            "Mini-Cupcakes? As in the mini version of regular cupcakes, which is already a mini version of cake? Honestly, where does it end with you people?",
            -- S4E03 "Launch Party", officequotes.net/no4-03.php
            "Oh no, it's bad. It's real bad. It's like eating a hot circle of garbage.",
        } },
        { id = "banter", name = "Banter", shortcut = "banter", mode = "random", channel = "SAY", lines = {
            -- S3E06 "Diwali", officequotes.net/no3-06.php
            "This is the best meeting we've ever had.",
            -- S2E10 "Christmas Party", officequotes.net/no2-10.php
            "I'm the DJ because I really know how to heat up a party.",
            -- S6E14 "Sabre", officequotes.net/no6-14.php
            "Just 'cause you have liquid that doesn't make it a toast.",
        } },
        { id = "farewells", name = "Farewells", shortcut = "farewells", mode = "random", channel = "SAY", lines = {
            -- S3E08 "The Merger", officequotes.net/no3-08.php
            "See you later, Jim.",
            -- S5E16 "Blood Drive", officequotes.net/no5-16.php
            "Cool. Bye.",
        } },
    },
})
IC.Library.Register({
    id = "office-creed", title = "The Office: Creed Bratton", version = 1,
    culture = "The Office (US)", locale = "enUS", author = "In Character contributors",
    source = "Transcripts: officequotes.net (e.g. https://www.officequotes.net/no4-12.php), read via web.archive.org snapshots; episode numbers follow officequotes.net.",
    contentNote = "Verbatim quotations from the show; Creed's lines joke about crime, cults, drugs and fraud. Text only.",
    pools = {
        { id = "greetings", name = "Greetings", shortcut = "greetings", mode = "random", channel = "SAY", lines = {
            -- S2E14 "The Carpet", officequotes.net/no2-14.php
            "Hi guys. Somebody makin' soup?",
            -- S5E05 "Employee Transfer", officequotes.net/no5-05.php
            "Let's put a smile on that face!",
        } },
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "random", channel = "SAY", lines = {
            -- S4E01 "Fun Run", officequotes.net/no4-01.php
            "I've been involved in a number of cults, both as a leader and a follower. You have more fun as a follower, but you make more money as a leader.",
            -- S2E21 "Conflict Resolution", officequotes.net/no2-21.php
            "I sprout mung beans on a damp paper towel in my desk drawer. Very nutritious. But they smell like death.",
            -- S6E01 "Gossip", officequotes.net/no6-01.php
            "If I can't scuba, then what's this all been about? What am I working toward?",
            -- S3E23 "The Job", officequotes.net/no3-23.php
            "www.creedthoughts.gov.www/creedthoughts. Check it out.",
        } },
        { id = "jokes", name = "Jokes", shortcut = "jokes", mode = "random", channel = "SAY", lines = {
            -- S5E04 "Crime Aid", officequotes.net/no5-04.php
            "Nobody steals from Creed Bratton and gets away with it. The last person to do this disappeared. His name? Creed Bratton.",
            -- S3E20 "Product Recall", officequotes.net/no3-20.php
            "About 10 years ago, for tax reasons, I faked my own death. I've been collecting benefits as my own widow ever since.",
            -- S3E10 "A Benihana Christmas", officequotes.net/no3-10.php
            "Once you've danced naked at a hash bonfire with the spirits of the dead, all parties seem pretty much the same.",
        } },
        { id = "banter", name = "Banter", shortcut = "banter", mode = "random", channel = "SAY", lines = {
            -- S5E08 "Frame Toby", officequotes.net/no5-08.php
            "Cool beans, man, I live by the quarry. We should hang out by the quarry and throw things down there.",
            -- S5E08 "Frame Toby", officequotes.net/no5-08.php
            "Just pretend like we're talking until the cops leave.",
        } },
        { id = "battlecries", name = "Battle cries", shortcut = "battlecries", mode = "random", channel = "SAY", lines = {
            -- S3E20 "Product Recall", officequotes.net/no3-20.php
            "I will do whatever it takes to survive. Like I did... when I was a homeless man.",
            -- S4E01 "Fun Run", officequotes.net/no4-01.php
            "That's my boss! Yeah-ha baby!",
        } },
        { id = "toasts", name = "Toasts", shortcut = "toasts", mode = "random", channel = "SAY", lines = {
            -- S4E01 "Fun Run", officequotes.net/no4-01.php
            "Can we get another round?",
        } },
        { id = "farewells", name = "Farewells", shortcut = "farewells", mode = "random", channel = "SAY", lines = {
            -- S2E16 "Valentine's Day", officequotes.net/no2-16.php
            "Okay, you take it easy, ace.",
        } },
    },
})
IC.Library.Register({
    id = "office-angela", title = "The Office: Angela Martin", version = 1,
    culture = "The Office (US)", locale = "enUS", author = "In Character contributors",
    source = "Transcripts: officequotes.net (e.g. https://www.officequotes.net/no4-12.php), read via web.archive.org snapshots; episode numbers follow officequotes.net.",
    contentNote = "Verbatim quotations from the show; prim insults (\"morons\"). Text only.",
    pools = {
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "random", channel = "SAY", lines = {
            -- S2E08 "Performance Review", officequotes.net/no2-08.php
            "I really enjoy being judged. I believe I hold up very well to even severe scrutiny.",
            -- S3E06 "Diwali", officequotes.net/no3-06.php
            "I find this incredibly offensive.",
            -- S3E21 "Women's Appreciation", officequotes.net/no3-21.php
            "Sometimes, the clothes at GapKids are just too flashy. So I'm forced to go to the American Girl store and order clothes for large colonial dolls.",
            -- S4E01 "Fun Run", officequotes.net/no4-01.php
            "Cat Heaven is a beautiful place, but you don't get there if you're euthanized.",
        } },
        { id = "jokes", name = "Jokes", shortcut = "jokes", mode = "random", channel = "SAY", lines = {
            -- S3E20 "Product Recall", officequotes.net/no3-20.php
            "I don't have a headache. I'm just preparing.",
        } },
        { id = "banter", name = "Banter", shortcut = "banter", mode = "random", channel = "SAY", lines = {
            -- S3E20 "Product Recall", officequotes.net/no3-20.php
            "I'm sorry... that you're both morons.",
            -- S4E02 "Dunder Mifflin Infinity", officequotes.net/no4-02.php
            "Don't rush me. I'm grieving.",
            -- S1E03 "Health Care", officequotes.net/no1-03.php
            "You let him walk all over you. It's just pathetic.",
            -- S3E10 "A Benihana Christmas", officequotes.net/no3-10.php
            "There's only one party and it's hosted by the Party PLANNING Committee and it starts at three o'clock.",
        } },
        { id = "battlecries", name = "Battle cries", shortcut = "battlecries", mode = "random", channel = "SAY", lines = {
            -- S2E04 "The Fire", officequotes.net/no2-04.php
            "Arms at your sides! Arms at your sides!",
        } },
        { id = "farewells", name = "Farewells", shortcut = "farewells", mode = "random", channel = "SAY", lines = {
            -- S2E09 "E-mail Surveillance", officequotes.net/no2-09.php
            "I'm just leaving for the day.",
            -- S5E01 "Weight Loss", officequotes.net/no5-01.php
            "I usually read a chapter of a book, and it's lights out by 8:30. That's how I sleep at night!",
        } },
    },
})
IC.Library.Register({
    id = "office-pam", title = "The Office: Pam Beesly", version = 1,
    culture = "The Office (US)", locale = "enUS", author = "In Character contributors",
    source = "Transcripts: officequotes.net (e.g. https://www.officequotes.net/no4-12.php), read via web.archive.org snapshots; episode numbers follow officequotes.net.",
    contentNote = "Verbatim quotations from the show. Text only.",
    pools = {
        { id = "greetings", name = "Greetings", shortcut = "greetings", mode = "random", channel = "SAY", lines = {
            -- S1E03 "Health Care", officequotes.net/no1-03.php
            "Dunder Mifflin, this is Pam.",
            -- S2E20 "Drug Testing", officequotes.net/no2-20.php
            "Hey guys, what's going on?",
            -- S4E12 "Did I Stutter?", officequotes.net/no4-12.php
            "Hi everyone. My name is Pam, and I wear glasses.",
        } },
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "random", channel = "SAY", lines = {
            -- S3E04 "Grief Counseling", officequotes.net/no3-04.php
            "Did I wake up this morning thinking I'd be throwing together a bird funeral? You never can tell what your day here is gonna turn into.",
        } },
        { id = "jokes", name = "Jokes", shortcut = "jokes", mode = "random", channel = "SAY", lines = {
            -- S7E24 "Search Committee", officequotes.net/no7-24.php
            "They're the same picture.",
            -- S4E14 "Goodbye Toby", officequotes.net/no4-14.php
            "Oh, thank you! I don't know why I doubted it, because I'm so clearly awesome!",
        } },
        { id = "banter", name = "Banter", shortcut = "banter", mode = "random", channel = "SAY", lines = {
            -- S1E03 "Health Care", officequotes.net/no1-03.php
            "Shut up, Dwight.",
            -- S2E01 "The Dundies", officequotes.net/no2-01.php
            "We're not laughing at you, Dwight.",
            -- S2E13 "The Secret", officequotes.net/no2-13.php
            "I hate you.",
        } },
        { id = "battlecries", name = "Battle cries", shortcut = "battlecries", mode = "random", channel = "SAY", lines = {
            -- S5E26 "Company Picnic", officequotes.net/no5-26.php
            "Back off, Dwight.",
        } },
        { id = "toasts", name = "Toasts", shortcut = "toasts", mode = "random", channel = "SAY", lines = {
            -- S2E01 "The Dundies", officequotes.net/no2-01.php
            "And, I feel God in this Chili's tonight. WHOOOOOOOO!!!!",
            -- S2E01 "The Dundies", officequotes.net/no2-01.php
            "I just want to say, that this was the best, Dundies, ever! WHOOOOOOOOO!!!",
        } },
        { id = "farewells", name = "Farewells", shortcut = "farewells", mode = "random", channel = "SAY", lines = {
            -- S9E12 "Customer Loyalty", officequotes.net/no9-12.php
            "Yep. I'll talk to you tomorrow.",
        } },
    },
})
