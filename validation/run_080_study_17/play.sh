#!/usr/bin/env bash
# Run 080: the seventeenth registered study (preregistrations/PREREGISTRATION_17.md), played once: MuJoCo's own
# frictionless contact, condim 1, for issue 12, a friction of 0 raised to 1e-5. Google DeepMind's Linux release of MuJoCo
# 3.16.0, under MuJoCo's defaults (rel_def) and under Senua AI's configuration, the elliptic cone with 100 noslip
# iterations (rel_rec); no build. The plays, at the drawn coarse step and a quarter of it: a fresh cube set sliding on a
# ground of friction 0, 2 s, along 0, 22.5 and 45 degrees, kept from turning and free to turn, once with MuJoCo's default
# contact (condim 3, where MuJoCo raises the friction to 1e-5) and once with condim 1. Every number of the plays drawn
# from seed 17 (DRAW=1 prints the draw and plays nothing). Every rule judged by sx_contact rule.
# DRY=1 plays throwaway numbers (run 063's cube and steps) on both arms into dry/; no rule is read from it.
# usage: play.sh <folder holding sx_contact> <work folder>
#        (repository root, on the cloud machine; the work folder holds the release in mujoco-3.16.0)
set -u
draw() {  # the registered numbers from the seed: Study 10's procedure, from x(0) = 17
  local x=17 V=0 D=""
  pick() { x=$(( (x * 1103515245 + 12345) % 2147483648 )); V=$(( $1 + x * ($2 - $1 + 1) / 2147483648 )); }
  dec() { local v=$1 p=$2 s="" d=1 i; [ "$v" -lt 0 ] && { s="-"; v=$(( -v )); }
    for ((i = 0; i < p; i++)); do d=$(( d * 10 )); done
    if [ "$p" -eq 0 ]; then echo "$s$v"; else printf "%s%d.%0${p}d\n" "$s" $(( v / d )) $(( v % d )); fi; }
  plain() { echo "$1" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
  # the values a kind may not take: Study 16's lists, the values Study 16 drew, the settings of runs 077 to 079, and those
  # this draw has already given to that kind
  SEEN_step=" 0.00003125 0.000125 0.00015625 0.00025 0.0003 0.0003125 0.000375 0.0004 0.0004075 0.0005 0.000625 0.001 0.0012 0.00125 0.0015 0.0016 0.00163 0.002 0.0025 0.004 0.006 0.008 0.01 0.012 0.015 0.02 0.03 0.04 0.00114 0.000285 0.00165 0.0004125 0.0001425 0.00057 0.000855 0.016 0.00116 0.00029 0.00168 0.00042 0.00119 0.0002975 0.00171 0.0004275 0.00122 0.000305 0.0001525 "
  SEEN_len=" 0.0004 0.0005 0.0006 0.007 0.008 0.009 0.01 0.011 0.012 0.014 0.015 0.02 0.025 0.026 0.0271 0.028 0.03 0.032 0.033 0.035 0.038 0.04 0.042 0.043 0.045 0.05 0.08 0.09 0.1 0.2 0.24 0.25 0.26 0.267 0.27 0.273 0.28 0.29 0.3 0.32 0.4 0.5 0.0434 0.0392 0.096 0.0312 0.0093 0.0424 0.017 0.271 0.275 0.0264 0.00059 0.0121 0.0435 0.0336 0.0079 0.0499 0.0431 0.097 0.0305 0.0097 0.0439 0.0485 0.403 0.0454 0.0331 0.071 0.0349 0.0098 0.297 0.302 0.0295 0.00052 0.298 0.269 0.0273 0.00054 0.0146 0.0449 0.0426 0.07 0.0326 0.0077 0.279 0.286 0.0284 0.00043 0.0129 0.041 0.0314 0.083 0.0334 0.0092 0.001 0.0405 0.0489 "
  SEEN_mass=" 0.15 0.161 0.17 0.18 0.2 0.22 0.24 0.25 0.35 0.4 0.45 0.5 0.519 0.6 0.9 0.95 1 1.023 1.05 1.1 1.15 1.2 1.3 1.4 1.6 2 3 5 1.861 0.881 0.202 0.442 1.113 0.524 0.176 1.381 0.218 1.903 0.908 0.248 0.408 1.423 1.714 1.438 0.209 1.08 0.578 0.194 1.164 0.522 0.167 1.564 1.7 0.225 1.116 0.436 0.199 1.56 1.704 0.21 0.596 1.561 "
  SEEN_speed=" 0.3 0.6 0.8 0.85 0.9 0.95 1 1.1 1.2 1.5 2 2.4 3 4 5 1.01 3.24 1.47 3.67 1.16 0.81 3.19 0.98 4.35 0.86 2.97 0.96 3.5 1.15 3.36 1.45 4.53 0.94 3.51 1.28 3.62 1.09 "
  q() {  # q <kind> <name> <lo> <hi> <places>: one quantity, drawn again while its value is one its kind may not take
    local k="$1" v p seen
    while :; do
      pick "$3" "$4"; v="$(dec "$V" "$5")"; p="$(plain "$v")"
      eval "seen=\"\${SEEN_$k:- }\""
      case "$seen" in *" $p "*) echo "  ($2 drawn again: $v)" ;; *) eval "SEEN_$k=\"\${SEEN_$k:- }$p \""; break ;; esac
    done
    D="$p"; [ "${QUIET:-0}" = 1 ] || echo "$2 $p"
  }
  local c
  q step dt_coarse 100 200 5; c=$D; echo "dt_fine $(awk -v c="$c" 'BEGIN { printf "%.9g", c / 4 }')"
  # the cube (Study 10's ranges for the cube held and slid)
  q mass cube_mass 1000 2000 3; q len cube_half 400 500 4; q speed cube_v 80 120 2
}
if [ "${DRAW:-0}" = 1 ]; then draw; exit 0; fi
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
DIRS="0 22.5 45"; LOCKS="1 0"; ARMS="rel_def rel_rec"; SECS=2
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_080_study_17/dry"; mkdir -p "$O"
  DTS="0.00114 0.000285"; CMASS=1.861; CHALF=0.0434; CV=1.01
else
  O="$R/validation/run_080_study_17"; mkdir -p "$O"; draw > "$O/draw.txt"
  v() { awk -v k="$1" '$1 == k { print $2 }' "$O/draw.txt"; }
  DTS="$(v dt_coarse) $(v dt_fine)"; CMASS=$(v cube_mass); CHALF=$(v cube_half); CV=$(v cube_v)
fi
CUBE="mass=$CMASS radius=$CHALF"
LEAST=$(awk -v s="$SECS" 'BEGIN { printf "%d", 0.00001 * 9.8 * s * 1e6 + 0.5 }')
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
{
  echo "steps $DTS; cube $CUBE slid at $CV m/s for $SECS s on a ground of friction 0, along $DIRS degrees, locked $LOCKS"
  echo "under condim 3 MuJoCo raises the friction to 1e-5 (mjMINMU): the speed that friction takes in $SECS s, 1e-5 g t, is $LEAST um/s"
} > "$O/parameters.txt"
arm() {  # <name> <def|rec>: the plays every arm makes, the same in each
  local name=$1 cfg=$2 X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    MUJOCO_DIR="$W/mujoco-3.16.0" tools/build_rig.sh mjc_contact > /dev/null
    case $cfg in rec) OPTS="cone=elliptic noslip=100" ;; *) OPTS="" ;; esac
    mkdir -p slides; S=slides/stats.txt; : > $S
    for dt in $DTS; do
      for dir in $DIRS; do
        for lk in $LOCKS; do
          for cd in 3 1; do
            p=c${cd}_${dir}_lock${lk}_$dt
            # shellcheck disable=SC2086
            tools/mjc_contact slides/$p.txt dt=$dt h0=0 vx0=$CV mu=0 $CUBE secs=$SECS lock=$lk dir=$dir condim=$cd $OPTS | sed "s|^STATS|STATS run $p|" >> $S
          done
        done
      done
    done )
  rm -rf "${O:?}/${name:?}"; mkdir -p "$O/$name"; cp -R "$X/slides" "$O/$name/"; rm -rf "${X:?}"
  echo "arm $name played $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
for a in $ARMS; do arm "$a" "${a#rel_}"; done
# measuring
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
st() { grep "^STATS run $2 " "$1" | head -1; }
{
  for a in $ARMS; do
    for dt in $DTS; do for dir in $DIRS; do for lk in $LOCKS; do for cd in 3 1; do
      p=c${cd}_${dir}_lock${lk}_$dt; f="$O/$a/slides/$p.txt"
      lost=$(awk '$1 == "CONTACT" { for (i = 1; i < NF; i++) if ($i == "vx0_ums") v0 = $(i + 1); next } { v = $3 } END { printf "%d", v0 - v }' "$f")
      echo "$a slide $cd $dir $lk $dt speed_lost_ums $lost side_um $(fld "$(st "$O/$a/slides/stats.txt" "$p")" side_um) highest_um $(fld "$("$B" hover "$f" | tail -1)" highest_um)"
    done; done; done; done
    echo "$a solver most_iterations $(grep -o 'most_iterations [0-9]*' "$O/$a/slides/stats.txt" | awk '{ if ($2 > m) m = $2 } END { print m + 0 }') at_iteration_limit $(grep -o 'at_iteration_limit [0-9]*' "$O/$a/slides/stats.txt" | awk '{ s += $2 } END { print s + 0 }') warnings $(grep -o 'warnings [0-9]*' "$O/$a/slides/stats.txt" | awk '{ s += $2 } END { print s + 0 }')"
  done
} > "$O/measured.txt"
if [ "${DRY:-0}" = 1 ]; then echo "dry run: $(wc -l < "$O/measured.txt") measured lines"; date -u +%FT%TZ > "$O/finished.txt"; exit 0; fi
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
ab() { local x=$1; echo "${x#-}"; }
each() {  # <arm> <condim> <field>: the field of every slide of the arm with that condim
  local a=$1 cd=$2 k=$3 dt dir lk
  for dt in $DTS; do for dir in $DIRS; do for lk in $LOCKS; do get "$a slide $cd $dir $lk $dt" "$k"; done; done; done
}
# ---- the rules, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" | tail -1; }
  for a in $ARMS; do
    # required: with condim 3 and a friction of 0, each slide loses speed to MuJoCo's least friction
    # shellcheck disable=SC2046
    rule "${a}_Q1_least_friction_slows" all_ge $((LEAST / 2)) $(each "$a" 3 speed_lost_ums)
    # condim 1: no friction at all
    # shellcheck disable=SC2046
    rule "${a}_F1_keeps_its_speed" all_le 1 $(for x in $(each "$a" 1 speed_lost_ums); do ab "$x"; done)
    # shellcheck disable=SC2046
    rule "${a}_F2_keeps_its_line" all_le 1 $(for x in $(each "$a" 1 side_um); do ab "$x"; done)
    # shellcheck disable=SC2046
    rule "${a}_F3_stays_on_the_ground" all_le 1 $(each "$a" 1 highest_um)
    rule "${a}_V1_iteration_limit" eq "$(get "$a solver" at_iteration_limit)" 0
    rule "${a}_V1_warnings" eq "$(get "$a solver" warnings)" 0
  done
} > "$O/rules.txt"
{
  echo "rules: $(grep -c '^RULE' "$O/rules.txt"), held: $(grep -c ': HELD$' "$O/rules.txt")"
} >> "$O/rules.txt"
date -u +%FT%TZ > "$O/finished.txt"
