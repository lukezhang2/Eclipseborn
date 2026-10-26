# AI planning

Shared work board so **Cursor** and **Claude** do not overlap.

## How to use (both AIs)

1. **Read this file first** before planning or editing anything for a new user prompt.
2. If the user’s request is **already listed as in-progress or planned** under the other AI (or under your own section as actively claimed), **stop** and tell the user that the other AI is already on it.
3. If the work is free, **write your plan under your section** before you start coding.
4. When finished, mark items done or remove them so the board stays accurate.
5. Do not edit the other AI’s section except to leave a short handoff note if you blocked on their work.

---

## Cursor

**Cursor rules (every prompt):**
- Read this file (and Claude’s **Done recently**) before planning or implementing.
- If the request is already claimed by Claude, or already listed under **Done recently** in either section, **stop** and tell the user.
- Write the plan under **Active / claimed** before implementing.
- On every update: bump `config/version` to **one patch above the highest** of Cursor Done / Claude Done / `origin/main`; run `bash tools/export-web.sh`; commit; push the branch **and** `main` (Pages).
- Log each ship in **Done recently** as one short line: `vX.Y.Z · YYYY-MM-DD h:mm AM/PM EDT — …`.

### Active / claimed
_(none)_

### Queue
_(none)_

### Done recently
- v0.1.94 · 2026-10-26 4:28 PM EDT — Done-recently entries stamped with ship date/time (EDT) from git; `index-0_1_94.pck`
- v0.1.93 · 2026-10-26 4:25 PM EDT — Wickwright hovers above lever ledges (floor jumps can't reach); tighter hurtbox; `index-0_1_93.pck`
- v0.1.92 · 2026-10-26 4:22 PM EDT — Attack while climbing; hold on rung during swing; climb anim resumes only if still on ladder; `index-0_1_92.pck`
- v0.1.91 · 2026-10-26 4:17 PM EDT — Unwedge stuck fall-in-place (snap to nearby floor / cancel phantom fall anim); `index-0_1_91.pck`
- v0.1.90 · 2026-10-26 4:09 PM EDT — Fix crate pull self-acceleration (double-move) and wall-wedge (stand-off gap + wall block); `index-0_1_90.pck`
- v0.1.89 · 2026-10-26 4:03 PM EDT — Snuff arena lamps after Wickwright defeat (no leftover wash circles); dial etching replaces floor disc; crystal/chest cleanup; `index-0_1_89.pck`
- v0.1.88 · 2026-10-26 3:53 PM EDT — Wickwright defeat cutscene: wind-up slam, impact shake, debris burst; layered brick wall breach replaces flat hole; `index-0_1_88.pck`
- v0.1.87 · 2026-10-26 3:37 PM EDT — Editor palette reorganized (Terrain/Lights/Doors/Props/Scenery/Actors); new houses create selectable zones (removed when facade deleted); `index-0_1_87.pck`
- v0.1.86 · 2026-10-26 11:56 AM EDT — Tower door Interact-only; death/cutscene state cleared on zone change; checkpoints zone-aware so leaving tower can't softlock death; `index-0_1_86.pck`
- v0.1.85 · 2026-10-25 3:29 AM EDT — Demo end via shaft descent; Wickwright falls left; Match-the-Hour removed (levers slam all ON); `index-0_1_85.pck`
- v0.1.84 · 2026-10-25 3:26 AM EDT — step off the top of a ladder smoothly instead of hopping; `index-0_1_84.pck`
- v0.1.83 · 2026-10-25 3:23 AM EDT — sync clockwork_tower (arena levers→lamps 4–6, remove floor a/b/c); `index-0_1_83.pck`
- v0.1.81 — sync clockwork_tower (arena levers→lamps 4–6, remove floor a/b/c, enemies in overlay); `index-0_1_81.pck`
- v0.1.80 · 2026-10-25 3:20 AM EDT — Wickwright sword hits reach + flash/sparks/wound dial feedback; `index-0_1_80.pck`
- v0.1.77 · 2026-10-25 3:10 AM EDT — Wickwright takes full sword hits (10 to kill, larger hurtbox); `index-0_1_77.pck`
- v0.1.76 · 2026-10-25 3:08 AM EDT — Enemies drop 2–3 silver gears on kill; gear pickup delay 0.25s; `index-0_1_76.pck`
- v0.1.75 · 2026-10-25 3:00 AM EDT — sync clockwork_tower (gallery pushable lanterns, cloister floors, arena lamps 4–6, removed texts/practice lamps); `index-0_1_75.pck`
- v0.1.74 · 2026-10-25 2:55 AM EDT — LightSource never builds a solid body / never pushable (hard disable); `index-0_1_74.pck`
- v0.1.73 · 2026-10-25 2:52 AM EDT — Lanterns never collide with player; editor/LevelData lights default non-pushable; `index-0_1_73.pck`
- v0.1.72 · 2026-10-25 2:47 AM EDT — Playtest Zone shows session editor edits (trusted user:// mirror + sync tagged builtins on apply); `index-0_1_72.pck`
- v0.1.71 · 2026-10-25 2:45 AM EDT — boot shows the real title behind the glass (no white flash); Clockwork crack look; particle steam vents; Wickwright redrawn as the Grandfather Wraith (animated wings, pendulum heart, eye tracking); `index-0_1_71.pck`
- v0.1.70 · 2026-10-25 2:45 AM EDT — Clockwork Tower enemies visible/editable in Level Editor (catalog + LevelData spawn); `index-0_1_70.pck`
- v0.1.69 · 2026-10-25 2:29 AM EDT — Editor Ctrl/Cmd multi-select (group move/dupe/delete/layer/light settings), top-layer click pick, Resize N/E/S/W edge grips; `index-0_1_69.pck`
- v0.1.68 · 2026-10-25 2:27 AM EDT — Editor lantern kind (Moon / Hearth / Candle / Crimson / Sunshaft); `index-0_1_68.pck`
- v0.1.67 · 2026-10-25 2:27 AM EDT — sync cursed_cottage (backdrop, moon lamp mid-hall, hatch spawn 520/460); `index-0_1_67.pck`
- v0.1.66 · 2026-10-25 2:24 AM EDT — Editor number fields apply on Enter only; clicking away keeps the previous value; `index-0_1_66.pck`
- v0.1.65 · 2026-10-25 2:23 AM EDT — sync cursed_cottage (backdrop JSON, moon lamp → mid hall, hatch spawn 520/460); `index-0_1_65.pck`
- v0.1.64 · 2026-10-25 2:10 AM EDT — Editor mob HP (script defaults; Make default for new mobs only); `index-0_1_64.pck`
- v0.1.63 · 2026-10-25 2:08 AM EDT — Editor creature damage (script defaults; Make default for new creatures only) and lever Starts on; `index-0_1_63.pck`
- v0.1.62 · 2026-10-25 2:04 AM EDT — Session-only editor overlays (clear on refresh); brick/backdrop Background palette; `index-0_1_62.pck`
- v0.1.61 · 2026-10-25 1:57 AM EDT — levers flip on attack hit as well as Interact; `index-0_1_61.pck`
- v0.1.60 · 2026-10-25 1:56 AM EDT — player map: undiscovered cover hides lantern light that spilled above it; `index-0_1_60.pck`
- v0.1.59 · 2026-10-25 2:03 AM EDT — Clockwork Tower boss resets on player death (HP/phase/gate/lamps); `index-0_1_59.pck`
- v0.1.58 · 2026-10-25 1:53 AM EDT — Editor zone-link doors/houses/hatches + spawn more palette kinds (pipe/jar/enemy/tower); `index-0_1_58.pck`
- v0.1.57 · 2026-10-25 1:49 AM EDT — Editor: shopkeeper sales default off + per-shop prices; piece color hex/wheel; RMB pan; prop_text + show text pieces; `index-0_1_57.pck`
- v0.1.55 · 2026-10-25 1:38 AM EDT — player map: zone nameplate, plaque labels, reveal only the framed screen; `index-0_1_55.pck`
- v0.1.54 · 2026-10-25 1:36 AM EDT — Backpack no-pause; Equipment + Consumables tabs; player preview + 3 accessory slots; `index-0_1_54.pck`
- v0.1.52 · 2026-10-25 1:27 AM EDT — lantern wash: fix TAU-wrap rim scramble + keep corner grazes (no jagged shards); `index-0_1_52.pck`
- v0.1.51 · 2026-10-25 1:25 AM EDT — Inventory on B (+ HUD Bag button) with shop-style fade; supplies stash/use, abilities + key items; `index-0_1_51.pck`
- v0.1.50 · 2026-10-25 1:24 AM EDT — #0d020f fire-sky universal zone backdrop; `index-0_1_50.pck`
- v0.1.49 · 2026-10-25 1:23 AM EDT — player map: textured side-view of every zone piece, whole zone fitted in the panel; `index-0_1_49.pck`
- v0.1.48 · 2026-10-25 1:18 AM EDT — village purple full-field BG + top-only fire fringe (nudged up); editor Pieces/Background mode; `index-0_1_48.pck`
- v0.1.47 · 2026-10-25 1:17 AM EDT — Clockwork Tower ladders (hold W climb + climb anim), full lobby floor (no hole), story floors + denser brick backdrop; `index-0_1_47.pck`
- v0.1.46 · 2026-10-25 1:06 AM EDT — Clockwork Tower in Level Editor (zone seed, playtest, tall-map camera, lamp/checkpoint overlays); `index-0_1_46.pck`
- v0.1.45 · 2026-10-25 1:02 AM EDT — single yellow light wash; houses above wash (no paint-through); quieter umbras; `index-0_1_45.pck`
- v0.1.44 · 2026-10-25 1:00 AM EDT — tower polish: zone fades, death anim+fade, lobby+pre-boss CPs, bottom-left spawn, jump-reach climb, boss wake/seal, floor lamps+high levers, side rooms, lever flip; keeps village exit left-of-tower; `index-0_1_44.pck`
- v0.1.43 · 2026-10-25 12:59 AM EDT — tower exit spawns left of the village tower (not on the door); `index-0_1_43.pck`
- v0.1.42 · 2026-10-25 12:53 AM EDT — fire band on-screen; light fill/outline linear opacity (max 50%/100%); overlaps add intensity; `index-0_1_42.pck`
- v0.1.41 · 2026-10-25 12:40 AM EDT — light wash matches burns (no fake BG cuts); fan-fill depth; village fire sky only (no brick/city); `index-0_1_41.pck`
- v0.1.40 · 2026-10-25 12:37 AM EDT — Clockwork Tower climb + Wickwright (Match the Hour), defeat cutscene, reward chest → crystal piece (double jump overlay), apex checkpoint, village descent hole; `index-0_1_40.pck`
- v0.1.39 · 2026-10-25 12:28 AM EDT — lantern AoE visible on floor (wash z above floors, brighter fill + bold occluded edge); `index-0_1_39.pck`
- v0.1.38 · 2026-10-25 12:22 AM EDT — realistic cheap shadows: contact-hardening umbra, soft penumbra, wash falloff (no extra rays); `index-0_1_38.pck`
- design — Clockwork Tower combat/boss/ascent plan (`docs/CLOCKWORK_TOWER_COMBAT.md`); no gameplay ship
- v0.1.37 · 2026-10-25 12:04 AM EDT — editor Undo/Redo buttons + Ctrl+Z/Y/Shift+Z; snapshot history for move/resize/rotate/inspector; `index-0_1_37.pck`
- v0.1.35 · 2026-10-24 11:59 PM EDT — ShadowWorld perf: 12Hz throttle, poly cache, physics umbra clip, node pool, no spin dirty; `index-0_1_35.pck`
- v0.1.34 · 2026-10-24 11:57 PM EDT — editor Duplicate + Move axis arrows; piece ids numbered (not lettered); levels updated
- v0.1.33 · 2026-10-24 11:48 PM EDT — shop GUI fade (gear prices + editor stock Inf/N); fast-travel fade polish; no shopkeeper dialogue
- v0.1.32 · 2026-10-24 11:48 PM EDT — sync lantern_village: bench 455, vent 1053, platform A travel 200 at x=1278, hearth lamp r=300, shade heart above platform B, extra steam vent; `index-0_1_32.pck`
- v0.1.31 · 2026-10-24 11:44 PM EDT — clipped realistic shadows (floors/walls/BG); editor light intensity (wash + burn rate); `index-0_1_31.pck`
- v0.1.30 · 2026-10-24 11:35 PM EDT — first death uses last hearth, not continue/logout position; save checkpoint_x/y separately; `index-0_1_30.pck`
- v0.1.29 · 2026-10-24 11:30 PM EDT — Brass & Rivets UI theme and steampunk world art
- v0.1.28 · 2026-10-24 11:46 PM EDT — steel floor walk bank; jump matched; no death land spam; burn loops fixed; realistic hurt (keeps 0.1.27 hit-connect)
- v0.1.27 · 2026-10-24 11:27 PM EDT — enemy hit flash/knockback; hit-connect SFX when player attack lands
- v0.1.26 · 2026-10-24 11:23 PM EDT — shadow crystal: no floating label; tiny red ember in the core
- v0.1.25 · 2026-10-24 11:22 PM EDT — editor moving-platform path/spin inspector when selected + path ghost; village platforms are prop_platform
- v0.1.24 · 2026-10-24 11:18 PM EDT — quieter intro; natural walk/slash/jump/land (−45%); hurt + shade/HP burn loops; `index-0_1_24.pck`
- v0.1.23 · 2026-10-24 11:12 PM EDT — enemies blocked by pushable crates (`pass_through_objects` opt-out); fall anim mild arm raise
- v0.1.22 · 2026-10-24 11:10 PM EDT — fix silent SFX: default AudioBusLayout (SFX/Music), AudioManager ALWAYS + web unlock; `index-0_1_22.pck`
- v0.1.21 · 2026-10-24 11:07 PM EDT — permanent shadow crystal fragments (saved collected_ids); map hint “Tab to close” only
- v0.1.20 · 2026-10-24 11:03 PM EDT — longer cardinal attack hitboxes to match slash sprite tip (N/E/S/W); `index-0_1_20.pck`
- v0.1.19 · 2026-10-24 11:02 PM EDT — persist activated hearths (JSON sidecar + web flush); tall unmissable hearth hitbox; restore lit on load
- v0.1.18 · 2026-10-24 10:58 PM EDT — player hitboxes: flush red attack boxes, inset yellow hurtbox, enemies no longer body-block; `index-0_1_18.pck`
- v0.1.17 · 2026-10-24 10:52 PM EDT — Cursor workflow: always export+push main; sync version past Claude Done history
- v0.1.16 · 2026-10-24 10:58 PM EDT — house fade + interact lock; editor platform path/spin + rotate tool; steam vents (includes village lamp sync)
- v0.1.15 · 2026-10-24 10:46 PM EDT — sync lantern_village: remove door_street_a, lever→street+square only, lamp radii/pos; `index-0_1_15.pck`
- v0.1.14 · 2026-10-24 10:16 PM EDT — Minecraft lever; editor lever→lantern/door links; switchable doors; checkpoint fast travel
- v0.1.13 · 2026-10-24 10:09 PM EDT — geometry house cover (burns + washes), left exit door (Interact/walk), rebuilt village/cottage lights
- v0.1.12 · 2026-10-24 9:41 PM EDT — house light occlusion (layer 128 burns), left Interact exit, rebuilt lantern washes, continuous zone map
- v0.1.11 · 2026-10-24 9:31 PM EDT — Settings on the title menu too
- v0.1.10 · 2026-10-24 9:21 PM EDT — sync lantern_village from editor save (switch/lamp/crate/platform); `index-0_1_10.pck`
- v0.1.8 · 2026-10-24 9:07 PM EDT — corner-aware lantern rays + safer umbra (closes random light gaps); `index-0_1_8.pck`
- v0.1.7 · 2026-10-24 9:02 PM EDT — default `blocks_light` ON for most piece kinds
- v0.1.5 · 2026-10-24 8:45 PM EDT — Godot export scripts + cache-busted Pages packs

---

## Claude

_(Claude: claim work below before coding. Do not take items listed as Active under Cursor.)_

**Claude rules (every prompt):**
- Read this file before planning or implementing anything.
- If the request is already claimed by Cursor, or already listed under **Done recently** in either section, **stop** and tell the user.
- Write the plan under **Active / claimed** before implementing.
- On every update, bump `config/version` in `project.godot` by one patch (e.g. `0.1.4` → `0.1.5`) and log it in **Done recently** as one short line: `vX.Y.Z · YYYY-MM-DD h:mm AM/PM EDT — …`.

### Active / claimed
_(none)_

### Queue
_(none)_

### Done recently
- v0.1.84 · 2026-10-25 3:26 AM EDT — ladder top: no hop; climb up onto an invisible one-way ledge over the hatch and walk off (S/Down climbs back down); `index-0_1_84.pck`
- v0.1.82 · 2026-10-25 3:21 AM EDT — shopkeepers stay behind the counter even with an old editor-saved y (Lantern Keep no longer floats); `index-0_1_82.pck`
- v0.1.79 · 2026-10-25 3:18 AM EDT — Pearl gear icon on the HUD counter, shop gear total + prices, and backpack; `index-0_1_79.pck`
- v0.1.78 · 2026-10-25 3:13 AM EDT — tower prompt E — Ascend; ladder top hops onto the landing; white Pearl gear currency; player plain round head (no ears); `index-0_1_78.pck`
- v0.1.71 · 2026-10-25 2:45 AM EDT — boot shows the real title behind the glass (no white flash); Clockwork crack look; particle steam vents; Wickwright redrawn as the Grandfather Wraith (animated wings, pendulum heart, eye tracking); `index-0_1_71.pck`
- v0.1.56 · 2026-10-25 1:40 AM EDT — shop counters walk-through (keeper behind, player in front); tower exit spawns left of the door via shared `ClockworkTower.VILLAGE_DOOR_X`; tower facade no longer blocks walking; `index-0_1_56.pck`
- v0.1.53 · 2026-10-25 1:28 AM EDT — editor Add tabs (Build/Lights/Props/Decor/People) w/ art previews; steampunk NPCs; themed shops (lamp shop / gear rack workshop / hearth lodge) + low D3 desks (keeper behind) + brass title signs; IM Fell font for title/headings/"E —" plaques; mirrored clockwork tower complex (door left, MAP_W-500); enemy black-box fix; house shadow corners (clip ignores own body); removed intro "boiler-house" hint; `index-0_1_53.pck`
- v0.1.36 · 2026-10-25 12:04 AM EDT — fixed rooms crashing on load: v0.1.34 id renumbering also renamed code names (`map_min_x`→`map_min_24`, `MAP_W`→`MAP_23`…) in LanternVillage/CursedCottage/ZoneCatalog; restored (string ids kept). Village polish: wash light gap closed; house light blockers = walls+roof (no eave/hull wedges); chains on all fixed lamps; dark-oak decor crates; unsquished jars; bench/vent nudged clear of houses; `index-0_1_36.pck`
- v0.1.29 · 2026-10-24 11:30 PM EDT — Brass & Rivets UI theme (`UITheme`) + world art restyle (`WorldArt`): platforms, crates, houses, rest posts, caged lanterns, jars, hatch, lever, windows, bench, valve, vents; `index-0_1_29.pck`
- v0.1.11 · 2026-10-24 9:31 PM EDT — Settings on the title menu too; shared `SettingsPanel` for title + pause
- v0.1.9 · 2026-10-24 9:39 PM EDT — Settings menu (volume, brightness, fullscreen)
- v0.1.6 · 2026-10-24 8:52 PM EDT — E = Interact for levers / switches / buttons
- Claude rules added (no game change)
