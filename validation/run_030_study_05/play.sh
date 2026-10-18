#!/usr/bin/env bash
# Run 030: the fifth registered study (preregistrations/PREREGISTRATION_05.md), played once: the inverse weight in the
# current pose (patches/in_design/invweight_at_pose.diff, switch MUJOCO_INVWEIGHT_AT_POSE=1) on scenes the probes did not
# use. Arms: release (Google DeepMind's Linux release), off (the patched build, switch unset), on (switch set), each
# making the same plays. MuJoCo's own test suite: the release's test build (run 020's) and the patched test build,
# switch unset and set. Every rule judged by sx_contact rule. DRY=1 plays throwaway parameters (run 025's arm and run
# 026's cubes) on the release arm only, into dry/, with no build and no MuJoCo suite; no rule is read from it.
# usage: play.sh <folder holding sx_contact> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src, the release in mujoco-3.16.0, and
#        run 020's release test build in t20-release)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
PF="$R/patches/in_design/invweight_at_pose.diff"
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_030_study_05/dry"; ARMS="release"
  ARM="len1=0.3 len2=0.3 mass1=1 mass2=0.5 rb=0.03 mb=0.2 mu=0.8"; POSES="0.5,1.2 1.1,-0.6"; FOLD=0,2.5; DTS="0.002 0.0005"
  REST="h0=0 secs=2"; DROP="h0=0.01 secs=1"
  CUBE="mass=0.5 radius=0.05 mu=0.5"; NS="3 5"; SHIFT=0.02; VS=1.2; GRIP="mass=0.2 radius=0.03 mu=0.8 squeeze=2.45"; GOFF=0.01
else
  O="$R/validation/run_030_study_05"; ARMS="release off on"
  ARM="len1=0.28 len2=0.24 mass1=0.9 mass2=0.4 rb=0.025 mb=0.15 mu=0.7"; POSES="0.6,1.0 1.3,-0.5"; FOLD=0,2.2; DTS="0.001 0.00025"
  REST="h0=0.0004 secs=2"; DROP="h0=0.012 secs=1"
  CUBE="mass=0.4 radius=0.045 mu=0.6"; NS="4 7"; SHIFT=0.015; VS=1.0; GRIP="mass=0.25 radius=0.035 mu=0.7 squeeze=3.0"; GOFF=0.008
fi
mkdir -p "$O"; : > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
if [ "${DRY:-0}" != 1 ]; then
  rm -rf "$W/mujoco-s5-src" && mkdir -p "$W/mujoco-s5-src" && (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-s5-src"
  (cd "$W/mujoco-s5-src" && patch -p1 -s < "$PF")
  echo "release source $(git -C "$W/mujoco-src" rev-parse HEAD); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-s5-src" -B "$W/s5-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$W/mujoco-s5-build" && cmake --build "$W/s5-lib" -j"$J" && cmake --install "$W/s5-lib" ) > "$O/build_lib.log" 2>&1
  echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
  ( cmake -S "$W/mujoco-s5-src" -B "$W/t30-s5" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t30-s5" -j"$J" ) > "$O/build_tests.log" 2>&1
  echo "build tests exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
fi
arm() {  # <name> <MuJoCo folder> [switch]: the plays every arm makes, the same in each
  local name=$1 mj=$2 sw=${3:-} X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"; mkdir -p "$X/suites"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_pair mjc_arm mjc_stack mjc_grip; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
    if [ -n "$sw" ]; then export MUJOCO_INVWEIGHT_AT_POSE=$sw; else unset MUJOCO_INVWEIGHT_AT_POSE; fi
    tools/contact_suite.sh defaults > /dev/null; tools/contact_suite2.sh defaults > /dev/null
    mkdir -p runs cubes; S=runs/stats.txt; : > $S
    for cfg in defaults recommended; do
      if [ $cfg = recommended ]; then set -- cone=elliptic noslip=10; else set --; fi
      k=0
      for PS in $POSES; do
        k=$((k + 1))
        for scene in rest drop; do
          if [ $scene = rest ]; then SC=$REST; else SC=$DROP; fi
          for dt in $DTS; do for wr in native straight folded; do
            case $wr in native) P0=$PS ;; straight) P0=0,0 ;; folded) P0=$FOLD ;; esac
            f=runs/arm_${cfg}_pose${k}_${scene}_${dt}_$wr.txt
            # shellcheck disable=SC2086
            tools/mjc_arm $f dt=$dt pose=$PS pose0=$P0 $ARM $SC "$@" | sed "s|^STATS|STATS run $(basename $f .txt)|" >> $S
          done; done
        done
      done
    done
    for dt in $DTS; do
      # shellcheck disable=SC2086
      for n in $NS; do tools/mjc_stack cubes/stack${n}_$dt dt=$dt n=$n secs=2 $CUBE | sed "s|^STATS|STATS run stack${n}_$dt|" >> $S; done
      # shellcheck disable=SC2086
      tools/mjc_stack cubes/offset3_$dt dt=$dt n=3 shift=$SHIFT secs=2 $CUBE | sed "s|^STATS|STATS run offset3_$dt|" >> $S
      # shellcheck disable=SC2086
      tools/mjc_stack cubes/slide_ground_$dt dt=$dt n=1 vx=$VS secs=1 base=0 $CUBE | sed "s|^STATS|STATS run slide_ground_$dt|" >> $S
      # shellcheck disable=SC2086
      tools/mjc_stack cubes/slide_box_$dt dt=$dt n=1 vx=$VS secs=1 base=0.5 $CUBE | sed "s|^STATS|STATS run slide_box_$dt|" >> $S
    done
    set -- $DTS; g=$1
    for off in 0 $GOFF; do for pad in box mesh; do
      # shellcheck disable=SC2086
      tools/mjc_grip cubes/grip_${pad}_off$off dt=$g offset=$off pad=$pad $GRIP | sed "s|^STATS|STATS run grip_${pad}_off$off|" >> $S
    done; done )
  rm -rf "$O/$name"; mkdir -p "$O/$name"; cp -R "$X/runs" "$X/cubes" "$X/suites" "$O/$name/"; rm -rf "$X"
  echo "arm $name played $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
for a in $ARMS; do
  case $a in release) arm release "$W/mujoco-3.16.0" ;; off) arm off "$W/mujoco-s5-build" ;; on) arm on "$W/mujoco-s5-build" 1 ;; esac
done
if [ "${DRY:-0}" != 1 ]; then
  suite() {  # <build folder> <label> [switch]
    ( cd "$1" && if [ -n "${3:-}" ]; then export MUJOCO_INVWEIGHT_AT_POSE=$3; else unset MUJOCO_INVWEIGHT_AT_POSE; fi
      ctest --timeout 900 -j"$J" > "$O/ctest_$2.txt" 2>&1 )
    echo "suite $2 exit $? $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1) $(date -u +%FT%TZ)" >> "$O/progress.txt"
  }
  suite "$W/t20-release" release
  suite "$W/t30-s5" off
  suite "$W/t30-s5" on 1
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
fi
# measuring: every number a rule reads, from Senua AI's measure or the rig's own STATS line (plumbing extracts them)
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  for a in $ARMS; do
    for cfg in defaults recommended; do for k in 1 2; do for scene in rest drop; do for dt in $DTS; do
      d=$O/$a/runs; n=$d/arm_${cfg}_pose${k}_${scene}_${dt}_native.txt
      for wr in straight folded; do
        e=$("$B" ends $n $d/arm_${cfg}_pose${k}_${scene}_${dt}_$wr.txt | tail -1)
        echo "$a arm $cfg pose$k $scene $dt $wr apart_nm $(fld "$e" place_apart_nm) speed_apart_ums $(fld "$e" speed_apart_ums)"
      done
      if [ $scene = rest ]; then
        for wr in native straight folded; do
          echo "$a creep $cfg pose$k $dt $wr mean_speed_ums $(fld "$("$B" creep $d/arm_${cfg}_pose${k}_${scene}_${dt}_$wr.txt | tail -1)" mean_speed_ums)"
        done
      fi
    done; done; done; done
    lim=0; wrn=0
    for f in "$O/$a/runs/stats.txt" "$O/$a/suites/1/defaults/stats.txt" "$O/$a/suites/2/defaults/stats.txt"; do
      lim=$((lim + $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
      wrn=$((wrn + $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
    done
    echo "$a solver at_iteration_limit $lim warnings $wrn"
  done
} > "$O/measured.txt"
if [ "${DRY:-0}" = 1 ]; then echo "dry run: $(wc -l < "$O/measured.txt") measured lines"; exit 0; fi
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
# ---- the rules, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" | tail -1; }
  n=0; same=0; for f in $(cd "$O/release" && find runs cubes suites -type f | sort); do n=$((n + 1)); cmp -s "$O/release/$f" "$O/off/$f" && same=$((same + 1)); done
  rule R1_safe_when_off_plays eq "$same" "$n"
  rule R2_safe_when_off_suite eq "$(diff "$O/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>')" 0
  for k in 1 2; do for scene in rest drop; do for dt in $DTS; do
    rule "R3_defect_pose${k}_${scene}_$dt" ge "$(get "release arm defaults pose$k $scene $dt straight" apart_nm)" 1000
  done; done; done
  for cfg in defaults recommended; do for k in 1 2; do for scene in rest drop; do for dt in $DTS; do for wr in straight folded; do
    rule "R4_place_${cfg}_pose${k}_${scene}_${dt}_$wr" le "$(get "on arm $cfg pose$k $scene $dt $wr" apart_nm)" 100
    rule "R5_speed_${cfg}_pose${k}_${scene}_${dt}_$wr" le "$(get "on arm $cfg pose$k $scene $dt $wr" speed_apart_ums)" 10
  done; done; done; done; done
  for k in 1 2; do for dt in $DTS; do
    c=$(get "on creep defaults pose$k $dt native" mean_speed_ums)
    for wr in straight folded; do rule "R6_creep_pose${k}_${dt}_$wr" near "$(get "on creep defaults pose$k $dt $wr" mean_speed_ums)" "$c" 1; done
  done; done
  n=0; same=0; for f in $(cd "$O/release" && find suites cubes -type f | sort); do n=$((n + 1)); cmp -s "$O/release/$f" "$O/on/$f" && same=$((same + 1)); done
  rule R7_cubes_and_suites_on_as_released eq "$same" "$n"
  rule R8_mujoco_suite_on_as_off eq "$(diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep -c '^>')" 0
  rule R9_iteration_limit eq "$(get "on solver" at_iteration_limit)" 0
  rule R9_warnings eq "$(get "on solver" warnings)" 0
  diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep '^>' | sed 's/^> /reported: changed with the switch set: /'
} > "$O/rules.txt"
echo "rules: $(grep -c '^RULE' "$O/rules.txt"), held: $(grep -c ': HELD$' "$O/rules.txt")" >> "$O/rules.txt"
date -u +%FT%TZ > "$O/finished.txt"
