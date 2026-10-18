#!/usr/bin/env bash
# Run 032, design probe (not registered): does finding F10 reach joint limits? MuJoCo sets a joint limit's softness
# from the joint's inverse weight, dof_invweight0, which mj_setConst computes once in the pose a model is written in
# (qpos0), as it does a contact's from the bodies' (run 025). Run 029's patch in design changes contacts only. Physics
# has an answer that does not depend on how a scene is written: the same arm, started in the same place, swings the same.
# The rig tools/mjc_arm.c gains elbowlimit=LO,HI, the elbow's limits as elbow angles of the arm itself, so the same in
# every writing (the joint's range is LO - pose0 to HI - pose0); nothing when unset, which step 0 checks byte for byte
# against run 025.
#   swing   the arm released at rest, its ball 1 m above the ground (it never reaches it), its elbow on its upper limit,
#           which gravity presses it against: pose E (shoulder 0, elbow 0.6 rad), limits -2 and 0.6; pose F (shoulder
#           0.4, elbow 1.0), limits -2 and 1.0; 2 s
#   written native, straight (0, 0) and folded (0, 2.5); at 2 ms and 0.5 ms; under MuJoCo's defaults and with its
#   diagexact flag (the exact diagonal, in the current pose, for every constraint row, limits included; run 028)
# Each pair of writings is read by Senua AI's measure: sx_contact ends (how far apart the ball ends: its height, and the
# larger difference of its two speeds) and gap (the summed and the largest height difference over the play, at the
# play's own step).
# usage: probe.sh <sx_contact binary>   (repository root, tools/mjc_arm built)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"; O=validation/run_032_limit_written_pose; W=$O/runs; mkdir -p $W $O/step0
S=$W/stats.txt; : > $S; R=$O/reading.txt; : > $R
line() { "$B" "$@" | tail -1 | sed 's/ dt_ns [0-9]*//'; }
# step 0: the rig unchanged without the limit: run 025's 24 plays under the defaults
{
  for pose in A B; do
    case $pose in A) P=0.5,1.2 ;; B) P=1.1,-0.6 ;; esac
    for scene in rest drop; do
      case $scene in rest) SC="h0=0 secs=2" ;; drop) SC="h0=0.01 secs=1" ;; esac
      for dt in 0.002 0.0005; do for wr in native straight folded; do
        case $wr in native) P0=$P ;; straight) P0=0,0 ;; folded) P0=0,2.5 ;; esac
        g=defaults_${pose}_${scene}_${dt}_$wr.txt
        # shellcheck disable=SC2086
        tools/mjc_arm $O/step0/$g dt=$dt pose=$P pose0=$P0 $SC > /dev/null
        if cmp -s $O/step0/$g validation/run_025_diagonal_approximation/runs/$g; then echo "SAME run_025 $g"; else echo "DIFFERS run_025 $g"; fi
      done; done
    done
  done
} > $O/identity.txt
rm -rf $O/step0
for cfg in defaults diagexact; do
  if [ $cfg = diagexact ]; then set -- diagexact=1; else set --; fi
  for pose in E F; do
    case $pose in E) P=0,0.6; L=-2,0.6 ;; F) P=0.4,1.0; L=-2,1.0 ;; esac
    for dt in 0.002 0.0005; do
      for wr in native straight folded; do
        case $wr in native) P0=$P ;; straight) P0=0,0 ;; folded) P0=0,2.5 ;; esac
        f=$W/${cfg}_${pose}_${dt}_$wr.txt
        # shellcheck disable=SC2086
        tools/mjc_arm $f dt=$dt pose=$P pose0=$P0 elbowlimit=$L h0=1 secs=2 "$@" | sed "s/^STATS/STATS run $(basename $f .txt)/" >> $S
      done
      ns=$(awk -v d=$dt 'BEGIN { printf "%d", d * 1e9 + 0.5 }'); n=$W/${cfg}_${pose}_${dt}_native.txt
      for wr in straight folded; do
        g=$W/${cfg}_${pose}_${dt}_$wr.txt
        echo "$cfg $pose $dt native against $wr | $(line ends $n $g) | $(line gap $ns $n $g)" >> $R
      done
    done
  done
done
grep -o 'STATS run [^ ]*\|most_iterations [0-9]*\|at_iteration_limit [0-9]*\|warnings [0-9]*' $S | paste -d' ' - - - - > $O/solver.txt
date -u +%FT%TZ > $O/finished.txt
