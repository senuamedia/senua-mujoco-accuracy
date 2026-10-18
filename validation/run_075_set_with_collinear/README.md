# Run 075: Senua AI's set with the box-on-box collinear patch (a probe)

17 October 2026 (01:26 to 01:40 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Readings in
[`measured.txt`](measured.txt).

[Run 074](../run_074_boxbox_collinear/README.md)'s patch in design, the box-on-box clip's polygon without its collinear
vertices ([`boxbox_collinear.diff`](../../patches/in_design/boxbox_collinear.diff)), stood every stack of run 052's
grid. Senua AI's set (Study 15) is the configuration with three patches, and under it de Saxce's correction tipped a
stack of 9 the release keeps upright (Study 12, runs 066 and 068). This probe builds all four patches into one MuJoCo,
from its source at `UPSTREAM_COMMIT`, with its tests. Four arms, all under the configuration:

- **rel**: MuJoCo 3.16.0 as released.
- **off**: every switch unset.
- **set**: Study 15's three switches.
- **set4**: those and the collinear switch.

## Safe when off, and MuJoCo's tests

With every switch unset, all 375 files are byte for byte the release's, and every one of MuJoCo's 3,492 tests gives the
release's result. With the four switches set, the only tests that change are the two Study 12 named:
`ForwardTest.DiscreteImplicitRowNoslip` and `SolverTest.ZeroToleranceDisablesTermination`.

## The straight stacks

The most tilt of any cube, in urad, and the changes in the contacts after step 30, run 063's cube (Study 10's):

| Stack | Released | The set | The set with the collinear patch |
|---|---|---|---|
| 3 cubes, at all five steps | 0 | 0 | **0, no change** |
| 5 cubes: 0.1425, 0.285, 0.57, 1.14, 1.71 ms | 4,450; 2,302; 0; 0; 2,698 | 3,489; 0; 0; 0; 0 | **0 at every step, no change** |
| 9 cubes, the same steps | 0; 2,523; 0; 0; 0 | 3,094; 3,181; 1,073; 0; 3,055 | **0 at every step, no change** |
| 12 cubes, the same steps | 2,336; 4,236; 0; 11,710; 5,474 | 1,430; 0; 2,837; 345; 12,162 | **0 at every step, no change** |
| 5 cubes on a fixed box of half-size 0.5 m, 0.285 and 1.14 ms | 3,391; 2,600 | 2,557; 0 | **0; 0, no change** |

Released, 8 of the 20 straight stacks tilt, and with the set's three patches 9 do. With the collinear patch none does,
and no face's contacts change in any of them. The stack on a fixed box tilts released, from the cubes above it, and
stands with the patch.

## What the patch does not change

| | The set | With the collinear patch |
|---|---|---|
| Stacks of 3 offset by 1 mm a cube, 0.285 and 1.14 ms | 2,248 and 2,115 urad | 2,202 and 2,126 urad |
| Stacks of 3 offset by 17 mm a cube | 9,657 and 9,363 urad | 9,528 and 9,363 urad |
| Study 15's arm set down and dropped, 16 plays; the holds; the grips; the slide on a box's face | 0; 0; 0 or 1 um/s; 131,090 and 130,579 um | **byte for byte as the set** |

The offset stacks lean in every arm, released (2,262 and 2,180 urad at 1 mm) and patched alike. That is finding F11
(issue 9): an offset load sinks one edge deeper than the other. At 1 mm the lean is about 2 mrad, more than run 026's
offset stacks would give in proportion. Their contacts change hundreds of times in each arm. They are where issue 9's
next probe looks.

## What it shows

With the collinear patch, Senua AI's set stands every straight stack played: 3 to 12 cubes, 0.1425 to 1.71 ms, and a
stack on a fixed box. That includes the stack of 9 that de Saxce's correction tipped. Nothing else the set plays
changes, and of MuJoCo's tests only the two Study 12 named. It is the design for a registration on fresh numbers.
