#!/usr/bin/env bash
# Run 070: a design probe, not registered: it finds where to look and decides nothing. Run 069 found that a straight
# stack's tilt (issue 21) starts when MuJoCo's box-on-box collision adds contacts along the edges of a face: equal cubes
# face to face put the incident face's edges on the reference face's side planes, and a drift at rounding level makes
# the clip (clipHalfPlane, engine_collision_box.c) emit intersections at arbitrary places along them, each a contact at
# the corners' depth. A patch in design, patches/in_design/boxbox_clip_tol.diff (switch MUJOCO_BOXBOX_CLIPTOL=1;
# engine_collision_box.c only, 58 lines added, none removed), clips with the rounding slack MuJoCo's separation tests
# already carry, so that a vertex within it of a plane is on the plane and an edge on the plane gives only its ends.
# Built from MuJoCo's source at UPSTREAM_COMMIT, with its tests. Arms: rel, MuJoCo 3.16.0 as released; off and on, the
# patch with its switch unset and set. Played, on run 063's numbers (Study 10's cubes): under Senua AI's configuration
# (the elliptic cone, 100 noslip iterations) and under MuJoCo's defaults, at 1.14 and 0.285 ms, straight stacks of 5 and
# 9 and the offset stack of 3, 2 s, each with its contacts traced; a cube slid on a box's face; the cube held at 0.5 and
# 0.95 of its friction limit; the grip, box and mesh pads, at the centre and off it. And run 052's grid under the
# configuration: the stacks of 5 and 9 at steps 0.1425, 0.285, 0.57, 0.855 and 1.14 ms and main tolerances from MuJoCo's
# default (1e-8) to 1e-14, released and with the switch set. MuJoCo's own test suite on the patched build, the switch
# unset and set.
# Readings: the rigs' columns and STATS fields; per stack play, the most tilt of any cube and the changes in the number
# of contacts between any two geoms after the first 30 steps (from the contacts trace, read and not kept); Senua AI's
# measures (sx_contact creep, stop); file comparison by cmp.
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds mujoco-src at UPSTREAM_COMMIT and the release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_070_boxbox_clip"; REL="$W/mujoco-3.16.0"; QB="$W/mujoco-p70-build"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
PF="$R/patches/in_design/boxbox_clip_tol.diff"
rm -rf "${W:?}/mujoco-p70-src" "$W/p70-lib" "$QB" "$W/t70" && mkdir -p "$W/mujoco-p70-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p70-src"
(cd "$W/mujoco-p70-src" && patch -p1 -s < "$PF")
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p70-src" -B "$W/p70-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$QB" && cmake --build "$W/p70-lib" -j"$J" && cmake --install "$W/p70-lib" ) > "$O/build_lib.log" 2>&1
log "build lib exit $?"
( cmake -S "$W/mujoco-p70-src" -B "$W/t70" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t70" -j"$J" ) > "$O/build_tests.log" 2>&1
log "build tests exit $?"
REC="cone=elliptic noslip=100"; KCUBE="mass=0.442 radius=0.0424 mu=0.524"; CUBE="mass=1.861 radius=0.0434 mu=0.39"
LIM=$(awk 'BEGIN { printf "%.6f", 0.39 * 1.861 * 9.8 }'); GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"
# the changes in the number of contacts between any two geoms after the first 30 steps, from a contacts trace
CHG='{ if ($1 != cs) { if (cs != "") fl(cs); cs = $1 } p = $2 "-" $3; seen[p] = 1; cnt[p]++ }
function fl(st,   p) { for (p in seen) { if (st > 30 && cnt[p] != pc[p]) n++; pc[p] = cnt[p]; cnt[p] = 0 } }
END { fl(cs); print n + 0 }'
stack() {  # <out prefix> <settings...>: plays a stack with its contacts traced; appends its STATS line to $S, and
           # "<prefix> <count changes>" to $C
  local p=$1; shift
  tools/mjc_stack "$p" "$@" contacts="$p.contacts" | sed "s|^STATS|STATS run $(basename "$p")|" >> "$S"
  echo "$(basename "$p") $(awk "$CHG" "$p.contacts")" >> "$C"
  rm -f "$p.contacts"
}
for arm in rel: off: on:1; do
  a=${arm%%:*}; sw=${arm#*:}
  case $a in rel) mj=$REL ;; *) mj=$QB ;; esac
  X="$W/p70$a"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_stack mjc_grip; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null 2>&1; done
    if [ -n "$sw" ]; then export MUJOCO_BOXBOX_CLIPTOL=$sw; else unset MUJOCO_BOXBOX_CLIPTOL; fi
    mkdir -p p grid; S=p/stats.txt; C=p/changes.txt; : > $S; : > $C
    for os in rec:$REC def:; do
      on=${os%%:*}; OPTS=${os#*:}
      for dt in 0.00114 0.000285; do
        for n in 5 9; do stack p/stack${n}_${on}_$dt dt=$dt n=$n secs=2 $KCUBE $OPTS; done
        stack p/offset3_${on}_$dt dt=$dt n=3 shift=0.017 secs=2 $KCUBE $OPTS
        # shellcheck disable=SC2086
        tools/mjc_stack p/slide_box_${on}_$dt dt=$dt n=1 vx=1.16 secs=1 base=0.5 $KCUBE $OPTS | sed "s|^STATS|STATS run slide_box_${on}_$dt|" >> $S
        for fr in 0.5 0.95; do
          pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
          # shellcheck disable=SC2086
          tools/mjc_contact p/hold_${fr}_${on}_$dt.txt dt=$dt h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=0 $OPTS | sed "s|^STATS|STATS run hold_${fr}_${on}_$dt|" >> $S
        done
        for off in 0 0.0093; do for pad in box mesh; do
          # shellcheck disable=SC2086
          tools/mjc_grip p/grip_${pad}_off${off}_${on}_$dt dt=$dt offset=$off pad=$pad $GRIP $OPTS | sed "s|^STATS|STATS run grip_${pad}_off${off}_${on}_$dt|" >> $S
        done; done
      done
    done
    if [ "$a" != off ]; then
      S=grid/stats.txt; C=grid/changes.txt; : > $S; : > $C
      for tol in def 1e-9 1e-10 1e-11 1e-12 1e-14; do
        if [ $tol = def ]; then T=""; else T="tolerance=$tol"; fi
        for dt in 0.0001425 0.000285 0.00057 0.000855 0.00114; do
          for n in 5 9; do stack grid/stack${n}_${tol}_$dt dt=$dt n=$n secs=2 $KCUBE $REC $T; done
        done
      done
    fi )
  rm -rf "${O:?}/${a:?}"; mkdir -p "$O/$a"; cp -R "$X/p" "$O/$a/"; [ -d "$X/grid" ] && cp -R "$X/grid" "$O/$a/"; rm -rf "${X:?}"
  log "$a played"
done
unset MUJOCO_BOXBOX_CLIPTOL
# MuJoCo's own test suite on the patched build, the switch unset and set; the two memory-heavy texture tests alone
for s in off: on:1; do
  n=${s%%:*}; sw=${s#*:}
  ( cd "$W/t70" && if [ -n "$sw" ]; then export MUJOCO_BOXBOX_CLIPTOL=$sw; else unset MUJOCO_BOXBOX_CLIPTOL; fi
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
# measuring
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
stk() {  # <prefix>: the most tilt of any cube over the play; at the last step the largest speed (vx or vz)
  local p=$1 t s
  t=$(cat "$p"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }')
  s=$(for f in "$p"_[0-9].txt; do tail -1 "$f"; done | awk '{ x = $3 < 0 ? -$3 : $3; y = $4 < 0 ? -$4 : $4; if (x > m) m = x; if (y > m) m = y } END { print m + 0 }')
  echo "most_tilt_urad $t end_speed_ums $s"
}
{
  for y in off on; do
    n=0; s=0
    for f in $(cd "$O/rel" && find p -type f ! -name stats.txt | sort); do n=$((n + 1)); cmp -s "$O/rel/$f" "$O/$y/$f" && s=$((s + 1)); done
    echo "files rel against $y: $s of $n the same"
  done
  for f in $(cd "$O/rel" && find p -type f ! -name stats.txt | sort); do cmp -s "$O/rel/$f" "$O/on/$f" || echo "differ rel against on: $f"; done
  for a in rel on; do
    for on in rec def; do
      for dt in 0.00114 0.000285; do
        for s in stack5 stack9 offset3; do echo "$a ${s}_${on}_$dt $(stk "$O/$a/p/${s}_${on}_$dt") contact_count_changes $(grep "^${s}_${on}_$dt " "$O/$a/p/changes.txt" | awk '{ print $2 }')"; done
        echo "$a slide_box_${on}_$dt slid_um $(fld "$("$B" stop "$O/$a/p/slide_box_${on}_${dt}_1.txt" | tail -1)" slid_um) $(stk "$O/$a/p/slide_box_${on}_$dt")"
        echo "$a holds_${on}_$dt creep_ums $(for fr in 0.5 0.95; do fld "$("$B" creep "$O/$a/p/hold_${fr}_${on}_$dt.txt" | tail -1)" mean_speed_ums; done | tr '\n' ' ')"
        echo "$a grips_${on}_$dt creep_ums $(for off in 0 0.0093; do for pad in box mesh; do fld "$("$B" creep "$O/$a/p/grip_${pad}_off${off}_${on}_$dt.txt" | tail -1)" mean_speed_ums; done; done | tr '\n' ' ')"
      done
    done
    echo "$a solver most_iterations $(grep -o 'most_iterations [0-9]*' "$O/$a/p/stats.txt" | awk '{ if ($2 > x) x = $2 } END { print x + 0 }') at_iteration_limit $(grep -o 'at_iteration_limit [0-9]*' "$O/$a/p/stats.txt" | awk '{ s += $2 } END { print s + 0 }') warnings $(grep -o 'warnings [0-9]*' "$O/$a/p/stats.txt" | awk '{ s += $2 } END { print s + 0 }')"
  done
  echo "the grid under the configuration, the most tilt of any cube (urad) and the contact count changes, rel then on:"
  for n in 5 9; do
    for dt in 0.0001425 0.000285 0.00057 0.000855 0.00114; do
      line="stack$n $dt"
      for tol in def 1e-9 1e-10 1e-11 1e-12 1e-14; do
        q=stack${n}_${tol}_$dt
        r=$(stk "$O/rel/grid/$q" | awk '{ print $2 }'); rc=$(grep "^$q " "$O/rel/grid/changes.txt" | awk '{ print $2 }')
        o=$(stk "$O/on/grid/$q" | awk '{ print $2 }'); oc=$(grep "^$q " "$O/on/grid/changes.txt" | awk '{ print $2 }')
        line="$line | $tol $r/$rc $o/$oc"
      done
      echo "$line"
    done
  done
  for a in rel on; do echo "$a grid solver most_iterations $(grep -o 'most_iterations [0-9]*' "$O/$a/grid/stats.txt" | awk '{ if ($2 > x) x = $2 } END { print x + 0 }') at_iteration_limit $(grep -o 'at_iteration_limit [0-9]*' "$O/$a/grid/stats.txt" | awk '{ s += $2 } END { print s + 0 }') warnings $(grep -o 'warnings [0-9]*' "$O/$a/grid/stats.txt" | awk '{ s += $2 } END { print s + 0 }')"; done
  echo "MuJoCo suite: $(wc -l < "$O/suite_results_off.txt" | tr -d ' ') tests; changed with the switch set: $(wc -l < "$O/suite_changed.txt" | tr -d ' ')"
  echo "MuJoCo suite, the switch unset against the release (run 064's suite_results_release.txt): $(diff "$R/validation/run_064_study_14/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>') tests read differently"
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
