# Run 102: the contact's time constant, issue 9's depth

17 October 2026 (13:28 to 13:30 UTC). Not registered: a design probe on the second cloud machine, pushed before its
plays ([`probe.sh`](probe.sh)). It finds where to look and decides nothing. Its readings and solver statistics are kept.

## Why

A stack sinks at every contact (issue 9), as deep as the softness the model authors (run 089): MuJoCo's soft contact
has a time constant, its solref, 0.02 s unless the model sets it, and a contact sinks under a load by a depth that
grows with it. MuJoCo's own guard (refsafe) lets a contact be as stiff as a time constant of twice the step.

## The setting

The rigs gain `gsolref=T,D`: every geom's solref, the time constant and damping ratio, set after the scene is loaded,
as a model's own geom solref sets it. Unset, the scene's own: the five rigs as they were ([`before/`](before/)) and as
they are now give the same bytes, play files and solver statistics, on one play each
([`identity.txt`](identity.txt)). Played in Senua AI's set, MuJoCo built from its source at the pinned commit with its
six validated patch files, every switch set ([`patch_check.txt`](patch_check.txt)), under the configuration (the
elliptic cone, 100 noslip iterations) unless said.

## What it found

**The depth falls with the square of the time constant.** A cube (1 kg, half-size 0.05 m, friction 0.5) set down at
rest for 2 s, how far its lowest face is below the ground at the end, nm ([`reading_depth.txt`](reading_depth.txt)):

| Time constant | Configuration, 1.14 ms | Configuration, 0.285 ms | MuJoCo's defaults, 1.14 ms | MuJoCo's defaults, 0.285 ms |
|---|---|---|---|---|
| MuJoCo's, 0.02 s | 107,649 | 107,649 | 17,055 | 17,055 |
| 8 steps | 22,691 | 1,419 | 3,548 | 222 |
| 4 steps | 5,676 | 355 | 887 | 55 |
| 2 steps | 1,419 | 89 | 222 | 14 |

**Stacks sink 35 to 1,034 times less, and offset stacks come to rest.** Straight stacks of run 078's cube, the deepest
contact, nm, and run 093's stacks of three offset 1, 5 and 17 mm a cube after 6 s, the largest lean and the fastest
turn of any cube, urad and urad/s ([`reading_stacks.txt`](reading_stacks.txt)):

| | MuJoCo's time constant, 1.14 ms | Two steps, 1.14 ms | MuJoCo's time constant, 0.285 ms | Two steps, 0.285 ms |
|---|---|---|---|---|
| Stack of 3 / 5 / 10, deepest contact | 366,909 / 563,645 / 901,106 | 5,676 / 11,351 / 25,523 | 366,909 / 563,645 / 901,106 | 355 / 710 / 1,596 |
| Offset 1 mm: lean, turn | 612, 3,567 | 6, 0 | 2,131, 1,822 | 0, 0 |
| Offset 5 mm: lean, turn | 1,495, 11 | 48, 0 | 1,497, 11 | 2, 0 |
| Offset 17 mm: lean, turn | 7,016, 21 | 127, 1 | 7,014, 21 | 9, 0 |

- With noslip in the configuration, the stiffer contact brings every offset stack to rest, where with MuJoCo's time
  constant the 1 mm stacks keep turning.

**The set's other plays hold** ([`reading_set.txt`](reading_set.txt)): Study 15's arm set down and dropped in two
poses, the cube Study 19 held at 0.5 and 0.95 of its limit, 0 um/s at both steps and both time constants; Study 15's
grip, box pads 1 um/s with MuJoCo's time constant and 0 with two steps, mesh pads 0; MuJoCo's box and Study 19's box 1
at rest.

**The free cube is not held by it** ([`reading_free.txt`](reading_free.txt)): Study 20's cube b, condim 3, pushed along
0 degrees at 0.95 of its limit, creeps 1,098 and 482 um/s at 1.277 and 0.319 ms with MuJoCo's time constant, 488 and
121 with two steps.

The solver ([`stats.txt`](stats.txt)): at most 57 iterations a step, none at 100, no warnings.

## What it means

- Issue 9's depth is the time constant, and a model can set it: at twice the step, the stiffest MuJoCo allows, a stack
  of ten sinks 25.5 um at its deepest contact at 1.14 ms and 1.6 um at 0.285 ms, against 901 um.
- The same setting brings offset stacks to rest under noslip, the part of issue 14's many-contact cost that stacks
  show. It does not hold the free cube near its limit.
