#!/usr/bin/env bash
# The audit's re-make of runs 045 to 051 (docs/audit.md), as remake_043_044.sh re-made runs 043 and 044: each run played
# and measured again by its own scripts, in a clean copy of the repository on the cloud machine, then every file the
# record keeps for it compared byte for byte with a second clean copy, the record. Each run's recorded outputs are
# cleared first; its scripts, README and Study 12's dry run (dry/, made by DRY=1 and not played here) are kept. Each
# script builds what it built (the de Saxce patch's versions from their patch files, on MuJoCo's source at
# UPSTREAM_COMMIT). A script's printed output goes where the record keeps it (out.txt, out_2.txt) and otherwise into
# this folder. Run 050 is played as its corrected probe (a1af52b), the play the record keeps.
# usage: remake_045_051.sh <folder holding sx_contact and sx_contact_suite.sh> <work folder> <record copy>
#   (from the root of the clean copy to re-make in; writes validation/audit/remake_045_051_compare.txt and _log.txt;
#   the work folder holds mujoco-src at UPSTREAM_COMMIT, the release in mujoco-3.16.0 and run 020's release test build
#   in t20-release)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; W="$(cd "${2:?}" && pwd)"; REF="$(cd "${3:?}" && pwd)"
A=validation/audit; L=$A/remake_045_051_log.txt; C=$A/remake_045_051_compare.txt; : > $L
log() { echo "$(date -u +%T) $*" >> $L; }
keep() { [ "$1" = README.md ] || [ "${1%.sh}" != "$1" ] || [ "$1" = dry ]; }
RUNS="run_045_f12_free_cube_direction run_046_desaxce run_047_desaxce_v2 run_048_desaxce_v3 run_049_desaxce_v4 run_050_stacks_box_and_limits run_051_study_12"
for r in $RUNS; do
  d=validation/$r
  for f in "$d"/*; do keep "$(basename "$f")" || rm -rf "$f"; done
  log "$r cleared"
done
d=validation/run_045_f12_free_cube_direction
bash $d/probe.sh "$M" "$W" > $d/out.txt 2>&1; log "run 045 played, exit $?"
bash $d/probe_2.sh "$M" "$W" > $d/out_2.txt 2>&1; log "run 045 step 2 played, exit $?"
for r in run_046_desaxce run_047_desaxce_v2 run_048_desaxce_v3 run_049_desaxce_v4; do
  bash validation/$r/probe.sh "$M" "$W" > validation/$r/out.txt 2>&1; log "$r played, exit $?"
done
bash validation/run_049_desaxce_v4/probe_2.sh "$W" > $A/remake_045_051_out_049_2.txt 2>&1; log "run 049 step 2 played, exit $?"
bash validation/run_050_stacks_box_and_limits/probe.sh "$M" "$W" > $A/remake_045_051_out_050.txt 2>&1; log "run 050 played, exit $?"
bash validation/run_051_study_12/play.sh "$M" "$W" > $A/remake_045_051_out_051.txt 2>&1; log "run 051 played, exit $?"
# the record writes the home folder of the machine its outputs were made on as ~ (docs/runs.md)
for r in $RUNS; do grep -rlF "$HOME" validation/$r 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done; done
log "home folder written as ~ in the re-made outputs"
{
  for r in $RUNS; do
    d=validation/$r
    ( cd "$REF" && find "$d" -type f ! -name README.md ! -name '*.sh' ! -path '*/dry/*' | sort ) | while read -r f; do
      if [ ! -f "$f" ]; then echo "MISSING $f"; elif cmp -s "$REF/$f" "$f"; then echo "SAME $f"; else echo "DIFFERS $f"; fi
    done
    find "$d" -type f ! -name README.md ! -name '*.sh' ! -path '*/dry/*' | sort | while read -r f; do
      [ -f "$REF/$f" ] || echo "NEW $f"
    done
  done
} > $C
log "compared: $(grep -c '^SAME' $C) same, $(grep -c '^DIFFERS' $C) differ, $(grep -c '^MISSING' $C) missing, $(grep -c '^NEW' $C) new"
