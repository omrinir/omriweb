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
- Picking it up starts it at once (player.collect -> `_drink_god`, not stored as a special): `boosts[PickupScript.GOD] = player.GOD_TIME` (23 s, HUD boost row shows it; flames ramp up over the first 2.5 s). Light on particles: body flames ~15 alive, 1 bullet ember per 2 frames (max 8), 14-part hit burst.
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

## Stage 30 - "FROZEN VILLAGE" ("THEY LEARNED THE COLD") - Andean highland village in a blizzard, region 4 level 3
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

## Stage 45 - "THE RED PALACE" ("THEY LEARNED YOU") - the Imperial Palace of Petropolis, region 5 level 9 (the end of the Empire)
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

**Blood and gore are never reduced** (blood drops, flesh chunks, blood sprays, "hit" blood particles, ragdoll corpses,
torn-cheek wounds) - they are part of the game. Only non-gore effects scale:

| Level | What changes |
|---|---|
| 0 | everything full |
| 1 | smoke / sparks / dust particles x0.6, zombies redraw 1 frame less often, simplified zombie drawing above 8 on screen, background redraws every 2nd frame, rain/ash x0.7 |
| 2 | smoke / sparks / dust x0.35, damage numbers only for head hits, simplified zombie drawing always, background every 3rd frame, rain/ash x0.45, off-screen zombies think 15x/s instead of 30x/s |
| 3 | smoke / sparks / dust x0.18, no damage numbers, background every 4th frame, rain/ash x0.3 |

* Pause menu (ESC): **EFFECTS: AUTO / HIGH / LOW** (saved in settings.cfg). HIGH = always level 0, LOW = always level 3.
* **F3** shows FPS and the current level in the bottom-left corner.
* The background (`effects/parallax_backdrop.gd`) draws each layer in its own node. Between redraws a layer just moves with the
  camera, so scrolling stays smooth; it redraws at once if the camera moved more than `MAX_SHIFT` px.
* New non-gore effects should ask `Quality` (`particles()`, `ambient()`, `Quality.scaled(n, mult)`). Never scale blood or gore.
* `effects/collision_outlines.gd` now redraws only when a body changes (moves, breaks, opens) or the camera moved 200 px.
