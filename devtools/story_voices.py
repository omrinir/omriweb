#!/usr/bin/env python3
# Step 2: run story_voices_master.py in the same folder (levels every line to about -18 dB mean like the level 1 scene).
# Story scene voices (levels 52 + 54): Kokoro TTS + pyworld processing + ffmpeg -> mono 44.1k mp3, ~-18 dB mean.
import os, subprocess, sys
import numpy as np, soundfile as sf, pyworld as pw
from kokoro_onnx import Kokoro

K = Kokoro("/tmp/claude-0/kok/model_q8.onnx", "/tmp/claude-0/kok/voices.npz")
OUT = "/home/claude/omriweb/shooter_game/sounds/story"
SR = 24000

# who: (voice, speed, pitch factor, whisper mix, tremble depth, extra ffmpeg filter)
STYLE = {
    "P": ("am_onyx", 0.95, 1.0, 0.30, 0.0, "highpass=f=70,acompressor=threshold=-18dB:ratio=3"),
    "Z": ("bm_lewis", 1.1, 0.88, 0.28, 0.0, "highpass=f=60,aecho=0.8:0.45:6:0.35,acompressor=threshold=-20dB:ratio=4"),
    "Q": ("am_michael", 1.0, 1.04, 0.55, 0.045, "highpass=f=90,lowpass=f=7000,acompressor=threshold=-20dB:ratio=3"),
}

SCENES = {
    "l52_quisling": {"P": "P", "Z": "Q", "lines": [
        ("Z", "z01", "Don't shoot. Please. I'm alive."),
        ("P", "p01", "You're wearing a dead man's face."),
        ("Z", "z02", "They don't eat their own. So I became one of them."),
        ("P", "p02", "Where are they going?"),
        ("Z", "z03", "South. Every train. Every road."),
        ("P", "p03", "The dead don't make plans."),
        ("Z", "z04", "These ones do. Someone thinks for them now."),
        ("P", "p04", "Who?"),
        ("Z", "z05", "The Architect. And he knows your name."),
    ]},
    "l54_stranger": {"P": "P", "Z": "Z", "lines": [
        ("Z", "z01", "You came to burn the bridge."),
        ("P", "p01", "You again. Whose side are you on?"),
        ("Z", "z02", "There are no sides. Only the plan."),
        ("P", "p02", "Then I'll kill the one who made it."),
        ("Z", "z03", "He's waiting for you. He always was."),
        ("P", "p03", "Why me?"),
        ("Z", "z04", "Because you're the only one of us... who forgot."),
        ("P", "p04", "...Of us?"),
        ("Z", "z05", "Cross the bridge. Remember."),
    ]},
}


def render(text, style):
    voice, speed, pitch, wmix, trem, _ = STYLE[style]
    a, sr = K.create(text, voice=voice, speed=speed, lang="en-us")
    x = a.astype(np.float64)
    f0, t = pw.harvest(x, sr)
    sp = pw.cheaptrick(x, f0, t, sr)
    ap = pw.d4c(x, f0, t, sr)
    f0 = f0 * pitch
    if trem > 0:   # scared tremble: slow wobble on the pitch
        f0 = f0 * (1 + trem * np.sin(2 * np.pi * 5.5 * t))
    voiced = pw.synthesize(f0, sp, ap, sr)
    whisper = pw.synthesize(f0, sp, np.ones_like(ap), sr)   # all-noise excitation = whisper
    n = min(len(voiced), len(whisper))
    y = (1 - wmix) * voiced[:n] + wmix * whisper[:n] * 1.6
    y = np.concatenate([np.zeros(int(0.05 * sr)), y, np.zeros(int(0.15 * sr))])
    return y / (np.abs(y).max() + 1e-9) * 0.9, sr


for scene, d in SCENES.items():
    os.makedirs(f"{OUT}/{scene}", exist_ok=True)
    for who, name, text in d["lines"]:
        style = d[who]
        y, sr = render(text, style)
        tmp = f"/home/claude/work/story/{scene}_{name}.wav"
        sf.write(tmp, y, sr)
        flt = STYLE[style][5] + ",loudnorm=I=-16:TP=-2:LRA=7"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", tmp, "-af", flt, "-ar", "44100", "-ac", "1",
                        "-b:a", "64k", f"{OUT}/{scene}/{name}.mp3"], check=True)
        print(scene, name, round(len(y) / sr, 2))
