# Run 068: Senua AI's set with its three patches in one build (a probe)

17 October 2026 (00:14 to 00:27 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Readings in
[`measured.txt`](measured.txt).

Senua AI's set, as this record has validated its parts, is the configuration (the elliptic cone, 100 noslip
iterations) with three patches:

- the inverse weight in the current pose, third version ([`invweight_at_pose_v3.diff`](../../patches/invweight_at_pose_v3.diff),
  `engine_core_constraint.c`; Studies 8 to 10);
- de Saxce's correction ([`desaxce_elliptic_v4.diff`](../../patches/desaxce_elliptic_v4.diff), `engine_forward.c`;
  Study 12);
- in design, the friction solved in the directions that can move ([`qcqp_reduced.diff`](../../patches/in_design/qcqp_reduced.diff),
  `engine_solver.c`; Study 14, 13 of 15).

[Run 066](../run_066_combined/README.md) played the last two together. This probe builds all three into one MuJoCo, from
its source at `UPSTREAM_COMMIT`; they apply cleanly (`patch_check.txt`). Five arms:

- **rel**: MuJoCo 3.16.0 as released.
- **off**: the build, every switch unset.
- **all**: every switch set.
- **rel_rk4**, **all_rk4**: rel and all under RK4, Study 10's second integrator.

The scenes and numbers are run 066's, with dropped arms played for 3 s.

## Safe when off, and MuJoCo's tests

With every switch unset, all 249 play files are byte for byte the release's, and every one of MuJoCo's 3,492 tests
gives the release's result. With every switch set, the same two tests fail as with de Saxce's switch alone:
`ForwardTest.DiscreteImplicitRowNoslip` and `SolverTest.ZeroToleranceDisablesTermination`, the two Study 12 traced in
advance. Against run 066's arm with two patches, the third patch changes 48 files: the 48 plays of an arm on its ball.
Nothing else changes.

## The readings

Creep is `sx_contact creep`'s mean speed over the play's second half, in um/s. A dropped arm's last moving time is the
last step at which its ball moves faster than 10 um/s.

| | rel | all | rel_rk4 | all_rk4 |
|---|---|---|---|---|
| The 32 resting plays | 24 over 10 um/s, up to 714 | **all 0** | 24 over 10, up to 714 | **all 0** |
| The 16 dropped plays, 3 s | 14 over 10, up to 591, still moving at 3 s | **all 0, the last motion by 0.656 s** | 14 over 10, up to 590 | **all 0, by 0.654 s** |
| The arm held by joint friction | 2 | 2 | 2 | 2 |
| The 18 holds; the 8 grips | 0; 0 or 1 | the same | the same | the same |
| The cube slid kept from turning, 1.14 ms | 133,036 um each way | 133,052 | 133,039 | 133,071 |
| Slid free to turn, 1.14 ms | 133,042, 136,043, 133,266 | 133,036 each | 133,051, 134,897, 133,076 | 133,054 each |
| Straight stacks of 5 and 9, the most tilt, 1.14 ms | 0, 0 | 0, 0 | 4,415, 1,415 urad | 3,517, 999 |
| The same, 0.285 ms | 2,302, 2,523 | 0, 3,181 | 3,126, 5,390 | 4,146, 6,739 |
| The first suite: run 063's cube; Study 14's | 10; 9 (T08) | **10; 10** | 9 (T01); 8 (T01, T08) | 9 (T01); 8 (T01, T08) |
| The most iterations on a step; steps at the limit | 18; 0 | 57; 0 | 103; 20 (the slide on a box's face, 1.14 ms) | 57; 0 |

No warning in any arm. The box scene of run 049 sets its own options, so it plays alike in each arm pair. Its six-step
cycle is unchanged (issue 20).

Under RK4, the first suite's T01 fails released and patched alike. That is Study 10's finding: free flight is exact
under RK4, so the test's ratio cannot be read. T08 fails on Study 14's cube released and patched alike, though its
chain falls further with the patches (4,241 to 382 um against 14,349 to 1,146 um). The chain rises at its fourth step
in both, and at its sixth with the patches. The stacks tilt at both steps under RK4, released and patched.

## What it shows

- **Issue 1.** With every patch of the set, under the default integrator and under RK4, every arm here holds: set
  down in every pose, as written and mirrored, and dropped, the slide on landing over by 0.656 s. Every hold and grip
  is as before.
- **Together.** The three patches do not interfere. Each changes what it changes alone, and only the two traced tests
  fail. Under the default integrator the configuration passes the first suite on both cubes.
- **RK4.** It keeps T01 unreadable and T08 failing on Study 14's cube, released and patched, and the stacks tilt under
  it at 1.14 ms too.
- **Issue 21.** The stacks are as run 066 and runs 069 and 070 trace them.

This is the design for a registration of the set together: the configuration with its three patches, a dropped arm
read over the second half of 3 s, under the default integrator.
