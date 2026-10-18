# Run 012: the first registered study, played once

Played 15 October 2026 (01:07 UTC, `played_at.txt`) on run 002's Linux machine, by [`play.sh`](play.sh), under
[`preregistrations/PREREGISTRATION_01.md`](../../preregistrations/PREREGISTRATION_01.md), pushed before any play.
Three arms (`stock/`, `off/`, `on/`): MuJoCo 3.16.0 as released, the patched build with the switch unset, and with
`MUJOCO_SLIP_ALIGNED_PYRAMID=1`. Every number a rule reads is in `measured.txt`; every rule's line, as `sx_contact rule`
judged it, in `rules.txt`.

**The result: all 17 rule lines held.** The slip-aligned pyramid is validated on this registration's scenes.

| Rule | Numbers | |
|---|---|---|
| R1 safe when off | 109 of 109 files byte-identical to stock | held |
| R2 the defect is there | Stock, 1 ms: 93,035 um along 0 degrees, 121,062 along 30 and along 60 (30% further; at least 15% registered) | held |
| R3 no direction, slide | On: 93,035 um along every direction at 1 ms, 93,343 at 0.25 ms | held |
| R4 no drift | On: 0 um along every direction, both steps | held |
| R5 Coulomb | On, 0.25 ms: 93,343 um along every direction, against 93,295 (0.05% long; 1% registered) | held |
| R6 no direction, hold | On: creep 965 um/s at 0.65 and 1,575 at 0.85, the same along 0, 30 and 60 degrees | held |
| R7 the stock hold lets go | Stock at 0.85: 303,791 um/s along 30 degrees against 1,575 along 0 degrees | held |
| R8 free cube | On: 93,170 um along 30 and 60 degrees against 93,048 along 0 (0.13%), drift 130 um | held |
| R9 nothing else changes | On: 71 of 71 files of both contact suites byte-identical to stock | held |
| R10 the solver | On: no step at the iteration limit, no warning; at most 7 iterations on a step, against 6 for stock (2 allowed) | held |

Stock, for the record of the defect on these scenes: along 15 and 75 degrees the level cube slides 102,034 um and
leaves its line by 20,687 um; along 30 and 60 degrees it leaves it by 22,720 um; the free cube slides 122,313 um along
30 and 60 degrees and leaves its line by 18,091 um.

The dry run (`dry/`, stock only, throwaway parameters) ran to the end and wrote every measured line; no rule was read
from it. Its pushes were sized for a friction of 0.5 while its friction was 0.4, a slip in the throwaway parameters
that touches nothing the study read.

## What it shows

On a cube, friction, speed, steps and directions the probes did not use, MuJoCo as shipped gives friction a direction
(30% further and 23 mm off line along 30 degrees; a hold lost at 0.85 of its limit), and the slip-aligned pyramid
removes it entirely for a level cube and to within 0.13% for a cube free to turn, with nothing else changed and the
release unchanged when off. Its only cost seen: one more solver iteration on the busiest step.

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 93,035 um | 93,049 um |
| 93,048 um | 93,063 um |
| 93,170 um | 93,184 um |
| 93,343 um | 93,362 um |
| 102,034 um | 102,051 um |
| 121,062 um | 121,079 um |
| 122,313 um | 122,330 um |

Every rule line of the study whose inputs the correction changes was judged again by `sx_contact rule` with the
corrected readings ([`rejudge.txt`](../audit/measure_correction/rejudge.txt)): no verdict changes.
