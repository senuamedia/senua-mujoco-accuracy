#!/usr/bin/env bash
# Run 039, design probe (not registered): two questions the record has not asked.
# (a) The weld. Study 8 validated the inverse weight in the current pose, third version
#     (patches/invweight_at_pose_v3.diff, switch MUJOCO_INVWEIGHT_AT_POSE=1), on a connect equality; the patch changes a
#     weld by the same helper, and no rig played one. The arm rig gains tipweld=1: link 2 held where it starts, in place
#     and in orientation, by MuJoCo's weld equality between two sites (one at the ball's centre on link 2, one in the
#     world where the ball's centre starts, turned as link 2 starts); nothing when unset, which step 0 checks against
#     run 038's release plays. Study 8's arm (links 0.29 and 0.27 m, 0.95 and 0.45 kg, ball 0.026 m and 0.17 kg),
#     released at rest with its ball 1 m above the ground and held there by the weld alone, poses (0.15, 0.75) and
#     (0.3, 1.0), 2 s, written native, straight (0, 0) and folded (0, 2.4), at 1.6 ms and 0.4 ms. Arms: the release under
#     MuJoCo's defaults and with its diagexact flag; the patched build, switch unset (off) and set (on). The right answer:
#     the same in every writing.
# (b) The free tumbling body (known issue M10). A new rig, tools/mjc_tumble.c: one free rigid body, principal moments
#     0.0045, 0.0072 and 0.0101 kg m2, set spinning at (2.2, 1.4, -3.1) rad/s along its own axes, no gravity, nothing
#     touching it, 2 s, under each of MuJoCo's integrators (Euler, implicitfast, implicit, RK4) at the record's step
#     ladder, 10 ms over 1, 4, 16 and 64. The right answer, whatever the step: its rotational kinetic energy and the
#     magnitude of its angular momentum stay what they were. Read by Senua AI's new measure, sx_tumble (the energy and
#     |L| from the body-frame angular velocity and the principal moments, exact whole-number arithmetic). Beside them,
#     Euler on the patched build, switch unset and set, and under the elliptic cone with noslip with the switch set,
#     compared byte for byte with the release: with no constraint the patch and the cone have nothing to act on.
# Each arm plays in its own scratch copy, the rigs built against its MuJoCo. Every play is read by Senua AI's measures:
# sx_contact ends (how far apart two writings end: the ball's height, nm, and the larger difference of its speeds, um/s)
# and final (the ball's height and speed at the end); sx_tumble tumble.
# usage: probe.sh <folder holding sx_contact and sx_tumble> <work folder>
#        (repository root, on the cloud machine; the work folder holds mujoco-src and the release in mujoco-3.16.0)
set -u
M="$(cd "${1:?usage: see the header}" && pwd)"; B="$M/sx_contact"; T="$M/sx_tumble"; W="$(cd "${2:?}" && pwd)"
R="$(pwd)"; J=$(nproc); O="$R/validation/run_039_weld_and_tumble"; PF="$R/patches/invweight_at_pose_v3.diff"
mkdir -p "$O"; : > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
# ---- the patched library, from the patch file
rm -rf "$W/mujoco-p39-src" && mkdir -p "$W/mujoco-p39-src" && (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p39-src"
(cd "$W/mujoco-p39-src" && patch -p1 -s < "$PF")
echo "release source $(git -C "$W/mujoco-src" rev-parse HEAD); patch $(sha256sum "$PF" | cut -c1-16)" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p39-src" -B "$W/p39-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$W/mujoco-p39-build" && cmake --build "$W/p39-lib" -j"$J" && cmake --install "$W/p39-lib" ) > "$W/p39-build.log" 2>&1
echo "build lib exit $? $(date -u +%FT%TZ)" >> "$O/progress.txt"
ARM="len1=0.29 len2=0.27 mass1=0.95 mass2=0.45 rb=0.026 mb=0.17 mu=0.72"; FOLD=0,2.4; DTS="0.0016 0.0004"
WELDS="0.15,0.75 0.3,1.0"; LADDER="0.01 0.0025 0.000625 0.00015625"
BODY="i1=0.0045 i2=0.0072 i3=0.0101 w1=2.2 w2=1.4 w3=-3.1 secs=2"
rigs() {  # <scratch folder> <MuJoCo folder>: the rigs built in a scratch copy of the repository
  cp -R "$R/tools" "$1/"
  (cd "$1" && for n in mjc_arm mjc_tumble; do MUJOCO_DIR=$2 tools/build_rig.sh $n > /dev/null; done)
}
# ---- step 0: the arm rig unchanged without the weld, against run 038's release plays (the arm on contact, the swing on
# a limit, the hold by joint friction, the held ball), replayed by the release with the run's own parameters
X=$(mktemp -d); rigs "$X" "$W/mujoco-3.16.0"
(
  cd "$X" || exit 2
  mkdir -p step0; V="$R/validation/run_038_study_08/release/runs"
  POSES="0.65,0.95 1.25,-0.45"; SWINGS="0.15,0.75:-2.1,0.75 0.3,1.0:-2,1.0"; HOLDS="0.15,0.75 0.3,1.0"
  same() { if cmp -s "step0/$1" "$V/$1"; then echo "SAME run_038 $1"; else echo "DIFFERS run_038 $1"; fi; }
  for cfg in defaults recommended; do
    if [ $cfg = recommended ]; then set -- cone=elliptic noslip=10; else set --; fi
    k=0
    for PS in $POSES; do
      k=$((k + 1))
      for scene in rest drop; do
        if [ $scene = rest ]; then SC="h0=0.0006 secs=2"; else SC="h0=0.011 secs=1"; fi
        for dt in $DTS; do for wr in native straight folded; do
          case $wr in native) P0=$PS ;; straight) P0=0,0 ;; folded) P0=$FOLD ;; esac
          g=arm_${cfg}_pose${k}_${scene}_${dt}_$wr.txt
          # shellcheck disable=SC2086
          tools/mjc_arm step0/$g dt=$dt pose=$PS pose0=$P0 $ARM $SC "$@" > /dev/null; same $g
        done; done
      done
    done
  done
  k=0
  for spec in $SWINGS; do
    k=$((k + 1)); PS=${spec%%:*}; L=${spec#*:}
    for dt in $DTS; do for wr in native straight folded; do
      case $wr in native) P0=$PS ;; straight) P0=0,0 ;; folded) P0=$FOLD ;; esac
      # shellcheck disable=SC2086
      tools/mjc_arm step0/swing_pose${k}_${dt}_$wr.txt dt=$dt pose=$PS pose0=$P0 elbowlimit=$L h0=1 secs=2 $ARM > /dev/null
      same swing_pose${k}_${dt}_$wr.txt
    done; done
  done
  for sc in hold connect; do
    k=0
    for PS in $HOLDS; do
      k=$((k + 1))
      if [ $sc = hold ]; then set -- jointfriction=5.5; else set -- tipconnect=1; fi
      for dt in $DTS; do for wr in native straight folded; do
        case $wr in native) P0=$PS ;; straight) P0=0,0 ;; folded) P0=$FOLD ;; esac
        # shellcheck disable=SC2086
        tools/mjc_arm step0/${sc}_pose${k}_${dt}_$wr.txt dt=$dt pose=$PS pose0=$P0 "$@" h0=1 secs=2 $ARM > /dev/null
        same ${sc}_pose${k}_${dt}_$wr.txt
      done; done
    done
  done
) > "$O/identity.txt"
rm -rf "$X"
echo "step 0 $(grep -c '^SAME' "$O/identity.txt") of $(wc -l < "$O/identity.txt") $(date -u +%FT%TZ)" >> "$O/progress.txt"
# ---- the plays, each arm in its own scratch copy
arm() {  # <name> <MuJoCo folder> [switch]
  local name=$1 mj=$2 sw=${3:-} X
  X=$(mktemp -d); rigs "$X" "$mj"
  ( cd "$X" || exit 2
    if [ -n "$sw" ]; then export MUJOCO_INVWEIGHT_AT_POSE=$sw; else unset MUJOCO_INVWEIGHT_AT_POSE; fi
    mkdir -p runs tumble; S=runs/stats.txt; : > $S
    for cfg in defaults diagexact; do
      if [ $cfg = diagexact ]; then
        [ "$name" = release ] || continue
        set -- diagexact=1
      else set --; fi
      k=0
      for PS in $WELDS; do
        k=$((k + 1))
        for dt in $DTS; do for wr in native straight folded; do
          case $wr in native) P0=$PS ;; straight) P0=0,0 ;; folded) P0=$FOLD ;; esac
          f=runs/weld_${cfg}_pose${k}_${dt}_$wr.txt
          # shellcheck disable=SC2086
          tools/mjc_arm $f dt=$dt pose=$PS pose0=$P0 tipweld=1 h0=1 secs=2 $ARM "$@" | sed "s|^STATS|STATS run $(basename $f .txt)|" >> $S
        done; done
      done
    done
    T2=tumble/stats.txt; : > $T2
    if [ "$name" = release ]; then INTEGS="Euler implicitfast implicit RK4"; else INTEGS="Euler"; fi
    for integ in $INTEGS; do for dt in $LADDER; do
      f=tumble/tumble_${integ}_$dt.txt
      # shellcheck disable=SC2086
      tools/mjc_tumble $f dt=$dt integ=$integ $BODY | sed "s|^STATS|STATS run $(basename $f .txt)|" >> $T2
      if [ "$name" = on ]; then
        # shellcheck disable=SC2086
        tools/mjc_tumble tumble/tumble_${integ}_${dt}_elliptic_noslip.txt dt=$dt integ=$integ cone=elliptic noslip=10 $BODY \
          | sed "s|^STATS|STATS run tumble_${integ}_${dt}_elliptic_noslip|" >> $T2
      fi
    done; done )
  rm -rf "$O/$name"; mkdir -p "$O/$name"; cp -R "$X/runs" "$X/tumble" "$O/$name/"; rm -rf "$X"
  echo "arm $name played $(date -u +%FT%TZ)" >> "$O/progress.txt"
}
arm release "$W/mujoco-3.16.0"
arm off "$W/mujoco-p39-build"
arm on "$W/mujoco-p39-build" 1
# ---- the reading
line() { "$@" | tail -1 | sed 's/ dt_ns [0-9]*//'; }
{
  for a in release off on; do for cfg in defaults diagexact; do
    [ -f "$O/$a/runs/weld_${cfg}_pose1_0.0016_native.txt" ] || continue
    for k in 1 2; do for dt in $DTS; do
      d=$O/$a/runs; n=$d/weld_${cfg}_pose${k}_${dt}_native.txt
      for wr in native straight folded; do
        echo "weld $a $cfg pose$k $dt $wr | $(line "$B" final $d/weld_${cfg}_pose${k}_${dt}_$wr.txt)"
      done
      for wr in straight folded; do
        echo "weld $a $cfg pose$k $dt native against $wr | $(line "$B" ends $n $d/weld_${cfg}_pose${k}_${dt}_$wr.txt)"
      done
    done; done
  done; done
  for f in $(cd "$O/release/tumble" && ls tumble_*.txt); do echo "tumble release ${f%.txt} | $(line "$T" tumble "$O/release/tumble/$f")"; done
  for a in off on; do
    for f in $(cd "$O/$a/tumble" && ls tumble_*.txt); do
      g=${f%_elliptic_noslip.txt}; g=${g%.txt}.txt
      if cmp -s "$O/$a/tumble/$f" "$O/release/tumble/$g"; then s=SAME; else s=DIFFERS; fi
      echo "tumble $a ${f%.txt} against release ${g%.txt} | $s"
    done
  done
  for a in release off on; do
    for f in "$O/$a/runs/stats.txt"; do
      echo "solver $a weld most_iterations $(grep -o 'most_iterations [0-9]*' "$f" | awk '{ if ($2 > m) m = $2 } END { print m + 0 }') at_iteration_limit $(grep -o 'at_iteration_limit [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }') warnings $(grep -o 'warnings [0-9]*' "$f" | awk '{ s += $2 } END { print s + 0 }')"
    done
    echo "solver $a tumble warnings $(grep -o 'warnings [0-9]*' "$O/$a/tumble/stats.txt" | awk '{ s += $2 } END { print s + 0 }') local_frame_check_largest $(grep -o 'local_frame_check [^ ]*' "$O/$a/tumble/stats.txt" | awk '{ if ($2 + 0 > m) m = $2 + 0 } END { print m + 0 }')"
  done
} > "$O/reading.txt"
date -u +%FT%TZ > "$O/finished.txt"
