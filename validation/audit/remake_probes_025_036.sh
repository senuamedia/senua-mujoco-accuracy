#!/usr/bin/env bash
# The audit's re-make, extended to the design probes of 15 October 2026 that need no build of MuJoCo: runs 025, 026, 027,
# 028, 032, 034 and 036, each played again by its own script in a clean copy of the repository, against Google DeepMind's
# Linux release, with the rigs as they are now (every change to the rigs since run 025 only added settings a play without
# them does not use, which each of runs 028, 032, 034 and 036 checked byte for byte in its step 0), then every file the
# record keeps for those runs compared byte for byte with a second clean copy, the record. Not compared: the scripts and
# READMEs, the clock lines (finished.txt) and the console logs (out.txt).
# usage: remake_probes_025_036.sh <folder holding sx_contact and sx_contact_suite.sh> <release folder> <record copy>
#   (from the root of the clean copy to re-make in; writes validation/audit/remake_probes_compare.txt and
#   remake_probes_log.txt)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; REL="${2:?}"; REF="$(cd "${3:?}" && pwd)"
A=validation/audit; L=$A/remake_probes_log.txt; : > $L; C=$A/remake_probes_compare.txt; : > $C
log() { echo "$(date -u +%T) $*" >> $L; }
for n in mjc_contact mjc_pair mjc_arm mjc_stack mjc_grip; do MUJOCO_DIR=$REL tools/build_rig.sh $n > /dev/null; done
log "rigs built against the release"
for r in 025 026 027 028 032 034 036; do
  d=$(ls -d validation/run_${r}_*)
  # clear the outputs the record keeps, so every one is made again
  find "$d" -mindepth 1 -maxdepth 1 ! -name README.md ! -name probe.sh ! -name identity_first_start.txt -exec rm -rf {} +
  if [ $r = 028 ]; then bash $d/probe.sh "$M" > /dev/null 2>&1; else bash $d/probe.sh "$B" > /dev/null 2>&1; fi
  log "run $r played"
done
for r in 025 026 027 028 032 034 036; do
  d=$(cd "$REF" && ls -d validation/run_${r}_*)
  for f in $(cd "$REF" && find "$d" -type f ! -name README.md ! -name probe.sh ! -name finished.txt ! -name out.txt ! -name identity_first_start.txt | sort); do
    if [ ! -f "$f" ]; then echo "MISSING $f"; elif cmp -s "$f" "$REF/$f"; then echo "SAME $f"; else echo "DIFFERS $f"; fi
  done
done > $C
for k in SAME DIFFERS MISSING; do echo "$k $(grep -c "^$k " $C)"; done | tee -a $L
