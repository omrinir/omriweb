# captions + music over the follow-cam render -> final level 2 Short
import json, subprocess
OUT = "/tmp/claude-0/short5"
FONTDIR = "/home/claude/omriweb/shooter_game/fonts"
MUSIC = "/home/claude/omriweb/shooter_game/music/level1_total_war.mp3"
tl = json.load(open(f"{OUT}/timeline.json"))
st, total = tl["starts"], tl["total"]
def ts(t):
    return f"0:{int(t // 60):02d}:{t % 60:05.2f}"
POP = r"{\fscx70\fscy70\t(0,110,\fscx108\fscy108)\t(110,200,\fscx100\fscy100)}"
Y = r"{\c&H00D7FF&}"
R = r"{\c&H3C3CFF&}"
W_ = r"{\c&HFFFFFF&}"
ev = [
    ("Top", 0.0, st[1], "LEVEL 2 ZOMBIES LEARNED\\N" + Y + "TO HUNT IN PACKS"),
    ("Top", st[1], st[4], POP + R + "BAD IDEA."),
    ("Top", st[4], st[4] + 0.75, POP + "THE BOSS LEARNED\\N" + Y + "TO BLOCK BULLETS"),
    ("Top", st[4] + 0.75, st[5], POP + "SO I SHOT HIS " + Y + "BACK"),
    ("Top", st[5], st[6], POP + R + "GHOST TRAIN" + W_ + " INCOMING"),
    ("Top", st[6], total, POP + R + "THEY LEARN"),
    ("Bot", 0.0, total, "THEY LEARN  ·  COMING TO STEAM"),
]
ass = f"""[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Top,Bangers,104,&H00FFFFFF,&H00FFFFFF,&H00000000,&HA0000000,0,0,0,0,100,100,3,0,1,8,5,8,40,40,40,1
Style: Bot,Bangers,56,&H00C8C8C8,&H00C8C8C8,&H00000000,&H90000000,0,0,0,0,100,100,4,0,1,4,2,2,40,40,150,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
for s, a, b, t in ev:
    ass += f"Dialogue: 0,{ts(a)},{ts(b)},{s},,0,0,0,,{t}\n"
open(f"{OUT}/caps.ass", "w").write(ass)
af = (f"[1:a]volume=1.0[game];[2:a]atrim=0:{total:.3f},volume=0.32[mus];"
      "[game][mus]amix=inputs=2:normalize=0,alimiter=limit=0.92,loudnorm=I=-14:TP=-1.0[aout]")
subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", f"{OUT}/video_only.mp4", "-i", f"{OUT}/game_audio.wav", "-i", MUSIC,
                "-filter_complex", f"[0:v]subtitles={OUT}/caps.ass:fontsdir={FONTDIR}[v];{af}",
                "-map", "[v]", "-map", "[aout]", "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p",
                "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", "-t", f"{total:.3f}", f"{OUT}/they_learn_l2_short.mp4"], check=True)
print("done", total)
