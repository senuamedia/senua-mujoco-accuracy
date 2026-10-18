# Run 032: the written pose and a joint limit

15 October 2026. Not registered: a design probe on Google DeepMind's Linux release of MuJoCo 3.16.0, played on the
second cloud machine (its release and measuring program checked identical, and recorded plays of runs 024 to 027 made
there byte for byte, run 031), by [`probe.sh`](probe.sh), pushed before any play. It finds where to look and decides
nothing.

Run 025 found a contact's softness depending on the pose a scene is written in, because MuJoCo takes it from inverse
weights frozen at `qpos0` (finding F10). A joint limit's softness comes the same way from the joint's own inverse
weight, `dof_invweight0`, also computed once at `qpos0`. Run 029's patch in design changes contacts only. The arm rig
gains `elbowlimit`, the elbow's limits as elbow angles of the arm itself, so the same in every writing; with it unset
the rig plays as before (`identity.txt`: run 025's 24 plays, 24 of 24 byte-identical).

## The scene

The two-link arm of run 025 released at rest with its ball 1 m above the ground (it never reaches it) and its elbow on
its upper limit, which gravity presses it against as the arm swings down: pose E (shoulder 0, elbow 0.6 rad, limits -2
and 0.6) and pose F (0.4 and 1.0, limits -2 and 1.0), 2 s, written in its own pose, straight and folded, at 2 ms and
0.5 ms, under MuJoCo's defaults and with its `diagexact` flag (the exact diagonal, in the current pose, for every
constraint row, limits included). The right answer: the same swing in every writing. Each pair of writings is read by
Senua AI's measure: `ends` (how far apart the ball ends, its height and speed) and `gap` (the largest height difference
over the play). All readings are in [`reading.txt`](reading.txt); the solver never reached its limit (at most 2
iterations a step) and raised no warning.

## The readings

| Configuration | Pose | Step | Straight against native: ends apart, um | Largest apart during the swing, um | Folded against native: ends apart, um | Largest, um |
|---|---|---|---|---|---|---|
| defaults | E | 2 ms | 838 | 839 | 1,240 | 1,240 |
| defaults | E | 0.5 ms | 638 | 640 | 939 | 965 |
| defaults | F | 2 ms | 348 | 1,055 | 139 | 439 |
| defaults | F | 0.5 ms | 416 | 1,180 | 190 | 554 |
| `diagexact` | E, F | both | 0 | 0 | 0 | 0 |

**Under MuJoCo's defaults the same swing ends up to 1.24 mm apart, and moves up to 9 mm/s apart, with only the
written pose changed**: larger than the contacts' 65 um (run 025), since here the limit carries the swing. With
`diagexact` every writing swings to the same nanometre, at both steps, in both poses.

## What it shows, and what it does not

Finding F10 reaches joint limits: a limit's softness, and with it the arm's swing, depends on the pose the scene was
written in, through `dof_invweight0`. MuJoCo's own `diagexact` removes it here (its costs on contacts are run 028's).
Run 029's patch, which takes the bodies' weights in the current pose for contacts only, does not reach limits; a next
version would take `dof_invweight0` in the current pose by the same formula. One arm, two poses, decided by no rule.
