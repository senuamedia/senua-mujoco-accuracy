# Run 069: the contacts the stacks are solved with (a probe)

17 October 2026 (00:24 UTC). Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh),
pushed before its plays. It finds where to look and decides nothing. Readings in [`measured.txt`](measured.txt). Each
play's contact changes are in `plays/*.events`, and its whole contact trace in `plays/*.contacts.gz`.

[Run 067](../run_067_stack_noslip_trace/README.md) found that each stack that tilts under Senua AI's configuration at
0.285 ms (issue 21) stands still until a kick in a single step. Each kick comes in the step the number of contacts
between two cubes changes. The stack rig has a new setting, `contacts=FILE` (`tools/mjc_stack.c`). It writes every
contact a step is solved with: its two geoms, its position, its distance and its normal. MuJoCo 3.16.0 as released plays
run 063's stacks (Study 10's cube) of 5 and 9, 2 s:

- at 0.285 ms, under the configuration (the elliptic cone, 100 noslip iterations);
- at 0.285 ms, under the elliptic cone alone;
- at 0.285 ms, under MuJoCo's defaults;
- at 1.14 ms, under the configuration.

The rig as it was before the setting is kept here as `mjc_stack_before.c`. It and the rig now, without the setting,
play the same 22 files byte for byte. With the setting, the 11 files of a play are byte for byte as without it
(`check/identity.txt`).

## How deep the cubes sit

The mean distance of each face's four contacts at step 1000 (0.285 s), negative into the face, in um:

| Stack of 9, from the top | 8 on 9 | 7 on 8 | 6 on 7 | 5 on 6 | 4 on 5 | 3 on 4 | 2 on 3 | 1 on 2 | On the ground |
|---|---|---|---|---|---|---|---|---|---|
| The configuration | 207 | 367 | 480 | 564 | 637 | 704 | 769 | 833 | 601 |
| The elliptic cone alone | 207 | 367 | 480 | 564 | 637 | 704 | 769 | 833 | 601 |
| MuJoCo's defaults | 38 | 76 | 113 | 149 | 183 | 216 | 248 | 277 | 166 |

The depth grows with the load, and the elliptic cone sits each cube 3 to 5.4 times deeper than MuJoCo's default
pyramidal cone. Noslip does not change it: at step 1000 the depths under the configuration and under the elliptic cone
alone are the same to the nanometre. Finding F11 (issue 9) put the deeper sinking under "the elliptic cone with noslip".
It is the elliptic cone's.

## What changes in the contacts

| Play | The most tilt | Changes in a face's number of contacts after step 30 | The first |
|---|---|---|---|
| 5, 0.285 ms, the configuration | 2,302 urad | 297 | step 2770 |
| 9, 0.285 ms, the configuration | 2,523 | 394 | step 2416 |
| 5 and 9, 0.285 ms, the elliptic cone alone | 0, 0 | 0, 0 | |
| 5 and 9, 0.285 ms, MuJoCo's defaults | 0, 0 | 2, 0 | step 5467 |
| 5 and 9, 1.14 ms, the configuration | 0, 0 | 0, 4 | step 623 (9) |

Every change is the same kind. A face starts with one contact at each of its four corners, at the corners of the cube
above, (+/-42.4, +/-42.4) mm. Then MuJoCo's box-on-box collision adds contacts along the face's edges, each at the corners'
depth. In the stack of 5's first change (cube 4 on cube 3, step 2770), two are added at (+/-42.4, 21.2) mm, at 366.91 um
like the corners. In the next three steps two other faces get pairs at y = 1.4 mm and y = -14.1 mm on the same two
edges, and others elsewhere along the edges, up to 8 a face. In the stack of 9 and under MuJoCo's defaults, the first added pair sits at the edges' middles,
(+/-42.4, 0) or (0, +/-42.4) mm. Under the defaults it is gone again in the next step. A face of 4 contacts becomes one of 6
or 8, all at one depth, and MuJoCo's soft contacts each push by their own depth. So the force on the face changes in
that step, and on one side of it when the added points are on one side.

## Where they come from

MuJoCo's box-on-box collision (`mjc_BoxBox`, `engine_collision_box.c`) clips the face of one box against the four side
planes of the other's face (`clipHalfPlane`). It emits an intersection wherever an edge strictly crosses a plane. Two
equal cubes, one straight on the other, have the upper face's edges lying on the lower face's side planes. A drift at
rounding level puts a corner a rounding error outside. The edge from it then "crosses" the plane, and the intersection,
a ratio of two rounding errors, lands anywhere along the edge. The separation tests in the same function carry a
rounding slack (`mjBOXBOX_SEPEPS`); the clip does not. Under the elliptic cone alone no face's contacts changed in
2 s; with noslip, at 0.285 ms, they changed from 0.69 s on.

## What it shows

Issue 21 is traced to the collision. Equal cubes stacked straight sit on the clip's planes, and a rounding-level drift
changes their contacts from step to step. Under the configuration the cubes sit 3 to 5.4 times deeper than under the
defaults, so every change moves a larger force. A patch in design, [`boxbox_clip_tol.diff`](../../patches/in_design/boxbox_clip_tol.diff),
gives the clip the separation tests' own slack, and [run 070](../run_070_boxbox_clip/README.md) plays it.
