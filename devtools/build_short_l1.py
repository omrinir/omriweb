#!/usr/bin/env python3
# Short v2: level 1 highlights, deadpan sarcastic robot narrator. 1080x1920, 30fps.
import subprocess, wave

import os
REC = os.environ.get("REC_FILE", "/tmp/claude-0/rec/l1m.avi")
OUT = "/tmp/claude-0/short3"
FONTDIR = "/home/claude/omriweb/shooter_game/fonts"
MUSIC = "/home/claude/omriweb/shooter_game/music/level1_zombie_joyride.ogg"
W, H = 1080, 1920
FG_Y = 430

# (start, end, speed, flash_on_cut)
SEGS = [
    (5.7, 7.3, 1.0, False),    # "Hello, friend."
    (14.9, 17.5, 1.0, False),  # "You can't kill what's already dead."
    (31.0, 34.4, 1.0, True),   # first contact
    (34.6, 38.6, 1.0, True),   # from above, sharpshooter
    (40.0, 42.9, 1.0, True),   # top gun, big headshot
    (50.2, 55.2, 1.0, True),   # explosion, streak x4-x6
    (60.8, 64.3, 1.0, True),   # boss shows up
    (67.6, 68.6, 1.0, True),
    (68.6, 69.8, 0.5, False),  # boss kill in slow motion
    (0.2, 2.6, 0.5, False),    # end card background: the burning city from the intro
]
# narrator: (line no, segment index, offset into that segment, caption)
VO = [  # (line no, segment index, offset into that segment, caption)
    (1, 0, 0.1, "HE SAID HELLO. ADORABLE."),
    (2, 1, 0.3, "HE IS NOT WRONG. TECHNICALLY."),
    (3, 2, 0.3, "DAY ONE. THE PLAN: PANIC."),
    (4, 3, 0.2, "THIS HUMAN'S PLAN: HEADSHOTS."),
    (5, 4, 0.0, "HEADSHOT. HEADSHOT. HEADSHOT.\\NI AM OUT OF WORDS."),
    (6, 5, 0.4, "SOMEONE HAS TO CLEAN THIS UP.\\NNOT ME. NO HANDS."),
    (7, 6, 0.6, "OH GOOD. A BIG ONE."),
    (8, 8, 1.6, "WAS A BIG ONE."),
    (9, 9, 0.2, "WOULD YOU SURVIVE LEVEL 1?"),
]
# kills from the recording log (game time, headshot?) for the live carnage counter
KILLS = []
for ln in open(REC.replace(".avi", ".log")):
    if ln.startswith("EV") and " kill " in ln:
        KILLS.append((float(ln.split("t=")[1].split()[0]), "head=true" in ln))


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stderr[-3000:])
        raise SystemExit(1)


def wav_len(p):
    with wave.open(p) as w:
        return w.getnframes() / w.getframerate()


def seg(i, a, b, sp, endcard):
    dur = (b - a) / sp
    punch = "1+0.10*max(0\\,1-t/0.35)" if (sp == 1.0 and not endcard) else "1"
    dark = "eq=brightness=-0.32:saturation=0.6,boxblur=5:1," if endcard else ""
    vf = (
        f"[0:v]trim={a}:{b},setpts=(PTS-STARTPTS)/{sp},fps=30,split[a][b];"
        f"[a]crop=760:720:260:0,{dark}scale=w='1080*({punch})':h=-2:eval=frame,crop=1080:1022,setsar=1[fg];"
        f"[b]crop=1280:720:0:0,scale=-2:{H},crop={W}:{H},boxblur=24:2,eq=brightness=-0.12:saturation=0.85[bg];"
        f"[bg][fg]overlay=0:{FG_Y}:shortest=1,format=yuv420p[v]"
    )
    af = f"[0:a]atrim={a}:{b},asetpts=PTS-STARTPTS" + (",atempo=0.5" if sp != 1.0 else "") + \
        ",aresample=48000,aformat=channel_layouts=stereo,afade=t=in:d=0.03" + f",afade=t=out:st={dur - 0.04:.3f}:d=0.04[aud]"
    run(["ffmpeg", "-v", "error", "-y", "-i", REC, "-filter_complex", vf + ";" + af,
         "-map", "[v]", "-map", "[aud]", "-t", f"{dur:.3f}", "-c:v", "libx264", "-preset", "fast", "-crf", "18",
         "-c:a", "pcm_s16le", f"{OUT}/seg{i}.mkv"])
    return dur


durs = [seg(i, a, b, sp, i == len(SEGS) - 1) for i, (a, b, sp, _) in enumerate(SEGS)]
starts = [sum(durs[:i]) for i in range(len(durs))]
total = sum(durs)
print("segments", [round(d, 2) for d in durs], "total", round(total, 2))
with open(f"{OUT}/list.txt", "w") as f:
    for i in range(len(SEGS)):
        f.write(f"file 'seg{i}.mkv'\n")
run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", f"{OUT}/list.txt", "-c", "copy", f"{OUT}/joined.mkv"])


def ts(t):
    return f"{int(t // 3600)}:{int(t % 3600 // 60):02d}:{t % 60:05.2f}"


vo_t = []
events = []
prev_end = 0.0
for n, si, off, cap in VO:
    t = max(starts[si] + off, prev_end + 0.2)   # never talk over the previous line
    d = wav_len(f"{OUT}/vo_{n}.wav")
    prev_end = t + d
    vo_t.append((n, t))
    print(f"vo {n} {t:.2f}-{t + d:.2f}")
    # typewriter: letters appear over ~55% of the spoken line (karaoke with an invisible "not yet" colour)
    chars = list(cap.replace("\\N", "\n"))
    per = max(1, int(d * 55 / max(1, len(chars))))
    body = "".join(("\\N" if c == "\n" else f"{{\\k{per}}}{c}") for c in chars)
    events.append(("Robot", t, t + d + 0.35, "{\\fad(60,120)}" + body))

e0 = starts[-1]
# hook (first two shots), then the logo and a live kill / headshot counter
events.append(("Hook", 0, starts[2], r"{\fad(0,150)}POV: DAY 1 OF THE\NZOMBIE APOCALYPSE"))
events.append(("Logo", starts[2], e0, r"{\fad(150,0)}THEY LEARN"))
events.append(("Unit", 0, e0, "◉ NARRATOR UNIT  ·  SARCASM 90%"))
# game time shown at each video moment -> how many kills had happened by then
marks = []
for i, (a, b, sp, _) in enumerate(SEGS[:-1]):
    marks.append((starts[i], a))
    for g, _h in KILLS:
        if a <= g < b:
            marks.append((starts[i] + (g - a) / sp + 0.02, g + 0.001))
marks.sort()
def counts(g):
    return (sum(1 for kg, _h in KILLS if kg <= g), sum(1 for kg, h in KILLS if kg <= g and h))
last = None
for j, (vt, g) in enumerate(marks):
    if vt < starts[2] or counts(g) == last:
        continue
    last = counts(g)
    k, hs = last
    end = next((m[0] for m in marks[j + 1:] if counts(m[1]) != last), e0)
    pop = r"{\fscx130\fscy130\t(0,160,\fscx100\fscy100)}" if k > 0 else ""
    events.append(("Count", vt, min(end, e0), pop + f"KILLS {k}   {{\\c&H3C3CFF&}}HEADSHOTS {hs}"))
events.append(("Boss", starts[6] + 0.5, starts[9], r"{\fad(80,200)\fscx150\fscy150\t(0,200,\fscx100\fscy100)}BOSS FIGHT"))
events.append(("Title", e0 + 0.2, total, r"{\fad(250,0)\fscx140\fscy140\t(0,400,\fscx100\fscy100)}THEY LEARN"))
events.append(("Tag", e0 + 0.9, total, r"{\fad(300,0)}COMING SOON TO STEAM"))

ass = f"""[Script Info]
ScriptType: v4.00+
PlayResX: {W}
PlayResY: {H}
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Robot,DejaVu Sans Mono,58,&H00FFF2C8,&HFF000000,&H90000000,&H90000000,-1,0,0,0,100,100,1,0,3,18,0,8,70,70,1500,1
Style: Unit,DejaVu Sans Mono,34,&H00C8B478,&H00C8B478,&H00000000,&H00000000,-1,0,0,0,100,100,2,0,1,3,0,8,60,60,1474,1
Style: Hook,Bangers,112,&H00FFFFFF,&H00FFFFFF,&H00000000,&HA0000000,0,0,0,0,100,100,3,0,1,8,5,8,40,40,150,1
Style: Count,Bangers,84,&H00FFFFFF,&H00FFFFFF,&H00000000,&HA0000000,0,0,0,0,100,100,4,0,1,7,4,8,40,40,285,1
Style: Boss,Bangers,120,&H002A2AE0,&H002A2AE0,&H00000000,&HA0000000,0,0,0,0,100,100,6,0,1,8,6,8,40,40,500,1
Style: Logo,Bangers,150,&H002A2AE0,&H002A2AE0,&H00000000,&HA0000000,0,0,0,0,100,100,6,0,1,8,6,8,40,40,120,1
Style: Level,Bangers,72,&H00FFFFFF,&H00FFFFFF,&H00000000,&H90000000,0,0,0,0,100,100,4,0,1,6,3,8,40,40,290,1
Style: Title,Bangers,210,&H002A2AE0,&H00FFFFFF,&H00000000,&HA0000000,0,0,0,0,100,100,8,0,1,10,8,5,40,40,0,1
Style: Tag,Bangers,84,&H00FFFFFF,&H00FFFFFF,&H00000000,&H90000000,0,0,0,0,100,100,4,0,1,6,3,2,40,40,560,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
for st, a, b, txt in events:
    ass += f"Dialogue: 0,{ts(a)},{ts(b)},{st},,0,0,0,,{txt}\n"
open(f"{OUT}/caps.ass", "w").write(ass)

flashes = "+".join(f"between(t\\,{starts[i]:.3f}\\,{starts[i] + 0.07:.3f})" for i, s in enumerate(SEGS) if s[3])
vf = f"drawbox=x=0:y=0:w={W}:h={H}:color=white@0.8:t=fill:enable='{flashes}',subtitles={OUT}/caps.ass:fontsdir={FONTDIR}"

inputs = ["-i", f"{OUT}/joined.mkv", "-i", MUSIC]
for n, t in vo_t:
    inputs += ["-i", f"{OUT}/vo_{n}.wav"]
parts = [f"[{k + 2}:a]aresample=48000,aformat=channel_layouts=stereo,adelay={int(t * 1000)}|{int(t * 1000)},apad[v{k}]"
         for k, (n, t) in enumerate(vo_t)]
af = ";".join(parts) + ";"
af += "".join(f"[v{k}]" for k in range(len(vo_t))) + f"amix=inputs={len(vo_t)}:normalize=0,atrim=0:{total:.3f},volume=1.7,asplit[vo][key];"
af += f"[0:a]volume=0.75[game];[1:a]atrim=0:{total:.3f},volume=0.45,afade=t=out:st={total - 1.8:.3f}:d=1.8[mus];"
af += "[game][mus]amix=inputs=2:normalize=0[bed];[bed][key]sidechaincompress=threshold=0.04:ratio=7:attack=15:release=350[duck];"
af += "[duck][vo]amix=inputs=2:normalize=0,alimiter=limit=0.9[aout]"
run(["ffmpeg", "-v", "error", "-y", *inputs, "-filter_complex", f"[0:v]{vf}[vout];{af}",
     "-map", "[vout]", "-map", "[aout]", "-c:v", "libx264", "-preset", "medium", "-crf", "19", "-pix_fmt", "yuv420p",
     "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", "-t", f"{total:.3f}", f"{OUT}/they_learn_short_v3.mp4"])
print("done")
