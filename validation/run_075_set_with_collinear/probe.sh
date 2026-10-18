#!/usr/bin/env bash
# Run 075: a design probe, not registered: it finds where to look and decides nothing. Run 074's patch in design, the
# box-on-box clip's polygon without its collinear vertices (patches/in_design/boxbox_collinear.diff, switch
# MUJOCO_BOXBOX_COLLINEAR=1, engine_collision_box.c), stood every stack of run 052's grid with no change in its contacts
# and changed none of MuJoCo's tests. Senua AI's set (Study 15) is the configuration with three patches: the inverse
# weight in the current pose (patches/invweight_at_pose_v3.diff), de Saxce's correction (patches/desaxce_elliptic_v4.diff)
# and the friction solved in the directions that can move (patches/qcqp_reduced.diff); under it de Saxce's correction
# tipped a stack of 9 the release keeps upright (Study 12, runs 066 and 068). This builds the four patches into one
# MuJoCo, from its source at UPSTREAM_COMMIT, with its tests. Arms, all under the configuration (the elliptic cone, 100
# noslip iterations): rel, MuJoCo 3.16.0 as released; off, every switch unset; set, the three switches of Study 15; set4,
# those and the collinear switch. Played, on run 063's cube (Study 10's): straight stacks of 3, 5, 9 and 12 at steps
# 0.1425, 0.285, 0.57, 1.14 and 1.71 ms, 2 s; stacks of 3 offset by 17 mm and by 1 mm a cube, and a stack of 5 on a fixed
# box of half-size 0.5 m, at 0.285 and 1.14 ms; each stack with its contacts traced. A cube slid on a box's face, the
# cube held at 0.5 and 0.95 of its friction limit, the grip with box and mesh pads at the centre and off it, at 0.285 and
# 1.14 ms; Study 15's arm set down in its four poses and dropped (3 s), at its two steps. MuJoCo's own test suite on the
# build, every switch unset and the four set.
# Readings: the rigs' columns and STATS fields; per stack, the most tilt of any cube and the changes in the number of
# contacts between any two geoms after step 30 (from the contacts trace, read and not kept); Senua AI's measures
# (sx_contact creep, stop); file comparison by cmp.
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds mujoco-src at UPSTREAM_COMMIT and the release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_075_set_with_collinear"; REL="$W/mujoco-3.16.0"; QB="$W/mujoco-p75-build"
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
PI="$R/patches/invweight_at_pose_v3.diff"; PD="$R/patches/desaxce_elliptic_v4.diff"; PQ="$R/patches/qcqp_reduced.diff"
PC="$R/patches/in_design/boxbox_collinear.diff"
rm -rf "${W:?}/mujoco-p75-src" "$W/p75-lib" "$QB" "$W/t75" && mkdir -p "$W/mujoco-p75-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p75-src"
(cd "$W/mujoco-p75-src" && patch -p1 -s < "$PI" && patch -p1 -s < "$PD" && patch -p1 -s < "$PQ" && patch -p1 -s < "$PC")
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in "$PI" "$PD" "$PQ" "$PC"; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p75-src" -B "$W/p75-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$QB" && cmake --build "$W/p75-lib" -j"$J" && cmake --install "$W/p75-lib" ) > "$O/build_lib.log" 2>&1
log "build lib exit $?"
( cmake -S "$W/mujoco-p75-src" -B "$W/t75" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t75" -j"$J" ) > "$O/build_tests.log" 2>&1
log "build tests exit $?"
switches() {  # <0, 3 or 4>: no switch, Study 15's three, or those and the collinear switch
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR
  if [ "$1" -ge 3 ]; then export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1; fi
  if [ "$1" -ge 4 ]; then export MUJOCO_BOXBOX_COLLINEAR=1; fi
}
REC="cone=elliptic noslip=100"; KCUBE="mass=0.442 radius=0.0424 mu=0.524"; CUBE="mass=1.861 radius=0.0434 mu=0.39"
LIM=$(awk 'BEGIN { printf "%.6f", 0.39 * 1.861 * 9.8 }'); GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"
A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"
CHG='{ if ($1 != cs) { if (cs != "") fl(cs); cs = $1 } p = $2 "-" $3; seen[p] = 1; cnt[p]++ }
function fl(st,   p) { for (p in seen) { if (st > 30 && cnt[p] != pc[p]) n++; pc[p] = cnt[p]; cnt[p] = 0 } }
END { fl(cs); print n + 0 }'
stack() {  # <out prefix> <settings...>: a stack with its contacts traced; its STATS line to $S, "<name> <changes>" to $C
  local p=$1; shift
  tools/mjc_stack "$p" "$@" contacts="$p.contacts" | sed "s|^STATS|STATS run $(basename "$p")|" >> "$S"
  echo "$(basename "$p") $(awk "$CHG" "$p.contacts")" >> "$C"
  rm -f "$p.contacts"
}
for arm in rel:0 off:0 set:3 set4:4; do
  a=${arm%%:*}; k=${arm#*:}
  case $a in rel) mj=$REL ;; *) mj=$QB ;; esac
  X="$W/p75$a"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/"
  ( cd "$X" || exit 2
    for n in mjc_contact mjc_stack mjc_grip mjc_arm; do MUJOCO_DIR=$mj tools/build_rig.sh $n > /dev/null 2>&1; done
    switches "$k"
    mkdir -p p arms; S=p/stats.txt; C=p/changes.txt; T=arms/stats.txt; : > $S; : > $C; : > $T
    for dt in 0.0001425 0.000285 0.00057 0.00114 0.00171; do
      # shellcheck disable=SC2086
      for n in 3 5 9 12; do stack p/stack${n}_$dt dt=$dt n=$n secs=2 $KCUBE $REC; done
    done
    for dt in 0.000285 0.00114; do
      # shellcheck disable=SC2086
      stack p/offset17_$dt dt=$dt n=3 shift=0.017 secs=2 $KCUBE $REC
      # shellcheck disable=SC2086
      stack p/offset1_$dt dt=$dt n=3 shift=0.001 secs=2 $KCUBE $REC
      # shellcheck disable=SC2086
      stack p/onbox5_$dt dt=$dt n=5 base=0.5 secs=2 $KCUBE $REC
      # shellcheck disable=SC2086
      tools/mjc_stack p/slide_box_$dt dt=$dt n=1 vx=1.16 secs=1 base=0.5 $KCUBE $REC | sed "s|^STATS|STATS run slide_box_$dt|" >> $S
      for fr in 0.5 0.95; do
        pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
        # shellcheck disable=SC2086
        tools/mjc_contact p/hold_${fr}_$dt.txt dt=$dt h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=0 $REC | sed "s|^STATS|STATS run hold_${fr}_$dt|" >> $S
      done
      for off in 0 0.0093; do for pad in box mesh; do
        # shellcheck disable=SC2086
        tools/mjc_grip p/grip_${pad}_off${off}_$dt dt=$dt offset=$off pad=$pad $GRIP $REC | sed "s|^STATS|STATS run grip_${pad}_off${off}_$dt|" >> $S
      done; done
    done
    for dt in 0.00171 0.0004275; do
      k2=0
      for PS in 0.555,0.905 1.157,-0.378 0.57,1.123 1.296,-0.403; do
        k2=$((k2 + 1))
        # shellcheck disable=SC2086
        tools/mjc_arm arms/rest_pose${k2}_$dt.txt dt=$dt pose=$PS pose0=$PS $A15 h0=0.00043 secs=2 $REC | sed "s|^STATS|STATS run rest_pose${k2}_$dt|" >> $T
        # shellcheck disable=SC2086
        tools/mjc_arm arms/drop_pose${k2}_$dt.txt dt=$dt pose=$PS pose0=$PS $A15 h0=0.0129 secs=3 $REC | sed "s|^STATS|STATS run drop_pose${k2}_$dt|" >> $T
      done
    done )
  rm -rf "${O:?}/${a:?}"; mkdir -p "$O/$a"; cp -R "$X/p" "$X/arms" "$O/$a/"; rm -rf "${X:?}"
  log "$a played"
done
switches 0
for s in off:0 set4:4; do
  n=${s%%:*}; k=${s#*:}
  ( cd "$W/t75" && switches "$k"
    ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$n.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_${n}_large.txt" 2>&1 )
  log "suite $n $(grep -E 'tests passed|tests failed' "$O/ctest_$n.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_${n}_large.txt" | tail -1)"
done
for n in off set4; do
  cat "$O/ctest_$n.txt" "$O/ctest_${n}_large.txt" | awk 'match($0, /Test +#[0-9]+: /) {
         hdr = substr($0, RSTART, RLENGTH); num = hdr; gsub(/[^0-9]/, "", num); rest = substr($0, RSTART + RLENGTH)
         st = "unknown"
         if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) {
           st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st) }
         name = rest; p = index(name, "  # GetParam()"); if (p > 0) name = substr(name, 1, p - 1)
         p = index(name, " ..."); if (p > 0) name = substr(name, 1, p - 1); sub(/ +$/, "", name)
         print num, name, st }' | sort -n > "$O/suite_results_$n.txt"
done
diff "$O/suite_results_off.txt" "$O/suite_results_set4.txt" | grep '^>' | sed 's/^> /changed with the four switches set: /' > "$O/suite_changed_set4.txt"
# measuring
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
tilt() { cat "$1"_*_tilt.txt | awk '$1 != "CONTACT" { x = $2 < 0 ? -$2 : $2; if (x > m) m = x } END { print m + 0 }'; }
chg() { grep "^$2 " "$O/$1/p/changes.txt" | awk '{ print $2 }'; }
{
  for y in off set set4; do
    n=0; s=0
    for f in $(cd "$O/rel" && find p arms -type f ! -name stats.txt | sort); do n=$((n + 1)); cmp -s "$O/rel/$f" "$O/$y/$f" && s=$((s + 1)); done
    echo "files rel against $y: $s of $n the same"
  done
  n=0; s=0
  for f in $(cd "$O/set" && find p arms -type f ! -name stats.txt ! -name changes.txt | sort); do n=$((n + 1)); cmp -s "$O/set/$f" "$O/set4/$f" && s=$((s + 1)); done
  echo "files set against set4: $s of $n the same"
  for f in $(cd "$O/set" && find p arms -type f ! -name stats.txt ! -name changes.txt | sort); do cmp -s "$O/set/$f" "$O/set4/$f" || echo "$f"; done | sed 's/_[0-9]*\(_tilt\)\{0,1\}\.txt$//; s/\.txt$//' | sort -u | sed 's/^/differ set against set4: /'
  echo "the straight stacks, the most tilt of any cube (urad) / the contact count changes, rel | set | set4:"
  for n in 3 5 9 12; do
    for dt in 0.0001425 0.000285 0.00057 0.00114 0.00171; do
      q=stack${n}_$dt
      echo "  $q | $(tilt "$O/rel/p/$q")/$(chg rel "$q") | $(tilt "$O/set/p/$q")/$(chg set "$q") | $(tilt "$O/set4/p/$q")/$(chg set4 "$q")"
    done
  done
  for dt in 0.000285 0.00114; do
    for q in offset17 offset1 onbox5; do echo "  ${q}_$dt | $(tilt "$O/rel/p/${q}_$dt")/$(chg rel "${q}_$dt") | $(tilt "$O/set/p/${q}_$dt")/$(chg set "${q}_$dt") | $(tilt "$O/set4/p/${q}_$dt")/$(chg set4 "${q}_$dt")"; done
  done
  for a in rel set set4; do
    for dt in 0.000285 0.00114; do
      echo "$a slide_box_$dt slid_um $(fld "$("$B" stop "$O/$a/p/slide_box_${dt}_1.txt" | tail -1)" slid_um) holds $(for fr in 0.5 0.95; do fld "$("$B" creep "$O/$a/p/hold_${fr}_$dt.txt" | tail -1)" mean_speed_ums; done | tr '\n' ' ')grips $(for off in 0 0.0093; do for pad in box mesh; do fld "$("$B" creep "$O/$a/p/grip_${pad}_off${off}_$dt.txt" | tail -1)" mean_speed_ums; done; done | tr '\n' ' ')"
    done
    echo "$a arms rest $(for dt in 0.00171 0.0004275; do for k in 1 2 3 4; do fld "$("$B" creep "$O/$a/arms/rest_pose${k}_$dt.txt" | tail -1)" mean_speed_ums; done; done | tr '\n' ' ')drop $(for dt in 0.00171 0.0004275; do for k in 1 2 3 4; do fld "$("$B" creep "$O/$a/arms/drop_pose${k}_$dt.txt" | tail -1)" mean_speed_ums; done; done | tr '\n' ' ')"
    echo "$a solver most_iterations $(cat "$O/$a/p/stats.txt" "$O/$a/arms/stats.txt" | grep -o 'most_iterations [0-9]*' | awk '{ if ($2 > x) x = $2 } END { print x + 0 }') at_iteration_limit $(cat "$O/$a/p/stats.txt" "$O/$a/arms/stats.txt" | grep -o 'at_iteration_limit [0-9]*' | awk '{ s += $2 } END { print s + 0 }') warnings $(cat "$O/$a/p/stats.txt" "$O/$a/arms/stats.txt" | grep -o 'warnings [0-9]*' | awk '{ s += $2 } END { print s + 0 }')"
  done
  echo "MuJoCo suite: $(wc -l < "$O/suite_results_off.txt" | tr -d ' ') tests; changed with the four switches set: $(wc -l < "$O/suite_changed_set4.txt" | tr -d ' ')"
  echo "MuJoCo suite, every switch unset against the release (run 064's suite_results_release.txt): $(diff "$R/validation/run_064_study_14/suite_results_release.txt" "$O/suite_results_off.txt" | grep -c '^>') tests read differently"
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
