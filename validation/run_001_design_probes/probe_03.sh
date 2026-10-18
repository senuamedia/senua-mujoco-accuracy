#!/usr/bin/env bash
# Design probe 03 (not registered): the slide that does not settle as the step is refined, read by its deceleration
# while it slides (Coulomb: mu g = 3,920 mm/s2 at friction 0.4); and every one-cube scene under the configuration that
# removes the creep (the elliptic cone with 10 noslip iterations). usage: probe_03.sh <sx_contact binary>
set -u
B="${1:?usage: probe_03.sh <sx_contact binary>}"
T=tools/mjc_contact; W=validation/run_001_design_probes/runs; S=$W/stats_03.txt; : > $S
for dt in 0.002 0.0005 0.000125 0.00003125; do
  echo "slide $dt, deceleration 50 to 200 ms | $($B accel $W/slide_$dt.txt 50 200 | tail -1)"
  echo "slide $dt, deceleration 0 to 50 ms | $($B accel $W/slide_$dt.txt 0 50 | tail -1)"
done
C="cone=elliptic noslip=10"
for dt in 0.002 0.0005 0.000125 0.00003125; do
  # shellcheck disable=SC2086
  { $T $W/p3_hold_$dt.txt dt=$dt h0=0 mu=0.5 mass=1 radius=0.05 push=2.94 pushat=0.5 secs=2 $C
    $T $W/p3_bounce_$dt.txt dt=$dt h0=0.1 mu=0 mass=1 radius=0.05 secs=1 $C
    $T $W/p3_oblique_$dt.txt dt=$dt h0=0.05 vx0=2 mu=0.3 mass=1 radius=0.05 secs=0.5 $C
    $T $W/p3_slide_$dt.txt dt=$dt h0=0 vx0=1 mu=0.4 mass=1 radius=0.05 secs=1 $C; } >> $S
  echo "elliptic+noslip $dt hold | $($B creep $W/p3_hold_$dt.txt | tail -1)"
  echo "elliptic+noslip $dt oblique | $($B impact $W/p3_oblique_$dt.txt | tail -1)"
  echo "elliptic+noslip $dt slide | $($B stop $W/p3_slide_$dt.txt | tail -1)"
  echo "elliptic+noslip $dt bounce | $($B bounce $W/p3_bounce_$dt.txt | tail -1)"
done
$T $W/p3_hold_rk4.txt dt=0.002 h0=0 mu=0.5 mass=1 radius=0.05 push=2.94 pushat=0.5 secs=2 integ=RK4 >> $S
echo "RK4 hold | $($B creep $W/p3_hold_rk4.txt | tail -1)"
