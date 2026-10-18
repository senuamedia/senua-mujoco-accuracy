# Study 4: the slip-aligned pyramid's third version, on fresh scenes

| | |
|---|---|
| Question | Study 3's question again on scenes never used in the record, with its runner's accounting corrected and R9's bound set from what run 023's diagnostic measured of MuJoCo's two cones |
| Outcome | **29 of 32 rule lines held; the study does not hold.** The patch stays in design |
| Registered | [`PREREGISTRATION_04.md`](../../preregistrations/PREREGISTRATION_04.md), 15 October 2026, pushed with its runner before any play |
| Played | Once, as [run 024](../../validation/run_024_study_04/README.md), 15 October 2026 07:57 UTC, on Linux (EC2 c7i.large) |
| Arms | MuJoCo 3.16.0 as released; the patched build with the switch unset; with it set; and, in a folder of its own, the release's elliptic cone on the moving floor as the reference, with the two cones on a still floor reported |
| Measured by | The Senua AI Robotics Core's measuring programs (`stop`, `creep`, `hover`), MuJoCo's own test suite, judged by `rule`; held to [Coulomb's law](../references.md#coulomb), [Popov 2010](../references.md#popov); the pyramid, [Stewart and Trinkle 1996](../references.md#stewart-trinkle), [Le Lidec et al. 2024](../references.md#le-lidec) |

## What changed from Study 3, and why

Study 3 failed R1 in its runner's accounting and R9 by a bound tighter than MuJoCo's two cones agree. Its registration
and verdict stand. This registration changed two things before any of its data existed: the elliptic reference plays
moved to a folder of their own, so the three arms make the same plays; and R9's bound became 3 steps, the largest
difference run 023's diagnostic measured between MuJoCo's own pyramid and elliptic cone with no direction in play.
Every other rule was Study 3's, on fresh scenes.

## The scenes

A cube of 1.15 kg, half-size 0.038 m, friction 0.62 (none of these numbers used before): slid at 0.85 m/s along 0, 25,
50, 70 and 85 degrees at 1.5 ms and 0.375 ms (Coulomb's distance 59,455 um); held with 0.76 and 0.93 of its limit
along the same five; slid along x on floors moving along y so it slips at 25 and 50 degrees; free to turn, slid along
the five; both contact suites; and MuJoCo's own 3,492 tests.

## The result

| Rule | Measured | |
|---|---|---|
| R1 safe when off, plays | 102 of 102 files identical, the statistics file included | held |
| R2 safe when off, MuJoCo's suite | 3,492 of 3,492 tests as released | held |
| R3 the defect is there | Released: 24% further along 25 degrees, 40% along 50 | held |
| R4 no direction | On: 59,065 um along all five directions at 1.5 ms, 59,586 at 0.375 ms | held |
| R5 no drift | On: 0 um | held |
| R6 Coulomb | On: 59,586 um against 59,455 | held |
| R7 the hold | On: 2,841 and 3,973 um/s along all five directions | held |
| R8 the released hold lets go | Released at 0.93 along 50 degrees: 931,592 um/s against 3,973 along 0 | held |
| R9 the moving floor, on | Within 3 steps of the elliptic cone on three lines; **4 steps** on the fourth, at 0.375 ms | **failed on one line** |
| R10 the moving floor, released | 30 to 234 steps from the elliptic cone | held |
| R11 free cube | On: **within 1.23%**, against 1%; drift **up to 1,176 um**, against 1,000 | **failed** |
| R12 the frame and the turned-contact tests | On: all five of MuJoCo's tests pass | held |
| R13 nothing else changes | On: 72 of 72 suite files identical; MuJoCo's suite changes only in the spinning box, by the stated lift | held |
| R14 the solver | On: no step at the limit, no warning, at most 7 iterations against 6 | held |

Both failures are bounds MuJoCo's own direction-free cone does not keep on these scenes. The registration's reported
control found MuJoCo's two cones 4 and 5 steps apart along x at 0.375 ms with no direction in play, where R9 allowed 3.
A diagnostic after the study, changing no verdict, found MuJoCo's elliptic cone spreading the same free cube by 3.7% and
drifting it 917 um, where R11 allowed 1% and 1,000 um; the released pyramid spreads it by 39% and drifts it 14.0 mm.
The lift is not a rule and is not corrected: on, the cube lifts 318 um at 1.5 ms along every direction, against the
release's 137 to 318.
