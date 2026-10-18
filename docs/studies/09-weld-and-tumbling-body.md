# Study 9: the inverse weight on a weld, and a free tumbling body

| | |
|---|---|
| Question | Part A: on an arm the probes did not use, held by a `weld` equality, does MuJoCo as released end it differently for each pose its file is written in, and with the third version on does every writing end in the same place, everything else as released? Part B: does a free rigid body tumbling with nothing acting on it keep its energy and angular momentum under each of MuJoCo's integrators, at every step of the ladder (known issue M10)? |
| Outcome | **46 of 58 rule lines held.** Part A held all 26: **the third version is validated for a `weld`**. Part B held 20 of 32: **RK4 keeps the body's energy and angular momentum at every step (8 of 8)**; Euler, implicitfast and implicit each hold 4 of 8, a first-order error |
| Registered | [`PREREGISTRATION_09.md`](../../preregistrations/PREREGISTRATION_09.md), 16 October 2026, pushed with its runner before any play |
| Played | Once, as [run 040](../../validation/run_040_study_09/README.md), 15 October 2026 21:12 UTC, on Linux (the first cloud machine, 2 virtual CPUs) |
| Arms | MuJoCo 3.16.0 as released; the patched build with the switch unset; with it set |
| Measured by | The Senua AI Robotics Core's measuring programs (`ends`, `tumble`), MuJoCo's own test suite, judged by `rule`; held to [Landau and Lifshitz](../references.md#landau); the integrators, [Hairer, Lubich and Wanner](../references.md#hairer-gni), [Hairer, Norsett and Wanner](../references.md#hairer-ode) |

## Why it was asked

Study 8 validated the third version on contacts, joint limits, joint friction and a `connect`. A `weld` goes through the
same helper, and [run 039](../../validation/run_039_weld_and_tumble/README.md), a probe, found it affected too (up to
85 um apart by writing). Known issue M10, energy gained or lost by a free tumbling body, was the one reported issue the
record had not measured: it needed a rig for one free body and a measure of its energy and angular momentum.

## The scenes

Drawn from seed 9 (`draw.txt`): an arm of links 0.273 and 0.267 m, 1.023 and 0.519 kg, a ball of 0.0271 m and 0.161 kg,
held 1 m up by a `weld` in poses (0.197, 0.627) and (0.305, 0.961), written in its own pose, straight and folded (0,
2.234), at 1.63 ms and 0.4075 ms, 2 s. A free body of principal moments 0.011372, 0.009324 and 0.007512 kg m2, spinning
at (2.52, 2, -0.83) rad/s along its own axes, no gravity and nothing touching it, 2 s at 10 ms and 1/4, 1/16 and 1/64 of
it, under Euler, implicitfast, implicit and RK4. Its rotational kinetic energy and the size of its angular momentum
are read in the body's own frame by `sx_tumble`, in whole numbers.

## The result

**Part A, the weld: 26 of 26.** Released, the straight writing ends 39,046 nm from the native in pose 1 and 79,970 nm
in pose 2 at both steps. With the switch set every straight and folded writing ends **0 nm** and **0 um/s** from the
native. With it unset the patched build plays every file as released (101 of 101), and with it set both suites and the
tumbling body play as released (88 of 88); MuJoCo's own tests read the same switch set, unset and released; no step at
the iteration limit, no warning.

**Part B, the tumbling body: 20 of 32.** The largest drift over the 2 s, parts per million of the start:

| Integrator | Energy: 10 ms | 2.5 ms | 0.625 ms | 0.156 ms | Angular momentum: 10 ms | 2.5 ms | 0.625 ms | 0.156 ms | Lines held |
|---|---|---|---|---|---|---|---|---|---|
| Euler (MuJoCo's default) | +4,170 | **+1,038** | +259 | +65 | **+1,662** | **+413** | **+103** | +25 | 4 of 8 |
| implicitfast | -4,110 | **-1,034** | -259 | -64 | **-1,640** | **-413** | **-104** | -26 | 4 of 8 |
| implicit | as implicitfast | | | | | | | | 4 of 8 |
| RK4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 8 of 8 |

Bounds fixed before the play: the energy within 5,000, 1,000, 500 and 500 per million, the angular momentum within 100
at every step; the lines in bold failed.

One of MuJoCo's 3,492 tests, `XMLReaderTest.LargeTextureAddressTest`, was killed by the system for memory in all three
arms (about 3.5 GB on a 3.8 GB machine); it reads the same in every arm, so no comparison changes ([run 040](../../validation/run_040_study_09/README.md)).

## What it means

- **The third version is validated for a `weld`**, as for contacts, joint limits, joint friction and a `connect`: one
  arm in one place ends in one place, however its file is written.
- **MuJoCo's RK4 keeps a free tumbling body's energy and angular momentum at every step.** Its default integrator gains
  both, and implicitfast and implicit lose both, at first order in the step: 0.4% of the energy and 0.17% of the
  angular momentum in 2 s at 10 ms on this body. The cause, the gyroscopic force taken once at the step's start, is
  traced for the chain (finding F4); the failed lines are recorded as measured and M10 stays open for those three.
