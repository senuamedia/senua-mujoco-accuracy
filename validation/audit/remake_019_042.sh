#!/usr/bin/env bash
# The audit's re-make of runs 019 to 042 (docs/audit.md): every run played and measured again by its own scripts, in
# order, in a clean copy of the repository on the cloud machine, then every file the record keeps for those runs compared
# byte for byte with a second clean copy, the record. Runs 001 to 018 are re-made by remake.sh. Each run's recorded
# outputs are cleared first, so that every one is made again; its scripts, README, the input legpress_trace.c (run 022)
# and the dry runs the studies committed before their plays (dry/, made by DRY=1 and not played here) are kept. The runs
# that build MuJoCo rebuild it from its source and their registered patch files into the work folder, as they did.
# The probes play the rigs as they are now, built against the release; every change to the rigs since added options a
# play without them does not use (run 039 checked the arm rig's 84 plays byte for byte after its last change).
# usage: remake_019_042.sh <folder holding sx_contact, sx_tumble and sx_contact_suite.sh> <work folder> <record copy>
#   (from the root of the clean copy to re-make in; writes validation/audit/remake_019_042_compare.txt and _log.txt;
#   the work folder holds mujoco-src, the release in mujoco-3.16.0, and the release's source tarball as in run 020)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; REF="$(cd "${3:?}" && pwd)"
REL="$W/mujoco-3.16.0"; A=validation/audit; L=$A/remake_019_042_log.txt; C=$A/remake_019_042_compare.txt; : > $L
log() { echo "$(date -u +%T) $*" >> $L; }
dir() { ls -d validation/run_$1_* 2>/dev/null | head -1; }
clear() {  # clear a run's recorded outputs, keeping what the run reads or what was not played by it
  find "$1" -mindepth 1 -maxdepth 1 ! -name README.md ! -name '*.sh' ! -name legpress_trace.c ! -name dry ! -name identity_first_start.txt -exec rm -rf {} +
}
rigs() { for n in mjc_contact mjc_pair mjc_chain mjc_joint mjc_rotvec mjc_arm mjc_stack mjc_grip mjc_tumble; do MUJOCO_DIR=$REL tools/build_rig.sh $n > /dev/null; done; }
rigs; log "rigs built against the release"
for r in 019 020 021 022 023 024 025 026 027 028 029 030 031 032 033 034 035 036 037 038 039 040 041 042; do
  d=$(dir $r); clear "$d"; log "run $r cleared"
  case $r in
    019|025|026|027|032|034|036) bash $d/probe.sh "$B" > /dev/null 2>&1 ;;
    028) bash $d/probe.sh "$M" > /dev/null 2>&1 ;;
    020) bash $d/play.sh "$W" > /dev/null 2>&1; bash $d/patch_check.sh "$W" > /dev/null 2>&1; bash $d/compare.sh > /dev/null 2>&1 ;;
    021) bash $d/play.sh "$B" "$M" "$W" > /dev/null 2>&1; bash $d/diag_belt.sh "$B" "$REL" > /dev/null 2>&1 ;;
    022) bash $d/play.sh "$B" "$M" "$W" > /dev/null 2>&1; bash $d/trace.sh "$W/mujoco-pyr2-build" > /dev/null 2>&1 ;;
    023) bash $d/play.sh "$B" "$M" "$W" > /dev/null 2>&1; bash $d/diag_r9.sh "$B" "$REL" > /dev/null 2>&1 ;;
    024) bash $d/play.sh "$B" "$M" "$W" > /dev/null 2>&1; bash $d/diag_r11.sh "$B" "$REL" > /dev/null 2>&1 ;;
    031) bash $d/play.sh "$B" "$M" "$W" > /dev/null 2>&1 ;;
    039|041) bash $d/probe.sh "$M" "$W" > /dev/null 2>&1 ;;
    *) bash $d/play.sh "$M" "$W" > /dev/null 2>&1 ;;
  esac
  log "run $r played, exit $?"
  rigs
done
# the record writes the home folder of the machine its outputs were made on as ~ (docs/runs.md): the re-made outputs
# are written the same way before they are compared
grep -rlF "$HOME" validation/run_0{19,2,3,4}* 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
log "home folder written as ~ in the re-made outputs"
# every file the record keeps for runs 019 to 042 (but the scripts, READMEs, the input and the dry runs) against the
# re-made copy; a file only the re-make wrote is NEW
{
  for r in 019 020 021 022 023 024 025 026 027 028 029 030 031 032 033 034 035 036 037 038 039 040 041 042; do
    d=$(cd "$REF" && ls -d validation/run_${r}_* | head -1)
    ( cd "$REF" && find "$d" -type f ! -name README.md ! -name '*.sh' ! -name legpress_trace.c ! -path '*/dry/*' | sort ) | while read -r f; do
      if [ ! -f "$f" ]; then echo "MISSING $f"; elif cmp -s "$REF/$f" "$f"; then echo "SAME $f"; else echo "DIFFERS $f"; fi
    done
    find "$d" -type f ! -name README.md ! -name '*.sh' ! -name legpress_trace.c ! -path '*/dry/*' | sort | while read -r f; do
      [ -f "$REF/$f" ] || echo "NEW $f"
    done
  done
} > $C
log "compared: $(grep -c '^SAME' $C) same, $(grep -c '^DIFFERS' $C) differ, $(grep -c '^MISSING' $C) missing, $(grep -c '^NEW' $C) new"
