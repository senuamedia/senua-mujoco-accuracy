# Run 035: the seventh registered study, played once

Played 15 October 2026 (10:35 UTC, `played_at.txt`) on the second cloud machine (4 virtual CPUs; its release, measuring
program and plays the first machine's byte for byte, runs 031 and 033), by [`play.sh`](play.sh), under
[`preregistrations/PREREGISTRATION_07.md`](../../preregistrations/PREREGISTRATION_07.md), pushed before any play. The
inverse weight in the current pose, second version (`patches/in_design/invweight_at_pose_v2.diff`, sha256
0141e9bc36ff5bfc...), rebuilt by the runner from the registered patch file, against Google DeepMind's Linux release,
with MuJoCo's own test suite run on and off. Every measured number is in `measured.txt`, every rule's line in
`rules.txt`. The dry run (`dry/`, the release only, the arms of runs 025, 032 and 034 and run 026's cubes) ran to the end
and wrote all 85 measured lines; no rule was read from it.

**The result: 134 of 134 rule lines held. The study holds: the second version is validated for what this registration
asks, contacts, joint limits and joint friction.**

| Rule | Measured | |
|---|---|---|
| R1 safe when off, plays | 216 of 216 files byte-identical to the release | held |
| R2 safe when off, MuJoCo's suite | All 3,492 tests as the release (every one passed in all three arms) | held |
| R3 the defect is there | Released, the straight writing ends at least 1 um from the native in every scene, pose and step (16 lines): 2.1 to 89 um on contact, 104 um to 1.91 mm swinging on the limit, 1.05 to 21.2 mm held by joint friction, counting the folded writings too | held |
| R4 correct, place | On: every straight and folded writing ends **0 nm** from the native, in every scene, pose and step, and on contact under both configurations (48 lines) | held |
| R5 correct, speed | On: **0 um/s** apart, every line (48 lines) | held |
| R6 correct, creep | On: the same creep in all three writings (16 lines): on contact 186 and 592 um/s; held by joint friction 38,842 and 27,061 um/s at 1.25 ms (38,845 and 27,064 at 0.3125 ms) | held |
| R7 nothing else changes, plays | On: 143 of 143 files of both suites, the stacks, the slides and the grips byte-identical to the release | held |
| R8 nothing else changes, MuJoCo's suite | Switch set against unset: no test changes | held |
| R9 the solver | On: no step at the iteration limit, no warning | held |

## What it shows

On an arm the probes never played, MuJoCo as released gives the same arm, in the same place, a different end for each
pose its file is written in, in every constraint this study played: on contact up to 89 um, swinging on a joint limit
up to 1.9 mm, held by joint friction up to 21 mm, and, in one pose, its creep held by friction from 29.8 to 55.4 mm/s by writing. With
the switch on every writing ends in exactly the same place at exactly the same speed and creeps alike, under MuJoCo's
defaults and, on contact, under the elliptic cone with noslip; every cube scene, both suites and all of MuJoCo's tests
are as released with it on, and every play and test with it off.

What it does not change: the creep of an arm held by joint friction itself (finding F1), and equality constraints, which
the third version adds (run 036 found them affected; run 037 holds the third version to the five checks).
