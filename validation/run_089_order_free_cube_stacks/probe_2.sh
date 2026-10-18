#!/usr/bin/env bash
# Run 089, step 2: written after step 1's readings and pushed before its plays.
#
# Step 1 found the leg press and its mirror image the same to 12 digits at every tolerance: swapping each first pyramid
# pair against the slip changes nothing in the release. Run 022's patch turned the contact by 180 degrees, which swaps
# both pairs. Part 1 turns the floor about the vertical (0, 90, 180, 270 degrees) in the release, at MuJoCo's default
# tolerance and at 1e-15 with 1,000 iterations (legpress_order_2.c).
#
# Step 1 found the free cube's two back contacts at their friction limit and sliding while its two front contacts had
# 6 to 8% of theirs unused, so a sharing that holds exists and noslip, solved contact by contact on a problem with many
# solutions, stops short of it. Part 2 plays that cube (Study 20's cube b, condim 3, 0.95 of its limit along 0 degrees,
# 1.277 ms, Senua AI's set under the configuration) with MuJoCo's noslip_tolerance at its default (1e-6) and at 1e-9,
# 1e-12 and 1e-15, with 100 noslip iterations and with 1,000. Part 3 plays run 078's offset stacks in the set at 1.14 ms
# the same way, and with the elliptic cone and no noslip.
# usage: probe_2.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_089_order_free_cube_stacks"; date -u +%FT%TZ > "$O/played_at_2.txt"
REL="$W/mujoco-3.16.0"; SET="$W/mujoco-s20v1-build"
sw() { unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT
  if [ "$1" = 1 ]; then export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1; fi; }
X=$(mktemp -d); cp -R "$R/tools" "$X/"
( cd "$X" && for r in mjc_contact mjc_stack; do MUJOCO_DIR=$SET tools/build_rig.sh $r > /dev/null; done )
cc -O2 -std=c11 -Wall -Wextra -I"$REL/include" -o "$X/legpress_order_2" "$O/legpress_order_2.c" -L"$REL/lib" -Wl,-rpath,"$REL/lib" -lmujoco -lm > "$O/build_legpress_2.log" 2>&1
mkdir -p "$X/p2"
# ---- part 1
sw 0
{
  for t in default:"" 1e-15:"1e-15 1000"; do
    tn=${t%%:*}; ta=${t#*:}
    for yaw in 0 90 180 270; do
      echo "tolerance $tn"
      # shellcheck disable=SC2086
      if [ -z "$ta" ]; then "$X/legpress_order_2" 0 1e-8 100 $yaw; else "$X/legpress_order_2" 0 $ta $yaw; fi
    done
  done
} > "$O/reading_legpress_2.txt"
# ---- part 2
sw 1
CB="mass=0.819 radius=0.0316 mu=0.734"; PU=$(awk 'BEGIN { printf "%.6f", 0.95 * 0.819 * 0.734 * 9.8 }')
{
  for ni in 100 1000; do for nt in default 1e-9 1e-12 1e-15; do
    if [ $nt = default ]; then NT=""; else NT="noslip_tolerance=$nt"; fi
    f=free_set_n${ni}_t$nt
    # shellcheck disable=SC2086
    "$X/tools/mjc_contact" "$X/p2/$f.txt" dt=0.001277 h0=0 $CB push=$PU pushat=0.4 secs=1.6 dir=0 lock=0 cone=elliptic noslip=$ni $NT trace="$X/p2/$f.trace" > "$X/p2/$f.stats"
    back=$(awk 'NR > 627 { for (k = 0; k < $4; k++) if ($(5 + 5 * k) < 0 && $(9 + 5 * k) > m) m = $(9 + 5 * k) } END { print m + 0 }' "$X/p2/$f.trace")
    echo "noslip $ni tolerance $nt | $("$B" creep "$X/p2/$f.txt" | tail -1) | most_tilt_urad $(grep -o 'most_tilt_urad [0-9-]*' "$X/p2/$f.stats" | awk '{ print $2 }') | back contacts' highest ratio to the limit, second half, ppm $back"
  done; done
} > "$O/reading_free_cube_2.txt"
# ---- part 3
{
  KCUBE="mass=0.442 radius=0.0424 mu=0.524"
  for cfg in n100_tdefault:"cone=elliptic noslip=100" n1000_t1e-15:"cone=elliptic noslip=1000 noslip_tolerance=1e-15" elliptic_alone:"cone=elliptic"; do
    cn=${cfg%%:*}; co=${cfg#*:}
    for sh in 0.001 0.017; do
      q=offset${sh#0.}_set_${cn}
      # shellcheck disable=SC2086
      "$X/tools/mjc_stack" "$X/p2/$q" dt=0.00114 n=3 shift=$sh secs=2 $KCUBE $co contacts="$X/p2/$q.contacts" > "$X/p2/$q.stats"
      tilt=$(cat "$X/p2/${q}"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }')
      turn=$(for f in "$X/p2/${q}"_*_tilt.txt; do awk '$1 != "CONTACT" { l = $3 } END { print (l < 0 ? -l : l) + 0 }' "$f"; done | sort -n | tail -1)
      ch=$(awk '{ k = $2 "-" $3; if ($1 != cs) { if (cs != "") for (p in c) { if (cs > 30 && c[p] != pc[p]) n++; pc[p] = c[p]; c[p] = 0 } cs = $1 } c[k]++ } END { print n + 0 }' "$X/p2/$q.contacts")
      echo "$q most_tilt_urad $tilt fastest_turn_at_end_urad_s $turn contact_changes_after_step_30 $ch"
      gzip -n -9 "$X/p2/$q.contacts"
    done
  done
} > "$O/reading_stacks_2.txt"
sw 0
for f in "$X"/p2/*.txt "$X"/p2/*.trace; do [ -f "$f" ] && [ "$(wc -c < "$f")" -gt 200000 ] && gzip -n "$f"; done
rm -rf "$O/p2"; cp -R "$X/p2" "$O/p2"; rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished_2.txt"
