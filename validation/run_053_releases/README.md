# Run 053: the record's contact scenes across MuJoCo's releases 3.11.0 to 3.16.0 (a probe)

16 October 2026 (10:42 to 10:43 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Issue 17 of
[the issue list](../../docs/issues.md) (known issue M9): MuJoCo's changelog says its box-box collision was rewritten in
3.12 and its plane-mesh collision in 3.13, and this record is pinned at 3.16.0.

Google DeepMind's Linux releases 3.11.0, 3.12.0, 3.13.0, 3.14.0 and 3.15.0, fetched from MuJoCo's GitHub releases, each
matching the sha256 published beside it, and 3.16.0, the release the record uses ([`releases.txt`](releases.txt)). Every
rig built against each release's own headers and library, without error. On Study 10's numbers, under MuJoCo's defaults
and under Senua AI's configuration, at 1.14 and 0.285 ms: the cube held and slid on the ground (box on plane), stacks, an
offset stack and a cube slid on a box's face (box on box), the grip with box and mesh pads (box and mesh on box), the arm
on contact (sphere on plane), and the first contact suite. Readings in [`measured.txt`](measured.txt).

## What changes from release to release

Each release's files against 3.16.0's, byte for byte:

| Scenes | 3.11.0 | 3.12.0 | 3.13.0, 3.14.0, 3.15.0 |
|---|---|---|---|
| Box on plane: holds, slides kept from turning and free to turn | all the same | all the same | all the same |
| Sphere on plane: the arm on contact | all the same | all the same | all the same |
| The first contact suite | all the same | all the same | all the same |
| Box on box: straight stacks | 10 of 112 the same | all the same | all the same |
| Box on box: the offset stack, the slide on a box's face, the box-pad grip | none the same (48) | all the same | all the same |
| Mesh pads on a box: the grip | 4 of 16 the same | 12 of 16 the same | all the same |

So the two rewrites the changelog names are the only changes in these scenes over six releases: box on box between
3.11 and 3.12, and the mesh pads again between 3.12 and 3.13. From 3.13 to 3.16 every file is byte for byte the same.

## What the changes do to the readings

- **Stacks, under MuJoCo's defaults**: in 3.11 the stack of 9 tilts 1.1 mrad at 0.285 ms and is still moving at 1.25
  mm/s after 2 s, and the stacks tilt 8 to 19 urad elsewhere; from 3.12 every straight stack stands, untilted and still.
- **Stacks, under the configuration**: in 3.11 the stack of 9 tilts 12.8 mrad at 1.14 ms and moves at 19.8 mm/s, where
  from 3.12 it stands; at 0.285 ms the stacks tilt in every release (finding F14), by up to 6.0 mrad in 3.11 and 2.5 in
  3.16.
- **The grips under MuJoCo's defaults** creep 3% to 10% faster in 3.11 than in 3.16 (box pads 6,252 to 6,778 against
  6,054 to 6,398 um/s; mesh pads, off centre, 8,792 to 8,851 against 8,073 to 8,083), and the mesh pads off centre 2% to 3%
  slower in 3.12 than in 3.16. Under the configuration every grip holds, in every release (0 or 1 um/s).
- **The slide on a box's face** goes 10 to 185 um differently in 3.11 (130,658 to 131,513 against 130,714 to 131,467
  um).
- **The offset stack** leans 2.1 to 2.2 mrad in 3.11 against 1.9 in 3.16 under the defaults, and 6.2 to 10.4 against
  9.4 to 9.7 under the configuration.
- The solver: at most 18 iterations a step in 3.11 under the configuration, against 9 from 3.12; never at the limit, no
  warning.

## What it shows

The collision changes MuJoCo's changelog names are real, change these scenes' results, and are the only changes the
record's contact scenes see from 3.11 to 3.16. 3.12's box-box rewrite made straight stacks stand under MuJoCo's
defaults. Holds, slides and the ten known-answer tests on the ground play byte for byte alike in all six releases. A
user upgrading from 3.11 or 3.12 to 3.16 would see box-on-box and mesh scenes change, and nothing else here.

## Not asked here

Releases before 3.11; scenes the record does not play (cylinders, capsules, convex meshes other than a box, height
fields); actuators and tendons (issue 16).
