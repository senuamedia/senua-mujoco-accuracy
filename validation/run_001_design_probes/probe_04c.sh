#!/usr/bin/env bash
# Design probe 04c (not registered): the arm released 0.03 rad inside its limit, with the rig's limit mapping
# corrected (stiffness and damping divided by the arm's inertia about the joint), under MuJoCo's default limit
# impedance and under a nearly hard one, at 2 ms and 1/64 of it. Written after the plays, from the commands that made
# reading_04c.txt; it remakes that reading and the j2_ runs byte for byte. usage: probe_04c.sh <sx_contact binary>
set -u
B="${1:?usage: probe_04c.sh <sx_contact binary>}"
T=tools/mjc_joint; W=validation/run_001_design_probes/runs; S=$W/stats_04c.txt; : > $S
A="mass=2 radius=0.04 arm=0.4 lo=-0.3 hi=3 limitk=2000 gravity=0 angle0=-0.33 secs=0.5"
for d in 20 150; do
  for dt in 0.002 0.00003125; do
    # shellcheck disable=SC2086
    $T $W/j2_${d}_${dt}_default.txt dt=$dt $A limitd=$d >> $S
    echo "damping $d, step $dt, impedance default | $($B final $W/j2_${d}_${dt}_default.txt | tail -1)"
    # shellcheck disable=SC2086
    $T $W/j2_${d}_${dt}_0.9999_0.9999_0.001.txt dt=$dt $A limitd=$d "limitimp=0.9999 0.9999 0.001" >> $S
    echo "damping $d, step $dt, impedance 0.9999 0.9999 0.001 | $($B final $W/j2_${d}_${dt}_0.9999_0.9999_0.001.txt | tail -1)"
  done
done
