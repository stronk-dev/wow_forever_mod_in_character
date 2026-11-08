# Implementation and verification receipt

Built 2026-11-08. No live WoW Forever client was available.

| Phase | Delivered | Verification |
| --- | --- | --- |
| 1 | Installable core, emote catalogue, dialogue modes, profile migration, slash commands, favorites bar | Pure Lua tests |
| 2 | Five-tab editor, configurable bars, account/character layouts, optional community library | Logic and mocked editor/install/save/preview/bar callbacks |
| 3 | Nested wheel, immediate favorites, pages/Back, cancellation, bindings, experimental release, combat UI guards | Mocked input/combat callbacks and pure tree navigation |
| 4 (selected polish) | Contribution schema/template, source notes, checklist, CI, deterministic ZIP, history bundle | TOC/XML/Lua syntax and archive integrity/layout checks |

**Local tests:** 26 logic/library tests and 10 mocked UI/integration tests passed under Lua 5.5.1 and LuaJIT 2.1. The manifest validator checks all runtime/test chunks, both matching interface-16001 TOCs, and six bindings. GitHub CI is configured for Lua 5.1/LuaJIT but was not executed remotely. The release ZIP is generated locally.

Library: Stanley (14 supplied lines), Michael Nicht (13 supplied lines), everyday Dutch (8 common expressions), Michael Scott/Jim/Dwight (one sourced phrase each). Total: 38 lines across six optional packs. Supplied phrases retain spelling/capitalization. Quotes are plain data; supplied `/run` wrappers were not retained or executed. Copies have provenance and remain editable; no update overwrites them.

Deferred: profile import/export, larger icon discovery, custom emote creation, native action-bar integration, and established animation/nearby-audio metadata. Token recognition is not an animation/audibility guarantee. UI uses standard WoW templates with paged lists/click-to-cycle selectors. No custom assets or full UI localization.

Live verification remains: addon loading, rendering, hardware/chat permissions, emote recognition/animation/audio, release bindings, real combat/taint handling, persistence on reload/full restart and cross-character separation. Follow `FOREVER_TEST_CHECKLIST.md`; mock success is not a live result. The API kit's persistence report concerns an older beta build; current status is unknown.

Separate phase commits were made in `/tmp/in-character-phase-history` because creating this workspace's `.git` was denied. The portable bundle is in the project root. No remote repository, PR or publication was created.
