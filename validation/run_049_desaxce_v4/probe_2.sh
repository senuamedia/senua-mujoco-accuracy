#!/usr/bin/env bash
# Run 049, step 2, written after step 1's readings and pushed before its plays. Step 1 left one of MuJoCo's tests that
# the fourth version changes for a reason not yet traced: ForwardTest.DiscreteImplicitRowNoslip, a stiff box sliding to
# rest at 2 m/s under the discrete integrator, with torsional and rolling friction (condim 6), impratio 10 and 2 noslip
# iterations, which with the switch set still moves at 0.078 after 200 steps (the test's bound 0.005). This plays the
# test's own scene, taken from MuJoCo's test file (engine_forward_test.cc) with only a body name added for the rig, from
# its keyframe, for 200 steps, read along x, on the release and on the fourth version with the switch set; and the same
# with condim 3 in place of 6, with no noslip, and under MuJoCo's default integrator, to find which part of the scene
# the shift acts through. The scene rig gains key=N (start from keyframe N), unchanged without it: run 043's two demo
# scenes played with the rig as it was at 936d8e4 and as it is now, compared by cmp.
# usage: probe_2.sh <work folder>   (repository root, on the cloud machine; the work folder holds mujoco-src, the
#        release in mujoco-3.16.0, and run 049's build of the fourth version in mujoco-p49v4-build)
set -u
W="$(cd "${1:?usage: see the header}" && pwd)"; R="$(pwd)"; O="$R/validation/run_049_desaxce_v4/step2"; mkdir -p "$O"
REL="$W/mujoco-3.16.0"; V4="$W/mujoco-p49v4-build"
awk '/TEST_F\(ForwardTest, DiscreteImplicitRowNoslip\)/ { t = 1 } t && /R"\(/ { p = 1; next } p && /\)";/ { exit } p { print }' "$W/mujoco-src/test/engine/engine_forward_test.cc" \
  | sed 's|<body pos="0 0 0.05">|<body name="box" pos="0 0 0.05">|' > "$O/scene.xml"
sed 's|condim="6"|condim="3"|' "$O/scene.xml" > "$O/scene_condim3.xml"
sed 's|noslip_iterations="2"|noslip_iterations="0"|' "$O/scene.xml" > "$O/scene_nonoslip.xml"
sed 's|integrator="discrete" ||' "$O/scene.xml" > "$O/scene_euler.xml"
for b in rel:$REL v4:$V4; do
  n=${b%%:*}; mj=${b#*:}
  X="$W/p49s2$n"; rm -rf "$X"; mkdir -p "$X" && cp -R "$R/tools" "$X/" && (cd "$X" && MUJOCO_DIR=$mj tools/build_rig.sh mjc_scene > /dev/null 2>&1)
done
# the rig unchanged without key: the version at 936d8e4, built against the release, on run 043's demo scenes
Y="$W/p49s2old"; rm -rf "$Y"; mkdir -p "$Y/tools" && git -C "$R" show 936d8e4:tools/mjc_scene.c > "$Y/tools/mjc_scene.c" && cp "$R/tools/build_rig.sh" "$Y/tools/" && (cd "$Y" && MUJOCO_DIR=$REL tools/build_rig.sh mjc_scene > /dev/null 2>&1)
{
  for s in ramp gripper; do
    case $s in ramp) ax="0.8660254037844386,0,-0.5"; bd=block ;; gripper) ax="0,0,-1"; bd=box ;; esac
    "$Y/tools/mjc_scene" "$Y/$s.txt" scene="$R/validation/run_043_fixes_in_the_wild/${s}_noflag.xml" body=$bd axis=$ax secs=6 > /dev/null
    "$W/p49s2rel/tools/mjc_scene" "$W/p49s2rel/$s.txt" scene="$R/validation/run_043_fixes_in_the_wild/${s}_noflag.xml" body=$bd axis=$ax secs=6 > /dev/null
    echo "$s $(cmp -s "$Y/$s.txt" "$W/p49s2rel/$s.txt" && echo same || echo DIFFERS)"
  done
} > "$O/identity.txt"
: > "$O/stats.txt"
for sc in scene scene_condim3 scene_nonoslip scene_euler; do
  for a in rel: v4:1; do
    n=${a%%:*}; sw=${a#*:}
    if [ -n "$sw" ]; then export MUJOCO_DESAXCE=$sw; else unset MUJOCO_DESAXCE; fi
    "$W/p49s2${n%%:*}/tools/mjc_scene" "$O/${sc}_$n.txt" scene="$O/$sc.xml" body=box axis=1,0,0 secs=3.2 key=0 | sed "s|^STATS|STATS run ${sc}_$n|" >> "$O/stats.txt"
    "$W/p49s2${n%%:*}/tools/mjc_scene" "$O/${sc}_${n}_z.txt" scene="$O/$sc.xml" body=box axis=0,0,1 secs=3.2 key=0 > /dev/null
  done
done
unset MUJOCO_DESAXCE
rm -rf "$W"/p49s2rel "$W"/p49s2v4 "$Y"
{
  for sc in scene scene_condim3 scene_nonoslip scene_euler; do for n in rel v4; do
    awk -v s="${sc}_$n" 'NR > 1 { last = $0; if ($1 == 49 || $1 == 99 || $1 == 149) at[$1] = $3 } END { split(last, f, " "); printf "%s along x: moved %d nm; speed at steps 50, 100, 150, 200: %s %s %s %s um/s\n", s, f[2], at[49], at[99], at[149], f[3] }' "$O/${sc}_$n.txt"
    awk -v s="${sc}_$n" 'NR > 1 { last = $0 } END { split(last, f, " "); printf "%s along z: moved %d nm; speed at the end %s um/s\n", s, f[2], f[3] }' "$O/${sc}_${n}_z.txt"
  done; done
} > "$O/measured.txt"
