#!/bin/sh
r() { xvfb-run -a openscad -D 'part="none"' -D step=$1 --imgsize=1200,1000 --camera=$2 --colorscheme=Tomorrow -o step$1.png steps.scad >/dev/null 2>&1; echo "step$1 done"; }
r 2  0,0,22,72,0,0,230 &
r 3  0,0,14,72,0,0,240 &
r 5  0,0,95,70,0,330,560 &
r 6  0,0,95,65,0,330,600 &
r 71 0,0,10,50,0,20,300 &
wait
