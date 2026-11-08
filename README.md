# In Character

Native Lua emote and dialogue launcher for WoW Forever, interface **16001**.

Phases 1–2: core, versioned account/character profiles, dialogue selection modes, runtime emote token checks, five-tab editor, multiple configurable bars and six optional community preset packs are implemented. Automated tests run independently of WoW; live-client functionality is unverified. The radial wheel follows in Phase 3.

Copy `InCharacter/` into `World of Warcraft/_forever_/Interface/AddOns/` so `InCharacter.toc` is directly inside `AddOns/InCharacter/`. Enable the addon, then type `/console scriptErrors 1` and `/reload`. Open `/ic` → Dialogue Pools, choose a preset, then click **Copy + greet/quote/bye**. `/ic greet`, `/ic quote`, `/ic bye` now use its editable pool copies. **Copy preset** leaves those shortcuts unchanged. Profiles can reset the shortcut mapping. Pools start empty and nothing sends automatically.

Run `lua tests/run.lua` or `luajit tests/run.lua` from this repository. No runtime dependencies.
