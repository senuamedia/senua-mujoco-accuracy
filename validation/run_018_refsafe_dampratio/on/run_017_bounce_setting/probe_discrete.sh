#!/usr/bin/env bash
# Run 017, step 2 (written after step 1's readings, before any of these plays): the same drops under MuJoCo's own
# opt-in discrete integrator. Step 1 found, under the default Euler integrator, that one solref does not give one
# bounce, and that at the larger steps a damping ratio under 1 throws the cube higher than it was dropped. MuJoCo
# 3.16.0's documentation (XMLreference, flag refsafe) says its stiffness guard under Euler only holds the time constant
# to at least twice the step, and that under the discrete integrator it instead replaces a contact row whose spring the
# step cannot resolve (time constant times damping ratio under the step) by the stiffest zero-restitution row, keeping
# the damping ratio. This step plays step 1's 28 drops with integ=discrete and reads them the same way.
# usage: probe_discrete.sh <sx_contact binary>   (repository root, tools/mjc_contact built)
set -u
B="${1:?usage: probe_discrete.sh <sx_contact binary>}"; O=validation/run_017_bounce_setting; W=$O/runs_discrete
mkdir -p $W
dt_of() { awk -v k="$1" 'BEGIN { printf "%.12f", 0.01 / k }'; }
CUBE="mass=2 radius=0.04"
S=$W/stats.txt; : > $S; R=$O/reading_discrete.txt; : > $R
for d in 1 0.5 0.2 0.1; do
  for k in 1 2 4 8 16 32 64; do
    f=$W/d${d}_$k.txt
    tools/mjc_contact $f dt="$(dt_of $k)" $CUBE h0=0.08 secs=0.5 solref=0.02,$d integ=discrete | sed "s/^STATS/STATS run d${d}_$k/" >> $S
    echo "solref 0.02 $d discrete 1/$k | $("$B" bounce $f | tail -1)" >> $R
  done
done
date -u +%FT%TZ > $O/finished_discrete.txt
