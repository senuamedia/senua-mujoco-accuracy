#!/usr/bin/env bash
# Run 064: the fourteenth registered study (preregistrations/PREREGISTRATION_14.md), played once: the friction solved in
# the directions that can move (patches/in_design/qcqp_reduced.diff, switch MUJOCO_QCQP_REDUCED=1), for issue 1's open
# part, an arm resting on a contact creeps under Senua AI's configuration. Six arms, each in its own scratch copy, each
# making the same plays: the release (Google DeepMind's Linux release of MuJoCo 3.16.0), the patched build with its
# switch unset, and with it set, each under MuJoCo's defaults (def) and under Senua AI's configuration, the elliptic cone
# with 100 noslip iterations (rec). The plays, at the drawn coarse step and a quarter of it: a fresh two-link arm set
# down on its ball and left at rest in four contact poses, each as written and mirrored about the vertical plane through
# its shoulder, and dropped onto its ball in each pose; the arm held 1 m up by joint friction in two poses; a cube held at
# 0.5, 0.75 and 0.95 of its friction limit and slid along 0, 22.5 and 45 degrees, kept from turning and free to turn; a
# two-pad grip, box and mesh pads, at the centre and off it; and the first contact suite on a fresh cube. MuJoCo's own
# test suite on the release's test build and on the patched one, switch unset and set. Every number of the plays drawn
# from seed 14 (DRAW=1 prints the draw and plays nothing). Every rule judged by sx_contact rule.
# DRY=1 plays throwaway numbers (Study 10's and Study 13's arms, Study 10's cubes and grip) on all six arms, the patched
# arms on run 063's build of the same patch file, with no build and no MuJoCo suite, into dry/; no rule is read from it.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src at UPSTREAM_COMMIT, the release in
#        mujoco-3.16.0, and run 020's release test build in t20-release)
set -u
draw() {  # the registered numbers from the seed: Study 10's procedure, from x(0) = 14
  local x=14 V=0 D=""
  pick() { x=$(( (x * 1103515245 + 12345) % 2147483648 )); V=$(( $1 + x * ($2 - $1 + 1) / 2147483648 )); }
  dec() { local v=$1 p=$2 s="" d=1 i; [ "$v" -lt 0 ] && { s="-"; v=$(( -v )); }
    for ((i = 0; i < p; i++)); do d=$(( d * 10 )); done
    if [ "$p" -eq 0 ]; then echo "$s$v"; else printf "%s%d.%0${p}d\n" "$s" $(( v / d )) $(( v % d )); fi; }
  plain() { echo "$1" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
  # the values a kind may not take: Study 13's lists, the values Studies 10 to 13 drew, the settings of runs 043 to 063,
  # and those this draw has already given to that kind
  SEEN_step=" 0.00003125 0.000125 0.00015625 0.00025 0.0003 0.0003125 0.000375 0.0004 0.0004075 0.0005 0.000625 0.001 0.0012 0.00125 0.0015 0.0016 0.00163 0.002 0.0025 0.004 0.006 0.008 0.01 0.012 0.015 0.02 0.03 0.04 0.00114 0.000285 0.00165 0.0004125 0.0001425 0.00057 0.000855 0.016 0.00116 0.00029 0.00168 0.00042 "
  SEEN_len=" 0.0004 0.0005 0.0006 0.007 0.008 0.009 0.01 0.011 0.012 0.014 0.015 0.02 0.025 0.026 0.0271 0.028 0.03 0.032 0.033 0.035 0.038 0.04 0.042 0.043 0.045 0.05 0.08 0.09 0.1 0.2 0.24 0.25 0.26 0.267 0.27 0.273 0.28 0.29 0.3 0.32 0.4 0.5 0.0434 0.0392 0.096 0.0312 0.0093 0.0424 0.017 0.271 0.275 0.0264 0.00059 0.0121 0.0435 0.0336 0.0079 0.0499 0.0431 0.097 0.0305 0.0097 0.0439 0.0485 0.403 0.0454 0.0331 0.071 0.0349 0.0098 0.297 0.302 0.0295 0.00052 "
  SEEN_mass=" 0.15 0.161 0.17 0.18 0.2 0.22 0.24 0.25 0.35 0.4 0.45 0.5 0.519 0.6 0.9 0.95 1 1.023 1.05 1.1 1.15 1.2 1.3 1.4 1.6 2 3 5 1.861 0.881 0.202 0.442 1.113 0.524 0.176 1.381 0.218 1.903 0.908 0.248 0.408 1.423 1.714 1.438 0.209 1.08 0.578 0.194 "
  SEEN_fric=" 0 0.1 0.2 0.3 0.35 0.4 0.45 0.48 0.5 0.55 0.58 0.6 0.62 0.65 0.68 0.7 0.72 0.75 0.8 0.39 0.371 0.421 0.772 0.524 0.717 0.369 0.78 0.379 0.409 0.432 0.732 0.534 0.44 0.42 0.468 0.762 0.778 "
  SEEN_speed=" 0.3 0.6 0.8 0.85 0.9 0.95 1 1.1 1.2 1.5 2 2.4 3 4 5 1.01 3.24 1.47 3.67 1.16 0.81 3.19 0.98 4.35 0.86 2.97 0.96 3.5 "
  SEEN_ang=" 0 0.15 0.197 0.2 0.3 0.305 0.35 0.4 0.5 0.6 0.627 0.65 0.7 0.75 0.9 0.95 0.961 1 1.1 1.2 1.25 1.3 2.2 2.234 2.3 2.4 2.5 3 -0.3 -0.33 -0.45 -0.5 -0.6 -0.7 -0.9 -2 -2.1 -2.2 0.604 1.158 1.149 -0.545 0.245 0.831 0.223 0.993 -2.026 -2.003 2.463 0.165 0.924 0.146 0.628 0.516 0.907 1.211 -0.464 "
  SEEN_force=" 2.45 2.8 2.94 3 3.2 2.48 2.58 3.02 2.55 "
  SEEN_torque=" 1.5 5 5.5 6 12 5.96 8.79 5.63 "
  q() {  # q <kind> <name> <lo> <hi> <places>: one quantity, drawn again while its value is one its kind may not take
    local k="$1" v p seen
    while :; do
      pick "$3" "$4"; v="$(dec "$V" "$5")"; p="$(plain "$v")"
      eval "seen=\"\${SEEN_$k:- }\""
      case "$seen" in *" $p "*) echo "  ($2 drawn again: $v)" ;; *) eval "SEEN_$k=\"\${SEEN_$k:- }$p \""; break ;; esac
    done
    D="$p"; [ "${QUIET:-0}" = 1 ] || echo "$2 $p"
  }
  local c ok gm gmu gs l1 l2 m1 m2 mbb h1a h1b h2a h2b jf
  q step dt_coarse 100 200 5; c=$D; echo "dt_fine $(awk -v c="$c" 'BEGIN { printf "%.9g", c / 4 }')"
  # the arm (Study 10's ranges); four contact poses, two from each of Study 10's two pose ranges; set down from rest_h0
  # and dropped from drop_h0; held 1 m up by joint friction drawn again until it is more than gravity's torque on the
  # shoulder in both held poses
  q len len1 260 300 3; l1=$D; q len len2 240 320 3; l2=$D; q mass mass1 900 1200 3; m1=$D; q mass mass2 350 600 3; m2=$D
  q len rb 250 300 4; q mass mb 150 200 3; mbb=$D; q fric arm_mu 650 800 3
  q ang contact1_q1 500 700 3; q ang contact1_q2 900 1200 3; q ang contact2_q1 1100 1300 3; q ang contact2_q2 -600 -300 3
  q ang contact3_q1 500 700 3; q ang contact3_q2 900 1200 3; q ang contact4_q1 1100 1300 3; q ang contact4_q2 -600 -300 3
  q len rest_h0 40 60 5; q len drop_h0 100 150 4
  q ang held1_q1 0 400 3; h1a=$D; q ang held1_q2 600 1000 3; h1b=$D; q ang held2_q1 0 400 3; h2a=$D; q ang held2_q2 600 1000 3; h2b=$D
  while :; do
    QUIET=1 q torque joint_friction 500 600 2; jf=$D
    ok=$(awk -v j="$jf" -v l1="$l1" -v l2="$l2" -v m1="$m1" -v m2="$m2" -v mb="$mbb" -v a1="$h1a" -v b1="$h1b" -v a2="$h2a" -v b2="$h2b" '
      function t(a, b) { return 9.8 * (m1 * l1 / 2 * cos(a) + m2 * (l1 * cos(a) + l2 / 2 * cos(a + b)) + mb * (l1 * cos(a) + l2 * cos(a + b))) }
      BEGIN { print (j > t(a1, b1) && j > t(a2, b2)) ? 1 : 0 }')
    [ "$ok" = 1 ] && break
    echo "  (joint_friction drawn again: $jf)"
  done
  echo "joint_friction $jf"
  # the cube held and slid; the first suite's cube; the grip (Study 10's ranges and conditions)
  q mass cube_mass 1000 2000 3; q len cube_half 400 500 4; q fric cube_mu 350 500 3; q speed cube_v 80 120 2
  q mass s1_mass 800 2000 3; q len s1_half 300 450 4; q len s1_h0 70 100 3; q speed s1_vx 200 400 2
  q speed s1_vxchain 90 150 2; q fric s1_mu 300 450 3; q speed s1_vslide 250 500 2; q fric s1_muhold 400 500 3
  q mass grip_mass 200 250 3; gm=$D; q len grip_half 300 350 4; q fric grip_mu 680 800 3; gmu=$D
  while :; do
    QUIET=1 q force grip_squeeze 245 320 2; gs=$D
    ok=$(awk -v m="$gm" -v u="$gmu" -v s="$gs" 'BEGIN { r = 2 * u * s / (m * 9.8); print (r >= 1.7 && r <= 2) ? 1 : 0 }')
    [ "$ok" = 1 ] && break
    echo "  (grip_squeeze drawn again: $gs)"
  done
  echo "grip_squeeze $gs"
  q len grip_offset 70 100 4
}
if [ "${DRAW:-0}" = 1 ]; then draw; exit 0; fi
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
PF="$R/patches/in_design/qcqp_reduced.diff"; DIRS="0 22.5 45"; FRS="0.5 0.75 0.95"
ARMS="rel_def rel_rec off_def off_rec on_def on_rec"
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_064_study_14/dry"; QB="$W/mujoco-p63-build"; mkdir -p "$O"
  DTS="0.00114 0.000285"; ARM="len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717"
  POSES="0.604,1.158 1.149,-0.545 0.516,0.907 1.211,-0.464"; RESTH=0.00059; DROPH=0.0121
  HELDS="0.245,0.831 0.223,0.993"; JF=5.96
  CMASS=1.861; CHALF=0.0434; CMU=0.39; CV=1.01
  S1M=0.881; S1H=0.0392; S1H0=0.096; S1VX=3.24; S1VXC=1.47; S1MU=0.371; S1VS=3.67; S1MUH=0.421
  GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"; GOFF=0.0093
else
  O="$R/validation/run_064_study_14"; QB="$W/mujoco-s14-build"; mkdir -p "$O"; draw > "$O/draw.txt"
  v() { awk -v k="$1" '$1 == k { print $2 }' "$O/draw.txt"; }
  DTS="$(v dt_coarse) $(v dt_fine)"
  ARM="len1=$(v len1) len2=$(v len2) mass1=$(v mass1) mass2=$(v mass2) rb=$(v rb) mb=$(v mb) mu=$(v arm_mu)"
  POSES="$(v contact1_q1),$(v contact1_q2) $(v contact2_q1),$(v contact2_q2) $(v contact3_q1),$(v contact3_q2) $(v contact4_q1),$(v contact4_q2)"
  RESTH=$(v rest_h0); DROPH=$(v drop_h0); HELDS="$(v held1_q1),$(v held1_q2) $(v held2_q1),$(v held2_q2)"; JF=$(v joint_friction)
  CMASS=$(v cube_mass); CHALF=$(v cube_half); CMU=$(v cube_mu); CV=$(v cube_v)
  S1M=$(v s1_mass); S1H=$(v s1_half); S1H0=$(v s1_h0); S1VX=$(v s1_vx); S1VXC=$(v s1_vxchain); S1MU=$(v s1_mu)
  S1VS=$(v s1_vslide); S1MUH=$(v s1_muhold)
  GRIP="mass=$(v grip_mass) radius=$(v grip_half) mu=$(v grip_mu) squeeze=$(v grip_squeeze)"; GOFF=$(v grip_offset)
fi
num() { awk "BEGIN { printf \"%.6f\", $1 }" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
mir() { awk -v p="$1" 'BEGIN { split(p, a, ","); printf "%.15g,%.15g", 3.14159265358979323846 - a[1], -a[2] }'; }
CUBE="mass=$CMASS radius=$CHALF"; LIM=$(num "$CMU * $CMASS * 9.8")
S1HOLD=$(num "0.6 * $S1MUH * $S1M * 9.8"); S1SLIP=$(num "1.2 * $S1MUH * $S1M * 9.8"); S1LIFT=$(num "3 * $S1M * 9.8")
S1MU10K=$(awk -v u="$S1MU" 'BEGIN { printf "%d", u * 10000 + 0.5 }'); S1SLIPMN=$(awk -v s="$S1SLIP" 'BEGIN { printf "%d", s * 1000 }')
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
{
  echo "steps $DTS; arm $ARM; contact poses $POSES, set down from $RESTH, dropped from $DROPH; held poses $HELDS joint friction $JF"
  echo "cube $CUBE mu $CMU limit $LIM N speed $CV; grip $GRIP offset $GOFF"
  echo "suite 1: SUITE_CUBE=mass=$S1M radius=$S1H SUITE_H0=$S1H0 SUITE_VX=$S1VX SUITE_VXCHAIN=$S1VXC SUITE_MU=$S1MU SUITE_VSLIDE=$S1VS SUITE_MUHOLD=$S1MUH SUITE_HOLD=$S1HOLD SUITE_SLIP=$S1SLIP SUITE_LIFT=$S1LIFT; read with SUITE_MU10K=$S1MU10K SUITE_SLIPMN=$S1SLIPMN"
} > "$O/parameters.txt"
if [ "${DRY:-0}" != 1 ]; then
  rm -rf "${W:?}/mujoco-s14-src" "$W/s14-lib" "$QB" "$W/t64-s14" && mkdir -p "$W/mujoco-s14-src"
  (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-s14-src"
  (cd "$W/mujoco-s14-src" && patch -p1 -s < "$PF")
  echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-s14-src" -B "$W/s14-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$QB" && cmake --build "$W/s14-lib" -j"$J" && cmake --install "$W/s14-lib" ) > "$O/build_lib.log" 2>&1
  echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
  ( cmake -S "$W/mujoco-s14-src" -B "$W/t64-s14" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t64-s14" -j"$J" ) > "$O/build_tests.log" 2>&1
  echo "build tests exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
fi
arm() {  # <name> <MuJoCo folder> <def|rec> [switch]: the plays every arm makes, the same in each
  local name=$1 mj=$2 cfg=$3 sw=${4:-} X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"; mkdir -p "$X/suites"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_grip mjc_arm; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
    unset MUJOCO_DESAXCE
    if [ -n "$sw" ]; then export MUJOCO_QCQP_REDUCED=$sw; else unset MUJOCO_QCQP_REDUCED; fi
    case $cfg in rec) OPTS="cone=elliptic noslip=100" ;; *) OPTS="" ;; esac
    # shellcheck disable=SC2086
    ( export SUITE_CUBE="mass=$S1M radius=$S1H" SUITE_H0=$S1H0 SUITE_VX=$S1VX SUITE_VXCHAIN=$S1VXC SUITE_MU=$S1MU \
        SUITE_VSLIDE=$S1VS SUITE_MUHOLD=$S1MUH SUITE_HOLD=$S1HOLD SUITE_SLIP=$S1SLIP SUITE_LIFT=$S1LIFT
      tools/contact_suite.sh fresh $OPTS > /dev/null )
    mkdir -p resting held cubes; T=resting/stats.txt; H=held/stats.txt; C=cubes/stats.txt; : > $T; : > $H; : > $C
    for dt in $DTS; do
      k=0
      for PS in $POSES; do
        k=$((k + 1))
        for side in as mirror; do
          if [ $side = as ]; then Q=$PS; else Q=$(mir "$PS"); fi
          # shellcheck disable=SC2086
          tools/mjc_arm resting/rest_pose${k}_${side}_$dt.txt dt=$dt pose=$Q pose0=$Q $ARM h0=$RESTH secs=2 $OPTS trace=resting/rest_pose${k}_${side}_$dt.trace | sed "s|^STATS|STATS run rest_pose${k}_${side}_$dt|" >> $T
        done
        # shellcheck disable=SC2086
        tools/mjc_arm resting/drop_pose${k}_$dt.txt dt=$dt pose=$PS pose0=$PS $ARM h0=$DROPH secs=1 $OPTS | sed "s|^STATS|STATS run drop_pose${k}_$dt|" >> $T
      done
      k=0
      for PS in $HELDS; do
        k=$((k + 1))
        # shellcheck disable=SC2086
        tools/mjc_arm held/jf_pose${k}_$dt.txt dt=$dt pose=$PS pose0=$PS jointfriction=$JF h0=1 secs=2 $ARM $OPTS | sed "s|^STATS|STATS run jf_pose${k}_$dt|" >> $H
      done
      for dir in $DIRS; do
        for fr in $FRS; do
          p=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
          # shellcheck disable=SC2086
          tools/mjc_contact cubes/hold_${dir}_${fr}_$dt.txt dt=$dt h0=0 mu=$CMU $CUBE push=$p pushat=0.4 secs=1.6 dir=$dir $OPTS | sed "s|^STATS|STATS run hold_${dir}_${fr}_$dt|" >> $C
        done
        # shellcheck disable=SC2086
        tools/mjc_contact cubes/slide_${dir}_$dt.txt dt=$dt h0=0 vx0=$CV mu=$CMU $CUBE secs=1.2 dir=$dir $OPTS | sed "s|^STATS|STATS run slide_${dir}_$dt|" >> $C
        # shellcheck disable=SC2086
        tools/mjc_contact cubes/free_${dir}_$dt.txt dt=$dt h0=0 vx0=$CV mu=$CMU $CUBE secs=1.2 lock=0 dir=$dir $OPTS | sed "s|^STATS|STATS run free_${dir}_$dt|" >> $C
      done
      for off in 0 $GOFF; do for pad in box mesh; do
        # shellcheck disable=SC2086
        tools/mjc_grip cubes/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $OPTS | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> $C
      done; done
    done )
  rm -rf "${O:?}/${name:?}"; mkdir -p "$O/$name"; cp -R "$X/resting" "$X/held" "$X/cubes" "$X/suites" "$O/$name/"; rm -rf "${X:?}"
  echo "arm $name played $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
for a in $ARMS; do
  case $a in
    rel_*) arm "$a" "$W/mujoco-3.16.0" "${a#*_}" ;;
    off_*) arm "$a" "$QB" "${a#*_}" ;;
    on_*) arm "$a" "$QB" "${a#*_}" 1 ;;
  esac
done
if [ "${DRY:-0}" != 1 ]; then
  suite() {  # <build folder> <label> [switch]: every test, the two memory-heavy texture tests alone
    ( cd "$1" && if [ -n "${3:-}" ]; then export MUJOCO_QCQP_REDUCED=$3; else unset MUJOCO_QCQP_REDUCED; fi
      ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$2.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_$2_large.txt" 2>&1 )
    echo "suite $2 $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_$2_large.txt" | tail -1) $(date -u +%FT%TZ)" >> "$O/progress.txt"
  }
  suite "$W/t20-release" release
  suite "$W/t64-s14" off
  suite "$W/t64-s14" on 1
  for a in release off on; do
    cat "$O/ctest_$a.txt" "$O/ctest_${a}_large.txt" | awk 'match($0, /Test +#[0-9]+: /) {
           hdr = substr($0, RSTART, RLENGTH); num = hdr; gsub(/[^0-9]/, "", num); rest = substr($0, RSTART + RLENGTH)
           st = "unknown"
           if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) {
             st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st) }
           name = rest; p = index(name, "  # GetParam()"); if (p > 0) name = substr(name, 1, p - 1)
           p = index(name, " ..."); if (p > 0) name = substr(name, 1, p - 1); sub(/ +$/, "", name)
           print num, name, st }' | sort -n > "$O/suite_results_$a.txt"
  done
fi
# measuring
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
for a in $ARMS; do
  SUITE_MU10K=$S1MU10K SUITE_SLIPMN=$S1SLIPMN bash "$M/sx_contact_suite.sh" "$O/$a/suites/1/fresh" "$O/$a/suite1.txt" > /dev/null 2>&1
done
{
  for a in $ARMS; do
    for dt in $DTS; do
      for k in 1 2 3 4; do
        for side in as mirror; do
          f="$O/$a/resting/rest_pose${k}_${side}_$dt"
          echo "$a rest $k $side $dt creep_ums $(fld "$("$B" creep "$f.txt" | tail -1)" mean_speed_ums) $(awk '{ s[NR] = $0 } END { h = int(NR / 2); for (i = h + 1; i <= NR; i++) { split(s[i], c, " "); x += c[3] } printf "slip_x_ums %.1f", x / (NR - h) }' "$f.trace") $(tail -1 "$f.txt" | awk '{ printf "sideways_over_normal %.4f", ($5 != 0) ? $6 / $5 : 0 }')"
        done
        echo "$a drop $k $dt creep_ums $(fld "$("$B" creep "$O/$a/resting/drop_pose${k}_$dt.txt" | tail -1)" mean_speed_ums)"
      done
      for k in 1 2; do echo "$a jf $k $dt creep_ums $(fld "$("$B" creep "$O/$a/held/jf_pose${k}_$dt.txt" | tail -1)" mean_speed_ums)"; done
      for dir in $DIRS; do
        for fr in $FRS; do echo "$a hold $dir $fr $dt creep_ums $(fld "$("$B" creep "$O/$a/cubes/hold_${dir}_${fr}_$dt.txt" | tail -1)" mean_speed_ums)"; done
        echo "$a slide $dir $dt slid_um $(fld "$("$B" stop "$O/$a/cubes/slide_${dir}_$dt.txt" | tail -1)" slid_um)"
        echo "$a free $dir $dt slid_um $(fld "$("$B" stop "$O/$a/cubes/free_${dir}_$dt.txt" | tail -1)" slid_um)"
      done
      for off in 0 $GOFF; do for pad in box mesh; do
        echo "$a grip $pad $off $dt creep_ums $(fld "$("$B" creep "$O/$a/cubes/grip_${pad}_off${off}_$dt.txt" | tail -1)" mean_speed_ums)"
      done; done
    done
    echo "$a suite1 passed $(grep '^SUITE passed' "$O/$a/suite1.txt" | awk '{ print $3 }')"
    most=0; lim=0; wrn=0
    for f in "$O/$a/resting/stats.txt" "$O/$a/held/stats.txt" "$O/$a/cubes/stats.txt" "$O/$a/suites/1/fresh/stats.txt"; do
      m=$(grep -o 'most_iterations [0-9]*' "$f" | awk '{ if ($2 > m) m = $2 } END { print m + 0 }'); [ "$m" -gt "$most" ] && most=$m
      lim=$((lim + $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
      wrn=$((wrn + $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
    done
    echo "$a solver most_iterations $most at_iteration_limit $lim warnings $wrn"
  done
} > "$O/measured.txt"
if [ "${DRY:-0}" = 1 ]; then echo "dry run: $(wc -l < "$O/measured.txt") measured lines"; date -u +%FT%TZ > "$O/finished.txt"; exit 0; fi
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
ab() { local x=$1; echo "${x#-}"; }
most_of() { local m=0 x; for x in "$@"; do x=${x#-}; [ "$x" -gt "$m" ] && m=$x; done; echo "$m"; }
same_files() {  # <arm a> <arm b> <folders...>: how many of a's play files in the folders b has byte-identical, of how many
              # (not the files that record the settings: stats.txt, the suite's CONFIG)
  local a=$1 b=$2 n=0 s=0 f; shift 2
  for f in $(cd "$O/$a" && find "$@" -type f ! -name stats.txt ! -name CONFIG | sort); do n=$((n + 1)); cmp -s "$O/$a/$f" "$O/$b/$f" && s=$((s + 1)); done
  echo "$s $n"
}
diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep '^>' | awk '{ print $3 }' > "$O/suite_changed_on.txt"
# ---- the rules, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" | tail -1; }
  # required: under the configuration, released, a resting pose creeps beyond the bound
  # shellcheck disable=SC2046
  rule Q1_released_arm_creeps ge "$(most_of $(for dt in $DTS; do for k in 1 2 3 4; do for side in as mirror; do get "rel_rec rest $k $side $dt" creep_ums; done; done; done))" 11
  # safe when off; untouched where the patched solve is not used; MuJoCo's suite
  for k in def rec; do
    # shellcheck disable=SC2046
    rule "E1_safe_when_off_$k" eq $(same_files rel_$k off_$k resting held cubes suites)
  done
  rule E2_safe_when_off_mujoco_suite eq "$(diff "$O/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>')" 0
  # shellcheck disable=SC2046
  rule P1_defaults_untouched eq $(same_files rel_def on_def resting held cubes suites)
  rule M1_mujoco_suite_as_off eq "$(grep -c . "$O/suite_changed_on.txt")" 0
  # the switch set under the configuration: every resting pose and every dropped arm holds; nothing else changes
  # shellcheck disable=SC2046
  rule on_rec_R1_every_resting_pose_holds all_le 10 $(for dt in $DTS; do for k in 1 2 3 4; do for side in as mirror; do ab "$(get "on_rec rest $k $side $dt" creep_ums)"; done; done; done)
  # shellcheck disable=SC2046
  rule on_rec_R2_every_dropped_arm_holds all_le 10 $(for dt in $DTS; do for k in 1 2 3 4; do ab "$(get "on_rec drop $k $dt" creep_ums)"; done; done)
  # shellcheck disable=SC2046
  rule on_rec_N1_nothing_else_changes eq $(same_files rel_rec on_rec held cubes suites)
  # shellcheck disable=SC2046
  rule on_rec_J1_joint_holds all_le 10 $(for dt in $DTS; do for k in 1 2; do ab "$(get "on_rec jf $k $dt" creep_ums)"; done; done)
  # shellcheck disable=SC2046
  rule on_rec_H1_every_hold_holds all_le 10 $(for dt in $DTS; do for dir in $DIRS; do for fr in $FRS; do ab "$(get "on_rec hold $dir $fr $dt" creep_ums)"; done; done; done)
  # shellcheck disable=SC2046
  rule on_rec_G1_grip_holds all_le 10 $(for dt in $DTS; do for off in 0 $GOFF; do for pad in box mesh; do ab "$(get "on_rec grip $pad $off $dt" creep_ums)"; done; done; done)
  rule on_rec_K1_ten_tests eq "$(get "on_rec suite1" passed)" 10
  rule on_rec_V1_iteration_limit eq "$(get "on_rec solver" at_iteration_limit)" 0
  rule on_rec_V1_warnings eq "$(get "on_rec solver" warnings)" 0
  sed 's/^/reported: changed with the switch set: /' "$O/suite_changed_on.txt"
} > "$O/rules.txt"
{
  echo "rules: $(grep -c '^RULE' "$O/rules.txt"), held: $(grep -c ': HELD$' "$O/rules.txt")"
} >> "$O/rules.txt"
date -u +%FT%TZ > "$O/finished.txt"
