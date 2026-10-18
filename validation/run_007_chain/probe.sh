#!/usr/bin/env bash
# Run 007, design probe (not registered): the first deep dive's two-link chain on MuJoCo 3.16.0 as shipped, the same
# scenes as its Study 12 (the free chain) and Study 15 (the swinging chain), at its steps (10 ms over 1, 4, 16 and 64),
# under each of MuJoCo's four integrators. Rig tools/mjc_chain.c; measure: sx_contact chain.
#   free   no gravity, set turning: kinetic energy and angular momentum about the first joint must stay as they were
#   swing  gravity, released at rest: the total energy must stay as it was
# usage: probe.sh <sx_contact binary>        (from the repository root; writes the reading to standard output)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"
T=tools/mjc_chain; O=validation/run_007_chain; W=$O/runs; mkdir -p $W; S=$W/stats.txt; : > $S
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"
dt_of() { awk -v k=$1 'BEGIN { printf "%.12f", 0.01 / k }'; }
for integ in Euler implicitfast implicit RK4; do
  for k in 1 4 16 64; do
    # shellcheck disable=SC2086
    $T $W/free_${integ}_$k.txt dt=$(dt_of $k) $ARMS gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2 integ=$integ >> $S
    # shellcheck disable=SC2086
    $T $W/swing_${integ}_$k.txt dt=$(dt_of $k) $ARMS gravity=1 angle1=0.4 angle2=-0.7 secs=2 integ=$integ >> $S
  done
done
for integ in Euler implicitfast implicit RK4; do
  for k in 1 4 16 64; do
    echo "free $integ $k | $($B chain $W/free_${integ}_$k.txt | tail -1)"
    echo "swing $integ $k | $($B chain $W/swing_${integ}_$k.txt | tail -1)"
  done
done
