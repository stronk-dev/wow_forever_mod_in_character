# Preset library

Presets are ready-made RP characters, grouped in families: **The Office**, **Dutch politics**, **Dutch**, **World** and **Fundubs**. Pick one from the character switcher (the first row of your RP list: your own characters first, then one row per family), or open **/ic → RP lines → Preset characters**, choose a family and a character and click **Play as this character**: you start playing it. Nothing is sent to chat.

**Your edits sit on top of the preset.** Reword a line, delete one or add your own, and only those changes are stored. When the addon updates a preset, its new lines and slots show up in the character you already play, and your changes stay: a reworded line keeps your wording, a deleted line stays gone, your own lines stay. If an update drops a line you had reworded, your version stays as your own line. **Delete character** (RP lines page) removes a character and your changes; the preset stays in its family, ready to play fresh.

Each preset fills the slots it has lines for: **Greeting**, **Quote**, **Farewell**, **Joke**, **Toast**, **Battle cry** and **Banter**. The last four only show on your RP list when the character (or a shared pool) has lines for them.

| Family | Character | Language | Lines |
| --- | --- | --- | --- |
| The Office | **Michael Scott** (`office-michael`) | English | 2 greetings, 5 quotes, 1 farewell, 3 jokes, 2 toasts, 2 battle cries, 3 banter |
| The Office | **Dwight Schrute** (`office-dwight`) | English | 2 greetings, 5 quotes, 2 jokes, 4 battle cries, 4 banter |
| The Office | **Jim Halpert** (`office-jim`) | English | 2 greetings, 2 farewells, 2 jokes, 1 toast, 6 banter |
| The Office | **Stanley Hudson** (`office-stanley`) | English | 5 greetings, 6 quotes, 5 farewells, 2 jokes, 1 battle cry, 1 banter |
| The Office | **Andy Bernard** (`office-andy`) | English | 2 greetings, 4 quotes, 1 farewell, 1 joke, 2 toasts, 2 battle cries, 3 banter |
| The Office | **Kevin Malone** (`office-kevin`) | English | 1 greeting, 2 quotes, 2 farewells, 2 jokes, 3 banter |
| The Office | **Creed Bratton** (`office-creed`) | English | 2 greetings, 4 quotes, 1 farewell, 3 jokes, 1 toast, 2 battle cries, 2 banter |
| The Office | **Angela Martin** (`office-angela`) | English | 4 quotes, 2 farewells, 1 joke, 1 battle cry, 4 banter |
| The Office | **Pam Beesly** (`office-pam`) | English | 3 greetings, 1 quote, 1 farewell, 2 jokes, 2 toasts, 1 battle cry, 3 banter |
| Dutch politics | **Rita Verdonk** (`nl-verdonk`) | Dutch | 4 quotes, 2 farewells, 1 banter |
| Dutch politics | **Mark Rutte** (`nl-rutte`) | Dutch | 10 quotes, 2 farewells, 5 banter |
| Dutch politics | **Jan Peter Balkenende** (`nl-balkenende`) | Dutch | 6 quotes, 1 banter |
| Dutch politics | **Pim Fortuyn** (`nl-fortuyn`) | Dutch | 1 greeting, 6 quotes |
| Dutch | **Dutch sayings** (`dutch-sayings`) | Dutch | 4 greetings, 12 quotes, 6 farewells, 4 jokes, 5 toasts, 7 battle cries, 12 banter |
| Dutch | **alledaags** (`dutch-everyday`) | Dutch | 14 greetings, 16 farewells, 6 toasts, 7 battle cries, 11 banter |
| World | **Tavern regular** (`world-tavern`) | English | 12 greetings, 14 quotes, 10 farewells, 10 jokes, 12 toasts, 10 battle cries, 11 banter |
| World | **Adventurer** (`world-adventurer`) | English | 11 greetings, 15 quotes, 10 farewells, 10 jokes, 9 toasts, 12 battle cries, 12 banter |
| World | **Merchant** (`world-merchant`) | English | 10 greetings, 12 quotes, 10 farewells, 10 jokes, 13 banter |
| Fundubs | **Michael Nicht** (`dutch-mastermovies`) | Dutch | 5 greetings, 6 quotes, 2 farewells, 1 battle cry |

## Where the lines come from

- **Quotations are real.** Lines for The Office characters (checked word for word against episode transcripts), Dutch politicians and Mastermovies were said by that person or character. Each one has its source (episode, interview, debate, article) in a comment above it in `InCharacter/Data/Library/`. Nothing is written "in the style of" anyone.
- **Politicians:** famous one-liners, gaffes and debate moments, traced to Wikiquote, NOS, Parlement.com, Wikipedia and newspapers. Lines that demean groups of people were left out on purpose.
- **Mastermovies:** a Dutch fundub group (Paul Huig and Merijn Scholte-Albers); Michael Nicht is the main character of their Knight Rider parody *Nicht Rijder*. The project owner supplied the original lines verbatim; one was added from Wikipedia. Contains explicit language.
- **Dutch sayings** are real proverbs and expressions, checked against the Wikipedia lists of Dutch proverbs and sayings. **Dutch: alledaags** is common everyday Dutch.
- **World characters** (tavern regular, adventurer, merchant) are original lines written for In Character. They fit any race or faction and use no game terms.

Stanley and Mastermovies contain profanity; each preset shows a content note in the editor. These are text presets only; no audio is sent.

## Adding a preset

Copy `docs/PresetTemplate.lua.example` into `InCharacter/Data/Library/`, list it in both `.toc` files, and fill in real, sourced lines (or mark them as original). Pool `shortcut` values are the slot ids: `greetings`, `quotes`, `farewells`, `jokes`, `toasts`, `battlecries`, `banter`. Lines must be 255 bytes or less.

Preset pools record `provenance` and a `layer` (`hidden`, `edits`, `own`, `ids`). Lines are matched by their text, so rewording a line in a pack file shows the new wording to everyone who had not reworded it themselves.
