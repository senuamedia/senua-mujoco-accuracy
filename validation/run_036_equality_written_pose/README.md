# Run 036: the written pose and an equality constraint

15 October 2026. Not registered: a design probe on Google DeepMind's Linux release of MuJoCo 3.16.0, played on the
cloud machine by [`probe.sh`](probe.sh), pushed before any play. It finds where to look and decides nothing.

MuJoCo takes a `connect` or `weld` equality's softness from its bodies' inverse weights, `body_invweight0`, frozen at
`qpos0`, as it does a contact's (finding F10). The validated patch (Study 5) takes them in the current pose only for
contacts, and its second version adds joint limits and joint friction; neither changes equalities. The arm rig gains
`tipconnect`: the ball's centre held by MuJoCo's `connect` equality to the point in the world where it starts, both
given as sites, so the scene is the same in every writing. With it unset the rig plays as before (`identity.txt`: runs
025's and 032's 48 plays, 48 of 48 byte-identical).

## The scene

The two-link arm of run 025, its ball 1 m above the ground and held there by the equality, released at rest so that
gravity pulls the arm against the equality alone: pose E (shoulder 0, elbow 0.6 rad) and pose F (0.4 and 1.0), 2 s,
written in its own pose, straight and folded, at 2 ms and 0.5 ms, under MuJoCo's defaults and with `diagexact`. The right
answer: the same in every writing. Read by Senua AI's measure between writings: `ends` (how far apart the ball ends)
and `gap`. All readings are in [`reading.txt`](reading.txt); the solver never reached its limit (1 iteration a step)
and raised no warning.

## The readings

| Configuration | Pose | Ends apart from native: straight, folded, um (both steps) |
|---|---|---|
| defaults | E | 52.6, 4.3 |
| defaults | F | 100.7, 33.9 |
| `diagexact` | E, F | 0, 0 |

The equality is soft, so the held ball sags under the arm's weight, and by how much depends on the written pose: in pose
F, 310 um written in its own pose, 209 um written straight and 276 um written folded (the files' last lines, 2 ms). With
`diagexact` every writing ends to the same nanometre, at both steps.

## What it shows, and what it does not

Finding F10 reaches equality constraints too, through `body_invweight0`: every kind of constraint this record has played,
contacts, joint limits, joint friction and a `connect`, takes a softness that depends on the pose the scene was written
in, and MuJoCo's `diagexact` removes it in every one. A version of the patch that takes the equality's body weights in
the current pose would use the same helper as its contacts; it is not designed here. One arm, two poses, decided by no
rule.
