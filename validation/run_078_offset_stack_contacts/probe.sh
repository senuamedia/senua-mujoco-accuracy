#!/usr/bin/env bash
# Run 078: a design probe, not registered: it finds where to look and decides nothing. Issue 9 (F11): an offset stack
# leans. In run 075 and Study 16's dry run, a stack of 3 cubes each 1 mm over from the one below leans about 2.2 mrad
# under Senua AI's configuration (the elliptic cone, 100 noslip iterations), released and patched alike, its contacts
# changing hundreds of times; under MuJoCo's defaults it leans 86 urad and its contacts never change. What changes in its
# contacts? MuJoCo 3.16.0 as released, run 063's cube (Study 10's), the stack rig's contacts setting (run 069): stacks of
# 3 offset by 1 mm and by 17 mm a cube, 2 s, at 0.285 and 1.14 ms, under the configuration, under the elliptic cone
# alone, and under MuJoCo's defaults. Readings: per pair of geoms, each change in its number of contacts after step 30,
# the first eight with the contacts before and after (x, y and distance, um); each pair's mean distance at step 1000 and
# at the last step; each cube's tilt and the first step any cube is past 100 urad; the traces kept compressed.
# usage: probe.sh <work folder>   (repository root, on the cloud machine; the work folder holds the release in
#        mujoco-3.16.0)
set -u
W="$(cd "${1:?usage: see the header}" && pwd)"; R="$(pwd)"; O="$R/validation/run_078_offset_stack_contacts"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
REL="$W/mujoco-3.16.0"; KCUBE="mass=0.442 radius=0.0424 mu=0.524"
X="$W/p78"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
( cd "$X" && MUJOCO_DIR=$REL tools/build_rig.sh mjc_stack > /dev/null 2>&1 )
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
mkdir -p "$O/plays"
for p in rec:cone=elliptic\ noslip=100 ell:cone=elliptic def:; do
  n=${p%%:*}; opts=${p#*:}
  for dt in 0.000285 0.00114; do
    for sh in 0.001 0.017; do
      q=offset${sh#0.}_${n}_$dt
      # shellcheck disable=SC2086
      "$X/tools/mjc_stack" "$O/plays/$q" dt=$dt n=3 shift=$sh secs=2 $KCUBE $opts contacts="$X/$q.contacts" > "$O/plays/$q.stats"
      awk "$SUM" "$X/$q.contacts" > "$O/plays/$q.events"
      gzip -n -9 -c "$X/$q.contacts" > "$O/plays/$q.contacts.gz"
      echo "$q played $(date -u +%FT%TZ)" >> "$O/progress.txt"
    done
  done
done
rm -rf "${X:?}"
{
  echo "the option sets: rec, the configuration (cone=elliptic noslip=100); ell, the elliptic cone alone; def, MuJoCo's defaults"
  for n in rec ell def; do
    for dt in 0.000285 0.00114; do
      for sh in 0.001 0.017; do
        q=offset${sh#0.}_${n}_$dt
        tilt=$(cat "$O/plays/${q}"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }')
        onset=$(for f in "$O/plays/${q}"_*_tilt.txt; do awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > 100) { print $1; exit } }' "$f"; done | sort -n | head -1)
        echo "$q most_tilt_urad $tilt first_step_past_100_urad ${onset:-none} $(grep '^CHANGES' "$O/plays/$q.events") first_change_step $(grep -m1 '^EVENT' "$O/plays/$q.events" | awk '{ print $4 }')"
        grep '^DEPTH step 1000' "$O/plays/$q.events" | sed 's/^/  /'
      done
    done
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
