#!/usr/bin/env bash
# The audit's re-make of runs 077 to 100 (docs/audit.md), as remake_066_076.sh re-made runs 066 to 076, in three parts
# played at once on the three cloud machines, each a chain of runs whose MuJoCo builds it makes itself:
#   a: runs 091 and 095 to 100 (Studies 21 and 22 and the probes that read their builds)
#   b: runs 077, 084 to 089 and 093 (Studies 16, 19 and 20 and the probes that read their builds)
#   c: runs 078 to 083, 090, 092 and 094 (the release's and probes that build their own)
# Each run played and measured again by its own scripts, in a clean copy of the repository, then every file the record
# keeps for it compared byte for byte with a second clean copy, the record. Each run's recorded outputs are cleared
# first; its README, its scripts, its .c inputs and its dry run (dry/, made by DRY=1 and not played here) are kept. Each
# run plays with the measure it ran with: runs 077 to 090, before the correction of 17 October 2026, with the measure as
# it was then (a folder holding sx_contact, sx_contact_suite.sh and sx_tumble); runs 091 to 097 with the corrected
# build; runs 098 to 100 with the build with `fastest`. The rigs are the repository's as they are now, each of their later
# settings unset in these runs' plays. A script's printed output goes into this folder. As the record does, the home
# folder is written ~, inside compressed files too, and the play files runs 098 and 099 keep compressed are compressed.
# usage: remake_077_100.sh <part: a, b or c> <folder of the measure before the correction> <corrected sx_contact>
#        <sx_contact with fastest> <work folder> <record copy>
#   (from the root of the clean copy to re-make in; writes validation/audit/remake_077_100_<part>_compare.txt and
#   _log.txt; the work folder holds mujoco-src at UPSTREAM_COMMIT, the release in mujoco-3.16.0 and, for parts a and b,
#   run 020's release test build in t20-release)
set -u
P=${1:?usage: see the header}; MO="$(cd "${2:?}" && pwd)"; N3="$(cd "$(dirname "${3:?}")" && pwd)/$(basename "$3")"
N4="$(cd "$(dirname "${4:?}")" && pwd)/$(basename "$4")"; W="$(cd "${5:?}" && pwd)"; REF="$(cd "${6:?}" && pwd)"
A=validation/audit; L=$A/remake_077_100_${P}_log.txt; C=$A/remake_077_100_${P}_compare.txt; : > $L
log() { echo "$(date -u +%T) $*" >> $L; }
keep() { [ "$1" = README.md ] || [ "${1%.sh}" != "$1" ] || [ "${1%.c}" != "$1" ] || [ "$1" = dry ]; }
case $P in
  a) RUNS="run_091_study_21 run_095_noslip_equality run_096_free_cube_directions run_097_noslip_equality_v2 run_098_noslip_normal run_099_study_22 run_100_noslip_normal_tolerance" ;;
  b) RUNS="run_077_study_16 run_084_set_condim_holds run_085_study_19 run_086_qcqp_reduced_v2 run_087_study_20 run_088_step_dependence run_089_order_free_cube_stacks run_093_stacks_converged" ;;
  c) RUNS="run_078_offset_stack_contacts run_079_noslip_roll_kept run_080_study_17 run_081_study_18 run_082_noslip_roll_cone run_083_condim6_hold_trace run_090_row_order_swap run_092_mesh_hull_cup run_094_noslip_costs" ;;
  *) echo "part a, b or c"; exit 2 ;;
esac
for r in $RUNS; do
  d=validation/$r
  for f in "$d"/*; do keep "$(basename "$f")" || rm -rf "$f"; done
  log "$r cleared"
done
play() {  # <run> <script> <arguments...>
  local r=$1 s=$2; shift 2
  bash "validation/$r/$s" "$@" > "$A/remake_077_100_out_${r:4:3}_${s%.sh}.txt" 2>&1; log "$r $s played, exit $?"
}
case $P in
  a) play run_091_study_21 play.sh "$N3" "$W"
     play run_095_noslip_equality probe.sh "$N3" "$W"
     play run_096_free_cube_directions probe.sh "$N3" "$W"; play run_096_free_cube_directions probe_2.sh "$N3" "$W"
     play run_097_noslip_equality_v2 probe.sh "$N3" "$W"
     play run_098_noslip_normal probe.sh "$N4" "$W"; play run_098_noslip_normal probe_2.sh "$N4" "$W"
     play run_099_study_22 play.sh "$N4" "$W"
     play run_100_noslip_normal_tolerance probe.sh "$N4" "$W" ;;
  b) play run_077_study_16 play.sh "$MO" "$W"
     play run_084_set_condim_holds probe.sh "$MO" "$W"
     play run_085_study_19 play.sh "$MO" "$W"
     play run_086_qcqp_reduced_v2 probe.sh "$MO" "$W"
     play run_087_study_20 play.sh "$MO" "$W"
     play run_088_step_dependence probe.sh "$MO" "$W"; play run_088_step_dependence probe_2.sh "$MO" "$W"
     play run_089_order_free_cube_stacks probe.sh "$MO" "$W"; play run_089_order_free_cube_stacks probe_2.sh "$MO" "$W"
     play run_093_stacks_converged probe.sh "$N3" "$W" ;;
  c) play run_078_offset_stack_contacts probe.sh "$W"
     play run_079_noslip_roll_kept probe.sh "$MO" "$W"
     play run_080_study_17 play.sh "$MO" "$W"
     play run_081_study_18 play.sh "$MO" "$W"
     play run_082_noslip_roll_cone probe.sh "$MO" "$W"
     play run_083_condim6_hold_trace probe.sh "$W"
     play run_090_row_order_swap probe.sh "$W"; play run_090_row_order_swap probe_2.sh "$W"
     play run_092_mesh_hull_cup probe.sh "$N3" "$W"
     play run_094_noslip_costs probe.sh "$N3" "$W"; play run_094_noslip_costs probe_2.sh "$N3" "$W" ;;
esac
# the record's own handling of the outputs: the home folder written ~ (docs/runs.md), inside compressed files too; the
# play files and traces of runs 098 and 099 that the record keeps compressed
for r in $RUNS; do
  grep -rlF "$HOME" "validation/$r" 2>/dev/null | while read -r f; do sed -i "s|$HOME|~|g" "$f"; done
  find "validation/$r" -name '*.gz' | while read -r f; do
    if gzip -dc "$f" | grep -qF "$HOME"; then gzip -dc "$f" | sed "s|$HOME|~|g" | gzip -n > "$f.new" && mv "$f.new" "$f"; fi
  done
done
case $P in
  a) d=validation/run_098_noslip_normal; find "$d/a" -type f \( -name '*.txt' -o -name '*.trace' \) ! -name stats.txt -exec gzip -n {} +
     d=validation/run_099_study_22; for a in rel off set5 set6; do find "$d/$a" -type f -name '*.txt' ! -name stats.txt -exec gzip -n {} +; done ;;
esac
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
