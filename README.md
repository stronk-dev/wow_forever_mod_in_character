# In Character

Native Lua emote and dialogue launcher for WoW Forever, interface **16001**.

Phase 1: implemented core, versioned account/character profiles, random/shuffle/sequential pools, runtime emote token checks, slash commands and a draggable favorites bar. Automated tests run independently of WoW; live-client functionality is unverified.

Copy `InCharacter/` into `World of Warcraft/_forever_/Interface/AddOns/` so `InCharacter.toc` is directly inside `AddOns/InCharacter/`. Enable the addon, then type `/console scriptErrors 1` and `/reload`. `/ic help` lists commands; `/ic greet`, `/ic quote`, `/ic bye` use the corresponding pools. Pools start empty; optional presets and the editor follow in Phase 2.

Run `lua tests/run.lua` or `luajit tests/run.lua` from this repository. No runtime dependencies.
