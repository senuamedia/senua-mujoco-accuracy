# Study 5: the inverse weight in the current pose

| | |
|---|---|
| Question | On scenes the probes did not use, does MuJoCo as released end the same arm differently for each pose its file is written in; with the patch on, does every writing end in the same place, at the same speed, creeping alike; does nothing else change, in this record's cube scenes and in MuJoCo's own suite; and with it off, is MuJoCo the release? |
| Outcome | **86 of 86 rule lines held: the patch is validated** for contacts, what it changes |
| Registered | [`PREREGISTRATION_05.md`](../../preregistrations/PREREGISTRATION_05.md), 15 October 2026, pushed with its runner before any play |
| Played | Once, as [run 030](../../validation/run_030_study_05/README.md), 15 October 2026 09:27 UTC, on Linux (EC2 c7i.large) |
| Arms | MuJoCo 3.16.0 as released; the patched build with the switch unset; with it set; each under MuJoCo's defaults and, for the arm, the elliptic cone with noslip |
| Measured by | The Senua AI Robotics Core's measuring programs (`ends`, `creep`), MuJoCo's own test suite, judged by `rule`; held to MuJoCo's constraint model, [Todorov 2014](../references.md#todorov-2014) |

## Why it was asked

MuJoCo takes each contact's softness from its bodies' inverse weights, computed once in the pose a model is written in.
The same arm, in the same place, then sinks and creeps by different amounts depending only on how its file was written
(run 025, finding F10). MuJoCo's own `diagexact` flag removes that but turns symmetric scenes under the default cone
(run 028). The patch takes each contact body's weight where the body is, by MuJoCo's own formula, and changes nothing
else; in run 029 it held 49 of 50 check lines, the one failure the check's arithmetic on a writing that started, by
rounding, a hair above the ground. This study started every writing clearly above the ground and set the creep's bound
at the measure's resolution, before any of its data existed.

## The scenes

An arm of 0.28 and 0.24 m, 0.9 and 0.4 kg, with a ball of 0.025 m and 0.15 kg at its tip, friction 0.7, in two poses
(C: 0.6 and 1.0 rad; D: 1.3 and -0.5), each written in its own pose, straight and folded; set down from 0.4 mm (2 s) and
dropped from 12 mm (1 s), at 1 ms and 0.25 ms. Stacks of 4 and 7 cubes, an offset stack, slides on the ground and a box
face, and grips with box and mesh pads, all new cubes. Both contact suites; MuJoCo's own 3,492 tests.

## The result

| Rule | Measured | |
|---|---|---|
| R1 safe when off, plays | 192 of 192 files identical | held |
| R2 safe when off, MuJoCo's suite | 3,492 of 3,492 tests as released | held |
| R3 the defect is there | Released: the straight writing ends 6.0 to 43.6 um from the native, every pose, scene and step | held |
| R4 correct, place | On: every writing ends 0 nm from the native, under both configurations, every pose, scene and step | held |
| R5 correct, speed | On: 0 um/s apart | held |
| R6 correct, creep | On: the same creep in every writing (175 and 174 um/s in pose C, 521 in pose D) | held |
| R7 nothing else changes, plays | On: 143 of 143 cube and suite files identical | held |
| R8 nothing else changes, MuJoCo's suite | Switch set against unset: no test changes | held |
| R9 the solver | On: no step at the iteration limit, no warning | held |

Released, the same arm ends 2.0 to 97 um apart by writing and creeps at 112 to 175 um/s in one pose and 367 to 557 in
the other; with the patch on it ends in exactly the same place at exactly the same speed, whatever its file. Joint
limits and joint friction are outside this patch and this study: run 032 found the same effect on a joint limit, and
the second version is in design.
