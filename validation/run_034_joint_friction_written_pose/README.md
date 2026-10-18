# Run 034: the written pose and joint friction

15 October 2026. Not registered: a design probe on Google DeepMind's Linux release of MuJoCo 3.16.0, played on the
cloud machine by [`probe.sh`](probe.sh), pushed before any play. It finds where to look and decides nothing.

A joint's dry friction (MuJoCo's `frictionloss`) is a constraint row whose softness MuJoCo takes from the joint's
inverse weight, `dof_invweight0`, frozen at `qpos0`, as for a joint limit (run 032, finding F10). The arm rig gains
`jointfriction`, MuJoCo's frictionloss on both hinges; with it unset the rig plays as before (`identity.txt`: runs 025's
and 032's 48 plays, 48 of 48 byte-identical).

## The scene

The two-link arm of run 025 released at rest with its ball 1 m above the ground, both hinges given 6 N m of dry
friction, more than gravity's torque on either (at most about 4.6 N m, at the shoulder): pose E (shoulder 0, elbow 0.6
rad) and pose F (0.4 and 1.0), 2 s, written in its own pose, straight and folded, at 2 ms and 0.5 ms, under MuJoCo's
defaults and with `diagexact`. The right answer: it stays where it was put, in every writing. Each play is read by
Senua AI's measure: `creep` (the ball's mean speed along x over the second half), and between writings `ends` and `gap`.
All readings are in [`reading.txt`](reading.txt); the solver never reached its limit (1 iteration a step) and raised no
warning.

## The readings

| Configuration | Pose | The ball creeps at, mm/s: native, straight, folded | Ends apart from native: straight, folded, mm |
|---|---|---|---|
| defaults | E | 39.0, 54.8, 24.1 | 32.2, 24.8 |
| defaults | F | 21.0, 33.9, 24.6 | 16.3, 6.1 |
| `diagexact` | E | 34.6 in all three | 0, 0 |
| `diagexact` | F | 20.8 in all three | 0, 0 |

The same at both steps, within 0.1%.

- **An arm held by friction above its load does not stay.** It creeps at 21 to 55 mm/s at the ball (finding F1 and
  known issue M13, on a jointed arm), where the right answer is 0.
- **How fast depends on the written pose.** Under the defaults the creep spreads from 24 to 55 mm/s in pose E with the
  writing alone, and after 2 s the same arm is 6 to 32 mm from where its other writings put it: the largest effect of
  the written pose this record has found. With `diagexact` every writing creeps and ends exactly alike.

## What it shows, and what it does not

Finding F10 reaches joint friction, through `dof_invweight0`, as it does joint limits. The validated patch (Study 5)
covers contacts only; its second version, which takes `dof_invweight0` in the current pose too, is in design (run 033),
and this scene is the one to hold it to next. Neither touches the creep itself (F1). One arm, two poses, decided by no
rule.
