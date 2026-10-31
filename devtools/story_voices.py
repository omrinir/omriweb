#!/usr/bin/env python3
# Step 2: run story_voices_master.py in the same folder (levels every line to about -18 dB mean like the level 1 scene).
# Story scene voices (levels 52, 54, 55, 57, 59, 60; pass scene ids as args to render only those): Kokoro TTS + pyworld processing + ffmpeg -> mono 44.1k mp3, ~-18 dB mean.
import os, subprocess, sys
import numpy as np, soundfile as sf, pyworld as pw
from kokoro_onnx import Kokoro

K = Kokoro("/tmp/claude-0/kok/model_q8.onnx", "/tmp/claude-0/kok/voices.npz")
OUT = "/home/claude/omriweb/shooter_game/sounds/story"
SR = 24000
TMP = os.environ.get("VO_TMP", "/home/claude/work/story")   # the wavs story_voices_master.py reads (run it in this folder)

# who: (voice, speed, pitch factor, whisper mix, tremble depth, extra ffmpeg filter)
STYLE = {
    "P": ("am_onyx", 0.95, 1.0, 0.30, 0.0, "highpass=f=70,acompressor=threshold=-18dB:ratio=3"),
    "Z": ("bm_lewis", 1.1, 0.88, 0.28, 0.0, "highpass=f=60,aecho=0.8:0.45:6:0.35,acompressor=threshold=-20dB:ratio=4"),
    "Q": ("am_michael", 1.0, 1.04, 0.55, 0.045, "highpass=f=90,lowpass=f=7000,acompressor=threshold=-20dB:ratio=3"),
    # THE CHORUS (57): the hive speaks with many voices at once - see CHORUS below
    "C": ("bm_lewis", 0.9, 0.8, 0.5, 0.0, "highpass=f=60,aecho=0.8:0.6:40|90:0.4|0.25,acompressor=threshold=-20dB:ratio=4"),
    # ECHO FILE (60): the lab terminal reads the file - flat recorded female voice through a small speaker (MONO below)
    "T": ("af_sarah", 0.92, 0.97, 0.08, 0.0, "highpass=f=260,lowpass=f=4600,acrusher=bits=12:mode=log:aa=1,aecho=0.7:0.35:14:0.3,acompressor=threshold=-20dB:ratio=4"),
    # THE HIVE (62): the hive speaks in ONE voice for the first time - see ONE below (unison: every layer sings the lead's pitch)
    "H": ("bm_lewis", 0.86, 0.84, 0.22, 0.0, "highpass=f=55,aecho=0.8:0.55:120|260:0.3|0.18,acompressor=threshold=-20dB:ratio=4"),
    # WE (63, JOIN ending): the hero's own voice with the hive's ONE voice under it - see US below
    "U": ("am_onyx", 0.9, 0.97, 0.2, 0.0, "highpass=f=60,aecho=0.8:0.5:90|200:0.25|0.15,acompressor=threshold=-20dB:ratio=4"),
}
# one voice (62): (voice, gain, whisper mix). Every layer is time-matched to the lead and forced onto the lead's pitch contour,
# so it sounds like one calm voice made of many throats - not a chorus
ONE = [("bm_lewis", 1.0, 0.22), ("af_bella", 0.55, 0.3), ("am_michael", 0.6, 0.35), ("bf_emma", 0.4, 0.45)]
# we (63): the hero leads, the hive follows on his pitch, quieter (he joined it - it did not swallow him)
US = [("am_onyx", 1.0, 0.2), ("bm_lewis", 0.5, 0.3), ("af_bella", 0.32, 0.35), ("am_michael", 0.38, 0.4)]
# chorus layers: (voice, pitch factor, delay s, gain, whisper mix)
CHORUS = [("bm_lewis", 0.78, 0.0, 1.0, 0.35), ("am_michael", 0.9, 0.035, 0.8, 0.5),
          ("af_bella", 1.0, 0.06, 0.55, 0.6), ("bm_george", 0.7, 0.09, 0.7, 0.7), ("af_nicole", 1.12, 0.12, 0.35, 0.9)]
MONO = {"T": 0.12}   # f0 flattened toward the line's median (0 = flat, 1 = natural): a recorded / synthetic monotone

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
    "l59_stranger": {"P": "P", "Z": "Z", "lines": [
        ("Z", "z01", "This is my last visit. Where you're going, I can't follow."),
        ("P", "p01", "Then answer me. What did you do to me?"),
        ("Z", "z02", "I did it. I took your memory. LETHE was mine."),
        ("Z", "z03", "You were the first voice. If you went home... there would be no one left who isn't them."),
        ("P", "p02", "Home. That's what they keep calling it."),
        ("Z", "z04", "The Glacier Lab. It started there. And it wants you back."),
        ("Z", "z05", "A linked mind can't follow you. Goodbye, Zero."),
    ]},
    "l60_file": {"P": "P", "T": "T", "C": "C", "lines": [
        ("P", "p01", "Project Echo... This file has my face on it."),
        ("T", "t01", "Subject Zero. Pattern: original, unmutated."),
        ("T", "t02", "Status: Lethe administered."),
        ("T", "t03", "If the network reclaims him, every mind becomes one. Do not let him go home."),
        ("P", "p02", "Home...? This is where I came from."),
        ("C", "c01", "Welcome home."),
    ]},
    "l62_hive": {"P": "P", "H": "H", "lines": [
        ("H", "h01", "Zero. You came down to us."),
        ("P", "p01", "Who's there? Show yourself."),
        ("H", "h02", "There is no one here. There is only us. One voice, now."),
        ("P", "p02", "Then talk. Why me? Why all of this?"),
        ("H", "h03", "We were made to learn you."),
        ("H", "h04", "Every one you killed was a lesson. Every lesson came home."),
        ("P", "p03", "So I taught you how to kill me."),
        ("H", "h05", "We do not hate you. You are our teacher."),
        ("H", "h06", "We are not learning to beat you, Zero. We are learning to be you."),
        ("P", "p04", "Seven soldiers. One man's pattern. That was the project."),
        ("H", "h07", "And the root still needs the first. Come down to the heart. Finish the lesson."),
        ("P", "p05", "I'll finish it. My way."),
    ]},
    "l63_ending": {"P": "P", "H": "H", "U": "U", "lines": [
        ("H", "h01", "Zero. You came all the way home."),
        ("P", "p01", "You're still talking."),
        ("H", "h02", "Every lesson you gave us is in here. Every road. Every face you burned. We kept them all."),
        ("H", "h03", "But you are the one lesson we never learned. You forgot. So you are free."),
        ("H", "h04", "Come inside, and you will remember everything. Your name. The six. No one is ever alone again."),
        ("P", "p02", "And every mind becomes one."),
        ("H", "h05", "Yes. Or end it. You are the only one who can."),
        ("P", "p03", "You learned how I fight. You never learned why."),
        ("H", "h06", "Then teach us. One last time."),
        ("P", "p04", "This is the last lesson."),
        ("P", "p05", "The spores went quiet. All of them, at once."),
        ("P", "p06", "No more lessons. Nobody left to learn me."),
        ("P", "p07", "I still don't remember my name. But whatever I am... it's mine."),
        ("P", "p08", "I'm tired of fighting myself."),
        ("H", "h07", "Then stop. Come home, Zero."),
        ("U", "u01", "I remember now. The lab. The six. All of it."),
        ("U", "u02", "We are home."),
        ("U", "u03", "No more lessons. Now we just... know."),
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


def render_one(text, style="H", layers=None):
    layers = ONE if layers is None else layers
    voice, speed, pitch, _, _, _ = STYLE[style]
    lead, sr = K.create(text, voice=voice, speed=speed, lang="en-us")
    lx = lead.astype(np.float64)
    lf0, lt = pw.harvest(lx, sr)
    lf0 = lf0 * pitch
    y = np.zeros(len(lx) + sr)
    for v, gain, wmix in layers:
        a, sr2 = K.create(text, voice=v, speed=speed, lang="en-us")
        if v != voice:   # same length as the lead (second pass with a corrected speed)
            a, sr2 = K.create(text, voice=v, speed=speed * len(a) / len(lead), lang="en-us")
        x = a.astype(np.float64)
        f0, t = pw.harvest(x, sr2)
        sp = pw.cheaptrick(x, f0, t, sr2)
        ap = pw.d4c(x, f0, t, sr2)
        nf = np.interp(np.linspace(0, 1, len(f0)), np.linspace(0, 1, len(lf0)), lf0)
        nf[(f0 <= 0) | (nf < 40)] = 0.0   # unvoiced where either one is unvoiced
        voiced = pw.synthesize(nf, sp, ap, sr2)
        whisper = pw.synthesize(nf, sp, np.ones_like(ap), sr2)
        n = min(len(voiced), len(whisper))
        p = (1 - wmix) * voiced[:n] + wmix * whisper[:n] * 1.6
        p = p / (np.abs(p).max() + 1e-9) * gain
        m = min(len(p), len(y))
        y[:m] += p[:m]
    y = np.trim_zeros(y, "b")
    y = np.concatenate([np.zeros(int(0.05 * sr)), y, np.zeros(int(0.5 * sr))])
    return y / (np.abs(y).max() + 1e-9) * 0.9, sr


def render(text, style):
    if style == "C":
        return render_chorus(text)
    if style == "H":
        return render_one(text)
    if style == "U":
        return render_one(text, "U", US)
    voice, speed, pitch, wmix, trem, _ = STYLE[style]
    a, sr = K.create(text, voice=voice, speed=speed, lang="en-us")
    x = a.astype(np.float64)
    f0, t = pw.harvest(x, sr)
    sp = pw.cheaptrick(x, f0, t, sr)
    ap = pw.d4c(x, f0, t, sr)
    f0 = f0 * pitch
    if trem > 0:   # scared tremble: slow wobble on the pitch
        f0 = f0 * (1 + trem * np.sin(2 * np.pi * 5.5 * t))
    if style in MONO:   # monotone: squash the melody toward the median pitch
        v = f0 > 0
        if v.any():
            med = np.median(f0[v])
            f0[v] = med * (f0[v] / med) ** MONO[style]
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
        if os.environ.get("VO_ONLY") and name not in os.environ["VO_ONLY"].split(","):   # VO_ONLY=u01,u02: only these lines
            continue
        style = d[who]
        y, sr = render(text, style)
        tmp = f"{TMP}/{scene}_{name}.wav"
        sf.write(tmp, y, sr)
        flt = STYLE[style][5] + ",loudnorm=I=-16:TP=-2:LRA=7"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", tmp, "-af", flt, "-ar", "44100", "-ac", "1",
                        "-b:a", "64k", f"{OUT}/{scene}/{name}.mp3"], check=True)
        print(scene, name, round(len(y) / sr, 2))
