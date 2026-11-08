# In Character

A native Lua emote and dialogue launcher for **WoW Forever, interface 16001**. Quick actions put labeled, one-click buttons for your pins, everyday emotes and named dialogue pools near the cursor. Dialogue can be a **specific message**, a random line, a shuffled line or the next line in order.

## Install

[GitHub Releases and installable ZIPs](https://github.com/stronk-dev/wow_forever_mod_in_character/releases)

Download the named **InCharacter-0.7.0.zip** asset, rather than GitHub's generated source archive. Extract it into `World of Warcraft/_forever_/Interface/AddOns/` so `AddOns/InCharacter/InCharacter.toc` exists. Enable it at character select. For a local build, run `python3 scripts/package.py`; the ZIP is written to `dist/`.

This is a **test release**. Automated logic and UI callback tests pass; rendering and client behavior still need testing in Forever. Before upgrading, close WoW and back up both account and character `WTF/.../SavedVariables/InCharacter.lua` files.

## Get started

- Type **`/ic quick`** for the new action panel. It opens on your pins in a stable order. Tabs switch to **Emotes** or **My lines**. A pool button plays in its configured mode; its **...** control opens specific lines, with separate Random and Next controls. Opening, hovering and releasing the key never send anything.
- New installations open quick actions from the round **In Character** button. Existing launcher choices are preserved; choose **Quick actions** under **Home / setup** to change yours. Shift-drag moves the button. Right-click opens settings; `/ic` and **Options → AddOns → In Character** open the same controls.
- **Home / setup** assigns the quick-action key, offers the legacy circle as an optional style, toggles a favorites bar, and creates category bars. No fixed number of emotes or pools is required.
- **Emote library** starts with **Everyday emotes**, a smaller suggested selection plus commands you keep or pin. **All emotes** retains every definition so you can restore or try others. The quick lists can be switched to all commands explicitly. Sound and animation filters use your recorded observations, not reference guesses.
- **Dialogue & messages** manages named pools and their individual messages. Use any pool names you like. Greetings, Quotes and Farewells are empty starter examples, not a limit on the addon.
- **Favorite actions** reorders pins and offers Preview, Play, Unpin and Create bar. The first four visible favorites also have key bindings.
- **Bars, wheel & button** has scrollable controls for bar rows/columns, fill direction, icon size, labels and per-item visibility. Wheel and menu have separate **Edit items** controls. **Profiles** selects shared or private data and independently shared or private layouts.

To trim a category bar, right-click any of its buttons, or select the bar under **Bars, wheel & button → Edit shown / hidden items**. Uncheck unwanted actions. They stay in this editor so you can restore them; other bars keep their own choices. **Show listed / Hide listed** operates on the current search results. Set **Columns** and **Rows** for a fixed grid, or use **Rows = 0** to wrap automatically. Extra actions remain reachable through page arrows.

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

Quick actions are the default replacement for the wheel. They show a compact button grid rather than nested circles. **My lines** uses the actual pool names and optional preset groups: jokes, different farewell tones, or any other pools you create work identically. Pins remain in the order you chose. Pool counts have no fixed limit; pages keep all enabled actions reachable. Labels and explicit pool-mode text provide recognition even while icons are being reviewed.

In **Bars, wheel & button**, choose panel columns or opt into the **Legacy circle**. Its existing radius, size, page and neutral-centre controls remain available in that style. **Edit quick items** controls per-action visibility for either style, independently of menu/bar visibility. The legacy circle starts on labeled categories with a neutral centre and explicit navigation.

The panel always uses click confirmation. Legacy-circle experimental hold/release requires moving the cursor, then pausing over a playable action for at least 0.15 seconds before releasing the bound key. Releasing over a submenu, immediately after a page/context change, in the centre, or outside the circle sends nothing. `/ic wheel` is retained as an alias for quick actions. Hold/release behavior still needs a live-client test.

Bars support favorites, categories, all pools, one pool, a random-pool action, all messages in a pool, or one exact message. Visible arrows and mouse-wheel paging make every enabled entry reachable; page capacity adapts to the screen and grid settings. Columns and rows are physical dimensions; fill direction controls row-first or column-first placement. Titles move/collapse bars; right-click a title opens settings, and right-click a button edits that bar's items. Layout rebuilding waits until after combat; bar paging is unavailable during combat. Existing actions, the launcher menu and wheel remain available subject to client restrictions.

## Commands and keys

```text
/ic                         setup and editor
/ic quick                   labeled quick-action panel (or chosen legacy style)
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

- Shared data is `InCharacterDB`; character settings/layouts are `InCharacterCharDB`. Schema 6 adds curation and per-character observations while keeping positions, layouts, message IDs, text, pins and custom artwork. Old reference-based filters reset to All. Legacy realm-keyed originals remain available for recovery.
- Stored quotes have no addon length/count limit. Sending is conservatively limited to **255 UTF-8 bytes after literal pipe escaping**, with no control characters. Long messages remain editable and previewable; nothing is truncated or split into spam.
- Chat predicates are checked before selection. Known restrictions and reported send failures leave playback unchanged; nothing is queued. A silent server rejection may remain undetectable.
- Quick-use badges describe recorded checks on this character; untested actions say **Not checked**. Nearby-audio markers require an explicit **Another player heard it** observation. The Retail reference metadata is kept only as context in the review tool. Client token recognition establishes availability only. No custom addon audio is broadcast.
- Built-in emotes follow Charades' client-token-to-`DoEmote` path, with the namespaced API used only when `DoEmote` is unavailable. The addon reports Lua errors; a submitted request does not establish whether the client animated it.
- There are no timers that send chat, arbitrary slash/macro execution, spells, item use or targeting actions. Only direct player input dispatches an action.
- Profile import/export, custom emote authoring, native action-bar drag/drop and full UI localization remain deferred.

## Verification and contributions

Local results: **78 logic/library tests and 76 isolated mocked UI tests** pass under Lua 5.5.1 and LuaJIT 2.1, plus manifest/XML/Lua syntax and ZIP checks. Mocks do not establish visual quality, artwork availability or client compatibility. Test rendering, input, chat restrictions and saved-data persistence in the live client before relying on a release.

```sh
lua tests/run.lua && lua tests/ui.lua
luajit tests/run.lua && luajit tests/ui.lua
python3 scripts/verify.py && python3 scripts/package.py
```

GitHub Actions runs tests and uploads the installable ZIP on pushes/PRs. A version tag (`v0.7.0`) publishes the ZIP as a GitHub prerelease after CI passes. See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute code or presets. Original code is MIT; quotes and game assets retain their owners' rights.

The interaction choices draw on [OPie's documented quick/click modes and small-ring guidance](https://www.townlong-yak.com/addons/opie/guide), [first-hand requests for readable controls and personal messages in Stryk's](https://www.reddit.com/r/wowaddons/comments/1vi2gc8/stryks_emote_wheel/), and [SpeakEasy feedback about indistinguishable reused icons](https://www.reddit.com/r/wowaddons/comments/1x49kwb/speakeasy_emote_wheel_quick_chat_roleplay_lines/). These are design references and individual reports, not a representative user survey. No code or artwork from these additional projects was imported.
