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
- `t_rec.gd` + `build_short.py` - promo clips. `t_rec.gd` is the bot with the HUD hidden; record with
  `xvfb-run ... godot --path . --rendering-driver opengl3 --write-movie out.avi --fixed-fps 60 -s res://t_rec.gd -- <level> 1 <sec> <start_x>`
  (env `REC_SPECIAL=gravity` hands the bot an item). `build_short.py` cuts the clips into a 1080x1920 Short with captions,
  music and a narrator voice (espeak-ng + mbrola us2 run through sox; paths at the top of the script).
- `robot_voice.py` + `robot_lines.txt` - the deadpan robot narrator (espeak-ng mbrola us2, pitch flattened with pyworld, sox speaker colour).
  `build_short_l1.py` - the level 1 Short (segments and narrator cues at the top). Record with `REC_NOMUSIC=1` so the music can be laid over the cuts.
- `kokoro_voiceovers.py` - natural voiceovers with Kokoro-82M (Apache-2.0). Needs `pip install kokoro-onnx` (user-approved 2026-10-17),
  the q8 model from the npm package `kokoro-q8-shards` (6 parts, concatenate; sha256 fbae9257...) and the voice .bin files from the npm
  package `kokoro-local-runtime` (`voices/*.bin`, float32 reshaped to (510,1,256), saved together as voices.npz).
- `build_short_followcam.py` + `mix_short_followcam.py` + `shots_level2.json` + `level2_vo_lines.txt` - 30 s level 2 Short: record at
  `--resolution 2560x1440` with `REC_POS=<csv>`, then a 4:5 follow-cam crop on the player. No slow motion (it wrecked the audio);
  zoom only where a shot lists `zk` keyframes, punch/shake/flash only on its `hits`. Narrator = Kokoro am_onyx at speed 0.85
  (lines file), music = level1_total_war from 22 s (its first 21 s are silent), game audio ducked under the voice.
