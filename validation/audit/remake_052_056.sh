#!/usr/bin/env bash
# The audit's re-make of runs 052 to 056 (docs/audit.md), as remake_045_051.sh re-made runs 045 to 051: each run played
# and measured again by its own script, in a clean copy of the repository on the cloud machine, then every file the
# record keeps for it compared byte for byte with a second clean copy, the record. Each run's recorded outputs are
# cleared first; its script and README are kept. The rigs are the repository's as they are now, each of their later
# settings unset in these runs' plays. Run 053 fetches MuJoCo's releases again and checks each against its published
# sha256. A script's printed output goes into this folder.
# usage: remake_052_056.sh <folder holding sx_contact and sx_contact_suite.sh> <work folder> <record copy>
#   (from the root of the clean copy to re-make in; writes validation/audit/remake_052_056_compare.txt and _log.txt;
#   the work folder holds the releases in mujoco-3.11.0 to mujoco-3.16.0 and Study 12's build in mujoco-s12-build)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; W="$(cd "${2:?}" && pwd)"; REF="$(cd "${3:?}" && pwd)"
A=validation/audit; L=$A/remake_052_056_log.txt; C=$A/remake_052_056_compare.txt; : > $L
log() { echo "$(date -u +%T) $*" >> $L; }
keep() { [ "$1" = README.md ] || [ "${1%.sh}" != "$1" ]; }
RUNS="run_052_joint_friction_and_tolerance run_053_releases run_054_noslip_converged run_055_actuators_and_box run_056_resting_arm"
for r in $RUNS; do
  d=validation/$r
  for f in "$d"/*; do keep "$(basename "$f")" || rm -rf "$f"; done
  log "$r cleared"
done
bash validation/run_052_joint_friction_and_tolerance/probe.sh "$M" "$W" > $A/remake_052_056_out_052.txt 2>&1; log "run 052 played, exit $?"
bash validation/run_053_releases/probe.sh "$M" "$W" > $A/remake_052_056_out_053.txt 2>&1; log "run 053 played, exit $?"
bash validation/run_054_noslip_converged/probe.sh "$M" "$W" > $A/remake_052_056_out_054.txt 2>&1; log "run 054 played, exit $?"
bash validation/run_055_actuators_and_box/probe.sh "$W" > $A/remake_052_056_out_055.txt 2>&1; log "run 055 played, exit $?"
bash validation/run_056_resting_arm/probe.sh "$M" "$W" > $A/remake_052_056_out_056.txt 2>&1; log "run 056 played, exit $?"
# the record writes the home folder of the machine its outputs were made on as ~ (docs/runs.md)
for r in $RUNS; do grep -rlF "$HOME" validation/$r 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done; done
log "home folder written as ~ in the re-made outputs"
{
  for r in $RUNS; do
    d=validation/$r
    ( cd "$REF" && find "$d" -type f ! -name README.md ! -name '*.sh' | sort ) | while read -r f; do
      if [ ! -f "$f" ]; then echo "MISSING $f"; elif cmp -s "$REF/$f" "$f"; then echo "SAME $f"; else echo "DIFFERS $f"; fi
    done
    find "$d" -type f ! -name README.md ! -name '*.sh' | sort | while read -r f; do
      [ -f "$REF/$f" ] || echo "NEW $f"
    done
  done
} > $C
log "compared: $(grep -c '^SAME' $C) same, $(grep -c '^DIFFERS' $C) differ, $(grep -c '^MISSING' $C) missing, $(grep -c '^NEW' $C) new"
