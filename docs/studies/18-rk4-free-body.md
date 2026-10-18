# Study 18: MuJoCo's RK4 integrator, for a free body's energy

| | |
|---|---|
| Question | On numbers no earlier study or probe used: does RK4 keep a free chain's energy and angular momentum, and a tumbling body's, at every step played, where MuJoCo's default integrator does not? |
| Outcome | **7 of 7 rule lines held.** RK4 kept the free chain's energy and angular momentum to 1 ppm and the tumbling body's to 0, at 6.25 ms and a quarter, a sixteenth and a sixty-fourth of it. Euler, MuJoCo's default, drifted 65,518 and 9,625 ppm at 6.25 ms, in proportion to the step. **Issue 11 is fixed and validated by configuration.** |
| Registered | [`PREREGISTRATION_18.md`](../../preregistrations/PREREGISTRATION_18.md), pushed with its runner, dry run and rules plumbing check at 03:04 UTC on 17 October 2026, before any play |
| Played | Once, as [run 081](../../validation/run_081_study_18/README.md), 17 October 2026, 03:05 UTC, on Linux (the first cloud machine) |
| Arms | MuJoCo 3.16.0 as released, under each of its four integrators; no build and no patch |
| Measured by | The Senua AI Robotics Core's `chain`, `tumble` and `rule`; held to [Landau and Lifshitz](../references.md#landau); the integrators, [Hairer, Lubich and Wanner](../references.md#hairer-gni), [Hairer, Norsett and Wanner](../references.md#hairer-ode) |

## Why it was asked

With nothing acting on it, a body's energy and angular momentum must stay what they were, whatever the step. Under
MuJoCo's default integrator a free two-link chain gains 9.7% of its energy in 2 s at 10 ms (run 007), because the
Coriolis and centripetal forces are taken once, at the step's start (F4). Study 9 found RK4 keeping a tumbling body's
energy, and runs 007 and 014 found it keeping a free chain's, as probes.

## The rules and what they read

| Rule | Reading | Held |
|---|---|---|
| Q1, Q2 the default integrator drifts | Euler at 6.25 ms: the chain's energy 65,518 ppm, the tumbling body's 9,625 | 2 of 2 |
| R1, R2 RK4 keeps the free chain | energy and angular momentum within 1 ppm at every step | 2 of 2 |
| R3, R4 RK4 keeps the tumbling body | energy and angular momentum 0 at every step | 2 of 2 |
| V1 no warning | none | 1 of 1 |

## What it decides

- **Issue 11: fixed and validated by configuration.** MuJoCo's own RK4 keeps a free body's energy and angular
  momentum, a free chain and a tumbling body, at every step played. MuJoCo's default integrator, implicitfast and
  implicit do not.
- Under gravity, RK4 kept the swinging chain's total energy to 1,702 ppm at 6.25 ms and to 3 ppm or less at the finer
  steps (reported). A body under gravity or in contact is not decided here.
- RK4's costs the record has seen stay as recorded: the first suite's T01 cannot be read under it (Study 10), and
  under it the stacks tilt at 1.14 ms (run 068, not with the collinear patch played).
