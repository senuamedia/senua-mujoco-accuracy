#!/usr/bin/env bash
# Run 073: a design probe, not registered: it finds where to look and decides nothing. Issue 20 (F13): MuJoCo's own test
# scene DiscreteImplicitRowNoslip (a box slid at 2 m/s on a plane, 16 ms step, the discrete integrator, the elliptic cone,
# impratio 10, condim 6, 2 noslip iterations) never comes to rest: from step 31 it repeats a six-step cycle of speeds up
# to 77 mm/s. Run 050 found the cycle needs rolling friction and noslip; run 055, that noslip run to a tolerance of
# 1e-12 does not converge on it. What does noslip compute for its contacts through the cycle? Run 062's instrumentation
# patch, patches/in_design/noslip_trace.diff (off unless MUJOCO_NOSLIP_TRACE is set; 13 lines added, none removed),
# prints for each elliptic contact at each noslip sweep its normal force, its first two friction components before and
# after the sweep, their residual and their block of A, and each sweep's improvement. Built from MuJoCo's source at
# UPSTREAM_COMMIT. Played: the scene as written (run 049's copy, key 0), 16 s, and with 100 noslip iterations; released,
# on the trace build with the switch unset, and traced, compared by cmp. Readings: per noslip pass, its sweeps, its first
# and last improvement, the contacts, how many times a sweep returned zero for a contact's first two friction components
# from nonzero, the largest change in them in the last sweep; and the box's speed at that step; over the last 160 steps.
# usage: probe.sh <work folder>   (repository root, on the cloud machine; the work folder holds mujoco-src at
#        UPSTREAM_COMMIT and the release in mujoco-3.16.0)
set -u
W="$(cd "${1:?usage: see the header}" && pwd)"; R="$(pwd)"; J=$(nproc); O="$R/validation/run_073_box_noslip_trace"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
PF="$R/patches/in_design/noslip_trace.diff"; T="$W/mujoco-p73-build"
rm -rf "${W:?}/mujoco-p73-src" "$W/p73-lib" "$T" && mkdir -p "$W/mujoco-p73-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p73-src"
(cd "$W/mujoco-p73-src" && patch -p1 -s < "$PF")
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p73-src" -B "$W/p73-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$T" && cmake --build "$W/p73-lib" -j"$J" && cmake --install "$W/p73-lib" ) > "$O/build_lib.log" 2>&1
echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"
for b in rel:$W/mujoco-3.16.0 tr:$T; do
  n=${b%%:*}; mj=${b#*:}; X="$W/p73$n"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" && MUJOCO_DIR=$mj tools/build_rig.sh mjc_scene > /dev/null 2>&1 )
done
# the trace, read one noslip pass at a time (as run 067)
SUM='
function flush() { printf "%d %d %.6g %.6g %d %d %.6g\n", st, sw, imp0, impl, nc0, rej, mch
  st++; sw = 0; nc0 = 0; cur = -1; rej = 0; mch = 0 }
BEGIN { cur = -1 }
/^NOSLIP iter / { it = $3 + 0
  if (it == 0 && after) flush()
  after = 0
  if (it != cur) { cur = it; mch = 0 }
  if (it == 0) nc0++
  o1 = $11; o2 = $12; n1 = $14; n2 = $15
  if (n1 == 0 && n2 == 0 && (o1 != 0 || o2 != 0)) rej++
  d = n1 - o1; if (d < 0) d = -d; e = n2 - o2; if (e < 0) e = -e; if (d > mch) mch = d; if (e > mch) mch = e
  next }
/^NOSLIP_SWEEP / { if ($3 == 0 && after) flush(); sw = $3 + 1; if ($3 == 0) imp0 = $5; impl = $5; after = 1; next }
END { if (sw > 0) flush() }'
mkdir -p "$O/rel" "$O/off" "$O/trace"
for p in written: n100:noslip=100; do
  n=${p%%:*}; opt=${p#*:}
  unset MUJOCO_NOSLIP_TRACE
  # shellcheck disable=SC2086
  "$W/p73rel/tools/mjc_scene" "$O/rel/box_$n.txt" scene="$SCN" body=box axis=1,0,0 secs=16 key=0 $opt > "$O/rel/box_$n.stats" 2> "$O/rel/box_$n.err"
  # shellcheck disable=SC2086
  "$W/p73tr/tools/mjc_scene" "$O/off/box_$n.txt" scene="$SCN" body=box axis=1,0,0 secs=16 key=0 $opt > "$O/off/box_$n.stats" 2> "$O/off/box_$n.err"
  export MUJOCO_NOSLIP_TRACE=1
  # shellcheck disable=SC2086
  { "$W/p73tr/tools/mjc_scene" "$O/trace/box_$n.txt" scene="$SCN" body=box axis=1,0,0 secs=16 key=0 $opt 2>&1 1>&3 | tee >(gzip -n -9 > "$O/trace/box_$n.trace.gz") | awk "$SUM" > "$O/trace/box_$n.steps"; } 3> "$O/trace/box_$n.stats"
  unset MUJOCO_NOSLIP_TRACE
  echo "box_$n played $(date -u +%FT%TZ)" >> "$O/progress.txt"
done
rm -rf "$W/p73rel" "$W/p73tr"
sleep 2
{
  echo "per pass in trace/*.steps: pass sweeps first_improvement last_improvement contacts zero_returns_all_sweeps largest_change_last_sweep_N"
  s=0; n=0; u=0
  for f in box_written.txt box_n100.txt box_written.stats box_n100.stats; do n=$((n + 1)); cmp -s "$O/rel/$f" "$O/off/$f" && s=$((s + 1)); cmp -s "$O/off/$f" "$O/trace/$f" && u=$((u + 1)); done
  echo "safe when off: $s of $n files byte for byte as released; traced byte for byte as untraced: $u of $n; the trace build's stderr with the switch unset: $(cat "$O"/off/*.err | wc -l | tr -d ' ') lines"
  for n in written n100; do
    np=$(wc -l < "$O/trace/box_$n.steps" | tr -d ' ')
    echo "box_$n passes $np; the last 12 passes with the box's speed (vx, um/s) at the step each ends:"
    paste -d ' ' <(tail -12 "$O/trace/box_$n.steps") <(tail -12 "$O/trace/box_$n.txt" | awk '{ print "vx", $3 }') | sed 's/^/  /'
    awk 'NR > 1 { s[NR] = $0; n = NR } END { c = 0; for (i = n - 159; i <= n; i++) { split(s[i], f, " "); x = f[3] < 0 ? -f[3] : f[3]; if (x > 1000) c++ } print "  last 160 steps faster than 1 mm/s:", c }' "$O/trace/box_$n.txt"
    tail -160 "$O/trace/box_$n.steps" | awk '{ if ($6 > 0) r++; if ($2 >= m) m = $2; s += $2 } END { printf "  over the last 160 passes: passes with a zero return %d; most sweeps %d; mean sweeps %.2f\n", r + 0, m, s / NR }'
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
