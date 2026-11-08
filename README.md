# In Character

Native Lua emote and dialogue launcher for WoW Forever, interface **16001**.

Phases 1–3 are implemented: core, versioned account/character profiles, dialogue selection modes, runtime emote token checks, five-tab editor, configurable bars, six optional community preset packs and a nested radial wheel. Automated tests run independently of WoW; live-client functionality is unverified.

Copy `InCharacter/` into `World of Warcraft/_forever_/Interface/AddOns/` so `InCharacter.toc` is directly inside `AddOns/InCharacter/`. Enable the addon, then type `/console scriptErrors 1` and `/reload`. Open `/ic` → Dialogue Pools, choose a preset, then click **Copy + greet/quote/bye**. `/ic greet`, `/ic quote`, `/ic bye` now use its editable pool copies. **Copy preset** leaves those shortcuts unchanged. Profiles can reset the shortcut mapping. Pools start empty and nothing sends automatically.

Run `lua tests/run.lua` or `luajit tests/run.lua` from this repository. No runtime dependencies.

Run `lua tests/ui.lua` or `luajit tests/ui.lua` for mocked UI callback tests. `/ic wheel` opens click confirmation; set **In Character** bindings in WoW's Key Bindings for the wheel, editor and favorites 1–4. The Wheel tab enables experimental hold/release; verify that in the live client before relying on it. Both TOCs specify 16001; the `_Camelot.toc` flavor follows the inspected Charades convention.
