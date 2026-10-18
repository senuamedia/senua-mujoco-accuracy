#!/usr/bin/env bash
# Run 005, design probe (not registered), following run 003: MuJoCo 3.16.0 as shipped.
#   1. the drop (100 mm, no friction) and the set-down (20 mm, friction 0.5) at steps of 12, 15, 20, 30 and 40 ms,
#      past the step where MuJoCo's stiffness guard (refsafe: the time constant held at no less than twice the step)
#      starts to act (10 ms, with the default time constant of 0.02 s);
#   2. the hold pushed along 22.5 degrees, where the default cone also turns the friction, with 0.6, 0.69, 0.72, 0.8,
#      0.85 and 0.9 of the limit, both cones, 2 ms;
#   3. the slide that ends along 0, 22.5 and 45 degrees with the cube free to turn (lock=0), both cones, 2 ms.
# usage: probe.sh <sx_contact binary>        (from the repository root; writes the reading to standard output)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"
T=tools/mjc_contact; O=validation/run_005_past_refsafe_and_free; W=$O/runs; mkdir -p $W; S=$W/stats.txt; : > $S
for dt in 0.012 0.015 0.02 0.03 0.04; do
  $T $W/bounce_$dt.txt dt=$dt h0=0.1 mu=0 secs=1 >> $S
  $T $W/rest_$dt.txt dt=$dt h0=0.02 mu=0.5 secs=1 >> $S
done
for cone in pyramidal elliptic; do
  for frac in 0.6 0.69 0.72 0.8 0.85 0.9; do
    p=$(awk -v f=$frac 'BEGIN { printf "%.6f", f * 0.5 * 9.8 }')
    $T $W/hold_${cone}_22.5_$frac.txt dt=0.002 h0=0 mu=0.5 push=$p pushat=0.5 secs=2 dir=22.5 cone=$cone >> $S
  done
  for dir in 0 22.5 45; do
    $T $W/slide_free_${cone}_$dir.txt dt=0.002 h0=0 vx0=1 mu=0.4 secs=1 lock=0 dir=$dir cone=$cone >> $S
  done
done
for dt in 0.012 0.015 0.02 0.03 0.04; do
  echo "bounce $dt | $($B bounce $W/bounce_$dt.txt | tail -1)"
  echo "rest $dt | $($B rest $W/rest_$dt.txt | tail -1) | last line of the rig: $(tail -1 $W/rest_$dt.txt)"
done
for cone in pyramidal elliptic; do
  for frac in 0.6 0.69 0.72 0.8 0.85 0.9; do
    echo "hold $cone 22.5 $frac | $($B creep $W/hold_${cone}_22.5_$frac.txt | tail -1) | $(grep "dir=22.5 cone=$cone" $S | grep " lock 1 " | grep -o 'side_um [-0-9]* most_side_ums [0-9]*' | sed -n "$(echo "0.6 0.69 0.72 0.8 0.85 0.9" | tr ' ' '\n' | grep -n "^$frac$" | cut -d: -f1)p")"
  done
  for dir in 0 22.5 45; do
    echo "slide free $cone $dir | $($B stop $W/slide_free_${cone}_$dir.txt | tail -1) | $(grep " lock 0 " $S | grep "dir=$dir cone=$cone" | grep -o 'side_um [-0-9]* most_side_ums [0-9]*')"
  done
done
