# Study 1: friction without a direction

| | |
|---|---|
| Question | Does MuJoCo's default friction cone give friction a direction on scenes the probes did not use, and does the slip-aligned pyramid remove it, with nothing else changed and MuJoCo unchanged when it is off? |
| Outcome | **17 of 17 rule lines held.** The patch is validated |
| Registered | [`PREREGISTRATION_01.md`](../../preregistrations/PREREGISTRATION_01.md), 15 October 2026, pushed before any play |
| Played | Once, as [run 012](../../validation/run_012_study_01/README.md), 15 October 2026 01:07 UTC, on Linux (EC2 c7i.large) |
| Arms | MuJoCo 3.16.0 as released; the patched build with the switch unset; with it set |
| Measured by | The Senua AI Robotics Core's measuring programs (`stop`, `creep`), judged by their `rule` command; held to [Coulomb's law](../references.md#coulomb), [Popov 2010](../references.md#popov); the pyramid, [Stewart and Trinkle 1996](../references.md#stewart-trinkle), [Le Lidec et al. 2024](../references.md#le-lidec) |

## The scenes

A cube of 1.4 kg, half-size 0.04 m, friction 0.35 (none of these numbers used in the probes): slid at 0.8 m/s along
0, 15, 30, 60 and 75 degrees at 1 ms and 0.25 ms (Coulomb's distance 93,294.5 um); held with 0.65 and 0.85 of its
limit along 0, 30 and 60 degrees; free to turn, slid along 0, 30 and 60 degrees; and both of the first deep dive's
contact suites.

## The result

| Rule | Measured | |
|---|---|---|
| R1 safe when off | 109 of 109 files byte-identical | held |
| R2 the defect is there | Released: 93,035 um along 0 degrees, 121,062 along 30 and 60 | held |
| R3 no direction | Patched: 93,035 um along all five directions at 1 ms, 93,343 at 0.25 ms | held |
| R4 no drift | Patched: 0 um along all five directions | held |
| R5 Coulomb | Patched: 93,343 um against 93,295 | held |
| R6 the hold | Patched: 965 and 1,575 um/s along all three directions | held |
| R7 the released hold lets go | Released at 0.85: 303,791 um/s along 30 degrees, 1,575 along 0 | held |
| R8 a cube free to turn | Patched: 93,170 um against 93,048, drift 130 um | held |
| R9 nothing else changes | Patched: 71 of 71 suite files byte-identical | held |
| R10 the solver | No step at the limit, no warning, at most 7 iterations against 6 | held |
