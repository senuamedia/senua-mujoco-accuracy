#!/usr/bin/env bash
# Run 027, design probe (not registered): meshes and a two-pad grip (known issue M8: meshes collide as convex hulls;
# mesh fingers grip badly). Rig tools/mjc_grip.c: two pads (half-sizes 0.01 x 0.02 x 0.02 m) squeeze a cube of 0.2 kg,
# half-size 0.03 m, from either side along x with 2.45 N each, friction 0.8, and hold it up against gravity by friction
# alone: friction can hold 2 x 0.8 x 2.45 = 3.92 N, twice the cube's weight of 1.96 N. What has a right answer:
#   held      the cube does not slip down and does not turn
#   pads      a pad written as a MuJoCo box and as a mesh of the same eight corners hold the cube alike (box, mesh, and
#             the mesh with MuJoCo's multiccd flag)
#   offset    the pads grip at the cube's centre (0) and 10 mm along y from it, where gravity turns the cube about the
#             squeeze unless the pads' contact resists it; a flat pad's face resists it
# 2 s, at 2 ms and 0.5 ms, under MuJoCo's defaults and the elliptic cone with 10 noslip iterations.
# Each play is read by Senua AI's measure, as a hold: sx_contact creep (the cube's mean speed down over the second half,
# and the friction on it against the squeeze, per 10,000), rest (the mean squeeze, beside the weight), final on the tilt
# file (the angle the cube has turned through at the end, and its angular speed), and ends between the box and each
# mesh pad.
# usage: probe.sh <sx_contact binary>   (repository root, tools/mjc_grip built)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"; O=validation/run_027_grip_and_meshes; W=$O/runs; mkdir -p $W
S=$W/stats.txt; : > $S; R=$O/reading.txt; : > $R
line() { "$B" "$@" | tail -1 | sed 's/ dt_ns [0-9]*//'; }
for cfg in defaults recommended; do
  case $cfg in defaults) set -- ;; recommended) set -- cone=elliptic noslip=10 ;; esac
  for dt in 0.002 0.0005; do
    for off in 0 0.01; do
      for pad in box mesh meshccd; do
        case $pad in box) P="pad=box" ;; mesh) P="pad=mesh" ;; meshccd) P="pad=mesh multiccd=1" ;; esac
        f=$W/${cfg}_${pad}_off${off}_$dt
        # shellcheck disable=SC2086
        tools/mjc_grip $f dt=$dt offset=$off $P "$@" | sed "s/^STATS/STATS run $(basename $f)/" >> $S
        echo "$cfg $pad offset $off $dt | $(line creep $f.txt) | $(line rest $f.txt) | turned $(line final ${f}_tilt.txt)" >> $R
      done
      for pad in mesh meshccd; do
        echo "$cfg box against $pad offset $off $dt | $(line ends $W/${cfg}_box_off${off}_$dt.txt $W/${cfg}_${pad}_off${off}_$dt.txt) | turned $(line ends $W/${cfg}_box_off${off}_${dt}_tilt.txt $W/${cfg}_${pad}_off${off}_${dt}_tilt.txt)" >> $R
      done
    done
  done
done
grep -o 'STATS run [^ ]*\|most_iterations [0-9]*\|at_iteration_limit [0-9]*\|most_contacts [0-9]*\|warnings [0-9]*' $S | paste -d' ' - - - - - > $O/solver.txt
date -u +%FT%TZ > $O/finished.txt
