# Run 066: the de Saxce patch and the friction solved in the directions that can move, together (a probe)

17 October 2026 (23:59 UTC on 16 October to 00:14). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Readings in
[`measured.txt`](measured.txt).

Study 14 held 13 of 15 rule lines. The friction solved in the directions that can move
([`qcqp_reduced.diff`](../../patches/in_design/qcqp_reduced.diff), `MUJOCO_QCQP_REDUCED=1`) held every resting arm at 0.
It failed on a dropped arm still sliding from its landing in the window read, and on T08, which fails under the
configuration released and patched alike. Run 065 traced T08 to the elliptic cone's hop, which the de Saxce patch
removes. This probe builds both patches into one MuJoCo, from its source at `UPSTREAM_COMMIT`:
[`desaxce_elliptic_v4.diff`](../../patches/desaxce_elliptic_v4.diff) (`engine_forward.c`, validated by Study 12) and
the friction solve (`engine_solver.c`). Both apply cleanly (`patch_check.txt`). Five arms, all under Senua AI's
configuration (the elliptic cone, 100 noslip iterations):

- **rel**: MuJoCo 3.16.0 as released.
- **off**: the build with both switches unset.
- **q**: `MUJOCO_QCQP_REDUCED=1` only.
- **d**: `MUJOCO_DESAXCE=1` only.
- **dq**: both switches set.

The scenes are run 063's, on Study 10's numbers at 1.14 and 0.285 ms, with Study 14's arm added at 1.19 and 0.2975 ms.
Every dropped arm now plays for 3 s instead of 1, so its second half starts at 1.5 s.

## Safe when off, and MuJoCo's tests

With both switches unset, all 249 play files are byte for byte the release's, and every one of MuJoCo's 3,492 tests gives
the release's result (run 064's reading). With the friction solve's switch alone, no test changes. With de Saxce's
switch, alone or with the other, the same two tests fail: `ForwardTest.DiscreteImplicitRowNoslip` and
`SolverTest.ZeroToleranceDisablesTermination`, the two Study 12 traced in advance.

## What each switch changes

| | Files that differ from the release's |
|---|---|
| q | 42, every one an arm on its ball: Study 10's arm in both poses, Study 13's in its second, Study 14's in all four, set down (as written and mirrored) and dropped, at both steps |
| d | 116 |
| dq | 134 |

Against **d**, **dq** differs in the same 42 arm files and in nothing else. With de Saxce's correction on, the friction
solve still changes only the arms that creep.

## The readings

Creep is `sx_contact creep`'s mean speed over the play's second half, in um/s. A dropped arm's last moving time is the
last step at which its ball moves faster than 10 um/s along x or z.

| | rel | q | d | dq |
|---|---|---|---|---|
| The 32 resting plays (8 poses of three arms, as written and mirrored, 2 steps each) | 24 over 10 um/s, up to 714 | **all 0** | 24 over 10 um/s, up to 714 | **all 0** |
| The 16 dropped plays (the 8 poses, 2 steps), 3 s | Study 13's first pose 0; the rest 79 to 591, still moving at 3 s | all 0, the last motion by 0.668 s | Study 13's first pose 0; the rest 76 to 591, still moving at 3 s | **all 0, the last motion by 0.655 s** |
| The arm held by joint friction | 2 | 2 | 2 | 2 |
| The 18 holds; the 8 grips | 0; 0 or 1 | the same | the same | the same |
| The cube slid kept from turning, along 0, 22.5 and 45 degrees, 1.14 ms | 133,036 um each | the same | 133,052 each | as d |
| Slid free to turn, 1.14 ms | 133,042, 136,043, 133,266 | the same | 133,036 each | as d |
| Straight stacks at 0.285 ms, the most tilt (5, 9) | 2,302, 2,523 urad | the same | 0, 3,181 | as d |
| Straight stacks at 1.14 ms; the offset stack of 3 | 0, 0; 9,363 and 9,657 | the same | the same | the same |
| The first suite: run 063's cube; Study 14's | 10 of 10; 9 of 10 (T08) | the same | 10 of 10; **10 of 10** | **10 of 10; 10 of 10** |
| The box of run 049, its last 160 steps | 106 faster than 1 mm/s | the same | 106 | 106 |
| The most iterations on a step | 18 | 18 | 57 | 57 |

No arm reached the iteration limit, and there was no warning. At 0.285 ms, kept from turning, the cube slides
133,471 um released and 133,494 um with d along every direction. Free to turn, it slides 133,491, 135,734 and
133,605 um released and 133,478 um along each with d.

## What it shows

- **Issue 1.** With both patches, every arm here holds: set down in every pose, as written and mirrored, and dropped.
  A dropped arm's slide on landing ends by 0.655 s, so a 3 s play read from 1.5 s reads it at rest. Study 14's R2
  read a 1 s play from 0.5 s.
- **T08.** It passes on Study 14's cube with de Saxce's correction on, as run 065 found.
- **Together.** The two patches do not interfere. Each changes what it changes alone, and only the two traced tests
  fail.
- **Issue 21.** de Saxce's correction stands the stack of 5 at 0.285 ms and tips the stack of 9 further (3,181 urad,
  released 2,523), as in Study 12. Run 052 found the stacks' outcome follows the last digits of the solve, so one
  reading orders nothing.
- **Issue 20.** The box's six-step cycle is unchanged by either patch.

The set Study 10 validated also includes the inverse weight in the current pose
([`invweight_at_pose_v3.diff`](../../patches/invweight_at_pose_v3.diff)), which this probe does not play. Run 068 plays
all three patches together.

## Files

Each arm's plays are in `rel`, `off`, `q`, `d` and `dq` (`p`, `arms`, `suites`). MuJoCo's test output is in
`ctest_*.txt`, read into `suite_results_*.txt` and `suite_changed_*.txt`.
