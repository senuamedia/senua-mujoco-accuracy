#!/usr/bin/env bash
# Run 085: the nineteenth registered study (preregistrations/PREREGISTRATION_19.md), played once: noslip leaving a
# condim-6 contact's rolling friction as it was, solved through the friction-solve patch
# (patches/in_design/noslip_roll_kept_after_qcqp.diff, switch MUJOCO_NOSLIP_ROLL_KEPT=1), for issue 20, a box that should
# rest keeps moving. One build from MuJoCo's source at UPSTREAM_COMMIT with Senua AI's four validated patches
# (patches/invweight_at_pose_v3.diff, desaxce_elliptic_v4.diff, qcqp_reduced.diff, boxbox_collinear.diff) and this one,
# with its tests. Arms: rel, Google DeepMind's Linux release of MuJoCo 3.16.0; off, the build with every switch unset;
# set4, the four validated switches; set5, those and the rolling switch. The plays: MuJoCo's own test scene of issue 20
# (DiscreteImplicitRowNoslip, run 049's copy) as written and with 100 noslip iterations; three fresh boxes written from
# it (each its drawn half-size, mass and slide speed, nothing else changed), at the scene's 16 ms step and at a drawn
# step, as written and with 100 noslip iterations, 16 s each; and, under Senua AI's configuration (the elliptic cone, 100
# noslip iterations), for the byte comparisons, Study 15's arm set down and dropped, a cube held at 0.5 and 0.95 of its
# limit with condim 3 and 4, and Study 15's grip. MuJoCo's own test suite on the release's test build and on the patched
# one, every switch unset and the five set. Every number of the boxes drawn from seed 19 (DRAW=1 prints the draw and
# plays nothing). Every rule judged by sx_contact rule.
# DRY=1 plays throwaway numbers (MuJoCo's own box, written three times) on all four arms on run 084's build of the same
# five patch files, with no build and no MuJoCo suite, into dry/; no rule is read from it.
# usage: play.sh <folder holding sx_contact> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src at UPSTREAM_COMMIT, the release in
#        mujoco-3.16.0, and run 020's release test build in t20-release)
set -u
draw() {  # the registered numbers from the seed: Study 10's procedure, from x(0) = 19
  local x=19 V=0 D=""
  pick() { x=$(( (x * 1103515245 + 12345) % 2147483648 )); V=$(( $1 + x * ($2 - $1 + 1) / 2147483648 )); }
  dec() { local v=$1 p=$2 s="" d=1 i; [ "$v" -lt 0 ] && { s="-"; v=$(( -v )); }
    for ((i = 0; i < p; i++)); do d=$(( d * 10 )); done
    if [ "$p" -eq 0 ]; then echo "$s$v"; else printf "%s%d.%0${p}d\n" "$s" $(( v / d )) $(( v % d )); fi; }
  plain() { echo "$1" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
  # the values a kind may not take: Study 18's lists, the values Studies 17 and 18 drew, the settings of runs 079 to 084,
  # MuJoCo's own box (half-size 0.05 m, 1 kg, 2 m/s, 16 ms), and those this draw has already given to that kind
  SEEN_step=" 0.00003125 0.000125 0.00015625 0.00025 0.0003 0.0003125 0.000375 0.0004 0.0004075 0.0005 0.000625 0.001 0.0012 0.00125 0.0015 0.0016 0.00163 0.002 0.0025 0.004 0.006 0.008 0.01 0.012 0.015 0.02 0.03 0.04 0.00114 0.000285 0.00165 0.0004125 0.0001425 0.00057 0.000855 0.016 0.00116 0.00029 0.00168 0.00042 0.00119 0.0002975 0.00171 0.0004275 0.00122 0.000305 0.0001525 0.00174 0.000435 0.00625 0.0015625 0.000390625 0.00009765625 "
  SEEN_len=" 0.0004 0.0005 0.0006 0.007 0.008 0.009 0.01 0.011 0.012 0.014 0.015 0.02 0.025 0.026 0.0271 0.028 0.03 0.032 0.033 0.035 0.038 0.04 0.042 0.043 0.045 0.05 0.08 0.09 0.1 0.2 0.24 0.25 0.26 0.267 0.27 0.273 0.28 0.29 0.3 0.32 0.4 0.5 0.0434 0.0392 0.096 0.0312 0.0093 0.0424 0.017 0.271 0.275 0.0264 0.00059 0.0121 0.0435 0.0336 0.0079 0.0499 0.0431 0.097 0.0305 0.0097 0.0439 0.0485 0.403 0.0454 0.0331 0.071 0.0349 0.0098 0.297 0.302 0.0295 0.00052 0.298 0.269 0.0273 0.00054 0.0146 0.0449 0.0426 0.07 0.0326 0.0077 0.279 0.286 0.0284 0.00043 0.0129 0.041 0.0314 0.083 0.0334 0.0092 0.001 0.0405 0.0489 0.0437 0.0329 0.224 0.462 0.181 "
  SEEN_mass=" 0.15 0.161 0.17 0.18 0.2 0.22 0.24 0.25 0.35 0.4 0.45 0.5 0.519 0.6 0.9 0.95 1 1.023 1.05 1.1 1.15 1.2 1.3 1.4 1.6 2 3 5 1.861 0.881 0.202 0.442 1.113 0.524 0.176 1.381 0.218 1.903 0.908 0.248 0.408 1.423 1.714 1.438 0.209 1.08 0.578 0.194 1.164 0.522 0.167 1.564 1.7 0.225 1.116 0.436 0.199 1.56 1.704 0.21 0.596 1.561 1.505 0.915 0.587 "
  SEEN_speed=" 0.3 0.6 0.8 0.85 0.9 0.95 1 1.1 1.2 1.5 2 2.4 3 4 5 1.01 3.24 1.47 3.67 1.16 0.81 3.19 0.98 4.35 0.86 2.97 0.96 3.5 1.15 3.36 1.45 4.53 0.94 3.51 1.28 3.62 1.09 0.91 "
  q() {  # q <kind> <name> <lo> <hi> <places>: one quantity, drawn again while its value is one its kind may not take
    local k="$1" v p seen
    while :; do
      pick "$3" "$4"; v="$(dec "$V" "$5")"; p="$(plain "$v")"
      eval "seen=\"\${SEEN_$k:- }\""
      case "$seen" in *" $p "*) echo "  ($2 drawn again: $v)" ;; *) eval "SEEN_$k=\"\${SEEN_$k:- }$p \""; break ;; esac
    done
    D="$p"; [ "${QUIET:-0}" = 1 ] || echo "$2 $p"
  }
  # the step: from 8 to 16 ms, about MuJoCo's own 16 ms; three boxes about MuJoCo's own: half-size 40 to 60 mm, 0.6 to
  # 1.6 kg, slid at 1.2 to 2.8 m/s
  q step dt_box 800 1600 5
  for b in 1 2 3; do q len box${b}_half 400 600 4; q mass box${b}_mass 600 1600 3; q speed box${b}_v 120 280 2; done
}
if [ "${DRAW:-0}" = 1 ]; then draw; exit 0; fi
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
PS="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/qcqp_reduced.diff $R/patches/boxbox_collinear.diff $R/patches/in_design/noslip_roll_kept_after_qcqp.diff"
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"; ARMS="rel off set4 set5"; BOXES="1 2 3"
A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"; A15P="0.555,0.905 1.157,-0.378"
CUBE="mass=1.561 radius=0.0489 mu=0.438"; GRIP="mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61"; GOFF=0.0092
REC="cone=elliptic noslip=100"
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_085_study_19/dry"; QB="$W/mujoco-p84-build"; mkdir -p "$O"
  DTB=0.016; for b in $BOXES; do eval "H$b=0.05 MS$b=1 V$b=2"; done
else
  O="$R/validation/run_085_study_19"; QB="$W/mujoco-s19-build"; mkdir -p "$O"; draw > "$O/draw.txt"
  v() { awk -v k="$1" '$1 == k { print $2 }' "$O/draw.txt"; }
  DTB=$(v dt_box); for b in $BOXES; do eval "H$b=$(v box${b}_half) MS$b=$(v box${b}_mass) V$b=$(v box${b}_v)"; done
fi
LIM=$(awk 'BEGIN { printf "%.6f", 0.438 * 1.561 * 9.8 }')
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
# the fresh boxes' scenes: MuJoCo's own, with the box's half-size, its starting height, its mass, its slide speed and the
# step replaced, and nothing else
mkdir -p "$O/scenes"
for b in $BOXES; do
  eval "h=\$H$b ms=\$MS$b vv=\$V$b"
  for st in 0.016 $DTB; do
    sed -e "s/timestep=\"0.016\"/timestep=\"$st\"/" -e "s/pos=\"0 0 0.05\"/pos=\"0 0 $h\"/" -e "s/size=\".05 .05 .05\"/size=\"$h $h $h\"/" \
        -e "s/mass=\"1\"/mass=\"$ms\"/" -e "s/qvel=\"2 0 0 0 0 0\"/qvel=\"$vv 0 0 0 0 0\"/" "$SCN" > "$O/scenes/box${b}_$st.xml"
  done
done
{
  echo "MuJoCo's own box: $SCN; the fresh boxes' step $DTB"
  for b in $BOXES; do eval "echo box $b: half-size \$H$b m, mass \$MS$b kg, slid at \$V$b m/s"; done
  for f in "$O"/scenes/*.xml; do echo "$(basename "$f"): $(diff "$SCN" "$f" | grep -c '^>') lines changed from MuJoCo's scene"; done
} > "$O/parameters.txt"
switches() {  # <0, 4 or 5>
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT
  if [ "$1" -ge 4 ]; then export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1; fi
  if [ "$1" -ge 5 ]; then export MUJOCO_NOSLIP_ROLL_KEPT=1; fi
}
if [ "${DRY:-0}" != 1 ]; then
  rm -rf "${W:?}/mujoco-s19-src" "$W/s19-lib" "$QB" "$W/t85-s19" && mkdir -p "$W/mujoco-s19-src"
  (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-s19-src"
  for p in $PS; do (cd "$W/mujoco-s19-src" && patch -p1 -s < "$p"); done
  echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in $PS; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" > "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-s19-src" -B "$W/s19-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$QB" && cmake --build "$W/s19-lib" -j"$J" && cmake --install "$W/s19-lib" ) > "$O/build_lib.log" 2>&1
  echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
  ( cmake -S "$W/mujoco-s19-src" -B "$W/t85-s19" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t85-s19" -j"$J" ) > "$O/build_tests.log" 2>&1
  echo "build tests exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
fi
arm() {  # <name> <MuJoCo folder> <0, 4 or 5>: the plays every arm makes, the same in each
  local name=$1 mj=$2 sw=$3 X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_scene mjc_contact mjc_grip mjc_arm; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
    switches "$sw"
    mkdir -p boxes other; S=boxes/stats.txt; T=other/stats.txt; : > $S; : > $T
    for ns in written:"" n100:noslip=100; do
      nn=${ns%%:*}; opt=${ns#*:}
      # shellcheck disable=SC2086
      tools/mjc_scene boxes/mujoco_$nn.txt scene="$SCN" body=box axis=1,0,0 secs=16 key=0 $opt | sed "s|^STATS|STATS run mujoco_$nn|" >> $S
      for b in $BOXES; do
        for st in 0.016 $DTB; do
          # shellcheck disable=SC2086
          tools/mjc_scene boxes/box${b}_${st}_$nn.txt scene="$O/scenes/box${b}_$st.xml" body=box axis=1,0,0 secs=16 key=0 $opt | sed "s|^STATS|STATS run box${b}_${st}_$nn|" >> $S
        done
      done
    done
    for dt in 0.00171 0.0004275; do
      k=0
      for PSE in $A15P; do
        k=$((k + 1))
        # shellcheck disable=SC2086
        tools/mjc_arm other/rest_pose${k}_$dt.txt dt=$dt pose=$PSE pose0=$PSE $A15 h0=0.00043 secs=2 $REC | sed "s|^STATS|STATS run rest_pose${k}_$dt|" >> $T
        # shellcheck disable=SC2086
        tools/mjc_arm other/drop_pose${k}_$dt.txt dt=$dt pose=$PSE pose0=$PSE $A15 h0=0.0129 secs=3 $REC | sed "s|^STATS|STATS run drop_pose${k}_$dt|" >> $T
      done
      for cd in 3 4; do
        if [ $cd = 3 ]; then CD=""; else CD="condim=4"; fi
        for fr in 0.5 0.95; do
          pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
          # shellcheck disable=SC2086
          tools/mjc_contact other/hold_c${cd}_${fr}_$dt.txt dt=$dt h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=0 lock=0 $REC $CD | sed "s|^STATS|STATS run hold_c${cd}_${fr}_$dt|" >> $T
        done
      done
      for off in 0 $GOFF; do for pad in box mesh; do
        # shellcheck disable=SC2086
        tools/mjc_grip other/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $REC | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> $T
      done; done
    done )
  rm -rf "${O:?}/${name:?}"; mkdir -p "$O/$name"; cp -R "$X/boxes" "$X/other" "$O/$name/"; rm -rf "${X:?}"
  echo "arm $name played $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
for a in $ARMS; do
  case $a in
    rel) arm rel "$W/mujoco-3.16.0" 0 ;;
    off) arm off "$QB" 0 ;;
    set4) arm set4 "$QB" 4 ;;
    set5) arm set5 "$QB" 5 ;;
  esac
done
switches 0
if [ "${DRY:-0}" != 1 ]; then
  suite() {  # <build folder> <label> <0 or 5>: every test, the two memory-heavy texture tests alone
    ( cd "$1" && switches "$3"
      ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$2.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_$2_large.txt" 2>&1 )
    echo "suite $2 $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_$2_large.txt" | tail -1) $(date -u +%FT%TZ)" >> "$O/progress.txt"
  }
  suite "$W/t20-release" release 0
  suite "$W/t85-s19" off 0
  suite "$W/t85-s19" set5 5
  for a in release off set5; do
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
# measuring: over a box's last 160 steps, how many are faster than 1 mm/s along its slide, and the fastest
last160() { awk 'NR > 1 { s[NR] = $0; m = NR } END { c = 0; x0 = 0; for (i = m - 159; i <= m; i++) { split(s[i], f, " "); x = f[3] < 0 ? -f[3] : f[3]; if (x > 1000) c++; if (x > x0) x0 = x } printf "fast_steps %d fastest_ums %d", c, x0 }' "$1"; }
{
  for a in $ARMS; do
    for nn in written n100; do
      echo "$a box mujoco $nn $(last160 "$O/$a/boxes/mujoco_$nn.txt")"
      for b in $BOXES; do for st in 0.016 $DTB; do echo "$a box $b $st $nn $(last160 "$O/$a/boxes/box${b}_${st}_$nn.txt")"; done; done
    done
    most=0; lim=0; wrn=0
    for f in "$O/$a/boxes/stats.txt" "$O/$a/other/stats.txt"; do
      m=$(grep -o 'most_iterations [0-9]*' "$f" | awk '{ if ($2 > m) m = $2 } END { print m + 0 }'); [ "$m" -gt "$most" ] && most=$m
      lim=$((lim + $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
      wrn=$((wrn + $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
    done
    echo "$a solver most_iterations $most at_iteration_limit $lim warnings $wrn"
  done
} > "$O/measured.txt"
if [ "${DRY:-0}" = 1 ]; then echo "dry run: $(wc -l < "$O/measured.txt") measured lines"; date -u +%FT%TZ > "$O/finished.txt"; exit 0; fi
get() { grep "^$1 " "$O/measured.txt" | head -1 | awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }'; }
same_files() {  # <arm a> <arm b> <folders...>: how many of a's play files in the folders b has byte-identical, of how many
  local a=$1 b=$2 n=0 s=0 f; shift 2
  for f in $(cd "$O/$a" && find "$@" -type f ! -name stats.txt | sort); do n=$((n + 1)); cmp -s "$O/$a/$f" "$O/$b/$f" && s=$((s + 1)); done
  echo "$s $n"
}
every() {  # <arm> <field>: the field of every box play of the arm
  local a=$1 k=$2 nn b st
  for nn in written n100; do get "$a box mujoco $nn" "$k"; for b in $BOXES; do for st in 0.016 $DTB; do get "$a box $b $st $nn" "$k"; done; done; done
}
NAMED="SolverTest.ZeroToleranceDisablesTermination ForwardTest.DiscreteImplicitRowNoslip"
diff "$O/suite_results_off.txt" "$O/suite_results_set5.txt" | grep '^>' | awk '{ print $3 }' > "$O/suite_changed_set5.txt"
# ---- the rules, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" | tail -1; }
  # required: released, MuJoCo's own box keeps moving
  rule Q1_released_box_keeps_moving ge "$(get "rel box mujoco written" fast_steps)" 10
  # safe when off; every suite read; MuJoCo's suite
  # shellcheck disable=SC2046
  rule E1_safe_when_off eq $(same_files rel off boxes other)
  # shellcheck disable=SC2046
  rule M0_every_suite_read all_eq 3492 $(for a in release off set5; do if [ -f "$O/suite_results_$a.txt" ]; then wc -l < "$O/suite_results_$a.txt" | tr -d ' '; else echo 0; fi; done)
  rule E2_safe_when_off_mujoco_suite eq "$(diff "$O/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>')" 0
  rule M1_mujoco_suite_named_only eq "$(grep -cvxF -e "${NAMED% *}" -e "${NAMED#* }" "$O/suite_changed_set5.txt")" 0
  # the five switches: every box at rest over its last 160 steps
  # shellcheck disable=SC2046
  rule set5_R1_every_box_rests all_le 10 $(every set5 fastest_ums)
  # nothing else changes: the arm, the holds with condim 3 and 4, and the grips, byte for byte as set4
  # shellcheck disable=SC2046
  rule set5_N1_nothing_else_changes eq $(same_files set4 set5 other)
  rule set5_V1_iteration_limit eq "$(get "set5 solver" at_iteration_limit)" 0
  rule set5_V1_warnings eq "$(get "set5 solver" warnings)" 0
  sed 's/^/reported: changed with the five switches set: /' "$O/suite_changed_set5.txt"
} > "$O/rules.txt"
{
  echo "rules: $(grep -c '^RULE' "$O/rules.txt"), held: $(grep -c ': HELD$' "$O/rules.txt")"
} >> "$O/rules.txt"
date -u +%FT%TZ > "$O/finished.txt"
