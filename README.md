# In Character

A native Lua emote and dialogue launcher for **WoW Forever, interface 16001**. Persistent bars put your emotes and named RP pools one click away. A separate **Roleplay bar** has readable pool buttons and visible tabs for your preset sets and custom lines. Dialogue can be a **specific message**, a random line, a shuffled line or the next line in order.

## Install

[GitHub Releases and installable ZIPs](https://github.com/stronk-dev/wow_forever_mod_in_character/releases)

Download the named **InCharacter-0.9.0.zip** asset, rather than GitHub's generated source archive. Extract it into `World of Warcraft/_forever_/Interface/AddOns/` so `AddOns/InCharacter/InCharacter.toc` exists. Enable it at character select. For a local build, run `python3 scripts/package.py`; the ZIP is written to `dist/`.

This is a **test release**. Automated logic and UI callback tests pass; rendering and client behavior still need testing in Forever. Before upgrading, close WoW and back up both account and character `WTF/.../SavedVariables/InCharacter.lua` files.

## Get started

- Type **`/ic bars`** to show the **Roleplay bar**. It stays on screen after playing. **Left-click a pool** to play one line. **Right-click a pool** to open a second, persistent bar of its specific lines; click any line to send exactly that message. Opening bars and switching tabs send nothing.
- The RP bar's visible tabs select **All pools**, **My lines**, or an installed preset set such as **Stanley Hudson** or **Michael Nicht**. The playback button in its title cycles **Random → Shuffle → In order → Pool mode**. Pool mode uses each pool's own saved setting. Empty pools are hidden by default.
- **Drag a bar's title** to move it; click the title to collapse it. **×** hides the bar. **…** opens that bar's settings: rows, columns, size, labeled-button width, icon/text appearance, playback and shown/hidden items. Specific-line bars have their own grid and reuse the same window when you choose a different pool, keeping your placement.
- New installations show a separate **compact emote hotbar** with action-button artwork, hidden names and no panel background during normal play. It starts with pinned emotes; choose **Enabled emote categories (combined)** to feed several categories into one bar. Their actions appear once, with your review filters and individual hidden-item choices still applied.
- The round **In Character** button and the quick-access key toggle the RP bar by default. Shift-drag moves the button; right-click opens settings. `/ic` and **Options → AddOns → In Character** open the same controls. Existing launcher menu choices are preserved. On upgrading from 0.7's popup style, quick access switches to the persistent bar once; optional popup/circle styles remain selectable.
- **Home / setup** shows and hides the RP and emote bars, has **Arrange** for compact bars, and assigns the quick-access key. **Bars, wheel & button** adds other bars, including category bars. There is no fixed number of emotes, pools or messages.
- **Emote library** starts with **Everyday emotes**, a smaller suggested selection plus commands you keep or pin. **All emotes** retains every definition so you can restore or try others. The quick lists can be switched to all commands explicitly. Sound and animation filters use your recorded observations, not reference guesses.
- **Dialogue & messages** manages named pools and their individual messages. Use any pool names you like. Greetings, Quotes and Farewells are empty starter examples, not a limit on the addon.
- **Favorite actions** reorders pins and offers Preview, Play, Unpin and Create bar. The first four visible favorites also have key bindings.
- **Bars, wheel & button** has scrollable controls for bar rows/columns, fill direction, icon size, labels and per-item visibility. Wheel and menu have separate **Edit items** controls. **Profiles** selects shared or private data and independently shared or private layouts.

## Fit emotes into your hotbar space

Type **`/ic arrange`**, or click **Home / setup → Arrange**. An outline shows the space each unlocked compact hotbar occupies. **Drag its left handle to move it; drag the right handle horizontally to resize it.** Icons refit live. Click **Done** or press Escape to hide the outlines and handles. Shift-drag an emote button to move its bar without opening Arrange. Dragging never performs the action.

In **Bars, wheel & button**, select an emote bar and choose **Compact auto-fit hotbar** under appearance. Its **Hotbar width** slider provides the same width control as dragging; **Maximum icon size** limits how large icons grow. **Hotbar rows** defaults to one and supports up to four. Icons shrink to fit the selected space, with a minimum of 20 UI units; additional actions use small inline page arrows or mouse-wheel paging rather than becoming unreadable. Width is independent of how many actions are currently enabled. Names remain available in tooltips, with optional labels in settings.

Choose **Enabled emote categories (combined)** under **Shows**, then click **Choose categories** and check the categories to include. **+ Emote hotbar** creates this combined layout directly. You can still use only pinned emotes, a single category, all enabled emotes or mixed favorites. **Classic icon grid** retains manual rows/columns; labeled RP bars keep their own layout.

To trim a category bar, right-click any of its buttons, or select the bar under **Bars, wheel & button → Edit shown / hidden items**. Uncheck unwanted actions. They stay in this editor so you can restore them; other bars keep their own choices. **Show listed / Hide listed** operates on the current search results. For a classic grid, set **Columns** and **Rows**, or use **Rows = 0** to wrap automatically. Extra actions remain reachable through page arrows.

Emote artwork is mapped by command rather than copied from the category icon. Existing custom artwork is preserved. The icon picker has action/texture search, suggested categories, client macro icons and manual texture/file IDs. Each saved message can have its own icon: open **Browse / edit messages** and click the icon beside its text. **Reset** inherits the pool icon again. Shared icons identify the same action across layouts; hiding is independent for each layout.

## Check emotes one at a time

**`/ic review`** starts with the everyday selection. **Try it now** performs one emote on your click. Record whether you heard it, another player heard it, and whether an animation was visible. Click the artwork to change its icon and mark whether it fits. **Keep & next**, **Hide & next**, or **Save & next** records your decision; **Skip** leaves it undecided.

Mark an entry as a duplicate with an optional `/command` reference, or as text-only. These choices filter everyday use without deleting commands, favorites or custom text. They never redirect an action to a different emote. Exact client-token aliases appear together in the review pass. The full definition list stays accessible in the editor.

The review sets also cover all unchecked commands, all recognized commands and unchecked icons. Playback never marks a sound, animation or icon correct automatically. Usefulness and icon choices belong to the active profile; sound/animation observations belong to the current character. **You heard** does not become **Others heard**. These are your observations, not client telemetry or proof across different client builds. Save a decision before leaving an entry; unsaved review fields are discarded on navigation.

## Dialogue: choose what each click does

Create a pool, name it, choose SAY/YELL/EMOTE, select its normal playback mode, and enter one message per line. Save it. The optional preset library copies editable Office/Dutch culture examples; see [LIBRARY.md](LIBRARY.md). Nothing is sent by creating, saving, copying or previewing.

| Control | What it does |
| --- | --- |
| **Play next** | Sends one saved line using that pool's current mode. |
| **Random message** | Picks one saved line uniformly, with repeats possible. |
| **Browse / edit messages** | Opens the message list and an editor for the selected message. |
| **Send this message** | Sends exactly the selected, saved message. It does not advance any pool's playback. |
| **Preview only** | Shows the complete message in a scrollable local preview; nothing is sent. |
| **Pin message / Create message bar** | Makes a favorite or a bar for that exact message. |

The message browser also has New, Save, Discard, Move up/down, confirmed Delete, channel/mode dropdowns, a byte counter, and Play next/Random from pool buttons. Edited messages must be saved or discarded before **Send this message** is enabled. The main pool editor similarly refuses to play a saved pool while its bulk draft is pending.

Specific-message pins use stable IDs. Editing/reordering in the message browser keeps them pointing at the same message. Bulk text editing preserves IDs for unchanged/reordered text; replaced text receives new IDs, and the editor reports removed pins. A bar referencing a deleted message becomes visibly unavailable rather than sending another message.

Random/shuffle/in-order overrides appear in pool submenus. Each override has its own playback state; using Random does not disturb the normal shuffle or sequence. All selection states are session-only.

Pool and message drafts survive switching items/pages and closing the window until `/reload`. **Save** is required for persistence. Previewing does not consume a shuffle bag or sequence.

## Menus and radial wheel

The launcher menu shows favorites, emote categories and dialogue groups. Larger emote categories split into purpose-based groups such as **Orders & movement**, **Greetings & farewells**, **Affection** and **Jokes & music**. **All emotes · A–Z** uses alphabetical ranges. Each flyout has its own title, Back and visible paging arrows; mouse-wheel scrolling also works. Dialogue follows **group → pool → playback choices → Choose a specific message**. Hover or click opens a submenu. Right-click a playable action to pin/unpin it; Shift-right-click hides it from this menu. Restore it in **Edit menu categories / items**. Clicking outside or Escape closes the menu.

The **persistent Roleplay bar** is the default quick-access presentation. Your pool names determine its buttons: jokes, different farewell tones and any other named pools work identically. Preset tabs come from the copied preset's provenance, and **My lines** collects custom pools. On **All pools**, labels include the preset name to distinguish similarly named pools; selecting one preset shortens its labels. Full names remain in tooltips.

The former popup panel and radial circle remain optional under **Bars, wheel & button → Quick actions**. Panel columns apply only to the popup; ring radius, button size, paging and neutral-centre settings apply only to the circle. Their **Edit quick items** controls are independent of each bar's item choices.

The optional panel always uses click confirmation. Legacy-circle experimental hold/release requires moving the cursor, then pausing over a playable action for at least 0.15 seconds before releasing the bound key. Releasing over a submenu, immediately after a page/context change, in the centre, or outside the circle sends nothing. `/ic wheel` remains an alias for the chosen quick-access style. Hold/release behavior still needs a live-client test.

Bars support pinned emotes only, mixed favorites, categories, all pools, one pool, a random-pool action, all messages in a pool, or one exact message. Visible arrows and mouse-wheel paging make every enabled entry reachable; page capacity adapts to the screen and grid settings. Columns and rows are physical dimensions; fill direction controls row-first or column-first placement. Titles move/collapse bars; right-click a title opens settings, and right-click a button edits that bar's items. On the RP bar, right-click instead opens specific lines; use Shift-right-click for the item editor. Moving/resizing stops when combat starts; layout rebuilding waits until after combat; bar paging, preset switching, playback-mode changes and opening a new specific-line bar are unavailable during combat. Already visible action buttons remain usable subject to client chat restrictions. Existing actions, the launcher menu and wheel remain available subject to client restrictions.

## Commands and keys

```text
/ic                         setup and editor
/ic bars                    show and expand the persistent RP bar
/ic arrange                 toggle compact hotbar move / resize handles
/ic quick                   toggle the RP bar (or chosen optional style)
/ic review                  check emotes one at a time
/ic emotes                  emote library
/ic menu                    categorized menu at cursor
/ic wheel                   compatibility alias for quick actions
/ic My Custom Pool          normal playback from a named pool
/ic play random My Pool     explicit random playback
/ic play shuffle My Pool    explicit shuffle playback
/ic play sequential My Pool explicit in-order playback
/ic message <pool> <id>     an exact message (IDs shown in its editor)
/ic greet                   optional Greetings shortcut
/ic quote                   optional Quotes shortcut
/ic bye                     optional Farewells shortcut
/ic help
```

`/ic pool <exact pool ID>` resolves duplicate/reserved names. If `/ic` already belongs to another addon at load time, use `/incharacter`. No keys are assigned automatically. In-addon key capture and WoW's **Key Bindings → In Character** expose window, wheel, menu and favorite 1–4 bindings. Key capture listens only after you click a binding control; Escape, another click, closing the page, combat or 15 seconds without a selection cancels it.

## Data, metadata and safety

- Shared data is `InCharacterDB`; character settings/layouts are `InCharacterCharDB`. Schema 8 converts existing icon-based emote/category bars to compact strips once, retaining their position, source and hidden items; prior grid settings are retained under `previousGrid`. Selecting Classic icon grid thereafter stays selected. Mixed favorites and labeled RP/message bars retain their presentation. The previous migration adds an RP bar once to existing nonempty layouts. Deleted bars and deliberately empty layouts stay deleted/empty on reload; `/ic bars` can recreate an RP bar explicitly. Curation and per-character observations, message IDs, text, pins and custom artwork are retained. Old reference-based filters reset to All. Legacy realm-keyed originals remain available for recovery.
- Stored quotes have no addon length/count limit. Sending is conservatively limited to **255 UTF-8 bytes after literal pipe escaping**, with no control characters. Long messages remain editable and previewable; nothing is truncated or split into spam.
- Chat predicates are checked before selection. Known restrictions and reported send failures leave playback unchanged; nothing is queued. A silent server rejection may remain undetectable.
- Quick-use badges describe recorded checks on this character; untested actions say **Not checked**. Nearby-audio markers require an explicit **Another player heard it** observation. The Retail reference metadata is kept only as context in the review tool. Client token recognition establishes availability only. No custom addon audio is broadcast.
- Built-in emotes follow Charades' client-token-to-`DoEmote` path, with the namespaced API used only when `DoEmote` is unavailable. The addon reports Lua errors; a submitted request does not establish whether the client animated it.
- There are no timers that send chat, arbitrary slash/macro execution, spells, item use or targeting actions. Only direct player input dispatches an action.
- Profile import/export, custom emote authoring, native action-bar drag/drop and full UI localization remain deferred.

## Verification and contributions

Local results: **88 logic/library tests and 98 isolated mocked UI tests** pass under Lua 5.5.1 and LuaJIT 2.1, plus manifest/XML/Lua syntax and ZIP checks. Mocks do not establish visual quality, artwork availability or client compatibility. Test rendering, input, chat restrictions and saved-data persistence in the live client before relying on a release.

```sh
lua tests/run.lua && lua tests/ui.lua
luajit tests/run.lua && luajit tests/ui.lua
python3 scripts/verify.py && python3 scripts/package.py
```

GitHub Actions runs tests and uploads the installable ZIP on pushes/PRs. A version tag (`v0.9.0`) publishes the ZIP as a GitHub prerelease after CI passes. See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute code or presets. Original code is MIT; quotes and game assets retain their owners' rights.

The interaction choices draw on [OPie's documented quick/click modes and small-ring guidance](https://www.townlong-yak.com/addons/opie/guide), [first-hand requests for readable controls and personal messages in Stryk's](https://www.reddit.com/r/wowaddons/comments/1vi2gc8/stryks_emote_wheel/), and [SpeakEasy feedback about indistinguishable reused icons](https://www.reddit.com/r/wowaddons/comments/1x49kwb/speakeasy_emote_wheel_quick_chat_roleplay_lines/). These are design references and individual reports, not a representative user survey. No code or artwork from these additional projects was imported.

The persistent toolbar approach also follows [Total RP 3’s native movable toolbar](https://github.com/Total-RP/Total-RP-3/blob/main/totalRP3/Modules/Toolbar/Toolbar.lua): direct buttons, movable placement and saved visibility. The RP bar here uses this addon’s own widgets and dispatcher; no toolbar code was copied.
