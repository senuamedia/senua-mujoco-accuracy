# Study 13: 100 noslip iterations, for a joint held by friction

| | |
|---|---|
| Question | On numbers no earlier study used: with 100 noslip iterations in place of 10, does Senua AI's configuration hold a joint by friction within the record's bound for a hold, and leave everything else it plays exactly as it was? |
| Outcome | **11 of 11 rule lines held. Issue 6, a joint held by friction creeps, is fixed and validated.** The single joint holds at 0 and the two-link arm at 2 and 3 um/s, where with 10 noslip iterations the arm creeps at 58 and 372 um/s; every cube, grip and suite play file is byte for byte as with 10. The recommended configuration becomes the elliptic cone with 100 noslip iterations. |
| Registered | [`PREREGISTRATION_13.md`](../../preregistrations/PREREGISTRATION_13.md), 16 October 2026, pushed with its runner, dry run and rules plumbing check before any play |
| Played | Once, as [run 058](../../validation/run_058_study_13/README.md), 16 October 2026 12:06 UTC, on Linux (the first cloud machine, 4 virtual CPUs and 8 GB) |
| Arms | MuJoCo 3.16.0 as released: its defaults; the configuration with 10 noslip iterations; the same with 100 |
| Measured by | The Senua AI Robotics Core's measuring programs (`creep`, `stop`), file comparison, judged by `rule`; held to [Coulomb's law](../references.md#coulomb), [Popov 2010](../references.md#popov); MuJoCo's soft constraints, [Todorov 2014](../references.md#todorov-2014) |

## Why it was asked

A joint held by dry friction larger than its load creeps (known issue M13): released, run 001's single joint turns at
1.5 degrees a second. MuJoCo's noslip solver acts on dry friction rows as well as on contacts, and under the
configuration's 10 noslip iterations Study 10's arm, its two hinges' friction rows coupled, still crept at 93 and 25
um/s. In probes, 100 noslip iterations held it to 2 um/s (run 052) and changed no other file of the configuration's
plays (run 054).

## The rules and what they read

| Rule | Reading | Held |
|---|---|---|
| Q1, Q2 released, the joint and the arm creep | 25,404 urad/s; up to 40,534 um/s | 2 of 2 |
| Q3 the configuration's arm creeps | up to 372 um/s with 10 noslip iterations | 1 of 1 |
| J1 the single joint holds (at most 24 urad/s, 10 um/s at its cube) | 0 at both steps | 1 of 1 |
| J2 the arm holds (at most 10 um/s) | 2 and 3 um/s in its two poses, at both steps | 1 of 1 |
| N1 nothing else changes | 85 of 85 play files of the cubes, grips and suite byte for byte as with 10 iterations | 1 of 1 |
| H1, G1, K1 what the configuration holds | every hold 0 um/s, every grip 0 to 2, the ten tests 10 of 10 | 3 of 3 |
| V1 the solver | at most 23 iterations a step, none at 100, no warning | 2 of 2 |

## What it decides

- **Issue 6 is fixed and validated**: the elliptic cone with 100 noslip iterations holds a joint by friction, single and
  coupled, within the record's bound for a hold.
- **The recommended configuration becomes the elliptic cone with 100 noslip iterations**, both MuJoCo's own options. Its
  contact plays here are byte for byte those of 10; Studies 2, 10 and 11 were played with 10.
- Not decided: an arm resting on its ball (issue 1's open part: on these numbers it stands in one pose and slides at 191
  um/s in the other, with 10 or 100 iterations alike); a joint equality with joint friction (issue 14); the patches.
