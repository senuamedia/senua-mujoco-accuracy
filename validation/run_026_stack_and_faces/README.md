# Run 026: a resting stack and face-to-face boxes

15 October 2026. Not registered: a design probe on Google DeepMind's Linux release of MuJoCo 3.16.0, played on the
cloud machine by [`probe.sh`](probe.sh), pushed before any play. It finds where to look and decides nothing.

Known issues M6 (the soft contact) and M9 (MuJoCo rewrote its box-box collision in 3.12) point at stacks and at boxes
face to face. A new rig, [`tools/mjc_stack.c`](../../tools/mjc_stack.c), plays cubes of 0.5 kg, half-size 0.05 m,
friction 0.5, each free to move and turn, set down touching, and writes each cube's height above what is below it,
speeds and contact forces in the contact rigs' format, and its tilt in the joint rig's format. The scenes:

- **stack**: 3, 5 and 10 cubes set down straight, 2 s. The right answer: each cube carries its own weight, none slides,
  none tilts.
- **offset**: 3 cubes, each 20 mm along x from the one below, so the cubes above every face stand over it, 2 s. The
  right answer is the same.
- **slide**: one cube set sliding at 1.2 m/s on the ground, and on a fixed box (half-size 0.5 m) whose top face is at
  the ground's height, so its one contact is box face on box face, 1 s. The right answer: Coulomb's distance, 146,939
  um, the same on both, no lift, no tilt.

At 2 ms and 0.5 ms, under MuJoCo's defaults and the elliptic cone with 10 noslip iterations (**recommended**, Study 2).
Every play is read by Senua AI's measure (`rest`, `pull`, `stop`, `creep`, `hover`, `ends`, and `final`, the last
step's first two columns: in a contact file the height of a cube's lowest face above what is below it and its speed,
in a tilt file its tilt and angular speed). All readings are in [`reading.txt`](reading.txt); the solver's counts in
[`solver.txt`](solver.txt): at most 14 iterations a step, never the limit, no warning.

## The readings

**A straight stack stands, and every cube carries its weight.** In every stack, at both steps and in both
configurations, the net contact force on each cube is 4,899 to 4,900 mN against its weight of 4,900; none is ever pulled,
none slides (0 um/s), none tilts (0 urad).

**It sinks, and a box on a box sinks twice as deep as a box on the ground.** Under the defaults, at both steps, the
lowest face of each cube rests below the top of what carries it by:

| Contact | Weights it carries | Depth, um |
|---|---|---|
| A cube on the ground | 3, 5, 10 | 51, 85, 165 |
| A cube on a cube | 1, 2, 3, 5, 9 | 34, 68, 101, 165, 278 |

That is 17 um a cube's weight on the ground and 34 um on another cube, up to 5 weights (the contact stiffens slightly
deeper, as MuJoCo's impedance does). MuJoCo sets each contact's softness from the inverse weights of the two bodies it
joins (finding F10, run 025): a cube on the ground has one, a cube on a cube two, and the softness doubles. The ten
contacts of the stack of ten together sink 1.6 mm.

**Under the recommended configuration the stack sinks three to six times deeper.** The same stacks, the elliptic cone with
noslip: one cube on another 207 um, three cubes on the ground 294 um, nine cubes on a cube 901 um; the stack of ten's
contacts together 6.1 mm, nearly four times as much (six times for one cube on another, three for nine). At 2 ms the stack of five had not come to rest: its second contact reads 446 um at the end,
against 564 um at 0.5 ms and in the stack of ten, and the file shows it moving from 563 um at 1.4 s.

**An offset stack leans and keeps moving.** Every cube stands over the one below it, but under the defaults the three
cubes tilt by 408, 1,253 and 1,467 urad and the upper two still creep at 16 and 26 um/s at 2 s, at both steps. Under the
recommended configuration they tilt by 1,980, 6,086 and 5,790 urad and are still turning at 0.12 to 0.15 mrad a second at
2 s. The right answer is no tilt and no creep.

**Face to face, a box slides exactly as on the ground.** Under the defaults the cube sliding on the box face and on the
ground give byte-identical files: 146,106 um at 2 ms (0.57% short of Coulomb's) and 146,946 um at 0.5 ms (0.005% over),
no tilt at the end. It lifts as finding F3 says, 772 um at 2 ms and 373 at 0.5 ms (1,457 and 196 um under the
recommended configuration, whose box and ground files differ in their bytes but read the same).

## What it shows, and what it does not

MuJoCo's box-box collision gives a box sliding on a box what its plane gives a box on the ground, and a straight stack
stands with every cube carrying its weight. What departs from the right answer is the soft contact: a stack sinks in
proportion to its load at each contact, twice as much between two bodies as on the ground and three to six times as much
under the elliptic cone with noslip, and an offset stack leans and creeps where a rigid one would not. A probe on one
cube size and one friction, decided by no rule; this is finding F11.
