#!/usr/bin/env bash
# Design probe 02 (not registered): the hold, which creeps on MuJoCo as shipped. Does it scale with the push? Do
# MuJoCo's own options remove it: the noslip solver, the elliptic friction cone, the implicit integrators?
# usage: probe_02.sh <sx_contact binary>        (from the repository root)
set -u
B="${1:?usage: probe_02.sh <sx_contact binary>}"
T=tools/mjc_contact; W=validation/run_001_design_probes/runs; S=$W/stats_02.txt; : > $S
H="h0=0 mu=0.5 mass=1 radius=0.05 pushat=0.5 secs=2 dt=0.002"
for frac in 0.2 0.4 0.6 0.8 0.95; do
  p=$(echo "scale=6; $frac * 0.5 * 9.8" | bc)
  $T $W/p2_push_$frac.txt $H push=$p >> $S
  echo "push $frac of the limit | $($B creep $W/p2_push_$frac.txt | tail -1)"
done
for m in 0.2 5; do
  p=$(echo "scale=6; 0.6 * 0.5 * $m * 9.8" | bc)
  $T $W/p2_mass_$m.txt h0=0 mu=0.5 mass=$m radius=0.05 pushat=0.5 secs=2 dt=0.002 push=$p >> $S
  echo "mass $m kg at 0.6 | $($B creep $W/p2_mass_$m.txt | tail -1)"
done
for opt in "noslip=10" "noslip=100" "cone=elliptic" "cone=elliptic noslip=10" "integ=implicitfast" "integ=implicit" "integ=rk4" "impratio=10" "cone=elliptic impratio=10"; do
  tag=$(echo "$opt" | tr ' =' '__')
  # shellcheck disable=SC2086
  $T $W/p2_$tag.txt $H push=2.94 $opt >> $S
  echo "0.6, $opt | $($B creep $W/p2_$tag.txt | tail -1)"
done
