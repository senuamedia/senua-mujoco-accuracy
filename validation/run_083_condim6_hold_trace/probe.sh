#!/usr/bin/env bash
# Run 083: a design probe, not registered: it finds where to look and decides nothing. Runs 079 and 082 found a cube
# with rolling friction (condim 6) held under Senua AI's configuration (the elliptic cone, 100 noslip iterations) creeping
# at 498 um/s at 0.5 of its friction limit, the elliptic cone's creep with no noslip at all; with condim 3 it holds at 0.
# What does noslip compute for its contacts? Run 076's instrumentation patch, patches/in_design/noslip_trace_all.diff
# (off unless MUJOCO_NOSLIP_TRACE_ALL is set), prints every friction component of each elliptic contact with torsional
# or rolling friction at each noslip sweep: before it, as the friction solve returns it, and as kept after MuJoCo's cost
# check. Built from MuJoCo's source at UPSTREAM_COMMIT. Played under the configuration, run 063's cube (Study 10's) held at
# 0.5 of its friction limit from 0.4 s, 0.6 s, at 1.14 ms, with condim 6 and with condim 4 (torsional friction, no
# rolling); and the same with condim 3 for comparison (the trace prints nothing for it). Released, on the trace build with
# the switch unset, and traced, compared by cmp. Readings: per noslip pass and contact, from its last sweep: the normal
# force, whether the solve's friction was kept or the old put back, every friction component kept, how far it lies along
# its cone; the cube's speed at the last step; the trace kept compressed.
# usage: probe.sh <work folder>   (repository root, on the cloud machine; the work folder holds mujoco-src at
#        UPSTREAM_COMMIT and the release in mujoco-3.16.0)
set -u
W="$(cd "${1:?usage: see the header}" && pwd)"; R="$(pwd)"; J=$(nproc); O="$R/validation/run_083_condim6_hold_trace"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
PF="$R/patches/in_design/noslip_trace_all.diff"; T="$W/mujoco-p83-build"
rm -rf "${W:?}/mujoco-p83-src" "$W/p83-lib" "$T" && mkdir -p "$W/mujoco-p83-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p83-src"
(cd "$W/mujoco-p83-src" && patch -p1 -s < "$PF")
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p83-src" -B "$W/p83-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$T" && cmake --build "$W/p83-lib" -j"$J" && cmake --install "$W/p83-lib" ) > "$O/build_lib.log" 2>&1
echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
REC="cone=elliptic noslip=100"; CUBE="mass=1.861 radius=0.0434 mu=0.39"
PUSH=$(awk 'BEGIN { printf "%.6f", 0.5 * 0.39 * 1.861 * 9.8 }')
for b in rel:$W/mujoco-3.16.0 tr:$T; do
  n=${b%%:*}; mj=${b#*:}; X="$W/p83$n"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" && MUJOCO_DIR=$mj tools/build_rig.sh mjc_contact > /dev/null 2>&1 )
done
SUM='
BEGIN { pass = 0 }
function flush(   c) { for (c in line) print pass, line[c]; pass++; split("", line); split("", seen0) }
/^NOSLIPF / {
  it = $3 + 0; c = $5; dm = $7 + 0; k = dm - 1; fn = $9
  if (it == 0 && (lastit > 0 || (c in seen0))) flush()
  if (it == 0) seen0[c] = 1
  lastit = it
  o = 11; nw = o + k + 1; kp = nw + k + 1; mu = kp + 2 * (k + 1)
  same = 1; restored = 1; zero = 1
  for (j = 0; j < k; j++) { if ($(kp + j) != $(nw + j)) same = 0; if ($(kp + j) != $(o + j)) restored = 0; if ($(nw + j) != 0) zero = 0 }
  s = 0; for (j = 0; j < k; j++) { if ($(mu + j) > 0) { q = $(kp + j) / $(mu + j); s += q * q } }
  ratio = (fn > 0) ? sqrt(s) / fn : 0
  st = same ? "kept" : (restored ? "restored" : "other")
  if (zero) st = st "_from_zero"
  txt = sprintf("contact %s dim %d normal %.6g %s cone %.6f friction", c, dm, fn, st, ratio)
  for (j = 0; j < k; j++) txt = txt sprintf(" %.6g", $(kp + j))
  txt = txt " solve"; for (j = 0; j < k; j++) txt = txt sprintf(" %.6g", $(nw + j))
  line[c] = txt
  next }
END { if (pass > 0 || length(line) > 0) flush() }'
mkdir -p "$O/rel" "$O/off" "$O/trace"
for cd in 6 4 3; do
  q=hold_c$cd
  unset MUJOCO_NOSLIP_TRACE_ALL
  "$W/p83rel/tools/mjc_contact" "$O/rel/$q.txt" dt=0.00114 h0=0 $CUBE push=$PUSH pushat=0.4 secs=0.6 dir=0 $REC condim=$cd > "$O/rel/$q.stats" 2> "$O/rel/$q.err"
  "$W/p83tr/tools/mjc_contact" "$O/off/$q.txt" dt=0.00114 h0=0 $CUBE push=$PUSH pushat=0.4 secs=0.6 dir=0 $REC condim=$cd > "$O/off/$q.stats" 2> "$O/off/$q.err"
  export MUJOCO_NOSLIP_TRACE_ALL=1
  "$W/p83tr/tools/mjc_contact" "$O/trace/$q.txt" dt=0.00114 h0=0 $CUBE push=$PUSH pushat=0.4 secs=0.6 dir=0 $REC condim=$cd > "$O/trace/$q.stats" 2> "$W/p83_$q.trace"
  unset MUJOCO_NOSLIP_TRACE_ALL
  awk "$SUM" "$W/p83_$q.trace" | sort -n -k1,1 -k3,3 > "$O/trace/$q.passes"
  gzip -n -9 -c "$W/p83_$q.trace" > "$O/trace/$q.trace.gz"; rm -f "$W/p83_$q.trace"
  echo "$q played $(date -u +%FT%TZ)" >> "$O/progress.txt"
done
rm -rf "$W/p83rel" "$W/p83tr"
{
  s=0; n=0; u=0
  for cd in 6 4 3; do for e in txt stats; do f=hold_c$cd.$e; n=$((n + 1)); cmp -s "$O/rel/$f" "$O/off/$f" && s=$((s + 1)); cmp -s "$O/off/$f" "$O/trace/$f" && u=$((u + 1)); done; done
  echo "safe when off: $s of $n files byte for byte as released; traced byte for byte as untraced: $u of $n; the trace build's stderr with the switch unset: $(cat "$O"/off/*.err | wc -l | tr -d ' ') lines"
  for cd in 6 4 3; do
    q=hold_c$cd
    echo "$q: the cube's speed at the last step $(tail -1 "$O/trace/$q.txt" | awk '{ print $3 }') um/s; passes traced $(awk '{ print $1 }' "$O/trace/$q.passes" | sort -u | wc -l | tr -d ' ')"
    awk '{ t[$8]++ } END { for (k in t) printf "  over all passes: %s %d\n", k, t[k] }' "$O/trace/$q.passes" | sort
    last=$(tail -1 "$O/trace/$q.passes" | awk '{ print $1 }')
    [ -n "$last" ] && awk -v l="$last" '$1 > l - 3' "$O/trace/$q.passes" | sed 's/^/    /'
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
