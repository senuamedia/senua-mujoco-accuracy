#!/usr/bin/env bash
# Run 105: a design probe, not registered: it finds where to look and decides nothing. Run 104: the elliptic cone with
# impratio 1,000 and every contact's time constant at twice the step held every contact play of the set, free cubes and
# offset stacks too; without noslip, inverse dynamics agreed (1e-11 N) but joint friction fell (20 to 43 mm/s); with
# noslip it held, and inverse dynamics could not agree (9 N). Joint friction has its own reference and impedance in
# MuJoCo, each joint's solreffriction and solimpfriction, and its creep falls in proportion to the time constant (run
# 052). Here every joint's friction is as stiff as MuJoCo allows it: its time constant twice the step (the floor of
# MuJoCo's own guard, refsafe), its impedance 0.9999 (MuJoCo's largest, mjMAXIMP). The arm and scene rigs gain
# jsolref=T,D, jsolimp=I (every joint's, set after the scene is loaded) and fwdinv=1 (MuJoCo's flag); unset, the rigs as
# they were (before/), checked byte for byte. In Senua AI's set (MuJoCo built from UPSTREAM_COMMIT with its six
# validated patch files, every switch set), three configurations: set (the elliptic cone, 100 noslip iterations);
# impnstc (run 104's: and impratio 1,000, every geom's solref twice the step); nons (the elliptic cone, impratio 1,000,
# every geom's solref and every joint's solreffriction twice the step, damping ratio 1, every joint's solimpfriction
# 0.9999, no noslip). Plays: run 104's (free cubes and holds, Study 13's slides, Study 15's arm and grip, run 093's
# stacks, MuJoCo's box), the arm with fwdinv; Study 22's group 14 (a joint equality with joint friction, 7 scenes at
# their own step, 0.957 ms, 1 s; Study 15's arm held by joint friction, 8 N m, with a weld or a connect at its tip, two
# poses, 1.71 ms), read as Study 22 read them: the held body's and the coupled body's travel (`final`), and the
# largest gap between them (`gap`).
# usage: probe.sh <sx_contact, the measure with fastest> <work folder>   (repository root, on the cloud machine; the
#        work folder holds mujoco-src at UPSTREAM_COMMIT)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"; J=$(nproc)
O="$R/validation/run_105_no_noslip"; P="$W/mujoco-p105-build"; mkdir -p "$O"; : > "$O/progress.txt"
date -u +%FT%TZ > "$O/played_at.txt"
log() { echo "$* $(date -u +%FT%TZ)" >> "$O/progress.txt"; }
PS="$R/patches/invweight_at_pose_v3.diff $R/patches/desaxce_elliptic_v4.diff $R/patches/qcqp_reduced_v2.diff $R/patches/boxbox_collinear.diff $R/patches/noslip_roll_kept_after_qcqp.diff $R/patches/noslip_equality.diff"
export MUJOCO_INVWEIGHT_AT_POSE=1 MUJOCO_DESAXCE=1 MUJOCO_QCQP_REDUCED=1 MUJOCO_BOXBOX_COLLINEAR=1 MUJOCO_NOSLIP_ROLL_KEPT=1 MUJOCO_NOSLIP_EQUALITY=1
rm -rf "${W:?}/mujoco-p105-src" "$W/p105-lib" "$P" && mkdir -p "$W/mujoco-p105-src"
(cd "$W/mujoco-src" && git archive HEAD) | tar x -C "$W/mujoco-p105-src"
for p in $PS; do (cd "$W/mujoco-p105-src" && patch -p1 -s < "$p") || log "patch FAILED $p"; done
echo "source $(git -C "$W/mujoco-src" rev-parse HEAD); upstream $(cat "$R/UPSTREAM_COMMIT"); patches $(for p in $PS; do sha256sum "$p" | cut -c1-16; done | tr '\n' ' ')" > "$O/patch_check.txt"
( cmake -S "$W/mujoco-p105-src" -B "$W/p105-lib" -G Ninja -DCMAKE_BUILD_TYPE=Release -DMUJOCO_BUILD_EXAMPLES=OFF \
    -DMUJOCO_BUILD_SIMULATE=OFF -DMUJOCO_BUILD_TESTS=OFF -DMUJOCO_TEST_PYTHON_UTIL=OFF \
    -DCMAKE_INSTALL_PREFIX="$P" && cmake --build "$W/p105-lib" -j"$J" && cmake --install "$W/p105-lib" ) > "$O/build_lib.log" 2>&1
log "build lib exit $?"
X=$(mktemp -d); cp -R "$R/tools" "$X/"; mkdir -p "$X/b" && cp -R "$R/tools" "$X/b/"
for r in mjc_arm mjc_scene; do cp "$O/before/$r.c" "$X/b/tools/$r.c"; done
( cd "$X" && for r in mjc_stack mjc_contact mjc_arm mjc_grip mjc_scene; do MUJOCO_DIR=$P tools/build_rig.sh $r > /dev/null 2>&1 || echo "rig $r FAILED"; done ) >> "$O/progress.txt"
( cd "$X/b" && for r in mjc_arm mjc_scene; do MUJOCO_DIR=$P tools/build_rig.sh $r > /dev/null 2>&1 || echo "rig before $r FAILED"; done ) >> "$O/progress.txt"
log "rigs built"
N="$X/tools"; A15="len1=0.279 len2=0.286 mass1=1.116 mass2=0.436 rb=0.0284 mb=0.199 mu=0.686"
SCN="$R/validation/run_049_desaxce_v4/step2/scene.xml"; SC="$R/validation/run_099_study_22/scenes"
LIM=$(awk 'BEGIN { printf "%.6f", 0.438 * 1.561 * 9.8 }')
mul() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.9g", a * b }'; }
cr() { "$B" creep "$1" < /dev/null | tail -1 | grep -o "mean_speed_ums [-0-9]*"; }
fin() { "$B" final "$1" < /dev/null | tail -1 | awk '{ for (i = 1; i < NF; i++) { if ($i == "angle_urad") a = $(i + 1); if ($i == "speed_urads") s = $(i + 1) } } END { printf "%s %s", a, s }'; }
fld() { awk -v k="$2" '{ for (i = 1; i < NF; i++) if ($i == k) { print $(i + 1); exit } }' <<< "$1"; }
ab() { echo "${1#-}"; }
# ---- the rigs: before and now, the new settings unset, the same bytes
mkdir -p "$X/i"
for k in b n; do
  rg="$X/tools"; [ $k = b ] && rg="$X/b/tools"
  "$rg/mjc_arm" "$X/i/${k}_arm.txt" dt=0.00171 pose=0.555,0.905 pose0=0.555,0.905 $A15 h0=1 secs=1 jointfriction=5.15 cone=elliptic noslip=100 > "$X/i/${k}_arm.stats"
  "$rg/mjc_scene" "$X/i/${k}_scene.txt" scene="$SC/held_1.xml" body=b axis=0,0,-1 secs=1 cone=elliptic noslip=100 > "$X/i/${k}_scene.stats"
done
{ for f in $(cd "$X/i" && ls b_* | sed 's/^b_//'); do cmp -s "$X/i/b_$f" "$X/i/n_$f" && echo "$f: the same bytes" || echo "$f: DIFFERENT"; done; } > "$O/identity.txt"
# the configuration's options at a step: cfgopt <name> <step> <rig: c contact, j joints>
cfgopt() {
  case $1 in
    set) echo "cone=elliptic noslip=100" ;;
    impnstc) echo "cone=elliptic noslip=100 impratio=1000 gsolref=$(mul "$2" 2),1" ;;
    nons) if [ "$3" = j ]; then echo "cone=elliptic impratio=1000 gsolref=$(mul "$2" 2),1 jsolref=$(mul "$2" 2),1 jsolimp=0.9999"; else echo "cone=elliptic impratio=1000 gsolref=$(mul "$2" 2),1"; fi ;;
  esac
}
: > "$O/stats.txt"; mkdir -p "$X/p"
st() { sed "s|^STATS|STATS run $1|" >> "$O/stats.txt"; }
for cn in set impnstc nons; do
  {
    for cube in a:1.572:0.0474:0.61 b:0.819:0.0316:0.734; do
      c=${cube%%:*}; rest=${cube#*:}; ms=${rest%%:*}; rest=${rest#*:}; hs=${rest%%:*}; mu=${rest#*:}
      pu=$(awk -v m="$ms" -v u="$mu" 'BEGIN { printf "%.6f", 0.95 * m * u * 9.8 }')
      for dt in 0.001277 0.00031925; do
        f="$X/p/free_${cn}_${c}_$dt.txt"
        # shellcheck disable=SC2046
        "$N/mjc_contact" "$f" dt=$dt h0=0 mass=$ms radius=$hs mu=$mu push=$pu pushat=0.4 secs=1.6 dir=0 lock=0 fwdinv=1 $(cfgopt $cn $dt c) | st "free_${cn}_${c}_$dt"
        echo "$cn free cube $c 0.95 $dt | $(cr "$f")"
      done
    done
    for dt in 0.00171 0.0004275; do
      for fr in 0.5 0.95; do
        pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }'); f="$X/p/hold_${cn}_${fr}_$dt.txt"
        # shellcheck disable=SC2046
        "$N/mjc_contact" "$f" dt=$dt h0=0 mass=1.561 radius=0.0489 mu=0.438 push=$pu pushat=0.4 secs=1.6 dir=0 lock=1 fwdinv=1 $(cfgopt $cn $dt c) | st "hold_${cn}_${fr}_$dt"
        echo "$cn hold $fr $dt | $(cr "$f")"
      done
    done
    for dt in 0.001 0.00025; do
      for dir in 0 22.5 45; do
        f="$X/p/slide_${cn}_${dir}_$dt.txt"
        # shellcheck disable=SC2046
        "$N/mjc_contact" "$f" dt=$dt h0=0 vx0=1.01 mu=0.39 mass=1.861 radius=0.0434 secs=1.2 dir=$dir lock=0 $(cfgopt $cn $dt c) | st "slide_${cn}_${dir}_$dt"
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
          "$N/mjc_arm" "$f" dt=$dt pose=$pose pose0=$pose $A15 $ho fwdinv=1 $(cfgopt $cn $dt j) | st "arm_${cn}_${hn}${k}_$dt"
          echo "$cn arm $hn $k $dt | $(cr "$f")"
        done
      done
      for pad in box mesh; do
        f="$X/p/grip_${cn}_${pad}_$dt"
        # shellcheck disable=SC2046
        "$N/mjc_grip" "$f" dt=$dt offset=0.0092 pad=$pad mass=0.21 radius=0.0334 mu=0.69 squeeze=2.61 $(cfgopt $cn $dt c) | st "grip_${cn}_${pad}_$dt"
        echo "$cn grip $pad $dt | $(cr "$f.txt")"
      done
    done
    for sh in 0.001 0.005 0.017; do
      q="$X/p/offset_${cn}_$sh"
      # shellcheck disable=SC2046
      "$N/mjc_stack" "$q" dt=0.00114 n=3 shift=$sh secs=6 mass=0.442 radius=0.0424 mu=0.524 $(cfgopt $cn 0.00114 c) | st "offset_${cn}_$sh"
      echo "$cn offset stack $sh 6s | cube 1 tilt $(fin "${q}_1_tilt.txt") | cube 2 tilt $(fin "${q}_2_tilt.txt") | cube 3 tilt $(fin "${q}_3_tilt.txt")"
    done
    q="$X/p/straight10_$cn"
    # shellcheck disable=SC2046
    "$N/mjc_stack" "$q" dt=0.00114 n=10 shift=0 secs=2 mass=0.442 radius=0.0424 mu=0.524 $(cfgopt $cn 0.00114 c) | st "straight10_$cn"
    line="$cn straight stack 10 2s | depth_nm"; for c in $(seq 1 10); do line="$line $(fin "${q}_$c.txt" | cut -d' ' -f1)"; done; echo "$line"
    f="$X/p/box_$cn.txt"
    # shellcheck disable=SC2046
    "$N/mjc_scene" "$f" scene="$SCN" body=box axis=1,0,0 secs=16 key=0 $(cfgopt $cn 0.016 j) | st "box_$cn"
    echo "$cn MuJoCo's box | $("$B" fastest "$f" 160 < /dev/null | tail -1 | grep -o 'fastest_ums [0-9]*')"
    # Study 22's group 14
    for sp in held_1:b:0,0,-1:a:1,0,0 held_2:b:0,0,-1:a:1,0,0 held_3:b:0,0,-1:a:1,0,0 i2430_1:b1:1,0,0:b2:1,0,0 i2430_2:b1:1,0,0:b2:1,0,0 load_1:b:1,0,0:a:0,0,-1 load_2:b:1,0,0:a:0,0,-1; do
      IFS=: read -r sn bh ah bc ac <<< "$sp"
      sdt=$(grep -o 'timestep="[0-9.]*"' "$SC/$sn.xml" | grep -o '[0-9.]*'); sns=$(awk -v d="$sdt" 'BEGIN { printf "%d", d * 1e9 + 0.5 }')
      fh="$X/p/${sn}_${cn}_held.txt"; fc="$X/p/${sn}_${cn}_coupled.txt"
      # shellcheck disable=SC2046
      "$N/mjc_scene" "$fh" scene="$SC/$sn.xml" body=$bh axis=$ah secs=1 fwdinv=1 $(cfgopt $cn $sdt j) | st "${sn}_${cn}_held"
      # shellcheck disable=SC2046
      "$N/mjc_scene" "$fc" scene="$SC/$sn.xml" body=$bc axis=$ac secs=1 $(cfgopt $cn $sdt j) | st "${sn}_${cn}_coupled"
      echo "$cn g14 $sn | held_nm $(ab "$(fld "$("$B" final "$fh" < /dev/null | tail -1)" angle_urad)") coupled_nm $(ab "$(fld "$("$B" final "$fc" < /dev/null | tail -1)" angle_urad)") gap_um $(fld "$("$B" gap "$sns" "$fh" "$fc" < /dev/null | tail -1)" largest_um)"
    done
    k=0
    for pose in 0.555,0.905 1.157,-0.378; do
      k=$((k + 1))
      for eq in tipweld tipconnect; do
        f="$X/p/arm_${cn}_${eq}_$k.txt"
        # shellcheck disable=SC2046,SC2086
        "$N/mjc_arm" "$f" dt=0.00171 pose=$pose pose0=$pose $A15 jointfriction=8 h0=1 secs=2 $eq=1 fwdinv=1 $(cfgopt $cn 0.00171 j) | st "arm_${cn}_${eq}_$k"
        echo "$cn g14 arm $eq $k | $(cr "$f")"
      done
    done
  } >> "$O/reading.txt"
  log "configuration $cn done"
done
rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished.txt"
