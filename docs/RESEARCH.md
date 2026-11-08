# Reference inspection — 2026-11-08

Read source before implementation: [Charades Wheel.lua](https://github.com/damesene/wow-charades/blob/main/Wheel.lua), [Actions.lua](https://github.com/damesene/wow-charades/blob/main/Actions.lua), [Editor.lua](https://github.com/damesene/wow-charades/blob/main/Editor.lua), [Charades_Camelot.toc](https://github.com/damesene/wow-charades/blob/main/Charades_Camelot.toc), [CurseForge listing](https://www.curseforge.com/wow/addons/charades), and [Forever Addon Kit](https://github.com/Thunderz96/forever-addon-kit).

Observed in source:

- Charades ships a `_Camelot.toc` declaring interface `16001`; ship a matching In Character flavor TOC plus the ordinary TOC. No evidence for a `_Forever.toc` convention in these references.
- Wheel input comes from binding down/up callbacks, cursor coordinates divided by effective scale, and direct mouse handlers. Escape uses `UISpecialFrames`. Its hover opens inner categories and outer selection runs on key release. In Character uses independently written, explicitly entered submenus and resets hover between pages to reduce accidental selection.
- Actions.lua enumerates `EMOTE<n>_TOKEN` and localized `CMD1..4` globals, calls `DoEmote`, and prefers `C_ChatInfo.SendChatMessage` with global fallback. In Character only dispatches recognized emotes and pool text. No arbitrary slash, sequence, macro, protected-action, or timer execution is included.
- Editor uses `BackdropTemplate`, `InputBoxTemplate`, and explicit combat guards. In Character uses its own compact standalone editor.
- The kit measures a modern API with interface 16001, notes unknown-event registration errors, and documents beta-era secure-snippet and SavedVariables bugs. These are historical observations, **not proof of current live-client behavior**. In Character feature-detects relevant APIs, guards event registration, uses no secure snippets, and requires live persistence checks. It does not install external bridges or write macros as a workaround.

Code and assets are independently written; Charades is a behavioral/API reference, not vendored. No Charades icons or arbitrary command execution were imported.

Preset research: [NBCUniversal's 20th anniversary article](https://www.nbcuniversal.com/article/celebrating-20-years-office) supports the short Michael Scott and Jim impersonation catchphrases. Jim's bear line belongs to **Jim impersonating Dwight**, not Dwight. [Rainn Wilson interview](https://www.aol.com/rainn-wilson-says-playing-dwight-000000582.html) explicitly discusses that misattribution and quotes Dwight's identity-theft line. Stanley and Michael Nicht lines were supplied directly by the project owner, not independently transcribed. See pack metadata for provenance.
