# Run 023: the third registered study, played once

Played 15 October 2026 (05:25 UTC, `played_at.txt`) on the cloud machine, by [`play.sh`](play.sh), under
[`preregistrations/PREREGISTRATION_03.md`](../../preregistrations/PREREGISTRATION_03.md), pushed before any play. The
slip-aligned pyramid's third version (`patches/in_design/slip_aligned_pyramid_v3.diff`, sha256 58a65674e1c61dd9...),
rebuilt by the runner from the registered patch file, against Google DeepMind's Linux release, with MuJoCo's own test
suite run on and off. Every measured number is in `measured.txt`, every rule's line in `rules.txt`. The dry run
(`dry/`, the release only, throwaway parameters) ran to the end and wrote all 34 measured lines; no rule was read from
it.

**The result: 29 of 32 rule lines held. The study does not hold, and the patch stays in design.** Two rules failed as
written, for reasons stated below: R1 because of the runner, R9 by one step more than it allowed.

| Rule | Measured | |
|---|---|---|
| R1 safe when off, plays | 101 of 102 files byte-identical | **failed** |
| R2 safe when off, MuJoCo's suite | All 3,492 tests as the release, `doc_test` included | held |
| R3 the defect is there | Released, 1.5 ms: 104,804 um along 40 degrees and 92,392 along 65, against 74,747 along 0 (40% and 24% further) | held |
| R4 no direction, slide | On: 74,747 um along all five directions at 1.5 ms, 75,243 at 0.375 ms | held |
| R5 no drift | On: 0 um along every direction, both steps | held |
| R6 Coulomb | On, 0.375 ms: 75,243 um against 75,139 (0.14%) | held |
| R7 no direction, hold | On: 2,482 um/s at 0.78 and 3,038 at 0.88 of the limit, along all five directions | held |
| R8 the released hold lets go | Released at 0.88 along 40 degrees: 638,509 um/s against 3,038 along 0 | held |
| R9 the moving floor, on | On: 198 and 197, 253 and 253 steps at 1.5 ms, against the elliptic cone's; **810 and 808, 1,034 and 1,032 at 0.375 ms** | **failed at 0.375 ms** |
| R10 the moving floor, released | Released: 51 to 303 steps away from the elliptic cone's | held |
| R11 free cube | On: 75,583, 75,421, 75,042 and 74,998 um along 20 to 80 degrees against 74,880 along 0 (within 0.94%); drift at most 595 um | held |
| R12 the frame and the turned-contact tests | On: `ContactStage`, `ContactVelocity`, `SleepingUnaffectedByWaking`, `FoldDenseBlocksSolveMatches`, `DiscreteStiffLegPress` pass | held |
| R13 nothing else changes | On: 72 of 72 suite files byte-identical; in MuJoCo's suite only `InverseTest.DiscreteInverseFreeBody` changes (the lift) | held |
| R14 the solver | On: no step at the limit, no warning, at most 7 iterations against 5 released | held |

## The two rules that failed

**R1, by the runner.** The one file that differs is the release arm's statistics file, `runs/stats.txt`, and its only
difference is four lines: the elliptic cone's reference plays on the moving floor, which only the release arm plays.
The runner left those plays' files out of R1 but not their lines in the shared statistics file. Every play file the off
arm made is byte-identical to the release's, and so is every other line of the statistics file (the off arm's is kept
as `off/stats.txt`). R1 failed as it was written; the patch did not change a play with its switch unset.

**R9, by one step at the finer step.** On the moving floor the aligned pyramid stops 2 steps after MuJoCo's elliptic cone
at 0.375 ms, where the rule allowed 1; at 1.5 ms it is within 1. A diagnostic after the study
([`diag_r9.sh`](diag_r9.sh), `diag_r9.txt`, pushed before its plays, changing no verdict) slid the same cube along x on a
still floor, the pyramid's own axis, where the pyramid has no direction: the release's pyramid stops 1 to 3 steps after
the elliptic cone there too (200 and 198, 257 and 256 at 1.5 ms; 815 and 813, 1,048 and 1,045 at 0.375 ms). The two
cones differ by that much with no direction in play, so the rule's bound was tighter than the two cones' own difference.
The released pyramid on the same moving floor is 51 to 303 steps away.

## What it shows

With the switch on, every direction slides, holds and stops alike: no direction, no drift, Coulomb's distance within
0.14%, the holds the release loses kept, a moving floor within 2 steps of MuJoCo's own direction-free cone where the
release is 51 to 303 away, the frame and its sensors as released, and every one of MuJoCo's tests as before but the
one the lift explains. With it unset, all 3,492 of MuJoCo's tests and every play are as released. Two rules failed as
written, neither by the patch's physics as far as the diagnostics show; under the registration the study does not hold,
and the third version stays in design.

**The lift, reported:** with the switch on the cube lifts as much along every direction as along x: 390 um at 1.5 ms
along all five, against the release's 390, 298, 311, 154 and 363; 54 um at 0.375 ms, against 54, 31, 34, 34 and 55. As
stated in the registration, this version does not correct it.

A next registration would compare the off arm's plays file by file only for the plays both arms make, and bound the
moving floor by the two cones' own difference along an axis, measured in the same run.

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 74,747 um | 74,756 um |
| 74,880 um | 74,892 um |
| 74,998 um | 75,006 um |
| 75,042 um | 75,053 um |
| 75,243 um | 75,258 um |
| 75,421 um | 75,430 um |
| 75,583 um | 75,598 um |
| 92,392 um | 92,406 um |
| 104,804 um | 104,819 um |

Every rule line of the study whose inputs the correction changes was judged again by `sx_contact rule` with the
corrected readings ([`rejudge.txt`](../audit/measure_correction/rejudge.txt)): no verdict changes.
