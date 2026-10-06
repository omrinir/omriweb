# THEY LEARN — Developer Guide

A Godot 4.3 (GL Compatibility) 2D run & gun. All art is drawn procedurally in code (`_draw()`),
except the hero sprite sheet (`sprites/hero.png`) and the dog sprite (`sprites/dog.png`).
All sound effects are synthesized in code (`sfx.gd`).

## Folder map

| Folder / file | What lives there |
|---|---|
| `main.gd` | Builds a level: road, obstacles, zombies, survivors, pickups, exit + boss, camera, HUD. Stages 1-4 are built here directly; stages 5-9 delegate to `levels/stage_N.gd`. |
| `player.gd` | The hero: movement, jump, roll, slide, ladders, drop-through floors, aiming, firing, reload. |
| `zombie.gd` | Every zombie. Kinds 0-19 are implemented inside it; kinds 20+ are modules in `enemies/types/`. |
| `ai/` | **Zombie intelligence**: `player_memory.gd` (autoload `PlayerMemory`), `intelligence_profile.gd`, `zombie_brain.gd`, `squad_director.gd`. |
| `enemies/` | `zombie_type.gd` (base class for new zombie types), `zombie_registry.gd` (kind → file), `types/*.gd`, `enemy_sounds.gd`. |
| `weapons/` | `weapon_db.gd` (every weapon's stats), `weapon_sounds.gd`, `molotov.gd`. |
| `levels/` | `stage_base.gd` (base class), `stage_registry.gd` (level → file), `stage_5.gd` … `stage_10.gd` (stage 10 = NORTHEAST region, level 1: Salt Flats). |
| `environment/` | `platform.gd` (one-way floors), `ladder.gd`, `hazard.gd` (base for traps), `fire_zone.gd`, `acid_pool.gd`, plus stage-specific machines. |
| `effects/` | `parallax_backdrop.gd` (layered background), `backdrop_kit.gd` (skyline, smoke, clouds, helicopters, lightning…), `ambient.gd` (ash, embers, steam vents, sparks, drips, flicker lights, screens, falling debris), `signal_fx.gd`. |

## Where to change…

* **Difficulty / zombie intelligence per stage** → `ai/intelligence_profile.gd` (`STAGES` table).
  Fairness limits (minimum reaction time, maximum simultaneous attackers) are at the bottom.
* **How zombies use what they learned about you** → `ai/zombie_brain.gd` (`_adapt_attack`, `_heights`, `_decide`).
* **What zombies remember about you** → `ai/player_memory.gd` (`LEARN_RATE`, `DECAY_ON_LEVEL`).
* **Attack slots, communication, commands, coordinated waves** → `ai/squad_director.gd`.
* **Weapons** → `weapons/weapon_db.gd`. Add a dictionary to `WEAPONS`; the id is its index.
  Wheel/pickup icon: `weapon_wheel.gd → draw_weapon()`. In-hand look: `"style"` + `player.gd → _draw_rifle()`.
* **Which zombies / weapons / boss appear in a stage** → `levels/stage_N.gd` (`zombie_weights`, `weapon_offers`, `boss_kind`).

## Adding a new zombie type

1. Create `enemies/types/my_zombie.gd`:
   ```gdscript
   extends "res://enemies/zombie_type.gd"
   const SOUNDS := { "my_growl": [...] }      # optional, auto-registered
   func stats() -> Dictionary: return {"name": "MY ZOMBIE", "hp": 30, ...}
   func draw() -> bool: begin_draw(); ...; end_draw(); return true
   ```
2. Register it in `enemies/zombie_registry.gd` (new number + path).
3. Add it to a stage's `zombie_weights()`.

Hooks you can override: `stats, brain_overrides, use_brain_movement, setup, physics, logic,
can_bite, on_bite, on_damage, damage_mult, on_death, on_release, draw`.

## The intelligence system in one paragraph

Each zombie owns a **ZombieBrain**. It sees the player only through line of sight and remembers
the last-seen spot for `memory_duration` seconds (no wall-hacks). Every `reaction_time` it picks a
role: APPROACH, ATTACK, FLANK, HOLD, RETREAT, AMBUSH, WAIT, COVER or CONFUSED. The **SquadDirector**
hands out only 2–3 *attack slots*; zombies without one flank, wait, hide or prepare. When the
player is vulnerable (reloading, grabbed, just hit) one extra slot opens. Holders sometimes launch a
coordinated wave from both sides. From stage 5 zombies **call each other** (ring + click sound).
Leaders boost nearby zombies; killing a leader confuses them. **PlayerMemory** records preferred
weapon category, distance, retreat direction, crouching, camping, high ground, reloads and
explosives; from stage 8 the brains adapt to it gradually (shotgun → keep distance, sniper →
zig-zag, SMG → rush, grenades → spread out, high ground → climb, retreat side → flank the other side).

## Testing from the command line

Test scripts (`t_*.gd`, extending SceneTree) are NOT part of the game folder — the editor would report
parse errors for them. Copy one into the project root temporarily, run it, then delete it:
```
godot --headless --path . -s res://t_parse.gd          # compiles every script, prints FAIL lines
```

## Controls

A/D move (double-tap = run) · W jump / climb ladder · S crouch (S+W = drop through a floor) · LMB fire ·
R reload · Q weapon wheel · 1-5 weapons · G drop weapon · E grenade · SHIFT roll · F grapple ·
RMB sniper scope · ESC pause.

## Abilities, upgrades and the 70-level economy

* **Abilities** → `abilities/ability_db.gd` (list) + `abilities/types/<id>.gd` (behavior) + `abilities/ability_runner.gd`
  (5 equipped slots, C = use, 6-0 = select). Add a dictionary + a script and it appears in the wheel, HUD and shop.
* **Shop / upgrades** → `progression/upgrade_db.gd` (tracks, prices, income) and `ui/upgrade_shop.gd` (screen).
  Every weapon gets DAMAGE / FIRE RATE / MAGAZINE / RELOAD (or CAPACITY), every ability POWER / COOLDOWN, plus PERKS.
  Price = base × (1 + unlock_level / 12) × 1.55^level; income per stage grows with the stage number, so the
  economy stays even from stage 1 to 70. Give new weapons an `"unlock_level"` in `weapon_db.gd`.

## Stage 10 - Salt Flats (NORTHEAST region, level 1)

* `levels/stage_10.gd`, art in `effects/s10_decor.gd`, shared objects in `environment/s10_hazards.gd`.
* New zombies (kinds 41-43): `blood_gate.gd` (shot from far -> its blood lands near you and becomes a portal it jumps through),
  `kraken.gd` (squid tentacles: low SWEEP = jump, overhead SLAM = step aside; also the stage boss "THE DROWNED FISHERMAN"),
  `live_wire.gd` (charges and shoots electric bolts from its mouth; leashed by a live cable to a power pole - the cable on the floor shocks you).

## Ragdoll corpses

`effects/ragdoll.gd`: humanoid zombies die as a soft body (11 joints, Verlet physics, one ray per joint).
How it falls depends on the hit (headshot snaps the head back, explosions launch, weak hits sometimes crumple in place).
It simulates only until it settles (~1-2 s, max 4 s), then freezes. Animals, the hand, the mech, jetpack, bloater and gunner
keep their old death. A zombie type can opt out with `"ragdoll": false` in `stats()`.

## JETPACK ability

`abilities/types/jetpack.gd` (unlocks at stage 2). C = take off, hold W/SPACE = thrust, release = slow hover-fall, C again = land/turn off.
Fuel burns only in the air. Flight time by POWER level: `FUEL = [20, 24, 27, 29, 31, 32]` seconds (max 32).
POWER upgrades use `power_base` 110 in `ability_db.gd` (130, 200, 310, 480, 740 scrap = 1860 total).
`"cd_after": true` = the 40 s cooldown starts when the flight ends (shorter if you land early with fuel left).

## Stage 11 - Sun-Bleached Town (NORTHEAST region, level 2)

* `levels/stage_11.gd`, art + night lighting in `effects/s11_decor.gd` (NightOverlay: dark except near working lamps and bonfires;
  shooting a lamp bulb makes that area dark and sets `Game.player_dark`, so zombies see you less).
* Second floor only in parts of the level (`ROOFS`). **Any stage:** double-tap S on a one-way floor = drop to the floor below (`player.gd`, `DOUBLE_TAP`).
* New zombies: `devourer.gd` (walks to nearby zombies and absorbs them: bigger, more HP, more damage, up to 3; shoot it while it eats to make it spit the zombie out;
  boss "THE GLUTTON"), `splitjaw.gd` (lies like a corpse as bait, head splits open showing teeth, leaps at you). SCOUT is back (calls the others).

## Stage 12 - The Lighthouse (NORTHEAST region, level 3)

* `levels/stage_12.gd`, art in `effects/s12_decor.gd` (blood-red dusk, sea fog bands, lighthouse beam from the lamp),
  hazards in `environment/s12_hazards.gd` (quicksand slows you and drains health if you stay; thrown hands).
* Second floor only on two buried-house roofs (`BURIED`).
* New zombies: `mimic.gd` (identical to the survivor girl, cries HELP, morphs halfway to you; doesn't groan - `can_groan()` hook in zombie_type.gd),
  `ironwing.gd` (robotic wings: flies, telegraphed dives, a wing breaks at half HP; boss "THE IRON ANGEL"),
  `spare_parts.gd` (throws its own hand, sits and throws both legs - real severed legs other zombies can rethrow - then crawls and grabs).

## Stage 13 - Dunes of Bone (NORTHEAST region, level 4)

* `levels/stage_13.gd`. Real walkable dunes: `environment/s13_dunes.gd` -> `Dune` (StaticBody2D + CollisionPolygon2D, raised-cosine
  shape, max ~32 degrees, blocks bullets and the sand stream; group `no_outline` = draws its own outline). `stage.surface_y(x)` = ground height.
  Obstacles only from this stage's own generators (`ribcage`, `rock`) so nothing spawns inside a dune.
* `SandStorm`: every 32-46 s an 8 s storm (screen haze, sand streaks, zombies see you less via `Game.player_dark`).
* New zombies: `graveborn.gd` (travels under the sand as a moving mound, cracks + rumble warning, erupts under you; boss "THE OSSUARY"),
  `sandblaster.gd` (sandblasting machine: rev warning, sand stream that tracks you slowly, pushes and hurts; tank on its back is the weak spot -
  3 hits from behind burst it). MIMIC appears here too.
* `DuneSinker` (in `s13_dunes.gd`): characters standing on a dune are drawn a few px into the sand (`SINK`) instead of floating on the
  slope corner. Visual only (moves the canvas item after everyone moved); physics and hit boxes are unchanged.
* GRAVEBORN erupts right away (`JUMP_WARN`) when you jump over its mound, so it can't simply be skipped.
* SANDBLASTER stream = real `CPUParticles2D` (`_jet`) whose speed matches the stream length, plus a dust cloud (`_dust`) where it hits a wall/dune.

## Stomp rule (all stages)

`player.gd -> _try_stomp()`: landing on a zombie's head = 20 damage, but only ONCE per zombie (`meta "stomped"`).
Landing on the same zombie again hurts YOU (1 heart) and bounces you off.
SHIELD ELITE (`shield_elite.gd`) now rests its heavy shield every `REST_EVERY` s for `REST_T` s (state `REST`) - shoot it from the front then.

## Real zombie voices

`sounds/zombies/*.mp3` - clips cut from recordings (fades, EQ, normalized quiet). `sfx.gd -> SAMPLES` maps a sound name
(zscream, zhit, zdeath, groan, roar, scream, fscream, fwail) to clips; if a clip exists it replaces the synthesized sound.
Loudness: `SAMPLE_GAIN` (now ~4 dB below the synthesized sounds). Each zombie has its own voice pitch (`zombie.gd -> _vp`, bigger = deeper).
Zombie types can choose a death sound (`zombie_type.gd -> death_sound()`, MIMIC = female wail).

## Stage 14 - Fishermen's Grave (NORTHEAST region, level 5)

* `levels/stage_14.gd`, art in `effects/s14_decor.gd`: stormy night harbor (heavy rain `StormRain`, lightning that lights everything
  outside for a moment + thunder), black sea, burning trawler, cannery skyline, fishermen's cemetery (crosses with nets, anchors, upturned boats).
* `StormOverlay` = darkness shader with lights (harbor lamps, `Bulb`, `FireBarrel` in group `s14_lights`) and `DarkZone`s:
  inside the two cannery halls (`HALLS`) it is almost black, only flickering bulbs (every third one is dead). Halls have a steel catwalk + ladders.
  Wooden piers (`PIERS`) = second floor in parts of the level.
* New zombies: `crumbler.gd` (every bullet tears off the part nearest the hit - scalp, jaw, ear, hand, arms, chest, belly, legs;
  parts fly as real `Chunk`s; one leg = hops, no legs = crawls; falls apart on death),
  `retcher.gd` (huge cook: HEAVE warning -> PUKE stream of real bile blobs + burning puddles (`acid_pool.gd` with `tint`);
  3 shots in the swollen belly while heaving = it chokes; boss "THE BILGE KING"). SCOUT and IRONWING return.
* `zombie.gd -> lie_down()` = spawn a zombie lying like a corpse (wakes when you come close). Type zombies now draw lying/rising too (`begin_draw`).

## Player monologue (all levels)

`ui/monologue.gd` (added to every level by `main.gd`): the hero talks to himself - comic speech bubble (font `fonts/Bangers-Regular.ttf`, OFL)
on its own CanvasLayer (above the darkness) + voice clip `sounds/voice/vNN.mp3` (v01..v100): deep raspy voice with a light whisper
(Kokoro TTS am_onyx, LPC whisper mixed 30%, close-mic EQ, no time-stretch).
* 100 lines in `LINES`; `EVENTS` maps an event name to its possible lines + priority (1 combat - only sometimes, 2 normal,
  3 important, 4 must react - e.g. shooting the survivor girl). `SIGHTS` = first time a zombie type is seen in the run.
* Only 1-4 lines per level (`LINES_PER_LEVEL`, random each level), `MIN_BETWEEN` 40 s apart, the last one is saved for an important moment.
  Lines already heard in the run are avoided (`heard`).
* Events: `Game.story.emit(name, info)` - emitted from zombie.gd, player.gd, survivor.gd, exit.gd, bullet.gd (lamp), acid.gd,
  ai/zombie_brain.gd, ai/squad_director.gd, abilities/types/jetpack.gd, many enemies/types/*.gd, hazards
  (`hazard.gd -> story_kind`: fire / acid / shock / puke) and stages (thunder, sandstorm, quicksand).
* Add a line: entry in `LINES` + `sounds/voice/vNN.mp3` + its number in an `EVENTS` entry (or a new event + `Game.story.emit`).

## Flashlight ability

`abilities/types/flashlight.gd` (ability_db id "flashlight", icon "torch", unlock stage 1, `cd_after`): C = on, C again = off.
Natural light, not a cone: three overlapping soft round lights stretched toward the aim (`Beam.lights()`), plus an additive warm glow
(`Beam._draw`, radial GradientTexture2D). The hand follows the aim with a small lag and a little sway.
Battery: `TIME` 20 s -> 30 s with POWER upgrades. The last `FLICKER_T` (2.5 s) it flickers and dims, then "BATTERY DEAD".
While on, zombies can see you (`Game.player_dark` = false).
Darkness layers read every node in group `dyn_lights` through `effects/dyn_lights.gd` (`gather` / `merge`):
`subway.gd`, `effects/s11_decor.gd` NightOverlay, `effects/s14_decor.gd` StormOverlay.
Dark levels (night, subway, `stage.dark_level()` = stages 11 and 14) show `ui/tip_banner.gd` "TIP: USE YOUR FLASHLIGHT" for 4 s.

## Stage 15 - Carnival of the Dead (NORTHEAST region, level 6)

* `levels/stage_15.gd`, art in `effects/s15_decor.gd`: morning in Olinda after a carnival that never ended - golden low sun with rays,
  sea and Recife towers in the haze, the Olinda hill with pastel houses, white twin-tower churches and palms, colonial row houses
  with iron balconies and colored shutters (`ColonialRow`), carnival masks, streamers, confetti, Olinda giant puppets (`GiantPuppet`,
  some fallen), abandoned parade floats (`ParadeFloat`) = second floor (`FLOATS`) with ladders. Obstacles: maracatu drums, drink stall.
* New zombies: `bombhead.gd` (tears off his head and throws it - the head hits/bounces/chatters on the ground - then runs headless with a
  lit fireworks belt and explodes on you or when the fuse ends; shooting him while he runs = he explodes right there and hurts zombies),
  `minigunner.gd` (spin-up warning, sprays ~16 bullets/s with a wide spread and a slow-tracking aim, then OVERHEAT = x1.5 damage),
  `stilter.gd` (kangaroo legs: walks with bent legs, crouches deeper as a warning, legs fully extended in the air; huge leaps aimed where you will be, stomp on landing;
  boss "THE BONECO" = giant Olinda puppet with a wide landing shockwave). CRUMBLER returns.
