#!/usr/bin/env bash
# Run 100: a design probe, not registered: it finds where to look and decides nothing. Run 098: with noslip re-solving
# the normal forces (patches/in_design/noslip_normal.diff, setn) every free cube holds, but under the configuration
# stacks offset 5 mm a cube turn faster than without it (set5); its stacks stop at noslip's tolerance (at most 51
# iterations a step, never 100), and held to 1e-15 at 1,000 iterations they come nearly to rest. Is it the tolerance?
# At 100 noslip iterations (the configuration's), MuJoCo's noslip_tolerance at 1e-8, 1e-10, 1e-12 and 1e-15, set5 and
# setn, in run 098's build (p98): run 093's stacks offset 1 and 5 mm, of run 078's cube and Study 16's, at 1.14 and 0.285
# ms, played 6 s; and Study 20's free cube b (condim 3) pushed along 0 degrees at 0.95 of its limit, at 1.277 and 0.319 ms.
# Readings: Senua AI's measure, `final` on each cube's tilt file, `creep` on the free cube; the solver's iterations.
# usage: probe.sh <sx_contact, the measure> <work folder>   (repository root, on the cloud machine; the work folder
#        holds run 098's build in mujoco-p98-build)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_100_noslip_normal_tolerance"; P98="$W/mujoco-p98-build"; mkdir -p "$O"; date -u +%FT%TZ > "$O/played_at.txt"
switches() {  # <5 or n>
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT MUJOCO_NOSLIP_EQUALITY MUJOCO_NOSLIP_NORMAL
  export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1
  if [ "$1" = n ]; then export MUJOCO_NOSLIP_NORMAL=1; fi
}
X=$(mktemp -d); mkdir -p "$X/p" "$X/b" && cp -R "$R/tools" "$X/p/"
( cd "$X/p" && for r in mjc_stack mjc_contact; do MUJOCO_DIR=$P98 tools/build_rig.sh $r > /dev/null 2>&1 || echo "rig $r FAILED"; done )
fin() { "$B" final "$1" < /dev/null | tail -1 | awk '{ for (i = 1; i < NF; i++) { if ($i == "angle_urad") a = $(i + 1); if ($i == "speed_urads") s = $(i + 1) } } END { printf "tilt_urad %s turn_urad_s %s", a, s }'; }
its() { grep "run $1 " "$O/stats.txt" | grep -o 'most_iterations [0-9]* at_iteration_limit [0-9]*'; }
: > "$O/stats.txt"
{
  for arm in set5:5 setn:n; do
    an=${arm%%:*}; sw=${arm#*:}; switches $sw
    for tol in 1e-8 1e-10 1e-12 1e-15; do
      NO="cone=elliptic noslip=100 noslip_tolerance=$tol"
      for cube in k078:"mass=0.442 radius=0.0424 mu=0.524" k016:"mass=0.596 radius=0.0405 mu=0.528"; do
        cn=${cube%%:*}; cv=${cube#*:}
        for dt in 0.00114 0.000285; do for sh in 0.001 0.005; do
          q=${an}_${tol}_${cn}_${sh}_$dt
          # shellcheck disable=SC2086
          "$X/p/tools/mjc_stack" "$X/b/$q" dt=$dt n=3 shift=$sh secs=6 $cv $NO | sed "s|^STATS|STATS run $q|" >> "$O/stats.txt"
          echo "$an tol $tol stack $cn shift $sh $dt 6s | cube 1 $(fin "$X/b/${q}_1_tilt.txt") | cube 2 $(fin "$X/b/${q}_2_tilt.txt") | cube 3 $(fin "$X/b/${q}_3_tilt.txt") | $(its "$q")"
        done; done
      done
      for dt in 0.001277 0.00031925; do
        q=${an}_${tol}_free_$dt; pu=$(awk 'BEGIN { printf "%.6f", 0.95 * 0.819 * 0.734 * 9.8 }')
        # shellcheck disable=SC2086
        "$X/p/tools/mjc_contact" "$X/b/$q.txt" dt=$dt h0=0 mass=0.819 radius=0.0316 mu=0.734 push=$pu pushat=0.4 secs=1.6 dir=0 lock=0 $NO | sed "s|^STATS|STATS run $q|" >> "$O/stats.txt"
        echo "$an tol $tol free cube b $dt at 0.95 | $("$B" creep "$X/b/$q.txt" < /dev/null | tail -1 | grep -o 'mean_speed_ums [-0-9]*') | $(its "$q")"
      done
    done
  done
} > "$O/reading.txt"
rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished.txt"
