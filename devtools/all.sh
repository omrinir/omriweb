#!/bin/bash
cd $1
for lv in $(seq 1 51); do
 out=$(timeout 240 ${GODOT:-godot} --headless --path . -s res://t_run.gd -- $lv 600 2>&1)
 e=$(echo "$out" | grep -cE "SCRIPT ERROR|Parse Error|Cannot infer")
 f=$(echo "$out" | grep -c "frame 600")
 echo "L$lv err=$e reached=$f $(echo "$out" | grep -E 'SCRIPT ERROR|Parse Error' | head -2 | tr '\n' ' ')"
done
