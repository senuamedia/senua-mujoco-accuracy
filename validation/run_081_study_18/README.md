# Run 081: Study 18, MuJoCo's RK4 integrator, for a free body's energy

17 October 2026 (03:05 UTC). The eighteenth registered study,
[`PREREGISTRATION_18.md`](../../preregistrations/PREREGISTRATION_18.md), played once on the first cloud machine by
[`play.sh`](play.sh), the runner as registered (sha256 cbb464cf872771d2...), from an archive of the registration's commit
(e996143). The rule lines are in [`rules.txt`](rules.txt), the readings in [`measured.txt`](measured.txt), the draw in
[`draw.txt`](draw.txt).

## Result: 7 of 7 rule lines held

The largest drift over 2 s, in parts per million, at the drawn 6.25 ms step and a quarter, a sixteenth and a
sixty-fourth of it:

| | 6.25 ms | 1.5625 ms | 0.390625 ms | 0.0977 ms |
|---|---|---|---|---|
| The free chain's energy: Euler (MuJoCo's default), implicitfast | 65,518 | 16,547 | 4,106 | 1,024 |
| The same: implicit | 68,947 | 16,463 | 4,101 | 1,026 |
| **The same: RK4** | **1** | **1** | **1** | **1** |
| The free chain's angular momentum: Euler | 44,185 | 10,861 | 2,683 | 669 |
| **The same: RK4** | **1** | **1** | **1** | **1** |
| The tumbling body's energy: Euler | 9,625 | 2,379 | 593 | 148 |
| **The same: RK4** | **0** | **0** | **0** | **0** |
| The tumbling body's angular momentum: Euler | 3,869 | 957 | 238 | 59 |
| **The same: RK4** | **0** | **0** | **0** | **0** |

RK4 kept the free chain's energy and angular momentum to 1 ppm, the rounding of the rig's files, and the tumbling
body's exactly, at every step (R1 to R4). Euler, implicitfast and implicit drift in proportion to the step, a
first-order error (Q1, Q2). MuJoCo raised no warning (V1).

Reported, not ruled: the swinging chain, under gravity, departs from its total energy by 1,702 ppm under RK4 at 6.25 ms
and by 1 to 3 ppm at the finer steps. Under the other three it departs by 1.3% to 48% (12,748 to 483,111 ppm).

## What it decides

As registered: **issue 11, the integrators do not keep a free body's energy, is fixed and validated by configuration.**
MuJoCo's own RK4 keeps a free body's energy and angular momentum, a free chain and a tumbling body, at every step
played. MuJoCo's default integrator, implicitfast and implicit do not.

Not decided: a body under gravity or in contact; RK4 with Senua AI's set beyond what Study 15 ruled; the costs of RK4 the
record has seen, which stay as recorded; anything against a real robot.
