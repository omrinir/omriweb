# 5 natural voiceovers with Kokoro-82M (q8 ONNX), lightly mastered for social video.
import subprocess, numpy as np, soundfile as sf
from kokoro_onnx import Kokoro
k = Kokoro('/tmp/claude-0/kok/model_q8.onnx', '/tmp/claude-0/kok/voices.npz')
TAKES = [
    ("am_onyx", 0.92, "deep_trailer",
     "They climb. They hide. They hunt in packs... And every level, they get smarter. This is the new game. They Learn. Coming soon to Steam."),
    ("bm_george", 0.95, "british_storyteller",
     "The dead didn't just rise. They learned. They Learn... the brand new zombie shooter. Coming soon, on Steam."),
    ("am_michael", 1.0, "warm_narrator",
     "You've survived zombies before. Not like these. These ones learn. They Learn. Soon on Steam."),
    ("am_fenrir", 0.98, "gritty_action",
     "Fifty one levels. Over a hundred and sixty kinds of zombies. One rule. Aim for the head. They Learn. Coming soon to Steam."),
    ("af_heart", 0.94, "eerie_female",
     "Day one, they were slow. Day twelve... they wore our faces. This is They Learn. The new game, coming soon to Steam."),
]
for i, (voice, speed, tag, text) in enumerate(TAKES, 1):
    a, sr = k.create(text, voice=voice, speed=speed, lang="en-us")
    raw = f"raw_{i}.wav"
    sf.write(raw, a, sr)
    out = f"they_learn_vo_{i}_{tag}.wav"
    # gentle polish: rumble cut, a little warmth and presence, light compression, tiny room, -16 LUFS
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", raw, "-af",
                    "highpass=f=70,equalizer=f=160:t=q:w=1:g=2,equalizer=f=3500:t=q:w=1.2:g=1.5,"
                    "acompressor=threshold=-20dB:ratio=2.5:attack=8:release=120,"
                    "aecho=0.8:0.5:28:0.08,adelay=250|250,apad=pad_dur=0.4,loudnorm=I=-16:TP=-1.5:LRA=9,aresample=48000",
                    "-ac", "2", out], check=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", out, "-b:a", "192k", out.replace(".wav", ".mp3")], check=True)
    print(i, voice, tag, f"{len(a) / sr:.2f}s")
