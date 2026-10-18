#!/usr/bin/env bash
# Run 013, design probe (not registered): run 001 found MuJoCo's noslip solver leaves the default (pyramidal) cone's
# hold exactly as it was (1,293 um/s with and without it), while with the elliptic cone it removes the creep. Its
# pyramidal pass moves force only within each pair of opposing edges (engine_solver.c). Does it hold once the pyramid
# is turned along the slip (the validated patch, run 012)? The hold of run 001 (1 kg, half-size 0.05 m, friction 0.5,
# pushed with 0.6 of the limit from 0.5 s, 2 ms) along x and along 30 degrees, with noslip 10 and 100, on the patched
# build with the switch off and on; and the elliptic cone with noslip 10 for reference.
# usage: probe.sh <sx_contact binary>   (repository root; tools/mjc_contact built against the patched MuJoCo)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"
T=tools/mjc_contact; O=validation/run_013_noslip_with_aligned_pyramid; W=$O/runs; mkdir -p $W; S=$W/stats.txt; : > $S
H="dt=0.002 h0=0 mu=0.5 mass=1 radius=0.05 push=2.94 pushat=0.5 secs=2"
for sw in off on; do
  for dir in 0 30; do
    for ns in 0 10 100; do
      # shellcheck disable=SC2086
      if [ $sw = on ]; then MUJOCO_SLIP_ALIGNED_PYRAMID=1 $T $W/hold_${sw}_${dir}_ns$ns.txt $H dir=$dir noslip=$ns >> $S
      else $T $W/hold_${sw}_${dir}_ns$ns.txt $H dir=$dir noslip=$ns >> $S; fi
    done
  done
done
# shellcheck disable=SC2086
$T $W/hold_elliptic_0_ns10.txt $H dir=0 cone=elliptic noslip=10 >> $S
for f in $W/hold_*.txt; do echo "$(basename $f .txt) | $($B creep $f | tail -1)"; done
