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
- Log each ship in **Done recently** as one short line: `vX.Y.Z — …`.

### Active / claimed
_(none)_

### Queue
_(none)_

### Done recently
- v0.1.64 — Editor mob HP (script defaults; Make default for new mobs only); `index-0_1_64.pck`
- v0.1.63 — Editor creature damage (script defaults; Make default for new creatures only) and lever Starts on; `index-0_1_63.pck`
- v0.1.62 — Session-only editor overlays (clear on refresh); brick/backdrop Background palette; `index-0_1_62.pck`
- v0.1.61 — levers flip on attack hit as well as Interact; `index-0_1_61.pck`
- v0.1.60 — player map: undiscovered cover hides lantern light that spilled above it; `index-0_1_60.pck`
- v0.1.59 — Clockwork Tower boss resets on player death (HP/phase/gate/lamps); `index-0_1_59.pck`
- v0.1.58 — Editor zone-link doors/houses/hatches + spawn more palette kinds (pipe/jar/enemy/tower); `index-0_1_58.pck`
- v0.1.57 — Editor: shopkeeper sales default off + per-shop prices; piece color hex/wheel; RMB pan; prop_text + show text pieces; `index-0_1_57.pck`
- v0.1.55 — player map: zone nameplate, plaque labels, reveal only the framed screen; `index-0_1_55.pck`
- v0.1.54 — Backpack no-pause; Equipment + Consumables tabs; player preview + 3 accessory slots; `index-0_1_54.pck`
- v0.1.52 — lantern wash: fix TAU-wrap rim scramble + keep corner grazes (no jagged shards); `index-0_1_52.pck`
- v0.1.51 — Inventory on B (+ HUD Bag button) with shop-style fade; supplies stash/use, abilities + key items; `index-0_1_51.pck`
- v0.1.50 — #0d020f fire-sky universal zone backdrop; `index-0_1_50.pck`
- v0.1.49 — player map: textured side-view of every zone piece, whole zone fitted in the panel; `index-0_1_49.pck`
- v0.1.48 — village purple full-field BG + top-only fire fringe (nudged up); editor Pieces/Background mode; `index-0_1_48.pck`
- v0.1.47 — Clockwork Tower ladders (hold W climb + climb anim), full lobby floor (no hole), story floors + denser brick backdrop; `index-0_1_47.pck`
- v0.1.46 — Clockwork Tower in Level Editor (zone seed, playtest, tall-map camera, lamp/checkpoint overlays); `index-0_1_46.pck`
- v0.1.45 — single yellow light wash; houses above wash (no paint-through); quieter umbras; `index-0_1_45.pck`
- v0.1.44 — tower polish: zone fades, death anim+fade, lobby+pre-boss CPs, bottom-left spawn, jump-reach climb, boss wake/seal, floor lamps+high levers, side rooms, lever flip; keeps village exit left-of-tower; `index-0_1_44.pck`
- v0.1.43 — tower exit spawns left of the village tower (not on the door); `index-0_1_43.pck`
- v0.1.42 — fire band on-screen; light fill/outline linear opacity (max 50%/100%); overlaps add intensity; `index-0_1_42.pck`
- v0.1.41 — light wash matches burns (no fake BG cuts); fan-fill depth; village fire sky only (no brick/city); `index-0_1_41.pck`
- v0.1.40 — Clockwork Tower climb + Wickwright (Match the Hour), defeat cutscene, reward chest → crystal piece (double jump overlay), apex checkpoint, village descent hole; `index-0_1_40.pck`
- v0.1.39 — lantern AoE visible on floor (wash z above floors, brighter fill + bold occluded edge); `index-0_1_39.pck`
- v0.1.38 — realistic cheap shadows: contact-hardening umbra, soft penumbra, wash falloff (no extra rays); `index-0_1_38.pck`
- design — Clockwork Tower combat/boss/ascent plan (`docs/CLOCKWORK_TOWER_COMBAT.md`); no gameplay ship
- v0.1.37 — editor Undo/Redo buttons + Ctrl+Z/Y/Shift+Z; snapshot history for move/resize/rotate/inspector; `index-0_1_37.pck`
- v0.1.35 — ShadowWorld perf: 12Hz throttle, poly cache, physics umbra clip, node pool, no spin dirty; `index-0_1_35.pck`
- v0.1.34 — editor Duplicate + Move axis arrows; piece ids numbered (not lettered); levels updated
- v0.1.33 — shop GUI fade (gear prices + editor stock Inf/N); fast-travel fade polish; no shopkeeper dialogue
- v0.1.32 — sync lantern_village: bench 455, vent 1053, platform A travel 200 at x=1278, hearth lamp r=300, shade heart above platform B, extra steam vent; `index-0_1_32.pck`
- v0.1.31 — clipped realistic shadows (floors/walls/BG); editor light intensity (wash + burn rate); `index-0_1_31.pck`
- v0.1.30 — first death uses last hearth, not continue/logout position; save checkpoint_x/y separately; `index-0_1_30.pck`
- v0.1.29 — Brass & Rivets UI theme and steampunk world art
- v0.1.28 — steel floor walk bank; jump matched; no death land spam; burn loops fixed; realistic hurt (keeps 0.1.27 hit-connect)
- v0.1.27 — enemy hit flash/knockback; hit-connect SFX when player attack lands
- v0.1.26 — shadow crystal: no floating label; tiny red ember in the core
- v0.1.25 — editor moving-platform path/spin inspector when selected + path ghost; village platforms are prop_platform
- v0.1.24 — quieter intro; natural walk/slash/jump/land (−45%); hurt + shade/HP burn loops; `index-0_1_24.pck`
- v0.1.23 — enemies blocked by pushable crates (`pass_through_objects` opt-out); fall anim mild arm raise
- v0.1.22 — fix silent SFX: default AudioBusLayout (SFX/Music), AudioManager ALWAYS + web unlock; `index-0_1_22.pck`
- v0.1.21 — permanent shadow crystal fragments (saved collected_ids); map hint “Tab to close” only
- v0.1.20 — longer cardinal attack hitboxes to match slash sprite tip (N/E/S/W); `index-0_1_20.pck`
- v0.1.19 — persist activated hearths (JSON sidecar + web flush); tall unmissable hearth hitbox; restore lit on load
- v0.1.18 — player hitboxes: flush red attack boxes, inset yellow hurtbox, enemies no longer body-block; `index-0_1_18.pck`
- v0.1.17 — Cursor workflow: always export+push main; sync version past Claude Done history
- v0.1.16 — house fade + interact lock; editor platform path/spin + rotate tool; steam vents (includes village lamp sync)
- v0.1.15 — sync lantern_village: remove door_street_a, lever→street+square only, lamp radii/pos; `index-0_1_15.pck`
- v0.1.14 — Minecraft lever; editor lever→lantern/door links; switchable doors; checkpoint fast travel
- v0.1.13 — geometry house cover (burns + washes), left exit door (Interact/walk), rebuilt village/cottage lights
- v0.1.12 — house light occlusion (layer 128 burns), left Interact exit, rebuilt lantern washes, continuous zone map
- v0.1.11 — Settings on the title menu too
- v0.1.10 — sync lantern_village from editor save (switch/lamp/crate/platform); `index-0_1_10.pck`
- v0.1.8 — corner-aware lantern rays + safer umbra (closes random light gaps); `index-0_1_8.pck`
- v0.1.7 — default `blocks_light` ON for most piece kinds
- v0.1.5 — Godot export scripts + cache-busted Pages packs

---

## Claude

_(Claude: claim work below before coding. Do not take items listed as Active under Cursor.)_

**Claude rules (every prompt):**
- Read this file before planning or implementing anything.
- If the request is already claimed by Cursor, or already listed under **Done recently** in either section, **stop** and tell the user.
- Write the plan under **Active / claimed** before implementing.
- On every update, bump `config/version` in `project.godot` by one patch (e.g. `0.1.4` → `0.1.5`) and log it in **Done recently** as one short line: `vX.Y.Z — …`.

### Active / claimed
_(none)_

### Queue
_(none)_

### Done recently
- v0.1.56 — shop counters walk-through (keeper behind, player in front); tower exit spawns left of the door via shared `ClockworkTower.VILLAGE_DOOR_X`; tower facade no longer blocks walking; `index-0_1_56.pck`
- v0.1.53 — editor Add tabs (Build/Lights/Props/Decor/People) w/ art previews; steampunk NPCs; themed shops (lamp shop / gear rack workshop / hearth lodge) + low D3 desks (keeper behind) + brass title signs; IM Fell font for title/headings/"E —" plaques; mirrored clockwork tower complex (door left, MAP_W-500); enemy black-box fix; house shadow corners (clip ignores own body); removed intro "boiler-house" hint; `index-0_1_53.pck`
- v0.1.36 — fixed rooms crashing on load: v0.1.34 id renumbering also renamed code names (`map_min_x`→`map_min_24`, `MAP_W`→`MAP_23`…) in LanternVillage/CursedCottage/ZoneCatalog; restored (string ids kept). Village polish: wash light gap closed; house light blockers = walls+roof (no eave/hull wedges); chains on all fixed lamps; dark-oak decor crates; unsquished jars; bench/vent nudged clear of houses; `index-0_1_36.pck`
- v0.1.29 — Brass & Rivets UI theme (`UITheme`) + world art restyle (`WorldArt`): platforms, crates, houses, rest posts, caged lanterns, jars, hatch, lever, windows, bench, valve, vents; `index-0_1_29.pck`
- v0.1.11 — Settings on the title menu too; shared `SettingsPanel` for title + pause
- v0.1.9 — Settings menu (volume, brightness, fullscreen)
- v0.1.6 — E = Interact for levers / switches / buttons
- Claude rules added (no game change)
