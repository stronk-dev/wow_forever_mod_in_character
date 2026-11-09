# In Character

Native Lua emotes and roleplay dialogue for **WoW Forever, interface 16001**. Use a radial wheel, a context menu, compact emote hotbars and labeled RP bars together. A normal Options screen chooses Bars, Context menu and Radial independently for Emotes and RP. RP playback follows the character you have loaded; emote choices remain independent. Pools can contain jokes, different farewell tones, character quotations or any other named collection; playback can use a specific line, random selection, shuffle or sequence.

## Install

Download **InCharacter-0.11.0.zip** from [GitHub Releases](https://github.com/stronk-dev/wow_forever_mod_in_character/releases) when published, or build locally with `python3 scripts/package.py`. Extract into:

```text
World of Warcraft/_forever_/Interface/AddOns/InCharacter/
```

`InCharacter.toc` must be directly inside that folder. Enable the addon, then `/reload`. `/console scriptErrors 1` enables Lua error reports. Before upgrading, close WoW and back up both account and character `WTF/.../SavedVariables/InCharacter.lua` files.

**Test release:** automated logic/callback checks pass; appearance, mouse behavior, sound and client restrictions still require testing inside Forever.

## Open what you need

| Presentation | Direct access | Controls |
| --- | --- | --- |
| Radial wheel | `/ic wheel`, its own key, Options → Open radial | Categories, nested groups, favorites, pool playback and specific messages. |
| Context menu | `/ic menu`, its own key, Options → Open menu | Categories and nested flyouts with Back and paging. |
| RP bar | `/ic bars`, its own key, Options → Show RP bar | Click a pool to play; right-click to open a persistent bar of its exact lines. |
| Emote bars | Options and Edit layouts | Pins, one category, several categories combined, all enabled emotes or mixed favorites. |
| Settings | `/ic`, Options → AddOns → In Character | Emotes, dialogue, favorites, layouts, profiles and the preset library. |

**The wheel key always opens the wheel**, regardless of the optional quick-style preference. Bars remain available alongside either popup. The optional panel still has `/ic quick` and a separate key binding.

New installations use launcher **left-click = radial**, **right-click = context menu**, **middle-click = edit layouts**. Existing left-click choices are preserved. Configure all three independently under Layouts or by selecting the launcher in Edit Mode. **Shift-right-click** opens settings outside Edit Mode; Shift-drag moves the launcher. Options and the Blizzard settings entry also have direct presentation buttons.

No keys are assigned automatically. In-addon key capture and **Key Bindings → In Character** expose settings, radial, context menu, RP bar, edit layouts, optional quick style and favorite 1–4. Key capture listens only after a deliberate click and cancels on Escape, window/tab closure, combat or timeout.

## Options and loaded RP characters

**`/ic` → Options** has two rows, **Emotes** and **RP dialogue**, with independent **Bars / Context menu / Radial** checkboxes. It also exposes the main emote bar's source, icon size and reviewed/all-recognized selection directly. There is no exclusive interface mode. **Show emote bars** unhides/expands existing emote bars and creates one if none exists; **`/ic emote-bars`** does the same. **Bare emote bar** makes the main bar compact while retaining its contents and position.

At the top, choose the **loaded RP character**: Stanley Hudson, Michael Nicht, another preset or a character you create. Loading a preset for the first time creates editable copies. Loading it again reuses those copies and preserves edits. **Copy preset** creates an additional character/copy without switching who you are playing; **Load character** switches explicitly. No selection or load action sends chat.

Each RP character owns named pools of any kind. Create jokes, different farewell tones, observations or any other collections. **Dialogue & messages** normally lists the loaded character's pools. **All stored pools** exposes other saved content for management, and each pool's **Character** dropdown can assign it to another character. Names, text, icons and message IDs are preserved.

The loaded selection is saved separately for each actual WoW character and for shared/private profile scope. Menu, radial, bars, favorites, shortcut commands and exact-message sends all enforce that selection. A stale pin or old bar cannot speak another character's lines. Missing Greetings/Farewells shortcuts do not fall back to a different character's pools. Emotes are unaffected by changing RP character.

## One mode for editing layouts

Type **`/ic edit`** or click **Move / resize** in Options. `/ic arrange` is an alias. Where the client provides Blizzard's `EditMode.Enter` / `EditMode.Exit` callbacks, WoW's Edit Mode opens and closes these same controls.

- Click a highlighted bar to select it. Drag the highlighted area to move it. Drag its **bottom-right corner** to resize width and height.
- The inspector changes the selected bar's source, appearance, dimensions, button size, emote filter, active categories, visibility, lock and RP tabs/group. Changes update the actual bar.
- Select hidden bars from the list to unhide them. Add multiple emote or RP bars. **Items / icons** opens that bar's item editor; **Full bar settings** exposes further options. Radial and context item editors are also linked here.
- Click the launcher to configure its mouse actions, size and visibility; drag it without Shift while editing.
- **Undo** restores the layout from when this edit session began. Dialogue edits remain intact. **Done** or Escape leaves editing. No action can be played while layout editing is active.

In Character stores layouts separately from Blizzard's named layouts. Enter/exit integration does not register custom secure systems or make Blizzard's Save/Revert manage addon data; use the addon's Undo for addon layout changes. The standalone editor works when the client lacks those callbacks. The live Forever bridge remains unverified.

RP bars, specific-line bars and icon grids also have a normal resize grip during play when unlocked. Their title moves/collapses them; **…** or title right-click opens the same layout inspector. **×** hides RP/message bars. Compact emote strips hide their editing frame during normal play; Shift-drag moves them, and Edit Mode exposes resizing.

## Emote contents and compact sizing

A bare strip occupies only its visible buttons during play: two 24-unit buttons occupy **52 × 26 UI units**, including spacing. There is no title, background or unused panel in the normal view. The larger width/height allowance is shown only in Edit Mode and controls wrapping/paging; entering/leaving editing keeps the first button in place. **Icon size** can be reduced to 12 units directly in Options. Up to four rows and overflow paging remain available. Names are in tooltips, with optional labels. Icon grids and wide labeled buttons remain selectable; changing manual grid rows/columns switches away from a resized viewport.

Choose **Enabled emote categories (combined)** and tick any combination of Combat, Social, Reactions, Idle and Voice/Fun. Duplicate client actions appear once. **+ Emote hotbar** creates this layout directly. You can also choose pinned emotes, all emotes, one pool, all pools, all messages in a pool or a specific message/action.

Each bar has an independent emote selection:

- **My profile choices** respects your everyday/review selection and filters.
- **All recognized commands** exposes the full set recognized by this client, including commands omitted by the everyday selection.
- **Explicitly kept only** starts with commands you marked Keep.

In **Items / icons**, filtered emotes explain why they are absent. **Checking one includes it on that bar**, without changing other bars or your global review. Uncheck to hide it again. **Show listed / Hide listed** acts on the current search results. Unrecognized definitions remain flagged; they cannot be forced into recognized-only lists. A profile explicitly showing unverified definitions can display them as unavailable, but dispatch still refuses them.

The icon picker supports command/texture search, suggested categories, client macro icons and manual paths/file IDs. Each message can have its own icon. Custom artwork persists. Recognition does not establish that an emote animates or makes sound.

**`/ic review`** checks emotes one at a time: Try, Keep, Hide, Duplicate, text-only and icon approval. Sound/animation observations belong to the current character; usefulness and icons belong to the active profile. Nothing automatically marks an emote audible or its icon correct. **You heard** and **Another player heard it** are separate observations. The complete definition list remains accessible in the editor.

## RP pools and exact messages

Create any named pool under **Dialogue & messages**. Choose SAY/YELL/EMOTE, its playback mode and icon, enter one message per line, then Save. The optional [preset library](LIBRARY.md) copies editable Office/Dutch examples. Empty Greetings/Quotes/Farewells starters and their shortcuts are conveniences, with no restriction on new pool types.

RP bars contain only pools owned by the loaded character. Their title identifies that character; redundant single-group tabs are omitted. Tabs can organize mixed-provenance pools within that character when needed. Its mode button cycles Random, Shuffle, In order and each pool's saved mode. Empty pools can be hidden. Tabs can be hidden and a particular group selected in the inspector to make a smaller dedicated bar. On All pools, labels distinguish the preset; selecting a preset shortens labels. Pool names and original text are retained.

Right-click a pool button for a persistent **specific-line bar**. Click a line to send exactly that message; this does not advance a pool's sequence or shuffle. Choosing another pool reuses that companion bar while keeping its size and position. Resize or page it like other bars. Shift-right-click a pool button edits its shown/hidden items.

The message editor supports create/edit/delete/reorder, Preview, Play next, Random, exact-message sending, per-message icons, favorites and dedicated bars. Stable IDs keep exact-message pins attached through message edits/reorders; deleted messages never retarget another line. Bulk text replacements receive new IDs where appropriate. Unsaved message/pool drafts survive navigation and closing the editor until `/reload`; Save is required for persistence. Playback refuses pending drafts. Preview sends nothing and does not consume selection state.

Random allows repeats; shuffle visits each item once per cycle; sequential loops in order. Explicit playback overrides have independent state, so Random does not disturb the normal sequence. Selection state is session-only.

## Radial and context controls

The radial starts on labeled categories with a neutral center. Click to navigate; pointing across a sector never activates an action. Center goes back or cancels at the root. Right-click/Escape cancels, and arrows/scroll page long lists. Radius, icon size, items per page, center size and click/experimental hold mode have their own settings, independently of quick style or bars.

Experimental hold/release requires cursor movement and at least 0.15 seconds over a playable action. Releasing over navigation, immediately after a page change, at the center or outside sends nothing. This needs a live-client input test.

The compact context menu starts with the loaded character selector and up to three RP pool buttons. **Click a pool to play once**; use its separate **>** button for playback choices or exact lines. Hovering a pool never sends or opens its details accidentally. Additional pools remain under **More RP pools**. Two favorite emotes stay near the front; **Emote categories** contains grouped commands, all favorites and the full recognized A–Z list. **Show emote bars** and **Options** remain directly accessible. The root fits within twelve rows before user visibility settings.

Menus and the editor use Blizzard panel artwork, native panel buttons, checkboxes and slider tracks. Radial, menu and bar visibility choices remain independent. Right-click playable menu items to pin/unpin; Shift-right-click hides them from that menu. Use the item editor to restore hidden entries. Back, paging, outside click and Escape remain supported.

## Commands

```text
/ic                          settings
/ic wheel                    radial wheel
/ic menu                     context menu
/ic bars                     show / expand RP bar
/ic emote-bars               show / recover emote bars
/ic character <name or ID>    load an RP character or preset
/ic edit                     edit all layouts
/ic arrange                  alias for edit
/ic quick                    optional quick style
/ic review                   one-by-one emote checks
/ic emotes                   emote library
/ic My Custom Pool           play a named pool
/ic play random My Pool      explicit random playback
/ic play shuffle My Pool     explicit shuffle playback
/ic play sequential My Pool  explicit in-order playback
/ic message <pool> <id>      exact message
/ic greet | quote | bye      optional starter shortcuts
/ic help
```

Use `/ic pool <exact pool ID>` for duplicate/reserved names. If another addon owns `/ic` when this addon loads, use `/incharacter`.

## Persistence, safety and limits

Shared data is `InCharacterDB`; character data is `InCharacterCharDB`. Profiles and layouts independently support shared/private scope. Schema 10 separates stored RP characters and adds independent presentation choices. Existing custom pools and preset copies are grouped without deleting or replacing text, icons or IDs. Latest preset copies remain separately loadable from older saved copies. Explicit legacy shortcut mappings can identify the previously selected character; ambiguous combinations fall back to My character until you choose. Selected styles, positions, review decisions and explicit empty collections are retained. Updates no longer convert existing emote grids or replace a chosen popup style. Legacy migration records remain for recovery.

Stored messages have no addon length/count limit. Sending uses a conservative **255-byte limit after literal pipe escaping**, without truncating or splitting. Only direct user input dispatches chat/emotes; there is no timed sending, macro evaluation, spell/item/target automation or custom audio broadcast. Client predicates are checked before selection, and reported failures preserve playback state. Silent server rejection may remain undetectable.

Editing stops on combat entry; UI rebuilding waits until safe. Existing playable actions and popups remain subject to client restrictions. Bar paging, group/mode changes and opening a new specific-line bar wait until after combat. No chat is queued or replayed.

Profile import/export, custom emote authoring, native Blizzard action-bar drag/drop and full localization remain deferred.

## Tests and contributions

**101 logic/library tests and 125 isolated mocked UI tests** pass under Lua 5.5 and LuaJIT, plus manifest/XML/Lua syntax and ZIP checks. Mocks exercise callbacks, resize calculations, filtering, input and persistence—not live appearance or the actual client Edit Mode implementation.

```sh
lua tests/run.lua && lua tests/ui.lua
luajit tests/run.lua && luajit tests/ui.lua
python3 scripts/verify.py && python3 scripts/package.py
```

GitHub Actions tests pushes/PRs and uploads an installable ZIP. A version bump on the default branch, or an explicit version tag, publishes that ZIP as a prerelease after CI passes; documentation-only pushes and PRs do not publish releases. See [CONTRIBUTING.md](CONTRIBUTING.md) for code/preset contributions. Original code is MIT; retained Charades attribution/license details are in `InCharacter/THIRD_PARTY_NOTICES.txt`. Quotes and Blizzard assets retain their owners' rights.
