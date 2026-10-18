#!/usr/bin/env bash
# Run 082: a design probe, not registered: it finds where to look and decides nothing. Runs 076 and 079 traced two
# defects to a condim-6 contact's rolling friction sharing one ellipsoid with its sliding friction: the box that never
# rests (issue 20) and, under Senua AI's configuration, a held cube that creeps (issue 1, for rolling friction; run 079's
# patch rested the box and left the creep). A second design, patches/in_design/noslip_roll_cone.diff (switch
# MUJOCO_NOSLIP_ROLL_CONE=1; engine_solver.c only, 50 lines added, none removed): noslip solves a condim-6 contact's
# sliding and torsional friction in the ellipsoid of radius the normal force, with the rolling friction held, then the
# rolling friction in an ellipsoid of its own of the same radius, each with MuJoCo's own solver. Built from MuJoCo's source at UPSTREAM_COMMIT,
# with its tests. Arms: rel, MuJoCo 3.16.0 as released; off and on, the patch with its switch unset and set. Played: the
# box scene of run 049 as written (16 s), with 100 noslip iterations, and with condim 4 (run 076's copy); under Senua AI's
# configuration (the elliptic cone, 100 noslip iterations) with condim 6, run 063's cube (Study 10's) held at 0.5 and
# 0.95 of its friction limit and slid kept from turning and free to turn, at 1.14 and 0.285 ms; and, with condim 3 as
# every earlier play, the holds, the slides and the grips of run 063 at the same steps. MuJoCo's own test suite on the
# build, the switch unset and set.
# Readings: Senua AI's measures (sx_contact creep, stop, hover), the rigs' columns and STATS fields, file comparison by
# cmp.
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds mujoco-src at UPSTREAM_COMMIT and the release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_082_noslip_roll_cone"; REL="$W/mujoco-3.16.0"; QB="$W/mujoco-p82-build"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
PF="$R/patches/in_design/noslip_roll_cone.diff"
rm -rf "${W:?}/mujoco-p82-src" "$W/p82-lib" "$QB" "$W/t82" && mkdir -p "$W/mujoco-p82-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p82-src"
(cd "$W/mujoco-p82-src" && patch -p1 -s < "$PF")
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p82-src" -B "$W/p82-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$QB" && cmake --build "$W/p82-lib" -j"$J" && cmake --install "$W/p82-lib" ) > "$O/build_lib.log" 2>&1
log "build lib exit $?"
( cmake -S "$W/mujoco-p82-src" -B "$W/t82" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t82" -j"$J" ) > "$O/build_tests.log" 2>&1
log "build tests exit $?"
REC="cone=elliptic noslip=100"; CUBE="mass=1.861 radius=0.0434 mu=0.39"; GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"
LIM=$(awk 'BEGIN { printf "%.6f", 0.39 * 1.861 * 9.8 }')
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"; SC4="$R/validation/run_076_box_rolling_trace/scene_condim4.xml"
for arm in rel: off: on:1; do
  a=${arm%%:*}; sw=${arm#*:}
  case $a in rel) mj=$REL ;; *) mj=$QB ;; esac
  X="$W/p82$a"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_grip mjc_scene; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null 2>&1; done
    if [ -n "$sw" ]; then export MUJOCO_NOSLIP_ROLL_CONE=$sw; else unset MUJOCO_NOSLIP_ROLL_CONE; fi
    mkdir -p p; S=p/stats.txt; : > $S
    tools/mjc_scene p/box_written.txt scene="$SCN" body=box axis=1,0,0 secs=16 key=0 | sed "s|^STATS|STATS run box_written|" >> $S
    tools/mjc_scene p/box_n100.txt scene="$SCN" body=box axis=1,0,0 secs=16 key=0 noslip=100 | sed "s|^STATS|STATS run box_n100|" >> $S
    tools/mjc_scene p/box_condim4.txt scene="$SC4" body=box axis=1,0,0 secs=16 key=0 | sed "s|^STATS|STATS run box_condim4|" >> $S
    for dt in 0.00114 0.000285; do
      for cd in 6 3; do
        if [ $cd = 6 ]; then CD="condim=6"; else CD=""; fi
        for fr in 0.5 0.95; do
          pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
          # shellcheck disable=SC2086
          tools/mjc_contact p/hold_c${cd}_${fr}_$dt.txt dt=$dt h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=0 $REC $CD | sed "s|^STATS|STATS run hold_c${cd}_${fr}_$dt|" >> $S
        done
        # shellcheck disable=SC2086
        tools/mjc_contact p/slide_c${cd}_$dt.txt dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 dir=0 $REC $CD | sed "s|^STATS|STATS run slide_c${cd}_$dt|" >> $S
        # shellcheck disable=SC2086
        tools/mjc_contact p/free_c${cd}_$dt.txt dt=$dt h0=0 vx0=1.01 $CUBE secs=1.2 lock=0 dir=22.5 $REC $CD | sed "s|^STATS|STATS run free_c${cd}_$dt|" >> $S
      done
      for off in 0 0.0093; do for pad in box mesh; do
        # shellcheck disable=SC2086
        tools/mjc_grip p/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $REC | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> $S
      done; done
    done )
  rm -rf "${O:?}/${a:?}"; mkdir -p "$O/$a"; cp -R "$X/p" "$O/$a/"; rm -rf "${X:?}"
  log "$a played"
done
unset MUJOCO_NOSLIP_ROLL_CONE
for s in off: on:1; do
  n=${s%%:*}; sw=${s#*:}
  ( cd "$W/t82" && if [ -n "$sw" ]; then export MUJOCO_NOSLIP_ROLL_CONE=$sw; else unset MUJOCO_NOSLIP_ROLL_CONE; fi
    ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$n.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_${n}_large.txt" 2>&1 )
  log "suite $n $(grep -E 'tests passed|tests failed' "$O/ctest_$n.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_${n}_large.txt" | tail -1)"
done
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
diff "$O/suite_results_off.txt" "$O/suite_results_on.txt" | grep '^>' | sed 's/^> /changed with the switch set: /' > "$O/suite_changed.txt"
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  for y in off on; do
    n=0; s=0
    for f in $(cd "$O/rel" && find p -type f ! -name stats.txt | sort); do n=$((n + 1)); cmp -s "$O/rel/$f" "$O/$y/$f" && s=$((s + 1)); done
    echo "files rel against $y: $s of $n the same"
  done
  for f in $(cd "$O/rel" && find p -type f ! -name stats.txt | sort); do cmp -s "$O/rel/$f" "$O/on/$f" || echo "differ rel against on: $f"; done
  for a in rel on; do
    for b in written n100 condim4; do
      echo "$a box_$b $(awk 'NR > 1 { s[NR] = $0; m = NR } END { c = 0; x0 = 0; for (i = m - 159; i <= m; i++) { split(s[i], f, " "); x = f[3] < 0 ? -f[3] : f[3]; if (x > 1000) c++; if (x > x0) x0 = x } printf "last 160 steps faster than 1 mm/s: %d, fastest %d um/s", c, x0 }' "$O/$a/p/box_$b.txt")"
    done
    for dt in 0.00114 0.000285; do
      for cd in 6 3; do
        echo "$a condim $cd $dt holds_creep_ums $(for fr in 0.5 0.95; do fld "$("$B" creep "$O/$a/p/hold_c${cd}_${fr}_$dt.txt" | tail -1)" mean_speed_ums; done | tr '\n' ' ')slide_slid_um $(fld "$("$B" stop "$O/$a/p/slide_c${cd}_$dt.txt" | tail -1)" slid_um) slide_highest_um $(fld "$("$B" hover "$O/$a/p/slide_c${cd}_$dt.txt" | tail -1)" highest_um) free_slid_um $(fld "$("$B" stop "$O/$a/p/free_c${cd}_$dt.txt" | tail -1)" slid_um)"
      done
      echo "$a grips $dt creep_ums $(for off in 0 0.0093; do for pad in box mesh; do fld "$("$B" creep "$O/$a/p/grip_${pad}_off${off}_$dt.txt" | tail -1)" mean_speed_ums; done; done | tr '\n' ' ')"
    done
    echo "$a solver most_iterations $(grep -o 'most_iterations [0-9]*' "$O/$a/p/stats.txt" | awk '{ if ($2 > x) x = $2 } END { print x + 0 }') at_iteration_limit $(grep -o 'at_iteration_limit [0-9]*' "$O/$a/p/stats.txt" | awk '{ s += $2 } END { print s + 0 }') warnings $(grep -o 'warnings [0-9]*' "$O/$a/p/stats.txt" | awk '{ s += $2 } END { print s + 0 }')"
  done
  echo "MuJoCo suite: $(wc -l < "$O/suite_results_off.txt" | tr -d ' ') tests; changed with the switch set: $(wc -l < "$O/suite_changed.txt" | tr -d ' ')"
  cat "$O/suite_changed.txt"
  echo "MuJoCo suite, the switch unset against the release (run 064's suite_results_release.txt): $(diff "$R/validation/run_064_study_14/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>') tests read differently"
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
