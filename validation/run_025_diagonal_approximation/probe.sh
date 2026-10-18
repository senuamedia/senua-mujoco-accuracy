#!/usr/bin/env bash
# Run 025, design probe (not registered): the solver's diagonal approximation (known issue M12). MuJoCo sets each
# contact's softness from an approximation of the constraint's inverse inertia that it computes once, in the pose a
# scene is written in (qpos0: body_invweight0, engine_setconst.c), not in the pose the bodies are in. Physics has an
# answer that does not depend on how a scene is written: the same arm, in the same place, at rest, does the same thing
# whatever pose its file was written in. The rig tools/mjc_arm.c plays a two-link arm whose tip, a ball, touches the
# ground, written three ways:
#   native    in the pose it starts in
#   straight  with both joints at 0 (the arm straight out, level)
#   folded    with the shoulder at 0 and the elbow at 2.5 rad
# The arm starts in the same place, at rest, in all three. Two starting poses (A: shoulder 0.5, elbow 1.2 rad; B: 1.1
# and -0.6), two scenes (rest: the ball set down touching the ground, 2 s; drop: the ball 10 mm above it, 1 s), two
# steps (2 ms, MuJoCo's default, and 0.5 ms), three configurations of MuJoCo's own options:
#   defaults      MuJoCo's defaults
#   converged     tolerance 1e-10 and 1,000 iterations, to see whether a tighter solve changes anything
#   recommended   the elliptic cone with 10 noslip iterations (Study 2)
# Each play is read by Senua AI's measure: sx_contact rest (the ground's mean force on the ball over the second half),
# creep (the ball's mean speed along x over the second half), bounce (the drop: the rebound per 10,000 of the drop),
# pull (the lowest ground force), and between two writings of one scene ends (how far apart they end: the ball's height,
# and its speed) and gap (the summed and the largest height difference over the play, at the play's own step).
# usage: probe.sh <sx_contact binary>   (repository root, tools/mjc_arm built)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"; O=validation/run_025_diagonal_approximation; W=$O/runs; mkdir -p $W
S=$W/stats.txt; : > $S; R=$O/reading.txt; : > $R
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
for cfg in defaults converged recommended; do
  case $cfg in
    defaults) set -- ;;
    converged) set -- tolerance=1e-10 iterations=1000 ;;
    recommended) set -- cone=elliptic noslip=10 ;;
  esac
  for pose in A B; do
    case $pose in A) P=0.5,1.2 ;; B) P=1.1,-0.6 ;; esac
    for scene in rest drop; do
      case $scene in rest) SC="h0=0 secs=2" ;; drop) SC="h0=0.01 secs=1" ;; esac
      for dt in 0.002 0.0005; do
        for wr in native straight folded; do
          case $wr in native) P0=$P ;; straight) P0=0,0 ;; folded) P0=0,2.5 ;; esac
          f=$W/${cfg}_${pose}_${scene}_${dt}_$wr.txt
          # shellcheck disable=SC2086
          tools/mjc_arm $f dt=$dt pose=$P pose0=$P0 $SC "$@" | sed "s/^STATS/STATS run $(basename $f .txt)/" >> $S
          st=$(grep "^STATS run $(basename $f .txt) " $S)
          if [ $scene = rest ]; then
            echo "$cfg $pose $scene $dt $wr | $("$B" rest $f | tail -1) | $("$B" creep $f | tail -1) | $("$B" pull $f | tail -1) | invweight0 $(fld "$st" invweight0_link2) at_start $(fld "$st" invweight_link2_at_start) most_iterations $(fld "$st" most_iterations) at_iteration_limit $(fld "$st" at_iteration_limit) warnings $(fld "$st" warnings)" >> $R
          else
            echo "$cfg $pose $scene $dt $wr | $("$B" bounce $f | tail -1) | $("$B" pull $f | tail -1) | invweight0 $(fld "$st" invweight0_link2) at_start $(fld "$st" invweight_link2_at_start) most_iterations $(fld "$st" most_iterations) at_iteration_limit $(fld "$st" at_iteration_limit) warnings $(fld "$st" warnings)" >> $R
          fi
        done
        n=$W/${cfg}_${pose}_${scene}_${dt}_native.txt; ns=$(awk -v d=$dt 'BEGIN { printf "%d", d * 1e9 + 0.5 }')
        for wr in straight folded; do
          g=$W/${cfg}_${pose}_${scene}_${dt}_$wr.txt
          echo "$cfg $pose $scene $dt native against $wr | $("$B" ends $n $g | tail -1) | $("$B" gap $ns $n $g | tail -1)" >> $R
        done
      done
    done
  done
done
date -u +%FT%TZ > $O/finished.txt
