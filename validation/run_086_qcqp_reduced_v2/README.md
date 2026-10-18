# Run 086: the friction solve dropping a direction at noslip's floor, for a cube that cannot turn

17 October 2026 (04:03 to 04:22 UTC). A design probe, not registered: it finds where to look and decides nothing.
Played on the first cloud machine by [`probe.sh`](probe.sh), pushed before its plays (commit 7ca4892), from an archive
of that commit.

## Why

Run 084 found a cube that cannot turn (held on three slide joints) still creeping with torsional or rolling friction
(condim 4 or 6) under Senua AI's set. Noslip takes a contact's block without its regularisation and clamps each diagonal
entry from below at 1e-10 (`extractBlock`, `engine_solver.c`). The cube's torsional and rolling directions, which cannot
move, sit at that floor. The friction-solve patch, [`qcqp_reduced.diff`](../../patches/qcqp_reduced.diff), drops a
direction whose entry is at most 1e-10 of the block's largest. For this cube the largest is about 0.5, so the floor is
kept.

Its second version, [`qcqp_reduced_v2.diff`](../../patches/in_design/qcqp_reduced_v2.diff), changes that one condition: a
direction is also dropped at the floor. It keeps the same switch. Since no entry is below the floor, the two versions
differ only when the block's largest entry is below 1, and then only in dropping the entries at the floor.

## What was played

Two builds from MuJoCo's source at `UPSTREAM_COMMIT`, every switch set, under Senua AI's configuration (the elliptic
cone, 100 noslip iterations):

- **v1**: Study 19's build of Senua AI's five patch files;
- **v2**: the same five with the second version in place of the first, built here with its tests.

The plays (88 files a build):

- the arms of Studies 10, 13, 14 and 15 set down and dropped, at their studies' steps (48 plays);
- run 063's cube (1.861 kg, half-size 0.0434 m, friction 0.39) held at 0.5 and 0.95 of its limit, with condim 3, 4 and
  6, held from turning and free, at 1.14 and 0.285 ms;
- Study 15's grip.

MuJoCo's own test suite was run on the v2 build, every switch unset and set. The readings are in
[`measured.txt`](measured.txt).

## What it found

| Cube, creep in um/s at 0.5 and 0.95 of the limit | v1 | v2 |
|---|---|---|
| condim 3, held from turning or free | 0, 0 | 0, 0 |
| condim 4, held from turning | **498, 946** | **0, 0** |
| condim 6, held from turning | **498, 946** | **0, 0** |
| condim 4 or 6, free | 0, 0 | 0, 0 |

The same at both steps. Every arm held at 0 in both builds, and the grips at 1 um/s or less.

- Of the 88 play files, 80 are byte-identical between the builds. The 8 that differ are exactly the holds of the cube
  held from turning with condim 4 and 6.
- MuJoCo's suite on v2, every switch unset: all 3,492 tests as released (against run 064's release results).
- With every switch set, one test changes: `SolverTest.ZeroToleranceDisablesTermination`, one of the two Study 12
  named.
- No step at the iteration limit, no warning.

## What it means

The second version holds the cube that cannot turn and changes nothing else played. It is a candidate for issue 1's
open part, registered as [Study 20](../../preregistrations/PREREGISTRATION_20.md) on fresh cubes. The entries
themselves were not traced step by step: that the floor is what kept the cube creeping is the patch's reasoning, and
this probe's result agrees with it.
