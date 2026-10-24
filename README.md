# Unbound

> *You aren't moving platforms. You're changing what counts as a platform.*

**Game design plan, draft 5.** "Unbound" is a working title. Items marked **(open)** haven't been decided yet. Please add your opinion on them.

## Contents

- [The pitch](#the-pitch)
- [Story](#story)
- [Shadow-walking](#shadow-walking)
- [Movement](#movement)
- [Shade and health](#shade-and-health)
- [Bosses and abilities](#bosses-and-abilities)
- [World](#world)
- [Menus and the map](#menus-and-the-map)
- [Multiplayer](#multiplayer)
- [Sound and music](#sound-and-music)
- [Visuals and animation](#visuals-and-animation)
- [Tech](#tech)
- [Build order](#build-order)
- [Open questions](#open-questions)

---

## The pitch

A 2D **metroidvania** set in a world of **steel and steam**. You play a cursed boy whose body is now a **shadow spirit**: black fire and two white eyes. He can **only exist in shadow**, and light burns him. You don't move platforms. You move **boxes, lamps, gears, and giant machines** to change where the shadows fall, and those shadows become the floors, walls, and bridges you walk on. From the start he can **run** and **attack**. **Double jump** is the reward for beating the first boss.

> **What "metroidvania" means:** a game set in one big connected map instead of separate levels. At first you can't reach many areas. You beat bosses to get new abilities, and those abilities let you go back and open earlier areas you couldn't get into before. The name comes from Metroid and Castlevania.

## Story

- **The boy:** a child whose name isn't chosen yet. Ideas: Wren, Ash, Umbra, Kael. **(open)** What you see on screen is not a normal body. The curse burned him down to a shadow spirit.
- **The curse:** his parents did something bad to a **Witch**, such as stealing her lantern or burning her forest. **(open)** As revenge she cast **The Curse of the Shadow** on their son.
- **What the curse does:** his body is black fire. Two white eyes are the only face he has left. Vulnerable light eats his **shade** first. When that is gone, the fire starts coming apart and his **health** falls. He can only stand on, walk through, and survive inside shadows.
- **Goal:** find the Witch and break the curse so he can be unbound.
- **Story idea:** each boss is a piece of the curse or a servant of the Witch. When you beat one, you take back a piece of yourself, and that's the new ability. **(open)**
- **Possible endings:** break the curse and become human again, or accept the shadow and become something new. **(open)**

## Shadow-walking

```
  (o) LAMP
   |  \  light
   |   \       ___
   |    \     |   | CRATE
   |     \    |___|▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  <- shadow = ground
 ══╧══════════════════        gap       ═══════════
```

The core idea: the crate blocks the lamp's light, and its shadow becomes a bridge across the gap. Slide the lamp, or push the crate, and the bridge moves too.

### Rules

| Thing | What happens |
|---|---|
| **Shadow** | Solid ground. You can stand on it, walk on it, and jump off it. |
| **Vulnerable light** | Hearth, candle, and sunshaft. Standing in it drains the shade bar, then health. See [Shade and health](#shade-and-health). |
| **Safe light** | Moon and crimson. They do not drain shade or health. |
| **Boxes** | Two kinds. **Moveable** boxes slide when the spirit walks into them. **Immoveable** boxes do not. Both block light, so a box that moves takes its shadow with it. |
| **Other objects** | Statues, gears, and machines also block light. The spirit does not shove these the way he shoves a box. Lamps and gears use their own controls, below. |

### How the shadows are made

- Every light source sends out rays, and every object is a shape that blocks them.
- The game works out the shadow shapes every frame and turns them into collision the player can walk on.
- When a lamp moves or a gear turns, the shadows change right away, and so does the ground.

### Ways the player changes the shadows

1. **Move lamps.** Push, carry, or slide lamps on rails. A closer lamp makes a bigger shadow, and the angle of the light sets which way the shadow points.
2. **Rotate gears.** Gears move giant objects like bridges, pillars, windmill blades, and clock hands, and those objects cast moving shadows.
3. **Turn lights on and off.** Switches, shutters, and candles you can blow out.
4. **Special lights.** Not every light burns, and not every shadow is a floor. See [Kinds of light](#kinds-of-light).
5. **Push boxes.** Walk into a moveable box and it slides. Its shadow slides with it. An immoveable box never slides, so the shadow it casts stays put.

### Boxes

The spirit can walk into both kinds of box. Touching one changes his animation, and it changes the box's animation too.

| Box | Spirit animation | Box animation | Shadow |
|---|---|---|---|
| **Moveable** | **Push.** The flame flattens and wraps the near face while he keeps walking into it. | **Slide.** The box eases away from him. It stops at a wall, another immoveable box, or the end of its floor. | Moves with the box on the same frame. A bridge can be dragged across a gap. |
| **Immoveable** | **Bump.** The flame splashes against the face and snaps back. He does not pass through. | **Shake.** One short shudder, then it locks again. It never leaves its spot. | Stays where it is. These shadows are anchors you can trust. |

You can only push from a side you can stand on. If the near face is sitting in burning light, you cannot stand there to shove the box. That is a puzzle, not a special move.

A moving box can open a bridge, steal one, or sweep a safe patch out from under you. Immoveable boxes are how a room keeps one shadow that puzzles are allowed to depend on.

### Kinds of light

Color tells you the type before you step into it. Exact sizes are **(open)**. What each type does to shade and health is below.

| Light | Where it comes from | Does it burn? | What its shadow does |
|---|---|---|---|
| **Hearth** | Lamps and lanterns. Steady warm yellow. | Yes. Drains a full shade bar in about 1.5s, then health. | Hard edge. Stable floor, wall, or bridge. The default puzzle light. |
| **Candle** | Candles and small flames. It flickers. | Yes, in a small radius. Same shade timing as hearth. | The edge wobbles, so a bridge can thin for a moment. Can be snuffed. |
| **Moon** | Moon shafts and pale night sky. Cool blue-white. | No. Shade refills here. | Soft, shorter than a hearth shadow, and still solid. Safe travel. |
| **Crimson** | Red glass, gems, or a stained window. | No. Shade refills here. | Does not make a floor. It makes a **solid dark wall** you cannot pass. |
| **Sunshaft** | A white-hot column, rare. | Yes, and faster. A full shade bar lasts about 0.75s, then health falls faster than in hearth light. | Long and sharp. A long bridge that is dangerous to build. |

When a box moves between two lights, it can cast both kinds at once: a hearth floor one way and a crimson wall the other. The shadow updates as soon as the box moves.

### Example puzzle

There's a gap you can't jump across. A lamp sits on a rail below it, and a broken bridge hangs above. Slide the lamp left and the bridge's shadow stretches across the gap. But now the lamp lights up the spot where you're standing, so you have to cross fast.

**Difficulty: medium.** Puzzles have 2–4 steps. Hints come from how the room looks, not from text. Checkpoints are close together so failing doesn't feel bad.

## Movement

Walk, run, and a single jump are his from the first room. Double jump is not.

| Move | What it looks like | What it's for | When he has it |
|---|---|---|---|
| **Walk** | Short steps in the base of the flame. The eyes stay level. | Careful pushes and narrow shadow bridges. | Start |
| **Run** | The flame stretches backward, the eyes lead, and a few embers trail. | Crossing a shadow before it moves, and general travel. | Start |
| **Jump** | The flame compresses, then bursts upward. | One box-height, plus a little. | Start |
| **Double jump** | A second burst in the air. The flame flares brighter and the eyes lift. | Gaps and ledges a single jump cannot clear. It should not skip a whole room. | After **The Lamplighter**, the first boss |

How tall the jumps are, and whether run is a held button or full tilt on the stick, is **(open)**. The feel we want: run is fast enough that a sliding shadow is a choice, and the second jump is readable as a flare, not a second copy of the first jump. Before the Lamplighter, a second jump press in the air does nothing.

## Shade and health

Two separate meters. Shade is the time he can spend in vulnerable light. Health is his life, and it is a number.

| Meter | How it is shown | Start of the game | What spends it |
|---|---|---|---|
| **Shade** | A bar, not a number. It looks like a strip of the same black fire. | Full. A full bar lasts about **1.5 seconds** in hearth or candle light. | Standing in vulnerable light only. |
| **Health** | A number, current and maximum, like **100 / 100**. | **100** current, **100** maximum. | Vulnerable light, but only after shade is empty. Enemy hits also come off health, and they skip the shade bar. |

### Standing in the light

1. The moment any part of him is in hearth, candle, or sunshaft light, the shade bar starts dropping.
2. In hearth or candle light, a full bar reaches empty in about **1.5 seconds**. Sunshaft does it in about **0.75 seconds**. Two lights at once use whichever is faster. They do not stack.
3. While shade is left, health does not move. He can still run, jump, and push.
4. When the bar hits empty, health starts falling fast. In hearth or candle light that is about **100 health per second**, so a starting life of 100 is about one more second. Sunshaft is faster, about **200 per second**. Exact rates are **(open)**, but staying in the light after the bar breaks has to feel like "leave now."
5. At **0** health the flame comes apart and he respawns at the last checkpoint. Current health comes back to his maximum, and the shade bar comes back full.

Shade refills only when he is out of vulnerable light: in shadow, moonlight, or crimson light. Empty to full takes about **1 second**. The exact refill speed is **(open)**. Health does not come back on its own in the dark. A checkpoint sets current health back to maximum and refills shade. Healing with Umbra restores a chunk of current health and does not raise the maximum.

The shade bar does not get longer during the game. Only health does.

### Health can grow

The maximum starts at 100 and goes up as the game goes on. Current health never sits above the maximum.

- Hidden pickups, working name **shade hearts**, each raise the maximum by **25**. A few of them are in the world. The step size and how many exist are **(open)**.
- Some bosses can raise the maximum too. **(open)** which ones.
- The number on screen shows the new maximum, for example **100 / 125** right after the first heart, once current health is healed or restored.
- Later areas are allowed to hit harder because the number can be higher than 100.

### What it looks like

- **Shade draining:** the bar thins, the flame thins with it, and the eyes squint. A quiet hiss. He is not dying yet.
- **Health draining:** the light-burn animation. Edges lift off as ash, the number ticks down fast, and the sound is the crackle.
- **Death:** the whole flame comes apart, then he is back at the checkpoint.

## Bosses and abilities

| Boss | Ability | Unlocks |
|---|---|---|
| **The Lamplighter** (first boss) | **Double Jump:** a second jump in the air | Ledges and gaps one jump cannot clear |
| **The Clockwork Warden** | **Gear Sense:** turn gears without touching them, and see gears hidden in walls | Machine areas |
| **The Hollow Moth** | **Shade Dash:** dash through a short strip of vulnerable light without the shade bar dropping. If the dash ends still in that light, shade starts draining as usual | Rooms with thin light beams |
| **The Mirror Queen** | **Reflect:** place a mirror shard that bends light | Light-aiming puzzles |
| **The Eclipse Beast** | **Shadow Grip:** pull or push lamps from far away | Rooms where lamps are out of reach |
| **The Candle Choir** | **Snuff:** put out small lights | The bright cathedral |
| **The Witch** (final boss) | Break the curse | Ending |

The names, abilities, and order are all up for change. **(open)**

He can still push a lamp by walking into it from the start. **Shadow Grip** is the later version of that, from far away. It moved off the first boss so the Lamplighter could teach double jump. Whether the Eclipse Beast is the right boss for Shadow Grip is **(open)**.

### Combat

Press **F** to attack. The lash goes in the direction he is facing. Facing is left or right, taken from the last way he moved, and standing still keeps it. The attack is a whip of the flame itself, not a weapon he holds. Healing costs a resource called Umbra.

The swing has three beats: a short startup, the active frames while the lash is out, and a short recovery before another F will swing again. He does not turn around during the active frames.

Landing on an enemy from above while falling bounces him up. That bounce is separate from the F lash.

**Bosses use light as a weapon.** Their light attacks erase your ground, so the arena changes during the fight. Some bosses are made of shadow, and you beat them by shining light on them.

### Hitboxes

Fights use two kinds of box. These are not the crates in the rooms. Crates, walls, and shadow floors stay ordinary collision. The lash does not push a box.

| Kind | What it is | When it exists |
|---|---|---|
| **Hurtbox** | The part of a body that can take a hit. The spirit has one. Every enemy has one. | The whole time that body can be damaged. |
| **Hitbox** | The part of an attack that deals damage. | Only during that attack's active frames. |

Every attack, his or an enemy's, is written down the same way:

- Who owns it
- Which direction it faces
- How far in front of the owner it sits, and how big it is
- How many frames of startup, active, and recovery it has
- How much damage it deals
- Which hurtboxes it is allowed to touch

On F, the spirit's hitbox appears in front of his facing direction for the active frames only. If it overlaps an enemy hurtbox, that enemy takes the damage **once** for that swing. The same swing cannot hit them again. The next press of F is a new swing.

Enemy attacks use the same list: their own offset, size, frames, and damage. If an enemy hitbox overlaps the spirit's hurtbox, he loses health. Enemy hits still skip the shade bar.

The numbers for his lash and for each enemy are **(open)**. The framework is the part to build first, before the numbers are tuned.

## World

One connected world of **steel and steam**. The ground is riveted plate, iron beams, and brick. Pipes run along the walls. Brass valves, coal soot, rust, and vents of white steam are in every district. Lamps and furnace glow are the light. Open sky is rare, and when it shows through a broken roof it is moonlight, not a sunny field.

Each area is a district of that same machine, with its own music. They are not separate biomes.

A **room** is one camera space, the same kind of room Hollow Knight loads one at a time. Hollow Knight's areas, counted as the rooms on its map, are about this big: a small pocket is 6–16 rooms (Howling Cliffs 6, Fog Canyon 13, Royal Waterways 16), a mid area is about 26–31 (Crystal Peak 26, Fungal Wastes 30, Greenpath 31), and a hub is 37–40 (City of Tears 37, Forgotten Crossroads 40). The whole of Hallownest on that map is about **307** rooms. Shops and other interiors behind doors are not in those counts.

Production time for this game is short, so each of our zones is about **half** the room count of the Hollow Knight area it is closest to. Seven zones, not sixteen. The whole map is about **90 rooms**.

| Area | Rooms | Hollow Knight stand-in | Description |
|---|---|---|---|
| **The Cursed Cottage** | **4** | Howling Cliffs, 6 rooms | Where you start. A boiler-house home: pipes in the walls, a cold furnace, the tutorial. |
| **Lantern Village** | **20** | Forgotten Crossroads, 40 rooms | An abandoned town. Iron lamp posts, steam leaking from street grates. The early hub. |
| **The Clockworks** | **15** | Fungal Wastes, 30 rooms | Giant gears, pistons, and moving machines. |
| **Moth Hollow** | **16** | Greenpath, 31 rooms | A collapsed boiler tunnel. Moths and wet fungus on the iron. |
| **Glass Spire** | **13** | Crystal Peak, 26 rooms | A brass-and-glass tower of mirrors, gauges, and light beams. |
| **Cathedral of Candles** | **13** | Kingdom's Edge, 26 rooms | A furnace nave. Gas-fed flames. Very bright and very dangerous. |
| **The Witch's Wood** | **9** | Queen's Gardens, 18 rooms | The final area. Trees grown through a dead foundry, roots wrapped around gears. |

- Shortcuts open up as you explore. There are optional secret rooms and side bosses.
- You save at checkpoints. One idea is that save points are dark spots, like an unlit fireplace. **(open)**
- The zone map fills in as you explore. See [Menus and the map](#menus-and-the-map).

## Menus and the map

### Title menu

The game opens on a menu with two choices.

| Choice | What it does |
|---|---|
| **Play** | Opens the save slots. Choosing a slot starts that game, or continues it. |
| **Controls** | Lists every action and the key bound to it. Choose an action, press a new key, and that key replaces the old one. |

Two actions cannot share a key. A reset puts the defaults back. Every action below can be rebound, including attack, the map, and the menu.

| Action | Default key |
|---|---|
| Move left / right | A / D, or the arrow keys |
| Run | Shift |
| Jump | Space |
| Attack | F |
| Zone map | Tab |
| Menu | Esc |

During a game, **Esc** opens this same menu. In **single player** the game pauses. The spirit, enemies, lights, boxes, shade, and health all stop until the menu closes. In **co-op** Esc opens the menu for that player only, and the world does not pause.

### Zone map

**Tab** opens a map of the zone he is standing in, drawn to fit one screen. It is the whole of that zone, not the whole world. Tab again closes it.

- A room is drawn after he enters it. Rooms he has never entered stay blank.
- Each living player gets an icon on the room they are in. The icons look different, so co-op players can tell who is who. A partner's icon shows even in a room this player has not mapped yet, so nobody gets lost.
- The map does not move lamps or fight. It only shows where people are.
- In single player, Tab pauses the game the same way Esc does, so shade does not drain while the map is up. In co-op, Tab does not pause the world.

## Multiplayer

**Co-op for 2–4 players.** We still need to decide between online, same computer, or both. **(open)**

### How co-op works with shadows

- Every player is a cursed shadow-child. Player 1 is the boy, and the others are other cursed kids or "shadow siblings." **(open)**
- **Co-op puzzles:** one player holds a lamp still, turns a gear, or pushes a box while another walks on the shadow it makes.
- **Players could cast shadows too.** A player standing in front of a light would make a small shadow a teammate can stand on. It's fun, but it makes puzzles harder to design. **(open)**
- A player whose health hits 0 comes back as a small wisp and can be revived at a checkpoint or by a teammate.
- In single player, co-op puzzles change so one person can solve them, for example with a lever that locks a gear in place.
- Esc and Tab pause only in single player. In co-op the world keeps moving while one player has the menu or the zone map open.

### Save files

Requirement: *save files must start with the other players.*

- When you make a new save file, you choose the group, and **everyone starts the adventure together** from the beginning.
- The save belongs to that group. Progress, abilities, and the map are shared.
- To keep playing, the same group joins again. Should the host be allowed to continue alone when friends aren't online? We recommend yes. **(open)**
- Each save slot shows who's in it, for example "Slot 1: Anthony, Sam, Jordan."

## Sound and music

### Sound effects

| Action | Sound |
|---|---|
| Blocking or parrying | Heavy steel clang with a little echo |
| Walking on shadow | Soft, whispery footsteps |
| Turning gears | Deep grinding metal and ratchet clicks |
| Moving lamps | Glass rattling and squeaky metal |
| Pushing a moveable box | A wooden scrape, or a heavier grind if the box is stone |
| Bumping an immoveable box | A dull thud and a short flame puff |
| Double jump | A brighter whoosh than the first jump |
| Shade draining | A thin hiss that gets sharper as the bar empties |
| Shade refilling | A soft inhale, like the flame pulling itself together |
| Health burning in light | Crackling and sizzling, faster than the shade hiss |
| Lights on or off | A soft ignition whoosh, or a candle puff |
| Shadow ground appearing | A low hum or an ink splash |
| Health hitting 0 | Ash blowing away as the flame comes apart |
| Attack swing | A short flame whip |
| Hitting enemies | Crunchy, punchy hits |
| Boss getting hurt | A big low hit and a short freeze-frame |

### Music

- **Background music:** soft, sad, and a little mysterious, with piano, cello, and music box. Each area gets its own song.
- **Boss music:** louder and more intense, with drums, choir, and strings. Each boss gets its own theme.
- **Music that changes:** extra instruments come in when a boss reaches its second phase.
- **Sources:** start with free libraries like [freesound.org](https://freesound.org) and [Kenney.nl](https://kenney.nl), and replace them with custom sounds later. We haven't decided whether to make our own music. **(open)**

## Visuals and animation

- **Style:** 2D, dark, and high contrast. Iron, rust, brass, coal, and steam, with warm lamplight against deep black. Hand-drawn or pixel art is **(open)**. Pixel art would be faster to make.
- **The spirit:** he is not a little knight. No mask, no horned hood, no cloak shaped like a person, no sword as the silhouette. The whole body is **black fire**: a ragged flame of shadow, taller when he is still, streaming back when he runs. **Two white eyes** are the only face. They sit in the flame and move on their own, so you can tell where he is looking. The flame's edge has a faint ember-red, not a costume.
- **Idle:** the flame breathes in and out. The eyes drift, then settle. Every few seconds one taller flicker rises and falls.
- **Shadows on the ground** should look a bit magical, like dark ink with a faint purple edge, so players can easily tell where they can walk. They are separate from the spirit's body. His body is fire. The floor-shadows are ink.
- **Light and death:** touching vulnerable light only thins the flame while shade is left. The ash animation starts when the shade bar is empty and health is falling. At 0 health the whole shape comes apart. Shadow enemies use that same coming-apart effect when they die.

### Spirit animations

| Animation | What you see |
|---|---|
| **Idle** | Breathing flame, drifting eyes, a rare tall flicker. |
| **Walk** | Low steps. Eyes level. The flame barely trails. |
| **Run** | Body stretched back, eyes leading, embers behind. |
| **Jump** | Compress, then a burst upward. |
| **Double jump** | A second, brighter burst. Eyes flare. Plays only after the Lamplighter is beaten. |
| **Attack** | The flame lashes out in the facing direction, then snaps back. Plays on F. |
| **Fall** | Flame points up. Eyes tip down. |
| **Push** | Flame spreads across a moveable box. Plays the whole time he is walking into it. |
| **Bump** | Flame splashes on an immoveable box and snaps back into shape. |
| **Shade drain** | Flame thins and eyes squint while the bar drops. He is still whole. |
| **Light burn** | Plays only after the shade bar is empty. Edges become ash and the health number falls. At 0, the flame comes apart. |
| **Also needed** | Block, wall-slide, hurt, death, and getting an ability. |

Box animations are only **idle**, **slide**, and **shake**, described under [Boxes](#boxes). A sliding box has to read clearly, because the shadow under it is moving too.

## Tech

| Choice | Pick | Why |
|---|---|---|
| Engine | **Godot 4** | It's free, great at 2D, and has 2D lights, shadows, and multiplayer built in. It uses an easy language called GDScript. |
| Alternative | Unity | Also works, but it's heavier and its licensing has been messy. |
| Art tools | Aseprite or Krita | Cheap or free 2D art tools |
| Multiplayer | Godot networking, Steam later | Use direct connections for testing, then Steam for real online play. |
| Version control | Git + GitHub | So we both work on the same code and don't lose anything. Each finished change is committed and pushed. The codespace disk is not the only copy. |

**Hardest technical part:** shadows that act as real ground have to come out the same on every player's computer during online play. The plan is for the host to decide where all the lights and objects are and send that to everyone. Each computer then builds the shadow ground from it.

## Build order

### Phase 0: Prototype

1. Set up the Godot project.
2. Make one room with one hearth lamp and one moveable box, where the box's shadow is walkable.
3. Add walk, run, and a single jump that feel good. Double jump stays locked until the first boss.
4. Add the shade bar and the health number. One hearth lamp drains a full shade bar in about 1.5 seconds, then health at about 100 per second from a starting value of 100. At 0, respawn. Shade refills in shadow in about 1 second. Health does not.
5. Add one immoveable box beside it. Walking into the moveable box plays push and drags its shadow. Walking into the immoveable box plays bump, and that shadow stays.
6. Let the player push the lamp so the shadow ground updates.
7. **Checkpoint: is walking on shadows fun, and does pushing a box feel better than pushing a lamp?** Play it and decide before going further.

### Phase 1: Core systems

1. Add gears and giant moving objects.
2. Add switches and lights that turn on and off.
3. Add the other light types: candle, moon, crimson, and sunshaft. One new type at a time, after hearth already works.
4. Add the F attack and the hitbox framework: one player hurtbox, one player hitbox in the facing direction, and one enemy with its own hurtbox and hitbox. A swing hits once.
5. Add the title menu with Play and Controls, rebinding, and Esc pausing a single-player game.
6. Add checkpoints and saving.

### Phase 2: First real slice

1. Build the Cursed Cottage, all 4 rooms, and the first stretch of Lantern Village. The full village is 20 rooms, so this slice does not have to finish it.
2. Add the Lamplighter boss. Beating him unlocks double jump.
3. Add the first sounds and music.
4. Add the Tab map for the current zone, with a player icon. Build the cottage and village rooms in steel and steam.
5. Add one shade heart that raises maximum health from 100 to 125.

### Phase 3: Multiplayer

1. Get 2-player co-op working over the network.
2. Add group save files.
3. Add co-op puzzles.

### Phase 4: Expand

1. Build the remaining areas, bosses, and abilities, one area at a time.
2. Add story scenes, the Witch, and the endings.
3. Polish, balance, and playtest with friends.

> **Scope:** Hollow Knight is about 307 mapped rooms and took a team of three about three years. This game is seven zones at about half those sizes, about 90 rooms in all. A full metroidvania with online multiplayer is still a big project at that size. So we build the small Phase 0 prototype first to find out if the idea is fun, and we add multiplayer in Phase 3, once the core game works. The code will be written so multiplayer is easy to add later.

## Open questions

1. What's the game called, and what's the boy's name?
2. Is Godot 4 OK as the engine?
3. Should multiplayer be online, same computer, or both? How many players?
4. Should the host be able to continue a group save alone?
5. Hand-drawn or pixel art for the black-fire spirit? Pixel art is faster.
6. Are we making our own art and music, or starting with free assets?
7. Should players cast shadows teammates can stand on?
8. Should we start with the Phase 0 prototype?
9. How high should the jump and double jump go, and is run a held button?
10. Is the Eclipse Beast the right boss for **Shadow Grip**, now that the Lamplighter unlocks double jump?
11. Should moonlight stay completely safe, and should crimson light stay safe to stand in?
12. Is about 1 second the right shade refill, and is about 100 health per second the right burn once the bar is empty?
13. Should each shade heart add 25 max health, and which bosses raise it too?
