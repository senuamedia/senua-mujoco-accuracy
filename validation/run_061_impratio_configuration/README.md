# Run 061: impratio across the configuration's scenes (a probe)

16 October 2026 (12:23 to 12:27 UTC). Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh),
pushed before its plays. It finds where to look and decides nothing. Readings in [`measured.txt`](measured.txt).

[Run 059](../run_059_resting_arm_impratio/README.md) found that the resting arm's slide (issue 1's open part) falls about
as 1/impratio, and that at impratio 100 every resting pose played creeps at most 7 um/s. This plays run 054's scenes on
Study 10's numbers under Senua AI's configuration (the elliptic cone, 100 noslip iterations since Study 13) at impratio 1
(MuJoCo's default), 10, 30 and 100, with Study 13's resting arm added, on MuJoCo 3.16.0 as released (**rel**) and on the
de Saxce patch's fourth version with its switch set (**on**). The rigs unchanged: run 052's 208 plays made again, byte for
byte (`rel/id/identity.txt`).

## The readings

| | impratio 1 | 10 | 30 | 100 |
|---|---|---|---|---|
| The resting arms, the ball's creep, um/s (Study 10's two poses; Study 13's two) | 714, 9; 0, 192 | 70, 1; 0, 19 | 23, 0; 0, 7 | **7, 0; 0, 2** |
| The 18 holds; the 8 grips | 0; 0 or 1 um/s | 0; up to 3 | 0; up to 3 | 0; up to 2 |
| The arm held by joint friction | 2 um/s | 2 | 2 | 2 |
| The first suite's ten tests | 10 of 10 | 10 | 10 | 10 |
| Released: the cube slid kept from turning, highest above the ground at 1.14 ms; the free cube's largest drift | 97 um; 1,026 um | 139; 326 | 214; 768 | 215; 920 |
| With the switch set: the same | 0; 0 | 0; 0 | 0; 0 | 0; 0 |
| The stack of 9, most tilt at 1.14 ms, released / switch set | 0 / 0 urad | 11,278 / 9,763 | 17,322 / 5,498 | 12,928 / 2,224 |
| The stack of 9, most tilt over the five steps, released / switch set | 2,523 / 9,791 urad | 13,862 / 25,241 | 17,322 / 18,515 | 15,951 / 17,200 |

Every reading with the resting arms is the same at 0.285 ms. With the switch set the slides are the patch's at every
impratio (the free cube 133,033 to 133,036 um along every direction at 1.14 ms). The most iterations on a step: at most
45; released at impratio 30 the cube slid on a box's face reaches 100 on 58 steps at 0.285 ms.

## What it shows

- **impratio holds the resting arm and tips the stacks.** At impratio 100 every resting pose creeps at most 7 um/s and
  every hold, grip, joint and known-answer test is as at impratio 1. But straight stacks that stand at impratio 1 at
  1.14 ms tilt at every impratio from 10 up, by up to 17 mrad, released and with the switch set, and the stack of 9 moves
  at up to 35 mm/s at the end. impratio trades issue 1's open part against issue 21; it is not a fix.
- Released, a higher impratio makes a sliding cube rise higher and a free cube drift further (issues 4 and 5); with the
  de Saxce patch neither appears at any impratio.
