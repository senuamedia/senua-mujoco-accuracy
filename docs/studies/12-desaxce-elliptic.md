# Study 12: de Saxce's correction for the elliptic cone, for a sliding body's lift and a free cube's direction

| | |
|---|---|
| Question | On numbers no earlier study or probe used: with the de Saxce patch's fourth version switched on, does a sliding cube stay on the ground and slide the same along every direction, under Senua AI's configuration and under the elliptic cone alone, while everything held is held as before; with it off, is the patched MuJoCo the release, file for file and test for test; with it on, does any of MuJoCo's tests change other than the two named in advance? |
| Outcome | **43 of 43 rule lines held. Issues 4 (a sliding body hops) and 5 (a free cube has a direction) are fixed and validated under the elliptic cone**, with Senua AI's configuration and with the elliptic cone alone. Every hold and grip file byte for byte as released. With the switch set two of MuJoCo's 3,492 tests fail, the two named in advance. Not ruled, and a cost: under the configuration the switch tips a stack of 9 cubes that the release keeps upright. |
| Registered | [`PREREGISTRATION_12.md`](../../preregistrations/PREREGISTRATION_12.md), 16 October 2026, pushed with its runner, dry run and rules plumbing check before any play |
| Played | Once, as [run 051](../../validation/run_051_study_12/README.md), 16 October 2026 10:25 UTC, on Linux (the first cloud machine, 4 virtual CPUs and 8 GB) |
| Arms | MuJoCo 3.16.0 as released, and built with the patch, its switch unset and set, each under MuJoCo's defaults, under Senua AI's configuration and under the elliptic cone alone (nine arms) |
| Measured by | The Senua AI Robotics Core's measuring programs (`creep`, `stop`, `hover`), the rigs' own fields, file comparison, MuJoCo's own test suite, judged by `rule`; held to [Coulomb's law](../references.md#coulomb); the relaxation, [Anitescu 2006](../references.md#anitescu), [Le Lidec et al. 2024](../references.md#le-lidec); the correction, [de Saxce and Feng 1991](../references.md#desaxce-1991) |

## Why it was asked

Under MuJoCo's elliptic cone a sliding body leaves the surface (finding F3; known issues M5 and M11): run 016's cube,
slid at 1.2 m/s, rises 10.6 mm at a 10 ms step. A cube free to turn, slid along different directions, goes different
distances, drifts across its line and turns (F12). Both come from the cone's convex relaxation of Coulomb friction,
under which a sliding contact pushes itself apart at about friction times its slip ([Anitescu 2006](../references.md#anitescu); runs 016 and 045);
no MuJoCo setting removes them (run 045). [De Saxce and Feng's correction (1991)](../references.md#desaxce-1991) is the known answer: the same cone
condition in a velocity shifted along the normal by friction times the slip.

## The patch

[`patches/desaxce_elliptic_v4.diff`](../../patches/desaxce_elliptic_v4.diff) (sha256 00cb8f8eb4a07535...), switch
`MUJOCO_DESAXCE=1`, `engine_forward.c` only, 103 lines added and none removed. After MuJoCo's own solve, each elliptic
contact's normal reference is lowered by friction times its slip, and the step is solved again from that solution
until no shift moves by more than the solver's own tolerance (a fixed point, as [Acary, Cadoux, Lemarechal and Malick
2011](../references.md#acary-2011) solve it). The slip is the part of the contact's tangential residual that the soft friction's own regularisation
does not account for, so a contact that sticks has none. Islands and the dual solver are handled as MuJoCo handles them.
Four versions were probed (runs 046 to 050); this is the fourth.

## The scenes

On fresh numbers drawn from seed 12: a cube of 1.903 kg held at 0.5, 0.75 and 0.95 of its friction limit and slid at
0.81 m/s along 0, 22.5 and 45 degrees, kept from turning; the same cube slid free to turn along 0, 11.25, 22.5, 33.75
and 45 degrees; a two-pad grip, box and mesh pads, at the centre and off it; stacks of 5 and 9 (played, not ruled); all
at 1.16 ms and 0.29 ms. The cube slid along 0 at the record's step ladder, 10 ms over 1, 4, 16 and 64. The first contact
suite's ten known-answer tests on a fresh cube. MuJoCo's own test suite.

## The rules and what they read

| Rule | Released | Switch set: the configuration; the elliptic cone alone | Held |
|---|---|---|---|
| Q1 to Q3 the defects are there | Lifts 4,442 um at 10 ms; drifts up to 790 um; 2,867 steps on fewer than four corners | | 6 of 6 |
| E1, E2 safe when off | | 164 of 164 files, three times; every MuJoCo test as released | 4 of 4 |
| P1 the pyramidal cone untouched | | 164 of 164 files | 1 of 1 |
| M1 MuJoCo's suite, switch set | | Two tests fail, the two named in advance | 1 of 1 |
| L1, L2 no lift, four corners | | 0 um at every step and the ladder; no step on fewer than four corners | 4 of 4 |
| D1 to D3 no direction, drift or turn | Free: 88,051 to 89,432 um at 1.16 ms, turning up to 36 mrad | 88,012 and 88,017 um along every direction at 1.16 ms, 88,374 and 88,380 at 0.29; no drift, no turn | 16 of 16 |
| C1 Coulomb at the fine step | | Within 0.1% of 88,323 um (88,374 to 88,399) | 2 of 2 |
| V1 the solver | | Never at the iteration limit, no warning | 4 of 4 |
| H1, G1, K1 under the configuration | | Every hold 0 um/s, every grip 0 or 1, the ten tests 10 of 10 | 3 of 3 |
| N1 nothing held is touched | | Every hold and grip file byte for byte as released (35 of 35) | 1 of 1 |
| H2 under the elliptic cone alone | | Every hold and grip creeps as released (finding F1) | 1 of 1 |

## What it decides

- **Issue 4, a sliding body hops (F3), is fixed and validated under the elliptic cone**, with Senua AI's configuration
  and with the elliptic cone alone. Under MuJoCo's default pyramidal cone the lift is there too (run 050), and this
  patch does not act on it.
- **Issue 5, a free cube has a direction (F12), is fixed and validated** the same way.
- **Nothing held is touched**: every hold and grip plays byte for byte as released.
- The patch moves to [`patches/`](../../patches/README.md), beside its copy under `in_design/`.

## What it costs, and what it does not decide

- **Two of MuJoCo's tests fail with the switch set**, both traced before the study (run 049):
  `ZeroToleranceDisablesTermination` counts the patch's extra passes, and `DiscreteImplicitRowNoslip` checks a scene
  that never comes to rest released either (finding F13); the switch moves the phase of its cycle.
- **A tall stack with noslip.** Under the configuration the switch tips the stack of 9 at both steps (up to 6.5 mrad,
  still moving at 3.2 to 5.2 mm/s), where released it does not tilt. Under the elliptic cone alone every stack stands
  with the switch set. Played and reported, not ruled; it is recorded under finding F14 (issue 21), which stays open.
- **The iterations**: at most 16 on a step under the configuration (15 released), 14 under the elliptic cone alone (7).
- Not decided: inverse dynamics (`mj_inverse` does not apply the shift), the RK4 and implicitfast integrators (run 050,
  a probe, found the lift and direction gone under both), a bounce (run 050: unchanged), anything against a real robot.
