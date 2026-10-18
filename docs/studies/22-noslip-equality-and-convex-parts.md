# Study 22: noslip keeping a joint equality, and a concave shape as convex parts

| | |
|---|---|
| Question | On fresh numbers, two questions, each its own group of rules. 14: with noslip's pass also re-solving the equality rows (`noslip_equality.diff`) in Senua AI's set, does a joint equality hold where the release breaks it, the friction-held body stay held, a loaded equality give as without noslip, an arm held by a weld or a connect with joint friction rest, and everything without an equality play exactly as before? 15: does a cup written as one mesh collide as its hull, and as convex parts, primitives or meshes, as the cup it is? |
| Outcome | **39 of 39 rule lines held.** Issue 14's broken equality fixed and validated: the patch joins Senua AI's set as its sixth file. Issue 15 corrected by configuration: a concave shape written as convex parts. |
| Registered | [`PREREGISTRATION_22.md`](../../preregistrations/PREREGISTRATION_22.md), pushed with its runner, dry run and rules plumbing check on 17 October 2026, before any play |
| Played | Once, as [run 099](../../validation/run_099_study_22/README.md), 17 October 2026, 10:58 to 11:12 UTC, on Linux (the first cloud machine) |
| Arms | MuJoCo 3.16.0 as released; Senua AI's five validated patches with `noslip_equality.diff`, switches unset, the five set, the six set |
| Measured by | Senua AI's measure as corrected on 17 October 2026, with `fastest` (`final`, `gap`, `creep`, `fastest`), file comparison, MuJoCo's own test suite, judged by the Senua AI Robotics Core's `rule`; held to [Coulomb's law](../references.md#coulomb); joint friction and equalities as constraints, [Todorov 2014](../references.md#todorov-2014), [Featherstone 2008](../references.md#featherstone) |

## Why it was asked

Run 094 reproduced MuJoCo's issue [#2430](https://github.com/google-deepmind/mujoco/issues/2430): with noslip, a joint
its friction holds stays still and a joint coupled to it moves and stays moved, because noslip re-solves the friction
rows only. Runs 095 and 097 found a design that keeps the coupling and changes nothing without an equality, and chose
its first version, never worse than noslip as it stands. Run 092 found a cup written as one mesh colliding as its hull,
and as convex parts as the cup it is. Each needed fresh numbers and registered rules.

## What it found

| Group | Reading | Rules |
|---|---|---|
| 14 | Released under the configuration, the body coupled to a friction-held one moves 386 um (held scenes) and 650 mm and 1.64 m (after #2430); in the set the gap is 0 in every scene and the held body stays at 0; a loaded equality gives 581 um, as with no noslip; a welded or connected arm with joint friction rests (0 um/s, released 2 to 5); the set's own plays byte-identical with the switch set and unset, every arm, grip and hold at most 10 um/s and every box at rest | 13 of 13 |
| 15 | As one mesh the ball rests on the hull's top, 10 mm down and 0.367 mm in, a lid that is not there; as primitives and as convex meshes it rests on the floor, 0.367 mm in, the same to the nanometre; released and in the set, under the defaults and the configuration; every cup at rest | 21 of 21 |
| All | Safe when off, file for file and all 3,492 of MuJoCo's tests; with the six switches set only `ZeroToleranceDisablesTermination` changes; every play measured | 5 of 5 |

The cost, reported: with an equality and joint friction noslip ran to its limit of 100 iterations on 1,423 steps of
the plays with an equality.

## What it decides

- **Issue 14 fixed in part.** Its broken equality is fixed and validated; [`noslip_equality.diff`](../../patches/noslip_equality.diff)
  is Senua AI's sixth patch file. Its inverse dynamics is a limit of holding friction exactly (run 094), and noslip's
  multi-contact instability a measured limit of the configuration (runs 093, 096, 098, 100).
- **Issue 15 corrected by configuration**: a shape that is not convex written as convex parts, primitives or meshes,
  MuJoCo's documented remedy.
