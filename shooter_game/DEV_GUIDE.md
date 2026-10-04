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
