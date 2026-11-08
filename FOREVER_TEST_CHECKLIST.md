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

## Editor, library and bars

- [ ] All five tabs fit at common UI scales/screen resolutions. Long names, long quotes, scrolling, UTF-8, apostrophes and input focus work. Escape clears edit focus/closes the relevant window without sending.
- [ ] Create, rename, reorder and delete pools. Edit/add/delete/reorder lines in the multiline field and Save. Change icon, mode and channel. Verify IDs stay stable when renaming.
- [ ] Unsaved drafts survive switching pools/tabs, closing/reopening the editor, and entering combat. Switching profile scopes never transfers a draft to another profile. Save persists; Discard draft restores saved text. Unsaved drafts are explicitly session-only.
- [ ] Copy each library pack, inspect source/content notes, and verify your supplied lines remain verbatim. Copying again preserves edits and creates distinct pools; upgrading addon files does not replace installed copies.
- [ ] Library copy and preview send nothing. Shortcuts map only to the available pools when using **Copy + greet/quote/bye**. Profiles → Reset mapping restores default pool IDs.
- [ ] Favorite/unfavorite emotes and pools. Emote labels/icons can be customized without altering tokens. Add a bar pinned to a pool, a category and Favorites.
- [ ] Add/delete bars, change button size and horizontal/vertical layout, drag their title, collapse/expand, hide/restore and lock positions. Scroll pages containing more than 12 actions; all remain reachable.
- [ ] Bar positions/settings and dialogue survive `/reload`, normal logout/login and full restart. The beta loading bug was marked fixed in build 70009; this addon still needs verification. Back up both account and character `WTF/.../SavedVariables/InCharacter.lua` files while WoW is closed.
- [ ] Upgrade a v2 save with character profiles/layouts under both `Argent Dawn:Name` and `ArgentDawn:Name` spellings. Each character migrates once into InCharacterCharDB. Old originals remain intact. Conflicting records produce a notice and are retained for recovery; a later reload never re-imports stale data.
- [ ] Enable character profile on two characters and verify quotes/favorites differ. Character bar layouts remain separate by default. Explicit account layout scope shares positions. Switching scopes retains both copies.
- [ ] Copy account to character/reset active profile requires the second confirmation click and changes only the intended scope.

## Emotes and nearby audio

- [ ] Client emote tokens are detected, including localized commands. Unrecognized tokens are flagged/disabled or hidden; no arbitrary slash fallback executes.
- [ ] Test every shipped emote for recognition, target-sensitive text, animation and race/sex-dependent voice. `/joke` may resolve to `SILLY` from the client token table.
- [ ] Ask a nearby second player to confirm which built-in emotes they can hear. Do not infer audibility from local sound. No custom addon audio is broadcast.
- [ ] The animated filter shows curated reference entries and labels them accordingly. Check those animations on the actual build before treating them as verified. Audio/text-only filters are absent until supported by evidence.
- [ ] With PerformEmote available it is preferred, its failure result is reported, and DoEmote is never called as a retry. Verify the legacy DoEmote restriction result only on a build requiring that fallback.

## Wheel and bindings

- [ ] `/ic wheel` opens click confirmation. Root shows Favorites, Combat, Reactions, Social, Idle, Voice/Fun and Roleplay. Immediate favorite buttons and their paging work.
- [ ] Click a category, Roleplay → custom/preset group → pool, Back, and pages with more than 8 actions. No action executes merely on hover or submenu traversal.
- [ ] Wheel action click sends once; click mode stays open after binding release. The next bound key press toggles it closed. Empty groups and stale/deleted favorites do not error.
- [ ] Escape or right-click anywhere on the wheel cancels without sending. No key release after cancellation executes a stale action. Tooltip/catcher disappear on close.
- [ ] Assign editor, wheel and favorite 1–4 bindings in WoW Key Bindings → In Character. Favorite bindings match the first four visible entries in a Favorites bar with the same page, including when unverified entries are hidden. Repeated presses/modifiers/mouse bindings work. No existing binding is reassigned automatically.
- [ ] Enable experimental release: hold bound key, click submenus, point at an action at least 0.15 seconds, release. Exactly one action executes only if Forever delivers key-up with a permitted hardware context.
- [ ] Releasing over a submenu, gap, center, a newly entered page, or after right-click/Escape does not execute. Crossing sectors without a click/release sends nothing. `/ic wheel` always uses click confirmation even when release mode is enabled.
- [ ] On small screens and non-default UI scales, labels/icons remain legible and all targets stay on screen. Point/release uses visible rectangular targets, not infinite angular sectors.

## Combat and restrictions

- [ ] Entering combat closes the editor but leaves the unprotected wheel usable. Open/navigate/cancel the wheel in combat and directly use Combat emotes such as OOM. No blocked-action/taint errors occur. The editor still refuses to open in combat.
- [ ] Existing bar/favorite bindings attempt only direct emotes or chat, subject to client restrictions. No spell, item, targeting or secure macro actions occur.
- [ ] Pending layout refresh runs once after `PLAYER_REGEN_ENABLED`. No chat is replayed at combat end or on any timer/event.

## Report

Build / locale / character: ____________________

Passed check IDs and exact failures / Lua stack traces: ____________________

Unverified behavior and known client bugs: ____________________
