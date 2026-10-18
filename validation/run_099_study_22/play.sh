#!/usr/bin/env bash
# Run 099: the twenty-second registered study (preregistrations/PREREGISTRATION_22.md), played once, in two groups that
# each decide one issue:
#  14. issue 14, a joint equality noslip breaks (MuJoCo's issue #2430): noslip's pass re-solving the equality rows
#      (patches/in_design/noslip_equality.diff) in Senua AI's set, on fresh scenes: a body held by its joint's friction
#      and a body coupled to it; scenes after #2430's second model; a load on the coupled joint; Study 15's arm held by a
#      weld or a connect with joint friction; and the set's own plays, which have no equality;
#  15. issue 15, a mesh collides as its convex hull: fresh cups, each as one mesh, as five box primitives and as five
#      convex meshes (MuJoCo's documented remedy, a shape as convex parts), a ball dropped in.
# One build from MuJoCo's source at UPSTREAM_COMMIT: Senua AI's five validated patch files and noslip_equality.diff, with
# its tests. Arms: rel, Google DeepMind's Linux release of MuJoCo 3.16.0; off, the build with every switch unset; set5,
# the five switches set; set6, the six. Every arm makes every play. MuJoCo's own test suite on the release's test build
# and on the build's, every switch unset and the six set. Every number drawn from seed 22 (DRAW=1 prints the draw and
# plays nothing). Every reading by Senua AI's measure (sx_contact as of 17 October 2026, with `fastest`), every rule
# judged by its rule.
# DRY=1 plays throwaway numbers at the edges of the drawn ranges on run 095's build of the same six patch files, with no
# build and no MuJoCo suite, into dry/; no rule is read from it.
# usage: play.sh <sx_contact, the measure> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src at UPSTREAM_COMMIT, the release in
#        mujoco-3.16.0, and run 020's release test build in t20-release)
set -u
draw() {  # the registered numbers from the seed: Study 10's procedure, from x(0) = 22
  local x=22 V=0 D=""
  pick() { x=$(( (x * 1103515245 + 12345) % 2147483648 )); V=$(( $1 + x * ($2 - $1 + 1) / 2147483648 )); }
  dec() { local v=$1 p=$2 s="" d=1 i; [ "$v" -lt 0 ] && { s="-"; v=$(( -v )); }
    for ((i = 0; i < p; i++)); do d=$(( d * 10 )); done
    if [ "$p" -eq 0 ]; then echo "$s$v"; else printf "%s%d.%0${p}d\n" "$s" $(( v / d )) $(( v % d )); fi; }
  plain() { echo "$1" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
  # the values a kind may not take: Study 21's lists and the values it drew and derived, the settings of runs 092 to 098,
  # and those this draw has already given to that kind
  SEEN_step=" 0.00003125 0.000125 0.00015625 0.00025 0.0003 0.0003125 0.000375 0.0004 0.0004075 0.0005 0.000625 0.001 0.0012 0.00125 0.0015 0.0016 0.00163 0.002 0.0025 0.004 0.006 0.008 0.01 0.012 0.015 0.02 0.03 0.04 0.00114 0.000285 0.00165 0.0004125 0.0001425 0.00057 0.000855 0.016 0.00116 0.00029 0.00168 0.00042 0.00119 0.0002975 0.00171 0.0004275 0.00122 0.000305 0.0001525 0.00174 0.000435 0.00625 0.0015625 0.000390625 0.00009765625 0.01411 0.001277 0.00031925 0.005 0.001791 0.00044775 0.002411 0.00060275 0.009131 0.0045655 "
  SEEN_len=" 0.0004 0.0005 0.0006 0.007 0.008 0.009 0.01 0.011 0.012 0.014 0.015 0.02 0.025 0.026 0.0271 0.028 0.03 0.032 0.033 0.035 0.038 0.04 0.042 0.043 0.045 0.05 0.08 0.09 0.1 0.2 0.24 0.25 0.26 0.267 0.27 0.273 0.28 0.29 0.3 0.32 0.4 0.5 0.0434 0.0392 0.096 0.0312 0.0093 0.0424 0.017 0.271 0.275 0.0264 0.00059 0.0121 0.0435 0.0336 0.0079 0.0499 0.0431 0.097 0.0305 0.0097 0.0439 0.0485 0.403 0.0454 0.0331 0.071 0.0349 0.0098 0.297 0.302 0.0295 0.00052 0.298 0.269 0.0273 0.00054 0.0146 0.0449 0.0426 0.07 0.0326 0.0077 0.279 0.286 0.0284 0.00043 0.0129 0.041 0.0314 0.083 0.0334 0.0092 0.001 0.0405 0.0489 0.0437 0.0329 0.224 0.462 0.181 0.0509 0.0416 0.0491 0.0474 0.0316 0.0377 0.0355 0.0446 0.0532 0.0563 0.0234 0.0423 0.0302 0.0411 0.0761 0.1109 0.0812 0.06 0.005 0.0025 0.0275 0.0475 0.15 "
  SEEN_mass=" 0.15 0.161 0.17 0.18 0.2 0.22 0.24 0.25 0.35 0.4 0.45 0.5 0.519 0.6 0.9 0.95 1 1.023 1.05 1.1 1.15 1.2 1.3 1.4 1.6 2 3 5 1.861 0.881 0.202 0.442 1.113 0.524 0.176 1.381 0.218 1.903 0.908 0.248 0.408 1.423 1.714 1.438 0.209 1.08 0.578 0.194 1.164 0.522 0.167 1.564 1.7 0.225 1.116 0.436 0.199 1.56 1.704 0.21 0.596 1.561 1.505 0.915 0.587 0.978 1.565 1.342 1.572 0.819 1.881 0.836 1.987 1.051 2.562 0.977 1.495 1.432 2.039 10 100 1000 0.1 "
  SEEN_ratio=" 0.3 0.5 0.75 0.95 2 "
  SEEN_force=" 0.5 2 5 9 20 30000 100000 "
  SEEN_torque=" 5.15 "
  q() {  # q <kind> <name> <lo> <hi> <places>: one quantity, drawn again while its value is one its kind may not take
    local k="$1" v p seen
    while :; do
      pick "$3" "$4"; v="$(dec "$V" "$5")"; p="$(plain "$v")"
      eval "seen=\"\${SEEN_$k:- }\""
      case "$seen" in *" $p "*) echo "  ($2 drawn again: $v)" ;; *) eval "SEEN_$k=\"\${SEEN_$k:- }$p \""; break ;; esac
    done
    D="$p"; [ "${QUIET:-0}" = 1 ] || echo "$2 $p"
  }
  # group 14: a step from 0.5 to 2 ms; three held bodies, each 5 to 500 kg, its joint's friction 1.2 to 3 times its
  # weight; two scenes after #2430's second model, a joint friction of 20,000 to 100,000 N pushed by 0.3 to 0.9 of it;
  # two loads, the friction 1.2 to 3 times the falling body's weight; the arm's joint friction, 3 to 8 N m
  q step g14_dt 500 2000 6
  for i in 1 2 3; do q mass g14h${i}_mass 5000 500000 3; q ratio g14h${i}_k 1200 3000 3; done
  for i in 1 2; do q force g14i${i}_f 20000 100000 0; q ratio g14i${i}_phi 300 900 3; done
  for i in 1 2; do q ratio g14l${i}_k 1200 3000 3; done
  q torque g14_jf 3000 8000 3
  # group 15: a step from 1 to 3 ms; two cups, each 40 to 80 mm in outer half-width, 40 to 100 mm high, walls and floor
  # 3 to 10 mm thick, and a ball of radius 10 to 25 mm and 0.05 to 0.5 kg
  q step g15_dt 1000 3000 6
  for i in 1 2; do q len g15c${i}_w 400 800 4; q len g15c${i}_h 400 1000 4; q len g15c${i}_t 30 100 4; q len g15c${i}_r 100 250 4; q mass g15c${i}_m 50 500 3; done
}
if [ "${DRAW:-0}" = 1 ]; then draw; exit 0; fi
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
P6="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/qcqp_reduced_v2.diff $R/patches/boxbox_collinear.diff $R/patches/noslip_roll_kept_after_qcqp.diff $R/patches/in_design/noslip_equality.diff"
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"; S19="$R/validation/run_085_study_19/scenes"
ARMS="rel off set5 set6"; GRIP="mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61"; GOFF=0.0092; REC="cone=elliptic noslip=100"
A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"
ARMSETS="s10:len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717:0.00059:0.0121:0.00114 0.000285:0.604,1.158 1.149,-0.545
s13:len1=0.297 len2=0.302 mass1=1.08 mass2=0.578 rb=0.0295 mb=0.194 mu=0.778:0.00052:0.0121:0.00168 0.00042:0.516,0.907 1.211,-0.464
s14:len1=0.298 len2=0.269 mass1=1.164 mass2=0.522 rb=0.0273 mb=0.167 mu=0.667:0.00054:0.0146:0.00119 0.0002975:0.582,1.117 1.227,-0.516 0.58,0.969 1.276,-0.407
s15:$A15:0.00043:0.0129:0.00171 0.0004275:0.555,0.905 1.157,-0.378 0.57,1.123 1.296,-0.403"
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_099_study_22/dry"; Q6B="$W/mujoco-p95-build"; mkdir -p "$O"
  # throwaway numbers at the edges of the drawn ranges
  G14DT=0.0005; G14HM1=5; G14HK1=1.2; G14HM2=500; G14HK2=3; G14HM3=50; G14HK3=2.5
  G14IF1=100000; G14IP1=0.9; G14IF2=20000; G14IP2=0.3; G14LK1=1.2; G14LK2=3; G14JF=8
  G15DT=0.003; G15W1=0.04; G15H1=0.1; G15T1=0.003; G15R1=0.025; G15M1=0.5; G15W2=0.08; G15H2=0.04; G15T2=0.01; G15R2=0.01; G15M2=0.05
else
  O="$R/validation/run_099_study_22"; Q6B="$W/mujoco-s22-build"; mkdir -p "$O"; draw > "$O/draw.txt"
  v() { awk -v k="$1" '$1 == k { print $2 }' "$O/draw.txt"; }
  G14DT=$(v g14_dt); for i in 1 2 3; do eval "G14HM$i=$(v g14h${i}_mass) G14HK$i=$(v g14h${i}_k)"; done
  for i in 1 2; do eval "G14IF$i=$(v g14i${i}_f) G14IP$i=$(v g14i${i}_phi) G14LK$i=$(v g14l${i}_k)"; done; G14JF=$(v g14_jf)
  G15DT=$(v g15_dt); for i in 1 2; do eval "G15W$i=$(v g15c${i}_w) G15H$i=$(v g15c${i}_h) G15T$i=$(v g15c${i}_t) G15R$i=$(v g15c${i}_r) G15M$i=$(v g15c${i}_m)"; done
fi
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
mul() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.6f", a * b }'; }
# ---- the scenes, written once, the same for every arm
SC="$O/scenes"; mkdir -p "$SC"
box() { echo "<geom type=\"box\" size=\"0.05 0.05 0.05\" mass=\"$1\" contype=\"0\" conaffinity=\"0\"/>"; }
for i in 1 2 3; do
  eval "m=\$G14HM$i k=\$G14HK$i"; f=$(mul "$(mul "$k" "$m")" 9.8)
  cat > "$SC/held_$i.xml" <<EOF
<mujoco model="held $i"><option timestep="$G14DT" integrator="implicit" gravity="0 0 -9.8"/>
<worldbody>
<body name="b" pos="0 0 1"><joint name="B" type="slide" axis="0 0 -1" frictionloss="$f"/>$(box "$m")</body>
<body name="a" pos="0.5 0 1"><joint name="A" type="slide" axis="1 0 0"/>$(box 1)</body>
</worldbody>
<equality><joint joint1="A" joint2="B" polycoef="0 1 0 0 0"/></equality>
</mujoco>
EOF
done
for i in 1 2; do
  eval "f=\$G14IF$i p=\$G14IP$i"; pu=$(mul "$f" "$p")
  cat > "$SC/i2430_$i.xml" <<EOF
<mujoco model="after issue 2430's second model, $i"><option timestep="$G14DT" integrator="implicit"/>
<worldbody>
<body name="b1" pos="0 0 0"><joint name="j1" type="slide" axis="1 0 0" frictionloss="$f"/>$(box 1)</body>
<body name="b2" pos="0 0.5 0"><joint name="j2" type="slide" axis="1 0 0"/>$(box 1)</body>
</worldbody>
<equality><joint joint1="j1" joint2="j2" polycoef="0 1 0 0 0"/></equality>
<actuator><general joint="j1" gainprm="0" biastype="affine" biasprm="-$pu 0 0"/></actuator>
</mujoco>
EOF
  eval "k=\$G14LK$i"; fl=$(mul "$k" 9.8)
  cat > "$SC/load_$i.xml" <<EOF
<mujoco model="load $i"><option timestep="$G14DT" integrator="implicit" gravity="0 0 -9.8"/>
<worldbody>
<body name="a" pos="0 0 1"><joint name="A" type="slide" axis="0 0 -1"/>$(box 1)</body>
<body name="b" pos="0.5 0 1"><joint name="B" type="slide" axis="1 0 0" frictionloss="$fl"/>$(box 1)</body>
</worldbody>
<equality><joint joint1="B" joint2="A" polycoef="0 1 0 0 0"/></equality>
</mujoco>
EOF
done
mk() {  # <name> <half x> <half y> <half z>: a box mesh about its centre
  local x=$2 y=$3 z=$4
  echo "<mesh name=\"$1\" vertex=\"-$x -$y -$z  $x -$y -$z  $x $y -$z  -$x $y -$z  -$x -$y $z  $x -$y $z  $x $y $z  -$x $y $z\"/>"
}
: > "$SC/cup_expected.txt"
for i in 1 2; do
  eval "w=\$G15W$i h=\$G15H$i t=\$G15T$i r=\$G15R$i m=\$G15M$i"
  iw=$(awk -v w="$w" -v t="$t" 'BEGIN { printf "%.6f", w - t }'); ht=$(awk -v t="$t" 'BEGIN { printf "%.6f", t / 2 }')
  wh=$(awk -v h="$h" -v t="$t" 'BEGIN { printf "%.6f", (h - t) / 2 }'); wz=$(awk -v h="$h" -v t="$t" 'BEGIN { printf "%.6f", t + (h - t) / 2 }')
  wp=$(awk -v w="$w" -v t="$t" 'BEGIN { printf "%.6f", w - t / 2 }'); z0=$(awk -v h="$h" -v r="$r" 'BEGIN { printf "%.6f", h + r + 0.01 }')
  head="<mujoco model=\"cup $i\"><option timestep=\"$G15DT\" gravity=\"0 0 -9.8\"/>"
  ground='<geom name="ground" type="plane" size="1 1 0.1"/>'
  ball="<body name=\"ball\" pos=\"0 0 $z0\"><freejoint/><geom type=\"sphere\" size=\"$r\" mass=\"$m\"/></body>"
  cat > "$SC/cup_${i}_one.xml" <<EOF
$head<asset><mesh name="cup" vertex="-$w -$w 0  $w -$w 0  $w $w 0  -$w $w 0  -$w -$w $h  $w -$w $h  $w $w $h  -$w $w $h  -$iw -$iw $t  $iw -$iw $t  $iw $iw $t  -$iw $iw $t  -$iw -$iw $h  $iw -$iw $h  $iw $iw $h  -$iw $iw $h"/></asset>
<worldbody>$ground<geom name="cup" type="mesh" mesh="cup"/>$ball</worldbody></mujoco>
EOF
  parts="<geom type=\"box\" pos=\"0 0 $ht\" size=\"$w $w $ht\"/><geom type=\"box\" pos=\"-$wp 0 $wz\" size=\"$ht $w $wh\"/><geom type=\"box\" pos=\"$wp 0 $wz\" size=\"$ht $w $wh\"/><geom type=\"box\" pos=\"0 -$wp $wz\" size=\"$iw $ht $wh\"/><geom type=\"box\" pos=\"0 $wp $wz\" size=\"$iw $ht $wh\"/>"
  cat > "$SC/cup_${i}_prim.xml" <<EOF
$head<worldbody>$ground$parts$ball</worldbody></mujoco>
EOF
  cat > "$SC/cup_${i}_mparts.xml" <<EOF
$head<asset>$(mk floor "$w" "$w" "$ht")$(mk wallx "$ht" "$w" "$wh")$(mk wally "$iw" "$ht" "$wh")</asset>
<worldbody>$ground<geom type="mesh" mesh="floor" pos="0 0 $ht"/><geom type="mesh" mesh="wallx" pos="-$wp 0 $wz"/><geom type="mesh" mesh="wallx" pos="$wp 0 $wz"/><geom type="mesh" mesh="wally" pos="0 -$wp $wz"/><geom type="mesh" mesh="wally" pos="0 $wp $wz"/>$ball</worldbody></mujoco>
EOF
  echo "$i $z0 $(awk -v h="$h" -v t="$t" 'BEGIN { printf "%d", (h - t + 0.01) * 1e9 + 0.5 }')" >> "$SC/cup_expected.txt"
done
{
  echo "group 14: the step $G14DT"
  for i in 1 2 3; do eval "m=\$G14HM$i k=\$G14HK$i"; echo "held body $i: $m kg, its friction $k times its weight"; done
  for i in 1 2; do eval "f=\$G14IF$i p=\$G14IP$i"; echo "after issue 2430, $i: joint friction $f N, pushed by $p of it"; done
  for i in 1 2; do eval "k=\$G14LK$i"; echo "load $i: the friction $k times the weight of the falling body"; done
  echo "the joint friction of the arm $G14JF N m"
  echo "group 15: the step $G15DT"
  for i in 1 2; do eval "w=\$G15W$i h=\$G15H$i t=\$G15T$i r=\$G15R$i m=\$G15M$i"; echo "cup $i: outer half-width $w m, $h m high, walls and floor $t m, a ball of radius $r m and $m kg"; done
} > "$O/parameters.txt"
switches() {  # <0, 5 or 6>
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT MUJOCO_NOSLIP_EQUALITY
  if [ "$1" -ge 5 ]; then export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1; fi
  if [ "$1" -ge 6 ]; then export MUJOCO_NOSLIP_EQUALITY=1; fi
}
switches 0
if [ "${DRY:-0}" != 1 ]; then
  rm -rf "${W:?}/mujoco-s22-src" "$W/s22-lib" "$Q6B" "$W/t99-s22" && mkdir -p "$W/mujoco-s22-src"
  (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-s22-src"
  for p in $P6; do (cd "$W/mujoco-s22-src" && patch -p1 -s < "$p") || log "patch FAILED $p"; done
  echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in $P6; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" > "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-s22-src" -B "$W/s22-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$Q6B" && cmake --build "$W/s22-lib" -j"$J" && cmake --install "$W/s22-lib" ) > "$O/build_lib.log" 2>&1
  log "build lib exit $?"
  ( cmake -S "$W/mujoco-s22-src" -B "$W/t99-s22" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t99-s22" -j"$J" ) > "$O/build_tests.log" 2>&1
  log "build tests exit $?"
fi
squeeze() { find "$1" -name '*.txt' ! -name stats.txt -size +200k -exec gzip -n {} +; }
arm() {  # <name> <MuJoCo folder> <0, 5 or 6>: the plays every arm makes, the same in each
  local name=$1 mj=$2 sw=$3 X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_scene mjc_contact mjc_grip mjc_arm mjc_stack; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
    switches "$sw"
    mkdir -p g14 sets g15; : > g14/stats.txt; : > sets/stats.txt; : > g15/stats.txt
    # group 14: the equality scenes, 1 s, with no noslip, noslip 5 and noslip 100 (the configuration)
    for ns in none:"cone=elliptic" n5:"cone=elliptic noslip=5" n100:"cone=elliptic noslip=100"; do
      nn=${ns%%:*}; no=${ns#*:}
      for sp in held_1:b:0,0,-1:a:1,0,0 held_2:b:0,0,-1:a:1,0,0 held_3:b:0,0,-1:a:1,0,0 i2430_1:b1:1,0,0:b2:1,0,0 i2430_2:b1:1,0,0:b2:1,0,0 load_1:b:1,0,0:a:0,0,-1 load_2:b:1,0,0:a:0,0,-1; do
        IFS=: read -r sn bh ah bc ac <<< "$sp"
        # shellcheck disable=SC2086
        tools/mjc_scene g14/${sn}_${nn}_held.txt scene="$SC/$sn.xml" body=$bh axis=$ah secs=1 $no < /dev/null | sed "s|^STATS|STATS run ${sn}_${nn}_held|" >> g14/stats.txt
        # shellcheck disable=SC2086
        tools/mjc_scene g14/${sn}_${nn}_coupled.txt scene="$SC/$sn.xml" body=$bc axis=$ac secs=1 $no < /dev/null | sed "s|^STATS|STATS run ${sn}_${nn}_coupled|" >> g14/stats.txt
      done
    done
    k=0
    for pose in 0.555,0.905 1.157,-0.378; do
      k=$((k + 1))
      for eq in tipweld tipconnect; do
        # shellcheck disable=SC2086
        tools/mjc_arm g14/arm_${eq}_$k.txt dt=0.00171 pose=$pose pose0=$pose $A15 jointfriction=$G14JF h0=1 secs=2 $eq=1 $REC | sed "s|^STATS|STATS run arm_${eq}_$k|" >> g14/stats.txt
      done
    done
    squeeze g14
    # the set's own plays, which have no equality: Study 21's arms, grips and boxes, the cube Study 19 held, run 093's
    # offset stacks
    while IFS= read -r line; do
      an=${line%%:*}; rest=${line#*:}; AP=${rest%%:*}; rest=${rest#*:}; RH=${rest%%:*}; rest=${rest#*:}; DH=${rest%%:*}; rest=${rest#*:}
      DT=${rest%%:*}; POSES=${rest#*:}
      for dt in $DT; do
        k=0
        for PSE in $POSES; do
          k=$((k + 1))
          # shellcheck disable=SC2086
          tools/mjc_arm sets/${an}_rest${k}_$dt.txt dt=$dt pose=$PSE pose0=$PSE $AP h0=$RH secs=2 $REC < /dev/null | sed "s|^STATS|STATS run ${an}_rest${k}_$dt|" >> sets/stats.txt
          # shellcheck disable=SC2086
          tools/mjc_arm sets/${an}_drop${k}_$dt.txt dt=$dt pose=$PSE pose0=$PSE $AP h0=$DH secs=3 $REC < /dev/null | sed "s|^STATS|STATS run ${an}_drop${k}_$dt|" >> sets/stats.txt
        done
      done
    done <<< "$ARMSETS"
    for dt in 0.00171 0.0004275; do for off in 0 $GOFF; do for pad in box mesh; do
      # shellcheck disable=SC2086
      tools/mjc_grip sets/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $REC | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> sets/stats.txt
    done; done; done
    for ns in written:"" n100:noslip=100; do
      nn=${ns%%:*}; opt=${ns#*:}
      # shellcheck disable=SC2086
      tools/mjc_scene sets/box_mujoco_$nn.txt scene="$SCN" body=box axis=1,0,0 secs=16 key=0 $opt | sed "s|^STATS|STATS run box_mujoco_$nn|" >> sets/stats.txt
      for f in "$S19"/*.xml; do
        b=$(basename "$f" .xml)
        # shellcheck disable=SC2086
        tools/mjc_scene sets/box_${b}_$nn.txt scene="$f" body=box axis=1,0,0 secs=16 key=0 $opt | sed "s|^STATS|STATS run box_${b}_$nn|" >> sets/stats.txt
      done
    done
    LIM=$(awk 'BEGIN { printf "%.6f", 0.438 * 1.561 * 9.8 }')
    for dt in 0.00171 0.0004275; do for fr in 0.5 0.95; do
      pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
      # shellcheck disable=SC2086
      tools/mjc_contact sets/hold_${fr}_$dt.txt dt=$dt h0=0 mass=1.561 radius=0.0489 mu=0.438 push=$pu pushat=0.4 secs=1.6 dir=0 lock=1 $REC | sed "s|^STATS|STATS run hold_${fr}_$dt|" >> sets/stats.txt
    done; done
    for sh in 0.001 0.017; do
      # shellcheck disable=SC2086
      tools/mjc_stack sets/stack_$sh dt=0.00114 n=3 shift=$sh secs=2 mass=0.442 radius=0.0424 mu=0.524 $REC | sed "s|^STATS|STATS run stack_$sh|" >> sets/stats.txt
    done
    squeeze sets
    # group 15: each cup three ways, under MuJoCo's defaults and under the configuration, 2 s
    for i in 1 2; do for way in one prim mparts; do for c in defaults:"" config:"cone=elliptic noslip=100"; do
      cn=${c%%:*}; co=${c#*:}
      # shellcheck disable=SC2086
      tools/mjc_scene g15/cup_${i}_${way}_$cn.txt scene="$SC/cup_${i}_$way.xml" body=ball axis=0,0,-1 secs=2 $co | sed "s|^STATS|STATS run cup_${i}_${way}_$cn|" >> g15/stats.txt
    done; done; done
    squeeze g15 )
  rm -rf "${O:?}/${name:?}"; mkdir -p "$O/$name"; cp -R "$X/g14" "$X/sets" "$X/g15" "$O/$name/"; rm -rf "${X:?}"
  log "arm $name played"
}
for a in $ARMS; do
  case $a in
    rel) arm rel "$W/mujoco-3.16.0" 0 ;;
    off) arm off "$Q6B" 0 ;;
    set5) arm set5 "$Q6B" 5 ;;
    set6) arm set6 "$Q6B" 6 ;;
  esac
done
switches 0
if [ "${DRY:-0}" != 1 ]; then
  suite() {  # <build folder> <label> <0 or 6>: every test, the two memory-heavy texture tests alone
    ( cd "$1" && switches "$3"
      ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$2.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_$2_large.txt" 2>&1 )
    log "suite $2 $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_$2_large.txt" | tail -1)"
  }
  suite "$W/t20-release" release 0
  suite "$W/t99-s22" off 0
  suite "$W/t99-s22" set6 6
  for a in release off set6; do
    cat "$O/ctest_$a.txt" "$O/ctest_${a}_large.txt" | awk 'match($0, /Test +#[0-9]+: /) {
           hdr = substr($0, RSTART, RLENGTH); num = hdr; gsub(/[^0-9]/, "", num); rest = substr($0, RSTART + RLENGTH)
           st = "unknown"
           if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) {
             st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st) }
           name = rest; p = index(name, "  # GetParam()"); if (p > 0) name = substr(name, 1, p - 1)
           p = index(name, " ..."); if (p > 0) name = substr(name, 1, p - 1); sub(/ +$/, "", name)
           print num, name, st }' | sort -n > "$O/suite_results_$a.txt"
  done
  for f in "$O"/ctest_*.txt "$O"/build_*.log; do sed -i "s|$HOME|~|g" "$f"; gzip -n "$f"; done
fi
# measuring: every reading by the measure, a file read whole, compressed or not
rd() { if [ -f "$1.gz" ]; then gzip -dc "$1.gz" > "$2"; else cp "$1" "$2"; fi; }
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
ab() { echo "${1#-}"; }
m1() { local t r; t=$(mktemp); rd "$1" "$t"; shift; r=$("$B" "$@" "$t" | tail -1); rm -f "$t"; echo "$r"; }
fa() { local t r; t=$(mktemp); rd "$1" "$t"; r=$("$B" fastest "$t" 160 | tail -1); rm -f "$t"; echo "$r"; }
g2() { local t u r; t=$(mktemp); u=$(mktemp); rd "$2" "$t"; rd "$3" "$u"; r=$("$B" gap "$1" "$t" "$u" | tail -1); rm -f "$t" "$u"; echo "$r"; }
DTNS=$(awk -v d="$G14DT" 'BEGIN { printf "%d", d * 1e9 + 0.5 }')
{
  for a in $ARMS; do
    G="$O/$a/g14"
    for nn in none n5 n100; do
      for sn in held_1 held_2 held_3 i2430_1 i2430_2; do
        echo "$a g14 ${sn%_*} ${sn#*_} $nn held_nm $(ab "$(fld "$(m1 "$G/${sn}_${nn}_held.txt" final)" angle_urad)") coupled_nm $(ab "$(fld "$(m1 "$G/${sn}_${nn}_coupled.txt" final)" angle_urad)") gap_um $(fld "$(g2 "$DTNS" "$G/${sn}_${nn}_held.txt" "$G/${sn}_${nn}_coupled.txt")" largest_um)"
      done
      for i in 1 2; do
        echo "$a g14 load $i $nn held_nm $(ab "$(fld "$(m1 "$G/load_${i}_${nn}_held.txt" final)" angle_urad)") gap_um $(fld "$(g2 "$DTNS" "$G/load_${i}_${nn}_held.txt" "$G/load_${i}_${nn}_coupled.txt")" largest_um)"
      done
    done
    for k in 1 2; do for eq in tipweld tipconnect; do
      echo "$a g14 arm $eq $k creep_ums $(ab "$(fld "$(m1 "$G/arm_${eq}_$k.txt" creep)" mean_speed_ums)")"
    done; done
    S="$O/$a/sets"
    for f in $(cd "$S" && ls | sed 's/\.gz$//' | grep -E '^s1[0-9]_(rest|drop)[0-9]_[0-9.]+\.txt$' | sort); do echo "$a arm ${f%.txt} creep_ums $(ab "$(fld "$(m1 "$S/$f" creep)" mean_speed_ums)")"; done
    for dt in 0.00171 0.0004275; do for off in 0 $GOFF; do for pad in box mesh; do
      echo "$a grip $pad $off $dt creep_ums $(ab "$(fld "$(m1 "$S/grip_${pad}_off${off}_$dt.txt" creep)" mean_speed_ums)")"
    done; done; done
    for f in $(cd "$S" && ls | sed 's/\.gz$//' | grep -E '^box_.*\.txt$' | sort); do echo "$a box ${f%.txt} fastest_ums $(fld "$(fa "$S/$f")" fastest_ums)"; done
    for dt in 0.00171 0.0004275; do for fr in 0.5 0.95; do
      echo "$a hold $fr $dt creep_ums $(ab "$(fld "$(m1 "$S/hold_${fr}_$dt.txt" creep)" mean_speed_ums)")"
    done; done
    for i in 1 2; do for way in one prim mparts; do for cn in defaults config; do
      f="$O/$a/g15/cup_${i}_${way}_$cn.txt"
      echo "$a g15 cup $i $way $cn down_nm $(fld "$(m1 "$f" final)" angle_urad) fastest_ums $(fld "$(fa "$f")" fastest_ums)"
    done; done; done
    for part in eq:g14 other:"sets g15"; do
      pn=${part%%:*}; pf=${part#*:}; most=0; lim=0; wrn=0
      for g in $pf; do
        f="$O/$a/$g/stats.txt"
        mm=$(grep -o 'most_iterations [0-9]*' "$f" | awk '{ if ($2 > m) m = $2 } END { print m + 0 }'); [ "$mm" -gt "$most" ] && most=$mm
        lim=$((lim + $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
        wrn=$((wrn + $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
      done
      echo "$a solver_$pn most_iterations $most at_iteration_limit $lim warnings $wrn"
    done
  done
} > "$O/measured.txt"
if [ "${DRY:-0}" = 1 ]; then echo "dry run: $(wc -l < "$O/measured.txt") measured lines"; date -u +%FT%TZ > "$O/finished.txt"; exit 0; fi
same_files() {  # <arm a> <arm b> <exclude pattern> <folders...>: how many of a's play files b has byte-identical, of how many
  local a=$1 b=$2 x=$3 n=0 s=0 f; shift 3
  for f in $(cd "$O/$a" && find "$@" -type f ! -name stats.txt | grep -vE "$x" | sort); do n=$((n + 1)); cmp -s "$O/$a/$f" "$O/$b/$f" && s=$((s + 1)); done
  echo "$s $n"
}
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
vals() { grep "^$1 $2 " "$O/measured.txt" | awk -v k="$3" '{ for (i = 1; i < NF; i++) if ($i == k) print $(i + 1) }'; }
NAMED="SolverTest.ZeroToleranceDisablesTermination ForwardTest.DiscreteImplicitRowNoslip"
diff "$O/suite_results_off.txt" "$O/suite_results_set6.txt" | grep '^>' | awk '{ print $3 }' > "$O/suite_changed_set6.txt"
# ---- the rules, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" < /dev/null | tail -1; }
  # every arm: safe when off, every suite read, MuJoCo's suite, every play measured
  # shellcheck disable=SC2046
  rule E1_safe_when_off eq $(same_files rel off '^$' g14 sets g15)
  # shellcheck disable=SC2046
  rule M0_every_suite_read all_eq 3492 $(for a in release off set6; do if [ -f "$O/suite_results_$a.txt" ]; then wc -l < "$O/suite_results_$a.txt" | tr -d ' '; else echo 0; fi; done)
  rule E2_safe_when_off_mujoco_suite eq "$(diff "$O/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>')" 0
  rule M1_mujoco_suite_named_only eq "$(grep -cvxF -e "${NAMED% *}" -e "${NAMED#* }" "$O/suite_changed_set6.txt")" 0
  # shellcheck disable=SC2046
  rule P0_every_play_measured all_eq 159 $(for a in $ARMS; do grep "^$a " "$O/measured.txt" | grep -v " solver_" | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^(held_nm|coupled_nm|gap_um|creep_ums|fastest_ums|down_nm)$/) { if ($(i + 1) ~ /^-?[0-9]+$/) n++ } } END { print n + 0 }'; done)
  # group 14: the equality
  # shellcheck disable=SC2046
  rule G14_Q1_released_coupling_breaks all_ge 100 $(for k in "held 1" "held 2" "held 3" "i2430 1" "i2430 2"; do get "rel g14 $k n100" gap_um; done)
  # shellcheck disable=SC2046
  rule G14_C1_coupling_kept all_le 10 $(for k in "held 1" "held 2" "held 3" "i2430 1" "i2430 2"; do get "set6 g14 $k n100" gap_um; done)
  # shellcheck disable=SC2046
  rule G14_C2_held_body_holds all_le 10000 $(for k in "held 1" "held 2" "held 3" "i2430 1" "i2430 2"; do get "set6 g14 $k n100" held_nm; done)
  for i in 1 2; do
    rule "G14_C3_load_as_without_noslip_$i" all_within "$(get "set6 g14 load $i none" gap_um)" 100 "$(get "set6 g14 load $i n100" gap_um)"
  done
  # shellcheck disable=SC2046
  rule G14_R1_held_arm_rests all_le 10 $(vals set6 "g14 arm" creep_ums)
  # shellcheck disable=SC2046
  rule G14_N1_nothing_else_changes eq $(same_files set5 set6 '^$' sets g15)
  # shellcheck disable=SC2046
  rule G14_R2_every_arm_holds all_le 10 $(vals set6 arm creep_ums)
  # shellcheck disable=SC2046
  rule G14_G2_every_grip_holds all_le 10 $(vals set6 grip creep_ums)
  # shellcheck disable=SC2046
  rule G14_B2_every_box_rests all_le 10 $(vals set6 box fastest_ums)
  # shellcheck disable=SC2046
  rule G14_H2_every_hold_holds all_le 10 $(vals set6 hold creep_ums)
  rule G14_V1_iteration_limit eq "$(get "set6 solver_other" at_iteration_limit)" 0
  rule G14_V1_warnings eq "$(( $(get "set6 solver_eq" warnings) + $(get "set6 solver_other" warnings) ))" 0
  # group 15: the cups; resting inside, the ball's centre comes down by the cup's inner depth and 10 mm; on the hull's
  # top, by 10 mm
  while read -r i z0 exp; do
    for cn in defaults config; do
      rule "G15_Q1_one_mesh_on_the_hull_${i}_$cn" near "$(get "rel g15 cup $i one $cn" down_nm)" 10000000 1000000
      rule "G15_C0_primitives_on_the_floor_${i}_$cn" near "$(get "rel g15 cup $i prim $cn" down_nm)" "$exp" 1000000
      rule "G15_C2_set_primitives_on_the_floor_${i}_$cn" near "$(get "set6 g15 cup $i prim $cn" down_nm)" "$exp" 1000000
      for a in rel set6; do
        rule "G15_C1_convex_meshes_as_primitives_${a}_${i}_$cn" near "$(get "$a g15 cup $i mparts $cn" down_nm)" "$(get "$a g15 cup $i prim $cn" down_nm)" 1000
      done
    done
  done < "$O/scenes/cup_expected.txt"
  # shellcheck disable=SC2046
  rule G15_S1_every_cup_at_rest all_le 10 $(vals rel "g15 cup" fastest_ums) $(vals set6 "g15 cup" fastest_ums)
  sed 's/^/reported: changed with the six switches set: /' "$O/suite_changed_set6.txt"
  grep "^set6 solver_eq \|^rel solver_eq " "$O/measured.txt" | sed 's/^/reported: /'
} > "$O/rules.txt"
{
  echo "rules: $(grep -c '^RULE' "$O/rules.txt"), held: $(grep -c ': HELD$' "$O/rules.txt")"
} >> "$O/rules.txt"
date -u +%FT%TZ > "$O/finished.txt"
