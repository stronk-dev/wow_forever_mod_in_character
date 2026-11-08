# Implementation and verification receipt

Updated 2026-11-08 for 0.3.1. No live WoW Forever client was available.

| Phase | Delivered | Verification |
| --- | --- | --- |
| 1 | Installable core, emote catalogue, dialogue modes, profile migration, slash commands, favorites bar | Pure Lua tests |
| 2 | Five-tab editor, configurable bars, account/character layouts, optional community library | Logic and mocked editor/install/save/preview/bar callbacks |
| 3 | Nested wheel, immediate favorites, pages/Back, cancellation, bindings, experimental release, combat UI guards | Mocked input/combat callbacks and pure tree navigation |
| 4 (selected polish) | Contribution schema/template, source notes, checklist, CI, deterministic ZIP, history bundle | TOC/XML/Lua syntax and archive integrity/layout checks |

**Local tests:** 40 logic/library tests and 14 isolated mocked UI/integration tests pass under Lua 5.5.1 and LuaJIT 2.1. Every UI test loads fresh addon/globals. Source cycling uses real button callbacks; release tests move the mocked cursor through the wheel's hit-testing. The validator checks all Lua chunks, matching interface-16001 TOCs, per-character SavedVariables metadata and six bindings. GitHub CI is configured for Lua 5.1/LuaJIT; it was not executed remotely in this implementation session. Packaging derives its ZIP name from the TOC.

Library: Stanley (14 supplied lines), Michael Nicht (13 supplied lines), everyday Dutch (8 common expressions), Michael Scott/Jim/Dwight (one sourced phrase each). Total: 38 lines across six optional packs. Supplied phrases retain spelling/capitalization. Quotes are plain data; supplied `/run` wrappers were not retained or executed. Copies have provenance and remain editable; no update overwrites them.

Audit fixes: single-value normalization and name lookup regression coverage; per-character SavedVariables with v1/v2 migration and lazy private copies; pre-selection chat restriction checks; PerformEmote preference/result handling; literal pipe escaping/encoded-byte checks; combat wheel availability; real curated animation metadata with nonfunctional audio/text filters removed; visible favorite binding alignment; loaded/shared layout cleanup on deletion; session editor drafts; TOC-derived runtime/package versions.

Deferred: profile import/export, larger icon discovery, custom emote creation, native action-bar integration and verified nearby-audio metadata. Animation is curated reference data from Charades, not a live Forever result. Token recognition establishes neither animation nor audibility. UI uses standard templates and click-to-cycle selectors; no custom assets/full UI localization.

Live verification remains: loading/rendering, hardware/chat permissions and instance lockdown, emote recognition/animation/audio, release bindings, combat/taint handling, persistence on reload/full restart and migrated cross-character separation. Follow the checklist; mock success is not a live result. The beta SavedVariables report was marked fixed in build 70009 by its reporter; the kit's persistence row was not re-checked and should not be treated as proof of a live bug.

The original four phase commits are now restored in this project's Git repository on `master`, tracking `origin/master`. The original `InCharacter-history.bundle` is an archive of 0.3.0 only; it does not contain subsequent working-tree fixes. No live-client test results are inferred from Git history.
