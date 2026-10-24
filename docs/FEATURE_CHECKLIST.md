# Unbound — feature checklist vs plan (draft 6)

Status after the first implementation pass. ✅ in game now · 🚧 stub / partial · ❌ not yet

## Phase 0 — Prototype
- ✅ Godot 4.3 project
- ✅ Hearth lamp + moveable box + walkable shadow collision (`ShadowWorld`)
- ✅ Walk, run (Shift), single jump — double jump gated on `GameState.has_double_jump`
- ✅ Shade bar (1.5s hearth drain) + health number (100, burns after shade empty)
- ✅ Immoveable box (bump / shake) vs moveable (push / slide)
- ✅ Pushable lamps
- ✅ Prototype room scene (`scenes/rooms/PrototypeRoom.tscn`)

## Phase 1 — Core systems
- ✅ Gears that move a linked platform (`Gear.gd` in Lantern Village)
- ✅ Light switch lever toggles a street lamp (`LightSwitch.gd`)
- ✅ Light kinds: hearth, candle, moon, crimson, sunshaft (data + colors; crimson walls in ShadowWorld)
- ✅ F attack + hitbox / hurtbox framework (once-per-swing)
- ✅ Title menu: Play + Controls + rebind + reset
- ✅ Esc pause menu (single-player pauses via `GameState.set_paused`)
- ✅ Checkpoints + save slots (`SaveManager`)

## Phase 2 — First slice
- ✅ Cursed Cottage 4-room tutorial (hall → crate → chest → hatch)
- ✅ Hatch breaks with F → Lantern Village
- ✅ Lamplighter (tough enemy) unlocks double jump on defeat
- 🚧 Sounds / music (hooks only — no audio assets yet)
- ✅ Tab zone map with player icon (cottage + village layouts)
- ✅ Steel-and-steam visual language (riveted floors, pipes, iron doors)
- ✅ One shade heart in Lantern Village (+25 max HP)
- ✅ Basic enemy with hit/hurt boxes + pogo bounce

## Phase 3 / 4
- ❌ Online co-op / group saves
- ❌ Remaining zones, bosses, story endings

## How to run
```bash
godot --path /workspaces/Eclipseborn
```
Main scene: title menu → Play → New Game → Cursed Cottage.

Prototype sandbox (from Godot: open `scenes/rooms/PrototypeRoom.tscn` and play).
