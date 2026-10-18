#!/usr/bin/env bash
# The audit's re-make of runs 062 to 065 (docs/audit.md), as remake_057_061.sh re-made runs 057 to 061: each run played
# and measured again by its own script, in a clean copy of the repository on the cloud machine, then every file the
# record keeps for it compared byte for byte with a second clean copy, the record. Each run's recorded outputs are
# cleared first; its script, README and Study 14's dry run (dry/, made by DRY=1 and not played here) are kept. The
# rigs are the repository's as they are now, each of their later settings unset in these runs' plays. A script's
# printed output goes into this folder.
# usage: remake_062_065.sh <folder holding sx_contact and sx_contact_suite.sh> <work folder> <record copy>
#   (from the root of the clean copy to re-make in; writes validation/audit/remake_062_065_compare.txt and _log.txt;
#   the work folder holds the releases in mujoco-3.11.0 to mujoco-3.16.0 and Study 12's build in mujoco-s12-build)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; W="$(cd "${2:?}" && pwd)"; REF="$(cd "${3:?}" && pwd)"
A=validation/audit; L=$A/remake_062_065_log.txt; C=$A/remake_062_065_compare.txt; : > $L
log() { echo "$(date -u +%T) $*" >> $L; }
keep() { [ "$1" = README.md ] || [ "${1%.sh}" != "$1" ] || [ "$1" = dry ]; }
RUNS="run_062_noslip_trace run_063_qcqp_reduced run_064_study_14 run_065_suite_t08"
for r in $RUNS; do
  d=validation/$r
  for f in "$d"/*; do keep "$(basename "$f")" || rm -rf "$f"; done
  log "$r cleared"
done
bash validation/run_062_noslip_trace/probe.sh "$W" > $A/remake_062_065_out_062.txt 2>&1; log "run 062 played, exit $?"
bash validation/run_063_qcqp_reduced/probe.sh "$M" "$W" > $A/remake_062_065_out_063.txt 2>&1; log "run 063 played, exit $?"
bash validation/run_064_study_14/play.sh "$M" "$W" > $A/remake_062_065_out_064.txt 2>&1; log "run 064 played, exit $?"
bash validation/run_065_suite_t08/probe.sh "$M" "$W" > $A/remake_062_065_out_065.txt 2>&1; log "run 065 played, exit $?"
bash validation/run_065_suite_t08/probe_2.sh "$M" "$W" > $A/remake_062_065_out_065_2.txt 2>&1; log "run 065 step 2 played, exit $?"
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
