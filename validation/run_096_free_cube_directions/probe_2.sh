#!/usr/bin/env bash
# Run 096, step 2: written after step 1's readings and pushed before its plays. Step 1 found the free cube's creep at
# 0.95 of its limit to be a cycle, not a steady slide: it rocks on its front edge (in the set its tilt swings 3.28 to
# 3.84 mrad, once each 300 steps), and all four contacts slip together in a pulse each cycle; the release rocks too, and
# at 0.75 its swings grow. Does noslip drive the cycle, and does it follow the step? The same cube and pushes (0.95 and
# 0.75 of its limit, along 0 degrees, free), in the set and released: under the elliptic cone with no noslip, and under
# the configuration (the elliptic cone, 100 noslip iterations) at a quarter of the step (0.31925 ms), with the trace and
# tracedir. Readings: Senua AI's corrected measure, `creep`; the traces kept whole.
# usage: probe_2.sh <sx_contact, the corrected measure> <work folder>   (repository root, on the cloud machine)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_096_free_cube_directions"; V="$W/mujoco-s21v2-build"; REL="$W/mujoco-3.16.0"
mkdir -p "$O/p2"; date -u +%FT%TZ > "$O/played_at_2.txt"
switches() {  # <0 or 5>
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT MUJOCO_NOSLIP_EQUALITY
  if [ "$1" -ge 5 ]; then export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1; fi
}
X=$(mktemp -d)
for a in v:$V r:$REL; do
  n=${a%%:*}; mj=${a#*:}; mkdir -p "$X/$n" && cp -R "$R/tools" "$X/$n/"
  ( cd "$X/$n" && MUJOCO_DIR=$mj tools/build_rig.sh mjc_contact > /dev/null 2>&1 || echo "rig FAILED for $n" )
done
CB="mass=0.819 radius=0.0316 mu=0.734"
push() { awk -v f="$1" 'BEGIN { printf "%.6f", f * 0.819 * 0.734 * 9.8 }'; }
: > "$O/p2/stats.txt"
{
  for arm in set:v:5 rel:r:0; do
    an=${arm%%:*}; rest=${arm#*:}; rn=${rest%%:*}; sw=${rest#*:}; switches $sw
    for cfg in "nonoslip:0.001277:cone=elliptic" "quarter:0.00031925:cone=elliptic noslip=100"; do
      cn=${cfg%%:*}; rest=${cfg#*:}; dt=${rest%%:*}; co=${rest#*:}
      for fr in 0.95 0.75; do
        f="free_${an}_${cn}_$fr"; pu=$(push $fr)
        # shellcheck disable=SC2086
        "$X/$rn/tools/mjc_contact" "$O/p2/$f.txt" dt=$dt h0=0 $CB push=$pu pushat=0.4 secs=1.6 dir=0 lock=0 $co trace="$O/p2/$f.trace" tracedir=1 | sed "s|^STATS|STATS run $f|" >> "$O/p2/stats.txt"
        echo "$f | $("$B" creep "$O/p2/$f.txt" | tail -1 | grep -o 'mean_speed_ums [-0-9]*')"
      done
    done
  done
} > "$O/reading_2.txt"
switches 0
rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished_2.txt"
