#!/usr/bin/env bash
# Run 008's lift table, re-made by Senua AI's measure. The table "a single cube slid on the ground" in this run's
# README was read before the measure had a reading for it. sx_contact's hover reading (added 15 October 2026) reads
# the same plays, suite 2's slide that ends (stop_<k>.txt), under both configurations: while the cube slides, the
# highest its lowest face rises above the ground, the step at which it does, the fastest it moves up and the deepest
# it sinks. The measure truncates to the micrometre; the table rounded to it.
# usage: hover.sh <sx_contact binary>   (from the repository root)
set -u
B="${1:?usage: hover.sh <sx_contact binary>}"; O=validation/run_008_contact_suites
for c in defaults elliptic_noslip; do
  for k in 1 4 16 64; do echo "$c 1/$k | $("$B" hover suites/2/$c/stop_$k.txt | tail -1)"; done
done > $O/hover.txt
