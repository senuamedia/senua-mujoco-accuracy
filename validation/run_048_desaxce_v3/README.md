# Run 048: the de Saxce patch's third version (a probe)

16 October 2026. Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh), pushed with the
patch before any play. It finds where to look and decides nothing.

**Played twice, from the same commit (3ef74fc).** Its first play (07:14 to 07:25 UTC) finished, but its outputs were
deleted on the cloud machine, while clearing a full disk, before they were pulled. It was played again from its own
commit (07:45 to 07:55 UTC); the files here are the second play's. The first play's summary lines, read at the time,
match the second's: the same four changed tests, 197 of 309 files the same as released, at most 204 iterations on a
step and 2 of the scenes' steps (the suites not counted in that line) at the iteration limit, the ten known-answer tests 10 of 10.

The third version, [`patches/in_design/desaxce_elliptic_v3.diff`](../../patches/in_design/desaxce_elliptic_v3.diff)
(sha256 92cb492f55158767..., switch `MUJOCO_DESAXCE=1`, 104 lines added, none removed), answers run 047's seven changed
tests: it shifts only a contact in the primal cost's middle zone (its force on the cone's surface), by the scaled norm
of its tangential residual; reads the dual solver's result after `mj_dualFinish`; solves islands as MuJoCo solves them;
and stops when no shift moves by more than the solver's own tolerance. Arms and plays as in
[run 047](../run_047_desaxce_v2/README.md), without the first version ([`measured.txt`](measured.txt)).

## What held

- **Safe when off**: all 309 files byte for byte as released; MuJoCo's suite, 3,492 tests, all passed.
- **The lift and the direction go**: the sliding cube never leaves the ground at any step; the free cube slides
  133,038 um along 0 and 22.5 degrees at 1.14 ms and 133,480 and 133,481 at 0.285 ms.
- **Every hold creeps 0 um/s and every grip 0 or 1 um/s**; the ten known-answer tests, 10 of 10.
- 197 of 309 files byte for byte as released, against 77 under the second version.

## What did not

- **The fixed point cycles where a contact sits at the line between sticking and sliding.** There the shift jumps
  from 0 to the full tangential residual, a contact flips between the two from pass to pass, and the passes run to the
  limit: 204 iterations on a step on the slides on the ground and on a box face at 0.285 ms, 103 on two scenes of the
  first contact suite (`oblique_1`, `chain_1`); 6 steps reached the iteration limit (2 on the slides, 4 in the suite).
- **Four of MuJoCo's tests read differently with the switch set** (`suite_changed.txt`):
  `ForwardTest.DiscreteImplicitRowNoslip`, `SolverTest.NewtonDecrementTermination`, `SolverTest.SolversEquivalent`
  and `SolverTest.ZeroToleranceDisablesTermination`. `NewtonDecrementTermination` and `ZeroToleranceDisablesTermination` read the passes' iterations in counts and statistics
  written for one solve; under the fourth version (run 049) `SolversEquivalent` and `NewtonDecrementTermination` no longer change, and `DiscreteImplicitRowNoslip` is traced there.

## What it shows

The zone rule is the wrong measure of slip: in MuJoCo's soft model a sticking contact has a tangential residual, its
friction's regularisation, so the rule's shift is not zero at stick and jumps at the boundary. The slip that de
Saxce's term multiplies is the part of the residual the regularisation does not account for. That is the fourth
version, played in [run 049](../run_049_desaxce_v4/README.md).
