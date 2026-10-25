# Clockwork Tower — Combat, Boss & Ascent Plan

**Status:** design only (not implemented).  
**Depends on:** shade/light burn (`GameState` / `ShadowWorld`), levers + lamps, steam vents, moving platforms, existing `WanderEnemy` / `BasicEnemy` / `Lamplighter` stub.  
**Village hook:** `ClockworkTower.gd` “F — Ascend” is still a placeholder — this doc is what that door should open.

---

## 1. Combat fantasy

Eclipseborn’s identity is inverted light: **darkness is home; light burns shade then HP**. Tower combat should never be “more HP bars in a corridor.” Every encounter teaches one of these pillars:

| Pillar | Meaning |
|--------|---------|
| **Light as hitbox** | Some enemy attacks only solidify while lamps are on. |
| **Enemy-as-lantern** | Living lights you kill, snuff, or kite. |
| **Vertical pressure** | Drops, swings, and snipes from above (tower fantasy). |
| **Wind-up honesty** | Brass gears always telegraph heavy moves. |

**Core loop for every tower fight:** read the light → move through safe shadow → create or steal a dark pocket → strike → survive the enemy/boss flipping the lights back.

---

## 2. Enemy roster (tower)

### Shade Grub *(exists — `WanderEnemy`)*
- **Role:** Floor filler.  
- **Attack:** Contact nibble; ledge flip.  
- **Tower use:** Dense packs in shafts so darkness feels crowded.  
- **Sprite:** Segmented plum grub, amber eyes, 2-frame crawl *(already shipped)*.

### Rivet Mite *(new)*
- **Role:** Vertical pressure / jump interrupt.  
- **Attack:** Clings under gear platforms; drops when the player passes under; tiny contact hit.  
- **Why:** Teaches look-up. One-slash kill, high annoyance.  
- **Sprite:** Thumbnail brass beetle with oversized rivet-head shell; cotter-pin legs.

### Fuse Beetle *(new)*
- **Role:** Mobile light hazard.  
- **Attack:** Back-mounted cage lantern drains shade in a small radius; short charge when lit; **snuffs on death**.  
- **Why:** Enemy as light source — kill to reclaim darkness, or kite into another foe / lamp socket.  
- **Sprite:** Iron weevil + caged ember; glow bob while walking; smoke puff on death.

### Pendulum Sentinel *(new)*
- **Role:** Lane control.  
- **Attack:** Ceiling hinge; fixed swing arc. Blade **only hurts in the bright half of its swing** (nearby lamp on). In full dark it passes as soft shadow.  
- **Why:** Same language as the boss — light makes danger solid.  
- **Sprite:** Clock-hand body, brass axe tip, violet hub-eye; motion-blur slash frames.

### Steam Wraith *(new)*
- **Role:** Ambush / soft lock.  
- **Attack:** Spawns from `SteamVent`s; lunges; retreats into steam (hurtbox shrinks while hidden).  
- **Why:** Pairs with existing vents; slash the silhouette on exit.  
- **Sprite:** Ash silhouette with gear-teeth ribs; denser outside steam.

### Coil Sniper *(new)*
- **Role:** Climb harassment.  
- **Attack:** Perch fire; brass needles leave **brief light flares** on impact (shade drain, not big HP). Wind-up coil telegraph.  
- **Why:** Forces movement while ascending.  
- **Sprite:** Long copper limb on a stool-gear; visible coil twist before shot.

### Winding Knight *(new, elite)*
- **Role:** Mid-tower gatekeeper.  
- **Attack:** Wind-up → wide slash; brief invuln while gears spin; **vulnerable during rewind click**.  
- **Why:** Mini-boss read; one per gallery landing.  
- **Sprite:** Tall riveted plate, key-shaped helm, glowing wind-key in the chest.  
- **Reward:** Hearth + key gear (opens gallery / teaches dial UI).

---

## 3. Boss — The Wickwright (Keeper of the Tower Dial)

### Fantasy
A **flying** clockwork warden: humanoid brass skeleton, stained-glass **wing-gears**, lantern heart under a hinged glass ribcage, cable-tendrils that yank high light switches. Face = pocket-watch with one violet pupil that slides like a second hand.

### Normal offense (your request)
While the arena stays “alive” with lamps, platforms, and furniture, the Wickwright:
- **Dive claw** (telegraphed hover → plunge)
- **Pendulum sweep** (wide horizontal hand-blade)
- **Fuse-spit** (temporary light puddles on the floor)
- **Switch yank** — flies to the **upper gallery** and flips levers mid-fight, reconfiguring safe/unsafe zones

Player can still slash the body for **armor chips** (tiny damage + hit feedback), but real progress needs the abstract method below.

### Abstract fighting method — “Match the Hour”
1. Chest **dial** shows an hour mark (I–VI).  
2. Arena has floor cage-lamps + high wall levers.  
3. Player sets lighting to **match that hour’s pattern** (taught in the Switch Gallery floor before the fight).  
4. Matching pattern **opens the glass ribcage** — heart is vulnerable for a short window.  
5. Strike the heart while staying in a residual shadow strip (risk: burn if you stand fully lit).  
6. Wrong pattern → boss anger-flips switches and dive-punishes.

This is not “stand in a circle and DPS.” It is **solving a living lock while a predator hunts you.**

### Phases
| Phase | What changes |
|-------|----------------|
| **1 — Dial Reading** | Full gallery + 4 floor lamps. Dive / sweep / switch flips. Heart opens on correct hour. |
| **2 — Stolen Gallery** | Boss smashes 2 levers. Finish patterns with **pushable lamps / Fuse Beetles** in sockets. Adds mites + more fuse-spit. |
| **3 — False Hours** | Most lamps die. Three ghost dials appear; **only the shadow cast on the back wall is true**. Final wounds hit the **wall-shadow of the heart**, not the flying body. Last hit = eclipse: player in last shadow strip, heart fully lit. |

### Feel goals
- First clear = reading + improvisation.  
- Later clears = planned hour sequences (speedrun-friendly).  
- Never a pure bullet-hell chart.

### Reward (TBD at implement time)
Placeholder: story flag `tower_wickwright_down` + ability or key for the next zone (do **not** reuse double-jump — Lamplighter already owns that).

---

## 4. Sprite bible (procedural / nearest-neighbor)

Match village language: iron, brass, plum-ash shade, warm ember. Prefer `ImageTexture` frames like `WanderEnemy`, or `WorldArt`-style polygons for props.

### Wickwright frames
- Idle hover (wing-gears tick)  
- Dive wind-up / dive claw  
- Pendulum sweep (blurred hand)  
- Switch yank (tendril up)  
- Heart exposed (glass open, ember core)  
- Hurt / armor chip / death unwind (gears spill)  
- Phase-3 shadow silhouette variant  

### Shared readable rules
- Heavy attacks: visible coil or key turns.  
- Light-bearing foes: warm core + cage bars (same as village lanterns).  
- Shade foes: soft ovals, amber slit eyes (grub lineage).  
- Hit FX: existing `EnemyHitFX`.  

### Silhouette test
At 32–64px, outline alone must read: mite = rivet under ledge; beetle = dome+lamp; sentinel = long hand; sniper = stick+coil; knight = key helm; Wickwright = winged watch.

---

## 5. Tower ascent (how it looks / plays)

Vertical zone — not one room. Village door → multi-floor climb → apex duel.

### B1 · Gear Lobby
- **Look:** Riveted iron lobby, warm hearth, tall stained glass casting safe moon-stripes.  
- **Obstacles:** Slow gear elevators, one steam vent, crate → pressure plate.  
- **Foes:** Shade Grubs ×3, Rivet Mites ×2.

### F2–F3 · Pendulum Cloister
- **Look:** Long nave of swinging clock-hands; brass pews; candle cages on chains.  
- **Obstacles:** Timed pendulum gaps; platforms that only solidify when lit; optional dark crystal side-path.  
- **Foes:** Pendulum Sentinels, Fuse Beetles.

### F4–F5 · Steam Flue
- **Look:** Vertical chimney of pipes; orange heat haze; grated landings.  
- **Obstacles:** Bursting vents, rising steam that soft-blinds sniper tells, crumbling ledges.  
- **Foes:** Steam Wraiths, Coil Snipers above.

### F6 · Switch Gallery
- **Look:** Open scaffold over the village; wall of labeled levers; practice dial on the floor.  
- **Obstacles:** Light-pattern puzzle gate (**teaches boss language**). Soft fail — no fatal drops.  
- **Foes:** Winding Knight (elite).

### F7 · Dial Arena
- **Look:** Circular brass floor, clock-face mosaic, high switch balcony, stained-glass moon.  
- **Obstacles:** Moving rim gears, lamp sockets, destructible gallery rails (phase 2).  
- **Foes:** The Wickwright.

---

## 6. Suggested build order

1. Tower zone scene + floor shells + replace `ClockworkTower` placeholder ascend.  
2. Rivet Mite + Fuse Beetle (reuse light/hurtbox patterns).  
3. Switch Gallery tutorial (hour patterns).  
4. Wickwright arena stub: lamp patterns + dive AI + heart expose.  
5. Remaining enemies + phases 2–3.  
6. Full sprite pass + audio (tick, unwind, fuse snuff).

---

## 7. Open decisions (ask before coding)

- Exact ability/reward after Wickwright.  
- Single continuous vertical scene vs. discrete floor scenes.  
- Whether Fuse Beetles can be “socketed” as temporary lamps in phase 2.  
- Co-op notes later (shade is per-player) — ignore for now.
