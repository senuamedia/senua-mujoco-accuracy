# Run 015: the second registered study, played once

Played 15 October 2026 (02:59 UTC, `played_at.txt`) on run 002's Linux machine, by [`play.sh`](play.sh), under
[`preregistrations/PREREGISTRATION_02.md`](../../preregistrations/PREREGISTRATION_02.md), pushed before any play. Two
arms on Google DeepMind's Linux release: **released** (MuJoCo's defaults) and **recommended** (the elliptic cone with 10
noslip iterations). Every number a rule reads is in `measured.txt`; every rule's line in `rules.txt`; the suite's plays
and readings under each arm's folder.

**The result: all 11 rule lines held.** The elliptic cone with noslip is validated as MuJoCo's recommended
configuration on this registration's scenes.

| Rule | Numbers | |
|---|---|---|
| R1 the defects are there | Released: the hold at 0.5 of the limit creeps 700 um/s; the slide along 30 degrees goes 177,631 um against 136,296 along 0 (30% further) | held |
| R2 every hold holds | Recommended: all 18 holds (0.5, 0.75 and 0.95 of the limit, along 0, 30 and 60 degrees, at 2 ms and 0.5 ms) creep 0 um/s | held |
| R3 no direction | Recommended: 136,256 um along every direction at 2 ms, 137,100 at 0.5 ms | held |
| R4 Coulomb | Recommended, 0.5 ms: 137,100 um against 137,188 (0.06% short) | held |
| R5 the ten tests | Recommended: 10 of 10; released: 9 of 10, the hold (T06) failing | held |
| R6 the solver | Recommended: no step at the limit, no warning, at most 5 iterations on a step against 4 released | held |

The released arm, for the record on these scenes: the hold creeps 700, 1,749 and 2,589 um/s at 0.5, 0.75 and 0.95 of
its limit along 0 degrees, the same at both steps; pushed along 30 degrees with 0.95 of the limit, it slides away at
0.72 m/s.

The dry run (`dry/`, released arm only, run 001's cube) ran to the end and wrote every measured line; no rule was read
from it. It played the suite's default scenes but read them with this study's constants, so its suite count (5 of 10)
means nothing, as no rule reads it.

## What it shows

Two options MuJoCo already has, the elliptic friction cone and 10 noslip iterations, remove both contact defects this
record found in MuJoCo as released, the creep at rest and the friction's direction, on scenes the probes never used,
and pass every one of the first deep dive's ten contact tests, for one more solver iteration on the busiest step. A
user can set them today. The chain's energy under Euler (run 007) and the lift of a sliding body (run 008) are not
touched by them.

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 136,256 um | 136,273 um |
| 136,296 um | 136,312 um |
| 137,100 um | 137,117 um |
| 177,631 um | 177,648 um |

Every rule line of the study whose inputs the correction changes was judged again by `sx_contact rule` with the
corrected readings ([`rejudge.txt`](../audit/measure_correction/rejudge.txt)): no verdict changes.
