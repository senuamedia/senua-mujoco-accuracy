#!/usr/bin/env bash
# Run 084: a design probe, not registered: it finds where to look and decides nothing. Run 083 found a cube with torsional
# or rolling friction (condim 4 or 6) held from turning under Senua AI's configuration creeping because noslip's
# friction solve returns zero for its contacts, whose torsional and rolling directions cannot move: issue 1's own
# mechanism, which the friction-solve patch of Senua AI's set addresses; runs 079 and 082 were built without that patch.
# Runs 079 and 082 brought the box that never rests (issue 20) to rest with two designs for the rolling friction. This
# plays Senua AI's set with the collinear patch (patches/invweight_at_pose_v3.diff, desaxce_elliptic_v4.diff,
# qcqp_reduced.diff, boxbox_collinear.diff) and, as a fifth, run 079's design made to apply after the friction-solve
# patch and to solve through it (patches/in_design/noslip_roll_kept_after_qcqp.diff, switch MUJOCO_NOSLIP_ROLL_KEPT=1,
# 45 lines added, none removed), in one build from MuJoCo's source at UPSTREAM_COMMIT, with its tests. Arms, all under
# the configuration (the elliptic cone, 100 noslip iterations) unless a scene sets its own: rel, MuJoCo 3.16.0 as
# released; set4, the four validated switches; set5, those and the rolling switch. Played: run 063's cube (Study 10's)
# held at 0.5 and 0.95 of its friction limit with condim 3, 4 and 6, held from turning and free to turn, and slid kept
# from turning and free to turn with condim 6, at 1.14 and 0.285 ms; the grips (condim 3); Study 15's arm set down and
# dropped in two poses at its two steps; and the box of run 049 (MuJoCo's test scene, its own options), as written and
# with 100 noslip iterations. MuJoCo's own test suite on the build, every switch unset and the five set.
# Readings: Senua AI's measures (sx_contact creep, stop), the rigs' columns and STATS fields, file comparison by cmp.
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds mujoco-src at UPSTREAM_COMMIT and the release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_084_set_condim_holds"; REL="$W/mujoco-3.16.0"; QB="$W/mujoco-p84-build"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
PS="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/qcqp_reduced.diff $R/patches/boxbox_collinear.diff $R/patches/in_design/noslip_roll_kept_after_qcqp.diff"
rm -rf "${W:?}/mujoco-p84-src" "$W/p84-lib" "$QB" "$W/t84" && mkdir -p "$W/mujoco-p84-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p84-src"
for p in $PS; do (cd "$W/mujoco-p84-src" && patch -p1 -s < "$p"); done
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in $PS; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p84-src" -B "$W/p84-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$QB" && cmake --build "$W/p84-lib" -j"$J" && cmake --install "$W/p84-lib" ) > "$O/build_lib.log" 2>&1
log "build lib exit $?"
( cmake -S "$W/mujoco-p84-src" -B "$W/t84" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t84" -j"$J" ) > "$O/build_tests.log" 2>&1
log "build tests exit $?"
switches() {  # <0, 4 or 5>
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT
  if [ "$1" -ge 4 ]; then export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1; fi
  if [ "$1" -ge 5 ]; then export MUJOCO_NOSLIP_ROLL_KEPT=1; fi
}
REC="cone=elliptic noslip=100"; CUBE="mass=1.861 radius=0.0434 mu=0.39"; GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"
LIM=$(awk 'BEGIN { printf "%.6f", 0.39 * 1.861 * 9.8 }')
A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"
for arm in rel:0 set4:4 set5:5; do
  a=${arm%%:*}; k=${arm#*:}
  case $a in rel) mj=$REL ;; *) mj=$QB ;; esac
  X="$W/p84$a"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_grip mjc_arm mjc_scene; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null 2>&1; done
    switches "$k"
    mkdir -p p; S=p/stats.txt; : > $S
    tools/mjc_scene p/box_written.txt scene="$SCN" body=box axis=1,0,0 secs=16 key=0 | sed "s|^STATS|STATS run box_written|" >> $S
    tools/mjc_scene p/box_n100.txt scene="$SCN" body=box axis=1,0,0 secs=16 key=0 noslip=100 | sed "s|^STATS|STATS run box_n100|" >> $S
    for dt in 0.00114 0.000285; do
      for cd in 3 4 6; do
        if [ $cd = 3 ]; then CD=""; else CD="condim=$cd"; fi
        for lk in 1 0; do
          for fr in 0.5 0.95; do
            pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
            # shellcheck disable=SC2086
            tools/mjc_contact p/hold_c${cd}_lock${lk}_${fr}_$dt.txt dt=$dt h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=0 lock=$lk $REC $CD | sed "s|^STATS|STATS run hold_c${cd}_lock${lk}_${fr}_$dt|" >> $S
          done
        done
      done
      for lk in 1 0; do
        # shellcheck disable=SC2086
        tools/mjc_contact p/slide_c6_lock${lk}_$dt.txt dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 dir=22.5 lock=$lk $REC condim=6 | sed "s|^STATS|STATS run slide_c6_lock${lk}_$dt|" >> $S
      done
      for off in 0 0.0093; do for pad in box mesh; do
        # shellcheck disable=SC2086
        tools/mjc_grip p/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $REC | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> $S
      done; done
    done
    for dt in 0.00171 0.0004275; do
      k2=0
      for PSE in 0.555,0.905 1.157,-0.378; do
        k2=$((k2 + 1))
        # shellcheck disable=SC2086
        tools/mjc_arm p/rest_pose${k2}_$dt.txt dt=$dt pose=$PSE pose0=$PSE $A15 h0=0.00043 secs=2 $REC | sed "s|^STATS|STATS run rest_pose${k2}_$dt|" >> $S
        # shellcheck disable=SC2086
        tools/mjc_arm p/drop_pose${k2}_$dt.txt dt=$dt pose=$PSE pose0=$PSE $A15 h0=0.0129 secs=3 $REC | sed "s|^STATS|STATS run drop_pose${k2}_$dt|" >> $S
      done
    done )
  rm -rf "${O:?}/${a:?}"; mkdir -p "$O/$a"; cp -R "$X/p" "$O/$a/"; rm -rf "${X:?}"
  log "$a played"
done
switches 0
for s in off:0 set5:5; do
  n=${s%%:*}; k=${s#*:}
  ( cd "$W/t84" && switches "$k"
    ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$n.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_${n}_large.txt" 2>&1 )
  log "suite $n $(grep -E 'tests passed|tests failed' "$O/ctest_$n.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_${n}_large.txt" | tail -1)"
done
for n in off set5; do
  cat "$O/ctest_$n.txt" "$O/ctest_${n}_large.txt" | awk 'match($0, /Test +#[0-9]+: /) {
         hdr = substr($0, RSTART, RLENGTH); num = hdr; gsub(/[^0-9]/, "", num); rest = substr($0, RSTART + RLENGTH)
         st = "unknown"
         if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) {
           st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st) }
         name = rest; p = index(name, "  # GetParam()"); if (p > 0) name = substr(name, 1, p - 1)
         p = index(name, " ..."); if (p > 0) name = substr(name, 1, p - 1); sub(/ +$/, "", name)
         print num, name, st }' | sort -n > "$O/suite_results_$n.txt"
done
diff "$O/suite_results_off.txt" "$O/suite_results_set5.txt" | grep '^>' | sed 's/^> /changed with the five switches set: /' > "$O/suite_changed_set5.txt"
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  n=0; s=0
  for f in $(cd "$O/set4" && find p -type f ! -name stats.txt | sort); do n=$((n + 1)); cmp -s "$O/set4/$f" "$O/set5/$f" && s=$((s + 1)); done
  echo "files set4 against set5: $s of $n the same"
  for f in $(cd "$O/set4" && find p -type f ! -name stats.txt | sort); do cmp -s "$O/set4/$f" "$O/set5/$f" || echo "differ set4 against set5: $f"; done
  for a in rel set4 set5; do
    for b in written n100; do
      echo "$a box_$b $(awk 'NR > 1 { s[NR] = $0; m = NR } END { c = 0; x0 = 0; for (i = m - 159; i <= m; i++) { split(s[i], f, " "); x = f[3] < 0 ? -f[3] : f[3]; if (x > 1000) c++; if (x > x0) x0 = x } printf "last 160 steps faster than 1 mm/s: %d, fastest %d um/s", c, x0 }' "$O/$a/p/box_$b.txt")"
    done
    for dt in 0.00114 0.000285; do
      for cd in 3 4 6; do for lk in 1 0; do
        echo "$a hold condim $cd lock $lk $dt creep_ums $(for fr in 0.5 0.95; do fld "$("$B" creep "$O/$a/p/hold_c${cd}_lock${lk}_${fr}_$dt.txt" | tail -1)" mean_speed_ums; done | tr '\n' ' ')"
      done; done
      echo "$a slide condim 6 $dt slid_um $(for lk in 1 0; do fld "$("$B" stop "$O/$a/p/slide_c6_lock${lk}_$dt.txt" | tail -1)" slid_um; done | tr '\n' ' ')"
      echo "$a grips $dt creep_ums $(for off in 0 0.0093; do for pad in box mesh; do fld "$("$B" creep "$O/$a/p/grip_${pad}_off${off}_$dt.txt" | tail -1)" mean_speed_ums; done; done | tr '\n' ' ')"
    done
    echo "$a arm creep_ums $(for dt in 0.00171 0.0004275; do for k in 1 2; do for w in rest drop; do fld "$("$B" creep "$O/$a/p/${w}_pose${k}_$dt.txt" | tail -1)" mean_speed_ums; done; done; done | tr '\n' ' ')"
    echo "$a solver most_iterations $(grep -o 'most_iterations [0-9]*' "$O/$a/p/stats.txt" | awk '{ if ($2 > x) x = $2 } END { print x + 0 }') at_iteration_limit $(grep -o 'at_iteration_limit [0-9]*' "$O/$a/p/stats.txt" | awk '{ s += $2 } END { print s + 0 }') warnings $(grep -o 'warnings [0-9]*' "$O/$a/p/stats.txt" | awk '{ s += $2 } END { print s + 0 }')"
  done
  echo "MuJoCo suite: $(wc -l < "$O/suite_results_off.txt" | tr -d ' ') tests; changed with the five switches set: $(wc -l < "$O/suite_changed_set5.txt" | tr -d ' ')"
  cat "$O/suite_changed_set5.txt"
  echo "MuJoCo suite, every switch unset against the release (run 064's suite_results_release.txt): $(diff "$R/validation/run_064_study_14/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>') tests read differently"
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
