# Run 056: why the resting arm creeps (a probe)

16 October 2026 (11:52 UTC). Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh),
pushed before its plays. It finds where to look and decides nothing. Issue 1's open part
([the issue list](../../docs/issues.md)): Study 10's two-link arm, set down with its ball on the ground and left at rest,
creeps along the ground at 714 um/s in its first pose under Senua AI's configuration, its sideways force 0.11 of its
normal force, well inside its friction cone (0.717). Readings in [`measured.txt`](measured.txt).

The arm rig gains `trace`: per step the ball's contacts, the slip of the ball's surface at its contact (the velocity of
its material point there; the ground is still), link 2's spin and the joints' speeds. Unchanged without it: Study 10's
arm plays on contact under MuJoCo's defaults and the configuration, 16 of 16 byte for byte with run 042's files.

## The readings

Pose 1 (shoulder 0.604, elbow 1.158 rad), over the second second, the same at 1.14 and 0.285 ms; released, and with the
de Saxce patch's switch set the same:

| Options | The ball creeps | Its surface slips at the contact | Link 2 spins | Sideways over normal force |
|---|---|---|---|---|
| MuJoCo's defaults (the pyramidal cone) | 1,188 um/s | 1,290 um/s | 3,873 urad/s | 0.113 |
| The elliptic cone alone | 714 | 776 | 2,332 | 0.111 |
| The configuration (the elliptic cone, 10 noslip iterations) | 714 | 776 | 2,332 | 0.111 |
| 100 noslip iterations; 1,000 at a noslip tolerance of 1e-12; the main solve at 1e-12 | 714 | 776 | 2,332 | 0.111 |
| The configuration with `diagexact` | 960 | 1,043 | 3,131 | 0.112 |
| **The pyramidal cone with 10 noslip iterations** | **0** | **0** | **0** | 0.109 |

In pose 2 the ball creeps 8 to 13 um/s under each elliptic setting and the defaults (28 to 43 with `diagexact`), and 0
under the pyramidal cone with noslip.

## What it shows

- **The ball slides at its contact**; it does not roll. Its surface slips along the ground at about the speed its centre
  creeps, while its sideways force stays at about a sixth of what friction can give (0.111 of its normal force against
  0.717).
- **Under the elliptic cone noslip does nothing for this contact**: 10, 100 or 1,000 noslip iterations, to MuJoCo's default
  noslip tolerance or to 1e-12, give the same files byte for byte, and the same readings as the elliptic cone alone and as a main solve run to 1e-12. MuJoCo's
  noslip solves an elliptic contact's friction for its normal force (`solNoSlip`, `engine_solver.c`), and here it stops
  after a pass or two with nothing to improve.
- **Under the pyramidal cone noslip holds it at 0**, where for a cube pushed along an axis it does nothing (runs 001
  and 013). The two cones' noslip holds opposite cases.
- The de Saxce patch does not touch it: the solver treats the contact as sticking, so there is no slip to shift by.
- So Senua AI's configuration does not hold this arm, and no MuJoCo option played here holds both it and the cube under
  one cone. Why the elliptic cone's noslip leaves this contact sliding is not yet traced.
