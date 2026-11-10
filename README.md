# In Character

Emotes and roleplay lines for **WoW Forever (interface 16001)**, kept small enough to stay out of the way while you play. Native Lua, no libraries.

## Install

Download **InCharacter-0.14.0.zip** from [GitHub Releases](https://github.com/stronk-dev/wow_forever_mod_in_character/releases) when published, or build it with `python3 scripts/package.py`. Extract it into:

```text
World of Warcraft/_forever_/Interface/AddOns/InCharacter/
```

`InCharacter.toc` must be directly inside that folder. Enable the addon, then `/reload`. Before upgrading, close WoW and back up both `WTF/.../SavedVariables/InCharacter.lua` files.

**Prerelease for in-game testing:** 97 logic tests and 49 isolated mocked UI tests pass on Lua and LuaJIT, and `tests/layout_probe.lua` finds no cut-off or overlapping text on the play surfaces. None of this verifies Blizzard rendering, physical input, chat permissions, emote animations or nearby sound on Forever.

## Playing in character

Pick your RP character once. Every character has the same three roles: **Greeting**, **Quote** and **Farewell**, plus any extra pools you add. Bars, the menu, the wheel and `/ic greet | quote | bye` always use the loaded character's roles, so switching character keeps your layout and only changes what is said. Buttons show the role word; where a preset came from appears only as a dimmed line in the tooltip.

Switch character from the first row of the RP list (on the bar, in the menu or in the wheel), or with `/ic character <name>`.

## What you see while playing

| Surface | How it works |
| --- | --- |
| **Bars** | Choose **one bar** (favorites, the five emote categories as groups, and your RP character) or **separate bars** (favorites, one bar per category, and an RP bar). Each layout keeps its own positions. Bars are icons only, with no titles; tooltips name things. Click an emote to do it. Click a group to open its list. Click a role or pool to say its next line; its small arrow (or right-click) lists the exact lines. |
| **Lists (flyouts)** | Open away from the screen edge, sized to their names. Pointing at a group or role opens it beside the list and never sends; the tooltip appears on the other side, so it never covers that list. Right-click an emote or line to pin or unpin it as a favorite (gold `*`). Click elsewhere or press Esc to close. |
| **Launcher** | Left-click: emote menu. Right-click: settings. Shift-drag: move. Its tooltip names the character you're playing. |
| **Radial wheel** | Press its key: 7 slices under the cursor (Favorites, the five categories, your RP character). Point anywhere in a slice's direction; its full name appears beside the ring, never squeezed into the centre. Choosing a group zooms into it as its own ring (at most 8 slices; scroll pages). The centre goes back, or closes at the top. Only a click, or releasing the key in hold mode, sends. |
| **Emote menu key** | The same list as the launcher menu, opened at the cursor. |

Play controls work in combat; the client may still restrict chat or emotes. Settings and bar editing wait until after combat.

## Settings (`/ic`, Options → AddOns, or right-click the launcher)

- **Emotes & lists:** your lists on the left, what is in the selected list in the middle (Up / Down / Remove), and a searchable library on the right (every emote, a category, or your character's lines). Right-click a library row to add or remove it. Select an entry to try it, favorite it, rename it or change its icon. **Advanced** adds the testing tools: wiki sound/animation filters, emotes this client lacks, recording what you and others saw and heard, and nesting one list inside another.
- **RP lines:** choose or create the character you're playing. Edit its pools: name, role (Greeting / Quote / Farewell / none), Say, Yell or Emote text, shuffle, random or in order, one line per row with a byte counter. Individual messages keep their button IDs when edited. **Play as this character** turns a preset (Stanley, Mastermovies / Michael Nicht, other Office characters, everyday Dutch; see [LIBRARY.md](LIBRARY.md)) into your own editable copy.
- **Layout & keys:** one bar or separate bars, Move & edit bars, hide bars; the launcher (shown, size); the wheel (key, click or hold, which list, icon size); the emote menu (key, which list); favorite keys 1–4.
- **Profiles:** shared or per-character data and layouts, and reset.

**Move & edit bars** (`/ic edit`, Shift-right-click a bar, or Blizzard's Edit Mode where supported) tints every bar and shows its name *on* the bar. Drag to move. Click a bar and a small panel opens next to it with: one bar or separate bars, which list it shows, size, per row, vertical, names, hidden, locked, delete, + Bar, and Undo all. Clicks select here and never play anything.

## Emote facts

Sound and animation labels come from the [Warcraft Wiki emote table](https://warcraft.wiki.gg/wiki/List_of_emotes), which documents Retail, and are marked as reference. The small blue dot on a button means *you recorded that others heard it*. Whether an emote exists comes from the running client. Emotes the client doesn't know are hidden on bars, wheel and menu but stay in your lists.

## Commands

```text
/ic                       settings            /ic edit       move & edit bars
/ic wheel                 radial wheel        /ic menu       emote menu at the cursor
/ic bars                  hide / show bars    /ic lines      RP lines page
/ic bars one | separate   switch bar layout   /ic <pool>     play a named pool
/ic greet | quote | bye   your character's Greeting / Quote / Farewell
/ic play random|shuffle|sequential <pool>     /ic character <name>
/ic message <pool ID> <message ID>            /ic help
```

If another addon owns `/ic`, use `/incharacter`. No keys are assigned automatically. Key Bindings → In Character lists: settings, wheel, emote menu, show/hide bars, move & edit bars, favorite 1–4.

## Safety and limits

- **Sends only on your input:** a click, a key or a slash command. There is no timed or automatic chat, no macro text, and no spells, items or targeting. Hovering never sends.
- **Message length:** lines are stored at any length. A line is sent only if it fits **255 bytes after pipe escaping**. Lines are never split or truncated.
- **Chat restrictions:** if the client reports a chat lockdown or restriction, nothing is sent and playback doesn't advance. Nothing is queued for later.
- **Saved data:** `InCharacterDB` (shared) and `InCharacterCharDB` (per character).
- **Upgrading to 0.14 (schema 13), once:** lists earlier versions generated by themselves ("My wheel", "Wheel / …", "Menu / …", one copy per old bar) move out of sight into the save (`profile.retired.collections`), unless a list you made or your favorites point to one; those are kept as ordinary lists. The wheel and menu go back to the built-in lists. Old bars stay in the save, unused (`layout.retired`); the main bar keeps the old main bar's position, size and hidden state, and if you had no visible bars it stays hidden. Pool names that start with their exact preset title lose that "<preset> / " prefix once; names you type later are never changed. Each character's Greeting / Quote / Farewell slots are filled from its pools once; a slot you empty stays empty. Pools, lines, characters, favorites and your own lists are kept.

This addon manages its own buttons; it does not add spells, items, native action-bar drag/drop or custom audio broadcasting.

## Development

```sh
lua tests/run.lua && lua tests/ui.lua
luajit tests/run.lua && luajit tests/ui.lua
python3 scripts/verify.py && python3 scripts/package.py
lua scripts/layout_preview.lua > dist/InCharacter-layout.svg
lua tests/layout_probe.lua /tmp/ic-probe   # wireframe + findings for every surface
```

`tests/layout_probe.lua` loads the addon in the mocked client with the full emote catalog and a loaded preset character. It opens every surface (bars, flyouts, menu, wheel, Edit Mode, each settings page, popups), resolves every anchor, and writes a wireframe per state plus `report.txt` listing cut-off text, overlapping text and controls. Text widths are estimated and art is approximated: these are wireframes, not screenshots. [docs/UX_AUDIT.md](docs/UX_AUDIT.md) records the audit, the research into other addons and the decisions behind 0.14.

The shared collection model feeds every play surface. `Platform.lua` owns client integrations (chat, emotes, restrictions, tokens, bindings, cursor, Settings and Edit Mode); domain services use that boundary. Pure bar/menu models are in `Models/`, and the radial model is in `Services/WheelModel.lua`. `scripts/layout_preview.lua` renders their real dimensions to SVG without starting WoW. This is a geometry illustration, not an in-game screenshot. `scripts/gen_emote_catalog.py` regenerates `Data/EmoteCatalog.lua` from the wiki table. See [CONTRIBUTING.md](CONTRIBUTING.md). Original code is MIT. Third-party attribution is in `InCharacter/THIRD_PARTY_NOTICES.txt`. Quotes and Blizzard assets belong to their owners.
