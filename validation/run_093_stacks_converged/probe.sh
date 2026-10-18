#!/usr/bin/env bash
# Run 093: a design probe, not registered: it finds where to look and decides nothing. Issue 9 (F11): run 089 found the
# offset stacks in Senua AI's set still turning at 2 s under the configuration (noslip 100, MuJoCo's tolerance), and
# coming to rest with noslip held to convergence (1,000 iterations, tolerance 1e-15): 23 and 0 urad/s. This asks what a
# registered study would need: whether held to convergence the stacks come to rest and stay so over longer plays, and
# what the converged setting does to the set's other plays.
# Part A: offset stacks of 3 cubes, each 1, 5 and 17 mm over from the one below, of run 078's cube (0.442 kg, half-size
# 0.0424 m, friction 0.524) and of Study 16's (0.596 kg, 0.0405 m, 0.528), at 1.14 and 0.285 ms, played 2, 4 and 6 s,
# in Senua AI's set (Study 20's build of its five validated patch files, every switch set), under the elliptic cone with
# noslip 100 at MuJoCo's tolerance, with noslip 1,000 at 1e-15, and with no noslip. Read: each cube's tilt and its speed
# of turning at the last step (Senua AI's corrected measure, `final`, on the stack rig's tilt files).
# Part B: in the set, the plays Study 15 and Study 19 held, played with noslip 100 at MuJoCo's tolerance and with noslip
# 1,000 at 1e-15: Study 15's arm set down and dropped in its two poses, the cube Study 19 held (1.561 kg, half-size
# 0.0489 m, friction 0.438), held from turning at 0.5 and 0.95 of its limit, and Study 15's grip, at 1.71 and 0.4275
# ms; Study 19's box 1 and MuJoCo's box with 100 noslip iterations, and with 1,000 at 1e-15. Read: `creep` (mean speed
# over the second half) and, for the boxes, the fastest of the last 160 steps. The readings and the statistics are kept;
# the per-step play files, a few hundred MB, are not.
# usage: probe.sh <sx_contact, the corrected measure> <work folder>   (repository root, on the cloud machine; the work
#        folder holds Study 20's build in mujoco-s20v1-build)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_093_stacks_converged"; SET="$W/mujoco-s20v1-build"; date -u +%FT%TZ > "$O/played_at.txt"
export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1
X=$(mktemp -d); cp -R "$R/tools" "$X/"
( cd "$X" && for r in mjc_stack mjc_contact mjc_grip mjc_arm mjc_scene; do MUJOCO_DIR=$SET tools/build_rig.sh $r > /dev/null; done )
mkdir -p "$X/a" "$X/b"; : > "$X/a/stats.txt"; : > "$X/b/stats.txt"
NS="n100:cone=elliptic noslip=100|n1000:cone=elliptic noslip=1000 noslip_tolerance=1e-15|none:cone=elliptic"
fin() { "$B" final "$1" | tail -1 | awk '{ for (i = 1; i < NF; i++) { if ($i == "angle_urad") a = $(i + 1); if ($i == "speed_urads") s = $(i + 1) } } END { printf "tilt_urad %s turn_urad_s %s", a, s }'; }
# ---- part A
{
  for cube in k078:"mass=0.442 radius=0.0424 mu=0.524" k016:"mass=0.596 radius=0.0405 mu=0.528"; do
    cn=${cube%%:*}; cv=${cube#*:}
    echo "$NS" | tr '|' '\n' | while IFS= read -r ns; do
      nn=${ns%%:*}; no=${ns#*:}
      for dt in 0.00114 0.000285; do for sh in 0.001 0.005 0.017; do for secs in 2 4 6; do
        q=a/${cn}_${nn}_${sh}_${dt}_${secs}s
        # shellcheck disable=SC2086
        "$X/tools/mjc_stack" "$X/$q" dt=$dt n=3 shift=$sh secs=$secs $cv $no | sed "s|^STATS|STATS run $q|" >> "$X/a/stats.txt"
        echo "$cn $nn shift $sh $dt ${secs}s | cube 1 $(fin "$X/${q}_1_tilt.txt") | cube 2 $(fin "$X/${q}_2_tilt.txt") | cube 3 $(fin "$X/${q}_3_tilt.txt")"
      done; done; done
    done
  done
} > "$O/reading_stacks.txt"
# ---- part B
A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"
CUBE="mass=1.561 radius=0.0489 mu=0.438"; LIM=$(awk 'BEGIN { printf "%.6f", 0.438 * 1.561 * 9.8 }')
GRIP="mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61"
cr() { "$B" creep "$1" | tail -1 | awk '{ for (i = 1; i < NF; i++) if ($i == "mean_speed_ums") print $(i + 1) }'; }
last160() { awk 'NR > 1 { s[NR] = $0; m = NR } END { if (m < 161) { printf "fastest_ums missing"; exit } x0 = 0; for (i = m - 159; i <= m; i++) { split(s[i], f, " "); x = f[3] < 0 ? -f[3] : f[3]; if (x > x0) x0 = x } printf "fastest_ums %d", x0 }' "$1"; }
{
  for ns in "n100:cone=elliptic noslip=100" "n1000:cone=elliptic noslip=1000 noslip_tolerance=1e-15"; do
    nn=${ns%%:*}; no=${ns#*:}
    for dt in 0.00171 0.0004275; do
      k=0
      for pose in 0.555,0.905 1.157,-0.378; do
        k=$((k + 1))
        # shellcheck disable=SC2086
        "$X/tools/mjc_arm" "$X/b/arm_rest${k}_${nn}_$dt.txt" dt=$dt pose=$pose pose0=$pose $A15 h0=0.00043 secs=2 $no | sed "s|^STATS|STATS run arm_rest${k}_${nn}_$dt|" >> "$X/b/stats.txt"
        # shellcheck disable=SC2086
        "$X/tools/mjc_arm" "$X/b/arm_drop${k}_${nn}_$dt.txt" dt=$dt pose=$pose pose0=$pose $A15 h0=0.0129 secs=3 $no | sed "s|^STATS|STATS run arm_drop${k}_${nn}_$dt|" >> "$X/b/stats.txt"
        echo "$nn arm pose $k $dt | rest creep_ums $(cr "$X/b/arm_rest${k}_${nn}_$dt.txt") | drop creep_ums $(cr "$X/b/arm_drop${k}_${nn}_$dt.txt")"
      done
      for fr in 0.5 0.95; do
        pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
        # shellcheck disable=SC2086
        "$X/tools/mjc_contact" "$X/b/hold_${fr}_${nn}_$dt.txt" dt=$dt h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=0 lock=1 $no | sed "s|^STATS|STATS run hold_${fr}_${nn}_$dt|" >> "$X/b/stats.txt"
        echo "$nn hold $fr $dt | creep_ums $(cr "$X/b/hold_${fr}_${nn}_$dt.txt")"
      done
      for pad in box mesh; do
        # shellcheck disable=SC2086
        "$X/tools/mjc_grip" "$X/b/grip_${pad}_${nn}_$dt" dt=$dt offset=0.0092 pad=$pad $GRIP $no | sed "s|^STATS|STATS run grip_${pad}_${nn}_$dt|" >> "$X/b/stats.txt"
        echo "$nn grip $pad $dt | creep_ums $(cr "$X/b/grip_${pad}_${nn}_$dt.txt")"
      done
    done
  done
  for ns in "n100:noslip=100" "n1000:noslip=1000 noslip_tolerance=1e-15"; do
    nn=${ns%%:*}; no=${ns#*:}
    for sc in "$R/validation/run_049_desaxce_v4/step2/scene.xml" "$R/validation/run_085_study_19/scenes/box1_0.016.xml"; do
      b=$(basename "$(dirname "$sc")")_$(basename "$sc" .xml)
      # shellcheck disable=SC2086
      "$X/tools/mjc_scene" "$X/b/box_${b}_$nn.txt" scene="$sc" body=box axis=1,0,0 secs=16 key=0 $no | sed "s|^STATS|STATS run box_${b}_$nn|" >> "$X/b/stats.txt"
      echo "$nn box $b | $(last160 "$X/b/box_${b}_$nn.txt")"
    done
  done
} > "$O/reading_set.txt"
grep -h -o "at_iteration_limit [0-9]*\|warnings [0-9]*" "$X/a/stats.txt" "$X/b/stats.txt" | sort | uniq -c > "$O/solver.txt"
mkdir -p "$O/a" "$O/b"; cp "$X/a/stats.txt" "$O/a/"; cp "$X/b/stats.txt" "$O/b/"
rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished.txt"
