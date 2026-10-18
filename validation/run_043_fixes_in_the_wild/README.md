# Run 043: the fixes in the wild for a held object that creeps, measured beside Senua AI's (a probe)

16 October 2026 (04:31 to 04:45 UTC). Not registered: a design probe on the first cloud machine (4 virtual CPUs, 8 GB),
by [`probe.sh`](probe.sh), pushed before any play. It finds where to look and decides nothing. The question: when
Senua AI's Measure holds each fix already in use or proposed for finding F1 (a load inside the friction cone creeps,
known issue M1) to the same known answers as Senua AI's own fix, how does each do? Throwaway numbers: Study 10's
1.861 kg cube (friction 0.39) and its grip. Every reading is the measuring program's (`creep`, `gap`, `ends`), in
`measured.txt`; file comparisons are `cmp`.

## Part A: MuJoCo's own options, on its 3.16.0 release

The cube held with 0.5, 0.75 and 0.95 of its friction limit along 0, 22.5 and 45 degrees, at 1.14 ms and 0.285 ms,
1.6 s; the cube gripped between two pads, box and mesh, centred and 9.3 mm off. The worst creep over the three loads
and two steps, micrometres a second (the right answer is 0):

| Arm | Along 0 | Along 22.5 | Along 45 | The grips | Most iterations |
|---|---|---|---|---|---|
| MuJoCo's defaults | 2,150 | 490,220 | 743,398 | 6,054 to 8,083 | 3 |
| `impratio` 10 | 215 | 489,600 | 743,362 | 664 to 792 | 4 |
| `impratio` 100 | 21 | 489,529 | 743,448 | 66 to 79 | 4 |
| The elliptic cone | 946 | 946 | 946 | 3,374 to 3,725 | 2 |
| The elliptic cone, `impratio` 10 | 95 | 95 | 95 | 337 to 374 | 3 |
| Noslip, 10 iterations, under the default cone | 2,150 | 490,220 | 743,398 | 6,398 centred, 25 to 30 off centre | 12 |
| **Senua AI's configuration**: the elliptic cone with 10 noslip iterations | **0** | **0** | **0** | **0 to 1** | 6 |

Along 22.5 and 45 degrees the default cone's figures are a cube sliding away, not creeping: the pyramid gives at most
0.707 of the friction limit at 45 degrees and about 0.77 at 22.5, so 0.75 and 0.95 of the limit along 45, and 0.95
along 22.5, exceed it (finding F2). Every arm on the default cone carries that; the elliptic cone has no direction.

## Part B: MuJoCo pull request #3349, stiction, on its own builds

[Pull request #3349](https://github.com/google-deepmind/mujoco/pull/3349), "Static friction for elliptic contacts",
closed without being merged, stores the relative pose of each pair of touching bodies and adds a spring against slip
from it, for the elliptic cone only, behind a flag. It was built here exactly as its author left it: its head,
4c7bdaf6 (17 June 2026), and the commit it branched from, 55c6332f (16 June 2026), each from MuJoCo's own repository
(`build_check.txt`; both report MuJoCo 3.10's development header). [`pr3349.diff`](pr3349.diff) is the pull request's
diff as GitHub gives it: its changed lines are exactly those between the two commits (646 added, 7 removed, 20 files);
only the header lines differ from `git diff`'s.

Four arms, all on the elliptic cone: **june**, the commit it branched from; **off** and **on**, its head with the flag
unset and set; **cfg**, Senua AI's configuration on its head. The scenes: Part A's holds; a held cube (0.6 of the limit,
along 22.5 degrees) moved 2 mm from outside at 0.8 s (**teleport**); the same held cube shoved with 1.5 of the limit
from 0.7 to 0.75 s so it slips and stops somewhere new, with the state saved at 0.6 s restored at 1.2 s, beside the
same play without the detour (**restore**); and the pull request's own two demo scenes, [`ramp.xml`](ramp.xml) (a block
on a 30 degree ramp) and [`gripper.xml`](gripper.xml) (a box in a passive parallel-jaw grip), extracted from its diff
and played as its author wrote them (on), with the flag line removed (june, off: `ramp_noflag.xml`,
`gripper_noflag.xml`), and with it removed and 10 noslip iterations (cfg), 6 s each, read by the new scene rig
[`tools/mjc_scene.c`](../../tools/mjc_scene.c).

| | june | off | **on** (stiction) | **cfg** (Senua AI) |
|---|---|---|---|---|
| The holds, worst creep, um/s (18 plays) | 946 | 946 | **0** | **0** |
| Moved 2 mm from outside: creep after, um/s (both steps) | 597 | 597 | **31** | **0** |
| A state restored after a shove: the play the same as without the detour | yes | yes | **no**: the cube's height up to 107 um apart and its speed 474 mm/s apart summed over the play at 1.14 ms (29 um and 1,179 mm/s at 0.285 ms); it ends in the same place | **yes, byte for byte** |
| The pull request's ramp: creep, um/s; moved in 6 s | 8,020; 47.8 mm | 8,020; 47.8 mm | **0**; 0.40 mm | **0**; 0.15 mm |
| The pull request's gripper: creep, um/s; moved in 6 s | 17,276; 104 mm | 17,276; 104 mm | **0**; 1.37 mm | **0**; 1.57 mm |
| Most iterations | 4 | 4 | 4 | 8 |

- **Safe when off.** With its flag unset the pull request plays all 20 hold and demo files byte for byte as the
  commit it branched from (`measured.txt`). MuJoCo's own test suite, read test by test
  ([`suite_reread.sh`](suite_reread.sh), `suite_compare.txt`): all 1,681 of the earlier build's tests have a
  counterpart, and only two read differently, two memory-heavy reader tests killed for memory once in each build
  (`XMLReaderTest.LargeTextureAddressTest` on june, `XMLReaderTest.LargeTextureTest` on the pull request), alike in
  kind; the pull request adds 13 tests, all passing, among them its own nine stiction tests. The last line of
  `measured.txt`, the probe's own comparison, read the test names wrongly (it kept the parameter suffix some names
  carry, which holds spaces) and is not the reading; `suite_reread.sh` is.
- **The move from outside.** With stiction the cube, moved 2 mm, is pulled back toward the pose the pull request stored,
  at up to 2.2 mm a second, and rocks for about a quarter of a second before it settles (the speed column of `B/on/teleport_*`).
  Its stored pose is not told the body moved. Under Senua AI's configuration the cube does not move at all after the
  move.
- **The restored state.** The pull request keeps its stored poses in `mjData` but, by its own documentation, not in
  MuJoCo's saved state (`mj_getState`), to be reconstructed from the contacts after a restore; by its code, a pair
  still touching at the restore keeps the pose stored at the moment of the restore, not of the moment saved: the cube is pulled toward where the shove left it, and the play strays from the original (`gap`: the cube's height up to 107 um apart, its speed 474 mm/s apart summed) before the
  replayed shove brings it to the same end. Under Senua AI's configuration the restored play is the original byte
  for byte. Without stiction a restore is exact too (june, off).
- **The demos.** Both fixes hold the pull request's own ramp and gripper (no creep over the last 3 s); both settle a
  little at the start.

## What it shows

| Fix | For | Against |
|---|---|---|
| `impratio` | Slows the creep along an axis (2,150 to 215 and 21 um/s) and in the grips | Never stops it; no help with direction under the default cone |
| The elliptic cone alone | No direction | Still creeps (up to 946 um/s; grips 3.4 to 3.7 mm/s) |
| The elliptic cone with `impratio` 10 | No direction, creep cut tenfold | Still creeps (95 um/s; grips 337 to 374 um/s) |
| Noslip under the default cone | Slows the off-centre grips to 25 to 30 um/s | No effect along an axis or in the centred grips; the default cone's direction stays; 12 iterations |
| Pull request #3349, stiction | Holds every hold and its own two demos; safe when off; costs no extra iterations; its own nine tests pass | Elliptic cone only; a body moved from outside is pulled back and rocks; a restored state does not restore; 646 lines of new state, not merged |
| **Senua AI's configuration** | **Holds every hold and grip, and the pull request's own demos, to 0; a body moved from outside stays put; a restored state restores byte for byte; no new code** | About twice the solver iterations (6 to 8 against 3 to 4); noslip's other costs as MuJoCo documents them |

These are a probe's readings on throwaway numbers. A registered study decides.
