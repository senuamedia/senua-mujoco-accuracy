#!/usr/bin/env bash
# Run 010, design probe (not registered): the first deep dive's Study 9 rotations through MuJoCo's own quaternion
# functions (tools/mjc_rotvec.c): its 40 registered rotations (five axes, the last x as the control, by eight angles
# from 8e-4 down to 2e-14 rad), read by the same measure with the same bound (sx_contact rotvec, 1 ppm); then the same
# five axes at angles down to and past MuJoCo's own floor (an axis shorter than 1e-15 is replaced with x).
# usage: probe.sh <sx_contact binary>        (from the repository root; writes the reading)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"
O=validation/run_010_small_rotations; W=$O/runs; mkdir -p $W
REG=""; FLOOR=""
for ax in 0,-1,0 0,0.6,-0.8 0.36,0.48,0.8 -1,2,2 1,0,0; do
  for an in 8,-4 3,-7 6,-9 2.2,-9 1.8,-9 4,-10 5,-12 2,-14; do REG="$REG $ax,$an"; done
  for an in 1,-14 4,-15 2.5,-15 2,-15 1.5,-15 1,-15 5,-16 1,-16 1,-18; do FLOOR="$FLOOR $ax,$an"; done
done
# shellcheck disable=SC2086
tools/mjc_rotvec $W/rotvec_registered.txt $REG > $W/stats.txt
# shellcheck disable=SC2086
tools/mjc_rotvec $W/rotvec_floor.txt $FLOOR >> $W/stats.txt
echo "registered | $($B rotvec $W/rotvec_registered.txt 1 | tail -1)"
echo "toward the floor | $($B rotvec $W/rotvec_floor.txt 1 | tail -1)"
