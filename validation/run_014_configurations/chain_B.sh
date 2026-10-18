#!/usr/bin/env bash
# Run 014, the chain plays of configuration B again: the probe's first play asked MuJoCo for the integrator "RK" (its
# pattern for the integrator's name dropped the 4), and every chain play of B stopped at loading. The same plays as
# probe.sh's chain loop, with integ=RK4, into runs_B; their readings appended to reading.txt.
# usage: chain_B.sh <sx_contact binary>   (repository root, rigs built)
set -u
B="${1:?usage: chain_B.sh <sx_contact binary>}"; O=validation/run_014_configurations; W=$O/runs_B; S=$W/stats_chain.txt; : > $S
dt_of() { awk -v k="$1" 'BEGIN { printf "%.12f", 0.01 / k }'; }
for k in 1 4 16; do
  tools/mjc_chain $W/free_$k.txt dt=$(dt_of $k) mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2 gravity=0 angle2=-0.9 omega1=2.5 omega2=1.5 secs=2 integ=RK4 >> $S
  tools/mjc_chain $W/swing_$k.txt dt=$(dt_of $k) mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2 gravity=1 angle1=0.4 angle2=-0.7 secs=2 integ=RK4 >> $S
done
{ echo "== B, the chain played again with integ=RK4"
  for k in 1 4 16; do
    echo "free chain 1/$k | $($B chain $W/free_$k.txt | tail -1)"
    echo "swinging chain 1/$k | $($B chain $W/swing_$k.txt | tail -1)"
  done; } >> $O/reading.txt
