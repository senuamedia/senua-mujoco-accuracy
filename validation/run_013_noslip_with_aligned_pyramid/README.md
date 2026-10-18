# Run 013: noslip with the pyramid turned along the slip

15 October 2026. Not registered: a design probe on run 002's Linux machine, by [`probe.sh`](probe.sh) (pushed before
its plays); reading `reading.txt`. Run 001 found that MuJoCo's noslip solver leaves the default (pyramidal) cone's
hold exactly as it was, while with the elliptic cone it removes the creep. Its pyramidal pass moves force only within
each pair of opposing pyramid edges (`engine_solver.c`). The question: does noslip hold the default cone once the
pyramid is turned along the slip (the validated patch, run 012)? Run 001's hold (1 kg, half-size 0.05 m, friction
0.5, pushed with 0.6 of the limit from 0.5 s, 2 ms), along x and along 30 degrees, with noslip 0, 10 and 100, on the
patched build with the switch off and on. The rig built against the patched build; the solver never reached its
iteration limit and raised no warning.

| Creep, um/s (right answer 0) | noslip 0 | noslip 10 | noslip 100 |
|---|---|---|---|
| Pyramidal, along x, patch off | 1,293 | 1,293 | 1,293 |
| Pyramidal, along x, patch on | 1,293 | 1,293 | 1,293 |
| Pyramidal, along 30 degrees, patch off | 1,024 | 782 | 782 |
| Pyramidal, along 30 degrees, patch on | 1,293 | 782 | 782 |
| Elliptic, along x | | 0 | |

## What it shows

**No: the hypothesis is refuted.** With the pyramid along the slip, noslip still does nothing along x and cuts the
creep along 30 degrees only to 782 um/s, as it does without the patch. The direction of the pyramid is not what keeps
noslip from holding a pyramidal contact; only the elliptic cone with noslip holds (0). A correction for the creep at
rest under the default cone needs something else, and stays open.
