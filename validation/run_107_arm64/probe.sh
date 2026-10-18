#!/usr/bin/env bash
# Run 107: a design probe, not registered: it finds where to look and decides nothing. Issue 18: MuJoCo documents
# determinism only within one version on one architecture; the record has played Intel only (macOS and Linux). Here the
# same plays on an arm64 machine (AWS EC2 c7g.xlarge, Graviton3) and on the first cloud machine (Intel), each build
# playing the whole list twice. MuJoCo's x86-64 builds compile with -mavx and use hand-written AVX code for its vector
# sums (MUJOCO_ENABLE_AVX, MUJOCO_ENABLE_AVX_INTRINSICS); on arm64 there is no AVX and the plain loops run, and the
# compilers fuse a multiply and an add into one rounding there by default (FMA, -ffp-contract). Builds:
#   arm64: relA, Google DeepMind's arm64 Linux release (mujoco-3.16.0-linux-aarch64.tar.gz, its sha256 checked);
#          srcA, MuJoCo from its source at UPSTREAM_COMMIT with gcc, MuJoCo's own options; srcAnc, the same with
#          -ffp-contract=off; setAnc, Senua AI's set (the six validated patch files) with -ffp-contract=off;
#   x86:   relX, Google DeepMind's x86-64 Linux release (the record's); srcXna, MuJoCo from its source with
#          MUJOCO_ENABLE_AVX and MUJOCO_ENABLE_AVX_INTRINSICS off; setXna, Senua AI's set the same way.
# The plays, the same list for every build (the set's builds with every switch set): under MuJoCo's defaults, Study
# 13's slide along 0, 30 and 45 degrees at 2 and 0.5 ms, a cube held at 0.6 of its limit, Study 18's chain free and
# swinging and its tumbling body under Euler and RK4 at 10 and 2 ms, a stack of ten, MuJoCo's box as written; under
# Senua AI's configuration (the elliptic cone, 100 noslip iterations), the slides at 1 ms, the cube Study 19 held at 0.5
# and 0.95, Study 20's free cube b at 0.95, Study 15's arm set down, dropped and held by joint friction and its grip at
# 1.71 ms, stacks of three offset 5 mm and of ten at 1.14 ms, MuJoCo's box and Study 19's box 1; and under its hold form
# (and impratio 1,000, every geom's solref twice the step) the free cube and the stacks.
# usage: probe.sh <arm or x86> <work folder>   (repository root on that machine; on x86 the work folder holds the
#        release in mujoco-3.16.0 and mujoco-src at UPSTREAM_COMMIT; on arm, mujoco-src)
set -u
M=${1:?usage: see the header}; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_107_arm64/$M"; mkdir -p "$O"; : > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
{ uname -m; grep -m1 -i "model name\|CPU part" /proc/cpuinfo; gcc --version | head -1; . /etc/os-release; echo "$PRETTY_NAME"; } > "$O/machine.txt"
PS="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/qcqp_reduced_v2.diff $R/patches/boxbox_collinear.diff $R/patches/noslip_roll_kept_after_qcqp.diff $R/patches/noslip_equality.diff"
build() {  # <name> <patches: 0 or 6> <cmake options...>: MuJoCo from its source into $W/mujoco-<name>-build
  local n=$1 p=$2; shift 2
  rm -rf "${W:?}/mujoco-$n-src" "$W/$n-lib" "$W/mujoco-$n-build" && mkdir -p "$W/mujoco-$n-src"
  (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-$n-src"
  if [ "$p" = 6 ]; then for f in $PS; do (cd "$W/mujoco-$n-src" && patch -p1 -s < "$f") || log "patch FAILED $f"; done; fi
  ( cmake -S "$W/mujoco-$n-src" -B "$W/$n-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$W/mujoco-$n-build" "$@" && cmake --build "$W/$n-lib" -j"$J" && cmake --install "$W/$n-lib" ) > "$O/build_$n.log" 2>&1
  log "build $n exit $?"
}
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in $PS; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" > "$O/patch_check.txt"
if [ "$M" = arm ]; then
  T="mujoco-3.16.0-linux-aarch64.tar.gz"; U="https://github.com/google-deepmind/mujoco/releases/download/3.16.0"
  [ -f "$W/$T" ] || { curl -sSL -o "$W/$T" "$U/$T" && curl -sSL -o "$W/$T.sha256" "$U/$T.sha256"; }
  (cd "$W" && sha256sum -c "$T.sha256") > "$O/release_check.txt" 2>&1; log "release check exit $?"
  rm -rf "$W/mujoco-3.16.0-arm" && mkdir -p "$W/mujoco-3.16.0-arm" && tar xzf "$W/$T" -C "$W/mujoco-3.16.0-arm" --strip-components=1
  build srcA 0
  build srcAnc 0 -DCMAKE_C_FLAGS=-ffp-contract=off -DCMAKE_CXX_FLAGS=-ffp-contract=off
  build setAnc 6 -DCMAKE_C_FLAGS=-ffp-contract=off -DCMAKE_CXX_FLAGS=-ffp-contract=off
  BUILDS="relA:$W/mujoco-3.16.0-arm:0 srcA:$W/mujoco-srcA-build:0 srcAnc:$W/mujoco-srcAnc-build:0 setAnc:$W/mujoco-setAnc-build:6"
else
  build srcXna 0 -DMUJOCO_ENABLE_AVX=OFF -DMUJOCO_ENABLE_AVX_INTRINSICS=OFF
  build setXna 6 -DMUJOCO_ENABLE_AVX=OFF -DMUJOCO_ENABLE_AVX_INTRINSICS=OFF
  BUILDS="relX:$W/mujoco-3.16.0:0 srcXna:$W/mujoco-srcXna-build:0 setXna:$W/mujoco-setXna-build:6"
fi
CFG="cone=elliptic noslip=100"; A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"
ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"; FREE="angle2=-0.9 omega1=2.5 omega2=1.5"
SWING="angle1=0.4 angle2=-0.7"; BODY="i1=0.0045 i2=0.0072 i3=0.0101 w1=2.2 w2=1.4 w3=-3.1"
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"; B19="$R/validation/run_085_study_19/scenes/box1_0.016.xml"
lim() { awk -v f="$1" -v m="$2" -v u="$3" 'BEGIN { printf "%.6f", f * m * u * 9.8 }'; }
plays() {  # <rigs folder> <out folder>: the list, every play's statistics in stats.txt
  local T=$1 P=$2 dt d s
  mkdir -p "$P"; : > "$P/stats.txt"
  st() { sed "s|^STATS|STATS run $1|" >> "$P/stats.txt"; }
  for dt in 0.002 0.0005; do for d in 0 30 45; do
    "$T/mjc_contact" "$P/d_slide_${d}_$dt.txt" dt=$dt h0=0 vx0=1.01 mu=0.39 mass=1.861 radius=0.0434 secs=1.2 dir=$d lock=0 < /dev/null | st d_slide_${d}_$dt
  done; done
  "$T/mjc_contact" "$P/d_hold.txt" dt=0.002 h0=0 mass=1 radius=0.05 mu=0.5 push=$(lim 0.6 1 0.5) pushat=0.4 secs=1.6 lock=1 < /dev/null | st d_hold
  for s in Euler RK4; do for dt in 0.01 0.002; do
    # shellcheck disable=SC2086
    "$T/mjc_chain" "$P/d_free_${s}_$dt.txt" dt=$dt $ARMS gravity=0 $FREE secs=2 integ=$s < /dev/null | st d_free_${s}_$dt
    # shellcheck disable=SC2086
    "$T/mjc_chain" "$P/d_swing_${s}_$dt.txt" dt=$dt $ARMS gravity=1 $SWING secs=2 integ=$s < /dev/null | st d_swing_${s}_$dt
    # shellcheck disable=SC2086
    "$T/mjc_tumble" "$P/d_tumble_${s}_$dt.txt" dt=$dt integ=$s $BODY secs=2 < /dev/null | st d_tumble_${s}_$dt
  done; done
  "$T/mjc_stack" "$P/d_stack10" dt=0.002 n=10 secs=2 mass=0.442 radius=0.0424 mu=0.524 < /dev/null | st d_stack10
  "$T/mjc_scene" "$P/d_box.txt" scene="$SCN" body=box axis=1,0,0 secs=16 key=0 < /dev/null | st d_box
  for d in 0 30 45; do
    # shellcheck disable=SC2086
    "$T/mjc_contact" "$P/c_slide_$d.txt" dt=0.001 h0=0 vx0=1.01 mu=0.39 mass=1.861 radius=0.0434 secs=1.2 dir=$d lock=0 $CFG < /dev/null | st c_slide_$d
  done
  for f in 0.5 0.95; do
    # shellcheck disable=SC2086
    "$T/mjc_contact" "$P/c_hold_$f.txt" dt=0.00171 h0=0 mass=1.561 radius=0.0489 mu=0.438 push=$(lim $f 1.561 0.438) pushat=0.4 secs=1.6 dir=0 lock=1 $CFG < /dev/null | st c_hold_$f
  done
  # shellcheck disable=SC2086
  "$T/mjc_contact" "$P/c_free.txt" dt=0.001277 h0=0 mass=0.819 radius=0.0316 mu=0.734 push=$(lim 0.95 0.819 0.734) pushat=0.4 secs=1.6 dir=0 lock=0 $CFG < /dev/null | st c_free
  for hp in rest:"h0=0.00043 secs=2" drop:"h0=0.0129 secs=3" jf:"h0=1 secs=2 jointfriction=5.15"; do
    # shellcheck disable=SC2086
    "$T/mjc_arm" "$P/c_arm_${hp%%:*}.txt" dt=0.00171 pose=0.555,0.905 pose0=0.555,0.905 $A15 ${hp#*:} $CFG < /dev/null | st c_arm_${hp%%:*}
  done
  for pad in box mesh; do
    # shellcheck disable=SC2086
    "$T/mjc_grip" "$P/c_grip_$pad" dt=0.00171 offset=0.0092 pad=$pad mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61 $CFG < /dev/null | st c_grip_$pad
  done
  # shellcheck disable=SC2086
  "$T/mjc_stack" "$P/c_offset" dt=0.00114 n=3 shift=0.005 secs=6 mass=0.442 radius=0.0424 mu=0.524 $CFG < /dev/null | st c_offset
  # shellcheck disable=SC2086
  "$T/mjc_stack" "$P/c_stack10" dt=0.00114 n=10 secs=2 mass=0.442 radius=0.0424 mu=0.524 $CFG < /dev/null | st c_stack10
  "$T/mjc_scene" "$P/c_box.txt" scene="$SCN" body=box axis=1,0,0 secs=16 key=0 cone=elliptic noslip=100 < /dev/null | st c_box
  "$T/mjc_scene" "$P/c_box19.txt" scene="$B19" body=box axis=1,0,0 secs=16 key=0 cone=elliptic noslip=100 < /dev/null | st c_box19
  HOLD="$CFG impratio=1000"
  # shellcheck disable=SC2086
  "$T/mjc_contact" "$P/h_free.txt" dt=0.001277 h0=0 mass=0.819 radius=0.0316 mu=0.734 push=$(lim 0.95 0.819 0.734) pushat=0.4 secs=1.6 dir=0 lock=0 $HOLD gsolref=0.002554,1 < /dev/null | st h_free
  # shellcheck disable=SC2086
  "$T/mjc_stack" "$P/h_offset" dt=0.00114 n=3 shift=0.005 secs=6 mass=0.442 radius=0.0424 mu=0.524 $HOLD gsolref=0.00228,1 < /dev/null | st h_offset
  # shellcheck disable=SC2086
  "$T/mjc_stack" "$P/h_stack10" dt=0.00114 n=10 secs=2 mass=0.442 radius=0.0424 mu=0.524 $HOLD gsolref=0.00228,1 < /dev/null | st h_stack10
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
