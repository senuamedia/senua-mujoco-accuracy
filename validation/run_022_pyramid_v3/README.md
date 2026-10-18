# Run 022: the slip-aligned pyramid's third version

15 October 2026. Not registered: a patch in design. Step 1 traces why MuJoCo's stiff leg-press test fails with the
second version switched on; step 2 holds the third version to the five checks and MuJoCo's whole suite, every check
stated in [`play.sh`](play.sh) before any play.

**The result: the third version passes all five checks and MuJoCo's whole suite.** With the switch unset MuJoCo's 3,492
tests give the release's result, test for test, `doc_test` included; with it set, the one test that changes is the
spinning box, by the lift this version does not correct, as stated before the plays. The way is open to a registered
study (Study 3).

## Step 1: the leg press ([`trace.sh`](trace.sh), [`legpress_trace.c`](legpress_trace.c), `trace/`)

`legpress_trace.c` plays the test's own scene (a stiff ">" leg pressed onto the floor, three springy joints) the way
the test plays it, against the second version's build, and logs every contact at every step. The test asserts that the
discrete integrator converges at first order: the error at the finer step is under 0.7 of the coarser's.

| Play | Coarse error | Fine error | Ratio | The test |
|---|---|---|---|---|
| Switch unset | 0.0100 | 0.0052 | 0.52 | passes |
| Switch set | 0.0133 | 0.0099 | 0.74 | fails |
| Switch set, no contact turned (diagnostic) | 0.0100 | 0.0052 | 0.52 | passes |
| Switch set, every slipping contact turned (diagnostic) | 0.0133 | 0.0099 | 0.74 | fails |

The reference play (implicitfast at 1e-4) ends the same in all four. **The cause:** the leg's one contact slides along
-x, and the release's frame has its first tangent along +x at every step. The second version turns the pyramid along
the slip: by exactly 180 degrees, at 238 of the 240 contact-steps (`frictionrot` -1, 0). A four-edge pyramid turned
by 180 degrees has the same four edges: the rows the solver gets are the release's, each pair's two rows swapped. That
swap alone moves the discrete integrator's endpoints, by 0.8 mm on the slide joint and 3.2 mrad on the hip at the
coarse step, and the convergence ratio from 0.52 to 0.74.

So two things are learned. The patch turned a contact it did not need to turn: a slip along an edge of the pyramid is
already aligned. And MuJoCo's discrete integrator gives a different answer when two equivalent rows are swapped,
by about as much as its own coarse-step error here.

**The fix, grounded in the pyramid's own geometry and no constant:** turn the pyramid only by the part of the slip's
angle that is not a multiple of 90 degrees. Of the slip and its three quarter turns about the normal, use the one
nearest the frame's first tangent: the same four edges, in the release's order whenever the slip lies along an edge.

## The third version

[`patches/in_design/slip_aligned_pyramid_v3.diff`](../../patches/in_design/slip_aligned_pyramid_v3.diff) (sha256
58a65674e1c61dd9...), 107 lines added, none removed: the second version, with the turn reduced as above, and the new
`mjContact` field added to `doc/includes/references.h` as MuJoCo documents every field (its `doc_test` failed without
it in run 021). The lift is not corrected and is stated.

## Step 2: the five checks and MuJoCo's whole suite (`checks.txt`, every line a `sx_contact rule`)

Run 021's plays again, three arms (release, version 3 switch unset, switch set), and, new, every belt play under MuJoCo's
elliptic cone, the right reference for a moving floor, stated before the plays. Both builds compiled with no warning
from the patched files.

| Check | Result |
|---|---|
| 1 Required | **Held.** The release slides 20% further along 22.5 degrees and 42% along 45; its belt plays stop 52 to 293 steps away from the elliptic cone's on the same belt |
| 2, C1 no direction | **Held.** 126,717 um along 0, 22.5 and 45 degrees at 2 ms; 127,655 at 0.125 ms |
| 2, C2 no drift | **Held.** 0 um |
| 2, C3 the holds the release loses | **Held.** 1,875, 2,263 and 2,748 um/s at 0.72, 0.8 and 0.9 of the limit, along 22.5 and 45 degrees as along 0 |
| 2, C4 the moving floor | **Held.** Each belt play stops within one step of the elliptic cone's: 223 and 223, 190 and 190 at 2 ms; 910 and 909, 781 and 780 at 0.5 ms |
| 2, C5 the frame | **Held.** MuJoCo's `ContactStage` and `ContactVelocity` pass |
| 2, C6 the turned-contact tests | **Held.** `SleepingUnaffectedByWaking`, `FoldDenseBlocksSolveMatches` and `DiscreteStiffLegPress` pass |
| 3 Nothing else gets worse | **Held.** 75 of 75 suite and lift-slide files byte-identical to the release; in MuJoCo's suite, switch set against unset, only `InverseTest.DiscreteInverseFreeBody` changes (the lift, below) |
| 4 Safe when off | **Held.** 112 of 112 files byte-identical to the release; MuJoCo's whole suite, 3,492 tests, test for test as the release, `doc_test` included |
| 5 The solver keeps converging | **Held.** No step at the iteration limit, no warning |

The rig is unchanged when `belt` is not given: the release's slides along x are byte-identical to run 016's.

## The lift, stated

The third version lifts a sliding body as much in every direction as along an axis: 649 um at 2 ms along 0, 22.5 and
45 degrees, against the release's 649, 496 and 288. Its one cost in MuJoCo's suite is the spinning box that leaves the
ground. It is F3's, not this patch's to tune.

## Reported, not judged

- **The slow holds**, below MuJoCo's rest speed: at 0.6 of the limit along 45 degrees the release's 969 um/s stays,
  against 1,293 along 0; along 22.5 degrees it is turned and creeps at 1,293.
- **A cube free to turn**: 126,772, 126,906 and 127,130 um along 0, 22.5 and 45 degrees (within 0.28%), 188 um of drift
  along 22.5.

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 126,717 um | 126,732 um |
| 126,772 um | 126,791 um |
| 126,906 um | 126,926 um |
| 127,130 um | 127,146 um |
| 127,655 um | 127,681 um |

What this page concludes does not change: the largest of these corrections is 0.02%.
