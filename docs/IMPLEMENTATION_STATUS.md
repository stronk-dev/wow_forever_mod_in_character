# Implementation and verification receipt

Updated 2026-11-08 for **0.5.0**. No live WoW Forever client was available for this implementation session. The UI is native addon code; no website, screenshot mockup or external runtime library is used.

## Implementation

| Requirement | Implemented behavior |
| --- | --- |
| Emotes | Reference catalogue plus client-only entries, runtime token recognition, categories/search/filter chips, local details, Try, pinning, custom names/icons. Audio/animation metadata is visibly marked reference-only. |
| Arbitrary dialogue | Named pools with random, shuffle and sequential modes; explicit playback-mode overrides; specific saved message actions; full local previews. Legacy greet/quote/bye shortcuts remain optional conveniences. |
| Message controls | Dedicated browser/editor: New, Save, Discard, confirmed Delete, reorder, channel/mode choices, byte count, exact send, pin and create-bar controls. Stable message IDs preserve exact pins across explicit edits/reordering. |
| Radial wheel | Two rings, nested groups/pools/message lists, breadcrumb, centre Back/root cancel, direct favorites, paging, click mode and experimental dwell-guarded release, bounded hit-testing and deliberate category switching inside submenus. |
| Launcher menus | Same pool/action hierarchy in cascading menus with explicit Back, pin/unpin, details and cancellation. |
| Bars | Movable/collapsible/resizable/wrapping/oriented/locked/hidden bars; pool/mode/exact-message sources; visible paging and screen-dependent page capacity. Deleted exact messages show a missing-message warning and cannot retarget. |
| Favorites/settings | A favorite-actions page with ordering/preview/play/unpin/bar controls; setup cards, dropdowns, sliders, icon picker and key capture; Options and addon-compartment integration. |
| Persistence | Account/character scope and independent layouts; schema 4 migration adds message IDs, canonicalizes old aliases and retains originals of legacy realm-keyed data. Defaults never replace edited/deleted pools. |
| Preset contribution | Six optional, versioned, sourced packs with schema validation and a small contribution template. Supplied Stanley/Michael Nicht wording remains verbatim. |
| Distribution | Deterministic versioned ZIP; standard GitHub CI validates/tests/packages and uploads artifacts. Version tags publish prerelease assets after CI passes. |

## Audit fixes

The 0.4.0 review was re-audited rather than accepted at face value. Reproduced issues now covered by tests: outgoing drafts lost on New/copy, flattened wheel hierarchy, ignored custom display names, silent bar truncation above 48 actions, un-unpinnable legacy `/joke` favorites, and audio claims presented as verified. Further checks cover nested exact-message playback, ID stability, failure rollback, message drafts, actual dropdown callbacks, page reachability on small screens and refused key assignments preserving existing keys.

## Verification

**61 logic/library tests + 36 isolated mocked UI/integration tests pass under Lua 5.5.1 and LuaJIT 2.1.** The validator parses seven bindings, compares the two TOCs, verifies every runtime Lua file is included, and syntax-checks runtime/test chunks. ZIP checks cover integrity and correct addon-folder layout. CI also targets Lua 5.1; local LuaJIT tests exercise 5.1 semantics, but they do not imply a remote CI result.

The UI tests drive the shared dispatcher through menus, mouse coordinates, nested Back/page navigation, message controls, favorites, bars, key capture and profile-safe draft storage. They do not render textures/text or implement Blizzard's input/taint/security system.

## Remaining live verification

Run the entire manual checklist: rendered layouts at normal/small UI scales, named icon assets and fallback behavior, popup ordering, Settings/compartment entry points, actual key-up hardware callbacks, combat/taint behavior, instance chat restrictions, literal pipes, nearby audio and reload/full-restart persistence/migration. No screenshot or in-game success is claimed.

The generated modern texture API documentation declares a boolean return for SetTexture; this does not prove a particular file exists or that Forever reports an asynchronous asset failure the same way. Fallbacks handle errors/explicit rejection and blank paths; the real assets still need client inspection.

Deferred items explicitly allowed by the brief: profile text/JSON import/export, custom emote authoring, native Blizzard action-bar integration and localization. The release remains a test build until live verification is recorded.
