#!/usr/bin/env bash
# The audit's re-make of runs 066 to 076 (docs/audit.md), as remake_062_065.sh re-made runs 062 to 065: each run played
# and measured again by its own scripts, in a clean copy of the repository on the cloud machine, then every file the
# record keeps for it compared byte for byte with a second clean copy, the record. Each run's recorded outputs are
# cleared first; its scripts, README, Study 15's dry run (dry/, made by DRY=1 and not played here) and run 069's copy of
# the stack rig as it was before its contacts setting (an input) are kept. The rigs are the repository's as they are now,
# each of their later settings unset in these runs' plays. A script's printed output goes into this folder.
# usage: remake_066_076.sh <folder holding sx_contact and sx_contact_suite.sh> <work folder> <record copy>
#   (from the root of the clean copy to re-make in; writes validation/audit/remake_066_076_compare.txt and _log.txt;
#   the work folder holds mujoco-src at UPSTREAM_COMMIT, the release in mujoco-3.16.0 and run 020's release test build
#   in t20-release)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; W="$(cd "${2:?}" && pwd)"; REF="$(cd "${3:?}" && pwd)"
A=validation/audit; L=$A/remake_066_076_log.txt; C=$A/remake_066_076_compare.txt; : > $L
log() { echo "$(date -u +%T) $*" >> $L; }
keep() { [ "$1" = README.md ] || [ "${1%.sh}" != "$1" ] || [ "$1" = dry ] || [ "$1" = mjc_stack_before.c ]; }
RUNS="run_066_combined run_067_stack_noslip_trace run_068_full_set run_069_stack_contacts run_070_boxbox_clip
  run_071_study_15 run_072_boxbox_trace run_073_box_noslip_trace run_074_boxbox_collinear run_075_set_with_collinear
  run_076_box_rolling_trace"
for r in $RUNS; do
  d=validation/$r
  for f in "$d"/*; do keep "$(basename "$f")" || rm -rf "$f"; done
  log "$r cleared"
done
o() { echo "$A/remake_066_076_out_$1.txt"; }
bash validation/run_066_combined/probe.sh "$M" "$W" > "$(o 066)" 2>&1; log "run 066 played, exit $?"
bash validation/run_067_stack_noslip_trace/probe.sh "$W" > "$(o 067)" 2>&1; log "run 067 played, exit $?"
bash validation/run_068_full_set/probe.sh "$M" "$W" > "$(o 068)" 2>&1; log "run 068 played, exit $?"
bash validation/run_069_stack_contacts/probe.sh "$W" > "$(o 069)" 2>&1; log "run 069 played, exit $?"
bash validation/run_070_boxbox_clip/probe.sh "$M" "$W" > "$(o 070)" 2>&1; log "run 070 played, exit $?"
bash validation/run_070_boxbox_clip/probe_2.sh "$M" "$W" > "$(o 070_2)" 2>&1; log "run 070 step 2 played, exit $?"
bash validation/run_071_study_15/play.sh "$M" "$W" > "$(o 071)" 2>&1; log "run 071 played, exit $?"
bash validation/run_072_boxbox_trace/probe.sh "$W" > "$(o 072)" 2>&1; log "run 072 played, exit $?"
bash validation/run_073_box_noslip_trace/probe.sh "$W" > "$(o 073)" 2>&1; log "run 073 played, exit $?"
bash validation/run_074_boxbox_collinear/probe.sh "$M" "$W" > "$(o 074)" 2>&1; log "run 074 played, exit $?"
bash validation/run_075_set_with_collinear/probe.sh "$M" "$W" > "$(o 075)" 2>&1; log "run 075 played, exit $?"
bash validation/run_076_box_rolling_trace/probe.sh "$W" > "$(o 076)" 2>&1; log "run 076 played, exit $?"
# the record writes the home folder of the machine its outputs were made on as ~ (docs/runs.md)
for r in $RUNS; do grep -rlF "$HOME" validation/$r 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done; done
log "home folder written as ~ in the re-made outputs"
{
  for r in $RUNS; do
    d=validation/$r
    ( cd "$REF" && find "$d" -type f ! -name README.md ! -name '*.sh' ! -name mjc_stack_before.c ! -path '*/dry/*' | sort ) | while read -r f; do
      if [ ! -f "$f" ]; then echo "MISSING $f"; elif cmp -s "$REF/$f" "$f"; then echo "SAME $f"; else echo "DIFFERS $f"; fi
    done
    find "$d" -type f ! -name README.md ! -name '*.sh' ! -name mjc_stack_before.c ! -path '*/dry/*' | sort | while read -r f; do
      [ -f "$REF/$f" ] || echo "NEW $f"
    done
  done
} > $C
log "compared: $(grep -c '^SAME' $C) same, $(grep -c '^DIFFERS' $C) differ, $(grep -c '^MISSING' $C) missing, $(grep -c '^NEW' $C) new"
