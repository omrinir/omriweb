# Narrator for Short v4: Kokoro am_onyx (voiceover take 1), slow and simple.
import subprocess, soundfile as sf
from kokoro_onnx import Kokoro
k = Kokoro('/tmp/claude-0/kok/model_q8.onnx', '/tmp/claude-0/kok/voices.npz')
OUT = "/tmp/claude-0/short4"
for i, text in enumerate([l.strip() for l in open(f"{OUT}/lines.txt") if l.strip()], 1):
    a, sr = k.create(text, voice="am_onyx", speed=0.85, lang="en-us")
    sf.write(f"{OUT}/raw_{i}.wav", a, sr)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", f"{OUT}/raw_{i}.wav", "-af",
                    "highpass=f=70,equalizer=f=160:t=q:w=1:g=2,equalizer=f=3500:t=q:w=1.2:g=1.5,"
                    "acompressor=threshold=-20dB:ratio=2.5:attack=8:release=120,aecho=0.8:0.5:28:0.08,"
                    "loudnorm=I=-16:TP=-1.5:LRA=9,aresample=48000", "-ac", "1", f"{OUT}/vo_{i}.wav"], check=True)
    d = float(subprocess.run(["soxi", "-D", f"{OUT}/vo_{i}.wav"], capture_output=True, text=True).stdout)
    print(i, f"{d:.2f}", text)
