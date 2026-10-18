# Study 17: MuJoCo's own frictionless contact, condim 1

| | |
|---|---|
| Question | On numbers no earlier study or probe used, under MuJoCo's defaults and under Senua AI's configuration: does a cube set sliding on a condim-1 contact keep its speed and its line and stay on the ground, along every direction played, kept from turning and free to turn? Does the same cube on a condim-3 ground of friction 0 lose speed to MuJoCo's least friction? |
| Outcome | **12 of 12 rule lines held.** With condim 1, every slide lost 0 um/s, ended 0 um off its line, and never left the ground. With condim 3 and friction 0, every slide lost speed, 196 um/s along an axis, exactly what a friction of 1e-5 takes in 2 s. **Issue 12 is fixed and validated by configuration.** |
| Registered | [`PREREGISTRATION_17.md`](../../preregistrations/PREREGISTRATION_17.md), pushed with its runner, dry run and rules plumbing check at 02:57 UTC on 17 October 2026, before any play |
| Played | Once, as [run 080](../../validation/run_080_study_17/README.md), 17 October 2026, 02:58 UTC, on Linux (the first cloud machine) |
| Arms | MuJoCo 3.16.0 as released, under MuJoCo's defaults and under Senua AI's configuration; no build and no patch |
| Measured by | The contact rig's own columns and fields, and the Senua AI Robotics Core's `hover` and `rule`; held to [Coulomb's law](../references.md#coulomb); MuJoCo's soft constraints, [Todorov 2014](../references.md#todorov-2014) |

## Why it was asked

MuJoCo raises any friction below 1e-5 to 1e-5 under its default contact, condim 3 (`mjMINMU`). So a "frictionless"
ground took 1,250 ppm of two cubes' momentum in run 008, exactly 1e-5 of their weight over the play. MuJoCo's
documented frictionless contact is condim 1, a normal-only contact. Run 009 found it keeping the two cubes' momentum
within the files' rounding, but that was a probe on one scene.

## The rules and what they read

| Rule | Reading | Held |
|---|---|---|
| Q1 the least friction slows it | condim 3: 139 to 196 um/s lost in every slide, against at least 98 | 2 of 2 |
| F1 it keeps its speed | condim 1: 0 um/s lost in all 12 slides of each arm | 2 of 2 |
| F2 it keeps its line | condim 1: 0 um off its line | 2 of 2 |
| F3 it stays on the ground | condim 1: 0 um above it | 2 of 2 |
| V1 the solver | never at the limit, no warning | 4 of 4 |

## What it decides

- **Issue 12: fixed and validated by configuration.** A frictionless contact is MuJoCo's own condim 1, under MuJoCo's
  defaults and under Senua AI's configuration.
- A friction of 0 under condim 3 stays 1e-5, by MuJoCo's design. Under the default pyramidal cone, that least friction
  also depends on the slide's direction (139 to 196 um/s, issue 2's), and under the elliptic cone it does not.
- Not decided: condim 1 between two moving bodies (run 009, a probe), the patches' arms, anything against a real robot.
