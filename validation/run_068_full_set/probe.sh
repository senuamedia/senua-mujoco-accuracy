#!/usr/bin/env bash
# Run 068: a design probe, not registered: it finds where to look and decides nothing. Senua AI's set, as this record
# has validated its parts: the configuration (the elliptic cone, 100 noslip iterations; Studies 2, 10 and 13); the
# inverse weight in the current pose, third version (patches/invweight_at_pose_v3.diff, MUJOCO_INVWEIGHT_AT_POSE=1,
# engine_core_constraint.c; Studies 8 to 10); de Saxce's correction (patches/desaxce_elliptic_v4.diff, MUJOCO_DESAXCE=1,
# engine_forward.c; Study 12); and, in design, the friction solved in the directions that can move
# (patches/in_design/qcqp_reduced.diff, MUJOCO_QCQP_REDUCED=1, engine_solver.c; Study 14, 13 of 15). Run 066 plays the
# last two together; this plays all three patches in one build, before a registration of the set together. Arms: rel,
# MuJoCo 3.16.0 as released; off, the build with the three patches and every switch unset; all, every switch set; under
# the configuration with MuJoCo's default integrator, and rel_rk4 and all_rk4 the same under RK4 (Study 10's two
# integrators). On run 066's scenes and numbers: run 063's (Study 10's) cubes, grips, stacks, the slide on a box's face,
# the arm held by joint friction, Study 10's and Study 13's arms set down and dropped (3 s), at 1.14 and 0.285 ms; Study
# 14's arm set down and dropped (3 s) at 1.19 and 0.2975 ms; run 049's box scene (its own options, in every arm alike);
# the first contact suite on run 063's
# cube and on Study 14's. MuJoCo's own test suite on the build, every switch unset and every switch set.
# Readings: Senua AI's measures (sx_contact creep, stop; the first deep dive's suite runner), file comparison by cmp, the
# rigs' columns and STATS fields. A dropped arm's last moving time is the last step at which the ball's speed along x or
# z is more than 10 um/s.
# usage: probe.sh <folder holding sx_contact and sx_contact_suite.sh> <work folder>   (repository root, on the cloud
#        machine; the work folder holds mujoco-src at UPSTREAM_COMMIT and the release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_068_full_set"; REL="$W/mujoco-3.16.0"; QB="$W/mujoco-p68-build"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
PI="$R/patches/invweight_at_pose_v3.diff"; PD="$R/patches/desaxce_elliptic_v4.diff"; PQ="$R/patches/in_design/qcqp_reduced.diff"
rm -rf "${W:?}/mujoco-p68-src" "$W/p68-lib" "$QB" "$W/t68" && mkdir -p "$W/mujoco-p68-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p68-src"
(cd "$W/mujoco-p68-src" && patch -p1 -s < "$PI" && patch -p1 -s < "$PD" && patch -p1 -s < "$PQ")
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(sha256sum "$PI" | cut -c1-16) $(sha256sum "$PD" | cut -c1-16) $(sha256sum "$PQ" | cut -c1-16)" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p68-src" -B "$W/p68-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$QB" && cmake --build "$W/p68-lib" -j"$J" && cmake --install "$W/p68-lib" ) > "$O/build_lib.log" 2>&1
log "build lib exit $?"
( cmake -S "$W/mujoco-p68-src" -B "$W/t68" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t68" -j"$J" ) > "$O/build_tests.log" 2>&1
log "build tests exit $?"
switches() {  # <1 to set every switch, empty to unset them>
  if [ -n "$1" ]; then export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1
  else unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED; fi
}
KCUBE="mass=0.442 radius=0.0424 mu=0.524"; CUBE="mass=1.861 radius=0.0434 mu=0.39"
LIM=$(awk 'BEGIN { printf "%.6f", 0.39 * 1.861 * 9.8 }'); GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"
A10="len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717"
A13="len1=0.297 len2=0.302 mass1=1.08 mass2=0.578 rb=0.0295 mb=0.194 mu=0.778"
A14="len1=0.298 len2=0.269 mass1=1.164 mass2=0.522 rb=0.0273 mb=0.167 mu=0.667"
mir() { awk -v p="$1" 'BEGIN { split(p, a, ","); printf "%.15g,%.15g", 3.14159265358979323846 - a[1], -a[2] }'; }
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"
ARMS="rel off all rel_rk4 all_rk4"
for a in $ARMS; do
  case $a in rel|rel_rk4) mj=$REL ;; *) mj=$QB ;; esac
  case $a in all|all_rk4) sw=1 ;; *) sw="" ;; esac
  case $a in *_rk4) REC="cone=elliptic noslip=100 integ=RK4" ;; *) REC="cone=elliptic noslip=100" ;; esac
  X="$W/p68$a"; rm -rf "$X"; mkdir -p "$X/suites" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_stack mjc_grip mjc_arm mjc_scene; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null 2>&1; done
    switches "$sw"
    mkdir -p p arms; S=p/stats.txt; T=arms/stats.txt; : > $S; : > $T
    for dt in 0.00114 0.000285; do
      for dir in 0 22.5 45; do
        for fr in 0.5 0.75 0.95; do
          pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
          # shellcheck disable=SC2086
          tools/mjc_contact p/hold_${dir}_${fr}_$dt.txt dt=$dt h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=$dir $REC | sed "s|^STATS|STATS run hold_${dir}_${fr}_$dt|" >> $S
        done
        # shellcheck disable=SC2086
        tools/mjc_contact p/slide_${dir}_$dt.txt dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 dir=$dir $REC | sed "s|^STATS|STATS run slide_${dir}_$dt|" >> $S
        # shellcheck disable=SC2086
        tools/mjc_contact p/free_${dir}_$dt.txt dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 lock=0 dir=$dir $REC | sed "s|^STATS|STATS run free_${dir}_$dt|" >> $S
      done
      for off in 0 0.0093; do for pad in box mesh; do
        # shellcheck disable=SC2086
        tools/mjc_grip p/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $REC | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> $S
      done; done
      # shellcheck disable=SC2086
      for n in 5 9; do tools/mjc_stack p/stack${n}_$dt dt=$dt n=$n secs=2 $KCUBE $REC | sed "s|^STATS|STATS run stack${n}_$dt|" >> $S; done
      # shellcheck disable=SC2086
      tools/mjc_stack p/offset3_$dt dt=$dt n=3 shift=0.017 secs=2 $KCUBE $REC | sed "s|^STATS|STATS run offset3_$dt|" >> $S
      # shellcheck disable=SC2086
      tools/mjc_stack p/slide_box_$dt dt=$dt n=1 vx=1.16 secs=1 base=0.5 $KCUBE $REC | sed "s|^STATS|STATS run slide_box_$dt|" >> $S
      k=0
      for PS in 0.245,0.831 0.223,0.993; do
        k=$((k + 1))
        # shellcheck disable=SC2086
        tools/mjc_arm arms/jf_pose${k}_$dt.txt dt=$dt pose=$PS pose0=$PS jointfriction=5.96 h0=1 secs=2 $A10 $REC | sed "s|^STATS|STATS run jf_pose${k}_$dt|" >> $T
      done
      for set in s10:0.604,1.158:1 s10:1.149,-0.545:2 s13:0.516,0.907:1 s13:1.211,-0.464:2; do
        an=${set%%:*}; rest=${set#*:}; PS=${rest%:*}; k=${rest##*:}
        if [ $an = s10 ]; then A=$A10; H=0.00059; else A=$A13; H=0.00052; fi
        for side in as mirror; do
          if [ $side = as ]; then Q=$PS; else Q=$(mir "$PS"); fi
          # shellcheck disable=SC2086
          tools/mjc_arm arms/${an}_pose${k}_${side}_rest_$dt.txt dt=$dt pose=$Q pose0=$Q $A h0=$H secs=2 $REC | sed "s|^STATS|STATS run ${an}_pose${k}_${side}_rest_$dt|" >> $T
        done
        # shellcheck disable=SC2086
        tools/mjc_arm arms/${an}_pose${k}_drop_$dt.txt dt=$dt pose=$PS pose0=$PS $A h0=0.0121 secs=3 $REC | sed "s|^STATS|STATS run ${an}_pose${k}_drop_$dt|" >> $T
      done
    done
    for dt in 0.00119 0.0002975; do
      k=0
      for PS in 0.582,1.117 1.227,-0.516 0.58,0.969 1.276,-0.407; do
        k=$((k + 1))
        for side in as mirror; do
          if [ $side = as ]; then Q=$PS; else Q=$(mir "$PS"); fi
          # shellcheck disable=SC2086
          tools/mjc_arm arms/s14_pose${k}_${side}_rest_$dt.txt dt=$dt pose=$Q pose0=$Q $A14 h0=0.00054 secs=2 $REC | sed "s|^STATS|STATS run s14_pose${k}_${side}_rest_$dt|" >> $T
        done
        # shellcheck disable=SC2086
        tools/mjc_arm arms/s14_pose${k}_drop_$dt.txt dt=$dt pose=$PS pose0=$PS $A14 h0=0.0146 secs=3 $REC | sed "s|^STATS|STATS run s14_pose${k}_drop_$dt|" >> $T
      done
    done
    # the box scene carries its own options (MuJoCo's test scene, its own integrator), in every arm alike
    tools/mjc_scene p/box.txt scene="$SCN" body=box axis=1,0,0 secs=16 key=0 | sed "s|^STATS|STATS run box|" >> $S
    # shellcheck disable=SC2086
    ( export SUITE_CUBE="mass=0.881 radius=0.0392" SUITE_H0=0.096 SUITE_VX=3.24 SUITE_VXCHAIN=1.47 SUITE_MU=0.371 SUITE_VSLIDE=3.67 \
        SUITE_MUHOLD=0.421 SUITE_HOLD=2.180898 SUITE_SLIP=4.361796 SUITE_LIFT=25.9014
      tools/contact_suite.sh fresh $REC > /dev/null )
    # shellcheck disable=SC2086
    ( export SUITE_CUBE="mass=1.7 radius=0.0426" SUITE_H0=0.07 SUITE_VX=3.36 SUITE_VXCHAIN=1.45 SUITE_MU=0.413 \
        SUITE_VSLIDE=4.53 SUITE_MUHOLD=0.443 SUITE_HOLD=4.428228 SUITE_SLIP=8.856456 SUITE_LIFT=49.98
      tools/contact_suite.sh fresh14 $REC > /dev/null ) )
  rm -rf "${O:?}/${a:?}"; mkdir -p "$O/$a"; cp -R "$X/p" "$X/arms" "$X/suites" "$O/$a/"; rm -rf "${X:?}"
  log "$a played"
done
switches ""
# MuJoCo's own test suite on the build: every switch unset, and every switch set; the two memory-heavy texture tests alone
for n in off all; do
  ( cd "$W/t68" && if [ $n = all ]; then switches 1; else switches ""; fi
    ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$n.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_${n}_large.txt" 2>&1 )
  log "suite $n $(grep -E 'tests passed|tests failed' "$O/ctest_$n.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_${n}_large.txt" | tail -1)"
done
for n in off all; do
  cat "$O/ctest_$n.txt" "$O/ctest_${n}_large.txt" | awk 'match($0, /Test +#[0-9]+: /) {
         hdr = substr($0, RSTART, RLENGTH); num = hdr; gsub(/[^0-9]/, "", num); rest = substr($0, RSTART + RLENGTH)
         st = "unknown"
         if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) {
           st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st) }
         name = rest; p = index(name, "  # GetParam()"); if (p > 0) name = substr(name, 1, p - 1)
         p = index(name, " ..."); if (p > 0) name = substr(name, 1, p - 1); sub(/ +$/, "", name)
         print num, name, st }' | sort -n > "$O/suite_results_$n.txt"
done
diff "$O/suite_results_off.txt" "$O/suite_results_all.txt" | grep '^>' | sed 's/^> /changed with every switch set: /' > "$O/suite_changed_all.txt"
# measuring
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
stk() {  # <prefix>: the most tilt of any cube over the play; at the last step the largest speed (vx or vz)
  local p=$1 t s
  t=$(cat "$p"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }')
  s=$(for f in "$p"_[0-9].txt; do tail -1 "$f"; done | awk '{ x = $3 < 0 ? -$3 : $3; y = $4 < 0 ? -$4 : $4; if (x > m) m = x; if (y > m) m = y } END { print m + 0 }')
  echo "most_tilt_urad $t end_speed_ums $s"
}
lastmove() {  # <arm play file>: the last time, s, at which the ball's speed along x or z is more than 10 um/s
  awk '$1 == "CONTACT" { for (i = 1; i < NF; i++) if ($i == "dt_ns") d = $(i + 1); next }
       { x = $3 < 0 ? -$3 : $3; z = $4 < 0 ? -$4 : $4; if (x > 10 || z > 10) l = $1 + 1 }
       END { printf "%.4f", l * d / 1e9 }' "$1"
}
for a in $ARMS; do
  SUITE_MU10K=3710 SUITE_SLIPMN=4361 bash "$M/sx_contact_suite.sh" "$O/$a/suites/1/fresh" "$O/$a/suite1.txt" > /dev/null 2>&1
  SUITE_MU10K=4130 SUITE_SLIPMN=8856 bash "$M/sx_contact_suite.sh" "$O/$a/suites/1/fresh14" "$O/$a/suite1_14.txt" > /dev/null 2>&1
done
{
  for pair in rel:off rel:all rel_rk4:all_rk4; do
    x=${pair%%:*}; y=${pair#*:}; n=0; s=0
    for f in $(cd "$O/$x" && find p arms suites -type f ! -name stats.txt ! -name CONFIG | sort); do n=$((n + 1)); cmp -s "$O/$x/$f" "$O/$y/$f" && s=$((s + 1)); done
    echo "files $x against $y: $s of $n the same"
  done
  for a in rel all rel_rk4 all_rk4; do
    for dt in 0.00114 0.000285; do
      echo "$a holds $dt $(for dir in 0 22.5 45; do for fr in 0.5 0.75 0.95; do fld "$("$B" creep "$O/$a/p/hold_${dir}_${fr}_$dt.txt" | tail -1)" mean_speed_ums; done; done | tr '\n' ' ')"
      echo "$a slides $dt slid_um $(for dir in 0 22.5 45; do fld "$("$B" stop "$O/$a/p/slide_${dir}_$dt.txt" | tail -1)" slid_um; done | tr '\n' ' ') free slid_um $(for dir in 0 22.5 45; do fld "$("$B" stop "$O/$a/p/free_${dir}_$dt.txt" | tail -1)" slid_um; done | tr '\n' ' ')"
      echo "$a grips $dt $(for off in 0 0.0093; do for pad in box mesh; do fld "$("$B" creep "$O/$a/p/grip_${pad}_off${off}_$dt.txt" | tail -1)" mean_speed_ums; done; done | tr '\n' ' ')"
      for set in s10_pose1 s10_pose2 s13_pose1 s13_pose2; do
        for side in as mirror; do echo "$a ${set}_${side}_rest_$dt creep_ums $(fld "$("$B" creep "$O/$a/arms/${set}_${side}_rest_$dt.txt" | tail -1)" mean_speed_ums)"; done
        n=${set}_drop_$dt
        echo "$a $n creep_ums $(fld "$("$B" creep "$O/$a/arms/$n.txt" | tail -1)" mean_speed_ums) last_moving_s $(lastmove "$O/$a/arms/$n.txt")"
      done
      for k in 1 2; do echo "$a jf_pose${k}_$dt creep_ums $(fld "$("$B" creep "$O/$a/arms/jf_pose${k}_$dt.txt" | tail -1)" mean_speed_ums)"; done
      for s in stack5 stack9 offset3; do echo "$a ${s}_$dt $(stk "$O/$a/p/${s}_$dt")"; done
    done
    for dt in 0.00119 0.0002975; do
      for k in 1 2 3 4; do
        for side in as mirror; do echo "$a s14_pose${k}_${side}_rest_$dt creep_ums $(fld "$("$B" creep "$O/$a/arms/s14_pose${k}_${side}_rest_$dt.txt" | tail -1)" mean_speed_ums)"; done
        n=s14_pose${k}_drop_$dt
        echo "$a $n creep_ums $(fld "$("$B" creep "$O/$a/arms/$n.txt" | tail -1)" mean_speed_ums) last_moving_s $(lastmove "$O/$a/arms/$n.txt")"
      done
    done
    echo "$a box $(tail -1 "$O/$a/p/box.txt")"
    echo "$a suite1 passed $(grep '^SUITE passed' "$O/$a/suite1.txt" | awk '{ print $3 }') | suite1 on Study 14's cube passed $(grep '^SUITE passed' "$O/$a/suite1_14.txt" | awk '{ print $3 }') $(grep '^T08' "$O/$a/suite1_14.txt")"
    echo "$a solver most_iterations $(cat "$O/$a/p/stats.txt" "$O/$a/arms/stats.txt" | grep -o 'most_iterations [0-9]*' | awk '{ if ($2 > x) x = $2 } END { print x + 0 }') at_iteration_limit $(cat "$O/$a/p/stats.txt" "$O/$a/arms/stats.txt" | grep -o 'at_iteration_limit [0-9]*' | awk '{ s += $2 } END { print s + 0 }') warnings $(cat "$O/$a/p/stats.txt" "$O/$a/arms/stats.txt" | grep -o 'warnings [0-9]*' | awk '{ s += $2 } END { print s + 0 }')"
  done
  echo "MuJoCo suite: $(wc -l < "$O/suite_results_off.txt" | tr -d ' ') tests; changed with every switch set: $(wc -l < "$O/suite_changed_all.txt" | tr -d ' ')"
  echo "MuJoCo suite, every switch unset against the release (run 064's suite_results_release.txt): $(diff "$R/validation/run_064_study_14/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>') tests read differently"
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
