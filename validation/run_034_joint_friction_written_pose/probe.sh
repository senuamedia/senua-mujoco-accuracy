#!/usr/bin/env bash
# Run 034, design probe (not registered): does finding F10 reach joint friction? MuJoCo sets a joint's dry friction
# (frictionloss) row's softness from the joint's inverse weight, dof_invweight0, frozen at qpos0, as for a joint limit
# (run 032). The rig tools/mjc_arm.c gains jointfriction=NM, MuJoCo's frictionloss on both hinges; nothing when unset,
# which step 0 checks byte for byte against runs 025 and 032.
#   held    the arm released at rest, its ball 1 m above the ground, both hinges with 6 N m of dry friction, more than
#           gravity's torque on either (at most about 4.6 N m at the shoulder): pose E (shoulder 0, elbow 0.6 rad) and
#           pose F (0.4 and 1.0), 2 s. The right answer: it stays where it was put, in every writing
#   written native, straight (0, 0) and folded (0, 2.5); at 2 ms and 0.5 ms; under MuJoCo's defaults and with its
#   diagexact flag
# Each play is read by Senua AI's measure: sx_contact creep (the ball's mean speed along x over the second half), and
# between two writings ends (how far apart the ball ends, its height and speed) and gap.
# usage: probe.sh <sx_contact binary>   (repository root, tools/mjc_arm built)
set -u
B="${1:?usage: probe.sh <sx_contact binary>}"; O=validation/run_034_joint_friction_written_pose; W=$O/runs; mkdir -p $W $O/step0
S=$W/stats.txt; : > $S; R=$O/reading.txt; : > $R
line() { "$B" "$@" | tail -1 | sed 's/ dt_ns [0-9]*//'; }
# step 0: the rig unchanged without joint friction: run 025's 24 plays and run 032's 24 plays
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
  for cfg in defaults diagexact; do
    if [ $cfg = diagexact ]; then set -- diagexact=1; else set --; fi
    for pose in E F; do
      case $pose in E) P=0,0.6; L=-2,0.6 ;; F) P=0.4,1.0; L=-2,1.0 ;; esac
      for dt in 0.002 0.0005; do for wr in native straight folded; do
        case $wr in native) P0=$P ;; straight) P0=0,0 ;; folded) P0=0,2.5 ;; esac
        g=${cfg}_${pose}_${dt}_$wr.txt
        tools/mjc_arm $O/step0/$g dt=$dt pose=$P pose0=$P0 elbowlimit=$L h0=1 secs=2 "$@" > /dev/null
        if cmp -s $O/step0/$g validation/run_032_limit_written_pose/runs/$g; then echo "SAME run_032 $g"; else echo "DIFFERS run_032 $g"; fi
      done; done
    done
  done
} > $O/identity.txt
rm -rf $O/step0
for cfg in defaults diagexact; do
  if [ $cfg = diagexact ]; then set -- diagexact=1; else set --; fi
  for pose in E F; do
    case $pose in E) P=0,0.6 ;; F) P=0.4,1.0 ;; esac
    for dt in 0.002 0.0005; do
      for wr in native straight folded; do
        case $wr in native) P0=$P ;; straight) P0=0,0 ;; folded) P0=0,2.5 ;; esac
        f=$W/${cfg}_${pose}_${dt}_$wr.txt
        tools/mjc_arm $f dt=$dt pose=$P pose0=$P0 jointfriction=6 h0=1 secs=2 "$@" | sed "s/^STATS/STATS run $(basename $f .txt)/" >> $S
        echo "$cfg $pose $dt $wr | $(line creep $f)" >> $R
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
