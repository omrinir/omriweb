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
| `weapons/` | `weapon_db.gd` (every weapon's stats), `weapon_sounds.gd`, `molotov.gd`, `rocket.gd` (ROCKET LAUNCHER: one rocket that splits into 3 minis that drop in an arc and land near/mid/far on screen, each a small all-particle explosion). |
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

`ui/monologue.gd`, `ui/kill_streak.gd` (fast-kill streak meter above the player: tiers GOOD..GODLIKE, HEADSHOT stamp; logic in game_state `streak_*`) (added to every level by `main.gd`): the hero talks to himself - comic speech bubble (font `fonts/Bangers-Regular.ttf`, OFL)
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
  `stilter.gd` (gaunt hunched creature with kangaroo legs - muscular thighs, sinewy shins, long clawed feet; skull with sunken glowing eyes and a hanging jaw;
  walks with bent legs, crouches deeper as a warning, legs fully extended in the air; huge leaps aimed where you will be, stomp on landing; dies as a ragdoll;
  boss "THE BONECO" = giant Olinda puppet with a wide landing shockwave). CRUMBLER returns.

## Stage 16 - The Flood (NORTHEAST region, level 7) - "THEY COME IN WAVES"

* `levels/stage_16.gd`, art in `effects/s16_decor.gd`: afternoon construction site in light rain (`LightRain` = thin slanted streaks +
  splashes on the road), warm hazy sun behind clouds, hazy skyline with cranes, concrete building skeletons with tarps and a tower crane,
  site fence with tarps and danger signs. Obstacles: concrete pipes, jersey barriers, brick pallets, containers.
* `SCAFFOLDS` = steel scaffolding (`Scaffold`) with TWO floors (`TIER1` 120 / `TIER2` 240 above the road) - player and zombies jump onto them.
* One zombie type only: `swarmer.gd` - hunched, fast, 1-hit, comes in huge numbers. They climb on each other (`on_back`):
  blocked by a wall / obstacle / a slow swarmer ahead -> hop onto its back; landing on a swarmer's back = ride it. Piles form at walls
  and under the player when he is on a high floor; from the pile (or a floor) they leap up. Close range: pounce + bite.
  Dies as a ragdoll (`ragdoll_pose` / `draw_ragdoll`). Anti-stuck: every few frames (and right after spawning) checks if its body
  overlaps a solid (`_inside_solid`) and pops up/out (`_unstick`); a rider whose mount walks into a wall gets off.
* `HordeDirector` (inner class in stage_16.gd): every `WAVE_GAP` s a wave (`WAVE_SIZE`, grows with progress) streams in off-screen
  ahead (25% from behind), capped at `MAX_ALIVE` awake swarmers near the player. Every 2nd wave = ammo drop next to the player.
  Performance: zombies farther than `FREEZE_DIST` from the player are fully paused (physics off) and wake up when he gets close.
* Lots of ammo: a box every `AMMO_GAP` px (road or scaffold), a SUPPLY crate on every top floor.
* Boss `broodmother.gd` "THE BROODMOTHER": huge spiny thing on all fours with a translucent belly sac full of wriggling young.
  LABOR (sac swells, glows, screams) -> BIRTH: throws 3-4 newborn swarmers at you (+2 under half HP, max `MAX_KIDS` alive).
* `game_state.gd` `LEVEL_WORLD` now maps levels 14-16 to their own worlds (before, 14/15/16 were read as subway/factory/NIGHT).

Ragdoll hooks for zombie types (`effects/ragdoll.gd`): a type can define `ragdoll_pose() -> Array` (11 joints, local, unscaled)
and `draw_ragdoll(ci, rag)` to keep its own silhouette as a soft corpse (STILTER uses both).

## Progression, saving and performance (feedback round)

* **Weapons** (`progression/arsenal.gd`): every weapon enters the game at a fixed stage = `"unlock_level"` in `weapons/weapon_db.gd`
  (1 shotgun, 2 sniper, 3 taser, 4 pistol, 5 SMG, 6 assault rifle, 7 molotov, 8 grenade launcher, 9 assault shotgun, 12 rocket launcher).
  It waits for you at the start of that stage (NEW WEAPON). Mid-level `CACHE_AT` = a weapon cache with an older unlocked weapon you don't own.
  The old per-stage `weapon_offers()` lists are gone.
* **Ammo**: fixed supply points with a sign (`SupplyMarker`) at 20/40/60/80% (`SUPPLY_POINTS`; a stage can override `supply_points()` -
  stage 16 has one every 10%, incl. medkits). Dynamic drops: a dying zombie drops ammo with 3% (full) .. 20% (almost empty) .. 35% (all empty)
  - `Arsenal.ammo_drop_chance()`.
* **Saving** (`game_state.gd`): autosave at level end + at the mid-level checkpoint (`environment/checkpoint.gd`, `main.gd` `CHECKPOINT_AT`):
  position, weapons, ammo, grenades. TRY AGAIN after passing it = start at the checkpoint with that gear. Each level attempt keeps one
  `attempt_seed`, so a restart rebuilds the exact same level. Menu: CONTINUE (checkpoint or next stage) + STAGE MAP. The stage buttons
  are PRACTICE (`start_practice`): stage-appropriate loadout, nothing is saved and the real save is restored on return (`end_practice`).
* **Performance**: death budget in `zombie.gd` - from the 3rd death within 1 s (`DEATH_HEAVY`) the death is "lite": no ragdoll, a third of
  the blood drops, one flesh chunk, one spray layer. Blood drops capped (`MAX_BLOOD`). Landed flesh chunks stop redrawing (fade by modulate).

## Special items + accuracy

* **SPECIAL items** (`progression/arsenal.gd` -> `SPECIALS`): grenades (3 uses), molotovs (2), grenade launcher (4), rocket launcher (2).
  Not weapons: not in the weapon bar / wheel / shop / progression (`"special": true` in weapon_db -> `WeaponDB.removed()` = true).
  1-2 random finds per stage (`specials_for_level`, one in each half of `SPECIAL_FINDS`), rarer/stronger ones from later stages (`"from"`).
  E = switch to it, fire = use. Last use -> it's dumped and you're back on your gun. Holding one: a different find replaces it,
  the same kind adds uses. Perk BANDOLIER (`grenade_pouch`) = +1 use per find. No starting grenades anymore; SUPPLY crates = 3 ammo boxes.
* **Accuracy** (`game_state.gd`): every trigger pull gets `Game.shot_id`; bullets carry it (`bullet.gd` `shot`), and a shot counts as a hit
  once no matter how many pellets / pierced zombies it hit (was up to 200%+). Taser hits count too. Clamped to 100%.

## Story scenes (in-level conversations)

* Part of the level, not a video: a character stands in the level, the player walks to it himself, and when he gets
  `spot` px away (on the floor) the game takes control - stops, raises the gun, walks slowly to `dist`, and they talk.
  Then the ending (`leap` = crouches and jumps up out of the frame, `vanish` = cut to black + boom) and play continues.
  The player is shown without the gun during the scene (`player.unarmed` = only the sprite, no drawn arms / weapon).
  Subtitle names come from `names` ("" = no name, e.g. the stranger before he is known).
* `story/story_db.gd` - list of scenes. `story/scenes/l01_stranger.gd` - level 1 scene (copy it for new levels:
  level, x, actor = registry name, voices folder, names, beats). `story/story_trigger.gd` places the actor, clears the
  path (props / cover / small bricks removed, pickups moved past the actor) and starts `story/story_scene.gd`
  (letterbox, own camera, typed subtitles, voices, ENTER / SPACE = skip; zombies frozen, player invulnerable).
* Plays once per run of the level: `Game.story_seen` resets when a level is started (map / next / CONTINUE / practice),
  not on TRY AGAIN. Starting from a checkpoint past the scene = no scene.
* Shots go through `_frame()` so the feet sit low in the frame and a strip of ground is always visible.
  `player.auto_walk` (used only while `controllable` is false) does the scripted walk; `player.calm` softens the idle
  breathing during the scene (in close-ups it looked like the player rising).
* Level 3 (`story/scenes/l03_survivor.gd`): actor "SURVIVOR" (survivor.gd with `scripted = true` - stands, can't be shot),
  `zoom` 0.75 (all shots a bit wider), `ending` "drain" = the player absorbs her with the device (real drain: full life),
  she screams (fscream + fwail) and stays burned in the level. Voices `sounds/story/l03_survivor/` (her: Kokoro af_sarah + tremble).
* During a scene the monologue (ui/monologue.gd) stays quiet (group "story_scene").
* Level 1 voices: `sounds/story/l01_stranger/` - player = Kokoro am_onyx + monologue FX, zombie = Kokoro bm_lewis,
  fast villain delivery (speed 1.1, pitched down without slowing, rasp layer, thin metallic comb = half-robot).
* The zombie = `enemies/types/stranger.gd` (registry `STRANGER`, scale 1.1 - a bit taller than the player): flayed "revenant" - skull with red eyes and a lipless grin,
  ribs and guts, metal braces, a cannon arm with red hoses, a hooked metal claw, metal knee braces and toe claws.
  Controls from the scene: `talking`, `tilt`, `smile`, `look_back`. Recurring character - he disappears in the black, not killed.

## THEY LEARN clock (level timer)

* `progression/level_clock.gd` - GOLD / SILVER par per level (from level length, level number, difficulty).
  Shown top-center by `hud.gd` (`_draw_clock`): time, a GOLD | SILVER | red bar, the current target and 3 "eyes".
* Why it matters: past SILVER the zombies start learning you - every 30 s one more tier (max 3, `Game.learn_tier`).
  Each tier: `zombie_brain.adapt_k()` +0.2 (they use what PlayerMemory learned about you), `coord()` +0.1,
  decisions 10% faster (never under 0.25 s), and `PlayerMemory` learns 50% faster. No extra HP / zombies.
  Big red alert + sound on every tier; beeps in the last 10 s before GOLD / SILVER.
* Reward (`Game.finish_level`): GOLD = 20 points per second left + 50% more scrap + "THEY FORGET YOU"
  (next level's PlayerMemory decays 70% instead of 35%) + trophy GHOST. SILVER = 8 points per second left + 25% scrap.
  Results screen shows the medal and TIME BONUS.
* The clock pauses in story scenes (`main.clock_paused`) and the pause menu, and resumes from the checkpoint (saved there).
* Tune: PACE, PACE_DROP, BOSS_TIME, SILVER_MULT, LEARN_STEP, DIFF_MULT, GOLD_POINTS / SCRAP.

## Hero run animation

* `hero_anim.gd` "run" anchors are aligned on the head (no forward/back jumps between frames); frames 2 and 4 are the
  airborne phase (feet off the ground, head level) instead of sinking the whole body. Running kicks up dust (`player._dust`).

## Stage 17 - "THE DRY RIVER" ("THEY LEARNED TO LIE")

* `levels/stage_17.gd` + `effects/s17_decor.gd`: noon, dead river - cracked mud drawn over the road (`Riverbed`),
  stranded boats / rocks / driftwood (solid, own outline: group "no_outline"), river junk, old wooden piers
  (PIERS at PIER_H = one jump), mesas + broken dam + banks in the background, `HeatHaze` screen shader.
* `enemies/types/mirage.gd` (MIRAGE): walks with 2-3 copies (3 on HARD). **Only the real one casts a shadow and kicks
  up dust.** A copy pops from one bullet (no blood, no score, no kill), vanishes when it touches you, and blocks
  bullets meant for the real one. The real one waits behind its copies just outside your usual shooting distance
  (PlayerMemory.avg_distance) and charges when you reload or its copies are gone; lost copies come back every 7 s.
  Kill the real one -> all its copies vanish.
* Boss `enemies/types/mirage_king.gd` (FATA MORGANA): 3-4 copies that return fast, and every 8-11 s (or after 5 hits)
  swaps places with one of its copies in a shimmer.
* Story `story/scenes/l17_stranger.gd`: the stranger teaches the shadow rule - and has no shadow himself
  (`actor_props: {"no_shadow": true}`); ending "shimmer" = he dissolves like a mirage.

## GOD MODE potion
- Special item `"god"` (progression/arsenal.gd SPECIALS, never random). Placed by main.gd on `Arsenal.potion_levels()` (3, then every 2-3 levels, fixed seed) in the middle of the level (POTION_MID 42-58%), at the spot with the most zombies around. Player cannot be hurt while it lasts (player.hurt).
- Picking it up starts it at once (player.collect -> `_drink_god`, not stored as a special): `boosts[PickupScript.GOD] = player.GOD_TIME` (13.8 s, was 23 - cut 40% on 2026-10-17 because it was too easy, HUD boost row shows it; flames ramp up over the first 2.5 s). Light on particles: body flames ~15 alive, 1 bullet ember per 2 frames (max 8), 14-part hit burst.
- While active: body flames (`player._flames`), bullets get `god = true` (red ember trail + `GodBurst` on hit, bullet.gd), zombie.gd multiplies damage x4 when `src.god`.
- Potion art: `PickupScript.draw_potion(ci, pos, scale, time)` (ground, HUD slot, hand, boost icon).

## Pass barrier ("THEY'RE BEHIND YOU")
- environment/pass_barrier.gd, created by main.gd each level. If 4+ awake zombies that already noticed the player are 220-1300 px behind him, a red energy wall rises 230 px ahead (StaticBody2D layer 512 - only the player's mask has 512; zombies and bullets pass).
- It opens when all locked zombies are dead (or got >1700 px away / frozen), or after 40 s as a safety net. Paused during story scenes.
- Why: running past zombies made a growing crowd follow the player; measured in level 16 physics frame time rose from ~6 ms to 12-17 ms with 10-17 chasers near.

## Corpse splat
- zombie.gd `_try_splat`: 50% of deaths (SPLAT_CHANCE), played when the flung body first lands (ragdoll `on_ground()` or is_on_floor), on screen only, at most one per 250 ms. Sounds: sfx.gd "corpse_splat" (3 clips in sounds/guns).

## Aim guide (L key)
- `Settings.aim_guide`: 0 off, 1 crosshair, 2 crosshair + dotted line (saved in settings.cfg). The dotted line shows only on EASY; NORMAL/HARD get the crosshair only (L toggles it on/off there).
- ui/crosshair.gd (in the HUD layer, runs while paused): hides the OS cursor in play, draws 4 ticks whose gap = the weapon's real spread at the mouse distance (`player.aim_spread()`), red when `player.aim_on_zombie`. Cursor comes back when paused / weapon wheel / dead.
- player.gd `_update_aim_guide` (ray from the muzzle to the mouse, stops at walls / first zombie) and `_draw_aim_guide` (faint dotted line; shotgun = 2 cone edges, 260 px). Hidden when the laser perk / sniper scope already show a line, and for the bow (own arc).

## Stage 18 - "THE QUARRY" ("THEY LEARNED TO DIG")
- levels/stage_18.gd + effects/s18_decor.gd: bright midday open-pit quarry (blue sky, sun glare, stone terraces, bucket-wheel excavator, conveyors, crane, gravel, orange fences, DANGER signs). World: QuarryGround, Obstacle "blocks" / "truck" / "cart" / "drill_rig", metal "scaffold" floors (SCAFFOLDS, SCAFF_H 120). Screen: SunGlare + light dust.
- Zombies: DRILLER 0.16, UZI 0.2, BOMBHEAD 0.18 (back from 15), walkers/runners, a few CRUMBLER. UZI on scaffolds, extra DRILLERs between them.
- enemies/types/driller.gd (on death: explosion + `Scrap` pieces - drill cone, treads, wheels, yellow panels, glass, pipe, bolts - and a smoking burnt hull that stays ~9 s): DRIVE -> DIG (0.7 s) -> UNDER (invulnerable, moves under obstacles, layer 0) -> WARN (WARN_T = 1.0 s red ring + "!" at the player's spot, locked) -> ERUPT (hurt + launch) -> STUN (1.5 s, x1.5 damage). Boss mode (chase_range > 600): "THE EXCAVATOR", wider eruption, digs again faster.
- enemies/types/uzi.gd: AIM 0.45 s (red glint) -> BURST 11 shots @ 13/s, aimed at AIM_H = 38 px (above a crouching player, 34 px) with upward-only spread, each shot climbs CLIMB 0.065 rad (recoil) - crouching dodges the whole burst -> RELOAD 1.4 s. Uses the real "smg" gunshot.
- Main menu PRACTICE buttons now 2-18; region 2 level 9 renamed "The Quarry".
- DRILLER extras: stats "metal": true -> zombie.gd take_damage plays "metal_ping" (3 variants) + sparks, no blood/flesh/groan, except head-zone (cab window = pilot). DIG tips the whole machine nose-down (_pitch) and drives forward into the ground; a canvas_item clip shader (CLIP_SHADER, clip_y = ground) hides everything below the surface during DIG/ERUPT. Player > HIGH (60 px) above it: it stops ~110 px away and a zombie hand with a pistol pokes out of the cab window (3-shot bursts, GUN_CD 1.5-2.2 s; boss 5 shots).

## Stage 19 - "THE GREEN WALL" ("THEY LEARNED THE TREES") - jungle, region 3 level 1
- levels/stage_19.gd + effects/s19_decor.gd: light filtering through the canopy, distant step pyramid + waterfall, giant trees with buttress roots and swaying lianas, mossy stone heads, ferns / monstera / flowers. World: JungleGround, Obstacle "log" / "boulder" / "ruin" (tall carved pillar) / "stump", wooden tree platforms (TREEHOUSES, TREE_H 125). Screen: JungleFX (hanging canopy edge, light rays, falling leaves, fireflies, low mist).
- Zombies: SWINGER 0.2, BLADES 0.16, LEAPER, AMBUSHER, walkers/runners. Boss: BLADES boss mode "THE THRESHER".
- enemies/types/swinger.gd: WALK -> THROW (jumps up JUMP_V, vine catches at the apex) -> SWING (real pendulum; anchor halfway to the player at a height that keeps the bottom of the arc CLEAR above the ground; released at the far apex) -> DROP (lands LAND_GAP from the player; landing on him = hit). x1.5 damage while swinging.
- enemies/types/blades.gd: WALK (blades scrape sparks) -> WINDUP 0.5 s (blades out, glint) -> SPIN 0.9 s whirlwind dash 330 px/s (contact = hit, DEFLECT 50% of bullets with sparks + metal ping) -> DIZZY 1 s (stars, x1.5 damage). Boss spins twice.
- Main menu PRACTICE buttons now 2-19 (narrower buttons); region 3 level 1 renamed "The Green Wall".
- Perf note (stage 19): the backdrop redraws every layer every frame - keep each layer to a few dozen polygons. The first version's fern/flower layer cost ~11.7 ms/frame; now the whole jungle backdrop is ~5.7 ms (stage 18 ~2.4 ms). Near foliage = dark silhouettes (grass blades, broad leaves, palm fronds), no cartoon flowers.

## Crosshair bloom + sustained-fire accuracy
- player.gd `_bloom` (0..1): each shot adds BLOOM_AUTO.x (0.075, SMG / assault rifle) or BLOOM_SEMI.x (0.22); after 0.16 s without firing it decays at BLOOM_DECAY 1.4/s. Sniper and bow: none.
- Extra bullet spread = max * bloom^1.6: auto up to 0.05 rad (~2.9 deg after ~2 s of continuous fire), semi up to 0.015 rad.
- ui/crosshair.gd: gap = 4 + 26 * bloom (+ a small pop per shot) - closed at rest, opens the longer you hold the trigger.

## Stage 20 - "GREEN HELL" ("THEY LEARNED TO BLEND IN") - jungle, region 3 level 2
- levels/stage_20.gd: reuses the stage 19 backdrop / ground / obstacles / JungleFX (effects/s19_decor.gd) + dense static foliage from effects/s20_decor.gd:
  Undergrowth (z 2, behind characters), Bush (z 6, IN FRONT of characters, group "s20_bush"), Curtain (z 6, vines hanging from the canopy at the top), BushFader (the bush the player stands in fades to FADE_ALPHA).
  All foliage is static (drawn once) - keep it that way; the backdrop layers are the ones that redraw every frame.
  Bush shake: BushFader skews (no redraw) any on-screen bush a zombie is moving through (|vx| > SHAKE_VX) - the tell that a hidden zombie is coming. A frozen GHILLIE does not shake it. Tune SHAKE / SHAKE_SPEED.
- GHILLIE (enemies/types/ghillie.gd): leaf suit in the same colors as Bush (SUIT == BUSH). HIDE in a bush -> STALK creeps only while the crosshair is NOT on / pointing at it (_watched: WATCH_R, WATCH_DOT), freezes into a "bush" when watched -> lunges at LUNGE_R (or after FREEZE_MAX frozen, or when shot) -> after a bite RETREATs to another bush. Tells: "gh_rustle" + leaf particles while moving, eye glint every few seconds while hiding. Boss mode = "THE THICKET" (stage 20 boss).
  wants_redraw() (new zombie_type hook, used by zombie._maybe_redraw): false while motionless in HIDE - skips redraws.
- HANGED (enemies/types/hanged.gd): hangs from a noose (Bough node it creates at the anchor), pendulum sway (hits push it), pistol: AIM (red sight line + glint, AIM_T) -> SHOTS shots that LEAD the player's velocity (LEAD) -> COOL. Death: rope snaps (Bough.cut), corpse falls (collision restored in on_death). Placed by stage_20 HANGED_AT, never over tree platforms.
- particles.gd: new "leaf" burst kind.
- Fix: s19_decor near_plants palm frond polygon self-intersected ("triangulation failed" spam every frame in stages 19/20) - now a strip along the spine.

## Android (phone) build
- Touch controls: ui/touch_controls.gd (autoload "Touch"). Scripts reach it ONLY through ui/touch_api.gd (TouchAPI.on() / TouchAPI.node()), which creates the layer itself if the autoload is missing from project.godot - never write `Touch.` directly. On only on mobile (OS feature "mobile") or with `-- --touch` on desktop for testing.
  Phone camera: zoom MOBILE_ZOOM (1.6) and the player sits at the left quarter of the screen (MOBILE_LEAD, via shake_camera.base_offset). Right side = aim stick + JUMP only; RELOAD/SWAP/GREN/HOOK/SKILL in a row at the top-left; no ROLL button.
  Left floating stick = A/D (+run at RUN_AT, down = S, up = W climb). Right floating stick = aim + auto-fire, with a small aim assist (ASSIST / ASSIST_RANGE).
  Buttons press the real keys via Input.parse_input_event, so all keyboard code works unchanged. Only aim/fire are read directly: player.aim_world() / Touch.fire.
  Menus: taps become mouse clicks (Godot emulate_mouse_from_touch). Android back button = ESC in game, quit in menus (config/quit_on_go_back=false).
- Export: preset "Android" in export_presets.cfg (arm64, no gradle, signed with the Godot debug keystore - fine for sideloading, not for the Play Store).
  Needs the Android export templates (android_release.apk) and an SDK path whose build-tools contain apksigner (in the cloud box: /root/android-sdk with apksigner/zipalign from apt).
  `Godot --headless --path . --export-release "Android" build/TheyLearn.apk`
- Size: the upload limit for sending files is 30MB. The phone uses light 64k copies of the music (music/mobile/*.ogg, picked in main._load_music when OS has "mobile"); the Android preset excludes the full music, the Windows preset excludes music/mobile. map/continent.png is imported lossy (WebP 0.85).
- Icon: icon.png (+ android_icons/ for the launcher).

## MIND CONTROL (special item "mind")
- effects/mind_control.gd. Special in progression/arsenal.gd SPECIALS: 1 use, from level 10, weight 0.7 (rare). TEST: a pickup near the start of EVERY level while Arsenal.TEST_MIND_EVERY_LEVEL = true (placed in main.gd) - set false when done testing.
- Fire (E to select, then shoot): purple beam (ray + small aim assist). Bosses and special zombies (NO_CONTROL) refuse - the use is not consumed. A miss is not consumed either.
- Session (25 s, DURATION): zombie.possessed = session -> zombie.gd skips its AI and calls session.drive(): A/D move, SHIFT / full stick run, W jump, LMB / aim stick claw (CLAW_DMG in front).
  Camera reparents to the zombie. Hero: controllable=false, mind_linked=true, invulnerable, purple trance. Touch controls stay visible (mind_linked).
  Other zombies: zombie.mind_traitor (static) -> _traitor_near() makes them chase it (direct, no brain steering) and bite it via zombie.hurt() (x8 damage).
  End: time out / traitor dies -> traitor collapses dead (_die), camera + control return to the hero.
- Fix: touch layer was drawn once on desktop (Node2D visible by default) - now hidden unless Touch.on.
- Abilities (effects/mind_abilities.gd): C / RMB (phone: SKILL) = the controlled zombie's own ability, chosen by kind in ability_for():
  spin (BLADES), pounce (default: LEAPER, AMBUSHER, GHILLIE, walkers...), shoot (UZI, MINIGUNNER, SANDBLASTER, GUNNER), spit (SPITTER, RETCHER, HURLER),
  slam (BRUTE, TANK, SHIELDED, DEVOURER, CRUMBLER...), scream = stun (SCREAMER, SIREN, COMMANDER, PACK_LEADER), explode (BLOATER, BOMBHEAD - ends the control).
  Cooldowns in INFO; HUD shows the ability name + ready bar. Hidden types (GHILLIE _k / AMBUSHER _hide) are un-hidden when taken over.
- Fix (stuck in the last seconds): stages 16/17 freeze zombies > FREEZE_DIST from the hero, and zombie.gd sleeps zombies > 1400 px from the hero.
  Both now also keep zombies awake near the controlled zombie (MindControl.near_focus / zombie._traitor_near), so walking it far away no longer freezes it.

## Stage 21 - "CLIFFSIDE" ("THEY LEARNED TO FLY") - mountain cliffs at dusk, region 3 level 3
- levels/stage_21.gd + effects/s21_decor.gd: dusk sky, snowy peaks, cliffs with pagodas / waterfalls / rope bridges, pines (backdrop, few polygons).
  World: CliffGround (built between the pits), wooden WALKWAYS at TIER 150 (the "second level") with prayer Flags, Obstacle "rock" / "lantern" (tall cover) / "crate".
- Trap: SpikePit (extends hazard.gd), one per main._pits (pits() = SPIKE_PITS 6): player takes 1 and is bounced out (bounce), zombies take 60 per tick.
  SMART_HOP 0.75: most zombies jump over a pit when they reach its edge, the rest fall in and die (lure them!).
- GLIDER (enemies/types/glider.gd): WALK -> CLIMB (ballistic jump onto the nearest platform, _platform_target / _climb_to) -> PERCH -> GLIDE
  (descent aimed at your chest, leads your movement) -> HOP (small jump timed to land on you) -> RECOVER. Shooting it while gliding tears the wings (falls). x1.5 damage in the air.
- REVOLVER (enemies/types/revolver.gd): AIM (red line, AIM_T) -> one heavy Slug (DAMAGE 2) -> RUN a little (away if close, else sideways / to cover) -> repeat.
  Boss THE SHERIFF (stage 21 boss): 2 shots per volley, the second leads more.
- Mind control: REVOLVER -> "shoot" ability; GLIDER -> default "pounce".
- Menu practice row: 2-21 (spacing 43, size 40).

## Level cards with pictures (map)
- map.gd LevelSelect / LevelCard: cards are 370x140 and show map/thumbs/level_N.png (740x280, rounded corners, dark gradient on the left for the name and at the bottom for the stars).
  Locked = darkened + lock. A level without a picture (or not built yet) falls back to the old plain card.
- The pictures are real in-game shots: each level is loaded, the HUD is hidden, the camera zooms in (2.1x) and the level's signature zombies + its boss are posed facing the hero
  (GLIDER gliding, BLADES spinning, UZI / REVOLVER aiming...). Then cropped + graded (scratchpad tools t_thumb.gd + make_cards.py).
  New level -> ask for its picture to be generated (until then its card is plain).

## Stage 22 - "THE DAM" ("THEY LEARNED TO SET TRAPS") - grey rainy morning at a giant dam, region 3 level 4
- levels/stage_22.gd + effects/s22_decor.gd: overcast sky, dam wall with spillway waterfalls, power pylons, pines, reeds + fence. World: wet concrete DamGround,
  steel CATWALKS at TIER 140 (harpooners stand there), Obstacle "barrier" / "drums" / "timber" (tall cover). DamFX: drizzle + spray mist.
- Trap: LogTrap (LOG_TRAPS positions): a visible tripwire (red flags) with a rope to a wooden tower AHEAD (300 px) holding a round log on a ramp (chock).
  Touch the wire -> chock flies out -> the log rolls down the ramp, falls + bounces (DROP_DMG) -> rolls back at you, spinning (ROLL_DMG, ROLL_V, ROLL_DIST) - jump over it.
  Drawn end-on (round cross-section with bark + rings) as a rolling log looks in side view. Stops at an obstacle / after ROLL_DIST and stays as cover. Kills zombies in its path.
- GOLIATH (enemies/types/goliath.gd): huge butcher. Falls apart in order by HP (LOSE_AT): front arm, back arm, back leg (hops), front leg (crawls), head on death.
  Tactics change: 2 arms = SMASH (windup + ground slam), 1 arm = faster swipe, no arms = CHARGE (headbutt rush, then STUN), no legs = crawl + bite.
  Boss THE BUTCHER (stage 22 boss). Limbs fly as Limb nodes.
- HARPOONER (enemies/types/harpooner.gd): diver with a spear gun. AIM (red line) -> Spear on a rope -> hit = 1 damage + reels you in (REEL_PULL, HOLD_T)
  using player._push_t; miss / wall = spear reels back by itself; RELOAD window.
- Mind control: HARPOONER -> shoot, GOLIATH -> slam. Map picture: map/thumbs/level_22.png. Menu practice row 2-22 (spacing 41, size 38).

## Stage 23 - "HIGHWAY 7" ("THEY LEARNED TO DRIVE") - jammed highway at dusk, region 3 level 5
- levels/stage_23.gd + effects/s23_decor.gd: dusk sky + low sun, burning city skyline (fire glow + smoke), overpass deck with stuck cars / billboards / street lamps,
  guard rail + green EXIT signs. World: RoadGround (lane dashes, skid marks, oil), broken OVERPASSES at TIER 150 with ladders, sign Gantry (decor),
  steaming sewer manholes (manhole.gd, MANHOLES), RoadFX (embers + warm haze). Music: level1_zombie_joyride.ogg.
- Car (s23_decor.gd, generator "wreck"): solid AnimatableBody2D (sync_to_physics = false so it really moves), cover, you can stand on it.
  push(dir, speed, t) slides it: hurts the player on the side it moves toward (HIT_DMG 2) and kills zombies in the way (Z_DMG).
- Trap: car alarm. ALARM_CHANCE of cars (plus always the 2nd one) have a blinking red LED. Touch it / stand on it / shoot it / a SHOVER pushes it ->
  siren + flashing lights, Game.make_noise(ALARM_NOISE) and ALARM_SPAWN zombies run in from both sides (off screen).
- BIKER (enemies/types/biker.gd): CRUISE (keeps RANGE) -> REV (wheelie + smoke = warning) -> CHARGE through you and past (jumps cars) -> SKID (your window).
  At DISMOUNT_AT hp it is thrown off: the bike becomes a burning Wreck, the rider fights on foot. Boss ROAD KING (stage 23 boss): two charges in a row.
- SHOVER (enemies/types/shover.gd): big trucker. If a car is between him and you (and you are on the road) he walks behind it and pushes it at you (PUSH_V, PUSH_T).
  No car + you are next to him -> SHOVE: arms back (warning) then a big knock-back push (1 damage). Jump onto / over the car to dodge.
- Mind control: SHOVER -> slam, BIKER -> pounce. Map picture: map/thumbs/level_23.png. Menu practice row is now automatic (Game.IMPLEMENTED buttons, shrinks to fit).

## Killing spree sound
- ui/kill_streak.gd: in each streak a kill number between SPREE_SOUND_AT (5-7) is picked; with SPREE_SOUND_CHANCE (0.6) "spree_die" plays there
  (sounds/streak/spree_die.mp3, SPREE_SOUND_PITCH 1.15 = 15% faster). Registered in sfx.gd SAMPLES (+ SAMPLE_GAIN).

## Stage 24 - "BURNING FIELDS" ("THEY LEARNED TO STAND STILL") - burning wheat fields at night, region 3 level 6
- levels/stage_24.gd + effects/s24_decor.gd: red smoky night sky + orange moon, fire line along the hills, red barn / silos / turning windmill / fences,
  swaying wheat with burning patches. World: FieldGround (dirt road, straw, burnt spots), wooden HAYLOFTS at TIER 140 with ladders,
  Obstacle "bale" (round hay bales, cover) / "fence" / "cart". FieldFX: embers + red glow.
- SCARECROW_FIELDS: 4 posts per field, 1-2 of them are SCARECROW zombies, the rest are decor Scarecrows (most with a crow on them).
  Tell: the real ones have no crow and their head slowly turns to follow you.
- Trap: BearTrap (BEAR_TRAPS) hidden in the grass, teeth glint every few seconds. Player steps in -> 1 damage + held (player.grab, HOLD_T 1.5 s, A/D mashing frees sooner).
  A zombie that steps in is stuck (Z_HOLD) and takes Z_DMG. Smart zombies (hazard_awareness) hop over it (danger_at + world_rect).
- SCARECROW (enemies/types/scarecrow.gd): POSE on a post (setup() lifts it POST_H onto a Post node; drawn with the same scarecrow_body() as the decor)
  -> wakes when you pass it (WAKE_PASS), stand next to it (NEAR_T) or shoot it -> DROP behind you -> STALK (fast, hunched, sickle) -> SWING (raised sickle = warning, DAMAGE 2) -> BACK hop.
- TORCH (enemies/types/torch.gd): burning zombie, immune to fire. Keeps range, backs off when close (BACKOFF). WIND (lit bottle held back = warning)
  -> Bottle in an arc, leading your movement -> fire_zone (FIRE_W, FIRE_T). Dies -> bursts into a fire zone. Boss THE PYRE: 3 bottles in a fan, 3 fire zones on death.
- Mind control: SCARECROW -> spin, TORCH -> spit. Map picture: map/thumbs/level_24.png.
- Fix: LogTrap (s22) and BearTrap now have world_rect() (zombie_brain calls it when hopping over a hazard).

## Stage 25 - "RADIO TOWER" ("THEY LEARNED TO CALL FOR HELP") - stormy night at a radio station on a hill, region 3 level 7
- levels/stage_25.gd + effects/s25_decor.gd: storm sky with moving clouds, giant lattice mast with blinking red lights + guy wires, satellite dishes,
  equipment huts, pines, razor-wire fence, wind-blown wet grass. World: HillGround (wet mud + gravel), steel CATWALKS at TIER 150 with ladders,
  Obstacle "cabinet" (tall cover) / "spool" / "generator".
- StormFX (screen layer, group "storm"): rain + lightning on a schedule (PERIOD). warning() = the WARN seconds before a flash, flashing() = the flash.
  It is the clock for the trap. strike_flash() = small flash for ROD strikes.
- Trap: Puddle (PUDDLES) with a broken power pole and its cable lying in the water. During warning() it glows blue and sparks;
  on the flash it electrifies: DMG 2 to the player standing in it, Z_DMG to zombies in it. Smart zombies wait outside while it is live (danger_at).
- SIGNALER (enemies/types/signaler.gd): radio backpack + antenna. Keeps range (backs off inside BACKOFF), kneels and TRANSMITs (TRANSMIT_T, waves + progress bar).
  Done -> CALL_N zombies run in from both sides + make_noise (MAX_CALLS per signaler, LEVEL_CAP per level). Any hit while transmitting = "SIGNAL LOST".
- ROD (enemies/types/rod.gd): lineman in a yellow rain coat with a copper-tipped iron rod. RAISE (sparks) -> Strike: a warning circle on the ground under you (WARN_T),
  then a bolt (DAMAGE 2, also hurts zombies in the circle). Move when the circle appears. Boss THE STORMBRINGER: 3 strikes (on you, ahead, behind).
- Mind control: ROD -> shoot, SIGNALER -> scream. Map picture: map/thumbs/level_25.png. Game.IMPLEMENTED = 25.

## Stages 26 + 27 are one story (end of region 3)
- 25 RADIO TOWER -> the signal came from underground -> 26 THE BUNKER (the zombies' command center) -> THE GENERAL escapes through the tunnel
  -> 27 PLATEAU GATE starts at the tunnel exit and ends with the General's last stand at the gate.
- THE GENERAL (enemies/types/general.gd) is the boss of both. It checks Game.level: 26 = commander that escapes, 27 = final fight.

## Stage 26 - "THE BUNKER" ("THEY LEARNED TO GIVE ORDERS") - underground military command bunker, region 3 level 8
- levels/stage_26.gd + effects/s26_decor.gd: concrete hall with vault doors, painted floor numbers, pipes, spinning red emergency lights, pillars + hanging lamps.
  World: BunkerGround, Ceiling (concrete slab at CEIL_Y, ventilation DUCT at DUCT_Y with grates, flickering fluorescents), steel CATWALKS (TIER 150),
  Obstacle "crates" / "drums" / "locker", ExitTunnel ("TO THE GATE") behind the exit. dark_level() = true (flashlight tip).
- BunkerDark (CanvasLayer + shader): the bunker is a bit dark (DARKNESS); a section whose FuseBox is cut goes almost black (BLACK). Player glow + flashlight light it.
- FuseBox: one per SECTION_W. cut() = section dark for BLACKOUT_T (9 s). The player touching the box restores it at once.
- Trap: LaserGate (LASERS): a red laser curtain from ceiling to floor, cycles ON_T / OFF_T, flickers WARN_T before turning on. DMG 2 + pushback; zombies take Z_DMG.
- HAZMAT (enemies/types/hazmat.gd): always faces you. AIM (green drip) -> SPRAY GasCloud in front (doesn't turn while spraying = your window to get behind).
  Tank on the back: hits from behind do x TANK_MULT and after TANK_HP hits (or any explosion) the tank bursts into a gas cloud and he dies. Gas also hurts other zombies.
- BLACKOUT (enemies/types/blackout.gd): night-vision goggles. When it sees you in a lit section it RUNs to that section's FuseBox and PULLs the lever (MAX_CUTS 2).
  Faster in the dark (DARK_SPEED), goggles glow.
- VENT (enemies/types/vent.gd): spawns inside the ceiling duct (only red eyes visible, dust falls, duct rattles; bullets hit the metal).
  Crawls to BEHIND you (the side you're not aiming at) and drops through a grate when you're on the floor. Aim back at it and it has to crawl around.
- THE GENERAL in 26: keeps distance (KEEP), aims + 3-shot bursts, every ORDER_CD whistles "ATTACK!" (nearby zombies rush).
  At ESCAPE_AT hp (35%) he can't be hit any more: "RETREAT! TO THE GATE!", drops loot, opens the exit and runs off right into the tunnel.
- Mind control: HAZMAT -> spit, BLACKOUT / VENT -> pounce, GENERAL -> shoot.

## Stage 27 - "PLATEAU GATE" ("THEY LEARNED TO HOLD THE LINE") - fortified border checkpoint at dawn, region 3 level 9 (region finale)
- levels/stage_27.gd + effects/s27_decor.gd: dawn sky + rising sun, snowy Andes on the horizon (the next region), long border wall with watchtowers / razor wire / flags,
  anti-tank hedgehogs + wire + sandbags up close. World: GateGround (packed dirt, tire tracks), TunnelExit at the start ("BUNKER B-2", the General's boot prints),
  TOWERS (Watchtower decor + wooden floor at TIER 180 + ladder + Searchlight), Obstacle "sandbags" / "hedgehog" / "jeep", GreatGate behind the exit (doors slide open when the boss dies).
- Trap: Searchlight sweeps the ground (SWEEP, SPEED). Stand in the spot -> "SPOTTED!" siren, make_noise, the light locks on you and an artillery Shell lands where you stood (CD between).
- SNIPER (enemies/types/sniper.gd): on the towers. AIM = red laser that follows you with a lag (TRACK); the last FREEZE (0.3 s) it locks + blinks, then fires along it (chest band only).
  Move when it blinks and it misses. If your crosshair is on him (DUCK_R) he DUCKs behind the sandbags (bullets x0.15) - aiming at him suppresses him.
- SAPPER (enemies/types/sapper.gd): keeps distance; when you walk toward him he kneels and buries a Mine where he stands, then backs off (MAX_MINES).
  Mine: small blinking red light, arms after ARM_T, step on it = click + blast almost at once (DELAY 0.15, RADIUS 92) - jump over mines. Also kills zombies (smart ones avoid).
- HANDLER (enemies/types/handler.gd): walks with two dogs on a leash. You come within RELEASE_R -> "SIC 'EM!" -> 2 DOG zombies (kind 15). Then whistles every WHISTLE_CD
  (dogs rush you again) and keeps distance. Kill him from range before he releases them.
- THE GENERAL in 27 (final): artillery ("FIRE FOR EFFECT!": 3 Shells around you, every SHELL_CD) + pistol bursts. Under RAGE_AT (50%): "NO MORE RETREAT!" - sword:
  WIND (raised) -> DASH -> TIRED (x1.5 damage window). Armor + bandaged arm from the escape. Death opens the great gate = region 3 done.
- Shell (in general.gd): warning circle on the ground + falling whistle, then explosion.blast. Used by the General and the searchlights.
- Mind control: SNIPER -> shoot, SAPPER -> explode, HANDLER -> scream. Map pictures: map/thumbs/level_26.png, level_27.png. Game.IMPLEMENTED = 27.

## LASER CANNON (special item "laser", weapons/laser_cannon.gd)
- progression/arsenal.gd SPECIALS "laser": 8 uses ("uses"), found from level 14 ("from"), rare ("weight" 0.5). The grenade-pouch perk does not add uses.
- Test: Arsenal.TEST_LASER_LEVEL = 3 -> main.gd puts one at the start of level 3 (next to the mind control test pickup). Set it to 0 to remove.
- player.gd: when the item is in hand (weapon == GRENADE and special == "laser") the trigger goes to LaserCannon.tick() instead of _fire().
  Hold fire = charge (player.laser_charge, CHARGE_T 1.4 s): ChargeFX pulls green particles into the barrel in a spiral, shrinking rings, rising sound,
  the gun's coils and core glow brighter; it blinks when almost full. Let go early = the charge is cancelled and no use is spent.
- Full charge -> Beam (BEAM_T 1.6 s): energy burst at the muzzle (flash, shockwave rings, 40 sparks, big screen shake), then a thick green beam with a white core
  and two spiral energy lines that follows your aim, pushes you back a little, and hits every zombie on the line every TICK (DMG 18, bosses x BOSS_K 0.6),
  sometimes sets them on fire. It goes through zombies and stops only at walls (breaks bricks it hits). Narrows out at the end.
- After the 8th beam ends the item is used up and you go back to your gun. Sounds: lz_charge / lz_fire / lz_hit (registered via sfx.gd BANKS).

## Region 4 - ANDES (levels 28-36)

## Stage 28 - "DEATH ROAD" ("THEY LEARNED TO WAIT") - Bolivia's Yungas road, region 4 level 1
(Rebuilt: the old "Cloud Pass" with condors, wind gusts and floating rope bridges was replaced.)
- levels/stage_28.gd + effects/s28_decor.gd: overcast dusk over a cloud-forest valley. Background: snowy Cordillera far away above the mist,
  grey ridges, the green mountain opposite with the road cut into it (trucks with headlights crawl along it, white crosses, thin waterfalls),
  cloud-forest canopy + tree ferns below the road. The ridges use smooth value noise (_ridge) so they never repeat or seam.
  World: RoadGround (muddy dirt road, ruts, puddles, roots), Washout pits (pits() = WASHOUTS; extends the stage 21 SpikePit: rusted rebar,
  broken edges, a yellow warning sign, WashoutMist rising inside), CliffLedge (LEDGES: towering rock face behind the road with moss and vines,
  an upper road shelf on timber struts - the one-way floor itself is hidden, the ledge draws it - plus a ladder), Waterfall (WATERFALLS:
  falls from the cliff onto the road, spray/drop particles), WreckBus (BUSES), WreckTruck (TRUCKS + one before the boss arena, burning, smoke),
  Shrine (SHRINES: roadside animita with candles and flowers), Obstacle "slide_rocks" / "fuel_drums" / "luggage". RoadFX: drizzle + a cloud
  rising from the valley now and then. particles.gd got two new kinds: "mist" and "drop".
- WreckBus: hands on the windows; within KNOCK_R it bangs from inside (warning), within OPEN_R it opens and PASSENGERS zombies jump out
  on the player's side (stage._open_bus).
- CLINGER (enemies/types/clinger.gd): replaces the CONDOR. A fallen traveller in a torn orange poncho who hangs on edges: both edges of every
  washout and two spots under every upper road (anchors are found from the "washouts" and "ledges" groups; the stage calls attach() right after
  spawning). Only fingers show (and the head peeks now and then). Stand on the edge / jump over the washout / walk over it on the upper road ->
  LUNGE -> grab (player.grab, mash A/D) -> after PULL_T you are pulled into the washout (rebar) or off the upper road (falls + 1 damage).
  Escaped or missed -> EXPOSED (x1.5 damage) then climbs out to fight. If you pass it without touching the edge it climbs out and attacks from
  behind. Shot while hanging and still alive -> sinks into the mist and moves to the other edge. Weighted spawns walk to a free edge (SEEK).
- BOSS EL CAMIONERO (enemies/types/trucker.gd, Registry.TRUCKER): huge trucker with a tire on his back. REV (truck horn + stomps = warning)
  -> CHARGE (hits = 2 damage + knockback, runs over zombies, hops washouts) -> SKID if he misses in the open. If he hits a solid obstacle
  (bus, truck, rocks) he CRASHes: stunned CRASH_T, takes damage, x2 damage taken. After LEARN_AT crashes he LEARNS: no more charging when
  something solid is behind you - he throws Tires instead (bounce and roll, jump over them). Below 50% HP: shorter warning, 2 tires per throw.
- BOULDER (enemies/types/boulder.gd): hulking porter with a stone basket on the upper roads. LIFTs a boulder over his head (dust = warning),
  ROLLs it at you (Rock: bounces, 2 damage, crushes zombies in the way, breaks on walls) or lobs it in an arc. Jump over it.
- Mind control: CLINGER -> pounce (default), TRUCKER -> slam.
- Obstacle names: never reuse main.gd generator names (car, barrels, barrier, crates, rubble, bus, train, container, tires, sandbags, block, wall) in
  custom_gen - main.gd handles those itself. Renamed earlier: 22 "barrier"->"jersey", 26 "crates"->"ammo_crates", 27 "sandbags"->"bags".

## Stage 29 - "MINE OF ECHOES" ("THEY LEARNED TO LISTEN") - Andean silver mine (inspired by Cerro Rico, Potosi), region 4 level 2
- levels/stage_29.gd + effects/s29_decor.gd: cavern with wooden scaffolds + ladders, far lanterns, silver veins that glint, an ore cart riding a trestle,
  timber support frames with swinging lanterns, stalactites, El Tio silhouettes. World: MineGround (rails + sleepers), CaveCeiling (rock ceiling at CEIL_Y,
  stalactites, falling water drops), Lantern (group "mine_lights", flicker), SteamLeak (compressed-air pipe that puffs steam), ElTio (clay mine deity with horns,
  candles, coca leaves, colored ribbons and a smoking cigarette), SCAFFOLDS at TIER 150, Obstacle "minecart" / "ore" / "timber". MineDark: dark + lantern/flashlight
  holes. MineFX: floating dust.
- Trap: CaveIn (CAVE_INS, group "cave_ins"): cracked ceiling sections. Player shots nearby add rumble (RUMBLE_SHOTS within the DECAY), explosions call shake().
  WARN_T of falling dust + glowing cracks + rumble, then ROCKS FallingRock (2 damage, kill zombies) and a CD.
- ECHO (enemies/types/echo.gd): blind miner (bandaged eyes, broken helmet lamp). Ignores what it can't hear: a shot within SHOT_R, running within RUN_R,
  walking within WALK_R, explosions (_alert_t), or being hit -> RUSH to that spot (screech), then SEEK, then LISTEN (head tilts, echolocation clicks).
  Crouching + not shooting = it doesn't notice you even right next to it. Strikes when it touches you.
- DYNAMITER (enemies/types/dynamiter.gd): LIGHT (sparks) -> throws a Stick in an arc (leads you; higher arc if you're behind cover). The stick bounces/rolls,
  the fuse burns (FUSE) -> blast (RADIUS) that also shakes the cave-ins. On death his bundle lights and blows up a second later.
  Boss THE FOREMAN: 3 sticks in a fan.
- Mind control: DYNAMITER -> explode, ECHO -> pounce.

## Stage 30 - "FROZEN VILLAGE" ("THEY LEARNED THE WINTER") - Andean highland village in a blizzard, region 4 level 3
- levels/stage_30.gd + effects/s30_decor.gd: grey blizzard sky, faded ridges, adobe houses with snowy roofs + smoking chimneys, a white colonial church,
  alpaca pens, colorful frozen laundry, snowdrifts. World: SnowGround (snow over cobbles, footprints), House walls under each roof platform (HOUSES, "roof")
  with lit windows and a chimney that puffs smoke particles, BellTower (TOWER, group "bells": ring() swings the bell + sound waves; a wooden floor at TOWER_H),
  BRAZIERS (fire barrels: smoke + sparks + warm glow; standing within WARM_R removes the freeze), Obstacle "stonewall" / "woodpile" / "haycart".
  BlizzardFX (group "blizzard"): heavy diagonal snow + whiteout(t) (WHITE = how white at the peak).
- Trap: ThinIce (ICE): frozen puddles. Standing on one cracks it (cracks stay and heal slowly, heavy zombies break it at once); at CRACK_T it breaks:
  DMG 2 + frozen (player._daze_t = CHILL: slow + shaky aim) and zombies on it take 30. Refreezes after REFREEZE.
- FROSTBITE (enemies/types/frostbite.gd): ice armor (ICE hp) absorbs all damage until it shatters; fire / explosions / laser break it ICE_FIRE x faster.
  Without ice it's weak and faster. Its bite freezes your hands (CHILL). Boss THE FROZEN ONE: 6x ice that regrows after REGROW s without being hit.
- BELLRINGER (enemies/types/bellringer.gd): in the bell tower (finds the BellTower under it): every RING_CD when you're within RANGE it pulls the rope (PULL_T, shoot it
  to SILENCE it) -> the bell rings, the blizzard turns to whiteout (WHITE_T) and zombies within RUSH_R rush you. On the ground: a hand bell (weaker).
- Mind control: FROSTBITE -> slam, BELLRINGER -> scream. Map pictures: map/thumbs/level_28.png, level_29.png, level_30.png. Game.IMPLEMENTED = 30.

## Stage 31 - "FLOATING ISLANDS" ("THEY LEARNED TO SWIM") - Lake Titicaca, Uros reed islands, region 4 level 4
- levels/stage_31.gd + effects/s31_decor.gd: sunrise over the lake, the snowy Cordillera Real reflected in the water, a glittering sun path,
  far reed islands with huts / watchtowers / cooking smoke / sailing reed boats, swaying totora reeds.
- The whole level is a shallow lake: LakeGround (lake bed) + WaterFront (translucent water surface drawn ABOVE the actors, so legs are
  underwater). stage.LakeLogic sets player.in_water (slower) when the player is on the lake bed; main meta "lake_floor" = floor_y.
- Island (group "islands", solid, ISL_H high): reed bundles, huts with woven door curtains, fish racks, clay stoves (smoke particles),
  reed watchtowers. Islands are generated (ISLE_W / ISLE_GAP) from x=0 (the start island); BOSS_ISLES = two refuge islands in the boss arena.
  Zombies that spawn inside an island are moved on top of it (extra_spawns).
- Trap: RottenPatch - darker, wet, mossy reeds in the middle of some islands. Step on it: it creaks and sags (SAG_T, cracks appear), then
  breaks - you drop into a water hole inside the island, 1 damage + TANGLED (slow, shaky aim, TANGLE_T). Regrows after REGROW_T.
- Obstacles in the water: "moored_boat" (reed boat with a puma head) / "reed_bundles" / "fish_crates".
- DROWNED (enemies/types/drowned.gd): swims underwater (collision_layer 0 - bullets can't reach it; only bubbles + a V ripple show; it swims
  under boats/crates but not islands). Close to you while you're in the water -> RISE (boiling bubbles = warning) -> bursts out and bites ->
  UP (x1.4) -> dives. You on an island: it waits at the edge (LURK_T) then CLIMBs on. Grenade/explosion in the water -> STUNNED floating (x2).
  Taser hits it underwater. Boss MAMA QUCHA: sends Waves along the lake (islands break them - stand on the reeds); if you hide on an island
  near her she first yanks you into the water, then the wave.
- BALSERO (enemies/types/balsero.gd): reed boat + boatman + 2 passengers. Sails to the island you're on and unloads the passengers onto it,
  then pokes you with his long pole. Shots low on the boat damage the hull (BOAT_HP): sink it before it unloads and the passengers drown...
  and come back as DROWNED. After the boat sinks he is a normal zombie.
- NETTER (enemies/types/netter.gd): fisherman in a chullo hat. Keeps distance (BACKOFF), whirls the net (warning), throws it in an arc.
  Netted: very slow, no jumping, reeled toward him. ROLL (SHIFT) tears the net; a heavy hit on him (CUT_DMG) or killing him frees you.

## Stage 32 - "DEVIL'S CARNIVAL" ("THEY LEARNED TO DANCE") - the Oruro carnival (Diablada), Bolivia, region 4 level 5
- levels/stage_32.gd + effects/s32_decor.gd: night sky with fireworks, hills with town lights and the lit Virgin of Socavon statue,
  colonial houses + the twin-tower church, string lights that blink ON THE BEAT, a zombie crowd in the stands bobbing to the beat,
  flags and balloons. World: PlazaGround (cobblestones, confetti, streamers), Arch (silver-plate carnival arches with a devil mask),
  Facade (colonial houses with carved wooden balconies = the upper floor, FACADES), Obstacle "food_cart" (smoking anticucho grill) /
  "bleachers" / "brass_drums". CarnivalFX: falling confetti + a small beat indicator at the bottom of the screen.
- Band (group "band"): the level's music is generated live: kick + tuba / snare + brass at BPM, beat_id counts beats, pulse() = 1 on the beat.
  music() returns "" (main.gd now skips loading music when a stage returns "").
- Castillo (group "castillos"): wooden firework tower. Shoot the wheels (WheelBody.hit_by_bullet) -> BURN_T seconds of spinning sparks that
  burn every zombie in RADIUS (and you, if you stand too close).
- Firecrackers: strings of firecrackers on the ground; anyone stepping on them sets off a chain of pops (1 damage to you, zombies hop and burn).
- DIABLO (enemies/types/diablo.gd): devil dancer. Within SYNC_R of a living "bandleader" (BANDLEADER or SUPAY) it is in sync: leaps at you on
  every beat, stomps between beats; odd dancers leap OVER you and land behind (surround). The mask blocks front head shots (MASK_HP) until
  it breaks. When its bandleader dies -> lose_beat() -> DIZZY (x1.6).
- MORENADA (enemies/types/morenada.gd): heavy barrel-costume dancer with a rattle. Starts on a beat: WIND (rattle) -> SPIN toward you
  (bullets are DEFLECTED, contact = 1 damage + knockback; explosions/fire still hurt) -> DIZZY (x2 damage).
- BANDLEADER (enemies/types/bandleader.gd): tuba player in a red marching coat, group "bandleaders". Stays behind the troupe (BACKOFF);
  puffs his cheeks (warning) and blasts you back (BLAST_R). Killing him makes nearby dancers lose the beat. TROUPES = bandleader + 4 diablos.
- BOSS SUPAY (enemies/types/supay.gd, also stage 33): the devil king (4 horns, crown, trident, red-black cape with a gold dragon). Leaps on the
  beat (landing next to you = STOMP_DMG), throws arcs of firework Rockets, "DANCE WITH ME!" summons 4 diablos around you (CIRCLE_CD).
  Stage 32: at ESCAPE_AT he becomes invulnerable and runs off to the volcano (the exit opens) -> stage 33.
- Mind control: BANDLEADER -> scream.

## Stage 33 - "SULFUR CRATER" ("THEY LEARNED THE FIRE") - sulfur mine on an active Andean volcano, region 4 level 6
(Story: SUPAY escaped the carnival in stage 32 and ran up here - this is the final fight with him.)
- levels/stage_33.gd + effects/s33_decor.gd: night, red-lit ash clouds with lightning inside the plume, black volcanic cones (one erupting,
  winding lava flows), the mine slope with glowing lava streams, stone huts, little blue sulfur flames and a rusty cableway with moving
  buckets; near: lava rocks, sulfur crust, rising steam. World: VolcGround (basalt, sulfur patches, glowing cracks), LavaPit (pits() =
  LAVA_PITS; extends the stage 21 SpikePit, burns zombies), Vent (fumarole hazard: blue sulfur flame ON_T / OFF_T with a bubbling warning),
  Shelter "REFUGIO" (group "shelters", SHELTERS + one in the boss arena), Hopper (wooden sulfur sorting tower, its deck = upper floor),
  Obstacle "sulfur_sacks" / "slag_cart" / "lava_rocks". AshFX: falling ash and embers, warning edges, the surge itself on screen.
- Volcano (group "volcano"): CALM (20-26s) -> WARN (4s: rumble, shaking, "TAKE COVER!") -> SURGE (3s of burning ash): every TICK the player
  and every zombie NOT inside a refugio takes damage. During WARN zombies within 700px of a refugio run into it (zombie.gd goal_x - a
  general "walk here and ignore the player" field, INF = normal); zombies right next to you keep fighting (even inside the hut).
- AZUFRERO (enemies/types/azufrero.gd): sulfur porter with a tall basket of sulfur above his head. Shots above the head / into his back /
  fire / explosions hit the basket (BASKET_HP) -> it ignites BLUE: he sprints at you as a torch and BURSTs (2 damage to you, 28 to zombies
  in BURST_R, blue fire on the ground). Ignite him inside a crowd.
- CINDER (enemies/types/cinder.gd): ash zombie with glowing cracks. Its "health" is ash (ASH_HP; real hp is huge). At 0 it collapses into a
  PILE with an ember Core (a small StaticBody on the zombie layer - bullets call Core.take_damage). It reforms after REFORM_T unless the core
  is shot, the pile is stepped on, or an explosion hits it. The ash surge doesn't hurt it (ash_proof) - it gets faster in it.
- SMOKER (enemies/types/smoker.gd): gas-mask worker with a smoke tank. Keeps distance and throws a Canister between you and the zombies
  coming at you -> SmokeCloud (drawn over everything, LIFE seconds) hides their approach. His tank bursts into a big cloud when he dies.
- BOSS SUPAY final (Game.level != 32): no escape; below RAGE_AT his cape burns with blue sulfur fire - landings leave blue fire, rockets
  become blue fireballs. He ignores the ash surges - you have to fight him between refugios.
- Region 4 names in game_state REGIONS: levels 31-33 = Floating Islands, Devil's Carnival, Sulfur Crater. Game.IMPLEMENTED = 33.


## Shared: REVIVER (enemies/types/reviver.gd) + group "corpses"
- zombie.gd _die(): every non-boss zombie that was not itself revived joins group "corpses" while its body lies there.
- REVIVER: necromancer with a blue crystal staff. Stays behind the others (FLEE_R), looks for a corpse within SEEK_R, walks to it and
  CHANNELs for REVIVE_T seconds (blue beam) -> the corpse rises as the same kind with meta "revived" and a ReviveAura child (orbiting blue
  motes + sparks). A revived zombie can not be revived again. Any damage during the ritual interrupts it (STUN). Kill healers first.
- Use it in later levels' zombie_weights() (Registry.REVIVER).

## Shared: STATIONARY BOSSES (enemies/stationary_boss.gd)
- Base for giant bosses that never move (from stage 34): extends zombie_type.gd. The boss turns to face you, think(pl, delta) picks the
  next attack, wind(name, t) shows a warning for t seconds and then calls attack(name, pl).
- fire_shot(from, target, speed, dmg, kind, col, r) = straight Shot (kinds: orb / nail / bolt / ball), fire_lob(from, target, flight, dmg,
  kind, blast_r, col, r) = arcing Lob (ice / rock / canister / beam / plasma), explodes with blast_r > 0.
- weak_rect() (local, unscaled, facing right): hits there x WEAK_MULT, the rest of the body x ARMOR_MULT (bullets / melee only).
- "THEY LEARN": lead grows with every miss (shots aim where you are going). can_see() = a waist-height ray to you; behind cover (within
  320px of it) the direct shots hit the cover, and after HIDE_LEARN seconds hidden learned_lob = true -> it lobs over cover.
  Standing right next to it (POUND_R) -> ground pound that throws you back.
- It stands EDGE px before the end of the level, and while you are near it the camera slides (shake_camera.gd frame_target)
  so the whole giant stays on screen.

## Stage 34 - "OBSERVATORY" ("THEY LEARNED TO WATCH") - Atacama desert observatories, Chile, region 4 level 7
- levels/stage_34.gd + effects/s34_decor.gd: night sky with the Milky Way, the Magellanic Clouds and shooting stars; far Andes with
  observatory domes firing yellow guide-star lasers; a radio-dish array; salt pillars and candelabra cacti. World: SaltGround, Dome
  (DOMES, the balcony at TIER is a hidden upper floor + ladder), Obstacle "flight_cases" / "rover" / "solar_rack". NightFX on screen.
- Trap GuideLaser (one in front of every dome): every CYCLE seconds a red dashed WARNING line (WARN_T), then the beam SWEEPs SPAN px
  of ground - hurts the player once per sweep, 12 damage to zombies.
- SPOTTER (enemies/types/spotter.gd): astronomer with a big search lamp. Keeps BACKOFF distance, locks the beam on you (LOCK_T) ->
  SPOTTED: every zombie within RALLY_R knows where you are and rushes you. Shoot the lamp (in his hand) to break it.
- PANEL (enemies/types/panel.gd): technician holding a hexagonal telescope mirror. Front bullets to the body / head bounce back at you
  (Reflect). Shoot the legs, from behind, or use explosives / fire; the mirror breaks after MIRROR_HP.
- TEAMS: PANEL in front, two zombies, a REVIVER behind them. SPOTTERs stand on the odd dome balconies.
- BOSS THE DISH (enemies/types/dish.gd, stationary): a giant fused with a radio dish. Weak point = the blue receiver crystal above its
  head. Attacks: burst (3 orbs, learns to lead), fan (FAN_N orbs - jump / duck between them), lob (plasma over cover once it learned
  you hide), pound.
- Game.IMPLEMENTED = 34.

## Stage 35 - "SKULL GLACIER" ("THEY LEARNED TO HIDE") - high Andean glacier (inspired by Aconcagua), region 4 level 8
- levels/stage_35.gd + effects/s35_decor.gd: cold bright day - white sun with a 22-degree ice halo and two sundogs, cirrus, sparkling
  "diamond dust"; snowy peaks with blue shadows and a glacier tongue; a blue serac wall with ice-cave arches, frozen waterfalls and a
  giant skull trapped in the ice; a field of penitentes and torn expedition flags. World: GlacierGround, IceShelf (SHELVES, upper floor at
  TIER + rope ladder; one more shelf in the boss arena), Obstacle "ice_cube" (something frozen inside) / "sled" / "old_tent". GlacierFX.
- Trap Icicles (under every shelf): walk under -> the icicle cracks (WARN_T) and falls (hurts you once, DMG_Z to zombies). Every icicle has
  a small body on the zombie layer: SHOOT an icicle and it drops on the zombies below. They regrow after REGROW_T.
- Trap GlareIce (GLARE): smooth shiny ice - player.slip_t: almost no grip, you slide (player.gd: slip_t, also slow_t = stuck in snow).
- ENCASED (enemies/types/encased.gd): a climber frozen in an ice block, next to ice blocks that are just decor (FROZEN_GROUPS). Remembers
  which side you came from; when you pass him it CRACKs and bursts out behind you. Standing next to it for NEAR_T also breaks it.
  The ice eats bullets (ICE_HP) - shatter it from range and he comes out DAZED (x1.5). Fire / explosions melt it at once.
- AXEMAN (enemies/types/axeman.gd): mountain guide with two ice axes. Keeps KEEP distance and throws a spinning Axe that flies out and comes
  back (hits on the way out AND back). With both axes in the air he runs and takes x1.4. Learns how you dodge: jump over an axe -> the
  next ones fly higher (aim_y), duck -> lower.
- AVALANCHER (enemies/types/avalancher.gd): big zombie with a pututu (conch horn). Blows it (BLOW_T, a head shot cuts it off) -> a snow
  Slide falls where you WILL be (your speed): shadow + trickle warning, then snow chunks -> 1 damage, slow_t (buried to the knees) and a
  snow pile that slows you for PILE_T. Zombies step out of the shadow.
- BOSS ICE TITAN (enemies/types/ice_titan.gd, stationary): giant buried to the waist in the glacier, skull head with an icicle crown, a blue
  heart inside an ice ribcage = weak point. breath (icicle fan), spikes (IceSpikes: a wave of ice spikes running along the ground - jump it
  or get on the shelf), boulder (ice lob, 3 over cover once it learned you hide), pound. GUARD_HITS heart hits within GUARD_WIN -> it covers
  the heart with its hand (GUARD_T) - the guard only drops while it winds up an attack: shoot the heart then.
- Game.IMPLEMENTED = 35.

## Stage 36 - "THE SUMMIT" ("THEY LEARNED TO WORSHIP") - Inca mountaintop sanctuary (inspired by Llullaillaco), region 4 level 9 (Andes finale)
- levels/stage_36.gd + effects/s36_decor.gd: stormy dusk - heavy violet clouds with lightning inside, a low red sunset band, a sea of
  clouds below with other peaks sticking out (lit from inside by lightning), Inca terraces and a chullpa burial tower on the slope,
  apachetas and frozen ichu grass. World: SummitGround, Terrace (polygonal Inca masonry, upper floor at TIER + steps), Obstacle
  "apacheta" / "offering" (altar with textile, gold and silver llamas) / "wall_stub". StormFX: diagonal snow + lightning flashes.
- Trap Storm (+ Strike): every CYCLE seconds lightning near you - a glowing circle with sparks is the WARN, then the bolt (1 damage +
  short daze, DMG_Z to zombies). Standing HIGH on a terrace -> the bolt is aimed exactly at you (where you are going). Quiet near the boss
  (quiet_from) - APU brings his own lightning.
- Trap Crumble (terraces in CRUMBLE_ON): loose stones in the middle of the terrace - stand on them HOLD_T and they fall (the floor there
  is gone for RESET_T).
- MALLKI (enemies/types/mallki.gd): Inca mummy bundle wrapped in WRAPS layers of textile. Bullets tear the layers (WRAP_HP each) before
  the body; each layer gone = faster. Not shot for REWRAP_T -> it wraps itself again. Fire burns all the cloth, explosions = 2 layers.
- GUARDIAN (enemies/types/guardian.gd): Inca warrior with a painted shield and a star mace. The shield covers HIGH or LOW; front hits
  there are BLOCKED. LEARN_HITS hits on the open half -> it moves the shield there. From behind / from above / explosions get through.
  Shield bash up close (no bite).
- QUIPU (enemies/types/quipu.gd, group "quipus"): record keeper with a knotted quipu. zombie.gd tells him about every bullet hit near
  him (observe). RECORD_N hits with one weapon -> he ties a knot (TIE_T, a hit cuts it) -> zombies in SHARE_R take x0.4 from that weapon
  (meta "resist_weapon", a KnotMark above their heads). Switch weapons or kill him - his knots unravel when he dies.
- BOSS APU (enemies/types/apu.gd, stationary): the mountain spirit on a stone throne - golden sun mask (weak point), gold staff, sling.
  sling (2 stones, lead), rocks (lob, 3 over cover once it learned), lightning (Strike on you + one on a side), pound. LEARNS which way
  you run from lightning (dodge, DODGE_LEARN) -> the second bolt waits on that side, plus a third further on.
- Boss HP: zombie.gd adds +400 to every boss after level 5, so stationary boss stats use ~300-400.
- Game.IMPLEMENTED = 36.

## Region 5 - SOUTHEAST (levels 37-45): the megacities. "They learned to use our machines."

## Stage 37 - "FAVELA HEIGHTS" ("THEY LEARNED OUR STREETS") - a Rio de Janeiro favela at sunset, region 5 level 1
(Story: after the Andes the hero comes down to the coast - Brazil's megacities.)
- levels/stage_37.gd + effects/s37_decor.gd: golden-pink sunset with kites (pipas) in the sky; Sugarloaf with its cable car and Corcovado
  with Christ the Redeemer, the bay with city lights; a hill of stacked colorful houses with lit windows, blue water tanks and wires;
  close facades with rebar and laundry lines. World: FavelaGround, Laje (brick or painted house, flat roof = upper floor at TIER + ladder),
  Obstacle "moto" (moto-taxi) / "trash_bags" / "bar_table" (boteco table + beer crates). FavelaFX: warm haze.
- Trap LiveWire ("gato" - stolen power line between two poles): sparks + yellow strip = WARN, then electric arcs to the street under the
  middle (hurts you once, DMG_Z to zombies). Shoot the junction box on the pole -> short circuit (20 to zombies near it), the wire is dead.
- Trap WaterTank (blue tank on every laje): shoot it HP times -> it tips, water washes zombies away (6 + knockback) and leaves a Puddle
  (group "puddles", LIFE). A LiveWire arc over a puddle electrifies the whole puddle (SHOCK_DMG). TANK_WIRE = roofs whose tank pours
  right under a live wire (the combo).
- KITE (enemies/types/kite.gd): pipa flyer with a glass-coated "cerol" line. Keeps KEEP distance, holds the kite over you; every DIVE_CD the
  kite whistles (WARN_T) and dives - the line slices through where you are (1 damage). Misses -> it leads you (lead). Shoot the kite
  (KiteBody, layer 4) -> LINE CUT, he becomes an angry normal zombie.
- CAPOEIRA (enemies/types/capoeira.gd): sees every shot you fire (zombie.gd on_player_fired -> type on_shot). A shot through him -> AU
  (cartwheel, no collision for AU_T) then a DODGE_CD; every shot he sees shortens it (DODGE_MIN) - he reads your rhythm. Hit him with a
  quick double tap, from closer than CLOSE, with explosives, or while he winds up his meia-lua kick (x1.3).
- GRAFFITI (enemies/types/graffiti.gd): keeps KEEP distance and waits for you to RELOAD (player.is_reloading) -> rushes in and sprays your
  face: PaintSplats (CanvasLayer over everything, BLIND_T) and every zombie in MARK_R knows where you are. Shoot the can while he sprays ->
  it pops (x2).
- BOSS O DONO DO MORRO (enemies/types/dono.gd, stationary) on the roof of the tall house at the end (main meta "boss_x"/"boss_y" - the stage
  decides where a stationary boss stands, stationary_boss.gd _place). burst (BURST_N rifle rounds, lead), rojao (fireworks lobbed over
  you, "rocket" Lob), pound if you climb up. DUCK_HITS head hits in DUCK_WIN -> he ducks behind the brick parapet (DUCK_T, bullets from
  below do nothing, he throws fireworks blind at your last spot) and stands up laughing with a burst ready.
- Game.IMPLEMENTED = 37.

## Stage 38 - "MEGACITY CORE" ("THEY LEARNED OUR MACHINES") - Sao Paulo at night in the drizzle (garoa), region 5 level 2
- levels/stage_38.gd + effects/s38_decor.gd: city-glow sky with helicopters (blinking lights, one with a searchlight), a dense skyline of
  lit towers with red antenna lights and the white wave of the Copan building; Avenida Paulista with the MASP (box on red beams), lit
  signs and a traffic jam of red tail lights; Minhocao pillars with pixacao tags. World: CityGround (wet asphalt, neon reflections),
  Overpass (raised concrete road = upper floor at TIER), Scaffold (the boss stands on it), Obstacle "taxi" / "barrier_jersey" / "kiosk".
  RainFX: drizzle + neon haze.
- Trap GlassTower (GLASS): a glass tower lobby. Stand under it -> the panel cracks (glint, WARN_T) -> glass rains down (RAIN_T, 1 damage,
  DMG_Z to zombies). Shoot the panel (GlassPanel, layer 4) to drop it on zombies. Broken glass stays on the street: walking on it CRUNCHES
  and every zombie in CRUNCH_R hears you.
- Trap Billboard (BOARDS): a hacked digital billboard - "LOOK" (eye + glitches, WARN_T) then a white flash: if you are aiming toward it
  (or standing under it) you are dazed DAZE_T. Not in the "hazards" group (no world_rect / danger_at).
- OFFICE (enemies/types/office.gd): office zombie with a phone. When you are busy (reloading / a zombie next to you / far from him) he
  CALLs (CALL_T) -> BACKUP_N runners arrive from behind you. Any hit drops the phone. MAX_CALLS calls.
- WASHER (enemies/types/washer.gd): window washer hanging HANG_H above the street on a rope (no collision while hanging, x1.5), drips a
  slippery Soap puddle (player.slip_t). Swings toward you, and when you walk under him (DROP_R) he drops on you (1 damage + daze).
- COURIER (enemies/types/courier.gd): fast motoboy with a delivery box. Runs to where you WILL be (your speed x LEAD_T) and leaves a
  Package (FUSE beeps, explodes, or at once when you come within PROX). Shoot a package to blow it up on the zombies around it. PACKAGES.
- BOSS THE TOWER (enemies/types/tower.gd, stationary) on the scaffold: a giant crane operator fused with a tower crane - jib, trolley,
  hook and an I-beam. nails (NAIL_N nail-gun burst, lead), drop (the trolley rolls over you and releases the beam - "beam" Lob, a new beam
  after BEAM_RELOAD), pound. LEARNS a heat map of where you stand (BUCKET px, real time) - after LEARN_T it knows your favorite spot and
  every second beam falls there. Hard hat: head hits x0.35 until HAT_HP hits knock it off.
- Game.IMPLEMENTED = 38.

## Stage 39 - "THE STADIUM" ("THEY LEARNED THE GAME") - the Maracana on a match night, region 5 level 3
- levels/stage_39.gd + effects/s39_decor.gd: night sky with floodlight glow, drifting red/green flare smoke and fireworks; the far stand
  with the white ring roof and rows of floodlights, thousands of jumping zombie fans (colored dots), giant flags and burning flares;
  LED boards around the pitch with cameramen. World: TrackGround (red running track, then striped grass for the last GRASS_FROM px),
  Stand (near stand: seat rows full of zombie fans + the upper walkway = upper floor at TIER), Goal (behind the boss), Obstacle
  "ad_board" / "bench" / "cooler". StadiumFX: confetti (stops at the ground).
- The crowd - CrowdHype ("THE 12TH MAN", one per Stand, group "crowds"): a CAPO stands on the walkway with a megaphone and a big drum
  (drawn x CAPO_SCALE so he stands out), and a CROWD HYPE meter hangs above the stand. Hype rises GAIN/s while you fight within NEAR of
  the stand and +KILL_GAIN for every zombie you kill near it (Game.story "zkill"); it decays when you leave. The drum beats faster as
  hype rises. 100% = PITCH INVASION: banner, roar, INVASION_FANS fans (runners in team shirts, group "crowd_fans", at most MAX_FANS alive)
  hop the railing and drop through the walkway onto the track, and FLARES burning flares land around you (small fire zones). Then a
  COOLDOWN and hype climbs again more slowly (MAX_INVASIONS per stand). Shoot the CAPO (CAPO_HP, hitbox CapoBody on layer 4) -> the stand
  goes QUIET for good. THEY LEARN: once one capo is down (main meta "capos_down"), the others duck behind the drum whenever your aim
  points at them (AIM_COS) - the drum soaks the shots (DRUM_HP). Break the drum, or come from the side / flick-shoot.
- Trap Floodlight (LIGHTS): a light tower sweeping its beam along the track. Get caught in the light -> every zombie in ALERT_R knows
  where you are and rushes you.
- HOOLIGAN (enemies/types/hooligan.gd): torcida fan with a lit flare. Throws it BEHIND you (the side away from him) -> FlareFire on the
  ground (BURN_T) cuts off your retreat. With CHANT_N zombies around him he chants "OLE OLE OLE" -> they all rush. Shoot the flare in
  his raised hand -> it burns him.
- STRIKER (enemies/types/striker.gd): number 9. Keeps KEEP distance and kicks a Ball. The Ball is a real CharacterBody2D
  (move_and_collide, mask 1|16): it bounces on the real floor, platforms and obstacle tops, stops at walls, rolls to a stop and fades
  (REST_T / LIFE). (Old bug: it used an invisible floor at the kicker's height, so balls kicked from the walkway floated in mid-air.)
  If the ball is blocked by cover he learns to CHIP it over (lob). Shoot the ball -> it homes straight back at him through obstacles
  (OWN GOAL: 10 damage + stun).
- REFEREE (enemies/types/referee.gd): counts every shot you fire near him (on_shot). FOUL_N shots -> whistle (a hit cuts it) -> YELLOW
  card: your gun is jammed YELLOW_T (player.jam_t - grenades and specials still work). Second card = RED: jammed RED_T.
- BOSS GOALKEEPER (enemies/types/goalkeeper.gd, stationary) in the goal at the end of the grass. punt (2 burning balls, lead), throw
  ("football" Lob, 3 over cover once it learned), pound. READS YOUR AIM: keep your crosshair on his head SAVE_T -> he raises his gloves
  (SAVE_HOLD) and head shots are SAVED. Snap-aim and shoot, or shoot while he winds up a kick / throw.
- player.gd: jam_t (stage 39). menu.gd: the practice buttons wrap into two rows when there are more than 24 levels.
- Game.IMPLEMENTED = 39.

## THE EMPIRE OF THE DEAD (levels 40-45, region 5 levels 4-9)
Story: after the Maracana the hero follows them to the coast - they are not a horde any more. They wear uniforms, hold ranks and fly red
flags, and they all work for one goal: to conquer the world.
- enemies/empire_kit.gd (shared): the emblem is an OUROBOROS (an ancient serpent eating its own tail) around a skull, black on a white
  disc on a red flag - an original symbol for the game (deliberately not any real-world political symbol). emblem / flag / banner /
  armband / helmet drawing, soldier() = the shared uniformed body (helmet / officer cap / gas mask, red armband, red eyes), rifle(),
  fire() = a soldier's bullet (stationary_boss Shot), order(z, kind, r) = an order to every member of group "empire" in range
  (type.on_order(kind, from)), clear_shot().
- "THEY LEARN TOGETHER": squad_aim_y(main) is one aim height shared by every rifleman in the level. A bullet that misses because you
  jumped -> all of them aim higher; because you ducked -> all of them aim lower (Tracker -> squad_miss).
- zombie.gd: meta "morale_t" (FLAGBEARER) -> x0.6 damage while it lasts.

## Stage 40 - "HARBOR OF WAR" ("THEY LEARNED TO OBEY") - the Port of Santos at dawn, region 5 level 4
- levels/stage_40.gd + effects/s40_decor.gd: dawn over the harbor with funnel smoke, the Serra do Mar, Santos' famous leaning buildings,
  warships with red flags; gantry cranes with red banners, container stacks, a cargo ship with tanks on deck; bollards and chains.
  World: QuayGround, ContainerStack (upper floor at TIER + ladder, the emblem sprayed on), Obstacle "drum_pile" / "cargo_crate" /
  "bollard". HarborFX: sea fog.
- Trap SwingBox (SWINGS): a container swinging on a crane cable at body height (pendulum PERIOD / AMP) - knocks you away, DMG_Z to zombies.
- Trap BarbWire (WIRES): slow + 1 damage per TICK while you walk through; jump over it.
- CONSCRIPT (enemies/types/conscript.gd): rifleman. Line of sight + RANGE -> AIM_T (glint) -> shot. Orders: volley / charge /
  leaderless (confused) / broken.
- OFFICER (enemies/types/officer.gd, "IMPERIAL OFFICER"): stays KEEP behind. "VOLLEY!" (whistle) when you are in the open and he has
  VOLLEY_MIN riflemen, "CHARGE!" when you reload, pistol shots. His death -> "leaderless" for every soldier in ORDER_R.
- FLAGBEARER (enemies/types/flagbearer.gd): the empire flag on a pole - empire soldiers within AURA_R take x0.6 damage. Shoot the pole /
  flag (above his head) FLAG_HP times -> the flag falls, the protection is gone at once and the soldiers around are "broken".
  While the flag is up he FIGHTS WITH IT (aggression 0.45): CHOP - swings the pole back (WIND_T) and slams it down in front
  (CHOP_REACH) - step back out of reach. THRUST - lowers the pole like a spear and lunges (THRUST_REACH, LUNGE_V) at chest height
  (THRUST_PIVOT y -44: passes over a crouching player) - jump or crouch. THEY LEARN YOUR DODGE: stepped back from a CHOP -> next is a
  THRUST; jumped / crouched under a THRUST -> back to CHOP. A hit keeps the same attack. The pole is hit-tested as a segment
  (_pole_hits); the flag cloth is drawn on the swinging pole (pole_pose()).
- SQUADS: 3 conscripts in front, a flagbearer in the middle (every other squad), the officer behind.
- BOSS BEHEMOTH (enemies/types/behemoth.gd, stationary tank): the commander in the hatch is the weak point (he ducks for DUCK_T after
  each cannon shot). shell = "BRACKETING": the first shell lands FIRST_ERR short or long, every next one halves the error while you stay
  within MOVE_RESET of the last spot ("ON TARGET") - move and he starts a new bracket. mg = MG_N bullet burst. pound = point-blank shot.
- stationary_boss.gd Lob: new "shell" look.
- Game.IMPLEMENTED = 40. Region 5 level names: Harbor of War, The Parade, Metro Barracks, War Factory, The Dam, The Red Palace.

## Stage 41 - "THE PARADE" ("THEY LEARNED TO MARCH") - Brasilia at dusk, region 5 level 5
- levels/stage_41.gd + effects/s41_decor.gd: the National Congress (twin towers, dome and bowl) wrapped in red banners, the Cathedral's
  crown, a giant flag mast, searchlights and red-white salute fireworks; ministry blocks with banners and marching troop silhouettes;
  lamp posts with flags. World: AvenueGround, ReviewStand (stepped stand with a red drape; upper floor at TIER + 2 ladders),
  Obstacle "crowd_barrier" / "planter" / "drum_stack". ParadeFX: red-white ticker tape.
- EmperorBalloon (one over every stand, group "balloons"): a giant parade balloon of the Emperor's crowned skull, HEIGHT above the
  avenue, on 3 long ropes held by 3 CONSCRIPT handlers (spawned in extra_spawns, driven by goal_x) who march BEHIND it on the side away
  from you (OFFS). It follows you (ROAM, ROPE_MAX) and drops bombs (BOMB_CD, Boom.blast BOMB_R) that fall to YOUR level (ground or the
  stand walkway); a red ring shows every landing spot. THEY LEARN YOUR STEP: it remembers where you dodged to (dodge) - after 1 dodge
  it drops a pair (on you + where you ran last time), after 2 a fan of three. Extra bombs never land on its own handlers; the main bomb
  can be lured onto them. Shoot it HP times -> it deflates, spins and crashes (CRASH_R, CRASH_DMG to zombies under it). Kill 2 handlers
  -> it breaks free and floats away. (Replaced the old TankColumn trap.)
- Every empire type obeys goal_x first (no aiming / lunging / shouting while it walks to an ordered spot).
- ai/zombie_brain.gd: a zombie that is already inside a danger zone keeps walking out (it used to freeze at the edge).
- HonorGuard (GUARDS, group "honor_guards"): a podium with a sergeant (sabre) and 3 ceremonial riflemen (red tunics, plumed helmets),
  hitboxes GuardBody on layer 4. Every VOLLEY_CD: "PRESENT... FIRE!" - a harmless salute volley into the sky. THEY LEARN TO AIM: come
  within NOTICE_R, fire near them or hit one of them -> hostile: "AIM!" with red aim lines at head height (AIM_Y -42), the aim locks
  LOCK_T before "FIRE!" -> 3 real shots (stationary_boss Shot). Crouch under the line (or use cover). Kill the sergeant (SERGEANT_HP) ->
  no more orders, the guard stands still. Each dead rifleman = one shot less. (Replaced the old SaluteGun trap.)
- zombie.gd: meta "drum_t" (DRUMMER) -> x1.3 move speed while it lasts. player.gd daze(t, msg) - the message is now a parameter.
- game_state.gd: a kill by a trap ("hazard" / "tank") far away is not tagged LONG SHOT.
- DRUMMER (enemies/types/drummer.gd): beats every BEAT -> every empire soldier within DRUM_R marches x1.3. You reload -> "DRUM ROLL!"
  (charge order). The drum in front of his belly soaks bullets: DRUM_HP hits break it (no more beat, he gets angry and runs).
  Killing him with the drum intact -> "broken" for the soldiers around.
- GUARDSMAN (enemies/types/guardsman.gd): honor guard - shako, white cross belts, bayonet. Below half HP he swaps with a healthy guard
  within SWAP_R (he falls back with goal_x, the partner gets "cover_me" and rushes). Bayonet LUNGE (LUNGE_WIND glint -> dash).
  "THEY LEARN TOGETHER": dodge a lunge by jumping / ducking -> every guard in the level thrusts high / low from now on (main meta
  "guard_lunge").
- PROPAGANDIST (enemies/types/propagandist.gd): keeps KEEP away. "SURRENDER!" - you in the cone in front of him within SHOUT_R -> daze
  DAZE_T, every zombie within CALL_R is alerted. You crouch for HIDE_T -> "THERE HE IS!": empire soldiers within CALL_R rush you.
  Shoot the loudspeaker horn above his head HORN_HP times -> FEEDBACK: he goes silent and the soldiers around are "broken".
- Squads: 2 guards in front, 2 riflemen, a drummer in the middle, a propagandist / officer behind. On the stands: rifleman + guard.
- BOSS THE MARSHAL (enemies/types/marshal.gd, stationary on his review stand, main metas boss_x / boss_y / boss_ground_y):
  bulletproof glass on the parade side (GLASS_HP hits, explosions count 2) - break it or flank him from behind on the stand.
  barrage = "ARTILLERY!": red smoke marks your spot, after MARK_T shells fall from the sky around it. Dodge one -> the next barrage is wider
  (up to 5 shells) and shifted toward where you ran (_lean); get hit -> back to 3. pistol = PISTOL_N burst. kneel = "KNEEL!" at close
  range: knockback + daze. Below half HP -> "GUARD!": GUARD_N guardsmen appear on the avenue and every empire soldier charges.
- Game.IMPLEMENTED = 41.

## Stage 42 - "METRO BARRACKS" ("THEY LEARNED TO DIG IN") - the Brasilia metro turned into a barracks, region 5 level 6
- levels/stage_42.gd + effects/s42_decor.gd: underground station - concrete ceiling with flickering fluorescent tubes, a geometric
  blue-white tile wall in the style of Athos Bulcao (Brasilia's tile artist), tunnel mouths with red signals, "CENTRAL" sign, bunk beds,
  rifle racks, "OBEY" posters, columns with hanging cables. World: PlatformGround (yellow safety line + track bed), Mezzanine (upper
  floor at TIER + 2 ladders), Obstacle "bunk" / "footlocker" / "rack". MetroFX: dust + flicker.
- Trap MGNest (NESTS, faces left): sandbag nest + machine gun. Manned by an empire soldier (goal_x to gun_spot, meta "manning"); kill
  the gunner and the nearest soldier within RECRUIT_R runs to "MAN THE GUN!". BURST bullets via E.fire (shared squad aim learning).
  AMMO rounds then RELOAD_T - unless a LOADER brings a box (refill()).
- Trap Tripwire (WIRES): step on the wire -> click -> FUSE -> blast. Jump over it, crouch on it DISARM_T to disarm, or shoot the grenade
  (a tiny body on layer 4 with hit_by_bullet) to set it off from afar. Empire soldiers never trigger them; plain zombies do.
- FirePatch: burning napalm (damage tick to you, ignites zombies; FLAMERs have meta "fireproof"). delay > 0 = a canister falls first.
- Sandbags: a wall a PIONEER builds (build() over BUILD_T, solid + cover only when done, HP, repair(), blastable). Shooting walls down
  counts main meta "walls_lost".
- LOADER (enemies/types/loader.gd): runs to empty MG nests and refills them; hands out magazines (meta "supply_t" -> conscripts fire
  twice as fast, conscript.gd); keeps KEEP away. Shoot the crate stack above his head CRATE_HP times -> ammo cook-off (blast).
- FLAMER (enemies/types/flamer.gd): pilot light (WIND_T) -> flame cone SPRAY_T (damage, ignites, leaves a FirePatch). "THEY LEARN
  TOGETHER - CUT OFF": you retreat while he closes in -> main meta "flamer_kite"; after KITE_LEARN retreats every flamer throws a napalm
  canister behind you as you run. Shoot the nozzle while he sprays (or blast him) -> BACKFIRE.
- PIONEER (enemies/types/pioneer.gd; ENGINEER is an older type): you shoot at his squad in the open -> runs AHEAD and builds a sandbag
  wall ("DIG IN!"), up to MAX_WALLS; repairs damaged walls nearby. "THEY LEARN TOGETHER": WALLS_LEARN walls shot down -> every pioneer
  adds steel plates (double HP, "STEEL PLATES!").
- Every empire type obeys goal_x first; zombie.gd: a zombie walking to an ordered spot (goal_x) now jumps obstacles like a chasing one.
- BOSS ARMORED TRAIN (enemies/types/armored_train.gd, stationary locomotive): weak point = the driver's window. shell (turret lob), mg
  burst - accurate while the headlight is on; shoot the headlight LIGHT_HP times -> it fires blind. "THEY LEARN": then it fires FLAREs
  near you - while you stand within FLARE_R of a burning flare it is accurate again. "ALL OUT!" every TROOP_CD when few soldiers are
  near: TROOP_N riflemen jump out of the door. pound = steam blast.
- Lesson: a freed node is not always == null in Godot 4 - check is_instance_valid(x) directly.
- Game.IMPLEMENTED = 42.
- FIX (stationary_boss.gd): zombie.gd's hit box is 38*wf wide and 66*sc tall, so a bullet stops at the box edge, not inside the drawing.
  That made the Dish's weak point (above the box) and the Behemoth's commander (behind the front face) impossible to hit with real
  bullets. Now: hit_size() (default = tall enough to include weak_rect; the ARMORED TRAIN overrides it to cover the whole locomotive),
  and in_weak() also accepts a hit on the box's side face at the weak point's height (weak_on_face() - override false for a weak point
  that is not the front-most thing at its height). Checked with real rays for every stationary boss (levels 34-42).

## Stage 43 - "WAR FACTORY" ("THEY LEARNED TO BUILD") - the Volta Redonda steel works, region 5 level 7
- levels/stage_43.gd + effects/s43_decor.gd: hazy orange sky with sparks, blast furnaces and chimneys over the Paraiba river, an assembly
  hall with a saw-tooth roof and tank hulls hanging from cranes, red banners, steel girders with chains and hooks. World: FactoryGround,
  Catwalk (upper floor at TIER; a higher one at BOSS_TIER over the boss), Obstacle "steel_coil" / "parts_bin" / "road_wheel".
  FactoryFX: sparks + heat haze.
- Trap Conveyor (LINES: [place, width, dir]): moves you (SPEED) and zombies along.
- Trap Press (one in the middle of every conveyor): up -> WARN_T (red lamp + steam hiss) -> slam: DMG to you, DMG_Z to zombies -> rises.
  rush() = "PRESS NOW!" from a FOREMAN with a short RUSH_WARN. Dodging a rushed press counts main meta "press_dodge".
- WELDER (enemies/types/welder.gd): finds the most damaged empire unit in SEEK_R (the boss counts in hit points) and welds HEAL per TICK.
  Mask down while welding = headshots blocked. Aim at him while he welds (within FLASH_R) -> ARC FLASH daze. Kill him while he walks.
- TANKETTE (enemies/types/tankette.gd): one-man tank. Front hits x FRONT_MULT, rear hits x REAR_MULT, explosions full. Stops and turns
  slowly (TURN_T) - jump over it. "THEY LEARN TOGETHER": rear hits on FLANK_LEARN tankettes -> all keep KEEP_LEARNED away and turn in
  TURN_LEARNED. MG bursts (E.fire), rams when touching.
- FOREMAN (enemies/types/foreman.gd): keeps KEEP away. "OFF THE LINE!" every LINE_CD: a conscript comes off the nearest conveyor
  (up to CREW_MAX alive). "PRESS NOW!" when you stand under a press; after 2 dodged rushes (press_dodge) he gives even less warning.
  His death -> his crew is "leaderless".
- stationary_boss.gd: can_turn() (default true).
- BOSS PROTOTYPE (enemies/types/prototype.gd): an unfinished super-tank bolted to the line - it CAN'T TURN (always faces left).
  Weak point = the open glowing engine on the rear deck: hit it from the catwalk above the rear or from the floor behind it
  (hit_size covers the whole tank, in_weak also counts top hits above the deck). twin = two shells: the first at you, the second where
  you dodge - "THEY LEARN YOUR DODGE": DODGE_LEARN more dodges to one side -> the second shell lands there. mg burst. Behind it the guns
  can't reach you - "COOLANT!" steam blast from the engine. "SEND THE WELDERS!" every WELD_CD when damaged and fewer than WELDERS_MAX:
  welders walk up and repair it. Checked with real rays: engine = hit from the catwalk and from behind, armor from the front.
- Game.IMPLEMENTED = 43.

## Stage 44 - "THE DAM" ("THEY LEARNED THE SKY") - the Itaipu dam on the Parana river, region 5 level 8
- levels/stage_44.gd + effects/s44_decor.gd: misty sky with transport planes dropping paratroopers, the green Parana valley with
  high-voltage pylons, the dam face (buttresses, penstocks, a spillway chute with white water), the crest parapet with lamps.
  World: CrestGround, Gantry (yellow gantry crane = upper floor at TIER + 2 ladders; one more near the boss), Obstacle "jersey" /
  "cable_drum" / "valve". DamFX: spray and mist.
- Trap Surge (one around every gantry, SURGE_W): floodgates open - siren + orange lights (WARN_T) -> a wave washes the section (PUSH,
  DMG to you, DMG_Z to zombies). Empire soldiers walk out EARLY seconds before the siren (goal_x). Climb the gantry.
- Trap Transformer (POWER): hums, charges (CHARGE_T, sparks, ring) then arcs to everything within R (damage + short daze). It is solid
  cover too; shooting it while idle makes it discharge early.
- DropZone (DROPS): when you pass it a plane drops N PARATROOPERs behind you (opposite your aim).
- stationary_boss.gd: floats() (default false) - a floating boss skips gravity.
- PARATROOPER (enemies/types/paratrooper.gd): meta "drop" -> starts DROP_H up, steers its chute to the side you are NOT facing.
  In the air it takes AIR_MULT damage. "THEY LEARN TOGETHER - HALO": HALO_LEARN paratroopers shot in the air -> later ones free-fall
  and open the chute only HALO_OPEN above the ground. On the ground: short SMG bursts.
- MORTARMAN (enemies/types/mortarman.gd): keeps KEEP away, sets up (SETUP_T), lobs shells (FLIGHT, whistle). Packs up when you come
  within PACK_R. "THEY LEARN YOUR HIDING SPOTS - TOGETHER": a cover you crouched behind for HIDE_T goes into main meta
  "known_covers"; at a known cover every mortar fires at once with FAST_FLIGHT.
- STORMTROOPER (enemies/types/stormtrooper.gd): elite assault (gas mask, leather coat, SMG bursts). Sees you shoot at him (on_shot) ->
  rolls (ROLL_T, bullets miss). "THEY LEARN YOUR RHYTHM": every roll shortens the roll cooldown of all stormtroopers (main meta
  "storm_seen", down to ROLL_MIN). You crouch behind cover -> "FLUSH HIM OUT!" grenade behind it.
- BOSS RED ZEPPELIN (enemies/types/red_zeppelin.gd, floating at BOSS_ALT): weak point = the gondola underneath (shoot from below or from
  the gantry). bombs = a carpet of BOMB_N bombs around you; "THEY LEARN WHERE YOU RUN": the next carpet is shifted toward where you ran
  from the last one (run_bias). mg burst. "JUMP! JUMP!" - JUMP_N paratroopers when few soldiers are near.
- Game.IMPLEMENTED = 44.

## Stage 45 - "THE RED PALACE" ("THEY LEARNED YOUR TRICKS") - the Imperial Palace of Petropolis, region 5 level 9 (the end of the Empire)
- levels/stage_45.gd + effects/s45_decor.gd: red dusk with a moon, the Serra dos Orgaos with the "Finger of God" peak, Petropolis'
  gothic cathedral, the neoclassical summer palace of Brazil's emperors painted red (columns, lit arched windows, giant banners,
  imperial palms), a hydrangea garden with an iron fence. World: PalaceGround (stone + red carpet), Balcony (upper floor at TIER +
  2 ladders), Throne (the dais at the end: floor at DAIS + 2 ladders, giant curtain with the emblem), Obstacle "statue" / "urn" /
  "hedge". PalaceFX: red petals + ash.
- Trap Brazier (BRAZIERS): embers flare (WARN_T) -> a ring of fire R for FLARE_T (damage ticks to you, ignites zombies).
- Trap HangingBanner (BANNERS): a giant banner on a rope over the path. Stand under it -> creak (WARN_T) -> it falls (DMG / DMG_Z).
  The rope is a small body on layer 4 - shoot it to drop the banner on zombies.
- empire_kit.gd: leader_down() / leaders_killed() - officer, flagbearer, drummer and commissar deaths are counted (main meta).
  conscript.gd: new order "rally" (a confused conscript goes back to the fight).
- PRAETORIAN (enemies/types/praetorian.gd): tower shield that blocks bullets from the angle it guards - "front" or "high" (shots coming
  down, dir.y > HIGH_DY). "THEY LEARN YOUR ANGLE - TOGETHER": the last ANGLE_MEMORY shots at any praetorian (main meta "pr_shots") decide
  the shield for all of them - switch angles. Spear thrust opens the shield for a moment; explosions ignore it.
- COMMISSAR (enemies/types/commissar.gd): rallies confused soldiers ("NO RETREAT!"), takes command (VOLLEY) when no officer is near.
  "THEY LEARNED YOU KILL THE LEADERS FIRST": KEEP grows with leaders_killed, and he hides behind praetorians.
- HERALD (enemies/types/herald.gd): hears every shot (on_shot). BURST_SHOTS shots in BURST_T -> "BY ORDER OF THE EMPEROR!": empire
  soldiers within DECREE_R take x0.6 damage for DECREE_T (longer each time). Rallies confused soldiers. His death breaks the decree.
- BOSS THE EMPEROR (enemies/types/emperor.gd, on the throne dais): weak point = the head. bolts = a fan of BOLT_N fireballs aimed at the
  height the whole empire learned from your dodges (squad_aim_y). "GUARDS!" calls praetorians; while one is within GUARD_R he takes
  GUARD_MULT damage. Below half: crown boomerang (while it flies the bare head takes CROWNLESS_MULT), "FOR THE EMPIRE!" (rally + charge),
  faster bolts. His death: "THE EMPIRE FALLS" - every empire soldier is broken.
- Game.IMPLEMENTED = 45.

## Performance pass: many zombies on screen
Measured with a headless profiler (60 zombies around the player, fixed 60 fps, CPU only). Rules for new code:
* **Particles are batched**: `Particles.burst()` no longer creates a node per burst. All bursts on one parent go into a single
  layer node (`particles.gd`, parent meta `_particle_layer`, cap `MAX_P`) that draws only what is on screen and sleeps when empty.
* **Gore caps**: burn ticks (`source == "fire"`) don't spray blood or FleshFx. `effects/flesh_fx.gd` allows at most `MAX_SPRAYS`
  live sprays (lite mode from half of that).
* **Zombie drawing**: redraw rate adapts to how many zombies are visible (`_maybe_redraw`: every 2nd frame for 1-3 zombies, every
  6th for 33+; movement itself stays smooth). `Zombie.crowded()` (more than 14 visible) drops tiny head details and fingers.
  `Art.limb()` takes `cap_start`/`cap_end` so joined limb segments don't draw hidden circles; `Art.oval_shaded()` caches its
  per-vertex shading colors; `Art.on_screen()` caches the visible rect once per frame.
* **Zombie brain** (`ai/zombie_brain.gd`) steers every other frame (alternating slots, double delta); in between, the zombie keeps
  the last direction and speed ratio. Hazard scan every 4 frames, crowd spacing every 8.
* **No full-group scans every frame**: empire commanders (OFFICER, COMMISSAR, HERALD) re-check their troops at most ~4 times a
  second when they have no order to give. Do the same in new types: a timer, not a per-frame `get_nodes_in_group` loop.
* Enemy `Shot`s (stationary bosses) only redraw on screen and die 1500 px from the player. Bullets build their damage
  dictionary only when they hit something.
* Profiling hooks: `zombie.gd` has `static var prof_on` / `prof` - set `prof_on = true` and read `prof` (µs per kind for logic and
  draw) to find the expensive zombie types.

### One draw call per zombie (`effects/draw_batch.gd`)
In Godot 4, every `draw_circle` / `draw_colored_polygon` / `draw_polyline` / `draw_arc` / thick `draw_line` is its own draw call.
A zombie used ~120 of them, so 20 zombies cost more than the whole level. Same fix as the gravity grenade black hole: collect
all triangles and send them in ONE `RenderingServer.canvas_item_add_triangle_array` call.
* `DrawBatch.begin(self)` ... `DrawBatch.end(self)` around a `_draw()` (zombie.gd does it). Between them, `DrawBatch.circle(self, ...)`,
  `.colored_polygon`, `.polygon`, `.polyline`, `.arc`, `.line`, `.rect`, `.set_transform` take the same parameters as Godot's
  `draw_*` (plus the canvas item first) and are only recorded. Outside a begin/end they just call the normal `draw_*`.
* Textures and text (`.texture_rect`, `.string`, `.string_outline`) can't go in the batch: they flush, draw natively, carry on.
* EVERY script now does this: `func _draw()` is a 3-line wrapper (begin, `_draw_b()`, end) and the real drawing is in
  `_draw_b()`. All `draw_*` calls go through `DrawBatch.*` (same parameters, canvas item first). Ready-made triangle arrays:
  `DrawBatch.tris(ci, pts, cols)` (not `RenderingServer.canvas_item_add_triangle_array`, which would draw out of order).
  New code: write `func _draw_b()` + the wrapper, and `DrawBatch.circle(self, ...)`, never a bare `draw_circle(...)`
  inside a batched `_draw` (it would land under everything). `DrawBatch.ENABLED = false` switches batching off.
* Not batched on purpose: hud.gd, weapon_wheel.gd, rain.gd (rects / text / thin lines that Godot already merges; batching
  them only cost CPU). Result: ~300 draw calls per frame on every level (was 650-2,140).
* Antialiased polylines get a 1 px fading edge strip (`FEATHER`); `Art.disc`/`oval` draw a soft outline ring the same way.
* Redraw less: the parallax backdrop redraws every 2nd frame even at full quality (sky every 4th; `Quality.BG_EVERY`),
  the HUD and the weapon bar every 2nd frame unless something is animating. The backdrop is still the biggest CPU cost
  (~1.7 ms per frame); caching its layers would be the next step.

### No stutter on kills
* **Text never animates its font size.** Every new (font size, outline) pair makes Godot rasterize new glyphs and upload a texture
  (the HEADSHOT! stamp did that every frame for ~12 frames). Draw at a fixed size and scale with `draw_set_transform`:
  `ui/kill_streak.gd` (`FONT_SIZES` buckets + `_prewarm`), zombie.gd `HitText` (`FS`), hud.gd level title.
* **Blood spray shader warms up at level start.** The first CPUParticles2D spray compiled a GPU shader (~0.2 s freeze on the first
  kill). main.gd calls `FleshFx.prewarm()`: 0.4 s in, three almost invisible sprays in the middle of the screen.

### Smooth motion on fast monitors (`effects/smooth_motion.gd`)
Physics runs 60 times a second. On a 120/144 Hz screen there are 2-3 frames per physics step, so the player, zombies and bullets
jumped every 2nd-3rd frame and the camera (following the player) scrolled unevenly. `physics/common/physics_interpolation` is on
(project.godot, jitter fix 0): Godot draws those objects between their last two physics positions every frame.
* Only things that move in `_physics_process` are interpolated: `SmoothMotion.MOVERS` (player, zombie + Orb/EnemyShot, survivor,
  bullet, grenade, rocket, molotov, debris, severed leg, blood drop, acid, pickup). The root window is OFF (game_state.gd), so
  everything else (UI, decor, effects moved in `_process`) draws exactly as before. Children of a mover are OFF too (they still
  follow the parent's smoothed position); Light2D children keep the parent's setting.
* main.gd connects `SceneTree.node_added` -> `SmoothMotion.on_node_added`, which sets the mode and calls
  `reset_physics_interpolation` deferred (after the spawner set the position, so nothing streaks in from (0,0)).
* The camera follows the smoothed player: player.gd `_process` passes the offset to `shake_camera.follow_smooth()`
  (player processes before its child camera, so the scroll uses this frame's offset). Jumps over 200 px are not smoothed.
* Something new that moves in `_physics_process`? Add its script to `MOVERS`. Something you teleport? Call
  `reset_physics_interpolation()` after moving it.
* Measured (headless, 144 FPS, level 1 running right): frame-to-frame change of the scroll step 0.31 px -> 0.05 px.

## Fire (effects/flame_fx.gd)
Shared flame drawing for every fire: `tongue()` (teardrop flame tongue, 3-4 colour layers, swaying tip), `puff()` (a bit of flame
that breaks off and rises), `glow()` (soft radial texture - no hard-edged discs), `additive()` (light blend for glow children),
PALETTE (orange) and BLUE.
* environment/fire_zone.gd (Molotov / TORCH bottles / barrels / SUPAY / crowd flares): scorched fuel puddle, a continuous burning bed,
  overlapping flame tongues, puffs, soft smoke, embers and a light pool (child _Light, additive). Ignite flare -> burn -> fade (FADE_T).
  It fits itself to the ground under it on the first frame, so it never burns in the air over a pit or past a ledge. A blue modulate
  (b > 1, SUPAY / AZUFRERO) switches to the BLUE palette.
* fire.gd (small fires on wrecks / props): same look, smaller. zombie.gd `_draw_burning()`: real flames on burning zombies.
* TORCH: head / shoulder flames and the bottle's burning rag use the same tongues.
* Fires redraw 30x/s (20x/s at quality level 2+): about 0.13 ms per fire on screen.

## Auto quality (quality.gd, autoload `Quality`)
Watches the real frame rate. A 1-second average under ~52 FPS steps effects down one level (two levels under ~39 FPS);
8 seconds above ~58 FPS steps one level back up (the wait doubles if it had to drop again right after rising).
Targets follow the screen refresh rate when it is below 60 Hz. Loading hitches, pauses and the first 2.5 s of a scene are ignored.
Only looks change: zombie damage, speed and intelligence stay the same (off-screen zombies just think less often).

**Blood and gore** (blood drops, flesh chunks, blood sprays, "hit" blood particles) are full at level 0 and cut by 35% from
level 1 on (`Quality.gore()`, table `GORE`): fewer per hit and lower caps on how many live at once. Ragdoll corpses and
torn-cheek wounds never change. Non-gore effects scale more:

| Level | What changes |
|---|---|
| 0 | everything full |
| 1 | smoke / sparks / dust particles x0.7 (30% less), zombies redraw 1 frame less often, simplified zombie drawing above 8 on screen, background redraws every 2nd frame, rain/ash x0.7 |
| 2 | smoke / sparks / dust x0.5 (50% less), damage numbers only for head hits, simplified zombie drawing always, background every 3rd frame, rain/ash x0.45, off-screen zombies think 15x/s instead of 30x/s |
| 3 | smoke / sparks / dust x0.3 (70% less), no damage numbers, background every 4th frame, rain/ash x0.3 |

* **Lag spikes** (user request 2026-10-17: cut particles 30-70% only when the game actually slows): besides the 1 s average,
  every frame slower than `SPIKE_K` (1.7) x the target frame time counts; `SPIKE_N` (6) such frames inside one window step down
  a level at once (`Quality.spikes` counts these). Level 0 stays full, so a smooth game never loses particles.
* Pause menu (ESC): **EFFECTS: AUTO / HIGH / LOW** (saved in settings.cfg). HIGH = always level 0, LOW = always level 3.
* **F3** shows FPS and the current level in the bottom-left corner.
* The background (`effects/parallax_backdrop.gd`) draws each layer in its own node. Between redraws a layer just moves with the
  camera, so scrolling stays smooth; it redraws at once if the camera moved more than `MAX_SHIFT` px.
* New non-gore effects should ask `Quality` (`particles()`, `ambient()`, `Quality.scaled(n, mult)`). New gore asks `Quality.gore()`.
* `effects/collision_outlines.gd` now redraws only when a body changes (moves, breaks, opens) or the camera moved 200 px.

## Screen kick when firing
Every shot jolts the camera a few pixels opposite to the barrel and springs back (~0.13 s): shake_camera.gd `fire_kick(dir, px)` -
a damped spring (kick_stiffness, kick_damping, kick_max), not a random shake, so rapid fire stays readable (SMG averages ~1 px).
player.gd `_screen_kick(rk)`: px = SCREEN_KICK_BASE + SCREEN_KICK_PER_RECOIL * the weapon's "recoil" (weapon_db), capped at
SCREEN_KICK_MAX; recoil >= SCREEN_KICK_HEAVY (shotgun, launcher, rocket) also gets a short shake. Measured peaks: pistol 2.3 px,
SMG 2.4, assault rifle 2.6, rifle 3.2, sniper 3.7, shotgun 7.1. Set SCREEN_KICK_BASE and SCREEN_KICK_PER_RECOIL to 0 to turn it off.

## Hit reactions (where the bullet lands)
A zombie that survives a hit reacts for a moment, by zone (zombie.gd `_start_react`, `REACT_TIME`): **head** = the head snaps
back and the face tips up (0.28 s), **body** = it doubles over and clutches its belly (0.38 s, slows to 60%), **leg** = it hops
on the other leg with the hit leg lifted (0.5 s, slows to 40%). Only bullet / melee / taser / laser hits; not explosions, fire
or metal. Strength = weapon "knockback" (`_react_push`, 0.8-1.6); big zombies x0.6, bosses x0.35. A head reaction is not
overridden by a body/leg hit right after it. Kinds 0-19 bend their joints in `_draw_body`; type modules (20+) get a whole-body
tilt / hop through `begin_draw` (`react_tilt()`, `react_hop()`). Runner/screamer bend less (their vest polygon flips otherwise).

## Region 6 - SOUTHERN CONE (levels 46-54): "They learned to plan."
Each level brings 3 new zombie types; the boss is a giant variant of the level's first type (chase_range > 600, like KRAKEN).
Game.IMPLEMENTED = 57 (levels 52-57 below the Stage 51 section).

## Stage 46 - "WINE VALLEY" ("THEY LEARNED THE BLADE") - Mendoza vineyards at harvest dusk, region 6 (SOUTHERN CONE) level 1
- levels/stage_46.gd + effects/s46_decor.gd: dusk sky with long flat sunset clouds, low sun and condors; far layer (0.06) = the snowy Andes
  with Aconcagua (pink alpenglow, a cloud cap drifting over the peak); mid layer (0.28) = hills, swaying poplar rows, adobe bodegas with
  flickering arched windows, chimney smoke and a stone bell tower; near layer (0.6) = vineyard rows (posts, wires, autumn leaves and
  grape clusters swaying). World: VineyardGround, Pergola (grape pergola = upper floor at TIER + 2 ladders, ammo/health on top),
  BodegaGate (stone arch "BODEGA LA MUERTE" behind the boss), Obstacle "casks" / "bins" / "press" (custom_gen skips reserved spots
  with free_x - main.gd's generator does not check _rects). HarvestFX: falling vine leaves + warm haze.
- Trap BarrelStack (STACKS): barrels on a ramp. You come within RANGE in front of it -> creak (0.6 s) -> a RollingBarrel rolls at you
  (jump it; it crushes zombies for DMG_Z and smashes into wine on walls). Shoot the wedge (layer-4 body) to release one early. 6 barrels.
- Trap FermentVat (VATS): every CYCLE hisses (WARN_T) then vents a heavy CO2 cloud for CLOUD_T - inside it you are dazed ("CO2 FUMES").
  Solid cover. Each bullet raises the pressure gauge; VAT_HP hits -> it bursts: wine wave, DMG_Z to zombies within BLAST_R, DMG to you if close.
- EXECUTIONER (enemies/types/executioner.gd): hooded headsman with a sword longer than he is tall, tip dragging on the ground in front.
  The flat of the blade blocks body shots from the front ("CLANG"); head, back and legs are open. SLAM = sword raised high -> lands
  where you stood (crack + shake), then the blade is STUCK in the ground for STUCK_T (x STUCK_MULT damage). SWEEP = sword drawn back
  low -> sweeps the ground (jump). "THEY LEARN HOW YOU DODGE": jumped sweeps -> slam_bias up ("HE WON'T SWING LOW AGAIN");
  stepped out of slams -> lunge grows by LUNGE_STEP up to LUNGE_MAX (he steps into the swing) and more sweeps ("HE READS YOUR STEP").
- HARVESTER (enemies/types/harvester.gd): grape picker with a sickle on a chain. Keeps KEEP away, spins the chain overhead (WIND_T),
  throws the Sickle. Hooked -> the chain drags you to him (PULL_V, max PULL_MAX) and he slashes. Shoot the chain (a layer-4 body that
  follows the chain) -> "CHAIN CUT": unarmed for REARM_T. "THEY LEARN YOUR TIMING": jumped over it -> aims higher ("HE AIMS HIGH");
  ran out of range -> leads you more ("HE LEADS YOU"). Own line-of-sight check (_los) because the brain doesn't run while physics() moves him.
- CASK (enemies/types/cask.gd): a big winery worker stuck in a wine barrel. The barrel (BARREL_HP) takes body hits (splinters);
  head and legs are open; explosions hit the barrel double. Barrel broken -> wine spray, FREE_SPEED faster, FREE_MULT damage taken.
  ROLL: at ROLL_R distance he tucks in (TUCK_T, shaking) and rolls at you (ROLL_V) - jump over. "THEY LEARN YOUR JUMP - TOGETHER":
  jumps over any rolling cask count in main meta "cask_jumps"; after JUMP_LEARN every cask BOUNCEs right when it reaches you
  ("THEY BOUNCE NOW") - roll or run instead.
- BOSS THE HEADSMAN = EXECUTIONER with chase_range > 600: x1.75 size, faster wind-up, SLAM sends a Shockwave both ways along the
  floor (jump it, WAVE_V / WAVE_RANGE), shorter stuck time, 45% chance of a two-swing combo (SWEEP then SLAM or the other way).
- Game.IMPLEMENTED = 48 (levels 46-48 = SOUTHERN CONE levels 1-3).

## Stage 47 - "PAMPAS STORM" ("THEY LEARNED TO WRESTLE") - Argentine pampas estancia in an endless thunderstorm, region 6 (SOUTHERN CONE) level 2
- levels/stage_47.gd + effects/s47_decor.gd: green-grey storm sky, fast clouds that light up with each flash (StormFX.flash_k);
  far layer (0.06) = flat horizon with anvil storm cells, translucent slanted rain curtains and ground-touching bolts; mid layer (0.28)
  = white estancia casco (tile roof, arches), swaying ombu trees, spinning windmills, grazing dead cows, fence; near layer (0.62) =
  waving pampas-grass plumes and wire-fence posts. World: PampaGround, Galpon (tin barn "LA ULTIMA" with a hay loft = upper floor at
  TIER + 2 ladders, ammo/health on top; GALPONS), Corral (cow skulls, EL TORO's arena at level_w-1100), Obstacle "bale" / "trough" /
  "carreta", Mud (MUD, slows). StormFX (screen layer, group "storm"): flash every PERIOD 8-11 s with WARN 1.4 s of rumble first,
  rain scaled by Quality.ambient(), emits Game.story "thunder"; warning() / flashing() / time_to_flash() are read by the traps.
- Trap Windmill (WINDMILLS, platform = small upper floor at MILL_TIER): during the storm warning the tower glows with blue St Elmo's
  fire; on the flash the bolt hits the nearest windmill (player within ACTIVE_R): platform + circle R around the base -> DMG to you,
  DMG_Z to zombies. The lofts are the safe high ground; the mill platforms are NOT.
- Trap Stampede (STAMPEDES): you come within 260 px -> "STAMPEDE! GET UP HIGH" (WARN_T 2.2) -> a herd of HERD dead cows runs across
  at SPEED. On the ground = DMG + knockback; stand higher than SAFE_H (obstacle / loft / platform) and it passes under you. Tramples
  zombies for DMG_Z.
- TORO (enemies/types/toro.gd): hunched bull-man (horns, tattered poncho, coin belt, gorilla arms). PAW (scrapes the ground) ->
  CHARGE at CHARGE_V; contact = grabbed: lifts you overhead (pl.grab - mash A/D to break free) for HOLD_T, then THROWS you
  (THROW_V, THROW_DMG). Close by he does a short REACH grab. Charging into an obstacle/wall = STUN_T (x STUN_MULT damage).
  "THEY LEARNED TO WRESTLE": jumped his charge -> he leaps and grabs high ("HE READS YOUR JUMP"); rolled past -> turns and
  re-charges at once ("HE TURNS ON A DIME"); mashed free -> holds shorter and throws faster ("HE THROWS FASTER").
- BOLEADOR (enemies/types/boleador.gd): gaucho (wide hat, striped poncho, red sash). Keeps KEEP away (backs off inside BACKOFF),
  spins bolas overhead (SPIN_T) and throws them in an arc (BOLA_V). Hit = TANGLED for TANGLE_T (a Tangle node is your grabbed_by -
  mash A/D). The bola is a layer-4 body: shoot it out of the air. Shared learning (main meta): running away -> "bola_lead" grows by
  LEAD_STEP up to LEAD_MAX ("THEY LEAD YOUR RUN"); jumping it -> "bola_high" ("THEY THROW HIGH"). They stand on the lofts.
- STORMCALLER (enemies/types/stormcaller.gd): soaked black poncho, Lichtenberg scars, quiver of iron rods. Throws a rod (Javelin)
  that sticks in the ground as a PlantedRod (layer 4, ROD_HP): CHARGE_T with a warning circle R + climbing sparks -> lightning
  (DMG / Z_DMG); stays live LIVE_T and re-strikes every RESTRIKE. Max MAX_LIVE rods at once, RODS in the quiver. Out of rods or
  under 50% hp -> CALL: lightning strikes himself -> CHARGED for 7 s (x1.7 speed, x0.75 damage taken, shock on touch, telegraphed
  arc ARC_R) then regains 2 rods. Shared learning: escaping circles -> "storm_lead" (plants ahead of your run, "THEY PLANT WHERE YOU
  RUN"); shot 2+ rods -> "storm_rods_shot" (plants two, on both sides, "THEY PLANT TWO"). One near each windmill after the first.
- Boss EL TORO (toro.gd, chase_range > 600): "EL TORO - JUMP HIS CHARGE", hp 560, scale 2.45. Double charge, throws you high
  (BOSS_THROW), SLAM leap -> shockwave both ways (jump it); hitting the corral wall also sends a wave.
- Spawns: zombie_weights BOLEADOR .08 / STORMCALLER .05 / TORO .025; extra_spawns: 2 boleadors per loft, stormcaller per mill,
  TORO at 0.24 / 0.5 / 0.7. Sounds pm_zap / pm_rumble (stage) + type sounds. Music level1_total_war.
- To change: GALPONS, TIER, WINDMILLS, MILL_TIER, STAMPEDES, MUD, HARDER, zombie_weights(); trap consts in s47_decor.gd
  (Windmill R/DMG, Stampede WARN_T/SPEED/HERD/SAFE_H, StormFX PERIOD/WARN); type consts at the top of each type file.
- Tests (headless, attempt_seed 4747): 1800 frames, no script errors; TORO grab+throw (~450 px, 2 dmg), jump/roll learned, wall stun;
  boss grab/high throw/slam; boleador throws + tangles; stormcaller rod strikes, call, charged shocks; windmill strike hits on
  platform; stampede hits a grounded player.

## Stage 48 - "OLD QUARTER" ("THEY LEARNED STEEL") - La Boca / San Telmo, Buenos Aires, region 6 level 3 (the Southern Cone)
- levels/stage_48.gd + effects/s48_decor.gd: night over Buenos Aires. Three parallax layers moving at different speeds:
  far_city (0.06: skyline, the Obelisk, the La Boca transporter bridge with a moving gondola, port cranes, ships sailing the
  Riachuelo), mid_houses (0.28: colourful corrugated-iron conventillos, flickering windows, laundry swaying on lines) and
  near_street (0.6: three-arm iron lamps, fileteado signs TANGO/BOCA/CAFE/MILONGA, tango couple silhouettes, a bandoneon player).
  oq_sky = stars + moon. World: CobbleGround (cobbles + tram rails), Conventillo (house with an iron balcony = upper floor at TIER +
  2 ladders, WALKWAYS), TangoStage ("CAMINITO" stage before the boss arena: floor at STAGE_TIER, painted house fronts, string lights),
  Obstacle "kiosk" / "cart" (choripan cart) / "planter". QuarterFX: river mist + moths around the lamps.
- Trap Tram (TRAMS): a bell (oq_bell, WARN_T) and then a tram rushes along a stretch of street (SPEED, LEN). DMG to you, DMG_Z crushes
  zombies. Climb to a balcony or double jump. CYCLE between runs.
- Trap SparkWire (WIRES): a torn tram cable dangling into a puddle. It crackles (WARN_T, oq_crackle) and then discharges over the whole
  puddle (R) for ZAP_T. It shocks you and DMG_Z hits zombies too - lure them in.
- IRONARMS (enemies/types/ironarms.gd): a dock worker someone fitted with two robotic gun arms. Keeps distance (KEEP), aims (AIM) and
  fires VOLLEY_N bolts; every CHARGE_EVERY volleys a charged shot that blasts (BLAST_DMG). Each arm has its own HP (ARM_HP) and a hit
  band on the body: bullets from the front that hit the band hit the ARM (metal ping, sparks) and do not hurt the zombie. Shoot both
  arms off (they fall as pieces) -> it goes RAGE and charges (RAGE_SPEED). One arm left -> fires slower (ONE_ARM_SLOW). Explosions
  damage all arms. "THEY LEARNED STEEL": shared learning in main meta - "ia_lead"/"ia_aim_y" (missed shots after you jump raise the
  aim and the lead, after you crouch lower it), "ia_cover" (shots blocked by cover; at COVER_LEARN they lob arcs over cover).
- TANGO (enemies/types/tango.gd): always a pair (man + woman; setup spawns the partner, static _spawning guard). They move in a
  step-step-pause rhythm and stay close (PAIR_GAP). A shot that would hit -> they spin (SPIN_T, collision_layer 0 = bullets pass) with
  DODGE_CHANCE. "THEY LEARNED YOUR RHYTHM": the gap between your shots (main meta "tango_beat") sets the spin cooldown (spin_cd) - fire
  in an uneven rhythm. Gancho kick up close (KICK_R). One partner dies -> the other "breaks its heart": +1 damage, x RAGE_SPEED, no
  more spins.
- CLOCKWORK (enemies/types/clockwork.gd): a porcelain-masked wind-up doll with a brass key in its back. Runs in bursts (BURST_T x
  BURST_MULT) while the wind drains (WIND_DRAIN); at zero it STOPS and is vulnerable (STOP_MULT damage) while it rewinds (REWIND_T).
  A wound clockwork within HELP_R walks over and winds it twice as fast. Shoot the key from behind (KEY_HP) -> HAYWIRE: fast erratic
  running, damage 2, it hurts itself (HAYWIRE_DPS) until it breaks. "THEY WIND UP OUT OF SIGHT": hits taken while stopped (main meta
  "cw_stop_hits") at STOP_LEARN -> clockworks retreat to rewind when the wind is low (RETREAT_AT).
- BOSS THE MACHINIST (ironarms.gd boss variant, chase_range > 600): four arms (BOSS_ARMS: 2 guns + 2 rocket pods, BOSS_ARM_HP each),
  BOSS_VOLLEY_N barrage, rockets every ROCKET_CD (lobbed, blast), all of the ironarms learning. Below half HP with an arm missing ->
  REBUILD once (REBUILD_T, takes x0.5 damage meanwhile, arms come back). With no arms left after the rebuild -> RAGE.
- To tune: WALKWAYS, TIER, TRAMS, WIRES, TANGOS, STAGE_W, zombie_weights() in stage_48.gd; Tram / SparkWire constants in s48_decor.gd.
- Game.IMPLEMENTED = 48.

## Stage 49 - "RIVER DELTA" ("THEY LEARNED TO BREATHE WATER") - the Tigre / Parana delta on a foggy morning, region 6 (SOUTHERN CONE) level 4
- levels/stage_49.gd + effects/s49_decor.gd: pale foggy morning sky with a hazy sun disc, slow fog bands and herons; far layer (0.06) =
  the wide brown river, low islands with poplars and weeping willows, a ferry crossing slowly; mid layer (0.28) = colourful stilt houses,
  a Tudor-style rowing club, boats bobbing on the water; near layer (0.6) = reeds swaying, red ceibo flowers, mooring posts and floating
  debris drifting. World: DeltaGround (plank boardwalk over mud), StiltDeck (STILTS: verandas of stilt houses = upper floor at TIER,
  2 ladders each, ammo/health on top), Channel (CHANNELS: open water cutting the boardwalk, you wade = slower), RowingClub
  ("CLUB DE REMO" behind the boss), Obstacle "wreck" (a beached boat) / "crates" / "nets" (custom_gen skips reserved spots with free_x).
  DeltaFX: fog bands, mosquito swarms, green river tint.
- Trap SinkingDock (DOCKS): rotten planks. Step on one -> creak + "!" (WARN_T) -> it snaps: DMG to you, SLOW_T stuck in the mud
  ("STUCK IN THE MUD"), DMG_Z to zombies standing on it. After that it is a water hole (TideDirector treats it as water).
- Trap TideDirector ("THE RIVER RISES"): every CYCLE seconds (first one after 18 s) - "THE RIVER IS RISING - GET HIGH!" (WARN_T), the water
  rises H px over the whole boardwalk for HIGH_T, then falls (FALL_T). Owns player.in_water (channels, broken docks, high tide) and sets
  main meta "tide" (0..1) - FLOATER floats faster, ANGLER swims under water to you. Climb a stilt deck or an obstacle to stay dry.
- FLOATER (enemies/types/floater.gd): a drowned body bloated with river gas (Last of Us bloater / police-diver "floaters"). Every belly hit
  swells it (SWELL_PER); full belly or death = pops into a toxic GasCloud (hurts + dazes you "TOXIC GAS", GAS_DMG_Z to other zombies,
  floaters immune). Next to you (SELF_R) it swells itself (SELF_T, green glow + gurgle) and pops. Faster in the tide (TIDE_SPEED).
  "THEY LEARN WHERE TO WALK - TOGETHER": popped from far (> FAR_D) counts in main meta "floater_far"; after HIDE_LEARN every floater
  walks behind another zombie ("THEY HIDE BEHIND THE OTHERS") so you can't pop it early without hitting the crowd.
- ANGLER (enemies/types/angler.gd): a hunched fisherman with a bone rod growing from his back and a glowing "luz mala" lantern hanging in
  front of his needle-toothed mouth. Waits submerged in a channel (LURK - only hat and eyes above water; body shots just SPLASH, only the
  eye band is open). You come within SPRING_R -> the lantern swings (SWING_T) -> he leaps at you (LEAP_V), grabs and drags you (DRAG_T,
  DRAG_V, shake free A/D) then bites. Shoot the lantern (layer-4 body) -> "BLINDED" for BLIND_T, takes BLIND_MULT damage, no more lurking.
  "THEY LEARN THE LIGHT GIVES THEM AWAY": after DARK_LEARN lanterns shot (main meta "lures_shot") lanterns stay dark until you are within
  DARK_R and swing faster (SWING_T_DARK) - "THE LIGHTS GO DARK".
- SPOREWALKER (enemies/types/sporewalker.gd): a corpse overgrown by the delta's damp - mushroom caps on head and shoulder, shelf fungi on
  the back, white mycelium, glowing spores (Cordyceps). Close to you (PUFF_R) it swells (PUFF_WIND) and puffs a SporeCloud: slow
  (slow_t) + blur (daze "SPORES"); shooting it point-blank (HIT_PUFF_D) also bursts a small puff. On death a Stalk grows from the corpse
  (layer-4 body + "blastable"): shoot it STALK_HP times ("CUT") or blow/burn it ("BURNED") within GROW_T, or it blooms - raises up to
  RAISE_MAX corpses within RAISE_R ("RISE!") or, with no corpses around, spawns 1-2 hungry runners ("HUNGRY!"). Killed while burning
  (fire bullets / explosion) = no stalk at all. "THEY CHOOSE WHERE TO DIE": after LEARN_CUT stalks cut (main meta "spore_cut") a hurt
  sporewalker (< SEEK_HP) walks to the nearest corpse (SEEK_R) to die there, and stalks grow faster (GROW_T_LEARNED) and raise one more.
- BOSS THE RIVER MOTHER = FLOATER with chase_range > 600: x2 size, doesn't self-pop; belly hits do BELLY_MULT. Spits GasBubbles in an arc
  (SPIT_CD, a small gas cloud where they land), belches up to BELCH_MAX little floaters (BELCH_CD), below half HP a GAS WAVE around her
  (WAVE_WARN then a WAVE_R cloud, every WAVE_CD). Dies in a huge gas cloud - step back.
- Spawns (extra_spawns): SQUADS of FLOATER + walker + 1-2 SPOREWALKERs, an ANGLER in every channel past x 900, a SPOREWALKER on every deck.

## Stage 50 – "TANGO CEMETERY" ("THEY LEARNED TO PULL THE STRINGS")

Recoleta at night. Files: `levels/stage_50.gd`, `effects/s50_decor.gd`, `enemies/types/puppeteer.gd`, `lobizon.gd`, `coffin_breaker.gd`.

**Level** (`stage_50.gd`): `MAUSOLEUMS` (3 roofs at `TIER` 150, 2 ladders each, ammo/health on top) are the upper floor. Traps: `ANGELS` (AngelStatue) and `CRYPTS` (CryptDoor). Obstacles: grave / sarcophagus / urn (`custom_gen`, checked with `free_x`). `COFFINS` are coffin spawns (one sits on a roof). `SQUADS` alternate between a puppeteer with 3 dolls and a lobizon with a walker. Boss: `Registry.PUPPETEER` in front of the RecoletaGate. Music: `level2_suspense.mp3`. The `rc_*` sounds are in `SOUNDS`.

**Moon** (`s50_decor.gd` MoonCycle, group `moon_cycle`): clouds (`CLOUD_T` 14-19 s), then a warning "THE CLOUDS ARE PARTING..." (`WARN_T` 3 s, howl), then "FULL MOON" (`FULL_T` 11 s). Shared through statics `S50.moon_k` (visual 0..1), `moon_warn` and `full_now` (gameplay, flips instantly). Use `S50.moon_full()` / `moon_rising()`. MoonFX draws the darkness, silver light, ground fog and banners. `force(state, t)` is for tests.

**Decor**: `cem_sky` (moon and a cloud bank that slides off), `far_city` 0.06 (skyline, Basilica del Pilar with a swinging bell, bats), `mid_tombs` 0.28 (mausoleum rows, candles, fog), `near_cypress` 0.6 (cypresses, iron fence, cats with glowing eyes). Inner classes reach the statics through `const S50 := preload(self)`.

**PUPPETEER**: strings up to `MAX_STRINGS` 3 zombies (boss 6) within `STRING_R`. Each string is `StringCut` (StaticBody2D, layer 4, mask 0, `hit_by_bullet`) on the middle of the string, so shooting the string cuts it. Puppets get `_speed_mul × PUPPET_SPEED` and meta `puppet`/`pp_mul`. JERK (`JERK_CD`, `JERK_WIND` telegraph: bar pulled back, strings flare) makes all the puppets lunge together. A strung puppet that dies is re-raised once (`REVIVES`, boss 3): "DANCE AGAIN!". A puppet farther than `STRING_MAX` slips off. He moves on his own and holds `HOLD_R` from you. When he dies, all strings snap and puppets stagger for `SNAP_STUN`. Learning: main meta `pp_cuts` ≥ `CUT_LEARN` gives double strings (2 hits each) and a faster re-string. Boss "THE BOKOR": `WHIP` (0.5 s windup, `WHIP_R`) and `SUMMON_CD` (raises 2 strung dolls).

**LOBIZON**: slow human under the clouds. It starts the TURN (howl, `TURN_T`) when the moon is about to be full. As a WOLF it gets leaps, a 2-hit claw combo, `REGEN` and `WOLF_MULT` armour. It REVERTS (×1.5 damage) when the clouds return. Learning: if you sit up high during a full moon for `ABOVE_LEARN` s, it sets main meta `lobizon_climb` and every lobizon leaps onto roofs. Without a MoonCycle it uses its own cycle (`OWN_CYCLE`).

**COFFIN BREAKER**: its own state machine, not `dormant`. The coffin hitbox is small and absorbs bullets. Approaching (`HINT_R`) gives faint scratches. `WAKE_R` triggers SCRATCH (`WARN_T`, lid jumps, fingers), then it bursts and leaves a CoffinBox. If you are close it keeps the lid as a front shield (`LID_HP`). It throws the lid (LidShot) if you are past `THROW_R` / `FLEE_R` or up high. GRAB (mash A/D) bites every `BITE_T`; on release it is stunned. Shooting a closed coffin early opens it early with no shield. Learning: main meta `cb_early` ≥ `EARLY_LEARN` makes later coffins patient: they ignore shots, stay silent, wait until you pass (`PASS_D`), then burst out behind you ("BEHIND YOU").

## Stage 51 - "THE RANCH" (THEY LEARNED TO HERD)

Zone 6 (Southern Cone), stage 6. An Argentine estancia ("La Patrona") at blazing summer noon: white sun, dust, dead quiet.
The dead gauchos still work the land - they ride, keep bees and brand cattle. Now they brand *you*.

**Files**
- `levels/stage_51.gd` - layout, spawns, sounds (`rn_creak`, `rn_pour`, `rn_bellow`).
- `effects/s51_decor.gd` - sky + 3 parallax layers + all world objects / traps.
- `enemies/types/rider.gd` - RIDER (also the boss, EL PATRON).
- `enemies/types/beekeeper.gd` - BEEKEEPER (+ `Swarm`, `HoneyPuddle`).
- `enemies/types/brander.gd` - BRANDER (+ `Brand`, the mark on the player).

**Background (Backdrop)** - `ranch_sky` (white-blue noon sky, sun with turning rays, circling vultures),
`far_plain` 0.06 (heat-shimmer horizon, mirage band, eucalyptus line, distant dust of a dead herd),
`mid_casco` 0.28 (the casco with gallery + green shutters, Australian windmills + round tank, barn, silos, waving flag),
`near_fence` 0.6 (wire fence, swaying purple thistles, rolling tumbleweeds, cattle skulls). All layers animate on `t`.
Screen FX: `S17.HeatHaze` shader + dust particles + `RanchFX` (dust motes scaled by `Quality.ambient()`, a dust gust every 12-18 s, warm glare).

**Layout / upper floor**
- `TOWERS` - wooden water towers. Their deck is an invisible `add_floor` with 2 ladders, and each holds a pickup.
- `SILOS` - grain silos with a catwalk (floor + ladder + pickup). A `GrainChute` trap sits next to each one.
- Riders can't climb, so a deck is safe from the horse. The rider circles underneath and waits.
- `CHUTES` (steer trap), `TROUGHS` (8 + 1 in the arena), `ASADO` (smoke), `BEES`, `COOPS`.
- `DomaArena` (boss) at `level_w - 1100`.
- Obstacles `bales` / `drums` / `tractor` come from `custom_gen` and skip reserved spots.
- `extra_spawns`:
  - a regular zombie on every deck
  - a beekeeper by each set of bee boxes
  - a brander guarding every 2nd trough
  - 3 riders in the open

**Traps**
- `GrainChute`: walk under the pipe and it creaks (`WARN_T`), then pours grain (`POUR_T`).
  - The pour does damage + slow to the player and buries zombies (`DMG_Z`).
  - It leaves a slowing pile (`PILE_T`).
  - Shooting the red hatch triggers it on your timing.
- `Chute`: approach and the gate shakes (`WARN_T`), then a dead steer (`Steer`) runs down the road toward you.
  - Jump it or roll. It tramples zombies too, and collapses on a wall.
  - It has HP (`STEER_HP`). Shooting the latch opens the gate early.
- `Trough` (group `troughs`): stand in it to wash off a brand. `AsadoPit` (group `smoke_src`, `SMOKE_R`): its smoke disperses bee swarms.
- `Decor.smoky(tree, p)` returns true for asado smoke or any fire hazard (`fire_zone` with `zombie_burn`) within 150 px.

**RIDER** - a dead gaucho on a dead horse.
- **TROT:** approaches. If you're too close it backs off to build a run-up. The horse leaps bales and drums.
- **WIND:** a telegraph, with a neigh and the facón raised.
- **CHARGE** (`CHARGE_V`) through you plus `OVERSHOOT`:
  - The horse tramples (`TRAMPLE_DMG`).
  - A jump that's too low gets cut by the facón (`SLASH_DMG`).
  - Ramming a wall or obstacle makes it **STUMBLE** (damage x`STUMBLE_MULT`).
- **Two HP pools:**
  - Hits at horse height (local y > -36) go to `horse_hp`.
  - Hits on the rider are re-mapped so a head is a head and a torso is a torso.
  - Explosions and fire hit both.
  - When the horse dies a `HorseCorpse` stays on the ground and the rider is thrown (`THROWN_T`). He then fights on foot with his own HP, with a smaller hitbox resized at runtime.
- **Learns:**
  - Jump a charge once (`JUMP_LEARN`) and the next charge stops right in front of you and **REARS**: the hooves strike high and catch jumpers. Then it keeps charging.
  - Counter: roll through it or back off.

**EL PATRON** (boss, `chase_range > 600`, `boss_name` "EL PATRON - SHOOT THE HORSE"):
- **The horse:** armored (`HORSE_ARMOR` on bullets; explosions do full damage). While mounted the rider takes x`RIDER_GUARD`.
- **LASSO** (`LASSO_WIND`):
  - The loop flies at you.
  - If caught you are dragged (`DRAG_V`) straight into a rear-up hoof strike.
  - Shooting the rope cuts it (the `Rope` body on layer 4 has `hit_by_bullet`).
- **CALL:** whistles for 2 riders at `CALL_AT` hp fractions, up to 4 riders alive.
- **STAMPEDE:** under 60% hp, every 2nd charge brings `STAMPEDE_N` dead steers (`s51_decor.Steer`) alongside.
- **On foot:** faster, still throws the lasso, and always hunts.

**BEEKEEPER** - a ragged beekeeper whose body is a hive, with a big hive box strapped to his back.
- Keeps distance (`KEEP_R`). **RELEASE** (`RELEASE_T`, loud buzz) lets out a `Swarm`.
- **The swarm:**
  - It has HP (`SWARM_HP`); bullets do 6 or the gun's fixed damage. It chases you and stings (`STING_DMG` every `STING_T`).
  - It is dispersed by: smoke (asado, fire), explosions (it is in group `blastable`), incendiary bullets, or a burning zombie nearby.
  - Cover stops it: horizontal moves are ray-checked on mask 1.
- **The hive:**
  - Shots from behind, or above the head, hit the hive (`HIVE_HP`).
  - Breaking it splashes a `HoneyPuddle` that slows you and releases one ANGRY swarm (faster, more HP).
  - After that the beekeeper has no more swarms and goes berserk.
- **Learns:** once its swarm has been stuck behind your cover for `BLOCK_LEARN` seconds, swarms go wide. They climb over the cover and come down on you from the other side ("THEY LEARN YOUR COVER").

**BRANDER** - a heavy gaucho in a scorched leather apron with a red-hot "P" branding iron.
- **AIM** (`AIM_T`, sizzle, glowing tip), then **THRUST** (`THRUST_T`), then **RECOVER**.
- A hit does damage and puts a `Brand` node on the player (`BRAND_T`). Brands stack up to `BRAND_MAX`.
- **While branded:**
  - Every `HERD_EVERY` seconds, every zombie within `HERD_R` gets `_alert_t`, `_rush_t` and `brain.seen_t = 0` / `last_seen`, so the whole herd converges ("THE HERD KNOWS YOU").
  - Standing in a trough washes the brand off and bumps the `brand_washes` meta on main.
- **Learns:** once you've washed a brand, branders guard the water. When you're branded or near a trough, they stand between you and the nearest trough (`GUARD_R`).
- Test helper: `apply_brand(player, t)` is static.

**Tunables** - in each file header. Stage: `TOWERS`, `TIER`, `SILOS`, `SILO_TIER`, `CHUTES`, `TROUGHS`, `ASADO`, `BEES`, `zombie_weights()`
(BRANDER 0.07, BEEKEEPER 0.05, RIDER 0.03, regulars 0.52, runners 0.33).

## Region 6 story (levels 52-54): THE ARCHITECT
Inspired by zombie comics and sci-fi books (named in each zombie's section). The dead move SOUTH on purpose, run by one mind, THE ARCHITECT
(boss of 54, giant SHEPHERD). Living traitors (QUISLING, 52) walk among them in dead skin and serve him. 52: they board the trains south.
53: they besiege Montevideo and he sends a PURSUER after the hero by name. 54: the hero arms the charges and kills him - his whole herd
drops, the bridge falls ("THE REST ALREADY CROSSED" -> Patagonia, "They learned to think").
* Story scenes: `story/scenes/l52_quisling.gd` (x 1300, the quisling pulls his mask off - action `mask_off` - and names the Architect)
  and `story/scenes/l54_stranger.gd` (x 8250 in the clear stretch 6750-8750 before the gate; the STRANGER's third visit: "you're the
  only one of us... who forgot"). Any scene action story_scene.gd doesn't know goes to `stage.on_story_beat(id)` (54: wind / herd_roar /
  lamps_out / charges_beep). Voices: devtools/story_voices.py + story_voices_master.py.

## Stage 52 - "RAIL YARD" (THEY LEARNED THE TIMETABLE)

Zone 6 (Southern Cone), stage 7. The huge freight yard on the edge of Buenos Aires (Remedios de Escalada workshops / Retiro freight yard).
Orange smog dusk that slowly turns into a sodium-lit evening. The dead are boarding the freight trains south, on schedule.
Some of the dead are breathing: living QUISLINGS in dead-skin masks walk inside the herds. They serve THE ARCHITECT (boss of 54).

**Files**
- `levels/stage_52.gd` - layout, spawns, sounds (`sw_bell`, `sw_roll`, `lw_buzz`).
- `effects/s52_decor.gd` - sky + 3 parallax layers + all world objects / traps.
- `enemies/types/hauler.gd` - HAULER (also the boss, THE ENGINE) (+ `Wreck`, `Rupture`).
- `enemies/types/quisling.gd` - QUISLING (living human; also a story-scene actor).
- `enemies/types/straggler.gd` - STRAGGLER (+ `BehindEye`, the "something moved behind you" icon).

**Background (Backdrop)** - all layers animate on `t`; `dusk(t)` lerps the palette from smog dusk to evening over `DUSK_T` seconds.
- `yard_sky`: gradient sky, a sinking red sun, smog bands, birds, first stars.
- `far_city` (0.06): two skyline passes with windows lighting up, chimneys with blinking red lights and smoke, a lit passenger train on a viaduct.
- `mid_yard` (0.28): the "F.C. SUD" roundhouse, water tower, a row of boxcars with graffiti, catenary poles.
  Every `TRAIN_EVERY` s a freight train full of the dead rolls south (`_zombie_train`: bodies on the roofs, arms out of the doors).
- `near_rails` (0.6): rails and sleepers, timetable signal posts (red/amber/green), weeds, scrap, steam vents.
- `yard_overlay`: an orange sodium `haze_band` at screen y 420-612, behind the characters (readability rule).
- Screen FX: ash particles + `YardFX` (moving smog, soot and embers scaled by `Quality.ambient()`, orange tint).

**Layout / upper floors** - every high place has ladders and a pickup.
- `BOXCARS` - roof = invisible steel `add_floor` (`CAR_TIER`), 2 ladders, a regular zombie on top.
- `GANTRIES` - signal bridges with a walkway (`GANTRY_TIER`).
- `HOPPERS` - coal towers with a deck (`HOPPER_TIER`).
- `SodiumLamp` every `LAMPS` of the level, so silhouettes stay readable in the evening.
- `Turntable` (boss arena) at `level_w - 1100`, with a raised control booth (floor + ladder + ammo). The booth is the hiding place from the charge and the best spot to shoot the valves.
- Obstacles `buffer` / `sleepers` / `crates` / `wheels` come from `custom_gen` and skip reserved spots (all are group `cover`).
- `extra_spawns`:
  - a regular zombie on every deck
  - `QUISLING_GROUPS`: a herd of regulars with one quisling inside. The herds grow along the level (3 -> 5).
  - 7 stragglers (`STRAGGLERS`), 3 haulers (`HAULERS`)
- `zombie_weights()`: STRAGGLER 0.05, HAULER 0.035, QUISLING 0.02, regulars 0.55, runners 0.32.

**Traps**
- `Switch` (`SWITCHES`): walk past the red-white lever and a bell rings (`WARN_T`). Then a runaway `Flatcar` rolls along the road from the side you are heading to.
  - Jump it (`H` 40) or roll. It deals `DMG`, crushes zombies once each (`DMG_Z`), smashes on walls, and can be shot apart (`HP`).
  - Shooting the lever (a layer-4 body with `hit_by_bullet`) releases the car from the switch toward you, on your timing. Use it to mow down a herd.
- `LiveWire` (`WIRES`): a torn overhead wire. It buzzes (`WARN_T`, sparks), then whips the ground with an arc (`ARC_T`).
  - The arc hurts you (`DMG`) and fries zombies (`DMG_Z`, 12 on a boss). It fires sooner when you stand under it.
  - The poles are drawn behind the characters (`Poles`, z -1); only the torn wire and the arc are in front. Wires stay quiet while a story scene plays.
- Both are in group `hazards` with `danger_at()` / `world_rect()` for the bot.

**HAULER** - Junji Ito "Gyo": a bloated corpse strapped belly-down on a 4-legged walking frame made of rail parts (pistons, little rail-wheel feet).
A gas tank on its back is hosed into the corpse's back and mouth (it puffs green gas).
- Fast (`chase` 150). **RAM:** rears back with a steam hiss (`RAM_WIND`), then charges straight (`RAM_V`, `RAM_DMG`). **STOMP** when you are hugging it (`STOMP_R`, jump it).
- **Hit zones** (in `on_damage`, local coords from the 76x64 hitbox):
  - Front body = iron frame: x`FRAME_MULT` damage, sparks, `metal` (no blood). After 7 frame hits with no tank hit it pops "SHOOT THE TANK!".
  - The corpse's hanging head (front, chest height) = full damage.
  - The tank: from behind, from above, or its top that sticks out over everything (shoot high). `TANK_HP`.
    Any nearby explosion also hurts the tank (chain reactions).
- Tank gone -> **VENT** (`VENT_T`, gauge needle on the tank, leak jets; more shots into the tank only hiss, so the blast always comes) -> blast (`BLAST_R`, `BLAST_DMG` to zombies, 1 to the player).
  Then the frame collapses (`Wreck` stays on the ground and fades) and the corpse crawls on with `CRAWL_HP` and a resized hitbox.
- Killed with the tank intact (or while venting) -> `Rupture`: the tank hisses for 0.9 s and blows.
- Turns late (`TURN_T`), so rolling past it exposes the tank.
- **Learns** (main meta `hauler_pops` >= 1). New haulers spawn with `tank_learned`:
  - The tank is lowered behind an armor plate, so it can only be hit from behind or above ("get above them": boxcars, gantries).
  - They turn to you fast (`LEARN_TURN_T`) and after a ram.
  - With a damaged tank they back up against a `cover` object with their tank (`COVER_R`), wait there (`COVER_HOLD`), then come out to ram (`SORTIE_T`) and go back.
  - Popup "THEY HIDE THE TANK".

**THE ENGINE** (boss, `chase_range > 600`, `boss_name` "THE ENGINE"):
- A locomotive boiler walking on 4 legs whose knees are spoked drive wheels.
- It has a cab with a dead driver, a smokestack and a headlight.
- A giant stitched corpse face is fused into the smokebox door.
- Corpses hang in a cage and on chains (the "passengers").
- **STEAM** (`STEAM_WIND` hiss, then `STEAM_T`): a steam cone aimed at you, up to the booth too (`STEAM_R`). Roll or step out.
- **DROP** every `DROP_EVERY`: 2 corpses (`lie_down`) that get up when you come near (up to `DROP_MAX`).
- **WHISTLE -> CHARGE:** the whistle sounds and the headlight beam comes on (`WHISTLE_T`), then it charges down the track (`CHARGE_V`).
  - The charge crushes zombies and smashes brick cover.
  - Dodge: climb the booth, or roll through it (PERFECT DODGE).
- **VALVES** after every charge: 3 pressure valves pop up on the boiler top for `VALVE_T`.
  - Valve hits x`VALVE_MULT`. Each valve has `VALVE_HP`; a broken valve stays open for good (x2).
  - The rest of the boiler takes x`OPEN_MULT` while open. Closed, it is armor (x`ARMOR_MULT`, "CLANG").
  - The face takes x0.8. `BOSS_HEAD_K` cancels the engine's built-in x2 boss-head bonus, because the top of the boiler is not a head.
- Double charge (there and back) under 50% hp.
- **Learns:** after 2 roll-dodges it always double-charges ("IT READS YOUR ROLL").

**QUISLING** - WWZ quislings / TWD Whisperers: a living man in a cloak and mask of stitched dead skin, shambling inside a herd.
- **Tells:**
  - breath fog
  - blinking
  - white human eyes in the mask holes
  - a silent, lockstep herd
- **While HIDDEN** he whispers every `WHISPER_T`:
  - herd zombies within `SILENCE_R` stop groaning and walk in sync (same `_walk_phase`);
  - half of them FLANK (`brain.command` + `flank_side`), the rest APPROACH (`_alert_t`).
- **Exposed** when shot, when you come within `EXPOSE_R`, or when his whole herd dies. Then:
  - Mask pulled down (`mask_off` -> 1), a gasp.
  - **AIM** (`AIM_T`, red aim line that tracks you, then a revolver `Slug` for `SHOT_DMG`) or **THROW** (a `torch.gd` Bottle -> fire zone, `MOLOTOV_CD`).
  - After `SHOTS_BEFORE_RUN` he **RUNS** (`RUN_V`) to the next herd (`_find_group`) and **REHIDES**. Cornered with nowhere to go, he backs off and shoots again.
- Low HP (22), red blood, `qs_scream` death.
- Killing him confuses every zombie around (`brain.confuse(CONFUSE_T)`, "?" popups, "LEADERLESS").
- **Learns** (main meta `quisling_exposed` >= `LEARN_EXPOSED`):
  - He hides at the far side of the herd and picks the biggest herd when he runs.
  - He only breaks cover at `LEARN_EXPOSE_R`.
  - He holds his breath while you look at him.
- **Story actor** (not in group `zombies`): stands still and uses `talking`, `tilt`, `smile`, `look_back`, `t` (like `stranger.gd`).
  `mask_off` goes from 0 (mask on) to 1 (mask pulled down: a scared, sweating human face). Set it with `actor_props` or tween it from the scene.

**STRAGGLER** - Colson Whitehead's "Zone One" stragglers + Weeping Angels: dead commuters and railwaymen frozen mid-routine, grey as stone.
- Routines: lantern, pocket watch, suitcase, newspaper, broom. Each one gets its own outfit and hat.
- They wake up when you come near (`WAKE_R`) or shoot them.
- **They move only while you are not looking** (`player._face()` points away, `SIGHT_R`).
  - When unseen they are fast (`chase` 300) and strike hard (`DMG`).
  - When seen they freeze with dust and a creak, in a new threatening pose each time.
- Body hits x`BODY_MULT` (stone); headshots are normal.
- When one starts moving behind you there is a "crack" and an eye icon (`BehindEye`) on that side. The first time: "THEY MOVE WHEN YOU LOOK AWAY".
- **Learns** (main meta `st_stare` >= `LEARN_STARE` seconds of you staring at them):
  - They gather behind you (`GATHER_D`) and wait.
  - They move during your reload, even while you look ("THEY WAIT FOR YOUR RELOAD").

**Story scene** - `story/scenes/l52_quisling.gd` (x 1300): a QUISLING actor pulls his mask off and talks about the trains south and THE ARCHITECT, then vanishes.
The spot is between the first boxcar (0.09) and the first wire (0.14); the first straggler was moved to 0.2 so nothing stands next to the actor.

**Tunables** - in each file header. Stage: `BOXCARS`, `CAR_TIER`, `GANTRIES`, `GANTRY_TIER`, `HOPPERS`, `HOPPER_TIER`, `SWITCHES`, `WIRES`, `LAMPS`,
`QUISLING_GROUPS`, `STRAGGLERS`, `HAULERS`, `zombie_weights()`. Hauler: `COVER_R`, `COVER_HOLD`, `SORTIE_T`. Map picture: `map/thumbs/level_52.png`.

- Integration fix: a HAULER drops an ammo box when its frame goes down (or when it dies with the frame whole), and FRAME_MULT is 0.5 (was 0.35) - the playtest bot kept running dry on level 52.

## Stage 53 - "CAPITAL SIEGE" (THEY LEARNED TO BESIEGE)

Zone 6 (Southern Cone), stage 8. Montevideo, the last free capital, on a cold grey morning. The living hold the old city
behind burned buses and sandbags. The herd outside does not just push: it climbs itself, it spreads a word that rots the mind,
and THE ARCHITECT has sent one of them after the hero by name.

**Files**
- `levels/stage_53.gd` - layout, spawns, sounds (`sg_clank`, `sg_pour`, `sg_creak`, `sg_crash`), the PURSUER `Director`.
- `effects/s53_decor.gd` - sky + 3 parallax layers + all world objects / traps.
- `enemies/types/stacker.gd` - STACKER (+ `Tower`, `HitPop`). Also the boss, THE SIEGE TOWER.
- `enemies/types/babbler.gd` - BABBLER (+ `WordRing`, `Scramble`/`Painter` screen overlay, `Letters`).
- `enemies/types/pursuer.gd` - PURSUER (+ `Rocket`, `Director`, `Banner`/`BannerPaint`).

**Background (Backdrop)**
- `siege_sky`: 32-step grey-blue gradient, a pale sun, soft cloud bands, 2 sweeping searchlights, 4 soft smoke columns and gulls.
- `far_river` (0.06): the Rio de la Plata. It has the Cerro hill with its fortress, a lighthouse whose beam turns, port cranes, two burning ships and horizon mist.
- `mid_oldcity` (0.28):
  - The old-city skyline with Palacio Salvo (lit windows, rooftop searchlight, flag) and the blue-domed cathedral.
  - THE HERD: an animated bumpy mass with raised arms outside the walls.
  - The defenders' wall every 640 px: sandbags, muzzle flashes and a body pyramid that grows.
- `near_barricade` (0.6): Czech hedgehogs, coiled barbed wire, sandbags, poster columns with flapping posters, and drifting smoke.
- `haze`: `Kit.haze_band` 420-612. It is the readable mid-tone band behind the characters.
- Screen FX: ash particles, plus `SiegeFX` (low cold mist and a distant artillery flash every 7-14 s).

**Layout / upper floor**
- `GATE`: the Puerta de la Ciudadela. Its roof is an invisible `add_floor` with 2 ladders, an ammo pickup, a regular zombie and a BABBLER that shouts down.
- `FACADES`: 4 colonial fronts with an iron balcony each (floor, ladder and pickup).
  - Each one has an `OilDrum` above the street and 2 STACKERs waiting underneath. Climb up and they build a tower to you.
- `BUSES`: 4 burned buses. They are solid cover and you can stand on the roof.
  - Behind the even-index buses waits a BABBLER. Behind the odd-index buses wait 3 STACKERs.
- `BREACHES`: junk barricades along the road.
  - When you come within `TRIGGER_R` the barricade shakes (`WARN_T`) and collapses (`DMG`, `DMG_Z`).
  - `BURST` zombies pour through, and the last one is a STACKER.
- The Rambla at the end (`SeaWall`, the MONTEVIDEO letters) is the boss arena. It has 3 `ArenaBarricade`s (`ARENA_BARRICADES`) for the boss to smash.
- Obstacles `sandbags` / `stalls` / `tram` come from `custom_gen`. Keep them at 62 px tall or less: a 75 px tram (156 wide) stopped the no-god bot for good.
- `BREACHES` sit at 0.3 / 0.59 / 0.8 of the level. Do not put one past 0.85, where it overlaps the arena barricades.
- `zombie_weights`: STACKER 0.09, BABBLER 0.04, walkers and runners. The PURSUER is never in the weights; there is only one per level.

**Traps**
- `OilDrum` (group `s53_drums`): shoot the drum (the `Hit` body on layer 4). It tips over and pours burning oil on the street (`POUR_W`, `BURN_T`).
  - The oil ignites and damages zombies (`DMG_Z`) and topples any STACKER tower in it.
  - When a tower stands within 160 px it shows the hint "SHOOT THE OIL DRUM!" once.
- `BreachWall`: see Layout. It is a hazard (`world_rect` / `danger_at`), so the bot and the brain avoid standing in it.

**STACKER** - a shirtless grey-blue climber with a criss-cross rope harness, a knotted rope trailing behind and hooked fingers. (World War Z zombie pyramids, I Am a Hero.)
- When you are up high (`d.y < -70`, within 360 px), the free stackers within `STACK_R` gather under you.
  - They lock into a living `Tower` of 2-4 bodies. `need` is computed from your height.
  - The base stands braced, the middle body kneels on the shoulders, and the top body reaches up.
  - The `Tower` node draws fused flesh strands and the rope that links the harnesses.
- If no more stackers come, a shorter tower is finished after `SHORT_BUILD_T`.
- **Built:** the top body vaults onto your floor. From then on the tower is a ladder: any zombie that reaches the base is launched up to your floor (`LADDER_CD`).
- The tower comes apart when you have been away for `IDLE_DISBAND`, or after `LIFE_MAX`.
- **Counter:**
  - Shoot the base `TOPPLE_HITS` times (a shotgun hit counts double), or kill the base.
  - Any explosion on any member, or the burning oil, also brings the tower down.
  - **TOPPLE:** every member flies outward (the higher the body, the farther) and spins.
    - On landing it takes fall damage `FALL_DMG.x + FALL_DMG.y * slot` and lies down for 1-1.7 s.
    - Zombies it lands on take `DOMINO_DMG` and stagger. A body that lands on another tower topples that tower too ("DOMINO!").
- **Learns** (`main` meta `st_topples`):
  - After `LEARN_ARMOR` topples the base holds a rusty car door ("THEY BRACE THE BASE").
    - The door blocks front bullets to the torso and head (CLANG, "SHOOT THE LEGS").
    - Legs, explosions and fire still work.
  - After `LEARN_TWIN` topples they build two towers at once, 124 px apart ("TWO TOWERS").
- Test counters are main metas: `st_built`, `st_topples`, `st_climbs`, `st_blocks`, `st_armored`, `st_twins`.

**THE SIEGE TOWER** (boss, `chase_range > 600`) - a walking mass of about 22 fused bodies on 7 pairs of legs, carrying an iron-capped battering ram.
- The hitbox is resized at runtime to 124x168.
- **RAM** (`160 < |dx| < 600`): it leans back for `RAM_WIND` (dust and a roar), then charges at `RAM_V` for up to `RAM_MAX`.
  - Hitting an `ArenaBarricade` smashes it, sheds 2 bodies and stuns it for `STUN_BARRICADE`.
  - Hitting a wall stuns it for `STUN_WALL`.
  - Hitting you deals `RAM_DMG` and throws you. Zombies in its path are flung.
- **SWAT** at < `SWAT_R`, with a `SWAT_T` telegraph. Touching the mass also hurts.
- **SHED:** every 1/9 of its HP, and on each explosion, a body falls off.
  - The body lies on the ground, then gets up and attacks (kind 0 or 1, at most `SHED_CAP` alive).
  - Every 2 shed bodies an AMMO box drops (`ammo_drops`, at most 4), because the no-god bot ran dry at 700 HP.
  - The fallen bodies leave red holes in the mass.
- **Weak point:** the CORE face in the middle of the mass. It grows as bodies are shed (`_exposure`).
  - Core hits take x`CORE_MULT`, or x`CORE_STUN_MULT` while it is stunned ("CORE EXPOSED").
  - The rest of the mass takes x`BODY_MULT`, and explosions x`BODY_BLAST_MULT`.
  - The engine's "head" zone (the top half of the mass) is normalized with x0.22.
- **The fight:** dodge the ram so it hits a barricade or a wall, then pour shots into the exposed core.

**BABBLER** - a dead radio host (Pontypool Changes Everything, Stephen King's Cell). He wears a dirty white shirt, a loose tie, suspenders and headphones around the neck, and holds a cracked, taped megaphone.
- He repeats one word (`WORDS`: SOUTH, HUNGRY, HOME, KILL, OBEY...) in a jagged bubble. He keeps range (280) and prefers to stand behind another zombie (`HIDE_R`).
- **SHOUT:** every `CD` s he inhales for `INHALE_T`. The bubble grows and shakes and the word turns red. Then he shouts a `WordRing`.
  - The ring is a circle of the word that grows at `RING_V` up to `RING_R`.
  - It hits you when it reaches you with a clear line from the megaphone (ray on mask 1) and you are not rolling. You are then **WORD-SICK** for `SICK_T`:
    - `player.daze` adds aim sway and half speed.
    - The `Scramble` overlay (CanvasLayer 3, above the HUD) shows scrambled copies of the word, some of them over the HUD corners, plus noise bars and red edges.
    - There is no control inversion.
  - Zombies the ring passes "hear" the word: `drum_t` gives them x1.3 speed for `HEARD_T`, and they become alert.
- **Counter:** cover (a bus or sandbags between you), a roll through the ring, distance, or **shoot the megaphone**.
  - It has its own hit circle (`MEGA_R`, local (19,-48)) and absorbs bullets.
  - `MEGA_HITS` hits make him **SILENCED**: he screams, rushes at x`CHARGE_MULT` and can bite.
- **Learns:** after `LEARN_DODGES` dodged rings his timing changes ("IT LEARNED YOUR TIMING").
  - His pauses become irregular (`LEARNED_CD`).
  - `FAKE_P` of his inhales are fakes, followed by a fast real shout (`QUICK_INHALE`).
- **Death:** the letters of his word scatter, with a feedback squeal.
- Test counters: `rings`, `sick`, `dodges`, `fakes`, `mega_hits`, `silenced`, `learned`, plus main metas `bb_heard`, `bb_sick`, `bb_dodges`, `bb_silenced`.

**PURSUER** - "SENT FOR YOU" (Nemesis, the Terminator). A huge bald tyrant in a long coat with a stitched skull and one red lens eye. He carries a rocket launcher on his back and a tag on his chest.
- **One per level, never from the pace director.** `Pursuer.Director` (created in `stage_53.build_effects`) drops him from the sky about 520 px ahead of you when you pass `start_x` (11% of the level).
  - The landing comes with a shake, a roar, debris and the full-screen banner "HE WAS SENT FOR YOU / THE ARCHITECT KNOWS YOUR NAME".
  - From then on he walks after you at a steady `WALK_V` for the whole level. He leaps up to your floor, drops down, and jumps walls.
- **Never stuck:** the Director teleports him off-screen behind you (`RESPAWN_D`, onto a free floor spot) when:
  - he is more than `CATCH_D` behind,
  - he has barely moved for `STUCK_T` while off-screen,
  - or he fell below the floor.
  - Past `end_x` (the boss arena) he is removed if he is far away, so he does not join the boss fight.
- **Not a boss** (no HUD bar, the exit does not depend on him). He draws his own overhead HP bar and 3 down pips.
  - His HP is kept above a hidden `BUFFER` until the 3rd phase, so a big hit can never kill him early.
- **Falls but doesn't die:** at 0 phase HP he drops to one knee for `DOWN_T`. He is invulnerable then, and sparks fly off him.
  - He gets up with the next `PHASE_HP`. Only the 3rd fall is real death.
  - His death drops BOOST + SUPPLY + AMMO + HEALTH, gives 3000 points and the line "STAY DOWN."
- **Learns where you shoot:** each time he rises, armor grows on the zone you hit most (head, body or leg).
  - The armor is a riveted helmet, a chest plate or iron greaves ("THEY LEARN WHERE YOU SHOOT").
  - Bullets on an armored zone spark off ("ARMORED - AIM ELSEWHERE"). Explosions and fire bypass the armor.
  - Head hits are x0.6, so he can't be one-shot.
- **Attacks:**
  - **GRAB:** reach (`REACH_T`), then he lifts you overhead (`LIFT_T`) and throws you (`THROW_DMG`, `THROW_V`). A/D mash frees you (`player.grab`).
  - **PUNCH:** a short jab when the grab is on cooldown.
  - **ROCKET** at `ROCKET_R` with line of sight: a red laser dot tracks you, lagging behind, for `AIM_T`, then the rocket flies at the dot.
    - The `Rocket` explodes with `Boom.blast` (radius 90, `ROCKET_DMG` to zombies, 2 to you).
    - Counter: roll out of the dot, break line of sight, or keep moving.
- Test counters: `downs`, `armor`, `blocks`, `grabs`, `throws`, `punches`, `rockets`, `escapes`, `Director.teleports`; main metas `pu_spawned`, `pu_killed`, `pu_rocket_booms`, `pu_teleports`.

**Story hooks** - the popups carry the region-6 arc: "THEY CLIMB EACH OTHER", "IT SHEDS ITS DEAD", "HE WAS SENT FOR YOU", "THE ARCHITECT KNOWS YOUR NAME". The BABBLER words include SOUTH and OBEY.

**Shared-file note** - WORD-SICK calls `player.aim_sway(t, msg)` when the player has it, otherwise `player.daze()`, which also halves your speed. `player.gd` does not have `aim_sway` yet; the suggested diff is in `/home/claude/work/player_aim_sway_53.diff`.

## Stage 54 - "LAST BRIDGE" (THEY LEARNED TO FOLLOW)

Zone 6 (Southern Cone), stage 9, the region finale. Night on the old iron truss bridge over the Rio Negro between
Carmen de Patagones and Viedma, the gate to Patagonia. THE ARCHITECT is leading the dead south. The army mined the
bridge and ran. The hero arms the charges on the way across, kills the Architect on the far bank and blows the last bridge.

**Files**
- `levels/stage_54.gd` - layout, spawns, charge/gate logic, the collapse, story hooks. Sounds `b54_creak`, `b54_tick`,
  `b54_beep`, `b54_arm`, `b54_buzz`, `b54_zap`, `b54_brake`, `b54_crash`, `b54_rumble`, `b54_wind` (all existing files).
- `effects/s54_decor.gd` - sky + 3 parallax layers, all world objects, traps, the collapse and the screen FX.
- `enemies/types/shepherd.gd` - SHEPHERD (also the boss, THE ARCHITECT).
- `enemies/types/stinger.gd` - STINGER (+ `Worm`, `StingBody`).
- `enemies/types/darkseeker.gd` - DARKSEEKER (+ the thrown bolt).

**Background (Backdrop)** - `bridge_sky` (night gradient, batched stars, a big low moon with maria and a glow, wind-torn
clouds with a silver rim near the moon, a cold aurora curtain strongest to the south, a shooting star every 11 s),
`far_steppe` 0.06 (snowy ridges and mesas, the Patagones church tower on its hill with a lit window and red beacon,
steppe fires, a tiny line of the dead walking south),
`mid_river` 0.28 (the far shore with poplars and the Viedma lights, water bands, the moon's reflection column, burning
boats drifting, and THE HERD: 3 rows of dark heads with silver rims wading across, ripples, raised arms),
`near_truss` 0.6 (the far-side truss diagonals and rivets sweeping past, far lamps, railing, wind-blown debris).
All layers animate on `t`. `Decor.U.boom_ms` (set by the collapse) makes the herd sink with splashes,
`Decor.U.roar_ms` (story beat "herd_roar") makes it raise its arms and light its eyes.
Screen FX: `S11.NightOverlay` (`DARKNESS` 0.34, moved under `screen_layer` so it never darkens the HUD; it reads lamps,
`s11_lights` and `dyn_lights`), `BridgeFX` (wind streaks + river mist, `gust()` with `b54_wind`), `ChargeHud`.

**Layout / upper floor**
- North bank town to `TOWN_END` 1650 (shop fronts, a balcony floor `BALCONY` with ladders and a pickup), then the
  `BridgePortal` ("PUENTE 1931").
- The bridge `TRUSS_X0..TRUSS_X1` (1760..9280): `BridgeDeck` road with a rail track beside it, `Truss` segments
  (up to 6 panels, z -2) and `ClimbSpan` nodes (group `s54_truss`, used by the DARKSEEKER) that skip the gantries.
- `GANTRIES` - service gantries on the top chord (`TIER` 150) with 2 ladders each and a pickup up high (one GRENADE).
- Lamps every `LAMP_GAP` 460, every 3rd one a `FlickerLamp`. No lamps in the `DARK` stretches (3150..3750, 5600..6150),
  at the gate, at the town end or next to a charge.
- `GATE_X` 8800 - the army roadblock into the boss arena, then `SouthBank` ("PUESTO SUR", "RUTA 3 USHUAIA 3000").
- Obstacles `jersey` / `ammo` / `wreck` / `convoy` come from `custom_gen`. Do not name one `crates`: main.gd handles that
  name itself, so `reserve()` would not keep it out of the story stretch.
- `extra_spawns`:
  - a shepherd + 4 regulars at every charge
  - 2 darkseekers in each DARK stretch, one on 3 of the gantries
  - stingers at `STINGERS`
  - 2 regulars in the arena

**Demolition charges (the exit gate)**
- `CHARGES` (2560, 4000, 5440, 6560): `ChargePoint` bundles on the truss verticals (groups `s54_charges`, `s11_lights`).
- Stand within `ARM_R` 100 px for `ARM_T` 1.5 s ("HOLD" ring with a progress arc). The charge then blinks red forever,
  and the player says "CHARGE ARMED n/4".
- The `Roadblock` at `GATE_X` is a solid wall (layer 1) until all 4 are armed. Walking into it pops "ARM ALL CHARGES n/4".
- `ChargeHud` (top right, under STYLE) shows the armed count and, when an unarmed charge is more than 640 px behind
  the player, an "UNARMED CHARGE" arrow.
- Walk more than `MISSED_DX` 260 px past an unarmed charge and the hero says "MISSED A CHARGE - GO BACK" (once per
  charge), so nobody finds out 6000 px later at the gate.
- Checkpoint restart: on the first frame, every charge left of the player is armed quietly.

**Traps**
- `BrokenDeck` (`DECKS` 3110, 6330): a cracked deck plate. Stepping on it (or `HEAVY` 3 zombies on it at once) makes it
  creak (`WARN_T`), then the plates fall to the river (`FALL_T`). A player still on it takes `DMG`, grabs the beam and is
  thrown up (+ slow). Zombies on it drop into the river with a splash, and the open hole keeps swallowing zombies that
  walk over it (the player can still cross on the beams).
- `RollingTruck` (`TRUCK_X` 4300): an abandoned army truck with its brake on. Shoot the red brake (`Brake`, layer 4,
  `hit_by_bullet`) and it rolls `ROLL_DIST` px, crushing zombies (`CRUSH`) and hurting the player, then crashes into a
  `Boom.blast` + 2 fires.
- `LiveCable` (`CABLES` 3240, 6090): a cut cable hanging from the truss. It sparks (`WARN_T`), then arcs (`ARC_R`) and
  chains through zombies within `CHAIN_R` (`DMG_Z`). It also lights up DARKSEEKERs.

**SHEPHERD** - a tall, pale zombie in a torn red hood with glowing blue-white veins. Inspired by the Twelve and their
Many in *The Passage* (Justin Cronin) and the Raggedy Man who leads the flock in *Cell* (Stephen King).
- **LINK:** every `LINK_CD` it shoots a thin thread of light from its forehead to a nearby zombie (`LINK_R`), up to
  `MAX_MANY`. Its Many walk in step with it, are faster (`MANY_SPEED`) and take x0.6 damage (meta `morale_t`).
  A thread breaks if one strays past `LINK_MAX`.
- **LUNGE:** every `LUNGE_CD` it raises its arms (`LUNGE_WIND`, the threads flare) and all its Many leap at you at once.
- Keeps `HOLD_R` behind its Many.
- **Kill it and the Many die with it**: a chain, closest first (`CASCADE_STEP`), each one with a burst head and MULTI KILL.
- **Learns** (main meta `sh_kills`): after `SH_LEARN` dead shepherds the next ones stand further back (`HOLD_R_LEARN`).
  When you aim at one it swaps places with one of its Many in a flash (`SWAP_CD`) - "THEY HIDE BEHIND THEIR MANY".

**THE ARCHITECT** (boss, `chase_range > 600`, `boss_name` "THE ARCHITECT"):
- Linked to up to `BOSS_MANY` zombies on the bridge (`BOSS_LINK_R`, `BOSS_LINK_CD`).
- **Guarded:** while `GUARD_N`+ Many are linked he takes x`GUARD_MULT`. Fewer than that and his chest opens (x`OPEN_MULT`).
- **MIND BLAST** (`MIND_CD`, telegraph `MIND_WIND`): every linked zombie charges at once, and anyone inside `MIND_R` is
  knocked back.
- **PULL** (`PULL_CD`): when few Many are left he drags threads down into the river and `PULL_N` dead climb over the
  railing past the gate. `PULL_N` is kept below `GUARD_N`, so there is always an open window after a pull.
- **Death:** every zombie on the level drops dead ("THE REST ALREADY CROSSED"), then `stage.on_architect_dead(pos)`
  starts the collapse.

**The collapse** (`Decor.BridgeCollapse`)
- All charges beep fast for `BEEP_T` 2.2 s (`CollapseBanner` pulses a red border).
- Then booms run leftwards every `STEP` 0.16 s, `GAP` 230 px apart, from `x1` (just behind the player, never past
  `TRUSS_X1`) to `x0`. Near the player each boom is a real `Boom.blast` with shake; far away it is sound only.
- Truss pieces, lamps and deck chunks fall and splash in the river. `stage.collapse_at(a, b)` cuts the trusses and hides
  the lamps, gantries, charges and gate in that range.
- A wall at `x1` keeps the player on the south bank. The herd in the river sinks.
- Banner: "THE BRIDGE IS DOWN" / "nothing else crosses into Patagonia... nothing that walks".

**STINGER** - a bald, pale vampire-zombie in a long coat with black veins and a swollen throat. Inspired by the strigoi
of *The Strain* (Guillermo del Toro & Chuck Hogan, books and comics).
- **SWELL** (`SWELL_T`, a gurgle, the throat glows red), then **STING**: the jaw splits and a fleshy stinger shoots
  straight at you up to `STING_R` (`EXT_T`), holds `HOLD_T` and pulls back (`RET_T`).
- A hit does `DMG`, heals it `HEAL` and slows you. One hit per sting.
- **The stinger out is a big weak spot** (`StingBody`, layer 4): a shot does `STING_DMG` and makes it recoil.
- **Death:** `WORMS` white worms crawl from the corpse toward you for `WORM_LIFE` s. A touch is a small poison
  (`POISON_HITS` touches = 1 heart) + slow. Fire, explosions, the flashlight or a flare kill them, and rolling over them
  squishes them with no poison.
- **Learns** (main meta `st_dodges`): after `DODGE_LEARN` dodged stings it feints: swells, lets go (`FAKE_T`) and
  stings on a second, faster swell (`SWELL2_T`) - "IT FEINTS NOW".

**DARKSEEKER** - a fast, gaunt night hunter with grey skin and huge black eyes. Inspired by *I Am Legend*
(Richard Matheson): creatures of the night that hate light and make a world for themselves in the dark.
- **Light:** lit by a bridge lamp, the player's flashlight or a flare it takes x`LIT_MULT` damage. A flashlight or flare
  on it makes it shriek, recoil (`RECOIL_T`) and flee. A close flare (`FLARE_R`) stuns it (`FLARE_STUN`).
  It never steps into a lamp's cone and waits at the edge of the dark.
- **SMASH:** a lamp between you and it (or lighting you) gets a bolt thrown at it (`WIND_T`) and is shattered
  (`street_lamp.gd shatter`). `SMASH_CD`, up to `SMASH_MAX`.
- **CLIMB:** in the dark at `CLIMB_MIN..CLIMB_MAX` it leaps up to the truss top chord (group `s54_truss`), crawls upside
  down under it (`CRAWL_V`) until it is above you, and drops on you (POUNCE: damage + knockback). Light on it up there
  drops it stunned.
- **Learns** (main meta `ds_flash` = seconds your flashlight was on in this level): after `FLASH_LEARN` s, when the
  flashlight points at it, it climbs over you and lands behind you ("THEY COME FROM BEHIND").

**Story hooks** (call on `main._stage`)
- `story_stretch()` returns `Vector2(6750, 8750)`: a flat, clear road with no obstacles, traps or lamps in the way.
  Stand the actors around x 8250 (just before the gate).
- `on_story_beat(id)`:
  - "lamps_out" - all lamps flicker out for a moment
  - "herd_roar" - the herd in the river raises its arms, rumble + shake
  - "charges_beep" - armed charges beep fast
  - "wind" - a strong gust
  - "arm_all" - arms every charge
  - "collapse" - starts the collapse (testing)
- `arm_all_charges()`, `armed_count()`, `on_architect_dead(pos)`.

**Tunables** - in each file header. Stage: `CHARGES`, `GANTRIES`, `TIER`, `DARK`, `DECKS`, `TRUCK_X`, `CABLES`,
`STINGERS`, `LAMP_GAP`, `DARKNESS`, `MISSED_DX`, `GATE_X`, `STORY_X`, `zombie_weights()`
(SHEPHERD 0.02, STINGER 0.05, DARKSEEKER 0.05, regulars 0.55, runners 0.33).

**Tests** (test project, outside the repo)
- Headless: 1600 frames from the start, plus 900 frames with the player at x 3000 / 6000 / 9300 / 9650 (boss): no script errors.
- Playtest bot (`t_bot54.gd`, a `t_bot.gd` copy that stands on unarmed charges and walks back to missed ones):
  FINISHED in 63-102 s, stuck 0-1 (one 4.7 s wait on a gantry, no teleports), all 4 charges armed in 1.6-1.8 s each,
  boss killed, collapse ran. With the STRANGER scene in place it played for 30 s and the run still finished.
- Behaviour counters (`t_beh54.gd`):
  - charges: armed after 40 frames; the gate blocked the player at x 8768 (2 hints), opened after all 4, HUD showed 4
  - boss: 17 guarded hits, 2 MIND BLASTs, 1 PULL, 8 open hits; every zombie dead after he died; collapse 12 booms, 60 chunks, 60 splashes; the wall held the player at x1
  - shepherd: 3-4 links, lunges, chain kill 3/3 (4/4), learned after `SH_LEARN`, 2 swaps
  - stinger: 2 stings, 2 hits, 3 dodges, learned, 2-3 feints, 1 weak-spot hit, 6 worms, 5 touches -> poison, 1 squished by a roll
  - darkseeker: 1 smash, 1 climb, 1 pounce + hit, 0-1 recoil (varies run to run), 1-2 lit hits, 1 flare stun, learned, 1 landed behind
  - traps: deck 1 fall, 3 drops, 4 more through the open hole, player hit 1 on deck 2; cable 3-7 arcs, 2 zapped;
    truck: brake shot -> rolled, crashed and blew up (crushed 0 in that test: no zombies in its path)
- Fixed during testing: darkseekers fell out of the world after a drop (collision mask restored); 14 "triangulation failed"
  errors in one bot run (not reproduced since; the likely source, the shepherd/stinger coat polygon that self-intersects
  when a zombie is flung fast, now has its sway clamped); the boss never opened
  up because a PULL refilled 3 links (`PULL_N` 2); a generator named `crates` ignored the story stretch (renamed `ammo`).
- Known: the boss SUPPLY drop can fly past `level_w` and fall under the floor (seen here at x 10283; the drop code is in zombie.gd, so other boss levels may do it too).

## Region 7 story (levels 55-57+): THEY LEARNED TO THINK
Full story bible: `STORY.md` (next to this file). The infection is ECHO: when an infected body dies, a spore cloud carries its
last moments to the others, so every kill teaches the rest ("THEY LEARN"). The hero is Subject Zero of Project ECHO, cut out
of the hive and memory-wiped by the suppressant LETHE ("Good. Then it worked." in level 1). The Architect died at 54 and
nothing stopped: there is no leader any more, the hive thinks as one and wants the hero, its first voice, to "come home".
* **Spore lesson** (`effects/spore_lesson.gd`, from `zombie.gd` `_die`): from level `SPORE_FROM` (55) a kill sends a small glowing
  spore puff (CHANCE 0.6) to the nearest living zombie within 650 px, which flashes a ring ("it learned"). Max 3 at once, skipped
  for bosses, multi-kill "lite" deaths and Quality level 2+.
* Story scenes: `story/scenes/l55_stranger.gd` (x 4500 in stage_55's story_stretch 3700-5700; the STRANGER explains the spores:
  "Every one you kill... breathes out what it saw"; actions gust / flock_scatter) and `story/scenes/l57_chorus.gd` (x 6240 in the
  colony inside stretch 5600-7600; a WADDLER is the body, the MURMUR flock forms a face and the hive speaks for the first time with
  five layered voices; actions flock_form / flock_break). Voices: `devtools/story_voices.py l55_stranger l57_chorus` (CHORUS layers)
  then `story_voices_master.py l55_stranger l57_chorus` in /home/claude/work/story.

## Stage 55 - "WIND STEPPE" (THEY LEARNED THE WIND)

Zone 7 (Patagonia), stage 1. The Architect died on the bridge (54) and nothing changed: there is no leader any more, the
hive thinks as one. The hero walks the empty Patagonian steppe of ESTANCIA LA VENTOSA under a huge blue sky, in a wind that
never stops. The dead learned two things: the hero does not look up, and the wind can carry them. So they come out of the
sky and roll along the ground. Here the STRANGER tells him the truth about the spores.

**Files**
- `levels/stage_55.gd` - the wind, layout, spawns, drifter waves, hints, story hooks. Sounds `w55_whoosh`, `w55_gust`,
  `w55_sheet`, `w55_rattle`, `w55_creak`, `w55_blade`, `w55_crash`, `w55_hiss`, `w55_beep`, `w55_wire`, `w55_gate`,
  `w55_stampede`, `w55_baa` (synthesised; no new files). Music `level1_total_war.mp3`.
- `effects/s55_decor.gd` - sky + 3 parallax layers, all world objects, traps, screen FX, and the shared wind state `W`.
- `enemies/types/shearer.gd` - SHEARER (+ `Sheep`) and the boss THE ESTANCIERO.
- `enemies/types/drifter.gd` - DRIFTER (+ `CanopyBody`, `Rock`, `LooseCanopy`).
- `enemies/types/tumbler.gd` - TUMBLER.
- `map/thumbs/level_55.png` - level card.
- Death spores need nothing extra: zombie.gd already sends `SporeScript` (SPORE_FROM 55) on every death.

**The wind (the stage mechanic)**
- `wind()` returns -1..1; negative means it blows left, into the hero's face. The base is `BREEZE` 0.42 (always left).
- Cycle (`_wind_tick`):
  - CALM for `CALM_T` 6.5-10 s;
  - WARN for `WARN_T` 1.3 s: grass and dust lean hard, a whoosh, and the windsock HUD shows "GUST";
  - GUST for `GUST_T` 3 s at |wind| = 1;
  - LULL for `LULL_T` 2.2 s, when the wind drops.
- The API for zombie types and traps is `gust_k()` (0..1) and `warn_k()` (0..1). `force_gust()` starts a gust now.
- The wind moves particles, grass, flags, poplars, rotors, sheep, DRIFTERs and TUMBLERs.
- It pushes the player only in the air (`AIR_PUSH` 75 px/s at full wind). There is no push on the ground, on a ladder or
  while grabbed, so the wind never takes control away.
- `Decor.W` (static) is updated every frame by the stage: `wind`, `mag`, `gust`, `warn`, `lean`, `drift`, `spin`, `t`.
  Every decor class reads it.
- Screen: `WindFX` draws dust and seed streaks by wind and flashes on a gust. `WindHud` is a small windsock with "GUST!"
  under STYLE.

**Background (Backdrop)**
- `steppe_sky`: deep Patagonian blue, a low western sun, lenticular clouds standing over the Andes, torn clouds racing
  (faster in a gust) and two condors.
- `far_andes` (0.06): granite needles like Fitz Roy with snow plumes torn off the peaks, glaciers, a turquoise lake strip
  and cloud shadows running over the steppe.
- `mid_estancia` (0.28): ochre hills, poplar rows bending in gusts, the estancia casco (red roof), a turbine farm whose
  rotors follow the wind, guanacos, sheep dots, and Ruta 40 with a dust cloud.
- `near_steppe` (0.6): fence posts with 4 wires and skulls, coiron tufts that lean and shiver, calafate bushes, bent
  ñire trees, an Australian windpump and rolling tumbleweeds.
- `steppe_overlay`: a warm dust haze behind the figures.
- The level is bright on purpose: no dark areas and no fog.

**Layout / upper floors**
- `ARCH_X` 360: `EstanciaArch` "ESTANCIA LA VENTOSA" with a flapping flag.
- `SHED_X` 1100: `WoolShed` "ESQUILA". It has a loft at `SHED_TIER` 150 (invisible `add_floor` + 2 ladders) with AMMO and
  HEALTH up there, and a `SheetTrap` on the roof.
- `TOWER_X` 2600: `WaterTower`, deck at `TOWER_TIER` 190, ladder, a GRENADE on top.
- `PUESTO_X` 3060: a stone shepherds' hut with a smoking chimney. `GAS_X` 3330: the gas bottle.
- `STORY_X` 3700..5700: the clear story stretch (see Story hooks).
- `TURBINES`:
  - 6780 is broken (`BladeDrop`);
  - 8130 has a maintenance deck at `TURBINE_TIER` 170 with a ladder, HEALTH and AMMO.
- `CORRAL_X` 7330: the corral.
- `YARD_X` 9140: the boss arena in front of the big `ShearingYard` shed. It has a warm, lit interior so the boss reads
  against it. Also in the arena:
  - `PRESS_X` 9330: a raised `WoolPress` deck (`PRESS_TIER` 130) with AMMO;
  - HEALTH at `YARD_X`-120;
  - wool bales at `BALES` (cover, and the boss's charge jams on them).
- `WindPump`s at `PUMPS` and long `WireFence`s at `FENCES` (both background).
- Obstacles come from `custom_gen` as `Decor.Obstacle`: `wool` bales, `posts` (fence post piles), `rusty` (a rusted
  pickup) and `trough`. The name `crates` is not used, because main.gd handles that name itself.
- Every placed spawn (tumbler, flock) has a `reserve()`d rect, so generated obstacles never cover a spawn point. Without
  this, zombies were sinking into the floor.
- `extra_spawns`:
  - flocks of 4 sheep with 1-2 hidden shearers at `FLOCKS`;
  - the corral shearer (in `pen_mode`);
  - 3 perched drifters at `PERCHES` (shed roof, water tower, turbine deck);
  - tumblers at `TUMBLERS` and a 3-ball `PACK` at 6200-6380;
  - 2 regulars in the arena.
- Drifter waves (`_waves`): at `DRIFT_WAVES` the stage launches 1 drifter upwind of the player (player.x ± 680, meta
  `dr_fly`). Once drifters have learned, it launches 2 ("They come in pairs now..."). Waves never land in the story stretch.
- `_hints`: the hero says one line the first time he meets each type.

**Traps** (`s55_decor.gd`)
- `SheetTrap` (shed roof):
  - A loose sheet rattles (`WARN_T` 1.1) in a gust, then tears off and flies downwind at head height (`V` 470).
  - It does `DMG` 1 to the player and cuts zombies (`DMG_Z` 55). There are `SHEETS` 3, with a `RELOAD` of 3 s.
  - Shoot it to tear it off now.
- `BladeDrop` (turbine 6780):
  - The cracked blade creaks with a shadow on the ground (`WARN_T` 1.2), then falls (`FALL_T`) and crashes (`R` 110).
  - It does `DMG` 2 to the player and `DMG_Z` 90 to zombies.
  - Shoot the red bolt to drop it now.
- `GasBottle` (`GAS_X`):
  - A gust knocks it over. It rolls downwind hissing (`ROLL_V` 150) and blows up after `FUSE` 3.4 s (`BOOM_R` 130).
  - Shoot it to blow it up where it is; another explosion sets it off too.
- `BarbedWire` (`WIRES` 2060, 3470, 7090, 8440): low barbed wire across the road.
  - Walking through it snags the player (`SNAG_T` 0.9, slow + 1 heart, `CD` 1.6), so jump it.
  - Zombies get stuck and bleed.
  - A rolling TUMBLER gets caught (`snag_wire`) and opens.
- `Corral` (`CORRAL_X`):
  - Walk near it (`TRIG_R` 560) and the gate bursts (`WARN_T` 0.7).
  - `N_SHEEP` 12 sheep stampede at you. They are harmless, but they block shots.
  - A SHEARER rides inside the flock.

**SHEARER** - a dead shearer from the estancia: boina, moustache, bloody forearms, a blood-soaked leather apron over
bombachas, and huge sheep shears.
- **What he learned:** "you shoot what looks like a zombie." So he looks like a sheep. He crawls on all fours under a flayed
  fleece with a sheep's head on his own and grazes inside a flock (`Sheep`).
- **The tell:** human legs (boots and bombachas) behind, bloody hands in front, red eyes glinting inside the sheep head,
  blood on the wool, and sometimes the shear tips glint.
- **DISGUISE:** creeps toward you while you are in `CREEP_R`.
- **BURST:** he bursts out when you are too close (`BURST_R`), when he is shot, or when the flock panics. He throws off the
  fleece in a wool cloud and screams. Then he goes to LEAP (`LEAP_V`) and CHASE.
- **SNIP:** at `SNIP_R` the shears open wide and glint (`SNIP_WIND` 0.32, the warning), then close (`SNIP_DMG` + slow).
  Sometimes he does a fast second snip (`COMBO`). After a snip comes RECOVER, a window to shoot him.
- **Sheep** never die and never hurt you. A bullet into a sheep is swallowed by the wool ("baa") and the sheep runs, and
  the panic spreads. That is how you split a flock: shoot next to it and the shearer is exposed.
- **"FOUND ONE":** a hit while he is still disguised and more than `FOUND_R` away counts as found early (main meta
  `shr_found`).
- **Learns:** after `LEARN` 2 early finds, the next ones do not rise when you come close. They let you walk past and burst
  out behind you once you are `PASS_DX` beyond them, and their eyes barely glint (the legs still give them away).
  Caption: "THEY LET YOU PASS NOW".

**THE ESTANCIERO** (boss; `chase_range > 600`, hp 380, scale 2.25) - a giant shearer with a shearing machine on his back:
a two-stroke engine, a flywheel, and an articulated drive arm over the shoulder ending in huge hydraulic shears instead of
a hand.
- **SNAP:** close in, the shears open (`B_SNAP_WIND` 0.6, hydraulic hiss) and close at body height (`B_SNAP_DMG` 2).
  - After `JUMP_LEARN` 2 jumps over him, he snaps high: "IT READS YOUR JUMP". Roll or back off instead.
- **CHARGE:** the engine revs (`B_CHARGE_WIND`, smoke) and he charges with the shears open (`B_CHARGE_V` 480).
  - If he hits a wall, obstacle or wool bale, the shears jam (`B_STUCK_T` 1.5).
  - While jammed he is fully open: x`OPEN_MULT` 1.8 from any direction.
- **CALL:** he whistles to the flock. A stampede runs through the arena (blocking shots) with `CALL_SHEARERS` 2 shearers
  inside. Up to `CALLS` 3 times, every `CALL_EVERY` 15 s.
- **Weak spot:** the engine on his back.
  - From behind or above: x`ENGINE_MULT` 2.2 (sparks, metal hit).
  - The apron and shears in front: x`FRONT_MULT` 0.65.
  - The head-zone bonus is mostly cancelled for him (x0.2 on engine and open hits, x0.5 otherwise), so engine shots do not
    stack the global x2 head bonus.
- **Death:** the engine explodes, the shears fly and stick in the ground, wool and blood burst, and the giant falls.

**DRIFTER** - a zombie hanging in a harness under a torn, colourful paraglider. Cracked helmet, goggles, a torn
windbreaker, dangling legs, hands up on the brake toggles.
- **What it learned:** "the hero does not look up." They died in front of him at eye level, so now they come from the sky,
  with the wind.
- **Flight rules:**
  - It cannot fly against the wind. It drifts downwind (`DRIFT_V` × wind) and can only brake or speed up a little
    (`STEER`).
  - A gust lifts it (`CLIMB`); a lull sinks it (`SINK`).
  - Its ground shadow is the hint.
  - It always comes down within `AIR_MAX` 6.5 s.
- **PERCH:** stands on a deck with the folded wing flapping. You downwind within `LAUNCH_R` 640 → LAUNCH.
- **KITE:** on the ground, the wing inflates behind it. A gust (or `KITE_WAIT`) lifts it.
- **FLY:** cruises at `CRUISE` 250 px.
  - Directly above you it drops a rock or fence post (`ROCK_DMG`, with a growing shadow).
  - Ahead and below (`DIVE_DX`) it screeches, legs up (`DIVE_WIND` 0.4), and dives (`DIVE_V` 390, `DIVE_DMG` 1).
  - If you passed it upwind (`PASS_DX`), it dumps air and lands.
- **LANDED → GROUND:** a short daze (a window), then it drops the wing and walks as a weak brain zombie.
- **Counter - the canopy:** it is a big target (`CanopyBody`, layer 4, `CANOPY_HP` 24).
  - Every hit tears a hole and throws cloth scraps.
  - When the canopy is ripped (main meta `dr_rips`, popup "RIPPED!") it goes to SPIRAL and crashes (`CRASH_DMG` 80:
    "CRASHED!", dust, blood).
  - Fire burns the canopy at once. Explosions rip it.
  - Killing the body works too: the empty wing (`LooseCanopy`) then blows away.
- **Learns:** after `LEARN` 2 ripped canopies, the next ones cut their own lines and drop on you feet first (CUT). They do
  it when above and ahead of you, or the moment their canopy is hit. Caption: "THEY CUT LOOSE NOW". The stage then sends
  waves in pairs.

**TUMBLER** - a dead farmhand (torn poncho, scarf) curled up inside a ball of thorny steppe brush (mata negra). The branches
grew through him. Inside: a red eye and a grey hand between the twigs.
- **What it learned:** "the hero shoots what walks at him." A tumbleweed rolling in the wind is scenery, and nobody shoots
  it. So they do not walk; the wind rolls them.
- **REST:** a ball by the road, rocking in the wind (the tell is the red eye and the hand). You downwind within `ROLL_R`
  900 → ROLL.
- **ROLL:**
  - It rolls fast downwind (`ROLL_V` 215 + gust × `ROLL_GUST` 170).
  - It bounces on bumps (`HOP`) and over obstacles (`WALL_HOP`).
  - It never rolls upwind: if you are behind it, it opens and walks.
  - If you jump over it, it opens behind you.
- **UNROLL** at `GRAB_R` 58: the ball opens wide with thorny arms spread (`UNROLL_T` 0.28, the warning), then GRAB.
- **GRAB:** a thorny hug (`player.grab`) that squeezes every `SQUEEZE_EVERY` 0.9 s for 1 heart.
  - You break free with A/D. It also lets go after `HOLD_MAX` 2.2 s or on a `HEAVY_HIT` 22.
  - A release leaves it in STUN, a window to shoot it.
- **WALK:** a brain zombie with the ball on its back like a cloak. A gust with you downwind makes it CURL and roll again
  (`CURL_CD`).
- **Counter - the ball:**
  - Shots strip twigs (`BALL_HP` 30); only `BALL_LEAK` 0.35 of the damage reaches the body. Stripped bare, it is exposed
    and dazed.
  - Fire burns the ball at once (and it burns). An explosion breaks the ball.
  - Barbed wire catches a rolling ball (SNAG).
- **Learns:** a lone roller stopped before it reaches you is a lesson (main meta `tb_lessons`). After `LEARN` 3 lessons
  the next ones wait for a gust (`gust_k` > 0.5, or `WAIT_MAX` 9 s) and roll together as a pack (`PACK_R` 650,
  `PACK_BOOST` 1.2). Caption: "THEY WAIT FOR THE WIND".

**Story hooks** (call on `main._stage`)
- `story_stretch()` returns `Vector2(3700, 5700)`: flat road with no obstacles, traps, wires or placed zombies, and no
  drifter waves.
  - The STRANGER stands at x 4500.
  - A decor flock (9 sheep, `STORY_FLOCK` 4900..5250) grazes there for the scene.
- `on_story_beat(id)`:
  - "gust" - `force_gust()`, a full gust now (the scene's first line)
  - "flock_scatter" - every sheep within 1400 px flees and nearby shearers burst (the scene's last line)
  - "calm" - jumps to the lull
  - "stampede" - bursts the corral
- `wind()`, `gust_k()`, `warn_k()`, `force_gust()`.

**Tunables** - in each file header.
- Stage: `BREEZE`, `CALM_T`, `WARN_T`, `GUST_T`, `LULL_T`, `AIR_PUSH`, `SHED_X`, `TOWER_X`, `TURBINES`, `PUESTO_X`, `GAS_X`,
  `WIRES`, `CORRAL_X`, `BALES`, `STORY_X`, `FLOCKS`, `PERCHES`, `DRIFT_WAVES`, `TUMBLERS`, `PACK`, `PUMPS`, `FENCES`.
- `zombie_weights()`: SHEARER 0.03, DRIFTER 0.035, TUMBLER 0.05, regulars 0.56, runners 0.32.
- Balance was not touched (MINIGUN 140, GOD 13.8 s, no big ammo piles).

**Tests** (test project, outside the repo)
- **Headless:** no script errors in any of these runs:
  - 1600 frames from the start;
  - 900 frames with the player at x 3000, 6000, 9300 and 9760 (boss), story marked seen;
  - 900 frames at 4400 with the story scene playing.
- **Playtest bot (`t_bot.gd`):** FINISHED in every run. The STRANGER scene played 36 s in each run; the stuck events were
  fights the mortal bot waited out.

  | Run | Time | Deaths | Stuck | Teleports |
  | --- | --- | --- | --- | --- |
  | god, seed 5 | 121 s | 0 | 1 (3 s) | 0 |
  | mortal, default seed | 152 s | 2 | — | 0 |
  | mortal, seed 77 | 187 s | 7 | — | — |
  | mortal, earlier default-seed run | 225 s | 4 | — | 2 |

  - Seed 77 is comparable to stage 54 on the same seed: 188 s, 6 deaths.
  - The earlier default-seed run teleported twice in the story stretch, waiting on zombies that had walked in.
- **Behaviour counters (`t55.gd`):** every check passes.
  - shearer: 1 burst, 1 leap, 6 snips / 6 hits; 2 early finds → learned; a learned one let the player pass and burst
    behind him.
  - boss: 2-3 snaps, 2 charges, 1 jam on the bales, 1 flock call, 19-23 engine hits; died in about 16 s of point-blank
    fire.
  - drifter:
    - flight: 3 dives / 3 hits, 3 landings, max air 4.5 s;
    - canopy: 6 hits → 2 rips → 2 crashes → dead, learned after 2;
    - learned: 1 cut-loose;
    - fire: 1 burn → down; blast: rips the canopy.
    - perched and kiting drifters both launched.
  - tumbler: roll → unroll → grab (2 squeezes, 1 release); shots stripped the ball; fire burned it; the barbed wire
    snagged it; learned: waited, then 3 rolled as a pack on the gust.
  - wind: 3 gusts, range -1..0, the player pushed in the air (260-627 px), all 4 story beats run.
  - walk (traps): 1 sheet flight, wire snags, 1 blade fall, 1 corral burst. The gas bottle tips only when a gust catches
    the player near it, so it is not hit on every run.
- **Fixed during testing:**
  - A perched drifter landed back on its own deck; its flight `collision_mask` is now 1, restored on landing.
  - Tumblers and flocks spawned inside generated obstacles and sank; their spawn spots are now reserved.
  - The boss died too fast because engine hits stacked the head bonus; there are now per-zone multipliers.
  - The learned shearer burst before the player passed; the pass logic was simplified.
  - The "ESQUILA" sign was hidden behind the loft pickups; it moved below the loft.
  - Scripted test scenarios now clear random `cover` obstacles, so they are not flaky.

## Stage 56 - "ICE FJORD" (THEY LEARNED THE COLD)

Zone 7 (Patagonia), stage 2. A frozen fjord under Fitz Roy-style granite spires. Blue glacier walls calve into black water, and dead fishing boats sit frozen in the sea ice.
The level starts on the wooden dock of a fish cannery on stilts and ends at the glacier front.
THE ARCHITECT is dead (54) and nothing changed: the hive thinks as one. Here the dead learned two things.
First, heads break, so they armor them in ice. Second, the cold keeps them from rotting.
Every kill sends its spores to the nearest corpse-mate (the shared `effects/spore_lesson.gd` from 55, so this level adds no spore code of its own).

**Files**
- `levels/stage_56.gd` - layout, spawns, freezing water, story beat. Sounds: `ti_crack`, `ti_break`, `cv_groan`, `cv_crash`, `hk_rattle`, `hk_run`, `fd_hiss`, `fj_rumble`.
- `effects/s56_decor.gd` - sky, 3 parallax layers, all world objects and traps, `IceArt` (shared ice-cliff painter).
- `enemies/types/thawed.gd` - THAWED, which is also the boss THE GLACIER (+ `IceShards`, `IceBlock`, `Shockwave`, `ShatterFlash`).
- `enemies/types/buoy.gd` - BUOY, the flyer (+ `Balloon`, `PopFx`, `Ascend`).
- `enemies/types/sealer.gd` - SEALER (+ `Spot`, `Bubbles`, `IceBreak`).
- Map picture: `map/thumbs/level_56.png`.

**Background (Backdrop)** - every layer animates on `t`.
- `fjord_sky`: a bright polar dusk sky with stars, a low sun with a halo, three aurora curtains (green / teal / violet) that wave, clouds and birds.
- `far_peaks` (0.06): granite spires with snow flags blowing off the tops, and a glacier tongue.
- `mid_fjord` (0.28): fjord water, drifting icebergs, a stuck trawler and white seabirds.
  The blue glacier front calves into the water every `CALVE_EVERY` s, or at once when `calve_ms` is set.
- `near_floes` (0.6): bobbing floes on black water, pressure ridges, frozen piles with icicles, blowing snow and sea smoke.
- `fjord_overlay`: a cold `haze_band` at screen y 420-612, behind the characters (readability rule).
- Screen FX: the "ash" particles recolored as blowing snow, plus `FjordFX` (spindrift and a cold tint, scaled by `Quality.ambient()`).

**Ground / water**
- `IceGround`: snowy sea ice with frozen bubbles and cracks. Before `DOCK_END` it is a frosted plank dock on piles.
- `WaterLead` (`LEADS`): open water between floes.
  - Walking through it is slow (`player.in_water`).
  - After `FREEZE_T` s in it you take 1 damage ("FREEZING WATER!", stage `_physics_process`).
  - Leads are added to `main._spawn_avoid`, so nothing spawns in the water.
  - There are no death pits in this level.
- `FishingHole` (`HOLES`): a hole in the ice with an orange tip-up flag. The flag pops up and the water boils when a SEALER is about to come out.
- `ice_at(x)` on the stage says where a SEALER may break new ice. It may not on the dock, inside a boat hull or next to open water.

**Layout / upper floors** - every high place has ladders and a pickup.
- `Cannery` (`CANNERY`): a walkway (`CANNERY_TIER`), a roof (`CANNERY_ROOF`, a third floor) and 3 ladders.
  The "CONSERVERA AUSTRAL" sign, fish boxes and a `HookLine` hang in front.
- `FrozenBoat` (`BOATS`: SAN JUAN, MARIA AUXILIADORA, DON PEDRO): a deck (`BOAT_DECK`) and a wheelhouse roof (`BOAT_CAB`), each with a ladder and a pickup.
- `IceLedge` (`LEDGES`): ledges in the glacier wall (`LEDGE_TIER`), with 2 ladders each.
- `GlacierArena` (boss) at `level_w - 1100`: the glacier front with a blue ice cave (THE GLACIER comes out of it).
  - A hiding ledge (`ARENA_LEDGE`, `ARENA_TIER`) with a ladder and ammo.
  - 2 `Calving` ledges and 2 `FuelDrum`s.
  - Health and ammo just before the arena.
- Obstacles `ice_block` (a frozen fish inside), `fish_box` ("MERLUZA") and `net_pile` (nets and floats) come from `custom_gen`.
  They skip reserved spots and water. All are solid and in group `cover`.
- `extra_spawns`:
  - a regular zombie on every deck
  - a THAWED plus a regular after every drum (`THAWED_AT`): the drum is the answer to the ice
  - `BUOYS` (8) and `SEALERS` (6, under the fishing holes)
  - a group next to every boat
  - 2 regulars in the arena
- `zombie_weights()`: THAWED 0.045, BUOY 0.03, SEALER 0.03, regulars 0.55, runners 0.33. `zombie_density()` uses `HARDER` by difficulty.

**Traps** (all in group `hazards` with `world_rect()` / `danger_at()` for the bot)
- `ThinIce` (`THIN`): stand on it and it cracks (`CRACK_T`, crack sounds), then breaks.
  - The break deals `DMG` plus a slow (`SLOW`) to you and `DMG_Z` to zombies standing on it.
  - It leaves open water, which joins group `ice_holes` (a SEALER exit), and it refreezes after `REFREEZE`.
  - A blast breaks it at once (it is `blastable`).
- `Calving` (`CALVING`): an ice shelf hanging from a glacier wall.
  - When you come near (`TRIGGER`) it groans, cracks spread and a shadow shows on the floor (`WARN_T`). Then ice chunks fall (`DMG`, `DMG_Z`, 25 on the boss).
  - Shooting the blue crack (a layer-4 body) drops it in `SHOT_WARN`, which is how you drop it on a crowd.
  - It regrows after `REGROW_T`. The wall behind it is drawn behind the characters (`Calving.Wall`, z -2).
- `HookLine` (in front of the cannery): when you enter, a bell rings and a lamp lights (`WARN_T`). Then the cart runs the rail with a fish hook at chest height (`SPEED`).
  - Crouch, jump or roll under it, or take `DMG`.
  - It hooks up to 2 zombies (`DMG_Z`), drags them and flings them.
  - Shooting the motor box starts it on your timing (cooldown `CD`).
- `FuelDrum` (`DRUMS`): a frozen fuel drum. `HP` bullets crack the frost, then it hisses (`FUSE`) and blows with source "barrel" (`BLAST_R`, `BLAST_DMG`).
  The blast strips THAWED ice and breaks thin ice nearby.

**THAWED** - a dead fisherman frozen inside a shell of ice. You see the body through the blue armor: a knitted sweater, oilskin bib trousers, a beanie, blue skin and lips, sometimes a frozen fish on the belt.
- Colors change per zombie (6 sweaters, 4 oilskins, beanie or none, ice tint).
- Heavy and slow, and its steps crack the ice.
- **What it learned:** thousands died from a bullet to the head. Ice stops a bullet better than a skull, so they went into the water, came out and froze, helmet first.
- **Ice plates** (`HEAD`, `CHEST`, `ARM` front forearm, `LEGS`), each with `LAYERS` layers of `LAYER_HP`:
  - A bullet into an iced plate only chips it (shards, more cracks). It is absorbed (`on_damage` returns false). A broken layer bursts into shards.
  - The head is armored until the helmet breaks. The first helmet hit pops "ICE HELMET" and the line "They froze their heads... break the ice first. Fire melts it".
  - A plate that is gone shows frozen flesh (x`SOFT_MULT`, "HEAD EXPOSED").
  - Fire melts every plate: burning melts `MELT_RATE`/s with steam, and incendiary bullets do x`INC_MELT` and ignite.
  - Explosions take `BLAST_ICE` from every plate, and the body takes only x`ICED_BLAST` while it is still iced.
- **SLAM:** it lifts both frozen fists (`WIND_T`) and smashes (`DMG`, plus a `CHILL` slow). Fully stripped, it moves faster (`BARE_SPEED`).
- **Death:** the ice shatters (`IceShards`: up to 260 shards, batched into one triangle-array draw), frozen gore (`Quality.gore()`) and a ragdoll.
- **Learns** (main meta):
  - `th_heads` >= `HEAD_LEARN` (helmets you broke): new ones cover the head with the iced forearm while you aim at it ("IT GUARDS ITS HEAD NOW").
    Counter: break the arm ice first, shoot the body, or wait for the arm to drop when it slams.
  - `th_stripped` >= `STRIP_LEARN` (THAWED you fully stripped): new ones refreeze a thin layer (`THIN_HP`) after `REFREEZE_T` without a hit, up to `REFREEZE_MAX` times ("IT REFREEZES").
    Counter: keep shooting, or use fire (no refreezing while it burns).

**THE GLACIER** (boss, `chase_range > 600`, `boss_name` "THE GLACIER") - a giant (x2.5) inside a glacier block: a red oilskin coat under thick ice, with ice-club arms.
- Hitbox 46x66. Plates `BOSS_LAYERS` x `BOSS_LAYER_HP`; side hits on the front half go to the ARM plate. It always refreezes (`BOSS_REFREEZE_T`, a full layer on the most damaged plate).
- **SMASH** (`SMASH_WIND`): an ice shockwave along the floor (`SMASH_R`, `SMASH_DMG`). Jump it or stand on the ledge.
- **THROW** (`THROW_WIND`): it tears off an `IceBlock` and lobs it at you in an arc, up to the ledge too (`THROW_R`, `THROW_DMG`).
  The block can be shot out of the air (layer-4 body, also `blastable`). Under 50% hp it throws two.
- **ROAR -> CALVE:** every `CALVE_EVERY` under 70% hp it roars and stomps, and the arena `Calving` nearest to you drops (`stage.calve_near(x, 0.8)`). The falling ice also hurts the boss.
- **Death:** a huge shatter and a flash (`ShatterFlash`).

**BUOY** - the flyer. A dead fisherman in an orange survival suit (reflective tape, hood or knit cap, frosted beard).
His harness is tied to a cluster of 5-6 floats: white or tinted weather balloons, hard orange net floats and boat fenders. The mix and colors change per zombie.
- **What it learned:** "you shoot what walks at you, on the ground, in front of you". So they rose above the line of fire and drop on you from above.
- It hovers over you at `ALT_PER` x (floats left) and drifts in the wind.
- **Attack cycle** (always: it comes down every 2-3 s, `ATTACK_CD`):
  - **TELL** (`VENT_T`): it pulls the valve (hiss) and a target ring appears on the floor where you stand.
  - **DROP**: it falls on you feet first (`DROP_SPEED`, `DROP_DMG`). Roll or step aside.
  - **LOW** (`LOW_T`): it hangs low and swings a gaff hook (`GAFF_*`). Here every weapon reaches its body, melee and flamethrower too.
  - **RISE**: it climbs back up.
- **Balloons:** each float is its own `Balloon` body (layer 4, `hit_by_bullet`, plus group `blastable`). Any bullet, pellet, arrow, flame, laser or blast pops it; an orange float takes 2 hits.
  - With fewer floats it flies lower. With none it falls:
    - onto the ice: a splat with damage by height (`FALL_DMG_K`, usually death). If it survives it is "GROUNDED", a limping normal zombie.
    - into open water: it sinks.
- Killed in the body while 2 or more floats remain: the corpse drifts up into the sky, dripping blood (`Ascend`). A last single float flies away alone.
- **Learns** (main meta `buoy_pops` >= `POP_LEARN`): new ones circle round and drop from behind you, on the side you are not aiming at ("IT COMES FROM BEHIND").
  The hiss and the floor ring still warn you. Counter: turn and roll.
- Unlike glider / ironwing / swinger / stacker it has no wings, rope or perch. It is lift you can shoot off piece by piece, and the drop is a vertical stomp with a floor marker.

**SEALER** - a dead seal hunter wearing the pelt of a seal he killed.
- The seal's head is his hood (snout, black eyes, whiskers) and the hind flippers hang behind.
- He wears sealskin boots, oilskin trousers (yellow / orange / navy), a red rope belt and an iced beard.
- He carries a hakapik: a wooden club with a hammer and hook head.
- The pelt is a silver harp seal with a dark "harp" saddle, or a brown fur seal.
- **What it learned:** "you shoot what you can see". So they went under the ice where bullets cannot reach and come up only to strike.
- **Cycle:**
  - **SUB**: it swims under the ice. `collision_layer` is 0 and every hit is absorbed. You see only a dark seal-shaped shadow and a bubble trail moving inside the ice (z above the ground).
    It heads for the open `ice_holes` node nearest you within `EXIT_R`: a fishing hole, a lead, broken thin ice or its own break. If there is none, it breaks the ice `BREAK_X` from you.
  - **TELL** (`TELL_T`): the water boils and the tip-up flag jumps, or cracks spread over the ice.
    The bubbles are a `Spot` body. Shoot them and it is thrown out "SPOTTED", stunned (`STUN_T`, damage x`STUN_MULT`). A blast over its shadow does the same (depth charge).
  - **BURST**: it leaps out at you, club first (`LUNGE_V`, `LUNGE_DMG`).
  - **SLIDE**: it lands and belly-slides like a seal (`SLIDE_T`). The hitbox becomes low and wide while it lies down.
  - **RETURN**: it walks to the nearest open hole (`HOLE_R`) and **DIVE**s. It clubs you if you are close (`CLUB_*`).
    With no hole near, it **CHOP**s a new one (`CHOP_T`, a window to shoot it). An `IceBreak` refreezes after 14 s.
- **Learns** (main meta `sealer_spotted` >= `SPOT_LEARN`): it fakes the bubbles at one hole (decoy `Bubbles`), swims fast (`FEINT_SPEED`) under you and bursts from the other side (`FEINT_BEHIND`, a short crack tell).
  Popup "THE BUBBLES LIE NOW" and the line "They saw me shoot the bubbles... watch the shadow, not the bubbles".

**Story beats** - `on_story_beat("calve")`: the glacier in the background calves now (`Decor.calve_ms`, a rumble and a camera shake). The hanging `Calving` within 900 px of the player that is nearest drops too, with its normal warning. This level has no story scene.

**Tunables** - in each file header.
- Stage: `DOCK_END`, `CANNERY`, `BOATS`, `LEDGES`, `LEADS`, `HOLES`, `THIN`, `CALVING`, `DRUMS`, `THAWED_AT`, `BUOYS`, `SEALERS`, `FREEZE_T`, `zombie_weights()`.
- Decor: `CALVE_EVERY`, and the trap constants above.

## Stage 57 - "PENGUIN COAST" (THEY LEARNED TO BE MANY)

Zone 7 (Patagonia), stage 3. A cold, windy beach at the end of the world: a living penguin colony on a pebble beach,
giant kelp, an old red-and-white lighthouse and a ruined whaling station (rusty oil tanks, a flensing gantry, whale
bones). THE ARCHITECT died at the bridge (stage 54) and nothing changed: there is no leader any more, the hive thinks
as one. Here the dead learned that a body can be shot, so some of them stopped needing one: a flock of dead birds
flies in the shape of a man, and the dead hide inside the colony because they learned you won't shoot into a crowd
of the living. Near the lighthouse the hive speaks for the first time (THE CHORUS scene).

**Files**
- `levels/stage_57.gd` - layout, spawns, decks + pickups, story hooks. Sounds `pg_squawk`, `pg_flee`, `s57_burst`,
  `s57_whoosh`, `s57_chain`, `s57_swoosh`, `s57_wave_roar`, `s57_wave_crash`, `s57_wind`, `s57_chorus` (all synth).
- `effects/s57_decor.gd` - sky + 3 parallax layers, the colony, all world objects, traps and the screen FX.
- `enemies/types/waddler.gd` - WADDLER (also the boss, THE BEACHMASTER). Sounds `wd_*`, `bm_*`.
- `enemies/types/murmur.gd` - MURMUR (+ `FX`: falling dead birds / feathers / fleeing birds). Sounds `mm_*`.
- `enemies/types/blubber.gd` - BLUBBER. Sounds `bl_*`.
- `map/thumbs/level_57.png`.

**Background (Backdrop)**
- `coast_sky`: heavy overcast gradient, a pale band of light over the sea, moving sun rays, wind-torn clouds, gulls and
  petrels riding the wind (some are blown backwards in a gust).
- `far_coast` 0.06: the snowy Tierra del Fuego range, cliffs, icebergs on the horizon, a rusty wrecked whaler and a far
  lighthouse that blinks.
- `mid_bay` 0.28: rolling waves breaking on rocks, sea lions and penguins on the rocks, kelp beds, and a distant
  murmuration that keeps changing shape (a hint of the MURMUR). THE CHORUS face also lives here: 190 birds that form a
  giant face over the sea (`Decor.U.face_ms`), move its mouth while it talks (`U.talk`) and break apart (`U.break_ms`).
- `near_shore` 0.6: the pebble bank behind the road with tussock grass in the wind, whale ribs, upturned boats, anchor
  chains, penguin burrows with heads peeking out, walking gulls.
- `coast_overlay` + `CoastFX` (screen): wind streaks, sea spray, snow flecks, `gust()`.
- Everything is batched into triangle arrays (`U.flush` -> `RenderingServer.canvas_item_add_triangle_array`).

**Layout / upper floor**
- `COLONIES` (1150, 2350, 4150, 8450): a `Colony` each with 1-2 WADDLERs hidden inside. `STORY_COLONY` 6240 has no
  zombies (the scene actor stands in it). `BOSS_COLONY` 9620 is in the arena.
- `SKELETONS` 2700: a `WhaleSkeleton` with a plank along the spine (deck at `SKEL_TIER` 170, 2 ladders, AMMO up top).
- `TANKS` 3330 / 4640: whale-oil tanks with a walkway on the roof (`TANK_TIER` 165, ladder, HEALTH / AMMO).
- `GANTRY` 3820: the flensing gantry (deck at `GANTRY_TIER` 205, 2 ladders, a GRENADE) with the `GantryHook` under it.
- `LIGHTHOUSE_X` 5350: the keeper's house roof (`HOUSE_TIER` 150) and the lamp gallery (`GALLERY_TIER` 300, HEALTH),
  ladders to both. Lamp beam sweeps.
- Obstacles `drums` / `boat` / `boulders` / `vertebra` come from `custom_gen`.
- `ARENA_X` 9240: `BossBeach` (wet boulders, the slipway, a whale skull, the "ESTACION BALLENERA PUNTA 1906" sign),
  HEALTH + AMMO, a regular and a runner.

**The penguin colony** (`Decor.Colony`, group `s57_colonies`)
- Harmless animated penguins (Magellanic, King and Gentoo, each one varied). They huddle (`HUDDLE`), wander
  (`WANDER`), and scatter (`SCATTER_T`) when you fire within `HEAR_R` 560 px, walk into them (`TOUCH_R`), or a blast
  or a charge hits them. Scattered penguins run, belly-slide and tumble, then regroup (`REGROUP_T`).
- While huddled the colony is a shield (`ColonyBody`, layer 4): a bullet into the crowd hits a penguin (it falls, feathers,
  no kill, no score) and the colony scatters. "THE COLONY SCATTERS"; the hero: "Not the birds... they hide in there."

**Traps**
- `OilBurst` (`OIL_BURSTS` 3640, 5000, 8900): a small whale-oil tank on the road. Shoot it (or blast it) and oil gushes
  out into a `Slick` (`SPREAD` 300 px) that ignites after `IGNITE_T` 0.7 s (`FireZone`, `BURN_T`).
- `Slick` (group `s57_slicks`): slippery (`player.slip_t`), zombies stumble on it (`STUMBLE`), it ignites from fire,
  explosions, burning zombies or a fire hazard and spreads the fire to slicks next to it. A wave douses it. The BLUBBER
  leaves one when it dies.
- `GantryHook`: stand under it (`TRIG_R`) and the chain rattles while the hook pulls back (`WIND_T`), then it swings
  across the road (`SWING_T`): `DMG` to you, `DMG_Z` to zombies (impales them). Shoot the pulley to swing it when you
  want (`release`).
- `WaveSurge` (`WAVES` 1620 / 7760): a stretch the sea washes over. A wave rises behind (`WARN_T`, a roar), then floods
  the road (`SURGE_T`): it pushes you back (`PUSH`), knocks zombies down and douses burning slicks. Up on a deck or in
  a jump it misses you.
- `SlickRocks` (`ROCKS` 880, 3150, 8180): flat wet rocks with kelp. You slip and zombies stumble.

**WADDLER** - a hunched dead man in a black-and-white parka whose hood is shaped like a penguin's head (white cheek
stripe, orange patch, a peak like a beak), long sleeves that hang like flippers, claws, orange rubber boots.
Learned from: the hero does not shoot into a crowd of the living, so they hide among the living.
- **HIDE:** crouches inside a colony and moves with it. Hidden it takes x`HIDE_MULT` 0.6.
- **REVEAL:** the colony scatters, you come close (`AMBUSH_R`) or it is hit: it stands up taller than the penguins,
  red eyes, blood on the white front (`REVEAL_T`, a shriek).
- **WADDLE -> WIND -> LUNGE:** a fast waddle, then a crouch (`WIND_T`) and a clawed leap (`LUNGE_V`, `LUNGE_DMG`).
- **FLOP:** a missed lunge lands it on its belly sliding (`FLOP_T`, x`FLOP_MULT` 1.5).
- Counter: one shot near the colony (or walk into it) scatters the penguins and exposes it; jump or roll the lunge.
- **Learns** (main meta `wd_kills` >= `LEARN_KILLS` 2): "IT WAITS FOR THE COLONY NOW" - when the colony scatters it
  does not attack but runs with the penguins and waits for them to huddle around it again (`WAIT`, up to `WAIT_MAX`),
  pushes the colony towards you (`Colony.lure`) and only leaps out when you are very close (`LEARN_R`, a shorter wind).
  While it waits it is exposed.
- Scene actor: `talking`, `tilt`, `smile`, `t`. Out of group "zombies" it never lunges or deals damage and takes no hits.

**THE BEACHMASTER** (boss, `chase_range > 600`) - a giant WADDLER, master of the beach, with feathers stuck in the parka
and a harpoon in the back.
- **SLIDE:** drops on its belly (`SLIDE_WIND`, dust) and slides along the beach (`SLIDE_V`) - jump it. It flattens
  penguins and stops after it passes you by `SLIDE_PAST` or at the arena edge (`ARENA_W`).
- **WALLOW:** after a slide it lies on its belly (`WALLOW_T`), its back open (x`WALLOW_MULT` 1.6).
- **FLOP:** when you are close (`FLOP_R`) it jumps and lands on you: a shock ring on the ground (`SLAM_R`).
- **ROAR:** roars (`ROAR_T`, chest open x`ROAR_MULT`) and calls `ROAR_N` WADDLERs out of the surf (up to `ROAR_MAX`).
- Front armour x`ARMOR` 0.8. Learns in the fight: after 2 jumped slides or below half HP, "IT TURNS BACK NOW" - the
  slide reverses at once.
- Death: its summons drop with it, the colonies scatter, big roar + shake.

**MURMUR** - a flock of dead birds (imperial shags, kelp gulls, brown skuas; red eyes, rotting raw patches) flying in the
shape of a man: head, shoulders, an arm reaching out with talons, two legs. One bird in the chest is red and glows -
the heart - and pale green spore threads tie every bird to the next.
Learned from: a body can be shot (the Architect died and nothing changed), so they stopped needing one body.
- **GATHER -> FORM:** a swirling cloud high in the sky; when you come within `WAKE_R` it forms the man.
- **DRIFT:** hovers above you (`HOVER_H`) to one side (`SIDE_OFF`), each flock at its own height, and switches sides
  after every dive. Two flocks never merge into one blob.
- **WIND -> SWOOP:** the shape tightens into a clawed hand pointing at you, the heart blazes, a screech (`WIND_T`),
  then it dives through you in an arc (`SWOOP_T`): `RAKE_DMG`. It always comes down within `SWOOP_CD` + `WIND_T`
  (about 2-3 s).
- **Hits:** every bullet is traced from its entry point along its path: it kills the first bird it passes (`BIRD_R`).
  The bird falls dead with feathers and blood, and the shape re-forms smaller. A bullet through a gap flies on
  (pierce). Every `BIRD_HP` damage is one bird. Below `BREAK_FRAC` of its birds the flock breaks: half fall dead,
  half flee into the sky ("THE FLOCK BREAKS"). Head/leg zones are normalised (x0.45 / x1.5).
- **The heart:** a shot aimed at the red bird hits it even through the birds around it: x`HEART_MULT` 3, the flock
  flinches apart, a new heart is chosen after `HEART_BACK`. `HEART_HITS` 3 hearts break the flock at once.
- **Explosions** (x`BLAST_MULT` 2) tear a chunk from the side facing the blast and blow the rest apart. Fire sets birds
  burning and they drop one by one. Every weapon kills it (bullets, melee, blasts, fire, taser/laser).
- Counter: shoot the heart while it tightens before a dive (it is densest then), jump/roll the swoop, grenade it low.
- **Learns** (main meta `mm_breaks` >= `LEARN_BREAKS` 2 broken flocks): "IT SPLITS NOW" - a heavy hit (blast, heart, or
  `SPLIT_DMG`+) on a flock of `SPLIT_MIN`+ birds splits it into two smaller flocks that attack from both sides (once).
  "IT FEINTS NOW" - sometimes (`FEINT_CHANCE`) it dives halfway, pulls up and then dives for real.
- Performance: no node per bird. The whole flock is one triangle array; falling/fleeing birds and feathers are one
  shared `FX` node per level (`CAP` 140). `N_BIRDS` 52 per flock, at most `TOTAL_MAX` 240 birds across all flocks
  (never fewer than `N_MIN` 34 per flock). The bird hitbox is the flock's bounding box, refitted every frame.

**BLUBBER** - a dead man who crawled inside the hide of a huge bull elephant seal and is sewn into it: a long grey-brown
sack of blubber, peeling moult patches, pink battle scars, crude black stitches. The seal's head with its drooping
proboscis is a helmet; under it, in the seal's open mouth, is the pale face of the dead man with red eyes. His human
arms come out of the chest like flippers and drag the body. The back is torn open: raw red flesh, spine and ribs - the
weak spot. Each one varies (hide tone, moult, scars, a stuck harpoon, kelp).
Learned from: the elephant seals on the beach survive anything with blubber and a belly that slides on the pebbles.
- **SEEK:** galumphs towards you, slowly. If you get behind it, it turns slowly (`TURN_T`, back exposed x`TURN_MULT` 1.8).
- **BELLOW -> CHARGE:** rears up, proboscis inflates, a deep bellow (`BELLOW_T`), then a belly-first charge
  (`CHARGE_V` 440, up to `CHARGE_T`, stops `CHARGE_PAST` after passing you): `CHARGE_DMG` + knockback, bowls other
  zombies over, scatters colonies. Hitting a wall stuns it ("STUCK!", `WALL_STUN`).
- **WALLOW:** after a charge it wallows in the sand (`WALLOW_T`), open from every side (x`WALLOW_MULT` 1.5).
- **Armour:** the front hide takes x`FRONT_MULT` 0.6 (x`CHARGE_FRONT` 0.3 while charging, "THICK HIDE", after 3 the
  hero says "Its hide's too thick - get behind it!"). The back takes x`BACK_MULT` 1.8. Fire x`FIRE_MULT` 1.3.
- **Death:** a big wet burst (blood, blubber chunks, water, shake) that leaves a flammable oil `Slick` (`SLICK_W`) and
  the flat empty hide on the beach.
- Counter: wait for the charge, jump it, and shoot its back while it wallows or turns.
- **Learns** (main meta `bl_dodges` >= `LEARN_DODGES` 2 dodged charges): "IT FAKES THE CHARGE" - a short fake lurch
  (`LURCH_T`) that stops dead so you jump for nothing, then the real charge after a short bellow (`FEINT_PAUSE`).

**Spores** ("they learn", story rule 3): the shared `effects/spore_lesson.gd` (zombie.gd, from level 55) carries the
lesson from every kill to the nearest zombie. The stage adds nothing on top of it.

**Story hooks** (call on `main._stage`)
- `story_stretch()` returns `Vector2(5600, 7600)`, a clean beach right after the lighthouse: no spawns, traps or obstacles.
  `story_colony()` returns the colony at 6240 (`STORY_COLONY`), where `story/scenes/l57_chorus.gd` stands its WADDLER.
- `on_story_beat(id)`:
  - "flock_form" - 190 birds form a giant face over the sea
  - "flock_break" - the face breaks apart and flies off (+ a gust)
  - "talk_on" / "talk_off" - the face's mouth moves
  - "penguins_flee" - every colony within 1500 px scatters
  - "wind" - a gust
  - "beam" - the lighthouse beam brightens

**Tunables** - in each file header. Stage: `COLONIES`, `STORY_COLONY`, `BOSS_COLONY`, `SKELETONS`, `TANKS`, `GANTRY`,
`LIGHTHOUSE_X`, `OIL_BURSTS`, `WAVES`, `ROCKS`, `MURMURS`, `BLUBBERS`, `STORY_X`, `ARENA_X`, `zombie_weights()`
(WADDLER 0.03, MURMUR 0.025, BLUBBER 0.03, regulars 0.56, runners 0.33).

**Tests** (test project, outside the repo)
- Headless `t_run`: 1500 frames from the start, and 900 frames each at px 3000 / 6000 / 9300 / 9760 (boss arena), with the story scene allowed to play. There was no SCRIPT ERROR in any run.
- `t57.gd diag`: 900 frames each at 3000 / 6000 / 9300 / 9760 with the story trigger removed. There were no errors.
- Behaviour tests (`t57.gd <mode>`) use counters:
  - **waddler**:
    - Hides in the colony.
    - Reveals when hit.
    - Lunges 2/2, both hit.
    - Kills 2 zombies with the summon.
    - Learned (via main meta) after 6 lures and lunges early.
  - **boss**: killed at frame 1663 while staying inside the arena.
  - **murmur**:
    - Flock breaks and 38 dead birds land.
    - The learned flock re-forms at 52 birds.
    - A heavy hit on a learned flock splits it (34 -> 21 + 20).
    - Blasts take chunks.
  - **heart**: 3 heart hits kill a flock that still has 11 birds.
  - **blubber**:
    - Front shots are armoured: 4 shots did 33 damage, while 1 back shot did 23.
    - The charge bowls over 2 zombies.
    - Death leaves a slick.
    - After 2 dodges it learns and fakes the charge (lurch).
  - **traps**:
    - Oil burst makes a slick, and the slick ignites.
    - Gantry hook hits 1 and hooks 2.
    - Wave surge knocks the player back.
    - Slick rocks cause 2 stumbles (0 slips in this run).
  - **colony**: scatters on a shot and regroups.
- `t_bot` with god=0: FINISHED in 152.5 s at 97% progress, boss killed, 2 deaths, stuck 7, tp 0, worst frame 49 ms, avg 11.1 ms. Level 54 baseline: 204 s, 10 deaths. With god=1 it finished in 100.8 s.
- xvfb opengl3 renders: `/mnt/project-files/levels-55-57/shots/l57_{lineup,whaling,murmur,boss}.png`.
- Known issues and notes:
  - The test project stubbed the level 55/56 workers' WIP files, because they had parse errors at the time.
  - An earlier bot run had a single 309 ms frame at x~3384 (first use of something). It did not happen again on the final run.
  - Godot prints "1 resources still in use at exit" at the end of the headless traps test. This comes from the test harness quitting.

## Stage 58 - "WHALE GRAVEYARD" (THEY LEARNED TO WEAR THE DEAD)

Zone 7 (Patagonia), stage 4. After the CHORUS on the penguin coast (57) the hero follows the coast to PUERTO HUESO, a
whaling station abandoned since 1911. The spores carried thousands of headshot deaths, so the hive learned that skulls
break and whale bone does not. So the dead wear the dead. It also learned that ECHO can grow in any dead thing, and the
dead here are enormous: the station has become an ECHO farm. Carcasses breathe and give birth, and the hive writes to the
hero on the oil tanks. In the west, over the mountains, a column of smoke: the Black Forest is burning (59).

**Files**
- `levels/stage_58.gd` - layout, spawns, skua waves, intro hints, the hero's story lines. Sounds `s58_pop`, `s58_gurgle`,
  `s58_burst`, `s58_crank`, `s58_click`, `s58_harpoon`, `s58_thunk`, `s58_hiss`, `s58_wind`, `s58_gulls` (synthesised; no
  new files). Music `level1_total_war.mp3`.
- `effects/s58_decor.gd` - sky + 3 parallax layers, all world objects, traps and screen FX.
- `enemies/types/flenser.gd` - FLENSER and the boss THE BONE KING.
- `enemies/types/skua.gd` - SKUA (+ `WingBody`).
- `enemies/types/bonecrawler.gd` - BONECRAWLER.
- `map/thumbs/level_58.png` - level card.
- Death spores need nothing extra: zombie.gd already sends `SporeScript` (SPORE_FROM 55) on every death.

**Background (Backdrop)**
- `grey_sky`: heavy grey sky, a pale peach band on the horizon, a low sun behind cloud with god-rays, distant rain
  curtains, gulls and skuas soaring.
- `far_isle` (0.06): steep snowy mountains with glaciers running into the sea and a low cloud stuck halfway up. In the
  west, a smoke column with an orange glow: the burning forest of 59.
- `mid_harbor` (0.28): the grey bay with waves, plus the far shore with:
  - rusty sheds, oil tanks and a white church with a spire;
  - a jetty and a half-sunk catcher with a harpoon gun;
  - a bloated whale carcass floating with gulls and a green glow.
- `near_bones` (0.6): the dark shingle bank with:
  - tussock grass, vertebrae and skulls, rib arches;
  - a rusty try-pot and a slipway rail;
  - the whalers' cemetery (crooked crosses) and glowing ECHO fungus on the bones.
- `grey_overlay`: a cold haze behind the figures.
- `GreyFX` (screen): fine slanted drizzle, drifting fog, and a sea gust every `GUST_EVERY` (`gust()` forces one; the last
  story line does).

**Layout / upper floors**
- `ARCH_X` 380: `BoneArch`, two whale jawbones with the sign "PUERTO HUESO / CIA. BALLENERA 1911".
- `TANKS` (1250, 1560, 6250): `OilTank`s. Each has a roof deck at `TANK_TIER` 170 (invisible `add_floor` + ladder) with
  AMMO (the second tank has HEALTH). The hive writing on them is glowing fungus letters: "WE REMEMBER", "COME HOME / ZERO",
  "ANY DEAD / WILL DO". A SKUA perches on tanks 2 and 3.
- `PLAN_X` 2900: `FlensingPlan`, the flensing platform: a wooden stage on piles at `PLAN_TIER` 140, two ladders, a winch,
  hooks on chains and a half-flensed whale. A GRENADE and AMMO are up there, guarded by a FLENSER.
- `CARCASSES` (3880, 6950): `EchoCarcass` traps (below).
- `BOAT_X` 4900: `CatcherBoat` "TORMENTA" on the slipway rail, with:
  - the deck at `BOAT_DECK` 120 (2 ladders) and the cab roof at `BOAT_CAB` 215 (ladder from the deck, HEALTH on top);
  - the crow's nest on the mast (a SKUA perches there);
  - a `HarpoonGun` on the bow.
- `GUNS`: the bow gun at 4880 and a gun on a low concrete base at 7900.
- `POTS` (2150, 5850): `TryPot`s.
- `ARENA_X` 9240: the boss arena in front of `BoneThrone`, a giant whale skull as a throne with a jawbone fence, an ECHO
  nest and a "PLAN No 2 / HE WEARS THEM ALL" sign. In the arena:
  - `ARENA_CASKS` at 9420 and 10120: oil casks; the boss's ram jams on them;
  - a raised plank at 130 with a GRENADE;
  - HEALTH and AMMO at the arena entrance.
- Obstacles come from `custom_gen` as `Decor.Obstacle`: `casks`, `boiler` (rusty boiler on its side), `bones` (bone pile)
  and `winch` (steam winch).
- Every world object and placed spawn has a `reserve()`d rect, so generated obstacles never cover them.
- `extra_spawns`:
  - FLENSERs at `FLENSERS` plus one on the flensing platform;
  - BONECRAWLERs at `CRAWLERS` (5300, 8350);
  - 3 perched skuas;
  - a regular on every deck;
  - 2 regulars in the arena.
- Skua waves (`_waves`): at `SKUA_WAVES` the stage launches 1 skua from the sky (meta `sk_fly`), 2 once skuas have
  learned ("Two of them... from both sides."). Two limits:
  - Never more than `SKUA_MAX` 3 in the air.
  - Waves the player passed by more than 700 px are skipped. A skua farther than 1600 px from the player despawns, so
    teleports and fast runs never pile them up.
- `_hints`: the first time each type is near, it gets an intro popup plus a hero line:
  - FLENSER: "THEY WEAR BONE NOW" / "Skulls break... whale bone doesn't. Shoot UNDER the shield."
  - SKUA: "THEY DIVE NOW" / "They learned it from the skuas... SHOOT THE WINGS."
  - BONECRAWLER: "THEY GROW IN ANY DEAD NOW" / "A whale's ribcage... with people inside. Break the ribs."
- `LINES` (environmental story, the hero talking to himself):
  - 1120: "Writing on the tanks... they're writing to me."
  - 3700: "They grow in the whales now. Anything dead will do."
  - 8050: "Smoke over the mountains... the forest is burning." This one also forces a sea gust.

**Traps** (`s58_decor.gd`)
- `EchoCarcass` (the womb):
  - A whale carcass covered in ECHO growths with glowing pustules (`PustuleBody`, `PUS_HP` 8 each).
  - Walk within `TRIG_R` 420 and it heaves (`WARN_T` 1.1, gurgle). Then it gives BIRTH: the ribs burst, a BONECRAWLER
    climbs out, and a spore cloud (`CLOUD_R` 280) sways the player's aim for `SWAY_T` 2.2 s.
  - Pop every pustule before it is triggered and it is "STILLBORN" (no birth, hero line).
- `HarpoonGun`: a harpoon cannon with a dead gunner grown into it (`GunnerBody`).
  - While you are in front of it in `RANGE` 780, it aims (`AIM_T` 0.9), locks with a laser line (`LOCK_T` 0.45), and fires
    a `Harpoon` (`V` 980). The harpoon does `DMG` 2 to the player and skewers every zombie on the way (`DMG_Z` 110,
    "IMPALED"), so you can bait it into a crowd.
  - Reloads in `CD` 3.2 s. Shoot the gunner (`GUNNER_HP` 40) and it is silent for good ("GUNNER DOWN").
- `TryPot`: two iron pots of boiling whale oil over a fire.
  - Shoot a pot (`PotBody`, `POT_HP` 2 hits) or blast it, and it cracks and spills burning oil: a `FireZone` `SPILL_W` 250
    wide for `BURN_T` 5 s.
  - It burns the player and sets zombies on fire.
- `Harpoon` (projectile, also used by the boss throw):
  - `thrower` is never impaled by its own harpoon.
  - `pull` > 0 drags the player toward the thrower and calls `thrower.type_mod.harpoon_hit(pl)`.
  - `dmg` overrides the gun's damage.

**FLENSER** - a station worker: a thick wool sweater, an oilskin apron soaked in blubber and blood, a watch cap, a beard.
In one hand a flensing knife on a long pole (a hockey-stick blade); on the other forearm a whale shoulder blade (scapula)
tied on with rope as a shield, cracked and dotted with spores.
- **What he learned:** "you shoot the head." Skulls break and whale bone does not, so he wears bone.
- **The shield:** blocks every front shot in its band (`SHIELD_H` 15 around `shield_y`). Walking, he holds it high
  (`HIGH_Y` -49, head and chest).
  - Shoot under it (belly or legs), from behind (x`BACK_MULT` 1.3), or blast it.
  - Each blocked shot chips the bone ("BONE" popup, chip sound). The chip is the shot's base damage x`CHIP` 0.6, so
    headshots do not break it faster: about 12 rifle shots break it. A blast chips `BLAST_CHIP` 60.
  - At 0 `BONE_HP` 85 it shatters ("BONE SHATTERS", bone shards) and he goes into RAGE (x`RAGE` 1.3 speed).
  - After 4 blocks the hero says "Whale bone stops bullets... shoot UNDER it".
- **HOOK:** in `HOOK_R` 85..175 he pulls the pole back (`HOOK_WIND` 0.45). The shield drops low, so his head is open. Then
  he stabs at ankle height (`HOOK_T`): jump it. A hit does `HOOK_DMG` 1, drags you to him ("HOOKED", `HOOK_PULL`) and
  slows you.
- **SLASH:** close in (`SLASH_R` 80) he raises the knife over his head (`SLASH_WIND` 0.42). The shield swings aside, so he
  is open x`OPEN_MULT` 1.25. Then he chops, followed by `RECOVER` 0.55. `CD` 0.5-1.1 s between attacks.
- **Learns:** front shots that go around the shield count in main meta `fl_around`. After `LEARN_AROUND` 8, the shield
  tracks the height you aim at (the player's aim line at his x), after `TRACK_DELAY` 0.25 s at `TRACK_V` 80. Caption "IT
  READS YOUR AIM NOW"; hero: "The bone follows my gun... aim high, then snap low". Counters: flick the aim, roll behind
  him, grenades.

**THE BONE KING** (boss; `chase_range > 600`, hp 470 base, scale 2.3, no ragdoll) - a giant flenser in a seal-skin cloak
with:
- a whale skull as a helmet (the rostrum sticks out like a beak);
- a bowed whale jawbone as a shield;
- harpoons stuck in his back and an ECHO growth bulging between his shoulders.
- **Armour:** x`B_ARMOR` 0.85 everywhere.
  - The skull helmet: head shots x`SKULL_MULT` 0.3 until it breaks (`SKULL_HP` 150, "SKULL BROKEN", hero: "The skull's
    off - GO FOR THE HEAD").
  - The jaw blocks the band in front while raised (`JAW_HP` 320, "JAWBONE", "JAW BROKEN").
  - The ECHO growth on his back takes x`GROWTH_MULT` 1.6.
- **SWEEP:** the jaw swings low and wide (`B_SWEEP_R` 250, `B_SWEEP_WIND` 0.55, `B_SWEEP_DMG` 2): jump. Afterwards he is
  open in front (x`B_OPEN_MULT`).
- **RAM:** he charges skull first (`RAM_V` 540, `RAM_DMG` 2). If he hits a wall, obstacle or the arena casks he gets stuck
  (`STUCK_T` 1.7, "STUCK - HIT HIS BACK", back x`STUCK_MULT` 2.0).
- **THROW:** at range (`THROW_R` 330, every `THROW_CD` 6 s) he throws a roped harpoon. A hit drags you to him ("REELED IN").
- **CALL:** he bellows and `CALL_N` 2 FLENSERs come in (`CALL_CD` 13 s, at most `CALL_MAX` 2 calls).
- He turns slowly (`TURN_T` 0.9), so roll behind him. If a wall or cask blocks his walk, he jumps it.
- **Learns in the fight:**
  - After `BACK_LEARN` 10 back hits: "IT GUARDS ITS BACK NOW". He turns fast (`TURN_T_LEARN` 0.25) and sweeps backwards.
    Hero: "He turns faster now... hit him while he's stuck".
  - Below half hp: "IT READS YOUR AIM NOW". The jaw tracks your aim. Hero: "The jaw follows my aim... feint it, or get
    behind him".
- `B_CD` 0.7-1.4 s between attacks; he is never idle for long.

**SKUA** (the flyer) - a dead man who sewed himself wings: baleen plates tied to his forearms like primary feathers, with
seal skin stitched between them as the membrane. A seal-skin hood and a hooked beak of whale tooth tied over his face.
- **What it learned:** the coast's skuas hunt like this. They soar high, stoop on prey from behind and climb away; the
  dead watched it from the beach for years. It does not drift with the wind (DRIFTER, 55) and it is not a flock (MURMUR,
  57): it is one fast raptor that hits and leaves.
- **PERCH:** sits on a mast or tank roof with the wings folded like a cloak. You within `PERCH_R` 640 → TAKEOFF.
- **SOAR:** high (`SOAR_H` 240-320) on your side (`SOAR_OFF` 240) in wide circles (`SOAR_V` 270). It always stoops within
  `SOAR_T` 1.5-2.7 s. Its shadow on the ground is the hint.
- **STOOP_W:** it stops in the air, folds its wings and screeches (`STOOP_WIND` 0.38, a "!" over it). That is the warning.
- **STOOP:** a straight, fast dive (`STOOP_V` 650, `STOOP_MAX` 1.1 s) at where you are (it corrects a little). A rake does
  `RAKE_DMG` 1 and it carries on past you. Jump or roll under it.
- **CLIMB:** it climbs heavily on the far side with the wings spread and beating hard (`CLIMB_T` 0.85, `CLIMB_V` 300). This
  is its biggest target.
- **Counter - the wings:**
  - Each wing is a `WingBody` (layer 4, radius 17*sc, `WING_HP` 16). They are hittable only while spread (SOAR, CLIMB,
    the pull-up of a feint). Folded in the dive, only the small body is open.
  - One ripped wing ("WING!", feathers and skin scraps) sends it into SPIRAL: it tumbles toward the broken side shedding
    debris and crashes (`CRASH_DMG` 70, "GROUNDED!", blood).
  - Fire bullets set a wing on fire ("WING ON FIRE"). An explosion tears both wings.
- **Learns:** every skua brought down by the wings counts in main meta `sk_downs`. After `LEARN` 3:
  - "THEY FEINT THE DIVE NOW". In a stoop (`FEINT_CHANCE` 0.65), it pulls up just before it reaches you (`FEINT_R` 210).
  - It passes over you to the other side and dives again from there after a short wind-up (`FEINT_WIND` 0.16). Hero:
    "It pulled up - wait for the second dive!".
  - Counter: do not roll early; wait for the second dive, or shoot it during the pull-up (the wings open).
  - The stage then sends waves in pairs.
- Flight `collision_mask` is 1 (it flies through platforms); on death or crash it becomes 1|16 so the body lands on decks.
- Emits `Game.story "flyer"` on its first stoop (the monologue's flyer line, like the buoy).

**BONECRAWLER** - three or four dead fused inside a whale rib cage, walking it like a giant bone centipede:
- a spine on top and curved ribs all round;
- the dead's arms and legs sticking out between the ribs as its legs;
- one head in front (leading) and one behind;
- inside, a glowing ECHO heart (the core) that holds them together.
- **What it learned:** ECHO grows in any dead thing, even other species. The whales died here a century ago and the spores
  found armour ready made. It is born from the carcasses (`EchoCarcass`) and also roams the station.
- **The ribs:**
  - `RIBS` 3 at each end, `RIB_HP` 20 each, about 2 rifle shots per rib. A hit on an end breaks that end's outer rib
    ("RIB BROKEN", bone debris), and only `LEAK` 0.2 of the damage goes through.
  - An end with no ribs left exposes the core from that side: x`CORE_MULT` 1.6, "CORE OPEN!", hero: "The ribs are gone -
    SHOOT THE HEART".
  - From above it is the spine (x`SPINE_MULT` 0.35). Fire gets between the ribs (x`FIRE_MULT` 1.25). A blast breaks one rib
    at each end.
- **REAR → SNAP:** in `REAR_R` 150 the front rears up and the ribs open like jaws (`REAR_T` 0.6). The core is open from the
  front here, which is the window. Then it lunges (`SNAP_V` 380, `SNAP_T` 0.26, `SNAP_DMG` 2), followed by `RECOVER_T`
  0.55. `REAR_CD` 1.1-1.9 s.
- **Learns:** cores destroyed count in main meta `bc_cores` (a kill counts if any core hit landed). After `LEARN` 2: "IT
  TURNS ITS BONES TO YOU NOW".
  - It always turns the end with more ribs toward you (`TURN_T` 0.45), walking backwards if it must.
  - After a burst of damage (`CURL_DMG` 32 within `CURL_WIN` 1 s) it curls into a ball for `CURL_T` 1.6 s (x`CURL_MULT`
    0.2, "CURLED"), with `CURL_CD` 4.5 s between curls. Hero: "It curls up when I hurt it... get behind it".
  - Counters: get to the other side (roll or jump over it), grenades, or wait for REAR.
- No ragdoll. Its corpse draws flat on the ground with folded legs and a dark, burst heart. zombie.gd's corpse rotation
  (rest angle 90°, +19*sc offset) is meant for upright bodies, so `draw()` sets its own transform when `z.dead`.
- `_floor()` + an unstick guard: if it ends up more than 6 px below the floor, it snaps back up.

**Tunables** - in each file header.
- Stage: `ARCH_X`, `TANKS`, `TANK_TIER`, `PLAN_X`, `PLAN_TIER`, `CARCASSES`, `BOAT_X`, `BOAT_DECK`, `BOAT_CAB`, `GUNS`,
  `POTS`, `FLENSERS`, `CRAWLERS`, `SKUA_WAVES`, `SKUA_MAX`, `LINES`, `ARENA_X`, `ARENA_CASKS`, `HARDER`.
- `zombie_weights()`: FLENSER 0.04, SKUA 0.02, BONECRAWLER 0.02, regulars 0.57, runners 0.35.
- Balance was not touched (no god mode, no big ammo piles).

---------------------------------------------------------------------------------------------------------------------------

## Stage 59 - "BLACK FOREST" (THEY LEARNED TO BURN)

Zone 7 (Patagonia), stage 5. A burnt lenga forest in Tierra del Fuego, after the fire: black trunks, grey ash, smoking
stumps, creeping fire lines, beaver ponds full of drowned trees, and a red sun seen through the smoke. The hero burned
thousands of them with flamethrowers, molotovs and barrels. Every one that died in fire breathed out the same lesson:
fire eats flesh, not charcoal. So they rolled in the hot ash until they became charcoal themselves. They walk through
flames, hide in the smoke and find the hero by his muzzle flash. Here the STRANGER visits for the last time and confesses.

**Files**
- `levels/stage_59.gd` - the smoke cycle, the muzzle-flash tracker, layout, spawns, moth waves, hints, story hooks. Sounds
  `s59_crackle`, `s59_flare`, `s59_creak`, `s59_crack`, `s59_thud`, `s59_whoosh`, `s59_hiss`, `s59_splash` (synthesised;
  no new files). Music `level1_total_war.mp3`. `world_tint` Color(1.04, 0.95, 0.88).
- `effects/s59_decor.gd` - sky + 3 parallax layers, all world objects, traps, screen FX, and the shared state `U`.
- `enemies/types/charred.gd` - CHARRED and the boss THE PYRE (+ `Cinders`, `EmberPatch`, `BurningLog`, `FireWave`,
  `PyreFlash`).
- `enemies/types/ashmoth.gd` - ASHMOTH (+ `WingBody`).
- `enemies/types/dambuilder.gd` - DAMBUILDER (+ `Dam`, `Ember`).
- `story/scenes/l59_stranger.gd` + `sounds/story/l59_stranger/` - the STRANGER's last visit.
- `map/thumbs/level_59.png` - level card.

**The smoke (the stage mechanic)**
- `smoke_k()` returns 0..1; `thick()` is `smoke_k() > 0.6`.
- Cycle (`_smoke_tick`):
  - CLEAR for `CLEAR_T` 9-13 s (the first one is `FIRST_CLEAR` 14 s);
  - ROLL for `ROLL_T` 2 s: the smoke rolls in with `s59_whoosh`. The first time, the hero says "Smoke... I can't see
    them. Can they see me?";
  - THICK for `THICK_T` 6 s;
  - THIN for `THIN_T` 2.5 s, back to CLEAR.
- `force_smoke()` starts the smoke now and `clear_smoke()` thins it now (story scene, tests).
- What the smoke does:
  - On screen, `SmokeFX` draws drifting smoke banks and a radial smoke wall around the player (clear inside 190 px, thick
    from 430 px out), plus a dark top edge. Far things fade into it.
  - CHARRED further than `SMOKE_R` 230 px fade out. Only their glowing cracks and ember eyes stay visible.
  - ASHMOTH waves come in pairs while the smoke is over 0.4.
- **The muzzle flash** (`_flash_tick`): every new `Game.shot_id` with `player._muzzle_flash > 0` is a flash. Arrows,
  molotovs and the flamethrower have no flash.
  - It sets `last_flash()` (world position at the muzzle) and `flash_age()` (seconds), which ASHMOTH reads.
  - It sets `Decor.U.flash` / `U.flash_pos`, so the shot lights up the smoke in a warm glow ("they see that").
- **Water:** in the beaver ponds `player.in_water` is set (slow walk), and `in_water_at(p)` tells a CHARRED it is in
  water. The water douses fire and softens the crust.
- `Decor.U` (static) is updated by the stage every frame: `smoke`, `flash`, `flash_pos`, `pocket` (the player on screen),
  `sparks_ms`.

**Background (Backdrop)**
- `forest_sky`: brown-grey above, amber near the horizon, a red coin sun through the smoke, drifting smoke bands, embers
  rising high, and a condor.
- `far_range` (0.06): the snowy Martial range (orange-tinted snow), the Beagle Channel, distant slope fires with smoke
  columns.
- `mid_burn` (0.28): hills of burnt lenga trunks, an island of living green forest that the fire missed (two-tier trees
  following the hill), fire fronts on the slope, and smoke.
- `near_forest` (0.6): thick black trunks with "alligator" charcoal and glowing cracks, beaver-cut pointed stumps,
  smoking stumps, fallen trunks and ash heaps.
- `forest_overlay`: warm haze behind the figures plus low smoke bands that get stronger with `U.smoke`.

**Layout / upper floors**
- `SIGN_X` 300: `ParkSign` (charred park entrance sign) with a fire-danger dial on "PELIGRO DE INCENDIO: EXTREMO".
- `HUT_X` 1050: `RangerHut` "GUARDAPARQUES", half burnt. Its porch roof is a floor at `HUT_TIER` 150 (invisible
  `add_floor` + 2 ladders) with AMMO and HEALTH on top.
- `PONDS` 2420 (w 520) and 7640 (w 480): `BeaverPond` - a flooded clearing with dark ash water, drowned trees and a beaver
  lodge.
  - The dam on the right side (`POND_DAM` 0.55 of the width) is a low floor at `DAM_TIER` 56.
  - HEALTH sits on the second dam.
  - The water x-range is added to `main._spawn_avoid`.
- `TOWER_X` 4130: `LookoutTower` (wooden fire lookout), deck at `TOWER_TIER` 220 with a ladder, GRENADE and AMMO.
- `STORY_X` 4500..6400: the clean story stretch (see Story hooks).
- `TRUCK_X` 6500: `BurntTruck`, the rangers' burnt pickup. Its bed is a low floor at `TRUCK_TIER` 70 with AMMO.
- `SAW_X` 9000: the boss arena in front of the burning sawmill `Sawmill` "ASERRADERO LAPATAIA", with a lit, fiery
  interior so the boss reads against it. Also in the arena:
  - a log deck at `SAW_DECK` (x+220, w 180), `SAW_TIER` 130, with a ladder and AMMO;
  - HEALTH at `SAW_X`-110;
  - log piles and a big saw blade.
- `Stump`s at `STUMPS` (smoking stumps with embers, decor).
- Obstacles come from `custom_gen` as `Decor.Obstacle`: `logs` (a pile of burnt logs), `stump` (a giant stump),
  `boulder` (an erratic boulder with ash) and `rootball` (an upturned root ball). The name `crates` is not used.
- Every placed spawn, building, trap and the story stretch is `reserve()`d, so generated obstacles never cover them.
- `extra_spawns`:
  - CHARRED at `CHARREDS` (1850 and 8470 stand inside a fire line);
  - DAMBUILDER at `BUILDERS` (near the ponds);
  - ASHMOTH roosting at `ROOSTS` (hut roof, tower deck, truck bed);
  - 2 regulars in the arena.
- Moth waves (`_waves`): at `MOTH_WAVES` the stage launches 1 ASHMOTH 640 px to one side of the player (meta `am_fly`).
  - It launches 2 when the moths have learned or the smoke is over 0.4 ("More wings in the smoke...").
  - Waves never land in the story stretch.
- `_hints`: the first time each type is on screen it shows its intro popup and the hero says one line:
  - CHARRED: "FIRE DOESN'T WORK NOW" / "They're burnt black... fire won't hurt them anymore. Crack the crust."
  - ASHMOTH: "THEY FOLLOW YOUR GUNFIRE NOW" / "It came to the flash... stop shooting and it loses me."
  - DAMBUILDER: "THEY BUILD COVER NOW" / "It's building a wall... it learned cover from me."
- `zombie_density()` is 1.0 / 1.15 / 1.3 by difficulty (`HARDER`).

**Traps** (`s59_decor.gd`)
- `FireLine` (`FIRES` 1760, 3300, 6900, 8380; a `Hazard`, group `s59_fires`): a creeping line of fire on the ground.
  - LOW (`LOW_T` 3.2-4.6 s): embers, safe to cross.
  - WARN (`WARN_T` 0.85 s): crackle and sparks.
  - FLARE (`FLARE_T` 2.6 s): tall flames that hurt you (`DMG` 1) and ignite zombies (`zombie_burn` 3).
  - A CHARRED loves it: it heals and re-crusts inside the flames. A flaring line pulls an ASHMOTH that has no flash to
    follow, and its wings can catch fire there.
- `Snag` (`SNAGS` 2200, 3800, 7380, 8720): a burnt standing tree about to fall (a "widow-maker").
  - Come within `TRIG_R` 300 and it creaks with sparks at the base and a shadow on the road (`WARN_T` 1.1).
  - Then it falls across the road (`FALL_T` 0.55): `DMG` 2 to you, `DMG_Z` 70 to zombies.
  - Shoot the glowing base (`SnagBody`) to drop it now, onto them.
  - It leaves a `FallenLog`: a smoking trunk on the ground, low cover that you can jump.
- `BeaverPond` water: slows you; a burning zombie that walks in is doused.

**CHARRED** - a dead man burnt to charcoal: a black "alligator skin" crust with glowing orange cracks, ember eyes and
smoke rising from the shoulders. Some wear the scorched yellow helmet of a forest firefighter (brigadista). Stiff and
hunched.
- **What it learned:** "FIRE DOESN'T WORK NOW." Fire eats flesh, not charcoal.
- **The crust:** two sides, FRONT and BACK, `CRUST_HP` 30 each (a hit counts on the side it came from).
  - A bullet on a crusted side only chips it: coal chips and sparks fly, and the body takes nothing.
  - Once a side breaks ("CRACKED") the glowing flesh shows, and hits there do x`CRACK_MULT` 1.6 (head included).
  - An explosion cracks both sides (`BLAST_CRUST` 40 each).
  - In pond water the crust is soft (x`WATER_MULT` 2) and the fire goes out ("DOUSED").
- **Fire feeds it:**
  - Incendiary bullets and the flamethrower are absorbed. They chip at half (`INC_CHIP`) and set it alight.
  - While it burns (fire line, molotov, flamethrower) it heals `FIRE_HEAL` 7 hp/s and regrows `REGROW` 12 crust/s. It is
    STOKED (x`STOKE_SPEED` 1.35 for `STOKE_T` 2.5 s), with the popup "IT DRINKS THE FIRE" and the hero's line "Fire makes
    them stronger! Keep them out of the flames."
- **SWIPE:** it raises its glowing claws (`WIND_T` 0.45, the warning), then strikes (`DMG` 1, `SWIPE_R` 46).
- **In smoke:** beyond `SMOKE_R` it fades out. Only the cracks and eyes stay, and a near shot's flash lights it up.
- **Death:** it crumbles into a pile of charcoal (`Cinders`, all chips in one draw call, max 280), an ash cloud, and gore
  per `Quality.gore()`.
- **Learns** (main meta `ch_cracks`, the number of sides broken):
  - At `HIDE_LEARN` 2: "IT HIDES ITS CRACKS NOW". A cracked side turns away from you: it walks at you backwards with
    the intact side forward and turns only to swing. Counter: wait for the swing, get round it, or use a grenade.
  - At `ROLL_LEARN` 4: "IT ROLLS IN THE ASH NOW". When cracked and not right on you, it drops and rolls in the ash
    (`ROLL_T` 1.3) and comes up with a thin new crust (`ASHED_HP` 18), up to `ROLL_MAX` 2 times. While it rolls it is
    open (x`ROLL_MULT` 1.4). Counter: shoot it while it rolls.

**THE PYRE** (boss; `chase_range > 600`, hp 340, scale 2.4) - a walking bonfire: a teepee of burning logs over a mound
of fused charred bodies. Heads and clawed arms push out of the pile, a big skull sits on top, and flames and sparks pour
from the apex.
- **The core:** the front crust is thick (`BOSS_CRUST` 160) and hides a glowing core (x`CORE_MULT` 1.2 when open). The
  back is thin (`BOSS_BACK` 36). The crust regrows (`BOSS_REGROW`) after `BOSS_QUIET` 3.5 s without hits. Fire heals it.
- **SWEEP:** up close (`SWEEP_WIND` 0.65) an arm of bodies and logs sweeps `SWEEP_R` 140 (`SWEEP_DMG` 2).
- **HURL:** it tears off a burning log and throws it in an arc (`BurningLog`, range `HURL_R` 230-900, `HURL_DMG` 1). You
  can shoot the log in the air. Where it lands it leaves embers (`EmberPatch`, 4 s, hurts you and burns zombies). Below
  50% hp it throws two.
- **RING:** below 75%, every `RING_EVERY` 9 s it stomps and two fire waves run along the floor both ways (`FireWave`,
  `WAVE_V` 360, `RING_DMG` 2). Jump them.
  - After `JUMP_LEARN` 2 jumps over a wave (main meta `py_jumps`): "IT READS YOUR JUMP". It sends a second pair
    `RING_GAP` 0.42 s later, which lands where you land.
- **SHED** at 66% and 33% (`SHED_AT`): it roars and a skin of bodies falls off. The core is bare for a moment, two
  stoked CHARRED rise from the shed skin, and then the crust grows back (to 75%).
- **Death:** a roar, a big flash (`PyreFlash`) and camera shake; burning logs fly off, a large charcoal spray, and any
  thrown logs and fire waves still out are put out.

**ASHMOTH** - a moth of ash: a shrunken charred body (head, hanging arms, dragging legs) hung between two huge wings of
bark and burnt skin. The wings are grey-brown with ash veins, glowing edges and ember "eye spots". It has feathery
antennae and a glowing orange belly, and flies in a nervous moth zig-zag, never straight.
- **What it learned:** "THEY FOLLOW YOUR GUNFIRE NOW." In smoke they see nothing, but everyone who died in the smoke saw
  the same last thing: the flash of the hero's barrel.
- **ROOST:** sits on a roof, deck or the ground with its wings slowly opening. A flash within `WAKE_R` 720, or you within
  `NEAR_R` 200, wakes it.
- **FLUTTER:** with no flash to follow it flutters at `HOVER` 210. A flaring fire line within `FIRE_PULL` 900 draws it,
  and there its wings can catch fire.
- **HOME:** it flies to the **last flash it saw** (not to you) in a zig-zag (`ZIG` 70, `HOME_V` 215). Every new shot
  within `SENSE_R` 1050 updates the target.
  - At the target with you near (`STRIKE_R` 130): STRIKE_W (stops, wings back), then STRIKE. It throws itself at you
    (`DIVE_V` 430): `DMG` 1 and "ASH IN YOUR EYES" (`player.daze` 1 s). Then RECOIL up and back.
  - At the target with you gone: SEARCH around the spot for `SEARCH_T` 2.4 s, then "LOST YOU" (main meta `am_lost`),
    and back to FLUTTER.
- **Counters:** stop shooting and move; use a bow, molotov or flamethrower (no flash); shoot a wing (`WingBody` on layer
  4, `WING_HP` 14 each - a torn wing means SPIRAL and crash, `CRASH_DMG` 80); shoot the glowing belly (x`GLOW_MULT`
  1.8). Fire ignites the wings ("MOTH TO A FLAME"); an explosion tears both.
- **Learns:** after `LEARN` 3 losses: "THEY WAIT WHERE YOU FIRED". New moths do not give up. They circle the last flash
  spot (CIRCLE, `CIRCLE_R` 95), and the next shot within `CIRCLE_DIVE` 620 makes them dive at once, with no search. The
  stage then sends waves in pairs. Hero: "It's circling where I shot from... don't fire from the same spot."

**DAMBUILDER** - a dead trapper wrapped in beaver pelts (beavers are the plague of the Fuegian forest; they wrecked it
before the fire). A beaver skull on his head with huge orange teeth, a flat tail hanging behind, burnt logs on his
shoulder.
- **What it learned:** "THEY BUILD COVER NOW." The hero hid behind cars, crates and walls in every level, and everyone
  who died facing cover breathed out the same thing: whoever is behind a wall lives.
- **SEEK:** you within `SEE_R` 1000: it picks a spot `BUILD_D` 360 from you (never closer than `MIN_D` 170) and runs
  there with the logs. `_pick_spot` avoids water, hazards, other cover and the story stretch.
- **BUILD:** it raises a log dam (`Dam`, `BUILD_T` 1.6 s) in front of you. The wall is solid cover: it stops bullets,
  you and zombies.
- **COVER:** crouched behind the wall (small hitbox). Every `LOB_CD` 2-2.8 s it rises (`LOB_WIND` 0.5, head open!) and
  lobs an ember in an arc (`Ember`, shootable, lands as an `EmberPatch`, `EMBER_DMG` 1).
- **RELOCATE:** the wall fell, so it grabs more logs (`LOGS` 2) and builds again further back. Out of logs, or you got
  round it: FIGHT, a tail slap up close (`TAIL_R` 44, `TAIL_DMG` 1).
- **The wall** (`Dam`, groups `cover`, `blastable`, `db_dams`): `DAM_HP` 90.
  - Bullets break logs (wood chips).
  - Fire (incendiary shots, a fire line) makes it burn (`DAM_BURN_T` 4, fast damage) and ignites zombies next to it, which
    a CHARRED enjoys.
  - An explosion nearly takes it apart (`DAM_BLAST` 75).
- **Learns:** after `LEARN` 3 walls broken (main meta `db_broken`): "IT BUILDS BETTER NOW". It uses wet logs from the
  ponds (they do not burn), builds a taller wall with a firing slit (`WET_H` 62, `WET_HP` 120), builds next to existing
  cover (an obstacle or a fallen log), and carries one more set of logs. Hero: "Wet logs... fire won't take them. And it
  builds behind cover."

**Story hooks** (call on `main._stage`)
- `story_stretch()` returns `Vector2(4500, 6400)`: flat road with no obstacles, traps, placed zombies or moth waves.
  The STRANGER stands at x 5450.
- `on_story_beat(id)`:
  - "smoke_in" - `force_smoke()` (the scene's first line)
  - "smoke_out" - `clear_smoke()`
  - "embers" - a gust of sparks (`SmokeFX.sparks()`)
  - "smoke_veil" - a thick `SmokeVeil` cloud (5.5 s, r 170) rolls over the STRANGER, and he is gone when it thins (last
    line; the scene ending is "shimmer")
- `smoke_k()`, `thick()`, `force_smoke()`, `clear_smoke()`, `last_flash()`, `flash_age()`, `in_water_at(p)`.

**Tunables** - in each file header.
- Stage: `CLEAR_T`, `ROLL_T`, `THICK_T`, `THIN_T`, `FIRST_CLEAR`, `HUT_X`, `TOWER_X`, `TRUCK_X`, `PONDS`, `POND_DAM`,
  `DAM_TIER`, `FIRES`, `SNAGS`, `STORY_X`, `SAW_X`, `SAW_DECK`, `CHARREDS`, `BUILDERS`, `ROOSTS`, `MOTH_WAVES`, `STUMPS`.
- `zombie_weights()`: CHARRED 0.045, ASHMOTH 0.015, DAMBUILDER 0.025, regulars 0.56, runners 0.33.
- Balance was not touched (no new weapons, no ammo piles).
- Performance: every `_draw` is the DrawBatch wrapper; each zombie is one draw call (`Decor.U` helpers + `U.flush`);
  `Cinders` keeps all chips in one node; particle counts scale with `Quality.ambient()` / `Quality.gore()`. Things that
  move (`BurningLog`, `FireWave`, `Ember`) move in `_process`, so there are no MOVERS.

**Tests** (private copy `/home/claude/tp_l59`, outside the repo)
- Parse check: `PARSED 414 bad 0`.
- `FROM=59 TO=59 all.sh`: `L59 err=0 reached=1`.
- Draw calls (`RENDER_TOTAL_DRAW_CALLS_IN_FRAME` under xvfb, auto-fight): 385-497 at the first fire line and pond, 391-465
  in the boss arena, 387-454 at the truck and fire lines. Same range as stage 57 (394-463) and lower than 55 (446-570).
  `t_count.gd`: 192 visible canvas items at start (stage 57: 243).
- `t_hitch.gd 59 1500`: avg 5.0 ms, 2-8 frames over 16.7 ms out of 1440, worst 18.8-27 ms (one-off). Stage 57 on the same
  run: avg 4.7 ms, 9 over, worst 20 ms.
- **Behaviour counters (`t59b.gd`, 60 fps):**
  - charred: 12 kills in 78 shots (~6.5 per kill). The 2nd crack learned HIDE; from the 4th, every one rolled once.
  - fire: a burning CHARRED went hp 20 → 41 with crust 0 → 30/30 (fed, stoked). Five incendiary hits did 0 damage.
    A bullet on a cracked side did 21; on a crusted side it did 0. Walking into water doused it.
  - moth: three times it homed to the flash, struck, then lost the player (am_lost 1, 2, 3). The 4th one circled the
    spot and dove 6 frames after a new flash.
  - dam: 3 walls built 360 px in front of the player, each broken, relocating each time; 3 lobs with 2-3 hits. The next
    builder (learned) built 3 wet walls (h 62, 120 hp).
  - boss: 2 hurls (1 hit), a ring, 1 jump (py_jumps), 2 sheds with stoked CHARRED, then dead after about 13 s of
    point-blank fire.
- **Story:** with the story_db line added in the copy, the scene plays in the clean stretch. Smoke rolls in on the first
  line, the embers gust on z04, and the STRANGER fades into the veil at the end; the player then walks on.
- **Fixed during testing:**
  - `FireWave` was freed on its first frame (its start x was read before the position was set); it now starts at INF.
  - The boss died in ~43 shots; it now has hp 340 and crust 160, and the crust regrows after SHED.
  - The smoke was too faint; the radial smoke wall around the player was added.
  - The boss looked like a box; it was redrawn as a log teepee over fused bodies.
  - A DAMBUILDER never moved when the player stood exactly at the edge of its range; it now walks toward an alerted
    player.

---

## Stage 60 - "GLACIER LAB" (THEY LEARNED WHERE THEY CAME FROM)

Zone 7 (Patagonia), stage 6. Project ECHO's research station, built inside the glacier. The level has:
- ice tunnels in blue light, steel corridors, and labs with broken cryo tanks;
- specimen jars, server racks, giant blast doors, red emergency lights and alarms;
- frost on everything, and ECHO fungus on the walls that pulses to the right, toward the deep levels (the ROOT, which is saved for 62).

The hive learned where it was born, and it guards its cradle. It learned the lab's own systems (blast doors, lockdowns), and from the
files it learned the hero's own combat pattern. In the file archive the hero finds his own file at a terminal (the SUBJECT ZERO scene),
and the hive answers through the speakers: "Welcome home."

**Files**
- `levels/stage_60.gd`: layout, wings and the lockdown / keycard system, spawns, the arena, and story hooks. All sounds are synth:
  `s60_door`, `s60_slam`, `s60_door_open`, `s60_alarm`, `s60_hiss`, `s60_vent`, `s60_shatter`, `s60_card`, `s60_granted`,
  `s60_beep`, `s60_drone`, `s60_powerdown`.
- `effects/s60_decor.gd`: sky + 3 parallax layers, all world objects, traps and the screen FX. Shared state is in `U`:
  `U.alarm`, `U.file_ms`, `U.welcome_ms`, `U.cards`, plus `U.since(ms)`.
- `enemies/types/specimen.gd`: SPECIMEN, which is also the boss SUBJECT FOUR. Sounds are `sp_*` and `s4_*`.
- `enemies/types/bloom.gd`: BLOOM. Sounds are `blm_*`. They are not `bl_*` because `bl_pop` already exists in stage 41 and
  SOUNDS names are global.
- `enemies/types/warden.gd`: WARDEN. Sounds are `wn_*`.
- `story/scenes/l60_file.gd` + `sounds/story/l60_file/*.mp3`.
- `map/thumbs/level_60.png`.

**Background (Backdrop)**
- `lab_sky`: the depth of the glacier. Dark blue, light cracks, and ice crystals that fall slowly.
- `far_ice` 0.06: the ice cave wall:
  - layered blue ice, cracks and trapped rocks;
  - air bubbles and light shafts;
  - far steel beams with blue lamps.
- `mid_lab` 0.28: the lab's back wall:
  - steel panels, and windows onto the glacier or into lab rooms with tanks;
  - ECHO veins that pulse to the right (deeper);
  - signs, and emergency lamps that spin red while `U.alarm` is up.
- `near_rig` 0.6:
  - giant frosted pipes with icicles;
  - cable trays and ceiling vents;
  - flickering fluorescents and hanging fungus threads;
  - low machines behind the road.
- `lab_overlay` is the cold haze behind the actors plus the ceiling shadow. `LabFX` (screen) draws:
  - frost crystals and cold breath;
  - the red alarm flash (`U.alarm`) and power flicker;
  - your keycards in the corner (`U.cards`).
- Everything is batched into triangle arrays (`U.flush`).

**Layout / upper floor**
- `LabGround`: perforated steel floor, frost, ice patches and hazard stripes. There is snow at the entrance.
- `Entrance` (x 0) is the tunnel mouth and the station gate: "ESTACION GLACIAR - PROYECTO ECHO".
- `DOORS` 1500 / 3200 / 4900 / 6800 / 8500 / 9150 are `BlastDoor`s (labels A-F). Three of the spaces between doors are lockable `WINGS`:
  - A (cryogenics, 1500-3200);
  - B (specimen lab, 3200-4900);
  - D (server hall, 6800-8500).
  The archive (the story room) is between B and D. The ROOT corridor (thick fungus) is between D and the arena.
- `TANKS` (23) are `CryoTank`s. Variant 0 has a SPECIMEN inside, 1 is empty, 2 was broken long ago. Each one has a `TankGlass` in front
  of the actor.
  - `HOLD_TANKS` 6300 / 6420 are in the archive and thaw only after the story scene. When the scene was already seen or isn't in
    `story_db`, they thaw by proximity as usual.
  - 9330 / 9450 are in the arena and thaw only when SUBJECT FOUR calls them.
- `CATWALKS` (1760, 4060, 7380) are steel walkways hung from the ceiling. Each has an `add_floor`, 2 ladders and AMMO / HEALTH /
  GRENADE on top, plus a regular zombie up there.
- Decor:
  - `JARS` (3300, 4230, 5120) are `JarShelf`s with organs, brains and embryos in cloudy fluid;
  - `RACKS` (5450, 6560, 6950, 7600, 8330) are `ServerRack` pairs (`count` 2) with blinking LEDs;
  - `FUNGUS` are `FungusPatch`es on the wall or floor that grow thicker to the right.
- Obstacles `bench` / `dewar` / `gurney` / `rack` come from `custom_gen`. They are solid cover.
- `TERMINAL_X` 5790: the archive `Terminal`. `STORY_ACTOR` 6000 is the story tank, which uses `hold_burst`.
- Arena: `ContainmentArena`, from door F to the end. It has:
  - a giant containment cell broken from the inside;
  - an observation window;
  - a "NIVEL -4" hatch that the fungus flows into.
  `ARENA_COVER` is a bench at 9420 and dewars at 9850, both in group "cover" for the boss. HEALTH + AMMO sit outside door F.

**Lockdown / keycards** (stage_60.gd)
- A WARDEN reaches the alarm panel of its wing and calls `lockdown(wi)`. Both doors of the wing slam shut, including the one behind
  you:
  - the doors crush zombies under them;
  - "LOCKDOWN - ALA A" appears;
  - the wing's frozen tanks thaw one after another;
  - the red alarm starts.
  - The hero says "LOCKDOWN - THEY SEALED ME IN. GET HIS KEYCARD!" The first time, the WARDEN shows the popup "THEY LOCK THE DOORS NOW".
- A dead WARDEN drops a `Keycard` (`drop_card`, kept inside its wing). Walk over it and you get "ACCESS GRANTED" and the wing opens
  (`open_wing`). A spare card is kept (`U.cards`, shown in the corner). Touch a locked door and the spare opens it at once.
- Safety net:
  - A sealed wing with no live WARDEN, no card on the floor and no card in hand gets an "EMERGENCY RELEASE" after `RELEASE_T` 4 s.
  - Any sealed wing gets one after `RELEASE_MAX` 75 s.
- Wing states are `W_OPEN`, `W_HALF` (learned early lock: only the far door is shut), `W_SEALED` and `W_CLEAR`.
- zombie.gd puts zombies more than 1400 px from the player to sleep. A WARDEN that is running to a far panel is driven from the stage's
  `_physics_process` (`warden.remote(delta)`).
- Arena: when you pass door F + 180 with the boss alive, door F seals ("CONTAINMENT 4 - SEALED"). It opens when the boss dies.

**Traps**
- `CoolantVent` (`COOLANT` 2450, 3480, 7900, 8800) is a liquid-nitrogen vent in the floor:
  - Step close (`TRIG_R`) and it hisses and draws a frost ring (`WARN_T` 0.85).
  - Then a column of cold fires (`BLAST_T` 1.1, `HGT` 210). It deals `DMG` and slows you (`SLOW_T`).
  - Zombies in the column freeze (`FREEZE_T` 2.4, they stop) and take `DMG_Z`.
  - Shoot the valve wheel (`ValveBody`) to fire it when you want. Cooldown is `CD` 3.2.
- `BlastDoor` slamming (lockdown) crushes zombies under it.
- `CryoTank`s release SPECIMENs as you pass, some of them behind you.

**SPECIMEN**: an escaped or thawed ECHO test subject:
- a torn, stained lab gown and blue-grey skin;
- a shaved head with surgical staples and electrodes;
- an IV line hanging from the arm and an ID bracelet with a barcode;
- glowing ECHO growths on the shoulder and back, and frost on the shoulders.
Its eyes are red, and green while it copies you. Learned from: ECHO was built to let soldiers share combat memory. The subjects here
got the soldiers' memory, so they fight like soldiers.
- **TANK:** frozen in a cryo tank.
  - When you pass (`THAW_R` 150-360, different for each one) the tank thaws (frost cracks, steam) and bursts.
  - A shot into the tank breaks it at once (x`TANK_MULT` 0.7 through the glass).
  - `hold` = it waits for the stage.
- **STIFF:** comes out frozen and stiff (`STIFF_T` 1.5). It is slow and brittle (x`STIFF_MULT` 1.4).
- **HUNT -> ROLL -> STRIKE:** "THEY ROLL LIKE SOLDIERS NOW".
  - Inside `ROLL_R` it combat-rolls at you (`ROLL_V`, `ROLL_T`). It is low, so chest-high bullets pass over it.
  - At the end of the roll it rises into a clawed uppercut (`STRIKE_*`). It sometimes rolls when it sees you fire (`ON_SHOT_CHANCE`).
  - The hero: "It rolled... like a soldier. Like ME."
- **SWIPE** is a close claw. **RECOVER:** after a strike or roll it is on one knee (`RECOVER_T`, x`RECOVER_MULT` 1.3). That is your window.
- Counter: crouch for the roll (or shoot low), roll or jump the uppercut, and shoot it on its knee.
- **Learns** (main meta `sp_beaten` >= `LEARN_N` 3; it counts strikes you rolled or jumped and kills during a roll or recover):
  "IT COPIES YOU NOW".
  - It copies your last move after `COPY_DELAY`:
    - you roll, it rolls the same way (invulnerable like you, except to blasts);
    - you crouch, it crouches until you stand;
    - you jump, it jumps.
  - Each copy shows a green ring and green eyes. A copy waits up to 0.7 s if the zombie is busy.
  - The hero: "It's copying me. Every move I make."
  - Counter: don't repeat the same move. It is always `COPY_DELAY` late, and it kneels after a copied roll.
- Scene actor: `tank_actor` stands in the story tank (lifted `BASE_H`) with its eyes closed until `wake_actor()`. It has `talking`,
  `tilt`, `smile` and `t`. Group "s60_specimens".

**SUBJECT FOUR** (boss, `chase_range > 600`): one of the seven ECHO soldiers, fused with his rifle. He fights with the hero's own moves
(`ai/player_memory.gd`).
- **Range:** keeps your favourite distance (`PlayerMemory.avg_distance`, clamped to `B_PREF` 220-470, +120 if you use the shotgun a lot).
- **B_AIM -> B_BURST:** a laser sight (`B_AIM_T`), then a burst of `B_SHOTS` 3 (`B_SHOT_V`, `EnemyShot`), then a reload.
  - A high laser (`AIM_HIGH` -44) means crouch.
  - "IT AIMS LOW NOW": after `SEEN_DUCKS` 2 ducked bursts (or `PlayerMemory.crouch` > 0.3) it mixes in a low laser (`AIM_LOW` -16).
    Jump or roll that one.
- **B_ROLL:** rolls when you shoot at it (invulnerable except to blasts). Cooldown is `B_ROLL_CD` 1.8, or 1.1 if your precision is
  above 0.6.
- **B_COVER:** below 95% / 50% HP or after a roll, it runs to cover (group "cover" in the arena: the bench and the dewars).
  - It hides there (x`B_COVER_MULT`) and peeks out to fire.
- **B_MELEE:** a rifle-butt strike when you are close (`B_MELEE_R`). Front armour x`B_ARMOR` 0.85, open after bursts x`B_OPEN_MULT`.
- Intro: "IT FIGHTS LIKE YOU NOW". The hero: "Subject Four... one of the seven. He fights like me."
- Below half HP: "IT REMEMBERS EVERYTHING". It calls the SPECIMENs out of the arena tanks (`stage.thaw_arena()`), and bursts become
  `B_SHOTS2` 5.
- Death: "Four of seven. I'm sorry, brother." Door F opens.

**BLOOM** (flyer): a floating ECHO colony like a glowing jellyfish. It has:
- a translucent bell of fungus fibre with a frilled rim;
- long thread tentacles;
- `N_NODES` 6 glowing green nodes on the bell.
It swims in pulses (`PULSE_T`, `PULSE_V`) and sets its position directly (no move_and_slide, collision_mask 0). Learned from: it is the
learning itself, in one body.
- **TEACH:** "IT TEACHES THEM NOW". It hovers above zombies (`TEACH_R` 230, up to `MAX_STUDENTS` 6) and ties glowing threads to them.
  - Zombies under it learn on the spot: x`TEACH_SPEED` 1.35 speed and +`TEACH_DUCK` 0.3 duck.
  - A lesson ring (`effects/spore_lesson.gd` colour) flies to them every `FLASH_EVERY` 1.6 s.
  - The lesson stays `LINGER_MS` 2500 after they leave.
  - Killing it gives "THE LESSON BREAKS": every student goes back to normal.
- **Hits:** the bell is spongy (x`BELL_MULT` 0.45). The nodes are the weak points (x`NODE_MULT` 1.6). Each shot is traced from its
  entry point, like MURMUR.
  - Every `NODE_HP` 13 damage pops a node. With no nodes left it dies.
  - Blasts do x`BLAST_MULT` 2.
- **STING:** it barely attacks. Right under it (`STING_R`) the tentacles glow (`STING_TELL` 0.6) and lash down, dealing `STING_DMG`
  and a slow.
- Counter: shoot the lights first, then the students.
- **Learns** (main meta `blm_kills` >= `LEARN_KILLS` 2, rechecked live): "IT HIDES BEHIND THEM NOW". After it loses a node, it drops
  behind its nearest student (the student is between you and it, `LOW_H`) or rises to the ceiling (`CEIL_H`) for `HIDE_T`, then
  goes back to teaching.
- Doors: it never drifts through a closed `BlastDoor` (group `s60_doors`).

**WARDEN**: lab security. It wears black riot armour and a helmet with a cracked visor (green ECHO fog inside, red eyes). It carries:
- a shoulder flashlight whose beam sweeps;
- an electric baton;
- a keycard on a lanyard.
Learned from: the hive learned the lab's systems. It knows where the alarm panels are, and that a blast door shuts you in.
- **PATROL** near home. If it sees you (`SEE_R` 620) or is hit, it goes to **ALERT**.
- **RUN:** "THEY LOCK THE DOORS NOW".
  - When you are inside its wing it sprints (`SPRINT`) to the nearest panel. It does not attack on the way.
  - **SLAP** (`SLAP_T`, hand on the panel) triggers `stage.lockdown()`.
  - Kill it before it gets there. Its back is open (x`BACK_MULT` 1.1).
- **FIGHT:** a baton swing (`SWING_WIND`, blue sparks) for `SWING_DMG` + a shock slow (`SLOW_T`).
- **Armour:** the visor takes x`VISOR_MULT` 0.4 for `VISOR_HITS` 2 head hits, then "VISOR CRACKED" and the head is open. The front
  takes x`FRONT_MULT` 0.65 and fire x`FIRE_MULT` 1.3.
- Death drops the keycard (`stage.drop_card(pos, wing)`). Group "s60_wardens".
- **Learns** (main meta `wn_cards` >= `LEARN_CARDS` 2; it counts keycards you picked up): "IT LOCKS THE DOOR AHEAD NOW".
  - When it sees you coming at a wing from outside (`AHEAD_R` 1250), it runs to the far door's panel first.
  - It locks that door early (`W_HALF`) and guards it (`GUARD`, `GUARD_R`).
  - When you walk into the wing, the door behind you slams too. Its card still opens the wing.
  - The hero: "He's running ahead to lock the next door!"

**Spores** ("they learn", story rule 3): the shared `effects/spore_lesson.gd` carries the lesson of each kill. BLOOM shows the same
idea openly and for its students only (the lesson rings use the same colour). Nothing else is added on top.

**Story hooks** (call on `main._stage`)
- `story_stretch()` returns `Vector2(5000, 6750)`, the file archive. It is reserved, so no obstacles, traps or spawns go there.
  `story/scenes/l60_file.gd` stands its SPECIMEN in the story tank at 6000 (`actor_props {"tank_actor": true}`).
- `on_story_beat(id)`:
  - "file_open": the SUBJECT ZERO file appears on the terminal (`U.file_ms`) with the hero's photo, plus a beep.
  - "welcome": the fungus swallows the screen ("WELCOME HOME", `U.welcome_ms`), the power flickers and drones, the story tank
    cracks, and the actor opens green eyes (`wake_actor`).
  - "alarm": a short siren.
- After the scene the story tank bursts (the actor is gone), the two archive tanks thaw ("the hive answered"), and the hero says
  "Home. That's what they call this place."

**Tunables**: in each file header.
- Stage: `DOORS`, `WINGS`, `TANKS`, `HOLD_TANKS`, `CATWALKS`, `COOLANT`, `JARS`, `RACKS`, `FUNGUS`, `BLOOMS`, `WARDENS` ([x, wing]),
  `ARENA_COVER`, `STORY`, `TERMINAL_X`, `STORY_ACTOR`, `RELEASE_T`, `RELEASE_MAX`.
- `zombie_weights()`: SPECIMEN 0.035, BLOOM 0.015, WARDEN 0.01, regulars 0.58, runners 0.33. Most SPECIMENs come from the tanks.
- Decor: `BlastDoor.CLOSE_T` / `OPEN_T`, `CryoTank.THAW_T`, `CoolantVent.*`, `Keycard.PICK_R`.

**Main metas used**:
- SPECIMEN: `sp_beaten`, `sp_said`, `sp_copy_said`
- BLOOM: `blm_kills`, `blm_seen`, `blm_said`, `blm_hide_said`
- WARDEN: `wn_cards`, `wn_lock_said`, `wn_ahead_said`

**Performance**
- Each zombie is one draw call (DrawBatch begin/_draw_b/end). There are no strings in zombie draws.
- BLOOM nodes and threads and the boss laser are inside the same batch, with no extra nodes.
- No MOVERS are needed:
  - `CoolantVent` uses `_physics_process` but does not move;
  - `Keycard` falls in `_process`;
  - boss bullets are `EnemyShot`;
  - the remote-driven WARDEN is a zombie.
- Draw calls (xvfb, avg over x 600..9400) are about 400, the same as level 57 (401).

**Tests** (test project `/home/claude/tp_l60`, outside the repo)
- `t_parse`: 424 parsed, 0 bad. `all.sh FROM=60 TO=60`: `L60 err=0 reached=1`.
- `t_run` at 2600 / 4300 / 7600 / 9300: no SCRIPT ERROR. There were 49-54 zombies (SPECIMEN about 19, mostly in tanks; BLOOM 4-5;
  WARDEN 4-7).
- `t60.gd <mode>`:
  - **lock:** the WARDEN reaches the panel and wing A seals (lockdowns 1). Killing it drops the card, walking over it opens the wing
    (opened 1, `wn_cards` 1). There were 0 emergency releases.
  - **tank:** 1-5 tanks thaw and release by proximity (it varies by run).
  - **bloom:** taught 4-6 students; they were boosted and then all restored when it died. Once learned it hides (3 hides).
  - **copy** (learned): it copied the hero's roll, duck and jump; `sp_copy_said` was set.
  - **boss:** it fired bursts, rolled on shots, took cover (1-11 times), aimed low, called the arena tanks (1), and the arena sealed.
  - **ahead** (learned): wing D got an early half-lock before entry, then sealed on entry.
  - **story:** the scene plays, the terminal shows the file then "WELCOME HOME", the story tank breaks, and the archive tanks thaw.
    The hero is never hurt during the scene.
  - **hold:** with the scene still due, archive tanks 6300 / 6420 are held. With the scene seen, they are not. Arena tanks are always
    held.
- `t_hitch` 1500 frames: lv60 avg 4.27 ms, 4/1440 frames over 16.7 ms, worst 22.1 ms. lv57 avg 4.30 ms, worst 31.5 ms.

---

## Stage 61 - "END OF THE WORLD" (THEY LEARNED TO MOVE AS ONE)

Zone 8 (Ushuaia), stage 1. The Glacier Lab (60) ended with "Welcome home", but the ROOT is not in the lab any more. It
went down the glacier with the meltwater into the Beagle Channel and grew under USHUAIA, the city at the end of the world,
under the old prison (the PRESIDIO). The whole region walks into the city as one body, in step. They are not attacking
the city: they are walking home. The hero walks with them through the streets, past the old prisoners' train and the
rusted cruise ship in the port, to the prison gate that goes down (62).

**Files**
- `levels/stage_61.gd` - layout, spawns, THRONG schools, condor waves, `updrafts()`, intro hints, the hero's story lines.
  Sounds `s61_valve`, `s61_steam`, `s61_snap`, `s61_creak`, `s61_crash`, `s61_wind`, `s61_march`, `s61_bell`
  (synthesised; no new files). Music `level1_total_war.mp3`.
- `effects/s61_decor.gd` - sky + 3 parallax layers, all world objects, the 2 traps and screen FX.
- `enemies/types/boneside.gd` - BONESIDE and the boss THE FERRYMAN (+ `BoneShard`, moved in `_process`).
- `enemies/types/condor.gd` - CONDOR (+ `WingBody`, `RiderBody`).
- `enemies/types/throng.gd` - THRONG (+ the shared `School`, `spawn_school()`).
- `map/thumbs/level_61.png` - level card.
- Death spores need nothing extra (zombie.gd sends them from 55 on).

**Background (Backdrop)**
- `end_sky`: cold dusk. Violet-blue above, pink-peach on the horizon where the sun went down behind the mountains, first
  stars, lenticular "flying saucer" clouds with pink rims (Patagonia), a faint green "aurora" (spores rising from the
  city), and far condors soaring in circles without a wingbeat.
- `far_peaks` (0.06): the Martial range and Monte Olivia (the sharp pyramid) with alpenglow-pink snow, the Martial
  glacier between the ridges with its meltwater stream (a thin green line runs down it: the way the ROOT came down), low
  cloud, and the Beagle Channel with Navarino's islands and pink glints.
- `mid_city` (0.28): the city on the slope: 3 rows of tin houses with red/blue/green roofs and snow, lit windows (some
  glow green: they stand at home waiting for the beat), chimneys, a church with a white spire, port cranes, and the
  procession: a road down the slope with dozens of tiny figures walking down in step (`BEAT`, the same tempo as THRONG).
- `near_street` (0.6): lenga "flag trees" bent east by the wind, a wooden fence, sodium street lamps, an abandoned car in
  snow, and a line of walkers behind the fence, all in step, walking right (toward the prison).
- `end_overlay`: cold violet haze behind the figures.
- Performance: each layer skips whole periods that are off screen (and `mid_city` skips houses left of the screen while
  keeping the same hash order), and the soft shapes (`soft_ellipse` / `soft_glow` / `soft_smoke`, each one its own draw
  call) are kept few: 12 + 8 in the sky, 3 chimney smokes of 4 puffs. Before the culling `mid_city` cost ~7 ms per redraw,
  after it ~3 ms (the same range as other levels' heaviest layer).
- `EndFX` (screen): light snow drifting at a slant; a wind gust every `GUST_EVERY` 14-22 s (`gust()`; the port line
  forces one).

**Layout / upper floors**
- Ground: `StreetGround` (asphalt with slush, kerb, pavement, puddles reflecting the pink sky, and footprints in the snow:
  every pair the same distance apart - they walk in step). In the port (`PIER` 4720-6460) it is a wooden pier on piles
  over dark water (`style "pier"`).
- `SIGN_X` 360: `FinSign`, the wooden sign "USHUAIA / FIN DEL MUNDO / THE END OF THE WORLD". Under it the hive wrote in
  glowing fungus "...Y EL PRINCIPIO / AND THE BEGINNING".
- `HOUSES` (860, 1190, 3720, 6720, 7640, 8000): `TinHouse`s. Coloured corrugated two-storey houses with a wooden balcony
  (the deck, at 130-150; invisible `add_floor` + ladder on the left) and AMMO / HEALTH / GRENADE on it, an upper storey,
  a snowy roof with icicles, a chimney, figures waiting at some windows with green eyes. Hive writing on 4 of them:
  "WALK / WITH US", "ONE STEP / ONE BODY", "ZERO / COME HOME", "UNO".
- `TRAIN_X` 2300: `EndTrain`, the End of the World train (it used to carry prisoners to the Presidio): 2 red wooden
  coaches full of seated dead nodding to the beat (roofs = deck at 112, ladder, AMMO), and a black-and-red steam engine
  "Nº 2" (cab roof deck with HEALTH). The `SteamValve` trap sits at the engine's front.
- `SHIP_X` 4980: `CruiseShip` "PAMPA SERENA" moored at the pier: a rusted navy hull with portholes, white decks, bridge,
  funnel, mast, ECHO growth and roots hanging into the water, and the hive writing "WE ARE ALL / GOING HOME". The
  promenade deck (at `SHIP_DECK` 170, two ladders, GRENADE / AMMO / HEALTH) runs the whole ship. A BONESIDE walks it.
  `LIFEBOATS` (5260, 5720) hang from davits over the pier.
- `UPDRAFTS` (1950, 3520, 4500, 6560, 7380, 8420): `Pyre`s, street bonfires of furniture with a tall column of hot air,
  sparks and ash spiralling up. These are the thermals the CONDORs climb (`stage.updrafts()`).
- `ARENA_X` 9000: the yard of the old prison, `Presidio`: the stone facade "CARCEL DE USHUAIA / PRESIDIO 1902" with
  barred arched windows (green eyes behind some bars), the clock tower, barbed wire, and the gatehouse at the level's end.
  Its arch is open on dark stairs going down; ECHO roots pour out of it and dive into the ground with pulses of light
  running down them; "BAJEN" / "COME DOWN, ZERO" is written above it. The exit (`level_w - 230`) is inside the arch.
  In the yard: one cover (`ARENA_COVER`, drums), a raised walkway at 130 with a GRENADE, HEALTH and AMMO at the entrance.
- Obstacles (`custom_gen`, names prefixed `s61_` so main.gd does not take them as its own "car" / "crates" /
  "container"): `car` (small rusted car with snow), `traps` (stacked king-crab traps), `drums`, `crates` (plastic fish
  crates), `container` (only on the pier; off the pier it becomes drums; cars on the pier become fish crates).
- Every world object, trap path (the steam jet, the ground under the lifeboats) and pyre has a `reserve()`d rect.
- `extra_spawns`: BONESIDEs at `BONESIDES` (8) + 1 on the ship's deck; THRONG schools at `SCHOOLS` (5 schools, 31
  members) via `ThrongT.spawn_school(self, x, n)`; a regular on every second deck; 2 regulars in the yard.
- Density: `zombie_density()` 0.85 (the schools come on top of the normal scatter).
- Condor waves (`_waves`): at `CONDOR_WAVES` the stage launches 1 condor gliding in from ahead (meta `cd_fly`); 2 once
  condors have learned (one from each side). Never more than `CONDOR_MAX` 2 near the player; waves passed by more than
  700 px are skipped. A condor more than `FAR_GONE` 2200 px from the player despawns.
- `_hints`: the first time each type is near, an intro popup + a hero line (what they learned, and from what):
  - BONESIDE: "THEY TURN THE BONE TO YOU NOW" / "Every bullet I fired hit flesh... so the side that faces me rotted to
    bone. Get BEHIND it!"
  - CONDOR: "THEY CARRY EACH OTHER NOW" / "I hold the line... so they fly OVER it. Shoot the one it's carrying - or the
    wing!" (sets main meta `cd_pick_said` so the condor's own first-pick line does not repeat it)
  - THRONG: "THEY MOVE AS ONE NOW" / "I picked them off one at a time... so now there is no 'one'. Break the school!"
- `LINES` (environmental story, the hero talking to himself), one per tick:
  - 160: "Ushuaia. The end of the world... and every one of them is walking here."
  - 1420: "They're walking in step. All of them... like one body."
  - 2240: "The prisoners' train. It carried them to the prison... now they walk there by themselves."
  - 2700: "The engine's still got steam. Shoot the valve when they march in front of it."
  - 4760: "The meltwater from the lab runs into this bay. The fungus came down the glacier with it." (+ a gust)
  - 5150: "Lifeboats over the pier... cut the ropes when they walk under."
  - 6620: "They're not attacking the city... they're walking home."
  - 8480: "The roots... all of them go to the old prison."
  - 8900: "The ROOT isn't in the lab any more. It grew down here - under the whole city."
  - After the boss is dead and you are within 760 px of the end: a far bell, and "Down there. That's where they're all
    walking... home."
- Ambience: every 10-16 s `s61_march`, the far thump of thousands of feet in the same step.

**Traps** (`s61_decor.gd`)
- `SteamValve` (on the engine's front, jet to the right): the red valve wheel (`ValveBody`, layer 4) glows when charged.
  Shoot it (or blast it) → the pressure gauge climbs (`WARN_T` 0.45, "!") → a scalding steam jet along the ground,
  `JET_W` 330 x `JET_H` 86 for `JET_T` 1.5 s. Every zombie in it once: `DMG_Z` 70 ("SCALDED", stagger 0.7; the boss
  would take 25). The player in it: `DMG` 1 ("Scalding steam!"). Recharges in `CD` 6 s. The point: wait for a THRONG
  school to march into the jet. No proximity trigger - only your shot sets it off. Moves nothing.
- `Lifeboat` (x2): an orange lifeboat hanging from two davits on ropes (`RopeBody` x2, layer 4) over the pier, its
  bottom at `hang` 128 (zombies walk under). Shoot either rope (or blast) → the boat falls (`G` 1500, moved in
  `_process`) and crushes every zombie its box touches during the fall and on landing (`DMG_Z` 160, "CRUSHED", 60 to a
  boss) and the player (`DMG` 2). Smoke, planks, shake. It stays broken on the pier.
- `Pyre`: decoration only (the thermal you can see); it does not burn.

**BONESIDE** (main type, enemies/types/boneside.gd) - THE USER'S HALF BONE / HALF FLESH ZOMBIE. Split down the middle
from crown to crotch along a seam of torn meat and blood. The front half (the side that faces you: face, chest, the
reaching arm) is bare skeleton: a lipless skull half, an empty rib cage, arm and leg bones. The back half (the nape, the
back, the rear arm) is living, swollen flesh with hair, an ear and rags.
- **What it learned:** the spores carried thousands of "bullet in the flesh" deaths. The hive learned that flesh is what
  bullets hit, so it let the shot side rot to the bone, and keeps the bone side toward you. It is built exactly the way
  it was shot: from the front.
- **Damage:**
  - Bone side (shots from the front): a chest shot passes between the ribs (`RIB_GAP` 45%, "THROUGH THE RIBS"; the
    bullet's `pierce` is raised so it flies on into the zombie behind!). Otherwise it chips bone (x`BONE_MULT` 0.25,
    head x`SKULL_MULT` 0.2; white bone chips). After 5 bone hits the hero says "Bullets go right through the bone... get
    behind it - hit the FLESH!".
  - Flesh side (shots from behind): x`FLESH_MULT` 1.35, blood and meat (FleshFx), wounds that show bone under them.
  - Fire eats flesh: x`FIRE_MULT` 1.5. Blasts x1 (they smash both halves).
- **It turns late:** it turns toward you after `TURN_DELAY` 0.55 s and does not walk while it is turned away. Jump or
  roll over it and shoot its back.
- **CLUB:** close (`CLUB_R` 72) it turns its BACK to you and raises the heavy flesh arm (`CLUB_WIND` 0.5; drawn
  mirrored: the flesh side faces you, x`OPEN_MULT` 1.2), then backhands you (`CLUB_DMG` 1, knockback).
- **LUNGE:** at mid range (`LUNGE_R` 140-270) it crouches bone-shoulder first (`LUNGE_WIND` 0.38) and charges (`LUNGE_V`
  400). It cannot turn mid-charge: jump over and it passes you, flesh to you (`RECOVER` 0.65). `CD` 0.6-1.2 s.
- **Learns** (main meta `bs_flesh` >= `LEARN` 10, back flesh hits): "IT TURNS WITH YOU NOW" + hero "It turns as I
  jump... wait for the swing - it shows the flesh to swing." It turns almost at once (`TURN_FAST` 0.07), pivots under
  you when you jump over it (reads where you will land), and aborts the lunge when you jump. Counter: bait the CLUB (it
  must show the flesh to swing), grenades, fire.
- **Death:** it tears in two along the seam: the bone half and the flesh half lie apart (`_draw_dead`), bones fly from
  one side, blood from the other.

**THE FERRYMAN** (boss; `chase_range > 600`, hp 520 (+400 from level 5), scale 2.4, no ragdoll) - the ferryman of the
Beagle Channel's dead: a giant BONESIDE with a ferry oar in the bone hand, an ECHO lantern on a chain in the flesh hand,
an old captain's cap; his rib cage opens like doors over a glowing ECHO heart.
- **Armour:** the bone side x`B_ARMOR` 0.3 (rib passes too). The flesh (back) x`ROT_MULT`. The heart x`HEART_MULT` 2.4,
  only open while the ribs are open (ly -44..-20).
- **SWEEP:** the oar low and wide (`B_SWEEP_R` 260, `B_SWEEP_WIND` 0.55, `B_SWEEP_DMG` 2): jump.
- **FERRY:** the rib cage opens (`RIB_WIND` 0.7, the heart shows) and he lunges (`RIB_V` 520) to swallow you. Caught
  ("ALL ABOARD", hero: "He's carrying me DOWN - shoot the HEART!"): he walks you toward the gate, squeezing (1 damage
  every `FERRY_SQUEEZE` 1.1 s) for up to `FERRY_MAX` 3.2 s, then throws you. Every shot while inside hits the heart
  (`FERRY_HEART` 3 → you are free), or mash A/D (player grab). Missed lunge: he stands with the ribs open for a moment.
- **SHED:** when you are far (`SHED_R` 380, every `SHED_CD` 5.5 s) he shakes `SHED_N` 5 bone shards at you in a fan
  (`BoneShard`, 1 damage, moved in `_process`).
- **TOLL:** he rings the lantern (`TOLL_CD` 15 s, `TOLL_T` 1.3): a THRONG school of `TOLL_N` 4 marches into the yard from
  behind you ("ALL ABOARD"), at most `TOLL_MAX` 2 schools alive.
- He turns slowly (`TURN_T` 0.75): roll behind him. Keeps to the yard (`ARENA_W` 1150). `B_CD` 0.4-0.95 s.
- **Learns in the fight:**
  - After `BACK_LEARN` 10 back hits: "IT TURNS WITH YOU NOW" - turns fast (`TURN_T_LEARN` 0.2) and sweeps backwards.
    Hero: "He turns faster now... make him open the ribs."
  - Every `ROT_EVERY` 180 hp lost: "IT ROTS THE FLESH NOW" - the flesh rots to bone (`ROT_MULT` 1.4 → 1.15 → 0.9 → 0.7),
    so the back pays less and less and the heart is the way to finish him. Hero: "The flesh is rotting to bone where I
    hit it... shoot the HEART when the ribs open!"
- Death: his schools die with him, he bellows, the bell rings, and he bursts into bone and meat.

**CONDOR** (the flyer, enemies/types/condor.gd) - a dead Andean condor, huge (the wingspan of one and a half men): black
body, white ruff, bald grey-pink head with a comb, hooked beak, and the spread "fingers" of its primaries. Feathers are
gone in places and show ribs and membrane. A green ECHO eye. In its talons hangs a zombie (the RIDER), kicking.
- **What it learned:** the hero stops them at a line - they walk at him from the front and die in a row. So the hive
  learned to go over the line: "THEY CARRY EACH OTHER NOW". The condor does not attack itself. It carries.
- **How it flies (not like any earlier flyer):** it almost never flaps. It rides the city's thermals (`stage.updrafts()`,
  the pyres): it circles up in one (`CLIMB_V` 90) to `THERMAL_TOP` 400, glides at you (`GLIDE_V` 200), sinking slowly
  (`SINK_V` 26). Too low (`MIN_H` 175) → back to the nearest thermal. Its line is predictable - that is how you shoot it.
- **Cycle:** THERMAL → GLIDE → RUN (over you, the rider screams) → DROP (lets the rider go on you: a real zombie falls;
  landing on you = "LANDED ON YOU", `DROP_DMG` 1) → LEAVE (a few heavy wingbeats, empty) → PICK: it dives and grabs a
  regular / runner / THRONG from the ground ahead (`PICK_R` 650) to carry it too. Nobody to pick? It fetches one from
  outside (`RIDERS` 2), then flies away to sea (AWAY, despawns).
- **Counters:**
  - Shoot the rider (`RiderBody`, `RIDER_HP` 26): it dies in the talons and falls as a corpse ("CARGO DOWN"). Counts in
    main meta `cd_shot`.
  - Shoot a wing (`WingBody` x2, layer 4, `WING_HP` 34): it spirals down and crashes (`CRASH_DMG` 90, "WING!",
    "GROUNDED!"); the rider falls alive.
  - A blast rips both wings (and kills the rider).
- **Learns** (main meta `cd_shot` >= `LEARN` 3 riders shot down): "THEY DROP THEM BEHIND YOU NOW" + hero "Behind me - it's
  dropping them BEHIND me!". It flies higher (`HIGH_LEARN` +90), comes from behind, and at the last moment swoops low
  (`SWOOP_H` 150) to drop the rider behind your back (on the side you are not facing, `BEHIND` 120). Counter: turn, keep
  your back to a wall.

**THRONG** (enemies/types/throng.gd) - the crowd of Ushuaia: townspeople, fishermen, dockers, cruise tourists in bright
puffer coats, beanies with pompoms, boots. Alone each is weak (a shot or two). But they are not alone: they are a
`School`, one body made of many, like a school of fish. A glowing ECHO thread ties nape to nape, the eyes pulse together,
and they march in exactly the same step (`BEAT` 0.5 s, one global phase for every crowd in the level and the background).
- **What they learned:** one body can be shot. Thousands of dead who were shot alone taught the hive that the single one
  dies, so it stopped moving single ones. It moves one body made of many: "THEY MOVE AS ONE NOW".
- **The School** (shared by all members; the first live member updates it once per physics frame):
  - MARCH: the school's anchor (`ax`) steps toward you on the beat (`MARCH_V` 84); every member runs to its slot (`GAP`
    26). If you are on a deck above them, they all jump together on the beat.
  - SURGE: the front within `SURGE_R` 150 → on the next beat the whole school lunges with arms out (`SURGE_V` 270,
    `SURGE_T` 0.42). One bite per school every `BITE_CD` 0.9 s (not 8 bites at once - fair).
  - FLINCH: a member is hit → the whole school steps back together.
  - SCATTER: a blast, or `SCATTER_DEATHS` 3 deaths within `SCATTER_WIN` 1.4 s → they scatter in all directions in leaps
    ("SCATTERED!", `SCATTER_T` 1.25), then REGROUP back into formation. That is the window to reap them.
  - A lone THRONG from the normal scatter (or dropped by a condor) joins a school within `JOIN_R` 420 or starts one.
- **Learns** (main meta `thr_broken` >= `LEARN` 2 schools scattered or wiped): "THEY FLANK NOW" + hero "They split around
  me... like a school of fish!". When the school reaches you (`SPLIT_R` 250) it splits like fish around a predator: the
  back half leaps over you in one synchronised arc (`SPLIT_T` 0.72) and lands behind you as a new school; both halves
  close in. Counter: shoot them in the air during the leap (they hang there together), a grenade in the middle, or back
  off before they arrive.


## Stage 62 - "THE HIVE MIND" (THEY LEARNED TO THINK AS ONE)

Zone 7 (Patagonia), stage 8. Under Ushuaia, beneath the old End of the World prison (the Presidio), the ROOT has grown into a living cave:
- walls of brain tissue and fungus;
- nerve threads that carry pulses of light toward the heart;
- cocoons with bodies inside;
- glowing memory pools that replay the hero's old fights.

The hive writes to him in fungus on the walls ("WE ARE ONE", "EVERY LESSON CAME HOME", "TEACHER", "COME DOWN / ZERO"). Here it speaks to him for the first time in one voice and tells him THE WHY. The level ends at the shaft that goes down to the heart (63).

**Files**
- `levels/stage_62.gd` covers layout, spawns, memory pools, SYNAPSE groups, intro hints, hero lines (through a queue: `_say`, `SAY_GAP`) and story hooks.
  - Sounds: `s62_squish`, `s62_sever`, `s62_charge`, `s62_sync`, `s62_gurgle`, `s62_chomp`, `s62_maw_die`, `s62_rise`, `s62_heart`, `s62_drone`, `s62_replay`. All are synthesised; there are no new sound files except the story voices.
  - Music: `level2_suspense.mp3`.
- `effects/s62_decor.gd` holds the sky, 3 parallax layers, all world objects, traps and screen FX.
  - It has a shared static state `U`:
    - `U.voice_ms`, `replay_ms` and `face_ms` are set by the scene;
    - `U.sync_ms` is set by a ganglion;
    - `U.heart` is 0..1 and gets stronger near the arena.
  - The `U` helpers (`quad/oval/halo/nerve/taper/figure...` + `flush`) are also used by the three zombie types, so each zombie is one draw call.
- `enemies/types/seeper.gd` - SEEPER and the boss THE FLOOD.
- `enemies/types/synapse.gd` - SYNAPSE. `make_group()` is static and is called by the stage.
- `enemies/types/remnant.gd` - REMNANT. `set_memory(i, rising)` is called by the stage and the pools.
- `story/scenes/l62_hive.gd` + `sounds/story/l62_hive/` - the story scene (the hive's one voice).
- `map/thumbs/level_62.png` - level card.

**Background (Backdrop)**
- `hive_sky`: the black-purple dark of the cave, a deep green glow from below (the heart) and glowing spores that rise slowly.
- `far_cavern` (0.06): a huge dome with:
  - flesh stalactites and flesh hills;
  - giant nerve trunks with pulses;
  - distant glowing mushrooms.
- `mid_wall` (0.28): the brain-tissue wall with:
  - folds (gyri);
  - cocoons with bodies in them, bones and blisters;
  - nerve threads with glowing beads;
  - the hive's fungus writing (`WRITING`).
- `near_roots` (0.6) has:
  - thick roots from the ceiling and fungus curtains;
  - a horizontal nerve rope with pulses running right;
  - glowing mushrooms and bones.
- `hive_overlay`: a green haze behind the figures, ceiling shadow and floor mist.
- `HiveFX` (screen) adds:
  - drifting spores;
  - a heartbeat vignette at the screen edges (`U.heart`);
  - a green ripple while the hive speaks;
  - a red flash when a ganglion fires.

**Layout**
- 0-760: `Cellar`. The prison cellar with stone stairs going down, bars, and the sign "PRESIDIO DE USHUAIA / NIVEL INFERIOR - NO PASAR". Fungus breaks through the cracks. The floor (`HiveGround.stone`) is prison stone that turns into flesh by x 2000.
- `POOLS` (1500 THE FIRST, 3420 SUBJECT FOUR, 6350 THE SPITTER, 7150 THE HOUND, 8180 THE FIRST):
  - each is a `MemoryPool` replaying an old fight: a flickering hero silhouette shooting the remembered enemy, with scanlines and "MEMORY: X" under it;
  - when the player comes within `POOL_R` 430, a REMNANT of that memory rises out of it;
  - once REMNANTs have learned (`rmn_kills >= 4`), the pool releases two.
- `PILLARS` (2620, 4260, 7920): flesh columns from floor to ceiling, wrapped in nerves.
- `SHELVES` (2160, 3130, 6480, 8240): bracket mushrooms on the wall. Each is an invisible `add_floor` at tier 120 (one jump, no ladder) with a pickup on top. Every second one has a zombie on it.
- `OBST`: fixed cover (`Obstacle` "pod", "bones", "root", "stalk"). The road generators use the same 4 kinds.
- `STORY` 4500-5940: the chamber of the one voice (`HiveChamber`):
  - a giant brain arch;
  - 14 nerve threads converging on the big pool (`MemoryPool.big`) at `STORY_ACTOR` 5300;
  - glowing memory cocoons on the sides;
  - a face in the wall that appears when the hive speaks.
- `ARENA_X` 9050 to the end is `FloodArena`:
  - a flooded basin (thin green liquid with ripples) and the heart wall with arteries;
  - at the far end, "EL CORAZON", a huge flesh sphincter: the shaft down to the heart, glowing red and green and beating with `U.heart`;
  - two arena shelves (`ARENA_SHELVES` 9300, 9760) to get above the boss's wave;
  - HEALTH + AMMO before the arena.

**Traps**
- `Ganglion` (`GANGLIA` 2950, 3780, 6820, 8560). A nerve knot on a flesh column (`KNOT_Y` 150).
  - Trigger: when the hero comes within `TRIG_R` 540, a red pulse starts down the thread from the ceiling (`WARN_T` 2.1 s, "!" over the knot, sound `s62_charge`).
  - If the pulse arrives, "THEY THINK AS ONE": every zombie within `RANGE` 1000 gets `_alert_t`, `rush(hero)` and the `drum_t` meta (x1.3 speed, the same as the level-41 drum) for `SYNC_T` 5 s. There is a screen flash and the `s62_sync` chord. Cooldown `CD` 11.
  - Counter: shoot the knot (`GangBody` on layer 4, `HP` 34; blasts kill it) and it is "SEVERED" forever.
  - The first time one fires, the hero says "A signal in the nerve - SHOOT THE KNOT before it gets there!".
- `Maw` (`MAWS` 1960, 4060, 7600). A flesh sphincter in the floor.
  - Anyone standing on it (also zombies, not bosses) sets it off: the lips tremble and drool (`WARN_T` 0.6), then jaws of teeth rise from the floor and close (`BITE_T`).
  - The hero takes `DMG` 1 and is held (`HOLD_T` slow).
  - Zombies are "DEVOURED" (`DMG_Z` 140, so it eats its own).
  - Counter: shoot the eye on the stalk (`HP` 46) and it reads "MAW DEAD". It is in the `hazards` group (`world_rect` / `danger_at`) and the `blastable` group.

**New zombies**

SEEPER (main type, kind 197). Bright toxic green and translucent: a liquid body in the shape of a man, the skeleton of whoever he was floating inside, and a glowing CORE swimming in the chest.
- **What it learned:** "a body can be shot - a puddle can't". Intro: "THEY MELT NOW" and the hero says "They learned a body can be shot... a puddle can't. Hit the glowing CORE!".
- **Melting:**
  - A hit that would kill it (predicted with `hit_damage()` x `MARGIN_HEAD` 2.2 / `MARGIN_BODY` 1.3) is blocked, and instead it MELTS (`MELT_T` 0.45, "MELTS").
  - The puddle takes no bullet damage ("SPLASH", green splash, `GooSplash`). After 6 splashes the hero says "Bullets just splash. Wait for it to RISE - then the core!".
  - The puddle flows to the hero (`FLOW_V` 210) with a leading bulge, ripples, bubbles and two floating eyes. It is sticky underfoot (`STICK` slow).
  - After 1.6-2.2 s it REFORMS: a rising column with slime strands (`REFORM_T` 1.15). If the hero stands on it, he takes a SURGE (1 damage).
  - It comes back with `REFORM_HP` 0.65 of max hp.
- **How to really kill it:**
  - the CORE, with a ray test from the hit (`CORE_R`): x`CORE_MULT` 1.8 and it can kill ("CORE BURST");
  - while it reforms, the core is big and exposed (x`REFORM_CORE` 2.6) and its hp is still low, so one good shot does it. Body hits during the reform do x`SOFT` 0.5 and never kill;
  - fire or blasts evaporate it: on the body x1.5 / x1.4 and lethal; on the puddle, instant death ("EVAPORATED");
  - after `MAX_REFORMS` 3 it can't hold together ("IT CAN'T HOLD") and dies normally.
- **Attack:** ENGULF. Close up, it swells (`ENGULF_WIND` 0.45) and throws itself on the hero: 1 damage + slow ("ENGULFED").
- **Learns:** meta `sep_beaten` counts core kills and evaporations.
  - At 3 or more: "IT RISES BEHIND YOU NOW". The puddle flows under the hero and reforms `BEHIND` 120 px past him, then attacks at once.
  - At 5 or more: "IT SPLITS NOW". When it melts it splits into two mini puddles (scale 0.78, 55% hp) that reform on both sides of the hero.
- **Placement:** `SEEPERS` lists walkers and `lurk` puddles. A lurk puddle waits on the floor until the hero is within `LURK_R` 230, then "!!", and it flows and rises. SEEPERs also come from the road spawns (weight 0.04).
- **Other code:**
  - `start_puddle(wait, flow_to)` and `make_mini()` are used by split, by the boss and by the stage.
  - Dead: the liquid spreads on the floor and soaks in (drawn at the death spot).
  - Scene actor mode: `speaker` (the mouth moves while it talks), `scene_melt` (it melts into the pool), and on `U.face_ms` its features take on the hero's face.

THE FLOOD (SEEPER boss, `chase_range > 600`). A giant SEEPER made of many bodies (several skulls float inside it) with a crown of drips.
- **Hit model:** core x2.0, body x0.8, fire x1.4, blast x1.3. The HUD name is "THE FLOOD".
- **Attacks:**
  - SLAM (`B_SLAM_R` 170, wind 0.6, 2 damage);
  - SPIT: 3 goo globs (`acid.gd`, they leave acid pools). Every second spit sheds a mini SEEPER puddle that flows at the hero (`MINI_MAX` 3).
- **Waves:** at `GATES` 70% and 40% hp it breaks ("THE FLOOD BREAKS"), melts and becomes a WAVE.
  - The wave runs across the whole arena to the far wall (`WAVE_V` 430, `WAVE_H` 72, 2 damage + slow). Bullets only splash it.
  - The counter is to jump it (one jump clears 72) or stand on an arena shelf. The hero says "It's coming as a WAVE - jump it or get up high!".
  - After the wave it pools, then reforms on the other side (`B_REFORM_T` 1.7) with the core exposed (x`B_REFORM_CORE` 3.0).
- **Learns in the fight:**
  - After the first wave, "IT RISES WHERE YOU STAND NOW". GEYSER: a bubbling ring under the hero (`GEY_WARN` 0.95), then a 210 px column of goo (1 damage, knock up). It works on shelves too, so standing still is punished.
  - Below half hp, "IT SPLITS NOW": every reform sheds two mini SEEPERs.
- **Death:** "THE FLOOD DRAINS"; the minis evaporate. The hero then says "The heart is down there. I can hear it beating.".

SYNAPSE (flyer, kind 198). Flying nerve cells: a translucent cell body, a glowing nucleus, writhing dendrites with glowing tips, and an axon tail.
- **They never fly alone.** `SynapseT.make_group(main, x, ground, n)` makes a pair or a trio joined by a current. The stage makes the `SYN_GROUPS` when the hero comes within 1000 px, so a late group already knows what was learned.
- **What they learned:** the hero dodges anything thrown at him, so the hive stretches a wall of current across his path. Intro: "THEY LINK NOW" and the hero says "They learned I dodge. So they made a wall. Shoot ONE knot - the link breaks!".
- **How it differs from DRIFTER / BUOY / MURMUR / BLOOM:**
  - new flight: SACCADE, like an eye. The group hangs frozen (`HOLD_T`), then snaps (`SNAP_T` 0.17) to a new centre in front of or over the hero, at a height where the rotating bar or triangle cuts through him;
  - new weakness: any one node (`NODE_HP` 14, blast x2) breaks the link;
  - new learned trick: the spare (below).
- **Current cycle:**
  - REST (`REST_T` 1.4): a limp nerve fibre, safe to pass;
  - CHARGE (`CHARGE_T` 0.55): sparks run along it and it flickers;
  - LIVE (`LIVE_T` 2.2): a double lightning bolt with a glow. It hurts on contact (1 damage + slow), rotates faster, and the centre creeps toward the hero (`CREEP`);
  - zombies that touch a LIVE link are "FRIED" (`DMG_Z` 30).
- **After a break:** "LINK BROKEN". A lone node becomes a STRAY: it flies at the hero in short saccades, crackles (`STRAY_TELL` 0.5) and sparks at close range.
- **Learns:** meta `syn_breaks` 3 or more gives "THEY KEEP A SPARE NOW". New groups come with a spare node hovering behind the group. It flies in to replace the one that fell ("RELINKED", `RELINK_T` 0.8), and the groups spread wider (x`WIDE` 1.4).
- **Code:** the group is a shared Dictionary. The leader (the first live member) runs the group and draws the links in its own batch. Nodes are positioned directly (`collision_mask` 0, like BLOOM). Dead nodes fall.

REMNANT (kind 199). An echo of an old fight that the hive kept. A translucent body in memory light (`Decor.MEM`) with scanlines, a glitch that jumps it sideways for a moment, and an afterimage when it moves fast.
- **What they learned:** the hive kept not only that the hero won, but HOW they fought him. Intro: "THEY REMEMBER YOUR FIGHTS NOW" and the hero says "I killed that one years ago. They kept the memory - and the trick.".
- **Memories** (`Decor.MEMORIES`, set by the pool):
  - 0 THE FIRST: a giant with a car door that blocks bullets from the front in its band (`DOOR_Y` / `DOOR_H`). SLAM: it lifts the door overhead (front open, x1.4) and slams.
  - 1 THE SPITTER: keeps its distance (`SPIT_R`) and lobs acid (`acid.gd`).
  - 2 SUBJECT FOUR: ROLLs at the hero ("PHASED": bullets pass through), then an UPPERCUT. Open afterwards.
  - 3 THE HOUND: four legs. Crouches (`POUNCE_WIND`) and makes a long leap. Open after landing.
- **Other moves:** everyone else has a short SWIPE. It RISES out of the pool and can't be hurt until it is whole ("NOT YET").
- **Learns:** meta `rmn_kills` 4 or more gives "THEY USE IT ALL AT ONCE NOW". Each new REMNANT gets a second trick from another memory (THE FIRST that also spits, a hound that also rolls...), +12 hp, and the pools release pairs.
- **Death:** "MEMORY FADES", and the body comes apart into rising shards of light.

**Story (environmental + scene)**
- Hero lines (`LINES`, queued so they never overlap):
  - 560: "The prison goes down further than any map said."
  - 1020: "That's me... in the water. They're replaying my fights."
  - 2860: "The whole cave is thinking. I can feel it."
  - 6240: "Every fight I ever had... they kept all of it."
  - 8950: "Something big is moving in the water."
  - Arena entry: "THE FLOOD" + "All of them... melted into ONE. Find the core!"
  - After the boss: "The heart is down there. I can hear it beating."
- Scene `l62_hive` (actor SEEPER, `actor_props {"speaker": true}`, `dist` 250, ending "vanish"). Its actions go to `on_story_beat`:
  - "speak" pulses the walls, nerves and the face in the wall;
  - "replay" flashes every memory pool and plays `s62_replay`;
  - "mirror" turns the face in the wall, and the speaker's face, into the hero's;
  - "melt" melts the speaker into the pool.
  - After the scene, the big pool releases two memories (THE FIRST, THE HOUND) and the hero says "Teacher. That's what I am to them.".

**Performance**
- Every `_draw` is the DrawBatch wrapper. Each zombie is one draw call (`Decor.U` helpers + `U.flush`; no strings in zombie draws). The SYNAPSE links and THE FLOOD's wave and geyser are inside the owner's batch.
- Decor redraws every 3-8 frames when on screen.
- `GooSplash` keeps at most `MAX_LIVE` 10 and moves in `_process`. Particles scale with `Quality`.
- No MOVERS needed: `Ganglion` / `Maw` use `_physics_process` but do not move, and the SYNAPSE are zombies.
- Draw calls (xvfb, holding fire, +6..8 extra SEEPER/REMNANT): 426-482 average. The same tool on level 58 gives 462-467. Without extras: 398 / 437.


## Stage 63 - "THE HEART" (THEY LEARNED YOU)

Zone 7 (Patagonia), stage 9, **the last level of the game**. At the bottom of the shaft under Ushuaia's old prison
(62) the hero reaches the heart of the ROOT. Every lesson the hive ever learned from him, from every region and every
kill, ended up here, and the hive has built him a museum: statues of him in every pose he ever fought in, wombs that
grow HOLLOWs (copies of him), and arteries that carry lessons home. The heart beats faster the closer he gets. At the
end the ROOT speaks and asks him to come home. He chooses: **DESTROY** or **JOIN**.

**Files**
- `levels/stage_63.gd` - layout, spawns, the heartbeat, PILGRIM waves, lesson bookkeeping, the hall and arena locks,
  intro hints, the hero's lines, the hand-off to the ending. Sounds `s63_beat`, `s63_squelch`, `s63_burst`,
  `s63_membrane`, `s63_gurgle`, `s63_geyser`, `s63_creak`, `s63_grip`, `s63_home`, `s63_lost` (synthesised).
- `effects/s63_decor.gd` - backdrop + all world objects, traps and screen FX. Also the shared state `Decor.U`
  (`beat`, `beats`, `heart_k`, `lessons`, `life`, `note`, `say()`), `CAT_COL` / `CAT_NAME` and the weapon-category
  helpers `cat_of_weapon(id)` / `cat_of_src(src)` ("auto", "shotgun", "precision", "explosive", "other").
- `effects/s63_ending.gd` - the ending (below). Text and voices: `story/scenes/l63_ending.gd`,
  `sounds/story/l63_ending/`.
- `enemies/types/hollow.gd` - HOLLOW and the mid-boss SUBJECT ZERO (+ `SporeLob`).
- `enemies/types/pilgrim.gd` - PILGRIM (+ `LooseLesson`).
- `enemies/types/root.gd` - THE ROOT.
- `map/thumbs/level_63.png` - level card.

**The idea: the level learns your gun.** `stage_63._track_shots` counts every shot by weapon category
(`Game.shot_id` + `player.gun`, `Decor.cat_of_weapon`). `fav_cat(rank)` = the category you use most (rank 0) / second
most (rank 1). HOLLOWs switch to it, SUBJECT ZERO and the ROOT's face fire it at you. Every PILGRIM that gets home is a
lesson on the category that killed its body, and the ROOT resists that category more.

**The heartbeat** (`_process`): a beat every `BEAT_T` 1.25 s at the entrance down to 0.62 s near the heart
(`U.heart_k` = how far in you are). In the arena it also speeds up as the ROOT loses hp. Each beat sets `U.beat` = 1
(every decor piece and PILGRIM wing reads it), plays `s63_beat` (louder near the heart) and ticks the valves. It stops
when the ROOT dies.

**Background (Backdrop)**
- `heart_sky`: the inside of a giant body: dark red vault, glowing ECHO veins, slow pulse.
- `far_vault` (0.06): ribbed cave walls of flesh with arteries and hanging roots.
- `mid_memory` (0.28): the "memory wall": fungus flesh with grown, half-melted remnants of memories from every
  region (8 kinds), and nerve threads.
- `near_flesh` (0.6): hanging root curtains, ganglia, rib arches, spore sacs that pulse with the heart.
- `heart_overlay`: warm haze behind the figures and the ceiling's shadow.
- `HeartFX` (screen): floating spores, the beat pulsing at the screen edges (stronger near the heart), the
  "LESSONS HOME" counter (right, under the style meter: one coloured dot per category with a count; appears after the
  first PILGRIM is seen) and notes (`U.notify`, under the boss bar). `Decor.U.say(pl, text, col)` queues hero lines
  2.3 s apart so two lines never overlap (dropped if more than 5 s late).

**Layout**
- `Threshold` (start): the prison gate swallowed by fungus, a rotten "PRESIDIO DE USH..." sign, chains, and a flesh
  mound carved "WELCOME HOME / ZERO".
- `FleshGround`: floor tiles of flesh with veins (one draw call per tile, redraw every 6 frames on screen).
- **Gallery of memory** (to 3500):
  - `STATUES` (13): fungus `Statue`s of the hero in 4 poses (aiming, rolling, kneeling, jumping). Some hold a sleeping HOLLOW
    (`[x, pose, true]`): it cracks out when you come within `WAKE_R` 240 or shoot it.
  - `PODS` (8): `HollowPod` wombs. A HOLLOW grows inside; when you come near it ripens (`RIPE_T` 0.9, the sac
    swells) and bursts. Shoot it before: the glass takes x`POD_MULT` 0.7 and the HOLLOW comes out hurt.
  - `SHELVES` (5): `RootShelf` root ledges (`add_floor` + 2 ladders) with loot: AMMO / HEALTH / GRENADE, some with
    a walker on top.
  - `MOUTHS` (7): `VeinMouth`s, artery mouths high on the wall (`MOUTH_H` 470) that PILGRIM waves fly out of.
- **Hall of mirrors** `HALL` (3500-4400): `MirrorHall` back wall (a glossy membrane with hundreds of hero silhouettes
  and "SUBJECT ZERO" carved in). Two `Membrane`s close behind and ahead of you when you step in ("SEALED IN"): solid
  walls of flesh (layer 1, they push you and zombies out of the wall's width). `HALL_COVER`: bones + barrels.
  `HALL_PODS` (2) burst when SUBJECT ZERO reaches phase 2. When ZERO dies: "THE HALL OPENS" and the hero says "It had
  my face... but not my memories."
- **Nerve road** (4400-8300): the checkpoint (main.gd, at half the level), more statues, pods, shelves, valves, snares
  and the denser PILGRIM waves.
- **Heart chamber** `ARENA_X0` 8300: the third membrane closes behind you. `HeartChamber` back wall with curved
  arteries running to the heart. `ARENA_SHELVES` (2 ledges), `ARENA_COVER` (bones, a car), `ARENA_PODS` (2, the ROOT
  calls them in phase III), `ARENA_MOUTHS` (2). HEALTH + AMMO at the entrance. A wall at `ROOT_X`-30 that blocks only
  the player (layer 512), so you can never walk into the ROOT.
- The exit never opens on a boss death: `_first_tick` removes the exit from `level_exit`. The ending calls
  `main._level_complete()` itself.
- Generated obstacles come from `custom_gen` as `Decor.Obstacle` (`s63_car`, `s63_barrels`, `s63_sandbags`,
  `s63_bones`; the `s63_` prefix stops main.gd from placing its own cars/barrels). None in the hall or the arena. All
  `Obstacle`s are in group `cover` with `cover_rect()` (HOLLOWs hide behind them).
- `zombie_weights()`: HOLLOW 0.07, regulars 0.56, runners 0.37. Most HOLLOWs come from statues and pods.
- `extra_spawns`: statue HOLLOWs, pod HOLLOWs (hall + arena pods held until called), SUBJECT ZERO at `HALL_BOSS_X`
  4160 (`chase_range` 650), walkers on the ledges.
- **PILGRIM waves** (`_wave`): every `WAVE_T` 8.5-12.5 s (x0.8 past half way) the nearest artery mouth ahead of you
  pulses and launches one PILGRIM (`MAX_PILGRIMS` 3 alive). Not while the hall is sealed. Plus: every HOLLOW you kill
  has a 60% chance to release a PILGRIM from its body 0.7 s later, carrying the lesson of the weapon that killed it.
- `_hints`: first time near:
  - a statue: "Statues of me. Every pose I ever fought in."
  - HOLLOW: "THEY FIGHT LIKE YOU NOW" / "That's... me. My coat, my roll. They GREW me."
  - PILGRIM: "THEY CARRY YOUR LESSONS HOME NOW" / "It's carrying something home. Shoot the sac before it gets there!"
  - at the start (not when starting from the checkpoint): "The heart. I can hear it from here... and it can hear me."
- Lessons: `lesson_home(cat, pos)` -> `U.lessons[cat]` +1, "A LESSON REACHED THE ROOT - <CAT>" note, `s63_home`, the
  hero: "One got through. The heart just learned my <cat>." `lesson_lost(cat)` -> main meta `pg_lost` +1.
- `drop_supply(kind)`: each ROOT phase change drops a pickup from above near you: AMMO (HEALTH before phase IV).

**Traps** (`s63_decor.gd`)
- `HeartValve` (`VALVES` 7): a valve in the floor. It swells on one beat (the warning: it bulges and glows,
  `WARN_T` 0.55) and erupts on the next (every `EVERY` 3rd beat, offset per valve): a geyser `HALF_W` 46 x `HGT` 190
  for `BLAST_T` 0.7 s. It does `DMG` 1 to you and throws you up (`LAUNCH` 620), and does `DMG_Z` 26 + launch to
  zombies (bait them). Shoot the valve and it erupts right away (to blow up a group). First hit: "The floor beats with the heart... watch the valves swell."
- `RootSnare` (`SNARES` 6): a root hidden in the floor with a small bulb next to it. Step on it (`TRIG_R` 34) and it
  creaks (`TELL_T` 0.32) then grips your legs: `DMG` 1 and slow (`SLOW_T` 1.4). It also grips zombies that walk over
  it (`HOLD_T` 2 s, meta `s63_held`, the stage holds them in place). Shoot the bulb (ValveBody, layer 4) and the
  snare is dead. `CD` 3.5 s between grips. First grip: "ROOTED - shoot the bulb next to it!"

**HOLLOW** - a copy of the hero grown by the hive: his long torn coat and hood, and instead of a face a black hollow
with two green slits. ECHO veins glow in the coat, the hands are pale fungus, the rifle is wrapped in roots.
- **What it learned:** the hive was built to learn SUBJECT ZERO, and here it grows him again. "THEY FIGHT LIKE YOU
  NOW". It keeps your favourite distance (`PlayerMemory.avg_distance`), fires telegraphed bursts (a glow at the
  muzzle, `MODES[mode].tell`), rolls when shot at (`ON_SHOT_CHANCE` 0.35, `ROLL_CD` 2.2; while rolling it can only be
  hurt by blasts - like you), jumps and fires in the air (`JUMP_CHANCE` 0.22), runs to cover when hurt
  (`COVER_CHANCE` 0.3, group `cover`), and clubs you up close (`MELEE_R` 70). It aims chest high (`AIM_HIGH`) so a
  crouch dodges, and once it has seen you crouch it sometimes aims low (`AIM_LOW`).
- At most `MAX_SHOOTERS` 2 (non-boss) HOLLOWs aim/fire at once.
- Where: `STATUE` (cracks out), `POD` (bursts out), or plain spawns.
- **Learns:** HOLLOW kills count in main meta `ho_kills`. After `LEARN_N` 4: "THEY USE YOUR <CAT> NOW" and every
  HOLLOW switches to your favourite weapon category (stage `fav_cat(0)`; main meta `ho_mode`):
  - BURSTS (auto): a 4-round burst;
  - SHOTGUN: rushes to 130-220 px and fires 5 pellets;
  - AIM (precision): a long laser tell and one fast shot (1250 px/s) from far;
  - BLASTS (explosive): lobs a `SporeLob` in an arc with a landing mark (pops for 1 within `LOB_R` 74);
  - rifle (before it learns, or "other"): 2 shots.
  Hero line per category ("They learned my shotgun..." etc.).
- On death the stage may release a PILGRIM carrying the lesson of what killed it.

**SUBJECT ZERO** (mid-boss in the hall; `chase_range` > 600; hp 200 (+400 boss), scale 1.3) - the first HOLLOW, the
hive's best copy, bigger, coat full of roots.
- Waits until you are within 600: "IT IS YOU NOW", "Subject Zero. They grew ME. With my gun." Then the membranes close.
- Fires your favourite category from the start, rolls on 70% of the shots aimed at him (`B_ROLL_CD` 1.1 s), uses
  `HALL_COVER` (35% of attacks), `B_CD` 0.6-1.1 s between attacks, armour x`B_ARMOR` 0.9, open x`B_OPEN_MULT` 1.35
  while recovering or calling.
- At 50%: "IT REMEMBERS YOUR LAST FIGHT" (`zero_call` roar): alternates your first and second favourite categories,
  attacks faster (`B_CD2`, `B_ROLL_CD2` 0.8), **copies your rolls and jumps** (`B_COPY_DELAY` 0.16 s after you) and
  bursts the two hall pods.
- Never leaves the hall.

**PILGRIM** (the flyer) - a robed, hooded corpse lying flat on its belly in the air, borne on two flesh-membrane wings
like a ray's that ripple along their length. Under its chest it hugs a glowing lesson sac coloured by the weapon
category of the lesson (`Decor.CAT_COL`: yellow BURSTS, orange SHOTGUN, blue AIM, red BLASTS).
- **New way of flying:** it does not chase you - it flies **home**, to the right, toward the ROOT. Its wings beat with
  the heart: on every beat it surges (`SURGE` x1.6 of `SPEED` 185), between beats it slacks (`SLACK` 0.45) - that is
  when you shoot it. Far behind you it hurries (`CATCH_UP` 270). It flies in a lane `LANE` 190-400 px above the floor
  with a slow wave. Shot at, it veers to another lane (`VEER_CHANCE` 0.45, `VEER_CD` 1.6). Passing over you it drops
  a spore puff (`PUFF_R` 80): your aim sways for `PUFF_T` 2.2 s ("SPORES IN YOUR EYES").
- **New weak point: the sac.** A hit on the sac (`SAC_R` 10 x scale) kills it at once: "LESSON LOST", the lesson
  never arrives (`lesson_lost`). The robe is spongy (x`ROBE_MULT` 0.7). HP 30.
- **Home:** `HOME_AHEAD` 820 px ahead of you / past an artery mouth ahead / into the heart chamber; in the arena it
  flies into the ROOT's core. Each one that gets home: `lesson_home` (the ROOT resists that category more; in the
  arena it also heals the ROOT).
- **Learns:** sacs lost count in main meta `pg_lost`. After `LEARN_LOST` 3: "THEY PASS IT ON NOW". A PILGRIM killed
  without hitting its sac throws the sac ahead (`LooseLesson`, a small glowing body on layer 4 that drifts home on its
  own, or merges into another PILGRIM's sac - a double lesson). One shot on the floating sac = lost. Hero: "It threw
  the lesson! Shoot the SAC, not the body."
- Positioned directly (no `move_and_slide`, `collision_mask` 0). One draw call.

**THE ROOT** (the final boss; hp 1200 (+400), scale 10.87, does not move) - the first culture of ECHO: a giant
heart-brain of fungus grown into the right wall of the chamber from floor to ceiling. Brain folds, two heart lobes that
beat with `U.beat`, thick arteries up to the ceiling, roots sinking into the floor, the faces of the absorbed pressed
from inside against the skin. In the middle of its front: the **core**, a vertical slit with lips of flesh that opens
on a green-white light.
- **Damage:** core x`CORE_MULT` 1.45, body x`BODY_MULT` 0.35 ("RESISTED"), each multiplied by `resist[cat]`. Blasts
  hit it (group `blastable`, deduped per frame). Phase changes `PHASE_AT` 75/50/25%: `TRANS_T` 2.2 s invulnerable
  ("IT IS CHANGING"), a title card "LESSON OF THE <REGION>" / "<sub>", and `drop_supply`.
- **Intro:** when you pass the arena gate +150: the membrane closes, the camera frames the ROOT, "IT LEARNED YOU" +
  "IT ALREADY KNOWS: <categories>" listing the lessons that got home, hero: "There you are. The first one. The ROOT."
- **Resist:** at the start, every lesson home (`U.lessons`) lowers that category's multiplier by `RESIST_STEP` 0.1
  (min `RESIST_MIN` 0.5). In the fight, PILGRIMs keep flying from the arena mouths into the core every
  `ARENA_PG_T` 13/12/11/9 s: each one that arrives = "IT LEARNED YOUR <CAT>", resist -0.1 and +`LEARN_HEAL` 45 hp.
  Hero: "They're feeding it lessons. Shoot the sacs before they reach the heart!"
- **Pulse:** stand within `PULSE_R` 160 and it swells (`PULSE_TELL` 0.45) and throws you back (`PULSE_CD` 2.6 s).
- **Phase I - "WE WAIT" (lesson of the Northeast):** roots under the floor. A glowing bump with cracks under you
  (`SPIKE_TELL` 0.75), then a giant spike (`SPIKE_H` 175). Volleys of `SPIKE_N` 4, `SPIKE_GAP` 0.62 s, aimed a bit
  ahead of where you run. After a volley the core opens for `OPEN_T` 2.6 s ("The core! It opened - hit the light!").
  **Learns:** after `SPIKE_LEARN` 3 jumps over spikes: "IT LEARNED YOUR JUMP" - every spike gets a second one on
  your landing (+0.38 s) and leads you more.
- **Phase II - "YOUR MACHINES" (Southeast):** two fungus guns grow from its front (`POD_L`, `POD_HP` 120). They spin
  (`POD_SPIN` 0.8, the warning), spray `POD_SHOTS` 11 `EnemyShot`s (`POD_SHOT_V` 720) and then overheat (`POD_HEAT`
  1.7 s, vulnerable, the core opens). Destroy both: "THE MACHINES ARE BROKEN", the core opens for 3.6 s, they regrow
  after `POD_REGROW` 7 s. A spike now and then. **Learns:** hide behind cover for `COVER_T` 1.2 s: "IT LEARNED YOUR
  COVER" - it lobs `SporeLob`s over the cover.
- **Phase III - "WE PLAN" (Southern Cone):** it marks 3 zones on the floor (`ZONE_W` 64, `ZONE_TELL` 1.05, `ZONE_GAP`
  0.28 s apart): where you are, where you are going, and where you ran last time (PlayerMemory), then they erupt
  (`ZONE_H` 210 spike clusters). Every `CALL_T` 17 s: "IT CALLS ITS CHILDREN" and the arena pods burst (up to 3
  HOLLOWs). **Learns:** it remembers which way you escaped the last zones and puts the third zone there: "IT PLANNED
  FOR THAT".
- **Phase IV - "WE ARE YOU" (Patagonia):** its front opens into a giant HOLLOW face (hood, hollow, two slits) that
  fires **your** favourite category, boss-sized, with a tell (`FACE_TELL`): BURSTS = a fan of bursts, SHOTGUN = a
  9-pellet blast with two guide lines, AIM = a long aim line and a hitscan beam (`BEAM_W` 22), BLASTS = 3 spore lobs.
  It swaps to your second category, and mixes in spikes and zones. "IT USES YOUR <CAT> NOW". **Learns:** sustained
  fire on the core (`HIDE_DMG` 150) -> "IT HIDES LIKE YOU": the face closes for `HIDE_T` 1.4 s.
- **Death:** it does not vanish (`corpse_time` huge, physics off, `tick_dead` pins it). The stage kills the zombies
  near the arena (`root_dead`) and 2.6 s later starts the ending. The heart stops beating.
- One draw call for everything (body, spikes, guns, zones, face, beam).

**The ending** (`effects/s63_ending.gd`) - in group `story_scene` (the Monologue stays silent), its own CanvasLayer 8
UI and Camera2D, black bars, typed subtitles (Bangers), voices from `sounds/story/l63_ending/` (text only if a file
is missing). The HUD is hidden, zombies are frozen, the player is not controllable and cannot be hurt.
- **Talk:** the hero walks closer; the ROOT's core glows as it speaks (`root.speak`). Lines `intro` h01-h05 / p01-p02.
- **Choose:** two buttons (menu_button.gd): **DESTROY** (red, "End the hive. Forever.") and **JOIN** (green,
  "Go home. Become one."). Mouse/touch, keyboard (arrows, A/D, 1/2, ENTER/SPACE), gamepad (ui_left /
  ui_right / ui_accept, focus neighbours). Saved as `Game.set_meta("ending_63", ...)`.
- **DESTROY:** p03 / h06 / p04, the hero raises his gun, a tracer and a white flash, the core shatters
  (`root.shattered`), every glow in the world dies (`U.life` -> 0: veins, mouths, spores go grey), grey spores fall,
  a shaft of daylight comes down. Then p05-p07.
- **JOIN:** p08 / h07, the hero walks to the core, his eyes turn green, roots wrap him (`root.embrace`), he is pulled
  in and fades, everything blooms (`U.life` -> 2), spores rise. Then u01-u03 in the "WE" voice.
- **THE END** (size 96), the ending's name ("ENDING: DESTROY - THE HIVE IS SILENT" / "ENDING: JOIN - EVERY MIND IS
  ONE"), "THEY LEARNED YOU.", and a CONTINUE button -> `_complete()`: restores the player camera and HUD, frees its
  UI, calls `main._level_complete()` (results -> map).
- ENTER / SPACE / gamepad accept / tap skip lines (talk and outro). Everything moves in `_process`.

**Tunables** - in each file header.
- Stage: `HALL`, `HALL_BOSS_X`, `ARENA_X0`, `ROOT_X`, `STATUES`, `PODS`, `HALL_PODS`, `ARENA_PODS`, `SHELVES`,
  `MOUTHS`, `ARENA_MOUTHS`, `MOUTH_H`, `VALVES`, `SNARES`, `ARENA_SHELVES`, `HALL_COVER`, `ARENA_COVER`, `WAVE_T`,
  `MAX_PILGRIMS`, `BEAT_T`, `HARDER`.
- HOLLOW: `LEARN_N`, `MODES`, `ROLL_*`, `ON_SHOT_CHANCE`, `MAX_SHOOTERS`, `AIM_*`, `MELEE_*`, `WAKE_R`, `B_*`.
- PILGRIM: `SPEED`, `SURGE`, `SLACK`, `LANE`, `VEER*`, `ROBE_MULT`, `SAC_R`, `PUFF_*`, `HOME_AHEAD`, `LEARN_LOST`, `HP`.
- ROOT: hp (stats), `BODY_MULT`, `CORE_MULT`, `PHASE_AT`, `SPIKE_*`, `POD_*`, `ZONE_*`, `FACE_*`, `RESIST*`,
  `LEARN_HEAL`, `PULSE_*`, `ARENA_PG_T`.
- Ending: `BAR_H`, `SPORES`; text in `story/scenes/l63_ending.gd`.

**After THE END (thanks + rating).** THE END shows "THANKS FOR PLAYING". CONTINUE opens the rating window
(`_ask_rating`): "HOW WOULD YOU RATE THEY LEARN?" with 5 stars (mouse hover/click, touch, 1-5 keys, left/right + ENTER,
gamepad) and a NOT NOW button. A rating shows "THANKS FOR YOUR FEEDBACK!" for 3.2 s, then the results screen. The rating
is saved only on the player's computer in `user://feedback.cfg` ([rating] stars, ending, time, count); nothing is sent
anywhere. `results.gd`: after the last level (`Game.level > IMPLEMENTED`) the NEXT LEVEL button becomes MAIN MENU.


# Polish pass (2026-10-17)

Six areas were reworked together: gun and kill feel, zombie spawn placement, lighting, zombie art, bot playtest bug fixes, and gun/ability progression. Each section below covers one area.

## Gun feel + kill feel (polish pass "gunfeel")

**Weapon balance** (`weapons/weapon_db.gd`). A regular zombie has 30 HP. Body hits do 12-15 x `damage`. Head hits do 30, and `damage` does not multiply them (only `head_mult` for automatics). Targets after this pass:

| Weapon | damage | fire_rate | knockback | Body shots to kill a walker |
|---|---|---|---|---|
| RIFLE | 1.25 (was 1.0) | 0.6 (0.7) | 85 (60) | 2 (was 3) |
| PISTOL | 0.8 (0.5) | 0.3 (0.38) | 55 (40) | 3 (5) |
| SMG | 0.33 (0.25), spread 0.1 (0.13) | 0.11 (0.13) | 30 (22) | 7 (9) |
| ASSAULT RIFLE | 0.55 (0.45) | 0.17 (0.2) | 60 (50) | 4 (5) |
| SNIPER | 1.7 (1.0) | 1.25 (1.5) | 230 (120) | 1, and it pierces 3 (was 2) |
| SHOTGUN | falloff [10, 2, 460] (was [9, 1, 420]) | 0.85 (1.0) | 190 (150) | 1 at close range |
| ASSAULT SHOTGUN | unchanged | unchanged | 200 (170) | 1 at close range |

`knockback` now also sets how far the corpse flies (see below).

**Kill feel** (`zombie.gd`):
- `_die` scales the corpse fling by the killing weapon's knockback: `KILL_FLING` [0.75 .. 1.75] over knockback 0..220.
  Bullet and melee only. Explosions keep their own launch.
- A kill with knockback >= `HEAVY_KB` (150: shotgun, assault shotgun, sniper) sets `heavy_kill`. The ragdoll
  (`effects/ragdoll.gd`) then never takes its 30% "crumple in place" branch, so the body always flies.
- `_kill_feel()`: plays `kill_punch` on a body kill (louder on a heavy kill), or `kill_crack` on a headshot kill.
  Both are synthesized in `weapons/weapon_sounds.gd`. It also asks the camera for a hit-stop:
  `HITSTOP_HEAD` 45 ms, `HITSTOP_HEAVY` 55 ms, `HITSTOP_BOSS` 280 ms. Only for kills on screen.
- Survivor knockback is applied once per trigger pull (`_kb_shot` = `Game.shot_id`). Before, all 6-7 shotgun pellets added
  110+knockback each, so a zombie was thrown ~1800 px/s, out of shotgun range, and the shotgun almost never killed.
- Damage numbers: pellets of the same trigger pull (`Game.shot_id`) merge into one number. It counts up and grows a little
  instead of stacking 6 numbers.

**Hit-stop** (`shake_camera.gd` `hit_stop(sec)`):
- Sets `Engine.time_scale = hitstop_scale` (0.08) for `sec` real seconds, then restores 1.0.
- The player compensates for time_scale (`_rt`), so the hero keeps moving and rapid fire is never slowed. Only the world freezes.
- At most one hit-stop per `hitstop_gap` (0.5 s, was 0.22). A boss always gets one.
- No hit-stop once 2+ zombies died in the last second (`zombie._kill_feel`, `death_load() >= 2`): chained freezes during
  multi-kills made the game feel like it was lagging (user report 2026-10-17).
- `Sfx.prewarm()` loads every sample at startup, so the first kill no longer pays a disk-load hitch.
- Never runs during BULLET TIME, the sniper scope or the weapon wheel (time_scale already < 1). If one of those changes
  time_scale during a hit-stop, it is not overwritten.
- While active, `Engine` has meta `"hitstop"`. `hud.gd` skips the BULLET TIME tint then.
- To turn it off: set the HITSTOP_* consts in zombie.gd to 0.

**Shots** (`player.gd`, `bullet.gd`):
- Muzzle flash `_draw_muzzle()`:
  - a 7-point flame star with a new shape on every shot (`_mf_seed`), a bright forward cone, a white core,
    and a soft light around the hero;
  - size per style (`MUZZLE_SIZE`), lasts `MUZZLE_T` = 0.06 s;
  - rifle and sniper also get side jets (a muzzle brake). The pistol uses the same flash.
- Shotgun and sniper shots leave 2-3 smoke particles at the barrel.
- Shell casings per weapon: shotgun = thick red shell, sniper = long brass, pistol/SMG = small.
- Tracer: every bullet draws a fading streak behind it, about one frame of travel long (`TRACER_K`, 24-80 px).
  Colors: warm; blue for sniper/pierce; orange for incendiary; red for GOD.
  The streak grows from 0 on the first frames, so it never draws back into the hero.
  The bullet node redraws only while the streak grows (first ~2 frames), and is static after that.
- Flesh hit flash `bullet.gd FleshHit` (zombies only):
  - a white-hot dot, 4 short rays and a small red mist on the exit side, 0.09 s;
  - capped at `MAX_ALIVE` (14) at once.

**Movement / responsiveness** (`player.gd`):
- `walk_speed` 190 -> 205, `accel` 1800 -> 2300: snappier starts and stops. Jump height and run speed are unchanged.
- The post-shot movement lock (`_push_t`, accel x0.25 for 0.12 s) now applies only to weapons with recoil >= `PUSH_HEAVY` (0.7).
  SMG / AR / pistol / rifle no longer drag your walk speed while you hold the trigger (true run & gun).
- Auto-reload: firing the last round in the magazine starts the reload at once. It no longer waits for the next trigger pull.
- Muzzle-flash sizes also cover the new progression styles (dbarrel, dbreath, revolver, lever, dmr, hsniper, lmg, minigun, rail).
  Their casings use the matching shell type.

**Dark-level hero rim** (`player.gd` `_is_dark()`, `RIM_COL`):
- On night, subway and `stage.dark_level()` levels, a faint cold halo is drawn behind the hero sprite (two `Art.glow` calls),
  so the black coat no longer disappears into dark backgrounds.
- The check is cached once per level. To change the strength, edit `RIM_COL.a` (0.3).

**Testing** (scripted shooter, kept outside the repo):
- Kills per weapon, level 3, 8 zombies, 11 s:
  - rifle 6 -> 8 kills;
  - pistol 7 -> 8;
  - SMG 8 in 601 frames -> 8 in 520;
  - sniper: the same 8 kills in 2 shots instead of 4.
- All 51 levels ran 600 frames headless with firing (rotating weapons) and no script errors.
- Hit-stop always restored `time_scale` (3-20 hit-stop frames per run).
- CPU time with 45 zombies and SMG fire: 31.4 / 30.8 s before vs 32.1 / 30.0 s after, which is within noise.

## Zombie placement and pace (polish pass, "spawns")

**Regular scatter** (`main.gd` -> `_spawn_zombies`). The level is split into equal **slots** (`SPAWN_FIRST` .. `level_w - SPAWN_END`).
Each group (picked from the stage's `zombie_weights`, group sizes as before: rats pack, dog pair, 2-3 cluster) gets one slot and a
random spot inside it (`SPAWN_JITTER`). Before, x was fully random: up to 3.5 empty screens on levels 1-4 and piles of 6+ in one spot.
* `_group_spot` / `_group_fits`: the whole group must fit on free road: not near a reserved rect (`_near_brick`), not within
  `SPAWN_CP_CLEAR` of the checkpoint, at least `SPAWN_GAP` from other scatter zombies, not on a hazard or a blocked range
  (`_spawn_blocked`). No room in the slot -> `_emptiest_spot` (the free spot farthest from every other zombie).
* `_spawn_blocked(x0, x1)`: hazards near the road (group `hazards`, their `rect`) + `_spawn_avoid` ranges
  (the subway's electrified rails - zombies used to spawn on them and die on frame 1).
* A rats pack counts as 3 zombies toward the level's count (it used to eat 5-7 of the budget and leave long gaps).
* Hurler imps stand one on each side of the hurler (they used to overlap the next group member).
* **Floors**: `SPAWN_FLOOR_SHARE` of single, small built-in zombies (kinds 0-19, not brute/mech/dog/boss) stand on a platform
  (group `platforms`) inside their slot instead of the road (`_spawn_on_floor`). A stage can turn this off:
  `scatter_on_floors() -> false` (stage 9: roofs are the safe route). Types 20+ are placed on floors by the stages themselves.
* `_spawn_group(rng, x, floor_y, kind, n, dormant_ok)` spawns one group; the pace director uses it too.

**After `extra_spawns`**
* `_settle_scatter()`: a scatter zombie standing on top of another zombie (`SPAWN_OVERLAP`) - usually one the stage placed on
  purpose - steps aside to a free spot. Stage-placed zombies never move.
* `_unstick_spawns()` (one physics frame later, when the physics space can be queried): a built-in zombie (kind < 20) whose body
  is inside a solid on the road (a stage obstacle that was not `reserve()`d, a squad placed at a fixed x) moves sideways to free
  floor (up to `UNSTICK_REACH`). Types 20+ are left alone - some hide inside things on purpose (BLEND IN trees, coffins, vents).

**Checkpoint restart**: `CP_RESTART_CLEAR` (440, was 260) - no zombie waiting right in your face when TRY AGAIN starts at the checkpoint.

**PACE DIRECTOR** (`levels/pace_director.gd`, created by `main.gd`): when no zombie is on screen for `IDLE_GAP` s and none is coming
within `COMING` px ahead (and fewer than `MAX_AWAKE` are chasing nearby), a group of 2-3 (stage weights) enters from off-screen
ahead (`AHEAD_MIN..AHEAD_MAX`) already alerted and running at the player. Checks ground with a ray (no pits / water / channels),
a shape query (not inside a wall), `_near_brick` and `_spawn_blocked`. Budget per level = `BUDGET_SHARE` x the scatter count.
Not before `START_X`, not in the last `BOSS_ZONE` px, not during story scenes, not when the player is under the road.
A stage with its own wave system returns `pace_stream() -> false` (stage 16).

**Measuring**: a headless SceneTree script walks the player through a level (teleport, invulnerable, "kills" the nearest visible
zombie every 0.6 s, walks when nothing awake is within 420 px) and prints screen-window counts, biggest gap, overlaps,
zombies inside solids / floating / on hazards / next to start or checkpoint, on-screen time, longest empty stretch and stuck zombies.
(Kept outside the repo: devtools/t_spawn.gd - copy it into a test project, args `levels seeds dyn_seconds`, e.g. `-- 1,2,3 1,2 150`; run with
`--fixed-fps 60`.)

**Numbers** (normal difficulty, levels 1-51 x seeds 1-3 = 153 builds; "screen" = a 1024 px camera window slid along the level in 128 px steps):

| | before | after |
|---|---|---|
| screens with no zombie (all / levels 1-4) | 7.2% / 40.3% | 0.9% / 4.7% |
| screens with <= 1 zombie | 19.4% | 9.5% |
| biggest empty stretch, average (worst) | 1351 px (5037) | 852 px (1801) |
| most zombies in one screen, average | 9.5 | 7.9 |
| overlapping pairs (< 16 px apart) per level | 3.2 | 0.4 |
| built-in zombies spawned inside a solid (153 builds) | 16 | 2 |
| zombies above the road (floors / roofs) per level | 4.8 | 5.5 |

Walk-through bot (19 sampled levels): longest stretch with nothing on screen 5.2 s avg / 14.2 s worst -> 3.4 s / 6.8 s;
first zombie on screen 2.8 s -> 1.9 s (levels 1 and 4 used to take 14 s / 7 s); kills per run 28.4 -> 31.4 (pace director); stuck ~0.1.

## Lighting / readability pass (polish: lighting)

Goal: characters (player + zombies) must always read against the background, no flat/placeholder backgrounds,
no seams or gaps. Contact sheets: `/mnt/project-files/polish/shots/lighting_contact_before.png` / `_after.png`.

### Shared helpers (effects/backdrop_kit.gd)
* `Kit.glow_tex()` - one shared radial GradientTexture2D (built once, static).
* `Kit.soft_glow(ci, c, r, col, squash := 1.0)` - soft halo (one textured quad). Use it instead of stacked
  transparent `draw_circle`s, which show hard rings.
* `Kit.soft_ellipse(ci, c, rx, ry, angle, col)` - rotated soft blob (nebula, mist, clouds).
* `Kit.soft_smoke(...)` - smoke column made of soft blobs. `Kit.smoke_column` and `Kit.fire_glow` now draw soft
  blobs too (all levels that use them changed look: no more "bubble" smoke / ringed fire glows).
* `Kit.haze_band(ci, vp, y0, y1, col)` - vertical haze gradient (transparent at y0 -> col at y1). Put it in a
  backdrop `overlay` just above the road (about y 420-612 on screen) to lift the background behind the
  characters: dark silhouettes read again without brightening the whole level.
* `Kit.gradient_sky` bands now overlap (height used `steps` instead of `steps - 1` -> 1-2 px gaps could appear).
* `art.gd -> Art.glow()`: radius >= 24 px now draws the soft texture (3 circles = visible rings on big glows);
  small glows keep the old 3-circle look.

### Rules of thumb for new levels
* Keep the band behind the characters (screen y ~430-607) mid-tone, not near-black and not white. If the art there
  is dark, add `bg.overlay = func(ci, v, t): Kit.haze_band(ci, v, 420.0, 612.0, Color(..., 0.2-0.26))`.
* Darkness overlays (subway.gd, s11 NightOverlay, s14 StormOverlay, s26 BunkerDark, s29 MineDark): the soft light
  around the player is 130 px (`subway.gd -> PLAYER_GLOW`), so zombies that come close are visible even in black areas.
* Sky gradients drawn by hand: band height = span / (steps - 1) + 1, and use 24-36 steps (12 shows posterized stripes).
* Screen-space fog/whiteout events: keep a full-screen white fill under ~0.15-0.2 alpha (stage 28 cloud was 0.28).

### Old levels rebuilt
* **Level 3 (factory)** - `factory.gd -> FactoryBg` is now a `parallax_backdrop.gd` subclass: smoggy sunset sky
  (soft sun, drifting smog bands, birds), far = cooling towers with steam + striped chimneys with red blinking lights +
  gas flare, mid = refinery (tanks, gas spheres, distillation columns with lights, pipe rack, foundry with flickering
  furnace windows, conveyor tower), near = big pipe with a steam-spitting valve, gantry crane with swinging load,
  sodium lamp with light cone; overlay = warm haze behind the characters + rising embers. Tunables: consts at the top
  of `FactoryBg` (HZ, FAR/MID/NEAR colors, LAMP).
* **Level 2 (subway)** - `subway.gd -> TunnelBg` rebuilt the same way: tiled station wall with mosaic band, station
  name signs (`NAMES`), torn posters, graffiti, damp stains; steel pillars with rivets and hazard stripes and sagging
  cables; hanging fluorescent fixtures (some dead, some flickering) with light pools; overlay = pale haze behind the
  characters + shadow under the ceiling. `darkness` 0.62 -> 0.52, player glow 70 -> 130 px.
* **Level 1/4 (street, background.gd)** - sun halo and smoke clouds are soft (no rings). Level 4 night world tint
  (main.gd CanvasModulate) 0.5/0.56/0.75 -> 0.64/0.68/0.86 so the player and zombies are not swallowed by the dark city.

### Per-level tweaks
* 7: world_tint 0.82/0.78/0.72 -> 0.92/0.88/0.82.
* 14: StormOverlay darkness 0.52 -> 0.45, player glow 130.  11/26/29: player glow 130; 29 MineDark 0.55 -> 0.48.
* 18: sky had dark seams every 52 px (band gap) + the sky showed between the terraces and the road -> fixed
  (quarry floor fill), 36-step sky, soft sun halo.  19: 36-step sky (was 12 visible stripes), soft sun halo.
* 25 / 36: haze band overlay behind the characters; 36 slope color lightened (2c2630 -> 3a3242).
* 28: valley-mist band is a gradient (was a rect with a hard top line); the passing cloud is 0.15 (was 0.28) with soft blobs.
* 34: Milky Way drawn with soft ellipses (hard-edged ellipses before).
* 22: sky = smooth gradient (was 5 hard bands), soft low clouds, soft spray at the dam foot, damp streaks on the dam.
* 44: dam wall got concrete pour lines, water streaks, shadow under the crest and moss at the foot (was flat grey).
* 47: haze band overlay behind the characters (dark storm grass).

### Performance
`draw_circle` is the expensive primitive in backdrops (tessellated every redraw). The new backdrops use rects and the
shared glow texture instead: measured on a heavily loaded machine, subway backdrop ~0.6 ms/frame, factory ~1.5 ms/frame
(all layers). Kit.smoke_column / fire_glow / Art.glow (r >= 24) are now one textured quad per blob, cheaper than before.

### Testing
`t_light.gd` (devtools/t_light.gd): renders start + middle of each level with the
player invulnerable and the 3 nearest zombies pulled next to him; one Godot process does a list of levels.

## Zombie art polish (zombieart)

How zombies look; behaviour, hit boxes and silhouettes are unchanged.

### Per-instance variation (kinds 0-19)
* `zombie.gd -> _vary(rng)` runs once in `_ready()` for the built-in kinds (`type_mod == null`), using the same
  per-instance RNG as `_det` (seeded by the instance id), so the look is stable for a zombie's lifetime.
* Skin: lerped 0..40% toward one of `SKIN_MIX` (grey-blue, jaundiced, pale, green, bruised). Animals (RAT/DOG/HOUND)
  only get a light/dark fur tint.
* WALKER and HURLER pick a shirt from `SHIRTS` and pants from `PANTS_MIX`. Kinds in `VARY_SHIRT` keep their base colour
  with a small hue/saturation shift. COP, CONDUCTOR, DRUNK, etc. keep their uniform colours (only the pants lightness varies).
* `hair` (from `HAIRS`), `_bald` (22%) and `_gore_arm` (35%) are new per-instance fields. Registry types keep the old
  defaults (`hair` = 3a3026, not bald, no gore arm), so `z._head()` / `z._arm()` look the same for them.

### Drawing changes in zombie.gd
* `_head`: the back-hair oval and RUNNER's long hair use `hair`. For kinds < 20 (not BRUTE/BOSS/COP/CONDUCTOR) a hair cap
  is drawn on top of the skull with no outline, because an outlined cap read as a dark hood at game zoom. Bald zombies get a
  sore on the scalp instead.
* `_head_rest`: a dim glint in the second (sunken) eye so faces read with two eyes; for kinds < 20, `_det[0]` adds blood drool.
* `_arm(..., gore := false)`: torn flesh and exposed bone on the forearm. Only the front arm of kinds 0-19 with `_gore_arm` passes
  true. It is skipped when `crowded()` is true.
* `_torso_walker`: an open collar plus two buttons.
* `_draw_rat`: pink tail, nose and ear, a highlight on the back, a raw sore and a red eye. The colours are `RAT_*` consts. The draw
  cost matches the old rat (A/B median about +2%).
* `_draw_hand`: a torn wet sleeve (one polygon), an exposed bone and a shaded palm. The colours are `HAND_*` consts.

### Registry types
* `enemies/zombie_type.gd -> face(head, eye := Vector2(3.5, -0.5))` is a new shared helper for the plain "oval head + one eye dot"
  types. It draws a sunken socket, an open jaw with teeth (opens more while biting), cheek rot from `z._det[5]` and a soft glow
  around the eye (`eye.x = INF` = no glow). Call it right after the head oval and before the hat and eye. These types use it:
  sapper, sniper, handler, blackout, echo, dynamiter, signaler, boulder, spotter, panel, axeman, quipu, avalancher, guardian,
  cinder, bellringer, frostbite, office, washer, striker, referee, capoeira, kite, courier, netter, boleador, tango,
  harvester and stormcaller.
* `enemies/empire_kit.gd -> soldier()` is shared by 19 empire types. It adds a darker collar, light on the shoulders, pocket flaps,
  a per-instance blood stain with a bullet hole (`_det[0]`), a zombie face (socket, jaw, teeth, cheek rot) and a red eye glow.
  `helmet()` is now shaded and outlined, with a chin strap and a highlight.
* `spare_parts.gd`: a stitched-on skin patch, an X-stitched eye, a glowing eye, a jaw with teeth, an ear, and a stained gown with a
  stitched belly wound.
* `goliath.gd`: apron pocket, blood smears, ribs, veins, a sunken eye socket and an eye glow.

### Testing tools (outside the repo)
* Zoo: `devtools/t_zoo.gd` (`zoo.sh outdir kinds zoom`) spawns every kind 0-19 and every registry kind
  (boss variants via `chase_range = 650`). Each kind is frozen in walk and attack poses on a neutral and a dark band.
  Use `REPEAT=n` for a crowd of one kind.
* Draw cost: `AB=1 [ABSWAP=1] REPEAT=4 prof.sh <proj> "kinds"` (headless) spawns half the zombies with the old `zombie_b0.gd`
  in the same process and prints the before/after µs per draw from the `zombie.gd` prof hooks. Swap the bands with ABSWAP
  and take the median: the machine is noisy.
* Zoomed renders exaggerate outlines because the 2D AA feather is in canvas units. Judge the art at zoom 1.25 (game) and 2.5.

## Playtest bot + bug fixes (polish pass, "playtest")

### Autoplay bot (test tool, kept OUTSIDE the repo)
`devtools/t_bot.gd` (a SceneTree script, like the other `t_*.gd` tools). It plays one level the way a
player would and prints one `BOT ...` summary line plus details:
```
godot --headless --fixed-fps 60 --path . -s res://t_bot.gd -- <level> <god 1/0> <max_sec> [start_x] [stuck_shot.png]
BOT_SEED=1234 godot ...      # level layout seed (default 1000 + level*7, so runs are repeatable)
```
* Input is real: physical key events (`Input.parse_input_event`) for A/D (double-tap = run), W (jump / double jump /
  ladder), S (double tap = drop through a floor). Aiming/firing uses `player._aim` + `player._fire_test` (head height of
  the nearest zombie with line of sight, layer 1). Reloads when idle, switches to a slot with ammo, throws specials
  (grenade / molotov / launcher / rocket / laser) at crowds of 3+ or at the boss.
* god = 1: `_invuln` every frame (+ ammo refill when everything is empty, counted as `refills`). god = 0: health is held at
  100000 and every real hit is counted -> `deaths` = damage / max HP (infinite-lives difficulty measure).
* Escapes: jumps on walls / gaps / stalls, double jump at the apex, climbs a ladder when stuck, drops through floors,
  backs off and run-jumps; after 25 s at the same x it teleports 260 px forward and logs `TELEPORT` (= a real stuck spot).
  With the pass barrier up and nothing visible it walks back to the zombies the wall waits for; at a locked exit with
  nothing to shoot it walks to the boss; if the boss takes no damage for 8 s it backs off and jumps over its charge.
* Logged: result (FINISHED / TIMEOUT), time, boss name / time killed / HP left, stuck episodes (x, y, what body blocks at
  knee and head height), barrier episodes + who the wall waits for after 15 s, story scene time (forced finish after
  90 s = hang), zombies falling out of the world / inside a solid body for 3 s / floating 4 s, pickups inside solids or
  under the floor, frames over 25 ms, "PASSED LOCKED GATE". SCRIPT ERROR / ERROR lines come from the Godot log itself.
* Frame times are wall clock: only meaningful on an idle machine.

### Bugs found and fixed
* `exit.gd`: the locked gate's invisible wall was 400 px tall - a double jump from a boss's head / a machine went over it,
  and the player was then stuck between the locked gate and the level end (level 7). Now 1600 px.
* `environment/pass_barrier.gd` ("THEY'RE BEHIND YOU"): the wall waited the full 40 s (up to 160 s per level) for
  zombies that can never come: underground / underwater ones (collision layer without 4: GRAVEBORN, DROWNED), leashed
  ones (types with a `LEASH` const: LIVEWIRE), and wanderers that walk away from the player more than `LOST_RANGE`
  (800 px). They are no longer locked / are dropped from the list.
* `enemies/types/driller.gd`: THE EXCAVATOR (level 18 boss) only drove toward a player closer than 900 px. Once the player
  ran past it to the gate it sat off screen forever (locked gate, no boss in view). A boss that has met the player
  (`_met`) now keeps coming from any distance.
* `levels/stage_9.gd`: the tunnel ladders stood in the middle of the 96 px road holes. At the top of the climb there is no
  floor under the player, so he fell back into the tunnel (bot stuck 25 s, real players must know to jump off sideways).
  Ladders now stand at the hole edge (`LADDER_EDGE`), so the feet land on the road.
* `enemies/types/ambusher.gd` (cape) and `zombie.gd _torso_runner` (vest): self-intersecting polygons ->
  "Invalid polygon data, triangulation failed" (8-69 errors per level in levels 5-7, 15, 20, 25, 27, 32, 37, 48) and the
  shape was simply not drawn that frame (cape / vest flicker). Cape point moved onto the back line; the runner vest drops
  its neck notch when the torso leans far forward and the polygon would cross itself.

### Known, not fixed (see the final report for the full list)
* Test toggles still on: `Arsenal.TEST_MIND_EVERY_LEVEL = true` (a MIND CONTROL pickup at the start of every level) and
  `TEST_LASER_LEVEL = 3`.
* CONDUCTOR (level 2 boss) can only be hurt in the back; a player who stays in front never damages it (by design, but there
  is no hint besides "NO EFFECT").
* Level 23 (HIGHWAY 7): the player can get pinned against a moving car (AnimatableBody2D): on the road, not on floor,
  velocity.y growing to 15000+, cannot move for 25 s (bot teleported). Not fixed.
* Bot limitation: it walks to a ladder's x with a 6 px tolerance; a ladder against a wall (stage 9 tunnel exit) can leave it
  pressing into the wall instead of climbing (a human just presses W). Bump the tolerance in `t_bot.gd` before trusting
  long stuck times near ladders.

### Results
Before/after table of the 51-level god-mode sweep: `devtools/playtest_results_2026-10-17.md`.

## Weapon + ability progression (polish pass "progression")

The player now gets something new at almost every stage of the 51-level campaign: a new gun, a new
ability, or a free WEAPON MOD. One table drives everything: `"unlock_level"` in `weapons/weapon_db.gd`
(guns) and in `abilities/ability_db.gd` (abilities). `progression/arsenal.gd -> rewards(lv)` reads both and
adds a WEAPON MOD to every stage from `MOD_FROM` (11) that has no gun / ability of its own.

### Unlock table (W = weapon, A = ability, M = WEAPON MOD)

| Stage | Reward | | Stage | Reward |
|---|---|---|---|---|
| 1 | W RIFLE (start kit) + A FLASHLIGHT | | 27 | W LMG (region 3 finale) |
| 2 | W SHOTGUN | | 28 | A SENTRY GUN (Andes start) |
| 3 | A SHOCK BLAST | | 29 | M |
| 4 | W PISTOL | | 30 | W DRAGON'S BREATH |
| 5 | A FLARE | | 31-32 | M |
| 6 | A JETPACK (Highrise) | | 33 | A ADRENALINE SHOT |
| 7 | W SMG | | 34-35 | M |
| 8 | A LAST BREATH | | 36 | W ANTI-MATERIEL (Andes finale) |
| 9 | W SNIPER (region 1 finale) | | 37 | W MARKSMAN RIFLE (Southeast start) |
| 10 | W REVOLVER (Northeast start) | | 38-39 | M |
| 11 | A INCENDIARY ROUNDS | | 40 | A MORTAR STRIKE (Harbor of War) |
| 12 | W ASSAULT RIFLE | | 41-44 | M |
| 13 | M | | 45 | W MINIGUN (Empire finale) |
| 14 | W TASER | | 46 | A CHAIN LIGHTNING (Southern Cone start) |
| 15 | A MOTION SCANNER | | 47-49 | M |
| 16 | W DOUBLE BARREL (The Flood) | | 50 | W RAILGUN |
| 17 | M | | 51 | M |
| 18 | W LEVER-ACTION (region 2 finale) | | 52-63 | M (planned levels) |
| 19 | W ASSAULT SHOTGUN (Plateau start) | | | |
| 20 | A SMOKE BOMB | | | |
| 21, 23, 26 | M | | | |
| 22 | W CROSSBOW | | | |
| 24 | W FLAMETHROWER (Burning Fields) | | | |
| 25 | A FOCUS | | | |

To change it: edit the `unlock_level` numbers. Nothing else needs to change (banner, gifts, shop order,
practice loadout and mods all follow).

### How a reward reaches the player
* **New gun**: `main.gd -> _spawn_supplies` places it at the start of its stage (`Arsenal.offers().new`) as a
  pickup with `gift = true` (`pickup.gd`: light beam + floating "NEW"). If all 5 slots are full, picking it up
  swaps out the oldest gun (lowest unlock_level); that gun is dropped on the floor so it can be taken back
  (`player.gd -> _take_weapon`). Older unlocked guns you don't own still come back in the mid-level weapon cache.
* **New ability**: `abilities/ability_runner.gd -> _fill_slots` equips it in a free slot or replaces the oldest
  ability that is not gear (`"keep": true` = FLASHLIGHT, JETPACK, LAST BREATH never get pushed out), and selects
  it so C uses it right away. Replaced abilities stay in the reserve (Q wheel -> ABILITIES, or the shop).
* **WEAPON MOD** (`pickup.gd MOD`, blue tool box): `Arsenal.apply_mod` gives +1 level on the lowest upgrade track
  of the gun in your hands (or another of your guns; all maxed = `MOD_SCRAP` scrap). Claimed once per stage:
  `Game.upgrades["m.<stage>"]` (saved with the upgrades), so TRY AGAIN / CONTINUE never give it twice. Not in PRACTICE.
* **Banner** (`ui/unlock_banner.gd`, group "unlock_banner"): after the stage title (5 s) one card per reward -
  icon, NEW WEAPON / NEW ABILITY / WEAPON MOD, name, what to do. Picking up a gift or mod shows an instant card
  (`picked_weapon`, `picked_mod`). Waits during story scenes. Ability cards only the first time a stage is played.
* **CONTINUE / checkpoints / TRY AGAIN**: gifts are offered from the level-start loadout (`Game.weapon_slots`), so a
  retry offers the gun again; starting at a checkpoint moves the gifts you did not take to just ahead of the
  checkpoint (`main.gd -> _start_at_checkpoint`). PRACTICE uses `Arsenal.loadout_for(lv)` (the 4 newest guns of
  that stage + rifle), so the stage's own gun is already in hand.

### New guns (weapons/weapon_db.gd ids 12-22; art in `weapons/gun_art.gd`)
REVOLVER (heavy 6-shot, pierces 1), DOUBLE BARREL (2 shells, 8 pellets, 0.22 s between barrels), LEVER-ACTION
(pierces 2), CROSSBOW (bolt, flat arc via `"gravity"`, pierces 3, bolts can be picked up again), FLAMETHROWER
(`"projectile": "flame"` -> `bullet.gd` flame puffs that grow, slow down and ignite; no reload), LMG (80 box mag),
DRAGON'S BREATH (`"incendiary": true` shotgun), ANTI-MATERIEL (.50, RMB scope via `"scope": true`, pierces 8),
MARKSMAN RIFLE (fast semi-auto precision), MINIGUN (70-round belt, 140 per pickup, spinning barrels), RAILGUN (pierces 20, scope).
New weapon fields: `pitch` (shot sound pitch), `incendiary`, `gravity`, `scope`, `flame`.
`gun_art.gd`: `draw_held()` (called from `player._draw_rifle` when the style is in `STYLES`) and `draw_icon()`
(called first in `weapon_wheel.draw_weapon`). New sound: `"flamer"` in `weapons/weapon_sounds.gd`.

### Abilities (abilities/ability_db.gd + abilities/types/<id>.gd)
| id | Name | What it does |
|---|---|---|
| flashlight | FLASHLIGHT | unchanged |
| dark_pulse | SHOCK BLAST | was DARK PULSE: same knockback/stun/grab break, now electric (blue rings + bolts to each zombie) |
| flare | FLARE | replaces DECOY ECHO: thrown road flare in group "decoys" (zombies chase it, `zombie._target_for_brain`), ignites zombies that reach it, lights dark levels ("dyn_lights") |
| jetpack | JETPACK | unchanged, unlock moved 2 -> 6 |
| last_breath | LAST BREATH | unchanged |
| fire_rounds | INCENDIARY ROUNDS | replaces BLOOD HOOK: 7 s INCENDIARY boost |
| hunters_sight | MOTION SCANNER | was HUNTER'S SIGHT: same see-through-walls overlay, green scan ring + beep |
| smoke | SMOKE BOMB | replaces PHANTOM STEP: cloud; zombies inside stagger and lose you (`brain.sees/last_seen`); while you stand in it nobody within 900 px sees you |
| focus | FOCUS | replaces SILENCE: BULLET TIME boost (world 0.35x, player full speed) + magazine refill, blue screen tint |
| sentry | SENTRY GUN | auto-turret 12 s, shoots the nearest zombie in line of sight (`bullet.gd` bullets) |
| adrenaline | ADRENALINE SHOT | +1 heart + ADRENALINE boost 6 s |
| mortar | MORTAR STRIKE | marks the aim point, 4-6 shells land (`rocket.gd -> mini_boom`) |
| chain_shock | CHAIN LIGHTNING | bolt to the zombie you aim at, jumps to 5+ more |

Each has an icon (`draw_icon`), sound, cooldown, POWER/COOLDOWN shop tracks and `power_desc`.
**Old saves**: `AbilityDB.MIGRATE` maps decoy->flare, phantom_step->smoke, silence->focus, blood_hook->fire_rounds;
`game_state.gd` runs `migrate_slots` / `migrate_upgrades` on load (bought levels move to the new ability).
Weapon ids did not change (new guns are appended), so old weapon slots load as before.

### Shop
WEAPONS tab is sorted by unlock stage; locked guns show "ARRIVES AT STAGE N" (not reached yet) or
"FIND IT FIRST (STAGE N, OR A WEAPON CACHE)". Abilities stay "???" until their stage. Only unlocked items can be bought.

### Also changed
`progression/arsenal.gd`: test flags `TEST_MIND_EVERY_LEVEL` (MIND CONTROL at every stage start) and
`TEST_LASER_LEVEL` (laser cannon at stage 3) were left on - turned off; both still come from normal special finds.

## Level bug fixes (polish pass round 2, "levels")

### Player can no longer get pinned (HIGHWAY 7 and everywhere)
* **Why it happened.** When the player's box overlaps a solid body by even 2-3 px, Godot's `move_and_slide` does not push him out. Every slide hits the same body, so `is_on_floor()` stays false, gravity keeps adding up (`velocity.y` reached 15000+), and he can't move. Three things caused the overlap:
  1. The Stage 23 car (`effects/s23_decor.gd` `Car`, an `AnimatableBody2D` moved by `position.x += step`) drove into the player.
  2. The bottom corner of the car's collision box sat exactly at road level. Walking into a parked car could snag on that corner.
  3. A sliding car shoved the player into a gap narrower than his body, between two obstacles.
* **Car fixes** (`s23_decor.gd`):
  * `LIFT` (8 px): the car's collision box now ends 8 px above the road, so it has no corner at foot height. It still looks like it touches the ground, and nothing fits under it.
  * `_carry()`: a car sliding at a player who is beside it (not on the roof) pushes him ahead with `move_and_collide`. If he is already against a wall, the car stops instead of crushing him.
  * `_unpin()`: runs after each slide step and when the car stops. If the player is still inside `solid_rect()`, it moves him out to the nearer free side, or onto the roof if that side is blocked.
* **Generic safety net** (`player.gd` `_pin_check`): if the player is in the air with `velocity.y > 600` and his y has not changed for `PIN_T` (0.3 s), he is moved to the nearest free spot. It tries offsets up, sideways and diagonally, from 4 px out to 90 px, using a shape query with the player's box and his collision mask minus one-way floors. His velocity is then set to zero. The check is skipped while he is grabbed, draining, climbing or hooked, and it costs nothing when he is not stuck.
* **Test:** `t_car.gd` (outside the repo) runs 70 scripted and random car-meets-player scenarios: pushed from the side, on the roof, falling onto either corner, walking or jumping into the car, crouching, overlapping at the start. A run counts as pinned when max `velocity.y` goes above 1000 and the player never gets back on the floor.
  * Before (HEAD): 14 of 70 pinned.
  * After: 0 of 70.
  * Bot on level 23 (four seeds): no teleports and no pinned episodes.

### Pass barrier waits ("THEY'RE BEHIND YOU", `environment/pass_barrier.gd`)
* **Why players waited.**
  * Locked zombies had brain roles like HOLD, FLANK, COVER or WAIT, so they hung back off screen or behind cover instead of coming.
  * The wall waited for the very last straggler.
  * The safety timeout was 40 s.
* **Changes:**
  * Every `PUSH_EVERY` (2 s) the locked zombies get `hear_noise(player)` and a forced `brain.command(ATTACK)`, so they come and fight.
  * `_not_stale`: a locked zombie that is not "in the fight" (closer than `NEAR` = 420 px and in line of sight) and is not getting closer is dropped after `STALE` (4 s).
  * The wall opens when `LEFT_OK` (1) zombie is left, or when `LEFT_LATE` (2) are left after `LATE_T` (7 s).
  * `TIMEOUT` is now 12 s (was 40).
* **Bot results** (god mode; total barrier time per level, before -> after with the final tuning):

  | Level / seed | Before | After |
  |---|---|---|
  | 39 / 1273 | 86 s, longest 41 s | 39 s, longest 8 s |
  | 39 / 5 | 84 s | 26 s |
  | 41 / 5 | 59 s, longest 40 s | 24 s |
  | 43 / 1301 | 62 s | 44 s, longest 9 s |
  | 43 / 5 | 70 s, longest 41 s | 12 s |
  | 50 / 1350 | 26 s | 24 s, longest 8 s |

  Every episode now lasts 9.4 s or less (before: up to 41 s).
  Finish times: level 39 went from 135 s / 127 s to 85 s / 73 s, and level 43 from 100 s / 111 s to 85 s / 56 s.

### Pickups / zombies inside solids (`main.gd` `_unstick_spawns`)
* **Pickups.** `pickup.gd` lands by casting a ray down from its spawn point. If that point is inside an obstacle that was never `reserve()`d (stage `brick.gd` blocks, `prop.gd` barrels or cars), the ray never hits it. The pickup then rests on the road inside the obstacle, where you can't see or collect it.
  * Fix: one physics frame after the build, each pickup whose spawn point, or the spot where it will land on the road, is inside a solid moves sideways to free road. It checks steps of 26 px out to 390 px and avoids pits.
* **Zombies of types 20+** used to be skipped by `_unstick_spawns`, because some hide inside things on purpose. They are now moved too when the body they are inside is a `prop.gd` or `brick.gd` obstacle; nothing hides in those on purpose. Example: stage 14 places CRUMBLERs lying down at fixed x in the halls, and some ended up inside concrete blocks.
* **Test:** `t_place.gd` (outside the repo) builds levels x seeds and counts pickups and zombies inside solids. Levels 8/14/16/49 x 5 seeds: pickups inside 8 -> 0, zombies inside 5 -> 0.
  All 51 levels x 3 seeds: pickups inside 8 -> 0, zombies inside 22 -> 16. The 16 left are on purpose: ceiling crawlers, the WALL CRAWLER on furniture, HANGED in trees, GHILLIE and SCARECROW, plus 2 level 42 CONSCRIPTs in StaticBody2D trenches, which are probably meant to be dug in.

### CONDUCTOR hint (`zombie.gd`, level 2 boss)
* A front hit still shows "NO EFFECT". On the 1st, 6th, 11th, 16th and 21st front hit it also shows a bigger yellow "SHOOT HIS BACK!". On the first one the hero also says "His front is armored... get behind him!".
* The transformer on his back now has a second, larger pulsing blue glow, so you can see where to shoot.
* "NO EFFECT" now pops up at most once every 0.3 s (`ne_t` meta). With an automatic gun the popups used to stack into an unreadable pile.

### "Invalid polygon data, triangulation failed" (level 6)
* Cause: `effects/s6_building.gd`, the moonlight cone under a hole in the ceiling. The top edge was drawn from `g0 + 6` to `g1 - 6`. When a hole is narrower than 12 px, those two points swap sides and the quad crosses itself. This happened in about 1 of 4 random level 6 layouts, and the cone was then not drawn.
* Fix: the top of the cone is now centred on the hole with a half-width of at least 2 px.
* How it was found: a test copy where every `draw_colored_polygon` / `draw_polygon` call was rewritten by regex to go through a checker. The checker runs `Geometry2D.triangulate_polygon` and prints the CanvasItem and the points when it fails. `get_stack()` is empty without a debugger, so the node and points are what identify the culprit. Level 6 start, 12 runs: 2 of 8 failed before, 0 of 12 after.

## Weapons round 2 (polish pass "weapons")

Builds on "Gun feel + kill feel" and "Weapon + ability progression". Covers the balance of the 11 progression guns,
the MINIGUN spin-up, heavy shot sounds, per-gun muzzle flashes, ragdoll hair and early-level ammo.

### Balance rules (how damage works, see `zombie.gd -> take_damage`)
* Regular zombie = 30 HP. Body hit = 12-15 x `damage`, leg = 7-10 x `damage`, head = 30 (sniper weapons 60).
* `falloff` / `fixed_damage` replace the zone damage (shotguns, crossbow, flamethrower), per pellet.
* **New:** a weapon with `damage` > `HEAD_HEAVY` (1.6) also multiplies the head: head x damage x `HEAD_HEAVY_K` (0.6),
  not on bosses. Before, ANTI-MATERIEL / RAILGUN did *less* on a headshot (60) than on a body shot (71 / 81).
  Now REVOLVER 36, LEVER-ACTION 43, MARKSMAN 31, SNIPER 61, ANTI-MATERIEL 126, RAILGUN 162 (x2 on a PERFECT hit).
* Fire rate is quantized to physics frames (`_cooldown = fire_rate`): 0.085 really fires every 0.1 s. The table uses
  the real rate. The MINIGUN keeps the remainder instead (`_cooldown = max(_cooldown, -1 frame) + rate`), so 0.045 = 22/s.

### Final table (base stats, no shop upgrades)
"Brute" = a 60 HP heavy (late-game heavies are 50-60 HP; the BRUTE kind itself has 30). Shots = body shots, all pellets
hitting (shotguns at point blank). DPS = raw; sustained = including reload.

| Stage | Gun | Role | Body dmg | Head | Pierce | Shots walker / brute | DPS / sustained | Ammo start/box/max |
|---|---|---|---|---|---|---|---|---|
| 1 | RIFLE | starter | 17 | 30 | 0 | 2 / 4 | 28 / 26 | 30/10/60 |
| 2 | SHOTGUN | close | 6x10 | - | 0 | 1 / 1 | 71 / 57 | 8/3/16 |
| 4 | PISTOL | fast precision | 11 | 30 | 0 | 3 / 6 | 37 / 32 | 36/12/96 |
| 7 | SMG | spray | 4 | 12 | 0 | 8 / 15 | 34 / 28 | 90/24/150 |
| 9 | SNIPER | one-shot, pierce | 34 | 61 | 3 | 1 / 2 | 27 / 23 | 5/2/10 |
| **10** | **REVOLVER** | heavy hand cannon | 27 (was 22) | 36 | 1 | 2 (25% 1) / 3 | 68 / 44 (was 52 / 35) | 24/8/48 |
| 12 | ASSAULT RIFLE | auto | 7 | 15 | 0 | 5 / 9 | 38 / 33 | 60/24/120 |
| **16** | **DOUBLE BARREL** | 2-shell burst | 8x13 | - | 0 | 1 / 1 | 446 / 133 | 12/4/28 (unchanged) |
| **18** | **LEVER-ACTION** | one-shot line rifle | 32 (was 26) | 43 | 2 | 1 (75%) / 2 | 64 / 46 (was 52 / 37) | 21/7/42 |
| 19 | ASSAULT SHOTGUN | auto close | 7x11 | - | 0 | 1 / 1 | 231 / 155 | 16/6/40 |
| **22** | **CROSSBOW** | silent, always one-shot, pierce, bolts come back | 38-46 (was 30-38) | same | 4 (3) | 1 / 2 | 60 (was 40) | 14/5/28 (12/4/24) |
| **24** | **FLAMETHROWER** | crowd at close range + burn | 2x4 + burn 7/s | - | 2 | ~4 puffs | 120 + burn | 200/70/360 (160/50/320) |

FLAMETHROWER reach: `bullet_speed` 720 -> 900 and `range` 340 -> 480. The puffs slow down (x(1 - 1.6 dt)), so the real
reach was only ~270 px (bot at stage 24: 9 kills in 100 s). Now ~350 px (34 kills).
| **27** | **LMG** | 80-round suppression | 7-8 (was 7) | 15 | 1 | 5 / 9 | 70 / 53 | 160/40/320 |
| **30** | **DRAGON'S BREATH** | pump shotgun, sets the crowd on fire | 8x13 (was 7x11) | - | 0 | 1 / 1 | 189 / 142 (was 96 / 77) | 14/5/30 (12/4/24) |
| **36** | **ANTI-MATERIEL** | kills a whole line (pierce 8) | 71 | 126 (60) | 8 | 1 / 1 | 51 / 41 (was 42 / 34) | 10/4/20 (8/3/16) |
| **37** | **MARKSMAN RIFLE** | fast precision | 23 (was 18) | 31 | 1 | 2 / 3 (was 4) | 92 / 69 (was 67 / 51) | 36/12/72 |
| **45** | **MINIGUN** | spin up, then 22 rounds/s | 7-8 (was 6) | 15 | 1 (0) | 5 / 9 | 156 / 117 (was 120 / 91) | 400/100/800 (300/80/600) |
| **50** | **RAILGUN** | crosses the screen (pierce 20) | 91 (was 81) | 162 (60) | 20 | 1 / 1 | 101 / 67 (was 81 / 51) | 12/4/24 (9/3/18) |

Other changes in `weapons/weapon_db.gd`:
* REVOLVER fire_rate 0.42 -> 0.4, knockback 140 -> 150 (= `HEAVY_KB`: kills always fling the body).
* LEVER-ACTION knockback 150 -> 170. CROSSBOW fire_rate 0.85 -> 0.7, knockback 90 -> 110.
* DRAGON'S BREATH: falloff [11, 2.5, 470] -> [13, 3, 520], pellets 7 -> 8, fire_rate 0.8 -> 0.55, reload 1.2 -> 1.1, range 1000.
  It was weaker than the ASSAULT SHOTGUN it comes 11 stages after.
* ANTI-MATERIEL fire_rate 1.7 -> 1.4, magazine 4 -> 5. MARKSMAN fire_rate 0.27 -> 0.24.
* MINIGUN damage 0.42 -> 0.55, fire_rate 0.05 -> 0.045, pierce 1, reload 3.2 -> 3.0, `spin_up` 0.4.
  **2026-10-17 (user: "600 bullets is god mode")**: fire_rate 0.065 (~15/s), magazine 70, 140 bullets per pickup and max 140
  (capacity upgrades still add +20%/level), ammo box 35. Practice loadouts (`arsenal.loadout_for`) never exceed ammo_max.
* RAILGUN damage 4.0 -> 4.5, fire_rate 1.0 -> 0.9, magazine 3 -> 4.
* LMG damage 0.5 -> 0.55, knockback 55 -> 65.
* Why none trivializes the game: ammo stays the limit (heavy guns have 10-24 rounds per pickup), bosses are excluded from
  the head bonus, and the strongest DPS guns (DOUBLE BARREL, DRAGON'S BREATH, FLAMETHROWER) only work at close range.

### MINIGUN spin-up (`player.gd -> _spin_update`)
* `_spin` 0..1. Holding fire spins up in `spin_up` (0.4 s); releasing spins down in `SPIN_DOWN` (0.7 s).
* It fires at once: the rate starts at `SPIN_START` (35%) of full and ramps to 100% (`cd / lerp(SPIN_START, 1, _spin)`).
  So a tap still shoots, and holding feels like a ramp, not a delay.
* Walk speed x `SPIN_MOVE` (0.8) while it is spinning and firing (not after release).
* Sounds (`weapons/weapon_sounds.gd`): `minigun_spin` (rising whine on spin start), `minigun_hum` (repeats every 0.26 s at
  full speed), `minigun_wind` (falling whine on release after firing).
* Art (`gun_art.gd`, "minigun"): 6 barrels drawn back-to-front around `player._spin_ang` (light ones in front), motion blur
  above 55% speed, clamp rings, motor with cooling ribs, ammo box with a belt, barrels glow orange after a long burst.
  `draw_held()` takes 2 new optional arguments: `spin` (angle, -1 = use time) and `spin_k` (0..1).

### Heavy shot sounds (`"sound2"` in weapon_db)
A second synthesized layer plays with the normal shot (`player._fire`): `boom_heavy` (REVOLVER, DOUBLE BARREL, LEVER-ACTION),
`boom_50` (ANTI-MATERIEL: deep boom + echo), `thud_auto` (LMG, MINIGUN, MARKSMAN: short low punch), `rail_zap` (RAILGUN:
falling electric zap + sub boom), `xbow_snap` (CROSSBOW), `fire_whoosh` (DRAGON'S BREATH). Volume = `sound2_db`.

### Muzzle flashes (`player.gd -> _draw_muzzle`)
* `MUZZLE_PAL`: per-style colours [light, flame star, cone, core]. RAILGUN is electric blue (plus a ring and 3 small arcs),
  DRAGON'S BREATH is red-orange.
* `MUZZLE_CONE`: forward cone length per style (longer for heavy guns). `MUZZLE_JETS`: styles with a muzzle brake (side jets):
  rifle, sniper, MARKSMAN, ANTI-MATERIEL (also a rear pair).

### Held art fixes (`weapons/gun_art.gd`) and the flame stream (`bullet.gd`)
* CROSSBOW: the bow limbs were a big outlined diamond (+-11 px); now a smaller curved prod (+-8.5) with a stirrup and a small sight.
* FLAMETHROWER puffs were 3 hard concentric circles (an orange ball). Now each puff is a soft `FlameFx.glow` halo, a
  `FlameFx.tongue` that always points up in world space (the node is rotated, so it draws with `draw_set_transform(-rotation)`)
  and sways per puff, a white-hot core for the first 30% of its life and soft dark smoke for the last 25%.
* Muzzle-brake jets are tapered triangles now (they were 2.2 x size px thick lines, which read as bars on the ANTI-MATERIEL).

### Ragdoll hair (`effects/ragdoll.gd -> draw`)
Corpses of kinds 0-19 now draw the same hair as the living zombie (`zombie.gd -> _head`): `z.hair` colour, back-hair oval
(not BRUTE, not bald), RUNNER's long hair (hangs back and down), the hair cap on top (`HAIR_CAP`, same points as the living
head, not BRUTE / BOSS / CONDUCTOR / COP) and the scalp sore on bald zombies. `HEAD_K` maps the living head size (7.2) to the
corpse head (6.0). Registry types (20+) are unchanged (they draw their own heads).

### Fire particle fix (`zombie.gd -> ignite`)
`ignite()` burst 24 particles every call. The FLAMETHROWER / DRAGON'S BREATH call it on every pellet hit (~30 times a
second per zombie). Now a zombie that is already burning (> 0.5 s left) only gets its timer extended.

### Early-level ammo (`progression/arsenal.gd`)
* Levels 1-`EARLY_LEVELS` (5) get one more supply point, `EARLY_SUPPLY` = [0.9, "supply"] (an x3 ammo crate in the
  boss arena): `Arsenal.supply_points_for(lv, base)`, called from `main.gd -> _spawn_supplies`.
* The ammo drop chance when the gun in hand is nearly empty is `EARLY_DROP` (0.3) instead of 0.2 on those levels.
* Bot (god = 0, practice loadout) before: level 3 ran dry at x=3417 and then 15 more times at the boss (rifle + shotgun
  vs the door boss), TIMEOUT with the boss at 553/600. After: 1-2 short dry spells, boss killed, FINISHED (2 seeds).
  Levels 1, 2, 4, 5 were fine before (level 4: one dry spell at x=6820).

### Test results
* All 51 levels, 600 frames headless, invulnerable player firing nonstop and switching through all 11 new guns + rifle +
  shotgun every 46 frames (`t_sweep.gd`): 0 SCRIPT ERROR / Parse Error / polygon errors (run twice, the second time with the final files).
* Bot (`t_wbot.gd`, god = 0, 100 s, each new gun alone on its own stage): no script errors. FINISHED: DOUBLE BARREL 16
  (95 kills), LEVER-ACTION 18, LMG 27, MARKSMAN 37 (39 kills in 44 s), MINIGUN 45 (68 kills in 83 s). The rest hit the 100 s
  cap on long levels (REVOLVER 10, CROSSBOW 22, DRAGON'S BREATH 30, ANTI-MATERIEL 36, RAILGUN 50) - the bot is slow on
  those layouts with any gun; single runs are noisy (PISTOL vs REVOLVER on stage 10: 42 s vs 62 s, then 100 s).
* Synth levels (peak / RMS of the new sounds) are in the same range as the shotgun.
* Screenshots: `/mnt/project-files/polish/shots/weapons_guns_before.png`, `weapons_guns_after.png`,
  `weapons_guns_after_fixes.png`, `weapons_ragdoll_hair_before_after.png`.

### Testing tools (outside the repo, in the test project)
* `t_wbot.gd` = `t_bot.gd` + `FORCE_GUN=<id>` (only that gun, infinite ammo) and a `WBOT` line (time, kills, damage).
* `t_gunshot.gd -- <level> <ids> <prefix> [zoom]` - holds each gun, fires, saves a zoomed crop with the flash. Use `--fixed-fps 60`.
* `t_corpse.gd -- out.png` - kills a row of zombies next to the player and saves a crop of the corpses (scaled x3).
* `t_sweep.gd -- <level>` - 600 frames, invulnerable, fires nonstop through all new guns.
* Render with `--fixed-fps 60`: without it a slow software renderer runs several physics steps per frame and corpses /
  flashes are gone before the screenshot.

## POWERS bar: abilities + special items in one menu (2026-10-17)
This replaces the separate ability slots (6-0, reserve swap-in) and the separate special-item box (E) described above.
- **One list**: `abilities/ability_runner.gd -> powers()` = every unlocked ability (`AbilityDB.unlocked(reached_level)`, unlock order) plus `"item"` when the player carries a special (`player.special`). No slots, no reserve; `Game.ability_slots` is still saved but no longer used.
- **Controls**: C = use the selected power. E or mouse wheel = next / previous power. 6-0 = powers 1-5. Q wheel, POWERS page = pick any (the page has as many sectors as powers, min 5). Touch: NEXT (E) and USE (C).
- **Items through C**: `player.use_item()` puts the item in hand, throws / fires it once toward the aim (`_use_special`), and goes back to the gun after `ITEM_SHOW` (0.35 s). `_item_cd` keeps the item's own fire rate. LASER CANNON: C starts an automatic charge (`_laser_auto`), the beam fires by itself, then back to the gun (`laser_cannon.beam_done`). The trigger (LMB) only fires guns now.
- Picking up an item selects it (`abilities.on_item_taken`); when it runs out the selection returns to the ability that was selected before.
- HUD: weapon bar has only the 5 gun slots; the POWERS row under it shows abilities and the item (xN uses), the selected name, and "C USE / E NEXT". Item icons: `weapon_wheel.draw_item()`.
- **Removed abilities**: SHOCK BLAST (dark_pulse), LAST BREATH, MOTION SCANNER (hunters_sight), SMOKE BOMB, MORTAR STRIKE. Their stages now give a WEAPON MOD. Old saves: upgrades bought for them are refunded as scrap (`AbilityDB.REMOVED`, `migrate_upgrades` returns the refund). CHAIN LIGHTNING keeps its own `Zap` class (it used to borrow it from dark_pulse.gd).
- **Removed the grappling hook** (F): no rope, no swing. Levels never needed it (the playtest bot finishes all 51 without it).
- Test: `devtools/t_powers.gd` (cycling, C on grenade / launcher / laser / potion, abilities, screenshots of the bar and wheel).

## GRAVITY GRENADE (weapons/gravity_grenade.gd, special "gravity")
- Special item from stage 6 (`Arsenal.SPECIALS.gravity`: 2 uses, weight 1.5), used with C from the POWERS bar like grenades.
- Extends `grenade.gd`: thrown, bounces, fuse 0.9 s. Then a `Singularity` opens 26 px above the landing point for `PULL_T` (1.9 s): every zombie within `PULL_R` (340) is staggered and its velocity is set toward the core (`PULL_V` 560, weaker at the edge, bosses x`BOSS_K` 0.3). Zombies at the core are held there and crushed (`CRUSH` 3 every 0.2 s).
- Then it collapses: `Boom.blast` with `BLAST_R` 170 and `BLAST_DMG` 60 (source "grenade", so armour that ignores bullets still takes it), 1 heart to the player if he stands inside, plus a purple `Flash` ring.
- Look: particles only (user choice, 2026-10-17). ~170 light dots (blue to white, some purple) spiral inward, speed up and shrink near the centre, with 2-dot trails; ~60 large faint dark dots orbit the centre and form the "hole". Zombies darken as they get close (`modulate`, restored on collapse) and vanish into the dark cloud (z_index 14). In the last `COLLAPSE_T` (0.28 s) everything is sucked to a point, then `Flash` bursts 90 sparks outward with drag. No rings, glows or shapes.
- Icons: `draw_icon()` (bar, wheel, pickup, in hand). Test: `devtools/t_gravity.gd` (6 zombies around a point: 5/6 pulled in and killed on stages 12 and 46).

## Quieter score popups + harder levels 1-57 (2026-10-20)
- Popups (user: "keep all, but show them randomly, and always when the score is big"):
  - `Game.show_pop(big)` returns true when big, otherwise with `Game.POP_CHANCE` (0.3).
  - Kill streak meter (ui/kill_streak.gd): always shown from `SHOW_FROM` (4) kills in a streak. At 2-3 kills it shows only sometimes (chosen once per streak, double chance on a special kill). Sounds always play.
  - HEADSHOT stamp and single special-kill captions: only sometimes, and one HEADSHOT stamp at a time.
  - Kill bonus text on the zombie (zombie.gd): one line (biggest bonus + total). Always shown when the total is 150+, otherwise sometimes.
  - HUD: COMBO shows from x3 (`COMBO_SHOW_MULT`), STYLE only at A/S (`STYLE_SHOW_RANK`). Both fade in and out.
- Difficulty: `Game.harder()` = 1.25 for levels 1-57 (`HARDER_UNTIL`), 1.0 for 58-63 (already hard).
  - Zombies per screen x1.25, boss HP x1.25, zombie and boss speed +10%. Normal zombie HP is unchanged, so kills stay fast.

## Zombie mix: zombies come back in later levels (2026-10-20, levels/zombie_mix.gd)
- User: "if a zombie appears on level one he will randomly appear on 2 and 3, just less times... and randomly pop them up on 1 or 2 different levels throughout the game".
- `ZombieMix.mix(level, weights)` is called by main.gd right after the stage's `zombie_weights()`. It only adds zombies and never changes what the stage asked for.
- A zombie first seen at level N returns:
  - at N+1 with half its weight, and at N+2 with a quarter (`NEXT_K`);
  - in 1-2 later levels within `GUEST_SPAN` (24) at half weight (`GUEST_K`).
- No level gets more than `MAX_GUESTS` (4) guests. The picks are seeded by kind and by level, so they are the same in every playthrough.
- Weights are capped by the host level's own most common new zombie, so returning zombies never outnumber that level's new ones.
- `INTRO` lists each level's new zombies and is generated from levels/stage_N.gd. When you add a level, add its new zombies there.
- `STAY_HOME` lists zombies that need their own level's terrain: water, ice holes, wind, vines, cliffs, ducts, scarecrow poles, masts and thermals.
- Levels without zombie 0 in their weights (16 = swarm only) get no extras.
- Test: devtools t_mix.gd (spawns every returning zombie near the player in its new level).

## New level types + music (2026-10-20)
- levels/level_events.gd: TYPES (hold 6,21,30,48,57 / escape 11,23,41,55 / escort 13,34,44,52), MID_BOSS [10,19,40] (boss at 0.62 of the level, gate opens when it dies). main.gd creates the event after the level is built (ev.main/floor_y/hud_layer, ev.start()).
- Never give event zombies chase_range > 600: ~40 types read that as "I am the boss". Use _alert_t like levels/pace_director.gd.
- music_db.gd: REGION[7] tracks, BOSS (crossfade when a live boss is within 900 px, back to the level track when it dies), MENU (Settings.menu_music on menu/map). Missing file = old behaviour. Credits + licence notes: music/CREDITS.txt.
- Tests: devtools/t_hold.gd, t_escape.gd, t_escort.gd (t_bot + event logging).

### HOLD THE LINE — `levels/events/hold.gd` (levels 6, 21, 30, 48, 57)

## (a) What it does
- **Where:** it scans for an arena centre at 30–40% of `level_w` and scores each spot. If nothing fits, it widens the range to 26–44%. As a last resort it allows a pit inside the arena, but never under a wall or in the middle. The arena is 1.2 *visible* screens wide (`vp.x / camera_zoom`, so 1228 px on desktop), falling back to 1.0 and then 0.85 screens. A spot is rejected if it has a pit within 80 px, a story scene within 1000 px, the checkpoint within 350 px, a boss within 300 px, or falls in the last 1500 px. Score penalties: hazards inside the arena, a wall that lands on an obstacle, ladder or reserved rect, and distance from 35%.
- **Before:** a low row of sandbags marks both wall spots, so the place reads as fortified.
- **Trigger** (player x ≥ centre − 90, no story scene running): two barricades slam down. The art is sandbags, corrugated metal, a car door, planks, barbed wire and a blinking lamp, drawn with DrawBatch only.
  - Collision is a StaticBody on layer 1, 56×230 px, which blocks the player, zombies and bullets. Above it sits an invisible layer-512 wall, 1400 px tall, that only the player hits (the same mechanism as pass_barrier). This stops a double jump from a floor or a JETPACK escape.
  - It also adds camera shake, sounds synthesised in this file (`Sfx.register`: hold_slam, hold_alarm, hold_win, hold_vault), the banner "HOLD THE LINE / SURVIVE 1:00" (Bangers at a fixed 72 px, animated with `set_transform`), and a `HOLD 0:42` box under the level clock with a progress bar that marks the lull.
- **Waves:** zombies spawn at the top of a wall, just inside, and drop in with a dust puff. In levels with floors, 30% of groups instead appear at the end of a floor inside the arena ("from above"). Kinds come from `main._pick_kind`. Boss, ceiling-crawler and sewer-hand kinds are remapped, and any spawn where `is_boss()` is true is freed. Rats and dogs come as packs.
  - Nothing lands within `SAFE_DROP` = 300 px of the player. If the player hugs a wall, zombies come from the far wall or the far end of a floor.
  - The number alive in the arena is capped. Every zombie inside gets `_alert_t` refreshed every 0.5 s.
- **Pacing** (k = t / duration): first group at 4%. **RAMP**: interval 3.4→2.4 s, group size 1→2. **LULL** at 50–60%: no spawns, a SUPPLY crate drops by parachute, "SUPPLY DROP / RELOAD!". **SURGE**: interval 2.2→1.6 s, size 1.6→2.5. "FINAL WAVE" appears with 10 s left, nothing new enters in the last 3.5 s, and a tick sounds each second for the last 5 s. That gives about 21–37 zombies per hold on NORMAL.
- **End:** "LINE HELD!" plus a reward of SUPPLY, AMMO and a heart. The reward drops low and 70–170 px *ahead* of the player, so it is picked up on the way out. The barricades topple outward over 1.1 s and the colliders are removed. Leftovers in the arena (and anything waiting up to 500 px past the right wall) are alerted and keep fighting. Loot that lands on a wall top slides into the arena.
- **Ammo:** once a second, if the held weapon is below 25% of its max, an AMMO box parachutes onto the surface the player stands on (under any floor above them). The cooldown is 6 s. If every weapon is empty, it drops a SUPPLY crate instead, after 2.5 s. No drop if a box is already lying within reach.
- **Clock:** `Game.clock_pars += duration`, so the forced wait never costs the GOLD/SILVER medal.
- **Safety net:** if the player is ever past a wall face while the hold is active (a bug or a teleport), they are put back inside.
- **Tuning** (all listed under the file's `לשנות:` header):
  - Placement and size: `AT/AT_WIDE/PREFER`, `WIDTHS [1.2,1.0,0.85]`, `TRIGGER_BEFORE 90`.
  - Waves: `DURATION [45,60,70]`, `MAX_ALIVE [5,7,9]`, `INTERVAL_MULT [1.3,1,0.85]`, `SIZE_ADD [-0.5,0,0.5]`, `EARLY_LEVEL 12 / EARLY_EASE 1.2` (level 6 gets intervals ×1.2 and a cap 1 lower), `RAMP`, `SURGE`, `RAMP_SIZE`, `SURGE_SIZE`, `LULL`, `START_AT`, `STOP_T`, `FINAL_T`, `ABOVE_SHARE`, `SAFE_DROP`.
  - Ammo and drops: `LOW_AMMO`, `AMMO_CD`, `EMPTY_CD`, `DROP_H`, `REWARD_H`, `CHUTE_GRAVITY`.
  - Walls: `WALL_W/WALL_H/WALL_VIS/SKY_H`.

## (b) Checkpoint, death, restart
- `start()` runs after `_start_at_checkpoint`. If the player is already past the arena's left wall (the arena always ends at least 350 px before the checkpoint), the event frees itself: no walls and no UI. The clock pars still get +duration, because the time saved at the checkpoint already includes the hold. I checked this with `HOLD_CP=1` on levels 6 and 57: no hold node, and pars went from 155 to 215 on level 6.
- If the player dies, spawning stops while `player.dead` is set. TRY AGAIN reloads the scene as normal and the hold replays; nothing is persisted. The walls, FX and UI belong to the scene, and the UI is also freed in `_exit_tree`.

## (c) Tests (my copy, NORMAL, bot god=0, `t_hold.gd` = t_bot plus hold logging)
All levels: `PARSED 445 bad 0` and no SCRIPT ERROR in any run. Damage taken inside the hold, on 5 hearts:
| lv | t_hold seed default: result / hold dmg / total dmg / spawned | t_hold seed 77 | plain t_bot.gd (no hold-aware wait) |
|---|---|---|---|
| 6  | FINISHED 141s / 1 / 5 / 30   | FINISHED 164s / 2 / 8   | FINISHED 139s dmg=10 |
| 21 | FINISHED 170s / 1 / 23 / 34  | FINISHED 174s / 0 / 17  | FINISHED 166s dmg=29 |
| 30 | FINISHED 157s / 6 / 15 / 33  | FINISHED 156s / 1 / 3   | FINISHED 155s dmg=11 |
| 48 | FINISHED 202s / 7 / 27 / 37  | FINISHED 204s / 11 / 27 | FINISHED 214s dmg=34 |
| 57 | FINISHED 225s / 17 / 33 / 37 | FINISHED 214s / 15 / 27 | FINISHED 240s dmg=21 |
Baseline without the hold (same bot): total dmg 3–29. Frames inside the hold: average 6–14 ms, worst 42 ms. Level 57 is the hardest because of the whaling-station hazards inside the arena; I'm accepting that as late-game difficulty. Ammo never ran out inside the hold, and the rifle had 15→57 after the reward. Spawned per hold: 21–37.

## (d) Shared changes / things the lead should know
1. **Trap in the BRIEF:** do *not* set `z.chase_range = 3000`. About 40 enemy types (revolver, frostbite, waddler, ironarms, glider…) treat `chase_range > 600` as "I am the BOSS", which means boss stats, boss attacks and the gate trigger. I use `_alert_t`, as pace_director does. The escape and escort authors should check their code for this.
2. **t_bot.gd** teleports 260 px forward after 25 s without progress, and it only exempts pass_barrier. In a 60 s hold it jumped past the right wall: one plain-bot run on level 21 did this before I added the safety net. Suggestion: in `_move()`, treat a child of main whose script ends with `events/hold.gd` and returns `is_active()` like the barrier (`best_x_f = f`). `t_hold.gd` does exactly that, and it also has `HOLD_SHOTS` / `HOLD_CP` / `HOLD_DIFF` env options.
3. The bot's only weapon is the starting rifle, and it sprays. Once in two seeds it reached a boss (21 REVOLVER, 6 HOUND) with no ammo, more than 4000 px after the hold. Without the hold that didn't happen in 3 runs. That is why the end reward is SUPPLY + AMMO, placed on the way out. If it still shows up, consider a slightly higher `Arsenal.ammo_drop_chance` on hold levels (shared file).
4. One headless run in about 60 crashed with signal 11 ("Caller thread can't call this function in this node (/root)") right after a hold started on level 30. I couldn't reproduce it in 8 more level-30 runs, and nothing in hold.gd uses threads. Worth watching.
5. No shared file needs to change for the event itself.

### ESCAPE / THE HORDE: `levels/events/escape.gd` (levels 11, 23, 41, 55)

## (a) What it is
- When the player passes `START_AT` (0.15 of the level, x=1536) and the 5 s level-title intro is over, a tsunami of the dead rises
  at the left edge of the screen: a dark wall with a forward-leaning crest of about 70 silhouettes (reaching arms, glowing red,
  yellow or green eyes, front-row runners with legs), plus dust. It is all one DrawBatch drawing on a Node2D in main (z 6, above the player).
  It has no zombie nodes. Collision is one x test against the front edge `_hx`.
- The horde moves at `SPEED` [210, 232, 258] (EASY/NORMAL/HARD). Walking is 205 and running is 320, so a walker gets caught slowly and a runner pulls away.
  It starts at `START_SPEED` 140 and ramps up over `RAMP_T` 2.5 s. If it falls more than `CATCHUP_GAP` 950 px behind, it moves at `CATCHUP_SPEED` 330, so it never stops threatening.
- Touching the wall (player x < front, feet below `WALL_H` 330, which covers every roof and overpass in these stages) costs 1 heart through `player.hurt` and
  launches the player forward and up (`KNOCK` 560/-480, enough to clear obstacles). `TOUCH_CD` [2.2, 1.8, 1.4]. After a hit the horde slows to
  30% for `STUMBLE_T` 1.6 s, and it waits while the player is inside it, so it never overruns them. Roll, shield and god mode work as usual.
- Live non-boss zombies it overtakes are absorbed with a blood burst and freed. Corpses are left alone.
- Runners ahead: every `SPAWN_EVERY` [3.6, 2.9, 2.4] s, 1-2 zombies from the level's `_pick_kind` mix (rats and dogs in their own group sizes, no
  ceiling crawlers or bosses) spawn 640-820 px ahead on free road (same spot test as pace_director) and charge. `SPAWN_BUDGET` [8, 11, 14].
- HUD: a "RUN!" punch banner (Bangers font, scaled through the transform) with "THE HORDE IS COMING - DON'T STOP" and then "DOUBLE-TAP TO SPRINT".
  Below the clock there is a meter (horde fill, player marker, green SAFE flag, "THE HORDE 23m" and "SAFE 41m"). When the horde is off screen,
  a red edge glow, an arrow and the distance show on the left, pulsing faster as it gets closer. A green flare marks the safe point in the world.
- Sound: roar, screams and groans from the horde, plus a synthesized `esc_rumble` (registered with `Sfx.register`, no audio files) whose volume follows the gap.
  The camera shakes on the rise, on each hit and when the horde is close.
- End: the player reaches `_safe_x`, which is min(trigger + `CHASE_LEN` 3300, checkpoint - `CP_GAP` 350), at least `STORY_GAP` 1100 before any story scene
  and outside the boss zone. The horde stops, roars, then sinks and crumbles into dust (`CRUMBLE_T` 2.6 s), "SAFE! THE HORDE FELL APART"
  appears, and the player gets +40 style. The safety net is `MAX_T` 75 s, after which it gives up ("THEY GAVE UP"). Safe x by level: 11 and 41: 4836, 23: 4770,
  55: 3400 (STRANGER at 4500). The chase is about 3,000 px, roughly 15-36 s depending on how much you fight.
- pass_barrier: it is suspended during the chase (otherwise its wall locks the player in front of the horde). If a wall is already up,
  it is faded out, and the barrier's physics process is restored at the end and on `_exit_tree`.
- Tuning constants (under "לשנות:" in the header): START_AT, CHASE_LEN, CP_GAP, STORY_GAP, SPEED, START_SPEED, RAMP_T, CATCHUP_GAP,
  CATCHUP_SPEED, WALL_H, TOUCH_CD, KNOCK, STUMBLE_T/K, SPAWN_EVERY, SPAWN_BUDGET, MAX_T, CRUMBLE_T.

## (b) Checkpoint, death, restart
- `start()` runs after `_start_at_checkpoint`. If the player is already at or past the trigger (a checkpoint start), or the window is
  shorter than `MIN_LEN` 1400, the node frees itself and nothing happens. The escape always ends before the checkpoint, so a checkpoint
  restart skips it.
- Death: the horde stops where it is and roars once, and the HUD stays. TRY AGAIN reloads main, so the event is rebuilt from scratch.
- It freezes during story scenes, `clock_paused` and `_finished`.

## (c) Tests (Godot 4.3, test copy, NORMAL). `t_escape.gd` = t_bot plus a horde log (ESC lines and HIT counter) and a `shot` mode for screenshots
Parse: `PARSED 445 bad 0`. No SCRIPT ERROR in any run. Final code:
- 11 seed 77: `BOT lv=11 god=0 result=FINISHED time=183.8s ... deaths=10 dmg=50` (chase 24.2 s, 7 horde hits)
- 11 seed 99: `result=FINISHED time=415.8s ... dmg=360` (0 horde hits; the long DEVOURER boss fight; baseline seed 99 = dmg 138, 197 s)
- 11 default seed: `result=TIMEOUT` (420 s and 700 s), stuck at x≈9230 y≈410 next to the boss. **Baseline without the event, seed 77, times out at the
  same spot** (`STUCK x=9230 y=409 260s`), so this is a bot/stage issue at the end of the level, not the escape.
- 23 default: `BOT lv=23 god=0 result=FINISHED time=140.8s ... deaths=10 dmg=50` (8 hits); seed 77: `FINISHED 182.7s dmg=40` (4 hits)
- 41 seed 77: `BOT lv=41 god=0 result=FINISHED time=145.2s ... deaths=5 dmg=29` (5 hits); seed 99: `FINISHED 131.8s dmg=27` (36 s chase, 15 hits)
- 41 default: one run `TIMEOUT` at the MARSHAL (baseline seed 77 also times out there, 950/950); one run crashed with signal 11 mid-chase (see d)
- 55 default: `BOT lv=55 god=0 result=FINISHED time=157.3s ... deaths=4 dmg=21` (6 hits); seed 77: `FINISHED 171.3s dmg=30` (8 hits)
- Baseline (no event): 11 dmg 8 / 138; 23 dmg 27; 41 dmg 14 / 133(TIMEOUT); 55 dmg 13 / 19. The bot walks slowly (about 140 px/s) and backs away from zombies
  into the wall, so it takes 0-15 horde hits (about 7 on average). A player who keeps moving takes far fewer.
- Screenshots were checked on 11 (night), 23, 41 and 55: the wall, crest, eyes, meter, off-screen arrow, crumble and SAFE banner all render correctly.

## (d) Shared changes / notes
- No shared files were edited. Nice to have: a public `suspended` flag in `environment/pass_barrier.gd` so events don't have to toggle its
  physics process and set `_fade` (escape.gd does this through duck typing today).
- Level 41 sometimes crashes the engine with signal 11 (identical backtrace with and without the event: a baseline run crashed too).
  It is pre-existing and non-deterministic, and I could not symbolize it with the official binary. Worth a look by whoever owns stage 41.

### ESCORT ("RESCUE"): levels 13, 34, 44, 52 (`levels/events/escort.gd`)

## (a) What it is, and its tuning constants
- A combat **medic** (a new character drawn in escort.gd: white helmet with a red cross, orange jacket, radio pack with a blinking antenna) waits at `SPAWN_AT` = 15% of the level and calls out on the radio (radio waves + a green marker over her). She is not survivor.gd, so she has no drain.
  On 52 she is pushed to at least `STORY_CLEAR` = 1000 px from story scenes, so she waits at x=2341 (the scene is at 1300).
- Start banner (HUD, Bangers): "RESCUE: GET HER TO THE EXTRACTION". It shows at 4.6 s, after the level title.
- She joins when you come within `JOIN_DIST` 320 px, then follows `FOLLOW_DIST` 80 px behind you. She walks at `WALK` 235 and sprints at `SPRINT` 345 when far. She jumps walls and obstacles, and jumps pits when a ray finds no ground ahead.
  When you are on a higher floor she climbs the nearest ladder that leads there (a hop when none exists). When you are below, she drops through the one-way floor. If she gets stuck inside a slope she nudges herself out.
- Teleport to a free ground spot next to you: when she is more than `TP_FAR` 1000 px away, when she fell, after `STUCK_T` 2.5 s stuck off-screen, or after `STUCK_FORCE` 5 s stuck on-screen (with a smoke puff).
- Collision layer 0: player bullets and explosions, zombies and the player all pass through her. Mask 1|16 (ground and floors).
- Hearts `HP` = [7,6,5] (EASY/NORMAL/HARD), shown over her head with an HP bar.
  - Any awake, chasing, non-boss zombie that touches her bites for 1 heart. The bite respects `type_mod.can_bite()` and skips ranged kinds. Each zombie can bite once per `BITE_CD` 1.2 s, and she gets `IFRAME` 0.9 s after a hit.
- **Hunters:** every `HUNT_EVERY` [13,10,8] s (±20%), `HUNTERS` [1,1,2] zombies 220-900 px away from her switch to `goal_x` = her x, ignore you and run at her. They get a red pulsing marker and a dashed line to her, and she shouts "HE'S AFTER ME!".
  Plain kinds (`HUNT_KINDS`) are picked first, never `NO_HUNT` kinds. A special type whose movement ignores `goal_x` is released after `HUNT_CHECK` 1.6 s, and every hunter is released after `HUNT_T` 7 s.
  A hunter is dropped if someone else rewrites its `goal_x` (s44 Surge). `HUNT_FIRST` 7 s of quiet after she joins.
- **Boss zone** (last `BOSS_ZONE` 1500 px, gate locked): she hides at `level_w-1580` ("I'LL STAY DOWN HERE!"). There she cannot be hurt and no hunters are picked.
- **Rescued:** the gate opens (boss dead) while she is alive, or you pass `exit.x-30`. Then:
  - `Game.add_score(RESCUE_SCORE` 1500, with multipliers) and `Game.scrap += RESCUE_SCRAP` 40 + 2×level (66 on lv13, 144 on lv52).
  - Banner "SURVIVOR RESCUED +N SCORE +N SCRAP". She runs to the helicopter and fades out.
  - The bonus is awarded before exit.gd fires `reached`, so the score is counted in `finish_level`.
- **Lost:** "SURVIVOR LOST / No rescue bonus this time" plus a wail. She lies there and fades after 12 s. No other penalty.
- Performance: every `_draw` uses the DrawBatch wrapper. She redraws only when on screen, and the banner and marks redraw only while active. The bite scan runs every 3rd physics frame. Solo bot run: slow25=0, worst=22 ms.

## (b) Checkpoint, death and restart
- If the player already starts past `spawn_x-200` (`_start_at_checkpoint` or any other jump), the medic spawns 70 px behind the player and is already following. The banner comes at 1 s.
- If she is still waiting and the player gets past her, she teleports next to the player and joins.
- The checkpoint does not save her state, so a TRY AGAIN from the checkpoint brings her back alive even if she died before it. This is intended: "spawn next to the player".
- Player death or restart reloads main.tscn and the event is created again. During story scenes (`clock_paused`) she stands still and no new hunters are picked.

## (c) Test results (t_escort.gd = t_bot + an ESCORT line; god=0, NORMAL)
Final build:
- `BOT lv=13 result=FINISHED time=75.7s deaths=2 dmg=14` | ESCORT lost (bot doesn't defend; bitten by graveborn/devourer)
- `BOT lv=34 result=FINISHED time=221.5s deaths=10 dmg=50` | ESCORT rescued, min_hp 5
- `BOT lv=44 result=FINISHED time=114.2s deaths=6 dmg=33` | ESCORT rescued, min_hp 5
- `BOT lv=52 result=FINISHED time=129.9s deaths=2 dmg=13 story=32s` | ESCORT rescued (joined 43.7 s, after the story scene)

Checkpoint start (ESCORT_CP=1):
- 13: FINISHED 55.5s deaths=0 dmg=1, rescued
- 34: FINISHED 136.9s deaths=6 dmg=30, rescued
- 44: FINISHED 127.9s deaths=6 dmg=34, rescued
- 52: FINISHED 255.2s deaths=5 dmg=27, rescued

Across 22 bot runs with her: 15 rescued (68%). The bot never protects her; most losses are on 13, where graveborn erupt right where you walk.

Baseline (ESCORT_OFF=1) shows the same bot variance on 34 and 44: each timed out once on the boss in 2 runs with the event off. The event does not cause it.

Screenshots were checked on 13, 34, 44 and 52 for: waiting, following with hearts, hunter marker, lost and rescued banners. Parse: `PARSED 445 bad 0`, and no SCRIPT ERROR in any run.

## (d) Shared changes I'd want (not made)
- `zombie.gd`: a real "bite target" hook would make hunters play their own bite animation and reach. Today escort.gd fakes the bite through `_bite_anim` and its own contact check.
- `results.gd`: show "SURVIVOR RESCUED +scrap" on the results screen. Right now the scrap is added straight to `Game.scrap`, so the results "scrap earned" line doesn't include it.
- Optional: save `medic_alive` in `Game.checkpoint`, if a medic who died before the checkpoint should stay dead.

# Level 2: train-roof rider + climbing test (2026-10-20)
- **Train rider** (subway.gd `_spawn_rider` / `_ride`): every ghost train carries one zombie on its roof (60% RUNNER, else WALKER). The jump point is computed when the train appears so the zombie lands `RIDER_LAND_GAP` (110 px) to the left or right of the player (never on an electric rail). It leaps off with `RIDER_VX` 650 / `RIDER_POP` 400, tumbles (`zombie._crash_fly`, one spin), lands with dust + a camera shake, staggers 0.45 s, then rushes the player (`_alert_t` 30, `_rush_t` 3). No rider during the boss fight (last `RIDER_SKIP_END` px). It can be shot while riding or in the air.
- **Climb instead of jump** (zombie.gd `CLIMB_LEVELS := [2]`, `CLIMB_SPEED` 170): a chasing zombie blocked by a wall grips it and climbs, arms and feet working, then pulls itself over the edge. `hop_up` (brain jumping to a floor above) also climbs. Gives up after 3 s. Only the default movement path; zombie types with their own physics are unchanged. To try it on other levels, add them to `CLIMB_LEVELS`; to undo, set it to `[]`.
- Test: `devtools/t_train.gd -- <player_x> <frames> [climb png]` (calls the train at frame 30 and logs the rider until it lands and chases; "climb" puts the player on a stuck subway car and saves a PNG of a climber).
