# Study 6: the slip-aligned pyramid's third version, against MuJoCo's own cone in the same run

| | |
|---|---|
| Question | Studies 3 and 4's question on fresh scenes, with the moving floor bounded by MuJoCo's own pyramid against its elliptic cone along an axis, and the free cube by MuJoCo's elliptic cone on the same cube, both measured in the same run |
| Outcome | **31 of 32 rule lines held; the study does not hold.** The patch stays in design |
| Registered | [`PREREGISTRATION_06.md`](../../preregistrations/PREREGISTRATION_06.md), 15 October 2026, pushed with its runner before any play |
| Played | Once, as [run 031](../../validation/run_031_study_06/README.md), 15 October 2026 09:46 UTC, on Linux (the second cloud machine, 4 virtual CPUs) |
| Arms | MuJoCo 3.16.0 as released; the patched build with the switch unset; with it set; and, in a folder of its own, the release's elliptic cone on the moving floor and on the free cube, and its two cones on a still floor along x |
| Measured by | The Senua AI Robotics Core's measuring programs (`stop`, `creep`, `hover`), MuJoCo's own test suite, judged by `rule`; held to [Coulomb's law](../references.md#coulomb), [Popov 2010](../references.md#popov); the pyramid, [Stewart and Trinkle 1996](../references.md#stewart-trinkle), [Le Lidec et al. 2024](../references.md#le-lidec) |

## Why it was asked

Studies 3 and 4 failed, beyond Study 3's runner, only on fixed bounds that MuJoCo's own direction-free cone does not keep
on the scenes played. Run 023's README had proposed bounding the moving floor by the two cones' own difference along an
axis in the same run; this study did that, and took the elliptic cone's free cube in the same run as R11's reference. On
Study 4's numbers R11's drift line would have failed: the references are measured, not chosen to pass.

## The scenes

A cube of 1.05 kg, half-size 0.042 m, friction 0.48, slid at 0.95 m/s along 0, 12, 33, 57 and 78 degrees at 1.2 ms and
0.3 ms (Coulomb's distance 95,929 um); held with 0.74 and 0.91 of its limit; slid along x on floors moving so it slips at
20 and 42 degrees; free to turn, slid along the five; both contact suites; MuJoCo's own 3,492 tests.

## The result

| Rule | Measured | |
|---|---|---|
| R1 safe when off, plays | 102 of 102 files identical | held |
| R2 safe when off, MuJoCo's suite | 3,492 of 3,492 tests as released | held |
| R3 the defect is there | Released: 34% further along 33 and 57 degrees | held |
| R4 no direction | On: 95,567 um along all five at 1.2 ms, 96,021 at 0.3 ms | held |
| R5 no drift | On: 0 um | held |
| R6 Coulomb | On: 96,021 um against 95,929 | held |
| R7 the hold | On: 1,863 and 2,642 um/s along all five directions | held |
| R8 the released hold lets go | Released at 0.91 along 33 degrees: 593,305 um/s against 2,642 along 0 | held |
| R9 the moving floor, on | Within MuJoCo's own two cones' difference on three lines (0, 1, 2 steps against 1, 1, 2); **4 steps against 3** at 0.3 ms slipping at 42 degrees | **failed on one line** |
| R10 the moving floor, released | 45 to 364 steps from the elliptic cone | held |
| R11 free cube | On: spread 173 um against the elliptic cone's 4,070; drift 93 um against 365 | held |
| R12 the frame and the turned-contact tests | On: all five of MuJoCo's tests pass | held |
| R13 nothing else changes | On: 72 of 72 suite files identical; MuJoCo's suite changes only in the spinning box, by the stated lift | held |
| R14 the solver | On: no step at the limit, no warning, at most 7 iterations against 6 | held |

Across Studies 3, 4 and 6, everything the third version is for has held on three sets of fresh scenes; each study failed
by one or a few steps on the moving floor at the finer step (and Study 4 on its free cube), at the size of MuJoCo's own
two cones' difference there. The lift is not a rule and is not corrected: on, the cube lifts 212 um at 1.2 ms along every
direction, against the release's 190 to 212.
