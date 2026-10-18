#!/usr/bin/env bash
# Run 031: the sixth registered study (preregistrations/PREREGISTRATION_06.md), played once: the slip-aligned
# pyramid's third version (patches/in_design/slip_aligned_pyramid_v3.diff, switch MUJOCO_SLIP_ALIGNED_PYRAMID=1) on
# fresh scenes. Arms: release (Google DeepMind's Linux release), off (the patched build, switch unset), on (switch set),
# all three making the same plays; reference (the release, in a folder of its own): the moving floor under the elliptic
# cone, R9's and R10's reference; the two cones on a still floor along x, R9's bound; and the free cube under the
# elliptic cone, R11's reference. MuJoCo's own test suite:
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
  O="$R/validation/run_031_study_06/dry"; ARMS="release reference"
  CUBE="mass=1 radius=0.05"; MU=0.4; V=1; LIMIT=3.92; BELTS="0.3639702343 0.9004040443"; AXIS="1.0641777725 1.3456327296"
else
  O="$R/validation/run_031_study_06"; ARMS="release off on reference"
  CUBE="mass=1.05 radius=0.042"; MU=0.48; V=0.95; LIMIT=4.93920; BELTS="0.3457717226 0.8553838421"; AXIS="1.0109688839 1.2783510931"
fi
DIRS="0 12 33 57 78"; DTS="0.0012 0.0003"; DT1=0.0012; DT2=0.0003; FRACS="0.74 0.91"; SLIPS="20 42"; mkdir -p "$O"; : > "$O/progress.txt"
date -u +%FT%TZ > "$O/played_at.txt"
if [ "${DRY:-0}" != 1 ]; then
  # the patched source, its library (for the rigs) and its tests, from the registered patch file
  rm -rf "$W/mujoco-s6-src" && mkdir -p "$W/mujoco-s6-src" && (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-s6-src"
  (cd "$W/mujoco-s6-src" && patch -p1 -s < "$P")
  echo "release source $(git -C "$W/mujoco-src" rev-parse HEAD); patch $(sha256sum "$P" | cut -c1-16)" > "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-s6-src" -B "$W/s6-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$W/mujoco-s6-build" && cmake --build "$W/s6-lib" -j"$J" && cmake --install "$W/s6-lib" ) > "$O/build_lib.log" 2>&1
  echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
  ( cmake -S "$W/mujoco-s6-src" -B "$W/t31-s6" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t31-s6" -j"$J" ) > "$O/build_tests.log" 2>&1
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
      tools/mjc_contact runs/hold_${dir}_$frac.txt dt=$DT1 h0=0 mu=$MU push=$p pushat=0.35 secs=1.4 dir=$dir $CUBE | sed "s/^STATS/STATS run hold_${dir}_$frac/" >> $S
    done; done
    set -- $BELTS
    for dt in $DTS; do
      tools/mjc_contact runs/belt20_$dt.txt dt=$dt h0=0 vx0=$V mu=$MU $CUBE secs=0.8 belt=0,$1 | sed "s/^STATS/STATS run belt20_$dt/" >> $S
      tools/mjc_contact runs/belt42_$dt.txt dt=$dt h0=0 vx0=$V mu=$MU $CUBE secs=0.8 belt=0,$2 | sed "s/^STATS/STATS run belt42_$dt/" >> $S
    done
    for dir in $DIRS; do
      tools/mjc_contact runs/free_$dir.txt dt=$DT1 h0=0 vx0=$V mu=$MU $CUBE secs=1 lock=0 dir=$dir | sed "s/^STATS/STATS run free_$dir/" >> $S
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
      tools/mjc_contact runs/belt20e_$dt.txt dt=$dt h0=0 vx0=$V mu=$MU $CUBE secs=0.8 belt=0,$1 cone=elliptic | sed "s/^STATS/STATS run belt20e_$dt/" >> $S
      tools/mjc_contact runs/belt42e_$dt.txt dt=$dt h0=0 vx0=$V mu=$MU $CUBE secs=0.8 belt=0,$2 cone=elliptic | sed "s/^STATS/STATS run belt42e_$dt/" >> $S
    done
    set -- $AXIS
    for dt in $DTS; do
      tools/mjc_contact runs/axis20_pyramidal_$dt.txt dt=$dt h0=0 vx0=$1 mu=$MU $CUBE secs=0.8 | sed "s/^STATS/STATS run axis20_pyramidal_$dt/" >> $S
      tools/mjc_contact runs/axis20_elliptic_$dt.txt dt=$dt h0=0 vx0=$1 mu=$MU $CUBE secs=0.8 cone=elliptic | sed "s/^STATS/STATS run axis20_elliptic_$dt/" >> $S
      tools/mjc_contact runs/axis42_pyramidal_$dt.txt dt=$dt h0=0 vx0=$2 mu=$MU $CUBE secs=0.8 | sed "s/^STATS/STATS run axis42_pyramidal_$dt/" >> $S
      tools/mjc_contact runs/axis42_elliptic_$dt.txt dt=$dt h0=0 vx0=$2 mu=$MU $CUBE secs=0.8 cone=elliptic | sed "s/^STATS/STATS run axis42_elliptic_$dt/" >> $S
    done
    for dir in $DIRS; do
      tools/mjc_contact runs/free_elliptic_$dir.txt dt=$DT1 h0=0 vx0=$V mu=$MU $CUBE secs=1 lock=0 dir=$dir cone=elliptic | sed "s/^STATS/STATS run free_elliptic_$dir/" >> $S
    done )
  rm -rf "$O/reference"; mkdir -p "$O/reference"; cp -R "$X/runs" "$O/reference/"; rm -rf "$X"
  echo "arm reference played $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
for a in $ARMS; do
  case $a in
    release) arm release "$W/mujoco-3.16.0" ;; off) arm off "$W/mujoco-s6-build" ;; on) arm on "$W/mujoco-s6-build" 1 ;;
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
  suite "$W/t31-s6" off
  suite "$W/t31-s6" on 1
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
      for dir in $DIRS; do
        echo "elliptic free $dir slid_um $(fld "$("$B" stop "$O/reference/runs/free_elliptic_$dir.txt" | tail -1)" slid_um) side_um $(fld "$(statline reference free_elliptic_$dir)" side_um)"
      done
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
  s0=$(get "release slide 0 $DT1" slid_um)
  rule R3_release_direction_33 share "$s0" "$(get "release slide 33 $DT1" slid_um)" 100 115
  rule R3_release_direction_57 share "$s0" "$(get "release slide 57 $DT1" slid_um)" 100 115
  for dt in $DTS; do
    s0=$(get "on slide 0 $dt" slid_um)
    rule "R4_no_direction_$dt" all_within "$s0" 10000 $(for d in 12 33 57 78; do get "on slide $d $dt" slid_um; done)
    rule "R5_no_drift_$dt" all_le 10 $(for d in $DIRS; do abs "$(get "on slide $d $dt" side_um)"; done)
  done
  rule R6_coulomb all_within 95929 100 $(for d in $DIRS; do get "on slide $d $DT2" slid_um; done)
  for frac in $FRACS; do
    rule "R7_no_direction_hold_$frac" all_within "$(get "on hold 0 $frac" creep_ums)" 100 $(for d in 12 33 57 78; do get "on hold $d $frac" creep_ums; done)
  done
  rule R8_release_hold_lets_go share "$(get "release hold 0 0.91" creep_ums)" "$(get "release hold 33 0.91" creep_ums)" 1 10
  for dt in $DTS; do for s in $SLIPS; do
    e=$(get "elliptic belt$s $dt" stopped_at_step)
    ax=$(abs $(( $(get "axis pyramidal $s $dt" stopped_at_step) - $(get "axis elliptic $s $dt" stopped_at_step) )))
    rule "R9_moving_floor_on_belt${s}_$dt" near "$(get "on belt$s $dt" stopped_at_step)" "$e" "$ax"
    p=$(get "release belt$s $dt" stopped_at_step)
    rule "R10_moving_floor_release_belt${s}_$dt" ge "$(abs $((p - e)))" 2
  done; done
  span() { awk '{ if (NR == 1 || $1 < lo) lo = $1; if (NR == 1 || $1 > hi) hi = $1 } END { print hi - lo }'; }
  rule R11_free_cube_spread le "$(for d in $DIRS; do get "on free $d" slid_um; done | span)" "$(for d in $DIRS; do get "elliptic free $d" slid_um; done | span)"
  most() { awk '{ x = $1 < 0 ? -$1 : $1; if (x > m) m = x } END { print m + 0 }'; }
  rule R11_free_cube_drift le "$(for d in $DIRS; do get "on free $d" side_um; done | most)" "$(for d in $DIRS; do get "elliptic free $d" side_um; done | most)"
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
