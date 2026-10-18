#!/usr/bin/env bash
# Run 051: the twelfth registered study (preregistrations/PREREGISTRATION_12.md), played once: the de Saxce patch's
# fourth version (patches/in_design/desaxce_elliptic_v4.diff, switch MUJOCO_DESAXCE=1) on fresh numbers, for issues 4
# and 5 of docs/issues.md: a sliding body hops off the surface (finding F3), and a free cube has a direction under the
# elliptic cone (F12). Nine arms, each in its own scratch copy, each making the same plays: the release (Google
# DeepMind's Linux release of MuJoCo 3.16.0), the patched build with its switch unset, and the patched build with it set,
# each under MuJoCo's defaults (def), under Senua AI's configuration, the elliptic cone with 10 noslip iterations (rec),
# and under the elliptic cone alone (ell). The plays, at the drawn coarse step and a quarter of it: a cube held at 0.5,
# 0.75 and 0.95 of its friction limit and slid along 0, 22.5 and 45 degrees, kept from turning; the same cube slid free
# to turn along 0, 11.25, 22.5, 33.75 and 45 degrees; a two-pad grip, box and mesh pads, at the centre and off it;
# straight stacks of 5 and 9 (played and reported, not ruled); and at the record's step ladder, the cube slid along 0
# kept from turning; the first contact suite on a fresh cube. MuJoCo's own test suite on the release's test build and
# on the patched one, switch unset and set. Every number of the plays drawn from seed 12 (DRAW=1 prints the draw and
# plays nothing). Every rule judged by sx_contact rule.
# DRY=1 plays throwaway numbers (Study 10's) on all nine arms, the patched arms on the build already made by run 050
# (mujoco-p50v4-build), with no build and no MuJoCo suite, into dry/; no rule is read from it.
# usage: play.sh <folder holding sx_contact and sx_contact_suite.sh> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src at UPSTREAM_COMMIT, the release in
#        mujoco-3.16.0, and run 020's release test build in t20-release)
set -u
draw() {  # the registered numbers from the seed: Study 10's procedure, from x(0) = 12
  local x=12 V=0 D=""
  pick() { x=$(( (x * 1103515245 + 12345) % 2147483648 )); V=$(( $1 + x * ($2 - $1 + 1) / 2147483648 )); }
  dec() { local v=$1 p=$2 s="" d=1 i; [ "$v" -lt 0 ] && { s="-"; v=$(( -v )); }
    for ((i = 0; i < p; i++)); do d=$(( d * 10 )); done
    if [ "$p" -eq 0 ]; then echo "$s$v"; else printf "%s%d.%0${p}d\n" "$s" $(( v / d )) $(( v % d )); fi; }
  plain() { echo "$1" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
  # the values a kind may not take: Study 11's lists, the values Studies 10 and 11 drew, the settings of runs 043 to 050,
  # and those this draw has already given to that kind
  SEEN_step=" 0.00003125 0.000125 0.00015625 0.00025 0.0003 0.0003125 0.000375 0.0004 0.0004075 0.0005 0.000625 0.001 0.0012 0.00125 0.0015 0.0016 0.00163 0.002 0.0025 0.004 0.006 0.008 0.01 0.012 0.015 0.02 0.03 0.04 0.00114 0.000285 0.00165 0.0004125 0.0001425 0.00057 0.000855 0.016 "
  SEEN_len=" 0.0004 0.0005 0.0006 0.007 0.008 0.009 0.01 0.011 0.012 0.014 0.015 0.02 0.025 0.026 0.0271 0.028 0.03 0.032 0.033 0.035 0.038 0.04 0.042 0.043 0.045 0.05 0.08 0.09 0.1 0.2 0.24 0.25 0.26 0.267 0.27 0.273 0.28 0.29 0.3 0.32 0.4 0.5 0.0434 0.0392 0.096 0.0312 0.0093 0.0424 0.017 0.271 0.275 0.0264 0.00059 0.0121 0.0435 0.0336 0.0079 "
  SEEN_mass=" 0.15 0.161 0.17 0.18 0.2 0.22 0.24 0.25 0.35 0.4 0.45 0.5 0.519 0.6 0.9 0.95 1 1.023 1.05 1.1 1.15 1.2 1.3 1.4 1.6 2 3 5 1.861 0.881 0.202 0.442 1.113 0.524 0.176 1.381 0.218 "
  SEEN_fric=" 0 0.1 0.2 0.3 0.35 0.4 0.45 0.48 0.5 0.55 0.58 0.6 0.62 0.65 0.68 0.7 0.72 0.75 0.8 0.39 0.371 0.421 0.772 0.524 0.717 0.369 0.78 "
  SEEN_speed=" 0.3 0.6 0.8 0.85 0.9 0.95 1 1.1 1.2 1.5 2 2.4 3 4 5 1.01 3.24 1.47 3.67 1.16 "
  SEEN_force=" 2.45 2.8 2.94 3 3.2 2.48 2.58 "
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
  # the steps: the coarse step on a grid of 0.01 ms, the fine a quarter of it
  q step dt_coarse 100 200 5; c=$D; echo "dt_fine $(awk -v c="$c" 'BEGIN { printf "%.9g", c / 4 }')"
  # the cube held, slid kept from turning and slid free to turn
  q mass cube_mass 1000 2000 3; q len cube_half 400 500 4; q fric cube_mu 350 500 3; q speed cube_v 80 120 2
  # the first suite's fresh cube (Study 2's way)
  q mass s1_mass 800 2000 3; q len s1_half 300 450 4; q len s1_h0 70 100 3; q speed s1_vx 200 400 2
  q speed s1_vxchain 90 150 2; q fric s1_mu 300 450 3; q speed s1_vslide 250 500 2; q fric s1_muhold 400 500 3
  # the grip: the squeeze drawn again until the friction of the two pads is from 1.7 to 2 times the cube's weight
  q mass grip_mass 200 250 3; gm=$D; q len grip_half 300 350 4; q fric grip_mu 680 800 3; gmu=$D
  while :; do
    QUIET=1 q force grip_squeeze 245 320 2; gs=$D
    ok=$(awk -v m="$gm" -v u="$gmu" -v s="$gs" 'BEGIN { r = 2 * u * s / (m * 9.8); print (r >= 1.7 && r <= 2) ? 1 : 0 }')
    [ "$ok" = 1 ] && break
    echo "  (grip_squeeze drawn again: $gs)"
  done
  echo "grip_squeeze $gs"
  q len grip_offset 70 100 4
  # the stacks (played and reported)
  q mass stack_mass 350 500 3; q len stack_half 400 500 4; q fric stack_mu 500 600 3
}
if [ "${DRAW:-0}" = 1 ]; then draw; exit 0; fi
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
J=$(nproc); PF="$R/patches/in_design/desaxce_elliptic_v4.diff"; LADDER="0.01 0.0025 0.000625 0.00015625"
DIRS="0 22.5 45"; FDIRS="0 11.25 22.5 33.75 45"; FRS="0.5 0.75 0.95"; NS="5 9"
ARMS="rel_def rel_rec rel_ell off_def off_rec off_ell on_def on_rec on_ell"
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_051_study_12/dry"; V4="$W/mujoco-p50v4-build"; mkdir -p "$O"
  DTS="0.00114 0.000285"; CMASS=1.861; CHALF=0.0434; CMU=0.39; CV=1.01
  S1M=0.881; S1H=0.0392; S1H0=0.096; S1VX=3.24; S1VXC=1.47; S1MU=0.371; S1VS=3.67; S1MUH=0.421
  GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"; GOFF=0.0093; KCUBE="mass=0.442 radius=0.0424 mu=0.524"
else
  O="$R/validation/run_051_study_12"; V4="$W/mujoco-s12-build"; mkdir -p "$O"; draw > "$O/draw.txt"
  v() { awk -v k="$1" '$1 == k { print $2 }' "$O/draw.txt"; }
  DTS="$(v dt_coarse) $(v dt_fine)"; CMASS=$(v cube_mass); CHALF=$(v cube_half); CMU=$(v cube_mu); CV=$(v cube_v)
  S1M=$(v s1_mass); S1H=$(v s1_half); S1H0=$(v s1_h0); S1VX=$(v s1_vx); S1VXC=$(v s1_vxchain); S1MU=$(v s1_mu)
  S1VS=$(v s1_vslide); S1MUH=$(v s1_muhold)
  GRIP="mass=$(v grip_mass) radius=$(v grip_half) mu=$(v grip_mu) squeeze=$(v grip_squeeze)"; GOFF=$(v grip_offset)
  KCUBE="mass=$(v stack_mass) radius=$(v stack_half) mu=$(v stack_mu)"
fi
# derived: the cube's friction limit and Coulomb's distance; the first suite's pushes, lift and reading constants
num() { awk "BEGIN { printf \"%.6f\", $1 }" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
CUBE="mass=$CMASS radius=$CHALF"; LIM=$(num "$CMU * $CMASS * 9.8")
COULOMB=$(awk -v v="$CV" -v u="$CMU" 'BEGIN { printf "%d", v * v / (2 * u * 9.8) * 1e6 + 0.5 }')
S1HOLD=$(num "0.6 * $S1MUH * $S1M * 9.8"); S1SLIP=$(num "1.2 * $S1MUH * $S1M * 9.8"); S1LIFT=$(num "3 * $S1M * 9.8")
S1MU10K=$(awk -v u="$S1MU" 'BEGIN { printf "%d", u * 10000 + 0.5 }'); S1SLIPMN=$(awk -v s="$S1SLIP" 'BEGIN { printf "%d", s * 1000 }')
set -- $DTS; DC=$1; DF=$2
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
{
  echo "steps $DTS; ladder $LADDER; cube $CUBE mu $CMU limit $LIM N speed $CV Coulomb $COULOMB um"
  echo "suite 1: SUITE_CUBE=mass=$S1M radius=$S1H SUITE_H0=$S1H0 SUITE_VX=$S1VX SUITE_VXCHAIN=$S1VXC SUITE_MU=$S1MU SUITE_VSLIDE=$S1VS SUITE_MUHOLD=$S1MUH SUITE_HOLD=$S1HOLD SUITE_SLIP=$S1SLIP SUITE_LIFT=$S1LIFT; read with SUITE_MU10K=$S1MU10K SUITE_SLIPMN=$S1SLIPMN"
  echo "grip $GRIP offset $GOFF; stacks $NS of $KCUBE"
} > "$O/parameters.txt"
if [ "${DRY:-0}" != 1 ]; then
  rm -rf "${W:?}/mujoco-s12-src" "$W/s12-lib" "$V4" "$W/t51-s12" && mkdir -p "$W/mujoco-s12-src"
  (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-s12-src"
  (cd "$W/mujoco-s12-src" && patch -p1 -s < "$PF")
  echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-s12-src" -B "$W/s12-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$V4" && cmake --build "$W/s12-lib" -j"$J" && cmake --install "$W/s12-lib" ) > "$O/build_lib.log" 2>&1
  echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
  ( cmake -S "$W/mujoco-s12-src" -B "$W/t51-s12" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t51-s12" -j"$J" ) > "$O/build_tests.log" 2>&1
  echo "build tests exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
fi
arm() {  # <name> <MuJoCo folder> <def|rec|ell> [switch]: the plays every arm makes, the same in each
  local name=$1 mj=$2 cfg=$3 sw=${4:-} X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"; mkdir -p "$X/suites"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_stack mjc_grip; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
    if [ -n "$sw" ]; then export MUJOCO_DESAXCE=$sw; else unset MUJOCO_DESAXCE; fi
    case $cfg in rec) OPTS="cone=elliptic noslip=10" ;; ell) OPTS="cone=elliptic" ;; *) OPTS="" ;; esac
    # shellcheck disable=SC2086
    ( export SUITE_CUBE="mass=$S1M radius=$S1H" SUITE_H0=$S1H0 SUITE_VX=$S1VX SUITE_VXCHAIN=$S1VXC SUITE_MU=$S1MU \
        SUITE_VSLIDE=$S1VS SUITE_MUHOLD=$S1MUH SUITE_HOLD=$S1HOLD SUITE_SLIP=$S1SLIP SUITE_LIFT=$S1LIFT
      tools/contact_suite.sh fresh $OPTS > /dev/null )
    mkdir -p cubes held stacks; C=cubes/stats.txt; H=held/stats.txt; K=stacks/stats.txt; : > $C; : > $H; : > $K
    for dt in $DTS; do
      for dir in $DIRS; do
        for fr in $FRS; do
          p=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
          # shellcheck disable=SC2086
          tools/mjc_contact held/hold_${dir}_${fr}_$dt.txt dt=$dt h0=0 mu=$CMU $CUBE push=$p pushat=0.4 secs=1.6 dir=$dir $OPTS | sed "s|^STATS|STATS run hold_${dir}_${fr}_$dt|" >> $H
        done
        # shellcheck disable=SC2086
        tools/mjc_contact cubes/slide_${dir}_$dt.txt dt=$dt h0=0 vx0=$CV mu=$CMU $CUBE secs=1.2 dir=$dir $OPTS | sed "s|^STATS|STATS run slide_${dir}_$dt|" >> $C
      done
      for dir in $FDIRS; do
        # shellcheck disable=SC2086
        tools/mjc_contact cubes/free_${dir}_$dt.txt dt=$dt h0=0 vx0=$CV mu=$CMU $CUBE secs=1.2 lock=0 dir=$dir $OPTS trace=cubes/free_${dir}_$dt.trace | sed "s|^STATS|STATS run free_${dir}_$dt|" >> $C
      done
      for off in 0 $GOFF; do for pad in box mesh; do
        # shellcheck disable=SC2086
        tools/mjc_grip held/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $OPTS | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> $H
      done; done
      # shellcheck disable=SC2086
      for n in $NS; do tools/mjc_stack stacks/stack${n}_$dt dt=$dt n=$n secs=2 $KCUBE $OPTS | sed "s|^STATS|STATS run stack${n}_$dt|" >> $K; done
    done
    for dt in $LADDER; do
      # shellcheck disable=SC2086
      tools/mjc_contact cubes/lift_$dt.txt dt=$dt h0=0 vx0=$CV mu=$CMU $CUBE secs=1.2 dir=0 $OPTS | sed "s|^STATS|STATS run lift_$dt|" >> $C
    done )
  rm -rf "${O:?}/${name:?}"; mkdir -p "$O/$name"; cp -R "$X/cubes" "$X/held" "$X/stacks" "$X/suites" "$O/$name/"; rm -rf "${X:?}"
  echo "arm $name played $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
for a in $ARMS; do
  case $a in
    rel_*) arm "$a" "$W/mujoco-3.16.0" "${a#*_}" ;;
    off_*) arm "$a" "$V4" "${a#*_}" ;;
    on_*) arm "$a" "$V4" "${a#*_}" 1 ;;
  esac
done
if [ "${DRY:-0}" != 1 ]; then
  suite() {  # <build folder> <label> [switch]: every test, the two memory-heavy texture tests alone
    ( cd "$1" && if [ -n "${3:-}" ]; then export MUJOCO_DESAXCE=$3; else unset MUJOCO_DESAXCE; fi
      ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$2.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_$2_large.txt" 2>&1 )
    echo "suite $2 $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_$2_large.txt" | tail -1) $(date -u +%FT%TZ)" >> "$O/progress.txt"
  }
  suite "$W/t20-release" release
  suite "$W/t51-s12" off
  suite "$W/t51-s12" on 1
  for a in release off on; do
    cat "$O/ctest_$a.txt" "$O/ctest_${a}_large.txt" | awk 'match($0, /Test +#[0-9]+: /) {
           hdr = substr($0, RSTART, RLENGTH); num = hdr; gsub(/[^0-9]/, "", num); rest = substr($0, RSTART + RLENGTH)
           st = "unknown"
           if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) {
             st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st) }
           name = rest; p = index(name, "  # GetParam()"); if (p > 0) name = substr(name, 1, p - 1)
           p = index(name, " ..."); if (p > 0) name = substr(name, 1, p - 1); sub(/ +$/, "", name)
           print num, name, st }' | sort -n > "$O/suite_results_$a.txt"
  done
fi
# measuring: every number a rule reads, from Senua AI's measures, the first deep dive's suite runner, or the rigs' own
# STATS lines (plumbing extracts them)
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
st() { grep "^STATS run $2 " "$1" | head -1; }
stk() {  # <prefix>: reported, not ruled: the most tilt of any cube over the play; at the last step the largest speed
         # (vx or vz) and spin of any cube
  local p=$1 t s w
  t=$(cat "$p"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }')
  w=$(for f in "$p"_*_tilt.txt; do tail -1 "$f"; done | awk '{ x = $3 < 0 ? -$3 : $3; if (x > m) m = x } END { print m + 0 }')
  s=$(for f in "$p"_[0-9].txt; do tail -1 "$f"; done | awk '{ x = $3 < 0 ? -$3 : $3; y = $4 < 0 ? -$4 : $4; if (x > m) m = x; if (y > m) m = y } END { print m + 0 }')
  echo "most_tilt_urad $t end_speed_ums $s end_spin_urads $w"
}
for a in $ARMS; do
  SUITE_MU10K=$S1MU10K SUITE_SLIPMN=$S1SLIPMN bash "$M/sx_contact_suite.sh" "$O/$a/suites/1/fresh" "$O/$a/suite1.txt" > /dev/null 2>&1
done
{
  for a in $ARMS; do
    c=$O/$a/cubes; h=$O/$a/held
    for dt in $DTS; do
      for dir in $DIRS; do
        for fr in $FRS; do echo "$a hold $dir $fr $dt creep_ums $(fld "$("$B" creep $h/hold_${dir}_${fr}_$dt.txt | tail -1)" mean_speed_ums)"; done
        echo "$a slide $dir $dt slid_um $(fld "$("$B" stop $c/slide_${dir}_$dt.txt | tail -1)" slid_um) side_um $(fld "$(st $c/stats.txt slide_${dir}_$dt)" side_um) highest_um $(fld "$("$B" hover $c/slide_${dir}_$dt.txt | tail -1)" highest_um)"
      done
      for dir in $FDIRS; do
        s=$(st $c/stats.txt free_${dir}_$dt)
        echo "$a free $dir $dt slid_um $(fld "$("$B" stop $c/free_${dir}_$dt.txt | tail -1)" slid_um) side_um $(fld "$s" side_um) most_yaw_urad $(fld "$s" most_yaw_urad) most_tilt_urad $(fld "$s" most_tilt_urad) steps_under_4_contacts $(fld "$s" steps_under_4_contacts)"
      done
      for off in 0 $GOFF; do for pad in box mesh; do
        echo "$a grip $pad $off $dt creep_ums $(fld "$("$B" creep $h/grip_${pad}_off${off}_$dt.txt | tail -1)" mean_speed_ums)"
      done; done
      for n in $NS; do echo "$a stack $n $dt $(stk "$O/$a/stacks/stack${n}_$dt")"; done
    done
    for dt in $LADDER; do
      echo "$a lift $dt highest_um $(fld "$("$B" hover $c/lift_$dt.txt | tail -1)" highest_um) slid_um $(fld "$("$B" stop $c/lift_$dt.txt | tail -1)" slid_um)"
    done
    echo "$a suite1 passed $(grep '^SUITE passed' $O/$a/suite1.txt | awk '{ print $3 }')"
    most=0; lim=0; wrn=0
    for f in "$O/$a/cubes/stats.txt" "$O/$a/held/stats.txt" "$O/$a/stacks/stats.txt" "$O/$a/suites/1/fresh/stats.txt"; do
      m=$(grep -o 'most_iterations [0-9]*' "$f" | awk '{ if ($2 > m) m = $2 } END { print m + 0 }'); [ "$m" -gt "$most" ] && most=$m
      lim=$((lim + $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
      wrn=$((wrn + $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
    done
    echo "$a solver most_iterations $most at_iteration_limit $lim warnings $wrn"
  done
} > "$O/measured.txt"
if [ "${DRY:-0}" = 1 ]; then echo "dry run: $(wc -l < "$O/measured.txt") measured lines"; date -u +%FT%TZ > "$O/finished.txt"; exit 0; fi
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
ab() { local x=$1; echo "${x#-}"; }
most_of() { local m=0 x; for x in "$@"; do x=${x#-}; [ "$x" -gt "$m" ] && m=$x; done; echo "$m"; }
sum_of() { local s=0 x; for x in "$@"; do s=$((s + x)); done; echo "$s"; }
same_files() {  # <arm a> <arm b> <folders...>: how many of a's files in the folders b has byte-identical, and of how many
  local a=$1 b=$2 n=0 s=0 f; shift 2
  for f in $(cd "$O/$a" && find "$@" -type f | sort); do n=$((n + 1)); cmp -s "$O/$a/$f" "$O/$b/$f" && s=$((s + 1)); done
  echo "$s $n"
}
NAMED="SolverTest.ZeroToleranceDisablesTermination ForwardTest.DiscreteImplicitRowNoslip"
diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep '^>' | awk '{ print $3 }' > "$O/suite_changed_on.txt"
# ---- the rules, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" | tail -1; }
  # required: the defects are there in the release, under the configuration and under the elliptic cone alone
  for k in rec ell; do
    rule "Q1_released_lifts_$k" ge "$(get "rel_$k lift 0.01" highest_um)" 100
    # shellcheck disable=SC2046
    rule "Q2_released_direction_$k" ge "$(most_of $(for dt in $DTS; do for dir in $FDIRS; do get "rel_$k free $dir $dt" side_um; done; done))" 10
    # shellcheck disable=SC2046
    rule "Q3_released_corners_$k" ge "$(sum_of $(for dt in $DTS; do for dir in $FDIRS; do get "rel_$k free $dir $dt" steps_under_4_contacts; done; done))" 1
  done
  # safe when off; the pyramidal cone untouched; MuJoCo's suite with the switch set
  for k in def rec ell; do
    # shellcheck disable=SC2046
    rule "E1_safe_when_off_$k" eq $(same_files rel_$k off_$k cubes held stacks suites)
  done
  rule E2_safe_when_off_mujoco_suite eq "$(diff "$O/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>')" 0
  # shellcheck disable=SC2046
  rule P1_pyramidal_untouched eq $(same_files rel_def on_def cubes held stacks suites)
  rule M1_mujoco_suite_named_only eq "$(grep -cvxF -e "${NAMED% *}" -e "${NAMED#* }" "$O/suite_changed_on.txt")" 0
  # the switch set, under the configuration and under the elliptic cone alone
  for k in rec ell; do
    A=on_$k
    # shellcheck disable=SC2046
    rule "${A}_L1_no_lift" all_le 1 $(for dt in $DTS; do for dir in $DIRS; do get "$A slide $dir $dt" highest_um; done; done; for dt in $LADDER; do get "$A lift $dt" highest_um; done)
    # shellcheck disable=SC2046
    rule "${A}_L2_four_corners" eq "$(sum_of $(for dt in $DTS; do for dir in $FDIRS; do get "$A free $dir $dt" steps_under_4_contacts; done; done))" 0
    for dt in $DTS; do
      rule "${A}_D1_no_direction_free_$dt" all_within "$(get "$A free 0 $dt" slid_um)" 10000 $(for dir in 11.25 22.5 33.75 45; do get "$A free $dir $dt" slid_um; done)
      rule "${A}_D1_no_direction_kept_$dt" all_within "$(get "$A slide 0 $dt" slid_um)" 10000 "$(get "$A slide 22.5 $dt" slid_um)" "$(get "$A slide 45 $dt" slid_um)"
      # shellcheck disable=SC2046
      rule "${A}_D2_no_drift_$dt" all_le 10 $(for dir in $FDIRS; do ab "$(get "$A free $dir $dt" side_um)"; done; for dir in $DIRS; do ab "$(get "$A slide $dir $dt" side_um)"; done)
      # shellcheck disable=SC2046
      rule "${A}_D3_no_turn_$dt" all_le 1000 $(for dir in $FDIRS; do ab "$(get "$A free $dir $dt" most_yaw_urad)"; done)
    done
    # shellcheck disable=SC2046
    rule "${A}_C1_coulomb" all_within "$COULOMB" 100 $(for dir in $DIRS; do get "$A slide $dir $DF" slid_um; done; for dir in $FDIRS; do get "$A free $dir $DF" slid_um; done)
    rule "${A}_V1_iteration_limit" eq "$(get "$A solver" at_iteration_limit)" 0
    rule "${A}_V1_warnings" eq "$(get "$A solver" warnings)" 0
  done
  # the switch set, under the configuration: what it holds (Study 2's R2 and R5, Study 10's G1), and nothing held touched
  # shellcheck disable=SC2046
  rule on_rec_H1_every_hold_holds all_le 10 $(for dt in $DTS; do for dir in $DIRS; do for fr in $FRS; do ab "$(get "on_rec hold $dir $fr $dt" creep_ums)"; done; done; done)
  # shellcheck disable=SC2046
  rule on_rec_G1_grip_holds all_le 10 $(for dt in $DTS; do for off in 0 $GOFF; do for pad in box mesh; do ab "$(get "on_rec grip $pad $off $dt" creep_ums)"; done; done; done)
  rule on_rec_K1_ten_tests eq "$(get "on_rec suite1" passed)" 10
  # shellcheck disable=SC2046
  rule on_rec_N1_held_untouched eq $(same_files rel_rec on_rec held)
  # the switch set, under the elliptic cone alone, whose holds creep released (finding F1): each hold and grip within
  # 1 um/s of the release's
  # shellcheck disable=SC2046
  rule on_ell_H2_held_as_released le "$(most_of $(for dt in $DTS; do for dir in $DIRS; do for fr in $FRS; do echo $(( $(get "on_ell hold $dir $fr $dt" creep_ums) - $(get "rel_ell hold $dir $fr $dt" creep_ums) )); done; done; for off in 0 $GOFF; do for pad in box mesh; do echo $(( $(get "on_ell grip $pad $off $dt" creep_ums) - $(get "rel_ell grip $pad $off $dt" creep_ums) )); done; done; done))" 1
  sed 's/^/reported: changed with the switch set: /' "$O/suite_changed_on.txt"
} > "$O/rules.txt"
{
  echo "rules: $(grep -c '^RULE' "$O/rules.txt"), held: $(grep -c ': HELD$' "$O/rules.txt")"
  echo "shared (Q, E, P, M): $(grep -c '^RULE [QEPM][0-9]' "$O/rules.txt"), held: $(grep '^RULE [QEPM][0-9]' "$O/rules.txt" | grep -c ': HELD$')"
  for A in on_rec on_ell; do echo "$A: $(grep -c "^RULE ${A}_[A-Z]" "$O/rules.txt"), held: $(grep "^RULE ${A}_[A-Z]" "$O/rules.txt" | grep -c ': HELD$')"; done
} >> "$O/rules.txt"
date -u +%FT%TZ > "$O/finished.txt"
