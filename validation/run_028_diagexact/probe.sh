#!/usr/bin/env bash
# Run 028, design probe (not registered): MuJoCo's own remedy for finding F10. MuJoCo 3.16.0 has an enable flag,
# diagexact, which replaces the diagonal approximation frozen in the written pose (qpos0) with the exact diagonal of
# the constraint inertia, J inv(M) J', in the current pose (XMLreference.rst, option/flag/diagexact; computation,
# "Diagonal approximation"). The four rigs gain a setting diagexact=1 that sets it, and nothing else when unset.
#   step 0    the rigs unchanged without it: run 025's 24 plays under the defaults, run 026's stack of ten and slides
#             under the defaults, run 027's grip under the defaults at 2 ms, and both of the first deep dive's contact
#             suites, played again and compared byte for byte with the record's: the suites with Study 3's release arm
#             (run 023), the latest plays the unchanged rigs made (the record's suites/2/defaults keeps run 008's
#             two-cube plays, made before run 009 corrected the pair rig's frictionless ground)
#   arm       run 025's scenes (two poses, rest and drop, 2 and 0.5 ms, written native, straight and folded) with
#             diagexact, under the defaults and with the elliptic cone and 10 noslip iterations: do the three writings
#             now agree?
#   stack     run 026's scenes (stacks of 3, 5 and 10, the offset stack, the slide on the ground and on a box face) with
#             diagexact, under the same two configurations
#   grip      run 027's grip (box and mesh pads, at the centre and 10 mm off) with diagexact, the same two
#             configurations, at 2 ms
#   suites    both of the first deep dive's contact suites with diagexact, and with the elliptic cone, noslip and
#             diagexact: suite 1 read by the first deep dive's own runner (its ten tests), suite 2 as run 008 read it
# Every play is read by Senua AI's measure, as runs 008 and 025 to 027 read theirs.
# usage: probe.sh <folder holding sx_contact and sx_contact_suite.sh>   (repository root; tools/mjc_contact, mjc_pair,
#        mjc_arm, mjc_stack and mjc_grip built)
set -u
M="${1:?usage: probe.sh <folder holding sx_contact and sx_contact_suite.sh>}"; B="$M/sx_contact"
O=validation/run_028_diagexact; W=$O/runs; mkdir -p $W $O/step0; S=$W/stats.txt; : > $S
line() { "$B" "$@" | tail -1 | sed 's/ dt_ns [0-9]*//'; }
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
# ---- step 0: the rigs unchanged when diagexact is not given
{
  R25=validation/run_025_diagonal_approximation/runs
  for pose in A B; do
    case $pose in A) P=0.5,1.2 ;; B) P=1.1,-0.6 ;; esac
    for scene in rest drop; do
      case $scene in rest) SC="h0=0 secs=2" ;; drop) SC="h0=0.01 secs=1" ;; esac
      for dt in 0.002 0.0005; do for wr in native straight folded; do
        case $wr in native) P0=$P ;; straight) P0=0,0 ;; folded) P0=0,2.5 ;; esac
        g=defaults_${pose}_${scene}_${dt}_$wr.txt
        # shellcheck disable=SC2086
        tools/mjc_arm $O/step0/$g dt=$dt pose=$P pose0=$P0 $SC > /dev/null
        if cmp -s $O/step0/$g $R25/$g; then echo "SAME run_025 $g"; else echo "DIFFERS run_025 $g"; fi
      done; done
    done
  done
  R26=validation/run_026_stack_and_faces/runs
  for dt in 0.002 0.0005; do
    tools/mjc_stack $O/step0/defaults_stack10_$dt dt=$dt n=10 secs=2 > /dev/null
    tools/mjc_stack $O/step0/defaults_slide_box_$dt dt=$dt n=1 vx=1.2 secs=1 base=0.5 > /dev/null
    for g in $(cd $O/step0 && ls defaults_stack10_${dt}_*.txt defaults_slide_box_${dt}_*.txt); do
      if cmp -s $O/step0/$g $R26/$g; then echo "SAME run_026 $g"; else echo "DIFFERS run_026 $g"; fi
    done
  done
  R27=validation/run_027_grip_and_meshes/runs
  for off in 0 0.01; do for pad in box mesh meshccd; do
    case $pad in box) P="pad=box" ;; mesh) P="pad=mesh" ;; meshccd) P="pad=mesh multiccd=1" ;; esac
    # shellcheck disable=SC2086
    tools/mjc_grip $O/step0/defaults_${pad}_off${off}_0.002 dt=0.002 offset=$off $P > /dev/null
    for g in defaults_${pad}_off${off}_0.002.txt defaults_${pad}_off${off}_0.002_tilt.txt; do
      if cmp -s $O/step0/$g $R27/$g; then echo "SAME run_027 $g"; else echo "DIFFERS run_027 $g"; fi
    done
  done; done
  tools/contact_suite.sh r028_identity > /dev/null; tools/contact_suite2.sh r028_identity > /dev/null
  for s in 1 2; do
    E=validation/run_023_study_03/release/suites/$s/defaults
    for g in $(cd $E && ls *_[0-9]*.txt); do
      if cmp -s suites/$s/r028_identity/$g $E/$g; then echo "SAME suite$s $g"; else echo "DIFFERS suite$s $g"; fi
    done
  done
} > $O/identity.txt
rm -rf $O/step0 suites/1/r028_identity suites/2/r028_identity
# ---- the arm, the stack and the grip, with diagexact
R=$O/reading.txt; : > $R
for cfg in diagexact recommended_diagexact; do
  case $cfg in diagexact) set -- diagexact=1 ;; recommended_diagexact) set -- diagexact=1 cone=elliptic noslip=10 ;; esac
  for pose in A B; do
    case $pose in A) P=0.5,1.2 ;; B) P=1.1,-0.6 ;; esac
    for scene in rest drop; do
      case $scene in rest) SC="h0=0 secs=2" ;; drop) SC="h0=0.01 secs=1" ;; esac
      for dt in 0.002 0.0005; do
        for wr in native straight folded; do
          case $wr in native) P0=$P ;; straight) P0=0,0 ;; folded) P0=0,2.5 ;; esac
          f=$W/arm_${cfg}_${pose}_${scene}_${dt}_$wr.txt
          # shellcheck disable=SC2086
          tools/mjc_arm $f dt=$dt pose=$P pose0=$P0 $SC "$@" | sed "s/^STATS/STATS run $(basename $f .txt)/" >> $S
          st=$(grep "^STATS run $(basename $f .txt) " $S)
          if [ $scene = rest ]; then
            echo "arm $cfg $pose $scene $dt $wr | $(line rest $f) | $(line creep $f) | $(line pull $f) | most_iterations $(fld "$st" most_iterations) at_iteration_limit $(fld "$st" at_iteration_limit) warnings $(fld "$st" warnings)" >> $R
          else
            echo "arm $cfg $pose $scene $dt $wr | $(line bounce $f) | $(line pull $f) | most_iterations $(fld "$st" most_iterations) at_iteration_limit $(fld "$st" at_iteration_limit) warnings $(fld "$st" warnings)" >> $R
          fi
        done
        n=$W/arm_${cfg}_${pose}_${scene}_${dt}_native.txt; ns=$(awk -v d=$dt 'BEGIN { printf "%d", d * 1e9 + 0.5 }')
        for wr in straight folded; do
          g=$W/arm_${cfg}_${pose}_${scene}_${dt}_$wr.txt
          echo "arm $cfg $pose $scene $dt native against $wr | $(line ends $n $g) | $(line gap $ns $n $g)" >> $R
        done
      done
    done
  done
  for dt in 0.002 0.0005; do
    for n in 3 5 10; do
      f=$W/stack_${cfg}_stack${n}_$dt
      tools/mjc_stack $f dt=$dt n=$n secs=2 "$@" | sed "s/^STATS/STATS run $(basename $f)/" >> $S
      for k in $(seq 1 $n); do
        echo "stack $cfg stack$n $dt cube $k | $(line rest ${f}_$k.txt) | $(line pull ${f}_$k.txt) | $(line stop ${f}_$k.txt) | $(line creep ${f}_$k.txt) | place $(line final ${f}_$k.txt) | tilt $(line final ${f}_${k}_tilt.txt)" >> $R
      done
    done
    f=$W/stack_${cfg}_offset3_$dt
    tools/mjc_stack $f dt=$dt n=3 shift=0.02 secs=2 "$@" | sed "s/^STATS/STATS run $(basename $f)/" >> $S
    for k in 1 2 3; do
      echo "stack $cfg offset3 $dt cube $k | $(line rest ${f}_$k.txt) | $(line pull ${f}_$k.txt) | $(line stop ${f}_$k.txt) | $(line creep ${f}_$k.txt) | place $(line final ${f}_$k.txt) | tilt $(line final ${f}_${k}_tilt.txt)" >> $R
    done
    for on in ground box; do
      f=$W/stack_${cfg}_slide_${on}_$dt
      if [ $on = box ]; then bs=base=0.5; else bs=base=0; fi
      tools/mjc_stack $f dt=$dt n=1 vx=1.2 secs=1 $bs "$@" | sed "s/^STATS/STATS run $(basename $f)/" >> $S
      echo "stack $cfg slide $on $dt | $(line stop ${f}_1.txt) | $(line hover ${f}_1.txt) | tilt $(line final ${f}_1_tilt.txt)" >> $R
    done
  done
  for off in 0 0.01; do for pad in box mesh; do
    f=$W/grip_${cfg}_${pad}_off${off}_0.002
    tools/mjc_grip $f dt=0.002 offset=$off pad=$pad "$@" | sed "s/^STATS/STATS run $(basename $f)/" >> $S
    echo "grip $cfg $pad offset $off 0.002 | $(line creep $f.txt) | $(line rest $f.txt) | turned $(line final ${f}_tilt.txt)" >> $R
  done; done
done
# ---- both contact suites
for cfg in diagexact elliptic_noslip_diagexact; do
  case $cfg in diagexact) set -- diagexact=1 ;; elliptic_noslip_diagexact) set -- cone=elliptic noslip=10 diagexact=1 ;; esac
  l=r028_$cfg
  tools/contact_suite.sh $l "$@" > /dev/null; tools/contact_suite2.sh $l "$@" > /dev/null
  bash "$M/sx_contact_suite.sh" suites/1/$l $O/suite1_$cfg.txt || echo "suite 1 $cfg: measuring incomplete"
  d=suites/2/$l
  {
    for run in stop land; do for k in 1 4 16 64; do echo "$run 1/$k | $($B stop $d/${run}_$k.txt | tail -1)"; done; done
    for k in 1 16; do
      echo "rest 1/$k | $($B pair $d/rest_${k}_a.txt $d/rest_${k}_b.txt | tail -1)"
      echo "carry 1/$k | $($B pair $d/carry_${k}_a.txt $d/carry_${k}_b.txt | tail -1)"
      echo "slip A 1/$k | $($B accel $d/slip_${k}_a.txt 700 900 | tail -1)"
      echo "slip B 1/$k | $($B accel $d/slip_${k}_b.txt 700 900 | tail -1)"
      echo "side 1/$k | $($B pair $d/side_${k}_a.txt $d/side_${k}_b.txt | tail -1)"
      echo "top 1/$k | $($B pair $d/top_${k}_a.txt $d/top_${k}_b.txt | tail -1)"
    done
  } > $O/suite2_$cfg.txt
  mkdir -p $O/suites/1 $O/suites/2; rm -rf $O/suites/1/$cfg $O/suites/2/$cfg
  mv suites/1/$l $O/suites/1/$cfg; mv suites/2/$l $O/suites/2/$cfg
done
grep -o 'STATS run [^ ]*\|most_iterations [0-9]*\|at_iteration_limit [0-9]*\|warnings [0-9]*' $S | paste -d' ' - - - - > $O/solver.txt
date -u +%FT%TZ > $O/finished.txt
