#!/usr/bin/env bash
# Run 021, a patch in design (not registered): the slip-aligned pyramid's second version,
# patches/in_design/slip_aligned_pyramid_v2.diff, answering run 020's four side effects of the validated version:
#   (1) mjContact.frame is left as the release computes it: the pyramid's basis is turned only while its rows are
#       built, the turn is kept in a new mjContact field (frictionrot), and mj_contactForce turns the decoded forces
#       back into the frame, so every output that reads the frame or the contact force is in the release's frame;
#   (2) the slip includes the surfaces' own velocity (surfacevel), as MuJoCo's contact velocity does;
#   (3) a contact is turned only when its slip is at least opt.sleep_tolerance, MuJoCo's own speed below which a body
#       is at rest (engine_sleep.c, treeCanSleep; default 1e-3, engine_init.c), and only when its sliding (and rolling)
#       frictions are isotropic;
#   (4) the lift is measured, not tuned.
# Switch: MUJOCO_SLIP_ALIGNED_PYRAMID=1 (the same name; the two versions are separate builds of the release source).
# Three arms, each in its own scratch copy of the repository, the rigs built against: release (Google DeepMind's Linux
# release), off (version 2 built from source, switch unset), on (the same, switch set). Each plays, from scratch:
#   suites    both of the first deep dive's contact suites under MuJoCo's defaults
#   slide     a 1 kg cube (half-size 0.05 m, locked) set sliding at 1 m/s, friction 0.4, along 0, 22.5 and 45 degrees,
#             at 2 ms and 0.125 ms (run 003's slide)
#   hold      the same cube, friction 0.5, pushed from 0.5 s with 0.6, 0.69, 0.72, 0.8 and 0.9 of its limit along 0,
#             22.5 and 45 degrees, at 2 ms (run 003's hold)
#   belt      the cube set sliding at 1 m/s along x on a floor moving along y (surfacevel) at 1 m/s and at
#             0.5773502691896258 m/s, so it slips at 45 and 30 degrees to the frame's axes, at 2 ms and 0.5 ms; beside
#             each, the reference: the same slip speed along x on a still floor (1.4142135623730951 and
#             1.1547005383792515 m/s). Coulomb's friction does not depend on the slip's direction, so the cube's x speed
#             reaches 0 at the step the reference's does
#   free      the cube free to turn, set sliding at 1 m/s along 0, 22.5 and 45 degrees, 2 ms (run 005's)
#   lift      run 016's slides at friction 0.4 and 1.2 m/s, 10 ms, 2.5 ms and 0.625 ms, along x
# and MuJoCo's own test suite runs on the release's test build (run 020's) and on version 2's, switch unset and set.
# Read by Senua AI's measure (sx_contact stop, creep, hover), judged by its rule command. The five checks, fixed before
# any play:
#   1 required     on the release: the slides along 22.5 and 45 degrees go more than 1% further than along 0; the
#                  belt plays stop more than one step after their references
#   2 correct      with the switch on:
#                    C1 every slide along 22.5 and 45 within 1 in 10,000 of the slide along 0, at each step
#                    C2 no drift: the slides' sideways distance at most 10 um
#                    C3 the loads the release loses (0.72, 0.8, 0.9 of the limit): the hold along 22.5 and 45 creeps as
#                       along 0, within 1 in 100
#                    C4 each belt play stops within one step of its reference
#                    C5 the contact frame is the release's: MuJoCo's ContactStage and ContactVelocity tests pass
#                    C6 the three tests run 020 failed by noise pass: SleepingUnaffectedByWaking,
#                       FoldDenseBlocksSolveMatches, DiscreteStiffLegPress
#   3 nothing else gets worse   with the switch on, both suites and the lift slides byte-identical to the release; in
#                  MuJoCo's suite only tests that assert the pyramid's friction rows or their forces may change, each
#                  examined in the README
#   4 safe when off   the off arm byte-identical to the release, every file; MuJoCo's suite, switch unset, test for test
#                  as the release
#   5 the solver keeps converging   switch on: no play at the iteration limit, no warning
# Reported, not judged: the lift along 0, 22.5 and 45 degrees (sx_contact hover), whether version 2 still raises it to
# the axis value in every direction; the holds at 0.6 and 0.69 of the limit, whose creep the release gives below
# MuJoCo's rest speed along some directions, where version 2 by design does not turn; the free cube.
# usage: play.sh <sx_contact binary> <folder holding sx_contact_suite.sh> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src, the release in mujoco-3.16.0, and
#        run 020's release test build in t20-release)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; M="$(cd "${2:?}" && pwd)"
W="$(cd "${3:?}" && pwd)"; R="$(pwd)"; O="$R/validation/run_021_pyramid_v2"; mkdir -p "$O"; J=$(nproc)
P="$R/patches/in_design/slip_aligned_pyramid_v2.diff"
: > "$O/progress.txt"
# step 0: version 2's source is the release source with exactly the patch applied
rm -rf "$W/mujoco-pyr2-src" && mkdir -p "$W/mujoco-pyr2-src" && (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-pyr2-src"
(cd "$W/mujoco-pyr2-src" && patch -p1 -s < "$P")
{ echo "release source $(git -C "$W/mujoco-src" rev-parse HEAD), UPSTREAM_COMMIT $(cat "$R/UPSTREAM_COMMIT")"
  echo "patch $(sha256sum "$P" | cut -c1-16) applied: $(grep -c 'frictionrot' "$W/mujoco-pyr2-src/src/engine/engine_core_constraint.c") lines name frictionrot in the constraint file"
} > "$O/patch_check.txt"
# builds: the library, installed (for the rigs), and the test suite
lib() { cmake -S "$W/mujoco-pyr2-src" -B "$W/pyr2-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
          -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
          -DCMAKE_INSTALL_PREFIX="$W/mujoco-pyr2-build" && cmake --build "$W/pyr2-lib" -j"$J" && cmake --install "$W/pyr2-lib"; }
tst() { cmake -S "$W/mujoco-pyr2-src" -B "$W/t21-pyr2" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
          -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t21-pyr2" -j"$J"; }
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
arm off "$W/mujoco-pyr2-build"
arm on "$W/mujoco-pyr2-build" 1
# MuJoCo's own suite: the release's test build (run 020's) and version 2's, switch unset and set
suite() {  # <build folder> <label> [switch]
  ( cd "$1" && if [ -n "${3:-}" ]; then export MUJOCO_SLIP_ALIGNED_PYRAMID=$3; else unset MUJOCO_SLIP_ALIGNED_PYRAMID; fi
    ctest --timeout 900 -j"$J" > "$O/ctest_$2.txt" 2>&1 )
  echo "suite $2 exit $? $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1)" >> "$O/progress.txt"
}
suite "$W/t20-release" release
suite "$W/t21-pyr2" off
suite "$W/t21-pyr2" on 1
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
    for dt in 0.002 0.0005; do for b in belt45 ref45 belt30 ref30; do
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
    rule "1_required_belt${b}_$dt" ge "$(get "release belt$b $dt" stopped_at_step)" "$(( $(get "release ref$b $dt" stopped_at_step) + 2 ))"
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
    rule "2_C4_belt${b}_$dt" near "$(get "on belt$b $dt" stopped_at_step)" "$(get "on ref$b $dt" stopped_at_step)" 1
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
  echo "3 MuJoCo's suite, switch set against unset: $(diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep -c '^>') tests differ (examined in the README)"
  n=0; same=0
  for f in $(cd "$O/release" && find runs suites -type f | sort); do n=$((n + 1)); cmp -s "$O/release/$f" "$O/off/$f" && same=$((same + 1)); done
  rule 4_off_as_released_files eq "$same" "$n"
  rule 4_off_suite_as_released eq "$(diff "$O/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>')" 0
  rule 5_iteration_limit eq "$(get "on solver" at_iteration_limit)" 0
  rule 5_warnings eq "$(get "on solver" warnings)" 0
} > "$O/checks.txt"
date -u +%FT%TZ > "$O/finished.txt"
