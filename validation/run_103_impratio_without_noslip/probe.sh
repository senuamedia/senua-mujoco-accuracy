#!/usr/bin/env bash
# Run 103: a design probe, not registered: it finds where to look and decides nothing. Noslip's multi-contact
# instability (a free cube near its friction limit rocks and creeps, offset stacks keep turning; runs 093, 096) and its
# other costs (a joint equality broken, inverse dynamics that cannot agree; run 094) all come with noslip. Two designs
# that re-solve the normal forces in noslip's pass hold the free cube but leave stacks offset 5 mm turning (runs 098,
# 101). MuJoCo documents impratio, the ratio of the friction's impedance to the normal's under the elliptic cone, larger
# making friction harder; Study 11 found it cutting the creep roughly in proportion (under the elliptic cone, 89 um/s at
# 10). Can Senua AI's set hold without noslip? Senua AI's six validated patch files, every switch set (Study 22's build,
# mujoco-s22-build), three configurations: the set's (the elliptic cone, 100 noslip iterations); the elliptic cone with
# impratio 100 and no noslip; the elliptic cone with impratio 1,000 and no noslip. Plays:
#   Study 20's free cubes a and b (condim 3) pushed along 0 degrees at 0.95 of their limit, at 1.277 and 0.319 ms;
#   the cube Study 19 held from turning at 0.5 and 0.95 of its limit, Study 15's grip with box and mesh pads, Study 15's
#   arm set down and dropped in two poses, and held in the air by joint friction (5.15 N m) in two poses, at 1.71 and
#   0.4275 ms; run 093's stacks offset 1, 5 and 17 mm a cube and a straight stack of 10, of run 078's cube, at 1.14 ms,
#   6 s and 2 s; MuJoCo's box (16 s).
# Readings by Senua AI's measure: `creep`; `final` on each stacked cube's tilt and height; `fastest` over the box's last
# 160 steps; the solver's statistics.
# usage: probe.sh <sx_contact, the measure with fastest> <work folder>   (repository root, on the cloud machine; the
#        work folder holds Study 22's build in mujoco-s22-build)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_103_impratio_without_noslip"; P="$W/mujoco-s22-build"; mkdir -p "$O"; date -u +%FT%TZ > "$O/played_at.txt"
export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1 MUJOCO_NOSLIP_EQUALITY=1
X=$(mktemp -d); cp -R "$R/tools" "$X/"
( cd "$X" && for r in mjc_stack mjc_contact mjc_arm mjc_grip mjc_scene; do MUJOCO_DIR=$P tools/build_rig.sh $r > /dev/null 2>&1 || echo "rig $r FAILED"; done )
N="$X/tools"; A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"
cr() { "$B" creep "$1" < /dev/null | tail -1 | grep -o "mean_speed_ums [-0-9]*"; }
fin() { "$B" final "$1" < /dev/null | tail -1 | awk '{ for (i = 1; i < NF; i++) { if ($i == "angle_urad") a = $(i + 1); if ($i == "speed_urads") s = $(i + 1) } } END { printf "%s %s", a, s }'; }
LIM=$(awk 'BEGIN { printf "%.6f", 0.438 * 1.561 * 9.8 }')
: > "$O/stats.txt"; mkdir -p "$X/p"
{
  for cfg in set:"cone=elliptic noslip=100" imp100:"cone=elliptic impratio=100" imp1000:"cone=elliptic impratio=1000"; do
    cn=${cfg%%:*}; co=${cfg#*:}
    for cube in a:1.572:0.0474:0.61 b:0.819:0.0316:0.734; do
      c=${cube%%:*}; rest=${cube#*:}; ms=${rest%%:*}; rest=${rest#*:}; hs=${rest%%:*}; mu=${rest#*:}
      pu=$(awk -v m="$ms" -v u="$mu" 'BEGIN { printf "%.6f", 0.95 * m * u * 9.8 }')
      for dt in 0.001277 0.00031925; do
        f="$X/p/free_${cn}_${c}_$dt.txt"
        # shellcheck disable=SC2086
        "$N/mjc_contact" "$f" dt=$dt h0=0 mass=$ms radius=$hs mu=$mu push=$pu pushat=0.4 secs=1.6 dir=0 lock=0 $co | sed "s|^STATS|STATS run free_${cn}_${c}_$dt|" >> "$O/stats.txt"
        echo "$cn free cube $c 0.95 $dt | $(cr "$f")"
      done
    done
    for dt in 0.00171 0.0004275; do
      for fr in 0.5 0.95; do
        pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }'); f="$X/p/hold_${cn}_${fr}_$dt.txt"
        # shellcheck disable=SC2086
        "$N/mjc_contact" "$f" dt=$dt h0=0 mass=1.561 radius=0.0489 mu=0.438 push=$pu pushat=0.4 secs=1.6 dir=0 lock=1 $co | sed "s|^STATS|STATS run hold_${cn}_${fr}_$dt|" >> "$O/stats.txt"
        echo "$cn hold $fr $dt | $(cr "$f")"
      done
      for pad in box mesh; do
        f="$X/p/grip_${cn}_${pad}_$dt"
        # shellcheck disable=SC2086
        "$N/mjc_grip" "$f" dt=$dt offset=0.0092 pad=$pad mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61 $co | sed "s|^STATS|STATS run grip_${cn}_${pad}_$dt|" >> "$O/stats.txt"
        echo "$cn grip $pad $dt | $(cr "$f.txt")"
      done
      k=0
      for pose in 0.555,0.905 1.157,-0.378; do
        k=$((k + 1))
        for hp in rest:"h0=0.00043 secs=2" drop:"h0=0.0129 secs=3" jointfriction:"h0=1 secs=2 jointfriction=5.15"; do
          hn=${hp%%:*}; ho=${hp#*:}; f="$X/p/arm_${cn}_${hn}${k}_$dt.txt"
          # shellcheck disable=SC2086
          "$N/mjc_arm" "$f" dt=$dt pose=$pose pose0=$pose $A15 $ho $co | sed "s|^STATS|STATS run arm_${cn}_${hn}${k}_$dt|" >> "$O/stats.txt"
          echo "$cn arm $hn $k $dt | $(cr "$f")"
        done
      done
    done
    for sh in 0.001 0.005 0.017; do
      q="$X/p/offset_${cn}_$sh"
      # shellcheck disable=SC2086
      "$N/mjc_stack" "$q" dt=0.00114 n=3 shift=$sh secs=6 mass=0.442 radius=0.0424 mu=0.524 $co | sed "s|^STATS|STATS run offset_${cn}_$sh|" >> "$O/stats.txt"
      echo "$cn offset stack $sh 6s | cube 1 tilt $(fin "${q}_1_tilt.txt") | cube 2 tilt $(fin "${q}_2_tilt.txt") | cube 3 tilt $(fin "${q}_3_tilt.txt")"
    done
    q="$X/p/straight10_$cn"
    # shellcheck disable=SC2086
    "$N/mjc_stack" "$q" dt=0.00114 n=10 shift=0 secs=2 mass=0.442 radius=0.0424 mu=0.524 $co | sed "s|^STATS|STATS run straight10_$cn|" >> "$O/stats.txt"
    echo "$cn straight stack 10 2s | top cube height_nm speed_ums $(fin "${q}_10.txt") | top tilt $(fin "${q}_10_tilt.txt")"
    f="$X/p/box_$cn.txt"; sn=$(echo "$co" | sed 's/cone=elliptic //')
    # shellcheck disable=SC2086
    "$N/mjc_scene" "$f" scene="$R/validation/run_049_desaxce_v4/step2/scene.xml" body=box axis=1,0,0 secs=16 key=0 cone=elliptic $sn | sed "s|^STATS|STATS run box_$cn|" >> "$O/stats.txt"
    echo "$cn MuJoCo's box | $("$B" fastest "$f" 160 < /dev/null | tail -1 | grep -o 'fastest_ums [0-9]*')"
  done
} > "$O/reading.txt"
rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished.txt"
