# Run 072: how far off the box-on-box clip's planes the stacks' corners lie when their contacts change (a probe)

17 October 2026 (01:02 to 01:03 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Readings in
[`measured.txt`](measured.txt). The changes are in `trace/*.events`, and the trace itself in `trace/*.trace.gz`.

[Run 069](../run_069_stack_contacts/README.md) traced the stacks' kicks (issue 21) to MuJoCo's box-on-box clip.
[Run 070](../run_070_boxbox_clip/README.md)'s patch, the clip given its separation tests' rounding slack (2.5e-14 m for
these cubes), stood every stack only with the main solver at 1e-11 or tighter. An instrumentation patch,
[`boxbox_trace.diff`](../../patches/in_design/boxbox_trace.diff) (off unless `MUJOCO_BOXBOX_TRACE` is set; 21 lines
added, none removed), prints four things for each box-on-box face contact: how far the incident face's corners lie
outside the reference face (the least and the most of the four), the sine of the face's turn in the reference plane, its
largest axis component out of that plane, and the vertices and contacts the clip gives. It plays run 063's stacks of 5
and 9 under the configuration, 2 s, at 0.285 ms at MuJoCo's default main tolerance and at 1e-12, and at 1.14 ms. With
the switch unset all 90 files are byte for byte the release's and the build prints nothing; traced, they are byte for
byte as untraced.

## What the trace shows

| Play | Most tilt | Contact changes | At each pair's first change: the most a corner lies outside; the face's turn (sine) |
|---|---|---|---|
| 5, 0.285 ms, default tolerance | 2,302 urad | 297 | the first pair: 2.8e-17 m; 2.5e-16. The other three, after the first kick: 8e-12 to 8e-11 m; 5.5e-11 to 1.7e-10 |
| 9, 0.285 ms, default | 2,523 | 394 | the first pair: 1.4e-17 m; 8e-17. A second pair, 0.64 s later: 4.9e-17 m; 2.4e-16. The other six, after the second kick: 1.1e-11 to 4.8e-11 m; 6e-11 to 1.4e-10 |
| 5 and 9, 0.285 ms, 1e-12 | 0, 0 | 5, 7 | every pair up to its first change: at most 6.9e-17 m; at most 2e-16 |
| 5 and 9, 1.14 ms, default | 0, 0 | 0, 4 | at most 5.6e-17 m; at most 2.6e-16 |

Each stack's first change comes from rounding alone: a corner 1e-17 to 6e-17 m outside, and a turn whose sine is about
1e-16. That is well within run 070's slack. After a kick, the faces it shook are turned and shifted for real, by 1e-11
to 1e-10. The clip then emits its points where the face's edges cross the reference face's sides. For a face turned by
a small angle, that is near the middle of each edge: the points (+/-42.4, 0) and (0, +/-42.4) mm of run 069. Each such
point lies on the support polygon's edge, within the turn, and adds nothing to the polygon. Yet it is one more contact
at the corners' depth.

## What it shows

Run 070's patch removes the trigger, but at MuJoCo's default tolerance something else shakes the stack, the clip's
points come back, and the stack tilts. The design follows from this: drop a clipped vertex that lies on a straight line
with its neighbours, to the noise level the same function's separation test uses for parallel edges (the sine of a turn
squared below `mjBOXBOX_PAREPS`, 1e-16). Turns of 1e-10 are far below that level. A real face turned by a visible angle
is far above it and keeps its polygon. [Run 074](../run_074_boxbox_collinear/README.md) plays this second design.
