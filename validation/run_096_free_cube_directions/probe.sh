#!/usr/bin/env bash
# Run 096: a design probe, not registered: it finds where to look and decides nothing. Issue 1's one open case: Study
# 20's free cube b (0.819 kg, half-size 0.0316 m, friction 0.734, condim 3), pushed square to a face at 0.95 of its
# friction limit at 1.277 ms, creeps in Senua AI's set. Run 089's trace found its two back contacts at their friction
# limit and the two front ones with room, and gave each contact's friction as a size only: friction pushing sideways in
# pairs that cancel would never show as slip and would use up the back contacts' room. The contact rig gains
# tracedir=1: each contact's entry in the trace also gives the friction in the ground plane, along and across the push,
# and the slip of the cube's material point at the contact, along and across. The cube, free, pushed at 0.95, 0.75 and
# 0.5 of its limit along 0 degrees, under the configuration (the elliptic cone, 100 noslip iterations), in Study 21's
# build of the set (mujoco-s21v2-build, its five switches set) and in Google DeepMind's Linux release of MuJoCo 3.16.0,
# with the trace and tracedir. Readings: Senua AI's corrected measure, `creep`; the traces kept whole.
# The rig checked first, in the set: the rig before tracedir (mjc_contact_before.c) and the rig now, the trace set and
# tracedir unset, compared byte for byte (play, trace, statistics); and the rig now with tracedir=1, whose play and
# statistics must be the same bytes as without it.
# usage: probe.sh <sx_contact, the corrected measure> <work folder>   (repository root, on the cloud machine)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_096_free_cube_directions"; V="$W/mujoco-s21v2-build"; REL="$W/mujoco-3.16.0"
mkdir -p "$O/p"; date -u +%FT%TZ > "$O/played_at.txt"
switches() {  # <0 or 5>
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT MUJOCO_NOSLIP_EQUALITY
  if [ "$1" -ge 5 ]; then export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1; fi
}
X=$(mktemp -d)
for a in v:$V r:$REL; do
  n=${a%%:*}; mj=${a#*:}; mkdir -p "$X/$n" && cp -R "$R/tools" "$X/$n/" && cp "$O/mjc_contact_before.c" "$X/$n/tools/"
  ( cd "$X/$n" && for r in mjc_contact mjc_contact_before; do MUJOCO_DIR=$mj tools/build_rig.sh $r > /dev/null 2>&1 || echo "rig $r FAILED for $n"; done )
done
CB="mass=0.819 radius=0.0316 mu=0.734"; REC="cone=elliptic noslip=100"
push() { awk -v f="$1" 'BEGIN { printf "%.6f", f * 0.819 * 0.734 * 9.8 }'; }
switches 5
P95=$(push 0.95)
"$X/v/tools/mjc_contact_before" "$X/i_b.txt" dt=0.001277 h0=0 $CB push=$P95 pushat=0.4 secs=1.6 dir=0 lock=0 $REC trace="$X/i_b.trace" > "$X/i_b.stats"
"$X/v/tools/mjc_contact" "$X/i_n.txt" dt=0.001277 h0=0 $CB push=$P95 pushat=0.4 secs=1.6 dir=0 lock=0 $REC trace="$X/i_n.trace" > "$X/i_n.stats"
"$X/v/tools/mjc_contact" "$X/i_d.txt" dt=0.001277 h0=0 $CB push=$P95 pushat=0.4 secs=1.6 dir=0 lock=0 $REC trace="$X/i_d.trace" tracedir=1 > "$X/i_d.stats"
{ for k in txt trace stats; do
    cmp -s "$X/i_b.$k" "$X/i_n.$k" && echo "the rig before and now, tracedir unset, $k: the same bytes" || echo "the rig before and now, tracedir unset, $k: DIFFERENT"
  done
  for k in txt stats; do
    cmp -s "$X/i_b.$k" "$X/i_d.$k" && echo "tracedir=1 against the rig before, $k: the same bytes" || echo "tracedir=1 against the rig before, $k: DIFFERENT"
  done; } > "$O/identity.txt"
: > "$O/p/stats.txt"
{
  echo "the trace with tracedir: <step> <yaw urad> <tilt urad> <contacts>, then a contact: <along the push, um from the cube's centre> <across, um> <normal mN> <friction mN> <friction over its limit, ppm> <friction along the push, mN> <across, mN> <slip along, um/s> <across, um/s>"
  for arm in set:v:5 rel:r:0; do
    an=${arm%%:*}; rest=${arm#*:}; rn=${rest%%:*}; sw=${rest#*:}; switches $sw
    for fr in 0.95 0.75 0.5; do
      f="free_${an}_$fr"; pu=$(push $fr)
      "$X/$rn/tools/mjc_contact" "$O/p/$f.txt" dt=0.001277 h0=0 $CB push=$pu pushat=0.4 secs=1.6 dir=0 lock=0 $REC trace="$O/p/$f.trace" tracedir=1 | sed "s|^STATS|STATS run $f|" >> "$O/p/stats.txt"
      echo "$f | $("$B" creep "$O/p/$f.txt" | tail -1 | grep -o 'mean_speed_ums [-0-9]*')"
    done
  done
} > "$O/reading.txt"
switches 0
rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished.txt"
