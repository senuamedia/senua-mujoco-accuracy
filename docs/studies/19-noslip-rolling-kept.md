# Study 19: noslip leaving the rolling friction as it was, for the box that never rests

| | |
|---|---|
| Question | On numbers no earlier study or probe used: with Senua AI's set and this switch, does every box come to rest: MuJoCo's own box and three fresh ones written from its scene, at its step and a fresh one, with 2 and 100 noslip iterations? Is everything else the set plays exactly as without the switch? With every switch unset, is the patched MuJoCo the release? Do any of MuJoCo's tests change but the two Study 12 named? |
| Outcome | **9 of 9 rule lines held.** All 14 box plays at rest over their last 160 steps, where released and with the set alone every box rocks (106 to 128 of those steps faster than 1 mm/s, up to 77 mm/s). Nothing else changed, safe when off, and of MuJoCo's tests only one of the two named changed. **Issue 20 is fixed and validated**, and the patch moves out of design. |
| Registered | [`PREREGISTRATION_19.md`](../../preregistrations/PREREGISTRATION_19.md), pushed with its runner, dry run and rules plumbing check at 04:00 UTC on 17 October 2026, before any play |
| Played | Once, as [run 085](../../validation/run_085_study_19/README.md), 17 October 2026, 04:00 to 04:20 UTC, on Linux (the first cloud machine) |
| Arms | MuJoCo 3.16.0 as released; built with Senua AI's four validated patches and this one, every switch unset, the four set, and the five set |
| Measured by | The scene rig's own columns, file comparison, MuJoCo's own test suite, judged by the Senua AI Robotics Core's `rule`; held to [Coulomb's law](../references.md#coulomb); MuJoCo's soft constraints, [Todorov 2014](../references.md#todorov-2014) |

## Why it was asked

MuJoCo's own test scene `DiscreteImplicitRowNoslip` never comes to rest (issue 20, F13). It is a box with condim 6 and
noslip, under the discrete integrator. It rocks on a six-step cycle with noslip converging every step (run 073). Every
contact's rolling torque sits at the edge of the elliptic cone, the one ellipsoid all of a contact's friction shares,
leaving the sliding friction no room (run 076).

The patch, [`noslip_roll_kept_after_qcqp.diff`](../../patches/noslip_roll_kept_after_qcqp.diff) (45 lines added to
`engine_solver.c`, none removed, applied after the friction-solve patch), changes noslip for a condim-6 contact. It
leaves the rolling friction as it was and solves the sliding and torsional friction in what the cone has left, through
MuJoCo's own solve. Noslip removes slip, and rolling is not slip. Two designs brought the box to rest (runs 079, 082),
and this one did so within the set (run 084).

## The rules and what they read

| Rule | Reading | Held |
|---|---|---|
| Q1 the release's box keeps moving | MuJoCo's own box faster than 1 mm/s on 106 of its last 160 steps | 1 of 1 |
| E1, E2 safe when off | 46 of 46 files; every MuJoCo test as released | 2 of 2 |
| M0, M1 MuJoCo's suite | each reading 3,492 tests; with the five switches only `ZeroToleranceDisablesTermination` changes | 2 of 2 |
| R1 every box comes to rest | no step of the last 160 faster than 10 um/s, in all 14 plays | 1 of 1 |
| N1 nothing else changes | 32 of 32 files of the arm, the holds and the grips as with the four switches alone | 1 of 1 |
| V1 the solver | never at the limit, no warning | 2 of 2 |

## What it decides

- **Issue 20: fixed and validated** by Senua AI's set with this patch, which is validated and moves to `patches/`.
- With it, MuJoCo's own test `DiscreteImplicitRowNoslip` passes because its box rests, not because its last step falls
  on the cycle's slow step.
- Not decided: issue 1's open part; rolling friction on a rolling body, which no rig here plays; the PGS solver;
  anything against a real robot.
