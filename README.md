# In Character

An emote and roleplay dialogue launcher for **WoW Forever, interface 16001**. Native Lua; no runtime dependencies.

## Install

**[Download the installable addon ZIP](https://github.com/stronk-dev/wow_forever_mod_in_character/releases/download/v0.3.1/InCharacter-0.3.1.zip)** · [Release notes](https://github.com/stronk-dev/wow_forever_mod_in_character/releases/tag/v0.3.1)

This is a test release: automated checks pass, but live Forever verification is still pending. Download the named addon ZIP under **Assets**, rather than GitHub's automatically generated source-code archives.

Extract `InCharacter-0.3.1.zip` into:

```text
World of Warcraft/_forever_/Interface/AddOns/
```

Or copy the repository's `InCharacter/` folder there. `InCharacter.toc` should sit directly inside `AddOns/InCharacter/`.

Enable the addon, then enter:

```text
/console scriptErrors 1
/reload
/ic
```

## Try a preset

1. Open **Dialogue Pools**.
2. Choose Stanley, Mastermovies/Michael Nicht, another Office character, or everyday Dutch.
3. Click **Copy + greet/quote/bye** to create editable pools and connect their available shortcuts.
4. Preview a line, then click a pool's **Favorite** button to put it on the quick bar.
5. Click that bar button to send one line.

**Copy preset** creates pools without changing shortcuts. Nothing sends automatically. Your supplied Stanley and Michael Nicht phrases are preserved verbatim. See [the library catalogue](LIBRARY.md) for contents and sources.

## Make it your own

- **Dialogue Pools:** create/rename/reorder/delete pools; edit one saying per line; choose SAY/YELL/EMOTE and random/shuffle/sequential mode. **Save** persists edits. Drafts survive switching pools/tabs or closing the editor for this session; they do not survive `/reload`. **Discard draft** restores saved text.
- **Emotes:** choose favorites and customize labels/icons. Tokens are checked against the client. The animated filter uses Charades' curated reference list; audio/text-only status still needs a live check.
- **Bars:** add bars, choose a pool/category/favorites, resize buttons, switch orientation, lock or hide. Drag titles to move; click titles to collapse. Scroll for more buttons.
- **Wheel:** `/ic wheel` opens a nested click-confirm menu with direct favorites, Back and pagination. Escape/right-click cancels. It stays usable in combat; chat/emotes remain subject to client restrictions.
- **Profiles:** share dialogue/favorites/settings or keep them private to a character. Choose bar-layout scope independently. A private profile is copied from the current shared profile only when first selected. Existing private profiles are retained when switching scopes.

Assign **In Character** keys in WoW's Key Bindings for the editor, wheel and visible favorites 1–4. No keys are assigned automatically. Optional hold/release mode requires hovering a visible action for 0.15 seconds; it is experimental until verified in Forever. Submenus always require a click. `/ic wheel` always uses click confirmation.

```text
/ic help
/ic greet
/ic quote
/ic bye
/ic My Custom Pool
/ic pool My Custom Pool
```

Pool names support case/punctuation normalization. Duplicate/reserved names can be addressed by exact ID with `/ic pool <ID>`; the editor shows IDs. Profiles can reset the three shortcut mappings. If another addon already owns `/ic` at load time, use `/incharacter`.

## What is tested

**40 logic/library tests and 14 isolated mocked UI tests pass on Lua 5.5.1 and LuaJIT 2.1.** Lua syntax, matching TOCs, XML bindings and ZIP integrity/layout checks also pass. CI is configured for Lua 5.1/LuaJIT; remote CI execution is separate from these local results.

**No live WoW client has been tested in this implementation session.** Follow [the Forever checklist](FOREVER_TEST_CHECKLIST.md) for loading/rendering, chat acceptance, nearby emote audio, real combat/taint behavior, key release and reload/full-restart persistence.

The reported beta SavedVariables bug was [marked fixed in build 70009](https://github.com/ClassicWoWCommunity/forever-bugs/issues/34). Normal SavedVariables are used; no workaround is installed.

## Limits and upgrades

- Stored quotes have no addon length/count limit. Sending allows at most **255 UTF-8 bytes after literal pipe escaping**. Longer lines remain editable/previewable. Nothing is truncated or split into multiple sends.
- Lockdown/account chat predicates are checked before selection. Reported failures leave playback unchanged; no chat is queued. A silent server rejection can still be undetectable.
- Wheel/buttons run only direct chat/emotes. Editor opening and bar-layout rebuilds wait until combat ends. No spells, items, targeting, arbitrary slash/macro execution or automatic chat.
- Shuffle/sequential state lasts for the session and resets on relevant edits/profile changes. Repeated text is treated as separate entries. Shuffle can repeat across cycle boundaries.
- Shared data is `InCharacterDB`; character scope/layout is `InCharacterCharDB`, declared with `SavedVariablesPerCharacter`. Schema 3 copies old realm-keyed records on each character's first upgraded login. Legacy originals remain in `InCharacterDB.characters` for recovery. If both realm spellings have records, the addon reports the conflict and preserves both.
- Pack updates never overwrite installed pool copies. Profile import/export, native action-bar drag/drop, a larger icon browser and verified nearby-audio metadata remain deferred.

Before upgrading, close WoW and back up both account and character `SavedVariables/InCharacter.lua` files under `WTF/`.

## Development

```sh
lua tests/run.lua
lua tests/ui.lua
luajit tests/run.lua
luajit tests/ui.lua
python3 scripts/verify.py
LUA=luajit python3 scripts/verify.py
python3 scripts/package.py
```

Packaging reads the release version from the TOC. Runtime modules are in `InCharacter/`; tests, packaging and CI are outside the addon. The ordinary and `_Camelot.toc` manifests both target 16001, following the inspected Charades convention. `_forever_` is the live path specified for this project.

See [CONTRIBUTING.md](CONTRIBUTING.md) for small preset PRs, [research notes](docs/RESEARCH.md) for source evidence and [implementation status](docs/IMPLEMENTATION_STATUS.md) for remaining live checks. Original code is MIT; quotation/game-asset rights remain with their owners. Charades attribution is retained in the addon.
