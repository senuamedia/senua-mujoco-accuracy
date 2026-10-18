# Run 063: the friction solved in the directions that can move (a probe)

16 October 2026 (12:47 to 12:57 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Readings in
[`measured.txt`](measured.txt).

[Run 062](../run_062_noslip_trace/README.md) traced issue 1's open part to MuJoCo's friction solve: `mju_QCQP2` (and
`mju_QCQP3`, `mju_QCQP`) reject a contact's friction block by an absolute threshold when one friction direction cannot
move, so noslip returns zero friction and puts the old friction back. A patch in design,
[`qcqp_reduced.diff`](../../patches/in_design/qcqp_reduced.diff) (sha256 22f07ccf8abf316e..., switch
`MUJOCO_QCQP_REDUCED=1`, `engine_solver.c` only, 67 lines added and none removed), finds a contact's friction directions
whose entry in A is at most 1e-10 of the block's largest, sets their friction to zero (friction in a direction that
cannot move does nothing to the motion) and solves the other directions with MuJoCo's own solvers in the same ellipsoid;
a contact with no such direction is solved as released. Built from MuJoCo's source at `UPSTREAM_COMMIT`, with its tests.

Arms: **rel**, MuJoCo 3.16.0 as released; **off** and **on**, the patch with its switch unset and set; under Senua AI's
configuration (the elliptic cone, 100 noslip iterations), on Study 10's numbers, at 1.14 and 0.285 ms.

## Safe when off

202 of 202 files byte for byte as released; MuJoCo's own test suite, 3,492 tests, every one reading as in the release's
run (Study 12's `suite_results_release.txt`).

## With the switch set

| | Released | Switch set |
|---|---|---|
| Study 10's arm at rest on its ball, poses 1 and 2, as written and mirrored | 714 and 9 um/s | **0 and 0** |
| Study 13's arm, poses 1 and 2, as written and mirrored | 0 and 192 um/s | **0 and 0** |
| Study 10's arm dropped on its ball, pose 1, the ball's mean speed over its last half second | 582 um/s | **0** |
| The 18 holds, the 8 grips, the slides kept and free, the stacks, the slide on a box's face, the suite, the arm held by joint friction, MuJoCo's box scene | | **byte for byte as released** |
| MuJoCo's own tests | 3,492 passed | **3,492 passed, none reading differently** |
| The most iterations on a step | 18 | 18, none at the limit, no warning |

Every one of the 30 files that change is a play of the three contacts that slid released (Study 10's two poses, Study 13's
second), set down or dropped; the pose that noslip held released (Study 13's first) plays byte for byte as released.

## What it shows

The patch removes the resting arm's slide in every pose played, both ways round, at both steps, and changes nothing else
played, MuJoCo's tests included. A candidate for issue 1's open part, to be registered on fresh numbers.
