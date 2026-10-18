#!/usr/bin/env bash
# Run 104: a design probe, not registered: it finds where to look and decides nothing. Run 103: under the elliptic cone,
# impratio 1,000 with no noslip held the free cubes near their limit (2 to 3 um/s, against 613 to 1,098 under the set's
# configuration) and brought every offset stack to rest, but joint friction, which impratio does not reach, crept at 20
# to 43 mm/s. Run 102: a contact time constant of twice the step cut a resting cube's depth from 108 um to 1.4 um. Here
# the two together, with and without noslip, against the set's configuration, in Senua AI's set (MuJoCo built from
# UPSTREAM_COMMIT with its six validated patch files, every switch set). Four configurations: set (the elliptic cone,
# 100 noslip iterations); impns (and impratio 1,000); imptc (the elliptic cone, impratio 1,000, no noslip, every geom's
# solref twice the step, damping ratio 1); impnstc (all three). Plays:
#   Study 20's free cubes a and b (condim 3) pushed along 0 degrees at 0.95 of their limit, at 1.277 and 0.319 ms, and
#   the cube Study 19 held from turning at 0.5 and 0.95 of its limit at 1.71 and 0.4275 ms, each with MuJoCo's fwdinv
#   flag (inverse dynamics against the forward step);
#   Study 13's cube set sliding at 1.01 m/s, free, along 0, 22.5 and 45 degrees, at 1 and 0.25 ms (Coulomb's distance
#   v^2 / (2 mu g) = 133,452 um);
#   Study 15's arm set down, dropped and held in the air by joint friction (5.15 N m), two poses; Study 15's grip with
#   box and mesh pads; at 1.71 and 0.4275 ms;
#   run 093's stacks offset 1, 5 and 17 mm a cube (6 s) and a straight stack of 10 (2 s), of run 078's cube, at 1.14 ms;
#   MuJoCo's box (16 s, its own 16 ms step).
# Readings by Senua AI's measure: `creep`, `stop` (slid_um), `final` (each stacked cube's tilt, height and speeds),
# `fastest` (the box's last 160 steps); the solver's statistics (iterations, warnings, fwdinv, side_um).
# usage: probe.sh <sx_contact, the measure with fastest> <work folder>   (repository root, on the cloud machine; the
#        work folder holds mujoco-src at UPSTREAM_COMMIT)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_104_impratio_and_time_constant"; P="$W/mujoco-p104-build"; mkdir -p "$O"; : > "$O/progress.txt"
date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
PS="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/qcqp_reduced_v2.diff $R/patches/boxbox_collinear.diff $R/patches/noslip_roll_kept_after_qcqp.diff $R/patches/noslip_equality.diff"
export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1 MUJOCO_NOSLIP_EQUALITY=1
rm -rf "${W:?}/mujoco-p104-src" "$W/p104-lib" "$P" && mkdir -p "$W/mujoco-p104-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p104-src"
for p in $PS; do (cd "$W/mujoco-p104-src" && patch -p1 -s < "$p") || log "patch FAILED $p"; done
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in $PS; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p104-src" -B "$W/p104-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$P" && cmake --build "$W/p104-lib" -j"$J" && cmake --install "$W/p104-lib" ) > "$O/build_lib.log" 2>&1
log "build lib exit $?"
X=$(mktemp -d); cp -R "$R/tools" "$X/"
( cd "$X" && for r in mjc_stack mjc_contact mjc_arm mjc_grip mjc_scene; do MUJOCO_DIR=$P tools/build_rig.sh $r > /dev/null 2>&1 || echo "rig $r FAILED"; done ) >> "$O/progress.txt"
log "rigs built"
N="$X/tools"; A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"
LIM=$(awk 'BEGIN { printf "%.6f", 0.438 * 1.561 * 9.8 }')
mul() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.9g", a * b }'; }
cr() { "$B" creep "$1" < /dev/null | tail -1 | grep -o "mean_speed_ums [-0-9]*"; }
fin() { "$B" final "$1" < /dev/null | tail -1 | awk '{ for (i = 1; i < NF; i++) { if ($i == "angle_urad") a = $(i + 1); if ($i == "speed_urads") s = $(i + 1) } } END { printf "%s %s", a, s }'; }
ht() { fin "$1" | cut -d" " -f1; }
# the configuration's options at a step: cfgopt <name> <step>
cfgopt() {
  case $1 in
    set) echo "cone=elliptic noslip=100" ;;
    impns) echo "cone=elliptic noslip=100 impratio=1000" ;;
    imptc) echo "cone=elliptic impratio=1000 gsolref=$(mul "$2" 2),1" ;;
    impnstc) echo "cone=elliptic noslip=100 impratio=1000 gsolref=$(mul "$2" 2),1" ;;
  esac
}
: > "$O/stats.txt"; mkdir -p "$X/p"
st() { sed "s|^STATS|STATS run $1|" >> "$O/stats.txt"; }
for cn in set impns imptc impnstc; do
  {
    for cube in a:1.572:0.0474:0.61 b:0.819:0.0316:0.734; do
      c=${cube%%:*}; rest=${cube#*:}; ms=${rest%%:*}; rest=${rest#*:}; hs=${rest%%:*}; mu=${rest#*:}
      pu=$(awk -v m="$ms" -v u="$mu" 'BEGIN { printf "%.6f", 0.95 * m * u * 9.8 }')
      for dt in 0.001277 0.00031925; do
        f="$X/p/free_${cn}_${c}_$dt.txt"
        # shellcheck disable=SC2046
        "$N/mjc_contact" "$f" dt=$dt h0=0 mass=$ms radius=$hs mu=$mu push=$pu pushat=0.4 secs=1.6 dir=0 lock=0 fwdinv=1 $(cfgopt $cn $dt) | st "free_${cn}_${c}_$dt"
        echo "$cn free cube $c 0.95 $dt | $(cr "$f")"
      done
    done
    for dt in 0.00171 0.0004275; do
      for fr in 0.5 0.95; do
        pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }'); f="$X/p/hold_${cn}_${fr}_$dt.txt"
        # shellcheck disable=SC2046
        "$N/mjc_contact" "$f" dt=$dt h0=0 mass=1.561 radius=0.0489 mu=0.438 push=$pu pushat=0.4 secs=1.6 dir=0 lock=1 fwdinv=1 $(cfgopt $cn $dt) | st "hold_${cn}_${fr}_$dt"
        echo "$cn hold $fr $dt | $(cr "$f")"
      done
    done
    for dt in 0.001 0.00025; do
      for dir in 0 22.5 45; do
        f="$X/p/slide_${cn}_${dir}_$dt.txt"
        # shellcheck disable=SC2046
        "$N/mjc_contact" "$f" dt=$dt h0=0 vx0=1.01 mu=0.39 mass=1.861 radius=0.0434 secs=1.2 dir=$dir lock=0 $(cfgopt $cn $dt) | st "slide_${cn}_${dir}_$dt"
        echo "$cn slide $dir $dt | $("$B" stop "$f" < /dev/null | tail -1 | grep -o 'slid_um [-0-9]*')"
      done
    done
    for dt in 0.00171 0.0004275; do
      k=0
      for pose in 0.555,0.905 1.157,-0.378; do
        k=$((k + 1))
        for hp in rest:"h0=0.00043 secs=2" drop:"h0=0.0129 secs=3" jointfriction:"h0=1 secs=2 jointfriction=5.15"; do
          hn=${hp%%:*}; ho=${hp#*:}; f="$X/p/arm_${cn}_${hn}${k}_$dt.txt"
          # shellcheck disable=SC2046,SC2086
          "$N/mjc_arm" "$f" dt=$dt pose=$pose pose0=$pose $A15 $ho $(cfgopt $cn $dt) | st "arm_${cn}_${hn}${k}_$dt"
          echo "$cn arm $hn $k $dt | $(cr "$f")"
        done
      done
      for pad in box mesh; do
        f="$X/p/grip_${cn}_${pad}_$dt"
        # shellcheck disable=SC2046
        "$N/mjc_grip" "$f" dt=$dt offset=0.0092 pad=$pad mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61 $(cfgopt $cn $dt) | st "grip_${cn}_${pad}_$dt"
        echo "$cn grip $pad $dt | $(cr "$f.txt")"
      done
    done
    for sh in 0.001 0.005 0.017; do
      q="$X/p/offset_${cn}_$sh"
      # shellcheck disable=SC2046
      "$N/mjc_stack" "$q" dt=0.00114 n=3 shift=$sh secs=6 mass=0.442 radius=0.0424 mu=0.524 $(cfgopt $cn 0.00114) | st "offset_${cn}_$sh"
      echo "$cn offset stack $sh 6s | cube 1 tilt $(fin "${q}_1_tilt.txt") | cube 2 tilt $(fin "${q}_2_tilt.txt") | cube 3 tilt $(fin "${q}_3_tilt.txt")"
    done
    q="$X/p/straight10_$cn"
    # shellcheck disable=SC2046
    "$N/mjc_stack" "$q" dt=0.00114 n=10 shift=0 secs=2 mass=0.442 radius=0.0424 mu=0.524 $(cfgopt $cn 0.00114) | st "straight10_$cn"
    line="$cn straight stack 10 2s | height_nm"; for c in $(seq 1 10); do line="$line $(ht "${q}_$c.txt")"; done; echo "$line"
    f="$X/p/box_$cn.txt"
    # shellcheck disable=SC2046
    "$N/mjc_scene" "$f" scene="$SCN" body=box axis=1,0,0 secs=16 key=0 $(cfgopt $cn 0.016) | st "box_$cn"
    echo "$cn MuJoCo's box | $("$B" fastest "$f" 160 < /dev/null | tail -1 | grep -o 'fastest_ums [0-9]*')"
  } >> "$O/reading.txt"
  log "configuration $cn done"
done
rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished.txt"
