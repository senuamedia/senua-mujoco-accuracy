# Run 087: Study 20, the friction solve dropping a direction at noslip's floor

17 October 2026 (04:35 to 04:49 UTC). The twentieth registered study,
[`PREREGISTRATION_20.md`](../../preregistrations/PREREGISTRATION_20.md), played once on the first cloud machine by
[`play.sh`](play.sh), the runner as registered (sha256 ad2bc4b824e541de...), from an archive of the registration's commit
(2253128). The rule lines are in [`rules.txt`](rules.txt), the readings in [`measured.txt`](measured.txt), the draw in
[`draw.txt`](draw.txt).

## Result: 13 of 14 rule lines held; H1 failed

What the second version was written for, it does. A cube held from turning, with condim 4 or 6, holds in every play
with the second version in Senua AI's set. Released and with the first version, it creeps:

| Creep, um/s, at 0.5, 0.75 and 0.95 of the limit, along each of 0, 22.5 and 45 degrees, at both steps | Released | The set, first version | **The set, second version** |
|---|---|---|---|
| Cube a (1.572 kg, half-size 0.0474 m, friction 0.61), held from turning, condim 4 or 6 | 779, 1,168, 1,479 | 779, 1,168, 1,479 | **0, 0, 0** |
| Cube b (0.819 kg, half-size 0.0316 m, friction 0.734), held from turning, condim 4 or 6 | 937, 1,405, 1,780 | 937, 1,405, 1,780 | **0, 0, 0** |

Q1 and Q2 held (1,780 and 1,479 um/s). N1 held: of the 222 play files compared, every one is byte-identical between the
two versions. That covers the arms, the grips, the boxes, the condim-3 holds and the free cubes. R1, G1 and B1 held:
every arm and every grip at most 10 um/s, every box at rest. With every switch unset, all 286 play files and all 3,492
of MuJoCo's tests are the release's (E1, E2, M0). With the five switches set, the only test that changes is
`SolverTest.ZeroToleranceDisablesTermination` (M1). Every play was measured (P0); no step at the iteration limit and
no warning (V1).

**H1 failed: a free cube pushed square to a face at 0.95 of its limit creeps.** It does so with condim 3, 4 and 6
alike. With either version the readings are the same, byte for byte (N1), and the release creeps more:

| Free cube, pushed along 0 degrees at 0.95 of the limit, creep in um/s | Released | The set, either version |
|---|---|---|
| Cube a, 1.277 ms (condim 3, 4, 6) | 1,458, 1,458, 1,448 | 613, 698, 699 |
| Cube a, 0.31925 ms | 598, 1,024, 558 | 173, 299, 299 |
| Cube b, 1.277 ms | 2,368, 2,367, 2,318 | 1,098, 1,124, 1,124 |
| Cube b, 0.31925 ms | 2,087, 2,226, 2,040 | 482, 763, 763 |

Every other hold of a free cube is at most 10 um/s in the set: at 0.5 and 0.75 of the limit, and along 22.5 and 45
degrees. Released, cube b also creeps at 0.75 along 0 degrees and at 0.95 along 22.5. No earlier study pushed a free
cube this hard: Study 15 held its cubes from turning, and run 084's free cube, with friction 0.39, held.

## What it decides

As registered, a failed rule leaves **issue 1 fixed in part**, and the second version stays in `patches/in_design/`.

What is now known about issue 1's open part:

- **A cube held from turning with condim 4 or 6** is held by the second version: all 72 such holds at 0 um/s. Of H1's
  216 holds, 204 held; the 12 that did not are the free cubes above. A registered study of the second version on its
  own claim is still to be played.
- **A free cube pushed square to a face near its limit** creeps in Senua AI's set, with condim 3 too. This is a new
  case of issue 1. It was not traced here, and is not decided.
