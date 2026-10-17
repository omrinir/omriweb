#!/usr/bin/env python3
# Builds the vertical promo Short (1080x1920, 30fps) from the recorded gameplay clips.
import subprocess, os

REC = "/tmp/claude-0/rec"
OUT = "/tmp/claude-0/short"
FONTDIR = "/home/claude/omriweb/shooter_game/fonts"
MUSIC = "/home/claude/omriweb/shooter_game/music/level1_total_war.mp3"
W, H = 1080, 1920
FG_Y = 420

# (clip, start, end, speed)  speed 0.5 = slow motion
SEGS = [
    ("a12", 2.2, 4.2, 1.0),
    ("a12", 4.2, 5.0, 0.5),   # black hole collapse in slow motion
    ("b02", 8.5, 13.0, 1.0),
    ("c24", 8.0, 12.8, 1.0),
    ("d47", 10.0, 14.6, 1.0),
    ("c24", 13.0, 16.0, 1.0),
    ("d47", 14.0, 16.0, 0.5),  # end card background
]


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stderr[-3000:])
        raise SystemExit(1)


def seg(i, clip, a, b, sp, endcard):
    dur = (b - a) / sp
    # punch-in zoom at the start of each cut (not inside the slow-mo continuation / end card)
    punch = "1+0.10*max(0\\,1-t/0.35)" if (sp == 1.0 and not endcard) else "1"
    dark = "eq=brightness=-0.32:saturation=0.6,boxblur=5:1," if endcard else ""
    vf = (
        f"[0:v]trim={a}:{b},setpts=(PTS-STARTPTS)/{sp},fps=30,split[a][b];"
        f"[a]crop=760:720:260:0,{dark}scale=w='1080*({punch})':h=-2:eval=frame,crop=1080:1022,setsar=1[fg];"
        f"[b]crop=1280:720:0:0,scale=-2:{H},crop={W}:{H},boxblur=24:2,eq=brightness=-0.13:saturation=0.85[bg];"
        f"[bg][fg]overlay=0:{FG_Y}:shortest=1,format=yuv420p[v]"
    )
    af = f"[0:a]atrim={a}:{b},asetpts=PTS-STARTPTS" + (",atempo=0.5" if sp != 1.0 else "") + ",aresample=48000,aformat=channel_layouts=stereo[aud]"
    run(["ffmpeg", "-v", "error", "-y", "-i", f"{REC}/{clip}.avi", "-filter_complex", vf + ";" + af,
         "-map", "[v]", "-map", "[aud]", "-t", f"{dur:.3f}", "-c:v", "libx264", "-preset", "fast", "-crf", "18",
         "-c:a", "pcm_s16le", f"{OUT}/seg{i}.mkv"])
    return dur


durs = [seg(i, *s, i == len(SEGS) - 1) for i, s in enumerate(SEGS)]
starts = [sum(durs[:i]) for i in range(len(durs))]
total = sum(durs)
print("segments", [round(d, 2) for d in durs], "total", round(total, 2))

with open(f"{OUT}/list.txt", "w") as f:
    for i in range(len(SEGS)):
        f.write(f"file 'seg{i}.mkv'\n")
run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", f"{OUT}/list.txt", "-c", "copy", f"{OUT}/joined.mkv"])


# ---------- captions (ASS, Bangers font) ----------
def ts(t):
    h = int(t // 3600); m = int(t % 3600 // 60); s = t % 60
    return f"{h}:{m:02d}:{s:05.2f}"


POP = r"{\fscx60\fscy60\t(0,120,\fscx112\fscy112)\t(120,220,\fscx100\fscy100)}"
cut = starts  # cut times
VO = [  # (line no, start time, subtitle text)
    (1, 0.35, "DAY 51."),
    (2, 1.9, "THE DEAD DIDN'T JUST {\\c&H00D7FF&}RISE."),
    (3, 4.9, "THEY {\\c&H00D7FF&}LEARNED."),
    (4, 6.6, "TO CLIMB. TO HUNT IN {\\c&H00D7FF&}PACKS."),
    (5, 10.4, "TO WEAR {\\c&H3030FF&}OUR FACES."),
    (6, 14.2, "BUT SO DID {\\c&H00D7FF&}WE."),
    (7, starts[-1] + 0.5, ""),
]
import wave
def wav_len(p):
    with wave.open(p) as w:
        return w.getnframes() / w.getframerate()

events = []
for n, t, txt in VO:
    d = wav_len(f"{OUT}/vo_{n}.wav")
    if txt:
        events.append(("Sub", t, t + d + 0.25, POP + txt))
# headline above the gameplay, one per cut
HEAD = [
    (cut[0], cut[2], "ONE GRENADE.\\N{\\c&HFFB070&}ONE BLACK HOLE."),
    (cut[2], cut[3], "51 LEVELS"),
    (cut[3], cut[4], "160+ KINDS OF ZOMBIES"),
    (cut[4], cut[5], "THEY ADAPT TO YOU"),
    (cut[5], cut[6], "HOW LONG CAN YOU LAST?"),
]
for a, b, txt in HEAD:
    events.append(("Head", a, b, POP + txt))
# end card
e0 = starts[-1]
events.append(("Title", e0 + 0.3, total, r"{\fad(250,0)\fscx140\fscy140\t(0,400,\fscx100\fscy100)}THEY LEARN"))
events.append(("Tag", e0 + 1.1, total, r"{\fad(300,0)}COMING SOON TO STEAM"))

ass = f"""[Script Info]
ScriptType: v4.00+
PlayResX: {W}
PlayResY: {H}
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Sub,Bangers,96,&H00FFFFFF,&H00FFFFFF,&H00000000,&H90000000,0,0,0,0,100,100,2,0,1,7,4,2,60,60,300,1
Style: Head,Bangers,112,&H00FFFFFF,&H00FFFFFF,&H00101010,&H90000000,0,0,0,0,100,100,3,-3,1,8,5,8,50,50,190,1
Style: Title,Bangers,210,&H002A2AE0,&H00FFFFFF,&H00000000,&HA0000000,0,0,0,0,100,100,8,0,1,10,8,5,40,40,0,1
Style: Tag,Bangers,84,&H00FFFFFF,&H00FFFFFF,&H00000000,&H90000000,0,0,0,0,100,100,4,0,1,6,3,2,40,40,560,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
for st, a, b, txt in events:
    ass += f"Dialogue: 0,{ts(a)},{ts(b)},{st},,0,0,0,,{txt}\n"
open(f"{OUT}/caps.ass", "w").write(ass)

# white flash on every hard cut (2 frames), skipping the slow-mo continuation
flashes = "+".join(f"between(t\\,{c:.3f}\\,{c + 0.07:.3f})" for i, c in enumerate(cut) if i not in (0, 1))
vf = f"drawbox=x=0:y=0:w={W}:h={H}:color=white@0.85:t=fill:enable='{flashes}',subtitles={OUT}/caps.ass:fontsdir={FONTDIR}"

# ---------- audio: game sound + music bed + narrator (ducks the rest) ----------
inputs = ["-i", f"{OUT}/joined.mkv", "-ss", "0", "-i", MUSIC]
for n, t, _ in VO:
    inputs += ["-i", f"{OUT}/vo_{n}.wav"]
vo_parts = []
for k, (n, t, _) in enumerate(VO):
    vo_parts.append(f"[{k + 2}:a]aresample=48000,aformat=channel_layouts=stereo,adelay={int(t * 1000)}|{int(t * 1000)},apad[v{k}]")
af = ";".join(vo_parts) + ";"
af += "".join(f"[v{k}]" for k in range(len(VO))) + f"amix=inputs={len(VO)}:normalize=0,atrim=0:{total:.3f},volume=1.6,asplit[vo][key];"
af += f"[0:a]volume=0.55[game];[1:a]atrim=0:{total:.3f},volume=0.33,afade=t=out:st={total - 1.5:.3f}:d=1.5[mus];"
af += "[game][mus]amix=inputs=2:normalize=0[bed];[bed][key]sidechaincompress=threshold=0.05:ratio=6:attack=20:release=300[duck];"
af += "[duck][vo]amix=inputs=2:normalize=0,alimiter=limit=0.9[aout]"
run(["ffmpeg", "-v", "error", "-y", *inputs, "-filter_complex", f"[0:v]{vf}[vout];{af}",
     "-map", "[vout]", "-map", "[aout]", "-c:v", "libx264", "-preset", "medium", "-crf", "19", "-pix_fmt", "yuv420p",
     "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", "-t", f"{total:.3f}", f"{OUT}/they_learn_short.mp4"])
print("done", f"{OUT}/they_learn_short.mp4")
