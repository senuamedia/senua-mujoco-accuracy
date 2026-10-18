# Run 088: the three issues that move with the step (7, 8 and 10), one probe

17 October 2026. Not registered: a design probe on Google DeepMind's Linux release of MuJoCo 3.16.0, played on the
first cloud machine by [`probe.sh`](probe.sh) (step 1, 04:41 UTC) and [`probe_2.sh`](probe_2.sh) (step 2, written after
step 1's readings, 04:57 UTC), each pushed before its plays. It finds where to look and decides nothing.

The contact rig gained one setting, `refsafe=0`, MuJoCo's `refsafe` flag disabled. Unset, the rig writes the same
scene as before: a slide and a drop played by the rig as it was ([`mjc_contact_before.c`](mjc_contact_before.c)) and
as it is are byte-identical ([`identity.txt`](identity.txt)).

## Issue 7: the friction does not move with the step; the hop does, and one of Senua AI's measures did

[`reading_slide.txt`](reading_slide.txt), [`reading_slide_set.txt`](reading_slide_set.txt). Run 001's slide: 1 kg,
half-size 0.05 m, friction 0.4, given 1 m/s, held from turning, at 2 ms and 1/4, 1/16 and 1/64 of it. Over the
window run 001 read (50 to 200 ms), the deceleration, and, from the rig's own force columns over the steps in contact,
the normal force against the weight and the friction against the normal:

| The slide, at 2, 0.5, 0.125 and 0.03125 ms | Deceleration, mm/s2 (Coulomb: 3,920) | Normal force while touching, against the weight | Friction against the normal |
|---|---|---|---|
| Released, MuJoCo's defaults, from the surface | 3,880; 3,898; 3,920; 3,957 | 2.58 to 2.71 | 0.4000 |
| Released, the configuration | 4,062; 3,997; 3,919; 3,959 | 2.53 to 2.74 | 0.4000 |
| **Senua AI's set, the configuration, started at its rest depth** | **3,920; 3,920; 3,920; 3,951** | **1.000000** | **0.4000** |

- **Released, the slide hops** at every step, started from the surface or from the depth it rests at, with either
  cone. On its first step in contact the ground pushes up with 46 N, nearly five times the weight, and the cube flies
  0.6 mm high and lands again. Between flights, the normal force while touching averages 2.5 to 2.8 times the weight.
  This is issue 4, the hop, which de Saxce's correction removes in Senua AI's set.
- **The friction itself does not move with the step**: in every play, released or in the set, it is 0.4000 of the
  normal force, to 1 part in 10,000.
- **In Senua AI's set the cube does not hop.** Started at its rest depth, the normal force is the weight to 1 part in a
  million, and the deceleration is Coulomb's 3,920 mm/s2 at 2, 0.5 and 0.125 ms.
- **The 3,951 at the finest step is a defect in Senua AI's own measure**, not MuJoCo. From the same rig columns in
  double precision the deceleration is 3,919.99 mm/s2 there. `sx_contact accel` and `sx_contact stop` turn the step
  into whole microseconds (`dt_us = intdiv(dt_ns, 1000)`), so a step of 31.25 us counts as 31. The time read is then
  short by 0.8%, which is exactly the 3,951, and the distance by 1,086 um. A step that is a whole number of microseconds
  is read exactly; one with a fraction of a microsecond is not (427.5 us by 0.12%, 152.5 us by 0.33%). It is recorded
  as a defect in the harness, to be fixed and every affected reading in the record checked.

So issue 7 is not a separate departure: it is issue 4's hop seen through the deceleration, and, at 1/64, partly Senua
AI's measure. In the set, the slide's distance from the columns converges with the step (126,692; 127,469; 127,663;
127,712 um against Coulomb's 127,551). At the coarse step that is the step's own error in the slide's start and stop;
at the fine step, 0.13% over, the friction falls below its limit in the last centimetre, where the speed is small.

## Issue 8: past its guard, the contact is exactly the guard's; within it, the depth does not move with the step

[`reading_rest.txt`](reading_rest.txt). The cube (1 kg, half-size 0.05 m) set down from 20 mm with friction 0.5, as
runs 003 and 005 played it, read over its last 0.5 s of 2 s.

| Depth at rest, nm | 5 ms | 10 ms | 20 ms | 40 ms |
|---|---|---|---|---|
| MuJoCo's defaults (the time constant 20 ms) | 17,055 | 17,055 | 67,861 | 252,121 |
| At 1 ms, with the time constant set to what the guard gives that step (20, 20, 40, 80 ms) | 17,055 | 17,055 | 67,861 | 252,062 |
| The guard off | 17,055 | 17,055 | thrown 1.5 km up | thrown 18.7 km up |
| The guard off, the implicit integrator | 17,055 | 17,055 | thrown 1.5 km up | thrown 18.7 km up |

| Depth at rest, nm, at a step of this part of the time constant | 1/16 | 1/4 | 1/2 | 1 |
|---|---|---|---|---|
| Time constant 10 ms | 4,265 | 4,265 | 4,265 | 17,055 |
| Time constant 40 ms | 67,861 | 67,861 | 67,861 | 252,121 |

- Past its guard the contact is softer by exactly the guard: at 20 ms the depth is the depth at 1 ms with the time
  constant the guard substitutes, to the nanometre. At 40 ms it is the same within 59 nm; that play is still settling,
  at 2 um/s.
- The guard is needed: without it the cube is thrown away at 20 and 40 ms, under Euler and the implicit integrator
  alike.
- With the step at most half the time constant the guard never acts, and the depth is the same at every step, byte
  for byte: for time constants of 10, 20 and 40 ms.
- A cube set down from the surface rests at the same depth as one set down from 20 mm: to the nanometre at 5, 10 and 20 ms, and within 35 nm at 40 ms, where both still settle.

## Issue 10: with the spring resolved by the step, the bounce does not move with the step

[`reading_bounce.txt`](reading_bounce.txt). Run 017's drop (2 kg, half-size 0.04 m, held from turning, from 80 mm),
1 s, under Euler, for time constants of 10, 20 and 40 ms and damping ratios of 0.5, 0.2 and 0.1, at run 017's seven
steps (10 ms down to 0.156 ms). MuJoCo's own discrete integrator treats a spring as one the step cannot resolve when
the time constant times the damping ratio is under the step. Here a play is called resolved when that product is at
least twice the step, the factor MuJoCo's guard uses for the time constant.

| Rebound, parts of 10,000 of the drop | Resolved: spread across the steps (lowest to highest) | Unresolved: highest |
|---|---|---|
| 10 ms, damping 0.5 / 0.2 / 0.1 | 238 (398 to 636) / 446 (2,696 to 3,142) / 16 (5,469 to 5,485) | 10,934 / 405,345 / 2,976,954 |
| 20 ms | 416 (340 to 756) / 305 (2,763 to 3,068) / 436 (5,005 to 5,441) | 6,323 / 240,498 / 2,175,043 |
| 40 ms | 77 (188 to 265) / 211 (2,737 to 2,948) / 270 (5,124 to 5,394) | none unresolved / 4,669 / 190,722 |

- In all 9 settings, the resolved plays spread by at most 446 parts of 10,000. That is inside the first deep dive's
  T04 bound of 500. None rebounds higher than it fell.
- Unresolved, the cube is thrown up to 298 times its drop height, and the bounce moves with the step.
- The 20 ms plays give run 017's readings where its cube had come down within its 0.5 s; the plays still rising at 0.5 s read higher over 1 s.

## What it means

- **Issue 7** is issue 4, the hop, seen through the deceleration, and, at the finest step, a defect in Senua AI's
  `accel` and `stop` measures. In Senua AI's set the friction does not move with the step.
- **Issue 8** is MuJoCo's documented guard and nothing else. The guard is needed, and with the step at most half the
  time constant the contact does not move with the step.
- **Issue 10** has a rule MuJoCo's own discrete integrator states: with the step at most half the time constant times
  the damping ratio, the bounce does not move with the step beyond T04's bound.

Each is a candidate for a registered study on fresh numbers. The probe decides none of them. The defect in `accel` and
`stop` is to be fixed before any study reads them at a step that is not a whole number of microseconds.

## Corrected 17 October 2026: the measure's step

The defect in `accel` and `stop` found above is corrected
([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)).
This run's readings stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. As corrected, the deceleration at 1/64 of 2 ms (31.25 us) reads:

| The slide, at 0.03125 ms | As printed, mm/s2 | Corrected, mm/s2 |
|---|---|---|
| Released, MuJoCo's defaults, from the surface | 3,957 | 3,907 |
| Released, the configuration | 3,959 | 3,913 |
| Senua AI's set, the configuration, started at its rest depth | 3,951 | **3,920**, Coulomb's |

The decelerations at 2, 0.5 and 0.125 ms are unchanged; the distances move by micrometres, as the audit lists. In Senua
AI's set the corrected measure reads Coulomb's 3,920 mm/s2 at all four steps, as the rig's own columns give it.
