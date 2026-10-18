# Run 082: noslip solving the rolling friction in a cone of its own (a probe)

17 October 2026 (03:13 to 03:32 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Readings in
[`measured.txt`](measured.txt).

[Run 079](../run_079_noslip_roll_kept/README.md)'s patch, noslip leaving the rolling friction as it was, brought the box
that never rests (issue 20) to rest. It left a condim-6 cube held under the configuration creeping (issue 1, for
rolling friction). A second design, [`noslip_roll_cone.diff`](../../patches/in_design/noslip_roll_cone.diff) (switch
`MUJOCO_NOSLIP_ROLL_CONE=1`, `engine_solver.c` only, 50 lines added, none removed), changes how noslip solves a condim-6
contact. It solves the sliding and torsional friction in the ellipsoid whose radius is the normal force, then the
rolling friction in an ellipsoid of its own, each with MuJoCo's own solver. The plays are run 079's.

With the switch unset, all 35 files are byte for byte the release's, and all of MuJoCo's 3,492 tests give the release's
result. With it set, none of MuJoCo's tests changes.

## What it shows

| | Released | With the switch set |
|---|---|---|
| The box of run 049, as written and with 100 noslip iterations: last 160 steps faster than 1 mm/s | 106 | **0**, at rest from step 16 |
| condim 6, the configuration: held at 0.5 and 0.95 of its limit | 498 and 946 um/s | **498 and 946 um/s** |
| condim 3: holds, slides, grips | | byte for byte as released |
| condim 6: slides | | the free slides by 1 um, the rest byte for byte |

This design, like run 079's, brings the box to rest and changes nothing else played. Neither stops the condim-6 hold
from creeping. Its creep, 498 and 946 um/s, is to the micrometre per second the creep of a condim-3 cube under the
elliptic cone with no noslip at all (run 070's first part). So, with rolling friction, noslip changes nothing for the
held cube, released or with either design. Why is the next thing to trace: what noslip computes for that contact.
