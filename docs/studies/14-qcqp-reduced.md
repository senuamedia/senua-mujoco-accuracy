# Study 14: the friction solved in the directions that can move, for an arm resting on a contact

| | |
|---|---|
| Question | On numbers no earlier study or probe used: with the patch's switch set, does Senua AI's configuration hold an arm resting on a contact, set down or dropped, in every pose played, while everything else it plays is exactly as released; with it unset, is the patched MuJoCo the release, file for file and test for test; with it set, does any of MuJoCo's tests change? |
| Outcome | **13 of 15 rule lines held; the decision does not hold.** Every resting play of a fresh arm, four poses as written and mirrored, at 0 with the switch set (497 um/s at most released), every other play and all of MuJoCo's tests as released, safe when off. **Failed**: R2, a dropped arm in one pose still sliding from its landing in the window read (it comes to rest at 0.61 s and holds at 0); K1, the first suite's T08 under the configuration, released and patched alike (the elliptic cone's hop, run 065). Issue 1 stays fixed in part; the patch stays in design. |
| Registered | [`PREREGISTRATION_14.md`](../../preregistrations/PREREGISTRATION_14.md), pushed with its runner, dry run and rules plumbing check at 13:05 UTC on 16 October 2026 (its text carries the local date, 17 October), before any play |
| Played | Once, as [run 064](../../validation/run_064_study_14/README.md), 16 October 2026 13:07 UTC, on Linux (the first cloud machine, 4 virtual CPUs and 8 GB) |
| Arms | MuJoCo 3.16.0 as released, and built with the patch, its switch unset and set, each under MuJoCo's defaults and under Senua AI's configuration (six arms) |
| Measured by | The Senua AI Robotics Core's measuring programs (`creep`, `stop`), the rigs' own fields, file comparison, MuJoCo's own test suite, judged by `rule`; held to [Coulomb's law](../references.md#coulomb), [Popov 2010](../references.md#popov); MuJoCo's soft constraints, [Todorov 2014](../references.md#todorov-2014) |

## Why it was asked

Under Senua AI's configuration a cube held or gripped holds, but an arm resting on its ball creeps in some poses
(Studies 10 and 13). Run 062 traced it in MuJoCo's source: noslip solves an elliptic contact's friction with `mju_QCQP2`
(or `mju_QCQP3`, `mju_QCQP`), which rejects the friction block by an absolute threshold when one friction direction
cannot move, as across a planar arm; it returns zero friction and MuJoCo puts the old friction back. The patch,
[`qcqp_reduced.diff`](../../patches/in_design/qcqp_reduced.diff) (67 lines added to `engine_solver.c`, none removed),
sets the friction in such a direction to zero and solves the other directions with MuJoCo's own solvers; any other
contact is solved as released. Run 063 found it holding every resting pose of two arms and changing nothing else.

## The rules and what they read

| Rule | Reading | Held |
|---|---|---|
| Q1 the release's arm creeps | up to 497 um/s at rest | 1 of 1 |
| E1, E2 safe when off | 129 of 129 files under each option set; every MuJoCo test as released | 3 of 3 |
| P1 untouched where the solve is not used | 129 of 129 files under MuJoCo's defaults | 1 of 1 |
| M1 MuJoCo's suite, switch set | no test changes | 1 of 1 |
| R1 every resting pose holds | 0 um/s in all 16 resting plays | 1 of 1 |
| R2 every dropped arm holds | 0, 50, 0, 7 and 0, 66, 0, 2 um/s over the second half | **0 of 1** |
| N1 nothing else changes | 89 of 89 play files as released | 1 of 1 |
| J1, H1, G1 the joint, the holds, the grips | at most 2 um/s | 3 of 3 |
| K1 the ten tests | 9 of 10 (T08) | **0 of 1** |
| V1 the solver | at most 20 iterations a step, none at 100, no warning | 2 of 2 |

## What it decides

- **Not decided**: issue 1 stays fixed in part, and the patch stays in design. The registration asked for every rule.
- **What failed, and why.** R2: dropped in one pose the arm slides on landing at its friction limit, a real slide, and
  with the switch set comes to rest at 0.61 s and holds at 0, where released it creeps at 89 um/s to the end; the rule
  read the second half of the play, from 0.5 s. K1: T08 fails under the configuration on this study's suite cube with or
  without the patch; [run 065](../../validation/run_065_suite_t08/README.md) found it the elliptic cone's, removed by
  the de Saxce patch (Study 12), with which the configuration passes all ten.
- **What held**: the patch's own target, an arm resting on a contact, at 0 in every pose on fresh numbers; and, with it,
  every other play and all of MuJoCo's tests as released.
- The next registration needs the configuration with both patches, and a reading of a dropped arm once it has stopped
  sliding.
- **Followed by** [Study 15](15-the-set-together.md), which played it with the configuration and the other two patches of
  Senua AI's set, the dropped arm read once its landing slide was over: 33 of 33 rule lines, the patch validated.
