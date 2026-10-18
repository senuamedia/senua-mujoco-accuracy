#!/usr/bin/env bash
# Run 106: the twenty-third registered study (preregistrations/PREREGISTRATION_23.md), played once: two configurations
# of MuJoCo's own options for the three issues noslip leaves (runs 102 to 105), on fresh numbers, against the set's:
#   1. issue 1's last case: a free cube pushed near its friction limit rocks and creeps (Study 20's H1);
#   9. issue 9: a stack sinks at every contact, an offset stack leans and, under noslip, keeps turning;
#  14. issue 14, noslip's costs: inverse dynamics that cannot agree, and the many-contact cost above; and the joint
#      equality without noslip;
# and the set's own plays (Study 22's, with fresh slides), so that nothing the set holds is lost.
# One build from MuJoCo's source at UPSTREAM_COMMIT with Senua AI's six validated patch files, every switch set. Arms:
# set, the configuration as validated (the elliptic cone, 100 noslip iterations); hold, and impratio 1,000 and every
# geom's solref twice the step with damping ratio 1; inverse, the elliptic cone, impratio 1,000, every geom's solref and
# every joint's solreffriction twice the step with damping ratio 1, every joint's solimpfriction 0.9999, no noslip. Every
# arm makes every play; the set's own plays are made again in set with the rigs as Study 22 played them (before/). Every
# number drawn from seed 23 (DRAW=1 prints the draw and plays nothing). Every reading by Senua AI's measure (sx_contact
# as in Study 22), every rule judged by its rule.
# DRY=1 plays throwaway numbers at the edges of the drawn ranges on Study 22's build of the same six patch files, with
# no build, into dry/, and judges the rules on them into dry/rules_plumbing.txt; no rule is read from it.
# usage: play.sh <sx_contact, the measure> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src at UPSTREAM_COMMIT, and for DRY=1
#        Study 22's build in mujoco-s22-build)
set -u
draw() {  # the registered numbers from the seed: Study 10's procedure, from x(0) = 23
  local x=23 V=0 D=""
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
  SEEN_fric=" 0 0.1 0.2 0.3 0.35 0.4 0.45 0.48 0.5 0.55 0.58 0.6 0.62 0.65 0.68 0.7 0.72 0.75 0.8 0.39 0.371 0.421 0.772 0.524 0.717 0.369 0.78 0.379 0.409 0.432 0.732 0.534 0.44 0.42 0.468 0.762 0.778 0.667 0.411 0.413 0.443 0.689 0.686 0.462 0.416 0.436 0.69 0.528 0.438 "
  q() {  # q <kind> <name> <lo> <hi> <places>: one quantity, drawn again while its value is one its kind may not take
    local k="$1" v p seen
    while :; do
      pick "$3" "$4"; v="$(dec "$V" "$5")"; p="$(plain "$v")"
      eval "seen=\"\${SEEN_$k:- }\""
      case "$seen" in *" $p "*) echo "  ($2 drawn again: $v)" ;; *) eval "SEEN_$k=\"\${SEEN_$k:- }$p \""; break ;; esac
    done
    D="$p"; [ "${QUIET:-0}" = 1 ] || echo "$2 $p"
  }
  # and, for this study: Study 20's friction list, the values Study 22 drew, and the settings of runs 099 to 105
  SEEN_step="$SEEN_step 0.000957 0.001243 0.00114 0.000285 0.001277 0.00031925 0.00171 0.0004275 0.001 0.00025 0.016 "
  SEEN_len="$SEEN_len 0.0478 0.046 0.0059 0.0119 0.0788 0.0455 0.0099 0.0233 0.0474 0.0316 0.0424 0.0489 0.0434 0.05 0.001 0.005 0.017 0.0334 0.0092 "
  SEEN_mass="$SEEN_mass 58.496 294.858 465.417 0.431 0.077 1.572 0.819 0.442 1.561 1.861 1 0.21 "
  SEEN_ratio="$SEEN_ratio 1.901 2.29 1.499 0.369 0.893 1.623 2.049 "
  SEEN_force="$SEEN_force 46365 48307 "
  SEEN_torque="$SEEN_torque 7.218 8 "
  SEEN_fric="$SEEN_fric 0.61 0.734 0.524 0.438 0.39 0.69 0.686 0.717 0.778 0.667 0.5 "
  SEEN_speed=" 0.5 1 1.01 1.2 2 "
  # group 1: a step from 0.5 to 2 ms; two cubes, each 0.3 to 2 kg, half-size 25 to 60 mm, friction 0.3 to 0.9
  q step g1_dt 500 2000 6
  for c in a b; do q mass g1${c}_mass 300 2000 3; q len g1${c}_half 250 600 4; q fric g1${c}_mu 300 900 3; done
  # group 9: a step from 0.5 to 1.5 ms; a cube of 0.3 to 2 kg, half-size 30 to 60 mm, friction 0.3 to 0.9; stacks of three
  # offset 0.02 to 0.06, 0.1 to 0.15 and 0.3 to 0.4 of the half-size a cube
  q step g9_dt 500 1500 6
  q mass g9_mass 300 2000 3; q len g9_half 300 600 4; q fric g9_mu 300 900 3
  q ratio g9_off1 20 60 3; q ratio g9_off2 100 150 3; q ratio g9_off3 300 400 3
  # group 14: Study 22's ranges: a step from 0.5 to 2 ms; three held bodies, each 5 to 500 kg, its joint's friction 1.2 to
  # 3 times its weight; two scenes after #2430's second model, a joint friction of 20,000 to 100,000 N pushed by 0.3 to
  # 0.9 of it; two loads, the friction 1.2 to 3 times the falling body's weight; the arm's joint friction, 3 to 8 N m
  q step g14_dt 500 2000 6
  for i in 1 2 3; do q mass g14h${i}_mass 5000 500000 3; q ratio g14h${i}_k 1200 3000 3; done
  for i in 1 2; do q force g14i${i}_f 20000 100000 0; q ratio g14i${i}_phi 300 900 3; done
  for i in 1 2; do q ratio g14l${i}_k 1200 3000 3; done
  q torque g14_jf 3000 8000 3
  # the slides: a step from 0.5 to 2 ms; a cube of 0.3 to 2 kg, half-size 25 to 60 mm, friction 0.3 to 0.9, set sliding at
  # 0.5 to 1.5 m/s
  q step gs_dt 500 2000 6
  q mass gs_mass 300 2000 3; q len gs_half 250 600 4; q fric gs_mu 300 900 3; q speed gs_v 500 1500 3
}
if [ "${DRAW:-0}" = 1 ]; then draw; exit 0; fi
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
P6="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/qcqp_reduced_v2.diff $R/patches/boxbox_collinear.diff $R/patches/noslip_roll_kept_after_qcqp.diff $R/patches/noslip_equality.diff"
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"; S19="$R/validation/run_085_study_19/scenes"
ARMS="set hold inverse"; GRIP="mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61"; GOFF=0.0092
A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"
ARMSETS="s10:len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717:0.00059:0.0121:0.00114 0.000285:0.604,1.158 1.149,-0.545
s13:len1=0.297 len2=0.302 mass1=1.08 mass2=0.578 rb=0.0295 mb=0.194 mu=0.778:0.00052:0.0121:0.00168 0.00042:0.516,0.907 1.211,-0.464
s14:len1=0.298 len2=0.269 mass1=1.164 mass2=0.522 rb=0.0273 mb=0.167 mu=0.667:0.00054:0.0146:0.00119 0.0002975:0.582,1.117 1.227,-0.516 0.58,0.969 1.276,-0.407
s15:$A15:0.00043:0.0129:0.00171 0.0004275:0.555,0.905 1.157,-0.378 0.57,1.123 1.296,-0.403"
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_106_study_23/dry"; Q6B="$W/mujoco-s22-build"; mkdir -p "$O"
  # throwaway numbers at the edges of the drawn ranges
  G1DT=0.002; G1aM=0.3; G1aH=0.025; G1aU=0.9; G1bM=2; G1bH=0.06; G1bU=0.3
  G9DT=0.0015; G9M=2; G9H=0.03; G9U=0.3; G9O1=0.06; G9O2=0.15; G9O3=0.4
  G14DT=0.002; G14HM1=5; G14HK1=1.2; G14HM2=500; G14HK2=3; G14HM3=50; G14HK3=2.5
  G14IF1=100000; G14IP1=0.9; G14IF2=20000; G14IP2=0.3; G14LK1=1.2; G14LK2=3; G14JF=8
  GSDT=0.002; GSM=0.3; GSH=0.06; GSU=0.3; GSV=1.5
else
  O="$R/validation/run_106_study_23"; Q6B="$W/mujoco-s23-build"; mkdir -p "$O"; draw > "$O/draw.txt"
  v() { awk -v k="$1" '$1 == k { print $2 }' "$O/draw.txt"; }
  G1DT=$(v g1_dt); for c in a b; do eval "G1${c}M=$(v g1${c}_mass) G1${c}H=$(v g1${c}_half) G1${c}U=$(v g1${c}_mu)"; done
  G9DT=$(v g9_dt); G9M=$(v g9_mass); G9H=$(v g9_half); G9U=$(v g9_mu); for k in 1 2 3; do eval "G9O$k=$(v g9_off$k)"; done
  G14DT=$(v g14_dt); for i in 1 2 3; do eval "G14HM$i=$(v g14h${i}_mass) G14HK$i=$(v g14h${i}_k)"; done
  for i in 1 2; do eval "G14IF$i=$(v g14i${i}_f) G14IP$i=$(v g14i${i}_phi) G14LK$i=$(v g14l${i}_k)"; done; G14JF=$(v g14_jf)
  GSDT=$(v gs_dt); GSM=$(v gs_mass); GSH=$(v gs_half); GSU=$(v gs_mu); GSV=$(v gs_v)
fi
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
mul() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.6f", a * b }'; }
q4() { awk -v d="$1" 'BEGIN { printf "%.9g", d / 4 }'; }
G1Q=$(q4 "$G1DT"); G9Q=$(q4 "$G9DT"); GSQ=$(q4 "$GSDT")
# ---- group 14's scenes, written once, the same for every arm: Study 22's, on this draw
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
# soft friction's law, for the inverse arm: a load a joint's friction holds makes it creep at (1 - I) dt a, I = 0.9999
# its impedance, dt the step (its time constant twice the step, damping ratio 1), a the load over the body's mass; over
# 1 s, the travel in nm: g for a held body, the push over 1 kg after #2430
{
  for i in 1 2 3; do echo "held_$i $(awk -v d="$G14DT" 'BEGIN { printf "%d", (1 - 0.9999) * d * 9.8 * 1e9 + 0.5 }')"; done
  for i in 1 2; do eval "f=\$G14IF$i p=\$G14IP$i"; echo "i2430_$i $(awk -v d="$G14DT" -v f="$f" -v p="$p" 'BEGIN { printf "%d", (1 - 0.9999) * d * f * p * 1e9 + 0.5 }')"; done
} > "$SC/law.txt"
# Coulomb's distance under MuJoCo's default integrator (semi-implicit Euler): v^2 / (2 mu g) less half a step's travel,
# v dt / 2, in um
for dt in $GSDT $GSQ; do echo "$dt $(awk -v v="$GSV" -v u="$GSU" -v d="$dt" 'BEGIN { printf "%d", (v * v / (2 * u * 9.8) - v * d / 2) * 1e6 + 0.5 }')"; done > "$SC/slide_expected.txt"
{
  echo "group 1: the step $G1DT and $G1Q"
  for c in a b; do eval "m=\$G1${c}M h=\$G1${c}H u=\$G1${c}U"; echo "cube $c: $m kg, half-size $h m, friction $u"; done
  echo "group 9: the step $G9DT and $G9Q; the cube $G9M kg, half-size $G9H m, friction $G9U; offsets $G9O1, $G9O2 and $G9O3 of the half-size"
  echo "group 14: the step $G14DT"
  for i in 1 2 3; do eval "m=\$G14HM$i k=\$G14HK$i"; echo "held body $i: $m kg, its friction $k times its weight"; done
  for i in 1 2; do eval "f=\$G14IF$i p=\$G14IP$i"; echo "after issue 2430, $i: joint friction $f N, pushed by $p of it"; done
  for i in 1 2; do eval "k=\$G14LK$i"; echo "load $i: the friction $k times the weight of the falling body"; done
  echo "the joint friction of the arm $G14JF N m"
  echo "the slides: the step $GSDT and $GSQ; the cube $GSM kg, half-size $GSH m, friction $GSU, set sliding at $GSV m/s"
} > "$O/parameters.txt"
export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1 MUJOCO_NOSLIP_EQUALITY=1
if [ "${DRY:-0}" != 1 ]; then
  rm -rf "${W:?}/mujoco-s23-src" "$W/s23-lib" "$Q6B" && mkdir -p "$W/mujoco-s23-src"
  (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-s23-src"
  for p in $P6; do (cd "$W/mujoco-s23-src" && patch -p1 -s < "$p") || log "patch FAILED $p"; done
  echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in $P6; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" > "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-s23-src" -B "$W/s23-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$Q6B" && cmake --build "$W/s23-lib" -j"$J" && cmake --install "$W/s23-lib" ) > "$O/build_lib.log" 2>&1
  log "build lib exit $?"
  sed -i "s|$HOME|~|g" "$O/build_lib.log"; gzip -n "$O/build_lib.log"
fi
cfg() {  # <arm> <step> <c, a rig without joint friction; j, a rig with it>: the arm's options at that step
  local t; t=$(awk -v d="$2" 'BEGIN { printf "%.9g", 2 * d }')
  case $1 in
    set) echo "cone=elliptic noslip=100" ;;
    hold) echo "cone=elliptic noslip=100 impratio=1000 gsolref=$t,1" ;;
    inverse) if [ "$3" = j ]; then echo "cone=elliptic impratio=1000 gsolref=$t,1 jsolref=$t,1 jsolimp=0.9999"; else echo "cone=elliptic impratio=1000 gsolref=$t,1"; fi ;;
  esac
}
squeeze() { find "$1" -name '*.txt' ! -name stats.txt -size +200k -exec gzip -n {} +; }
step_of() { grep -o 'timestep="[0-9.]*"' "$1" | head -1 | grep -o '[0-9.]*'; }
sets() {  # <arm> <rigs folder>: the set's own plays, in sets/ under the current folder
  local a=$1 T=$2
  mkdir -p sets
  # shellcheck disable=SC2034
  while IFS= read -r line; do
    an=${line%%:*}; rest=${line#*:}; AP=${rest%%:*}; rest=${rest#*:}; RH=${rest%%:*}; rest=${rest#*:}; DH=${rest%%:*}; rest=${rest#*:}
    DT=${rest%%:*}; POSES=${rest#*:}
    for dt in $DT; do
      k=0
      for PSE in $POSES; do
        k=$((k + 1))
        # shellcheck disable=SC2086,SC2046
        "$T/mjc_arm" sets/${an}_rest${k}_$dt.txt dt=$dt pose=$PSE pose0=$PSE $AP h0=$RH secs=2 $(cfg $a $dt j) < /dev/null | sed "s|^STATS|STATS run ${an}_rest${k}_$dt|" >> sets/stats.txt
        # shellcheck disable=SC2086,SC2046
        "$T/mjc_arm" sets/${an}_drop${k}_$dt.txt dt=$dt pose=$PSE pose0=$PSE $AP h0=$DH secs=3 $(cfg $a $dt j) < /dev/null | sed "s|^STATS|STATS run ${an}_drop${k}_$dt|" >> sets/stats.txt
      done
    done
  done <<< "$ARMSETS"
  for dt in 0.00171 0.0004275; do for off in 0 $GOFF; do for pad in box mesh; do
    # shellcheck disable=SC2086,SC2046
    "$T/mjc_grip" sets/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $(cfg $a $dt c) < /dev/null | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> sets/stats.txt
  done; done; done
  for f in "$SCN" "$S19"/*.xml; do
    b=$(basename "$f" .xml); [ "$f" = "$SCN" ] && b=mujoco
    # shellcheck disable=SC2046
    "$T/mjc_scene" sets/box_$b.txt scene="$f" body=box axis=1,0,0 secs=16 key=0 $(cfg $a "$(step_of "$f")" j) < /dev/null | sed "s|^STATS|STATS run box_$b|" >> sets/stats.txt
  done
  LIM=$(awk 'BEGIN { printf "%.6f", 0.438 * 1.561 * 9.8 }')
  for dt in 0.00171 0.0004275; do for fr in 0.5 0.95; do
    pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
    # shellcheck disable=SC2046
    "$T/mjc_contact" sets/hold_${fr}_$dt.txt dt=$dt h0=0 mass=1.561 radius=0.0489 mu=0.438 push=$pu pushat=0.4 secs=1.6 dir=0 lock=1 $(cfg $a $dt c) < /dev/null | sed "s|^STATS|STATS run hold_${fr}_$dt|" >> sets/stats.txt
  done; done
  for dt in $GSDT $GSQ; do for dir in 0 22.5 45; do
    # shellcheck disable=SC2046
    "$T/mjc_contact" sets/slide_${dir}_$dt.txt dt=$dt h0=0 vx0=$GSV mu=$GSU mass=$GSM radius=$GSH secs=1.2 dir=$dir lock=0 $(cfg $a $dt c) < /dev/null | sed "s|^STATS|STATS run slide_${dir}_$dt|" >> sets/stats.txt
  done; done
  squeeze sets
}
arm() {  # <name>: the plays every arm makes, the same in each
  local a=$1 X; X=$(mktemp -d); cp -R "$R/tools" "$X/"
  ( cd "$X" && for n in mjc_stack mjc_contact mjc_arm mjc_grip mjc_scene; do MUJOCO_DIR=$Q6B tools/build_rig.sh $n > /dev/null 2>&1 || echo "rig $n FAILED"; done ) >> "$O/progress.txt"
  ( cd "$X" && T="$X/tools" && mkdir -p g1 g9 g14
    # group 1: the free cubes, condim 3, 4 and 6, pushed along 0 and 45 degrees at 0.5, 0.75 and 0.95 of the limit
    for c in a b; do
      eval "ms=\$G1${c}M hs=\$G1${c}H mu=\$G1${c}U"
      for cd in 3 4 6; do
        if [ $cd = 3 ]; then CD=""; else CD="condim=$cd"; fi
        for dt in $G1DT $G1Q; do for dir in 0 45; do for fr in 0.5 0.75 0.95; do
          pu=$(awk -v f="$fr" -v m="$ms" -v u="$mu" 'BEGIN { printf "%.6f", f * m * u * 9.8 }'); f="free_${c}_c${cd}_${dir}_${fr}_$dt"
          # shellcheck disable=SC2086,SC2046
          "$T/mjc_contact" g1/$f.txt dt=$dt h0=0 mass=$ms radius=$hs mu=$mu push=$pu pushat=0.4 secs=1.6 dir=$dir lock=0 $CD fwdinv=1 $(cfg $a $dt c) < /dev/null | sed "s|^STATS|STATS run $f|" >> g1/stats.txt
        done; done; done
      done
    done
    squeeze g1
    # group 9: stacks of three offset three ways, 6 s; straight stacks of 3, 5 and 10, 2 s
    for dt in $G9DT $G9Q; do
      for k in 1 2 3; do
        eval "of=\$G9O$k"; sh=$(mul "$of" "$G9H")
        # shellcheck disable=SC2046
        "$T/mjc_stack" g9/offset${k}_$dt dt=$dt n=3 shift=$sh secs=6 mass=$G9M radius=$G9H mu=$G9U $(cfg $a $dt c) < /dev/null | sed "s|^STATS|STATS run offset${k}_$dt|" >> g9/stats.txt
      done
      for n in 3 5 10; do
        # shellcheck disable=SC2046
        "$T/mjc_stack" g9/straight${n}_$dt dt=$dt n=$n shift=0 secs=2 mass=$G9M radius=$G9H mu=$G9U $(cfg $a $dt c) < /dev/null | sed "s|^STATS|STATS run straight${n}_$dt|" >> g9/stats.txt
      done
    done
    squeeze g9
    # group 14: the equality scenes, 1 s; Study 22's arm held by joint friction with a weld or a connect at its tip, 2 s
    # at 1.71 ms; Study 15's arm held in the air by joint friction (5.15 N m), at 1.71 and 0.4275 ms
    for sp in held_1:b:0,0,-1:a:1,0,0 held_2:b:0,0,-1:a:1,0,0 held_3:b:0,0,-1:a:1,0,0 i2430_1:b1:1,0,0:b2:1,0,0 i2430_2:b1:1,0,0:b2:1,0,0 load_1:b:1,0,0:a:0,0,-1 load_2:b:1,0,0:a:0,0,-1; do
      IFS=: read -r sn bh ah bc ac <<< "$sp"
      # shellcheck disable=SC2046
      "$T/mjc_scene" g14/${sn}_held.txt scene="$SC/$sn.xml" body=$bh axis=$ah secs=1 fwdinv=1 $(cfg $a "$G14DT" j) < /dev/null | sed "s|^STATS|STATS run ${sn}_held|" >> g14/stats.txt
      # shellcheck disable=SC2046
      "$T/mjc_scene" g14/${sn}_coupled.txt scene="$SC/$sn.xml" body=$bc axis=$ac secs=1 $(cfg $a "$G14DT" j) < /dev/null | sed "s|^STATS|STATS run ${sn}_coupled|" >> g14/stats.txt
    done
    k=0
    for pose in 0.555,0.905 1.157,-0.378; do
      k=$((k + 1))
      for eq in tipweld tipconnect; do
        # shellcheck disable=SC2086,SC2046
        "$T/mjc_arm" g14/arm_${eq}_$k.txt dt=0.00171 pose=$pose pose0=$pose $A15 jointfriction=$G14JF h0=1 secs=2 $eq=1 fwdinv=1 $(cfg $a 0.00171 j) < /dev/null | sed "s|^STATS|STATS run arm_${eq}_$k|" >> g14/stats.txt
      done
      for dt in 0.00171 0.0004275; do
        # shellcheck disable=SC2086,SC2046
        "$T/mjc_arm" g14/jf${k}_$dt.txt dt=$dt pose=$pose pose0=$pose $A15 jointfriction=5.15 h0=1 secs=2 fwdinv=1 $(cfg $a $dt j) < /dev/null | sed "s|^STATS|STATS run jf${k}_$dt|" >> g14/stats.txt
      done
    done
    squeeze g14
    sets "$a" "$T" )
  rm -rf "${O:?}/${a:?}"; mkdir -p "$O/$a"; cp -R "$X/g1" "$X/g9" "$X/g14" "$X/sets" "$O/$a/"; rm -rf "${X:?}"
  log "arm $a played"
}
for a in $ARMS; do arm "$a"; done
# the set's own plays again in set, with the five rigs as Study 22 played them
X=$(mktemp -d); cp -R "$R/tools" "$X/"; for n in mjc_stack mjc_contact mjc_arm mjc_grip mjc_scene; do cp "$R/validation/run_106_study_23/before/$n.c" "$X/tools/$n.c"; done
( cd "$X" && for n in mjc_stack mjc_contact mjc_arm mjc_grip mjc_scene; do MUJOCO_DIR=$Q6B tools/build_rig.sh $n > /dev/null 2>&1 || echo "rig before $n FAILED"; done ) >> "$O/progress.txt"
( cd "$X" && sets set "$X/tools" )
rm -rf "${O:?}/before_set"; mkdir -p "$O/before_set"; cp -R "$X/sets" "$O/before_set/"; rm -rf "${X:?}"
log "before_set played"
# measuring: every reading by the measure, a file read whole, compressed or not
rd() { if [ -f "$1.gz" ]; then gzip -dc "$1.gz" > "$2"; else cp "$1" "$2"; fi; }
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
ab() { echo "${1#-}"; }
m1() { local t r; t=$(mktemp); rd "$1" "$t"; shift; r=$("$B" "$@" "$t" < /dev/null | tail -1); rm -f "$t"; echo "$r"; }
fa() { local t r; t=$(mktemp); rd "$1" "$t"; r=$("$B" fastest "$t" 160 < /dev/null | tail -1); rm -f "$t"; echo "$r"; }
g2() { local t u r; t=$(mktemp); u=$(mktemp); rd "$2" "$t"; rd "$3" "$u"; r=$("$B" gap "$1" "$t" "$u" < /dev/null | tail -1); rm -f "$t" "$u"; echo "$r"; }
# the rig's largest forward-inverse difference in a play's STATS line, in whole nanonewtons
nn() { grep "^STATS run $2 " "$1" | head -1 | awk '{ for (i = 1; i < NF; i++) if ($i == "most_fwdinv_constraint") { printf "%d", $(i + 1) * 1e9 + 0.5; exit } }'; }
DTNS=$(awk -v d="$G14DT" 'BEGIN { printf "%d", d * 1e9 + 0.5 }')
{
  for a in $ARMS; do
    G="$O/$a"
    for c in a b; do for cd in 3 4 6; do for dt in $G1DT $G1Q; do for dir in 0 45; do for fr in 0.5 0.75 0.95; do
      f="free_${c}_c${cd}_${dir}_${fr}_$dt"
      echo "$a g1 $c $cd $dt $dir $fr creep_ums $(ab "$(fld "$(m1 "$G/g1/$f.txt" creep)" mean_speed_ums)") fwdinv_nn $(nn "$G/g1/stats.txt" "$f")"
    done; done; done; done; done
    for dt in $G9DT $G9Q; do
      for k in 1 2 3; do for c in 1 2 3; do
        r=$(m1 "$G/g9/offset${k}_${dt}_${c}_tilt.txt" final)
        echo "$a g9 offset $k $dt $c lean_urad $(ab "$(fld "$r" angle_urad)") turn_urads $(ab "$(fld "$r" speed_urads)")"
      done; done
      for n in 3 5 10; do for c in $(seq 1 $n); do
        echo "$a g9 straight $n $dt $c depth_nm $(ab "$(fld "$(m1 "$G/g9/straight${n}_${dt}_$c.txt" final)" angle_urad)")"
      done; done
    done
    for sn in held_1 held_2 held_3 i2430_1 i2430_2 load_1 load_2; do
      echo "$a g14 ${sn%_*} ${sn#*_} held_nm $(ab "$(fld "$(m1 "$G/g14/${sn}_held.txt" final)" angle_urad)") coupled_nm $(ab "$(fld "$(m1 "$G/g14/${sn}_coupled.txt" final)" angle_urad)") gap_um $(fld "$(g2 "$DTNS" "$G/g14/${sn}_held.txt" "$G/g14/${sn}_coupled.txt")" largest_um) fwdinv_nn $(nn "$G/g14/stats.txt" "${sn}_held")"
    done
    for k in 1 2; do
      for eq in tipweld tipconnect; do
        echo "$a g14 arm $eq $k creep_ums $(ab "$(fld "$(m1 "$G/g14/arm_${eq}_$k.txt" creep)" mean_speed_ums)") fwdinv_nn $(nn "$G/g14/stats.txt" "arm_${eq}_$k")"
      done
      for dt in 0.00171 0.0004275; do
        echo "$a g14 jf $k $dt creep_ums $(ab "$(fld "$(m1 "$G/g14/jf${k}_$dt.txt" creep)" mean_speed_ums)") fwdinv_nn $(nn "$G/g14/stats.txt" "jf${k}_$dt")"
      done
    done
    S="$G/sets"
    for f in $(cd "$S" && ls | sed 's/\.gz$//' | grep -E '^s1[0-9]_(rest|drop)[0-9]_[0-9.]+\.txt$' | sort); do echo "$a arm ${f%.txt} creep_ums $(ab "$(fld "$(m1 "$S/$f" creep)" mean_speed_ums)")"; done
    for dt in 0.00171 0.0004275; do for off in 0 $GOFF; do for pad in box mesh; do
      echo "$a grip $pad $off $dt creep_ums $(ab "$(fld "$(m1 "$S/grip_${pad}_off${off}_$dt.txt" creep)" mean_speed_ums)")"
    done; done; done
    for f in $(cd "$S" && ls | sed 's/\.gz$//' | grep -E '^box_.*\.txt$' | sort); do echo "$a box ${f%.txt} fastest_ums $(fld "$(fa "$S/$f")" fastest_ums)"; done
    for dt in 0.00171 0.0004275; do for fr in 0.5 0.95; do
      echo "$a hold $fr $dt creep_ums $(ab "$(fld "$(m1 "$S/hold_${fr}_$dt.txt" creep)" mean_speed_ums)")"
    done; done
    while read -r dt ex; do for dir in 0 22.5 45; do
      echo "$a slide $dir $dt slid_um $(fld "$(m1 "$S/slide_${dir}_$dt.txt" stop)" slid_um) expected_um $ex"
    done; done < "$SC/slide_expected.txt"
    for part in eq:g14 other:"g1 g9 sets"; do
      pn=${part%%:*}; pf=${part#*:}; most=0; lim=0; wrn=0
      for g in $pf; do
        f="$G/$g/stats.txt"
        mm=$(grep -o 'most_iterations [0-9]*' "$f" | awk '{ if ($2 > m) m = $2 } END { print m + 0 }'); [ "$mm" -gt "$most" ] && most=$mm
        lim=$((lim + $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
        wrn=$((wrn + $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
      done
      echo "$a solver_$pn most_iterations $most at_iteration_limit $lim warnings $wrn"
    done
  done
} > "$O/measured.txt"
same_files() {  # <folder a> <folder b> <exclude pattern> <subfolders...>: how many of a's play files b has byte-identical, of how many
  local a=$1 b=$2 x=$3 n=0 s=0 f; shift 3
  for f in $(cd "$a" && find "$@" -type f ! -name stats.txt | grep -vE "$x" | sort); do n=$((n + 1)); cmp -s "$a/$f" "$b/$f" && s=$((s + 1)); done
  echo "$s $n"
}
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
vals() { grep "^$1 $2 " "$O/measured.txt" | awk -v k="$3" '{ for (i = 1; i < NF; i++) if ($i == k) print $(i + 1) }'; }
# ---- the rules, each judged by sx_contact rule
RF="$O/rules.txt"; [ "${DRY:-0}" = 1 ] && RF="$O/rules_plumbing.txt"
{
  rule() { "$B" rule "$@" < /dev/null | tail -1; }
  # shellcheck disable=SC2046
  rule E1_rigs_as_before eq $(same_files "$O/before_set" "$O/set" '^$' sets)
  # shellcheck disable=SC2046
  rule P0_every_play_measured all_eq 339 $(for a in $ARMS; do grep "^$a " "$O/measured.txt" | grep -v " solver_" | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^(creep_ums|fwdinv_nn|lean_urad|turn_urads|depth_nm|held_nm|coupled_nm|gap_um|fastest_ums|slid_um|expected_um)$/) { if ($(i + 1) ~ /^-?[0-9]+$/) n++ } } END { print n + 0 }'; done)
  # group 1
  # shellcheck disable=SC2046
  rule G1_Q1_the_free_cube_creeps_in_the_set ge "$(grep "^set g1 " "$O/measured.txt" | awk '$6 == 0 && $7 == 0.95' | awk '{ for (i = 1; i < NF; i++) if ($i == "creep_ums") print $(i + 1) }' | sort -n | tail -1)" 10
  # shellcheck disable=SC2046
  rule G1_C1_hold_every_free_cube_holds all_le 10 $(vals hold g1 creep_ums)
  # shellcheck disable=SC2046
  rule G1_C2_inverse_every_free_cube_holds all_le 10 $(vals inverse g1 creep_ums)
  # group 9
  # shellcheck disable=SC2046
  rule G9_Q1_the_set_sinks all_ge 100000 $(grep "^set g9 straight 10 " "$O/measured.txt" | awk '{ for (i = 1; i < NF; i++) if ($i == "depth_nm") print $(i + 1) }')
  # shellcheck disable=SC2046
  rule G9_Q2_the_set_leans all_ge 2000 $(grep "^set g9 offset 3 " "$O/measured.txt" | awk '$6 != 1' | awk '{ for (i = 1; i < NF; i++) if ($i == "lean_urad") print $(i + 1) }')
  for a in hold inverse; do
    # shellcheck disable=SC2046
    rule "G9_D_${a}_every_contact_within_100_um" all_le 100000 $(vals $a "g9 straight" depth_nm)
    # shellcheck disable=SC2046
    rule "G9_L_${a}_every_lean_within_1_mrad" all_le 1000 $(vals $a "g9 offset" lean_urad)
    # shellcheck disable=SC2046
    rule "G9_T_${a}_every_offset_stack_at_rest" all_le 10 $(vals $a "g9 offset" turn_urads)
  done
  # group 14
  # shellcheck disable=SC2046
  rule G14_I1_inverse_dynamics_agrees all_le 1000000 $(vals inverse g1 fwdinv_nn) $(vals inverse g14 fwdinv_nn)
  while read -r sn exp; do
    rule "G14_L1_soft_friction_law_$sn" all_within "$exp" 100 "$(get "inverse g14 ${sn%_*} ${sn#*_}" held_nm)"
  done < "$SC/law.txt"
  # shellcheck disable=SC2046
  rule G14_C1_inverse_coupling_kept all_le 10 $(vals inverse "g14 held" gap_um)
  # shellcheck disable=SC2046
  rule G14_C2_inverse_held_body_held all_le 10000 $(vals inverse "g14 held" held_nm)
  for i in 1 2; do
    rule "G14_C3_inverse_load_as_the_set_$i" all_within "$(get "set g14 load $i" gap_um)" 100 "$(get "inverse g14 load $i" gap_um)"
  done
  # shellcheck disable=SC2046
  rule G14_R1_inverse_held_arms_rest all_le 10 $(vals inverse "g14 arm" creep_ums) $(vals inverse "g14 jf" creep_ums)
  # shellcheck disable=SC2046
  rule G14_N1_hold_nothing_without_a_contact_changes eq $(same_files "$O/set" "$O/hold" '^$' g14)
  rule G14_V1_inverse_iteration_limit eq "$(( $(get "inverse solver_eq" at_iteration_limit) + $(get "inverse solver_other" at_iteration_limit) ))" 0
  rule G14_V1_inverse_warnings eq "$(( $(get "inverse solver_eq" warnings) + $(get "inverse solver_other" warnings) ))" 0
  # the set's own plays
  for a in hold inverse; do
    # shellcheck disable=SC2046
    rule "S_R_${a}_every_arm_rests" all_le 10 $(vals $a arm creep_ums)
    # shellcheck disable=SC2046
    rule "S_G_${a}_every_grip_holds" all_le 10 $(vals $a grip creep_ums)
    # shellcheck disable=SC2046
    rule "S_H_${a}_every_hold_holds" all_le 10 $(vals $a hold creep_ums)
    # shellcheck disable=SC2046
    rule "S_B_${a}_every_box_rests" all_le 10 $(vals $a box fastest_ums)
    while read -r dt ex; do for dir in 0 22.5 45; do
      rule "S_K_${a}_slide_${dir}_$dt" near "$(get "$a slide $dir $dt" slid_um)" "$ex" 10
    done; done < "$SC/slide_expected.txt"
  done
  rule V2_hold_iteration_limit_without_an_equality eq "$(get "hold solver_other" at_iteration_limit)" 0
  rule V2_hold_warnings eq "$(( $(get "hold solver_eq" warnings) + $(get "hold solver_other" warnings) ))" 0
  for a in set hold; do
    echo "reported: $a, the largest forward-inverse difference, nN: $(vals $a g1 fwdinv_nn | sort -n | tail -1) (free cubes), $(vals $a g14 fwdinv_nn | sort -n | tail -1) (group 14)"
  done
  grep "^inverse g14 i2430 \|^set g14 i2430 " "$O/measured.txt" | sed 's/^/reported: /'
  grep "^set g9 offset " "$O/measured.txt" | sed 's/^/reported: /'
  grep "^set slide " "$O/measured.txt" | sed 's/^/reported: /'
  grep " solver_" "$O/measured.txt" | sed 's/^/reported: /'
} > "$RF"
echo "rules: $(grep -c '^RULE' "$RF"), held: $(grep -c ': HELD$' "$RF")" >> "$RF"
find "$O" -name stats.txt -exec sed -i "s|$HOME|~|g" {} +
date -u +%FT%TZ > "$O/finished.txt"
