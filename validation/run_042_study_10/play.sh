#!/usr/bin/env bash
# Run 042: the tenth registered study (preregistrations/PREREGISTRATION_10.md), played once: MuJoCo's recommended
# configuration as this record defines it, end to end, under MuJoCo's default integrator and under RK4. The
# configuration: the elliptic cone with 10 noslip iterations (Study 2), every other option at its default, on MuJoCo
# built with the inverse weight in the current pose, third version (patches/invweight_at_pose_v3.diff), its switch
# MUJOCO_INVWEIGHT_AT_POSE=1 set. The slip-aligned pyramid (Study 1) acts only on a pyramidal cone and is not part of
# it. Held on fresh numbers to every rule of the record's studies that the configuration can be put to.
# Six arms, each in its own scratch copy, each making the same plays: rel_def (Google DeepMind's Linux release,
# MuJoCo's defaults), rel_rec (the release, elliptic cone and noslip), off_def and off_rec (the patched build, switch
# unset, under each), config (the patched build, switch set, elliptic cone and noslip) and config_rk4 (the same under
# RK4). The plays: a cube held and slid
# along 0, 22.5 and 45 degrees and slid free to turn; the first contact suite on a fresh cube and the second at its own
# parameters; stacks, an offset stack, slides on the ground and on a box face; a two-pad grip, box and mesh pads, at the
# centre and off it; an arm on contact (set down, dropped), swinging on an elbow limit, held by joint friction, held by a
# connect and held by a weld, each written three ways; a free tumbling body at the step ladder. MuJoCo's own test suite
# on the release's test build and the patched one, switch unset and set. Every number of the plays drawn from seed 10
# (DRAW=1 prints the draw and plays nothing). Every rule judged by sx_contact rule.
# DRY=1 plays throwaway parameters (Study 8's arm and cubes, Study 2's cube, run 039's body) on the rel_def and rel_rec
# arms only (both the release), into dry/, with no build and no MuJoCo suite; no rule is read from it.
# usage: play.sh <folder holding sx_contact, sx_tumble and sx_contact_suite.sh> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src, the release in mujoco-3.16.0, and
#        run 020's release test build in t20-release)
set -u
draw() {  # the registered numbers from the seed: a stream x(n+1) = (1103515245 x(n) + 12345) mod 2^31 from x(0) = 10,
          # each number mapped onto its range's grid; a value its kind may not take is drawn again
  local x=10 V=0 D=""
  pick() { x=$(( (x * 1103515245 + 12345) % 2147483648 )); V=$(( $1 + x * ($2 - $1 + 1) / 2147483648 )); }
  dec() { local v=$1 p=$2 s="" d=1 i; [ "$v" -lt 0 ] && { s="-"; v=$(( -v )); }
    for ((i = 0; i < p; i++)); do d=$(( d * 10 )); done
    if [ "$p" -eq 0 ]; then echo "$s$v"; else printf "%s%d.%0${p}d\n" "$s" $(( v / d )) $(( v % d )); fi; }
  plain() { echo "$1" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
  # the values a kind may not take: those the record used for the same kind (every setting of that kind in the record's
  # play, probe and runner scripts, Study 9's draw among them, and the rigs' and suites' defaults where a study played
  # them), and those this draw has already given to that kind
  SEEN_step=" 0.00003125 0.000125 0.00015625 0.00025 0.0003 0.0003125 0.000375 0.0004 0.0004075 0.0005 0.000625 0.001 0.0012 0.00125 0.0015 0.0016 0.00163 0.002 0.0025 0.004 0.006 0.008 0.01 0.012 0.015 0.02 0.03 0.04 "
  SEEN_len=" 0.0004 0.0005 0.0006 0.007 0.008 0.009 0.01 0.011 0.012 0.014 0.015 0.02 0.025 0.026 0.0271 0.028 0.03 0.032 0.033 0.035 0.038 0.04 0.042 0.043 0.045 0.05 0.08 0.09 0.1 0.2 0.24 0.25 0.26 0.267 0.27 0.273 0.28 0.29 0.3 0.32 0.4 0.5 "
  SEEN_mass=" 0.15 0.161 0.17 0.18 0.2 0.22 0.24 0.25 0.35 0.4 0.45 0.5 0.519 0.6 0.9 0.95 1 1.023 1.05 1.1 1.15 1.2 1.3 1.4 1.6 2 3 5 "
  SEEN_fric=" 0 0.1 0.2 0.3 0.35 0.4 0.45 0.48 0.5 0.55 0.58 0.6 0.62 0.65 0.68 0.7 0.72 0.75 0.8 "
  SEEN_speed=" 0.3 0.6 0.8 0.85 0.9 0.95 1 1.1 1.2 1.5 2 2.4 3 4 5 "
  SEEN_ang=" 0 0.15 0.197 0.2 0.3 0.305 0.35 0.4 0.5 0.6 0.627 0.65 0.7 0.75 0.9 0.95 0.961 1 1.1 1.2 1.25 1.3 2.2 2.234 2.3 2.4 2.5 3 -0.3 -0.33 -0.45 -0.5 -0.6 -0.7 -0.9 -2 -2.1 -2.2 "
  SEEN_force=" 2.45 2.8 2.94 3 3.2 "
  SEEN_torque=" 1.5 5 5.5 6 12 "
  SEEN_inertia=" 0.0045 0.0072 0.0101 0.007512 0.009324 0.011372 "
  SEEN_spin=" 1.4 1.5 2 2.2 2.5 2.52 3 -0.83 -3.1 "
  q() {  # q <kind> <name> <lo> <hi> <places>: one quantity, drawn again while its value is one its kind may not take
    local k="$1" v p seen
    while :; do
      pick "$3" "$4"; v="$(dec "$V" "$5")"; p="$(plain "$v")"
      eval "seen=\"\${SEEN_$k:- }\""
      case "$seen" in *" $p "*) echo "  ($2 drawn again: $v)" ;; *) eval "SEEN_$k=\"\${SEEN_$k:- }$p \""; break ;; esac
    done
    D="$p"; [ "${QUIET:-0}" = 1 ] || echo "$2 $p"
  }
  local c ok i1 i2 i3 w1 w2 w3 gm gmu gs l1 l2 m1 m2 rbb mbb h1a h1b h2a h2b jf
  # the steps: the coarse step on a grid of 0.01 ms, the fine a quarter of it
  q step dt_coarse 100 200 5; c=$D; echo "dt_fine $(awk -v c="$c" 'BEGIN { printf "%.9g", c / 4 }')"
  # the cube held and slid along 0, 22.5 and 45 degrees (Studies 1 and 2)
  q mass cube_mass 1000 2000 3; q len cube_half 400 500 4; q fric cube_mu 350 500 3; q speed cube_v 80 120 2
  # the first suite's fresh cube (Study 2's way)
  q mass s1_mass 800 2000 3; q len s1_half 300 450 4; q len s1_h0 70 100 3; q speed s1_vx 200 400 2
  q speed s1_vxchain 90 150 2; q fric s1_mu 300 450 3; q speed s1_vslide 250 500 2; q fric s1_muhold 400 500 3
  # the grip: the squeeze drawn again until the friction of the two pads is from 1.7 to 2 times the cube's weight
  q mass grip_mass 200 250 3; gm=$D; q len grip_half 300 350 4; q fric grip_mu 680 800 3; gmu=$D
  while :; do
    QUIET=1 q force grip_squeeze 245 320 2; gs=$D
    ok=$(awk -v m="$gm" -v u="$gmu" -v s="$gs" 'BEGIN { r = 2 * u * s / (m * 9.8); print (r >= 1.7 && r <= 2) ? 1 : 0 }')
    [ "$ok" = 1 ] && break
    echo "  (grip_squeeze drawn again: $gs)"
  done
  echo "grip_squeeze $gs"
  q len grip_offset 70 100 4
  # the stacks, the offset stack and the slides on the ground and on a box face
  q mass stack_mass 350 500 3; q len stack_half 400 500 4; q fric stack_mu 500 600 3; q len stack_shift 120 200 4
  q speed stack_v 90 120 2
  # the arm
  q len len1 260 300 3; l1=$D; q len len2 240 320 3; l2=$D; q mass mass1 900 1200 3; m1=$D; q mass mass2 350 600 3; m2=$D
  q len rb 250 300 4; rbb=$D; q mass mb 150 200 3; mbb=$D; q fric arm_mu 650 800 3
  # on contact: two poses, set down and dropped
  q ang contact1_q1 500 700 3; q ang contact1_q2 900 1200 3; q ang contact2_q1 1100 1300 3; q ang contact2_q2 -600 -300 3
  q len rest_h0 40 60 5; q len drop_h0 100 150 4
  # held 1 m up (on an elbow limit, by joint friction, by a connect, by a weld): two poses, the elbow's lower limits
  q ang held1_q1 0 400 3; h1a=$D; q ang held1_q2 600 1000 3; h1b=$D; q ang held2_q1 0 400 3; h2a=$D; q ang held2_q2 600 1000 3; h2b=$D
  q ang limit1_lo -2200 -2000 3; q ang limit2_lo -2200 -2000 3
  # the joint friction, drawn again until it is more than gravity's torque on the shoulder in both held poses
  while :; do
    QUIET=1 q torque joint_friction 500 600 2; jf=$D
    ok=$(awk -v j="$jf" -v l1="$l1" -v l2="$l2" -v m1="$m1" -v m2="$m2" -v mb="$mbb" -v a1="$h1a" -v b1="$h1b" -v a2="$h2a" -v b2="$h2b" '
      function t(a, b) { return 9.8 * (m1 * l1 / 2 * cos(a) + m2 * (l1 * cos(a) + l2 / 2 * cos(a + b)) + mb * (l1 * cos(a) + l2 * cos(a + b))) }
      BEGIN { print (j > t(a1, b1) && j > t(a2, b2)) ? 1 : 0 }')
    [ "$ok" = 1 ] && break
    echo "  (joint_friction drawn again: $jf)"
  done
  echo "joint_friction $jf"
  q ang fold 2200 2500 3
  # the tumbling body, as in Study 9
  while :; do
    QUIET=1 q inertia i1 3000 12000 6; i1=$D; QUIET=1 q inertia i2 3000 12000 6; i2=$D; QUIET=1 q inertia i3 3000 12000 6; i3=$D
    ok=$(awk -v a="$i1" -v b="$i2" -v c="$i3" 'function apart(x, y) { return (x > y ? x - y : y - x) * 10 > (x > y ? x : y) }
      BEGIN { print (a <= b + c && b <= a + c && c <= a + b && apart(a, b) && apart(b, c) && apart(a, c)) ? 1 : 0 }')
    [ "$ok" = 1 ] && break
    echo "  (moments drawn again: $i1 $i2 $i3)"
  done
  echo "i1 $i1"; echo "i2 $i2"; echo "i3 $i3"
  while :; do
    QUIET=1 q spin w1 -350 350 2; w1=$D; QUIET=1 q spin w2 -350 350 2; w2=$D; QUIET=1 q spin w3 -350 350 2; w3=$D
    ok=$(awk -v a="$w1" -v b="$w2" -v c="$w3" 'function big(x) { return (x < 0 ? -x : x) >= 0.5 }
      BEGIN { s = a * a + b * b + c * c; print (s >= 4 && s <= 16 && big(a) && big(b) && big(c)) ? 1 : 0 }')
    [ "$ok" = 1 ] && break
    echo "  (spin drawn again: $w1 $w2 $w3)"
  done
  echo "w1 $w1"; echo "w2 $w2"; echo "w3 $w3"
}
if [ "${DRAW:-0}" = 1 ]; then draw; exit 0; fi
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; T="$M/sx_tumble"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
J=$(nproc); PF="$R/patches/invweight_at_pose_v3.diff"; LADDER="0.01 0.0025 0.000625 0.00015625"
DIRS="0 22.5 45"; FRS="0.5 0.75 0.95"; NS="5 9"; REC="cone=elliptic noslip=10"
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_042_study_10/dry"; ARMS="rel_def rel_rec"; mkdir -p "$O"
  DTS="0.0016 0.0004"; CMASS=1.6; CHALF=0.045; CMU=0.45; CV=1.1
  S1M=1.6; S1H=0.045; S1H0=0.09; S1VX=3; S1VXC=1.2; S1MU=0.45; S1VS=4; S1MUH=0.4
  GRIP="mass=0.24 radius=0.033 mu=0.68 squeeze=3.2"; GOFF=0.007
  KCUBE="mass=0.45 radius=0.043 mu=0.58"; SHIFT=0.014; VS=0.9
  ARM="len1=0.29 len2=0.27 mass1=0.95 mass2=0.45 rb=0.026 mb=0.17 mu=0.72"; POSES="0.65,0.95 1.25,-0.45"
  RESTH=0.0006; DROPH=0.011; HELDS="0.15,0.75 0.3,1.0"; LOS="-2.1 -2"; JF=5.5; FOLD=0,2.4
  BODY="i1=0.0045 i2=0.0072 i3=0.0101 w1=2.2 w2=1.4 w3=-3.1 secs=2"
else
  O="$R/validation/run_042_study_10"; ARMS="rel_def rel_rec off_def off_rec config config_rk4"
  mkdir -p "$O"; draw > "$O/draw.txt"
  v() { awk -v k="$1" '$1 == k { print $2 }' "$O/draw.txt"; }
  DTS="$(v dt_coarse) $(v dt_fine)"; CMASS=$(v cube_mass); CHALF=$(v cube_half); CMU=$(v cube_mu); CV=$(v cube_v)
  S1M=$(v s1_mass); S1H=$(v s1_half); S1H0=$(v s1_h0); S1VX=$(v s1_vx); S1VXC=$(v s1_vxchain); S1MU=$(v s1_mu)
  S1VS=$(v s1_vslide); S1MUH=$(v s1_muhold)
  GRIP="mass=$(v grip_mass) radius=$(v grip_half) mu=$(v grip_mu) squeeze=$(v grip_squeeze)"; GOFF=$(v grip_offset)
  KCUBE="mass=$(v stack_mass) radius=$(v stack_half) mu=$(v stack_mu)"; SHIFT=$(v stack_shift); VS=$(v stack_v)
  ARM="len1=$(v len1) len2=$(v len2) mass1=$(v mass1) mass2=$(v mass2) rb=$(v rb) mb=$(v mb) mu=$(v arm_mu)"
  POSES="$(v contact1_q1),$(v contact1_q2) $(v contact2_q1),$(v contact2_q2)"; RESTH=$(v rest_h0); DROPH=$(v drop_h0)
  HELDS="$(v held1_q1),$(v held1_q2) $(v held2_q1),$(v held2_q2)"; LOS="$(v limit1_lo) $(v limit2_lo)"
  JF=$(v joint_friction); FOLD=0,$(v fold)
  BODY="i1=$(v i1) i2=$(v i2) i3=$(v i3) w1=$(v w1) w2=$(v w2) w3=$(v w3) secs=2"
fi
# derived: the cube's friction limit and Coulomb's distance; the first suite's pushes, lift and reading constants
num() { awk "BEGIN { printf \"%.6f\", $1 }" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
CUBE="mass=$CMASS radius=$CHALF"; LIM=$(num "$CMU * $CMASS * 9.8")
COULOMB=$(awk -v v="$CV" -v u="$CMU" 'BEGIN { printf "%d", v * v / (2 * u * 9.8) * 1e6 + 0.5 }')
S1HOLD=$(num "0.6 * $S1MUH * $S1M * 9.8"); S1SLIP=$(num "1.2 * $S1MUH * $S1M * 9.8"); S1LIFT=$(num "3 * $S1M * 9.8")
S1MU10K=$(awk -v u="$S1MU" 'BEGIN { printf "%d", u * 10000 + 0.5 }'); S1SLIPMN=$(awk -v s="$S1SLIP" 'BEGIN { printf "%d", s * 1000 }')
set -- $DTS; DC=$1; DF=$2
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
{
  echo "steps $DTS; cube $CUBE mu $CMU limit $LIM N speed $CV Coulomb $COULOMB um"
  echo "suite 1: SUITE_CUBE=mass=$S1M radius=$S1H SUITE_H0=$S1H0 SUITE_VX=$S1VX SUITE_VXCHAIN=$S1VXC SUITE_MU=$S1MU SUITE_VSLIDE=$S1VS SUITE_MUHOLD=$S1MUH SUITE_HOLD=$S1HOLD SUITE_SLIP=$S1SLIP SUITE_LIFT=$S1LIFT; read with SUITE_MU10K=$S1MU10K SUITE_SLIPMN=$S1SLIPMN"
  echo "grip $GRIP offset $GOFF; stacks $NS of $KCUBE shift $SHIFT slide $VS"
  echo "arm $ARM; contact poses $POSES rest h0 $RESTH drop h0 $DROPH; held poses $HELDS lower limits $LOS joint friction $JF; folded $FOLD"
  echo "body $BODY"
} > "$O/parameters.txt"
if [ "${DRY:-0}" != 1 ]; then
  rm -rf "${W:?}/mujoco-s10-src" && mkdir -p "$W/mujoco-s10-src" && (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-s10-src"
  (cd "$W/mujoco-s10-src" && patch -p1 -s < "$PF")
  echo "release source $(git -C "$W/mujoco-src" rev-parse HEAD); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-s10-src" -B "$W/s10-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$W/mujoco-s10-build" && cmake --build "$W/s10-lib" -j"$J" && cmake --install "$W/s10-lib" ) > "$O/build_lib.log" 2>&1
  echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
  ( cmake -S "$W/mujoco-s10-src" -B "$W/t42-s10" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t42-s10" -j"$J" ) > "$O/build_tests.log" 2>&1
  echo "build tests exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
fi
arm() {  # <name> <MuJoCo folder> <def|rec> [switch]: the plays every arm makes, the same in each
  local name=$1 mj=$2 cfg=$3 sw=${4:-} X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"; mkdir -p "$X/suites"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_pair mjc_arm mjc_stack mjc_grip mjc_tumble; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
    if [ -n "$sw" ]; then export MUJOCO_INVWEIGHT_AT_POSE=$sw; else unset MUJOCO_INVWEIGHT_AT_POSE; fi
    case $cfg in rec) OPTS=$REC ;; rk4) OPTS="$REC integ=RK4" ;; *) OPTS="" ;; esac
    # shellcheck disable=SC2086
    ( export SUITE_CUBE="$CUBE1" SUITE_H0=$S1H0 SUITE_VX=$S1VX SUITE_VXCHAIN=$S1VXC SUITE_MU=$S1MU SUITE_VSLIDE=$S1VS \
        SUITE_MUHOLD=$S1MUH SUITE_HOLD=$S1HOLD SUITE_SLIP=$S1SLIP SUITE_LIFT=$S1LIFT
      tools/contact_suite.sh fresh $OPTS > /dev/null )
    # shellcheck disable=SC2086
    tools/contact_suite2.sh registered $OPTS > /dev/null
    mkdir -p runs cubes tumble; S=runs/stats.txt; C=cubes/stats.txt; : > $S; : > $C
    for dt in $DTS; do
      for dir in $DIRS; do
        for fr in $FRS; do
          p=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
          # shellcheck disable=SC2086
          tools/mjc_contact cubes/hold_${dir}_${fr}_$dt.txt dt=$dt h0=0 mu=$CMU $CUBE push=$p pushat=0.4 secs=1.6 dir=$dir $OPTS | sed "s|^STATS|STATS run hold_${dir}_${fr}_$dt|" >> $C
        done
        # shellcheck disable=SC2086
        tools/mjc_contact cubes/slide_${dir}_$dt.txt dt=$dt h0=0 vx0=$CV mu=$CMU $CUBE secs=1.2 dir=$dir $OPTS | sed "s|^STATS|STATS run slide_${dir}_$dt|" >> $C
      done
      # shellcheck disable=SC2086
      for n in $NS; do tools/mjc_stack cubes/stack${n}_$dt dt=$dt n=$n secs=2 $KCUBE $OPTS | sed "s|^STATS|STATS run stack${n}_$dt|" >> $C; done
      # shellcheck disable=SC2086
      tools/mjc_stack cubes/offset3_$dt dt=$dt n=3 shift=$SHIFT secs=2 $KCUBE $OPTS | sed "s|^STATS|STATS run offset3_$dt|" >> $C
      # shellcheck disable=SC2086
      tools/mjc_stack cubes/slide_ground_$dt dt=$dt n=1 vx=$VS secs=1 base=0 $KCUBE $OPTS | sed "s|^STATS|STATS run slide_ground_$dt|" >> $C
      # shellcheck disable=SC2086
      tools/mjc_stack cubes/slide_box_$dt dt=$dt n=1 vx=$VS secs=1 base=0.5 $KCUBE $OPTS | sed "s|^STATS|STATS run slide_box_$dt|" >> $C
    done
    for dir in $DIRS; do
      # shellcheck disable=SC2086
      tools/mjc_contact cubes/free_$dir.txt dt=$DC h0=0 vx0=$CV mu=$CMU $CUBE secs=1.2 lock=0 dir=$dir $OPTS | sed "s|^STATS|STATS run free_$dir|" >> $C
    done
    for off in 0 $GOFF; do for pad in box mesh; do
      # shellcheck disable=SC2086
      tools/mjc_grip cubes/grip_${pad}_off$off dt=$DC offset=$off pad=$pad $GRIP $OPTS | sed "s|^STATS|STATS run grip_${pad}_off$off|" >> $C
    done; done
    k=0
    for PS in $POSES; do
      k=$((k + 1))
      for scene in rest drop; do
        if [ $scene = rest ]; then SC="h0=$RESTH secs=2"; else SC="h0=$DROPH secs=1"; fi
        for dt in $DTS; do for wr in native straight folded; do
          case $wr in native) P0=$PS ;; straight) P0=0,0 ;; folded) P0=$FOLD ;; esac
          # shellcheck disable=SC2086
          tools/mjc_arm runs/arm_pose${k}_${scene}_${dt}_$wr.txt dt=$dt pose=$PS pose0=$P0 $ARM $SC $OPTS | sed "s|^STATS|STATS run arm_pose${k}_${scene}_${dt}_$wr|" >> $S
        done; done
      done
    done
    set -- $LOS
    k=0
    for PS in $HELDS; do
      k=$((k + 1)); lo=$1; shift; hi=${PS#*,}
      for dt in $DTS; do for wr in native straight folded; do
        case $wr in native) P0=$PS ;; straight) P0=0,0 ;; folded) P0=$FOLD ;; esac
        for sc in swing hold connect weld; do
          case $sc in swing) H="elbowlimit=$lo,$hi" ;; hold) H="jointfriction=$JF" ;; connect) H="tipconnect=1" ;; weld) H="tipweld=1" ;; esac
          # shellcheck disable=SC2086
          tools/mjc_arm runs/${sc}_pose${k}_${dt}_$wr.txt dt=$dt pose=$PS pose0=$P0 $H h0=1 secs=2 $ARM $OPTS | sed "s|^STATS|STATS run ${sc}_pose${k}_${dt}_$wr|" >> $S
        done
      done; done
    done
    T2=tumble/stats.txt; : > $T2
    for dt in $LADDER; do
      # shellcheck disable=SC2086
      tools/mjc_tumble tumble/tumble_$dt.txt dt=$dt $BODY $OPTS | sed "s|^STATS|STATS run tumble_$dt|" >> $T2
    done )
  rm -rf "${O:?}/${name:?}"; mkdir -p "$O/$name"; cp -R "$X/runs" "$X/cubes" "$X/suites" "$X/tumble" "$O/$name/"; rm -rf "${X:?}"
  echo "arm $name played $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
CUBE1="mass=$S1M radius=$S1H"
for a in $ARMS; do
  case $a in
    rel_def) arm rel_def "$W/mujoco-3.16.0" def ;;
    rel_rec) arm rel_rec "$W/mujoco-3.16.0" rec ;;
    off_def) arm off_def "$W/mujoco-s10-build" def ;;
    off_rec) arm off_rec "$W/mujoco-s10-build" rec ;;
    config) arm config "$W/mujoco-s10-build" rec 1 ;;
    config_rk4) arm config_rk4 "$W/mujoco-s10-build" rk4 1 ;;
  esac
done
if [ "${DRY:-0}" != 1 ]; then
  suite() {  # <build folder> <label> [switch]
    ( cd "$1" && if [ -n "${3:-}" ]; then export MUJOCO_INVWEIGHT_AT_POSE=$3; else unset MUJOCO_INVWEIGHT_AT_POSE; fi
      ctest --timeout 900 -j"$J" > "$O/ctest_$2.txt" 2>&1 )
    echo "suite $2 exit $? $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1) $(date -u +%FT%TZ)" >> "$O/progress.txt"
  }
  suite "$W/t20-release" release
  suite "$W/t42-s10" off
  suite "$W/t42-s10" on 1
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
# measuring: every number a rule reads, from Senua AI's measures, the first deep dive's suite runner, or the rigs' own
# STATS lines (plumbing extracts them)
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
st() { grep "^STATS run $2 " "$1" | head -1; }
for a in $ARMS; do
  SUITE_MU10K=$S1MU10K SUITE_SLIPMN=$S1SLIPMN bash "$M/sx_contact_suite.sh" "$O/$a/suites/1/fresh" "$O/$a/suite1.txt" > /dev/null 2>&1
done
{
  for a in $ARMS; do
    c=$O/$a/cubes
    for dt in $DTS; do for dir in $DIRS; do
      for fr in $FRS; do echo "$a hold $dir $fr $dt creep_ums $(fld "$("$B" creep $c/hold_${dir}_${fr}_$dt.txt | tail -1)" mean_speed_ums)"; done
      echo "$a slide $dir $dt slid_um $(fld "$("$B" stop $c/slide_${dir}_$dt.txt | tail -1)" slid_um) side_um $(fld "$(st $c/stats.txt slide_${dir}_$dt)" side_um)"
    done; done
    for dir in $DIRS; do
      echo "$a free $dir slid_um $(fld "$("$B" stop $c/free_$dir.txt | tail -1)" slid_um) side_um $(fld "$(st $c/stats.txt free_$dir)" side_um)"
    done
    for off in 0 $GOFF; do for pad in box mesh; do
      g=$c/grip_${pad}_off$off
      echo "$a grip $pad $off creep_ums $(fld "$("$B" creep $g.txt | tail -1)" mean_speed_ums) turned_urad $(fld "$("$B" final ${g}_tilt.txt | tail -1)" angle_urad) turning_urads $(fld "$("$B" final ${g}_tilt.txt | tail -1)" speed_urads)"
    done; done
    echo "$a suite1 passed $(grep '^SUITE passed' $O/$a/suite1.txt | awk '{ print $3 }') t06_failed $(grep '^T06' $O/$a/suite1.txt | grep -c ': FAIL$')"
    d=$O/$a/runs
    for k in 1 2; do for scene in rest drop; do for dt in $DTS; do
      n=$d/arm_pose${k}_${scene}_${dt}_native.txt
      for wr in straight folded; do
        e=$("$B" ends $n $d/arm_pose${k}_${scene}_${dt}_$wr.txt | tail -1)
        echo "$a arm pose$k $scene $dt $wr apart_nm $(fld "$e" place_apart_nm) speed_apart_ums $(fld "$e" speed_apart_ums)"
      done
      if [ $scene = rest ]; then
        for wr in native straight folded; do
          echo "$a creep pose$k $dt $wr mean_speed_ums $(fld "$("$B" creep $d/arm_pose${k}_${scene}_${dt}_$wr.txt | tail -1)" mean_speed_ums)"
        done
      fi
    done; done; done
    for sc in swing hold connect weld; do for k in 1 2; do for dt in $DTS; do
      n=$d/${sc}_pose${k}_${dt}_native.txt
      for wr in straight folded; do
        e=$("$B" ends $n $d/${sc}_pose${k}_${dt}_$wr.txt | tail -1)
        echo "$a $sc pose$k $dt $wr apart_nm $(fld "$e" place_apart_nm) speed_apart_ums $(fld "$e" speed_apart_ums)"
      done
      if [ $sc = hold ]; then for wr in native straight folded; do
        echo "$a holdcreep pose$k $dt $wr mean_speed_ums $(fld "$("$B" creep $d/hold_pose${k}_${dt}_$wr.txt | tail -1)" mean_speed_ums)"
      done; fi
    done; done; done
    for dt in $LADDER; do
      t=$("$T" tumble "$O/$a/tumble/tumble_$dt.txt" | tail -1)
      echo "$a tumble $dt energy_end_ppm $(fld "$t" energy_end_ppm) energy_largest_ppm $(fld "$t" energy_largest_ppm) momentum_end_ppm $(fld "$t" momentum_end_ppm) momentum_largest_ppm $(fld "$t" momentum_largest_ppm)"
    done
    most=0; lim=0; wrn=0
    for f in "$O/$a/runs/stats.txt" "$O/$a/cubes/stats.txt" "$O/$a/tumble/stats.txt" "$O/$a/suites/1/fresh/stats.txt" "$O/$a/suites/2/registered/stats.txt"; do
      m=$(grep -o 'most_iterations [0-9]*' "$f" | awk '{ if ($2 > m) m = $2 } END { print m + 0 }'); [ "$m" -gt "$most" ] && most=$m
      lim=$((lim + $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
      wrn=$((wrn + $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
    done
    echo "$a solver most_iterations $most at_iteration_limit $lim warnings $wrn"
    # the most iterations over the plays of the kind Study 2's R6 bounded: the holds, the slides with the cube kept from
    # turning, and both suites (the free cube, the stacks and the grips are reported in the line above, not here)
    most=$(grep -E '^STATS run (hold_|slide_[0-9])' "$O/$a/cubes/stats.txt" | grep -o 'most_iterations [0-9]*' | awk '{ if ($2 > m) m = $2 } END { print m + 0 }')
    for f in "$O/$a/suites/1/fresh/stats.txt" "$O/$a/suites/2/registered/stats.txt"; do
      m=$(grep -o 'most_iterations [0-9]*' "$f" | awk '{ if ($2 > m) m = $2 } END { print m + 0 }'); [ "$m" -gt "$most" ] && most=$m
    done
    echo "$a solvercubes most_iterations $most"
  done
} > "$O/measured.txt"
if [ "${DRY:-0}" = 1 ]; then echo "dry run: $(wc -l < "$O/measured.txt") measured lines"; date -u +%FT%TZ > "$O/finished.txt"; exit 0; fi
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
ab() { local x=$1; echo "${x#-}"; }
same_files() {  # <arm a> <arm b> <folders...>: how many of a's files in the folders b has byte-identical, and of how many
  local a=$1 b=$2 n=0 s=0 f; shift 2
  for f in $(cd "$O/$a" && find "$@" -type f | sort); do n=$((n + 1)); cmp -s "$O/$a/$f" "$O/$b/$f" && s=$((s + 1)); done
  echo "$s $n"
}
# ---- the rules, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" | tail -1; }
  # required: the defects are there in the release, MuJoCo's defaults (Study 2's R1 and R5, Studies 5, 7, 8 and 9's R3)
  rule Q1_released_creeps ge "$(get "rel_def hold 0 0.5 $DC" creep_ums)" 100
  rule Q2_released_direction share "$(get "rel_def slide 0 $DC" slid_um)" "$(get "rel_def slide 45 $DC" slid_um)" 100 115
  rule Q3_released_hold_fails eq "$(get "rel_def suite1" t06_failed)" 1
  for k in 1 2; do for scene in rest drop; do for dt in $DTS; do
    rule "Q4_defect_arm_pose${k}_${scene}_$dt" ge "$(get "rel_def arm pose$k $scene $dt straight" apart_nm)" 1000
  done; done; done
  for sc in swing hold connect weld; do for k in 1 2; do for dt in $DTS; do
    rule "Q4_defect_${sc}_pose${k}_$dt" ge "$(get "rel_def $sc pose$k $dt straight" apart_nm)" 1000
  done; done; done
  # safe when off, and the switch changes nothing else (Studies 5, 7, 8 and 9's R1, R2, R7 and R8)
  # shellcheck disable=SC2046
  rule E1_safe_when_off_defaults eq $(same_files rel_def off_def runs cubes suites tumble)
  # shellcheck disable=SC2046
  rule E1_safe_when_off_configuration eq $(same_files rel_rec off_rec runs cubes suites tumble)
  rule E2_safe_when_off_mujoco_suite eq "$(diff "$O/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>')" 0
  # shellcheck disable=SC2046
  rule N1_switch_changes_nothing_else eq $(same_files rel_rec config cubes suites tumble)
  rule N2_mujoco_suite_on_as_off eq "$(diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep -c '^>')" 0
  # the configuration, under each integrator: every rule below is read for both arms
  for CA in config config_rk4; do
    # the hold, the grip and the slides (Study 2's R2 to R5, Study 1's R4 and R8; the grip, new)
    # shellcheck disable=SC2046
    rule ${CA}_H1_every_hold_holds all_le 10 $(for dt in $DTS; do for dir in $DIRS; do for fr in $FRS; do ab "$(get "$CA hold $dir $fr $dt" creep_ums)"; done; done; done)
    # shellcheck disable=SC2046
    rule ${CA}_G1_grip_holds all_le 10 $(for off in 0 $GOFF; do for pad in box mesh; do ab "$(get "$CA grip $pad $off" creep_ums)"; done; done)
    for dt in $DTS; do
      rule "${CA}_S1_no_direction_$dt" all_within "$(get "$CA slide 0 $dt" slid_um)" 10000 "$(get "$CA slide 22.5 $dt" slid_um)" "$(get "$CA slide 45 $dt" slid_um)"
      # shellcheck disable=SC2046
      rule "${CA}_S2_no_drift_$dt" all_le 10 $(for dir in $DIRS; do ab "$(get "$CA slide $dir $dt" side_um)"; done)
    done
    # shellcheck disable=SC2046
    rule ${CA}_S3_coulomb all_within "$COULOMB" 100 $(for dir in $DIRS; do get "$CA slide $dir $DF" slid_um; done)
    rule ${CA}_S4_free_cube all_within "$(get "$CA free 0" slid_um)" 100 "$(get "$CA free 22.5" slid_um)" "$(get "$CA free 45" slid_um)"
    rule ${CA}_S4_free_cube_drift all_le 1000 "$(ab "$(get "$CA free 22.5" side_um)")" "$(ab "$(get "$CA free 45" side_um)")"
    rule ${CA}_K1_ten_tests eq "$(get "$CA suite1" passed)" 10
    # the arm by written pose (Studies 5, 7, 8 and 9's R4, R5 and R6)
    for k in 1 2; do for scene in rest drop; do for dt in $DTS; do for wr in straight folded; do
      rule "${CA}_A4_place_arm_pose${k}_${scene}_${dt}_$wr" le "$(get "$CA arm pose$k $scene $dt $wr" apart_nm)" 100
      rule "${CA}_A5_speed_arm_pose${k}_${scene}_${dt}_$wr" le "$(get "$CA arm pose$k $scene $dt $wr" speed_apart_ums)" 10
    done; done; done; done
    for sc in swing hold connect weld; do for k in 1 2; do for dt in $DTS; do for wr in straight folded; do
      rule "${CA}_A4_place_${sc}_pose${k}_${dt}_$wr" le "$(get "$CA $sc pose$k $dt $wr" apart_nm)" 100
      rule "${CA}_A5_speed_${sc}_pose${k}_${dt}_$wr" le "$(get "$CA $sc pose$k $dt $wr" speed_apart_ums)" 10
    done; done; done; done
    for k in 1 2; do for dt in $DTS; do
      c=$(get "$CA creep pose$k $dt native" mean_speed_ums)
      for wr in straight folded; do rule "${CA}_A6_creep_pose${k}_${dt}_$wr" near "$(get "$CA creep pose$k $dt $wr" mean_speed_ums)" "$c" 1; done
      c=$(get "$CA holdcreep pose$k $dt native" mean_speed_ums)
      for wr in straight folded; do rule "${CA}_A6_holdcreep_pose${k}_${dt}_$wr" near "$(get "$CA holdcreep pose$k $dt $wr" mean_speed_ums)" "$c" 1; done
    done; done
    # the solver (Studies 5 to 9's R9 over every play; Study 2's R6 over the plays of its kind)
    rule ${CA}_V1_iteration_limit eq "$(get "$CA solver" at_iteration_limit)" 0
    rule ${CA}_V1_warnings eq "$(get "$CA solver" warnings)" 0
    rule ${CA}_V2_most_iterations_cubes le_plus "$(get "$CA solvercubes" most_iterations)" "$(get "rel_def solvercubes" most_iterations)" 3
    # the tumbling body (Study 9's T1 and T2)
    for dt in $LADDER; do
      case $dt in 0.01) eb=5000 ;; 0.0025) eb=1000 ;; *) eb=500 ;; esac
      rule "${CA}_T1_energy_$dt" le "$(get "$CA tumble $dt" energy_largest_ppm)" $eb
      rule "${CA}_T2_momentum_$dt" le "$(get "$CA tumble $dt" momentum_largest_ppm)" 100
    done
  done
  diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep '^>' | sed 's/^> /reported: changed with the switch set: /'
} > "$O/rules.txt"
{
  echo "rules: $(grep -c '^RULE' "$O/rules.txt"), held: $(grep -c ': HELD$' "$O/rules.txt")"
  echo "shared (Q, E, N): $(grep -c '^RULE [QEN][0-9]' "$O/rules.txt"), held: $(grep '^RULE [QEN][0-9]' "$O/rules.txt" | grep -c ': HELD$')"
  for CA in config config_rk4; do echo "$CA: $(grep -c "^RULE ${CA}_[A-Z]" "$O/rules.txt"), held: $(grep "^RULE ${CA}_[A-Z]" "$O/rules.txt" | grep -c ': HELD$')"; done
} >> "$O/rules.txt"
date -u +%FT%TZ > "$O/finished.txt"
