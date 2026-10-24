# Level Editor — format & where things live

First stop for anyone (human or AI) editing Eclipseborn levels.

## Quick map

| What | Path |
|------|------|
| Editor UI | `scenes/editor/LevelEditor.tscn`, `scripts/editor/LevelEditor.gd` |
| Piece proxy (draw/select/resize) | `scripts/editor/EditorPiece.gd` |
| Canonical sizes & anchors | `scripts/editor/PieceSpecs.gd` |
| Builtin zone seeds | `scripts/editor/ZoneCatalog.gd` |
| Load / save / spawn overlays | `scripts/autoload/LevelData.gd` |
| Saved overlays (repo) | `data/levels/<zone_id>.json` |
| Browser autosave | `user://editor/<zone_id>.json` |
| Live rooms (authoritative gameplay) | `scripts/world/CursedCottage.gd`, `LanternVillage.gd` |

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
      "id": "box_push_a",
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
