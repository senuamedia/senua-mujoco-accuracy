#!/usr/bin/env bash
# Run 044: the eleventh registered study (preregistrations/PREREGISTRATION_11.md), played once. The fixes in the wild
# for a held object that creeps (finding F1, known issue M1), each held by Senua AI's Measure to the same known answers
# as Senua AI's own fix, on fresh numbers. Run 043's probe, with its numbers drawn from seed 11 and its rules judged.
#   Part A, on Google DeepMind's 3.16.0 release: MuJoCo's defaults; impratio 10 and 100; the elliptic cone alone and
#     with impratio 10; noslip under the default cone; and Senua AI's recommended configuration, the elliptic cone with
#     10 noslip iterations. On the holds (three pushes, three directions, two steps) and the grips.
#   Part B, MuJoCo pull request #3349's stiction (run 043's pr3349.diff), on its own builds: june, MuJoCo at the commit
#     the pull request branched from (55c6332f); off and on, its head with the flag unset and set; cfg, Senua AI's
#     configuration on its head. All on the elliptic cone, the only cone stiction applies to. On the holds; a held cube
#     moved 2 mm from outside (teleport); a held cube shoved past its limit with the state saved before the shove
#     restored after it (restore), beside the same play without the detour; and the pull request's own two demo scenes,
#     as its author wrote them (on), with the flag line removed (june, off) and with it removed and 10 noslip iterations
#     (cfg). MuJoCo's own test suite on june and on the pull request's head, the flag unset; the two memory-heavy reader
#     tests (LargeTexture) played on their own, one at a time.
# Every reading is Senua AI's measuring program's (creep, gap, ends); file comparisons are cmp; every rule is judged by
# sx_contact rule. DRAW=1 prints the draw and plays nothing. DRY=1 plays run 043's numbers with no build and no MuJoCo
# suite, on the builds run 043 left in the work folder, into dry/; no rule is read from it.
# usage: play.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds mujoco-src, a clone of google-deepmind/mujoco, and the release in mujoco-3.16.0)
set -u
draw() {  # the registered numbers from the seed: Study 10's procedure, from x(0) = 11
  local x=11 V=0 D=""
  pick() { x=$(( (x * 1103515245 + 12345) % 2147483648 )); V=$(( $1 + x * ($2 - $1 + 1) / 2147483648 )); }
  dec() { local v=$1 p=$2 s="" d=1 i; [ "$v" -lt 0 ] && { s="-"; v=$(( -v )); }
    for ((i = 0; i < p; i++)); do d=$(( d * 10 )); done
    if [ "$p" -eq 0 ]; then echo "$s$v"; else printf "%s%d.%0${p}d\n" "$s" $(( v / d )) $(( v % d )); fi; }
  plain() { echo "$1" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
  # the values a kind may not take: Study 10's lists, the values Study 10 drew (run 043 played them too), and those
  # this draw has already given to that kind
  SEEN_step=" 0.00003125 0.000125 0.00015625 0.00025 0.0003 0.0003125 0.000375 0.0004 0.0004075 0.0005 0.000625 0.001 0.0012 0.00125 0.0015 0.0016 0.00163 0.002 0.0025 0.004 0.006 0.008 0.01 0.012 0.015 0.02 0.03 0.04  0.00114 0.000285 "
  SEEN_len=" 0.0004 0.0005 0.0006 0.007 0.008 0.009 0.01 0.011 0.012 0.014 0.015 0.02 0.025 0.026 0.0271 0.028 0.03 0.032 0.033 0.035 0.038 0.04 0.042 0.043 0.045 0.05 0.08 0.09 0.1 0.2 0.24 0.25 0.26 0.267 0.27 0.273 0.28 0.29 0.3 0.32 0.4 0.5  0.0434 0.0392 0.096 0.0312 0.0093 0.0424 0.017 0.271 0.275 0.0264 0.00059 0.0121 "
  SEEN_mass=" 0.15 0.161 0.17 0.18 0.2 0.22 0.24 0.25 0.35 0.4 0.45 0.5 0.519 0.6 0.9 0.95 1 1.023 1.05 1.1 1.15 1.2 1.3 1.4 1.6 2 3 5  1.861 0.881 0.202 0.442 1.113 0.524 0.176 "
  SEEN_fric=" 0 0.1 0.2 0.3 0.35 0.4 0.45 0.48 0.5 0.55 0.58 0.6 0.62 0.65 0.68 0.7 0.72 0.75 0.8  0.39 0.371 0.421 0.772 0.524 0.717 "
  SEEN_speed=" 0.3 0.6 0.8 0.85 0.9 0.95 1 1.1 1.2 1.5 2 2.4 3 4 5 "
  SEEN_ang=" 0 0.15 0.197 0.2 0.3 0.305 0.35 0.4 0.5 0.6 0.627 0.65 0.7 0.75 0.9 0.95 0.961 1 1.1 1.2 1.25 1.3 2.2 2.234 2.3 2.4 2.5 3 -0.3 -0.33 -0.45 -0.5 -0.6 -0.7 -0.9 -2 -2.1 -2.2 "
  SEEN_force=" 2.45 2.8 2.94 3 3.2  2.48 "
  SEEN_torque=" 1.5 5 5.5 6 12 "
  SEEN_inertia=" 0.0045 0.0072 0.0101 0.007512 0.009324 0.011372 "
  SEEN_spin=" 1.4 1.5 2 2.2 2.5 2.52 3 -0.83 -3.1 "
  q() {  # q <kind> <name> <lo> <hi> <places>: one quantity, drawn again while its value is one its kind may not take
    local k="$1" v p seen
    while :; do
      pick "$3" "$4"; v="$(dec "$V" "$5")"; p="$(plain "$v")"
      eval "seen=\"\${SEEN_$k:- }\""
      case "$seen" in *" $p "*) echo "  ($2 drawn again: $v)" ;; *) eval "SEEN_$k=\"\${SEEN_$k:- }$p \""; break ;; esac
    done
    D="$p"; [ "${QUIET:-0}" = 1 ] || echo "$2 $p"
  }
  local c ok gm gmu gs
  q step dt_coarse 100 200 5; c=$D; echo "dt_fine $(awk -v c="$c" 'BEGIN { printf "%.9g", c / 4 }')"
  q mass cube_mass 1000 2000 3; q len cube_half 400 500 4; q fric cube_mu 350 500 3
  q mass grip_mass 200 250 3; gm=$D; q len grip_half 300 350 4; q fric grip_mu 680 800 3; gmu=$D
  while :; do
    QUIET=1 q force grip_squeeze 245 320 2; gs=$D
    ok=$(awk -v m="$gm" -v u="$gmu" -v s="$gs" 'BEGIN { r = 2 * u * s / (m * 9.8); print (r >= 1.7 && r <= 2) ? 1 : 0 }')
    [ "$ok" = 1 ] && break
    echo "  (grip_squeeze drawn again: $gs)"
  done
  echo "grip_squeeze $gs"
  q len grip_offset 70 100 4
}
if [ "${DRAW:-0}" = 1 ]; then draw; exit 0; fi
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
J=$(nproc); BASE=55c6332f207b5ff2a67addfb3b606570791da8f2; HEAD=4c7bdaf692e7bec1018b91b2c9c24265cec476a7
DIFF="$R/validation/run_043_fixes_in_the_wild/pr3349.diff"
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_044_study_11/dry"; mkdir -p "$O"; BLD=p43
  DTS="0.00114 0.000285"; CMASS=1.861; CHALF=0.0434; CMU=0.39; GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"; GOFF=0.0093
else
  O="$R/validation/run_044_study_11"; BLD=p44; draw > "$O/draw.txt"
  v() { awk -v k="$1" '$1 == k { print $2 }' "$O/draw.txt"; }
  DTS="$(v dt_coarse) $(v dt_fine)"; CMASS=$(v cube_mass); CHALF=$(v cube_half); CMU=$(v cube_mu)
  GRIP="mass=$(v grip_mass) radius=$(v grip_half) mu=$(v grip_mu) squeeze=$(v grip_squeeze)"; GOFF=$(v grip_offset)
fi
set -- $DTS; DC=$1
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
if [ "${DRY:-0}" != 1 ]; then
  # the two builds of part B, from MuJoCo's own repository: the pull request's head and the commit it branched from
  ( cd "$W/mujoco-src" && { git cat-file -e $HEAD 2>/dev/null || git fetch -q origin pull/3349/head; } \
      && { git cat-file -e $BASE 2>/dev/null || git fetch -q origin $BASE; } )
  echo "pull request head $HEAD; branched from $BASE; its changed lines, sha256 $(cd "$W/mujoco-src" && git diff $BASE $HEAD | grep '^[-+]' | grep -v '^+++\|^---' | sha256sum | cut -c1-16); run 043's pr3349.diff's $(grep '^[-+]' "$DIFF" | grep -v '^+++\|^---' | sha256sum | cut -c1-16)" > "$O/build_check.txt"
  for pair in june:$BASE pr:$HEAD; do
    n=${pair%%:*}; rev=${pair#*:}
    rm -rf "${W:?}/mujoco-p44$n-src" "$W/p44$n-lib" "$W/mujoco-p44$n-build" "$W/t44$n" && mkdir -p "$W/mujoco-p44$n-src"
    (cd "$W/mujoco-src" && git archive $rev) | tar x -C "$W/mujoco-p44$n-src"
    ( cmake -S "$W/mujoco-p44$n-src" -B "$W/p44$n-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
        -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
        -DCMAKE_INSTALL_PREFIX="$W/mujoco-p44$n-build" && cmake --build "$W/p44$n-lib" -j"$J" && cmake --install "$W/p44$n-lib" ) > "$O/build_lib_$n.log" 2>&1
    log "build lib $n exit $?"
    echo "$n $(sha256sum "$W/mujoco-p44$n-build/lib/libmujoco.so" | cut -c1-16) $(grep -m1 'define mjVERSION_HEADER' "$W/mujoco-p44$n-src/include/mujoco/mujoco.h")" >> "$O/build_check.txt"
    ( cmake -S "$W/mujoco-p44$n-src" -B "$W/t44$n" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
        -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t44$n" -j"$J" ) > "$O/build_tests_$n.log" 2>&1
    log "build tests $n exit $?"
  done
fi
# the pull request's demo scenes, as its author wrote them, and with the stiction flag line removed
for s in ramp gripper; do
  awk -v f="model/stiction/$s.xml" '$0 == "diff --git a/" f " b/" f { p = 1; next } p && /^diff --git/ { exit } p && /^\+/ && !/^\+\+\+/ { print substr($0, 2) }' "$DIFF" > "$O/$s.xml"
  grep -v '<flag stiction="enable"/>' "$O/$s.xml" > "$O/${s}_noflag.xml"
done
DIRS="0 22.5 45"; FRS="0.5 0.75 0.95"
CUBE="h0=0 mu=$CMU mass=$CMASS radius=$CHALF"; LIM=$(awk -v u="$CMU" -v m="$CMASS" 'BEGIN { printf "%.6f", u * m * 9.8 }')
P06=$(awk -v l="$LIM" 'BEGIN { printf "%.6f", 0.6 * l }'); P15=$(awk -v l="$LIM" 'BEGIN { printf "%.6f", 1.5 * l }')
echo "cube $CUBE limit $LIM N; grip $GRIP offset $GOFF; steps $DTS; teleport 2 mm at 0.8 s; shove 1.5 of the limit from 0.7 to 0.75 s, state saved at 0.6 s and restored at 1.2 s; demos 6 s" > "$O/parameters.txt"
rigs() {  # <scratch folder> <MuJoCo folder>: the rigs built against that MuJoCo
  mkdir -p "$1" && cp -R "$R/tools" "$1/" && (cd "$1" && for n in mjc_contact mjc_grip mjc_scene; do MUJOCO_DIR=$2 tools/build_rig.sh $n > /dev/null 2>&1 || echo "rig $n failed against $2" >> "$O/progress.txt"; done)
}
holds() {  # <scratch folder> <out folder> <options...>
  local X=$1 F=$2; shift 2
  mkdir -p "$F"; : > "$F/stats.txt"
  for dt in $DTS; do for dir in $DIRS; do for fr in $FRS; do
    p=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
    "$X/tools/mjc_contact" "$F/hold_${dir}_${fr}_$dt.txt" dt=$dt $CUBE push=$p pushat=0.4 secs=1.6 dir=$dir "$@" | sed "s|^STATS|STATS run hold_${dir}_${fr}_$dt|" >> "$F/stats.txt"
  done; done; done
}
# part A: the release
XA="$W/p44rel"; rm -rf "$XA"; rigs "$XA" "$W/mujoco-3.16.0"
for arm in "defaults:" "impratio10:impratio=10" "impratio100:impratio=100" "elliptic:cone=elliptic" \
           "elliptic_impratio10:cone=elliptic impratio=10" "noslip_pyramidal:noslip=10" "configuration:cone=elliptic noslip=10"; do
  name=${arm%%:*}; opts=${arm#*:}
  # shellcheck disable=SC2086
  holds "$XA" "$O/A/$name" $opts
  for off in 0 $GOFF; do for pad in box mesh; do
    # shellcheck disable=SC2086
    "$XA/tools/mjc_grip" "$O/A/$name/grip_${pad}_off$off" dt=$DC offset=$off pad=$pad $GRIP $opts | sed "s|^STATS|STATS run grip_${pad}_off$off|" >> "$O/A/$name/stats.txt"
  done; done
  log "part A $name played"
done
rm -rf "$XA"
# part B: the pull request's builds
for arm in "june:june:cone=elliptic" "off:pr:cone=elliptic" "on:pr:cone=elliptic stiction=1" "cfg:pr:cone=elliptic noslip=10"; do
  name=${arm%%:*}; rest=${arm#*:}; build=${rest%%:*}; opts=${rest#*:}
  X="$W/p44$name"; rm -rf "$X"; rigs "$X" "$W/mujoco-$BLD$build-build"
  F="$O/B/$name"
  # shellcheck disable=SC2086
  holds "$X" "$F" $opts
  for dt in $DTS; do
    # shellcheck disable=SC2086
    "$X/tools/mjc_contact" "$F/teleport_$dt.txt" dt=$dt $CUBE push=$P06 pushat=0.4 secs=1.6 dir=22.5 teleport=0.8,0.002 $opts | sed "s|^STATS|STATS run teleport_$dt|" >> "$F/stats.txt"
    # shellcheck disable=SC2086
    "$X/tools/mjc_contact" "$F/shove_$dt.txt" dt=$dt $CUBE push=$P06 pushat=0.4 secs=1.6 dir=22.5 pulse=$P15,0.7,0.75 $opts | sed "s|^STATS|STATS run shove_$dt|" >> "$F/stats.txt"
    # shellcheck disable=SC2086
    "$X/tools/mjc_contact" "$F/shove_restored_$dt.txt" dt=$dt $CUBE push=$P06 pushat=0.4 secs=1.6 dir=22.5 pulse=$P15,0.7,0.75 restore=0.6,1.2 $opts | sed "s|^STATS|STATS run shove_restored_$dt|" >> "$F/stats.txt"
  done
  for s in ramp gripper; do
    case $s in ramp) ax="0.8660254037844386,0,-0.5"; bd=block ;; gripper) ax="0,0,-1"; bd=box ;; esac
    case $name in on) sc="$O/$s.xml"; so="" ;; cfg) sc="$O/${s}_noflag.xml"; so="noslip=10" ;; *) sc="$O/${s}_noflag.xml"; so="" ;; esac
    # shellcheck disable=SC2086
    "$X/tools/mjc_scene" "$F/demo_$s.txt" scene="$sc" body=$bd axis=$ax secs=6 $so | sed "s|^STATS|STATS run demo_$s|" >> "$F/stats.txt"
  done
  rm -rf "$X"
  log "part B $name played"
done
if [ "${DRY:-0}" != 1 ]; then
  # MuJoCo's own test suite on both builds, the flag unset; the two memory-heavy reader tests on their own
  for n in june pr; do
    ( cd "$W/t44$n" && ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$n.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_${n}_large.txt" 2>&1 )
    log "suite $n $(grep -E 'tests passed|tests failed' "$O/ctest_$n.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_${n}_large.txt" | tail -1)"
    cat "$O/ctest_$n.txt" "$O/ctest_${n}_large.txt" > "$O/ctest_${n}_all.txt"
  done
  ( cd "$O" && sed -e 's/ctest_\$n.txt/ctest_${n}_all.txt/' "$R/validation/run_043_fixes_in_the_wild/suite_reread.sh" > suite_reread.sh && bash suite_reread.sh )
fi
# measuring: every number from Senua AI's measuring program; file comparisons by cmp
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  for F in "$O"/A/* "$O"/B/*; do
    a=$(basename "$(dirname "$F")")/$(basename "$F")
    for dt in $DTS; do for dir in $DIRS; do for fr in $FRS; do
      echo "$a hold $dir $fr $dt creep_ums $(fld "$("$B" creep "$F/hold_${dir}_${fr}_$dt.txt" | tail -1)" mean_speed_ums)"
    done; done; done
    for g in "$F"/grip_*.txt; do
      [ -f "$g" ] || continue; case $g in *_tilt.txt) continue ;; esac
      echo "$a grip $(basename "$g" .txt) creep_ums $(fld "$("$B" creep "$g" | tail -1)" mean_speed_ums)"
    done
    for dt in $DTS; do
      [ -f "$F/teleport_$dt.txt" ] || continue
      echo "$a teleport $dt creep_after_ums $(fld "$("$B" creep "$F/teleport_$dt.txt" | tail -1)" mean_speed_ums)"
      ns=$(awk -v t=$dt 'BEGIN { printf "%d", t * 1e9 + 0.5 }')
      g=$("$B" gap $ns "$F/shove_$dt.txt" "$F/shove_restored_$dt.txt" | tail -1)
      e=$("$B" ends "$F/shove_$dt.txt" "$F/shove_restored_$dt.txt" | tail -1)
      echo "$a restore $dt identical $(cmp -s "$F/shove_$dt.txt" "$F/shove_restored_$dt.txt" && echo 1 || echo 0) $g | end $(fld "$e" place_apart_nm) nm $(fld "$e" speed_apart_ums) um/s"
    done
    for s in ramp gripper; do
      [ -f "$F/demo_$s.txt" ] || continue
      echo "$a demo $s creep_ums $(fld "$("$B" creep "$F/demo_$s.txt" | tail -1)" mean_speed_ums) moved_at_end_nm $(tail -1 "$F/demo_$s.txt" | awk '{ print $2 }')"
    done
    m=$(grep -o 'most_iterations [0-9]*' "$F/stats.txt" | awk '{ if ($2 > x) x = $2 } END { print x + 0 }')
    l=$(grep -o 'at_iteration_limit [0-9]*' "$F/stats.txt" | awk '{ s += $2 } END { print s + 0 }')
    w=$(grep -o 'warnings [0-9]*' "$F/stats.txt" | awk '{ s += $2 } END { print s + 0 }')
    echo "$a solver most_iterations $m at_iteration_limit $l warnings $w"
  done
  n=0; s=0; for f in $(cd "$O/B/june" && ls hold_*.txt demo_*.txt); do n=$((n + 1)); cmp -s "$O/B/june/$f" "$O/B/off/$f" && s=$((s + 1)); done
  echo "safe_when_off files_same $s of $n"
} > "$O/measured.txt"
if [ "${DRY:-0}" = 1 ]; then echo "dry run: $(wc -l < "$O/measured.txt") measured lines"; date -u +%FT%TZ > "$O/finished.txt"; exit 0; fi
# ---- the rules, each judged by sx_contact rule
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
ab() { local x=$1; echo "${x#-}"; }
{
  rule() { "$B" rule "$@" | tail -1; }
  for a in defaults impratio10 impratio100 elliptic elliptic_impratio10 noslip_pyramidal configuration; do
    # shellcheck disable=SC2046
    rule "A_${a}_H_every_hold_holds" all_le 10 $(for dt in $DTS; do for dir in $DIRS; do for fr in $FRS; do ab "$(get "A/$a hold $dir $fr $dt" creep_ums)"; done; done; done)
    # shellcheck disable=SC2046
    rule "A_${a}_G_every_grip_holds" all_le 10 $(for off in 0 $GOFF; do for pad in box mesh; do ab "$(get "A/$a grip grip_${pad}_off$off" creep_ums)"; done; done)
    rule "A_${a}_V_iteration_limit" eq "$(get "A/$a solver" at_iteration_limit)" 0
    rule "A_${a}_V_warnings" eq "$(get "A/$a solver" warnings)" 0
  done
  for a in june off on cfg; do
    # shellcheck disable=SC2046
    rule "B_${a}_H_every_hold_holds" all_le 10 $(for dt in $DTS; do for dir in $DIRS; do for fr in $FRS; do ab "$(get "B/$a hold $dir $fr $dt" creep_ums)"; done; done; done)
    # shellcheck disable=SC2046
    rule "B_${a}_T_moved_from_outside_stays" all_le 10 $(for dt in $DTS; do ab "$(get "B/$a teleport $dt" creep_after_ums)"; done)
    for dt in $DTS; do rule "B_${a}_S_restored_state_replays_${dt}" eq "$(get "B/$a restore $dt" identical)" 1; done
    # shellcheck disable=SC2046
    rule "B_${a}_D_the_pull_requests_demos_hold" all_le 10 $(for s in ramp gripper; do ab "$(get "B/$a demo $s" creep_ums)"; done)
    rule "B_${a}_V_iteration_limit" eq "$(get "B/$a solver" at_iteration_limit)" 0
    rule "B_${a}_V_warnings" eq "$(get "B/$a solver" warnings)" 0
  done
  rule E1_pull_request_off_as_june eq "$(get safe_when_off files_same)" "$(awk '/^safe_when_off/ { print $5 }' "$O/measured.txt")"
  rule E2_pull_request_suite_as_june eq "$(awk '/^shared:/ { print $NF }' "$O/suite_compare.txt")" 0
} > "$O/rules.txt"
{
  echo "rules: $(grep -c '^RULE' "$O/rules.txt"), held: $(grep -c ': HELD$' "$O/rules.txt")"
  for a in A_defaults A_impratio10 A_impratio100 A_elliptic A_elliptic_impratio10 A_noslip_pyramidal A_configuration B_june B_off B_on B_cfg; do
    echo "$a: $(grep -c "^RULE ${a}_[A-Z]" "$O/rules.txt"), held $(grep "^RULE ${a}_[A-Z]" "$O/rules.txt" | grep -c ': HELD$')"
  done
} >> "$O/rules.txt"
date -u +%FT%TZ > "$O/finished.txt"
