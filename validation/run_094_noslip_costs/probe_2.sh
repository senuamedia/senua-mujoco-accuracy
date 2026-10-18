#!/usr/bin/env bash
# Run 094, step 2: written after step 1's readings and pushed before its plays. Step 1 put the force on the joint
# without friction and found the equality kept about as well with noslip as without. MuJoCo's issue #2430's second
# model puts it on the joint with the friction: a motor pushing that joint below its friction limit, a free body
# coupled to it by a joint equality, and with noslip "one body staying in place while the other moves", the more so
# the larger the force. Here: body B on a vertical slide joint with joint friction twice its weight, pushed down by its
# weight; body A, 1 kg, on a horizontal slide joint with no friction, coupled by the equality A = B. With the friction
# holding and the equality kept, neither moves. B weighs 10, 100 and 1,000 kg (98, 980 and 9,800 N); played 1 s at
# 1 ms under the implicit integrator, as the issue's models, with noslip off, 1 and 5 iterations. Read by Senua AI's
# corrected measure: `final` on each body's motion, and `gap` between them.
# usage: probe_2.sh <sx_contact, the corrected measure> <work folder>   (repository root, on the cloud machine)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_094_noslip_costs"; mkdir -p "$O/scenes" "$O/p2"; date -u +%FT%TZ > "$O/played_at_2.txt"
X=$(mktemp -d); cp -R "$R/tools" "$X/"
( cd "$X" && MUJOCO_DIR="$W/mujoco-3.16.0" tools/build_rig.sh mjc_scene > /dev/null )
for mb in 10 100 1000; do
  F=$(awk -v m="$mb" 'BEGIN { printf "%g", 2 * m * 9.8 }')
  cat > "$O/scenes/held_m$mb.xml" <<EOF
<mujoco model="held"><option timestep="0.001" integrator="implicit" gravity="0 0 -9.8"/>
<worldbody>
<body name="b" pos="0 0 1"><joint name="B" type="slide" axis="0 0 -1" frictionloss="$F"/><geom type="box" size="0.05 0.05 0.05" mass="$mb" contype="0" conaffinity="0"/></body>
<body name="a" pos="0.5 0 1"><joint name="A" type="slide" axis="1 0 0"/><geom type="box" size="0.05 0.05 0.05" mass="1" contype="0" conaffinity="0"/></body>
</worldbody>
<equality><joint joint1="A" joint2="B" polycoef="0 1 0 0 0"/></equality>
</mujoco>
EOF
done
: > "$O/p2/stats.txt"
{
  echo "with the friction holding and the equality kept, neither body moves"
  for mb in 10 100 1000; do
    for ns in off:"" n1:"noslip=1" n5:"noslip=5"; do
      nn=${ns%%:*}; no=${ns#*:}
      for bd in b:0,0,-1 a:1,0,0; do
        bn=${bd%%:*}; ax=${bd#*:}
        # shellcheck disable=SC2086
        "$X/tools/mjc_scene" "$O/p2/held_m${mb}_${nn}_$bn.txt" scene="$O/scenes/held_m$mb.xml" body=$bn axis=$ax secs=1 $no | sed "s|^STATS|STATS run held_m${mb}_${nn}_$bn|" >> "$O/p2/stats.txt"
      done
      fb=$("$B" final "$O/p2/held_m${mb}_${nn}_b.txt" | tail -1 | awk '{ for (i = 1; i < NF; i++) if ($i == "angle_urad") print $(i + 1) }')
      fa=$("$B" final "$O/p2/held_m${mb}_${nn}_a.txt" | tail -1 | awk '{ for (i = 1; i < NF; i++) if ($i == "angle_urad") print $(i + 1) }')
      echo "B $mb kg noslip $nn | B moved $fb nm, A moved $fa nm | $("$B" gap 1000000 "$O/p2/held_m${mb}_${nn}_b.txt" "$O/p2/held_m${mb}_${nn}_a.txt" | tail -1)"
    done
  done
} > "$O/reading_equality_2.txt"
rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished_2.txt"
