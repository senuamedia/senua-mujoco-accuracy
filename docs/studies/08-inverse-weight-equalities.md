# Study 8: the inverse weight in the current pose, with equality constraints

| | |
|---|---|
| Question | On scenes the probes did not use, does MuJoCo as released end the same arm differently for each pose its file is written in, on contact, on a joint limit, held by joint friction and held by a `connect` equality; with the third version on, does every writing end in the same place, at the same speed, creeping alike; does nothing else change; and with it off, is MuJoCo the release? |
| Outcome | **154 of 154 rule lines held: the third version is validated** for contacts, joint limits, joint friction and a `connect` |
| Registered | [`PREREGISTRATION_08.md`](../../preregistrations/PREREGISTRATION_08.md), 15 October 2026, pushed with its runner before any play |
| Played | Once, as [run 038](../../validation/run_038_study_08/README.md), 15 October 2026 11:09 UTC, on Linux (the second cloud machine, 4 virtual CPUs) |
| Arms | MuJoCo 3.16.0 as released; the patched build with the switch unset; with it set; the arm on contact also under the elliptic cone with noslip |
| Measured by | The Senua AI Robotics Core's measuring programs (`ends`, `creep`), MuJoCo's own test suite, judged by `rule`; held to MuJoCo's constraint model, [Todorov 2014](../references.md#todorov-2014) |

## Why it was asked

Studies 5 and 7 validated the first two versions. Run 036 found a ball held by a `connect` equality sagging 209 to 310
um depending on the written pose, through the same frozen body weights; the third version takes those in the current
pose too, and held all 94 of its check lines in run 037.

## The scenes

A new arm (links of 0.29 and 0.27 m, 0.95 and 0.45 kg, a ball of 0.026 m and 0.17 kg, friction 0.72), every scene written
in its own pose, straight and folded (0, 2.4), at 1.6 ms and 0.4 ms: on contact in two poses, set down from 0.6 mm and
dropped from 11 mm; swinging on an elbow limit; held 1 m up by 5.5 N m of joint friction; held 1 m up by a `connect` to
where its ball starts. New stacks, an offset stack, slides on the ground and a box face, and grips with box and mesh pads;
both contact suites; MuJoCo's own 3,492 tests.

## The result

| Rule | Measured | |
|---|---|---|
| R1 safe when off, plays | 232 of 232 files identical | held |
| R2 safe when off, MuJoCo's suite | 3,492 of 3,492 tests as released | held |
| R3 the defect is there | Released, by writing alone: 6.0 to 94 um apart on contact, 35.7 to 113 um on the limit, 4.2 to 25.6 mm held by joint friction, 0.9 to 100 um held by the `connect` | held |
| R4 correct, place | On: every writing ends 0 nm from the native, in every scene, pose and step | held |
| R5 correct, speed | On: 0 um/s apart | held |
| R6 correct, creep | On: the same creep in every writing, on contact and held by joint friction | held |
| R7 nothing else changes, plays | On: 147 of 147 cube and suite files identical | held |
| R8 nothing else changes, MuJoCo's suite | Switch set against unset: no test changes | held |
| R9 the solver | On: no step at the iteration limit, no warning | held |

Not asked: a `weld`, which the patch also changes ([Study 9](09-weld-and-tumbling-body.md) asks it); the creep itself
of an arm held by friction (F1).
