# Run 103: impratio in place of noslip

17 October 2026 (13:31 UTC). Not registered: a design probe on the first cloud machine, pushed before its plays
([`probe.sh`](probe.sh)). It finds where to look and decides nothing. Its readings and solver statistics are kept.

## Why

Noslip's multi-contact instability (a free cube near its friction limit rocks and creeps, offset stacks keep turning;
runs 093 and 096) and its other costs (a joint equality broken, inverse dynamics that cannot agree; run 094) all come
with noslip. MuJoCo documents impratio, the ratio of the friction's impedance to the normal's under the elliptic cone,
larger making friction harder, and Study 11 found it cutting the creep roughly in proportion. Can Senua AI's set hold
without noslip?

## The arms

Senua AI's six validated patch files, every switch set (Study 22's build). Three configurations: set (the elliptic
cone, 100 noslip iterations); imp100 (the elliptic cone, impratio 100, no noslip); imp1000 (impratio 1,000, no
noslip). The bound on creep is the record's, 10 um/s.

## What it found

The creep, um/s, over each play's steps ([`reading.txt`](reading.txt)):

| Play | set | imp100 | imp1000 |
|---|---|---|---|
| Study 20's free cube a, 0.95 of its limit, 1.277 / 0.319 ms | 613 / 173 | 23 / 23 | 2 / 2 |
| Study 20's free cube b, the same | 1,098 / 482 | 29 / 29 | 3 / 3 |
| The cube Study 19 held, 0.5 and 0.95 of its limit | 0 | 6 and 11 | 1 and 1 |
| Study 15's grip, box and mesh pads | 0 to 1 | 38 | 4 |
| Study 15's arm set down and dropped, two poses | 0 | 3 to 6 | 0 to 1 |
| **Study 15's arm held in the air by joint friction, two poses** | **3 and 6** | **20,343 and 43,394** | **20,343 and 43,394** |

- Every play but the set's free cubes gives the same creep at both of its steps (the others at 1.71 and 0.4275 ms).
- Joint friction is not a contact: impratio does not reach it, and without noslip it does not hold.

**Every offset stack comes to rest.** Run 093's stacks of three offset 1, 5 and 17 mm a cube, 6 s at 1.14 ms, the
fastest turn of any cube, urad/s, and the largest lean, urad:

| Offset | set | imp100 | imp1000 |
|---|---|---|---|
| 1 mm | 3,567, lean 612 | 0, lean 348 | 0, lean 348 |
| 5 mm | 11, lean 1,495 | 0, lean 1,853 | 0, lean 1,852 |
| 17 mm | 21, lean 7,016 | 0, lean 7,955 | 0, lean 7,953 |

- A stack of ten sinks the same in all three (its top contact 207,044 nm): impratio leaves the normal's softness as it
  is. MuJoCo's box is at rest in all three.
- The solver ([`stats.txt`](stats.txt)): at most 57 iterations a step, none at 100, no warnings.

## What it means

- With impratio at 1,000 and no noslip, every contact in the set holds under the bound, the free cubes too, and
  offset stacks come to rest: the many-contact cost goes with noslip.
- Joint friction then falls. The next probe is the two together, and with the stiffer contact of
  [run 102](../run_102_contact_time_constant/README.md): impratio 1,000 with noslip, and against inverse dynamics and
  Coulomb's distance.
