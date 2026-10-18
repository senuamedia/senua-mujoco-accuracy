#!/usr/bin/env bash
# Run 098: a design probe, not registered: it finds where to look and decides nothing. Noslip's multi-contact
# instability in Senua AI's set (issue 14): a free cube pushed square to a face at 0.95 of its friction limit rocks on its
# front edge and slips each swing (run 096, issue 1's open case), and stacks offset 1 or 5 mm a cube keep turning (run
# 093, issue 9); without noslip neither rocks. Noslip re-solves the friction with every normal force held as the main
# solver left it. The design patches/in_design/noslip_normal.diff (off unless MUJOCO_NOSLIP_NORMAL=1) also re-solves each
# elliptic contact's normal row in noslip's pass, as MuJoCo's PGS solves a scalar row (its regularization kept, held at
# zero or above), before solving that contact's friction in the cone the new normal gives. Built here from MuJoCo's
# source at UPSTREAM_COMMIT with Senua AI's five validated patch files and this one (p98), with its tests. Arms: set5
# (the five switches) and setn (the five and this one), both in p98, under the configuration (the elliptic cone, 100
# noslip iterations).
# Part A, the free cubes of Study 20 (a: 1.572 kg, half-size 0.0474 m, friction 0.61; b: 0.819 kg, 0.0316 m, 0.734),
#   condim 3, 4 and 6, pushed along 0 degrees at 0.5, 0.75 and 0.95 of the limit and along 45 degrees at 0.95, at
#   1.277 ms and a quarter of it; cube b with condim 3 at 1.277 ms also with the trace and tracedir. Read by Senua AI's
#   corrected measure, `creep`; the rig's statistics (the largest tilt, the steps with fewer than 4 contacts).
# Part B, run 093's offset stacks: 3 cubes, offset 1, 5 and 17 mm a cube, of run 078's cube and Study 16's, at 1.14 and
#   0.285 ms, played 2, 4 and 6 s. Read: `final` on each cube's tilt file.
# Part C, the set's other plays: Study 15's arm set down and dropped in two poses, the cube Study 19 held at 0.5 and 0.95
#   of its limit, Study 15's grip with box and mesh pads, at 1.71 and 0.4275 ms; MuJoCo's box and Study 19's box 1. Read:
#   `creep`; the boxes `fastest` over their last 160 steps.
# Part D, safe when off: part C's plays at 1.71 ms in Study 21's build (mujoco-s21v2-build) and in p98 with the five
#   switches, compared byte for byte, play files and solver statistics.
# Part E, MuJoCo's own test suite on p98: every switch unset, set5 and setn.
# usage: probe.sh <sx_contact, the corrected measure with fastest> <work folder>   (repository root, on the cloud
#        machine; the work folder holds mujoco-src at UPSTREAM_COMMIT and Study 21's build in mujoco-s21v2-build)
#        DRY=1: the plumbing only, into dry/: no build (Study 21's build stands in for p98, so setn is set5 there), no
#        suite
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_098_noslip_normal"; V="$W/mujoco-s21v2-build"; P98="$W/mujoco-p98-build"
if [ "${DRY:-0}" = 1 ]; then O="$O/dry"; P98="$V"; fi
mkdir -p "$O"; : > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
PS="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/qcqp_reduced_v2.diff $R/patches/boxbox_collinear.diff $R/patches/noslip_roll_kept_after_qcqp.diff $R/patches/in_design/noslip_normal.diff"
switches() {  # <0, 5 or n>
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT MUJOCO_NOSLIP_EQUALITY MUJOCO_NOSLIP_NORMAL
  if [ "$1" != 0 ]; then export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1; fi
  if [ "$1" = n ]; then export MUJOCO_NOSLIP_NORMAL=1; fi
}
switches 0
if [ "${DRY:-0}" != 1 ]; then
  rm -rf "${W:?}/mujoco-p98-src" "$W/p98-lib" "$P98" "$W/t98" && mkdir -p "$W/mujoco-p98-src"
  (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p98-src"
  for p in $PS; do (cd "$W/mujoco-p98-src" && patch -p1 -s < "$p") || log "patch FAILED $p"; done
  echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in $PS; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" > "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-p98-src" -B "$W/p98-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$P98" && cmake --build "$W/p98-lib" -j"$J" && cmake --install "$W/p98-lib" ) > "$O/build_lib.log" 2>&1
  log "build lib exit $?"
fi
X=$(mktemp -d)
for a in v:$V p:$P98; do
  n=${a%%:*}; mj=${a#*:}; mkdir -p "$X/$n" && cp -R "$R/tools" "$X/$n/"
  ( cd "$X/$n" && for r in mjc_scene mjc_arm mjc_contact mjc_grip mjc_stack; do MUJOCO_DIR=$mj tools/build_rig.sh $r > /dev/null 2>&1 || echo "rig $r FAILED for $n"; done ) >> "$O/progress.txt"
done
log "rigs built"
cr() { "$B" creep "$1" < /dev/null | tail -1 | grep -o "mean_speed_ums [-0-9]*"; }
fin() { "$B" final "$1" < /dev/null | tail -1 | awk '{ for (i = 1; i < NF; i++) { if ($i == "angle_urad") a = $(i + 1); if ($i == "speed_urads") s = $(i + 1) } } END { printf "tilt_urad %s turn_urad_s %s", a, s }'; }
REC="cone=elliptic noslip=100"
# ---- part A
mkdir -p "$O/a"; : > "$O/a/stats.txt"
{
  for arm in set5:5 setn:n; do
    an=${arm%%:*}; sw=${arm#*:}; switches $sw
    for cube in a:1.572:0.0474:0.61 b:0.819:0.0316:0.734; do
      cn=${cube%%:*}; rest=${cube#*:}; ms=${rest%%:*}; rest=${rest#*:}; hs=${rest%%:*}; mu=${rest#*:}
      for cdm in 3 4 6; do
        for dt in 0.001277 0.00031925; do
          for pl in 0:0.5 0:0.75 0:0.95 45:0.95; do
            dir=${pl%%:*}; fr=${pl#*:}
            pu=$(awk -v f="$fr" -v m="$ms" -v u="$mu" 'BEGIN { printf "%.6f", f * m * u * 9.8 }')
            f="free_${an}_${cn}_c${cdm}_${dt}_${dir}_$fr"; tr=""
            if [ "$cn$cdm$dt" = "b30.001277" ]; then tr="trace=$O/a/$f.trace tracedir=1"; fi
            # shellcheck disable=SC2086
            "$X/p/tools/mjc_contact" "$O/a/$f.txt" dt=$dt h0=0 mass=$ms radius=$hs mu=$mu push=$pu pushat=0.4 secs=1.6 dir=$dir lock=0 condim=$cdm $REC $tr | sed "s|^STATS|STATS run $f|" >> "$O/a/stats.txt"
            echo "$an cube $cn condim $cdm $dt along $dir at $fr | $(cr "$O/a/$f.txt") | $(grep "run $f " "$O/a/stats.txt" | grep -o 'most_iterations [0-9]* at_iteration_limit [0-9]*')"
          done
        done
      done
    done
  done
} > "$O/reading_free.txt"
switches 0
log "part A done"
# ---- part B
mkdir -p "$X/b"; : > "$O/stats_stacks.txt"
{
  for arm in set5:5 setn:n; do
    an=${arm%%:*}; sw=${arm#*:}; switches $sw
    for cube in k078:"mass=0.442 radius=0.0424 mu=0.524" k016:"mass=0.596 radius=0.0405 mu=0.528"; do
      cn=${cube%%:*}; cv=${cube#*:}
      for dt in 0.00114 0.000285; do for sh in 0.001 0.005 0.017; do for secs in 2 4 6; do
        q=b/${an}_${cn}_${sh}_${dt}_${secs}s
        # shellcheck disable=SC2086
        "$X/p/tools/mjc_stack" "$X/$q" dt=$dt n=3 shift=$sh secs=$secs $cv $REC | sed "s|^STATS|STATS run $q|" >> "$O/stats_stacks.txt"
        echo "$an $cn shift $sh $dt ${secs}s | cube 1 $(fin "$X/${q}_1_tilt.txt") | cube 2 $(fin "$X/${q}_2_tilt.txt") | cube 3 $(fin "$X/${q}_3_tilt.txt")"
      done; done; done
    done
  done
} > "$O/reading_stacks.txt"
switches 0
log "part B done"
# ---- parts C and D
A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"
CUBE="mass=1.561 radius=0.0489 mu=0.438"; LIM=$(awk 'BEGIN { printf "%.6f", 0.438 * 1.561 * 9.8 }')
GRIP="mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61"
setplays() {  # <rig folder> <out folder> <stats file> <steps>
  rg=$1; C=$2; st=$3; mkdir -p "$C"
  for dt in $4; do
    k=0
    for pose in 0.555,0.905 1.157,-0.378; do
      k=$((k + 1))
      # shellcheck disable=SC2086
      "$rg/mjc_arm" "$C/arm_rest${k}_$dt.txt" dt=$dt pose=$pose pose0=$pose $A15 h0=0.00043 secs=2 $REC | sed "s|^STATS|STATS run arm_rest${k}_$dt|" >> "$st"
      # shellcheck disable=SC2086
      "$rg/mjc_arm" "$C/arm_drop${k}_$dt.txt" dt=$dt pose=$pose pose0=$pose $A15 h0=0.0129 secs=3 $REC | sed "s|^STATS|STATS run arm_drop${k}_$dt|" >> "$st"
    done
    for fr in 0.5 0.95; do
      pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
      # shellcheck disable=SC2086
      "$rg/mjc_contact" "$C/hold_${fr}_$dt.txt" dt=$dt h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=0 lock=1 $REC | sed "s|^STATS|STATS run hold_${fr}_$dt|" >> "$st"
    done
    for pad in box mesh; do
      # shellcheck disable=SC2086
      "$rg/mjc_grip" "$C/grip_${pad}_$dt" dt=$dt offset=0.0092 pad=$pad $GRIP $REC | sed "s|^STATS|STATS run grip_${pad}_$dt|" >> "$st"
    done
  done
  for sc in "$R/validation/run_049_desaxce_v4/step2/scene.xml" "$R/validation/run_085_study_19/scenes/box1_0.016.xml"; do
    bn=$(basename "$(dirname "$sc")")_$(basename "$sc" .xml)
    "$rg/mjc_scene" "$C/box_$bn.txt" scene="$sc" body=box axis=1,0,0 secs=16 key=0 noslip=100 | sed "s|^STATS|STATS run box_$bn|" >> "$st"
  done
}
: > "$O/stats_set.txt"
{
  for arm in set5:5 setn:n; do
    an=${arm%%:*}; sw=${arm#*:}; switches $sw
    setplays "$X/p/tools" "$X/c_$an" "$X/c_$an.stats" "0.00171 0.0004275"
    cat "$X/c_$an.stats" | sed "s|^STATS run |STATS run ${an}_|" >> "$O/stats_set.txt"
    for f in $(cd "$X/c_$an" && ls | grep -v "_tilt.txt" | sort); do
      case "$f" in
        box_*) echo "$an $f | $("$B" fastest "$X/c_$an/$f" 160 < /dev/null | tail -1 | grep -o 'fastest_ums [0-9]*')" ;;
        *) echo "$an $f | $(cr "$X/c_$an/$f")" ;;
      esac
    done
  done
} > "$O/reading_set.txt"
switches 5
setplays "$X/v/tools" "$X/d_v" "$X/d_v.stats" "0.00171"
setplays "$X/p/tools" "$X/d_p" "$X/d_p.stats" "0.00171"
switches 0
{
  nf=0; same=0
  for f in $(cd "$X/d_v" && find . -type f | sort); do
    nf=$((nf + 1))
    if cmp -s "$X/d_v/$f" "$X/d_p/$f"; then same=$((same + 1)); else echo "differs, Study 21's build against p98 set5: $f"; fi
  done
  echo "play files $nf: the same bytes in p98 set5 $same"
  cmp -s "$X/d_v.stats" "$X/d_p.stats" && echo "solver statistics, p98 set5: the same bytes" || echo "solver statistics, p98 set5: DIFFERENT"
} > "$O/identity.txt"
log "parts C and D done"
rm -rf "${X:?}"
# ---- part E
if [ "${DRY:-0}" != 1 ]; then
  ( cmake -S "$W/mujoco-p98-src" -B "$W/t98" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t98" -j"$J" ) > "$O/build_tests.log" 2>&1
  log "build tests exit $?"
  suite() {  # <label> <0, 5 or n>: every test, the two memory-heavy texture tests alone
    ( cd "$W/t98" && switches "$2"
      ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$1.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_$1_large.txt" 2>&1 )
    log "suite $1 $(grep -E 'tests passed|tests failed' "$O/ctest_$1.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_$1_large.txt" | tail -1)"
  }
  suite off 0; suite set5 5; suite setn n
  for a in off set5 setn; do
    cat "$O/ctest_$a.txt" "$O/ctest_${a}_large.txt" | awk 'match($0, /Test +#[0-9]+: /) {
           hdr = substr($0, RSTART, RLENGTH); num = hdr; gsub(/[^0-9]/, "", num); rest = substr($0, RSTART + RLENGTH)
           st = "unknown"
           if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) {
             st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st) }
           name = rest; p = index(name, "  # GetParam()"); if (p > 0) name = substr(name, 1, p - 1)
           p = index(name, " ..."); if (p > 0) name = substr(name, 1, p - 1); sub(/ +$/, "", name)
           print num, name, st }' | sort -n > "$O/suite_results_$a.txt"
  done
  diff "$O/suite_results_set5.txt" "$O/suite_results_setn.txt" > "$O/suite_set5_against_setn.txt"
  for f in "$O"/ctest_*.txt "$O"/build_*.log; do sed -i "s|$HOME|~|g" "$f"; gzip -n "$f"; done
fi
date -u +%FT%TZ > "$O/finished.txt"
