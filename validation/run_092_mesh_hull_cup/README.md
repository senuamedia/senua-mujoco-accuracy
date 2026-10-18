# Run 092: a cup collided as its hull, and as its convex parts

17 October 2026 (07:50 UTC). Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh),
pushed before its plays. It finds where to look and decides nothing.

## Why

Issue 15 (known issue M8): MuJoCo collides a mesh as its convex hull, so a shape whose hull differs from it collides as
a shape it is not. Run 027 played only a box-shaped mesh, whose hull is itself. This plays a shape whose hull is not,
with an answer given by geometry.

## What was played

An open-topped cup fixed on the ground (outer 0.1 by 0.1 m, 0.06 m high, walls and floor 0.005 m thick), and a ball of
radius 0.02 m and 0.1 kg dropped from rest with its centre 0.15 m up, over the cup's centre. It falls inside and rests
on the floor, its centre 0.025 m up: 125,000,000 nm below where it started. If the cup were closed it would rest on the
lid, 70,000,000 nm down. The cup three ways ([`scenes/`](scenes/)):

- **one mesh**, its vertices the cup's outer and inner corners, so its hull is the closed box;
- **five box primitives**, the floor and the four walls, MuJoCo's documented way to collide a shape that is not convex;
- **five convex meshes**, each one of those boxes.

Each played on the release for 2 s at a 2 ms step, under MuJoCo's defaults and under Senua AI's configuration. Read by
Senua AI's corrected measure, `final`: the ball's last displacement downward and its last speed
([`reading.txt`](reading.txt)).

## What it found

| The cup | Where the ball rests: displacement down, nm | Speed at the end |
|---|---|---|
| One mesh | 70,366,910: on the lid the hull adds, 0.367 mm into it | 0 |
| Five box primitives | 125,366,909: on the floor, 0.367 mm into it | 0 |
| Five convex meshes | 125,366,909: the same as the primitives | 0 |

The same under the defaults and the configuration; no warning. As one mesh, the ball rests on a lid that is not
there, 55 mm above the cup's floor. Split into convex parts, by primitives or by meshes, it rests on the floor, the
right answer to within the soft contact's own depth, the same in both.

## What it means

Issue 15 is MuJoCo's documented convex-hull collision, and its documented remedy, a shape split into convex parts,
gives the right contact here. A candidate for a registered study on fresh shapes; this probe decides nothing.
