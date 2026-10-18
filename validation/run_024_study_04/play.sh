#!/usr/bin/env bash
# Run 024: the fourth registered study (preregistrations/PREREGISTRATION_04.md), played once: the slip-aligned
# pyramid's third version (patches/in_design/slip_aligned_pyramid_v3.diff, switch MUJOCO_SLIP_ALIGNED_PYRAMID=1) on
# fresh scenes. Arms: release (Google DeepMind's Linux release), off (the patched build, switch unset), on (switch set),
# all three making the same plays; reference (the release, in a folder of its own): the moving floor under the elliptic
# cone, R9's and R10's reference, and the two cones on a still floor along x, reported only. MuJoCo's own test suite:
# the release's test build (run 020's) and the patched test build, switch unset and set. Every rule judged by sx_contact
# rule. DRY=1 plays throwaway parameters on the release and reference folders only, into dry/, with no build and no
# MuJoCo suite; no rule is read from it.
# usage: play.sh <sx_contact binary> <folder holding sx_contact_suite.sh> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src, the release in mujoco-3.16.0, and
#        run 020's release test build in t20-release)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; M="$(cd "${2:?}" && pwd)"
W="$(cd "${3:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
P="$R/patches/in_design/slip_aligned_pyramid_v3.diff"
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_024_study_04/dry"; ARMS="release reference"
  CUBE="mass=1 radius=0.05"; MU=0.4; V=1; LIMIT=3.92; BELTS="0.4663076582 1.1917535926"; AXIS="1.1033779190 1.5557238269"
else
  O="$R/validation/run_024_study_04"; ARMS="release off on reference"
  CUBE="mass=1.15 radius=0.038"; MU=0.62; V=0.85; LIMIT=6.9874; BELTS="0.3963615094 1.0129905537"; AXIS="0.9378712311 1.3223652528"
fi
DIRS="0 25 50 70 85"; DTS="0.0015 0.000375"; FRACS="0.76 0.93"; SLIPS="25 50"; mkdir -p "$O"; : > "$O/progress.txt"
date -u +%FT%TZ > "$O/played_at.txt"
if [ "${DRY:-0}" != 1 ]; then
  # the patched source, its library (for the rigs) and its tests, from the registered patch file
  rm -rf "$W/mujoco-s4-src" && mkdir -p "$W/mujoco-s4-src" && (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-s4-src"
  (cd "$W/mujoco-s4-src" && patch -p1 -s < "$P")
  echo "release source $(git -C "$W/mujoco-src" rev-parse HEAD); patch $(sha256sum "$P" | cut -c1-16)" > "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-s4-src" -B "$W/s4-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$W/mujoco-s4-build" && cmake --build "$W/s4-lib" -j"$J" && cmake --install "$W/s4-lib" ) > "$O/build_lib.log" 2>&1
  echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
  ( cmake -S "$W/mujoco-s4-src" -B "$W/t24-s4" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t24-s4" -j"$J" ) > "$O/build_tests.log" 2>&1
  echo "build tests exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
fi
arm() {  # <name> <MuJoCo folder> [switch]: the plays every arm makes, the same in each
  local name=$1 mj=$2 sw=${3:-} X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"; mkdir -p "$X/suites"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_pair; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
    if [ -n "$sw" ]; then export MUJOCO_SLIP_ALIGNED_PYRAMID=$sw; else unset MUJOCO_SLIP_ALIGNED_PYRAMID; fi
    tools/contact_suite.sh defaults > /dev/null; tools/contact_suite2.sh defaults > /dev/null
    bash "$M/sx_contact_suite.sh" suites/1/defaults suites/1/defaults/verdicts.txt > /dev/null 2>&1
    mkdir -p runs; S=runs/stats.txt; : > $S
    for dt in $DTS; do for dir in $DIRS; do
      tools/mjc_contact runs/slide_${dir}_$dt.txt dt=$dt h0=0 vx0=$V mu=$MU $CUBE secs=1 dir=$dir | sed "s/^STATS/STATS run slide_${dir}_$dt/" >> $S
    done; done
    for frac in $FRACS; do for dir in $DIRS; do
      p=$(awk -v f=$frac -v l=$LIMIT 'BEGIN { printf "%.6f", f * l }')
      tools/mjc_contact runs/hold_${dir}_$frac.txt dt=0.0015 h0=0 mu=$MU push=$p pushat=0.35 secs=1.4 dir=$dir $CUBE | sed "s/^STATS/STATS run hold_${dir}_$frac/" >> $S
    done; done
    set -- $BELTS
    for dt in $DTS; do
      tools/mjc_contact runs/belt25_$dt.txt dt=$dt h0=0 vx0=$V mu=$MU $CUBE secs=0.8 belt=0,$1 | sed "s/^STATS/STATS run belt25_$dt/" >> $S
      tools/mjc_contact runs/belt50_$dt.txt dt=$dt h0=0 vx0=$V mu=$MU $CUBE secs=0.8 belt=0,$2 | sed "s/^STATS/STATS run belt50_$dt/" >> $S
    done
    for dir in $DIRS; do
      tools/mjc_contact runs/free_$dir.txt dt=0.0015 h0=0 vx0=$V mu=$MU $CUBE secs=1 lock=0 dir=$dir | sed "s/^STATS/STATS run free_$dir/" >> $S
    done )
  rm -rf "$O/$name"; mkdir -p "$O/$name"; cp -R "$X/runs" "$X/suites" "$O/$name/"; rm -rf "$X"
  echo "arm $name played $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
reference() {  # the release, in its own folder: the elliptic cone on the moving floor, and the two cones along x
  local X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    MUJOCO_DIR=$W/mujoco-3.16.0 tools/build_rig.sh mjc_contact > /dev/null; unset MUJOCO_SLIP_ALIGNED_PYRAMID
    mkdir -p runs; S=runs/stats.txt; : > $S
    set -- $BELTS
    for dt in $DTS; do
      tools/mjc_contact runs/belt25e_$dt.txt dt=$dt h0=0 vx0=$V mu=$MU $CUBE secs=0.8 belt=0,$1 cone=elliptic | sed "s/^STATS/STATS run belt25e_$dt/" >> $S
      tools/mjc_contact runs/belt50e_$dt.txt dt=$dt h0=0 vx0=$V mu=$MU $CUBE secs=0.8 belt=0,$2 cone=elliptic | sed "s/^STATS/STATS run belt50e_$dt/" >> $S
    done
    set -- $AXIS
    for dt in $DTS; do
      tools/mjc_contact runs/axis25_pyramidal_$dt.txt dt=$dt h0=0 vx0=$1 mu=$MU $CUBE secs=0.8 | sed "s/^STATS/STATS run axis25_pyramidal_$dt/" >> $S
      tools/mjc_contact runs/axis25_elliptic_$dt.txt dt=$dt h0=0 vx0=$1 mu=$MU $CUBE secs=0.8 cone=elliptic | sed "s/^STATS/STATS run axis25_elliptic_$dt/" >> $S
      tools/mjc_contact runs/axis50_pyramidal_$dt.txt dt=$dt h0=0 vx0=$2 mu=$MU $CUBE secs=0.8 | sed "s/^STATS/STATS run axis50_pyramidal_$dt/" >> $S
      tools/mjc_contact runs/axis50_elliptic_$dt.txt dt=$dt h0=0 vx0=$2 mu=$MU $CUBE secs=0.8 cone=elliptic | sed "s/^STATS/STATS run axis50_elliptic_$dt/" >> $S
    done )
  rm -rf "$O/reference"; mkdir -p "$O/reference"; cp -R "$X/runs" "$O/reference/"; rm -rf "$X"
  echo "arm reference played $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
for a in $ARMS; do
  case $a in
    release) arm release "$W/mujoco-3.16.0" ;; off) arm off "$W/mujoco-s4-build" ;; on) arm on "$W/mujoco-s4-build" 1 ;;
    reference) reference ;;
  esac
done
if [ "${DRY:-0}" != 1 ]; then
  suite() {  # <build folder> <label> [switch]
    ( cd "$1" && if [ -n "${3:-}" ]; then export MUJOCO_SLIP_ALIGNED_PYRAMID=$3; else unset MUJOCO_SLIP_ALIGNED_PYRAMID; fi
      ctest --timeout 900 -j"$J" > "$O/ctest_$2.txt" 2>&1 )
    echo "suite $2 exit $? $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1) $(date -u +%FT%TZ)" >> "$O/progress.txt"
  }
  suite "$W/t20-release" release
  suite "$W/t24-s4" off
  suite "$W/t24-s4" on 1
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
statline() { grep "^STATS run $2 " "$O/$1/runs/stats.txt" | head -1; }
solver() {  # <label> <statistics file> ...: the most iterations, the steps at the limit and the warnings over the files
  local label=$1 lim=0 wrn=0 most=0 f m; shift
  for f in "$@"; do
    lim=$((lim + $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
    wrn=$((wrn + $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
    m=$(grep -o 'most_iterations [0-9]*' "$f" | awk '{ if ($2 > x) x = $2 } END { print x + 0 }'); [ "$m" -gt "$most" ] && most=$m
  done
  echo "$label solver most_iterations $most at_iteration_limit $lim warnings $wrn"
}
{
  for a in $ARMS; do
    if [ "$a" = reference ]; then
      for dt in $DTS; do for s in $SLIPS; do
        echo "elliptic belt$s $dt stopped_at_step $(fld "$("$B" stop "$O/reference/runs/belt${s}e_$dt.txt" | tail -1)" first_stopped_at_step)"
      done; done
      for dt in $DTS; do for s in $SLIPS; do for c in pyramidal elliptic; do
        st=$("$B" stop "$O/reference/runs/axis${s}_${c}_$dt.txt" | tail -1)
        echo "axis $c $s $dt stopped_at_step $(fld "$st" first_stopped_at_step) slid_um $(fld "$st" slid_um)"
      done; done; done
      solver reference "$O/reference/runs/stats.txt"
      continue
    fi
    for dt in $DTS; do for dir in $DIRS; do
      f=$O/$a/runs/slide_${dir}_$dt.txt; h=$("$B" hover "$f" | tail -1)
      echo "$a slide $dir $dt slid_um $(fld "$("$B" stop "$f" | tail -1)" slid_um) side_um $(fld "$(statline $a slide_${dir}_$dt)" side_um) highest_um $(fld "$h" highest_um) fastest_up_ums $(fld "$h" fastest_up_ums)"
    done; done
    for frac in $FRACS; do for dir in $DIRS; do
      echo "$a hold $dir $frac creep_ums $(fld "$("$B" creep "$O/$a/runs/hold_${dir}_$frac.txt" | tail -1)" mean_speed_ums)"
    done; done
    for dt in $DTS; do for s in $SLIPS; do
      echo "$a belt$s $dt stopped_at_step $(fld "$("$B" stop "$O/$a/runs/belt${s}_$dt.txt" | tail -1)" first_stopped_at_step)"
    done; done
    for dir in $DIRS; do
      echo "$a free $dir slid_um $(fld "$("$B" stop "$O/$a/runs/free_$dir.txt" | tail -1)" slid_um) side_um $(fld "$(statline $a free_$dir)" side_um)"
    done
    solver "$a" "$O/$a/runs/stats.txt" "$O/$a/suites/1/defaults/stats.txt" "$O/$a/suites/2/defaults/stats.txt"
  done
} > "$O/measured.txt"
if [ "${DRY:-0}" = 1 ]; then echo "dry run: $(wc -l < "$O/measured.txt") measured lines"; exit 0; fi
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
abs() { local x=$1; echo "${x#-}"; }
# ---- the rules, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" | tail -1; }
  n=0; same=0; for f in $(cd "$O/release" && find runs suites -type f | sort); do n=$((n + 1)); cmp -s "$O/release/$f" "$O/off/$f" && same=$((same + 1)); done
  rule R1_safe_when_off_plays eq "$same" "$n"
  rule R2_safe_when_off_suite eq "$(diff "$O/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>')" 0
  s0=$(get "release slide 0 0.0015" slid_um)
  rule R3_release_direction_25 share "$s0" "$(get "release slide 25 0.0015" slid_um)" 100 115
  rule R3_release_direction_50 share "$s0" "$(get "release slide 50 0.0015" slid_um)" 100 115
  for dt in $DTS; do
    s0=$(get "on slide 0 $dt" slid_um)
    rule "R4_no_direction_$dt" all_within "$s0" 10000 $(for d in 25 50 70 85; do get "on slide $d $dt" slid_um; done)
    rule "R5_no_drift_$dt" all_le 10 $(for d in $DIRS; do abs "$(get "on slide $d $dt" side_um)"; done)
  done
  rule R6_coulomb all_within 59455 100 $(for d in $DIRS; do get "on slide $d 0.000375" slid_um; done)
  for frac in $FRACS; do
    rule "R7_no_direction_hold_$frac" all_within "$(get "on hold 0 $frac" creep_ums)" 100 $(for d in 25 50 70 85; do get "on hold $d $frac" creep_ums; done)
  done
  rule R8_release_hold_lets_go share "$(get "release hold 0 0.93" creep_ums)" "$(get "release hold 50 0.93" creep_ums)" 1 10
  for dt in $DTS; do for s in $SLIPS; do
    e=$(get "elliptic belt$s $dt" stopped_at_step)
    rule "R9_moving_floor_on_belt${s}_$dt" near "$(get "on belt$s $dt" stopped_at_step)" "$e" 3
    p=$(get "release belt$s $dt" stopped_at_step)
    rule "R10_moving_floor_release_belt${s}_$dt" ge "$(abs $((p - e)))" 2
  done; done
  rule R11_free_cube all_within "$(get "on free 0" slid_um)" 100 $(for d in 25 50 70 85; do get "on free $d" slid_um; done)
  rule R11_free_cube_drift all_le 1000 $(for d in $DIRS; do abs "$(get "on free $d" side_um)"; done)
  for t in SensorTest.ContactStage SensorTest.ContactVelocity SleepTest.SleepingUnaffectedByWaking IpcTest.FoldDenseBlocksSolveMatches ForwardTest.DiscreteStiffLegPress; do
    rule "R12_$t" eq "$(grep -c " $t Passed$" "$O/suite_results_on.txt")" 1
  done
  n=0; same=0; for f in $(cd "$O/release" && find suites -type f | sort); do n=$((n + 1)); cmp -s "$O/release/$f" "$O/on/$f" && same=$((same + 1)); done
  rule R13_suites_on_as_released eq "$same" "$n"
  rule R13_mujoco_suite_beside_the_lift eq "$(diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep '^>' | grep -v -c ' InverseTest.DiscreteInverseFreeBody ')" 0
  rule R14_iteration_limit eq "$(get "on solver" at_iteration_limit)" 0
  rule R14_warnings eq "$(get "on solver" warnings)" 0
  rule R14_most_iterations le_plus "$(get "on solver" most_iterations)" "$(get "release solver" most_iterations)" 2
  diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep '^>' | sed 's/^> /reported: changed with the switch set: /'
  for dt in $DTS; do echo "reported: lift $dt, release $(for d in $DIRS; do get "release slide $d $dt" highest_um; done | tr '\n' ' ')/ on $(for d in $DIRS; do get "on slide $d $dt" highest_um; done | tr '\n' ' ')"; done
  for dt in $DTS; do for s in $SLIPS; do
    py=$(get "axis pyramidal $s $dt" stopped_at_step); el=$(get "axis elliptic $s $dt" stopped_at_step)
    echo "reported: the two cones on a still floor along x at the slip speed of belt$s, $dt: pyramidal $py, elliptic $el, apart $(abs $((py - el))) steps"
  done; done
} > "$O/rules.txt"
echo "rules: $(grep -c '^RULE' "$O/rules.txt"), held: $(grep -c ': HELD$' "$O/rules.txt")" >> "$O/rules.txt"
date -u +%FT%TZ > "$O/finished.txt"
