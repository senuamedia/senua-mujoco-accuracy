#!/usr/bin/env bash
# Run 072: a design probe, not registered: it finds where to look and decides nothing. Run 069 traced the stacks' kicks
# (issue 21) to MuJoCo's box-on-box clip adding contacts along a face's edges; run 070's patch, the clip given the
# separation tests' rounding slack (2.5e-14 m for these cubes), stood every stack of its grid with the main solver at a
# tolerance of 1e-11 or tighter, and none better at MuJoCo's default. How far off the clip's planes are the corners, and
# how far turned is the face, when the contacts change? An instrumentation patch, patches/in_design/boxbox_trace.diff
# (off unless MUJOCO_BOXBOX_TRACE is set; engine_collision_box.c only, 21 lines added, none removed), prints for each
# box-on-box face contact the least and most any incident corner lies outside the reference face's extent, the sine of
# the face's turn in the reference plane, its largest out-of-plane axis component, and the vertices and contacts the clip
# gives. Built from MuJoCo's source at UPSTREAM_COMMIT. Played under Senua AI's configuration (the elliptic cone, 100
# noslip iterations), run 063's stacks (Study 10's cube) of 5 and 9, 2 s: at 0.285 ms at MuJoCo's default main tolerance
# and at 1e-12, and at 1.14 ms at the default; released, on the trace build with the switch unset, and traced, compared by
# cmp. Readings: per pair of geoms, until its first change in contacts after step 30, the most any corner lies outside,
# the most turn and the most tilt; each change, the first ten, with the line before it and its own; the trace kept
# compressed.
# usage: probe.sh <work folder>   (repository root, on the cloud machine; the work folder holds mujoco-src at
#        UPSTREAM_COMMIT and the release in mujoco-3.16.0)
set -u
W="$(cd "${1:?usage: see the header}" && pwd)"; R="$(pwd)"; J=$(nproc); O="$R/validation/run_072_boxbox_trace"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
PF="$R/patches/in_design/boxbox_trace.diff"; T="$W/mujoco-p72-build"
rm -rf "${W:?}/mujoco-p72-src" "$W/p72-lib" "$T" && mkdir -p "$W/mujoco-p72-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p72-src"
(cd "$W/mujoco-p72-src" && patch -p1 -s < "$PF")
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p72-src" -B "$W/p72-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$T" && cmake --build "$W/p72-lib" -j"$J" && cmake --install "$W/p72-lib" ) > "$O/build_lib.log" 2>&1
echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
REC="cone=elliptic noslip=100"; KCUBE="mass=0.442 radius=0.0424 mu=0.524"
for b in rel:$W/mujoco-3.16.0 tr:$T; do
  n=${b%%:*}; mj=${b#*:}; X="$W/p72$n"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" && MUJOCO_DIR=$mj tools/build_rig.sh mjc_stack > /dev/null 2>&1 )
done
SUM='
{ k = $5 "-" $6; t = $3 + 0
  if (!(k in first) && t > 30 * dt) {
    e = $9 + 0; y = $11 + 0; u = $13 + 0
    if (!(k in me) || e > me[k]) me[k] = e; if (y > my[k]) my[k] = y; if (u > mu[k]) mu[k] = u }
  if ((k in prev) && $17 != pc[k] && t > 30 * dt) {
    if (!(k in first)) { first[k] = t; ord[++nk] = k }
    if (ev < 10) { ev++; printf "CHANGE %d pair %s at %s s: %s -> %s contacts\n  before: %s\n  at:     %s\n", ev, k, t, pc[k], $17, prev[k], $0 }
    nch++ }
  prev[k] = $0; pc[k] = $17; seen[k] = 1 }
END {
  for (k in seen) printf "PAIR %s first_change_s %s until_then most_corner_outside_m %.6g most_yaw_sin %.6g most_tilt %.6g\n", k, (k in first) ? first[k] : "none", me[k], my[k], mu[k]
  printf "CHANGES %d\n", nch + 0 }'
mkdir -p "$O/rel" "$O/off" "$O/trace"
for p in 0.000285:def 0.000285:1e-12 0.00114:def; do
  dt=${p%%:*}; tol=${p#*:}
  if [ "$tol" = def ]; then TT=""; else TT="tolerance=$tol"; fi
  for nn in 5 9; do
    q=stack${nn}_${dt}_$tol
    unset MUJOCO_BOXBOX_TRACE
    # shellcheck disable=SC2086
    "$W/p72rel/tools/mjc_stack" "$O/rel/$q" dt=$dt n=$nn secs=2 $KCUBE $REC $TT > "$O/rel/$q.stats" 2> "$O/rel/$q.err"
    # shellcheck disable=SC2086
    "$W/p72tr/tools/mjc_stack" "$O/off/$q" dt=$dt n=$nn secs=2 $KCUBE $REC $TT > "$O/off/$q.stats" 2> "$O/off/$q.err"
    export MUJOCO_BOXBOX_TRACE=1
    # shellcheck disable=SC2086
    "$W/p72tr/tools/mjc_stack" "$O/trace/$q" dt=$dt n=$nn secs=2 $KCUBE $REC $TT > "$O/trace/$q.stats" 2> "$W/p72_$q.trace"
    unset MUJOCO_BOXBOX_TRACE
    awk -v dt="$dt" "$SUM" "$W/p72_$q.trace" > "$O/trace/$q.events"
    gzip -n -9 -c "$W/p72_$q.trace" > "$O/trace/$q.trace.gz"; rm -f "$W/p72_$q.trace"
    echo "$q played $(date -u +%FT%TZ)" >> "$O/progress.txt"
  done
done
rm -rf "$W/p72rel" "$W/p72tr"
{
  s=0; n=0; u=0
  for f in $(cd "$O/rel" && ls | grep -v '\.err$'); do n=$((n + 1)); cmp -s "$O/rel/$f" "$O/off/$f" && s=$((s + 1)); cmp -s "$O/off/$f" "$O/trace/$f" && u=$((u + 1)); done
  echo "safe when off: $s of $n files byte for byte as released; traced byte for byte as untraced: $u of $n; the trace build's stderr with the switch unset: $(cat "$O"/off/*.err | wc -l | tr -d ' ') lines"
  for p in 0.000285_def 0.000285_1e-12 0.00114_def; do
    for nn in 5 9; do
      q=stack${nn}_$p
      tilt=$(cat "$O/trace/${q}"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }')
      echo "$q most_tilt_urad $tilt $(grep '^CHANGES' "$O/trace/$q.events")"
      grep '^PAIR' "$O/trace/$q.events" | sort | sed "s/^/  /"
    done
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
