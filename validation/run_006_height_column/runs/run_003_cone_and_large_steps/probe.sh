#!/usr/bin/env bash
# Run 003, design probe (not registered): MuJoCo 3.16.0's friction cone at an angle to its axes (known issue M4), and
# the contact at steps larger than the default (M6, M11). The one-cube rig, the cube unable to turn.
#   1. the slide that ends (1 m/s, friction 0.4) along 0, 22.5 and 45 degrees from x, with the default pyramidal cone
#      and with the elliptic cone, at 2 ms and 1/16 of it: distance, and drift across the line;
#   2. the hold (friction 0.5) pushed along 0 and 45 degrees with 0.6, 0.69, 0.72 and 0.8 of what friction can hold,
#      both cones, 2 ms: a pyramid whose edges lie on x and y holds only 0.707 of the limit along 45 degrees;
#   3. the drop (100 mm, no friction) and the set-down (20 mm, friction 0.5) at steps of 1, 2, 4, 6, 8 and 10 ms.
# A check on the rig: the slide along 0 degrees, pyramidal, 2 ms, must be byte-identical to run 001's slide_0.002.txt.
# usage: probe.sh <sx_contact binary>        (from the repository root; writes the reading to standard output)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"
T=tools/mjc_contact; O=validation/run_003_cone_and_large_steps; W=$O/runs; mkdir -p $W; S=$W/stats.txt; : > $S
for cone in pyramidal elliptic; do
  for dir in 0 22.5 45; do
    for dt in 0.002 0.000125; do
      $T $W/slide_${cone}_${dir}_$dt.txt dt=$dt h0=0 vx0=1 mu=0.4 secs=1 dir=$dir cone=$cone >> $S
    done
  done
  for dir in 0 45; do
    for frac in 0.6 0.69 0.72 0.8; do
      p=$(awk -v f=$frac 'BEGIN { printf "%.6f", f * 0.5 * 9.8 }')
      $T $W/hold_${cone}_${dir}_$frac.txt dt=0.002 h0=0 mu=0.5 push=$p pushat=0.5 secs=2 dir=$dir cone=$cone >> $S
    done
  done
done
for dt in 0.001 0.002 0.004 0.006 0.008 0.01; do
  $T $W/bounce_$dt.txt dt=$dt h0=0.1 mu=0 secs=1 >> $S
  $T $W/rest_$dt.txt dt=$dt h0=0.02 mu=0.5 secs=1 >> $S
done
if cmp -s $W/slide_pyramidal_0_0.002.txt validation/run_001_design_probes/runs/slide_0.002.txt; then
  echo "CHECK the slide along 0 degrees with dir= given is byte-identical to run 001's: yes"
else echo "CHECK the slide along 0 degrees with dir= given is byte-identical to run 001's: NO"; fi
for cone in pyramidal elliptic; do
  for dir in 0 22.5 45; do
    for dt in 0.002 0.000125; do
      echo "slide $cone $dir $dt | $($B stop $W/slide_${cone}_${dir}_$dt.txt | tail -1) | $(grep -o 'dt [^ ]* .*' $S | grep "^dt $dt h0 0 vx0 1 " | grep "dir=$dir cone=$cone" | grep -o 'side_um [-0-9]* most_side_ums [0-9]*')"
    done
  done
  for dir in 0 45; do
    for frac in 0.6 0.69 0.72 0.8; do
      echo "hold $cone $dir $frac | $($B creep $W/hold_${cone}_${dir}_$frac.txt | tail -1)"
    done
  done
done
for dt in 0.001 0.002 0.004 0.006 0.008 0.01; do
  echo "bounce $dt | $($B bounce $W/bounce_$dt.txt | tail -1)"
  echo "rest $dt | $($B rest $W/rest_$dt.txt | tail -1) | last line of the rig: $(tail -1 $W/rest_$dt.txt)"
done
