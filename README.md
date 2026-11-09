# In Character

Emotes and roleplay lines for **WoW Forever (interface 16001)**, kept small enough to stay out of the way while you play. Native Lua, no libraries.

## Install

Download **InCharacter-0.13.1.zip** from [GitHub Releases](https://github.com/stronk-dev/wow_forever_mod_in_character/releases) when published, or build it with `python3 scripts/package.py`. Extract it into:

```text
World of Warcraft/_forever_/Interface/AddOns/InCharacter/
```

`InCharacter.toc` must be directly inside that folder. Enable the addon, then `/reload`. Before upgrading, close WoW and back up both `WTF/.../SavedVariables/InCharacter.lua` files.

**Prerelease for in-game testing:** 101 logic tests and 47 isolated mocked UI tests pass on Lua and LuaJIT. Manifest and ZIP checks pass. These checks do not verify Blizzard rendering, physical input routing, chat permissions, emote animations or nearby sound on Forever.

## What you see while playing

| Surface | How it works |
| --- | --- |
| **Main bar** | One 28px icon bar near the bottom of the screen: your favorites, then a button for each emote category, then your RP character once it has lines. Empty pools stay in settings and are omitted from play controls. Click an emote to do it. Click a category to open its list. Click a pool to play its next line; its small arrow (or right-click) lists its exact lines. |
| **Lists (flyouts)** | Open upward from bars in the lower half of the screen, downward from the top half. Long lists scroll in one bounded column, with small navigation buttons. Pointing at a pool or group opens it to the side and never sends anything. Right-click an emote or exact line to pin or unpin it as a favorite (marked with a gold `*`); right-click a pool opens its lines. Click elsewhere or press Esc to close. |
| **Round launcher** | Click: the same list as a menu (or the radial wheel, if you choose). Left, right and middle clicks each have their own configurable action (menu, ring, settings, Edit Mode, show/hide bars or nothing). Shift-drag: move the launcher. |
| **Radial wheel** | Press its key and a compact ring (about 200–250 UI units before fans) appears under the cursor. Groups show small previews of their contents, and pointing at one fans its items out beyond it. Expanded fans need additional space. Only a left-click sends, or releasing the key in hold mode. Clicking a group goes into it; the centre goes back. Right-click a pool opens its lines; elsewhere right-click goes back or closes. Esc closes; scroll pages long lists. |
| **Emote menu key** | The same list opened at the cursor. |

Play controls remain accessible in combat; the client may restrict chat or emotes. Settings and bar editing wait until after combat.

## Settings (`/ic`, Options → AddOns, or right-click the launcher)

- **Emotes & lists:** every bar, ring and menu shows a *list*. The built-in lists are:
  - **Favorites**;
  - one per category: **Combat callouts**, **Greetings & manners**, **Reactions**, **Poses & idle**, **Playful emotes**, initially using the smaller suggested/kept selection;
  - **Main bar**, which shows the favorites inline and the categories as groups;
  - **RP: your character**, which follows the loaded character.

  Create, copy and reorder lists; choose a group icon; add any list to another as a group button or inline. The Bar / Ring / Menu buttons assign the selected list directly. Copy the dynamic RP list when you want a separately editable selection. The **library** on the right shows every emote the client knows (about 250 plus aliases). Filters distinguish your character's recorded results (*Heard nearby*, *Anim. seen*, *Text checked*) from Retail reference classifications marked *(ref)*. Search and category filters are also available. Choose RP pools, Exact lines or Pool modes to add normal pool buttons, specific messages or random/shuffle/sequential overrides directly to any list. Right-click a row to add or remove it. Select an emote to try it, rename it, change its icon, or record what you and others actually saw and heard on this character.
- **RP lines:** choose or create the RP character you're playing and edit its pools (Say / Yell / Emote text; shuffle, random or in order; one line per row; byte counter). Individual messages can be edited, reordered, given icons and placed in any list while retaining their button IDs. Unsaved message drafts survive switching pools and tabs. Bulk edits refuse to replace messages referenced by buttons; use Individual messages for those edits. Copy preset characters (Stanley, Mastermovies / Michael Nicht, other Office characters, everyday Dutch; see [LIBRARY.md](LIBRARY.md)).
- **Layout & keys:**
  - The launcher, including independent left/right/middle mouse actions.
  - Bars: *Move & edit bars*, *+ A bar per category*, *+ Favorites bar*, and hide or show all bars.
  - The wheel: key, click or hold mode, which list it shows, icon size, and *Try it*.
  - The emote menu: key and which list it shows.
  - Favorite keys 1–4.
- **Profiles:** shared or per-character data and layouts, and reset.

**Move & edit bars** (`/ic edit`, middle-click the launcher, or Blizzard's Edit Mode where supported) highlights every bar. Drag to move. A small panel then lets you choose:
- which list the bar shows;
- button size (12–64 UI units), buttons per row, or drag the corner to define a fit area;
- vertical layout and names under icons;
- hidden, locked or collapsed;
- delete or add a bar, and Undo.

Clicks select bars here and never play anything. Outside Edit Mode, bars hug their visible buttons; the fit rectangle is only shown while editing. Long bars wrap to the available space and page instead of extending off screen. Shift-middle-click a bar to collapse it into one icon; click that icon to expand, or use its arrow as a flyout.

## Emote facts

Sound and animation labels come from the [Warcraft Wiki emote table](https://warcraft.wiki.gg/wiki/List_of_emotes), which documents Retail, and are marked as reference. The small blue dot on a button means *you recorded that others heard it*. Whether an emote exists comes from the running client. Emotes the client doesn't know are hidden on bars, wheel and menu but stay in your lists.

## Commands

```text
/ic                       settings            /ic edit       move & edit bars
/ic wheel                 radial wheel        /ic menu       emote menu at the cursor
/ic bars                  hide / show bars    /ic lines      RP lines page
/ic greet | quote | bye   starter pools       /ic <pool>     play a named pool
/ic play random|shuffle|sequential <pool>     /ic character <name>
/ic message <pool ID> <message ID>            /ic help
```

If another addon owns `/ic`, use `/incharacter`. No keys are assigned automatically. Key Bindings → In Character lists: settings, wheel, emote menu, show/hide bars, move & edit bars, favorite 1–4.

## Safety and limits

- **Sends only on your input:** a click, a key or a slash command. There is no timed or automatic chat, no macro text, and no spells, items or targeting. Hovering never sends.
- **Message length:** lines are stored at any length. A line is sent only if it fits **255 bytes after pipe escaping**. Lines are never split or truncated.
- **Chat restrictions:** if the client reports a chat lockdown or restriction, nothing is sent and playback doesn't advance. Nothing is queued for later.
- **Saved data:** `InCharacterDB` (shared) and `InCharacterCharDB` (per character).
- **Upgrades:** schema 12 converts each old bar's source, included/hidden items, categories and playback mode into an explicit list. Existing bars retain their visibility, position, size and collapse state. No replacement bar is added. The unfinished 0.12 upgrade's `hiddenByUpgrade` flags are repaired once; deliberately hidden bars stay hidden. Each layout keeps a `preFoundation` recovery snapshot. Old per-wheel/menu choices become separate editable lists. Repeated reloads preserve edits to these lists.

This addon manages its own buttons; it does not add spells, items, native action-bar drag/drop or custom audio broadcasting.

## Development

```sh
lua tests/run.lua && lua tests/ui.lua
luajit tests/run.lua && luajit tests/ui.lua
python3 scripts/verify.py && python3 scripts/package.py
lua scripts/layout_preview.lua > dist/InCharacter-layout.svg
```

The shared collection model feeds every play surface. `Platform.lua` owns client integrations (chat, emotes, restrictions, tokens, bindings, cursor, Settings and Edit Mode); domain services use that boundary. Pure bar/menu models are in `Models/`, and the radial model is in `Services/WheelModel.lua`. `scripts/layout_preview.lua` renders their real dimensions to SVG without starting WoW. This is a geometry illustration, not an in-game screenshot. `scripts/gen_emote_catalog.py` regenerates `Data/EmoteCatalog.lua` from the wiki table. See [CONTRIBUTING.md](CONTRIBUTING.md). Original code is MIT. Third-party attribution is in `InCharacter/THIRD_PARTY_NOTICES.txt`. Quotes and Blizzard assets belong to their owners.

CI runs logic/UI tests on Lua 5.1 and LuaJIT and validates the addon before packaging. Push a matching `v<version>` tag to publish the tested ZIP and SVG as a prerelease; branch and PR builds upload workflow artifacts without publishing a release.
