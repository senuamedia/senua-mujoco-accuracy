#!/usr/bin/env bash
# Design probe 04 (not registered): the sixth and eighth registrations' arm (2 kg, half-size 0.04 m, 0.4 m from the
# joint) on MuJoCo as shipped, at 2 ms and 1/4, 1/16, 1/64 of it. usage: probe_04.sh <sx_contact binary>
set -u
B="${1:?usage: probe_04.sh <sx_contact binary>}"
T=tools/mjc_joint; W=validation/run_001_design_probes/runs; S=$W/stats_04.txt; : > $S
A="mass=2 radius=0.04 arm=0.4"
for dt in 0.002 0.0005 0.000125 0.00003125; do
  # shellcheck disable=SC2086
  { $T $W/j_spin_$dt.txt dt=$dt $A gravity=0 omega0=3 secs=1
    $T $W/j_torque_$dt.txt dt=$dt $A gravity=0 torque=1.5 secs=1
    $T $W/j_swing_$dt.txt dt=$dt $A secs=3
    $T $W/j_hold_$dt.txt dt=$dt $A coulomb=12 secs=2
    $T $W/j_rel20_$dt.txt dt=$dt $A lo=-0.3 hi=3 limitk=2000 limitd=20 gravity=0 angle0=-0.33 secs=0.5
    $T $W/j_rel150_$dt.txt dt=$dt $A lo=-0.3 hi=3 limitk=2000 limitd=150 gravity=0 angle0=-0.33 secs=0.5; } >> $S
  echo "spin 3 rad/s $dt | $($B final $W/j_spin_$dt.txt | tail -1)"
  echo "torque 1.5 N m $dt | $($B final $W/j_torque_$dt.txt | tail -1)"
  echo "swing $dt | $($B swing $W/j_swing_$dt.txt | tail -1)"
  echo "hold, friction 12 N m $dt | $($B creep $W/j_hold_$dt.txt | tail -1)"
  echo "released inside the limit, damping 20 $dt | $($B final $W/j_rel20_$dt.txt | tail -1)"
  echo "released inside the limit, damping 150 $dt | $($B final $W/j_rel150_$dt.txt | tail -1)"
done
