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

### Active / claimed
_(none)_

### Queue
_(none)_

### Done recently
- v0.1.10 — sync lantern_village from editor save (switch/lamp/crate/platform); `index-0_1_10.pck`
- v0.1.8 — corner-aware lantern rays + safer umbra (closes random light gaps); `index-0_1_8.pck`
- v0.1.7 — default `blocks_light` ON for most piece kinds
- v0.1.5 — Godot export scripts + cache-busted Pages packs
- v0.1.4 — blocks_light + Layer ±
- v0.1.3 — houses light-only layer 128
- v0.1.2 — AI planning board

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
- v0.1.9 — pause menu Settings: volume (master/music/SFX), brightness, fullscreen; `Settings` autoload (not web-exported yet)
- v0.1.6 — E = Interact (`interact` action, `Interactable` base); `LightSwitch` flips on E
- Claude rules added (no game change)
