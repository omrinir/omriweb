#!/usr/bin/env python3
# Level 2 Short built for retention: follow-cam crop on the player (from REC_POS csv), punch-zoom + shake + flash
# on every kill, speed ramps, ASS captions, music + narrator. Source: 2560x1440 recording at 60fps.
import json, math, os, random, subprocess, sys, wave
import numpy as np
from PIL import Image, ImageFilter, ImageEnhance

REC = "/tmp/claude-0/rec/l2.mkv"
POS = "/tmp/claude-0/rec/l2_pos.csv"
LOG = "/tmp/claude-0/rec/l2.log"
OUT = "/tmp/claude-0/short6"
FONTDIR = "/home/claude/omriweb/shooter_game/fonts"
MUSIC = "/home/claude/omriweb/shooter_game/music/level1_total_war.mp3"
SW, SH = 2560, 1440          # source frame
W, H, FPS = 1080, 1920, 30   # output
FW, FH, FY = 1080, 1350, 300  # gameplay window (4:5) inside the 9:16 frame
SCALE = SW / 1280.0          # REC_POS is in 1280x720 viewport space
SHOTS = json.load(open(f"{OUT}/shots.json"))   # [{"a":, "b":, "speed":, "zoom":, "dy":, "dx":}]
random.seed(7)

# ---------- player track (smoothed, so the camera glides) ----------
track = {}
for ln in open(POS):
    t, x, y = ln.strip().split(",")
    track[round(float(t) * 60)] = (float(x) * SCALE, float(y) * SCALE)
nmax = max(track)
xs = np.array([track.get(i, (SW / 2, SH * 0.6))[0] for i in range(nmax + 1)])
ys = np.array([track.get(i, (SW / 2, SH * 0.6))[1] for i in range(nmax + 1)])
k = np.exp(-0.5 * (np.arange(-30, 31) / 12.0) ** 2); k /= k.sum()     # ~0.2 s gaussian
xs = np.convolve(np.pad(xs, 30, mode="edge"), k, mode="valid")
ys = np.convolve(np.pad(ys, 30, mode="edge"), k, mode="valid")

kills = []
for ln in open(LOG):
    if ln.startswith("EV") and " kill " in ln:
        kills.append(float(ln.split("t=")[1].split()[0]))

# ---------- timeline ----------
starts, t = [], 0.0
for s in SHOTS:
    starts.append(t)
    t += (s["b"] - s["a"]) / s["speed"]
TOTAL = t
impacts = []   # only the big moments listed per shot ("hits"): explosions, multi-kills, the boss
for s, st in zip(SHOTS, starts):
    for g in s.get("hits", []):
        impacts.append(st + (g - s["a"]) / s["speed"])
impacts.sort()
json.dump({"starts": starts, "total": TOTAL, "impacts": impacts}, open(f"{OUT}/timeline.json", "w"))
print("total", round(TOTAL, 2), "impacts", len(impacts))


def zoom_at(s, u):
    keys = s.get("zk")
    if not keys:
        return s.get("zoom", 1.0)
    if u <= keys[0][0]:
        return keys[0][1]
    for (u0, z0), (u1, z1) in zip(keys, keys[1:]):
        if u <= u1:
            k = (u - u0) / max(1e-6, u1 - u0)
            k = k * k * (3 - 2 * k)   # smoothstep: eases in and out
            return z0 + (z1 - z0) * k
    return keys[-1][1]


def frames(a, b):
    """yield (game_time, rgb array) for source frames between a and b"""
    p = subprocess.Popen(["ffmpeg", "-v", "error", "-ss", f"{a:.3f}", "-i", REC, "-t", f"{b - a + 0.05:.3f}",
                          "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
    n = SW * SH * 3
    i = 0
    while True:
        buf = p.stdout.read(n)
        if len(buf) < n:
            break
        yield a + i / 60.0, np.frombuffer(buf, np.uint8).reshape(SH, SW, 3)
        i += 1
    p.wait()


enc = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}",
                        "-r", str(FPS), "-i", "-", "-c:v", "libx264", "-preset", "medium", "-crf", "18",
                        "-pix_fmt", "yuv420p", f"{OUT}/video_only.mp4"], stdin=subprocess.PIPE)
for si, (s, st) in enumerate(zip(SHOTS, starts)):
    nout = round((s["b"] - s["a"]) / s["speed"] * FPS)
    src = frames(s["a"], s["b"])
    cur_t, cur = next(src)
    for j in range(nout):
        T = st + j / FPS
        g = s["a"] + j / FPS * s["speed"]
        while cur_t + 1 / 120.0 < g:
            try:
                cur_t, cur = next(src)
            except StopIteration:
                break
        fi = min(int(round(g * 60)), len(xs) - 1)
        # zoom: shot zoom, a slow push-in, and a punch on every impact
        z = zoom_at(s, j / FPS)
        shake = 0.0
        flash = 0.0
        for it in impacts:
            d = T - it
            if 0 <= d < 0.6:
                z *= 1.0 + 0.07 * math.exp(-d / 0.12)
                shake = max(shake, 14.0 * math.exp(-d / 0.08))
                if d < 1.5 / FPS:
                    flash = max(flash, 0.55)
        if j < 2 and si > 0 and s.get("flash_in", False):
            flash = max(flash, 0.35 * (1 - j / 2))
        ch = SH / z
        cw = ch * FW / FH
        cx = xs[fi] + s.get("dx", 0) * SCALE + random.uniform(-shake, shake)
        cy = ys[fi] + s.get("dy", -60) * SCALE + random.uniform(-shake, shake)
        cx = min(max(cx, cw / 2), SW - cw / 2)
        cy = min(max(cy, ch / 2), SH - ch / 2)
        full = Image.fromarray(cur)
        fg = full.crop((int(cx - cw / 2), int(cy - ch / 2), int(cx + cw / 2), int(cy + ch / 2))).resize((FW, FH), Image.BICUBIC)
        # background: same moment, wider, blurred and darkened, so the frame is never empty
        bw = SH * 9 / 16
        bx = min(max(cx, bw / 2), SW - bw / 2)
        bg = full.crop((int(bx - bw / 2), 0, int(bx + bw / 2), SH)).resize((108, 192), Image.BILINEAR)
        bg = bg.filter(ImageFilter.GaussianBlur(3)).resize((W, H), Image.BILINEAR)
        bg = ImageEnhance.Brightness(bg).enhance(0.45)
        bg.paste(fg, (0, FY))
        arr = np.asarray(bg, dtype=np.float32)
        if flash > 0:
            arr = arr * (1 - flash) + 255 * flash
        enc.stdin.write(arr.clip(0, 255).astype(np.uint8).tobytes())
    print("shot", si, "done", nout, "frames")
enc.stdin.close()
enc.wait()

# ---------- audio: game sound per shot (with the same speed ramps) ----------
parts, labels = [], []
for i, s in enumerate(SHOTS):
    tempo = ""
    sp = s["speed"]
    while sp < 0.5:
        tempo += ",atempo=0.5"
        sp /= 0.5
    if abs(sp - 1.0) > 1e-3:
        tempo += f",atempo={sp:.4f}"
    d = (s["b"] - s["a"]) / s["speed"]
    parts.append(f"[0:a]atrim={s['a']:.3f}:{s['b']:.3f},asetpts=PTS-STARTPTS{tempo},aresample=48000,"
                 f"aformat=channel_layouts=stereo,apad,atrim=0:{d:.4f},afade=t=in:d=0.02,afade=t=out:st={max(0, d - 0.03):.4f}:d=0.03[g{i}]")
    labels.append(f"[g{i}]")
fc = ";".join(parts) + ";" + "".join(labels) + f"concat=n={len(SHOTS)}:v=0:a=1[game]"
subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", REC, "-filter_complex", fc, "-map", "[game]", "-c:a", "pcm_s16le",
                f"{OUT}/game_audio.wav"], check=True)
print("video + game audio ready")
