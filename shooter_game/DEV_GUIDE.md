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
| `levels/` | `stage_base.gd` (base class), `stage_registry.gd` (level → file), `stage_5.gd` … `stage_9.gd`. |
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

```
godot --headless --path . -s res://t_parse.gd          # compiles every script, prints FAIL lines
xvfb-run godot --path . -s res://t_stage.gd -- 6 0.4 x # runs stage 6 at 40% of its length, saves a screenshot
```
(`t_*.gd` test scripts are kept out of the shipped game.)

## Controls

A/D move (double-tap = run) · W jump / climb ladder · S crouch (S+W = drop through a floor) · LMB fire ·
R reload · Q weapon wheel · 1-5 weapons · G drop weapon · E grenade · SHIFT roll · F grapple ·
RMB sniper scope · ESC pause.
