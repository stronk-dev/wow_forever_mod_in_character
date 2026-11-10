local _, IC = ...
-- Sourced quotations of Dutch politicians. Every line has a source comment.
-- Lines were checked against the cited pages on 2026-11-10. Quotes about Islam,
-- immigrants or minorities were deliberately left out.

IC.Library.Register({
    id = "nl-verdonk", title = "NL politics: Rita Verdonk", version = 1,
    culture = "Dutch politics", locale = "nlNL", author = "In Character contributors",
    source = "nl.wikiquote.org/wiki/Rita_Verdonk; nl.wikipedia.org/wiki/Rita_Verdonk (Volkskrant, NOVA, nu.nl refs); Hart van Nederland 2025-03-12.",
    contentNote = "Real quotations of a public figure, for light-hearted roleplay. Text only.",
    pools = {
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "shuffle", channel = "SAY", lines = {
            -- https://nl.wikiquote.org/wiki/Rita_Verdonk (Elsevier, 'Niet rechts, niet links, maar recht door zee', 2006-04-05)
            "Ik ben niet links, ik ben niet rechts, maar ik ben recht door zee!",
            -- https://nl.wikiquote.org/wiki/Rita_Verdonk (campagnespot Trots op Nederland, 2010)
            "Het water staat ons aan de lippen.",
            -- https://nl.wikipedia.org/wiki/Rita_Verdonk (na uitzetting uit de VVD-fractie, september 2007)
            "Het gaat om mijn toekomst, maar ook om 620.555 voorkeurstemmen.",
            -- https://nl.wikipedia.org/wiki/Rita_Verdonk (reactie toen een imam weigerde haar een hand te geven; NOVA, 2004-11-22)
            "Dan hebben we gelijk iets om over te praten.",
        } },
        { id = "banter", name = "Banter", shortcut = "banter", mode = "shuffle", channel = "SAY", lines = {
            -- https://nl.wikipedia.org/wiki/Rita_Verdonk (over Mark Rutte, HP/De Tijd; Volkskrant 2007-06-05 'Verdonk: Rutte is niet echt rechts')
            "Hij is een fatsoenlijke VVD'er, maar niet echt rechts. Dat kan ik er niet van maken.",
        } },
        { id = "farewells", name = "Farewells", shortcut = "farewells", mode = "shuffle", channel = "SAY", lines = {
            -- https://www.hartvannederland.nl/politiek/beleid/artikelen/rita-verdonk-verlaat-politiek-een-bloody-shame (verklaring bij vertrek uit de politiek, 2025-03-12)
            "Ik wil meer flexibiliteit terug in mijn leven.",
            -- https://www.hartvannederland.nl/politiek/beleid/artikelen/rita-verdonk-verlaat-politiek-een-bloody-shame (idem, 2025-03-12)
            "Al die vaste, vaak langdurige vergaderingen en debatten heb ik nu wel genoeg gedaan.",
        } },
    },
})

IC.Library.Register({
    id = "nl-rutte", title = "NL politics: Mark Rutte", version = 1,
    culture = "Dutch politics", locale = "nlNL", author = "In Character contributors",
    source = "nl.wikiquote.org/wiki/Mark_Rutte; NOS terugblik 14 jaar Rutte (nos.nl/l/2526702, 2024-06-30); parlement.com; Factba.se transcript 2018-07-02.",
    contentNote = "Real quotations of a public figure, for light-hearted roleplay. Text only. Two lines are in English as originally said.",
    pools = {
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "shuffle", channel = "SAY", lines = {
            -- https://nos.nl/l/2526702 (NOS, 2024-06-30: terugkerend antwoord, o.a. formatie Rutte IV; ook parlement.com 'Nacht van Rutte (2021)')
            "Daar heb ik geen actieve herinnering aan.",
            -- https://nos.nl/l/2526702 (NOS, 2024-06-30: gevraagd naar zijn gebrek aan visie, 2013)
            "Visie is als de olifant die het uitzicht beneemt.",
                        -- https://nl.wikiquote.org/wiki/Mark_Rutte (H.J. Schoo-lezing, Rijksoverheid, 2013-09-02)
            "Dé manier om kwijt te raken wat we hebben, is vast te houden aan wat we hebben.",
            -- https://nl.wikiquote.org/wiki/Mark_Rutte (Metro Holland, 'Rutte heeft zestien miljoen bazen', 2015-03-16)
            "Ik heb zestien miljoen bazen.",
            -- https://nl.wikiquote.org/wiki/Mark_Rutte (Buitenhof, 2017-01-15)
            "De kans dat de VVD gaat regeren met de PVV is nul.",
            -- https://nl.wikiquote.org/wiki/Mark_Rutte (Nieuwsuur, 2013-04-11, over het sociaal akkoord; first two sentences)
            "Die auto die we rijden is nu 13, 14 jaar oud. We gaan eens een keer een nieuwe auto kopen.",
            -- https://nl.wikiquote.org/wiki/Mark_Rutte (NRC, 2021-08-09, reactie op IPCC-klimaatrapport)
            "We hebben net enorm goed gepresteerd op de Olympische Spelen, ik denk dat we dat op de Olympische Spelen van het klimaat ook kunnen.",
            -- https://parlement.com/nacht-van-rutte-2021-geen-actieve-herinnering (Kamerdebat 'functie elders', 2021-04-01)
            "Ik heb niet gelogen.",
            -- https://parlement.com/nacht-van-rutte-2021-geen-actieve-herinnering (Kamerdebat 'functie elders', 2021-04-01)
            "Ik heb mij dat achteraf verkeerd herinnerd. Ik betreur dat ten zeerste.",
            -- https://www.goodmorningamerica.com/amp/news/story/nato-secretarygeneral-calls-trump-daddy-123197665 (as NATO Secretary General next to Trump, NATO summit The Hague, 2025-06-25; English original)
            "Daddy has to sometimes use strong language to get them to stop.",
        } },
        { id = "banter", name = "Banter", shortcut = "banter", mode = "shuffle", channel = "SAY", lines = {
            -- https://nl.wikiquote.org/wiki/Mark_Rutte (Kamerdebat met Wilders, 2011-09-22; Volkskrant 2011-09-22)
            "Doe eens normaal man? Doe lekker zelf normaal! Tsjongejonge...",
            -- https://nl.wikiquote.org/wiki/Mark_Rutte (idem, 2011-09-22)
            "Lezen voordat u wat zegt!",
            -- https://nl.wikiquote.org/wiki/Mark_Rutte (idem, 2011-09-22)
            "Ik ben hier volkomen rustig.",
            -- https://nos.nl/l/2526702 (NOS, 2024-06-30: tegen premier Balkenende, motie van wantrouwen eind Balkenende IV)
            "Als u niet regeert, stap dan op.",
            -- https://rollcall.com/factbase/trump/transcript/donald-trump-remarks-bilat-mark-rutte-netherlands-july-2-2018/ (Oval Office, 2018-07-02, interrupting Trump; English original, two consecutive replies)
            "No. It's not positive.",
        } },
        { id = "farewells", name = "Farewells", shortcut = "farewells", mode = "shuffle", channel = "SAY", lines = {
            -- https://nos.nl/l/2526702 (NOS, 2024-06-30, afscheid als premier)
            "Het voelt heel weemoedig.",
            -- https://nos.nl/l/2526702 (NOS, 2024-06-30, afscheid als premier)
            "Ik heb alles gegeven; hart, ziel en lijf en hoofd.",
        } },
    },
})

IC.Library.Register({
    id = "nl-balkenende", title = "NL politics: Jan Peter Balkenende", version = 1,
    culture = "Dutch politics", locale = "nlNL", author = "In Character contributors",
    source = "nl.wikiquote.org/wiki/Jan_Peter_Balkenende; DNPP/RUG campagne TK2006 (Volkskrant 2006-10-30); linda.nl Algemene Beschouwingen.",
    contentNote = "Real quotations of a public figure, for light-hearted roleplay. Text only.",
    pools = {
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "shuffle", channel = "SAY", lines = {
            -- https://nl.wikiquote.org/wiki/Jan_Peter_Balkenende (Tweede Kamer, debat regeringsverklaring, 2002-07-26)
            "Eerst het zuur en dan het zoet.",
            -- https://nl.wikiquote.org/wiki/Jan_Peter_Balkenende (Tweede Kamer, 2006; also https://www.linda.nl/linda/oh-oh-den-haag/algemene-beschouwingen-opmerkelijke-momenten/)
            "Ik begrijp niet waarom u er zo negatief en vervelend over doet. Laten we blij zijn met elkaar. Laten we zeggen: 'Nederland kan het weer!', die VOC-mentaliteit. Over grenzen heen kijken! Dynamiek! Toch?",
            -- https://nl.wikiquote.org/wiki/Jan_Peter_Balkenende (Volkskrant, 'Kies alsjeblieft voor positieve energie', 2005-03-18)
            "Ik heb het een beetje gehad met al dat doorgeslagen negativisme. Daar heb ik het gewoon mee gehad.",
            -- https://nl.wikiquote.org/wiki/Jan_Peter_Balkenende (RTL Carrédebat, 2010-05-26, tegen presentatrice Mariëlle Tweebeeke)
            "U kijkt zo lief.",
            -- https://nl.wikiquote.org/wiki/Jan_Peter_Balkenende (Tweede Kamer, debat rapport-Davids, 2010-01-13)
            "Als je met de inzichten van nu terug zou kijken, denk ik dat je het anders zou hebben gedaan.",
            -- https://nl.wikiquote.org/wiki/Jan_Peter_Balkenende (EenVandaag, 2010-01-12)
            "Met de kennis van nu ga je altijd kijken wat er toen is gebeurd, alleen ik vind wel dat je wat toen is gebeurd ook moet bezien vanuit de kennis die we toen hadden.",
        } },
        { id = "banter", name = "Banter", shortcut = "banter", mode = "shuffle", channel = "SAY", lines = {
            -- https://www.rug.nl/research/dnpp/verkiezingen/tweede-kamer/campagne-tweede-kamerverkiezingen-2006 (tegen Wouter Bos, lijsttrekkersdebat NOS Radio 1, 2006-10-29; Volkskrant 2006-10-30. nl.wikipedia gives "u bent niet eerlijk")
            "U draait en u bent oneerlijk.",
        } },
    },
})

IC.Library.Register({
    id = "nl-fortuyn", title = "NL politics: Pim Fortuyn", version = 1,
    culture = "Dutch politics", locale = "nlNL", author = "In Character contributors",
    source = "nl.wikiquote.org/wiki/Pim_Fortuyn; nl.wikipedia.org/wiki/Pim_Fortuyn; NOS Nieuwsuur 2022-05-06; Hart van Nederland 2021-05-06.",
    contentNote = "Real quotations of a public figure, for light-hearted roleplay. Text only. His statements about Islam and immigration are deliberately excluded.",
    pools = {
        { id = "greetings", name = "Greetings", shortcut = "greetings", mode = "shuffle", channel = "SAY", lines = {
            -- https://nl.wikiquote.org/wiki/Pim_Fortuyn (inauguratiespeech als lijsttrekker Leefbaar Nederland, 2001-11-26)
            "Ik heb d'r zin an. At your service.",
        } },
        { id = "quotes", name = "Quotes", shortcut = "quotes", mode = "shuffle", channel = "SAY", lines = {
            -- https://nos.nl/nieuwsuur/artikel/2427740-de-geest-van-pim-leeft-voort-in-rotterdam (NOS, 2022-05-06: "Fortuyns lijfspreuk")
            "Ik zeg wat ik denk en doe wat ik zeg.",
            -- https://www.hartvannederland.nl/nieuws/politiek/nederlanders-herdenken-vermoorde-pim-fortuyn (bij het wegrijden na zijn afzetting bij Leefbaar Nederland, 2002-02-10)
            "Ik word de nieuwe minister-president. Vergis je niet, ik word de nieuwe minister-president.",
            -- https://nl.wikipedia.org/wiki/Pim_Fortuyn (Volkskrant-interview 2002-02-09; apocrief aan Voltaire toegeschreven)
            "Ik kan uw mening nog zo abject vinden, maar ik zal uw recht verdedigen om die te uiten.",
            -- https://nl.wikipedia.org/wiki/Pim_Fortuyn (Volkskrant-interview 2002-02-09, toen hem werd gezegd dat zijn partij iets niet toestond)
            "Nou, daar moest ik me maar eens niet zoveel meer van aantrekken.",
            -- https://nl.wikiquote.org/wiki/Pim_Fortuyn (De verweesde samenleving; opening of a longer passage)
            "Een leider van formaat is vader en moeder ineen. Hij stelt de Wet en waakt over de samenhang van de kudde.",
            -- https://nl.wikipedia.org/wiki/Pim_Fortuyn (briefje op de deur van pastoor Louis Berger, 2002-05-05)
            "De partijleider staat voor uw deur en u bent er niet. Waar moet hij nu zijn biecht doen?",
        } },
    },
})
