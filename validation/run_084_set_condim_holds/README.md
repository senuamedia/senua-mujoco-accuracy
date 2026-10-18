# Run 084: Senua AI's set on torsional and rolling friction, and the rolling design in it (a probe)

17 October 2026 (03:40 to 03:54 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Readings in
[`measured.txt`](measured.txt).

Run 083 found a cube with torsional or rolling friction (condim 4 or 6), held under Senua AI's configuration, creeping
because noslip's friction solve returns zero for its contacts. It also found the box that never rests (issue 20) brought
to rest by run 079's design, but runs 079 and 082 were built without Senua AI's friction-solve patch. This probe builds
five patches into one MuJoCo, from its source at `UPSTREAM_COMMIT`, with its tests:

- Senua AI's four validated patches (the inverse weight, de Saxce's correction, the friction solve and the box-on-box
  collinear patch);
- run 079's design made to apply after the friction-solve patch and to solve through it,
  [`noslip_roll_kept_after_qcqp.diff`](../../patches/in_design/noslip_roll_kept_after_qcqp.diff) (switch
  `MUJOCO_NOSLIP_ROLL_KEPT=1`, 45 lines added, none removed).

Three arms, under the configuration: **rel**, released; **set4**, the four validated switches; **set5**, those and the
rolling switch.

## The holds with torsional and rolling friction

Run 063's cube held at 0.5 and 0.95 of its friction limit, um/s, at both steps alike:

| | rel | set4 | set5 |
|---|---|---|---|
| condim 3, held from turning and free to turn | 0, 0 | 0, 0 | 0, 0 |
| condim 4 and condim 6, **free to turn** | **0, 0** | **0, 0** | **0, 0** |
| condim 4 and condim 6, **held from turning** (three slide joints) | 498, 946 | 498, 946 | 498, 946 |

A cube free to turn, with torsional or rolling friction, holds at 0, released and in the set. Only a cube that cannot
turn creeps, in every arm. Its contacts' torsional and rolling directions cannot move. Run 083 traced the release:
noslip's solve returns zero for these contacts. The set's solve is not traced here. A likely reason it fails too: in
MuJoCo's friction solve the block is scaled by each direction's coefficient (0.005 for torsion, 0.0001 for rolling) and
then rejected by an absolute threshold (1e-10). The friction-solve patch drops a direction by its unscaled size, a part
in 1e10 of the block's largest entry, which these may not meet.

## The box, and what else changes

| | rel | set4 | set5 |
|---|---|---|---|
| The box of run 049, as written and with 100 noslip iterations: last 160 steps faster than 1 mm/s | 106 | 106 | **0**, at rest from step 14 |
| Study 15's arm, set down and dropped in two poses | 205 to 688 um/s | 0 | 0, byte for byte as set4 |
| The grips; every condim-3 and condim-4 play | | | byte for byte as set4 |

Against set4, set5 changes only the two boxes, the condim-6 cube free to turn (its holds, at 0 in both, and its
slides, by 2 um at most), and nothing else. With every switch unset, every one of MuJoCo's 3,492 tests gives the
release's result. With the five set, the only test that changes is `SolverTest.ZeroToleranceDisablesTermination`, one
of the two Study 12 named. The other, `ForwardTest.DiscreteImplicitRowNoslip`, passes, as released, now that its box
rests.

## What it shows

- **Issue 20.** In Senua AI's set, the rolling design brings MuJoCo's test box to rest and changes nothing else played
  but condim-6 free cubes. It is the design for a registration.
- **Issue 1, for torsional and rolling friction.** A free body holds. A body that cannot turn, with condim 4 or 6, still
  creeps in the set. The likely reason, the friction solve's absolute threshold after scaling by the small coefficients,
  is not traced with the set on.
