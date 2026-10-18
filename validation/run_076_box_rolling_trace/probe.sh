#!/usr/bin/env bash
# Run 076: a design probe, not registered: it finds where to look and decides nothing. Run 073 found the box that never
# rests (issue 20, F13; MuJoCo's test scene DiscreteImplicitRowNoslip, condim 6) rocking on a six-step cycle, its contacts
# 4, 4, 4, 4, 2, 2, with noslip converging every step; run 050 found that with condim 4 (no rolling friction) it rests.
# What does noslip do with the torsional and rolling friction? An instrumentation patch,
# patches/in_design/noslip_trace_all.diff (off unless MUJOCO_NOSLIP_TRACE_ALL is set; engine_solver.c only, 23 lines
# added, none removed), prints for each elliptic contact with torsional or rolling friction, at each noslip sweep, every
# friction component before the sweep, as the friction solve returns it, and as kept after MuJoCo's cost check, with the
# residual and the coefficients. Built from MuJoCo's source at UPSTREAM_COMMIT. Played: the scene as written (run 049's
# copy, key 0), 16 s; and the same scene with condim 4, written by this script from it by changing condim="6" to
# condim="4" and nothing else; released, on the trace build with the switch unset, and traced, compared by cmp.
# Readings: per noslip pass and contact, from its last sweep: the normal force, whether the solve's friction was kept or
# the old put back, every friction component kept, and how far the friction lies along its elliptic cone (the square
# root of the sum of each component over its coefficient, squared, over the normal force: 1 on the cone's edge); the
# box's speed at each step; over the last 12 steps.
# usage: probe.sh <work folder>   (repository root, on the cloud machine; the work folder holds mujoco-src at
#        UPSTREAM_COMMIT and the release in mujoco-3.16.0)
set -u
W="$(cd "${1:?usage: see the header}" && pwd)"; R="$(pwd)"; J=$(nproc); O="$R/validation/run_076_box_rolling_trace"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
PF="$R/patches/in_design/noslip_trace_all.diff"; T="$W/mujoco-p76-build"
rm -rf "${W:?}/mujoco-p76-src" "$W/p76-lib" "$T" && mkdir -p "$W/mujoco-p76-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p76-src"
(cd "$W/mujoco-p76-src" && patch -p1 -s < "$PF")
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p76-src" -B "$W/p76-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$T" && cmake --build "$W/p76-lib" -j"$J" && cmake --install "$W/p76-lib" ) > "$O/build_lib.log" 2>&1
echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"
sed 's/condim="6"/condim="4"/' "$SCN" > "$O/scene_condim4.xml"
diff "$SCN" "$O/scene_condim4.xml" > "$O/scene_condim4.diff"
for b in rel:$W/mujoco-3.16.0 tr:$T; do
  n=${b%%:*}; mj=${b#*:}; X="$W/p76$n"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" && MUJOCO_DIR=$mj tools/build_rig.sh mjc_scene > /dev/null 2>&1 )
done
# per noslip pass and contact, its last sweep's line: a new pass starts at a sweep-0 line after a later sweep's, or at a
# sweep-0 line for a contact this pass has already seen
SUM='
BEGIN { pass = 0 }
function flush(   c) { for (c in line) print pass, line[c]; pass++; split("", line); split("", seen0) }
/^NOSLIPF / {
  it = $3 + 0; c = $5; dm = $7 + 0; k = dm - 1; fn = $9
  if (it == 0 && (lastit > 0 || (c in seen0))) flush()
  if (it == 0) seen0[c] = 1
  lastit = it
  o = 11; nw = o + k + 1; kp = nw + k + 1; mu = kp + 2 * (k + 1)
  same = 1; restored = 1
  for (j = 0; j < k; j++) { if ($(kp + j) != $(nw + j)) same = 0; if ($(kp + j) != $(o + j)) restored = 0 }
  s = 0; for (j = 0; j < k; j++) { if ($(mu + j) > 0) { q = $(kp + j) / $(mu + j); s += q * q } }
  ratio = (fn > 0) ? sqrt(s) / fn : 0
  st = same ? "kept" : (restored ? "restored" : "other")
  txt = sprintf("contact %s dim %d normal %.6g %s cone %.6f friction", c, dm, fn, st, ratio)
  for (j = 0; j < k; j++) txt = txt sprintf(" %.6g", $(kp + j))
  line[c] = txt
  next }
END { flush() }'
mkdir -p "$O/rel" "$O/off" "$O/trace"
for p in written:$SCN condim4:$O/scene_condim4.xml; do
  n=${p%%:*}; sc=${p#*:}
  unset MUJOCO_NOSLIP_TRACE_ALL
  "$W/p76rel/tools/mjc_scene" "$O/rel/box_$n.txt" scene="$sc" body=box axis=1,0,0 secs=16 key=0 > "$O/rel/box_$n.stats" 2> "$O/rel/box_$n.err"
  "$W/p76tr/tools/mjc_scene" "$O/off/box_$n.txt" scene="$sc" body=box axis=1,0,0 secs=16 key=0 > "$O/off/box_$n.stats" 2> "$O/off/box_$n.err"
  export MUJOCO_NOSLIP_TRACE_ALL=1
  "$W/p76tr/tools/mjc_scene" "$O/trace/box_$n.txt" scene="$sc" body=box axis=1,0,0 secs=16 key=0 > "$O/trace/box_$n.stats" 2> "$W/p76_$n.trace"
  unset MUJOCO_NOSLIP_TRACE_ALL
  awk "$SUM" "$W/p76_$n.trace" | sort -n -k1,1 -k3,3 > "$O/trace/box_$n.passes"
  gzip -n -9 -c "$W/p76_$n.trace" > "$O/trace/box_$n.trace.gz"; rm -f "$W/p76_$n.trace"
  echo "box_$n played $(date -u +%FT%TZ)" >> "$O/progress.txt"
done
rm -rf "$W/p76rel" "$W/p76tr"
{
  s=0; n=0; u=0
  for f in box_written.txt box_condim4.txt box_written.stats box_condim4.stats; do n=$((n + 1)); cmp -s "$O/rel/$f" "$O/off/$f" && s=$((s + 1)); cmp -s "$O/off/$f" "$O/trace/$f" && u=$((u + 1)); done
  echo "safe when off: $s of $n files byte for byte as released; traced byte for byte as untraced: $u of $n; the trace build's stderr with the switch unset: $(cat "$O"/off/*.err | wc -l | tr -d ' ') lines"
  for n in written condim4; do
    last=$(tail -1 "$O/trace/box_$n.passes" | awk '{ print $1 }')
    echo "box_$n: $(awk 'NR > 1 { s[NR] = $0; m = NR } END { c = 0; for (i = m - 159; i <= m; i++) { split(s[i], f, " "); x = f[3] < 0 ? -f[3] : f[3]; if (x > 1000) c++ } print "last 160 steps faster than 1 mm/s:", c }' "$O/trace/box_$n.txt"); passes $((last + 1))"
    echo "  the box's speed (vx, um/s), the last 12 steps: $(tail -12 "$O/trace/box_$n.txt" | awk '{ printf "%s ", $3 }')"
    echo "  the last 12 passes, each contact's last sweep:"
    awk -v l="$last" '$1 > l - 12' "$O/trace/box_$n.passes" | sed 's/^/    /'
    awk '{ t[$8]++ } END { for (k in t) printf "  over all passes: %s %d\n", k, t[k] }' "$O/trace/box_$n.passes"
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
