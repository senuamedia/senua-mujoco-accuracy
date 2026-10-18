#!/usr/bin/env bash
# The audit's re-make of runs 101 to 106 (docs/audit.md), as remake_077_100.sh re-made runs 077 to 100: one chain on
# the first cloud machine, each run's MuJoCo builds made by its own script (run 103 reads Study 22's build,
# mujoco-s22-build, which run 099 made). Each run played and measured again by its own scripts, in a clean copy of the
# repository, then every file the record keeps for it compared byte for byte with a second clean copy, the record. Each
# run's recorded outputs are cleared first; its README, its scripts, its .c inputs (before/) and its dry run (dry/, made
# by DRY=1 and not played here) are kept. Every run plays with the measure with `fastest`. A script's printed output
# goes into this folder. As the record does, the home folder is written ~, inside compressed files too; the play files
# and traces of run 101 over 200 kB are compressed, and the build logs of runs 102, 104 and 105.
# usage: remake_101_106.sh <sx_contact with fastest> <work folder> <record copy>
#   (from the root of the clean copy to re-make in; writes validation/audit/remake_101_106_compare.txt and _log.txt;
#   the work folder holds mujoco-src at UPSTREAM_COMMIT and Study 22's build in mujoco-s22-build)
set -u
N4="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; REF="$(cd "${3:?}" && pwd)"
A=validation/audit; L=$A/remake_101_106_log.txt; C=$A/remake_101_106_compare.txt; : > $L
log() { echo "$(date -u +%T) $*" >> $L; }
keep() { [ "$1" = README.md ] || [ "${1%.sh}" != "$1" ] || [ "${1%.c}" != "$1" ] || [ "$1" = dry ] || [ "$1" = before ]; }
RUNS="run_101_noslip_normal_v2 run_102_contact_time_constant run_103_impratio_without_noslip run_104_impratio_and_time_constant run_105_no_noslip run_106_study_23"
for r in $RUNS; do
  d=validation/$r
  for f in "$d"/*; do keep "$(basename "$f")" || rm -rf "$f"; done
  log "$r cleared"
done
play() {  # <run> <script> <arguments...>
  local r=$1 s=$2; shift 2
  bash "validation/$r/$s" "$@" > "$A/remake_101_106_out_${r:4:3}_${s%.sh}.txt" 2>&1; log "$r $s played, exit $?"
}
play run_101_noslip_normal_v2 probe.sh "$N4" "$W"
play run_102_contact_time_constant probe.sh "$N4" "$W"
play run_103_impratio_without_noslip probe.sh "$N4" "$W"
play run_104_impratio_and_time_constant probe.sh "$N4" "$W"
play run_105_no_noslip probe.sh "$N4" "$W"
play run_106_study_23 play.sh "$N4" "$W"
# the record's own handling of the outputs: the home folder written ~, inside compressed files too; run 101's play
# files and traces over 200 kB compressed; the build logs of runs 102, 104 and 105 compressed
for r in $RUNS; do
  grep -rlF "$HOME" "validation/$r" 2>/dev/null | grep -v '\.gz$' | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
  find "validation/$r" -name '*.gz' | while read -r f; do
    if gzip -dc "$f" | grep -qF "$HOME"; then gzip -dc "$f" | sed "s|$HOME|~|g" | gzip -n > "$f.new" && mv "$f.new" "$f"; fi
  done
done
find validation/run_101_noslip_normal_v2/a -type f \( -name '*.txt' -o -name '*.trace' \) ! -name stats.txt -size +200k -exec gzip -n {} +
for r in run_102_contact_time_constant run_104_impratio_and_time_constant run_105_no_noslip; do gzip -n "validation/$r/build_lib.log"; done
log "home folder written as ~; compressed as the record keeps them"
{
  for r in $RUNS; do
    d=validation/$r
    ( cd "$REF" && find "$d" -type f ! -name README.md ! -name '*.sh' ! -name '*.c' ! -path '*/dry/*' | sort ) | while read -r f; do
      if [ ! -f "$f" ]; then echo "MISSING $f"; elif cmp -s "$REF/$f" "$f"; then echo "SAME $f"; else echo "DIFFERS $f"; fi
    done
    find "$d" -type f ! -name README.md ! -name '*.sh' ! -name '*.c' ! -path '*/dry/*' | sort | while read -r f; do
      [ -f "$REF/$f" ] || echo "NEW $f"
    done
  done
} > $C
log "compared: $(grep -c '^SAME' $C) same, $(grep -c '^DIFFERS' $C) differ, $(grep -c '^MISSING' $C) missing, $(grep -c '^NEW' $C) new"
