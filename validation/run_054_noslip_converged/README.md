# Run 054: noslip run further, across the configuration's scenes (a probe)

16 October 2026 (11:36 to 11:41 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Run 052 found that more
noslip iterations hold an arm by joint friction (issue 6). This asks what that change to Senua AI's configuration does
to everything else it holds, on MuJoCo 3.16.0 as released (**rel**) and on the de Saxce patch's fourth version with its
switch set (**on**, Study 12's build), on Study 10's numbers. Four noslip settings under the elliptic cone: **n10**, 10
iterations (the configuration as it is); **n100**, 100; **n100t**, 100 at a noslip tolerance of 1e-12; **n1000t**,
1,000 at 1e-12. Readings in [`measured.txt`](measured.txt).

The contact, stack and grip rigs gain `noslip_tolerance`, unchanged without it: run 052's 208 plays at MuJoCo's default
tolerance, made again, 208 of 208 byte for byte (`rel/id/identity.txt`).

## The readings

Released. With the switch set the readings are the same but for the slides, which are the patch's (the free cube
133,036 um along every direction at 1.14 ms and 133,478 at 0.285, the kept cube never leaving the ground), the resting
arm's second pose (8 um/s) and the iterations (at most 39, 45, 111 and 1,011 a step; 0, 0, 34,836 and 30,662 steps at
100 or more):

| | n10 | n100 | n100t | n1000t |
|---|---|---|---|---|
| The arm held by joint friction, creep in its two poses | 93, 25 um/s | **2, 2** | **0, 0** | **0, 0** |
| The 18 holds | 0 um/s | 0 | 0 | 0 |
| The 8 grips | 0 or 1 um/s | 0 or 1 | 0 | 0 |
| The cube slid kept from turning, free to turn, and on a box's face | as released | the same | the same | the same |
| The arm at rest on its ball, creep in its two poses | 714, 9 um/s | 714, 9 | 714, 9 | 714, 9 |
| The first suite's ten tests | 10 of 10 | 10 | 10 | 10 |
| The most iterations on a step (MuJoCo counts noslip's) | 16 | 23 | 106 | 1,006 |
| Steps at 100 iterations or more | 0 | 0 | 30,934 | 19,320 |

The stacks are in `measured.txt`: with more noslip iterations they tilt and stand from step to step as with 10 (finding
F14).

## What it shows

- **100 noslip iterations, at MuJoCo's default noslip tolerance, hold the arm by joint friction to 2 um/s**, inside the
  record's bound for a hold (10 um/s), and change no other reading of the configuration's plays, at a cost of 23
  iterations a step against 16. A candidate for issue 6, to be registered.
- A noslip tolerance of 1e-12 holds the joint and the grips at 0, but on contact scenes noslip does not reach it and runs
  to its cap: tens of thousands of steps at 100 or 1,000 iterations. Not a configuration to recommend.
- **The arm at rest on its ball creeps at 714 um/s in its first pose under every setting.** Its sideways force is 0.11
  of its normal force, well inside its friction cone (0.717), so it should not move. Study 10 read the same creep under
  the configuration (713 and 714 um/s) without ruling it. Issue 1 of [the issue list](../../docs/issues.md), a held
  object creeps, is fixed for a held and a gripped cube, not for this arm; it is recorded as fixed in part.
