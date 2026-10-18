# Run 104: impratio and the contact's time constant, with and without noslip

17 October 2026 (13:35 to 13:36 UTC). Not registered: a design probe on the second cloud machine, pushed before its
plays ([`probe.sh`](probe.sh)). It finds where to look and decides nothing. Its readings and solver statistics are kept.

## Why

[Run 103](../run_103_impratio_without_noslip/README.md): impratio 1,000 with no noslip held every contact near its
limit and brought offset stacks to rest, but joint friction fell. [Run 102](../run_102_contact_time_constant/README.md):
a contact time constant of twice the step cut the depth 35 to 1,034 times. Here the two together, with and without
noslip.

## The arms

Senua AI's set, MuJoCo built from its source at the pinned commit with its six validated patch files, every switch set
([`patch_check.txt`](patch_check.txt)). Four configurations, all under the elliptic cone: set (100 noslip iterations);
impns (and impratio 1,000); imptc (impratio 1,000, every geom's solref twice the step with damping ratio 1, no noslip);
impnstc (all three).

## What it found

Creep, um/s, slides, um, and the depth of a stack of ten, nm ([`reading.txt`](reading.txt)):

| Play | set | impns | imptc | impnstc |
|---|---|---|---|---|
| Study 20's free cubes a and b, 0.95 of the limit, 1.277 and 0.319 ms | 173 to 1,098 | 0 | 0 | 0 |
| The cube Study 19 held, 0.5 and 0.95, 1.71 and 0.4275 ms | 0 | 0 | 0 | 0 |
| Study 15's arm set down and dropped, two poses | 0 | 0 | 0 | 0 |
| **Study 15's arm held by joint friction, two poses** | 3 and 6 | 3 and 6 | **20,343 and 43,394** | 3 and 6 |
| Study 15's grip, box and mesh pads | 0 to 1 | 0 | 0 to 1 | 0 |
| Run 093's offset stacks after 6 s, the fastest turn, urad/s | up to 3,567 | 0 | 0 | 0 |
| The same, the largest lean, urad | 612 / 1,495 / 7,016 | 348 / 1,852 / 7,953 | 6 / 34 / 145 | 6 / 34 / 145 |
| A stack of ten, its deepest contact | 901,106 | 901,106 | 25,523 | 25,523 |
| Study 13's slide, 1 ms (Coulomb's distance 133,452) | 133,124 | 133,120 | 132,946 | 132,946 |
| The same, 0.25 ms | 133,515 | 133,511 | 133,324 | 133,324 |
| MuJoCo's box, the fastest over its last 160 steps | 0 | 0 | 0 | 0 |

- The offset stacks' leans are for offsets of 1, 5 and 17 mm; the slides are the same along 0, 22.5 and 45 degrees,
  and none goes sideways.
- **The slides.** MuJoCo's default integrator takes a sliding body's distance short by half a step's travel,
  v dt / 2, 505 um at 1 ms and 126 um at 0.25 ms. With the stiffer contact, the slides are Coulomb's distance less that
  half step, to 1 and 2 um. With MuJoCo's time constant they go 177 and 189 um further, while the cube settles into
  its contact.
- **Inverse dynamics** ([`stats.txt`](stats.txt), MuJoCo's fwdinv on the free cubes and the held cube). With noslip,
  the constraint force of the forward step and inverse dynamics differ by up to 9.36 N (set), 8.89 (impns) and 8.95
  (impnstc), the whole friction force. Without it (imptc), by 1.2e-11 N at most, and the applied forces by 4.7e-8.
- The solver: at most 57 iterations a step (49 with the stiffer contact), none at 100, no warnings.

## What it means

- With impratio 1,000, the stiffer contact and noslip together (impnstc), every play here holds or comes to rest: the
  free cubes Study 20 failed on, the offset stacks of issues 9 and 14, joint friction, and Coulomb's distance to the
  integrator's own step. A stack of ten sinks 35 times less.
- Inverse dynamics still cannot agree with noslip. Without it, inverse dynamics agrees and every contact holds, but
  joint friction falls. The next probe: joint friction made stiff by its own reference, so that noslip is not needed.
