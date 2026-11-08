# In Character

A native Lua emote and roleplay dialogue launcher for **World of Warcraft: Forever 1.60.x**, interface **16001**. No frameworks or runtime dependencies.

## Status

Phases 1–3 are implemented, with Phase 4 documentation, contribution workflow, CI configuration and ZIP packaging. **No live WoW client was available.** The code and mocked tests do not establish visual correctness or live compatibility; follow [FOREVER_TEST_CHECKLIST.md](FOREVER_TEST_CHECKLIST.md).

- Combat, Reactions, Social, Idle and Voice/Fun emotes checked against client token globals. Unrecognized emotes are flagged/disabled or hidden. Customize labels/icons without changing trusted tokens. Animation/audio metadata remains unknown; verified-only filters can be empty.
- Named editable dialogue pools, SAY/YELL/EMOTE, random/shuffle/sequential modes, unlimited stored quote lengths, icons, favorites and previews that do not send or consume playback state.
- Multiple draggable/collapsible bars with category/pool/favorite sources, size/orientation, lock/hide and pagination.
- Radial wheel with immediate favorites, nested groups, pages/Back, click confirmation, Escape/right-click cancellation and optional experimental release binding. Bars/wheel share one dispatcher.
- Versioned SavedVariables, migration/default merging, shared or character profiles and independent shared/character bar layouts. Updates preserve player edits, deletions and empty lists.
- Six optional library packs: Stanley, Michael Scott, Jim, Dwight, everyday Dutch and Mastermovies / Michael Nicht. Your Stanley/Michael Nicht lines are verbatim. Additional Office samples have sources. See [LIBRARY.md](LIBRARY.md).

## Install and launch

Unzip `dist/InCharacter-0.3.0.zip` into `World of Warcraft/_forever_/Interface/AddOns/`, or copy this repository's **`InCharacter/` directory** there. The resulting path is:

```text
World of Warcraft/_forever_/Interface/AddOns/InCharacter/InCharacter.toc
```

Avoid an extra nested `InCharacter/InCharacter/` folder. Both TOCs declare interface `16001`; `_Camelot.toc` follows the [inspected Charades convention](https://github.com/damesene/wow-charades/blob/main/Charades_Camelot.toc). The supplied live-client path is `_forever_`; `_classic_beta_` was the beta path.

Enable the addon in WoW's AddOns menu, then type:

```text
/console scriptErrors 1
/reload
/ic
```

In **Dialogue Pools**, select a preset and click **Copy + greet/quote/bye**. This makes editable copies and maps available shortcuts to them. **Copy preset** installs copies without changing shortcuts. Nothing sends automatically; starter pools are empty.

For your own RP, click **New pool**, enter a name, select channel/mode/icon, enter one saying per line and click **Save**. Add/edit/delete/reorder sayings in that field. **Preview** displays locally; **Favorite** adds the pool to your default bar/wheel. Save edits before changing pools or tabs. The Bars tab can pin a pool directly as its source.

```text
/ic help
/ic wheel
/ic greet
/ic quote
/ic bye
/ic pool My Custom Pool
/ic My Custom Pool
```

Shortcuts initially use `greetings`, `quotes` and `farewells`; reset their mappings in Profiles. A preset containing only Quotes leaves the other mappings unchanged. Custom-name lookup normalizes punctuation/whitespace; `/ic pool <exact ID>` resolves duplicate or reserved names. IDs are shown in the editor and do not change when renamed.

If another addon already owns `/ic` when In Character loads, it is left alone; use `/incharacter`. Later-loading addons can still take aliases, so test conflicts in your actual addon set. Pool names do not register separate global slash commands.

## Bars, wheel and profiles

Drag bar titles to move them; click titles to collapse/expand. The Bars tab controls source, button size/orientation, lock and hide. Scroll over a bar for pages of 12 buttons. Restore hidden bars in the editor. Pool mode determines the single line sent by each click.

Assign **In Character** bindings in WoW's Key Bindings for editor, wheel and favorites 1–4. No default keys are assigned. `/ic wheel` always opens click confirmation. Click a group to enter, click an action to execute, Back to navigate, Escape/right-click to cancel. Root favorites page separately in groups of four; radial pages contain up to eight entries. The wheel is centered on screen and selection uses visible button hitboxes.

Click mode stays open on binding release; the next bound key press closes it. Experimental release mode in the Wheel tab requires binding down/up events and client permission to send chat from release. Hold the bound key, click through groups, point at a visible action at least **0.15 seconds**, then release. Hover never enters submenus; releasing over a group, gap or center does nothing. **Release behavior requires verification in Forever.**

Profiles selects shared or private pools/favorites/wheel settings, separately from bar-layout scope. Character layouts are the default. Each character has a private profile snapshot available; switching scopes retains both copies. **Copy account to this character** explicitly replaces that snapshot after a second confirmation click. Reset affects only the active profile and retains layouts.

## Limits

- Sends originate only from clicks, slash commands or bindings. No timed chat, combat automation, arbitrary slash/macro/sequence execution, spells/items/targeting, or broadcast custom audio.
- Stored quotes have no addon length/count limit. Sending conservatively allows at most **255 UTF-8 bytes** and no control characters per message. Longer quotes stay intact and previewable but must be shortened before sending. Nothing is split or truncated. Client/server restrictions may also silently reject chat.
- Selection state is per pool for the session. It resets on reload, profile switch/reset or relevant pool edits. Shuffle visits each entry once per cycle; duplicated text remains separate entries and cycle boundaries may repeat.
- Combat closes editor/wheel and blocks reopening. Existing bars attempt direct chat/emotes subject to client rules. Layout rebuilds wait until combat ends; chat never queues or replays.
- The [Forever API kit](https://github.com/Thunderz96/forever-addon-kit) documented historical beta persistence bugs. Current live status is unknown here. Normal `InCharacterDB` persistence is implemented; no macro/bridge workaround or automatic reload is installed. Test `/reload` **and full restart**, and back up SavedVariables while WoW is closed.
- Deferred: profile text/JSON import/export, a large icon browser, custom emote creation, native action-bar drag/drop, and established animation/nearby-audio metadata. The current editor offers eight icons/custom texture paths and addon-managed favorites/bars.

See [docs/RESEARCH.md](docs/RESEARCH.md) for inspected source references and [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md) for the verification receipt.

## Tests and packaging

From the project root:

```sh
lua tests/run.lua
lua tests/ui.lua
luajit tests/run.lua
luajit tests/ui.lua
python3 scripts/verify.py
LUA=luajit python3 scripts/verify.py
python3 scripts/package.py
```

Local results: **26 logic/library tests + 10 mocked UI/integration tests passed on Lua 5.5.1 and LuaJIT 2.1**. The validator syntax-checks addon/test Lua chunks, compares TOCs, checks file coverage and parses six XML bindings. Packaging verifies ZIP integrity/layout. CI is configured for Lua 5.1/LuaJIT but has not run on GitHub in this session. Mocks do not implement the real renderer or protected-action system.

## Files and contributions

Runtime: `InCharacter/` contains Core/Defaults, emote/library data, profile/dialogue/action/library/wheel services, editor/widgets/bars/wheel UI, bindings, TOCs and attribution. Repository deliverables include the saved `SPEC.md`, README, library catalogue, [contribution guide](CONTRIBUTING.md), manual checklist, tests, research notes, packaging scripts and CI. Preset PRs need a small data file plus matching TOC entries; schema checks discover them automatically.

Original code is MIT-licensed. Quotations/game assets retain their owners' rights. Charades attribution is in `InCharacter/THIRD_PARTY_NOTICES.txt`.

## Phase commits

This workspace disallowed creating `.git`. Completed phases were committed in a temporary repository; `InCharacter-history.bundle` contains the history. Restore into a **new** folder:

```sh
git clone /absolute/path/to/InCharacter-history.bundle in-character-history
```

The bundle contains source and phase commits; regenerate the ignored `dist/` ZIP with `python3 scripts/package.py` after cloning.
