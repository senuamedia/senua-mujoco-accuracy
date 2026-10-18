# Study 3: the slip-aligned pyramid's third version

| | |
|---|---|
| Question | On scenes the probes did not use, does the third version give friction no direction on a still floor and a moving one, keep the frame and every other result as released, and leave MuJoCo, play for play and test for test, as released when off? |
| Outcome | **29 of 32 rule lines held; the study does not hold.** The patch stays in design |
| Registered | [`PREREGISTRATION_03.md`](../../preregistrations/PREREGISTRATION_03.md), 15 October 2026, pushed before any play |
| Played | Once, as [run 023](../../validation/run_023_study_03/README.md), 15 October 2026 05:25 UTC, on Linux (EC2 c7i.4xlarge) |
| Arms | MuJoCo 3.16.0 as released; the patched build with the switch unset; with it set; on the moving floor, the release's elliptic cone as the reference |
| Measured by | The Senua AI Robotics Core's measuring programs (`stop`, `creep`, `hover`), MuJoCo's own test suite, judged by `rule`; held to [Coulomb's law](../references.md#coulomb), [Popov 2010](../references.md#popov); the pyramid, [Stewart and Trinkle 1996](../references.md#stewart-trinkle), [Le Lidec et al. 2024](../references.md#le-lidec) |

## The scenes

A cube of 1.3 kg, half-size 0.035 m, friction 0.55 (none of these numbers used before): slid at 0.9 m/s along 0, 20, 40,
65 and 80 degrees at 1.5 ms and 0.375 ms (Coulomb's distance 75,139 um); held with 0.78 and 0.88 of its limit along the
same five; slid along x on floors moving along y so it slips at 35 and 55 degrees; free to turn, slid along the five;
both contact suites; and MuJoCo's own 3,492 tests.

## The result

| Rule | Measured | |
|---|---|---|
| R1 safe when off, plays | 101 of 102 files identical: the release's statistics file also carries its four elliptic reference plays, which the runner did not leave out; every play file identical | **failed** |
| R2 safe when off, MuJoCo's suite | 3,492 of 3,492 tests as released, `doc_test` included | held |
| R3 the defect is there | Released: 40% further along 40 degrees, 24% along 65 | held |
| R4 no direction | On: 74,747 um along all five directions at 1.5 ms, 75,243 at 0.375 ms | held |
| R5 no drift | On: 0 um | held |
| R6 Coulomb | On: 75,243 um against 75,139 | held |
| R7 the hold | On: 2,482 and 3,038 um/s along all five directions | held |
| R8 the released hold lets go | Released at 0.88 along 40 degrees: 638,509 um/s against 3,038 along 0 | held |
| R9 the moving floor, on | Within 1 step of the elliptic cone at 1.5 ms; **2 steps at 0.375 ms**, where the rule allowed 1 | **failed** |
| R10 the moving floor, released | 51 to 303 steps from the elliptic cone | held |
| R11 free cube | On: within 0.94%, drift at most 595 um | held |
| R12 the frame and the turned-contact tests | On: all five of MuJoCo's tests pass | held |
| R13 nothing else changes | On: 72 of 72 suite files identical; MuJoCo's suite changes only in the spinning box, by the stated lift | held |
| R14 the solver | On: no step at the limit, no warning, at most 7 iterations against 5 | held |

A diagnostic after the study, changing no verdict, found MuJoCo's pyramid and elliptic cone 1 to 3 steps apart on a
still floor along the pyramid's own axis, where there is no direction: R9's bound was tighter than the two cones' own
difference. The lift is not a rule and is not corrected: on, the cube lifts 390 um at 1.5 ms along every direction,
against the release's 154 to 390.
