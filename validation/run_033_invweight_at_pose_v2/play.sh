#!/usr/bin/env bash
# Run 033, a patch in design (not registered): the inverse weight in the current pose, second version,
# patches/in_design/invweight_at_pose_v2.diff, switch MUJOCO_INVWEIGHT_AT_POSE=1. Run 032 found finding F10 reaching joint
# limits through dof_invweight0, which the first version (run 029) leaves frozen at qpos0. The second version is the first
# with the joint weights of joint limits and joint friction (dof_invweight0) also taken in the current pose, by the formula
# mj_setConst uses at qpos0; the stock lines are kept, the at-pose value assigned after them only with the switch set.
# Every other line below is run 029's runner, with these changes: run 032's swing on an elbow limit added to each arm's plays
# and to checks 1 and 2, and the creep check's bound set at the measure's resolution, 1 um/s (run 029's 1 part in 1,000
# rounds to 0 for a creep under 1 mm/s); all fixed before any play.
#
# Run 029's header, for the first version:
# patches/in_design/invweight_at_pose.diff, switch MUJOCO_INVWEIGHT_AT_POSE=1. MuJoCo sets each contact's
# regularisation from its two bodies' inverse weights, body_invweight0, which mj_setConst computes once in the pose a
# model is written in (qpos0). With the switch set, mj_diagApprox takes each contact body's weight in the pose the body
# is in, by exactly the formula mj_setConst uses (engine_setconst.c: the average diagonal of J inv(M) J' at the body's
# centre of mass, or 1/mass for a body that only slides). It keeps MuJoCo's approximation, one regularisation for the
# four edges of a contact's pyramid, and changes only the pose it is taken in: the first of the three sources of error
# MuJoCo's documentation names, not the other two. MuJoCo's own diagexact flag removes all three and makes symmetric
# scenes turn under the default cone (run 028). Only contacts are changed; joint limits and equality constraints keep
# their weights from qpos0. A free body's or a sliding body's translational weight does not depend on its pose, so on
# every scene of cubes the patch should change nothing.
# Three arms, each in its own scratch copy, the rigs built against: release (Google DeepMind's Linux release), off (the
# patched build, switch unset), on (switch set). Each plays both of the first deep dive's contact suites, run 025's arm
# (two poses, rest and drop, 2 and 0.5 ms, written native, straight and folded) under MuJoCo's defaults and with the
# elliptic cone and 10 noslip iterations, run 026's stacks and slides, and run 027's grips at 2 ms. MuJoCo's own test
# suite runs on the release's test build (run 020's) and on the patched one, switch unset and set.
# The five checks, fixed before any play, each judged by sx_contact rule:
#   1 required     release, MuJoCo's defaults: in every pose, scene and step the arm written straight ends at least
#                  1 um from the arm written in its own pose (runs 025: 13 to 65 um)
#   2 correct      switch on, MuJoCo's defaults: in every pose, scene and step the arm written straight and written
#                  folded each end within 100 nm and 10 um/s of the arm written in its own pose (MuJoCo's diagexact,
#                  run 028: within 17 nm); and the ball's creep in the rest scene the same in all three writings,
#                  within 1 part in 1,000
#   3 nothing else gets worse   switch on: both suites, the stacks, the slides and the grips byte-identical to the
#                  release; in MuJoCo's suite, switch set against unset, no test changes
#   4 safe when off   the off arm byte-identical to the release, every file; MuJoCo's whole suite, switch unset, test
#                  for test as the release
#   5 the solver keeps converging   switch on: no play at the iteration limit, no warning
# Reported, not judged: the arm with the elliptic cone and noslip; the arm's depths and creep in each writing.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src, the release in mujoco-3.16.0, and
#        run 020's release test build in t20-release)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
P="$R/patches/in_design/invweight_at_pose_v2.diff"; O="$R/validation/run_033_invweight_at_pose_v2"
mkdir -p "$O"; : > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
# ---- the patched source, its library (for the rigs) and its tests, from the patch file
rm -rf "$W/mujoco-iw2-src" && mkdir -p "$W/mujoco-iw2-src" && (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-iw2-src"
(cd "$W/mujoco-iw2-src" && patch -p1 -s < "$P")
echo "release source $(git -C "$W/mujoco-src" rev-parse HEAD); patch $(sha256sum "$P" | cut -c1-16)" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-iw2-src" -B "$W/iw2-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$W/mujoco-iw2-build" && cmake --build "$W/iw2-lib" -j"$J" && cmake --install "$W/iw2-lib" ) > "$O/build_lib.log" 2>&1
echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
( cmake -S "$W/mujoco-iw2-src" -B "$W/t33-iw2" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t33-iw2" -j"$J" ) > "$O/build_tests.log" 2>&1
echo "build tests exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
grep -i "engine_core_constraint.c.*warning" "$O/build_lib.log" "$O/build_tests.log" > "$O/patch_warnings.txt"
# ---- the plays, the same in each arm
arm() {  # <name> <MuJoCo folder> [switch]
  local name=$1 mj=$2 sw=${3:-} X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"; mkdir -p "$X/suites"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_pair mjc_arm mjc_stack mjc_grip; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
    if [ -n "$sw" ]; then export MUJOCO_INVWEIGHT_AT_POSE=$sw; else unset MUJOCO_INVWEIGHT_AT_POSE; fi
    tools/contact_suite.sh defaults > /dev/null; tools/contact_suite2.sh defaults > /dev/null
    mkdir -p runs; S=runs/stats.txt; : > $S
    for cfg in defaults recommended; do
      if [ $cfg = recommended ]; then set -- cone=elliptic noslip=10; else set --; fi
      for pose in A B; do
        case $pose in A) PS=0.5,1.2 ;; B) PS=1.1,-0.6 ;; esac
        for scene in rest drop; do
          case $scene in rest) SC="h0=0 secs=2" ;; drop) SC="h0=0.01 secs=1" ;; esac
          for dt in 0.002 0.0005; do for wr in native straight folded; do
            case $wr in native) P0=$PS ;; straight) P0=0,0 ;; folded) P0=0,2.5 ;; esac
            f=runs/arm_${cfg}_${pose}_${scene}_${dt}_$wr.txt
            # shellcheck disable=SC2086
            tools/mjc_arm $f dt=$dt pose=$PS pose0=$P0 $SC "$@" | sed "s|^STATS|STATS run $(basename $f .txt)|" >> $S
          done; done
        done
      done
    done
    for pose in E F; do
      case $pose in E) PS=0,0.6; L=-2,0.6 ;; F) PS=0.4,1.0; L=-2,1.0 ;; esac
      for dt in 0.002 0.0005; do for wr in native straight folded; do
        case $wr in native) P0=$PS ;; straight) P0=0,0 ;; folded) P0=0,2.5 ;; esac
        tools/mjc_arm runs/swing_${pose}_${dt}_$wr.txt dt=$dt pose=$PS pose0=$P0 elbowlimit=$L h0=1 secs=2 | sed "s|^STATS|STATS run swing_${pose}_${dt}_$wr|" >> $S
      done; done
    done
    mkdir -p cubes
    for dt in 0.002 0.0005; do
      for n in 3 5 10; do tools/mjc_stack cubes/stack${n}_$dt dt=$dt n=$n secs=2 | sed "s|^STATS|STATS run stack${n}_$dt|" >> $S; done
      tools/mjc_stack cubes/offset3_$dt dt=$dt n=3 shift=0.02 secs=2 | sed "s|^STATS|STATS run offset3_$dt|" >> $S
      tools/mjc_stack cubes/slide_ground_$dt dt=$dt n=1 vx=1.2 secs=1 base=0 | sed "s|^STATS|STATS run slide_ground_$dt|" >> $S
      tools/mjc_stack cubes/slide_box_$dt dt=$dt n=1 vx=1.2 secs=1 base=0.5 | sed "s|^STATS|STATS run slide_box_$dt|" >> $S
    done
    for off in 0 0.01; do
      tools/mjc_grip cubes/grip_box_off$off dt=0.002 offset=$off pad=box | sed "s|^STATS|STATS run grip_box_off$off|" >> $S
      tools/mjc_grip cubes/grip_mesh_off$off dt=0.002 offset=$off pad=mesh | sed "s|^STATS|STATS run grip_mesh_off$off|" >> $S
    done )
  rm -rf "$O/$name"; mkdir -p "$O/$name"; cp -R "$X/runs" "$X/cubes" "$X/suites" "$O/$name/"; rm -rf "$X"
  echo "arm $name played $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
arm release "$W/mujoco-3.16.0"
arm off "$W/mujoco-iw2-build"
arm on "$W/mujoco-iw2-build" 1
# ---- MuJoCo's own test suite
suite() {  # <build folder> <label> [switch]
  ( cd "$1" && if [ -n "${3:-}" ]; then export MUJOCO_INVWEIGHT_AT_POSE=$3; else unset MUJOCO_INVWEIGHT_AT_POSE; fi
    ctest --timeout 900 -j"$J" > "$O/ctest_$2.txt" 2>&1 )
  echo "suite $2 exit $? $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1) $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
suite "$W/t20-release" release
suite "$W/t33-iw2" off
suite "$W/t33-iw2" on 1
for a in release off on; do
  awk 'match($0, /Test +#[0-9]+: /) {
         hdr = substr($0, RSTART, RLENGTH); num = hdr; gsub(/[^0-9]/, "", num); rest = substr($0, RSTART + RLENGTH)
         st = "unknown"
         if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) {
           st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st) }
         name = rest; p = index(name, "  # GetParam()"); if (p > 0) name = substr(name, 1, p - 1)
         p = index(name, " ...."); if (p > 0) name = substr(name, 1, p - 1); sub(/ +$/, "", name)
         print num, name, st }' "$O/ctest_$a.txt" | sort -n > "$O/suite_results_$a.txt"
done
# ---- measuring: every number a check reads, from Senua AI's measure or the rig's own STATS line
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  for a in release off on; do
    for cfg in defaults recommended; do for pose in A B; do for scene in rest drop; do for dt in 0.002 0.0005; do
      d=$O/$a/runs; n=$d/arm_${cfg}_${pose}_${scene}_${dt}_native.txt
      for wr in straight folded; do
        e=$("$B" ends $n $d/arm_${cfg}_${pose}_${scene}_${dt}_$wr.txt | tail -1)
        echo "$a arm $cfg $pose $scene $dt $wr apart_nm $(fld "$e" place_apart_nm) speed_apart_ums $(fld "$e" speed_apart_ums)"
      done
      if [ $scene = rest ]; then
        for wr in native straight folded; do
          echo "$a creep $cfg $pose $dt $wr mean_speed_ums $(fld "$("$B" creep $d/arm_${cfg}_${pose}_${scene}_${dt}_$wr.txt | tail -1)" mean_speed_ums)"
        done
      fi
    done; done; done; done
    for pose in E F; do for dt in 0.002 0.0005; do for wr in straight folded; do
      e=$("$B" ends $O/$a/runs/swing_${pose}_${dt}_native.txt $O/$a/runs/swing_${pose}_${dt}_$wr.txt | tail -1)
      echo "$a swing $pose $dt $wr apart_nm $(fld "$e" place_apart_nm) speed_apart_ums $(fld "$e" speed_apart_ums)"
    done; done; done
    lim=0; wrn=0
    for f in "$O/$a/runs/stats.txt" "$O/$a/suites/1/defaults/stats.txt" "$O/$a/suites/2/defaults/stats.txt"; do
      lim=$((lim + $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
      wrn=$((wrn + $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
    done
    echo "$a solver at_iteration_limit $lim warnings $wrn"
  done
} > "$O/measured.txt"
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
# ---- the five checks, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" | tail -1; }
  for pose in A B; do for scene in rest drop; do for dt in 0.002 0.0005; do
    rule "1_required_${pose}_${scene}_$dt" ge "$(get "release arm defaults $pose $scene $dt straight" apart_nm)" 1000
    for wr in straight folded; do
      rule "2_correct_place_${pose}_${scene}_${dt}_$wr" le "$(get "on arm defaults $pose $scene $dt $wr" apart_nm)" 100
      rule "2_correct_speed_${pose}_${scene}_${dt}_$wr" le "$(get "on arm defaults $pose $scene $dt $wr" speed_apart_ums)" 10
    done
  done; done; done
  for pose in A B; do for dt in 0.002 0.0005; do
    c=$(get "on creep defaults $pose $dt native" mean_speed_ums)
    for wr in straight folded; do rule "2_correct_creep_${pose}_${dt}_$wr" near "$(get "on creep defaults $pose $dt $wr" mean_speed_ums)" "$c" 1; done
  done; done
  for pose in E F; do for dt in 0.002 0.0005; do
    rule "1_required_swing_${pose}_$dt" ge "$(get "release swing $pose $dt straight" apart_nm)" 1000
    for wr in straight folded; do
      rule "2_correct_swing_place_${pose}_${dt}_$wr" le "$(get "on swing $pose $dt $wr" apart_nm)" 100
      rule "2_correct_swing_speed_${pose}_${dt}_$wr" le "$(get "on swing $pose $dt $wr" speed_apart_ums)" 10
    done
  done; done
  n=0; same=0; for f in $(cd "$O/release" && find suites cubes -type f | sort); do n=$((n + 1)); cmp -s "$O/release/$f" "$O/on/$f" && same=$((same + 1)); done
  rule 3_cubes_and_suites_on_as_released eq "$same" "$n"
  rule 3_mujoco_suite_on_as_off eq "$(diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep -c '^>')" 0
  n=0; same=0; for f in $(cd "$O/release" && find runs suites cubes -type f | sort); do n=$((n + 1)); cmp -s "$O/release/$f" "$O/off/$f" && same=$((same + 1)); done
  rule 4_off_as_released_files eq "$same" "$n"
  rule 4_off_suite_as_released eq "$(diff "$O/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>')" 0
  rule 5_iteration_limit eq "$(get "on solver" at_iteration_limit)" 0
  rule 5_warnings eq "$(get "on solver" warnings)" 0
  diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep '^>' | sed 's/^> /reported: changed with the switch set: /'
  for pose in A B; do for dt in 0.002 0.0005; do for wr in straight folded; do
    echo "reported: recommended, $pose rest $dt $wr: release apart $(get "release arm recommended $pose rest $dt $wr" apart_nm) nm, on apart $(get "on arm recommended $pose rest $dt $wr" apart_nm) nm"
  done; done; done
} > "$O/checks.txt"
echo "checks: $(grep -c '^RULE' "$O/checks.txt"), held: $(grep -c ': HELD$' "$O/checks.txt")" >> "$O/checks.txt"
date -u +%FT%TZ > "$O/finished.txt"
