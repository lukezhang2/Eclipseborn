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
- v0.1.29 — Brass & Rivets UI theme (`UITheme`) + world art restyle (`WorldArt`): platforms, crates, houses, rest posts, caged lanterns, jars, hatch, lever, windows, bench, valve, vents; `index-0_1_29.pck`
- v0.1.11 — Settings on the title menu too; shared `SettingsPanel` for title + pause
- v0.1.9 — Settings menu (volume, brightness, fullscreen)
- v0.1.6 — E = Interact for levers / switches / buttons
- Claude rules added (no game change)
