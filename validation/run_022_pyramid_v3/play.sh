#!/usr/bin/env bash
# Run 022, step 2, a patch in design (not registered): the slip-aligned pyramid's third version,
# patches/in_design/slip_aligned_pyramid_v3.diff. It is the second version (run 021) with two changes:
#   - the new mjContact field is added to doc/includes/references.h, the documentation's copy of the public headers,
#     as MuJoCo's doc_test requires of every field;
#   - the pyramid is turned only by the part of the slip's angle that is not a multiple of 90 degrees: of the slip and
#     its three quarter turns about the normal, the one nearest the frame's first tangent. The four-edge pyramid turned
#     by a multiple of 90 degrees has the same edges in another order. Step 1 (trace.sh) found that MuJoCo's stiff
#     leg-press test fails under the second version because every turn there is exactly 180 degrees: the same edges,
#     each pair's two rows swapped, which moves the discrete integrator's endpoint. With this change a slip along an
#     edge leaves the rows exactly as released.
# The lift is not corrected: an aligned pyramid lifts a sliding body as much in every direction as along an axis (runs
# 020, 021), and that is stated, not tuned.
# Switch: MUJOCO_SLIP_ALIGNED_PYRAMID=1. Three arms, each in its own scratch copy, the rigs built against: release
# (Google DeepMind's Linux release), off (version 3 built from source, switch unset), on (switch set). Each plays the
# plays of run 021 (suites, slide, hold, belt with its still-floor reference, free, lift) and, new, every belt play
# again under MuJoCo's elliptic cone (cone=elliptic), which has no direction. MuJoCo's own test suite runs on the
# release's test build (run 020's) and on version 3's, switch unset and set.
# The five checks, fixed before any play (run 021's, with C4, C6, 3 and 4 as stated here):
#   1 required     on the release: the slides along 22.5 and 45 degrees go more than 1% further than along 0; each
#                  belt play under the release's pyramid stops more than one step away from the same belt play under
#                  the elliptic cone
#   2 correct      with the switch on:
#                    C1 every slide along 22.5 and 45 within 1 in 10,000 of the slide along 0, at each step
#                    C2 no drift: the slides' sideways distance at most 10 um
#                    C3 the loads the release loses (0.72, 0.8, 0.9 of the limit): the hold along 22.5 and 45 creeps as
#                       along 0, within 1 in 100
#                    C4 each belt play stops within one step of the same belt play under MuJoCo's elliptic cone (the
#                       right reference for a moving floor; run 021's still floor was not, the elliptic cone missing it
#                       too)
#                    C5 the contact frame is the release's: MuJoCo's ContactStage and ContactVelocity tests pass
#                    C6 the three tests run 020 failed by the turn pass: SleepingUnaffectedByWaking,
#                       FoldDenseBlocksSolveMatches, DiscreteStiffLegPress
#   3 nothing else gets worse   with the switch on, both suites and the lift slides byte-identical to the release; in
#                  MuJoCo's suite, switch set against unset, no test changes but InverseTest.DiscreteInverseFreeBody,
#                  which fails by the stated lift (runs 020, 021); any other change fails this check
#   4 safe when off   the off arm byte-identical to the release, every file; MuJoCo's whole suite, switch unset, test
#                  for test as the release, doc_test included
#   5 the solver keeps converging   switch on: no play at the iteration limit, no warning
# Reported, not judged: the lift along 0, 22.5 and 45 degrees; the holds at 0.6 and 0.69; the free cube; each belt
# play against its still-floor reference.
# usage: play.sh <sx_contact binary> <folder holding sx_contact_suite.sh> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src, the release in mujoco-3.16.0, and
#        run 020's release test build in t20-release)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; M="$(cd "${2:?}" && pwd)"
W="$(cd "${3:?}" && pwd)"; R="$(pwd)"; O="$R/validation/run_022_pyramid_v3"; mkdir -p "$O"; J=$(nproc)
P="$R/patches/in_design/slip_aligned_pyramid_v3.diff"
: > "$O/progress.txt"
# step 0: version 3's source is the release source with exactly the patch applied
rm -rf "$W/mujoco-pyr3-src" && mkdir -p "$W/mujoco-pyr3-src" && (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-pyr3-src"
(cd "$W/mujoco-pyr3-src" && patch -p1 -s < "$P")
{ echo "release source $(git -C "$W/mujoco-src" rev-parse HEAD), UPSTREAM_COMMIT $(cat "$R/UPSTREAM_COMMIT")"
  echo "patch $(sha256sum "$P" | cut -c1-16) applied: $(grep -c 'frictionrot' "$W/mujoco-pyr3-src/src/engine/engine_core_constraint.c") lines name frictionrot in the constraint file"
} > "$O/patch_check.txt"
# builds: the library, installed (for the rigs), and the test suite
lib() { cmake -S "$W/mujoco-pyr3-src" -B "$W/pyr3-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
          -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
          -DCMAKE_INSTALL_PREFIX="$W/mujoco-pyr3-build" && cmake --build "$W/pyr3-lib" -j"$J" && cmake --install "$W/pyr3-lib"; }
tst() { cmake -S "$W/mujoco-pyr3-src" -B "$W/t22-pyr3" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
          -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t22-pyr3" -j"$J"; }
lib > "$O/build_lib.log" 2>&1; echo "build lib exit $? warnings in patched files $(grep -E 'warning:' "$O/build_lib.log" | grep -c -E 'engine_core_(util|constraint)|mjdata')" >> "$O/progress.txt"
tst > "$O/build_tests.log" 2>&1; echo "build tests exit $? warnings in patched files $(grep -E 'warning:' "$O/build_tests.log" | grep -c -E 'engine_core_(util|constraint)|mjdata')" >> "$O/progress.txt"
# the plays of one arm, in a scratch copy
dt_of() { awk -v k="$1" 'BEGIN { printf "%.12f", 0.01 / k }'; }
arm() {  # <name> <MuJoCo folder> [switch]
  local name=$1 mj=$2 sw=${3:-} X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"; mkdir -p "$X/suites"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_pair; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
    if [ -n "$sw" ]; then export MUJOCO_SLIP_ALIGNED_PYRAMID=$sw; else unset MUJOCO_SLIP_ALIGNED_PYRAMID; fi
    tools/contact_suite.sh defaults > /dev/null; tools/contact_suite2.sh defaults > /dev/null
    bash "$M/sx_contact_suite.sh" suites/1/defaults suites/1/defaults/verdicts.txt > /dev/null 2>&1
    mkdir -p runs; S=runs/stats.txt; : > $S; C="mass=1 radius=0.05"
    for dt in 0.002 0.000125; do for dir in 0 22.5 45; do
      tools/mjc_contact runs/slide_${dir}_$dt.txt dt=$dt h0=0 vx0=1 mu=0.4 $C secs=1 dir=$dir | sed "s/^STATS/STATS run slide_${dir}_$dt/" >> $S
    done; done
    for frac in 0.6 0.69 0.72 0.8 0.9; do for dir in 0 22.5 45; do
      p=$(awk -v f=$frac 'BEGIN { printf "%.6f", f * 0.5 * 9.8 }')
      tools/mjc_contact runs/hold_${dir}_$frac.txt dt=0.002 h0=0 mu=0.5 push=$p pushat=0.5 secs=2 dir=$dir $C | sed "s/^STATS/STATS run hold_${dir}_$frac/" >> $S
    done; done
    for dt in 0.002 0.0005; do
      tools/mjc_contact runs/belt45_$dt.txt dt=$dt h0=0 vx0=1 mu=0.4 $C secs=1 belt=0,1 | sed "s/^STATS/STATS run belt45_$dt/" >> $S
      tools/mjc_contact runs/ref45_$dt.txt dt=$dt h0=0 vx0=1.4142135623730951 mu=0.4 $C secs=1 | sed "s/^STATS/STATS run ref45_$dt/" >> $S
      tools/mjc_contact runs/belt30_$dt.txt dt=$dt h0=0 vx0=1 mu=0.4 $C secs=1 belt=0,0.5773502691896258 | sed "s/^STATS/STATS run belt30_$dt/" >> $S
      tools/mjc_contact runs/ref30_$dt.txt dt=$dt h0=0 vx0=1.1547005383792515 mu=0.4 $C secs=1 | sed "s/^STATS/STATS run ref30_$dt/" >> $S
      tools/mjc_contact runs/belt45e_$dt.txt dt=$dt h0=0 vx0=1 mu=0.4 $C secs=1 belt=0,1 cone=elliptic | sed "s/^STATS/STATS run belt45e_$dt/" >> $S
      tools/mjc_contact runs/belt30e_$dt.txt dt=$dt h0=0 vx0=1 mu=0.4 $C secs=1 belt=0,0.5773502691896258 cone=elliptic | sed "s/^STATS/STATS run belt30e_$dt/" >> $S
    done
    for dir in 0 22.5 45; do
      tools/mjc_contact runs/free_$dir.txt dt=0.002 h0=0 vx0=1 mu=0.4 $C secs=1 lock=0 dir=$dir | sed "s/^STATS/STATS run free_$dir/" >> $S
    done
    for k in 1 4 16; do
      tools/mjc_contact runs/lift_$k.txt dt="$(dt_of $k)" $C h0=0 secs=0.81 vx0=1.2 mu=0.4 | sed "s/^STATS/STATS run lift_$k/" >> $S
    done )
  rm -rf "$O/$name"; mkdir -p "$O/$name"; cp -R "$X/runs" "$X/suites" "$O/$name/"; rm -rf "$X"
  echo "arm $name played $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
arm release "$W/mujoco-3.16.0"
arm off "$W/mujoco-pyr3-build"
arm on "$W/mujoco-pyr3-build" 1
# MuJoCo's own suite: the release's test build (run 020's) and version 2's, switch unset and set
suite() {  # <build folder> <label> [switch]
  ( cd "$1" && if [ -n "${3:-}" ]; then export MUJOCO_SLIP_ALIGNED_PYRAMID=$3; else unset MUJOCO_SLIP_ALIGNED_PYRAMID; fi
    ctest --timeout 900 -j"$J" > "$O/ctest_$2.txt" 2>&1 )
  echo "suite $2 exit $? $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1)" >> "$O/progress.txt"
}
suite "$W/t20-release" release
suite "$W/t22-pyr3" off
suite "$W/t22-pyr3" on 1
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
# measuring: every number a check reads, from Senua AI's measure or the rig's own STATS line (plumbing extracts them)
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
statline() { grep "^STATS run $2 " "$O/$1/runs/stats.txt" | head -1; }
{
  for a in release off on; do
    for dt in 0.002 0.000125; do for dir in 0 22.5 45; do
      f=$O/$a/runs/slide_${dir}_$dt.txt
      echo "$a slide $dir $dt slid_um $(fld "$("$B" stop "$f" | tail -1)" slid_um) side_um $(fld "$(statline $a slide_${dir}_$dt)" side_um) highest_um $(fld "$("$B" hover "$f" | tail -1)" highest_um) fastest_up_ums $(fld "$("$B" hover "$f" | tail -1)" fastest_up_ums)"
    done; done
    for frac in 0.6 0.69 0.72 0.8 0.9; do for dir in 0 22.5 45; do
      echo "$a hold $dir $frac creep_ums $(fld "$("$B" creep "$O/$a/runs/hold_${dir}_$frac.txt" | tail -1)" mean_speed_ums)"
    done; done
    for dt in 0.002 0.0005; do for b in belt45 ref45 belt30 ref30 belt45e belt30e; do
      echo "$a $b $dt stopped_at_step $(fld "$("$B" stop "$O/$a/runs/${b}_$dt.txt" | tail -1)" first_stopped_at_step)"
    done; done
    for dir in 0 22.5 45; do
      echo "$a free $dir slid_um $(fld "$("$B" stop "$O/$a/runs/free_$dir.txt" | tail -1)" slid_um) side_um $(fld "$(statline $a free_$dir)" side_um)"
    done
    for k in 1 4 16; do echo "$a lift 1/$k highest_um $(fld "$("$B" hover "$O/$a/runs/lift_$k.txt" | tail -1)" highest_um)"; done
    lim=0; wrn=0; most=0
    for f in "$O/$a/runs/stats.txt" "$O/$a/suites/1/defaults/stats.txt" "$O/$a/suites/2/defaults/stats.txt"; do
      lim=$((lim + $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
      wrn=$((wrn + $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
      m=$(grep -o 'most_iterations [0-9]*' "$f" | awk '{ if ($2 > x) x = $2 } END { print x + 0 }'); [ "$m" -gt "$most" ] && most=$m
    done
    echo "$a solver most_iterations $most at_iteration_limit $lim warnings $wrn"
  done
} > "$O/measured.txt"
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
abs() { local x=$1; echo "${x#-}"; }
# the checks, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" | tail -1; }
  for dt in 0.002 0.000125; do
    s0=$(get "release slide 0 $dt" slid_um)
    for dir in 22.5 45; do rule "1_required_slide_${dir}_$dt" share "$s0" "$(get "release slide $dir $dt" slid_um)" 100 101; done
  done
  for dt in 0.002 0.0005; do for b in 45 30; do
    p=$(get "release belt$b $dt" stopped_at_step); e=$(get "release belt${b}e $dt" stopped_at_step)
    rule "1_required_belt${b}_$dt" ge "$(abs $((p - e)))" 2
  done; done
  for dt in 0.002 0.000125; do
    s0=$(get "on slide 0 $dt" slid_um)
    rule "2_C1_no_direction_$dt" all_within "$s0" 10000 "$(get "on slide 22.5 $dt" slid_um)" "$(get "on slide 45 $dt" slid_um)"
    rule "2_C2_no_drift_$dt" all_le 10 "$(abs "$(get "on slide 22.5 $dt" side_um)")" "$(abs "$(get "on slide 45 $dt" side_um)")"
  done
  for frac in 0.72 0.8 0.9; do
    rule "2_C3_hold_$frac" all_within "$(get "on hold 0 $frac" creep_ums)" 100 "$(get "on hold 22.5 $frac" creep_ums)" "$(get "on hold 45 $frac" creep_ums)"
  done
  for dt in 0.002 0.0005; do for b in 45 30; do
    rule "2_C4_belt${b}_$dt" near "$(get "on belt$b $dt" stopped_at_step)" "$(get "release belt${b}e $dt" stopped_at_step)" 1
  done; done
  for t in SensorTest.ContactStage SensorTest.ContactVelocity; do
    rule "2_C5_$t" eq "$(grep -c " $t Passed$" "$O/suite_results_on.txt")" 1
  done
  for t in SleepTest.SleepingUnaffectedByWaking IpcTest.FoldDenseBlocksSolveMatches ForwardTest.DiscreteStiffLegPress; do
    rule "2_C6_$t" eq "$(grep -c " $t Passed$" "$O/suite_results_on.txt")" 1
  done
  n=0; same=0
  for f in $(cd "$O/release" && find suites -type f | sort) runs/lift_1.txt runs/lift_4.txt runs/lift_16.txt; do
    n=$((n + 1)); cmp -s "$O/release/$f" "$O/on/$f" && same=$((same + 1))
  done
  rule 3_suites_and_lift_slides_on_as_released eq "$same" "$n"
  n=0; same=0
  for k in 1 4 16; do n=$((n + 1)); cmp -s "$O/release/runs/lift_$k.txt" "$R/validation/run_016_sliding_lift/runs/def_mu0.4_v1.2_$k.txt" && same=$((same + 1)); done
  rule 0_rig_unchanged_lift_slides_as_run_016 eq "$same" "$n"
  diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep '^>' | sed 's/^> /3 changed with the switch set: /'
  rule 3_suite_changes_beside_the_lift eq "$(diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep '^>' | grep -v -c ' InverseTest.DiscreteInverseFreeBody ')" 0
  n=0; same=0
  for f in $(cd "$O/release" && find runs suites -type f | sort); do n=$((n + 1)); cmp -s "$O/release/$f" "$O/off/$f" && same=$((same + 1)); done
  rule 4_off_as_released_files eq "$same" "$n"
  rule 4_off_suite_as_released eq "$(diff "$O/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>')" 0
  rule 5_iteration_limit eq "$(get "on solver" at_iteration_limit)" 0
  rule 5_warnings eq "$(get "on solver" warnings)" 0
} > "$O/checks.txt"
date -u +%FT%TZ > "$O/finished.txt"
