#!/usr/bin/env bash
# Run 056: a design probe, not registered: it finds where to look and decides nothing. Issue 1's open part: Study 10's
# two-link arm set down with its ball on the ground, at rest, creeps along the ground at 714 um/s in its first pose under
# Senua AI's configuration (Study 10's readings; run 054: the same with noslip run to convergence), its sideways force
# 0.11 of its normal force, well inside its friction cone (0.717). Does the ball slide at its contact, or roll, and what
# does the creep follow? The arm rig gains trace (per step: the ball's contacts, the slip of its surface at the contact,
# link 2's spin, the joints' speeds), unchanged without it: Study 10's arm plays on contact under MuJoCo's defaults and
# the configuration made again and compared by cmp with run 042's files. On Study 10's numbers, both of its contact
# poses, written in their own pose, set down from 0.59 mm, 2 s, at 1.14 and 0.285 ms, under: MuJoCo's defaults; the
# elliptic cone alone; the configuration (the elliptic cone, 10 noslip iterations); 100 noslip iterations; 1,000 at a
# noslip tolerance of 1e-12; the pyramidal cone with 10 noslip iterations; the configuration with MuJoCo's diagexact
# flag; the configuration with the main solve at 1e-12 and 1,000 iterations; on MuJoCo 3.16.0 as released and on the de
# Saxce patch's fourth version with its switch set (Study 12's build).
# Readings: Senua AI's measure (sx_contact creep), file comparison by cmp, and the rig's columns and trace, read by the
# awk lines below.
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds the release in mujoco-3.16.0 and Study 12's build in mujoco-s12-build)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_056_resting_arm"; S10="$R/validation/run_042_study_10"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
ARM="len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717"; REC="cone=elliptic noslip=10"
CFGS="def: ell:cone=elliptic rec:cone=elliptic|noslip=10 n100:cone=elliptic|noslip=100 n1000t:cone=elliptic|noslip=1000|noslip_tolerance=1e-12 pyr10:noslip=10 diag:cone=elliptic|noslip=10|diagexact=1 tight:cone=elliptic|noslip=10|tolerance=1e-12|iterations=1000"
for arm in "rel:$W/mujoco-3.16.0:" "on:$W/mujoco-s12-build:1"; do
  a=${arm%%:*}; rest=${arm#*:}; mj=${rest%:*}; sw=${rest##*:}
  X="$W/p56$a"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    MUJOCO_DIR=$mj tools/build_rig.sh mjc_arm > /dev/null 2>&1
    if [ -n "$sw" ]; then export MUJOCO_DESAXCE=$sw; else unset MUJOCO_DESAXCE; fi
    mkdir -p p; S=p/stats.txt; : > $S
    if [ "$a" = rel ]; then
      mkdir -p id
      for c in def: rec:"$REC"; do
        cn=${c%%:*}; opts=${c#*:}
        for dt in 0.00114 0.000285; do
          k=0
          for PS in 0.604,1.158 1.149,-0.545; do
            k=$((k + 1))
            for sc in rest drop; do
              if [ $sc = rest ]; then SC="h0=0.00059 secs=2"; else SC="h0=0.0121 secs=1"; fi
              # shellcheck disable=SC2086
              tools/mjc_arm id/arm_pose${k}_${sc}_${dt}_${cn}.txt dt=$dt pose=$PS pose0=$PS $ARM $SC $opts > /dev/null
              echo "arm_pose${k}_${sc}_$dt $cn $(cmp -s id/arm_pose${k}_${sc}_${dt}_${cn}.txt "$S10/rel_$cn/runs/arm_pose${k}_${sc}_${dt}_native.txt" && echo same || echo DIFFERS)" >> id/identity.txt
            done
          done
        done
      done
    fi
    for c in $CFGS; do
      cn=${c%%:*}; opts=$(echo "${c#*:}" | tr '|' ' ')
      for dt in 0.00114 0.000285; do
        k=0
        for PS in 0.604,1.158 1.149,-0.545; do
          k=$((k + 1))
          # shellcheck disable=SC2086
          tools/mjc_arm p/${cn}_pose${k}_$dt.txt dt=$dt pose=$PS pose0=$PS $ARM h0=0.00059 secs=2 $opts trace=p/${cn}_pose${k}_$dt.trace | sed "s|^STATS|STATS run ${cn}_pose${k}_$dt|" >> $S
        done
      done
    done )
  rm -rf "${O:?}/${a:?}"; mkdir -p "$O/$a"; cp -R "$X/p" "$O/$a/"; [ -d "$X/id" ] && cp -R "$X/id" "$O/$a/"; rm -rf "${X:?}"
  log "$a played"
done
unset MUJOCO_DESAXCE
# measuring: the creep (sx_contact creep, the second second); over the second second the mean of the trace's columns;
# at the last step the ground's force on the ball, sideways over up
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  sed 's/^/identity /' "$O/rel/id/identity.txt"
  for a in rel on; do
    for c in $CFGS; do
      cn=${c%%:*}
      for dt in 0.00114 0.000285; do for k in 1 2; do
        n=${cn}_pose${k}_$dt; P="$O/$a/p"
        cr=$(fld "$("$B" creep "$P/$n.txt" | tail -1)" mean_speed_ums)
        tr=$(awk 'NR == 1 { } { s[NR] = $0 } END { h = int(NR / 2); for (i = h + 1; i <= NR; i++) { split(s[i], f, " "); nb += f[2]; sx += f[3]; sz += f[4]; w += f[5]; q1 += f[6]; q2 += f[7] } n = NR - h; printf "contacts %.2f slip_x_ums %.1f slip_z_ums %.1f spin_urads %.1f shoulder_urads %.1f elbow_urads %.1f", nb / n, sx / n, sz / n, w / n, q1 / n, q2 / n }' "$P/$n.trace")
        fr=$(tail -1 "$P/$n.txt" | awk '{ printf "Fz_mN %d Fx_mN %d ratio %.4f", $5, $6, ($5 != 0) ? $6 / $5 : 0 }')
        echo "$a $n creep_ums $cr $tr $fr most_iterations $(fld "$(grep "^STATS run $n " "$P/stats.txt")" most_iterations)"
      done; done
    done
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
