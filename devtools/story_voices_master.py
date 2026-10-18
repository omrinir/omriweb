# Story voices step 2: re-master the wavs from story_voices.py (run in its output folder) to ~-18 dB mean.
import glob, subprocess, re, os, sys
STY = {"Q": "highpass=f=90,lowpass=f=7000", "P": "highpass=f=70", "Z": "highpass=f=60,aecho=0.8:0.45:6:0.35",
       "C": "highpass=f=60,aecho=0.8:0.6:40|90:0.4|0.25",
       "T": "highpass=f=260,lowpass=f=4600,acrusher=bits=12:mode=log:aa=1,aecho=0.7:0.35:14:0.3"}
def mean(f):
    o = subprocess.run(["ffmpeg","-hide_banner","-i",f,"-af","volumedetect","-f","null","-"],capture_output=True,text=True).stderr
    return float(re.search(r"mean_volume: (-?[\d.]+)",o).group(1))
for w in sorted(glob.glob("l[56]*_*.wav")):
    scene, name = w[:-4].rsplit("_",1)
    who = name[0].upper()
    if len(sys.argv) > 1 and scene not in sys.argv[1:]:
        continue
    st = STY["P"] if who=="P" else (STY["Q"] if scene=="l52_quisling" else STY.get(who, STY["Z"]))
    out = f"/home/claude/omriweb/shooter_game/sounds/story/{scene}/{name}.mp3"
    g = 0.0
    for it in range(3):
        flt = f"{st},acompressor=threshold=-28dB:ratio=4:attack=5:release=120,volume={g}dB,alimiter=limit=0.84:level=false"
        subprocess.run(["ffmpeg","-v","error","-y","-i",w,"-af",flt,"-ar","44100","-ac","1","-b:a","64k",out],check=True)
        m = mean(out); 
        if abs(m+18) < 0.7: break
        g += (-18 - m)
    print(out.split("story/")[1], round(m,1))
