# captions + narrator (voice #1) + music over the follow-cam render -> final 30 s level 2 Short
import json, subprocess, wave
OUT = "/tmp/claude-0/short6"
FONTDIR = "/home/claude/omriweb/shooter_game/fonts"
MUSIC = "/home/claude/omriweb/shooter_game/music/level1_total_war.mp3"
MUSIC_FROM = 22.0   # the track is silent for its first ~21 s
tl = json.load(open(f"{OUT}/timeline.json"))
st, total = tl["starts"], tl["total"]
VO = [  # (line, shot index, offset, caption)
    (1, 0, 0.2, "IN LEVEL 2...\\N{\\c&H00D7FF&}THEY HUNT IN PACKS"),
    (2, 1, 2.5, "TOO BAD THEY NEVER\\N{\\c&H3C3CFF&}LEARNED TO DUCK"),
    (3, 2, 3.3, "THEN {\\c&H00D7FF&}THE CONDUCTOR{\\c&HFFFFFF&}\\NSHOWED UP"),
    (4, 3, 1.3, "BULLETS CAN'T TOUCH HIM...\\N{\\c&H00D7FF&}FROM THE FRONT"),
    (5, 5, 0.3, "AND THE {\\c&H3C3CFF&}GHOST TRAIN{\\c&HFFFFFF&}...\\NIS RIGHT ON TIME"),
    (6, 6, 0.7, ""),
]
def wl(p):
    with wave.open(p) as w:
        return w.getnframes() / w.getframerate()
def ts(t):
    return f"0:{int(t // 60):02d}:{t % 60:05.2f}"
POP = r"{\fscx75\fscy75\t(0,120,\fscx105\fscy105)\t(120,220,\fscx100\fscy100)}"
ev, vo_t = [], []
for n, si, off, cap in VO:
    t = st[si] + off
    d = wl(f"{OUT}/vo_{n}.wav")
    vo_t.append((n, t))
    print(f"vo {n} {t:.2f}-{t + d:.2f}")
    if cap:
        ev.append(("Top", t, min(t + d + 0.5, total), POP + cap))
e0 = st[6]
ev.append(("Title", e0 + 0.5, total, r"{\fad(200,0)\fscx140\fscy140\t(0,350,\fscx100\fscy100)}THEY LEARN"))
ev.append(("Tag", e0 + 1.0, total, r"{\fad(250,0)}COMING SOON TO STEAM"))
ev.append(("Bot", 0.0, e0, "THEY LEARN  ·  COMING TO STEAM"))
ass = f"""[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Top,Bangers,96,&H00FFFFFF,&H00FFFFFF,&H00000000,&HA0000000,0,0,0,0,100,100,3,0,1,8,5,8,40,40,40,1
Style: Bot,Bangers,56,&H00C8C8C8,&H00C8C8C8,&H00000000,&H90000000,0,0,0,0,100,100,4,0,1,4,2,2,40,40,150,1
Style: Title,Bangers,200,&H002A2AE0,&H00FFFFFF,&H00000000,&HA0000000,0,0,0,0,100,100,8,0,1,11,8,5,40,40,0,1
Style: Tag,Bangers,80,&H00FFFFFF,&H00FFFFFF,&H00000000,&H90000000,0,0,0,0,100,100,4,0,1,6,3,5,40,40,0,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
for s, a, b, t in ev:
    if s == "Tag":
        t = r"{\pos(540,1110)}" + t
    ass += f"Dialogue: 0,{ts(a)},{ts(b)},{s},,0,0,0,,{t}\n"
open(f"{OUT}/caps.ass", "w").write(ass)
# darken the gameplay a little under the end card
vf = f"[0:v]eq=brightness=-0.18:enable='gte(t\\,{e0 + 0.4:.2f})',subtitles={OUT}/caps.ass:fontsdir={FONTDIR}[v]"
inputs = ["-i", f"{OUT}/video_only.mp4", "-i", f"{OUT}/game_audio.wav", "-ss", f"{MUSIC_FROM}", "-i", MUSIC]
for n, t in vo_t:
    inputs += ["-i", f"{OUT}/vo_{n}.wav"]
parts = [f"[{k + 3}:a]aresample=48000,aformat=channel_layouts=stereo,adelay={int(t * 1000)}|{int(t * 1000)},apad[v{k}]"
         for k, (n, t) in enumerate(vo_t)]
af = ";".join(parts) + ";" + "".join(f"[v{k}]" for k in range(len(vo_t)))
af += f"amix=inputs={len(vo_t)}:normalize=0,atrim=0:{total:.3f},volume=1.5,asplit[vo][key];"
af += f"[1:a]volume=0.8[game];[2:a]atrim=0:{total:.3f},asetpts=PTS-STARTPTS,volume=0.6,afade=t=in:d=0.3,afade=t=out:st={total - 1.5:.3f}:d=1.5[mus];"
af += "[game][mus]amix=inputs=2:normalize=0[bed];[bed][key]sidechaincompress=threshold=0.04:ratio=5:attack=15:release=350[duck];"
af += "[duck][vo]amix=inputs=2:normalize=0,alimiter=limit=0.95,loudnorm=I=-14:TP=-1.0[aout]"
subprocess.run(["ffmpeg", "-v", "error", "-y", *inputs, "-filter_complex", f"{vf};{af}",
                "-map", "[v]", "-map", "[aout]", "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p",
                "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", "-t", f"{total:.3f}", f"{OUT}/they_learn_l2_short_v2.mp4"], check=True)
print("done", round(total, 2))
