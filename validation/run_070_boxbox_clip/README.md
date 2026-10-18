# Run 070: the box-on-box clip given the separation tests' rounding slack (a probe)

17 October 2026 (00:32 to 00:44 UTC; step 2 at 00:47). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh) and [`probe_2.sh`](probe_2.sh), each pushed before its plays. It finds where to look and decides
nothing. Readings in [`measured.txt`](measured.txt) and [`step2/measured.txt`](step2/measured.txt).

[Run 069](../run_069_stack_contacts/README.md) traced the stacks' kicks (issue 21) to MuJoCo's box-on-box clip
(`clipHalfPlane`, `engine_collision_box.c`). Equal cubes stacked straight put the upper face's edges on the lower face's
side planes. A drift then makes the clip emit intersections along those edges, each a contact at the corners' depth. A
patch in design, [`boxbox_clip_tol.diff`](../../patches/in_design/boxbox_clip_tol.diff) (switch
`MUJOCO_BOXBOX_CLIPTOL=1`, `engine_collision_box.c` only, 58 lines added, none removed), clips with the rounding slack
the same function's separation tests already carry: `mjBOXBOX_SEPEPS` times the summed half-sizes, 2.5e-14 m for these
cubes. A vertex within it of a plane counts as on the plane, and an edge on the plane gives only its ends. It is built
from MuJoCo's source at `UPSTREAM_COMMIT`, with its tests.

## A fault in step 1, and step 2

Step 1's first part looped over its option sets as `for os in rec:$REC def:`, which split the configuration's two
options into two passes. So its "rec" plays are under the elliptic cone alone, its "noslip=100" plays under MuJoCo's
default pyramidal cone with 100 noslip iterations, and its "def" plays under MuJoCo's defaults, as intended. Its grid
passed the options whole and is as its header states. Step 2 replays the first part under the configuration, on step 1's
build. Step 1's first part is kept as played.

## Safe when off, and MuJoCo's tests

With the switch unset, all 277 files of step 1 and all 93 of step 2 are byte for byte the release's, and all of MuJoCo's
3,492 tests give the release's result. With the switch set, none of MuJoCo's tests changes.

## The grid: run 052's stacks under the configuration

Straight stacks of 5 and 9, 2 s, at five steps from 0.1425 to 1.14 ms and six main tolerances. The table counts the plays
of 10 at each tolerance in which any cube tilts, released and with the switch set (the most tilt, in urad, is in
`measured.txt`):

| Main tolerance | 1e-8 (MuJoCo's default) | 1e-9 | 1e-10 | 1e-11 | 1e-12 | 1e-14 |
|---|---|---|---|---|---|---|
| Released: plays that tilt | 4 | 3 | 6 | 4 | 3 | 0 |
| With the switch set | **9** | **9** | 4 | **0** | **0** | **0** |
| With the switch set: changes in the contacts after step 30 | 0 to 503 a play | 0 to 486 | 0 to 442 | **0** | **0** | **0** |

Released, the stacks tilt and stand with no order in step or tolerance, as run 052 found, and their contacts change in
50 of the 60 plays. With the switch set and the main solver at 1e-11 or tighter, all 30 plays stand, and no
face's contacts change in any of them. At 1e-10 and looser, the switch does not remove the changes, and at MuJoCo's
default and 1e-9 the stacks tilt in 9 of 10 plays, against 4 and 3 released.

## Step 2: the first part under the configuration

| | Released | With the switch set |
|---|---|---|
| Stacks of 5 and 9 at 1.14 ms, the most tilt | 0, 0 | 0, **5,873** urad |
| The same at 0.285 ms | 2,302, 2,523 | 1,937, 6,130 |
| The offset stack of 3 | 9,363 and 9,657 urad | the same, file for file at 1.14 ms |
| A cube slid on a box's face; the two holds; the four grips | 130,843 and 131,393 um; 0; 0 or 1 um/s | the same, file for file |

The switch changes only the straight stacks and the offset stack at 0.285 ms. It tips the stack of 9 at 1.14 ms, which
the release keeps upright.

## What it shows

The patch does what it was built to do only where the solve is tight. With the main solver at 1e-11 or tighter, it
removes every change in the stacks' contacts, and every stack in the grid stands. At MuJoCo's default tolerance the
cubes drift off the clip's planes by more than the separation tests' slack, the changes come back, and the stacks tilt
more often than released. **The first version fails as a fix and stays in design.**

This also shows how large the drift is: more than 2.5e-14 m at the default tolerance, and within it at 1e-11. [Run
072](../run_072_boxbox_trace/README.md) traces it: how far off the planes the corners lie, and how far turned the face
is, when the contacts change.

## Files

Each arm's plays are in `rel`, `off` and `on` (`p`, and the grid in `grid`). Step 2's are in `step2/`. MuJoCo's test
output is in `ctest_*.txt`, read into `suite_results_*.txt`.
