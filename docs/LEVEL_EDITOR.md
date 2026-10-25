# Level Editor — format & where things live

First stop for anyone (human or AI) editing Eclipseborn levels.

## Quick map

| What | Path |
|------|------|
| Editor UI | `scenes/editor/LevelEditor.tscn`, `scripts/editor/LevelEditor.gd` |
| Piece proxy (draw/select/resize) | `scripts/editor/EditorPiece.gd` |
| Canonical sizes & anchors | `scripts/editor/PieceSpecs.gd` |
| Builtin zone seeds | `scripts/editor/ZoneCatalog.gd` (`cursed_cottage`, `lantern_village`, `clockwork_tower`, `house_keep`, `house_gear`, `house_inn`) |
| Backdrop (black-fire sky) | Universal `#0d020f` void + top fire fringe (`LevelData.default_backdrop`); JSON/`Background` mode can override; brick/city art may cover it |
| House shopkeeper defaults | `scripts/world/HouseProfiles.gd` |
| Load / save / spawn overlays | `scripts/autoload/LevelData.gd` |
| Saved overlays (repo) | `data/levels/<zone_id>.json` |
| Browser autosave | `user://editor/<zone_id>.json` |
| Live rooms (authoritative gameplay) | `scripts/world/CursedCottage.gd`, `LanternVillage.gd`, `HouseInterior.gd`, `ClockworkTowerZone.gd` |
| Build version (title menu) | `project.godot` → `application/config/version` (bump patch each change) |

### Piece IDs (numbered)

New and duplicated pieces use numeric suffixes (`window_1`, `lantern_12`), not letters. **Duplicate** offsets the copy up-right and allocates the next free number. **Move** tool shows X/Y arrows for single-axis drags.

### NPC / shopkeeper

Select a `prop_npc` piece → **Shop inventory** (all catalog items, stock Inf/−1 or a count, plus per-keeper **price**) when Shopkeeper is on; otherwise a dialogue box. New shopkeepers start with **all sales off** (`"shop_items": []`). Stored as `"is_shopkeeper": true` and `"shop_items": [{"id","stock","price"},…]`. House interiors read `npc_shop` via `LevelData.merged_piece`.

### Browser / session saves

Editor **Save (this session)** and auto-saves only last until you refresh the page. Refreshing clears `user://editor/` overlays so play uses repo `data/levels/` again. Use **Copy Save Code** (or commit JSON) to keep work.

### Tint color & text

- Floors, walls, platforms, crates, pipes, backgrounds, and **Text label** (`prop_text`) show a **Tint color** picker (wheel + `#hex`).
- Add **Text label** from Decor; edit text/font size in the inspector. Zone plaques (e.g. tower workshop/gallery) appear as `prop_text` pieces in the editor.
- **Right-click** (or middle-mouse) drag pans the viewport.

### Zone doors & houses

- **Zone door** (`prop_exit`) and **House facade** (`prop_house`): select → **Zone link** (target zone, spawn X/Y, fade caption). Builds on existing house exits / tower→village door.
- Palette also includes hatch, pipe, jar, enemy, tower so more builtins can be placed as non-catalog overlays.

### Levers, doors, and links

- Add **Lever** (`prop_switch`) or **Door (switchable)** (`prop_door`) from the palette.
- Select a lever → **Starts on** (begins powered or unpowered) and **Lever links**: multi-select lanterns and doors it should power.
- Saved as `"target_ids": ["lamp_street", "door_street_1"]` plus `"starts_on"`.
- Doors respond to `set_on` (open when powered). Checkpoints: Interact to rest and open **Fast Travel**.

### Creature damage

- Select an **Enemy** → creature type and **Damage**.
- Built-in defaults match the scripts: Wanderer 10, Rivet mite 8, Fuse beetle 10, Pendulum 14, Lamplighter 15.
- **Make default** remembers that number for creatures you add afterward (`user://editor_defaults.cfg`). Pieces already in the level are not rewritten.
- A piece only stores `"damage"` after you set it (or when you add a new creature). Older enemies with no key keep their script damage.

### Moving platforms & rotate

- Add **Moving platform** (`prop_platform`), or select an existing one (e.g. village gear platforms).
- When selected, the sidebar **Moving platform path** panel appears:
  - `Path distance` (`move_amplitude`) — how far along the main axis
  - `Move speed` — travel rate
  - `Vertical path` — move on Y instead of X
  - `Side path (wobble)` (`path_y_amplitude`) — elliptical secondary axis
  - `Rotate gear while moving` / `Rotate speed` — spin the bg gear
  - `Rotate platform body` — spin the floor itself
- A cyan path ghost draws in the viewport while the platform is selected.
- **Rotate** tool: click a piece and drag to set `"rotation"` (degrees).
- **Steam vent** (`prop_vent`): transparent rising steam particles.

## Sharing a level with an AI

1. Open the Level Editor (title → bottom-right hotspot → password).
2. Click **Copy Save Code** — JSON is copied to the clipboard and shown in a dialog.
3. Paste that JSON into chat (or commit it as `data/levels/<zone>.json`).

**Import Save Code** pastes JSON back into the editor.

Browser **Save** only writes `user://` (local to that browser). It does **not** update the git repo. Use **Copy Save Code** for that.

**Snap to edges** (sidebar toggle): while moving/resizing, piece edges snap to nearby pieces and the zone floor top.

## JSON schema (`schema`: 1)

```json
{
  "schema": 1,
  "zone": "cursed_cottage",
  "removed_ids": ["optional_catalog_id"],
  "pieces": [
    {
      "id": "box_push_1",
      "kind": "crate",
      "name": "Pushable Crate",
      "x": 980,
      "y": 453,
      "w": 58,
      "h": 58,
      "anchor": "center",
      "builtin": true
    }
  ]
}
```

### Piece fields

| Field | Meaning |
|-------|---------|
| `id` | Stable id. Catalog builtins keep theirs; new pieces use `kind_timestamp`. |
| `kind` | `floor`, `wall`, `crate`, `light`, `background`, or `prop_*` |
| `x`, `y` | World position. See **anchor**. |
| `w`, `h` | AABB size in pixels (must match gameplay). |
| `anchor` | `center` — `(x,y)` is box center. `bottom` — `(x,y)` is feet on the floor (houses, checkpoints, benches, towers). |
| `blocks_light` | `true` = occludes lantern washes via light-only physics layer 128 (no player collision). **Defaults on** for most kinds; lights / NPCs / enemies / pickups / backgrounds default off. |
| `layer` | Draw layer (`z_index`). Player is **0**. Use editor Layer ± to change. |
| `builtin` | `true` = seeded from `ZoneCatalog` / room script. |
| `radius` | Lantern wash radius (`kind: light` only). |
| `removed_ids` | Catalog ids deleted in the editor; rooms call `LevelData.prune_removed`. |

### Gameplay sizes (do not invent)

| Kind | Size | Notes |
|------|------|-------|
| Pushable crate (cottage) | **58×58** | `PushableBox` default; sit with `y = floor_top - 29` |
| Pushable crate (village) | **67×67** | sit with `y = floor_top - 33.5` |
| Cottage floor top | **482** | center 500, height 36 |
| Village floor top | **500** | center 520, height 40 |

`PieceSpecs.gd` is the single source for defaults. Editor crate art matches `PushableBox` wood texture 1:1 (no extra scale).

## How loads work

1. Room script builds the live layout (floors, lamps, crates, houses…).
2. `LevelData.apply(zone)` spawns **non-builtin** pieces from JSON.
3. `LevelData.prune_removed` deletes nodes tagged with ids in `removed_ids`.

Editor view merges `ZoneCatalog` + JSON overrides so the zone is never empty even when `pieces: []`.

## Applying a pasted save as a code change

1. Write/update `data/levels/<zone>.json` with the pasted JSON.
2. If builtins moved/resized, update matching entries in `ZoneCatalog.gd` **and** the room script (`CursedCottage.gd` / `LanternVillage.gd`) so play matches the editor.
3. Keep `PieceSpecs.gd` sizes in sync when changing crate/house defaults.
