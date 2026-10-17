#!/bin/bash
# usage: zoo.sh outdir kinds zoom
D="${1:?}"
mkdir -p "$D"
rm -f "${D:?}"/p*.png
cd "${PROJ:-.}"
timeout 1500 xvfb-run -a -s "-screen 0 1280x720x24" ${GODOT:-godot} --path . --rendering-driver opengl3 -s res://t_zoo.gd -- shot "$D" "$2" "$3" 2>&1 | grep -v "^\s*$" | sort | uniq -c | sort -rn | head -20
