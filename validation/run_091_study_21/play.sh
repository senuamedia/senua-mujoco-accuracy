#!/usr/bin/env bash
# Run 091: the twenty-first registered study (preregistrations/PREREGISTRATION_21.md), played once, in four groups that
# each decide one issue:
#   1. issue 1, a cube held from turning: the friction solve's second version (patches/in_design/qcqp_reduced_v2.diff)
#      in Senua AI's set, Study 20's protocol on fresh cubes, the free cubes played and reported;
#   7. issue 7: fresh slides, started at the depth they rest at, at four steps, in Senua AI's validated set under the
#      configuration: no hop, Coulomb's deceleration and distance;
#   8. issue 8: fresh time constants, MuJoCo's defaults: within half the time constant the depth at rest the same at
#      every step; at the time constant, deeper;
#  10. issue 10: fresh time constants and damping ratios, MuJoCo's default integrator: with the step at most half the
#      time constant times the damping ratio, the bounce the same at every step to within 500 parts of 10,000 and never
#      above the drop.
# Two builds from MuJoCo's source at UPSTREAM_COMMIT: v1, Senua AI's five validated patch files; v2, the same five with
# qcqp_reduced_v2.diff in place of qcqp_reduced.diff, with its tests. Arms: rel, Google DeepMind's Linux release of
# MuJoCo 3.16.0; off, v2 with every switch unset; v1set and v2set, each with the five switches set. Every arm makes every
# play. MuJoCo's own test suite on the release's test build and on v2's, every switch unset and the five set. Every
# number drawn from seed 21 (DRAW=1 prints the draw and plays nothing). Every reading by Senua AI's corrected measure
# (sx_contact, 17 October 2026), every rule judged by its rule.
# DRY=1 plays throwaway numbers on run 087's two builds of the same patch files, with no build and no MuJoCo suite,
# into dry/; no rule is read from it.
# usage: play.sh <sx_contact, the corrected measure> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src at UPSTREAM_COMMIT, the release in
#        mujoco-3.16.0, and run 020's release test build in t20-release)
set -u
draw() {  # the registered numbers from the seed: Study 10's procedure, from x(0) = 21
  local x=21 V=0 D=""
  pick() { x=$(( (x * 1103515245 + 12345) % 2147483648 )); V=$(( $1 + x * ($2 - $1 + 1) / 2147483648 )); }
  dec() { local v=$1 p=$2 s="" d=1 i; [ "$v" -lt 0 ] && { s="-"; v=$(( -v )); }
    for ((i = 0; i < p; i++)); do d=$(( d * 10 )); done
    if [ "$p" -eq 0 ]; then echo "$s$v"; else printf "%s%d.%0${p}d\n" "$s" $(( v / d )) $(( v % d )); fi; }
  plain() { echo "$1" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
  # the values a kind may not take: Study 20's lists and the values it drew and derived, the settings of runs 088 to 090,
  # and those this draw has already given to that kind
  SEEN_step=" 0.00003125 0.000125 0.00015625 0.00025 0.0003 0.0003125 0.000375 0.0004 0.0004075 0.0005 0.000625 0.001 0.0012 0.00125 0.0015 0.0016 0.00163 0.002 0.0025 0.004 0.006 0.008 0.01 0.012 0.015 0.02 0.03 0.04 0.00114 0.000285 0.00165 0.0004125 0.0001425 0.00057 0.000855 0.016 0.00116 0.00029 0.00168 0.00042 0.00119 0.0002975 0.00171 0.0004275 0.00122 0.000305 0.0001525 0.00174 0.000435 0.00625 0.0015625 0.000390625 0.00009765625 0.01411 0.001277 0.00031925 0.005 "
  SEEN_len=" 0.0004 0.0005 0.0006 0.007 0.008 0.009 0.01 0.011 0.012 0.014 0.015 0.02 0.025 0.026 0.0271 0.028 0.03 0.032 0.033 0.035 0.038 0.04 0.042 0.043 0.045 0.05 0.08 0.09 0.1 0.2 0.24 0.25 0.26 0.267 0.27 0.273 0.28 0.29 0.3 0.32 0.4 0.5 0.0434 0.0392 0.096 0.0312 0.0093 0.0424 0.017 0.271 0.275 0.0264 0.00059 0.0121 0.0435 0.0336 0.0079 0.0499 0.0431 0.097 0.0305 0.0097 0.0439 0.0485 0.403 0.0454 0.0331 0.071 0.0349 0.0098 0.297 0.302 0.0295 0.00052 0.298 0.269 0.0273 0.00054 0.0146 0.0449 0.0426 0.07 0.0326 0.0077 0.279 0.286 0.0284 0.00043 0.0129 0.041 0.0314 0.083 0.0334 0.0092 0.001 0.0405 0.0489 0.0437 0.0329 0.224 0.462 0.181 0.0509 0.0416 0.0491 0.0474 0.0316 "
  SEEN_mass=" 0.15 0.161 0.17 0.18 0.2 0.22 0.24 0.25 0.35 0.4 0.45 0.5 0.519 0.6 0.9 0.95 1 1.023 1.05 1.1 1.15 1.2 1.3 1.4 1.6 2 3 5 1.861 0.881 0.202 0.442 1.113 0.524 0.176 1.381 0.218 1.903 0.908 0.248 0.408 1.423 1.714 1.438 0.209 1.08 0.578 0.194 1.164 0.522 0.167 1.564 1.7 0.225 1.116 0.436 0.199 1.56 1.704 0.21 0.596 1.561 1.505 0.915 0.587 0.978 1.565 1.342 1.572 0.819 "
  SEEN_fric=" 0 0.1 0.2 0.3 0.35 0.4 0.45 0.48 0.5 0.55 0.58 0.6 0.62 0.65 0.68 0.7 0.72 0.75 0.8 0.39 0.371 0.421 0.772 0.524 0.717 0.369 0.78 0.379 0.409 0.432 0.732 0.534 0.44 0.42 0.468 0.762 0.778 0.667 0.411 0.413 0.443 0.689 0.686 0.462 0.416 0.436 0.69 0.528 0.438 0.61 0.734 1 2 "
  SEEN_speed=" 0.3 0.6 0.8 0.85 0.9 0.95 1 1.1 1.2 1.5 2 2.4 3 4 5 1.01 3.24 1.47 3.67 1.16 0.81 3.19 0.98 4.35 0.86 2.97 0.96 3.5 1.15 3.36 1.45 4.53 0.94 3.51 1.28 3.62 1.09 0.91 1.21 2.05 2.58 "
  SEEN_tc=" 0.005 0.01 0.02 0.04 0.08 "
  SEEN_dr=" 0.1 0.2 0.5 1 "
  q() {  # q <kind> <name> <lo> <hi> <places>: one quantity, drawn again while its value is one its kind may not take
    local k="$1" v p seen
    while :; do
      pick "$3" "$4"; v="$(dec "$V" "$5")"; p="$(plain "$v")"
      eval "seen=\"\${SEEN_$k:- }\""
      case "$seen" in *" $p "*) echo "  ($2 drawn again: $v)" ;; *) eval "SEEN_$k=\"\${SEEN_$k:- }$p \""; break ;; esac
    done
    D="$p"; [ "${QUIET:-0}" = 1 ] || echo "$2 $p"
  }
  # group 1: Study 20's ranges
  q step g1_dt 1000 2000 6
  q mass g1a_mass 1000 2500 3; q len g1a_half 300 500 4; q fric g1a_mu 300 800 3
  q mass g1b_mass 300 1000 3; q len g1b_half 300 500 4; q fric g1b_mu 300 800 3
  # group 7: a step from 1 to 3 ms (and a quarter, a sixteenth and a sixty-fourth of it), two slides, each lasting at
  # least 0.25 s (1 to 2 m/s, friction 0.2 to 0.4), so the step's own error in the distance is under 0.6%
  q step g7_dt 1000 3000 6
  for c in 1 2; do q mass g7c${c}_mass 500 2000 3; q len g7c${c}_half 300 600 4; q fric g7c${c}_mu 200 400 3; q speed g7c${c}_v 100 200 2; done
  # group 8: two settings, each a time constant from 6 to 30 ms and a cube
  for s in 1 2; do q tc g8s${s}_tc 6000 30000 6; q mass g8s${s}_mass 500 3000 3; q len g8s${s}_half 200 800 4; done
  # group 10: a coarse step from 8 to 12 ms (and its halves down to a sixty-fourth), three settings, each a time
  # constant, a damping ratio, a cube and a drop height; the first with a spring the coarse step cannot resolve, and
  # each with at least three steps that resolve it (the time constant times the damping ratio at least 1.5 ms)
  q step g10_dt 8000 12000 6
  q tc g10p1_tc 10000 20000 6; q dr g10p1_dr 150 200 3
  q tc g10p2_tc 20000 40000 6; q dr g10p2_dr 200 400 3
  q tc g10p3_tc 8000 50000 6; q dr g10p3_dr 400 600 3
  for p in 1 2 3; do q mass g10p${p}_mass 1000 3000 3; q len g10p${p}_half 300 500 4; q len g10p${p}_h0 500 1200 4; done
}
if [ "${DRAW:-0}" = 1 ]; then draw; exit 0; fi
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
P1="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/qcqp_reduced.diff $R/patches/boxbox_collinear.diff $R/patches/noslip_roll_kept_after_qcqp.diff"
P2="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/in_design/qcqp_reduced_v2.diff $R/patches/boxbox_collinear.diff $R/patches/noslip_roll_kept_after_qcqp.diff"
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"; S19="$R/validation/run_085_study_19/scenes"
ARMS="rel off v1set v2set"; CUBES="a b"; CDS="3 4 6"; LKS="1 0"; FRS="0.5 0.75 0.95"; DIRS="0 22.5 45"
GRIP="mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61"; GOFF=0.0092; REC="cone=elliptic noslip=100"
ARMSETS="s10:len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717:0.00059:0.0121:0.00114 0.000285:0.604,1.158 1.149,-0.545
s13:len1=0.297 len2=0.302 mass1=1.08 mass2=0.578 rb=0.0295 mb=0.194 mu=0.778:0.00052:0.0121:0.00168 0.00042:0.516,0.907 1.211,-0.464
s14:len1=0.298 len2=0.269 mass1=1.164 mass2=0.522 rb=0.0273 mb=0.167 mu=0.667:0.00054:0.0146:0.00119 0.0002975:0.582,1.117 1.227,-0.516 0.58,0.969 1.276,-0.407
s15:len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686:0.00043:0.0129:0.00171 0.0004275:0.555,0.905 1.157,-0.378 0.57,1.123 1.296,-0.403"
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_091_study_21/dry"; Q1B="$W/mujoco-s20v1-build"; Q2B="$W/mujoco-s20v2-build"; mkdir -p "$O"
  # throwaway numbers: run 087's cube twice, run 088's slide, time constants and drops
  G1DT=0.00114; for c in $CUBES; do eval "MS$c=1.861 H$c=0.0434 MU$c=0.39"; done
  G7DT=0.002; for c in 1 2; do eval "G7M$c=1 G7H$c=0.05 G7MU$c=0.4 G7V$c=1"; done
  for s in 1 2; do eval "G8TC$s=0.01 G8M$s=1 G8H$s=0.05"; done
  G10DT=0.01; G10TC1=0.02; G10DR1=0.2; G10TC2=0.04; G10DR2=0.2; G10TC3=0.02; G10DR3=0.5
  for p in 1 2 3; do eval "G10M$p=2 G10H$p=0.04 G10Z$p=0.08"; done
else
  O="$R/validation/run_091_study_21"; Q1B="$W/mujoco-s21v1-build"; Q2B="$W/mujoco-s21v2-build"; mkdir -p "$O"; draw > "$O/draw.txt"
  v() { awk -v k="$1" '$1 == k { print $2 }' "$O/draw.txt"; }
  G1DT=$(v g1_dt); for c in $CUBES; do eval "MS$c=$(v g1${c}_mass) H$c=$(v g1${c}_half) MU$c=$(v g1${c}_mu)"; done
  G7DT=$(v g7_dt); for c in 1 2; do eval "G7M$c=$(v g7c${c}_mass) G7H$c=$(v g7c${c}_half) G7MU$c=$(v g7c${c}_mu) G7V$c=$(v g7c${c}_v)"; done
  for s in 1 2; do eval "G8TC$s=$(v g8s${s}_tc) G8M$s=$(v g8s${s}_mass) G8H$s=$(v g8s${s}_half)"; done
  G10DT=$(v g10_dt); for p in 1 2 3; do eval "G10TC$p=$(v g10p${p}_tc) G10DR$p=$(v g10p${p}_dr) G10M$p=$(v g10p${p}_mass) G10H$p=$(v g10p${p}_half) G10Z$p=$(v g10p${p}_h0)"; done
fi
frac() { awk -v a="$1" -v k="$2" 'BEGIN { printf "%.10g", a / k }'; }
G1DTF=$(frac "$G1DT" 4)
G7DTS="$G7DT $(frac "$G7DT" 4) $(frac "$G7DT" 16) $(frac "$G7DT" 64)"
G10KS="1 2 4 8 16 32 64"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
{
  echo "group 1: the holds' steps $G1DT and $G1DTF"
  for c in $CUBES; do eval "echo cube $c: \$MS$c kg, half-size \$H$c m, friction \$MU$c"; done
  echo "group 7: the steps $G7DTS"
  for c in 1 2; do eval "echo slide $c: \$G7M$c kg, half-size \$G7H$c m, friction \$G7MU$c, given \$G7V$c m/s"; done
  for s in 1 2; do eval "echo group 8, setting $s: time constant \$G8TC$s s, \$G8M$s kg, half-size \$G8H$s m"; done
  echo "group 10: the coarse step $G10DT"
  for p in 1 2 3; do eval "echo group 10, setting $p: time constant \$G10TC$p s, damping ratio \$G10DR$p, \$G10M$p kg, half-size \$G10H$p m, dropped from \$G10Z$p m"; done
} > "$O/parameters.txt"
switches() {  # <0 or 5>
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT
  if [ "$1" -ge 5 ]; then export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1; fi
}
build() {  # <name> <patch files> <install folder> <with tests: 0 or 1>
  local n=$1 ps=$2 ib=$3 t=$4 p
  rm -rf "${W:?}/mujoco-s21$n-src" "$W/s21$n-lib" "$ib" "$W/t91-s21$n" && mkdir -p "$W/mujoco-s21$n-src"
  (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-s21$n-src"
  for p in $ps; do (cd "$W/mujoco-s21$n-src" && patch -p1 -s < "$p"); done
  echo "$n: source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in $ps; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" >> "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-s21$n-src" -B "$W/s21$n-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$ib" && cmake --build "$W/s21$n-lib" -j"$J" && cmake --install "$W/s21$n-lib" ) > "$O/build_${n}_lib.log" 2>&1
  log "build $n lib exit $?"
  if [ "$t" = 1 ]; then
    ( cmake -S "$W/mujoco-s21$n-src" -B "$W/t91-s21$n" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
        -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t91-s21$n" -j"$J" ) > "$O/build_${n}_tests.log" 2>&1
    log "build $n tests exit $?"
  fi
}
if [ "${DRY:-0}" != 1 ]; then : > "$O/patch_check.txt"; build v1 "$P1" "$Q1B" 0; build v2 "$P2" "$Q2B" 1; fi
squeeze() { find "$1" -name '*.txt' ! -name stats.txt -size +200k -exec gzip -n {} +; }
arm() {  # <name> <MuJoCo folder> <0 or 5>: the plays every arm makes, the same in each
  local name=$1 mj=$2 sw=$3 X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_scene mjc_contact mjc_grip mjc_arm; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
    switches "$sw"
    mkdir -p holds arms boxes slides rests drops
    : > holds/stats.txt; : > arms/stats.txt; : > boxes/stats.txt; : > slides/stats.txt; : > rests/stats.txt; : > drops/stats.txt
    # group 1: the holds, as Study 20
    for c in $CUBES; do
      eval "ms=\$MS$c hh=\$H$c mu=\$MU$c"; LIM=$(awk -v m="$ms" -v u="$mu" 'BEGIN { printf "%.6f", m * u * 9.8 }')
      for dt in $G1DT $G1DTF; do for cd in $CDS; do
        if [ $cd = 3 ]; then CD=""; else CD="condim=$cd"; fi
        for lk in $LKS; do for dir in $DIRS; do for fr in $FRS; do
          pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
          # shellcheck disable=SC2086
          tools/mjc_contact holds/hold_${c}_c${cd}_lock${lk}_${dir}_${fr}_$dt.txt dt=$dt h0=0 mass=$ms radius=$hh mu=$mu push=$pu pushat=0.4 secs=1.6 dir=$dir lock=$lk $REC $CD | sed "s|^STATS|STATS run hold_${c}_c${cd}_lock${lk}_${dir}_${fr}_$dt|" >> holds/stats.txt
        done; done; done
      done; done
    done
    squeeze holds
    while IFS= read -r line; do
      an=${line%%:*}; rest=${line#*:}; AP=${rest%%:*}; rest=${rest#*:}; RH=${rest%%:*}; rest=${rest#*:}; DH=${rest%%:*}; rest=${rest#*:}
      DT=${rest%%:*}; POSES=${rest#*:}
      for dt in $DT; do
        k=0
        for PSE in $POSES; do
          k=$((k + 1))
          # shellcheck disable=SC2086
          tools/mjc_arm arms/${an}_rest${k}_$dt.txt dt=$dt pose=$PSE pose0=$PSE $AP h0=$RH secs=2 $REC | sed "s|^STATS|STATS run ${an}_rest${k}_$dt|" >> arms/stats.txt
          # shellcheck disable=SC2086
          tools/mjc_arm arms/${an}_drop${k}_$dt.txt dt=$dt pose=$PSE pose0=$PSE $AP h0=$DH secs=3 $REC | sed "s|^STATS|STATS run ${an}_drop${k}_$dt|" >> arms/stats.txt
        done
      done
    done <<< "$ARMSETS"
    for dt in 0.00171 0.0004275; do for off in 0 $GOFF; do for pad in box mesh; do
      # shellcheck disable=SC2086
      tools/mjc_grip arms/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $REC | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> arms/stats.txt
    done; done; done
    squeeze arms
    for ns in written:"" n100:noslip=100; do
      nn=${ns%%:*}; opt=${ns#*:}
      # shellcheck disable=SC2086
      tools/mjc_scene boxes/mujoco_$nn.txt scene="$SCN" body=box axis=1,0,0 secs=16 key=0 $opt | sed "s|^STATS|STATS run mujoco_$nn|" >> boxes/stats.txt
      for f in "$S19"/*.xml; do
        b=$(basename "$f" .xml)
        # shellcheck disable=SC2086
        tools/mjc_scene boxes/${b}_$nn.txt scene="$f" body=box axis=1,0,0 secs=16 key=0 $opt | sed "s|^STATS|STATS run ${b}_$nn|" >> boxes/stats.txt
      done
    done
    squeeze boxes
    # group 7: each slide rests first at its step, then is given its speed from the depth it rested at, under the
    # configuration, for its stopping time and a half and 0.2 s
    for c in 1 2; do
      eval "m=\$G7M$c hh=\$G7H$c mu=\$G7MU$c vv=\$G7V$c"
      secs=$(awk -v v="$vv" -v u="$mu" 'BEGIN { printf "%.3f", 1.5 * v / (u * 9.8) + 0.2 }')
      for dt in $G7DTS; do
        # shellcheck disable=SC2086
        tools/mjc_contact slides/rest_${c}_$dt.txt dt=$dt h0=0 mass=$m radius=$hh mu=$mu secs=1 $REC | sed "s|^STATS|STATS run rest_${c}_$dt|" >> slides/stats.txt
        hn=$("$B" final slides/rest_${c}_$dt.txt | tail -1 | awk '{ for (i = 1; i < NF; i++) if ($i == "angle_urad") print $(i + 1) }')
        h=$(awk -v d="$hn" 'BEGIN { printf "%.9f", d / 1e9 }')
        # shellcheck disable=SC2086
        tools/mjc_contact slides/slide_${c}_$dt.txt dt=$dt h0=$h vx0=$vv mass=$m radius=$hh mu=$mu secs=$secs $REC | sed "s|^STATS|STATS run slide_${c}_$dt|" >> slides/stats.txt
      done
    done
    squeeze slides
    # group 8: set down from 20 mm with friction 0.5, MuJoCo's defaults, the contact's time constant given, 2 s
    for s in 1 2; do
      eval "tc=\$G8TC$s m=\$G8M$s hh=\$G8H$s"
      for k in 16 4 3 2 1; do
        dt=$(frac "$tc" $k)
        tools/mjc_contact rests/rest_${s}_k$k.txt dt=$dt h0=0.02 mu=0.5 mass=$m radius=$hh secs=2 solref=$tc,1 | sed "s|^STATS|STATS run rest_${s}_k$k|" >> rests/stats.txt
      done
    done
    squeeze rests
    # group 10: dropped, MuJoCo's defaults, the contact's time constant and damping ratio given, 1.2 s
    for p in 1 2 3; do
      eval "tc=\$G10TC$p dr=\$G10DR$p m=\$G10M$p hh=\$G10H$p z=\$G10Z$p"
      for k in $G10KS; do
        dt=$(frac "$G10DT" $k)
        tools/mjc_contact drops/drop_${p}_k$k.txt dt=$dt mass=$m radius=$hh h0=$z secs=1.2 solref=$tc,$dr | sed "s|^STATS|STATS run drop_${p}_k$k|" >> drops/stats.txt
      done
    done
    squeeze drops )
  rm -rf "${O:?}/${name:?}"; mkdir -p "$O/$name"; cp -R "$X/holds" "$X/arms" "$X/boxes" "$X/slides" "$X/rests" "$X/drops" "$O/$name/"; rm -rf "${X:?}"
  log "arm $name played"
}
for a in $ARMS; do
  case $a in
    rel) arm rel "$W/mujoco-3.16.0" 0 ;;
    off) arm off "$Q2B" 0 ;;
    v1set) arm v1set "$Q1B" 5 ;;
    v2set) arm v2set "$Q2B" 5 ;;
  esac
done
switches 0
if [ "${DRY:-0}" != 1 ]; then
  suite() {  # <build folder> <label> <0 or 5>: every test, the two memory-heavy texture tests alone
    ( cd "$1" && switches "$3"
      ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$2.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_$2_large.txt" 2>&1 )
    log "suite $2 $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_$2_large.txt" | tail -1)"
  }
  suite "$W/t20-release" release 0
  suite "$W/t91-s21v2" off 0
  suite "$W/t91-s21v2" set5 5
  for a in release off set5; do
    cat "$O/ctest_$a.txt" "$O/ctest_${a}_large.txt" | awk 'match($0, /Test +#[0-9]+: /) {
           hdr = substr($0, RSTART, RLENGTH); num = hdr; gsub(/[^0-9]/, "", num); rest = substr($0, RSTART + RLENGTH)
           st = "unknown"
           if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) {
             st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st) }
           name = rest; p = index(name, "  # GetParam()"); if (p > 0) name = substr(name, 1, p - 1)
           p = index(name, " ..."); if (p > 0) name = substr(name, 1, p - 1); sub(/ +$/, "", name)
           print num, name, st }' | sort -n > "$O/suite_results_$a.txt"
  done
  for f in "$O"/ctest_*.txt "$O"/build_*.log; do gzip -n "$f"; done
fi
# measuring: every reading by the measure, a file read whole, compressed or not
rd() { if [ -f "$1.gz" ]; then gzip -dc "$1.gz" > "$2"; else cp "$1" "$2"; fi; }
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
ab() { echo "${1#-}"; }
m1() { local t r; t=$(mktemp); rd "$1" "$t"; shift; r=$("$B" "$@" "$t" | tail -1); rm -f "$t"; echo "$r"; }
mw() { local t r f=$1 a=$2 b=$3; t=$(mktemp); rd "$f" "$t"; r=$("$B" accel "$t" "$a" "$b" | tail -1); rm -f "$t"; echo "$r"; }
last160() { local t; t=$(mktemp); rd "$1" "$t"; awk 'NR > 1 { s[NR] = $0; m = NR } END { if (m < 161) { printf "fast_steps missing fastest_ums missing"; exit } c = 0; x0 = 0; for (i = m - 159; i <= m; i++) { split(s[i], f, " "); x = f[3] < 0 ? -f[3] : f[3]; if (x > 1000) c++; if (x > x0) x0 = x } printf "fast_steps %d fastest_ums %d", c, x0 }' "$t"; rm -f "$t"; }
{
  for a in $ARMS; do
    for c in $CUBES; do for dt in $G1DT $G1DTF; do for cd in $CDS; do for lk in $LKS; do for dir in $DIRS; do
      echo "$a hold $c $dt $cd $lk $dir creep_ums $(for fr in $FRS; do ab "$(fld "$(m1 "$O/$a/holds/hold_${c}_c${cd}_lock${lk}_${dir}_${fr}_$dt.txt" creep)" mean_speed_ums)"; done | tr '\n' ' ')"
    done; done; done; done; done
    for f in $(cd "$O/$a/arms" && ls | sed 's/\.gz$//' | grep -E '^s1[0-9]_(rest|drop)[0-9]_[0-9.]+\.txt$' | sort); do echo "$a arm ${f%.txt} creep_ums $(ab "$(fld "$(m1 "$O/$a/arms/$f" creep)" mean_speed_ums)")"; done
    for dt in 0.00171 0.0004275; do for off in 0 $GOFF; do for pad in box mesh; do
      echo "$a grip $pad $off $dt creep_ums $(ab "$(fld "$(m1 "$O/$a/arms/grip_${pad}_off${off}_$dt.txt" creep)" mean_speed_ums)")"
    done; done; done
    for f in $(cd "$O/$a/boxes" && ls | sed 's/\.gz$//' | grep -v '^stats\.txt$' | sort); do echo "$a box ${f%.txt} $(last160 "$O/$a/boxes/$f")"; done
    for c in 1 2; do
      eval "vv=\$G7V$c mu=\$G7MU$c"
      w=$(awk -v v="$vv" -v u="$mu" 'BEGIN { t = 1000 * v / (u * 9.8); printf "%d %d", int(0.2 * t), int(0.8 * t) }')
      for dt in $G7DTS; do
        f="$O/$a/slides/slide_${c}_$dt.txt"
        echo "$a slide $c $dt decel_mm_s2 $(ab "$(fld "$(mw "$f" $w)" mean_acceleration_mm_s2)") slid_um $(fld "$(m1 "$f" stop)" slid_um) highest_um $(fld "$(m1 "$f" hover)" highest_um) window_ms $w"
      done
    done
    for s in 1 2; do for k in 16 4 3 2 1; do
      echo "$a rest $s $k depth_nm $(ab "$(fld "$(m1 "$O/$a/rests/rest_${s}_k$k.txt" final)" angle_urad)")"
    done; done
    for p in 1 2 3; do for k in $G10KS; do
      echo "$a drop $p $k rebound_per_10000 $(fld "$(m1 "$O/$a/drops/drop_${p}_k$k.txt" bounce)" rebound_per_10000)"
    done; done
    most=0; lim=0; wrn=0
    for g in holds arms boxes slides rests drops; do
      f="$O/$a/$g/stats.txt"
      mm=$(grep -o 'most_iterations [0-9]*' "$f" | awk '{ if ($2 > m) m = $2 } END { print m + 0 }'); [ "$mm" -gt "$most" ] && most=$mm
      lim=$((lim + $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
      wrn=$((wrn + $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
    done
    echo "$a solver most_iterations $most at_iteration_limit $lim warnings $wrn"
  done
} > "$O/measured.txt"
if [ "${DRY:-0}" = 1 ]; then echo "dry run: $(wc -l < "$O/measured.txt") measured lines"; date -u +%FT%TZ > "$O/finished.txt"; exit 0; fi
same_files() {  # <arm a> <arm b> <exclude pattern> <folders...>: how many of a's play files b has byte-identical, of how many
  local a=$1 b=$2 x=$3 n=0 s=0 f; shift 3
  for f in $(cd "$O/$a" && find "$@" -type f ! -name stats.txt | grep -vE "$x" | sort); do n=$((n + 1)); cmp -s "$O/$a/$f" "$O/$b/$f" && s=$((s + 1)); done
  echo "$s $n"
}
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
holds() {  # <arm> <lock>: every creep reading of the arm's holds with that lock
  grep "^$1 hold " "$O/measured.txt" | awk -v lk="$2" '$6 == lk { for (i = 9; i <= NF; i++) print $i }'
}
vals() {  # <arm> <kind>: every arm, grip or box reading of the arm
  case $2 in
    arm) grep "^$1 arm " "$O/measured.txt" | awk '{ print $5 }' ;;
    grip) grep "^$1 grip " "$O/measured.txt" | awk '{ print $7 }' ;;
    box) grep "^$1 box " "$O/measured.txt" | awk '{ print $7 }' ;;
  esac
}
NAMED="SolverTest.ZeroToleranceDisablesTermination ForwardTest.DiscreteImplicitRowNoslip"
diff "$O/suite_results_off.txt" "$O/suite_results_set5.txt" | grep '^>' | awk '{ print $3 }' > "$O/suite_changed_set5.txt"
# ---- the rules, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" | tail -1; }
  # every arm: safe when off, every suite read, MuJoCo's suite, every play measured
  # shellcheck disable=SC2046
  rule E1_safe_when_off eq $(same_files rel off '^$' holds arms boxes slides rests drops)
  # shellcheck disable=SC2046
  rule M0_every_suite_read all_eq 3492 $(for a in release off set5; do if [ -f "$O/suite_results_$a.txt" ]; then wc -l < "$O/suite_results_$a.txt" | tr -d ' '; else echo 0; fi; done)
  rule E2_safe_when_off_mujoco_suite eq "$(diff "$O/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>')" 0
  rule M1_mujoco_suite_named_only eq "$(grep -cvxF -e "${NAMED% *}" -e "${NAMED#* }" "$O/suite_changed_set5.txt")" 0
  # shellcheck disable=SC2046
  rule P0_every_play_measured all_eq 341 $(for a in $ARMS; do grep "^$a " "$O/measured.txt" | grep -v " solver " | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^(creep_ums|fastest_ums|decel_mm_s2|slid_um|highest_um|depth_nm|rebound_per_10000)$/) { j = i + 1; while (j <= NF && $j ~ /^-?[0-9]+$/) { n++; j++ } } } END { print n + 0 }'; done)
  # group 1: a cube held from turning
  rule G1_Q1_released_cube_creeps ge "$(grep '^rel hold a ' "$O/measured.txt" | awk -v d="$G1DT" '$4 == d && $5 == 4 && $6 == 1 && $7 == 0 { print $11 }')" 11
  rule G1_Q2_version1_cube_creeps ge "$(grep '^v1set hold a ' "$O/measured.txt" | awk -v d="$G1DT" '$4 == d && $5 == 4 && $6 == 1 && $7 == 0 { print $11 }')" 11
  # shellcheck disable=SC2046
  rule G1_H1_every_held_cube_holds all_le 10 $(holds v2set 1)
  # shellcheck disable=SC2046
  rule G1_N1_nothing_else_changes eq $(same_files v1set v2set '_c[46]_lock1_' holds arms boxes slides rests drops)
  # shellcheck disable=SC2046
  rule G1_R1_every_arm_holds all_le 10 $(vals v2set arm)
  # shellcheck disable=SC2046
  rule G1_G1_every_grip_holds all_le 10 $(vals v2set grip)
  # shellcheck disable=SC2046
  rule G1_B1_every_box_rests all_le 10 $(vals v2set box)
  rule G1_V1_iteration_limit eq "$(grep '^v2set solver' "$O/measured.txt" | awk '{ print $6 }')" 0
  rule G1_V1_warnings eq "$(grep '^v2set solver' "$O/measured.txt" | awk '{ print $8 }')" 0
  # group 7: the slide
  G7S1=${G7DTS%% *}
  rule G7_Q1_released_slide_hops ge "$(get "rel slide 1 $G7S1" highest_um)" 1
  # shellcheck disable=SC2046
  rule G7_S1_no_hop all_le 0 $(for c in 1 2; do for dt in $G7DTS; do get "v1set slide $c $dt" highest_um; done; done)
  for c in 1 2; do
    eval "vv=\$G7V$c mu=\$G7MU$c"
    ug=$(awk -v u="$mu" 'BEGIN { printf "%d", u * 9800 + 0.5 }'); dist=$(awk -v v="$vv" -v u="$mu" 'BEGIN { printf "%d", 1e6 * v * v / (2 * u * 9.8) + 0.5 }')
    # shellcheck disable=SC2046
    rule "G7_S2_coulomb_deceleration_$c" all_within "$ug" 100 $(for dt in $G7DTS; do get "v1set slide $c $dt" decel_mm_s2; done)
    # shellcheck disable=SC2046
    rule "G7_S3_coulomb_distance_$c" all_within "$dist" 100 $(for dt in $G7DTS; do get "v1set slide $c $dt" slid_um; done)
  done
  rule G7_V1_iteration_limit eq "$(grep '^v1set solver' "$O/measured.txt" | awk '{ print $6 }')" 0
  # group 8: the depth at rest, released
  for s in 1 2; do
    rule "G8_Q1_past_the_guard_deeper_$s" share "$(get "rel rest $s 16" depth_nm)" "$(get "rel rest $s 1" depth_nm)" 100 101
    rule "G8_R1_within_the_guard_the_same_$s" all_within "$(get "rel rest $s 16" depth_nm)" 10000 "$(get "rel rest $s 4" depth_nm)" "$(get "rel rest $s 3" depth_nm)" "$(get "rel rest $s 2" depth_nm)"
  done
  # group 10: the bounce, released; a step resolves the spring when the time constant times the damping ratio is at
  # least twice the step
  rule G10_Q1_released_creates_energy ge "$(get "rel drop 1 1" rebound_per_10000)" 10001
  allres=""
  for p in 1 2 3; do
    eval "tc=\$G10TC$p dr=\$G10DR$p"
    res=""; for k in $G10KS; do dt=$(frac "$G10DT" $k); if awk -v t="$tc" -v d="$dr" -v s="$dt" 'BEGIN { exit !(t * d >= 2 * s) }'; then res="$res $k"; fi; done
    rule "G10_P1_resolved_steps_$p" ge "$(echo $res | wc -w | tr -d ' ')" 3
    for i in $res; do for j in $res; do if [ "$i" -lt "$j" ]; then
      rule "G10_R1_same_bounce_${p}_k${i}_k$j" near "$(get "rel drop $p $i" rebound_per_10000)" "$(get "rel drop $p $j" rebound_per_10000)" 500
    fi; done; done
    for k in $res; do allres="$allres $(get "rel drop $p $k" rebound_per_10000)"; done
  done
  # shellcheck disable=SC2086
  rule G10_R2_never_above_the_drop all_le 10000 $allres
  sed 's/^/reported: changed with the five switches set: /' "$O/suite_changed_set5.txt"
} > "$O/rules.txt"
{
  echo "rules: $(grep -c '^RULE' "$O/rules.txt"), held: $(grep -c ': HELD$' "$O/rules.txt")"
} >> "$O/rules.txt"
date -u +%FT%TZ > "$O/finished.txt"
