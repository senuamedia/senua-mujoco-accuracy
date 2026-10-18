#!/usr/bin/env bash
# Run 062: a design probe, not registered: it finds where to look and decides nothing. Runs 056, 059 and 060 found that
# under the elliptic cone MuJoCo's noslip removes a resting arm's slide in one pose (Study 13's first) and leaves it in
# others (Study 10's first, Study 13's second), by pose and not by the slip's direction. What does noslip compute for
# those contacts? An instrumentation patch, patches/in_design/noslip_trace.diff (off unless MUJOCO_NOSLIP_TRACE is set;
# 13 lines added, none removed), prints for each elliptic contact at each noslip sweep its normal force, its friction
# before and after the sweep, the friction rows' residual without regularisation, and the rows' block of MuJoCo's A; and
# at each sweep's end its improvement against noslip's tolerance. Built from MuJoCo's source at UPSTREAM_COMMIT. With the
# switch unset the plays below are compared by cmp with the release's. Traced, 0.5 s at 1.14 ms under the configuration
# (the elliptic cone, 10 noslip iterations): Study 10's arm in its first contact pose and Study 13's arm in both, set down
# on the ball and left at rest; and Study 10's cube held at 0.5 of its friction limit along 0 degrees, which noslip
# holds. Readings: the trace lines, summarised by the awk lines below; file comparison by cmp.
# usage: probe.sh <work folder>   (repository root, on the cloud machine; the work folder holds mujoco-src at
#        UPSTREAM_COMMIT and the release in mujoco-3.16.0)
set -u
W="$(cd "${1:?usage: see the header}" && pwd)"; R="$(pwd)"; J=$(nproc); O="$R/validation/run_062_noslip_trace"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
PF="$R/patches/in_design/noslip_trace.diff"; T="$W/mujoco-p62-build"
rm -rf "${W:?}/mujoco-p62-src" "$W/p62-lib" "$T" && mkdir -p "$W/mujoco-p62-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p62-src"
(cd "$W/mujoco-p62-src" && patch -p1 -s < "$PF")
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p62-src" -B "$W/p62-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$T" && cmake --build "$W/p62-lib" -j"$J" && cmake --install "$W/p62-lib" ) > "$O/build_lib.log" 2>&1
echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
A10="len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717"
A13="len1=0.297 len2=0.302 mass1=1.08 mass2=0.578 rb=0.0295 mb=0.194 mu=0.778"
REC="cone=elliptic noslip=10"; CUBE="mass=1.861 radius=0.0434 mu=0.39"
PUSH=$(awk 'BEGIN { printf "%.6f", 0.5 * 0.39 * 1.861 * 9.8 }')
for b in rel:$W/mujoco-3.16.0 tr:$T; do
  n=${b%%:*}; mj=${b#*:}; X="$W/p62$n"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" && for r in mjc_arm mjc_contact; do MUJOCO_DIR=$mj tools/build_rig.sh $r > /dev/null 2>&1; done )
done
mkdir -p "$O/off" "$O/rel" "$O/trace"
play() {  # <rig folder> <out folder> <trace 0|1>
  local X=$1 P=$2 t=$3
  if [ "$t" = 1 ]; then export MUJOCO_NOSLIP_TRACE=1; else unset MUJOCO_NOSLIP_TRACE; fi
  # shellcheck disable=SC2086
  "$X/tools/mjc_arm" "$P/s10_pose1.txt" dt=0.00114 pose=0.604,1.158 pose0=0.604,1.158 $A10 h0=0.00059 secs=0.5 $REC > /dev/null 2> "$P/s10_pose1.err"
  # shellcheck disable=SC2086
  "$X/tools/mjc_arm" "$P/s13_pose1.txt" dt=0.00114 pose=0.516,0.907 pose0=0.516,0.907 $A13 h0=0.00052 secs=0.5 $REC > /dev/null 2> "$P/s13_pose1.err"
  # shellcheck disable=SC2086
  "$X/tools/mjc_arm" "$P/s13_pose2.txt" dt=0.00114 pose=1.211,-0.464 pose0=1.211,-0.464 $A13 h0=0.00052 secs=0.5 $REC > /dev/null 2> "$P/s13_pose2.err"
  # shellcheck disable=SC2086
  "$X/tools/mjc_contact" "$P/cube_hold.txt" dt=0.00114 h0=0 $CUBE push=$PUSH pushat=0.4 secs=0.5 dir=0 $REC > /dev/null 2> "$P/cube_hold.err"
  unset MUJOCO_NOSLIP_TRACE
}
play "$W/p62rel" "$O/rel" 0
play "$W/p62tr" "$O/off" 0
play "$W/p62tr" "$O/trace" 1
rm -rf "$W/p62rel" "$W/p62tr"
echo "played $(date -u +%FT%TZ)" >> "$O/progress.txt"
{
  s=0; n=0
  for f in s10_pose1 s13_pose1 s13_pose2 cube_hold; do n=$((n + 1)); cmp -s "$O/rel/$f.txt" "$O/off/$f.txt" && s=$((s + 1)); done
  echo "safe when off: $s of $n plays byte for byte as released; the trace build's stderr with the switch unset: $(cat "$O"/off/*.err | wc -l) lines"
  echo "traced plays byte for byte as untraced: $(for f in s10_pose1 s13_pose1 s13_pose2 cube_hold; do cmp -s "$O/off/$f.txt" "$O/trace/$f.txt" && echo same || echo DIFFERS; done | tr '\n' ' ')"
  for f in s10_pose1 s13_pose1 s13_pose2 cube_hold; do
    # over the last 200 steps' first noslip sweep (iter 0): the friction's change, the residual before, the sweeps a step
    awk -v k="$f" '
      /^NOSLIP iter 0 / { n0++; for (i = 1; i < NF; i++) v[$i] = $(i + 1); split("", w)
                          o1 = $11; o2 = $12; n1 = $14; n2 = $15; r1 = $17; r2 = $18; a00 = $20; a01 = $21; a11 = $23; fn = $9; mu = $25
                          d = n1 - o1; if (d < 0) d = -d; e = n2 - o2; if (e < 0) e = -e; ch = d > e ? d : e
                          rec[n0] = sprintf("normal %.6g friction_old %.6g %.6g friction_new %.6g %.6g change %.3g res %.4g %.4g A %.4g %.4g %.4g mu %.4g", fn, o1, o2, n1, n2, ch, r1, r2, a00, a01, a11, mu) }
      /^NOSLIP_SWEEP / { sw++ }
      END { printf "%s sweeps %d steps_traced %d last_step: %s\n", k, sw, n0, rec[n0] }' "$O/trace/$f.err"
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
