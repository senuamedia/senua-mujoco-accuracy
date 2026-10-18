# Study 7: the inverse weight in the current pose, for contacts, joint limits and joint friction

| | |
|---|---|
| Question | On scenes the probes did not use, does MuJoCo as released end the same arm differently for each pose its file is written in, on contact, swinging on a joint limit and held by joint friction; with the second version on, does every writing end in the same place, at the same speed, creeping alike; does nothing else change; and with it off, is MuJoCo the release? |
| Outcome | **134 of 134 rule lines held: the second version is validated** for contacts, joint limits and joint friction |
| Registered | [`PREREGISTRATION_07.md`](../../preregistrations/PREREGISTRATION_07.md), 15 October 2026, pushed with its runner before any play |
| Played | Once, as [run 035](../../validation/run_035_study_07/README.md), 15 October 2026 10:35 UTC, on Linux (the second cloud machine, 4 virtual CPUs) |
| Arms | MuJoCo 3.16.0 as released; the patched build with the switch unset; with it set; the arm on contact also under the elliptic cone with noslip |
| Measured by | The Senua AI Robotics Core's measuring programs (`ends`, `creep`), MuJoCo's own test suite, judged by `rule`; held to MuJoCo's constraint model, [Todorov 2014](../references.md#todorov-2014) |

## Why it was asked

Study 5 validated the first version for contacts. MuJoCo takes the softness of joint limits and joint friction from
the joints' own inverse weights, also frozen in the written pose: a swing on a joint limit ended up to 1.24 mm apart by
writing (run 032), and an arm held by joint friction up to 32 mm apart (run 034). The second version takes those in the
current pose too, by MuJoCo's own formula, the stock lines kept; in run 033 it held all 74 of its check lines.

## The scenes

A new arm (links of 0.26 and 0.32 m, 1.1 and 0.35 kg, a ball of 0.028 m and 0.18 kg, friction 0.65), every scene written
in its own pose, straight and folded (0, 2.3), at 1.25 ms and 0.3125 ms: on contact in two poses, set down from 0.5 mm
and dropped from 15 mm; swinging with its elbow pressed on an upper limit in two poses; held 1 m up by 5 N m of joint
friction on both hinges in two poses. New stacks, an offset stack, slides on the ground and a box face, and grips with
box and mesh pads; both contact suites; MuJoCo's own 3,492 tests.

## The result

| Rule | Measured | |
|---|---|---|
| R1 safe when off, plays | 216 of 216 files identical | held |
| R2 safe when off, MuJoCo's suite | 3,492 of 3,492 tests as released | held |
| R3 the defect is there | Released, by writing alone: 2.1 to 89 um apart on contact, 0.10 to 1.9 mm swinging on the limit, 1.1 to 21 mm held by joint friction | held |
| R4 correct, place | On: every writing ends 0 nm from the native, in every scene, pose and step | held |
| R5 correct, speed | On: 0 um/s apart | held |
| R6 correct, creep | On: the same creep in every writing, on contact and held by joint friction | held |
| R7 nothing else changes, plays | On: 143 of 143 cube and suite files identical | held |
| R8 nothing else changes, MuJoCo's suite | Switch set against unset: no test changes | held |
| R9 the solver | On: no step at the iteration limit, no warning | held |

Not corrected and not asked: the creep of an arm held by joint friction itself (F1), and equality constraints, which run
036 found affected and the third version, in design, adds.
