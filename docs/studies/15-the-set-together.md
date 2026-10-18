# Study 15: Senua AI's set together, the configuration with its three patches

| | |
|---|---|
| Question | On numbers no earlier study or probe used, with every switch set: does Senua AI's set hold an arm resting on a contact, set down or dropped, in every pose played, under the default integrator and under RK4? Does it hold the arm held by joint friction, every hold and every grip? Under the default integrator, does it keep de Saxce's fixes and pass the first suite's ten tests? With every switch unset, is the patched MuJoCo the release, file for file and test for test? With every switch set, do any of MuJoCo's tests change but the two Study 12 named? |
| Outcome | **33 of 33 rule lines held.** Every resting and every dropped play of a fresh arm at 0 under both integrators (released, up to 482 um/s at rest and 688 um/s dropped). The arm held by joint friction, every hold and every grip held. No lift, no direction, four corners on the ground, Coulomb's distance, and the ten tests 10 of 10. Safe when off, and only the two named tests changed. **Issue 1 is fixed and validated**, and the friction solve moves out of design. |
| Registered | [`PREREGISTRATION_15.md`](../../preregistrations/PREREGISTRATION_15.md), pushed with its runner, dry run and rules plumbing check at 00:49 UTC on 17 October 2026, before any play |
| Played | Once, as [run 071](../../validation/run_071_study_15/README.md), 17 October 2026, 00:53 to 01:07 UTC, on Linux (the first cloud machine, 4 virtual CPUs and 8 GB) |
| Arms | MuJoCo 3.16.0 as released, and built with the three patches, every switch unset, each under MuJoCo's defaults and under Senua AI's configuration; every switch set, under the configuration with MuJoCo's default integrator and with RK4 (six arms) |
| Measured by | The Senua AI Robotics Core's measuring programs (`creep`, `stop`, `hover`), the rigs' own fields, file comparison, MuJoCo's own test suite, judged by `rule`; held to [Coulomb's law](../references.md#coulomb), [Popov 2010](../references.md#popov); MuJoCo's soft constraints, [Todorov 2014](../references.md#todorov-2014) |

## Why it was asked

Senua AI's set is the configuration (the elliptic cone with 100 noslip iterations; Studies 2, 10 and 13) with three
patches:

- the inverse weight in the current pose ([`invweight_at_pose_v3.diff`](../../patches/invweight_at_pose_v3.diff),
  Studies 8 to 10);
- de Saxce's correction ([`desaxce_elliptic_v4.diff`](../../patches/desaxce_elliptic_v4.diff), Study 12);
- the friction solved in the directions that can move ([`qcqp_reduced.diff`](../../patches/qcqp_reduced.diff)).

Study 14 found the friction solve holding every resting arm. It failed two rules. One was a dropped arm read while it
was still sliding from its landing. The other was T08, which fails under the elliptic cone alone from the cone's hop
(run 065). Runs 066 and 068 played the three patches together on earlier numbers. Every arm held, every landing slide
ended by 0.656 s, and the patches did not interfere.

## What changed from Study 14, stated before the run

The dropped arm is played for 3 s and read from 1.5 s, past the landing slides of runs 066 and 068. A creeping arm
creeps to the end of the play, so a longer play does not hide one. The study plays all three patches, adds RK4, and
rules de Saxce's fixes again with the other two on.

## The rules and what they read

| Rule | Reading | Held |
|---|---|---|
| Q1 to Q3 the release's defects | the arm creeps up to 482 um/s at rest; the cube lifts 7,557 um at 10 ms; free slides spend 1,775 steps on fewer than four corners | 3 of 3 |
| E1, E2 safe when off | 131 of 131 files under each option set; every MuJoCo test as released | 3 of 3 |
| M1 MuJoCo's suite, every switch set | only the two named tests change | 1 of 1 |
| R1 every resting pose holds | 0 um/s in all 16 plays, under both integrators | 2 of 2 |
| R2 every dropped arm holds | 0 um/s in all 8 plays from 1.5 s, under both integrators; the last motion by 0.638 s | 2 of 2 |
| J1, H1, G1 the joint, the holds, the grips | at most 3 um/s, under both integrators | 6 of 6 |
| V1 the solver | at most 30 iterations a step, none at the limit, no warning | 4 of 4 |
| L1, L2 no lift, four corners | 0 um at every step and on the ladder; no step on fewer than four corners | 2 of 2 |
| D1 to D3 no direction, no drift, no turn | every free slide the same distance along each direction, 0 um off its line, not turned | 8 of 8 |
| C1 Coulomb | 97,600 to 97,623 um as Senua AI's corrected measure reads them (97,472 to 97,493 as printed; [audit](../audit.md#the-measure-corrected-17-october-2026)), within 1 part in 100 of 97,579 um | 1 of 1 |
| K1 the ten tests | 10 of 10 | 1 of 1 |

## What it decides

- **Issue 1, a held object creeps at a contact: fixed and validated** by Senua AI's set with every switch set, under
  the default integrator and under RK4. That covers a cube held and gripped, an arm resting on a contact (set down and
  dropped) and an arm held by joint friction. The friction solve,
  [`qcqp_reduced.diff`](../../patches/qcqp_reduced.diff), is validated and moves to `patches/`.
- **The set together: validated** under the default integrator for everything the study rules. Under RK4, for the
  arm, the holds, the grips and the solver.
- **Issues 4 and 5:** de Saxce's fixes replicate with the other two patches on.
- Not decided: the stacks (issue 21), the box that never rests (issue 20), the first suite under RK4 (8 of 10, reported),
  MuJoCo's PGS solver, condim 4 and 6, anything against a real robot.
