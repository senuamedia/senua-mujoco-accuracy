#!/usr/bin/env bash
# Run 081: the eighteenth registered study (preregistrations/PREREGISTRATION_18.md), played once: MuJoCo's RK4
# integrator, for issue 11, the integrators do not keep a free body's energy. Google DeepMind's Linux release of MuJoCo
# 3.16.0, no build. The plays, at a drawn step and a quarter, a sixteenth and a sixty-fourth of it, under each of
# MuJoCo's four integrators (Euler, its default; implicitfast; implicit; RK4): a fresh two-link chain on two hinges with
# nothing acting on it, no gravity, set turning (the rig tools/mjc_chain.c, run 007's scene); a fresh rigid body tumbling
# with nothing acting on it (tools/mjc_tumble.c, Study 9's scene); and, reported only, the same chain swinging under
# gravity from rest. Every number drawn from seed 18 (DRAW=1 prints the draw and plays nothing). Every rule judged by
# sx_contact rule; the chain read by sx_contact chain, the tumbling body by sx_tumble.
# DRY=1 plays throwaway numbers (run 007's chain and Study 9's dry-run body) into dry/; no rule is read from it.
# usage: play.sh <folder holding sx_contact and sx_tumble> <work folder>
#        (repository root, on the cloud machine; the work folder holds the release in mujoco-3.16.0)
set -u
draw() {  # the registered numbers from the seed: Study 10's procedure, from x(0) = 18
  local x=18 V=0 D=""
  pick() { x=$(( (x * 1103515245 + 12345) % 2147483648 )); V=$(( $1 + x * ($2 - $1 + 1) / 2147483648 )); }
  dec() { local v=$1 p=$2 s="" d=1 i; [ "$v" -lt 0 ] && { s="-"; v=$(( -v )); }
    for ((i = 0; i < p; i++)); do d=$(( d * 10 )); done
    if [ "$p" -eq 0 ]; then echo "$s$v"; else printf "%s%d.%0${p}d\n" "$s" $(( v / d )) $(( v % d )); fi; }
  plain() { echo "$1" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
  # the values a kind may not take: Study 17's lists, the values Studies 9 and 17 drew, the chain of runs 007, 014 and
  # 039, and those this draw has already given to that kind
  SEEN_step=" 0.00003125 0.000125 0.00015625 0.00025 0.0003 0.0003125 0.000375 0.0004 0.0004075 0.0005 0.000625 0.001 0.0012 0.00125 0.0015 0.0016 0.00163 0.002 0.0025 0.004 0.006 0.008 0.01 0.012 0.015 0.02 0.03 0.04 0.00114 0.000285 0.00165 0.0004125 0.0001425 0.00057 0.000855 0.016 0.00116 0.00029 0.00168 0.00042 0.00119 0.0002975 0.00171 0.0004275 0.00122 0.000305 0.0001525 0.00174 0.000435 "
  SEEN_len=" 0.0004 0.0005 0.0006 0.007 0.008 0.009 0.01 0.011 0.012 0.014 0.015 0.02 0.025 0.026 0.0271 0.028 0.03 0.032 0.033 0.035 0.038 0.04 0.042 0.043 0.045 0.05 0.08 0.09 0.1 0.2 0.24 0.25 0.26 0.267 0.27 0.273 0.28 0.29 0.3 0.32 0.4 0.5 0.0434 0.0392 0.096 0.0312 0.0093 0.0424 0.017 0.271 0.275 0.0264 0.00059 0.0121 0.0435 0.0336 0.0079 0.0499 0.0431 0.097 0.0305 0.0097 0.0439 0.0485 0.403 0.0454 0.0331 0.071 0.0349 0.0098 0.297 0.302 0.0295 0.00052 0.298 0.269 0.0273 0.00054 0.0146 0.0449 0.0426 0.07 0.0326 0.0077 0.279 0.286 0.0284 0.00043 0.0129 0.041 0.0314 0.083 0.0334 0.0092 0.001 0.0405 0.0489 0.0437 "
  SEEN_mass=" 0.15 0.161 0.17 0.18 0.2 0.22 0.24 0.25 0.35 0.4 0.45 0.5 0.519 0.6 0.9 0.95 1 1.023 1.05 1.1 1.15 1.2 1.3 1.4 1.6 2 3 5 1.861 0.881 0.202 0.442 1.113 0.524 0.176 1.381 0.218 1.903 0.908 0.248 0.408 1.423 1.714 1.438 0.209 1.08 0.578 0.194 1.164 0.522 0.167 1.564 1.7 0.225 1.116 0.436 0.199 1.56 1.704 0.21 0.596 1.561 1.505 "
  SEEN_ang=" 0 0.15 0.2 0.3 0.35 0.4 0.5 0.6 0.65 0.7 0.75 0.9 0.95 1 1.1 1.2 1.25 1.3 2.2 2.3 2.4 2.5 3 -0.3 -0.33 -0.45 -0.5 -0.6 -0.7 -0.9 -2 -2.1 -2.2 "
  SEEN_inertia=" 0.0045 0.0072 0.0101 0.011372 0.009324 0.007512 "
  SEEN_spin=" 1.4 1.5 2.2 2.5 3 -3.1 2.52 2 -0.83 "
  q() {  # q <kind> <name> <lo> <hi> <places>: one quantity, drawn again while its value is one its kind may not take
    local k="$1" v p seen
    while :; do
      pick "$3" "$4"; v="$(dec "$V" "$5")"; p="$(plain "$v")"
      eval "seen=\"\${SEEN_$k:- }\""
      case "$seen" in *" $p "*) echo "  ($2 drawn again: $v)" ;; *) eval "SEEN_$k=\"\${SEEN_$k:- }$p \""; break ;; esac
    done
    D="$p"; [ "${QUIET:-0}" = 1 ] || echo "$2 $p"
  }
  local ok i1 i2 i3 w1 w2 w3
  # the step: from 5 to 10 ms, as run 007's 10 ms and Study 9's ladder, then a quarter, a sixteenth and a sixty-fourth
  q step dt_base 500 1000 5
  # the chain (run 007's ranges about its scene: two cube arms on two hinges)
  q mass mass1 900 1500 3; q mass mass2 400 900 3; q len radius 300 500 4
  q len arm1 200 300 3; q len len1 400 600 3; q len arm2 150 250 3
  q ang angle2 -1200 -500 3; q spin omega1 150 350 2; q spin omega2 80 200 2
  q ang swing1 200 600 3; q ang swing2 -900 -400 3
  # the tumbling body (Study 9's procedure): its principal moments drawn again, all three, until they can belong to a
  # body (each at most the sum of the other two) and no two are within 1 part in 10 of each other
  while :; do
    QUIET=1 q inertia i1 3000 12000 6; i1=$D; QUIET=1 q inertia i2 3000 12000 6; i2=$D; QUIET=1 q inertia i3 3000 12000 6; i3=$D
    ok=$(awk -v a="$i1" -v b="$i2" -v c="$i3" 'function apart(x, y) { return (x > y ? x - y : y - x) * 10 > (x > y ? x : y) }
      BEGIN { print (a <= b + c && b <= a + c && c <= a + b && apart(a, b) && apart(b, c) && apart(a, c)) ? 1 : 0 }')
    [ "$ok" = 1 ] && break
    echo "  (moments drawn again: $i1 $i2 $i3)"
  done
  echo "i1 $i1"; echo "i2 $i2"; echo "i3 $i3"
  # its spin: drawn again, all three, until its size is from 2 to 4 rad/s and each component is at least 0.5 rad/s
  while :; do
    QUIET=1 q spin w1 -350 350 2; w1=$D; QUIET=1 q spin w2 -350 350 2; w2=$D; QUIET=1 q spin w3 -350 350 2; w3=$D
    ok=$(awk -v a="$w1" -v b="$w2" -v c="$w3" 'function big(x) { return (x < 0 ? -x : x) >= 0.5 }
      BEGIN { s = a * a + b * b + c * c; print (s >= 4 && s <= 16 && big(a) && big(b) && big(c)) ? 1 : 0 }')
    [ "$ok" = 1 ] && break
    echo "  (spin drawn again: $w1 $w2 $w3)"
  done
  echo "w1 $w1"; echo "w2 $w2"; echo "w3 $w3"
}
if [ "${DRAW:-0}" = 1 ]; then draw; exit 0; fi
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; TB="$M/sx_tumble"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
INTEGS="Euler implicitfast implicit RK4"; SECS=2
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_081_study_18/dry"; mkdir -p "$O"
  BASE=0.01; ARMS="mass1=1.2 mass2=0.6 radius=0.04 arm1=0.25 len1=0.5 arm2=0.2"; FREE="angle2=-0.9 omega1=2.5 omega2=1.5"
  SWING="angle1=0.4 angle2=-0.7"; BODY="i1=0.0045 i2=0.0072 i3=0.0101 w1=2.2 w2=1.4 w3=-3.1"
else
  O="$R/validation/run_081_study_18"; mkdir -p "$O"; draw > "$O/draw.txt"
  v() { awk -v k="$1" '$1 == k { print $2 }' "$O/draw.txt"; }
  BASE=$(v dt_base)
  ARMS="mass1=$(v mass1) mass2=$(v mass2) radius=$(v radius) arm1=$(v arm1) len1=$(v len1) arm2=$(v arm2)"
  FREE="angle2=$(v angle2) omega1=$(v omega1) omega2=$(v omega2)"; SWING="angle1=$(v swing1) angle2=$(v swing2)"
  BODY="i1=$(v i1) i2=$(v i2) i3=$(v i3) w1=$(v w1) w2=$(v w2) w3=$(v w3)"
fi
DTS=$(for k in 1 4 16 64; do awk -v b="$BASE" -v k="$k" 'BEGIN { printf "%.9g ", b / k }'; done)
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
{
  echo "steps $DTS; chain $ARMS; free (no gravity) $FREE; swinging (gravity, from rest) $SWING; tumbling body $BODY; $SECS s each"
} > "$O/parameters.txt"
X=$(mktemp -d); cp -R "$R/tools" "$X/"
( cd "$X" || exit 2
  for n in mjc_chain mjc_tumble; do MUJOCO_DIR="$W/mujoco-3.16.0" tools/build_rig.sh $n > /dev/null; done
  mkdir -p plays; S=plays/stats.txt; : > $S
  for integ in $INTEGS; do
    for dt in $DTS; do
      # shellcheck disable=SC2086
      tools/mjc_chain plays/free_${integ}_$dt.txt dt=$dt $ARMS gravity=0 $FREE secs=$SECS integ=$integ | sed "s|^STATS|STATS run free_${integ}_$dt|" >> $S
      # shellcheck disable=SC2086
      tools/mjc_chain plays/swing_${integ}_$dt.txt dt=$dt $ARMS gravity=1 $SWING secs=$SECS integ=$integ | sed "s|^STATS|STATS run swing_${integ}_$dt|" >> $S
      # shellcheck disable=SC2086
      tools/mjc_tumble plays/tumble_${integ}_$dt.txt dt=$dt integ=$integ $BODY secs=$SECS | sed "s|^STATS|STATS run tumble_${integ}_$dt|" >> $S
    done
  done )
rm -rf "${O:?}/plays"; cp -R "$X/plays" "$O/"; rm -rf "${X:?}"
echo "played $(date -u +%FT%TZ)" >> "$O/progress.txt"
# measuring
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  for integ in $INTEGS; do
    for dt in $DTS; do
      c=$("$B" chain "$O/plays/free_${integ}_$dt.txt" | tail -1); s=$("$B" chain "$O/plays/swing_${integ}_$dt.txt" | tail -1)
      t=$("$TB" tumble "$O/plays/tumble_${integ}_$dt.txt" | tail -1)
      echo "free $integ $dt energy_largest_ppm $(fld "$c" energy_largest_drift_ppm) momentum_largest_ppm $(fld "$c" momentum_largest_drift_ppm)"
      echo "swing $integ $dt energy_largest_ppm $(fld "$s" energy_largest_drift_ppm)"
      echo "tumble $integ $dt energy_largest_ppm $(fld "$t" energy_largest_ppm) momentum_largest_ppm $(fld "$t" momentum_largest_ppm)"
    done
  done
  echo "warnings $(grep -o 'warnings [0-9]*' "$O/plays/stats.txt" | awk '{ s += $2 } END { print s + 0 }')"
} > "$O/measured.txt"
if [ "${DRY:-0}" = 1 ]; then echo "dry run: $(wc -l < "$O/measured.txt") measured lines"; date -u +%FT%TZ > "$O/finished.txt"; exit 0; fi
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
ab() { local x=$1; echo "${x#-}"; }
# shellcheck disable=SC2086
set -- $DTS; D1=$1
# ---- the rules, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" | tail -1; }
  # required: MuJoCo's default integrator does not keep them, at the drawn step
  rule Q1_euler_chain_drifts ge "$(ab "$(get "free Euler $D1" energy_largest_ppm)")" 1000
  rule Q2_euler_tumble_drifts ge "$(ab "$(get "tumble Euler $D1" energy_largest_ppm)")" 1000
  # RK4 keeps them, at every step
  # shellcheck disable=SC2046
  rule R1_rk4_chain_energy all_le 100 $(for dt in $DTS; do ab "$(get "free RK4 $dt" energy_largest_ppm)"; done)
  # shellcheck disable=SC2046
  rule R2_rk4_chain_momentum all_le 100 $(for dt in $DTS; do ab "$(get "free RK4 $dt" momentum_largest_ppm)"; done)
  # shellcheck disable=SC2046
  rule R3_rk4_tumble_energy all_le 100 $(for dt in $DTS; do ab "$(get "tumble RK4 $dt" energy_largest_ppm)"; done)
  # shellcheck disable=SC2046
  rule R4_rk4_tumble_momentum all_le 100 $(for dt in $DTS; do ab "$(get "tumble RK4 $dt" momentum_largest_ppm)"; done)
  rule V1_warnings eq "$(get warnings warnings)" 0
} > "$O/rules.txt"
{
  echo "rules: $(grep -c '^RULE' "$O/rules.txt"), held: $(grep -c ': HELD$' "$O/rules.txt")"
} >> "$O/rules.txt"
date -u +%FT%TZ > "$O/finished.txt"
