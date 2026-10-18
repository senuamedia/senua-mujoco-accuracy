# Run 047: the de Saxce patch's second version, across the record's scenes and MuJoCo's test suite (a probe)

16 October 2026 (06:54 to 07:06 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed with the patch before any play. It finds where to look and decides nothing.

[Run 046](../run_046_desaxce/README.md) found that de Saxce's correction for MuJoCo's elliptic cone removes the sliding
cube's lift (F3) and the free cube's direction (F12) at a fixed 4 passes, a setting of that probe. The second version,
[`patches/in_design/desaxce_elliptic_v2.diff`](../../patches/in_design/desaxce_elliptic_v2.diff) (sha256
2db0a820d08f2a4f..., switch `MUJOCO_DESAXCE=1`), runs the fixed point until a solve finds nothing to improve, MuJoCo's
own convergence test, at most `opt.iterations` passes. Arms: **rel**, the release; **off** and **on**, the second
version with its switch unset and set; **v1**, the first version at 4 passes. Under Senua AI's configuration, on Study
10's numbers: run 046's plays, both of the first deep dive's contact suites, stacks, slides on the ground and on a box
face, the arm on contact and held by every constraint, written three ways; and MuJoCo's own test suite on the second
version, the switch unset and set ([`measured.txt`](measured.txt), `suite_changed.txt`, `ctest_*.txt`).

## What held

- **Safe when off**: all 309 files byte for byte as released; MuJoCo's suite, 3,492 tests, all passed.
- **The lift and the direction go, as in run 046**: the sliding cube never leaves the ground (10,570 um released at 10
  ms); the free cube slides 133,039 um along every direction at 1.14 ms and 133,481 at 0.285 ms (133,042 to 136,043
  released), with no side drift and never on fewer than four corners. The elliptic cone alone: 133,043 and 133,486.
- **Every hold creeps 0 um/s and every grip 0 or 1, at both steps**, as released; the ten known-answer tests, 10 of 10.
- The slide kept from turning goes 22 to 30 um further than released (133,058 against 133,036 at 1.14 ms, 133,501
  against 133,471 at 0.285 ms; Coulomb's distance 133,451).

## What did not

**Seven of MuJoCo's own tests fail with the switch set** (`suite_changed.txt`; their messages read with the switch set,
from the test build):

| Test | Reads | Cause |
|---|---|---|
| `SensorTest.Contact` | A box at rest reads a normal force of 8.0001306 where 8 is expected | The shift acts on a contact at rest: its tangential residual is not zero under MuJoCo's soft friction, but its slip is, and de Saxce's term is friction times the slip |
| `ForwardTest.DiscreteImplicitRowNoslip` | A stiff cube sliding to rest from 2 m/s under the discrete integrator, with torsional and rolling friction (condim 6) and 2 noslip iterations, still moves at 0.078 after 3.2 s (bound 0.005) | Not traced here |
| `ForwardTest.DiscreteJointInverseConsistency` | Inverse dynamics does not recover the forward forces (2.25 against a bound of 8.6e-6) | Likely that `mj_inverse` does not apply the shift; not traced here |
| `SolverTest.SolversEquivalent` | MuJoCo's dual solver (PGS) disagrees with Newton (-879 against -411) | A defect of this version: under PGS the accelerations are written by `mj_dualFinish` after the solve, and the shift read them before it |
| `SolverTest.WarmstartZeroIterationsIslands` | The islands' iteration counts are not as solved island by island | This version solves the constraint problem whole when its switch is set, not by MuJoCo's islands |
| `SleepTest.SleepingUnaffectedByWaking` | A sleeping body's acceleration differs in the last bit from the awake run's | As above |
| `SolverTest.ZeroToleranceDisablesTermination` | 12 iterations where 3 are expected | With a zero tolerance the passes add iterations to the count |

**The cost**: at most 28 iterations on any step, against 14 for the first version at 4 passes and 12 released: a
solve that finds nothing to improve is a strict test, and the passes run on after the shift has settled.

## What it shows

The second version is not the one to register. Each cause above has an answer in the design: shift only a contact that
slides (the primal cost's middle zone, where its force is on the cone's surface), read the dual solver's result after
`mj_dualFinish`, solve islands as MuJoCo does, and stop when no shift moves by more than the solver's own tolerance.
That is the third version, played in [run 048](../run_048_desaxce_v3/README.md).
