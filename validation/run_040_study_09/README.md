# Run 040: the ninth registered study, played once

Played 15 October 2026 (21:12 to 21:33 UTC, `played_at.txt`, `progress.txt`) on the first cloud machine (2 virtual CPUs,
3.8 GB), by [`play.sh`](play.sh), under [`preregistrations/PREREGISTRATION_09.md`](../../preregistrations/PREREGISTRATION_09.md),
pushed before any play. The inverse weight in the current pose, third version (`patches/invweight_at_pose_v3.diff`,
`patch_check.txt`), rebuilt by the runner from the registered patch file, against Google DeepMind's Linux release, with
MuJoCo's own test suite run on and off. The numbers are drawn from seed 9 (`draw.txt`, `parameters.txt`): an arm of
links 0.273 and 0.267 m, 1.023 and 0.519 kg, a ball of 0.0271 m and 0.161 kg, held by a `weld` in poses (0.197, 0.627)
and (0.305, 0.961), written in its own pose, straight and folded (0, 2.234), at 1.63 ms and 0.4075 ms; a free body of
principal moments 0.011372, 0.009324 and 0.007512 kg m2 spinning at (2.52, 2, -0.83) rad/s along its own axes. Every
measured number is in `measured.txt`, every rule's line in `rules.txt`. The dry run (`dry/`, the release only, run
039's arm, poses and body) ran to the end; no rule was read from it.

**The result: 46 of 58 rule lines held. Part A held all 26: the third version is validated for a `weld`. Part B held
20 of 32: RK4 keeps a free tumbling body's energy and angular momentum at every step; Euler, implicitfast and implicit
each hold 4 of their 8 lines.**

## Part A: the weld

| Rule | Measured | |
|---|---|---|
| R1 safe when off, plays | 101 of 101 files byte-identical to the release | held |
| R2 safe when off, MuJoCo's suite | Switch unset: every test gives the release's result (see the note below) | held |
| R3 the defect is there | Released, the straight writing ends 39,046 nm from the native in pose 1 and 79,970 nm in pose 2, at both steps (the folded writing 19,841 and 3,420 nm) | held |
| R4 correct, place | On: every straight and folded writing ends **0 nm** from the native, in each pose and step (8 lines) | held |
| R5 correct, speed | On: **0 um/s** apart, every line (8 lines) | held |
| R7 nothing else changes, plays | On: 88 of 88 files of both suites and the tumbling body byte-identical to the release | held |
| R8 nothing else changes, MuJoCo's suite | Switch set against unset: no test changes | held |
| R9 the solver | On: no step at the iteration limit, no warning | held |

## Part B: the free tumbling body

The largest drift over the 2 s, in parts per million of the start (`sx_tumble`), against T1's bounds for the energy
(5,000 at 10 ms, 1,000 at 2.5 ms, 500 at 0.625 and 0.15625 ms) and T2's for the angular momentum (100 at every step):

| Integrator | Energy: 10 ms | 2.5 ms | 0.625 ms | 0.156 ms | Angular momentum: 10 ms | 2.5 ms | 0.625 ms | 0.156 ms | Lines held |
|---|---|---|---|---|---|---|---|---|---|
| Euler (MuJoCo's default) | +4,170 | **+1,038** | +259 | +65 | **+1,662** | **+413** | **+103** | +25 | 4 of 8 |
| implicitfast | -4,110 | **-1,034** | -259 | -64 | **-1,640** | **-413** | **-104** | -26 | 4 of 8 |
| implicit | as implicitfast, to the part per million | | | | | | | | 4 of 8 |
| RK4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 8 of 8 |

The lines in bold failed. Euler gains energy and angular momentum, implicitfast and implicit lose them at about the
same rate, each falling four times with every fourfold smaller step, a first-order error; RK4 keeps both to the
measure's resolution at every step.

## Note: one of MuJoCo's tests ran out of memory in every arm

`XMLReaderTest.LargeTextureAddressTest` was killed by the system in all three arms (release, switch unset, switch set):
the kernel's log shows `xml_native_read` killed for memory at about 3.5 GB resident on this 3.8 GB machine. The other
3,491 tests passed in every arm. R2 and R8 compare the arms test by test, and that test reads the same in all three, so
neither rule's reading changes; in run 038, on a machine with more memory, it passed with the switch unset and set.

## What it shows

A `weld` is changed by finding F10 as a `connect` is: released, the same arm held in the same place ends up to 80 um
apart by how its file is written. With the third version on, every writing ends in exactly the same place at exactly
the same speed, and everything else plays as released. A free tumbling body, with nothing acting on it, keeps its energy
and angular momentum under RK4 and not under MuJoCo's other three integrators (known issue M10), whose error falls with
the step at first order.
