# Community preset library

Presets are optional data packs. Nothing is installed into a player's profile or sent to chat automatically. In `/ic` → **Dialogue & messages**, choose a pack from the library dropdown, read the content/source notes, and click **Copy preset**. Each click makes new editable copies with unique IDs. **Copy + use for /ic greet, quote, bye** also maps available shortcuts to those copies. Installing a pack containing only Quotes leaves Greetings and Farewells mappings unchanged.

| Pack ID | Contents | Provenance |
| --- | --- | --- |
| `office-stanley` | 5 greetings, 5 quotes, 4 farewells | Project-owner supplied, preserved verbatim |
| `dutch-mastermovies` | 5 greetings, 6 quotes, 2 farewells | Project-owner supplied Michael Nicht/Mastermovies phrases, preserved verbatim; attribution not independently checked |
| `dutch-everyday` | 4 greetings, 4 farewells | Common Dutch expressions, not character quotations |
| `office-michael` | 1 short quote | [NBCUniversal](https://www.nbcuniversal.com/article/celebrating-20-years-office) |
| `office-jim` | 1 short quote, Jim impersonating Dwight | [NBCUniversal](https://www.nbcuniversal.com/article/celebrating-20-years-office), [Rainn Wilson interview](https://www.aol.com/rainn-wilson-says-playing-dwight-000000582.html) |
| `office-dwight` | 1 short quote | [Rainn Wilson interview](https://www.aol.com/rainn-wilson-says-playing-dwight-000000582.html) |

The Mastermovies pack includes the owner's explicit language and sexual insults. Stanley includes profanity. They remain opt-in and carry content notes in the editor. These are text presets; no custom voice clips are sent to nearby players.

The small additional Office samples are deliberately sourced rather than generated in a character's style. Pack metadata records culture, locale, source, author, content note and version. Contributing more characters, regional Dutch expressions, or independently verified Mastermovies provenance requires only a small data file and manifest entries; see [CONTRIBUTING.md](CONTRIBUTING.md).

Installed copies record `provenance = { pack, version, source }`. Updating pack files changes the library for future copies; it never replaces edited pools. Re-copying after an update creates a new version beside the old one. Delete unwanted copies in the editor. Preset versioning is independent of the SavedVariables schema.
