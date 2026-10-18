#!/usr/bin/env bash
# Run 040: the ninth registered study (preregistrations/PREREGISTRATION_09.md), played once.
#   Part A: the inverse weight in the current pose, third version (patches/invweight_at_pose_v3.diff, switch
#   MUJOCO_INVWEIGHT_AT_POSE=1), on a weld equality, on an arm the probes did not use, written three ways; Study 8's
#   rules. Part B: a free tumbling body under each of MuJoCo's integrators at the step ladder, a registered measurement
#   of known issue M10: its energy and the magnitude of its angular momentum against bounds fixed before any play.
# Arms: release (Google DeepMind's Linux release), off (the patched build, switch unset), on (switch set), each making
# the same plays: the weld, the tumbling body, both contact suites. MuJoCo's own test suite: the release's test build
# (run 020's recipe) and the patched test build, switch unset and set. Every number of the plays is drawn from seed 9
# (DRAW=1 prints the draw and plays nothing). Every rule judged by sx_contact rule; the tumbling body read by sx_tumble.
# DRY=1 plays throwaway parameters (run 039's arm, poses and body) on the release arm only, into dry/, with no build and
# no MuJoCo suite; no rule is read from it.
# usage: play.sh <folder holding sx_contact and sx_tumble> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src, the release in mujoco-3.16.0, and
#        run 020's release test build in t20-release)
set -u
draw() {  # the registered numbers from the seed: a stream x(n+1) = (1103515245 x(n) + 12345) mod 2^31 from x(0) = 9,
          # each number mapped onto its range's grid; a value its kind may not take is drawn again
  local x=9 V=0 D=""
  pick() { x=$(( (x * 1103515245 + 12345) % 2147483648 )); V=$(( $1 + x * ($2 - $1 + 1) / 2147483648 )); }
  dec() { local v=$1 p=$2 s="" d=1 i; [ "$v" -lt 0 ] && { s="-"; v=$(( -v )); }
    for ((i = 0; i < p; i++)); do d=$(( d * 10 )); done
    if [ "$p" -eq 0 ]; then echo "$s$v"; else printf "%s%d.%0${p}d\n" "$s" $(( v / d )) $(( v % d )); fi; }
  plain() { echo "$1" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
  # the values a kind may not take: those the record used for the same kind (every setting of that kind in the record's
  # play, probe and runner scripts, and the rigs' defaults where a study played them), and those this draw has
  # already given to that kind
  SEEN_step=" 0.00015625 0.000625 0.0025 0.01 0.0003125 0.00125 0.0003 0.0012 0.000375 0.0015 0.0004 0.0016 0.0005 0.002 0.00025 0.001 0.000125 0.00003125 "
  SEEN_len=" 0.24 0.26 0.27 0.28 0.29 0.3 0.32 0.5 0.025 0.026 0.028 0.03 0.032 0.033 0.035 0.038 0.04 0.042 0.043 0.045 0.05 0.4 0.1 0.2 0.25 "
  SEEN_mass=" 0.15 0.17 0.18 0.2 0.22 0.24 0.25 0.35 0.4 0.45 0.5 0.6 0.9 0.95 1 1.05 1.1 1.15 1.2 1.3 1.4 1.6 2 3 "
  SEEN_ang=" 0 0.15 0.2 0.3 0.35 0.4 0.5 0.6 0.65 0.7 0.75 0.9 0.95 1 1.1 1.2 1.25 1.3 2.2 2.3 2.4 2.5 3 -0.3 -0.33 -0.45 -0.5 -0.6 -0.7 -0.9 -2 -2.1 -2.2 "
  SEEN_inertia=" 0.0045 0.0072 0.0101 "
  SEEN_spin=" 1.4 1.5 2.2 2.5 3 -3.1 "
  q() {  # q <kind> <name> <lo> <hi> <places>: one quantity, drawn again while its value is one its kind may not take
    local k="$1" v p seen
    while :; do
      pick "$3" "$4"; v="$(dec "$V" "$5")"; p="$(plain "$v")"
      eval "seen=\"\${SEEN_$k:- }\""
      case "$seen" in *" $p "*) echo "  ($2 drawn again: $v)" ;; *) eval "SEEN_$k=\"\${SEEN_$k:- }$p \""; break ;; esac
    done
    D="$p"; [ "${QUIET:-0}" = 1 ] || echo "$2 $p"
  }
  local c ok i1 i2 i3 w1 w2 w3
  # the steps: the coarse step on a grid of 0.01 ms, the fine a quarter of it
  q step dt_coarse 100 200 5; c=$D; echo "dt_fine $(awk -v c="$c" 'BEGIN { printf "%.9g", c / 4 }')"
  # the arm
  q len len1 260 300 3; q len len2 240 320 3; q mass mass1 900 1200 3; q mass mass2 350 600 3; q len rb 250 300 4
  q mass mb 150 200 3
  # the weld's two poses (shoulder, elbow) and the folded writing's elbow
  q ang weld1_q1 0 400 3; q ang weld1_q2 600 1000 3; q ang weld2_q1 0 400 3; q ang weld2_q2 600 1000 3
  q ang fold 2200 2500 3
  # the tumbling body: the three moments drawn again, all three, until no moment is more than the sum of the other two
  # (as for any rigid body) and no two are within 1 part in 10 of each other
  while :; do
    QUIET=1 q inertia i1 3000 12000 6; i1=$D; QUIET=1 q inertia i2 3000 12000 6; i2=$D; QUIET=1 q inertia i3 3000 12000 6; i3=$D
    ok=$(awk -v a="$i1" -v b="$i2" -v c="$i3" 'function apart(x, y) { return (x > y ? x - y : y - x) * 10 > (x > y ? x : y) }
      BEGIN { print (a <= b + c && b <= a + c && c <= a + b && apart(a, b) && apart(b, c) && apart(a, c)) ? 1 : 0 }')
    [ "$ok" = 1 ] && break
    echo "  (moments drawn again: $i1 $i2 $i3)"
  done
  echo "i1 $i1"; echo "i2 $i2"; echo "i3 $i3"
  # its spin, along its own axes: drawn again, all three, until its size is from 2 to 4 rad/s and each component is at
  # least 0.5 rad/s in size (a general axis, away from every principal axis)
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
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; T="$M/sx_tumble"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
J=$(nproc); PF="$R/patches/invweight_at_pose_v3.diff"; LADDER="0.01 0.0025 0.000625 0.00015625"
INTEGS="Euler implicitfast implicit RK4"
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_040_study_09/dry"; ARMS="release"
  ARM="len1=0.29 len2=0.27 mass1=0.95 mass2=0.45 rb=0.026 mb=0.17"; WELDS="0.15,0.75 0.3,1.0"; FOLD=0,2.4
  DTS="0.0016 0.0004"; BODY="i1=0.0045 i2=0.0072 i3=0.0101 w1=2.2 w2=1.4 w3=-3.1 secs=2"
  mkdir -p "$O"
else
  O="$R/validation/run_040_study_09"; ARMS="release off on"
  mkdir -p "$O"; draw > "$O/draw.txt"
  v() { awk -v k="$1" '$1 == k { print $2 }' "$O/draw.txt"; }
  ARM="len1=$(v len1) len2=$(v len2) mass1=$(v mass1) mass2=$(v mass2) rb=$(v rb) mb=$(v mb)"
  WELDS="$(v weld1_q1),$(v weld1_q2) $(v weld2_q1),$(v weld2_q2)"; FOLD=0,$(v fold); DTS="$(v dt_coarse) $(v dt_fine)"
  BODY="i1=$(v i1) i2=$(v i2) i3=$(v i3) w1=$(v w1) w2=$(v w2) w3=$(v w3) secs=2"
fi
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
echo "arm $ARM welds $WELDS fold $FOLD steps $DTS body $BODY" > "$O/parameters.txt"
if [ "${DRY:-0}" != 1 ]; then
  rm -rf "${W:?}/mujoco-s9-src" && mkdir -p "$W/mujoco-s9-src" && (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-s9-src"
  (cd "$W/mujoco-s9-src" && patch -p1 -s < "$PF")
  echo "release source $(git -C "$W/mujoco-src" rev-parse HEAD); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-s9-src" -B "$W/s9-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$W/mujoco-s9-build" && cmake --build "$W/s9-lib" -j"$J" && cmake --install "$W/s9-lib" ) > "$O/build_lib.log" 2>&1
  echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
  ( cmake -S "$W/mujoco-s9-src" -B "$W/t40-s9" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t40-s9" -j"$J" ) > "$O/build_tests.log" 2>&1
  echo "build tests exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
fi
arm() {  # <name> <MuJoCo folder> [switch]: the plays every arm makes, the same in each
  local name=$1 mj=$2 sw=${3:-} X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"; mkdir -p "$X/suites"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_pair mjc_arm mjc_tumble; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
    if [ -n "$sw" ]; then export MUJOCO_INVWEIGHT_AT_POSE=$sw; else unset MUJOCO_INVWEIGHT_AT_POSE; fi
    tools/contact_suite.sh defaults > /dev/null; tools/contact_suite2.sh defaults > /dev/null
    mkdir -p runs tumble; S=runs/stats.txt; : > $S
    k=0
    for PS in $WELDS; do
      k=$((k + 1))
      for dt in $DTS; do for wr in native straight folded; do
        case $wr in native) P0=$PS ;; straight) P0=0,0 ;; folded) P0=$FOLD ;; esac
        # shellcheck disable=SC2086
        tools/mjc_arm runs/weld_pose${k}_${dt}_$wr.txt dt=$dt pose=$PS pose0=$P0 tipweld=1 h0=1 secs=2 $ARM | sed "s|^STATS|STATS run weld_pose${k}_${dt}_$wr|" >> $S
      done; done
    done
    T2=tumble/stats.txt; : > $T2
    for integ in $INTEGS; do for dt in $LADDER; do
      # shellcheck disable=SC2086
      tools/mjc_tumble tumble/tumble_${integ}_$dt.txt dt=$dt integ=$integ $BODY | sed "s|^STATS|STATS run tumble_${integ}_$dt|" >> $T2
    done; done )
  rm -rf "${O:?}/${name:?}"; mkdir -p "$O/$name"; cp -R "$X/runs" "$X/tumble" "$X/suites" "$O/$name/"; rm -rf "${X:?}"
  echo "arm $name played $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
for a in $ARMS; do
  case $a in release) arm release "$W/mujoco-3.16.0" ;; off) arm off "$W/mujoco-s9-build" ;; on) arm on "$W/mujoco-s9-build" 1 ;; esac
done
if [ "${DRY:-0}" != 1 ]; then
  suite() {  # <build folder> <label> [switch]
    ( cd "$1" && if [ -n "${3:-}" ]; then export MUJOCO_INVWEIGHT_AT_POSE=$3; else unset MUJOCO_INVWEIGHT_AT_POSE; fi
      ctest --timeout 900 -j"$J" > "$O/ctest_$2.txt" 2>&1 )
    echo "suite $2 exit $? $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1) $(date -u +%FT%TZ)" >> "$O/progress.txt"
  }
  suite "$W/t20-release" release
  suite "$W/t40-s9" off
  suite "$W/t40-s9" on 1
  for a in release off on; do
    awk 'match($0, /Test +#[0-9]+: /) {
           hdr = substr($0, RSTART, RLENGTH); num = hdr; gsub(/[^0-9]/, "", num); rest = substr($0, RSTART + RLENGTH)
           st = "unknown"
           if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) {
             st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st) }
           name = rest; p = index(name, "  # GetParam()"); if (p > 0) name = substr(name, 1, p - 1)
           p = index(name, " ...."); if (p > 0) name = substr(name, 1, p - 1); sub(/ +$/, "", name)
           print num, name, st }' "$O/ctest_$a.txt" | sort -n > "$O/suite_results_$a.txt"
  done
fi
# measuring: every number a rule reads, from Senua AI's measures or the rigs' own STATS lines (plumbing extracts them)
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  for a in $ARMS; do
    d=$O/$a/runs
    for k in 1 2; do for dt in $DTS; do
      n=$d/weld_pose${k}_${dt}_native.txt
      for wr in straight folded; do
        e=$("$B" ends "$n" "$d/weld_pose${k}_${dt}_$wr.txt" | tail -1)
        echo "$a weld pose$k $dt $wr apart_nm $(fld "$e" place_apart_nm) speed_apart_ums $(fld "$e" speed_apart_ums)"
      done
    done; done
    for integ in $INTEGS; do for dt in $LADDER; do
      t=$("$T" tumble "$O/$a/tumble/tumble_${integ}_$dt.txt" | tail -1)
      echo "$a tumble $integ $dt energy_end_ppm $(fld "$t" energy_end_ppm) energy_largest_ppm $(fld "$t" energy_largest_ppm) momentum_end_ppm $(fld "$t" momentum_end_ppm) momentum_largest_ppm $(fld "$t" momentum_largest_ppm)"
    done; done
    lim=0; wrn=0
    for f in "$O/$a/runs/stats.txt" "$O/$a/tumble/stats.txt" "$O/$a/suites/1/defaults/stats.txt" "$O/$a/suites/2/defaults/stats.txt"; do
      lim=$((lim + $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
      wrn=$((wrn + $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
    done
    echo "$a solver at_iteration_limit $lim warnings $wrn"
  done
} > "$O/measured.txt"
if [ "${DRY:-0}" = 1 ]; then echo "dry run: $(wc -l < "$O/measured.txt") measured lines"; date -u +%FT%TZ > "$O/finished.txt"; exit 0; fi
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
# ---- the rules, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" | tail -1; }
  n=0; same=0; for f in $(cd "$O/release" && find runs tumble suites -type f | sort); do n=$((n + 1)); cmp -s "$O/release/$f" "$O/off/$f" && same=$((same + 1)); done
  rule R1_safe_when_off_plays eq "$same" "$n"
  rule R2_safe_when_off_suite eq "$(diff "$O/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>')" 0
  for k in 1 2; do for dt in $DTS; do
    rule "R3_defect_weld_pose${k}_$dt" ge "$(get "release weld pose$k $dt straight" apart_nm)" 1000
    for wr in straight folded; do
      rule "R4_place_weld_pose${k}_${dt}_$wr" le "$(get "on weld pose$k $dt $wr" apart_nm)" 100
      rule "R5_speed_weld_pose${k}_${dt}_$wr" le "$(get "on weld pose$k $dt $wr" speed_apart_ums)" 10
    done
  done; done
  n=0; same=0; for f in $(cd "$O/release" && find suites tumble -type f | sort); do n=$((n + 1)); cmp -s "$O/release/$f" "$O/on/$f" && same=$((same + 1)); done
  rule R7_suites_and_tumble_on_as_released eq "$same" "$n"
  rule R8_mujoco_suite_on_as_off eq "$(diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep -c '^>')" 0
  rule R9_iteration_limit eq "$(get "on solver" at_iteration_limit)" 0
  rule R9_warnings eq "$(get "on solver" warnings)" 0
  for integ in $INTEGS; do for dt in $LADDER; do
    case $dt in 0.01) eb=5000 ;; 0.0025) eb=1000 ;; *) eb=500 ;; esac
    rule "T1_energy_${integ}_$dt" le "$(get "release tumble $integ $dt" energy_largest_ppm)" $eb
    rule "T2_momentum_${integ}_$dt" le "$(get "release tumble $integ $dt" momentum_largest_ppm)" 100
  done; done
  diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep '^>' | sed 's/^> /reported: changed with the switch set: /'
} > "$O/rules.txt"
echo "rules: $(grep -c '^RULE' "$O/rules.txt"), held: $(grep -c ': HELD$' "$O/rules.txt")" >> "$O/rules.txt"
date -u +%FT%TZ > "$O/finished.txt"
