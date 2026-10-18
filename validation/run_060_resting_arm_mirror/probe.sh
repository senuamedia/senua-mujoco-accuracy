#!/usr/bin/env bash
# Run 060: a design probe, not registered: it finds where to look and decides nothing. Run 059 found that the resting
# arm's slide is the elliptic cone's soft friction's own creep (it falls as 1/impratio), and that noslip removes it on
# Study 13's arm in its first pose, where the ball slips toward +x, and not where it slips toward -x (Study 10's two
# poses, Study 13's second). Does the direction of the slip decide it? Each arm's poses played as written and mirrored
# about the vertical plane through the shoulder, (pi - q1, -q2): the same scene with x reversed, whose slip goes the
# other way. On MuJoCo 3.16.0 as released, written in its own pose, set down and left at rest, 2 s, at 1.14 ms, under
# MuJoCo's defaults, the elliptic cone alone, the configuration with 10 and with 100 noslip iterations, and the
# pyramidal cone with 10. Readings: Senua AI's measure (sx_contact creep) and the rig's trace (the slip at the contact).
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds the release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_060_resting_arm_mirror"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
A10="len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717"; H10=0.00059
A13="len1=0.297 len2=0.302 mass1=1.08 mass2=0.578 rb=0.0295 mb=0.194 mu=0.778"; H13=0.00052
mir() { awk -v p="$1" 'BEGIN { split(p, a, ","); printf "%.15g,%.15g", 3.14159265358979323846 - a[1], -a[2] }'; }
CFGS="def: ell:cone=elliptic n10:cone=elliptic|noslip=10 n100:cone=elliptic|noslip=100 pyr10:noslip=10"
X="$W/p60"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
( cd "$X" || exit 2
  MUJOCO_DIR="$W/mujoco-3.16.0" tools/build_rig.sh mjc_arm > /dev/null 2>&1
  mkdir -p p; S=p/stats.txt; : > $S
  for arm in s10:0.604,1.158:1 s10:1.149,-0.545:2 s13:0.516,0.907:1 s13:1.211,-0.464:2; do
    an=${arm%%:*}; rest=${arm#*:}; PS=${rest%:*}; k=${rest##*:}
    if [ $an = s10 ]; then a=$A10; h=$H10; else a=$A13; h=$H13; fi
    for side in as mirror; do
      if [ $side = as ]; then Q=$PS; else Q=$(mir "$PS"); fi
      for c in $CFGS; do
        cn=${c%%:*}; opts=$(echo "${c#*:}" | tr '|' ' ')
        n=${an}_pose${k}_${side}_$cn
        # shellcheck disable=SC2086
        tools/mjc_arm p/$n.txt dt=0.00114 pose=$Q pose0=$Q $a h0=$h secs=2 $opts trace=p/$n.trace | sed "s|^STATS|STATS run $n|" >> $S
      done
    done
  done )
rm -rf "${O:?}/p"; cp -R "$X/p" "$O/"; rm -rf "${X:?}"
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  for f in $(cd "$O/p" && ls *.txt | grep -v stats | sed 's/\.txt$//' | sort); do
    cr=$(fld "$("$B" creep "$O/p/$f.txt" | tail -1)" mean_speed_ums)
    sl=$(awk '{ s[NR] = $0 } END { h = int(NR / 2); for (i = h + 1; i <= NR; i++) { split(s[i], c, " "); x += c[3] } printf "%.1f", x / (NR - h) }' "$O/p/$f.trace")
    echo "$f creep_ums $cr slip_x_ums $sl $(tail -1 "$O/p/$f.txt" | awk '{ printf "sideways_over_normal %.4f", ($5 != 0) ? $6 / $5 : 0 }')"
  done
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
