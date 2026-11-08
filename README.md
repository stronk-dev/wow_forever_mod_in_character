# In Character

A native Lua emote and dialogue launcher for **WoW Forever, interface 16001**. Use a categorized menu, a radial wheel or configurable quick bars. Dialogue can be a **specific message**, a random line, a shuffled line or the next line in order.

## Install

[GitHub Releases and installable ZIPs](https://github.com/stronk-dev/wow_forever_mod_in_character/releases)

Download the named **InCharacter-0.6.0.zip** asset, rather than GitHub's generated source archive. Extract it into `World of Warcraft/_forever_/Interface/AddOns/` so `AddOns/InCharacter/InCharacter.toc` exists. Enable it at character select. For a local build, run `python3 scripts/package.py`; the ZIP is written to `dist/`.

This is a **test release**. Automated logic and UI callback tests pass; rendering and client behavior still need testing in Forever. Before upgrading, close WoW and back up both account and character `WTF/.../SavedVariables/InCharacter.lua` files.

## Get started

- Click the round **In Character** button for the menu. Shift-drag moves it. Right-click opens settings; `/ic` and **Options → AddOns → In Character** open the same controls.
- **Home / setup** lets you show/hide the launcher, assign the wheel key, choose click/experimental hold mode, toggle a favorites bar, or create bars for the five emote categories.
- **Emote library** has categories, search, reference metadata filters, previews/details, pinning, custom names and an icon picker. Runtime token recognition controls availability. Custom names apply in the menu, wheel and bars.
- **Dialogue & messages** manages named pools and their individual messages. Use any pool names you like. Greetings, Quotes and Farewells are empty starter examples, not a limit on the addon.
- **Favorite actions** reorders pins and offers Preview, Play, Unpin and Create bar. The first four visible favorites also have key bindings.
- **Bars, wheel & button** has scrollable controls for bar rows/columns, fill direction, icon size, labels and per-item visibility. Wheel and menu have separate **Edit items** controls. **Profiles** selects shared or private data and independently shared or private layouts.

To trim a category bar, right-click any of its buttons, or select the bar under **Bars, wheel & button → Edit shown / hidden items**. Uncheck unwanted actions. They stay in this editor so you can restore them; other bars keep their own choices. **Show listed / Hide listed** operates on the current search results. Set **Columns** and **Rows** for a fixed grid, or use **Rows = 0** to wrap automatically. Extra actions remain reachable through page arrows.

Emote artwork is mapped by command rather than copied from the category icon. Existing custom artwork is preserved. The icon picker has action/texture search, suggested categories, client macro icons and manual texture/file IDs. Each saved message can have its own icon: open **Browse / edit messages** and click the icon beside its text. **Reset** inherits the pool icon again. Shared icons identify the same action across layouts; hiding is independent for each layout.

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

The wheel opens with one ring of **labeled categories**, with no active category or action. **Click a category**, then a group or action. Hover never enters a group. The breadcrumb shows where you are; the centre returns **Back**, or cancels at the root. The centre and the gap before the ring select nothing. Arrows or scrolling change pages. Right-click or Escape cancels from any depth. A stationary cursor cannot select whatever appears under it when the wheel opens or changes pages.

Wheel controls include **ring radius**, **icon size**, **items per ring (4–12)** and **neutral centre size**. Eight entries per page is the default. **Edit wheel items** controls its categories and individual actions separately from menu/bar visibility. These are wheel geometry controls; bar rows/columns apply to rectangular bars.

Click confirmation is the default. Experimental hold/release requires moving the cursor, then pausing over a playable action for at least 0.15 seconds before releasing the bound key. Releasing over a submenu, immediately after a page/context change, in the centre, or outside the wheel sends nothing. `/ic wheel` always uses click confirmation. Hold/release behavior still needs a live-client test.

Bars support favorites, categories, all pools, one pool, a random-pool action, all messages in a pool, or one exact message. Visible arrows and mouse-wheel paging make every enabled entry reachable; page capacity adapts to the screen and grid settings. Columns and rows are physical dimensions; fill direction controls row-first or column-first placement. Titles move/collapse bars; right-click a title opens settings, and right-click a button edits that bar's items. Layout rebuilding waits until after combat; bar paging is unavailable during combat. Existing actions, the launcher menu and wheel remain available subject to client restrictions.

## Commands and keys

```text
/ic                         setup and editor
/ic emotes                  emote library
/ic menu                    categorized menu at cursor
/ic wheel                   radial wheel
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

- Shared data is `InCharacterDB`; character settings/layouts are `InCharacterCharDB`. Schema 5 adds presentation visibility, grid controls and per-message icons while keeping saved message IDs, text and custom artwork. Legacy realm-keyed originals remain available for recovery.
- Stored quotes have no addon length/count limit. Sending is conservatively limited to **255 UTF-8 bytes after literal pipe escaping**, with no control characters. Long messages remain editable and previewable; nothing is truncated or split into spam.
- Chat predicates are checked before selection. Known restrictions and reported send failures leave playback unchanged; nothing is queued. A silent server rejection may remain undetectable.
- Badges marked **(ref)** describe the Retail reference catalogue, not verified Forever audio/animation. Client token recognition establishes availability only. Check nearby sound with a second player. No custom addon audio is broadcast.
- Built-in emotes follow Charades' client-token-to-`DoEmote` path, with the namespaced API used only when `DoEmote` is unavailable. The addon reports Lua errors; a submitted request does not establish whether the client animated it.
- There are no timers that send chat, arbitrary slash/macro execution, spells, item use or targeting actions. Only direct player input dispatches an action.
- Profile import/export, custom emote authoring, native action-bar drag/drop and full UI localization remain deferred.

## Verification and contributions

Local results: **69 logic/library tests and 56 isolated mocked UI tests** pass under Lua 5.5.1 and LuaJIT 2.1, plus manifest/XML/Lua syntax and ZIP checks. Mocks do not establish visual quality, artwork availability or client compatibility. Test rendering, input, chat restrictions and saved-data persistence in the live client before relying on a release.

```sh
lua tests/run.lua && lua tests/ui.lua
luajit tests/run.lua && luajit tests/ui.lua
python3 scripts/verify.py && python3 scripts/package.py
```

GitHub Actions runs tests and uploads the installable ZIP on pushes/PRs. A version tag (`v0.6.0`) publishes the ZIP as a GitHub prerelease after CI passes. See [CONTRIBUTING.md](CONTRIBUTING.md) to contribute code or presets. Original code is MIT; quotes and game assets retain their owners' rights.
