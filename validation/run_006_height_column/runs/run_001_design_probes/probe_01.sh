#!/usr/bin/env bash
# Design probe 01 (not registered): the first deep dive's one-cube known-answer scenes played on MuJoCo 3.16.0 as
# shipped (Google DeepMind's prebuilt release), at its default step of 2 ms and at 1/4, 1/16 and 1/64 of it, and read
# by the same Simplex measuring program. usage: probe_01.sh <sx_contact binary>        (from the repository root)
set -u
B="${1:?usage: probe_01.sh <sx_contact binary>}"
T=tools/mjc_contact; O=validation/run_001_design_probes; W=$O/runs
STEPS="0.002 0.0005 0.000125 0.00003125"
for dt in $STEPS; do
  # the hold: 1 kg, half-size 0.05 m, friction 0.5, pushed with 0.6 of what friction can hold (2.94 N) from 0.5 s
  $T $W/hold_$dt.txt dt=$dt h0=0 mu=0.5 mass=1 radius=0.05 push=2.94 pushat=0.5 secs=2 >> $W/stats.txt
  # set down from 20 mm and left to rest
  $T $W/rest_$dt.txt dt=$dt h0=0.02 mu=0.5 mass=1 radius=0.05 secs=1 >> $W/stats.txt
  # dropped from 100 mm with no friction: the bounce
  $T $W/bounce_$dt.txt dt=$dt h0=0.1 mu=0 mass=1 radius=0.05 secs=1 >> $W/stats.txt
  # landing obliquely: from 50 mm at 2 m/s, friction 0.3
  $T $W/oblique_$dt.txt dt=$dt h0=0.05 vx0=2 mu=0.3 mass=1 radius=0.05 secs=0.5 >> $W/stats.txt
  # a slide that ends: resting, given 1 m/s along x, friction 0.4 (Coulomb's distance 1 / (2 x 0.4 x 9.8) = 127.55 mm)
  $T $W/slide_$dt.txt dt=$dt h0=0 vx0=1 mu=0.4 mass=1 radius=0.05 secs=1 >> $W/stats.txt
done
# determinism: the hold at the default step played a second time
$T $W/hold_again.txt dt=0.002 h0=0 mu=0.5 mass=1 radius=0.05 push=2.94 pushat=0.5 secs=2 > /dev/null
if cmp -s $W/hold_0.002.txt $W/hold_again.txt; then echo "DETERMINISM hold played twice: byte-identical"; else echo "DETERMINISM hold played twice: DIFFERS"; fi
for dt in $STEPS; do
  for k in creep; do echo "hold $dt | $($B $k $W/hold_$dt.txt | tail -1)"; done
  echo "rest $dt | $($B rest $W/rest_$dt.txt | tail -1)"
  echo "bounce $dt | $($B bounce $W/bounce_$dt.txt | tail -1)"
  echo "oblique $dt | $($B impact $W/oblique_$dt.txt | tail -1)"
  echo "slide $dt | $($B stop $W/slide_$dt.txt | tail -1)"
done
