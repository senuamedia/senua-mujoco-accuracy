#!/usr/bin/env bash
# Run 098, step 2: written after step 1's readings and pushed before its plays. Step 1: with the normal rows re-solved
# (setn) every free cube holds, but stacks offset 5 mm a cube turn at up to 37,357 urad/s at the end, where without it
# (set5) they turn at 8 to 85. Does it hold with noslip held to convergence? Run 093 found set5's offset stacks still
# turning held to convergence. The stacks offset 1 and 5 mm, of run 078's cube and Study 16's, at 1.14 and 0.285 ms,
# played 2, 4 and 6 s, under the elliptic cone with 1,000 noslip iterations at a tolerance of 1e-15, set5 and setn, in
# step 1's build (p98). Read by Senua AI's corrected measure, `final` on each cube's tilt file; the solver's iterations.
# usage: probe_2.sh <sx_contact, the corrected measure> <work folder>   (repository root, on the cloud machine; the work
#        folder holds step 1's build in mujoco-p98-build)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_098_noslip_normal"; P98="$W/mujoco-p98-build"; date -u +%FT%TZ > "$O/played_at_2.txt"
switches() {  # <5 or n>
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT MUJOCO_NOSLIP_EQUALITY MUJOCO_NOSLIP_NORMAL
  export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1
  if [ "$1" = n ]; then export MUJOCO_NOSLIP_NORMAL=1; fi
}
X=$(mktemp -d); mkdir -p "$X/p" && cp -R "$R/tools" "$X/p/"
( cd "$X/p" && MUJOCO_DIR=$P98 tools/build_rig.sh mjc_stack > /dev/null 2>&1 || echo "rig FAILED" )
fin() { "$B" final "$1" < /dev/null | tail -1 | awk '{ for (i = 1; i < NF; i++) { if ($i == "angle_urad") a = $(i + 1); if ($i == "speed_urads") s = $(i + 1) } } END { printf "tilt_urad %s turn_urad_s %s", a, s }'; }
CONV="cone=elliptic noslip=1000 noslip_tolerance=1e-15"
mkdir -p "$X/b"; : > "$O/stats_stacks_2.txt"
{
  for arm in set5:5 setn:n; do
    an=${arm%%:*}; sw=${arm#*:}; switches $sw
    for cube in k078:"mass=0.442 radius=0.0424 mu=0.524" k016:"mass=0.596 radius=0.0405 mu=0.528"; do
      cn=${cube%%:*}; cv=${cube#*:}
      for dt in 0.00114 0.000285; do for sh in 0.001 0.005; do for secs in 2 4 6; do
        q=b/${an}_${cn}_${sh}_${dt}_${secs}s
        # shellcheck disable=SC2086
        "$X/p/tools/mjc_stack" "$X/$q" dt=$dt n=3 shift=$sh secs=$secs $cv $CONV | sed "s|^STATS|STATS run $q|" >> "$O/stats_stacks_2.txt"
        echo "$an n1000 $cn shift $sh $dt ${secs}s | cube 1 $(fin "$X/${q}_1_tilt.txt") | cube 2 $(fin "$X/${q}_2_tilt.txt") | cube 3 $(fin "$X/${q}_3_tilt.txt")"
      done; done; done
    done
  done
} > "$O/reading_stacks_2.txt"
rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished_2.txt"
