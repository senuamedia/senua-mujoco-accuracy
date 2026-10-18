#!/usr/bin/env bash
# Run 055: a design probe, not registered: it finds where to look and decides nothing. Two open questions of
# docs/issues.md:
#   1. Issue 16 (M14): MuJoCo's users report actuator and tendon behaviour that changes between releases. The record had
#      no rig with an actuator or a tendon; mjc_act is new (tools/mjc_act.c): the one-joint rig's arm driven by MuJoCo's
#      position, velocity, motor, filtered general, damper and muscle actuators, or held by a fixed or a spatial tendon
#      spring. Each scene at 2 and 0.5 ms, under MuJoCo's default integrator and implicitfast, 2 s, on Google DeepMind's
#      Linux releases 3.11.0 to 3.16.0 (as fetched and checked by run 053), each release's files compared by cmp with
#      3.16.0's, and the end states read beside the answers the scenes have.
#   2. Issue 20 (F13): MuJoCo's DiscreteImplicitRowNoslip scene never comes to rest. Run 050 found the cycle needs
#      rolling friction and noslip, and more noslip iterations at noslip's default tolerance change nothing. Does noslip
#      run to convergence (a noslip tolerance of 1e-12, MuJoCo's own option) stop it? The scene as run 049 took it from
#      MuJoCo's test file, 1,000 steps, at 2, 10, 100 and 1,000 noslip iterations with a noslip tolerance of 1e-12, on the
#      release and on the de Saxce patch's fourth version (Study 12's build). The scene rig gains noslip_tolerance,
#      unchanged without it: run 049 step 2's plays made again and compared by cmp with its files.
# Readings: file comparison by cmp; the rigs' columns, read by the awk lines below; the rigs' STATS fields.
# usage: probe.sh <work folder>   (repository root, on the cloud machine; the work folder holds the releases in
#        mujoco-3.11.0 to mujoco-3.16.0 and Study 12's build in mujoco-s12-build)
set -u
W="$(cd "${1:?usage: see the header}" && pwd)"; R="$(pwd)"; O="$R/validation/run_055_actuators_and_box"
REL="3.11.0 3.12.0 3.13.0 3.14.0 3.15.0 3.16.0"; SCENES="position velocity motor filter damper fixed spatial muscle"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
# 1. actuators and tendons across the releases
for v in $REL; do
  mj="$W/mujoco-$v"; X="$W/p55_$v"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    MUJOCO_DIR=$mj tools/build_rig.sh mjc_act > build_mjc_act.log 2>&1 || echo "$v mjc_act did not build" >> "$O/progress.txt"
    mkdir -p p; S=p/stats.txt; : > $S
    for g in def implicitfast; do
      if [ $g = def ]; then G=""; else G="integ=$g"; fi
      for dt in 0.002 0.0005; do
        for s in $SCENES; do
          # shellcheck disable=SC2086
          tools/mjc_act p/${s}_${g}_$dt.txt dt=$dt scene=$s secs=2 $G 2> p/${s}_${g}_$dt.err | sed "s|^STATS|STATS run ${s}_${g}_$dt|" >> $S
        done
      done
    done )
  rm -rf "${O:?}/r$v"; mkdir -p "$O/r$v"; cp -R "$X/p" "$X/build_mjc_act.log" "$O/r$v/"; rm -rf "${X:?}"
  log "$v played"
done
# 2. the box that never rests, with noslip run to convergence
SC="$R/validation/run_049_desaxce_v4/step2/scene.xml"; S49="$R/validation/run_049_desaxce_v4/step2"
for b in rel:$W/mujoco-3.16.0: on:$W/mujoco-s12-build:1; do
  n=${b%%:*}; rest=${b#*:}; mj=${rest%:*}; sw=${rest##*:}
  X="$W/p55box$n"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/" && (cd "$X" && MUJOCO_DIR=$mj tools/build_rig.sh mjc_scene > /dev/null 2>&1)
  mkdir -p "$O/box_$n"
  if [ -n "$sw" ]; then export MUJOCO_DESAXCE=$sw; else unset MUJOCO_DESAXCE; fi
  if [ $n = rel ]; then
    "$X/tools/mjc_scene" "$O/box_rel/identity_scene_rel.txt" scene="$SC" body=box axis=1,0,0 secs=3.2 key=0 > /dev/null
    echo "run 049 step 2's scene_rel.txt made again: $(cmp -s "$O/box_rel/identity_scene_rel.txt" "$S49/scene_rel.txt" && echo same || echo DIFFERS)" > "$O/box_rel/identity.txt"
  fi
  : > "$O/box_$n/stats.txt"
  for ns in 2 10 100 1000; do
    "$X/tools/mjc_scene" "$O/box_$n/ns${ns}_tol12.txt" scene="$SC" body=box axis=1,0,0 secs=16 key=0 noslip=$ns noslip_tolerance=1e-12 | sed "s|^STATS|STATS run ns${ns}_tol12|" >> "$O/box_$n/stats.txt"
  done
  unset MUJOCO_DESAXCE; rm -rf "${X:?}"
  log "box $n played"
done
# measuring
{
  for v in $REL; do
    [ "$v" = 3.16.0 ] && continue
    n=0; s=0; dl=""
    for f in $(cd "$O/r3.16.0/p" && ls | grep '\.txt$' | grep -v stats | sort); do n=$((n + 1)); if cmp -s "$O/r3.16.0/p/$f" "$O/r$v/p/$f"; then s=$((s + 1)); else dl="$dl ${f%.txt}"; fi; done
    echo "files $v against 3.16.0: $s of $n the same; differ:${dl:- none}"
  done
  for v in $REL; do
    for g in def implicitfast; do for dt in 0.002 0.0005; do for s in $SCENES; do
      f="$O/r$v/p/${s}_${g}_$dt.txt"
      if [ -s "$f" ]; then
        awk -v k="$v ${s}_${g}_$dt" 'NR > 1 { l = $0; if (NR == 2) first = $0 } END { split(l, e, " "); printf "%s end q1_urad %d qd1_urads %d q2_urad %d qd2_urads %d last %d\n", k, e[2], e[3], e[4], e[5], e[6] }' "$f"
      else
        echo "$v ${s}_${g}_$dt NOT PLAYED: $(head -c 200 "$O/r$v/p/${s}_${g}_$dt.err" | tr '\n' ' ')"
      fi
    done; done; done
  done
  # the fixed tendon's summed momentum (equal arms): the most |qd1 + qd2| over the play, urad/s
  for v in $REL; do for g in def implicitfast; do for dt in 0.002 0.0005; do
    f="$O/r$v/p/fixed_${g}_$dt.txt"
    [ -s "$f" ] && awk -v k="$v fixed_${g}_$dt" 'NR > 1 { x = $3 + $5; if (x < 0) x = -x; if (x > m) m = x } END { printf "%s summed_speed_most_urads %d\n", k, m }' "$f"
  done; done; done
  cat "$O/box_rel/identity.txt" | sed 's/^/box identity /'
  for n in rel on; do for ns in 2 10 100 1000; do
    awk -v s="box_${n}_ns${ns}_tol12" 'NR > 1 { v = $3 < 0 ? -$3 : $3; t = $1
           if (t >= 40 && t < 200) { if (v > 1000) a++; if (v > am) am = v } if (t == 199) e200 = $3
           if (t >= 840) { if (v > 1000) b++; if (v > bm) bm = v } last = $3 }
         END { printf "%s steps_40_199_over_1mms %d fastest_ums %d speed_at_200 %d steps_840_999_over_1mms %d fastest_ums %d speed_at_1000 %d\n", s, a, am, e200, b, bm, last }' "$O/box_$n/ns${ns}_tol12.txt"
    echo "box_${n}_ns${ns}_tol12 solver $(grep "^STATS run ns${ns}_tol12 " "$O/box_$n/stats.txt" | grep -o 'most_iterations [0-9]*\|at_iteration_limit [0-9]*\|warnings [0-9]*' | tr '\n' ' ')"
  done; done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
