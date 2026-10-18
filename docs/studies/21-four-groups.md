# Study 21: four groups, each deciding one issue

| | |
|---|---|
| Question | On fresh numbers, four questions, each its own group of rules. 1: with the friction solve's second version in Senua AI's set, does every cube held from turning hold, with condim 3, 4 and 6, nothing else changing? 7: in Senua AI's set, does a slide neither hop nor depart from Coulomb's law at any step? 8: within half the contact's time constant, is the depth at rest the same at every step? 10: with the step at most half the time constant times the damping ratio, is the bounce the same at every step and never above the drop? |
| Outcome | **67 of 67 rule lines held.** Issue 1 fixed for a cube held from turning (it stays fixed in part, for the free cube); issue 7 found to be issue 4 and counted with it; issues 8 and 10 corrected by configuration. |
| Registered | [`PREREGISTRATION_21.md`](../../preregistrations/PREREGISTRATION_21.md), pushed with its runner, dry run and rules plumbing check at 07:47 UTC on 17 October 2026, before any play |
| Played | Once, as [run 091](../../validation/run_091_study_21/README.md), 17 October 2026, 07:47 to 08:01 UTC, on Linux (the first cloud machine) |
| Arms | MuJoCo 3.16.0 as released; Senua AI's five validated patches with the friction solve's first version; the same with its second, switches unset and set |
| Measured by | Senua AI's measure as corrected on 17 October 2026 (`creep`, `accel`, `stop`, `hover`, `final`, `bounce`), file comparison, MuJoCo's own test suite, judged by the Senua AI Robotics Core's `rule`; held to [Coulomb's law](../references.md#coulomb); the restitution, [Stronge 2018](../references.md#stronge); the integrator, [Hairer, Lubich and Wanner](../references.md#hairer-gni) |

## Why it was asked

The probes had found each answer: a cube held from turning held by the friction solve's second version (run 086,
Study 20); the slide's step dependence the hop of issue 4 (run 088); the contact's softening exactly MuJoCo's stiffness
guard, and the bounce step-independent once the step resolves its spring (run 088). Each needed fresh numbers and
registered rules. Issue 9 was not ready: its probes had not shown what bound "at rest" should be.

## What it found

| Group | Reading | Rules |
|---|---|---|
| 1 | Released and with the first version, a cube held from turning with condim 4 creeps at 1,608 um/s; with the second, all 108 holds of a cube held from turning, condim 3, 4 and 6, at 10 um/s or less; every other file byte-identical | 9 of 9 |
| 7 | Released, the slide rises 686 um off the ground; in the set no slide rises, the decelerations are 2,498 to 2,499 and 3,498 mm/s2 against Coulomb's 2,499 and 3,499, the distances within 0.6% at every step | 7 of 7 |
| 8 | Within half the time constant the depth at rest is 16,295 and 25,647 nm at every step, to the nanometre; at the time constant, four times deeper | 4 of 4 |
| 10 | Released, the unresolved coarse step throws the cube 46.8 times as high as it fell; with the spring resolved, the three settings' rebounds spread 393, 162 and 250 parts of 10,000, inside 500, none above the drop | 42 of 42 |
| All | Safe when off, every suite read, MuJoCo's suite only the test Study 12 named, every play measured | 5 of 5 |

## What it decides

- **Issue 1**: the friction solve's second version, [`qcqp_reduced_v2.diff`](../../patches/qcqp_reduced_v2.diff), is
  validated for a cube held from turning with condim 3, 4 and 6, and takes the first version's place in Senua AI's set.
  Issue 1 stays fixed in part: the free cube pushed square to a face near its limit is still open.
- **Issue 7**: issue 4's hop, seen through the deceleration; fixed by the same set. Counted once, with issue 4.
- **Issue 8**: corrected by configuration: a step at most half the contact's time constant, inside MuJoCo's own guard.
- **Issue 10**: corrected by configuration: a step at most half the time constant times the damping ratio, the spring
  MuJoCo's own discrete integrator calls resolved.
- Group 1's box rule read each box's last 160 steps by a line of the runner, not by Senua AI's measure, as Studies 19
  and 20 did.
