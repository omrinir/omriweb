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
- `story_voices.py` + `story_voices_master.py` - voices for the level 52 (QUISLING) and 54 (STRANGER) story scenes: Kokoro
  (player am_onyx, stranger bm_lewis pitched down + metallic comb, quisling am_michael + whisper + tremble; whisper = pyworld
  resynthesis with all-noise excitation), then mastered to about -18 dB mean like the level 1 scene.

- `t_masskill.gd` - mass-kill frame-time test: `godot --headless --path . -s res://t_masskill.gd -- <level> <n> all|stream [quality]` (copy into a test project first). Prints a MASSKILL summary (avg / p95 / max frame ms).
- `t_minigun.gd` - holds the trigger of a gun (default the minigun) into a steady crowd and prints frame times and kills:
  `-- [level 55] [weapon id 21] [seconds 10] [zombies per wave 4]`. Env `MG_NOFIRE=1` (crowd only), `MG_AIR=1` with 0 per wave
  (the gun alone), `MG_SHOT=300,out.png` (picture of that frame, run with a window under xvfb).
- `t_corpse_audit.gd` - checks that dead bodies of every zombie kind stop being redrawn once they lie still (`-- all`, a range
  `0-65` or a list). A corpse that keeps changing is redrawn for 7 s and makes mass kills slow; a new zombie type should come out
  still, or return true in `corpse_anim()` when its body moves on purpose.
- `t_jump.gd` - jump feel: walks off a pit edge and presses jump 1 / 4 / 7 frames later (coyote time = full jump that keeps
  the double jump), then presses jump just before landing (jump buffer = jumps on touchdown). `-- [level 1]`, headless.
- `t_music_mood.gd` - prints the level-music filter and volume (effects/music_mood.gd) when calm, with zombies near, during a
  hush, after a hit and on the way to the boss. `-- [level 1]`, headless.
- `t_eyes.gd` - forces the eyes in the dark (effects/dark_eyes.gd) on a dark level (2, 4, 11, 14, 26, 29, 54), saves a picture
  when they are open and checks they go away when you walk at them: `xvfb-run -a godot --rendering-driver opengl3 --path . -s res://t_eyes.gd -- 11 /tmp/eyes.png`.
- `t_arrows.gd` - threat arrows (ui/threat_arrows.gd): spawns zombies of one kind off screen behind the player and prints the
  arrows until they walk into view: `-- [level 55] [kind 1] [count 2] [distance 950]`. A runner should get an arrow about a
  second before it appears; a slow walker none. Env `ARROW_SHOT=/tmp/a.png` (+ `ARROW_K=0.7`) saves a picture (xvfb, opengl3).
- `t_rat_slam.gd` - rat slam (player.gd `rat_slam`): rats run at a player who stands still, case after case (front, behind,
  a pack, roll mid-slam, GOD MODE, shield, rat killed in the hand). Prints the bite damage (stays: 1 per slam, 0 with god /
  shield) and where each body lands (on its back by the feet), then checks the bodies stop being redrawn:
  `-- [level 1] [pack 5]`, headless. Env `SLAM_CASES=god,front`, `SLAM_SHOT=/tmp/slam` (pictures of the front/behind slams,
  xvfb, opengl3), `SLAM_TRACE=1`.
- `t_maker.gd` - the CHARACTER MAKER (characters/maker.gd) end to end: opens it (the first saved character must open), NEW, then
  STAND / WALK / RUN / ATTACK, the 3 shots that don't kill, all 7 KILL buttons (checks each death really happened), RANDOM,
  every tab, CROWD + NIGHT, DRAW (a drawing on white paper on his hat: paper cut, the white inside kept; a JPG "photo" of
  paper that darkens to one side dropped onto his hand, moved to his body; CUT BACKGROUND off / on, sliders, mouse drag, wheel;
  LOOK 45 (the middle turns forward, the edges stay); WARP: 9 dots show, a dot pressed and dragged with the real mouse
  follows it, a press away from the dots moves the whole picture, STRAIGHTEN; headshot, NO HEAD flying head and a corpse
  wearing the pictures), ATTACK = HAND with a bat (he swings, at least 2 hits land, he can't bite), SAVE (`characters/saved/zz_maker_test.tres` must load
  back the same, the replaced picture file cleaned), TRY IN LEVEL (level 3 must have him, wearing the pictures), pause BACK
  TO MAKER, DELETE (his picture files go too), NEW + a picture, BACK TO MENU (the unsaved picture goes). Ends with
  `MAKER OK`. Pictures of every step:
  `xvfb-run -a -s "-screen 0 1280x720x24" godot --fixed-fps 60 --rendering-driver opengl3 --path . -s res://t_maker.gd -- /tmp/m`
  (headless with `-- none`).
- `t_characters.gd` - CHARACTER MAKER parts: 14 test characters that together use every part, walking and biting on a grid
  (`CHAR_MODE=zoo`, default; `CHAR_DARK=1` dark background), every special death on them in level 3 (`CHAR_MODE=deaths`), or
  the saved characters (`CHAR_MODE=saved`). `-- <png prefix>`, xvfb + opengl3.
- `make_example_characters.gd` - writes the 6 example characters (BUTCHER ... TOURIST, kinds 1000-1005, in no level) to
  `characters/saved/`: `godot --headless --path . -s res://make_example_characters.gd`.
- `t_portrait.gd` - promo character art: one character at a time, frozen and big, drawn on white and then on black so a
  difference matte gives a clean cut-out (alpha = 1 - (white - black), colour = black / alpha). Env `PORT_OUT=<dir>`,
  `PORT_LIST="name:kind[:k=v,...];..."`, `PORT_LEVEL` (default 5). kind = zombie number or name, `HERO`, `SURV<variant>`;
  options `boss=1`, `pose=walk|attack`, `dir`, `zoom`, `cy`/`cx`, `wp`, `tm`, `gun`/`ax`/`ay` (HERO); any other key sets that
  type_mod variable (MIMIC monster form `_m=1,state=3`, spider CLIMBER `state=2,grow=1`). Writes `<name>_w.png` + `<name>_k.png`:
  `xvfb-run -a -s "-screen 0 2560x1440x24" godot --path . --resolution 2560x1440 --rendering-driver opengl3 -s res://t_portrait.gd`.
  The trailer Short's sketchbook drawings were made from these cut-outs.
