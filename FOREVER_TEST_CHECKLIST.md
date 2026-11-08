# WoW Forever live-client verification

**None of these checks has been performed in a live client by this implementation session.** The automated tests exercise pure Lua and mocked UI callbacks. They cannot prove server chat acceptance, animations, nearby audio, SavedVariables loading, key-up events, taint behavior or visual layout.

Record tester, date, region/locale, race/sex, `GetBuildInfo()` values, interface number and any other addons. Start with the clickable pool buttons before testing the wheel. Enable `/console scriptErrors 1`; use `/reload` manually. Record actual errors and failed operations; never mark an untested box passed.

## Install and core

- [ ] Install at `World of Warcraft/_forever_/Interface/AddOns/InCharacter/`. `InCharacter.toc` and `InCharacter_Camelot.toc` are directly in that folder. The beta path `_classic_beta_` is not the live path.
- [ ] Addon is listed/enabled, loads without Lua errors, and prints its loaded message.
- [ ] `/ic`, `/ic help`, `/ic wheel`, `/ic greet`, `/ic quote`, `/ic bye` work. Initially empty pools report that they are empty and send nothing.
- [ ] If another addon owns `/ic`, its handler still works; `/incharacter` opens In Character. Check load-order-dependent conflicts separately.
- [ ] In Dialogue Pools copy Stanley or Mastermovies with **Copy + greet/quote/bye**. Click a favorite/button and confirm exactly one line appears in SAY.
- [ ] Test SAY, YELL and EMOTE from direct clicks and slash commands in open world and instances. Test without a target, with friendly/hostile targets and after chat restrictions. A reported success in the addon cannot detect silent server rejection.
- [ ] Empty pools, blank lines, oversized UTF-8 messages and blocked actions do not send or create deferred sends. A 256-byte line remains intact and previewable. The send limit is 255 bytes after literal pipe escaping; test lone/doubled pipes, color/link-like strings and UTF-8 without changing stored text.
- [ ] In open world and an instance, inspect actual lockdown/account restriction predicates. When they report a block, a pool click explains why and leaves random/shuffle/sequential state unchanged. No send replays when restrictions clear. Record any silent server rejection separately.
- [ ] Random mode permits repeats; shuffle uses every entry once per cycle (duplicate text entries count separately); sequential loops. Preview does not advance playback. State resets on `/reload`, profile switch/reset and edits affecting the pool.

## Look and feel (the main thing to judge)

- [ ] Take screenshots of: the launcher button, its menu with a category flyout open, the radial wheel (click mode and hold mode), each page of the window, and the per-category bars. Note anything that overlaps, is cut off, unreadable or ugly, at your normal UI scale and at a small one.
- [ ] Icons: every curated emote shows a real icon (not a green square or question mark). List any that fall back. If a missing icon shows as the client's missing-texture square rather than a fallback, report it: the fallback relies on `SetTexture` returning false, which is unverified.
- [ ] The window appears under **Options > AddOns > In Character** and its buttons work. In Character appears in the addon dropdown next to the minimap; left-click opens the menu, right-click the window.
- [ ] Screenshot the **Browse / edit messages** window with a long UTF-8 message selected, a dirty edit, and a pinned message. Screenshot **Favorite actions**, a third-level launcher flyout, and the wheel breadcrumb/Back at each dialogue depth. No overlapping buttons, clipped counters or obscured previews at normal and small UI scales.

## Emote library and nearby audio

- [ ] The library lists roughly 250 emotes. Badges/filters visibly mark audio/animation/text-only metadata as reference data. Search finds commands, aliases and custom names. No label implies token recognition verifies nearby audio.
- [ ] Emotes the client doesn't know are greyed out and can't be used. Any Forever-only emote appears with an "Unlisted" badge.
- [ ] With a second player nearby, confirm they **hear** a sample of Sound emotes (`/chicken`, `/cheer`, `/laugh`, `/charge`, `/healme`, `/train`) and see but don't hear Animation emotes (`/dance`, `/flex`, `/sit`). Record any mismatch with the wiki-based badge.
- [ ] Custom names and icons apply on bars, menu and wheel without changing the emote that runs.

## Launcher menu

- [ ] Left-click the button: favorites on top, five categories, All emotes, then roleplay groups. Hovering a category opens its flyout beside the menu; long lists scroll with the mouse wheel.
- [ ] Clicking an entry uses it once and closes the menu. Right-click pins or unpins without closing. Clicking outside or pressing Esc closes it without sending.
- [ ] Navigate group → pool → playback choices → specific messages; Back closes one flyout level. Pin an exact message and an explicit Random action. Each invokes the intended behavior; opening/hovering groups sends nothing.
- [ ] Shift-drag moves the button and the position survives `/reload`. The *Click opens wheel* option works.

## Radial wheel

- [ ] Bind the wheel key on the Home card (click, press a key; right-click clears). It also shows in WoW's Key Bindings.
- [ ] The wheel opens centred on the cursor and stays on screen near the edges. Favorites are active first. Pointing at an inner icon switches the outer ring, and nothing runs until you click an outer action.
- [ ] Hold mode: hold the key, point at an outer action, release: it runs once. Releasing in the centre does nothing. Click mode: releasing the key keeps it open, and the next press closes it.
- [ ] Scroll pages a category with more than 12 entries. Right-click, Esc or clicking the centre cancels. Works in combat.
- [ ] Open Roleplay → a preset/custom group → pool → Choose a specific message. The breadcrumb follows navigation. Centre means Back in submenus and Cancel at root. Going Back restores the prior page. Nested lists longer than 12 remain reachable.
- [ ] Inside a submenu, crossing an inner category sector does not leave that context. Explicitly clicking an inner category does. Releasing over a group never enters or sends; dwell is required after every context/page change. Releasing outside the wheel's bounded hit area sends nothing.

## Bars, dialogue and profiles

- [ ] Home > *A bar per category* creates five bars; removing them leaves your other bars alone. Drag titles; click to collapse; right-click opens their settings; locking hides the title strip.
- [ ] Layouts page: size, buttons per row and vertical layout render correctly; Sound emotes show a small blue corner mark.
- [ ] Pin more than 48 actions and visit every bar page using arrows and scroll. Try large buttons on a small screen in both orientations; all entries remain reachable. Page arrows remain usable when the title is locked and hide on collapse. Paging is blocked in combat without sending anything.
- [ ] Dialogue: create, rename, reorder and delete pools; choose the icon from the picker; edit lines; the byte counter warns over 255. Unsaved edits survive switching pools and are marked unsaved; Save and Discard edits work. Preset copies keep your supplied lines verbatim.
- [ ] Bar positions, launcher, favorites and dialogue survive `/reload`, logout and a full restart. Back up both `WTF/.../SavedVariables/InCharacter.lua` files while WoW is closed.
- [ ] Upgrading a 0.3.x save keeps pools, favorites and bars; a v2 save under both `Argent Dawn:Name` and `ArgentDawn:Name` spellings migrates once and keeps the originals.
- [ ] Per-character profile on two characters keeps quotes/favorites separate; layout scope is independent.
- [ ] Type a pool draft, then create another pool or copy a preset. Return and verify text, name, mode, channel and icon remain. A pending bulk draft cannot be sent by the new Play/Random controls until saved/discarded.
- [ ] In Browse / edit messages: create, save, preview, explicitly send, pin, make a bar, edit, reorder and delete one selected message. Editing/reordering here preserves its ID/pins; deletion disables the old exact-message action instead of retargeting it. Empty, unsaved and oversized messages have correct controls/counters.
- [ ] Specific-message sends do not advance normal or overridden pool playback. Random, shuffle and in-order overrides keep separate state. Preview changes no state. Lockdown leaves state intact, displays a local reason and never replays a send later.
- [ ] Message drafts survive selection changes, closing/reopening and navigation until /reload. Drafts never leak between shared/private profiles or transfer into another pool. Bulk text replacements warn about removed exact-message pins; unchanged/reordered lines retain IDs.
- [ ] Favorite actions: reorder, preview, play, unpin and create a bar for pool/mode/exact-message actions. Binding 1–4 uses the matching visible favorites. Upgrade a saved `/joke` favorite: it displays canonically and unpins in one click without duplicates.
- [ ] A rejected key assignment leaves existing bindings intact. Icon selection with no current icon shows a question mark; explicit asset failures use the fallback. Verify actual SetTexture/file availability on this client; mocks only exercise the fallback path.

## Combat and restrictions

- [ ] Entering combat closes the settings window but leaves the wheel, menu and bars usable. Use Combat callouts such as /oom from each of them in combat. No blocked-action/taint errors occur. The editor still refuses to open in combat.
- [ ] Existing bar/favorite bindings attempt only direct emotes or chat, subject to client restrictions. No spell, item, targeting or secure macro actions occur.
- [ ] Pending layout refresh runs once after `PLAYER_REGEN_ENABLED`. No chat is replayed at combat end or on any timer/event.

## Report

Build / locale / character: ____________________

Passed check IDs and exact failures / Lua stack traces: ____________________

Unverified behavior and known client bugs: ____________________
