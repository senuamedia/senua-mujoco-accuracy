# Run 071: Study 15, Senua AI's set together

17 October 2026 (00:53 to 01:07 UTC). The fifteenth registered study,
[`PREREGISTRATION_15.md`](../../preregistrations/PREREGISTRATION_15.md), played once on the first cloud machine by
[`play.sh`](play.sh), the runner as registered (sha256 91b60dfb86a18752...). The rule lines are in
[`rules.txt`](rules.txt), the readings in [`measured.txt`](measured.txt), the draw in [`draw.txt`](draw.txt).

A first clone of the record on the cloud machine checked out only part of its files, for a full disk. The runner was
not among them, so nothing played. Space was freed, the clone made again, and the study played once from it.

## Result: 33 of 33 rule lines held

Senua AI's set is the configuration (the elliptic cone, 100 noslip iterations) with three patches in one build: the
inverse weight in the current pose, de Saxce's correction, and the friction solved in the directions that can move.
With every switch set, it held everything this study rules, on fresh numbers, under the default integrator and under
RK4.

| | Released (rel_rec) | The set, default integrator (on_rec) | The set, RK4 (on_rk4) |
|---|---|---|---|
| The 16 resting plays of a fresh arm (4 poses, as written and mirrored, 2 steps) | all 16 creep, 134 to 482 um/s | **all 0** | **all 0** |
| The 8 dropped plays, 3 s, read from 1.5 s | 6 creep, up to 688 um/s, still moving at 3 s | **all 0**, the last motion by 0.638 s | **all 0**, by 0.634 s |
| The arm held by joint friction | 2 or 3 um/s | 2 or 3 | 2 or 3 |
| The 18 holds; the 8 grips | 0; 0 or 1 | 0; 0 or 1 | 0; 0 or 1 |
| A slid cube's lift at 10 ms; at the coarse step | 7,557 um; 274 um | **0; 0** | 0; 0 |
| A free slide along 22.5 degrees against along 0, coarse step | 97,833 against 96,975 um, 796 um off its line, turned 48 mrad | **96,962 along each**, none off its line, none turned | |
| Free slides on fewer than four corners | 1,775 steps | **none** | |
| Coulomb's distance at the fine step, 97,579 um | | 97,472 to 97,493 um, within 1 part in 100 | |
| The first suite | 10 of 10 | **10 of 10** | 8 of 10 (reported, not ruled) |
| MuJoCo's tests | 3,492 passed | every test as with the switches unset, but the two named | |
| The most iterations on a step | 87 | 30, none at the limit, no warning | 30, none at the limit |

With every switch unset, all 131 play files under each option set are byte for byte the release's, and every one of
MuJoCo's 3,492 tests gives the release's result (E1, E2). With every switch set, the only tests that change are
`ForwardTest.DiscreteImplicitRowNoslip` and `SolverTest.ZeroToleranceDisablesTermination`, the two Study 12 named in
advance (M1).

## What it decides

As registered:

- **Issue 1, a held object creeps at a contact: fixed and validated.** A cube held and gripped, an arm resting on a
  contact (set down and dropped) and an arm held by joint friction all hold under Senua AI's set with every switch set,
  under the default integrator and under RK4. The friction solved in the directions that can move moves from
  `patches/in_design/` to `patches/`.
- **The set together: validated** under the default integrator for everything this study rules. Under RK4 that covers
  what R1, R2, J1, H1, G1 and V1 rule.
- **Issues 4 and 5:** de Saxce's fixes hold with the other two patches on (L1, L2, D1 to D3, C1, K1).

Not decided: the stacks (issue 21) and the box that never rests (issue 20); the first suite under RK4; MuJoCo's PGS
solver; condim 4 and 6; anything against a real robot.

## Reported, not ruled

The release under the configuration passes all ten of the first suite's tests on this study's cube, T08 included. In
Study 14, on another cube, it failed T08 (run 065 traced that to the elliptic cone's hop). Under RK4 the set passes 8 of
10.

## Files

The six arms' plays are in `rel_def`, `rel_rec`, `off_def`, `off_rec`, `on_rec` and `on_rk4` (`resting`, `held`,
`cubes`, `suites`). MuJoCo's test output is in `ctest_*.txt`, read into `suite_results_*.txt`. The dry run and the rules
plumbing check are in [`dry/`](dry/).

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 96,962 um | 96,973 um |
| 96,975 um | 96,986 um |
| 97,472 um | 97,600 um |
| 97,493 um | 97,623 um |
| 97,833 um | 97,844 um |

Every rule line of the study whose inputs the correction changes was judged again by `sx_contact rule` with the
corrected readings ([`rejudge.txt`](../audit/measure_correction/rejudge.txt)): no verdict changes.
