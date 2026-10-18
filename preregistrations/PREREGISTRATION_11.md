# Eleventh pre-registration: the fixes in the wild for a held object that creeps, measured beside Senua AI's

Registered 16 October 2026, after the design probe of run 043. Registered before any play of this registration
existed. To be played once, as run 044.

## The question

Under MuJoCo's defaults a load inside the friction cone creeps (finding F1, known issue M1). Several fixes are in use or
proposed: MuJoCo's documentation advises a larger `impratio`, the elliptic cone and the noslip solver, and MuJoCo pull
request #3349 (closed without being merged) adds stiction, a stored relative pose of each pair of touching bodies and a
spring against slip from it, for the elliptic cone only. Senua AI's fix is a configuration of MuJoCo's own options, the
elliptic cone with 10 noslip iterations ([Study 2](../docs/studies/02-recommended-configuration.md), replicated by
[Study 10](../docs/studies/10-recommended-configuration-end-to-end.md)). In run 043, a probe, only Senua AI's
configuration held every hold and grip to 0 on MuJoCo's release; stiction held the holds and its own demos, but a body
moved from outside was pulled back and a restored state did not restore.

On numbers no earlier study used: held to the same known answers, which of these fixes holds a held object still,
holds a gripped one, leaves a body moved from outside where it was put, restores a saved state exactly, and holds the
pull request's own two demo scenes; and is the pull request, with its flag unset, the MuJoCo it branched from, file for
file and test for test?

## Engines and arms

**Part A**, on Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
139577c541d43716...), seven arms: **defaults**; **impratio10** and **impratio100** (`impratio` 10 and 100);
**elliptic** (the elliptic cone); **elliptic_impratio10**; **noslip_pyramidal** (10 noslip iterations under the default
cone); **configuration** (Senua AI's: the elliptic cone with 10 noslip iterations).

**Part B**, on pull request #3349's own builds, built by the runner from MuJoCo's own repository (gcc, CMake and Ninja,
a Release build; its tests built the same way): **june**, MuJoCo at 55c6332f207b5ff2a67addfb3b606570791da8f2 (16 June
2026), the commit the pull request branched from; **off** and **on**, the pull request's head,
4c7bdaf692e7bec1018b91b2c9c24265cec476a7 (17 June 2026), with its flag unset and set (`<flag stiction="enable"/>`);
**cfg**, Senua AI's configuration on that head. All four on the elliptic cone, the only cone stiction applies to. The
pull request's changed lines are run 043's `pr3349.diff`'s; the runner checks it.

Played on the first cloud machine (AWS EC2 c7i.xlarge, 4 virtual CPUs, 8 GB).

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_044_study_11/play.sh`](../validation/run_044_study_11/play.sh) | 70da92ecb1146078... |
| Rigs | `tools/mjc_contact.c`, `tools/mjc_grip.c`, `tools/mjc_scene.c`, `tools/build_rig.sh` | 544cc4dee6f8376f..., 5adac004412ef94b..., 75db05398736b286..., b6a93676e6aee763... |
| The pull request's diff and the suite's re-read | `validation/run_043_fixes_in_the_wild/pr3349.diff`, `suite_reread.sh` | 581627551515f98b..., 5d64c8613fd5f1a0... |
| Senua AI's measures | `sx_contact` (`creep`, `gap`, `ends`, `rule`), source as run | 87e921cd4d2c03bf... (built for Linux: f09ea027cec7820d...) |

## The numbers, and how they were drawn

From one stream of whole numbers, x(n+1) = (1103515245 x(n) + 12345) mod 2^31, from x(0) = 11, by the tenth
registration's procedure and ranges; a value the record already used for a quantity of the same kind (Study 10's lists,
with Study 10's own drawn values added, which run 043 also played) or one this draw had already given was drawn again:
one was (a grip offset). The squeeze was drawn again until the pads' friction is 1.7 to 2 times the gripped cube's
weight (3 times). `DRAW=1 bash validation/run_044_study_11/play.sh` prints the draw.

| What | The numbers | Drawn from |
|---|---|---|
| The steps | 1.65 ms, and a quarter of it, 0.4125 ms | 1 to 2 ms |
| The cube held | 1.381 kg, half-size 0.0435 m, friction 0.369 (its limit 4.994 N) | 1 to 2 kg, 0.04 to 0.05 m, 0.35 to 0.5 |
| The grip | a cube of 0.218 kg, half-size 0.0336 m, friction 0.78, squeezed with 2.58 N (the pads' friction 1.88 times its weight), and 7.9 mm off centre | 0.2 to 0.25 kg, 0.03 to 0.035 m, 0.68 to 0.8, 2.45 to 3.2 N, 7 to 10 mm |

Not drawn, as in run 043: the pushes (0.5, 0.75 and 0.95 of the limit from 0.4 s, 1.6 s of play) and directions (0,
22.5 and 45 degrees); the move from outside (2 mm along 22.5 degrees at 0.8 s, the cube pushed with 0.6 of the limit);
the shove (1.5 of the limit from 0.7 to 0.75 s, the state saved at 0.6 s and restored at 1.2 s); and the pull
request's two demo scenes, played for 6 s as written.

## The scenes

- **The holds**: the cube pushed with 0.5, 0.75 and 0.95 of its limit along 0, 22.5 and 45 degrees, at both steps (18
  plays an arm), every arm.
- **The grips**: the gripped cube, box and mesh pads, centred and off centre, at the coarse step (part A).
- **Moved from outside** (teleport, part B): the held cube moved 2 mm, its position set directly.
- **A restored state** (restore, part B): the shoved cube, with and without the detour that saves the state at 0.6 s
  and restores it at 1.2 s; nothing is written during the detour, so an exact restore gives the same file.
- **The pull request's demos** (part B): its ramp (a block on a 30 degree ramp, friction 1) and its gripper (a box in a
  passive parallel-jaw grip), as written (on), with the flag line removed (june, off), and with it removed and 10
  noslip iterations (cfg); the block's motion read down the ramp and the box's down under gravity.
- **MuJoCo's own test suite** on june and on the pull request's head, the flag unset; the two memory-heavy reader tests
  (`LargeTexture`) played on their own, one at a time, after the others.

## The rules

Each judged by `sx_contact rule` from the measured lines. A creep is `sx_contact creep`'s mean speed over the second
half of the play, its size; the right answer for every one is 0, and the bound is the record's, 10 um/s.

| Rule | Statement | Arms |
|---|---|---|
| H every hold holds | All 18 holds creep at most 10 um/s | every arm |
| G every grip holds | All four grips creep at most 10 um/s | part A |
| T moved from outside, it stays | At both steps, the creep after the move at most 10 um/s | part B |
| S a restored state replays | At each step, the restored play byte-identical to the play without the detour (2 lines) | part B |
| D the pull request's demos hold | The ramp and the gripper each creep at most 10 um/s | part B |
| V the solver | No step at the iteration limit, no warning (2 lines) | every arm |
| E1 the pull request, safe when off, plays | off's holds and demos byte-identical to june's | shared |
| E2 the pull request, safe when off, MuJoCo's suite | Every test both builds have reads the same (the re-read of run 043, `suite_reread.sh`) | shared |

There are 58 rule lines: 4 for each of part A's seven arms, 7 for each of part B's four, and 2 shared. The most
iterations of any step are reported, a cost, and not ruled.

## The decisions

- For each arm, each of these is recorded as measured: **holds a held object** (H, and G where played), **leaves a body
  moved from outside where it was put** (T), **restores a saved state exactly** (S), **holds the pull request's own
  demos** (D).
- **The pull request is recorded as safe when off** if E1 and E2 hold.
- **A fix that meets every rule it is put to** (H, G, T, S, D, V where played) is recorded as holding a held object by
  this study's known answers; a fix that fails one is recorded with the rule it fails and its numbers.
- Nothing is decided about any fix's cost: the iterations are reported.

## Known risks, stated before the run

From run 043, on Study 10's numbers:

- Every arm on the default cone carries the pyramid's direction (finding F2): at 45 degrees it gives at most 0.707 of
  the limit, at 22.5 degrees about 0.77, so the 0.95 and the 0.75 pushes along 45 degrees, and 0.95 along 22.5, slide
  away. H fails on those arms whatever their creep along an axis.
- `impratio` 100 cut the creep along an axis to 21 um/s; it may meet 10 on these numbers along 0, but not along 45.
- Stiction held every hold and its own demos; after a move from outside the cube crept 31 um/s, and its restored play
  was not the original (T, S).
- Senua AI's configuration took 6 to 8 iterations against 3 to 4.
- Two memory-heavy reader tests were killed for memory when the suite ran four at a time; this study runs them alone.

## What is not asked

The friction's direction itself (Study 1); the written pose (Studies 5 to 10, and `diagexact`, run 028); the pull
request rebuilt on a later MuJoCo (it does not apply to 3.16.0; it is played as its author left it); gradients; a real
robot.

## Dry run

`DRY=1` played every arm on run 043's numbers, on the builds run 043 left, with no build and no MuJoCo suite: 262
measured lines, none empty, every one the same as run 043's ([`validation/run_044_study_11/dry/`](../validation/run_044_study_11/dry/)).
No rule was read from it.
