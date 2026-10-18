# Run 059: the resting arm's slide by impratio (a probe)

16 October 2026 (12:17 UTC). Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh), pushed
before its plays. It finds where to look and decides nothing. Readings in [`measured.txt`](measured.txt).

Issue 1's open part: an arm set down on its ball slides at its contact under the elliptic cone, well inside its friction
cone, and noslip does nothing for that contact ([run 056](../run_056_resting_arm/README.md)). Under the elliptic cone
MuJoCo divides the friction rows' regularisation by `impratio`. The arm rig gains `impratio`, unchanged without it
(Study 10's arm plays on contact, 8 of 8 files byte for byte with run 042's). On MuJoCo 3.16.0 as released, Study 10's
arm and Study 13's, each in its two contact poses, set down and left at rest, 2 s, at 1.14 ms.

The ball's creep along the ground, um/s, under the elliptic cone with 0, 10 or 100 noslip iterations:

| impratio | 1 | 3 | 10 | 30 | 100 |
|---|---|---|---|---|---|
| Study 10's arm, pose 1 | 714 | 235 | 70 | 23 | 7 |
| Study 10's arm, pose 2 | 9 | 3 | 1 | 0 | 0 |
| Study 13's arm, pose 1, no noslip | 596 | 195 | 58 | 19 | 6 |
| Study 13's arm, pose 1, 10 or 100 noslip iterations | 0 | 0 | 0 | 0 | 0 |
| Study 13's arm, pose 2 | 192 | 64 | 19 | 7 | 2 |

Under the configuration with implicitfast or RK4 every reading is as with MuJoCo's default integrator.

**What it shows.** The slide is the elliptic cone's soft friction's own creep: it falls about as 1/impratio (Study 10's
first pose 714, 235, 70, 23, 7 um/s against 714 over impratio). Noslip removes it for one of the four contacts (Study 13's first pose) and leaves the other three as they are,
at every impratio. At impratio 100 every pose creeps at most 7 um/s, inside the record's bound for a hold (10 um/s): a
candidate for issue 1's open part, to be probed across the configuration's other scenes (run 061). Why noslip leaves
three of the four contacts sliding is not traced here.
