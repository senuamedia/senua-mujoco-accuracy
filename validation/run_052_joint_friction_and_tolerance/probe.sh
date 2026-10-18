#!/usr/bin/env bash
# Run 052: a design probe, not registered: it finds where to look and decides nothing. Two open issues of
# docs/issues.md, on Google DeepMind's Linux release of MuJoCo 3.16.0, and for the stacks also on the de Saxce patch's
# fourth version with its switch set (Study 12's build of it):
#   1. Issue 6, a joint held by friction creeps (M13). Study 10: the arm held 1 m up by joint friction above its load
#      creeps at 30 mm/s at the ball under MuJoCo's defaults and at 93 and 25 um/s under Senua AI's configuration (the
#      elliptic cone with 10 noslip iterations). Which of MuJoCo's own options holds it still: more noslip iterations, a
#      tighter noslip tolerance, a tighter main solve, or a stiffer reference for the joints' friction rows
#      (solreffriction)? The arm on Study 10's numbers, held in its two poses, written in its own pose, 2 s, at 1.14 and
#      0.285 ms. The arm rig gains noslip_tolerance and fricsolref, unchanged without them: Study 10's plays of the arm
#      held by joint friction and at rest on contact, under MuJoCo's defaults and the configuration, made again and
#      compared by cmp with run 042's files.
#   2. Issue 21, a straight stack does not stand at a fine step (F14). Run 050: no stack moves without noslip, and with
#      the main solve at a tolerance of 1e-12 none tilts. At which tolerance does each stack stand, at which steps, and
#      what does a tighter tolerance cost and change in the configuration's other plays? Stacks of 5 and 9 and the
#      offset stack of 3 on Study 10's numbers under the configuration, at tolerances from MuJoCo's default (1e-8) to
#      1e-14, at 0.1425, 0.285, 0.57, 0.855 and 1.14 ms; and Study 10's cube held, slid kept from turning and free to
#      turn, and the grip, at tolerances 1e-8, 1e-10 and 1e-12, at 1.14 and 0.285 ms.
# Readings: Senua AI's measures (sx_contact creep, stop), file comparison by cmp, the rigs' STATS fields, and for the
# stacks the rig's own columns, read by the awk lines below (as in run 050).
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds the release in mujoco-3.16.0 and Study 12's build of the fourth version in mujoco-s12-build)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_052_joint_friction_and_tolerance"; REL="$W/mujoco-3.16.0"; V4="$W/mujoco-s12-build"
S10="$R/validation/run_042_study_10"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
REC="cone=elliptic noslip=10"; KCUBE="mass=0.442 radius=0.0424 mu=0.524"; CUBE="mass=1.861 radius=0.0434 mu=0.39"
LIM=$(awk 'BEGIN { printf "%.6f", 0.39 * 1.861 * 9.8 }'); GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"
ARM="len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717"; JF=5.96
for arm in rel: on:1; do
  a=${arm%%:*}; sw=${arm#*:}
  case $a in rel) mj=$REL ;; *) mj=$V4 ;; esac
  X="$W/p52$a"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_stack mjc_grip mjc_arm; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null 2>&1; done
    if [ -n "$sw" ]; then export MUJOCO_DESAXCE=$sw; else unset MUJOCO_DESAXCE; fi
    mkdir -p p; S=p/stats.txt; : > $S
    if [ "$a" = rel ]; then
      # 1. the arm held by joint friction; first, the rig unchanged without its new settings
      mkdir -p id
      for c in def: rec:"$REC"; do
        cn=${c%%:*}; opts=${c#*:}; src=rel_$cn
        for dt in 0.00114 0.000285; do
          k=0
          for PS in 0.245,0.831 0.223,0.993; do
            k=$((k + 1))
            # shellcheck disable=SC2086
            tools/mjc_arm id/hold_pose${k}_${dt}_${cn}.txt dt=$dt pose=$PS pose0=$PS jointfriction=$JF h0=1 secs=2 $ARM $opts > /dev/null
            echo "hold_pose${k}_${dt} $cn $(cmp -s id/hold_pose${k}_${dt}_${cn}.txt "$S10/$src/runs/hold_pose${k}_${dt}_native.txt" && echo same || echo DIFFERS)" >> id/identity.txt
          done
          k=0
          for PS in 0.604,1.158 1.149,-0.545; do
            k=$((k + 1))
            # shellcheck disable=SC2086
            tools/mjc_arm id/rest_pose${k}_${dt}_${cn}.txt dt=$dt pose=$PS pose0=$PS $ARM h0=0.00059 secs=2 $opts > /dev/null
            echo "arm_pose${k}_rest_${dt} $cn $(cmp -s id/rest_pose${k}_${dt}_${cn}.txt "$S10/$src/runs/arm_pose${k}_rest_${dt}_native.txt" && echo same || echo DIFFERS)" >> id/identity.txt
          done
        done
      done
      for v in "def:" "rec:$REC" "pyr10:noslip=10" "ns100:cone=elliptic noslip=100" "ns1000:cone=elliptic noslip=1000" \
               "nstol:$REC noslip_tolerance=1e-12" "nstol1000:cone=elliptic noslip=1000 noslip_tolerance=1e-12" \
               "tight:$REC tolerance=1e-12 iterations=1000" "fsr10:fricsolref=0.01,1" "fsr5:fricsolref=0.005,1" \
               "recfsr10:$REC fricsolref=0.01,1" "recfsr5:$REC fricsolref=0.005,1"; do
        vn=${v%%:*}; opts=${v#*:}
        for dt in 0.00114 0.000285; do
          k=0
          for PS in 0.245,0.831 0.223,0.993; do
            k=$((k + 1))
            # shellcheck disable=SC2086
            tools/mjc_arm p/jf_${vn}_pose${k}_$dt.txt dt=$dt pose=$PS pose0=$PS jointfriction=$JF h0=1 secs=2 $ARM $opts | sed "s|^STATS|STATS run jf_${vn}_pose${k}_$dt|" >> $S
          done
        done
      done
    fi
    # 2. the stacks under the configuration, by the main solver's tolerance and the step
    for tol in def 1e-9 1e-10 1e-11 1e-12 1e-14; do
      if [ $tol = def ]; then T=""; else T="tolerance=$tol"; fi
      for dt in 0.0001425 0.000285 0.00057 0.000855 0.00114; do
        for n in 5 9; do
          # shellcheck disable=SC2086
          tools/mjc_stack p/stack${n}_${tol}_$dt dt=$dt n=$n secs=2 $KCUBE $REC $T | sed "s|^STATS|STATS run stack${n}_${tol}_$dt|" >> $S
        done
        # shellcheck disable=SC2086
        tools/mjc_stack p/offset3_${tol}_$dt dt=$dt n=3 shift=0.017 secs=2 $KCUBE $REC $T | sed "s|^STATS|STATS run offset3_${tol}_$dt|" >> $S
      done
    done
    # the configuration's other plays at a tighter tolerance
    for tol in def 1e-10 1e-12; do
      if [ $tol = def ]; then T=""; else T="tolerance=$tol"; fi
      for dt in 0.00114 0.000285; do
        for dir in 0 22.5 45; do
          for fr in 0.5 0.95; do
            pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
            # shellcheck disable=SC2086
            tools/mjc_contact p/hold_${tol}_${dir}_${fr}_$dt.txt dt=$dt h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=$dir $REC $T | sed "s|^STATS|STATS run hold_${tol}_${dir}_${fr}_$dt|" >> $S
          done
          # shellcheck disable=SC2086
          tools/mjc_contact p/slide_${tol}_${dir}_$dt.txt dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 dir=$dir $REC $T | sed "s|^STATS|STATS run slide_${tol}_${dir}_$dt|" >> $S
          # shellcheck disable=SC2086
          tools/mjc_contact p/free_${tol}_${dir}_$dt.txt dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 lock=0 dir=$dir $REC $T trace=p/free_${tol}_${dir}_$dt.trace | sed "s|^STATS|STATS run free_${tol}_${dir}_$dt|" >> $S
        done
        for off in 0 0.0093; do
          # shellcheck disable=SC2086
          tools/mjc_grip p/grip_${tol}_off${off}_$dt dt=$dt offset=$off pad=box $GRIP $REC $T | sed "s|^STATS|STATS run grip_${tol}_off${off}_$dt|" >> $S
        done
      done
    done )
  rm -rf "${O:?}/${a:?}"; mkdir -p "$O/$a"; cp -R "$X/p" "$O/$a/"; [ -d "$X/id" ] && cp -R "$X/id" "$O/$a/"; rm -rf "${X:?}"
  log "$a played"
done
unset MUJOCO_DESAXCE
# measuring
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
stk() {  # <prefix>: the most tilt of any cube over the play; at the last step the largest speed (vx or vz) and spin
  local p=$1 t s w
  t=$(cat "$p"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }')
  w=$(for f in "$p"_*_tilt.txt; do tail -1 "$f"; done | awk '{ x = $3 < 0 ? -$3 : $3; if (x > m) m = x } END { print m + 0 }')
  s=$(for f in "$p"_[0-9].txt; do tail -1 "$f"; done | awk '{ x = $3 < 0 ? -$3 : $3; y = $4 < 0 ? -$4 : $4; if (x > m) m = x; if (y > m) m = y } END { print m + 0 }')
  echo "most_tilt_urad $t end_speed_ums $s end_spin_urads $w"
}
its() { fld "$(grep "^STATS run $2 " "$1")" most_iterations; }
{
  P="$O/rel/p"
  cat "$O/rel/id/identity.txt" | sed 's/^/identity /'
  for v in def rec pyr10 ns100 ns1000 nstol nstol1000 tight fsr10 fsr5 recfsr10 recfsr5; do
    for dt in 0.00114 0.000285; do for k in 1 2; do
      n=jf_${v}_pose${k}_$dt
      echo "rel $n creep_ums $(fld "$("$B" creep "$P/$n.txt" | tail -1)" mean_speed_ums) most_iterations $(its "$P/stats.txt" "$n")"
    done; done
  done
  for a in rel on; do
    P="$O/$a/p"
    for tol in def 1e-9 1e-10 1e-11 1e-12 1e-14; do
      for dt in 0.0001425 0.000285 0.00057 0.000855 0.00114; do
        for s in stack5 stack9 offset3; do
          echo "$a ${s}_${tol}_$dt $(stk "$P/${s}_${tol}_$dt") most_iterations $(its "$P/stats.txt" "${s}_${tol}_$dt")"
        done
      done
    done
    for tol in def 1e-10 1e-12; do
      for dt in 0.00114 0.000285; do
        for dir in 0 22.5 45; do
          for fr in 0.5 0.95; do n=hold_${tol}_${dir}_${fr}_$dt; echo "$a $n creep_ums $(fld "$("$B" creep "$P/$n.txt" | tail -1)" mean_speed_ums) most_iterations $(its "$P/stats.txt" "$n")"; done
          n=slide_${tol}_${dir}_$dt; echo "$a $n slid_um $(fld "$("$B" stop "$P/$n.txt" | tail -1)" slid_um) most_iterations $(its "$P/stats.txt" "$n")"
          n=free_${tol}_${dir}_$dt; s=$(grep "^STATS run $n " "$P/stats.txt")
          echo "$a $n slid_um $(fld "$("$B" stop "$P/$n.txt" | tail -1)" slid_um) side_um $(fld "$s" side_um) most_yaw_urad $(fld "$s" most_yaw_urad) most_iterations $(fld "$s" most_iterations)"
        done
        for off in 0 0.0093; do n=grip_${tol}_off${off}_$dt; echo "$a $n creep_ums $(fld "$("$B" creep "$P/$n.txt" | tail -1)" mean_speed_ums) most_iterations $(its "$P/stats.txt" "$n")"; done
      done
    done
    echo "$a solver most_iterations $(grep -oh 'most_iterations [0-9]*' "$P/stats.txt" | awk '{ if ($2 > x) x = $2 } END { print x + 0 }') at_iteration_limit $(grep -oh 'at_iteration_limit [0-9]*' "$P/stats.txt" | awk '{ s += $2 } END { print s + 0 }') warnings $(grep -oh 'warnings [0-9]*' "$P/stats.txt" | awk '{ s += $2 } END { print s + 0 }')"
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
