# Study 16: the box-on-box clip without its collinear vertices, for a straight stack

| | |
|---|---|
| Question | On numbers no earlier study or probe used, with Senua AI's set and this patch: does every straight stack stand, at three steps and three main tolerances, with its contacts unchanged and its cubes at rest? With the patch alone, under MuJoCo's defaults, does every straight stack stand? Is everything else the set plays exactly as without the patch? With every switch unset, is the patched MuJoCo the release? Do any of MuJoCo's tests change? |
| Outcome | **15 of 15 rule lines held.** With Senua AI's set and the patch, all 36 straight stacks of a fresh cube stood (released, 8 tilted, up to 10,919 urad), no face's contacts changed and every cube was at rest. Nothing else the set plays changed, and of MuJoCo's tests only the two Study 12 named. Safe when off. **Issue 21 is fixed and validated**, and the patch moves out of design. |
| Registered | [`PREREGISTRATION_16.md`](../../preregistrations/PREREGISTRATION_16.md), pushed with its runner, dry run and rules plumbing check at 02:12 UTC on 17 October 2026, before any play |
| Played | Once, as [run 077](../../validation/run_077_study_16/README.md), 17 October 2026, 02:14 to 02:48 UTC, on Linux (the first cloud machine, 4 virtual CPUs and 8 GB) |
| Arms | MuJoCo 3.16.0 as released, under its defaults and under Senua AI's configuration; built with Senua AI's three validated patches and this one, every switch unset under each; Study 15's three switches set; those and this one; and this one alone under MuJoCo's defaults (seven arms) |
| Measured by | The stack rig's own fields and its contacts trace, file comparison, MuJoCo's own test suite, judged by the Senua AI Robotics Core's `rule`; held to [Coulomb's law](../references.md#coulomb); MuJoCo's soft constraints, [Todorov 2014](../references.md#todorov-2014) |

## Why it was asked

Under Senua AI's configuration a straight stack of equal cubes tilts at some steps and tolerances and stands at others,
with no order (issue 21). The probes traced it to MuJoCo's box-on-box collision:

- Noslip converges every step (run 067).
- Each stack stands until a kick in one step. The kick comes when the clip of one face against the other
  (`clipHalfPlane`, `engine_collision_box.c`) adds contacts along the face's edges (run 069).
- It does this when the upper face's edges lie on the lower face's side planes and the face turns or shifts. The first
  time it is by rounding, the corners 1e-17 m out; after that, by the kick's own drift (run 072).
- Each added point lies on the support polygon's edge and adds nothing to it, yet it carries a corner's force.

The patch, [`boxbox_collinear.diff`](../../patches/boxbox_collinear.diff) (35 lines added to `engine_collision_box.c`,
none removed), drops from the clipped polygon every vertex on a straight line with its two neighbours. "Straight" means
to the noise level MuJoCo's separation test already uses for parallel edges. Its first design, the clip given a
rounding slack, failed at MuJoCo's default tolerance (run 070). This one stood every stack of run 052's grid (run 074)
and, in Senua AI's set, stacks of 3 to 12 cubes at five steps (run 075).

## The rules and what they read

| Rule | Reading | Held |
|---|---|---|
| Q1 the release's stacks tilt | up to 10,919 urad; 8 of 36 tilt more than 100 urad | 1 of 1 |
| E1, E2 safe when off | 576 of 576 files under each option set; every MuJoCo test as released | 3 of 3 |
| M0 every suite read | 3,492 tests in each of the four readings | 1 of 1 |
| M1, M2 MuJoCo's suite | with the four switches, only the two named tests change; with the patch alone, none | 2 of 2 |
| S1, S2, S3 every stack stands, its contacts unchanged, at rest | 0 urad, 0 changes and 0 um/s in all 36 | 3 of 3 |
| S4 the patch alone, under MuJoCo's defaults | 0 urad in all 36, as released | 1 of 1 |
| N1, N2 nothing else changes | 32 of 32 files, in the set and alone | 2 of 2 |
| V1 the solver | at most 25 iterations a step, none at the limit, no warning | 2 of 2 |

## What it decides

- **Issue 21: fixed and validated** by Senua AI's set with the collinear patch. The patch is validated and moves to
  `patches/`.
- Under MuJoCo's defaults no straight stack tilted, released or patched. S4 and N2 show the patch harms nothing there;
  they are not a fix there.
- Not decided: issue 9 (a stack sinks, and an offset stack leans; its offset stacks lean in every arm, reported); boxes
  of unequal size and plates; RK4; MuJoCo's PGS solver; anything against a real robot.
