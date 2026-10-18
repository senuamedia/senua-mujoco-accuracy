# Run 030: the fifth registered study, played once

Played 15 October 2026 (09:27 UTC, `played_at.txt`) on the cloud machine (2 virtual CPUs), by [`play.sh`](play.sh),
under [`preregistrations/PREREGISTRATION_05.md`](../../preregistrations/PREREGISTRATION_05.md), pushed before any play.
The inverse weight in the current pose (`patches/in_design/invweight_at_pose.diff`, sha256 3f471edca6159277...), rebuilt
by the runner from the registered patch file, against Google DeepMind's Linux release, with MuJoCo's own test suite run
on and off. Every measured number is in `measured.txt`, every rule's line in `rules.txt`. The dry run (`dry/`, the release
only, run 025's arm and run 026's cubes) ran to the end and wrote all 57 measured lines; no rule was read from it.

**The result: 86 of 86 rule lines held. The study holds: the patch is validated for what this registration asks.**

| Rule | Measured | |
|---|---|---|
| R1 safe when off, plays | 192 of 192 files byte-identical to the release | held |
| R2 safe when off, MuJoCo's suite | All 3,492 tests as the release | held |
| R3 the defect is there | Released, MuJoCo's defaults: the arm written straight ends 42,835 to 43,648 nm from the native writing in pose C and 6,024 to 6,385 nm in pose D, both scenes, both steps (8 lines) | held |
| R4 correct, place | On, both configurations: every straight and folded writing ends **0 nm** from the native, every pose, scene and step (32 lines) | held |
| R5 correct, speed | On: **0 um/s** apart, every line (32 lines) | held |
| R6 correct, creep | On, the rest scene: 175 and 174 um/s in pose C, 521 in pose D, the same in all three writings (8 lines) | held |
| R7 nothing else changes, plays | On: 143 of 143 files of both suites, the stacks, the slides and the grips byte-identical to the release | held |
| R8 nothing else changes, MuJoCo's suite | Switch set against unset: no test changes | held |
| R9 the solver | On: no step at the iteration limit, no warning | held |

**MuJoCo's suite on this machine.** `XMLReaderTest.LargeTextureAddressTest` was killed by the kernel for memory in all
three arms (the machine has 3.8 GB and no swap, as in runs 024 and 029), so it reads the same in each and R2 and R8
compare like with like.

## What it shows

On an arm the probes never played, MuJoCo as released ends the same arm, in the same place, 2.0 to 97 um apart
depending only on the pose its file was written in (2.0 to 43.6 um under its defaults, 4.2 to 97 um under the elliptic
cone with noslip), and it creeps at 112 to 175 um/s in one pose and 367 to 557 in the other by writing. With the switch
on, every writing ends in exactly the same place at exactly the same speed, under both configurations, at both steps,
and creeps alike (175 and 174 um/s; 521). Every cube scene, both of the first deep dive's suites and all of MuJoCo's own
tests are as released with the switch set, and every play and test is as released with it unset.

The patch is validated for contacts, which is what it changes. Joint limits and joint friction keep their weights from
`qpos0` under it; run 032 found the same effect on a joint limit, and the second version, which takes those in the
current pose too, is in design (run 033).
