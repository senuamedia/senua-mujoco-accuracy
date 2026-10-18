#!/usr/bin/env bash
# Run 089: a design probe, not registered: it finds where to look and decides nothing. Three parts.
#
# Part 1, issue 13, the discrete integrator depends on the order of equivalent rows (run 022: swapping the two rows of
# each pyramid pair of the leg press's one contact moves its endpoint by 0.8 mm and its convergence ratio from 0.52 to
# 0.74). legpress_order.c plays MuJoCo's own leg-press test and its mirror image, which in exact arithmetic gives the same
# joints with the pyramid's rows meeting the slip in the other order, on the release, at MuJoCo's default solver
# tolerance (1e-8, 100 iterations) and at 1e-12 and 1e-15 with 1,000 iterations. If the two agree once the solver is
# held tighter, the order enters only through where the solver stops.
#
# Part 2, issue 1's new case (Study 20's H1): a free cube pushed square to a face at 0.95 of its limit creeps in Senua
# AI's set. Study 20's cube b, condim 3, at 1.277 ms, along 0 degrees (creeps) and 22.5 (holds), released and in Senua
# AI's set (Study 20's build of its five validated patch files, mujoco-s20v1-build, every switch set), under Senua AI's
# configuration, traced (the contact rig's trace: each contact's place, normal force and friction against its limit,
# and the cube's tilt and turn); also free to tilt but not to turn (noyaw), and held from turning.
#
# Part 3, issue 9, a stack sinks, deeper under the elliptic cone. MuJoCo sets a pyramidal contact's four edges one
# softness, chosen to match the elliptic cone's friction, 2 mu^2 times the normal's (engine_core_constraint.c, its own
# comment: "D0_el = 2*mu^2*D_py: friction match"), so its normal is stiffer than the elliptic cone's by 2 / mu^2 for
# condim 3. A cube's depth at rest, set down from 20 mm, at 1 ms, by each cone, at frictions 0.2 to 2, released; and run
# 078's offset stacks (3 cubes, 1 and 17 mm a cube) in Senua AI's set under the configuration, at its two steps.
#
# Readings: Senua AI's measures (sx_contact creep), the rigs' own columns, MuJoCo's own numbers printed by legpress_order.
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds the release in mujoco-3.16.0 and Study 20's build in mujoco-s20v1-build)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_089_order_free_cube_stacks"; : > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
REL="$W/mujoco-3.16.0"; SET="$W/mujoco-s20v1-build"; REC="cone=elliptic noslip=100"
sw() { unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT
  if [ "$1" = 1 ]; then export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1; fi; }
X=$(mktemp -d); mkdir -p "$X/rel" "$X/set"
for a in rel:$REL set:$SET; do
  n=${a%%:*}; mj=${a#*:}; cp -R "$R/tools" "$X/$n/"
  ( cd "$X/$n" && for r in mjc_contact mjc_stack; do MUJOCO_DIR=$mj tools/build_rig.sh $r > /dev/null; done )
done
cc -O2 -std=c11 -Wall -Wextra -I"$REL/include" -o "$X/legpress_order" "$O/legpress_order.c" -L"$REL/lib" -Wl,-rpath,"$REL/lib" -lmujoco -lm > "$O/build_legpress.log" 2>&1
mkdir -p "$X/p"
# ---- part 1
sw 0
{
  for t in default:"" 1e-12:"1e-12 1000" 1e-15:"1e-15 1000"; do
    tn=${t%%:*}; ta=${t#*:}
    for mi in 0 1; do echo "tolerance $tn"; "$X/legpress_order" $mi $ta; done
  done
} > "$O/reading_legpress.txt"
log "part 1 played"
# ---- part 2
CB="mass=0.819 radius=0.0316 mu=0.734"; LIM=$(awk 'BEGIN { printf "%.6f", 0.819 * 0.734 * 9.8 }')
PU=$(awk -v l="$LIM" 'BEGIN { printf "%.6f", 0.95 * l }')
{
  for a in rel set; do
    if [ $a = set ]; then sw 1; else sw 0; fi
    for v in free:"lock=0" noyaw:"lock=0 noyaw=1" held:"lock=1"; do
      vn=${v%%:*}; vo=${v#*:}
      for dir in 0 22.5; do
        f=free_${a}_${vn}_$dir
        # shellcheck disable=SC2086
        "$X/$a/tools/mjc_contact" "$X/p/$f.txt" dt=0.001277 h0=0 $CB push=$PU pushat=0.4 secs=1.6 dir=$dir $vo $REC trace="$X/p/$f.trace" > "$X/p/$f.stats"
        echo "$a $vn $dir | $("$B" creep "$X/p/$f.txt" | tail -1) | $(grep -o 'most_yaw_urad [0-9-]*\|most_tilt_urad [0-9-]*\|steps_under_4_contacts [0-9-]*\|yaw_end_urad [0-9-]*' "$X/p/$f.stats" | tr '\n' ' ')"
      done
    done
  done
  sw 0
} > "$O/reading_free_cube.txt"
log "part 2 played"
# ---- part 3
depth() { awk -v a="$2" 'NR == 1 { for (i = 1; i < NF; i++) if ($i == "dt_ns") dt = $(i + 1); next }
  { t = $1 * dt / 1e9; if (t >= a) { n++; s += $2; v = $4 < 0 ? -$4 : $4; if (v > vm) vm = v } }
  END { if (n == 0) { print "depth_nm missing fastest_vz_ums missing"; exit } printf "depth_nm %d fastest_vz_ums %d", s / n, vm }' "$1"; }
{
  for mu in 0.2 0.4 0.7 1 1.41421356 2; do
    for cone in pyramidal elliptic; do
      f=depth_${cone}_$mu
      "$X/rel/tools/mjc_contact" "$X/p/$f.txt" dt=0.001 h0=0.02 mu=$mu secs=2 cone=$cone > "$X/p/$f.stats"
      echo "depth $cone mu $mu | $(depth "$X/p/$f.txt" 1.5)"
    done
  done
} > "$O/reading_depth.txt"
sw 1
{
  KCUBE="mass=0.442 radius=0.0424 mu=0.524"
  for dt in 0.000285 0.00114; do for sh in 0.001 0.017; do
    q=offset${sh#0.}_set_$dt
    # shellcheck disable=SC2086
    "$X/set/tools/mjc_stack" "$X/p/$q" dt=$dt n=3 shift=$sh secs=2 $KCUBE $REC contacts="$X/p/$q.contacts" > "$X/p/$q.stats"
    tilt=$(cat "$X/p/${q}"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }')
    turn=$(for f in "$X/p/${q}"_*_tilt.txt; do awk '$1 != "CONTACT" { l = $3 } END { print (l < 0 ? -l : l) + 0 }' "$f"; done | sort -n | tail -1)
    ch=$(awk '{ k = $2 "-" $3; if ($1 != cs) { if (cs != "") for (p in c) { if (cs > 30 && c[p] != pc[p]) n++; pc[p] = c[p]; c[p] = 0 } cs = $1 } c[k]++ } END { print n + 0 }' "$X/p/$q.contacts")
    echo "$q most_tilt_urad $tilt fastest_turn_at_end_urad_s $turn contact_changes_after_step_30 $ch most_contacts $(grep -o 'most_contacts [0-9]*' "$X/p/$q.stats" | awk '{ print $2 }')"
    gzip -n -9 "$X/p/$q.contacts"
  done; done
} > "$O/reading_stacks.txt"
sw 0
log "part 3 played"
for f in "$X"/p/*.txt "$X"/p/*.trace; do [ -f "$f" ] && [ "$(wc -c < "$f")" -gt 200000 ] && gzip -n "$f"; done
rm -rf "$O/p"; cp -R "$X/p" "$O/p"; rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished.txt"
