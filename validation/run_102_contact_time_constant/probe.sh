#!/usr/bin/env bash
# Run 102: a design probe, not registered: it finds where to look and decides nothing. Issue 9: a stack sinks at every
# contact, as deep as the softness the model authors (run 089): MuJoCo's soft contact has a time constant (solref,
# 0.02 s by default) and sinks under a load by a depth that grows with it. MuJoCo's own guard (refsafe) lets a contact be
# as stiff as a time constant of twice the step. The rigs gain gsolref=T,D: every geom's solref, set after the scene is
# loaded, as a model's own geom solref sets it (unset = the scene's own, checked here byte for byte against the rigs as
# they were, before/). Played in Senua AI's set (MuJoCo built from UPSTREAM_COMMIT with its six validated patch files,
# every switch set), under the configuration (the elliptic cone, 100 noslip iterations):
# Part A, the depth: a cube (1 kg, half-size 0.05 m, friction 0.5) set down at rest for 2 s, at 1.14 and 0.285 ms, with
#   the time constant at MuJoCo's default and at 8, 4 and 2 times the step (damping ratio 1), under the configuration
#   and under MuJoCo's defaults. Read by Senua AI's measure, `final`: the lowest face's height at the end.
# Part B, the stacks: straight stacks of 3, 5 and 10 of run 078's cube (0.442 kg, half-size 0.0424 m, friction 0.524),
#   2 s, and run 093's offset stacks (1, 5 and 17 mm a cube, 6 s), at 1.14 and 0.285 ms, with the default time constant
#   and at twice the step. Read: `final` on each cube's file and tilt file.
# Part C, the set's other plays at twice the step: Study 15's arm set down and dropped in two poses, the cube Study 19
#   held at 0.5 and 0.95 of its limit, Study 15's grip with box and mesh pads, at 1.71 and 0.4275 ms; MuJoCo's box and
#   Study 19's box 1. Read: `creep`; the boxes `fastest` over their last 160 steps; the solver's statistics.
# Part D, issue 1's free cube (Study 20's cube b, condim 3, pushed along 0 degrees at 0.95 of its limit), at 1.277 and
#   0.319 ms, with the default time constant and at twice the step. Read: `creep`.
# usage: probe.sh <sx_contact, the measure with fastest> <work folder>   (repository root, on the cloud machine; the
#        work folder holds mujoco-src at UPSTREAM_COMMIT)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_102_contact_time_constant"; P="$W/mujoco-p102-build"; mkdir -p "$O"; : > "$O/progress.txt"
date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
PS="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/qcqp_reduced_v2.diff $R/patches/boxbox_collinear.diff $R/patches/noslip_roll_kept_after_qcqp.diff $R/patches/noslip_equality.diff"
export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1 MUJOCO_NOSLIP_EQUALITY=1
rm -rf "${W:?}/mujoco-p102-src" "$W/p102-lib" "$P" && mkdir -p "$W/mujoco-p102-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p102-src"
for p in $PS; do (cd "$W/mujoco-p102-src" && patch -p1 -s < "$p") || log "patch FAILED $p"; done
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in $PS; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p102-src" -B "$W/p102-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$P" && cmake --build "$W/p102-lib" -j"$J" && cmake --install "$W/p102-lib" ) > "$O/build_lib.log" 2>&1
log "build lib exit $?"
X=$(mktemp -d); cp -R "$R/tools" "$X/"; mkdir -p "$X/b" && cp -R "$R/tools" "$X/b/"
for r in mjc_stack mjc_contact mjc_arm mjc_grip mjc_scene; do cp "$O/before/$r.c" "$X/b/tools/$r.c"; done
( cd "$X" && for r in mjc_stack mjc_contact mjc_arm mjc_grip mjc_scene; do MUJOCO_DIR=$P tools/build_rig.sh $r > /dev/null 2>&1 || echo "rig $r FAILED"; done ) >> "$O/progress.txt"
( cd "$X/b" && for r in mjc_stack mjc_contact mjc_arm mjc_grip mjc_scene; do MUJOCO_DIR=$P tools/build_rig.sh $r > /dev/null 2>&1 || echo "rig before $r FAILED"; done ) >> "$O/progress.txt"
log "rigs built"
REC="cone=elliptic noslip=100"; N="$X/tools"
A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"
mul() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.9g", a * b }'; }
fin() { "$B" final "$1" < /dev/null | tail -1 | awk '{ for (i = 1; i < NF; i++) { if ($i == "angle_urad") a = $(i + 1); if ($i == "speed_urads") s = $(i + 1) } } END { printf "%s %s", a, s }'; }
cr() { "$B" creep "$1" < /dev/null | tail -1 | grep -o "mean_speed_ums [-0-9]*"; }
# ---- the rigs: before and now, gsolref unset, the same bytes
mkdir -p "$X/i"
for k in b n; do
  rg="$X/tools"; [ $k = b ] && rg="$X/b/tools"
  "$rg/mjc_stack" "$X/i/${k}_stack" dt=0.00114 n=3 secs=1 mass=0.442 radius=0.0424 mu=0.524 $REC > "$X/i/${k}_stack.stats"
  "$rg/mjc_contact" "$X/i/${k}_contact.txt" dt=0.00114 h0=0 mass=1 radius=0.05 mu=0.5 secs=1 $REC > "$X/i/${k}_contact.stats"
  "$rg/mjc_arm" "$X/i/${k}_arm.txt" dt=0.00171 pose=0.555,0.905 pose0=0.555,0.905 $A15 h0=0.00043 secs=1 $REC > "$X/i/${k}_arm.stats"
  "$rg/mjc_grip" "$X/i/${k}_grip" dt=0.00171 offset=0.0092 pad=box mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61 $REC > "$X/i/${k}_grip.stats"
  "$rg/mjc_scene" "$X/i/${k}_scene.txt" scene="$SCN" body=box axis=1,0,0 secs=4 key=0 noslip=100 > "$X/i/${k}_scene.stats"
done
{ for f in $(cd "$X/i" && ls b_* | sed 's/^b_//'); do cmp -s "$X/i/b_$f" "$X/i/n_$f" && echo "$f: the same bytes" || echo "$f: DIFFERENT"; done; } > "$O/identity.txt"
# ---- part A
mkdir -p "$X/a"; : > "$O/stats.txt"
{
  for cfg in config:"$REC" defaults:""; do
    cn=${cfg%%:*}; co=${cfg#*:}
    for dt in 0.00114 0.000285; do
      for tk in default:0 8:8 4:4 2:2; do
        tn=${tk%%:*}; tm=${tk#*:}; gs=""; [ "$tm" != 0 ] && gs="gsolref=$(mul "$dt" "$tm"),1"
        f="$X/a/cube_${cn}_${dt}_$tn.txt"
        # shellcheck disable=SC2086
        "$N/mjc_contact" "$f" dt=$dt h0=0 mass=1 radius=0.05 mu=0.5 secs=2 $co $gs | sed "s|^STATS|STATS run cube_${cn}_${dt}_$tn|" >> "$O/stats.txt"
        echo "cube $cn $dt time constant $tn ($gs) | height_nm speed_ums $(fin "$f")"
      done
    done
  done
} > "$O/reading_depth.txt"
log "part A done"
# ---- part B
mkdir -p "$X/s"
{
  for dt in 0.00114 0.000285; do
    for tk in default:0 2:2; do
      tn=${tk%%:*}; tm=${tk#*:}; gs=""; [ "$tm" != 0 ] && gs="gsolref=$(mul "$dt" "$tm"),1"
      for nn in 3 5 10; do
        q="$X/s/straight${nn}_${dt}_$tn"
        # shellcheck disable=SC2086
        "$N/mjc_stack" "$q" dt=$dt n=$nn shift=0 secs=2 mass=0.442 radius=0.0424 mu=0.524 $REC $gs | sed "s|^STATS|STATS run straight${nn}_${dt}_$tn|" >> "$O/stats.txt"
        line="straight $nn $dt time constant $tn |"
        for c in $(seq 1 $nn); do line="$line cube $c $(fin "${q}_$c.txt") tilt $(fin "${q}_${c}_tilt.txt") |"; done
        echo "$line"
      done
      for sh in 0.001 0.005 0.017; do
        q="$X/s/offset${sh}_${dt}_$tn"
        # shellcheck disable=SC2086
        "$N/mjc_stack" "$q" dt=$dt n=3 shift=$sh secs=6 mass=0.442 radius=0.0424 mu=0.524 $REC $gs | sed "s|^STATS|STATS run offset${sh}_${dt}_$tn|" >> "$O/stats.txt"
        echo "offset $sh $dt time constant $tn | cube 1 tilt $(fin "${q}_1_tilt.txt") | cube 2 tilt $(fin "${q}_2_tilt.txt") | cube 3 tilt $(fin "${q}_3_tilt.txt")"
      done
    done
  done
} > "$O/reading_stacks.txt"
log "part B done"
# ---- part C
mkdir -p "$X/c"
LIM=$(awk 'BEGIN { printf "%.6f", 0.438 * 1.561 * 9.8 }')
{
  for dt in 0.00171 0.0004275; do
    for tk in default:0 2:2; do
      tn=${tk%%:*}; tm=${tk#*:}; gs=""; [ "$tm" != 0 ] && gs="gsolref=$(mul "$dt" "$tm"),1"
      k=0
      for pose in 0.555,0.905 1.157,-0.378; do
        k=$((k + 1))
        for hp in rest:0.00043:2 drop:0.0129:3; do
          hn=${hp%%:*}; rest=${hp#*:}; h=${rest%%:*}; secs=${rest#*:}; f="$X/c/arm_${hn}${k}_${dt}_$tn.txt"
          # shellcheck disable=SC2086
          "$N/mjc_arm" "$f" dt=$dt pose=$pose pose0=$pose $A15 h0=$h secs=$secs $REC $gs | sed "s|^STATS|STATS run arm_${hn}${k}_${dt}_$tn|" >> "$O/stats.txt"
          echo "arm $hn $k $dt time constant $tn | $(cr "$f")"
        done
      done
      for fr in 0.5 0.95; do
        pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }'); f="$X/c/hold_${fr}_${dt}_$tn.txt"
        # shellcheck disable=SC2086
        "$N/mjc_contact" "$f" dt=$dt h0=0 mass=1.561 radius=0.0489 mu=0.438 push=$pu pushat=0.4 secs=1.6 dir=0 lock=1 $REC $gs | sed "s|^STATS|STATS run hold_${fr}_${dt}_$tn|" >> "$O/stats.txt"
        echo "hold $fr $dt time constant $tn | $(cr "$f")"
      done
      for pad in box mesh; do
        f="$X/c/grip_${pad}_${dt}_$tn"
        # shellcheck disable=SC2086
        "$N/mjc_grip" "$f" dt=$dt offset=0.0092 pad=$pad mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61 $REC $gs | sed "s|^STATS|STATS run grip_${pad}_${dt}_$tn|" >> "$O/stats.txt"
        echo "grip $pad $dt time constant $tn | $(cr "$f.txt")"
      done
    done
  done
  for sc in "$SCN" "$R/validation/run_085_study_19/scenes/box1_0.016.xml"; do
    bn=$(basename "$(dirname "$sc")")_$(basename "$sc" .xml)
    for tk in default:0 2:2; do
      tn=${tk%%:*}; tm=${tk#*:}; gs=""; [ "$tm" != 0 ] && gs="gsolref=0.032,1"
      f="$X/c/box_${bn}_$tn.txt"
      # shellcheck disable=SC2086
      "$N/mjc_scene" "$f" scene="$sc" body=box axis=1,0,0 secs=16 key=0 noslip=100 $gs | sed "s|^STATS|STATS run box_${bn}_$tn|" >> "$O/stats.txt"
      echo "box $bn time constant $tn | $("$B" fastest "$f" 160 < /dev/null | tail -1 | grep -o 'fastest_ums [0-9]*')"
    done
  done
} > "$O/reading_set.txt"
log "part C done"
# ---- part D
mkdir -p "$X/d"
PU=$(awk 'BEGIN { printf "%.6f", 0.95 * 0.819 * 0.734 * 9.8 }')
{
  for dt in 0.001277 0.00031925; do
    for tk in default:0 2:2; do
      tn=${tk%%:*}; tm=${tk#*:}; gs=""; [ "$tm" != 0 ] && gs="gsolref=$(mul "$dt" "$tm"),1"
      f="$X/d/free_${dt}_$tn.txt"
      # shellcheck disable=SC2086
      "$N/mjc_contact" "$f" dt=$dt h0=0 mass=0.819 radius=0.0316 mu=0.734 push=$PU pushat=0.4 secs=1.6 dir=0 lock=0 $REC $gs | sed "s|^STATS|STATS run free_${dt}_$tn|" >> "$O/stats.txt"
      echo "free cube b $dt time constant $tn | $(cr "$f")"
    done
  done
} > "$O/reading_free.txt"
log "part D done"
rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished.txt"
