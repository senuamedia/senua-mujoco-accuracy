#!/usr/bin/env bash
# Run 043: a design probe, not registered. The fixes already in the wild for a held object that creeps (finding F1,
# known issue M1), measured by Senua AI's Measure on the same scenes as Senua AI's own fix. Nothing is decided.
#   Part A, on Google DeepMind's 3.16.0 release: MuJoCo's defaults; impratio 10 and 100; the elliptic cone alone and
#     with impratio 10; noslip under the default cone; and Senua AI's recommended configuration, the elliptic cone with
#     10 noslip iterations. On the holds (three pushes, three directions, two steps) and the grips.
#   Part B, MuJoCo pull request #3349's stiction (pr3349.diff, this folder), on its own builds: june, MuJoCo at the
#     commit the pull request branched from (55c6332f); off and on, the pull request's head with its flag unset and
#     set; cfg, Senua AI's configuration on that head. All four on the elliptic cone, the only cone stiction applies
#     to. On the holds; a held cube moved 2 mm from outside (teleport); a held cube shoved past its limit, with the
#     state saved before the shove restored after it (restore), beside the same play without the detour; and the pull
#     request's own two demo scenes, ramp.xml and gripper.xml, extracted from its diff and played as its author wrote
#     them (stiction on), with the flag line removed (off, june) and with it removed and 10 noslip iterations (cfg).
#     MuJoCo's own test suite on june and on the pull request's head, the flag unset.
# Throwaway numbers: Study 10's cube and grip. Every reading is Senua AI's measuring program's (creep, gap, ends); file
# comparisons are cmp.
# usage: probe.sh <folder holding sx_contact> <work folder>   (repository root, on the cloud machine; the work folder
#        holds mujoco-src, a clone of google-deepmind/mujoco, and the release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_043_fixes_in_the_wild"; J=$(nproc)
BASE=55c6332f207b5ff2a67addfb3b606570791da8f2; HEAD=4c7bdaf692e7bec1018b91b2c9c24265cec476a7
: > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
# ---- the two builds of part B, from MuJoCo's own repository: the pull request's head and the commit it branched from
( cd "$W/mujoco-src" && { git cat-file -e $HEAD 2>/dev/null || git fetch -q origin pull/3349/head; } \
    && { git cat-file -e $BASE 2>/dev/null || git fetch -q origin $BASE; } )
echo "pull request head $HEAD; branched from $BASE; its diff from there, sha256 $(cd "$W/mujoco-src" && git diff $BASE $HEAD | sha256sum | cut -c1-16), this folder's pr3349.diff $(sha256sum "$O/pr3349.diff" | cut -c1-16)" > "$O/build_check.txt"
for pair in june:$BASE pr:$HEAD; do
  n=${pair%%:*}; rev=${pair#*:}
  rm -rf "${W:?}/mujoco-p43$n-src" "$W/p43$n-lib" "$W/mujoco-p43$n-build" "$W/t43$n" && mkdir -p "$W/mujoco-p43$n-src"
  (cd "$W/mujoco-src" && git archive $rev) | tar x -C "$W/mujoco-p43$n-src"
  ( cmake -S "$W/mujoco-p43$n-src" -B "$W/p43$n-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$W/mujoco-p43$n-build" && cmake --build "$W/p43$n-lib" -j"$J" && cmake --install "$W/p43$n-lib" ) > "$O/build_lib_$n.log" 2>&1
  log "build lib $n exit $?"
  echo "$n $(sha256sum "$W/mujoco-p43$n-build/lib/libmujoco.so" | cut -c1-16) $(cat "$W/mujoco-p43$n-src/include/mujoco/mujoco.h" | grep -m1 'define mjVERSION_HEADER')" >> "$O/build_check.txt"
  ( cmake -S "$W/mujoco-p43$n-src" -B "$W/t43$n" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t43$n" -j"$J" ) > "$O/build_tests_$n.log" 2>&1
  log "build tests $n exit $?"
done
# ---- the pull request's demo scenes, as its author wrote them, and with the stiction flag line removed
for s in ramp gripper; do
  awk -v f="model/stiction/$s.xml" '$0 == "diff --git a/" f " b/" f { p = 1; next } p && /^diff --git/ { exit } p && /^\+/ && !/^\+\+\+/ { print substr($0, 2) }' "$O/pr3349.diff" > "$O/$s.xml"
  grep -v '<flag stiction="enable"/>' "$O/$s.xml" > "$O/${s}_noflag.xml"
done
# ---- the numbers (Study 10's cube and grip)
DTS="0.00114 0.000285"; DIRS="0 22.5 45"; FRS="0.5 0.75 0.95"
CUBE="h0=0 mu=0.39 mass=1.861 radius=0.0434"; LIM=$(awk 'BEGIN { printf "%.6f", 0.39 * 1.861 * 9.8 }')
GRIP="mass=0.202 radius=0.0312 mu=0.772 squeeze=2.48"; GOFF=0.0093
P06=$(awk -v l="$LIM" 'BEGIN { printf "%.6f", 0.6 * l }'); P15=$(awk -v l="$LIM" 'BEGIN { printf "%.6f", 1.5 * l }')
echo "cube $CUBE limit $LIM N; grip $GRIP offset $GOFF; steps $DTS; teleport 2 mm at 0.8 s; shove 1.5 of the limit from 0.7 to 0.75 s, state saved at 0.6 s and restored at 1.2 s" > "$O/parameters.txt"
rigs() {  # <scratch folder> <MuJoCo folder>: the rigs built against that MuJoCo
  mkdir -p "$1" && cp -R "$R/tools" "$1/" && (cd "$1" && for n in mjc_contact mjc_grip mjc_scene; do MUJOCO_DIR=$2 tools/build_rig.sh $n > /dev/null 2>&1 || echo "rig $n failed against $2" >> "$O/progress.txt"; done)
}
holds() {  # <scratch folder> <out folder> <options...>
  local X=$1 D=$2; shift 2
  mkdir -p "$D"; : > "$D/stats.txt"
  for dt in $DTS; do for dir in $DIRS; do for fr in $FRS; do
    p=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
    "$X/tools/mjc_contact" "$D/hold_${dir}_${fr}_$dt.txt" dt=$dt $CUBE push=$p pushat=0.4 secs=1.6 dir=$dir "$@" | sed "s|^STATS|STATS run hold_${dir}_${fr}_$dt|" >> "$D/stats.txt"
  done; done; done
}
# ---- part A: the release
XA="$W/p43rel"; rm -rf "$XA"; rigs "$XA" "$W/mujoco-3.16.0"
for arm in "defaults:" "impratio10:impratio=10" "impratio100:impratio=100" "elliptic:cone=elliptic" \
           "elliptic_impratio10:cone=elliptic impratio=10" "noslip_pyramidal:noslip=10" "configuration:cone=elliptic noslip=10"; do
  name=${arm%%:*}; opts=${arm#*:}
  # shellcheck disable=SC2086
  holds "$XA" "$O/A/$name" $opts
  for off in 0 $GOFF; do for pad in box mesh; do
    # shellcheck disable=SC2086
    "$XA/tools/mjc_grip" "$O/A/$name/grip_${pad}_off$off" dt=0.00114 offset=$off pad=$pad $GRIP $opts | sed "s|^STATS|STATS run grip_${pad}_off$off|" >> "$O/A/$name/stats.txt"
  done; done
  log "part A $name played"
done
rm -rf "$XA"
# ---- part B: the pull request's builds
for arm in "june:june:cone=elliptic" "off:pr:cone=elliptic" "on:pr:cone=elliptic stiction=1" "cfg:pr:cone=elliptic noslip=10"; do
  name=${arm%%:*}; rest=${arm#*:}; build=${rest%%:*}; opts=${rest#*:}
  X="$W/p43$name"; rm -rf "$X"; rigs "$X" "$W/mujoco-p43$build-build"
  D="$O/B/$name"
  # shellcheck disable=SC2086
  holds "$X" "$D" $opts
  for dt in $DTS; do
    # shellcheck disable=SC2086
    "$X/tools/mjc_contact" "$D/teleport_$dt.txt" dt=$dt $CUBE push=$P06 pushat=0.4 secs=1.6 dir=22.5 teleport=0.8,0.002 $opts | sed "s|^STATS|STATS run teleport_$dt|" >> "$D/stats.txt"
    # shellcheck disable=SC2086
    "$X/tools/mjc_contact" "$D/shove_$dt.txt" dt=$dt $CUBE push=$P06 pushat=0.4 secs=1.6 dir=22.5 pulse=$P15,0.7,0.75 $opts | sed "s|^STATS|STATS run shove_$dt|" >> "$D/stats.txt"
    # shellcheck disable=SC2086
    "$X/tools/mjc_contact" "$D/shove_restored_$dt.txt" dt=$dt $CUBE push=$P06 pushat=0.4 secs=1.6 dir=22.5 pulse=$P15,0.7,0.75 restore=0.6,1.2 $opts | sed "s|^STATS|STATS run shove_restored_$dt|" >> "$D/stats.txt"
  done
  for s in ramp gripper; do
    case $s in ramp) ax="0.8660254037844386,0,-0.5"; bd=block ;; gripper) ax="0,0,-1"; bd=box ;; esac
    case $name in on) sc="$O/$s.xml"; so="" ;; cfg) sc="$O/${s}_noflag.xml"; so="noslip=10" ;; *) sc="$O/${s}_noflag.xml"; so="" ;; esac
    # shellcheck disable=SC2086
    "$X/tools/mjc_scene" "$D/demo_$s.txt" scene="$sc" body=$bd axis=$ax secs=6 $so | sed "s|^STATS|STATS run demo_$s|" >> "$D/stats.txt"
  done
  rm -rf "$X"
  log "part B $name played"
done
# ---- MuJoCo's own test suite on both builds, the flag unset
for n in june pr; do
  ( cd "$W/t43$n" && ctest --timeout 900 -j"$J" > "$O/ctest_$n.txt" 2>&1 )
  log "suite $n exit $? $(grep -E 'tests passed|tests failed' "$O/ctest_$n.txt" | tail -1)"
  awk 'match($0, /Test +#[0-9]+: /) { rest = substr($0, RSTART + RLENGTH); st = "unknown"
         if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) { st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st) }
         name = rest; p = index(name, " ...."); if (p > 0) name = substr(name, 1, p - 1); sub(/ +$/, "", name); print name, st }' "$O/ctest_$n.txt" | sort > "$O/suite_results_$n.txt"
done
# ---- measuring: every number from Senua AI's measuring program; file comparisons by cmp
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
{
  for d in "$O"/A/* "$O"/B/*; do
    a=$(basename "$(dirname "$d")")/$(basename "$d")
    for dt in $DTS; do for dir in $DIRS; do for fr in $FRS; do
      echo "$a hold $dir $fr $dt creep_ums $(fld "$("$B" creep "$d/hold_${dir}_${fr}_$dt.txt" | tail -1)" mean_speed_ums)"
    done; done; done
    for g in "$d"/grip_*.txt; do
      [ -f "$g" ] || continue; case $g in *_tilt.txt) continue ;; esac
      echo "$a $(basename "$g" .txt) creep_ums $(fld "$("$B" creep "$g" | tail -1)" mean_speed_ums)"
    done
    for dt in $DTS; do
      [ -f "$d/teleport_$dt.txt" ] || continue
      echo "$a teleport $dt creep_after_ums $(fld "$("$B" creep "$d/teleport_$dt.txt" | tail -1)" mean_speed_ums)"
      ns=$(awk -v t=$dt 'BEGIN { printf "%d", t * 1e9 + 0.5 }')
      g=$("$B" gap $ns "$d/shove_$dt.txt" "$d/shove_restored_$dt.txt" | tail -1)
      e=$("$B" ends "$d/shove_$dt.txt" "$d/shove_restored_$dt.txt" | tail -1)
      echo "$a restore $dt identical $(cmp -s "$d/shove_$dt.txt" "$d/shove_restored_$dt.txt" && echo 1 || echo 0) $g | end $(fld "$e" place_apart_nm) nm $(fld "$e" speed_apart_ums) um/s"
    done
    for s in ramp gripper; do
      [ -f "$d/demo_$s.txt" ] || continue
      echo "$a demo $s creep_ums $(fld "$("$B" creep "$d/demo_$s.txt" | tail -1)" mean_speed_ums) moved_at_end_nm $(tail -1 "$d/demo_$s.txt" | awk '{ print $2 }')"
    done
    m=$(grep -o 'most_iterations [0-9]*' "$d/stats.txt" | awk '{ if ($2 > x) x = $2 } END { print x + 0 }')
    w=$(grep -o 'warnings [0-9]*' "$d/stats.txt" | awk '{ s += $2 } END { print s + 0 }')
    echo "$a solver most_iterations $m warnings $w"
  done
  echo "safe when off: june against off, holds and demos the same $(n=0; s=0; for f in $(cd "$O/B/june" && ls hold_*.txt demo_*.txt); do n=$((n + 1)); cmp -s "$O/B/june/$f" "$O/B/off/$f" && s=$((s + 1)); done; echo "$s of $n")"
  echo "MuJoCo's tests, june against the pull request's head: $(join <(sort "$O/suite_results_june.txt") <(sort "$O/suite_results_pr.txt") | awk '$2 != $3' | wc -l) of $(join <(sort "$O/suite_results_june.txt") <(sort "$O/suite_results_pr.txt") | wc -l) shared tests read differently; tests only on the pull request: $(join -v2 <(sort "$O/suite_results_june.txt") <(sort "$O/suite_results_pr.txt") | wc -l)"
} > "$O/measured.txt"
date -u +%FT%TZ > "$O/finished.txt"
