# Second pre-registration: MuJoCo's recommended configuration, the elliptic cone with noslip

Registered 15 October 2026, after design probes (runs 001, 003, 008, 013, 014). Registered before any play of this
registration existed. Played once, as run 015.

## The question

MuJoCo as released creeps under any load inside the friction limit (run 001) and, with its default cone, gives
friction a direction (runs 003, 005; Study 1). Its own options, the elliptic cone with noslip iterations, removed both
in the design probes and passed the first deep dive's ten contact tests (runs 008, 014). On scenes the probes did not
use: does MuJoCo as released still creep; with the elliptic cone and 10 noslip iterations, does every hold hold, every
slide go Coulomb's distance whatever its direction, and every one of the ten tests pass, at no cost to the solver?

## Engines and arms

- **released**: Google DeepMind's Linux release of MuJoCo 3.16.0, MuJoCo's own defaults.
- **recommended**: the same release with `cone=elliptic` and `noslip_iterations=10` (the rigs' `cone=elliptic
  noslip=10`), nothing else changed.

Rigs as committed at this registration (`tools/mjc_contact.c`); measured by Senua AI's `sx_contact` and judged by its
`rule`; the suite read by the first deep dive's runner.

## The scenes, registered parameters

None of these numbers was used in the probes.

- **The cube**: 1.6 kg, half-size 0.045 m, friction 0.45, held level.
- **The hold**: pushed from 0.4 s with 0.5, 0.75 and 0.95 of what friction can hold (7.056 N: 3.528, 5.292 and
  6.7032 N) along 0, 30 and 60 degrees, 1.6 s, at 2 ms and 0.5 ms.
- **The slide**: set sliding at 1.1 m/s along 0, 30 and 60 degrees, 1.2 s, at 2 ms and 0.5 ms. Coulomb's distance:
  1.1^2 / (2 x 0.45 x 9.8) = 137,188 um.
- **The ten tests**: the first deep dive's suite 1 on a fresh cube (`SUITE_CUBE="mass=1.6 radius=0.045"`,
  `SUITE_H0=0.09`, `SUITE_VX=3`, `SUITE_VXCHAIN=1.2`, `SUITE_MU=0.45`, `SUITE_VSLIDE=4`, `SUITE_MUHOLD=0.4`,
  `SUITE_HOLD=3.7632` (0.6 of its limit), `SUITE_SLIP=7.5264` (1.2 of it), `SUITE_LIFT=47.04` (three times its weight);
  read with `SUITE_MU10K=4500`, `SUITE_SLIPMN=7526`).

## The rules

| Rule | Statement | Kind |
|---|---|---|
| R1 the defects are there | Released: the hold at 0.5 along 0 degrees, 2 ms, creeps at least 100 um/s; the slide along 30 degrees, 2 ms, goes at least 15% further than along 0 degrees | ge; share |
| R2 every hold holds | Recommended: all 18 holds (three pushes, three directions, two steps) creep at most 10 um/s | all_le |
| R3 no direction | Recommended, each step: the slides along 30 and 60 degrees within 1 part in 10,000 of the slide along 0 degrees | all_within |
| R4 Coulomb | Recommended, 0.5 ms: all three slides within 1 part in 100 of 137,188 um | all_within |
| R5 the ten tests | Recommended: 10 of 10; released: T06 (the hold) fails | eq; eq |
| R6 the solver | Recommended, over every play: no step at the iteration limit, no warning, and the most iterations on any step no more than the released arm's most plus 3 | eq; eq; le_plus |

The study holds if every rule holds. A rule that fails is reported as failed, with its numbers.

## What is not asked

The chain's energy under Euler (run 007) is not touched by the cone and is not part of this configuration; the lift of
a sliding body (run 008) is not asked.

## Dry run

The study's runner is new. It is played once before the study on the released arm only with throwaway parameters
(run 001's cube), only to check that it runs to the end and writes every measured line; no rule is read from it.
