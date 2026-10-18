#!/usr/bin/env bash
# Run 077: the sixteenth registered study (preregistrations/PREREGISTRATION_16.md), played once: the box-on-box clip's
# polygon without its collinear vertices (patches/in_design/boxbox_collinear.diff, switch MUJOCO_BOXBOX_COLLINEAR=1), for
# issue 21, a straight stack that does not stand under Senua AI's configuration. One build from MuJoCo's source at
# UPSTREAM_COMMIT with Senua AI's three validated patches (patches/invweight_at_pose_v3.diff, desaxce_elliptic_v4.diff,
# qcqp_reduced.diff) and this one. Seven arms, each in its own scratch copy, each making the same plays: the release
# (Google DeepMind's Linux release of MuJoCo 3.16.0) under MuJoCo's defaults (rel_def) and under the configuration, the
# elliptic cone with 100 noslip iterations (rel_rec); the build with every switch unset under each (off_def, off_rec);
# Study 15's three switches set under the configuration (set_rec); those and the collinear switch (set4_rec); and the
# collinear switch alone under MuJoCo's defaults (col_def). The plays: straight stacks of 3, 5, 9 and 12 fresh cubes, 2 s,
# at the drawn coarse step, a quarter and an eighth of it, at MuJoCo's default main tolerance and at 1e-10 and 1e-12,
# each with its contacts traced; stacks of 3 offset by 1 mm and by 17 mm a cube and a stack of 5 on a fixed box, at the
# quarter step; and, for the byte comparisons, Study 15's arm set down and dropped, a fresh cube held at 0.5 and 0.95 of
# its friction limit, the same cube slid on a fixed box's face, and Study 15's grip, box and mesh pads, at the coarse and
# the quarter step. MuJoCo's own test suite on the release's test build and on the patched one, every switch unset, the
# four set, and the collinear switch alone. Every number of the stacks, the held and slid cube and the steps drawn from
# seed 16 (DRAW=1 prints the draw and plays nothing). Every rule judged by sx_contact rule. The stacks' play files are
# kept compressed (gzip -n), after every reading of them.
# DRY=1 plays throwaway numbers (run 063's cube and steps) on all seven arms on run 075's build of the same four patch
# files, with no build and no MuJoCo suite, into dry/; no rule is read from it.
# usage: play.sh <folder holding sx_contact> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src at UPSTREAM_COMMIT, the release in
#        mujoco-3.16.0, and run 020's release test build in t20-release)
set -u
draw() {  # the registered numbers from the seed: Study 10's procedure, from x(0) = 16
  local x=16 V=0 D=""
  pick() { x=$(( (x * 1103515245 + 12345) % 2147483648 )); V=$(( $1 + x * ($2 - $1 + 1) / 2147483648 )); }
  dec() { local v=$1 p=$2 s="" d=1 i; [ "$v" -lt 0 ] && { s="-"; v=$(( -v )); }
    for ((i = 0; i < p; i++)); do d=$(( d * 10 )); done
    if [ "$p" -eq 0 ]; then echo "$s$v"; else printf "%s%d.%0${p}d\n" "$s" $(( v / d )) $(( v % d )); fi; }
  plain() { echo "$1" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
  # the values a kind may not take: Study 15's lists, the values Study 15 drew, the settings of runs 071 to 076, and those
  # this draw has already given to that kind
  SEEN_step=" 0.00003125 0.000125 0.00015625 0.00025 0.0003 0.0003125 0.000375 0.0004 0.0004075 0.0005 0.000625 0.001 0.0012 0.00125 0.0015 0.0016 0.00163 0.002 0.0025 0.004 0.006 0.008 0.01 0.012 0.015 0.02 0.03 0.04 0.00114 0.000285 0.00165 0.0004125 0.0001425 0.00057 0.000855 0.016 0.00116 0.00029 0.00168 0.00042 0.00119 0.0002975 0.00171 0.0004275 "
  SEEN_len=" 0.0004 0.0005 0.0006 0.007 0.008 0.009 0.01 0.011 0.012 0.014 0.015 0.02 0.025 0.026 0.0271 0.028 0.03 0.032 0.033 0.035 0.038 0.04 0.042 0.043 0.045 0.05 0.08 0.09 0.1 0.2 0.24 0.25 0.26 0.267 0.27 0.273 0.28 0.29 0.3 0.32 0.4 0.5 0.0434 0.0392 0.096 0.0312 0.0093 0.0424 0.017 0.271 0.275 0.0264 0.00059 0.0121 0.0435 0.0336 0.0079 0.0499 0.0431 0.097 0.0305 0.0097 0.0439 0.0485 0.403 0.0454 0.0331 0.071 0.0349 0.0098 0.297 0.302 0.0295 0.00052 0.298 0.269 0.0273 0.00054 0.0146 0.0449 0.0426 0.07 0.0326 0.0077 0.279 0.286 0.0284 0.00043 0.0129 0.041 0.0314 0.083 0.0334 0.0092 0.001 "
  SEEN_mass=" 0.15 0.161 0.17 0.18 0.2 0.22 0.24 0.25 0.35 0.4 0.45 0.5 0.519 0.6 0.9 0.95 1 1.023 1.05 1.1 1.15 1.2 1.3 1.4 1.6 2 3 5 1.861 0.881 0.202 0.442 1.113 0.524 0.176 1.381 0.218 1.903 0.908 0.248 0.408 1.423 1.714 1.438 0.209 1.08 0.578 0.194 1.164 0.522 0.167 1.564 1.7 0.225 1.116 0.436 0.199 1.56 1.704 0.21 "
  SEEN_fric=" 0 0.1 0.2 0.3 0.35 0.4 0.45 0.48 0.5 0.55 0.58 0.6 0.62 0.65 0.68 0.7 0.72 0.75 0.8 0.39 0.371 0.421 0.772 0.524 0.717 0.369 0.78 0.379 0.409 0.432 0.732 0.534 0.44 0.42 0.468 0.762 0.778 0.667 0.411 0.413 0.443 0.689 0.686 0.462 0.416 0.436 0.69 "
  SEEN_speed=" 0.3 0.6 0.8 0.85 0.9 0.95 1 1.1 1.2 1.5 2 2.4 3 4 5 1.01 3.24 1.47 3.67 1.16 0.81 3.19 0.98 4.35 0.86 2.97 0.96 3.5 1.15 3.36 1.45 4.53 0.94 3.51 1.28 3.62 "
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
  q step dt_coarse 100 200 5; c=$D
  echo "dt_fine $(awk -v c="$c" 'BEGIN { printf "%.9g", c / 4 }')"; echo "dt_finer $(awk -v c="$c" 'BEGIN { printf "%.9g", c / 8 }')"
  # the stack's cube (run 026's and Study 12's ranges for stacked cubes); the cube held and slid (Study 10's ranges)
  q mass stack_mass 300 600 3; q len stack_half 350 500 4; q fric stack_mu 400 700 3
  q mass cube_mass 1000 2000 3; q len cube_half 400 500 4; q fric cube_mu 350 500 3; q speed cube_v 80 120 2
}
if [ "${DRAW:-0}" = 1 ]; then draw; exit 0; fi
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
PI="$R/patches/invweight_at_pose_v3.diff"; PD="$R/patches/desaxce_elliptic_v4.diff"; PQ="$R/patches/qcqp_reduced.diff"
PC="$R/patches/in_design/boxbox_collinear.diff"
NS="3 5 9 12"; TOLS="def 1e-10 1e-12"
ARMS="rel_def rel_rec off_def off_rec set_rec set4_rec col_def"
A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"; A15P="0.555,0.905 1.157,-0.378"
GRIP="mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61"; GOFF=0.0092
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_077_study_16/dry"; QB="$W/mujoco-p75-build"; mkdir -p "$O"
  DTS="0.00114 0.000285 0.0001425"; SCUBE="mass=0.442 radius=0.0424 mu=0.524"
  CMASS=1.861; CHALF=0.0434; CMU=0.39; CV=1.01
else
  O="$R/validation/run_077_study_16"; QB="$W/mujoco-s16-build"; mkdir -p "$O"; draw > "$O/draw.txt"
  v() { awk -v k="$1" '$1 == k { print $2 }' "$O/draw.txt"; }
  DTS="$(v dt_coarse) $(v dt_fine) $(v dt_finer)"
  SCUBE="mass=$(v stack_mass) radius=$(v stack_half) mu=$(v stack_mu)"
  CMASS=$(v cube_mass); CHALF=$(v cube_half); CMU=$(v cube_mu); CV=$(v cube_v)
fi
# shellcheck disable=SC2086
set -- $DTS; DC=$1; DF=$2
num() { awk "BEGIN { printf \"%.6f\", $1 }" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
CUBE="mass=$CMASS radius=$CHALF"; LIM=$(num "$CMU * $CMASS * 9.8")
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
{
  echo "steps $DTS; tolerances $TOLS; stacks of $NS: $SCUBE; held and slid cube $CUBE mu $CMU limit $LIM N speed $CV"
  echo "Study 15's arm $A15 in poses $A15P (set down from 0.00043, dropped from 0.0129); Study 15's grip $GRIP offset $GOFF"
} > "$O/parameters.txt"
switches() {  # <none|set|set4|col>
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR
  case $1 in set|set4) export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 ;; esac
  case $1 in set4|col) export MUJOCO_BOXBOX_COLLINEAR=1 ;; esac
}
if [ "${DRY:-0}" != 1 ]; then
  rm -rf "${W:?}/mujoco-s16-src" "$W/s16-lib" "$QB" "$W/t77-s16" && mkdir -p "$W/mujoco-s16-src"
  (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-s16-src"
  (cd "$W/mujoco-s16-src" && patch -p1 -s < "$PI" && patch -p1 -s < "$PD" && patch -p1 -s < "$PQ" && patch -p1 -s < "$PC")
  echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in "$PI" "$PD" "$PQ" "$PC"; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" > "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-s16-src" -B "$W/s16-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$QB" && cmake --build "$W/s16-lib" -j"$J" && cmake --install "$W/s16-lib" ) > "$O/build_lib.log" 2>&1
  echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
  ( cmake -S "$W/mujoco-s16-src" -B "$W/t77-s16" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t77-s16" -j"$J" ) > "$O/build_tests.log" 2>&1
  echo "build tests exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
fi
CHG='{ if ($1 != cs) { if (cs != "") fl(cs); cs = $1 } p = $2 "-" $3; seen[p] = 1; cnt[p]++ }
function fl(st,   p) { for (p in seen) { if (st > 30 && cnt[p] != pc[p]) n++; pc[p] = cnt[p]; cnt[p] = 0 } }
END { fl(cs); print n + 0 }'
arm() {  # <name> <MuJoCo folder> <def|rec> <none|set|set4|col>: the plays every arm makes, the same in each
  local name=$1 mj=$2 cfg=$3 sw=$4 X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_stack mjc_grip mjc_arm; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
    switches "$sw"
    case $cfg in rec) OPTS="cone=elliptic noslip=100" ;; *) OPTS="" ;; esac
    mkdir -p stacks other; S=stacks/stats.txt; C=stacks/changes.txt; T=other/stats.txt; : > $S; : > $C; : > $T
    stack() {  # <name> <settings...>: a stack with its contacts traced and read, the trace not kept
      local p=$1; shift
      tools/mjc_stack "stacks/$p" "$@" contacts="stacks/$p.contacts" | sed "s|^STATS|STATS run $p|" >> $S
      echo "$p $(awk "$CHG" "stacks/$p.contacts")" >> $C
      rm -f "stacks/$p.contacts"
    }
    for dt in $DTS; do
      for tol in $TOLS; do
        if [ "$tol" = def ]; then TT=""; else TT="tolerance=$tol"; fi
        # shellcheck disable=SC2086
        for n in $NS; do stack stack${n}_${tol}_$dt dt=$dt n=$n secs=2 $SCUBE $OPTS $TT; done
      done
    done
    # shellcheck disable=SC2086
    stack offset1_$DF dt=$DF n=3 shift=0.001 secs=2 $SCUBE $OPTS
    # shellcheck disable=SC2086
    stack offset17_$DF dt=$DF n=3 shift=0.017 secs=2 $SCUBE $OPTS
    # shellcheck disable=SC2086
    stack onbox5_$DF dt=$DF n=5 base=0.5 secs=2 $SCUBE $OPTS
    for dt in $DC $DF; do
      k=0
      for PS in $A15P; do
        k=$((k + 1))
        # shellcheck disable=SC2086
        tools/mjc_arm other/rest_pose${k}_$dt.txt dt=$dt pose=$PS pose0=$PS $A15 h0=0.00043 secs=2 $OPTS | sed "s|^STATS|STATS run rest_pose${k}_$dt|" >> $T
        # shellcheck disable=SC2086
        tools/mjc_arm other/drop_pose${k}_$dt.txt dt=$dt pose=$PS pose0=$PS $A15 h0=0.0129 secs=3 $OPTS | sed "s|^STATS|STATS run drop_pose${k}_$dt|" >> $T
      done
      for fr in 0.5 0.95; do
        p=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
        # shellcheck disable=SC2086
        tools/mjc_contact other/hold_${fr}_$dt.txt dt=$dt h0=0 mu=$CMU $CUBE push=$p pushat=0.4 secs=1.6 dir=0 $OPTS | sed "s|^STATS|STATS run hold_${fr}_$dt|" >> $T
      done
      # shellcheck disable=SC2086
      tools/mjc_stack other/slide_box_$dt dt=$dt n=1 vx=$CV secs=1 base=0.5 mass=$CMASS radius=$CHALF mu=$CMU $OPTS | sed "s|^STATS|STATS run slide_box_$dt|" >> $T
      for off in 0 $GOFF; do for pad in box mesh; do
        # shellcheck disable=SC2086
        tools/mjc_grip other/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $OPTS | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> $T
      done; done
    done )
  rm -rf "${O:?}/${name:?}"; mkdir -p "$O/$name"; cp -R "$X/stacks" "$X/other" "$O/$name/"; rm -rf "${X:?}"
  echo "arm $name played $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
for a in $ARMS; do
  case $a in
    rel_*) arm "$a" "$W/mujoco-3.16.0" "${a#*_}" none ;;
    off_*) arm "$a" "$QB" "${a#*_}" none ;;
    set_rec) arm "$a" "$QB" rec set ;;
    set4_rec) arm "$a" "$QB" rec set4 ;;
    col_def) arm "$a" "$QB" def col ;;
  esac
done
switches none
if [ "${DRY:-0}" != 1 ]; then
  suite() {  # <build folder> <label> <none|set4|col>: every test, the two memory-heavy texture tests alone
    ( cd "$1" && switches "$3"
      ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$2.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_$2_large.txt" 2>&1 )
    echo "suite $2 $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_$2_large.txt" | tail -1) $(date -u +%FT%TZ)" >> "$O/progress.txt"
  }
  suite "$W/t20-release" release none
  suite "$W/t77-s16" off none
  suite "$W/t77-s16" set4 set4
  suite "$W/t77-s16" col col
  for a in release off set4 col; do
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
# measuring
tilt() { cat "$1"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }'; }
endspeed() { for f in "$1"_[0-9].txt "$1"_[0-9][0-9].txt; do [ -f "$f" ] && tail -1 "$f"; done | awk '{ x = $3 < 0 ? -$3 : $3; y = $4 < 0 ? -$4 : $4; if (x > m) m = x; if (y > m) m = y } END { print m + 0 }'; }
{
  for a in $ARMS; do
    for dt in $DTS; do
      for tol in $TOLS; do
        for n in $NS; do
          q=stack${n}_${tol}_$dt
          echo "$a stack $n $tol $dt most_tilt_urad $(tilt "$O/$a/stacks/$q") end_speed_ums $(endspeed "$O/$a/stacks/$q") changes $(grep "^$q " "$O/$a/stacks/changes.txt" | awk '{ print $2 }')"
        done
      done
    done
    for q in offset1 offset17 onbox5; do
      echo "$a $q $DF most_tilt_urad $(tilt "$O/$a/stacks/${q}_$DF") end_speed_ums $(endspeed "$O/$a/stacks/${q}_$DF") changes $(grep "^${q}_$DF " "$O/$a/stacks/changes.txt" | awk '{ print $2 }')"
    done
    most=0; lim=0; wrn=0
    for f in "$O/$a/stacks/stats.txt" "$O/$a/other/stats.txt"; do
      m=$(grep -o 'most_iterations [0-9]*' "$f" | awk '{ if ($2 > m) m = $2 } END { print m + 0 }'); [ "$m" -gt "$most" ] && most=$m
      lim=$((lim + $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
      wrn=$((wrn + $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
    done
    echo "$a solver most_iterations $most at_iteration_limit $lim warnings $wrn"
  done
} > "$O/measured.txt"
squeeze() {  # the stacks' play files kept compressed, after every reading of them (gzip -n: the same bytes for the same
             # play, so a re-make compares them byte for byte)
  local a
  for a in $ARMS; do find "$O/$a/stacks" -name '*.txt' ! -name stats.txt ! -name changes.txt -exec gzip -n -9 {} +; done
}
if [ "${DRY:-0}" = 1 ]; then echo "dry run: $(wc -l < "$O/measured.txt") measured lines"; squeeze; date -u +%FT%TZ > "$O/finished.txt"; exit 0; fi
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
most_of() { local m=0 x; for x in "$@"; do x=${x#-}; [ "$x" -gt "$m" ] && m=$x; done; echo "$m"; }
sum_of() { local s=0 x; for x in "$@"; do s=$((s + x)); done; echo "$s"; }
same_files() {  # <arm a> <arm b> <folders...>: how many of a's play files in the folders b has byte-identical, of how many
              # (not the files that record the settings or the readings: stats.txt, changes.txt)
  local a=$1 b=$2 n=0 s=0 f; shift 2
  for f in $(cd "$O/$a" && find "$@" -type f ! -name stats.txt ! -name changes.txt | sort); do n=$((n + 1)); cmp -s "$O/$a/$f" "$O/$b/$f" && s=$((s + 1)); done
  echo "$s $n"
}
NAMED="SolverTest.ZeroToleranceDisablesTermination ForwardTest.DiscreteImplicitRowNoslip"
diff "$O/suite_results_off.txt" "$O/suite_results_set4.txt" | grep '^>' | awk '{ print $3 }' > "$O/suite_changed_set4.txt"
diff "$O/suite_results_off.txt" "$O/suite_results_col.txt" | grep '^>' | awk '{ print $3 }' > "$O/suite_changed_col.txt"
straight() {  # <arm> <field>: the field of every straight stack of the arm
  local a=$1 k=$2 dt tol n
  for dt in $DTS; do for tol in $TOLS; do for n in $NS; do get "$a stack $n $tol $dt" "$k"; done; done; done
}
# ---- the rules, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" | tail -1; }
  # required: released, under the configuration, some straight stack tilts
  # shellcheck disable=SC2046
  rule Q1_released_stack_tilts ge "$(most_of $(straight rel_rec most_tilt_urad))" 101
  # safe when off; MuJoCo's suite
  for k in def rec; do
    # shellcheck disable=SC2046
    rule "E1_safe_when_off_$k" eq $(same_files rel_$k off_$k stacks other)
  done
  # every suite read: each of the four readings lists all of MuJoCo's tests (a missing reading would make E2, M1 and
  # M2 compare nothing)
  # shellcheck disable=SC2046
  rule M0_every_suite_read all_eq 3492 $(for a in release off set4 col; do if [ -f "$O/suite_results_$a.txt" ]; then wc -l < "$O/suite_results_$a.txt" | tr -d ' '; else echo 0; fi; done)
  rule E2_safe_when_off_mujoco_suite eq "$(diff "$O/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>')" 0
  rule M1_mujoco_suite_set4_named_only eq "$(grep -cvxF -e "${NAMED% *}" -e "${NAMED#* }" "$O/suite_changed_set4.txt")" 0
  rule M2_mujoco_suite_collinear_alone eq "$(grep -c . "$O/suite_changed_col.txt")" 0
  # the four switches set, under the configuration: every straight stack stands, its contacts never change, at rest
  # shellcheck disable=SC2046
  rule set4_rec_S1_every_stack_stands all_le 10 $(straight set4_rec most_tilt_urad)
  # shellcheck disable=SC2046
  rule set4_rec_S2_contacts_never_change eq "$(sum_of $(straight set4_rec changes))" 0
  # shellcheck disable=SC2046
  rule set4_rec_S3_every_stack_at_rest all_le 10 $(straight set4_rec end_speed_ums)
  # the collinear switch alone, under MuJoCo's defaults: every straight stack stands
  # shellcheck disable=SC2046
  rule col_def_S4_every_stack_stands all_le 10 $(straight col_def most_tilt_urad)
  # nothing else changes: the arm, the holds, the slide on a box's face and the grips
  # shellcheck disable=SC2046
  rule set4_rec_N1_nothing_else_changes eq $(same_files set_rec set4_rec other)
  # shellcheck disable=SC2046
  rule col_def_N2_nothing_else_changes eq $(same_files rel_def col_def other)
  rule set4_rec_V1_iteration_limit eq "$(get "set4_rec solver" at_iteration_limit)" 0
  rule set4_rec_V1_warnings eq "$(get "set4_rec solver" warnings)" 0
  sed 's/^/reported: changed with the four switches set: /' "$O/suite_changed_set4.txt"
  sed 's/^/reported: changed with the collinear switch alone: /' "$O/suite_changed_col.txt"
} > "$O/rules.txt"
{
  echo "rules: $(grep -c '^RULE' "$O/rules.txt"), held: $(grep -c ': HELD$' "$O/rules.txt")"
} >> "$O/rules.txt"
squeeze
date -u +%FT%TZ > "$O/finished.txt"
