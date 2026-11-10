local _, IC = ...

-- ---------------------------------------------------------------------------
-- dutch-sayings: real Dutch proverbs and sayings, wording as listed in the
-- cited source. Source keys used in the comments below:
--   [SP] nl.wikipedia "Lijst van Nederlandse spreekwoorden" sublists
--        https://nl.wikipedia.org/wiki/Lijst_van_Nederlandse_spreekwoorden_A-E (and _F-J, _K-O, _P-U, _V-Z)
--   [UG] nl.wikipedia "Lijst van uitdrukkingen en gezegden" sublists
--        https://nl.wikipedia.org/wiki/Lijst_van_uitdrukkingen_en_gezegden_A-E (and _F-J, _K-O, _P-U, _V-Z)
--   [WT] nl.wiktionary "proost" (synonyms: gezondheid, santé; heildronk op iemands gezondheid)
--        https://nl.wiktionary.org/wiki/proost
--   [BNN] BNNVARA, "Doe maar normaal, dan doe je al gek genoeg: waar komt die uitspraak vandaan?"
--        https://bnnvara.nl/portal/artikelen/doe-maar-normaal-dan-doe-je-al-gek-genoeg-waar-komt-die-uitspraak-vandaan
-- ---------------------------------------------------------------------------
IC.Library.Register({
    id = "dutch-sayings", title = "Dutch sayings", version = 1,
    culture = "Dutch", locale = "nlNL", author = "In Character contributors",
    source = "Traditional Dutch proverbs and sayings as worded in nl.wikipedia 'Lijst van Nederlandse spreekwoorden' (https://nl.wikipedia.org/wiki/Lijst_van_Nederlandse_spreekwoorden) and 'Lijst van uitdrukkingen en gezegden' (https://nl.wikipedia.org/wiki/Lijst_van_uitdrukkingen_en_gezegden_A-E); toasts per nl.wiktionary 'proost' (https://nl.wiktionary.org/wiki/proost); 'Doe maar normaal' per BNNVARA (https://bnnvara.nl/portal/artikelen/doe-maar-normaal-dan-doe-je-al-gek-genoeg-waar-komt-die-uitspraak-vandaan).",
    contentNote = "Traditional, anonymous sayings; not attributed to any person. Mild teasing only.",
    pools = {
        { id = "greetings", name = "Greetings", shortcut = "greetings", mode = "shuffle", channel = "SAY", lines = {
            -- [SP] A-E
            "Bomen ontmoeten mekaar niet, mensen wel.",
            "Wie het eerst komt, die het eerst maalt.",
            -- [SP] F-J
            "Gezelligheid kent geen tijd.",
            -- [SP] K-O
            "Beter laat dan nooit.",
        } },
        { id = "farewells", name = "Farewells", shortcut = "farewells", mode = "shuffle", channel = "SAY", lines = {
            -- [SP] K-O
            "Wie dan leeft, wie dan zorgt.",
            "Morgen is er wéér een dag.",
            -- [SP] A-E
            "Bezoek en vis blijven drie dagen fris.",
            -- [SP] P-U
            "Oost west, thuis best.",
            "Komt tijd, komt raad.",
            -- [UG] F-J
            "Ik ga horizontaal.",
        } },
        { id = "toasts", name = "Toasts", shortcut = "toasts", mode = "shuffle", channel = "SAY", lines = {
            -- [WT] proost: synonyms gezondheid, santé; "dronk op iemands gezondheid"
            "Proost!",
            "Gezondheid!",
            "Op je gezondheid!",
            "Santé!",
            -- [SP] V-Z
            "Als de wijn is in de man, is de wijsheid in de kan.",
        } },
        { id = "battlecries", name = "Battle cries", shortcut = "battlecries", mode = "shuffle", channel = "SAY", lines = {
            -- [SP] A-E
            "De aanval is de beste verdediging.",
            "De aanhouder wint.",
            -- [SP] V-Z
            "Wie niet waagt, die niet wint.",
            -- [SP] P-U
            "Zonder strijd, geen overwinning.",
            "Niet geschoten is altijd mis.",
            -- [UG] A-E
            "De dood of de gladiolen.",
            "Maak je borst maar nat.",
        } },
        { id = "banter", name = "Banter", shortcut = "banter", mode = "shuffle", channel = "SAY", lines = {
            -- [BNN]
            "Doe maar normaal, dan doe je al gek genoeg.",
            -- [UG] F-J
            "Hoe ouder, hoe gekker.",
            "Spreek ik Frans?",
            "Ga toch fietsen!",
            "Nu zijn de rapen gaar.",
            -- [UG] A-E
            "Nu komt de aap uit de mouw.",
            -- [SP] A-E
            "Wie kaatst moet de bal verwachten.",
            "Wie boter op het hoofd heeft, moet uit de zon blijven.",
            "Wat de boer niet kent, dat vreet hij niet.",
            -- [SP] P-U / V-Z
            "De pot verwijt de ketel dat hij zwart ziet.",
            "De beste stuurlui staan aan wal.",
            "Holle vaten klinken het hardst.",
        } },
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "shuffle", channel = "SAY", lines = {
            -- [SP] K-O
            "Wie het kleine niet eert, is het grote niet weerd.",
            "Wie het laatst lacht, lacht het best.",
            "Al is de leugen nog zo snel, de waarheid achterhaalt ze wel.",
            "Een dag niet gelachen is een dag niet geleefd.",
            -- [SP] A-E
            "Een goed begin is het halve werk.",
            "Al doende leert men.",
            -- [SP] F-J
            "Spreken is zilver, zwijgen is goud.",
            "Beter één vogel in de hand, dan tien in de lucht.",
            -- [SP] P-U
            "Haastige spoed is zelden goed.",
            "Rome is ook niet op één dag gebouwd.",
            -- [SP] V-Z
            "Stille wateren hebben diepe gronden.",
            "Na regen komt zonneschijn.",
        } },
        { id = "jokes", name = "Jokes", shortcut = "jokes", mode = "shuffle", channel = "SAY", lines = {
            -- [SP] A-E
            "Als een boer niet zwemmen kan, ligt het aan het water.",
            -- [SP] K-O
            "Men kan niet door een muur lopen, behalve als er een deur in zit.",
            -- [SP] P-U
            "Denken moet je aan een paard overlaten, dat heeft een groter hoofd.",
            -- [SP] V-Z
            "Voorzichtigheid is de moeder van de porseleinkast.",
        } },
    },
})

-- ---------------------------------------------------------------------------
-- dutch-everyday v2: v1 lines kept verbatim (first in each pool); additions are
-- common everyday expressions, not quotations.
-- ---------------------------------------------------------------------------
IC.Library.Register({
    id = "dutch-everyday", title = "Dutch: alledaags", version = 2,
    culture = "Dutch", locale = "nlNL", author = "In Character contributors",
    source = "Common everyday Dutch expressions, curated for this addon; not attributed to a character or show.",
    contentNote = "General Dutch greetings, farewells, toasts, cheers and mild teasing, separate from the explicit Mastermovies pack.",
    pools = {
        { id = "greetings", name = "Greetings", shortcut = "greetings", mode = "shuffle", channel = "SAY", lines = {
            "Goedemorgen!", "Goedemiddag!", "Hoi, hoe gaat het?", "Gezellig!",
            "Goedenavond!", "Hoi allemaal!", "Hallo allemaal!", "Dag allemaal!", "Hoi hoi!",
            "Hé, hoe is het?", "Alles goed?", "Lang niet gezien!", "Welkom!", "Goeiemorgen!",
        } },
        { id = "farewells", name = "Farewells", shortcut = "farewells", mode = "shuffle", channel = "SAY", lines = {
            "Tot ziens!", "Doei!", "Tot de volgende keer!", "Houdoe!",
            "Doei doei!", "Dag!", "Tot zo!", "Tot straks!", "Tot later!", "Tot morgen!",
            "Fijne avond nog!", "Fijn weekend!", "Welterusten!", "Slaap lekker!",
            "Doe voorzichtig!", "Ik ga ervandoor.",
        } },
        { id = "toasts", name = "Toasts", shortcut = "toasts", mode = "shuffle", channel = "SAY", lines = {
            "Proost!", "Gezondheid!", "Op je gezondheid!", "Santé!", "Daar drinken we op!",
            "Op ons!",
        } },
        { id = "battlecries", name = "Battle cries", shortcut = "battlecries", mode = "shuffle", channel = "SAY", lines = {
            "Hup Holland hup!", "Kom op!", "Zet 'm op!", "Daar gaan we!", "Gaan met die banaan!",
            "Hup, hup, hup!", "Hou vol!",
        } },
        { id = "banter", name = "Banter", shortcut = "banter", mode = "shuffle", channel = "SAY", lines = {
            "Lekker bezig!", "Goed bezig!", "Doe normaal!", "Doe even normaal, joh.", "Rustig aan, joh!",
            "Nou, nou!", "Hou toch op!", "Echt niet!", "Ach, joh.", "Schiet eens op!", "Jij bent ook een mooie.",
        } },
    },
})

-- ---------------------------------------------------------------------------
-- dutch-mastermovies v2: all owner-supplied v1 lines kept verbatim.
-- Added line source: nl.wikipedia "Born to Be Alive (nummer)", section
-- "In populaire cultuur > Nicht Rijder", which quotes Michael Nicht shouting
-- "Village People 360 kick bitch!" in the Mastermovies fundub Zeebats.
--   https://nl.wikipedia.org/wiki/Born_to_Be_Alive_(nummer)
-- The same article documents the running gag behind the owner's line
-- "Born to be Alive is niet van de Village People!".
-- Note: per nl.wikipedia "Mastermovies" (https://nl.wikipedia.org/wiki/Mastermovies),
-- Mastermovies was a fundub duo (Paul Huig, Merijn Scholte-Albers); Michael Nicht
-- is the main character of their Knight Rider parody "Nicht Rijder".
-- ---------------------------------------------------------------------------
IC.Library.Register({
    id = "dutch-mastermovies", title = "Mastermovies: Michael Nicht", version = 2,
    culture = "Dutch / Mastermovies", locale = "nlNL", author = "Project owner; In Character contributors",
    source = "Verbatim lines supplied by the project owner on 2026-11-08, extracted as data from three macros; attribution not independently verified. v2 adds one line quoted in nl.wikipedia 'Born to Be Alive (nummer)' (https://nl.wikipedia.org/wiki/Born_to_Be_Alive_(nummer)), which also documents the Village People running gag in Mastermovies' Nicht Rijder fundubs (https://nl.wikipedia.org/wiki/Mastermovies).",
    contentNote = "Optional Dutch parody preset; explicit language and sexual insults, including homo used as an insult. Review before use. No audio.",
    icon = IC.Icons[5],
    pools = {
        { id = "greetings", name = "Greetings", shortcut = "greetings", mode = "random", channel = "SAY", lines = {
            "hallo klootviolen", "goeie middag klootviool", "nasi goreng biatch, sambal bij", "wat moet je kutt", "hoe gaat ie met jou?",
        } },
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "random", channel = "SAY", lines = {
            "michael, wat zijn dat voor bloemen?", "ik douw bami pang pang in je reet", "ik ben homo met je ex",
            "Born to be Alive is niet van de Village People!", "krijg nou een bakkie pleur", "klootviool",
        } },
        { id = "farewells", name = "Farewells", shortcut = "farewells", mode = "random", channel = "SAY", lines = {
            "ik check je later, homies for life, later!", "later klootviool",
        } },
        { id = "battlecries", name = "Battle cries", shortcut = "battlecries", mode = "random", channel = "SAY", lines = {
            -- nl.wikipedia "Born to Be Alive (nummer)", In populaire cultuur > Nicht Rijder
            "Village People 360 kick bitch!",
        } },
    },
})
