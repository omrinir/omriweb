# Deadpan robot narrator: espeak-ng + mbrola us2, pitch flattened with the WORLD vocoder, then light speaker colouring in sox.
import subprocess, sys, numpy as np, pyworld as pw, soundfile as sf
OUT = "/tmp/claude-0/short2"
lines = [l.strip() for l in open(f"{OUT}/lines.txt") if l.strip()]
for i, text in enumerate(lines, 1):
    raw = f"{OUT}/raw_{i}.wav"
    subprocess.run(["espeak-ng", "-v", "mb-us2", "-s", "150", "-p", "35", "-w", raw, text], check=True)
    x, sr = sf.read(raw)
    x = x.astype(np.float64)
    f0, t = pw.harvest(x, sr, f0_floor=60, f0_ceil=300)
    sp = pw.cheaptrick(x, f0, t, sr)
    ap = pw.d4c(x, f0, t, sr)
    v = f0 > 0
    if v.any():
        m = np.exp(np.log(f0[v]).mean())
        f0[v] = 98.0 * (f0[v] / m) ** 0.22   # almost flat: dry, bored, deadpan
    y = pw.synthesize(f0, sp, ap, sr)
    sf.write(f"{OUT}/flat_{i}.wav", y / max(1e-6, np.abs(y).max()) * 0.7, sr)
    subprocess.run(["sox", f"{OUT}/flat_{i}.wav", "-r", "48000", f"{OUT}/vo_{i}.wav",
                    "highpass", "80", "equalizer", "180", "1q", "+4", "equalizer", "2800", "1q", "+3", "lowpass", "7500",
                    "chorus", "0.7", "0.8", "24", "0.25", "0.3", "2", "-s",
                    "reverb", "12", "40", "25", "gain", "-n", "-1"], check=True)
    d = float(subprocess.run(["soxi", "-D", f"{OUT}/vo_{i}.wav"], capture_output=True, text=True).stdout)
    print(i, f"{d:.2f}", text)
