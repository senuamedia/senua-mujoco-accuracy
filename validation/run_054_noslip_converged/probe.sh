#!/usr/bin/env bash
# Run 054: a design probe, not registered: it finds where to look and decides nothing. Run 052 found that noslip with
# 1,000 iterations and a noslip tolerance of 1e-12, both MuJoCo's own options, holds an arm by joint friction at 0
# (issue 6), where the configuration's 10 iterations leave it creeping at 93 and 25 um/s. Does that change to Senua AI's
# configuration keep everything else the configuration holds, and what does it do to the stacks (issue 21)? On MuJoCo
# 3.16.0 as released (rel) and on the de Saxce patch's fourth version with its switch set (on, Study 12's build), four
# noslip settings under the elliptic cone: 10 iterations (the configuration as it is), 100, 100 at a noslip tolerance of
# 1e-12, and 1,000 at 1e-12. On Study 10's numbers, at 1.14 and 0.285 ms: the cube held at 0.5, 0.75 and 0.95 of its
# friction limit and slid along 0, 22.5 and 45 degrees, kept from turning; slid free to turn along 0, 11.25, 22.5, 33.75
# and 45; the grip, box and mesh pads, at the centre and off it; a cube slid on a box's face; the arm held 1 m up by
# joint friction, and on contact, set down and dropped, in two poses each; the first contact suite; and stacks of 5 and
# 9 and the offset stack of 3 at 0.1425, 0.285, 0.57, 0.855 and 1.14 ms. The contact, stack and grip rigs gain
# noslip_tolerance, unchanged without it: run 052's plays made again and compared by cmp with its files.
# Readings: Senua AI's measures (sx_contact creep, stop, hover; the first deep dive's suite runner), file comparison by
# cmp, the rigs' STATS fields, and for the stacks the rig's own columns (as in run 050).
# usage: probe.sh <folder holding sx_contact and sx_contact_suite.sh> <work folder>   (repository root, on the cloud
#        machine; the work folder holds the release in mujoco-3.16.0 and Study 12's build in mujoco-s12-build)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_054_noslip_converged"; REL="$W/mujoco-3.16.0"; V4="$W/mujoco-s12-build"
R52="$R/validation/run_052_joint_friction_and_tolerance/rel/p"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
REC="cone=elliptic noslip=10"; KCUBE="mass=0.442 radius=0.0424 mu=0.524"; CUBE="mass=1.861 radius=0.0434 mu=0.39"
LIM=$(awk 'BEGIN { printf "%.6f", 0.39 * 1.861 * 9.8 }'); GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"
ARM="len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717"; JF=5.96
CFGS="n10:cone=elliptic|noslip=10 n100:cone=elliptic|noslip=100 n100t:cone=elliptic|noslip=100|noslip_tolerance=1e-12 n1000t:cone=elliptic|noslip=1000|noslip_tolerance=1e-12"
for arm in rel: on:1; do
  a=${arm%%:*}; sw=${arm#*:}
  case $a in rel) mj=$REL ;; *) mj=$V4 ;; esac
  X="$W/p54$a"; rm -rf "$X"; mkdir -p "$X/suites" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_stack mjc_grip mjc_arm; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null 2>&1; done
    if [ -n "$sw" ]; then export MUJOCO_DESAXCE=$sw; else unset MUJOCO_DESAXCE; fi
    mkdir -p p; S=p/stats.txt; : > $S
    if [ "$a" = rel ]; then
      # the rigs unchanged without noslip_tolerance: run 052's plays at the default tolerance, made again
      mkdir -p id
      for dt in 0.00114 0.000285; do
        for dir in 0 22.5 45; do
          for fr in 0.5 0.95; do
            pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
            # shellcheck disable=SC2086
            tools/mjc_contact id/hold_def_${dir}_${fr}_$dt.txt dt=$dt h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=$dir $REC > /dev/null
          done
          # shellcheck disable=SC2086
          tools/mjc_contact id/slide_def_${dir}_$dt.txt dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 dir=$dir $REC > /dev/null
          # shellcheck disable=SC2086
          tools/mjc_contact id/free_def_${dir}_$dt.txt dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 lock=0 dir=$dir $REC trace=id/free_def_${dir}_$dt.trace > /dev/null
        done
        for off in 0 0.0093; do
          # shellcheck disable=SC2086
          tools/mjc_grip id/grip_def_off${off}_$dt dt=$dt offset=$off pad=box $GRIP $REC > /dev/null
        done
      done
      for dt in 0.0001425 0.000285 0.00057 0.000855 0.00114; do
        # shellcheck disable=SC2086
        for n in 5 9; do tools/mjc_stack id/stack${n}_def_$dt dt=$dt n=$n secs=2 $KCUBE $REC > /dev/null; done
        # shellcheck disable=SC2086
        tools/mjc_stack id/offset3_def_$dt dt=$dt n=3 shift=0.017 secs=2 $KCUBE $REC > /dev/null
      done
      s=0; n=0
      for f in $(cd id && ls | sort); do n=$((n + 1)); cmp -s "id/$f" "$R52/$f" && s=$((s + 1)) || echo "DIFFERS $f" >> id/identity.txt; done
      echo "run 052's plays made again: $s of $n byte for byte" >> id/identity.txt
    fi
    for c in $CFGS; do
      cn=${c%%:*}; opts=$(echo "${c#*:}" | tr '|' ' ')
      for dt in 0.00114 0.000285; do
        for dir in 0 22.5 45; do
          for fr in 0.5 0.75 0.95; do
            pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
            # shellcheck disable=SC2086
            tools/mjc_contact p/${cn}_hold_${dir}_${fr}_$dt.txt dt=$dt h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=$dir $opts | sed "s|^STATS|STATS run ${cn}_hold_${dir}_${fr}_$dt|" >> $S
          done
          # shellcheck disable=SC2086
          tools/mjc_contact p/${cn}_slide_${dir}_$dt.txt dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 dir=$dir $opts | sed "s|^STATS|STATS run ${cn}_slide_${dir}_$dt|" >> $S
        done
        for dir in 0 11.25 22.5 33.75 45; do
          # shellcheck disable=SC2086
          tools/mjc_contact p/${cn}_free_${dir}_$dt.txt dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 lock=0 dir=$dir $opts trace=p/${cn}_free_${dir}_$dt.trace | sed "s|^STATS|STATS run ${cn}_free_${dir}_$dt|" >> $S
        done
        for off in 0 0.0093; do for pad in box mesh; do
          # shellcheck disable=SC2086
          tools/mjc_grip p/${cn}_grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $opts | sed "s|^STATS|STATS run ${cn}_grip_${pad}_off${off}_$dt|" >> $S
        done; done
        # shellcheck disable=SC2086
        tools/mjc_stack p/${cn}_slide_box_$dt dt=$dt n=1 vx=1.16 secs=1 base=0.5 $KCUBE $opts | sed "s|^STATS|STATS run ${cn}_slide_box_$dt|" >> $S
        k=0
        for PS in 0.245,0.831 0.223,0.993; do
          k=$((k + 1))
          # shellcheck disable=SC2086
          tools/mjc_arm p/${cn}_jf_pose${k}_$dt.txt dt=$dt pose=$PS pose0=$PS jointfriction=$JF h0=1 secs=2 $ARM $opts | sed "s|^STATS|STATS run ${cn}_jf_pose${k}_$dt|" >> $S
        done
        k=0
        for PS in 0.604,1.158 1.149,-0.545; do
          k=$((k + 1))
          for sc in rest drop; do
            if [ $sc = rest ]; then SC="h0=0.00059 secs=2"; else SC="h0=0.0121 secs=1"; fi
            # shellcheck disable=SC2086
            tools/mjc_arm p/${cn}_arm_pose${k}_${sc}_$dt.txt dt=$dt pose=$PS pose0=$PS $ARM $SC $opts | sed "s|^STATS|STATS run ${cn}_arm_pose${k}_${sc}_$dt|" >> $S
          done
        done
      done
      for dt in 0.0001425 0.000285 0.00057 0.000855 0.00114; do
        # shellcheck disable=SC2086
        for n in 5 9; do tools/mjc_stack p/${cn}_stack${n}_$dt dt=$dt n=$n secs=2 $KCUBE $opts | sed "s|^STATS|STATS run ${cn}_stack${n}_$dt|" >> $S; done
        # shellcheck disable=SC2086
        tools/mjc_stack p/${cn}_offset3_$dt dt=$dt n=3 shift=0.017 secs=2 $KCUBE $opts | sed "s|^STATS|STATS run ${cn}_offset3_$dt|" >> $S
      done
      # shellcheck disable=SC2086
      ( export SUITE_CUBE="mass=0.881 radius=0.0392" SUITE_H0=0.096 SUITE_VX=3.24 SUITE_VXCHAIN=1.47 SUITE_MU=0.371 SUITE_VSLIDE=3.67 \
          SUITE_MUHOLD=0.421 SUITE_HOLD=2.180898 SUITE_SLIP=4.361796 SUITE_LIFT=25.9014
        tools/contact_suite.sh $cn $opts > /dev/null )
      log "$a $cn played"
    done )
  rm -rf "${O:?}/${a:?}"; mkdir -p "$O/$a"; cp -R "$X/p" "$X/suites" "$O/$a/"; [ -d "$X/id" ] && cp -R "$X/id" "$O/$a/"; rm -rf "${X:?}"
done
unset MUJOCO_DESAXCE
# measuring
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
stk() {  # <prefix>: the most tilt of any cube over the play; at the last step the largest speed (vx or vz)
  local p=$1 t s
  t=$(cat "$p"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }')
  s=$(for f in "$p"_[0-9].txt; do tail -1 "$f"; done | awk '{ x = $3 < 0 ? -$3 : $3; y = $4 < 0 ? -$4 : $4; if (x > m) m = x; if (y > m) m = y } END { print m + 0 }')
  echo "most_tilt_urad $t end_speed_ums $s"
}
its() { fld "$(grep "^STATS run $2 " "$1")" most_iterations; }
for a in rel on; do for c in $CFGS; do cn=${c%%:*}
  SUITE_MU10K=3710 SUITE_SLIPMN=4361 bash "$M/sx_contact_suite.sh" "$O/$a/suites/1/$cn" "$O/$a/suite1_$cn.txt" > /dev/null 2>&1
done; done
{
  sed 's/^/identity /' "$O/rel/id/identity.txt"
  for a in rel on; do
    P="$O/$a/p"
    for c in $CFGS; do
      cn=${c%%:*}
      for dt in 0.00114 0.000285; do
        for dir in 0 22.5 45; do
          for fr in 0.5 0.75 0.95; do n=${cn}_hold_${dir}_${fr}_$dt; echo "$a $n creep_ums $(fld "$("$B" creep "$P/$n.txt" | tail -1)" mean_speed_ums) most_iterations $(its "$P/stats.txt" "$n")"; done
          n=${cn}_slide_${dir}_$dt; echo "$a $n slid_um $(fld "$("$B" stop "$P/$n.txt" | tail -1)" slid_um) side_um $(fld "$(grep "^STATS run $n " "$P/stats.txt")" side_um) highest_um $(fld "$("$B" hover "$P/$n.txt" | tail -1)" highest_um)"
        done
        for dir in 0 11.25 22.5 33.75 45; do
          n=${cn}_free_${dir}_$dt; s=$(grep "^STATS run $n " "$P/stats.txt")
          echo "$a $n slid_um $(fld "$("$B" stop "$P/$n.txt" | tail -1)" slid_um) side_um $(fld "$s" side_um) most_yaw_urad $(fld "$s" most_yaw_urad) steps_under_4_contacts $(fld "$s" steps_under_4_contacts)"
        done
        for off in 0 0.0093; do for pad in box mesh; do n=${cn}_grip_${pad}_off${off}_$dt; echo "$a $n creep_ums $(fld "$("$B" creep "$P/$n.txt" | tail -1)" mean_speed_ums)"; done; done
        echo "$a ${cn}_slide_box_$dt slid_um $(fld "$("$B" stop "$P/${cn}_slide_box_${dt}_1.txt" | tail -1)" slid_um)"
        for k in 1 2; do n=${cn}_jf_pose${k}_$dt; echo "$a $n creep_ums $(fld "$("$B" creep "$P/$n.txt" | tail -1)" mean_speed_ums) most_iterations $(its "$P/stats.txt" "$n")"; done
        for k in 1 2; do n=${cn}_arm_pose${k}_rest_$dt; echo "$a $n creep_ums $(fld "$("$B" creep "$P/$n.txt" | tail -1)" mean_speed_ums)"; done
      done
      for dt in 0.0001425 0.000285 0.00057 0.000855 0.00114; do
        for s in stack5 stack9 offset3; do echo "$a ${cn}_${s}_$dt $(stk "$P/${cn}_${s}_$dt") most_iterations $(its "$P/stats.txt" "${cn}_${s}_$dt")"; done
      done
      echo "$a ${cn}_suite1 passed $(grep '^SUITE passed' "$O/$a/suite1_$cn.txt" | awk '{ print $3 }')"
      echo "$a ${cn}_solver most_iterations $(grep "^STATS run ${cn}_" "$P/stats.txt" | grep -o 'most_iterations [0-9]*' | awk '{ if ($2 > x) x = $2 } END { print x + 0 }') at_iteration_limit $(grep "^STATS run ${cn}_" "$P/stats.txt" | grep -o 'at_iteration_limit [0-9]*' | awk '{ s += $2 } END { print s + 0 }') warnings $(grep "^STATS run ${cn}_" "$P/stats.txt" | grep -o 'warnings [0-9]*' | awk '{ s += $2 } END { print s + 0 }')"
    done
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
