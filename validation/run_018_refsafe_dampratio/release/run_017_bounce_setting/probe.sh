#!/usr/bin/env bash
# Run 017, design probe (not registered): a bounce asked of MuJoCo's soft contact, at every step (known issue M7:
# restitution is not a parameter; a user who asked for 0.75 got 0.820). MuJoCo has no coefficient of restitution. A
# bounce comes from the contact's reference, solref: a time constant and a damping ratio, MuJoCo's default "0.02 1"
# (critically damped: no bounce, as run 008's T04 found). A damping ratio under 1 lets the contact spring back. The
# first deep dive's known-answer test T04 holds that the bounce does not depend on the step. This probe asks: does
# one solref give one bounce, at every step?
# Each play is suite 1's drop (a 2 kg cube, half-size 0.04 m, that cannot turn, dropped from 0.08 m, 0.5 s), at the
# steps of the suite (10 ms over 1, 2, 4, 8, 16, 32 and 64; the time constant 0.02 s is at least twice each step, so
# MuJoCo's stiffness guard, refsafe, does not act), with solref "0.02 D" for damping ratios D of 1, 0.5, 0.2 and 0.1.
# Step 0: with solref unset the rig plays exactly as before (suite 1's drop at 10 ms, made again, against
# suites/1/defaults/drop_1.txt), and solref "0.02 1", MuJoCo's default given explicitly, plays the same bytes.
# Each play is read by Senua AI's measure, sx_contact bounce: the rebound, in parts of 10,000 of the drop height.
# usage: probe.sh <sx_contact binary>   (repository root, tools/mjc_contact built)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"; O=validation/run_017_bounce_setting; W=$O/runs; mkdir -p $W
dt_of() { awk -v k="$1" 'BEGIN { printf "%.12f", 0.01 / k }'; }
CUBE="mass=2 radius=0.04"
tools/mjc_contact $W/identity_drop_1.txt dt="$(dt_of 1)" $CUBE h0=0.08 secs=0.5 > $W/identity_stats.txt
if cmp -s $W/identity_drop_1.txt suites/1/defaults/drop_1.txt; then echo "SAME suite 1 drop_1 made again" > $O/identity.txt
else echo "DIFFERS suite 1 drop_1 made again: $(cmp $W/identity_drop_1.txt suites/1/defaults/drop_1.txt)" > $O/identity.txt; fi
S=$W/stats.txt; : > $S; R=$O/reading.txt; : > $R
for d in 1 0.5 0.2 0.1; do
  for k in 1 2 4 8 16 32 64; do
    f=$W/d${d}_$k.txt
    tools/mjc_contact $f dt="$(dt_of $k)" $CUBE h0=0.08 secs=0.5 solref=0.02,$d | sed "s/^STATS/STATS run d${d}_$k/" >> $S
    echo "solref 0.02 $d 1/$k | $("$B" bounce $f | tail -1)" >> $R
  done
done
if cmp -s $W/d1_1.txt suites/1/defaults/drop_1.txt; then echo "SAME solref 0.02,1 given against suite 1 drop_1" >> $O/identity.txt
else echo "DIFFERS solref 0.02,1 given against suite 1 drop_1: $(cmp $W/d1_1.txt suites/1/defaults/drop_1.txt)" >> $O/identity.txt; fi
date -u +%FT%TZ > $O/finished.txt
