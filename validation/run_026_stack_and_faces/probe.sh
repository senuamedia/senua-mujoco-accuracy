#!/usr/bin/env bash
# Run 026, design probe (not registered): a resting stack and face-to-face boxes (known issues M6, M9: the soft contact
# and the box-box collision MuJoCo rewrote in 3.12). Rig tools/mjc_stack.c: cubes of 0.5 kg, half-size 0.05 m,
# friction 0.5, each free to move and turn, set down touching. What has a right answer:
#   stack     3, 5 and 10 cubes set down straight, 2 s: each cube carries its own weight (the net contact force on it is
#             its weight), none slides, none tilts, none is pulled
#   offset    3 cubes, each 20 mm along x from the one below (the cubes above a face always over it), 2 s: the same
#   slide     one cube set sliding at 1.2 m/s, on the ground and on a fixed box (half-size 0.5 m) whose top face is at
#             the ground's height, so the one contact is box face on box face, 1 s: Coulomb's distance,
#             1.2^2 / (2 x 0.5 x 9.8) = 146,939 um, on both, no lift, no tilt
# At 2 ms (MuJoCo's default) and 0.5 ms, under MuJoCo's defaults and the elliptic cone with 10 noslip iterations.
# Each play is read by Senua AI's measure: for each cube, sx_contact rest (the mean net contact force over the second
# half, beside the weight), pull (the lowest), stop (the largest speed over the last third; how far it slid), creep
# (the mean speed over the second half), final (the last step's first two columns: in a contact file the height of the
# cube's lowest face above what is below it, nm, and its speed; in a tilt file its tilt, urad, and its angular speed);
# the slides: stop, hover, final on the tilt file, and ends between the box face and the ground.
# usage: probe.sh <sx_contact binary>   (repository root, tools/mjc_stack built)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"; O=validation/run_026_stack_and_faces; W=$O/runs; mkdir -p $W
S=$W/stats.txt; : > $S; R=$O/reading.txt; : > $R
line() { "$B" "$@" | tail -1 | sed 's/ dt_ns [0-9]*//'; }
cube() {  # <label> <file prefix> <k>: one cube's readings
  local p=$2_$3
  echo "$1 cube $3 | $(line rest $p.txt) | $(line pull $p.txt) | $(line stop $p.txt) | $(line creep $p.txt) | place $(line final $p.txt) | tilt $(line final ${p}_tilt.txt)" >> $R
}
for cfg in defaults recommended; do
  case $cfg in defaults) set -- ;; recommended) set -- cone=elliptic noslip=10 ;; esac
  for dt in 0.002 0.0005; do
    for n in 3 5 10; do
      f=$W/${cfg}_stack${n}_$dt
      # shellcheck disable=SC2086
      tools/mjc_stack $f dt=$dt n=$n secs=2 "$@" | sed "s/^STATS/STATS run $(basename $f)/" >> $S
      for k in $(seq 1 $n); do cube "$cfg stack$n $dt" $f $k; done
    done
    f=$W/${cfg}_offset3_$dt
    tools/mjc_stack $f dt=$dt n=3 shift=0.02 secs=2 "$@" | sed "s/^STATS/STATS run $(basename $f)/" >> $S
    for k in 1 2 3; do cube "$cfg offset3 $dt" $f $k; done
    for on in ground box; do
      f=$W/${cfg}_slide_${on}_$dt
      if [ $on = box ]; then bs=base=0.5; else bs=base=0; fi
      tools/mjc_stack $f dt=$dt n=1 vx=1.2 secs=1 $bs "$@" | sed "s/^STATS/STATS run $(basename $f)/" >> $S
      echo "$cfg slide $on $dt | $(line stop ${f}_1.txt) | $(line hover ${f}_1.txt) | tilt $(line final ${f}_1_tilt.txt)" >> $R
    done
    echo "$cfg slide box against ground $dt | $(line ends $W/${cfg}_slide_box_${dt}_1.txt $W/${cfg}_slide_ground_${dt}_1.txt)" >> $R
  done
done
grep -o 'STATS run [^ ]*\|most_iterations [0-9]*\|at_iteration_limit [0-9]*\|most_contacts [0-9]*\|warnings [0-9]*' $S | paste -d' ' - - - - - > $O/solver.txt
date -u +%FT%TZ > $O/finished.txt
