#!/usr/bin/env bash
# Run 067: a design probe, not registered: it finds where to look and decides nothing. Issue 21 (F14): under Senua AI's
# configuration (the elliptic cone, 100 noslip iterations) a straight stack of 5 tilts up to 2.3 mrad at 0.285 ms and a
# stack of 9 up to 2.5 mrad, while at 1.14 ms both stand (run 063); no stack moves without noslip (run 050). What does
# noslip compute for the stacks' contacts? The instrumentation patch of run 062, patches/in_design/noslip_trace.diff (off
# unless MUJOCO_NOSLIP_TRACE is set; 13 lines added, none removed), prints for each elliptic contact at each noslip sweep
# its normal force, its friction before and after the sweep, the friction rows' residual and the rows' block of A, and
# at each sweep's end its improvement against noslip's tolerance. Built from MuJoCo's source at UPSTREAM_COMMIT. The
# trace is read as it is printed, one line a step, never kept whole. Played under the configuration, run 063's stacks
# (Study 10's cube): straight stacks of 5 and 9, 2 s, at 0.285 and 1.14 ms; the release's, the trace build's with the
# switch unset, and traced, compared by cmp. Readings: per step, noslip's sweeps, its first and last improvement, the
# contacts, how many times its sweeps returned zero friction for a contact, how many at their cone's edge (friction at least 0.999 of mu
# times the normal force), the largest friction change in the last sweep, and the smallest scaled determinant of a
# contact's block (mu^4 (A00 A11 - A01 A10), the quantity mju_QCQP2 checks against 1e-10); and each cube's tilt.
# usage: probe.sh <work folder>   (repository root, on the cloud machine; the work folder holds mujoco-src at
#        UPSTREAM_COMMIT and the release in mujoco-3.16.0)
set -u
W="$(cd "${1:?usage: see the header}" && pwd)"; R="$(pwd)"; J=$(nproc); O="$R/validation/run_067_stack_noslip_trace"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
PF="$R/patches/in_design/noslip_trace.diff"; T="$W/mujoco-p67-build"
rm -rf "${W:?}/mujoco-p67-src" "$W/p67-lib" "$T" && mkdir -p "$W/mujoco-p67-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p67-src"
(cd "$W/mujoco-p67-src" && patch -p1 -s < "$PF")
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p67-src" -B "$W/p67-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$T" && cmake --build "$W/p67-lib" -j"$J" && cmake --install "$W/p67-lib" ) > "$O/build_lib.log" 2>&1
echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
REC="cone=elliptic noslip=100"; KCUBE="mass=0.442 radius=0.0424 mu=0.524"
for b in rel:$W/mujoco-3.16.0 tr:$T; do
  n=${b%%:*}; mj=${b#*:}; X="$W/p67$n"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" && MUJOCO_DIR=$mj tools/build_rig.sh mjc_stack > /dev/null 2>&1 )
done
# the trace, read one step at a time: a step ends at its last NOSLIP_SWEEP line, before the next line of sweep 0
SUM='
function flush() { printf "%d %d %.6g %.6g %d %d %d %.6g %.6g\n", st, sw, imp0, impl, nc0, rej, edge, mch, mdet
  st++; sw = 0; nc0 = 0; mdet = -1; cur = -1; rej = 0; edge = 0; mch = 0 }
BEGIN { cur = -1; mdet = -1 }
/^NOSLIP iter / { it = $3 + 0
  if (it == 0 && after) flush()
  after = 0
  if (it != cur) { cur = it; edge = 0; mch = 0 }
  if (it == 0) nc0++
  fn = $9; o1 = $11; o2 = $12; n1 = $14; n2 = $15; a00 = $20; a01 = $21; a10 = $22; a11 = $23; mu = $25
  if (n1 == 0 && n2 == 0 && (o1 != 0 || o2 != 0)) rej++
  if (sqrt(n1 * n1 + n2 * n2) >= 0.999 * mu * fn && fn > 0) edge++
  d = n1 - o1; if (d < 0) d = -d; e = n2 - o2; if (e < 0) e = -e; if (d > mch) mch = d; if (e > mch) mch = e
  det = mu * mu * mu * mu * (a00 * a11 - a01 * a10); if (mdet < 0 || det < mdet) mdet = det
  next }
/^NOSLIP_SWEEP / { if ($3 == 0 && after) flush(); sw = $3 + 1; if ($3 == 0) imp0 = $5; impl = $5; after = 1; next }
END { if (sw > 0) flush() }'
mkdir -p "$O/rel" "$O/off" "$O/trace"
for dt in 0.000285 0.00114; do
  for nn in 5 9; do
    p=stack${nn}_$dt
    unset MUJOCO_NOSLIP_TRACE
    # shellcheck disable=SC2086
    "$W/p67rel/tools/mjc_stack" "$O/rel/$p" dt=$dt n=$nn secs=2 $KCUBE $REC > "$O/rel/$p.stats" 2> "$O/rel/$p.err"
    # shellcheck disable=SC2086
    "$W/p67tr/tools/mjc_stack" "$O/off/$p" dt=$dt n=$nn secs=2 $KCUBE $REC > "$O/off/$p.stats" 2> "$O/off/$p.err"
    export MUJOCO_NOSLIP_TRACE=1
    # shellcheck disable=SC2086
    { "$W/p67tr/tools/mjc_stack" "$O/trace/$p" dt=$dt n=$nn secs=2 $KCUBE $REC 2>&1 1>&3 | awk "$SUM" > "$O/trace/$p.steps"; } 3> "$O/trace/$p.stats"
    unset MUJOCO_NOSLIP_TRACE
    echo "$p played $(date -u +%FT%TZ)" >> "$O/progress.txt"
  done
done
rm -rf "$W/p67rel" "$W/p67tr"
{
  echo "per step in trace/*.steps: step sweeps first_improvement last_improvement contacts zero_friction_returns_all_sweeps at_cone_edge_last_sweep largest_friction_change_last_sweep_N smallest_scaled_det"
  s=0; n=0; u=0
  for f in $(cd "$O/rel" && ls | grep -v '\.stats$' | grep -v '\.err$'); do n=$((n + 1)); cmp -s "$O/rel/$f" "$O/off/$f" && s=$((s + 1)); cmp -s "$O/off/$f" "$O/trace/$f" && u=$((u + 1)); done
  echo "safe when off: $s of $n files byte for byte as released; traced byte for byte as untraced: $u of $n; the trace build's stderr with the switch unset: $(cat "$O"/off/*.err | wc -l | tr -d ' ') lines"
  for dt in 0.000285 0.00114; do
    for nn in 5 9; do
      p=stack${nn}_$dt; d=$(awk -v t="$dt" 'BEGIN { print t * 1e9 }')
      tilt=$(cat "$O/trace/${p}"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }')
      onset=$(for f in "$O/trace/${p}"_*_tilt.txt; do awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > 100) { print $1; exit } }' "$f"; done | sort -n | head -1)
      echo "$p most_tilt_urad $tilt first_step_any_cube_past_100_urad ${onset:-none} $(awk -v d="$d" '
        { n++; if ($2 >= 100) full++; if ($6 > 0) rj++; if ($7 > 0) ed++; s += $2; if ($5 > c) c = $5
          if (md == "" || $9 < md) md = $9; if ($4 > mi) mi = $4 }
        END { printf "steps %d sweeps_mean %.2f steps_at_100_sweeps %d contacts_most %d steps_with_zero_friction_return %d steps_with_cone_edge %d largest_last_improvement %.3g smallest_scaled_det %.3g", n, s / n, full, c, rj, ed, mi, md }' "$O/trace/$p.steps")"
    done
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
