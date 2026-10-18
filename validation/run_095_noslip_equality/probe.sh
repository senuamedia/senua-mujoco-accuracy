#!/usr/bin/env bash
# Run 095: a design probe, not registered: it finds where to look and decides nothing. Issue 14 (M3), the joint
# equality noslip breaks (MuJoCo's issue #2430, reproduced in run 094). Noslip re-solves the friction rows only and keeps
# every other force as the main solver left it. The patch patches/in_design/noslip_equality.diff (off unless
# MUJOCO_NOSLIP_EQUALITY=1) also re-solves the equality rows in noslip's pass, each as MuJoCo's PGS solves it, with its
# own regularization, given the friction the pass sets; with no equality rows nothing changes. Built here from MuJoCo's
# source at UPSTREAM_COMMIT with Senua AI's five validated patch files and this one (p95), with its tests.
# Part A, the equality scenes: run 094's (step 1's coupled bodies at 0.5, 9 and 20 N; step 2's held bodies of 10, 100
#   and 1,000 kg) and one after #2430's second model (two 1 kg bodies on slide joints along x, the first with joint
#   friction 100,000 N pushed by 30,000 N, a constant force in place of its motor's control; the second coupled to it
#   by a joint equality), with noslip off, 1, 5 and 100, the five switches set (set5) and the six (set6). Read by Senua
#   AI's corrected measure: `final` on each body's motion, `gap` between the two bodies.
# Part B, an arm held by an equality with joint friction: Study 15's arm in two poses, its tip held where it starts by
#   a weld (tipweld) or a connect (tipconnect), joint friction 5.15 N m on both hinges, in the air, at 1.71 ms, under the
#   configuration (the elliptic cone, 100 noslip iterations) and with no noslip, set5 and set6. Read: `final` and
#   `creep` on the ball, `gap` between set5 and set6.
# Part C, the set unchanged: the set's plays with no equality (Study 15's arm set down and dropped, the cube Study 19
#   held, Study 15's grip, MuJoCo's box and Study 19's box 1, run 093's offset stacks at 1 and 17 mm) in Study 21's build
#   (mujoco-s21v2-build) with the five switches, and in p95 with set5 and set6: compared byte for byte, play files and
#   solver statistics.
# Part D, MuJoCo's own test suite on p95: every switch unset, set5 and set6.
# usage: probe.sh <sx_contact, the corrected measure> <work folder>   (repository root, on the cloud machine; the work
#        folder holds mujoco-src at UPSTREAM_COMMIT and Study 21's build in mujoco-s21v2-build)
#        DRY=1: the plumbing only, into dry/: no build (Study 21's build stands in for p95, so set6 is set5 there), no
#        suite
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_095_noslip_equality"; V="$W/mujoco-s21v2-build"; P95="$W/mujoco-p95-build"
if [ "${DRY:-0}" = 1 ]; then O="$O/dry"; P95="$V"; fi
mkdir -p "$O"; : > "$O/progress.txt"; date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
PS="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/qcqp_reduced_v2.diff $R/patches/boxbox_collinear.diff $R/patches/noslip_roll_kept_after_qcqp.diff $R/patches/in_design/noslip_equality.diff"
switches() {  # <0, 5 or 6>
  unset MUJOCO_INVWEIGHT_AT_POSE MUJOCO_DESAXCE MUJOCO_QCQP_REDUCED MUJOCO_BOXBOX_COLLINEAR MUJOCO_NOSLIP_ROLL_KEPT MUJOCO_NOSLIP_EQUALITY
  if [ "$1" -ge 5 ]; then export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1; fi
  if [ "$1" -ge 6 ]; then export MUJOCO_NOSLIP_EQUALITY=1; fi
}
switches 0
if [ "${DRY:-0}" != 1 ]; then
  rm -rf "${W:?}/mujoco-p95-src" "$W/p95-lib" "$P95" "$W/t95" && mkdir -p "$W/mujoco-p95-src"
  (cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p95-src"
  for p in $PS; do (cd "$W/mujoco-p95-src" && patch -p1 -s < "$p") || log "patch FAILED $p"; done
  echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in $PS; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" > "$O/patch_check.txt"
  ( cmake -S "$W/mujoco-p95-src" -B "$W/p95-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
      -DCMAKE_INSTALL_PREFIX="$P95" && cmake --build "$W/p95-lib" -j"$J" && cmake --install "$W/p95-lib" ) > "$O/build_lib.log" 2>&1
  log "build lib exit $?"
fi
X=$(mktemp -d)
for a in v:$V p:$P95; do
  n=${a%%:*}; mj=${a#*:}; mkdir -p "$X/$n" && cp -R "$R/tools" "$X/$n/"
  ( cd "$X/$n" && for r in mjc_scene mjc_arm mjc_contact mjc_grip mjc_stack; do MUJOCO_DIR=$mj tools/build_rig.sh $r > /dev/null 2>&1 || echo "rig $r FAILED"; done ) >> "$O/progress.txt"
done
log "rigs built"
fin() { "$B" final "$1" | tail -1 | awk '{ for (i = 1; i < NF; i++) { if ($i == "angle_urad") a = $(i + 1); if ($i == "speed_urads") s = $(i + 1) } } END { printf "at %s nm, speed %s um/s", a, s }'; }
gp() { "$B" gap "$1" "$2" "$3" | tail -1 | grep -o "largest_um [-0-9]*"; }
cr() { "$B" creep "$1" | tail -1 | grep -o "mean_speed_ums [-0-9]*"; }
# ---- part A
mkdir -p "$O/scenes" "$O/a"; : > "$O/a/stats.txt"
cat > "$O/scenes/issue2430_2.xml" <<'EOF'
<mujoco model="after issue 2430's second model"><option timestep="0.001" integrator="implicit"/>
<worldbody>
<body name="b1" pos="0 0 0"><joint name="j1" type="slide" axis="1 0 0" frictionloss="100000"/><geom type="box" size="0.05 0.05 0.05" mass="1" contype="0" conaffinity="0"/></body>
<body name="b2" pos="0 0.5 0"><joint name="j2" type="slide" axis="1 0 0"/><geom type="box" size="0.05 0.05 0.05" mass="1" contype="0" conaffinity="0"/></body>
</worldbody>
<equality><joint joint1="j1" joint2="j2" polycoef="0 1 0 0 0"/></equality>
<actuator><general joint="j1" gainprm="0" biastype="affine" biasprm="-30000 0 0"/></actuator>
</mujoco>
EOF
S94="$R/validation/run_094_noslip_costs/scenes"
EQ="coupled_F0.5:$S94/coupled_F0.5.xml:a:0,0,-1:b:1,0,0:2000000
coupled_F9:$S94/coupled_F9.xml:a:0,0,-1:b:1,0,0:2000000
coupled_F20:$S94/coupled_F20.xml:a:0,0,-1:b:1,0,0:2000000
held_m10:$S94/held_m10.xml:b:0,0,-1:a:1,0,0:1000000
held_m100:$S94/held_m100.xml:b:0,0,-1:a:1,0,0:1000000
held_m1000:$S94/held_m1000.xml:b:0,0,-1:a:1,0,0:1000000
issue2430_2:$O/scenes/issue2430_2.xml:b1:1,0,0:b2:1,0,0:1000000"
{
  echo "$EQ" | while IFS=: read -r sn sp b1 a1 b2 a2 base; do
    for sw in 5 6; do
      switches $sw
      for ns in off:"" n1:"noslip=1" n5:"noslip=5" n100:"noslip=100"; do
        nn=${ns%%:*}; no=${ns#*:}; q="$O/a/${sn}_set${sw}_$nn"
        # shellcheck disable=SC2086
        "$X/p/tools/mjc_scene" "${q}_$b1.txt" scene="$sp" body=$b1 axis=$a1 secs=1 $no < /dev/null | sed "s|^STATS|STATS run ${sn}_set${sw}_${nn}_$b1|" >> "$O/a/stats.txt"
        # shellcheck disable=SC2086
        "$X/p/tools/mjc_scene" "${q}_$b2.txt" scene="$sp" body=$b2 axis=$a2 secs=1 $no < /dev/null | sed "s|^STATS|STATS run ${sn}_set${sw}_${nn}_$b2|" >> "$O/a/stats.txt"
        echo "$sn set$sw noslip $nn | $b1 $(fin "${q}_$b1.txt") | $b2 $(fin "${q}_$b2.txt") | between them $(gp "$base" "${q}_$b1.txt" "${q}_$b2.txt")"
      done
    done
  done
} > "$O/reading_equality.txt"
switches 0
log "part A done"
# ---- part B
mkdir -p "$O/b"; : > "$O/b/stats.txt"
A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"
{
  for eq in tipweld tipconnect; do
    for ns in "n100:cone=elliptic noslip=100" "none:cone=elliptic"; do
      nn=${ns%%:*}; no=${ns#*:}
      for kp in 1:0.555,0.905 2:1.157,-0.378; do
        k=${kp%%:*}; pose=${kp#*:}
        for sw in 5 6; do
          switches $sw; q="$O/b/${eq}_pose${k}_${nn}_set$sw"
          # shellcheck disable=SC2086
          "$X/p/tools/mjc_arm" "$q.txt" dt=0.00171 pose=$pose pose0=$pose $A15 jointfriction=5.15 h0=1 secs=2 $eq=1 $no | sed "s|^STATS|STATS run ${eq}_pose${k}_${nn}_set$sw|" >> "$O/b/stats.txt"
          echo "$eq pose $k noslip $nn set$sw | ball $(fin "$q.txt") | $(cr "$q.txt")"
        done
        echo "$eq pose $k noslip $nn | set5 against set6 $(gp 1710000 "$O/b/${eq}_pose${k}_${nn}_set5.txt" "$O/b/${eq}_pose${k}_${nn}_set6.txt")"
      done
    done
  done
} > "$O/reading_arm.txt"
switches 0
log "part B done"
# ---- part C
CUBE="mass=1.561 radius=0.0489 mu=0.438"; LIM=$(awk 'BEGIN { printf "%.6f", 0.438 * 1.561 * 9.8 }')
GRIP="mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61"; NO="cone=elliptic noslip=100"
for arm in v:5 p5:5 p6:6; do
  an=${arm%%:*}; sw=${arm#*:}; rg="$X/p/tools"; if [ "$an" = v ]; then rg="$X/v/tools"; fi
  C="$X/c_$an"; mkdir -p "$C"; : > "$X/c_$an.stats"; switches $sw
  k=0
  for pose in 0.555,0.905 1.157,-0.378; do
    k=$((k + 1))
    # shellcheck disable=SC2086
    "$rg/mjc_arm" "$C/arm_rest$k.txt" dt=0.00171 pose=$pose pose0=$pose $A15 h0=0.00043 secs=2 $NO | sed "s|^STATS|STATS run arm_rest$k|" >> "$X/c_$an.stats"
    # shellcheck disable=SC2086
    "$rg/mjc_arm" "$C/arm_drop$k.txt" dt=0.00171 pose=$pose pose0=$pose $A15 h0=0.0129 secs=3 $NO | sed "s|^STATS|STATS run arm_drop$k|" >> "$X/c_$an.stats"
  done
  for fr in 0.5 0.95; do
    pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
    # shellcheck disable=SC2086
    "$rg/mjc_contact" "$C/hold_$fr.txt" dt=0.00171 h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 dir=0 lock=1 $NO | sed "s|^STATS|STATS run hold_$fr|" >> "$X/c_$an.stats"
  done
  for pad in box mesh; do
    # shellcheck disable=SC2086
    "$rg/mjc_grip" "$C/grip_$pad" dt=0.00171 offset=0.0092 pad=$pad $GRIP $NO | sed "s|^STATS|STATS run grip_$pad|" >> "$X/c_$an.stats"
  done
  for sc in "$R/validation/run_049_desaxce_v4/step2/scene.xml" "$R/validation/run_085_study_19/scenes/box1_0.016.xml"; do
    bn=$(basename "$(dirname "$sc")")_$(basename "$sc" .xml)
    "$rg/mjc_scene" "$C/box_$bn.txt" scene="$sc" body=box axis=1,0,0 secs=16 key=0 noslip=100 | sed "s|^STATS|STATS run box_$bn|" >> "$X/c_$an.stats"
  done
  for sh in 0.001 0.017; do
    # shellcheck disable=SC2086
    "$rg/mjc_stack" "$C/stack_$sh" dt=0.00114 n=3 shift=$sh secs=2 mass=0.442 radius=0.0424 mu=0.524 $NO | sed "s|^STATS|STATS run stack_$sh|" >> "$X/c_$an.stats"
  done
done
switches 0
{
  nf=0; same5=0; same6=0
  for f in $(cd "$X/c_v" && find . -type f | sort); do
    nf=$((nf + 1))
    if cmp -s "$X/c_v/$f" "$X/c_p5/$f"; then same5=$((same5 + 1)); else echo "differs, Study 21's build against p95 set5: $f"; fi
    if cmp -s "$X/c_v/$f" "$X/c_p6/$f"; then same6=$((same6 + 1)); else echo "differs, Study 21's build against p95 set6: $f"; fi
  done
  echo "play files $nf: the same bytes in p95 set5 $same5, in p95 set6 $same6"
  cmp -s "$X/c_v.stats" "$X/c_p5.stats" && echo "solver statistics, p95 set5: the same bytes" || echo "solver statistics, p95 set5: DIFFERENT"
  cmp -s "$X/c_v.stats" "$X/c_p6.stats" && echo "solver statistics, p95 set6: the same bytes" || echo "solver statistics, p95 set6: DIFFERENT"
  echo "plays at the iteration limit or with a warning, Study 21's build: $(grep -c 'at_iteration_limit [1-9]\|warnings [1-9]' "$X/c_v.stats")"
} > "$O/identity.txt"
cp "$X/c_v.stats" "$O/identity_stats.txt"
log "part C done"
rm -rf "${X:?}"
# ---- part D
if [ "${DRY:-0}" != 1 ]; then
  ( cmake -S "$W/mujoco-p95-src" -B "$W/t95" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
      -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=ON -DMUJOCO_TEST_PYTHON_UTIL=OFF && cmake --build "$W/t95" -j"$J" ) > "$O/build_tests.log" 2>&1
  log "build tests exit $?"
  suite() {  # <label> <0, 5 or 6>: every test, the two memory-heavy texture tests alone
    ( cd "$W/t95" && switches "$2"
      ctest --timeout 900 -j"$J" -E LargeTexture > "$O/ctest_$1.txt" 2>&1; ctest --timeout 900 -j1 -R LargeTexture > "$O/ctest_$1_large.txt" 2>&1 )
    log "suite $1 $(grep -E 'tests passed|tests failed' "$O/ctest_$1.txt" | tail -1); large $(grep -E 'tests passed|tests failed' "$O/ctest_$1_large.txt" | tail -1)"
  }
  suite off 0; suite set5 5; suite set6 6
  for a in off set5 set6; do
    cat "$O/ctest_$a.txt" "$O/ctest_${a}_large.txt" | awk 'match($0, /Test +#[0-9]+: /) {
           hdr = substr($0, RSTART, RLENGTH); num = hdr; gsub(/[^0-9]/, "", num); rest = substr($0, RSTART + RLENGTH)
           st = "unknown"
           if (match(rest, /(Passed|\*\*\*Failed|\*\*\*Skipped|\*\*\*Not Run|\*\*\*Timeout|\*\*\*Exception) +[0-9.]+ sec$/)) {
             st = substr(rest, RSTART, RLENGTH); sub(/ +[0-9.]+ sec$/, "", st); sub(/^\*\*\*/, "", st); gsub(/ /, "_", st) }
           name = rest; p = index(name, "  # GetParam()"); if (p > 0) name = substr(name, 1, p - 1)
           p = index(name, " ..."); if (p > 0) name = substr(name, 1, p - 1); sub(/ +$/, "", name)
           print num, name, st }' | sort -n > "$O/suite_results_$a.txt"
  done
  diff "$O/suite_results_set5.txt" "$O/suite_results_set6.txt" > "$O/suite_set5_against_set6.txt"
  for f in "$O"/ctest_*.txt "$O"/build_*.log; do gzip -n "$f"; done
fi
date -u +%FT%TZ > "$O/finished.txt"
