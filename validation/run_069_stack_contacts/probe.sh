#!/usr/bin/env bash
# Run 069: a design probe, not registered: it finds where to look and decides nothing. Run 067 traced noslip on the
# stacks that tilt under Senua AI's configuration at 0.285 ms (issue 21): noslip converges every step to round-off, and
# the tilt starts with a kick in one step, in the stack of 5 at the first change in the number of contacts after it
# settles; in the stack of 9 the first change kicked it upward without a tilt, and its tilt began at a step with the same
# number. What changes in the contacts? The stack rig's new setting, contacts=FILE (tools/mjc_stack.c; unchanged
# without it), writes every contact a step solves with: its two geoms, its position, its distance and its normal.
# MuJoCo 3.16.0 as released, run 063's stacks (Study 10's cube) of 5 and 9, 2 s: at 0.285 ms under the configuration
# (the elliptic cone, 100 noslip iterations), under the elliptic cone alone and under MuJoCo's defaults; at 1.14 ms under
# the configuration. Checked first: the rig as it was before this setting (kept here as mjc_stack_before.c) and
# the rig now without it play the same files byte for byte, and with it the plays are byte for byte as without.
# Readings: per pair of geoms (the ground is geom 0, the lowest cube 1), the number of contacts each step; each change in
# it after the first 30 steps, the first eight with the contacts before and after (x, y and distance, um); each pair's
# mean distance at step 1000 and at the last step; each cube's tilt, the first step any cube is past 100 urad.
# usage: probe.sh <work folder>   (repository root, on the cloud machine; the work folder holds the release in
#        mujoco-3.16.0)
set -u
W="$(cd "${1:?usage: see the header}" && pwd)"; R="$(pwd)"; O="$R/validation/run_069_stack_contacts"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
REL="$W/mujoco-3.16.0"; KCUBE="mass=0.442 radius=0.0424 mu=0.524"
X="$W/p69"; rm -rf "$X"; mkdir -p "$X/old/tools" && cp -R "$R/tools" "$X/" && cp -R "$R/tools/." "$X/old/tools/"
cp "$O/mjc_stack_before.c" "$X/old/tools/mjc_stack.c"
( cd "$X" && MUJOCO_DIR=$REL tools/build_rig.sh mjc_stack > /dev/null 2>&1 )
( cd "$X/old" && MUJOCO_DIR=$REL tools/build_rig.sh mjc_stack > /dev/null 2>&1 )
echo "rig $(sha256sum "$R/tools/mjc_stack.c" | cut -c1-16); the rig before $(sha256sum "$X/old/tools/mjc_stack.c" | cut -c1-16)" > "$O/rig_check.txt"
mkdir -p "$O/plays" "$O/check"
# the identity checks: the old rig and the new without the setting; the new with it
for p in rec:cone=elliptic\ noslip=100 def:; do
  n=${p%%:*}; opts=${p#*:}
  # shellcheck disable=SC2086
  "$X/old/tools/mjc_stack" "$X/o_$n" dt=0.000285 n=5 secs=2 $KCUBE $opts > "$X/o_$n.stats"
  # shellcheck disable=SC2086
  "$X/tools/mjc_stack" "$X/w_$n" dt=0.000285 n=5 secs=2 $KCUBE $opts > "$X/w_$n.stats"
done
{ s=0; c=0
  for n in rec def; do
    for k in 1 2 3 4 5; do for t in "" _tilt; do c=$((c + 1)); cmp -s "$X/o_${n}_$k$t.txt" "$X/w_${n}_$k$t.txt" && s=$((s + 1)); done; done
    c=$((c + 1)); cmp -s "$X/o_$n.stats" "$X/w_$n.stats" && s=$((s + 1))
  done
  echo "the rig before and the rig now without contacts=: $s of $c files byte for byte"; } > "$O/check/identity.txt"
SUM='
function flush(st,   g1, g2, p) {
  for (g1 = 0; g1 <= 20; g1++) for (g2 = 0; g2 <= 20; g2++) { p = g1 "-" g2
    if (!(p in seen)) continue
    if (st > 30 && cnt[p] != pc[p]) { evn++; if (ev < 8) { ev++
      printf "EVENT %d step %d pair %s: %d -> %d contacts\n  before:%s\n  after:%s\n", ev, st, p, pc[p], cnt[p], prev[p], cur[p] } }
    if (st == 1000 || st == last) { if (cnt[p] > 0) printf "DEPTH step %d pair %s contacts %d mean_distance_um %.3f\n", st, p, cnt[p], dsum[p] / cnt[p] / 1000 }
    prev[p] = cur[p]; pc[p] = cnt[p]; cur[p] = ""; cnt[p] = 0; dsum[p] = 0 } }
{ if ($1 != cs) { if (cs != "") flush(cs); cs = $1 }
  p = $2 "-" $3; seen[p] = 1; cnt[p]++; dsum[p] += $7
  cur[p] = cur[p] sprintf(" (%.1f, %.1f, %.2f)", $4 / 1000, $5 / 1000, $7 / 1000) }
END { last = cs; flush(cs); printf "CHANGES after step 30: %d\n", evn }'
for p in rec_0.000285:0.000285:cone=elliptic\ noslip=100 ell_0.000285:0.000285:cone=elliptic def_0.000285:0.000285: rec_0.00114:0.00114:cone=elliptic\ noslip=100; do
  n=${p%%:*}; rest=${p#*:}; dt=${rest%%:*}; opts=${rest#*:}
  for nn in 5 9; do
    q=stack${nn}_$n
    # shellcheck disable=SC2086
    "$X/tools/mjc_stack" "$O/plays/$q" dt=$dt n=$nn secs=2 $KCUBE $opts contacts="$X/$q.contacts" > "$O/plays/$q.stats"
    if [ $n = rec_0.000285 ] && [ $nn = 5 ]; then
      # shellcheck disable=SC2086
      "$X/tools/mjc_stack" "$X/u_$q" dt=$dt n=$nn secs=2 $KCUBE $opts > "$X/u_$q.stats"
      { s=0; c=0; for k in 1 2 3 4 5; do for t in "" _tilt; do c=$((c + 1)); cmp -s "$O/plays/${q}_$k$t.txt" "$X/u_${q}_$k$t.txt" && s=$((s + 1)); done; done
        c=$((c + 1)); cmp -s "$O/plays/$q.stats" "$X/u_$q.stats" && s=$((s + 1))
        echo "with contacts= and without: $s of $c files byte for byte"; } >> "$O/check/identity.txt"
    fi
    awk "$SUM" "$X/$q.contacts" > "$O/plays/$q.events"
    gzip -n -9 -c "$X/$q.contacts" > "$O/plays/$q.contacts.gz"
    echo "$q played $(date -u +%FT%TZ)" >> "$O/progress.txt"
  done
done
rm -rf "${X:?}"
{
  cat "$O/check/identity.txt"
  for p in rec_0.000285 ell_0.000285 def_0.000285 rec_0.00114; do
    for nn in 5 9; do
      q=stack${nn}_$p
      tilt=$(cat "$O/plays/${q}"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }')
      onset=$(for f in "$O/plays/${q}"_*_tilt.txt; do awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > 100) { print $1; exit } }' "$f"; done | sort -n | head -1)
      first=$(grep -m1 '^EVENT' "$O/plays/$q.events" | awk '{ print $4 }')
      echo "$q most_tilt_urad $tilt first_step_any_cube_past_100_urad ${onset:-none} $(grep '^CHANGES' "$O/plays/$q.events") first_change_step ${first:-none} most_contacts $(grep -o 'most_contacts [0-9]*' "$O/plays/$q.stats" | awk '{ print $2 }')"
      grep '^DEPTH step 1000' "$O/plays/$q.events" | awk -v q="$q" '{ printf "%s depth at step 1000, pair %s: %s contacts, %s um\n", q, $5, $7, $9 }'
    done
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
