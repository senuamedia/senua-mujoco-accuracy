# Run 062: what MuJoCo's noslip computes for the resting arm (a probe)

16 October 2026 (12:37 UTC). Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh), pushed
before its plays. It finds where to look and decides nothing. Readings in [`measured.txt`](measured.txt), the trace
lines in `trace/`.

Runs 056, 059 and 060 found that under the elliptic cone MuJoCo's noslip removes a resting arm's slide in one pose
(Study 13's first) and leaves it in others (Study 10's first, Study 13's second), by pose, at every impratio, and alike
in mirror image. An instrumentation patch, [`noslip_trace.diff`](../../patches/in_design/noslip_trace.diff) (off unless
`MUJOCO_NOSLIP_TRACE` is set, 13 lines added to `engine_solver.c`, none removed), prints what noslip computes for each
elliptic contact at each sweep. Built from MuJoCo's source at `UPSTREAM_COMMIT`. With the switch unset the four plays are
byte for byte as released and print nothing; traced, byte for byte as untraced.

## What noslip computes

At each step noslip runs two sweeps. For the ball's contact, the last step of 0.5 s at 1.14 ms under the configuration:

| Contact | Normal force | Friction before | Friction after the sweep | A's block (the two friction directions) | Noslip holds it? |
|---|---|---|---|---|---|
| Study 10's arm, pose 1 | 11.44 N | (0, -1.250) N | **(0, 0)**, then put back | 1e-10, 3.218 | no |
| Study 13's arm, pose 2 | 4.33 N | (0, -0.478) | **(0, 0)**, then put back | 1e-10, 1.497 | no |
| Study 13's arm, pose 1 | 13.55 N | (0, 1.194) | (0, 1.215) | 1e-10, 3.083 | yes |
| Study 10's cube, held at 0.5 of its limit | 4.56 N | (0, 0.865) | (0, 0.865) | 0.537, 0.537 | yes |

The arm moves in a vertical plane, so the contact's first friction direction, across the plane, cannot move: its entry
in A is 1e-10. Where noslip fails, the friction it should find is inside the cone (for Study 10's arm, (0, -1.275) N
against a cone of radius 0.717 times 11.44 N), yet the sweep returns zero friction; MuJoCo's cost check sees the cost
rise and puts the old friction back, the sweep's improvement is zero, and noslip stops with the contact as the soft
solve left it, creeping.

## The cause, in MuJoCo's source

Noslip solves an elliptic contact's friction with `solveQCQP` (`engine_solver.c`), which for a contact with two friction
directions calls `mju_QCQP2` (`engine_util_solve.c`). It scales the block by the friction coefficients and then checks
that the scaled block is positive definite with an absolute threshold, `det < 1e-10`, returning zero friction if not.
With one direction that cannot move the scaled determinant is 1e-10 times the friction coefficient to the fourth times the
other direction's entry:

| Contact | Scaled determinant | Against 1e-10 |
|---|---|---|
| Study 10's arm, pose 1 | 8.5e-11 | below: zero friction |
| Study 13's arm, pose 2 | 5.5e-11 | below: zero friction |
| Study 13's arm, pose 1 | 1.13e-10 | above: solved |
| Study 10's cube | 6.7e-3 | above: solved |

That is the whole pattern of runs 056 to 061: the pose decides through the other direction's entry; a mirror image has
the same A; impratio does not enter (noslip's A carries no regularisation); the pyramidal cone's noslip does not use this
solve and holds every pose; a cube free in both directions has a well-conditioned block. MuJoCo's dual (PGS) solver
calls the same `solveQCQP`.

## What it shows

Issue 1's open part is traced: noslip under the elliptic cone leaves a contact sliding when one of its friction
directions cannot move and the other's entry is small enough that `mju_QCQP2`'s absolute determinant threshold rejects
the block. A fix is in design: solve such a contact's friction in the directions that can move.
