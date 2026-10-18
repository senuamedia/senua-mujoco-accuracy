#!/usr/bin/env bash
# Run 087: the twentieth registered study (preregistrations/PREREGISTRATION_20.md), played once: the friction-solve
# patch's second version (patches/in_design/qcqp_reduced_v2.diff, the same switch MUJOCO_QCQP_REDUCED=1), a direction
# also dropped at noslip's floor of 1e-10, for issue 1's open part, a cube that cannot turn creeping with torsional or
# rolling friction. Two builds from MuJoCo's source at UPSTREAM_COMMIT: v1, Senua AI's five validated patch files
# (patches/invweight_at_pose_v3.diff, desaxce_elliptic_v4.diff, qcqp_reduced.diff, boxbox_collinear.diff,
# noslip_roll_kept_after_qcqp.diff); and v2, the same five with qcqp_reduced_v2.diff in place of qcqp_reduced.diff, with
# its tests. Arms: rel, Google DeepMind's Linux release of MuJoCo 3.16.0; off, v2 with every switch unset; v1set and
# v2set, each with the five switches set. Under Senua AI's configuration (the elliptic cone, 100 noslip iterations): two
# fresh cubes held at 0.5, 0.75 and 0.95 of their friction limit along 0, 22.5 and 45 degrees, with condim 3, 4 and 6,
# held from turning and free, at a fresh step and a quarter of it; the arms of Studies 10, 13, 14 and 15 set down and
# dropped, at their studies' steps; Study 15's grip. With their scenes' own options: Study 19's boxes. MuJoCo's own test
# suite on the release's test build and on v2's, every switch unset and the five set. Every number of the cubes and the
# step drawn from seed 20 (DRAW=1 prints the draw and plays nothing). Every rule judged by sx_contact rule.
# DRY=1 plays throwaway numbers (run 086's cube, twice, at 1.14 ms) on all four arms on run 086's two builds of the same
# patch files, with no build and no MuJoCo suite, into dry/; no rule is read from it.
# usage: play.sh <folder holding sx_contact> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src at UPSTREAM_COMMIT, the release in
#        mujoco-3.16.0, and run 020's release test build in t20-release)
set -u
draw() {  # the registered numbers from the seed: Study 10's procedure, from x(0) = 20
  local x=20 V=0 D=""
  pick() { x=$(( (x * 1103515245 + 12345) % 2147483648 )); V=$(( $1 + x * ($2 - $1 + 1) / 2147483648 )); }
  dec() { local v=$1 p=$2 s="" d=1 i; [ "$v" -lt 0 ] && { s="-"; v=$(( -v )); }
    for ((i = 0; i < p; i++)); do d=$(( d * 10 )); done
    if [ "$p" -eq 0 ]; then echo "$s$v"; else printf "%s%d.%0${p}d\n" "$s" $(( v / d )) $(( v % d )); fi; }
  plain() { echo "$1" | sed -E 's/(\.[0-9]*[1-9])0+$/\1/; s/\.0+$//'; }
  # the values a kind may not take: Study 19's lists and the values it drew, Study 16's friction list and the frictions
  # Studies 16 and 19 played, the settings of runs 085 and 086, and those this draw has already given to that kind
  SEEN_step=" 0.00003125 0.000125 0.00015625 0.00025 0.0003 0.0003125 0.000375 0.0004 0.0004075 0.0005 0.000625 0.001 0.0012 0.00125 0.0015 0.0016 0.00163 0.002 0.0025 0.004 0.006 0.008 0.01 0.012 0.015 0.02 0.03 0.04 0.00114 0.000285 0.00165 0.0004125 0.0001425 0.00057 0.000855 0.016 0.00116 0.00029 0.00168 0.00042 0.00119 0.0002975 0.00171 0.0004275 0.00122 0.000305 0.0001525 0.00174 0.000435 0.00625 0.0015625 0.000390625 0.00009765625 0.01411 "
  SEEN_len=" 0.0004 0.0005 0.0006 0.007 0.008 0.009 0.01 0.011 0.012 0.014 0.015 0.02 0.025 0.026 0.0271 0.028 0.03 0.032 0.033 0.035 0.038 0.04 0.042 0.043 0.045 0.05 0.08 0.09 0.1 0.2 0.24 0.25 0.26 0.267 0.27 0.273 0.28 0.29 0.3 0.32 0.4 0.5 0.0434 0.0392 0.096 0.0312 0.0093 0.0424 0.017 0.271 0.275 0.0264 0.00059 0.0121 0.0435 0.0336 0.0079 0.0499 0.0431 0.097 0.0305 0.0097 0.0439 0.0485 0.403 0.0454 0.0331 0.071 0.0349 0.0098 0.297 0.302 0.0295 0.00052 0.298 0.269 0.0273 0.00054 0.0146 0.0449 0.0426 0.07 0.0326 0.0077 0.279 0.286 0.0284 0.00043 0.0129 0.041 0.0314 0.083 0.0334 0.0092 0.001 0.0405 0.0489 0.0437 0.0329 0.224 0.462 0.181 0.0509 0.0416 0.0491 "
  SEEN_mass=" 0.15 0.161 0.17 0.18 0.2 0.22 0.24 0.25 0.35 0.4 0.45 0.5 0.519 0.6 0.9 0.95 1 1.023 1.05 1.1 1.15 1.2 1.3 1.4 1.6 2 3 5 1.861 0.881 0.202 0.442 1.113 0.524 0.176 1.381 0.218 1.903 0.908 0.248 0.408 1.423 1.714 1.438 0.209 1.08 0.578 0.194 1.164 0.522 0.167 1.564 1.7 0.225 1.116 0.436 0.199 1.56 1.704 0.21 0.596 1.561 1.505 0.915 0.587 0.978 1.565 1.342 "
  SEEN_fric=" 0 0.1 0.2 0.3 0.35 0.4 0.45 0.48 0.5 0.55 0.58 0.6 0.62 0.65 0.68 0.7 0.72 0.75 0.8 0.39 0.371 0.421 0.772 0.524 0.717 0.369 0.78 0.379 0.409 0.432 0.732 0.534 0.44 0.42 0.468 0.762 0.778 0.667 0.411 0.413 0.443 0.689 0.686 0.462 0.416 0.436 0.69 0.528 0.438 "
  q() {  # q <kind> <name> <lo> <hi> <places>: one quantity, drawn again while its value is one its kind may not take
    local k="$1" v p seen
    while :; do
      pick "$3" "$4"; v="$(dec "$V" "$5")"; p="$(plain "$v")"
      eval "seen=\"\${SEEN_$k:- }\""
      case "$seen" in *" $p "*) echo "  ($2 drawn again: $v)" ;; *) eval "SEEN_$k=\"\${SEEN_$k:- }$p \""; break ;; esac
    done
    D="$p"; [ "${QUIET:-0}" = 1 ] || echo "$2 $p"
  }
  # the step: from 1 to 2 ms, and a quarter of it; cube a from 1 to 2.5 kg, where version 1 left run 086's cube creeping;
  # cube b from 0.3 to 1 kg; each 30 to 50 mm in half-size, friction 0.3 to 0.8
  q step dt_hold 1000 2000 6
  q mass cubea_mass 1000 2500 3; q len cubea_half 300 500 4; q fric cubea_mu 300 800 3
  q mass cubeb_mass 300 1000 3; q len cubeb_half 300 500 4; q fric cubeb_mu 300 800 3
}
if [ "${DRAW:-0}" = 1 ]; then draw; exit 0; fi
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
P1="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/qcqp_reduced.diff $R/patches/boxbox_collinear.diff $R/patches/noslip_roll_kept_after_qcqp.diff"
P2="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/in_design/qcqp_reduced_v2.diff $R/patches/boxbox_collinear.diff $R/patches/noslip_roll_kept_after_qcqp.diff"
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"; S19="$R/validation/run_085_study_19/scenes"
ARMS="rel off v1set v2set"; CUBES="a b"; CDS="3 4 6"; LKS="1 0"; FRS="0.5 0.75 0.95"; DIRS="0 22.5 45"
GRIP="mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61"; GOFF=0.0092; REC="cone=elliptic noslip=100"
# the arms: <name>:<arm>:<rest height>:<drop height>:<steps>:<poses>, as their studies played them
ARMSETS="s10:len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717:0.00059:0.0121:0.00114 0.000285:0.604,1.158 1.149,-0.545
s13:len1=0.297 len2=0.302 mass1=1.08 mass2=0.578 rb=0.0295 mb=0.194 mu=0.778:0.00052:0.0121:0.00168 0.00042:0.516,0.907 1.211,-0.464
s14:len1=0.298 len2=0.269 mass1=1.164 mass2=0.522 rb=0.0273 mb=0.167 mu=0.667:0.00054:0.0146:0.00119 0.0002975:0.582,1.117 1.227,-0.516 0.58,0.969 1.276,-0.407
s15:len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686:0.00043:0.0129:0.00171 0.0004275:0.555,0.905 1.157,-0.378 0.57,1.123 1.296,-0.403"
if [ "${DRY:-0}" = 1 ]; then
  O="$R/validation/run_087_study_20/dry"; Q1B="$W/mujoco-s19-build"; Q2B="$W/mujoco-p86-build"; mkdir -p "$O"
  DTC=0.00114; DTF=0.000285; for c in $CUBES; do eval "MS$c=1.861 H$c=0.0434 MU$c=0.39"; done
else
  O="$R/validation/run_087_study_20"; Q1B="$W/mujoco-s20v1-build"; Q2B="$W/mujoco-s20v2-build"; mkdir -p "$O"; draw > "$O/draw.txt"
  v() { awk -v k="$1" '$1 == k { print $2 }' "$O/draw.txt"; }
  DTC=$(v dt_hold); DTF=$(awk -v d="$DTC" 'BEGIN { printf "%.8f", d / 4 }' | sed -E 's/0+$//')
  for c in $CUBES; do eval "MS$c=$(v cube${c}_mass) H$c=$(v cube${c}_half) MU$c=$(v cube${c}_mu)"; done
fi
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
{
  echo "the holds' steps $DTC and $DTF"
  for c in $CUBES; do eval "echo cube $c: \$MS$c kg, half-size \$H$c m, friction \$MU$c, limit \$(awk -v m=\$MS$c -v u=\$MU$c 'BEGIN { printf \"%.6f\", m * u * 9.8 }') N"; done
} > "$O/parameters.txt"
switches() {  # <0 or 5>
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT
  if [ "$1" -ge 5 ]; then export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1; fi
}
build() {  # <name> <patch files> <install folder> <with tests: 0 or 1>
  local n=$1 ps=$2 ib=$3 t=$4 p
  rm -rf "${W:?}/mujoco-s20$n-src" "$W/s20$n-lib" "$ib" "$W/t87-s20$n" && mkdir -p "$W/mujoco-s20$n-src"
  (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-s20$n-src"
  for p in $ps; do (cd "$W/mujoco-s20$n-src" && patch -p1 -s < "$p"); done
  echo "$n: source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in $ps; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" >> "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-s20$n-src" -B "$W/s20$n-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$ib" && cmake --build "$W/s20$n-lib" -j"$J" && cmake --install "$W/s20$n-lib" ) > "$O/build_${n}_lib.log" 2>&1
  log "build $n lib exit $?"
  if [ "$t" = 1 ]; then
    ( cmake -S "$W/mujoco-s20$n-src" -B "$W/t87-s20$n" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
        -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t87-s20$n" -j"$J" ) > "$O/build_${n}_tests.log" 2>&1
    log "build $n tests exit $?"
  fi
}
if [ "${DRY:-0}" != 1 ]; then : > "$O/patch_check.txt"; build v1 "$P1" "$Q1B" 0; build v2 "$P2" "$Q2B" 1; fi
squeeze() { find "$1" -name '*.txt' ! -name stats.txt -size +200k -exec gzip -n {} +; }
arm() {  # <name> <MuJoCo folder> <0 or 5>: the plays every arm makes, the same in each
  local name=$1 mj=$2 sw=$3 X
  X=$(mktemp -d); cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_scene mjc_contact mjc_grip mjc_arm; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null; done
    switches "$sw"
    mkdir -p holds arms boxes; H=holds/stats.txt; A=arms/stats.txt; S=boxes/stats.txt; : > $H; : > $A; : > $S
    for c in $CUBES; do
      eval "ms=\$MS$c hh=\$H$c mu=\$MU$c"; LIM=$(awk -v m="$ms" -v u="$mu" 'BEGIN { printf "%.6f", m * u * 9.8 }')
      for dt in $DTC $DTF; do for cd in $CDS; do
        if [ $cd = 3 ]; then CD=""; else CD="condim=$cd"; fi
        for lk in $LKS; do for dir in $DIRS; do for fr in $FRS; do
          pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
          # shellcheck disable=SC2086
          tools/mjc_contact holds/hold_${c}_c${cd}_lock${lk}_${dir}_${fr}_$dt.txt dt=$dt h0=0 mass=$ms radius=$hh mu=$mu push=$pu pushat=0.4 secs=1.6 dir=$dir lock=$lk $REC $CD | sed "s|^STATS|STATS run hold_${c}_c${cd}_lock${lk}_${dir}_${fr}_$dt|" >> $H
        done; done; done
      done; done
    done
    squeeze holds
    while IFS= read -r line; do
      an=${line%%:*}; rest=${line#*:}; AP=${rest%%:*}; rest=${rest#*:}; RH=${rest%%:*}; rest=${rest#*:}; DH=${rest%%:*}; rest=${rest#*:}
      DT=${rest%%:*}; POSES=${rest#*:}
      for dt in $DT; do
        k=0
        for PSE in $POSES; do
          k=$((k + 1))
          # shellcheck disable=SC2086
          tools/mjc_arm arms/${an}_rest${k}_$dt.txt dt=$dt pose=$PSE pose0=$PSE $AP h0=$RH secs=2 $REC | sed "s|^STATS|STATS run ${an}_rest${k}_$dt|" >> $A
          # shellcheck disable=SC2086
          tools/mjc_arm arms/${an}_drop${k}_$dt.txt dt=$dt pose=$PSE pose0=$PSE $AP h0=$DH secs=3 $REC | sed "s|^STATS|STATS run ${an}_drop${k}_$dt|" >> $A
        done
      done
    done <<< "$ARMSETS"
    for dt in 0.00171 0.0004275; do for off in 0 $GOFF; do for pad in box mesh; do
      # shellcheck disable=SC2086
      tools/mjc_grip arms/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $REC | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> $A
    done; done; done
    squeeze arms
    for ns in written:"" n100:noslip=100; do
      nn=${ns%%:*}; opt=${ns#*:}
      # shellcheck disable=SC2086
      tools/mjc_scene boxes/mujoco_$nn.txt scene="$SCN" body=box axis=1,0,0 secs=16 key=0 $opt | sed "s|^STATS|STATS run mujoco_$nn|" >> $S
      for f in "$S19"/*.xml; do
        b=$(basename "$f" .xml)
        # shellcheck disable=SC2086
        tools/mjc_scene boxes/${b}_$nn.txt scene="$f" body=box axis=1,0,0 secs=16 key=0 $opt | sed "s|^STATS|STATS run ${b}_$nn|" >> $S
      done
    done
    squeeze boxes )
  rm -rf "${O:?}/${name:?}"; mkdir -p "$O/$name"; cp -R "$X/holds" "$X/arms" "$X/boxes" "$O/$name/"; rm -rf "${X:?}"
  log "arm $name played"
}
for a in $ARMS; do
  case $a in
    rel) arm rel "$W/mujoco-3.16.0" 0 ;;
    off) arm off "$Q2B" 0 ;;
    v1set) arm v1set "$Q1B" 5 ;;
    v2set) arm v2set "$Q2B" 5 ;;
  esac
done
switches 0
if [ "${DRY:-0}" != 1 ]; then
  suite() {  # <build folder> <label> <0 or 5>: every test, the two memory-heavy texture tests alone
    ( cd "$1" && switches "$3"
      ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$2.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_$2_large.txt" 2>&1 )
    log "suite $2 $(grep -E 'tests passed|tests failed' "$O/ctest_$2.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_$2_large.txt" | tail -1)"
  }
  suite "$W/t20-release" release 0
  suite "$W/t87-s20v2" off 0
  suite "$W/t87-s20v2" set5 5
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
  for f in "$O"/ctest_*.txt "$O"/build_*.log; do gzip -n "$f"; done
fi
# measuring: a file read whole, compressed or not
rd() { if [ -f "$1.gz" ]; then gzip -dc "$1.gz" > "$2"; else cp "$1" "$2"; fi; }
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
ab() { echo "${1#-}"; }
creep() { local t; t=$(mktemp); rd "$1" "$t"; ab "$(fld "$("$B" creep "$t" | tail -1)" mean_speed_ums)"; rm -f "$t"; }
last160() { local t; t=$(mktemp); rd "$1" "$t"; awk 'NR > 1 { s[NR] = $0; m = NR } END { if (m < 161) { printf "fast_steps missing fastest_ums missing"; exit } c = 0; x0 = 0; for (i = m - 159; i <= m; i++) { split(s[i], f, " "); x = f[3] < 0 ? -f[3] : f[3]; if (x > 1000) c++; if (x > x0) x0 = x } printf "fast_steps %d fastest_ums %d", c, x0 }' "$t"; rm -f "$t"; }
{
  for a in $ARMS; do
    for c in $CUBES; do for dt in $DTC $DTF; do for cd in $CDS; do for lk in $LKS; do for dir in $DIRS; do
      echo "$a hold $c $dt $cd $lk $dir creep_ums $(for fr in $FRS; do creep "$O/$a/holds/hold_${c}_c${cd}_lock${lk}_${dir}_${fr}_$dt.txt"; done | tr '\n' ' ')"
    done; done; done; done; done
    for f in $(cd "$O/$a/arms" && ls | sed 's/\.gz$//' | grep -E '^s1[0-9]_(rest|drop)[0-9]_[0-9.]+\.txt$' | sort); do echo "$a arm ${f%.txt} creep_ums $(creep "$O/$a/arms/$f")"; done
    for dt in 0.00171 0.0004275; do for off in 0 $GOFF; do for pad in box mesh; do
      echo "$a grip $pad $off $dt creep_ums $(creep "$O/$a/arms/grip_${pad}_off${off}_$dt.txt")"
    done; done; done
    for f in $(cd "$O/$a/boxes" && ls | sed 's/\.gz$//' | grep -v '^stats\.txt$' | sort); do echo "$a box ${f%.txt} $(last160 "$O/$a/boxes/$f")"; done
    most=0; lim=0; wrn=0
    for f in "$O/$a/holds/stats.txt" "$O/$a/arms/stats.txt" "$O/$a/boxes/stats.txt"; do
      m=$(grep -o 'most_iterations [0-9]*' "$f" | awk '{ if ($2 > m) m = $2 } END { print m + 0 }'); [ "$m" -gt "$most" ] && most=$m
      lim=$((lim + $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
      wrn=$((wrn + $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')))
    done
    echo "$a solver most_iterations $most at_iteration_limit $lim warnings $wrn"
  done
} > "$O/measured.txt"
if [ "${DRY:-0}" = 1 ]; then echo "dry run: $(wc -l < "$O/measured.txt") measured lines"; date -u +%FT%TZ > "$O/finished.txt"; exit 0; fi
same_files() {  # <arm a> <arm b> <exclude pattern> <folders...>: how many of a's play files b has byte-identical, of how many
  local a=$1 b=$2 x=$3 n=0 s=0 f; shift 3
  for f in $(cd "$O/$a" && find "$@" -type f ! -name stats.txt | grep -vE "$x" | sort); do n=$((n + 1)); cmp -s "$O/$a/$f" "$O/$b/$f" && s=$((s + 1)); done
  echo "$s $n"
}
vals() {  # <arm> <kind> <lock or -> <condims>: every hold reading of the arm with that lock and condim, or every arm, grip or box reading
  local a=$1 k=$2
  case $k in
    hold) grep "^$a hold " "$O/measured.txt" | awk -v lk="$3" -v cds=" $4 " '$6 == lk && index(cds, " " $5 " ") > 0 { for (i = 9; i <= NF; i++) print $i }' ;;
    holdall) grep "^$a hold " "$O/measured.txt" | awk '{ for (i = 9; i <= NF; i++) print $i }' ;;
    arm) grep "^$a arm " "$O/measured.txt" | awk '{ print $5 }' ;;
    grip) grep "^$a grip " "$O/measured.txt" | awk '{ print $7 }' ;;
    box) grep "^$a box " "$O/measured.txt" | awk '{ print $7 }' ;;
  esac
}
mx() { sort -n | tail -1; }
NAMED="SolverTest.ZeroToleranceDisablesTermination ForwardTest.DiscreteImplicitRowNoslip"
diff "$O/suite_results_off.txt" "$O/suite_results_set5.txt" | grep '^>' | awk '{ print $3 }' > "$O/suite_changed_set5.txt"
# ---- the rules, each judged by sx_contact rule
{
  rule() { "$B" rule "$@" | tail -1; }
  # required: released, and with version 1 in the set, some cube that cannot turn creeps with condim 4 or 6
  rule Q1_released_cube_creeps ge "$(vals rel hold 1 "4 6" | mx)" 11
  rule Q2_version1_cube_creeps ge "$(vals v1set hold 1 "4 6" | mx)" 11
  # safe when off; every suite read; MuJoCo's suite
  # shellcheck disable=SC2046
  rule E1_safe_when_off eq $(same_files rel off '^$' holds arms boxes)
  # shellcheck disable=SC2046
  rule M0_every_suite_read all_eq 3492 $(for a in release off set5; do if [ -f "$O/suite_results_$a.txt" ]; then wc -l < "$O/suite_results_$a.txt" | tr -d ' '; else echo 0; fi; done)
  rule E2_safe_when_off_mujoco_suite eq "$(diff "$O/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>')" 0
  rule M1_mujoco_suite_named_only eq "$(grep -cvxF -e "${NAMED% *}" -e "${NAMED#* }" "$O/suite_changed_set5.txt")" 0
  # every play measured, in every arm: 216 holds, 48 arms, 8 grips and 14 boxes, each a number
  # shellcheck disable=SC2046
  rule P0_every_play_measured all_eq 286 $(for a in $ARMS; do (vals $a holdall; vals $a arm; vals $a grip; vals $a box) | grep -cE '^[0-9]+$'; done)
  # version 2 in the set: every hold holds, condim 3, 4 and 6, held from turning and free
  # shellcheck disable=SC2046
  rule v2set_H1_every_hold_holds all_le 10 $(vals v2set holdall)
  # nothing else changes: every file but the holds of a cube that cannot turn with condim 4 or 6, byte for byte as v1set
  # shellcheck disable=SC2046
  rule v2set_N1_nothing_else_changes eq $(same_files v1set v2set '_c[46]_lock1_' holds arms boxes)
  # what the set held before still holds: every arm, every grip, every box
  # shellcheck disable=SC2046
  rule v2set_R1_every_arm_holds all_le 10 $(vals v2set arm)
  # shellcheck disable=SC2046
  rule v2set_G1_every_grip_holds all_le 10 $(vals v2set grip)
  # shellcheck disable=SC2046
  rule v2set_B1_every_box_rests all_le 10 $(vals v2set box)
  rule v2set_V1_iteration_limit eq "$(grep '^v2set solver' "$O/measured.txt" | awk '{ print $6 }')" 0
  rule v2set_V1_warnings eq "$(grep '^v2set solver' "$O/measured.txt" | awk '{ print $8 }')" 0
  sed 's/^/reported: changed with the five switches set: /' "$O/suite_changed_set5.txt"
} > "$O/rules.txt"
{
  echo "rules: $(grep -c '^RULE' "$O/rules.txt"), held: $(grep -c ': HELD$' "$O/rules.txt")"
} >> "$O/rules.txt"
date -u +%FT%TZ > "$O/finished.txt"
