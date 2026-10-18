#!/usr/bin/env bash
# Run 086: a design probe, not registered: it finds where to look and decides nothing. Run 084 found a cube that cannot
# turn, with torsional or rolling friction (condim 4 or 6), still creeping under Senua AI's set. Noslip takes a contact's
# block without its regularisation and clamps each diagonal entry from below at 1e-10 (extractBlock, engine_solver.c).
# The cube's torsional and rolling directions, which cannot move, sit at that floor. The friction-solve patch,
# patches/qcqp_reduced.diff, drops a direction whose entry is at most 1e-10 of the block's largest. For this cube the
# largest is about 0.5, so the floor is kept, and MuJoCo's solve rejects the block. Its second version,
# patches/in_design/qcqp_reduced_v2.diff (the same switch, MUJOCO_QCQP_REDUCED=1; one condition changed, a direction also
# dropped at noslip's floor of 1e-10), is the same as the first wherever the block's largest entry is 1 or more. This
# plays Senua AI's set with the rolling design in two builds from MuJoCo's source at UPSTREAM_COMMIT: v1, Study 19's build
# of its five patch files (mujoco-s19-build); and v2, the same five with the friction-solve patch's second version in
# place of the first, built here with its tests. Every switch set, under Senua AI's configuration (the elliptic cone, 100
# noslip iterations): the arms of Studies 10, 13, 14 and 15 set down and dropped in their poses, at their studies' steps;
# run 063's cube (Study 10's) held at 0.5 and 0.95 of its limit with condim 3, 4 and 6, held from turning and free to
# turn, at 1.14 and 0.285 ms; Study 15's grip. MuJoCo's own test suite on the v2 build, every switch unset and set.
# Readings: Senua AI's measures (sx_contact creep), file comparison by cmp.
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds mujoco-src at UPSTREAM_COMMIT and Study 19's build in mujoco-s19-build)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_086_qcqp_reduced_v2"; V1="$W/mujoco-s19-build"; V2="$W/mujoco-p86-build"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
PS="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/in_design/qcqp_reduced_v2.diff $R/patches/boxbox_collinear.diff $R/patches/in_design/noslip_roll_kept_after_qcqp.diff"
rm -rf "${W:?}/mujoco-p86-src" "$W/p86-lib" "$V2" "$W/t86" && mkdir -p "$W/mujoco-p86-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p86-src"
for p in $PS; do (cd "$W/mujoco-p86-src" && patch -p1 -s < "$p"); done
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in $PS; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' '); v1 build $V1" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p86-src" -B "$W/p86-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$V2" && cmake --build "$W/p86-lib" -j"$J" && cmake --install "$W/p86-lib" ) > "$O/build_lib.log" 2>&1
log "build lib exit $?"
( cmake -S "$W/mujoco-p86-src" -B "$W/t86" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t86" -j"$J" ) > "$O/build_tests.log" 2>&1
log "build tests exit $?"
switches() {  # <0 or 5>
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT
  if [ "$1" -ge 5 ]; then export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1; fi
}
REC="cone=elliptic noslip=100"; CUBE="mass=1.861 radius=0.0434 mu=0.39"; GRIP="mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61"
LIM=$(awk 'BEGIN { printf "%.6f", 0.39 * 1.861 * 9.8 }')
# the arms: <name>:<arm>:<rest height>:<drop height>:<steps>:<poses>
ARMSETS="s10:len1=0.271 len2=0.275 mass1=1.113 mass2=0.524 rb=0.0264 mb=0.176 mu=0.717:0.00059:0.0121:0.00114 0.000285:0.604,1.158 1.149,-0.545
s13:len1=0.297 len2=0.302 mass1=1.08 mass2=0.578 rb=0.0295 mb=0.194 mu=0.778:0.00052:0.0121:0.00168 0.00042:0.516,0.907 1.211,-0.464
s14:len1=0.298 len2=0.269 mass1=1.164 mass2=0.522 rb=0.0273 mb=0.167 mu=0.667:0.00054:0.0146:0.00119 0.0002975:0.582,1.117 1.227,-0.516 0.58,0.969 1.276,-0.407
s15:len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686:0.00043:0.0129:0.00171 0.0004275:0.555,0.905 1.157,-0.378 0.57,1.123 1.296,-0.403"
for arm in v1:$V1 v2:$V2; do
  a=${arm%%:*}; mj=${arm#*:}
  X="$W/p86$a"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_grip mjc_arm; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null 2>&1; done
    switches 5
    mkdir -p p; S=p/stats.txt; : > $S
    while IFS= read -r line; do
      an=${line%%:*}; rest=${line#*:}; A=${rest%%:*}; rest=${rest#*:}; H=${rest%%:*}; rest=${rest#*:}; DH=${rest%%:*}; rest=${rest#*:}
      DT=${rest%%:*}; POSES=${rest#*:}
      for dt in $DT; do
        k=0
        for PSE in $POSES; do
          k=$((k + 1))
          # shellcheck disable=SC2086
          tools/mjc_arm p/${an}_rest${k}_$dt.txt dt=$dt pose=$PSE pose0=$PSE $A h0=$H secs=2 $REC | sed "s|^STATS|STATS run ${an}_rest${k}_$dt|" >> $S
          # shellcheck disable=SC2086
          tools/mjc_arm p/${an}_drop${k}_$dt.txt dt=$dt pose=$PSE pose0=$PSE $A h0=$DH secs=3 $REC | sed "s|^STATS|STATS run ${an}_drop${k}_$dt|" >> $S
        done
      done
    done <<< "$ARMSETS"
    for dt in 0.00114 0.000285; do
      for cd in 3 4 6; do
        if [ $cd = 3 ]; then CD=""; else CD="condim=$cd"; fi
        for lk in 1 0; do for fr in 0.5 0.95; do
          pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
          # shellcheck disable=SC2086
          tools/mjc_contact p/hold_c${cd}_lock${lk}_${fr}_$dt.txt dt=$dt h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=0 lock=$lk $REC $CD | sed "s|^STATS|STATS run hold_c${cd}_lock${lk}_${fr}_$dt|" >> $S
        done; done
      done
      for off in 0 0.0092; do for pad in box mesh; do
        # shellcheck disable=SC2086
        tools/mjc_grip p/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $REC | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> $S
      done; done
    done )
  rm -rf "${O:?}/${a:?}"; mkdir -p "$O/$a"; cp -R "$X/p" "$O/$a/"; rm -rf "${X:?}"
  log "$a played"
done
for s in off:0 on:5; do
  n=${s%%:*}; k=${s#*:}
  ( cd "$W/t86" && switches "$k"
    ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$n.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_${n}_large.txt" 2>&1 )
  log "suite $n $(grep -E 'tests passed|tests failed' "$O/ctest_$n.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_${n}_large.txt" | tail -1)"
done
switches 0
for n in off on; do
  cat "$O/ctest_$n.txt" "$O/ctest_${n}_large.txt" | awk 'match($0, /Test +#[0-9]+: /) {
         hdr = substr($0, RSTART, RLENGTH); num = hdr; gsub(/[^0-9]/, "", num); rest = substr($0, RSTART + RLENGTH)
         st = "unknown"
         if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) {
           st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st) }
         name = rest; p = index(name, "  # GetParam()"); if (p > 0) name = substr(name, 1, p - 1)
         p = index(name, " ..."); if (p > 0) name = substr(name, 1, p - 1); sub(/ +$/, "", name)
         print num, name, st }' | sort -n > "$O/suite_results_$n.txt"
done
diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep '^>' | sed 's/^> /changed with every switch set: /' > "$O/suite_changed.txt"
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  n=0; s=0
  for f in $(cd "$O/v1" && find p -type f ! -name stats.txt | sort); do n=$((n + 1)); cmp -s "$O/v1/$f" "$O/v2/$f" && s=$((s + 1)); done
  echo "files v1 against v2: $s of $n the same"
  for f in $(cd "$O/v1" && find p -type f ! -name stats.txt | sort); do cmp -s "$O/v1/$f" "$O/v2/$f" || echo "differ v1 against v2: $f"; done
  for a in v1 v2; do
    echo "$a arms creep_ums $(for f in $(cd "$O/$a/p" && ls s1*_*.txt | sort); do x=$(fld "$("$B" creep "$O/$a/p/$f" | tail -1)" mean_speed_ums); echo "${x#-}"; done | sort -n | tail -1) at most, over $(cd "$O/$a/p" && ls s1*_*.txt | wc -l | tr -d ' ') plays"
    for dt in 0.00114 0.000285; do
      for cd in 3 4 6; do for lk in 1 0; do
        echo "$a hold condim $cd lock $lk $dt creep_ums $(for fr in 0.5 0.95; do fld "$("$B" creep "$O/$a/p/hold_c${cd}_lock${lk}_${fr}_$dt.txt" | tail -1)" mean_speed_ums; done | tr '\n' ' ')"
      done; done
      echo "$a grips $dt creep_ums $(for off in 0 0.0092; do for pad in box mesh; do fld "$("$B" creep "$O/$a/p/grip_${pad}_off${off}_$dt.txt" | tail -1)" mean_speed_ums; done; done | tr '\n' ' ')"
    done
    echo "$a solver most_iterations $(grep -o 'most_iterations [0-9]*' "$O/$a/p/stats.txt" | awk '{ if ($2 > x) x = $2 } END { print x + 0 }') at_iteration_limit $(grep -o 'at_iteration_limit [0-9]*' "$O/$a/p/stats.txt" | awk '{ s += $2 } END { print s + 0 }') warnings $(grep -o 'warnings [0-9]*' "$O/$a/p/stats.txt" | awk '{ s += $2 } END { print s + 0 }')"
  done
  echo "MuJoCo suite on v2: $(wc -l < "$O/suite_results_off.txt" | tr -d ' ') tests; changed with every switch set: $(wc -l < "$O/suite_changed.txt" | tr -d ' ')"
  cat "$O/suite_changed.txt"
  echo "MuJoCo suite, v2 with every switch unset against the release (run 064's suite_results_release.txt): $(diff "$R/validation/run_064_study_14/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>') tests read differently"
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
