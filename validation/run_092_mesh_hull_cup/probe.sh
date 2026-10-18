#!/usr/bin/env bash
# Run 092: a design probe, not registered: it finds where to look and decides nothing. Issue 15 (M8): MuJoCo collides a
# mesh as its convex hull. A shape whose hull differs from it then collides as a shape it is not. The case here has a
# right answer by geometry: an open-topped cup (outer 0.1 x 0.1 m, 0.06 m high, walls and floor 0.005 m thick) fixed on
# the ground, and a ball (radius 0.02 m, 0.1 kg) dropped from rest with its centre 0.15 m above the ground over the cup's
# centre. The right answer: it falls inside and rests on the cup's floor, its centre 0.025 m up, 0.125 m below where it
# started. The cup three ways, each scene written here: as one mesh (its vertices the cup's outer and inner corners, so
# its hull is the closed box); as five box primitives (the floor and the four walls, MuJoCo's documented way to collide a
# shape that is not convex, by convex parts); as five convex meshes, each a box. Each scene played on the release, for
# 2 s at a 2 ms step, under MuJoCo's defaults and under Senua AI's configuration (the elliptic cone, 100 noslip
# iterations). Readings by Senua AI's corrected measure: `final` on the scene rig's file, the ball's last displacement
# downward (nm) and its last speed (um/s).
# usage: probe.sh <sx_contact, the corrected measure> <work folder>   (repository root, on the cloud machine; the work
#        folder holds the release in mujoco-3.16.0)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_092_mesh_hull_cup"; mkdir -p "$O/scenes"; date -u +%FT%TZ > "$O/played_at.txt"
# the cup: outer half-widths 0.05, height 0.06; walls and floor 0.005
head='<mujoco model="cup"><option timestep="0.002" gravity="0 0 -9.8"/>'
ground='<geom name="ground" type="plane" size="1 1 0.1"/>'
ball='<body name="ball" pos="0 0 0.15"><freejoint/><geom type="sphere" size="0.02" mass="0.1"/></body>'
# 1. one mesh: the cup's 16 corners (outer box top and bottom, inner floor top and inner rim)
cat > "$O/scenes/cup_one_mesh.xml" <<EOF
$head<asset><mesh name="cup" vertex="-0.05 -0.05 0  0.05 -0.05 0  0.05 0.05 0  -0.05 0.05 0  -0.05 -0.05 0.06  0.05 -0.05 0.06  0.05 0.05 0.06  -0.05 0.05 0.06  -0.045 -0.045 0.005  0.045 -0.045 0.005  0.045 0.045 0.005  -0.045 0.045 0.005  -0.045 -0.045 0.06  0.045 -0.045 0.06  0.045 0.045 0.06  -0.045 0.045 0.06"/></asset>
<worldbody>$ground<geom name="cup" type="mesh" mesh="cup"/>$ball</worldbody></mujoco>
EOF
# 2. five box primitives: the floor, then the walls at x = -0.0475, x = +0.0475, y = -0.0475, y = +0.0475
parts='<geom type="box" pos="0 0 0.0025" size="0.05 0.05 0.0025"/><geom type="box" pos="-0.0475 0 0.0325" size="0.0025 0.05 0.0275"/><geom type="box" pos="0.0475 0 0.0325" size="0.0025 0.05 0.0275"/><geom type="box" pos="0 -0.0475 0.0325" size="0.045 0.0025 0.0275"/><geom type="box" pos="0 0.0475 0.0325" size="0.045 0.0025 0.0275"/>'
cat > "$O/scenes/cup_box_parts.xml" <<EOF
$head<worldbody>$ground$parts$ball</worldbody></mujoco>
EOF
# 3. five convex meshes, each one of those boxes (its 8 corners), placed as the primitives are
mk() {  # <name> <half x> <half y> <half z>: a box mesh about its centre
  local x=$2 y=$3 z=$4
  echo "<mesh name=\"$1\" vertex=\"-$x -$y -$z  $x -$y -$z  $x $y -$z  -$x $y -$z  -$x -$y $z  $x -$y $z  $x $y $z  -$x $y $z\"/>"
}
cat > "$O/scenes/cup_mesh_parts.xml" <<EOF
$head<asset>$(mk floor 0.05 0.05 0.0025)$(mk wallx 0.0025 0.05 0.0275)$(mk wally 0.045 0.0025 0.0275)</asset>
<worldbody>$ground<geom type="mesh" mesh="floor" pos="0 0 0.0025"/><geom type="mesh" mesh="wallx" pos="-0.0475 0 0.0325"/><geom type="mesh" mesh="wallx" pos="0.0475 0 0.0325"/><geom type="mesh" mesh="wally" pos="0 -0.0475 0.0325"/><geom type="mesh" mesh="wally" pos="0 0.0475 0.0325"/>$ball</worldbody></mujoco>
EOF
X=$(mktemp -d); cp -R "$R/tools" "$X/"
( cd "$X" && MUJOCO_DIR="$W/mujoco-3.16.0" tools/build_rig.sh mjc_scene > /dev/null )
mkdir -p "$O/p"; : > "$O/p/stats.txt"
{
  echo "the right answer: inside, the ball's centre 0.025 m up: 125,000,000 nm down from where it started; on the hull's top, 0.08 m up: 70,000,000 nm down"
  for s in cup_one_mesh cup_box_parts cup_mesh_parts; do
    for c in defaults:"" config:"cone=elliptic noslip=100"; do
      cn=${c%%:*}; co=${c#*:}
      f="$O/p/${s}_$cn.txt"
      # shellcheck disable=SC2086
      "$X/tools/mjc_scene" "$f" scene="$O/scenes/$s.xml" body=ball axis=0,0,-1 secs=2 $co | sed "s|^STATS|STATS run ${s}_$cn|" >> "$O/p/stats.txt"
      echo "$s $cn | $("$B" final "$f" | tail -1)"
    done
  done
} > "$O/reading.txt"
rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished.txt"
