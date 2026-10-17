#!/usr/bin/env python3
# Step 2: run story_voices_master.py in the same folder (levels every line to about -18 dB mean like the level 1 scene).
# Story scene voices (levels 52, 54, 55, 57; pass scene ids as args to render only those): Kokoro TTS + pyworld processing + ffmpeg -> mono 44.1k mp3, ~-18 dB mean.
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
    # THE CHORUS (57): the hive speaks with many voices at once - see CHORUS below
    "C": ("bm_lewis", 0.9, 0.8, 0.5, 0.0, "highpass=f=60,aecho=0.8:0.6:40|90:0.4|0.25,acompressor=threshold=-20dB:ratio=4"),
}
# chorus layers: (voice, pitch factor, delay s, gain, whisper mix)
CHORUS = [("bm_lewis", 0.78, 0.0, 1.0, 0.35), ("am_michael", 0.9, 0.035, 0.8, 0.5),
          ("af_bella", 1.0, 0.06, 0.55, 0.6), ("bm_george", 0.7, 0.09, 0.7, 0.7), ("af_nicole", 1.12, 0.12, 0.35, 0.9)]

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
    "l55_stranger": {"P": "P", "Z": "Z", "lines": [
        ("Z", "z01", "Their shepherd is dead. Did you think that would stop them?"),
        ("P", "p01", "It stopped them at the bridge."),
        ("Z", "z02", "For an hour. Then they remembered."),
        ("P", "p02", "Remembered what?"),
        ("Z", "z03", "Every one you kill... breathes out what it saw."),
        ("Z", "z04", "The others breathe it in. That's how they learn."),
        ("P", "p03", "So every kill makes them smarter."),
        ("Z", "z05", "You're the best teacher they ever had."),
        ("P", "p04", "Then I'll end the lesson."),
        ("Z", "z06", "South. The glacier. Where it began."),
    ]},
    "l57_chorus": {"P": "P", "C": "C", "lines": [
        ("C", "c01", "We... remember... you."),
        ("P", "p01", "Who's talking?"),
        ("C", "c02", "All of us. Every one you killed. We kept them."),
        ("P", "p02", "You're a flock of birds."),
        ("C", "c03", "Bodies break. So we learned to be many."),
        ("P", "p03", "What do you want from me?"),
        ("C", "c04", "You were the first voice. Subject Zero."),
        ("C", "c05", "We don't want to eat you. We want you to come home."),
        ("P", "p04", "I'm not one of you."),
        ("C", "c06", "You will remember."),
    ]},
}


def world(a, sr, pitch, wmix, trem=0.0):
    x = a.astype(np.float64)
    f0, t = pw.harvest(x, sr)
    sp = pw.cheaptrick(x, f0, t, sr)
    ap = pw.d4c(x, f0, t, sr)
    f0 = f0 * pitch
    if trem > 0:
        f0 = f0 * (1 + trem * np.sin(2 * np.pi * 5.5 * t))
    voiced = pw.synthesize(f0, sp, ap, sr)
    whisper = pw.synthesize(f0, sp, np.ones_like(ap), sr)
    n = min(len(voiced), len(whisper))
    return (1 - wmix) * voiced[:n] + wmix * whisper[:n] * 1.6


def render_chorus(text):
    speed = STYLE["C"][1]
    parts = []
    for voice, pitch, delay, gain, wmix in CHORUS:
        a, sr = K.create(text, voice=voice, speed=speed, lang="en-us")
        parts.append((np.concatenate([np.zeros(int(delay * sr)), world(a, sr, pitch, wmix)]) * gain, sr))
    sr = parts[0][1]
    n = max(len(p) for p, _ in parts)
    y = np.zeros(n)
    for p, _ in parts:
        y[:len(p)] += p / (np.abs(p).max() + 1e-9)
    y = np.concatenate([np.zeros(int(0.05 * sr)), y, np.zeros(int(0.4 * sr))])
    return y / (np.abs(y).max() + 1e-9) * 0.9, sr


def render(text, style):
    if style == "C":
        return render_chorus(text)
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
    if len(sys.argv) > 1 and scene not in sys.argv[1:]:
        continue
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
