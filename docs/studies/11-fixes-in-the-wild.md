# Study 11: the fixes in the wild for a held object that creeps, held to the same answers as Senua AI's

| | |
|---|---|
| Question | On numbers no earlier study used, which of the fixes in use or proposed for a load that creeps inside the friction cone (MuJoCo's `impratio`, the elliptic cone, noslip under the default cone, and pull request #3349's stiction) holds a held object still, holds a gripped one, leaves a body moved from outside where it was put, restores a saved state exactly, and holds the pull request's own demos, beside Senua AI's configuration; and is the pull request, its flag unset, the MuJoCo it branched from? |
| Outcome | **37 of 58 rule lines held. Senua AI's configuration held every line it was put to, 11 of 11, on MuJoCo's release and on the pull request's head.** No MuJoCo option alone holds a held object or a grip. Stiction holds a held object and its own demos and is safe when off, but **fails a body moved from outside and a restored state**. |
| Registered | [`PREREGISTRATION_11.md`](../../preregistrations/PREREGISTRATION_11.md), 16 October 2026, pushed with its runner and dry run before any play |
| Played | Once, as [run 044](../../validation/run_044_study_11/README.md), 16 October 2026 04:57 UTC, on Linux (the first cloud machine, 4 virtual CPUs and 8 GB) |
| Arms | MuJoCo 3.16.0 as released under seven configurations; pull request #3349 built as its author left it, its flag unset and set, beside the commit it branched from and Senua AI's configuration on its head |
| Measured by | The Senua AI Robotics Core's measuring programs (`creep`, `gap`, `ends`), file comparison, MuJoCo's own test suite, judged by `rule`; held to [Coulomb's law](../references.md#coulomb), [Popov 2010](../references.md#popov); MuJoCo's soft constraints, [Todorov 2014](../references.md#todorov-2014) |

## Why it was asked

Under MuJoCo's defaults a load inside the friction cone creeps (finding F1, known issue M1). MuJoCo's maintainers call
that working as intended, and its users and its documentation offer several fixes: a larger `impratio`, the elliptic
cone, the noslip solver, and in June 2026 [pull request #3349](https://github.com/google-deepmind/mujoco/pull/3349),
stiction, which stores the relative pose of each pair of touching bodies and adds a spring against slip from it; it
was closed without being merged. Senua AI's fix is a configuration of options MuJoCo already has, the elliptic cone
with 10 noslip iterations, validated by [Study 2](02-recommended-configuration.md) and replicated by
[Study 10](10-recommended-configuration-end-to-end.md). [Run 043](../../validation/run_043_fixes_in_the_wild/README.md),
a probe on throwaway numbers, put every fix to the same scenes. This study asked it on fresh numbers, with the rules
fixed in advance.

## The scenes

Drawn from seed 11 (`draw.txt`): a 1.381 kg cube, friction 0.369, held with 0.5, 0.75 and 0.95 of its friction limit
along 0, 22.5 and 45 degrees; a 0.218 kg cube gripped between two pads, box and mesh, with friction 1.88 times its
weight, centred and 7.9 mm off; at 1.65 ms and 0.4125 ms. On the pull request's builds also: the held cube moved 2 mm
from outside, as a reset, a teleoperation correction or a domain randomiser moves a body; the held cube shoved past its
limit with MuJoCo's saved state restored across the shove, as a planner or a reinforcement-learning rollout restores a
state; and the pull request's own two demo scenes, a block on a 30 degree ramp and a box in a passive parallel-jaw
grip, played as its author wrote them; and MuJoCo's own test suite on both builds.

## The result

| Fix | Held object (H) | Grip (G) | Moved from outside (T) | Restored state (S) | Its demos (D) | Solver (V) | Lines held |
|---|---|---|---|---|---|---|---|
| MuJoCo's defaults | **Failed**: 542 to 2,006 um/s along an axis; slides away along 45 degrees | **Failed**: 6,991 to 7,737 um/s | | | | Held | 2 of 4 |
| `impratio` 10 | **Failed**: 54 to 201 along an axis; slides away along 45 | **Failed**: 738 to 813 | | | | Held | 2 of 4 |
| `impratio` 100 | **Failed**: 5 to 20 along an axis; slides away along 45 | **Failed**: 74 to 81 | | | | Held | 2 of 4 |
| The elliptic cone | **Failed**: 471 to 895, every direction | **Failed**: 3,541 to 3,806 | | | | Held | 2 of 4 |
| The elliptic cone, `impratio` 10 | **Failed**: 47 to 89, every direction | **Failed**: 354 to 382 | | | | Held | 2 of 4 |
| Noslip under the default cone | **Failed**: 0 at half the limit, 1,355 to 2,006 above it along an axis; slides away along 45 | **Failed**: 7,103 to 7,198 | | | | Held | 2 of 4 |
| The commit the pull request branched from (june), and its head with the flag unset (off) | **Failed**: 471 to 895 | | **Failed**: 565 | Held | **Failed**: 8,020 and 17,276 | Held | 4 of 7 each |
| **Pull request #3349, stiction** (on) | **Held**: 0 | | **Failed**: pulled back at up to 3.1 mm/s, then 29 um/s | **Failed**: up to 120 um from the original | **Held**: 0 | Held | 4 of 7 |
| **Senua AI's configuration**, on the release | **Held**: 0 | **Held**: 0 to 1 | | | | Held | **4 of 4** |
| **Senua AI's configuration**, on the pull request's head (cfg) | **Held**: 0 | | **Held**: 0 | **Held**: byte for byte | **Held**: 0 | Held | **7 of 7** |
| The pull request, safe when off (E1, E2) | off plays all 20 hold and demo files byte for byte as june; MuJoCo's suite passes in full on both, every test reading the same | | | | | | 2 of 2 |

The worst creeps are over the three loads and both steps; the right answer is 0 and the bound 10 um/s. Blank: not
played for that arm. The figures for each play are in [run 044](../../validation/run_044_study_11/README.md).

## What the decisions record

- **Senua AI's configuration holds a held object by this study's known answers**: every hold, every grip, a body moved
  from outside, a restored state and the pull request's own demos, on MuJoCo's release and on the pull request's head.
- **No MuJoCo option alone does.** `impratio` slows the creep in proportion and never stops it; the elliptic cone
  removes the direction but not the creep; noslip under the default cone holds only the lightest push, and none of
  them leaves the default cone's direction behind.
- **Stiction holds a held object and the pull request's own demos, and fails two of this study's rules**: a body moved
  from outside is pulled back toward the pose the pull request stored, and a state saved and restored does not replay
  the original. Both follow from where it keeps its stored poses: in `mjData`, and, by its own documentation, "not part
  of the serialized state", to be reconstructed from the contacts after a restore. By its code, a pair still touching
  at a restore keeps the pose stored at the moment restored from, not the one of the state restored, and a body's
  position set from outside leaves its stored pose where it was; the measured pull-back and the restored play's
  departure are what that predicts.
- **The pull request is safe when off**, file for file and test for test.

## What it means

- **Senua AI's fix holds where every other fix measured falls short, and needs no new code.** It is two options
  MuJoCo already ships, chosen and proven by Senua AI's Measure. Stiction comes closest, and its 646 lines of new state
  are what a moved body and a restored state trip over: operations robot learning uses all the time (resets, domain
  randomisation, rollouts from a saved state).
- **The cost is solver work**: at most 6 iterations a step on the release and 8 on the pull request's head, against 3
  to 4 for MuJoCo's defaults and stiction. It is reported, not ruled.
- It says nothing about a free cube's direction under the elliptic cone (finding F12), the default cone's direction
  with Senua AI's patch (Study 1), the written pose (Studies 5 to 10), gradients, or a real robot. The pull request was
  played as its author left it, on the June 2026 MuJoCo it was written for; it does not apply to 3.16.0.
