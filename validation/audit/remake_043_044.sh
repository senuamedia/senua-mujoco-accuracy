#!/usr/bin/env bash
# The audit's re-make of runs 043 and 044 (docs/audit.md), as remake_019_042.sh re-made runs 019 to 042: each run played
# and measured again by its own script, in a clean copy of the repository on the cloud machine, then every file the
# record keeps for it compared byte for byte with a second clean copy, the record. Each run's recorded outputs are
# cleared first; its scripts, README, the pull request's diff it reads (pr3349.diff) and Study 11's dry run (dry/, made
# by DRY=1 and not played here) are kept. Both runs build MuJoCo at the pull request's two commits from its source, as
# they did; run 043's suite is then re-read by its suite_reread.sh, as recorded.
# usage: remake_043_044.sh <folder holding sx_contact> <work folder> <record copy>
#   (from the root of the clean copy to re-make in; writes validation/audit/remake_043_044_compare.txt and _log.txt;
#   the work folder holds mujoco-src, a clone of google-deepmind/mujoco, and the release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; W="$(cd "${2:?}" && pwd)"; REF="$(cd "${3:?}" && pwd)"
A=validation/audit; L=$A/remake_043_044_log.txt; C=$A/remake_043_044_compare.txt; : > $L
log() { echo "$(date -u +%T) $*" >> $L; }
keep() { [ "$1" = README.md ] || [ "${1%.sh}" != "$1" ] || [ "$1" = pr3349.diff ] || [ "$1" = dry ]; }
for d in validation/run_043_fixes_in_the_wild validation/run_044_study_11; do
  for f in "$d"/*; do keep "$(basename "$f")" || rm -rf "$f"; done
  log "$(basename $d) cleared"
done
d=validation/run_043_fixes_in_the_wild
bash $d/probe.sh "$M" "$W" > $d/out.txt 2>&1; log "run 043 played, exit $?"
(cd $d && bash suite_reread.sh); log "run 043 suite re-read, exit $?"
d=validation/run_044_study_11
bash $d/play.sh "$M" "$W" > $d/out.txt 2>&1; log "run 044 played, exit $?"
# the record writes the home folder of the machine its outputs were made on as ~ (docs/runs.md)
grep -rlF "$HOME" validation/run_043_* validation/run_044_* 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
log "home folder written as ~ in the re-made outputs"
{
  for r in 043 044; do
    d=$(cd "$REF" && ls -d validation/run_${r}_* | head -1)
    ( cd "$REF" && find "$d" -type f ! -name README.md ! -name '*.sh' ! -name pr3349.diff ! -path '*/dry/*' | sort ) | while read -r f; do
      if [ ! -f "$f" ]; then echo "MISSING $f"; elif cmp -s "$REF/$f" "$f"; then echo "SAME $f"; else echo "DIFFERS $f"; fi
    done
    find "$d" -type f ! -name README.md ! -name '*.sh' ! -name pr3349.diff ! -path '*/dry/*' | sort | while read -r f; do
      [ -f "$REF/$f" ] || echo "NEW $f"
    done
  done
} > $C
log "compared: $(grep -c '^SAME' $C) same, $(grep -c '^DIFFERS' $C) differ, $(grep -c '^MISSING' $C) missing, $(grep -c '^NEW' $C) new"
