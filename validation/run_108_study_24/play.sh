#!/usr/bin/env bash
# Run 108: the twenty-fourth registered study (preregistrations/PREREGISTRATION_24.md), played once: issue 18, MuJoCo
# across architectures, on plays no probe has made. On an arm64 machine (AWS EC2 c7g.xlarge, Graviton3) and on the first
# cloud machine (Intel), Ubuntu 24.04, gcc 13.3.0, every build plays the whole list twice. Builds:
#   arm64: relA, Google DeepMind's arm64 Linux release (its sha256 checked); srcA, MuJoCo from its source at
#          UPSTREAM_COMMIT with gcc, MuJoCo's own CMake options; clangAnc, the same with clang, -ffp-contract=off and
#          its library linked against clang's runtime; setA, Senua AI's set (the six validated patch files), gcc;
#   Intel: relX, Google DeepMind's x86-64 Linux release (the record's); setX, Senua AI's set, gcc.
# The set's builds play with every switch set. The plays, every number drawn from seed 24 (DRAW=1 prints the draw and
# plays nothing): under MuJoCo's defaults, a slide along 0, 30 and 45 degrees at a step and a quarter of it, a held
# cube, a two-link chain free and swinging and a tumbling body under Euler and RK4, a stack of ten, MuJoCo's box;
# under Senua AI's configuration (the elliptic cone, 100 noslip iterations), the slides, the held cube, a free cube at
# 0.95 of its limit, Study 15's arm set down, dropped and held by joint friction, Study 15's grip, a stack of three
# offset and a stack of ten, MuJoCo's box and Study 19's six; under its hold form (and impratio 1,000, every geom's
# solref at twice the step), the free cube and the stacks; under its inverse form (no noslip, every joint's friction
# as stiff), the free cube, the offset stack and the arm held by joint friction.
# DRY=1 plays throwaway numbers at the edges of the drawn ranges into dry/, with the same builds.
# usage: play.sh <arm or x86> <work folder>
#        (repository root on that machine; the work folder holds mujoco-src at UPSTREAM_COMMIT and, on x86, the release
#        in mujoco-3.16.0)
set -u
draw() {  # the registered numbers from the seed: Study 10's procedure, from x(0) = 24
  local x=24 V=0 D=""
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
  # and, for this study: Study 20's friction list, Study 18's chain and body, the values Study 23 drew, the settings of
  # run 107
  SEEN_step="$SEEN_step 0.000957 0.001243 0.00114 0.000285 0.001277 0.00031925 0.00171 0.0004275 0.001 0.00025 0.016 0.001729 0.00043225 0.000741 0.00018525 0.001819 0.000619 0.00015475 0.01 0.002 0.0005 "
  SEEN_len="$SEEN_len 0.0478 0.046 0.0059 0.0119 0.0788 0.0455 0.0099 0.0233 0.0474 0.0316 0.0424 0.0489 0.0434 0.05 0.001 0.005 0.017 0.0334 0.0092 0.0387 0.0382 0.054 0.0258 0.0509 0.04 0.25 0.5 0.2 "
  SEEN_mass="$SEEN_mass 58.496 294.858 465.417 0.431 0.077 1.572 0.819 0.442 1.561 1.861 1 0.21 1.369 1.059 0.677 131.88 48.302 497.338 1.646 1.2 0.6 "
  SEEN_ratio="$SEEN_ratio 1.901 2.29 1.499 0.369 0.893 1.623 2.049 0.057 0.123 0.395 1.975 1.5 2.821 0.558 0.392 2.355 2.42 0.6 "
  SEEN_fric="$SEEN_fric 0.61 0.734 0.524 0.438 0.39 0.69 0.686 0.717 0.778 0.667 0.5 0.567 0.873 0.646 0.522 "
  SEEN_speed=" 0.5 1 1.01 1.2 2 0.537 "
  SEEN_angle=" -0.9 0.4 -0.7 0.555 0.905 1.157 -0.378 "
  SEEN_omega=" 2.5 1.5 2.2 1.4 -3.1 "
  SEEN_inert=" 0.0045 0.0072 0.0101 "
  # the slides: a step from 0.5 to 2 ms; a cube of 0.3 to 2 kg, half-size 25 to 60 mm, friction 0.3 to 0.9, set
  # sliding at 0.5 to 1.5 m/s
  q step s_dt 500 2000 6; q mass s_mass 300 2000 3; q len s_half 250 600 4; q fric s_mu 300 900 3; q speed s_v 500 1500 3
  # the held cube and the free cube: a step from 0.5 to 2 ms; a cube of the same ranges; held at 0.3 to 0.9 of its limit
  q step h_dt 500 2000 6; q mass h_mass 300 2000 3; q len h_half 250 600 4; q fric h_mu 300 900 3; q ratio h_frac 300 900 3
  # the chain and the tumbling body: a step from 2 to 10 ms; link masses 0.5 to 2 and 0.2 to 1 kg, radius 30 to 50 mm,
  # the first link 0.4 to 0.6 m long with its centre 0.15 to 0.3 m along it, the second's centre 0.15 to 0.25 m along;
  # free: the elbow at -1 to -0.5 rad, the links spinning at 1 to 3 and 1 to 2 rad/s; swinging from 0.2 to 0.6 and -0.9
  # to -0.3 rad; the body's principal inertias 0.004 to 0.006, 0.006 to 0.008 and 0.009 to 0.0095 kg m2 (each pair's sum
  # above the third), spinning at 1 to 3, 1 to 2 and -4 to -2 rad/s
  q step c_dt 2000 10000 6; q mass c_mass1 500 2000 3; q mass c_mass2 200 1000 3; q len c_radius 300 500 4
  q len c_arm1 1500 3000 4; q len c_len1 4000 6000 4; q len c_arm2 1500 2500 4
  q angle c_angle2 -1000 -500 3; q omega c_omega1 1000 3000 3; q omega c_omega2 1000 2000 3
  q angle c_swing1 200 600 3; q angle c_swing2 -900 -300 3
  q inert t_i1 4000 6000 6; q inert t_i2 6000 8000 6; q inert t_i3 9000 9500 6
  q omega t_w1 1000 3000 3; q omega t_w2 1000 2000 3; q omega t_w3 -4000 -2000 3
  # the stacks: a step from 0.5 to 1.5 ms; a cube of 0.3 to 2 kg, half-size 30 to 60 mm, friction 0.3 to 0.9; the
  # offset stack 0.05 to 0.15 of the half-size a cube
  q step k_dt 500 1500 6; q mass k_mass 300 2000 3; q len k_half 300 600 4; q fric k_mu 300 900 3; q ratio k_off 50 150 3
}
if [ "${DRAW:-0}" = 1 ]; then draw; exit 0; fi
M=${1:?usage: see the header}; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
NAMES="s_dt s_mass s_half s_mu s_v h_dt h_mass h_half h_mu h_frac c_dt c_mass1 c_mass2 c_radius c_arm1 c_len1 c_arm2 c_angle2 c_omega1 c_omega2 c_swing1 c_swing2 t_i1 t_i2 t_i3 t_w1 t_w2 t_w3 k_dt k_mass k_half k_mu k_off"
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_108_study_24/dry/$M"; mkdir -p "$O"
  # throwaway numbers at the edges of the drawn ranges
  printf '%s\n' "s_dt 0.002" "s_mass 0.3" "s_half 0.06" "s_mu 0.9" "s_v 1.5" "h_dt 0.0005" "h_mass 2" "h_half 0.025" "h_mu 0.3" \
    "h_frac 0.9" "c_dt 0.01" "c_mass1 2" "c_mass2 0.2" "c_radius 0.05" "c_arm1 0.3" "c_len1 0.4" "c_arm2 0.25" "c_angle2 -1" \
    "c_omega1 3" "c_omega2 1" "c_swing1 0.6" "c_swing2 -0.3" "t_i1 0.004" "t_i2 0.006" "t_i3 0.0095" "t_w1 3" "t_w2 1" \
    "t_w3 -4" "k_dt 0.0015" "k_mass 2" "k_half 0.03" "k_mu 0.3" "k_off 0.15" > "$O/draw.txt"
else
  O="$R/validation/run_108_study_24/$M"; mkdir -p "$O"; draw > "$O/draw.txt"
fi
for k in $NAMES; do eval "$k=$(awk -v k="$k" '$1 == k { print $2 }' "$O/draw.txt")"; done
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
{ uname -m; grep -m1 -i "model name\|CPU part" /proc/cpuinfo; gcc --version | head -1; . /etc/os-release; echo "$PRETTY_NAME"; } > "$O/machine.txt"
PS="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/qcqp_reduced_v2.diff $R/patches/boxbox_collinear.diff $R/patches/noslip_roll_kept_after_qcqp.diff $R/patches/noslip_equality.diff"
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in $PS; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" > "$O/patch_check.txt"
build() {  # <name> <patches: 0 or 6> <cmake options...>: MuJoCo from its source into $W/mujoco-s24<name>-build
  local nm=$1 n=s24$1 p=$2; shift 2
  rm -rf "${W:?}/mujoco-$n-src" "$W/$n-lib" "$W/mujoco-$n-build" && mkdir -p "$W/mujoco-$n-src"
  (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-$n-src"
  if [ "$p" = 6 ]; then for f in $PS; do (cd "$W/mujoco-$n-src" && patch -p1 -s < "$f") || log "patch FAILED $f"; done; fi
  ( cmake -S "$W/mujoco-$n-src" -B "$W/$n-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$W/mujoco-$n-build" "$@" && cmake --build "$W/$n-lib" -j"$J" && cmake --install "$W/$n-lib" ) > "$O/build_$nm.log" 2>&1
  log "build $nm exit $?"
}
if [ "$M" = arm ]; then
  T="mujoco-3.16.0-linux-aarch64.tar.gz"; U="https://github.com/google-deepmind/mujoco/releases/download/3.16.0"
  [ -f "$W/$T" ] || { curl -sSL -o "$W/$T" "$U/$T" && curl -sSL -o "$W/$T.sha256" "$U/$T.sha256"; }
  (cd "$W" && sha256sum -c "$T.sha256") > "$O/release_check.txt" 2>&1; log "release check exit $?"
  rm -rf "$W/mujoco-3.16.0-arm24" && mkdir -p "$W/mujoco-3.16.0-arm24" && tar xzf "$W/$T" -C "$W/mujoco-3.16.0-arm24" --strip-components=1
  command -v clang > /dev/null || sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq clang > /dev/null 2>&1
  clang --version | head -1 > "$O/clang.txt"
  build srcA 0
  build clangAnc 0 -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_FLAGS=-ffp-contract=off \
    -DCMAKE_CXX_FLAGS=-ffp-contract=off -DCMAKE_SHARED_LINKER_FLAGS=-rtlib=compiler-rt -DCMAKE_EXE_LINKER_FLAGS=-rtlib=compiler-rt
  build setA 6
  BUILDS="relA:$W/mujoco-3.16.0-arm24:0 srcA:$W/mujoco-s24srcA-build:0 clangAnc:$W/mujoco-s24clangAnc-build:0 setA:$W/mujoco-s24setA-build:6"
else
  build setX 6
  BUILDS="relX:$W/mujoco-3.16.0:0 setX:$W/mujoco-s24setX-build:6"
fi
CFG="cone=elliptic noslip=100"; A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"; S19="$R/validation/run_085_study_19/scenes"
lim() { awk -v f="$1" -v m="$2" -v u="$3" 'BEGIN { printf "%.6f", f * m * u * 9.8 }'; }
mul() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.9g", a * b }'; }
q4() { awk -v d="$1" 'BEGIN { printf "%.9g", d / 4 }'; }
plays() {  # <rigs folder> <out folder>: the list, every play's statistics in stats.txt
  local T=$1 P=$2 dt d s f
  mkdir -p "$P"; : > "$P/stats.txt"
  st() { sed "s|^STATS|STATS run $1|" >> "$P/stats.txt"; }
  local HL; HL=$(lim "$h_frac" "$h_mass" "$h_mu"); local FL; FL=$(lim 0.95 "$h_mass" "$h_mu")
  local CH="mass1=$c_mass1 mass2=$c_mass2 radius=$c_radius arm1=$c_arm1 len1=$c_len1 arm2=$c_arm2"
  local BODY="i1=$t_i1 i2=$t_i2 i3=$t_i3 w1=$t_w1 w2=$t_w2 w3=$t_w3"
  local KS; KS=$(mul "$k_off" "$k_half"); local K="mass=$k_mass radius=$k_half mu=$k_mu"
  local HOLD="$CFG impratio=1000"; local INV="cone=elliptic impratio=1000"
  # MuJoCo's defaults
  for dt in $s_dt $(q4 "$s_dt"); do for d in 0 30 45; do
    "$T/mjc_contact" "$P/d_slide_${d}_$dt.txt" dt=$dt h0=0 vx0=$s_v mu=$s_mu mass=$s_mass radius=$s_half secs=1.2 dir=$d lock=0 < /dev/null | st d_slide_${d}_$dt
  done; done
  "$T/mjc_contact" "$P/d_hold.txt" dt=$h_dt h0=0 mass=$h_mass radius=$h_half mu=$h_mu push=$HL pushat=0.4 secs=1.6 lock=1 < /dev/null | st d_hold
  for s in Euler RK4; do
    # shellcheck disable=SC2086
    "$T/mjc_chain" "$P/d_free_$s.txt" dt=$c_dt $CH gravity=0 angle2=$c_angle2 omega1=$c_omega1 omega2=$c_omega2 secs=2 integ=$s < /dev/null | st d_free_$s
    # shellcheck disable=SC2086
    "$T/mjc_chain" "$P/d_swing_$s.txt" dt=$c_dt $CH gravity=1 angle1=$c_swing1 angle2=$c_swing2 secs=2 integ=$s < /dev/null | st d_swing_$s
    # shellcheck disable=SC2086
    "$T/mjc_tumble" "$P/d_tumble_$s.txt" dt=$c_dt integ=$s $BODY secs=2 < /dev/null | st d_tumble_$s
  done
  # shellcheck disable=SC2086
  "$T/mjc_stack" "$P/d_stack10" dt=$k_dt n=10 secs=2 $K < /dev/null | st d_stack10
  "$T/mjc_scene" "$P/d_box.txt" scene="$SCN" body=box axis=1,0,0 secs=16 key=0 < /dev/null | st d_box
  # Senua AI's configuration
  for d in 0 30 45; do
    # shellcheck disable=SC2086
    "$T/mjc_contact" "$P/c_slide_$d.txt" dt=$s_dt h0=0 vx0=$s_v mu=$s_mu mass=$s_mass radius=$s_half secs=1.2 dir=$d lock=0 $CFG < /dev/null | st c_slide_$d
  done
  # shellcheck disable=SC2086
  "$T/mjc_contact" "$P/c_hold.txt" dt=$h_dt h0=0 mass=$h_mass radius=$h_half mu=$h_mu push=$HL pushat=0.4 secs=1.6 dir=0 lock=1 $CFG < /dev/null | st c_hold
  # shellcheck disable=SC2086
  "$T/mjc_contact" "$P/c_free.txt" dt=$h_dt h0=0 mass=$h_mass radius=$h_half mu=$h_mu push=$FL pushat=0.4 secs=1.6 dir=0 lock=0 $CFG < /dev/null | st c_free
  for hp in rest:"h0=0.00043 secs=2" drop:"h0=0.0129 secs=3" jf:"h0=1 secs=2 jointfriction=5.15"; do
    # shellcheck disable=SC2086
    "$T/mjc_arm" "$P/c_arm_${hp%%:*}.txt" dt=0.00171 pose=0.555,0.905 pose0=0.555,0.905 $A15 ${hp#*:} $CFG < /dev/null | st c_arm_${hp%%:*}
  done
  for f in box mesh; do
    # shellcheck disable=SC2086
    "$T/mjc_grip" "$P/c_grip_$f" dt=0.00171 offset=0.0092 pad=$f mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61 $CFG < /dev/null | st c_grip_$f
  done
  # shellcheck disable=SC2086
  "$T/mjc_stack" "$P/c_offset" dt=$k_dt n=3 shift=$KS secs=6 $K $CFG < /dev/null | st c_offset
  # shellcheck disable=SC2086
  "$T/mjc_stack" "$P/c_stack10" dt=$k_dt n=10 secs=2 $K $CFG < /dev/null | st c_stack10
  for f in "$SCN" "$S19"/*.xml; do
    b=$(basename "$f" .xml); [ "$f" = "$SCN" ] && b=mujoco
    "$T/mjc_scene" "$P/c_box_$b.txt" scene="$f" body=box axis=1,0,0 secs=16 key=0 cone=elliptic noslip=100 < /dev/null | st c_box_$b
  done
  # the hold form
  # shellcheck disable=SC2086
  "$T/mjc_contact" "$P/h_free.txt" dt=$h_dt h0=0 mass=$h_mass radius=$h_half mu=$h_mu push=$FL pushat=0.4 secs=1.6 dir=0 lock=0 $HOLD gsolref=$(mul 2 "$h_dt"),1 < /dev/null | st h_free
  # shellcheck disable=SC2086
  "$T/mjc_stack" "$P/h_offset" dt=$k_dt n=3 shift=$KS secs=6 $K $HOLD gsolref=$(mul 2 "$k_dt"),1 < /dev/null | st h_offset
  # shellcheck disable=SC2086
  "$T/mjc_stack" "$P/h_stack10" dt=$k_dt n=10 secs=2 $K $HOLD gsolref=$(mul 2 "$k_dt"),1 < /dev/null | st h_stack10
  # the inverse form
  # shellcheck disable=SC2086
  "$T/mjc_contact" "$P/i_free.txt" dt=$h_dt h0=0 mass=$h_mass radius=$h_half mu=$h_mu push=$FL pushat=0.4 secs=1.6 dir=0 lock=0 $INV gsolref=$(mul 2 "$h_dt"),1 < /dev/null | st i_free
  # shellcheck disable=SC2086
  "$T/mjc_stack" "$P/i_offset" dt=$k_dt n=3 shift=$KS secs=6 $K $INV gsolref=$(mul 2 "$k_dt"),1 < /dev/null | st i_offset
  # shellcheck disable=SC2086
  "$T/mjc_arm" "$P/i_arm_jf.txt" dt=0.00171 pose=0.555,0.905 pose0=0.555,0.905 $A15 h0=1 secs=2 jointfriction=5.15 $INV gsolref=0.00342,1 jsolref=0.00342,1 jsolimp=0.9999 < /dev/null | st i_arm_jf
}
for b in $BUILDS; do
  n=${b%%:*}; rest=${b#*:}; mj=${rest%%:*}; sw=${rest#*:}
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT MUJOCO_NOSLIP_EQUALITY
  [ "$sw" = 6 ] && export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1 MUJOCO_NOSLIP_EQUALITY=1
  X=$(mktemp -d); cp -R "$R/tools" "$X/"
  ( cd "$X" && for r in mjc_contact mjc_chain mjc_tumble mjc_stack mjc_scene mjc_arm mjc_grip; do MUJOCO_DIR=$mj tools/build_rig.sh $r > /dev/null 2>&1 || echo "rig $r FAILED for $n"; done ) >> "$O/progress.txt"
  rm -rf "${O:?}/$n" "$O/${n}_2"
  plays "$X/tools" "$O/$n"; plays "$X/tools" "$O/${n}_2"; rm -rf "${X:?}"
  log "$n played twice"
done
find "$O" -name 'build_*.log' -exec sed -i "s|$HOME|~|g" {} + ; find "$O" -name stats.txt -exec sed -i "s|$HOME|~|g" {} +
date -u +%FT%TZ > "$O/finished.txt"
