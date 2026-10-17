# Dev test tools (not part of the Godot project)

SceneTree scripts used to test the game headless. Copy the one you need into the root of a scratch copy of
`shooter_game/` (so it does not ship with the game), then run it with the Godot 4.3 binary:

    godot --headless --path . -s res://t_run.gd -- <level> <frames> [shot.png] [player_x]
    xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 -s res://t_run.gd -- 12 150 shot.png 3000

- `t_run.gd` - load a level and run N frames; optional screenshot. `all.sh <projdir>` runs levels 1-51 and prints errors.
- `t_bot.gd` - playtest bot: plays a level like a player (runs right, shoots, jumps) and logs deaths, stalls and stuck zombies.
- `t_spawn.gd` - spawn placement analysis (args `levels seeds dyn_seconds`, e.g. `-- 1,2,3 1,2 150`).
- `t_light.gd` - renders the start and middle of each level for lighting contact sheets.
- `t_zoo.gd` + `zoo.sh outdir kinds zoom` - draws every zombie kind side by side.
