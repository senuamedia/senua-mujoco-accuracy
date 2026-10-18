# Run 027: a two-pad grip, with box pads and mesh pads

15 October 2026. Not registered: a design probe on Google DeepMind's Linux release of MuJoCo 3.16.0, played on the
cloud machine by [`probe.sh`](probe.sh), pushed before any play. It finds where to look and decides nothing.

Users report that MuJoCo collides meshes as their convex hulls and that mesh fingers grip badly (known issue M8), and
that nothing holds at rest (M1, finding F1). A new rig, [`tools/mjc_grip.c`](../../tools/mjc_grip.c), holds a cube of
0.2 kg, half-size 0.03 m, between two pads (half-sizes 0.01 x 0.02 x 0.02 m, 0.1 kg each, each on a slide joint along x),
each pressed toward it with 2.45 N, friction 0.8, and nothing else under it: friction can hold 3.92 N, twice the
cube's weight. The rig writes the cube's height, its speed down and the forces on it in the contact rigs' format, so it
reads as a hold, and the angle it has turned through in the joint rig's format.

- **pads**: a MuJoCo box; a mesh of the same eight corners (which MuJoCo collides with its general convex collider);
  and that mesh with MuJoCo's `multiccd` flag, which asks that collider for several contact points.
- **offset**: the pads grip at the cube's centre, and 10 mm along y from it, where gravity turns the cube about the
  squeeze unless the pads' faces resist it. A rigid flat face would: the friction over the two faces, half of it
  carrying the weight, can resist more than twice gravity's 0.02 N m of turn.

The right answer: the cube does not slip and does not turn, and a box pad and a mesh pad of the same shape hold it
alike. 2 s, at 2 ms and 0.5 ms, under MuJoCo's defaults and the elliptic cone with 10 noslip iterations (**recommended**,
Study 2). Every play is read by Senua AI's measure: `creep` (the cube's mean speed down over the second half, and the
friction against the squeeze), `rest` (the squeeze), `final` on the turn file (the angle turned through, and the
angular speed at the end), `ends` between the box and the mesh pads. All readings are in [`reading.txt`](reading.txt);
the solver never reached its limit (at most 7 iterations a step) and raised no warning ([`solver.txt`](solver.txt)).

## The readings

| Configuration | Pads | Grip | Slips down at, um/s | Turned through, urad | Still turning at, urad/s |
|---|---|---|---|---|---|
| defaults | box, mesh, mesh with multiccd | at the centre | 6,069 | 0 | 0 |
| defaults | box | 10 mm off | 5,969 to 5,978 | 217,275 to 217,996 | 101,583 to 102,241 |
| defaults | mesh, with or without multiccd | 10 mm off | 8,135 to 8,141 | 200,826 to 201,583 | 83,849 to 83,998 |
| recommended | box | at the centre, 10 mm off | 1 | 33 to 44 | 17 to 22 |
| recommended | mesh, with or without multiccd | at the centre, 10 mm off | 0 | 40 to 99 | 20 to 51 |

The ranges are the two steps, which agree within 1% wherever the numbers are large.

- **Under the defaults a gripped cube slides out of the grip.** Squeezed with friction for twice its weight, it slips
  down at 6.1 mm/s at both steps, with the friction on it at 0.40 of the squeeze, half its limit: finding F1, the
  creep at rest, now on a grip.
- **Gripped off its centre, it also turns,** by 0.22 rad (12 degrees) in 2 s and still turning at 0.1 rad/s, with box
  pads as with mesh pads, where a rigid face could resist more than twice the torque.
- **A mesh pad grips like a box pad at the centre, not off it.** At the centre the box and both mesh pads give the
  same play (0 apart at the end). Off the centre the mesh pad lets the cube slip 36% faster and turn 8% less, and the
  two end 2.4 mm apart in height. MuJoCo's `multiccd` flag changes nothing here: the mesh plays are the same with it
  and without it. On this box-shaped pad, the reported weakness of mesh fingers is the soft friction every pad has,
  with a smaller difference of its own.
- **The recommended configuration holds the grip**, box and mesh alike: the cube slips at most 1 um/s and turns 33 to
  99 urad in 2 s, the box and mesh plays within 0.8 um of each other. It still turns, slowly (17 to 51 urad/s at the end),
  where the right answer is 0.

## What it shows, and what it does not

On a grip, as on the ground, MuJoCo's defaults hold nothing at rest, and the creep also turns a cube gripped off its
centre. A pad written as a box-shaped mesh grips as the box does at the centre and somewhat worse off it; MuJoCo's own
elliptic cone with noslip holds both. This probe uses a convex, box-shaped mesh only: a mesh whose hull differs from its
shape (a curved or grooved finger) is not played, and the grip is held still, never lifted. It decides nothing; it
extends finding F1 to a grip, and measures known issue M8 on a box-shaped mesh.
