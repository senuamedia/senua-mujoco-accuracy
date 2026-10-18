# Run 038: the eighth registered study, played once

Played 15 October 2026 (11:09 UTC, `played_at.txt`) on the second cloud machine (4 virtual CPUs), by
[`play.sh`](play.sh), under [`preregistrations/PREREGISTRATION_08.md`](../../preregistrations/PREREGISTRATION_08.md),
pushed before any play. The inverse weight in the current pose, third version
(`patches/in_design/invweight_at_pose_v3.diff`, sha256 d3fd45cc3d3ecfb0...), rebuilt by the runner from the registered
patch file, against Google DeepMind's Linux release, with MuJoCo's own test suite run on and off. Every measured number
is in `measured.txt`, every rule's line in `rules.txt`. The dry run (`dry/`, the release only, the arms of runs 025, 032,
034 and 036 and run 026's cubes) ran to the end and wrote all 93 measured lines; no rule was read from it.

**The result: 154 of 154 rule lines held. The study holds: the third version is validated for what this registration
asks, contacts, joint limits, joint friction and a `connect` equality.**

| Rule | Measured | |
|---|---|---|
| R1 safe when off, plays | 232 of 232 files byte-identical to the release | held |
| R2 safe when off, MuJoCo's suite | All 3,492 tests as the release (every one passed in all three arms) | held |
| R3 the defect is there | Released, the straight writing ends at least 1 um from the native in every scene, pose and step (20 lines); by writing alone, counting the folded writings too, the arm ends 6.0 to 94 um apart on contact, 35.7 to 113 um on the limit, 4.2 to 25.6 mm held by joint friction, 0.9 to 100 um held by the `connect` | held |
| R4 correct, place | On: every straight and folded writing ends **0 nm** from the native, in every scene, pose and step, and on contact under both configurations (56 lines) | held |
| R5 correct, speed | On: **0 um/s** apart, every line (56 lines) | held |
| R6 correct, creep | On: the same creep in all three writings (16 lines): on contact 166 and 313 um/s, held by joint friction 30,311 and 21,399 um/s at 1.6 ms | held |
| R7 nothing else changes, plays | On: 147 of 147 files of both suites, the stacks, the slides and the grips byte-identical to the release | held |
| R8 nothing else changes, MuJoCo's suite | Switch set against unset: no test changes | held |
| R9 the solver | On: no step at the iteration limit, no warning | held |

## What it shows

On an arm the probes never played, MuJoCo as released gives the same arm, in the same place, a different end for each
pose its file is written in, in all four constraints played: on contact up to 94 um apart, on a joint limit up to 113 um,
held by joint friction up to 25.6 mm (in one pose, creeping at 24.9 to 47.5 mm/s by writing), held by a `connect` up to 100 um. With
the switch on every writing ends in exactly the same place at exactly the same speed and creeps alike; every cube scene,
both suites and all of MuJoCo's tests are as released with it on, and every play and test with it off.

Not asked and not changed: a `weld`, which the patch also changes but no rig of this record plays; the creep itself of an
arm held by friction (finding F1), and, under the elliptic cone with noslip, the arm on contact still creeps at 97 to 207
um/s in every writing alike (as run 025 found noslip not holding that arm in one pose).
