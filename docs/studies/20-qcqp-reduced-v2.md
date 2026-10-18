# Study 20: the friction solve dropping a direction at noslip's floor, for a cube that cannot turn

| | |
|---|---|
| Question | On numbers no earlier study or probe used: with the friction solve's second version in Senua AI's set, does every hold hold, with condim 3, 4 and 6, held from turning and free, along three directions? Is everything else the set plays exactly as with the first version? Do the arms, grips and boxes still hold? With every switch unset, is the patched MuJoCo the release? Do any of MuJoCo's tests change but the two Study 12 named? |
| Outcome | **13 of 14 rule lines held; H1 failed.** Every cube held from turning with condim 4 or 6 holds at 0 um/s, where released and with the first version it creeps at up to 1,780 um/s. Nothing else changed, byte for byte. But a free cube pushed square to a face at 0.95 of its limit creeps, at 173 to 1,124 um/s, with either version and with condim 3 too. Issue 1 stays fixed in part; the second version stays in design. |
| Registered | [`PREREGISTRATION_20.md`](../../preregistrations/PREREGISTRATION_20.md), pushed with its runner, dry run and rules plumbing check at 04:35 UTC on 17 October 2026, before any play |
| Played | Once, as [run 087](../../validation/run_087_study_20/README.md), 17 October 2026, 04:35 to 04:49 UTC, on Linux (the first cloud machine) |
| Arms | MuJoCo 3.16.0 as released; Senua AI's five validated patches with the friction solve's first version; the same with its second, switches unset and set |
| Measured by | `sx_contact creep` and the scene rig's columns, file comparison, MuJoCo's own test suite, judged by the Senua AI Robotics Core's `rule`; held to [Coulomb's law](../references.md#coulomb), [Popov 2010](../references.md#popov); MuJoCo's soft constraints, [Todorov 2014](../references.md#todorov-2014) |

## Why it was asked

Under Senua AI's set a cube held from turning creeps with torsional or rolling friction (run 084). Noslip clamps each
diagonal entry of a contact's block at 1e-10 from below. The directions such a cube cannot move in sit at that floor.
The friction solve's first version kept them whenever the block's largest entry was below 1. Its second version,
[`qcqp_reduced_v2.diff`](../../patches/in_design/qcqp_reduced_v2.diff), also drops a direction at the floor. In run 086
it held the cube and changed nothing else played.

## The rules and what they read

| Rule | Reading | Held |
|---|---|---|
| Q1, Q2 the cube held from turning creeps released and with the first version | 1,780 and 1,479 um/s | 2 of 2 |
| E1, E2, M0, M1 safe when off; MuJoCo's suite | 286 of 286 files; every test as released; 3,492 tests each reading; only `ZeroToleranceDisablesTermination` changes | 4 of 4 |
| P0 every play measured | 286 readings in each arm | 1 of 1 |
| **H1 every hold holds** | **204 of 216; the free cubes pushed along 0 degrees at 0.95 of the limit creep at 173 to 1,124 um/s** | **0 of 1** |
| N1 nothing else changes | 222 of 222 files | 1 of 1 |
| R1, G1, B1 the arms, the grips, the boxes | every arm and grip at most 10 um/s, every box at rest | 3 of 3 |
| V1 the solver | never at the limit, no warning | 2 of 2 |

## What it decides

- **Issue 1 stays fixed in part.** The second version stays in `patches/in_design/`.
- A cube held from turning with condim 4 or 6 is held by the second version in every one of its 72 plays here. That
  is measured, not yet validated on its own registered claim.
- A free cube pushed square to a face near its friction limit creeps in Senua AI's set. It is a new case of issue 1,
  not traced here.
