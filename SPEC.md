# In Character — Codex implementation brief

You are building **In Character**, a native Lua addon for **World of Warcraft: Forever (1.60.x, interface 16001)**. Implement actual installable addon files in this repository, not a website, mockup, or design-only document. Work autonomously, make sensible decisions, write tests where possible, and document what requires testing inside WoW.

## Project goal

A lightweight, configurable **emote + in-character dialogue launcher** that gives players:

1. Quick-access emotes organized by combat communication, social, idle, reactions and audible/funny voice emotes.
2. User-created named dialogue pools (Greetings, Quotes, Farewells, etc.), random/shuffled/sequential playback, no 255-character *macro* limit on stored quotes.
3. Two UI presentations over the same actions: draggable/collapsible quick bars and a nested radial wheel inspired by **Charades**.
4. Account-global and per-character data and layouts.

## Reference research (read source before writing wheel)

- Charades (Forever-compatible, MIT): https://github.com/damesene/wow-charades — examine Wheel.lua, Actions.lua, Editor.lua, and its Forever TOC; use as reference for mouse/key behavior, game-specific API limitations, and UI details. If copying/adapting code or assets, retain copyright/license notices and attribution. Do not blindly fork or import its whole codebase.
- https://www.curseforge.com/wow/addons/charades
- Forever API observations: https://github.com/Thunderz96/forever-addon-kit
- Forever ships a modern/mainline-style addon API, but uses interface **16001**. Do not assume retail version numbers or Classic Era APIs determine behavior. Verify actual API availability and protected-action restrictions.

## UX spec

**Main wheel**: favorites (immediately available) plus Combat, Reactions, Social, Idle, Voice/Fun and Roleplay groups. Open on a configurable keybind; point and release to activate, with click-to-confirm alternative. Cancel with Escape/right-click. Submenus should support at least two levels, with obvious back navigation and no accidental triggering when crossing a sector. If hold-key release semantics cannot be reliably implemented under Forever restrictions, implement click-confirm first, log the limitation and provide hold-key as an optional experimental mode.

**Quick bars**: show one or several moveable/resizable bars of icon buttons. Allow horizontal/vertical layout, collapse/expand, lock, hide, per-bar category/pool selection, and favorites. Do not replace Blizzard action bars. Use tooltips with the command or pool name. A pool button sends one randomly chosen line on the user's click. Provide an option to bind a pool to an addon-managed bar/favorite; do not promise native action-bar drag/drop unless secure action-button feasibility is proven.

**Editor**: `/ic` opens a usable configuration window with tabs for Emotes, Dialogue Pools, Bars, Wheel, Profiles. Users can create/rename/delete/reorder pools, add/edit/delete lines, select chat channel (SAY/YELL/EMOTE), set selection mode, select icon, make a favorite, and preview *without sending to chat*. Have accessible defaults but keep the interface compact. Include `/ic help`, `/ic wheel`, `/ic greet`, `/ic quote`, `/ic bye` shortcuts (custom pool names also supported using safe normalization). Do not steal existing slash commands. Support profile export/import as a safe text format later if needed; prefer a functional initial editor over ambitious import/export.

**Emotes**: ship categories with useful actual WoW emote tokens, validating where possible against Forever:

- Combat: `/oom`, `/healme`, `/helpme`, `/charge`, `/flee`, `/incoming`
- Social: `/wave`, `/bow`, `/salute`, `/hug`, `/flirt`, `/bye`
- Reactions: `/laugh`, `/cry`, `/angry`, `/cheer`, `/applaud`, `/chicken`
- Idle: `/sit`, `/sleep`, `/dance`, `/flex`, `/kneel`
- Voice/Fun: `/train`, `/joke`, `/silly`, `/roar`, `/chicken`

Not every token is guaranteed to be recognized or audible in Forever; gracefully hide/flag unverified ones. Include toggles/filters for animated, audible to nearby clients, and text-only where this can actually be established. Never claim custom addon audio is broadcast to others.

**Dialogue selection modes**:

- `random`: Uniform random selection, repeats possible.
- `shuffle`: Randomized bag, each item once per cycle.
- `sequential`: In order, looping after the last item.

Keep state per pool and make behavior clear. Empty pools never send. Quotes may contain punctuation, UTF-8 and apostrophes.

Avoid unsolicited auto-send, timer/trigger automation, or automatic spam. All chat sends must originate from direct user actions and honor Blizzard restrictions.

No combat automation and no `/cast`, `/use`, `/target` automation.

## Seed data: Stanley Hudson

Preserve verbatim; these are example phrases, not an invitation to generate additional invented character quotes.

### Greetings

- Leave me alone.
- What do you want?
- Oh, for the love of God.
- I'll give you a billion Stanley Nickels if you never talk to me again.
- Why don't you mind your business?

### Quotes

- Did I stutter?
- And shove it up your butt!
- Boy, have you lost your mind? 'Cause I'll help you find it!
- You are a professional idiot.
- You've been meatballed!

### Farewells

- Night, everybody.
- It is five o'clock. I will see you all tomorrow.
- Good day.
- Leave me alone, damn it!

Treat these as **optional example presets** only; do not make the addon Stanley-specific. No need to add or fabricate any new quotes.

## Architecture

Use a clean, minimal modular Lua layout:

```text
InCharacter/
  InCharacter.toc
  Core.lua
  Defaults.lua
  Data/
    Emotes.lua
  Services/
    Profiles.lua
    Dialogue.lua
    Actions.lua
  UI/
    Editor.lua
    Bars.lua
    Wheel.lua
  Bindings.xml (only if needed)
```

Use a shared action schema:

```lua
{
    id = "greeting",
    type = "pool", -- emote | pool | submenu
    label = "Greeting",
    icon = "...",
    payload = "greetings"
}
```

Both wheel and bars must call one action dispatcher.

Keep modules cohesive, avoid unnecessary third-party runtime libraries.

SavedVariables should be versioned with migration/default merge. Account-global vs character-specific profile selection should be explicit.

Avoid clobbering saved user data with defaults on update.

## Incremental implementation

### Phase 1 — Working core

Create:

- Addon TOC and initialization.
- Built-in emote definitions.
- Dialogue pool services.
- Profile persistence and migrations.
- `/ic`, `/ic help`, `/ic greet`, `/ic quote`, `/ic bye`.
- Chat sends from direct user action.
- Simple clickable favorites bar.
- Pure Lua selection logic and tests.

If something cannot be tested outside WoW, mark it clearly rather than claiming success.

### Phase 2 — Complete user workflow

Implement:

- In-game editor for creating and managing dialogue pools.
- Emote selection and favorites.
- Multiple collapsible, configurable bars.
- Per-character layouts.
- Icon and category choices.
- Selection modes.

Ensure a new character can configure their own RP without modifying Lua files.

### Phase 3 — Radial wheel

Inspect the Charades MIT source.

Implement:

- Nested radial menu.
- Favorites ring or quick-access selection.
- Category navigation.
- Hover/hold/release behavior.
- Click-to-confirm alternative.
- Cancellation.
- Keybindings.
- Combat-lockdown-safe handling.

Avoid protected secure-action changes during combat. Queue UI reconfigurations until safe, not chat sends.

### Phase 4 — Quality and polish

Implement as appropriate:

- Text/JSON import and export.
- More emote metadata.
- UI improvements.
- Performance improvements.
- Documentation.
- Release packaging.

Start by creating **Phase 1 now**, then continue to Phases 2 and 3 if practical within the session.

Don't stop after a plan.

At each stage, keep the repository installable and update the README with the true implementation status.

## Testing and deliverables

### Automated tests

Include tests for:

- Uniform random selection.
- Shuffle bag with no repeats within a cycle.
- Sequential selection.
- Single-item pools.
- Empty pools.
- Profile reset and migration.
- Default configuration merging.
- Preserving user data across updates.

### WoW Forever integration

The `.toc` should specify:

```text
## Interface: 16001
## Title: In Character
## Notes: Emotes, reactions, and roleplay dialogue
## SavedVariables: InCharacterDB
```

Check whether a Forever-specific `_Forever.toc` or `_Camelot.toc` is appropriate based on actual reference projects.

Do not assume a convention without confirming it.

### Installation

Document the expected installation path:

```text
World of Warcraft/_forever_/Interface/AddOns/InCharacter/
```

Include instructions for:

```text
/reload
/console scriptErrors 1
/ic
/ic help
/ic wheel
/ic greet
/ic quote
/ic bye
```

The beta used `_classic_beta_`, but the live client uses `_forever_`.

### Manual test checklist

Create `FOREVER_TEST_CHECKLIST.md`.

Include:

- Addon loads without Lua errors.
- Slash commands work.
- Chat messages appear correctly.
- Emote animations execute.
- Audible emotes are heard by nearby players.
- Dialogue pools persist after `/reload`.
- Bar positions persist.
- Radial wheel selection works.
- Key-release input behavior.
- Submenu navigation.
- Cancellation without execution.
- In-combat behavior.
- Profiles remain separate across characters.

Clearly distinguish automated testing from anything requiring a live client.

## Constraints

- Native Lua addon, not a web application.
- Target WoW Forever specifically.
- No unnecessary frameworks or build systems.
- No automatic combat actions.
- No unsupported claims about Forever API behavior.
- No fake screenshots standing in for working UI.
- Reuse/adapt MIT code only with appropriate attribution.
- Preserve user configuration across addon updates.
- Keep performance impact minimal.
- Maintain a clean, readable codebase.

## Expected final report

When implementation is finished, report:

1. Files created.
2. Features actually implemented.
3. Tests executed and their results.
4. Features requiring verification in WoW Forever.
5. Known limitations or blockers.
6. Exact installation and usage instructions.

Prioritize an intuitive, reliable addon over implementing every edge case.

**Build the actual addon.**

## Accepted scope addition: community preset library

Provide optional, editable, independently versioned Lua packs for The Office characters and Dutch culture, including Mastermovies / Michael Nicht. Make contribution through pull requests straightforward, with schema validation, source notes, and tests. Never overwrite edited user pools on addon updates or execute supplied macro text. User-supplied Michael Nicht phrases are recorded verbatim in the library alongside the Stanley phrases above. Research may add short, sourced examples for other Office characters; no invented character quotes.

## Accepted scope addition: full dialogue controls and UI

The product is not limited to Greetings / Quotes / Farewells. Players must be able to create arbitrary named pools and deliberately choose a specific saved message or random/shuffle/sequential playback. Expose those actions in a real in-game message editor, favorites, bars, nested launcher menus and the radial wheel. Preserve specific-message pins across edits/reordering using stable identities; never silently retarget a deleted message. Keep legacy shortcuts as conveniences only.

Fix the audited draft loss, custom-name display, 48-entry bar truncation, legacy joke alias pinning and unqualified audio claims. The wheel must retain nested navigation, obvious Back/breadcrumb controls, paging and safe cancellation. Validate actual UI callbacks and data persistence without claiming that mocked tests establish rendered appearance or live-client compatibility.
