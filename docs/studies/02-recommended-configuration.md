# Study 2: MuJoCo's recommended configuration, the elliptic cone with noslip

| | |
|---|---|
| Question | Do the elliptic cone and 10 noslip iterations, options MuJoCo already has, remove the creep at rest and the friction's direction on scenes the probes did not use, and pass all ten known-answer contact tests, at no cost to the solver? |
| Outcome | **11 of 11 rule lines held.** The configuration is validated |
| Registered | [`PREREGISTRATION_02.md`](../../preregistrations/PREREGISTRATION_02.md), 15 October 2026, pushed before any play |
| Played | Once, as [run 015](../../validation/run_015_study_02/README.md), 15 October 2026 02:59 UTC, on Linux (EC2 c7i.large) |
| Arms | MuJoCo 3.16.0 as released, with its defaults; the same with `cone="elliptic"` and `noslip_iterations="10"` |
| Measured by | The Senua AI Robotics Core's measuring programs (`creep`, `stop`), the first deep dive's suite runner, judged by `rule`; held to [Coulomb's law](../references.md#coulomb), [Popov 2010](../references.md#popov); MuJoCo's soft constraints, [Todorov 2014](../references.md#todorov-2014) |

## The scenes

A cube of 1.6 kg, half-size 0.045 m, friction 0.45 (none of these numbers used in the probes): held with 0.5, 0.75
and 0.95 of its limit along 0, 30 and 60 degrees, and slid at 1.1 m/s along the same, at 2 ms and 0.5 ms (Coulomb's
distance 137,188 um); and the first deep dive's ten contact tests on a fresh cube of the same size.

## The result

| Rule | Measured | |
|---|---|---|
| R1 the defects are there | Released: creeps 700 um/s at half its limit; slides 30% further along 30 degrees | held |
| R2 every hold holds | Recommended: 0 um/s on all 18 holds | held |
| R3 no direction | Recommended: the same distance along all three directions, to the micrometre | held |
| R4 Coulomb | Recommended: 137,100 um against 137,188 | held |
| R5 the ten tests | Recommended: 10 of 10; released: 9 of 10 (the hold fails) | held |
| R6 the solver | No step at the limit, no warning, at most 5 iterations against 4 | held |
