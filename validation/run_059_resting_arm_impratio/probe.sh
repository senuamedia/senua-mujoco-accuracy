#!/usr/bin/env bash
# Run 059: a design probe, not registered: it finds where to look and decides nothing. Issue 1's open part: an arm set
# down on its ball slides at its contact under the elliptic cone, well inside its friction cone, and noslip does nothing
# for that contact (run 056); Study 13's fresh arm slid at 191 um/s in one pose. Under the elliptic cone MuJoCo divides the
# friction rows' regularisation by impratio. Does the slide follow it, so that it is the soft friction's own creep that
# noslip leaves in place, and does any integrator change it? The arm rig gains impratio, unchanged without it: Study 10's
# arm plays on contact made again and compared by cmp with run 042's files. On MuJoCo 3.16.0 as released: Study 10's arm
# and Study 13's arm, each in its two contact poses, written in its own pose, set down and left at rest, 2 s, at 1.14 ms,
# under the elliptic cone with 0, 10 and 100 noslip iterations at impratio 1 (MuJoCo's default), 3, 10, 30 and 100; and
# under the configuration (10 noslip iterations) with implicitfast and with RK4.
# Readings: Senua AI's measure (sx_contact creep), the rig's trace (the slip at the ball's contact), file comparison by
# cmp.
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds the release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_059_resting_arm_impratio"; S10="$R/validation/run_042_study_10"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
A10="len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717"; P10="0.604,1.158 1.149,-0.545"; H10=0.00059
A13="len1=0.297 len2=0.302 mass1=1.08 mass2=0.578 rb=0.0295 mb=0.194 mu=0.778"; P13="0.516,0.907 1.211,-0.464"; H13=0.00052
X="$W/p59"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
( cd "$X" || exit 2
  MUJOCO_DIR="$W/mujoco-3.16.0" tools/build_rig.sh mjc_arm > /dev/null 2>&1
  mkdir -p p id; S=p/stats.txt; : > $S
  for c in def: rec:"cone=elliptic noslip=10"; do
    cn=${c%%:*}; opts=${c#*:}
    for dt in 0.00114 0.000285; do
      k=0
      for PS in $P10; do
        k=$((k + 1))
        # shellcheck disable=SC2086
        tools/mjc_arm id/rest_pose${k}_${dt}_$cn.txt dt=$dt pose=$PS pose0=$PS $A10 h0=$H10 secs=2 $opts > /dev/null
        echo "arm_pose${k}_rest_$dt $cn $(cmp -s id/rest_pose${k}_${dt}_$cn.txt "$S10/rel_$cn/runs/arm_pose${k}_rest_${dt}_native.txt" && echo same || echo DIFFERS)" >> id/identity.txt
      done
    done
  done
  play() {  # <name> <arm> <poses> <h0> <options...>
    local n=$1 a=$2 ps=$3 h=$4 k=0 PS; shift 4
    for PS in $ps; do
      k=$((k + 1))
      # shellcheck disable=SC2086
      tools/mjc_arm p/${n}_pose$k.txt dt=0.00114 pose=$PS pose0=$PS $a h0=$h secs=2 "$@" trace=p/${n}_pose$k.trace | sed "s|^STATS|STATS run ${n}_pose$k|" >> $S
    done
  }
  for arm in s10 s13; do
    if [ $arm = s10 ]; then a=$A10; ps=$P10; h=$H10; else a=$A13; ps=$P13; h=$H13; fi
    for ns in 0 10 100; do
      for ir in 1 3 10 30 100; do
        if [ $ns = 0 ]; then N=""; else N="noslip=$ns"; fi
        # shellcheck disable=SC2086
        play ${arm}_ns${ns}_imp$ir "$a" "$ps" $h cone=elliptic $N impratio=$ir
      done
    done
    for g in implicitfast RK4; do
      # shellcheck disable=SC2086
      play ${arm}_rec_$g "$a" "$ps" $h cone=elliptic noslip=10 integ=$g
    done
  done )
rm -rf "${O:?}/p" "$O/id"; cp -R "$X/p" "$X/id" "$O/"; rm -rf "${X:?}"
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  echo "identity: $(grep -c ' same$' "$O/id/identity.txt") of $(grep -c . "$O/id/identity.txt") byte for byte"
  for f in $(cd "$O/p" && ls *.txt | grep -v stats | sed 's/\.txt$//' | sort); do
    cr=$(fld "$("$B" creep "$O/p/$f.txt" | tail -1)" mean_speed_ums)
    sl=$(awk '{ s[NR] = $0 } END { h = int(NR / 2); for (i = h + 1; i <= NR; i++) { split(s[i], c, " "); x += c[3] } printf "%.1f", x / (NR - h) }' "$O/p/$f.trace")
    echo "$f creep_ums $cr slip_x_ums $sl $(tail -1 "$O/p/$f.txt" | awk '{ printf "sideways_over_normal %.4f", ($5 != 0) ? $6 / $5 : 0 }') most_iterations $(fld "$(grep "^STATS run $f " "$O/p/stats.txt")" most_iterations)"
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
