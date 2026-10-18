# Run 074: the box-on-box clip without its collinear vertices (a probe)

17 October 2026 (01:09 to 01:20 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Readings in
[`measured.txt`](measured.txt).

Runs 069 and 072 traced a straight stack's tilt (issue 21) to MuJoCo's box-on-box clip. Equal cubes face to face put the
upper face's edges on the lower face's side planes. A turn or shift of the face makes the clip emit intersections part
way along those edges. That happens first by rounding (corners 1e-17 m out), then by the kick's own drift (1e-11 m).
Each such point is a contact at the corners' depth that adds nothing to the support polygon. [Run 070](../run_070_boxbox_clip/README.md)'s
patch removed the rounding trigger but not the drift.

The second design, [`boxbox_collinear.diff`](../../patches/in_design/boxbox_collinear.diff) (switch
`MUJOCO_BOXBOX_COLLINEAR=1`, `engine_collision_box.c` only, 35 lines added, none removed), drops from the clipped polygon
every vertex that lies on a straight line with its two neighbours. "Straight" means to the noise level the same
function's separation test uses for parallel edges: the sine of the turn squared below `mjBOXBOX_PAREPS`, 1e-16. The
polygon is kept whole when fewer than 3 vertices would remain. It is built from MuJoCo's source at `UPSTREAM_COMMIT`,
with its tests. The plays are run 070's, its first part under the configuration and under MuJoCo's defaults as its
header states.

## Safe when off, and MuJoCo's tests

With the switch unset, all 185 files are byte for byte the release's, and all of MuJoCo's 3,492 tests give the release's
result. With the switch set, none of MuJoCo's tests changes.

## The grid: run 052's stacks under the configuration

Straight stacks of 5 and 9, 2 s, at five steps from 0.1425 to 1.14 ms and six main tolerances: plays of 10 in which any
cube tilts, and the changes in the contacts after step 30.

| Main tolerance | 1e-8 (MuJoCo's default) | 1e-9 | 1e-10 | 1e-11 | 1e-12 | 1e-14 |
|---|---|---|---|---|---|---|
| Released: plays that tilt | 4 | 3 | 6 | 4 | 3 | 0 |
| With the switch set | **0** | **0** | **0** | **0** | **0** | **0** |
| With the switch set: changes in the contacts | **0** | **0** | **0** | **0** | **0** | **0** |

Every one of the 60 plays stands with the switch set, with no change in any face's contacts. Released, 20 tilt, up to
8,562 urad.

## Under the configuration and MuJoCo's defaults

| | Released | With the switch set |
|---|---|---|
| Stacks of 5 and 9 at 0.285 ms, the configuration: the most tilt; contact changes | 2,302 and 2,523 urad; 297 and 394 | **0 and 0; 0 and 0** |
| The same at 1.14 ms | 0 and 0; 0 and 4 | 0 and 0; 0 and 0 |
| Under MuJoCo's defaults, both steps | 0; 2 changes in the stack of 5 at 0.285 ms | 0; 0 |
| The offset stack of 3, 0.285 ms, the configuration | 9,657 urad; 103 changes | 9,528 urad; 101 changes |
| The offset stack at 1.14 ms, under both option sets; the slide on a box's face; the holds; the grips | | **byte for byte as released** |

The switch changes only the straight stacks at 0.285 ms, the stack of 9 at 1.14 ms (whose contacts no longer change),
the stack of 5 under the defaults at 0.285 ms, and the offset stack at 0.285 ms. The offset stack's cubes overlap only
in part, so its clipped polygons are real, and it still leans (F11, issue 9).

## What it shows

Dropping the collinear vertices removes the stacks' contact changes and their tilt at every step and tolerance played,
including MuJoCo's default. It changes nothing else played and none of MuJoCo's tests. It is the candidate fix for issue
21. [Run 075](../run_075_set_with_collinear/README.md) plays it with Senua AI's set, on stacks of 3 to 12, before a
registration.
