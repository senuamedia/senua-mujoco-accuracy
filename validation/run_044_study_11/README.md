# Run 044: Study 11, the fixes in the wild for a held object that creeps, played once

[`PREREGISTRATION_11.md`](../../preregistrations/PREREGISTRATION_11.md), played once by [`play.sh`](play.sh) from the
registered commit (e1c44e1), 16 October 2026, 04:57 to 05:11 UTC, on the first cloud machine (4 virtual CPUs, 8 GB).
The study's page: [Study 11](../../docs/studies/11-fixes-in-the-wild.md). Every reading is Senua AI's measuring
program's (`creep`, `gap`, `ends`), in [`measured.txt`](measured.txt); every rule is judged by `sx_contact rule`, in
[`rules.txt`](rules.txt). The draw is in [`draw.txt`](draw.txt), the settings in [`parameters.txt`](parameters.txt).

**58 rule lines, 37 held.** Senua AI's configuration held every line it was put to, on MuJoCo's release (4 of 4) and
on the pull request's head (7 of 7). Every other fix failed at least one.

## Part A: MuJoCo's own options, on its 3.16.0 release

The 1.381 kg cube (friction 0.369, its limit 4.994 N) held with 0.5, 0.75 and 0.95 of the limit along 0, 22.5 and 45
degrees at 1.65 and 0.4125 ms; the 0.218 kg cube gripped between two pads, box and mesh, centred and 7.9 mm off. The
worst creep, um/s (the right answer is 0; the bound 10):

| Arm | Along 0 | Along 22.5 | Along 45 | The grips | Most iterations | Lines held |
|---|---|---|---|---|---|---|
| MuJoCo's defaults | 2,006 | 463,781 | 704,321 | 6,991 to 7,737 | 3 | 2 of 4 |
| `impratio` 10 | 201 | 463,224 | 704,371 | 738 to 813 | 4 | 2 of 4 |
| `impratio` 100 | 20 | 463,115 | 704,353 | 74 to 81 | 4 | 2 of 4 |
| The elliptic cone | 895 | 895 | 895 | 3,541 to 3,806 | 2 | 2 of 4 |
| The elliptic cone, `impratio` 10 | 89 | 89 | 89 | 354 to 382 | 3 | 2 of 4 |
| Noslip, 10 iterations, under the default cone | 2,006 | 463,781 | 704,321 | 7,103 to 7,198 | 10 | 2 of 4 |
| **Senua AI's configuration** | **0** | **0** | **0** | **0 to 1** | 6 | **4 of 4** |

- Every arm on the default cone carries the pyramid's direction (finding F2): pushed with 0.75 of the limit along 45
  degrees, and with 0.95 along 22.5 and 45, the cube slides away (124 to 704 mm/s), whatever else the arm does.
- **`impratio`** cuts the creep along an axis roughly in proportion: at half the limit 542, 54 and 5 um/s at
  `impratio` 1, 10 and 100. It never reaches 0, and at 100 only the half-limit push is under the bound.
- **The elliptic cone** has no direction: the same creep along every direction, 471, 707 and 895 um/s at the three
  loads; with `impratio` 10, 47, 71 and 89.
- **Noslip under the default cone** holds the half-limit push in every direction (0 um/s), and changes nothing at 0.75
  or 0.95 of the limit, nor in the grips. Run 043 read the same holds; its off-centre grips (25 to 30 um/s there) did
  not repeat here.
- Every arm's MuJoCo solver stayed off its iteration limit and raised no warning.

## Part B: pull request #3349, stiction, on its own builds

Built from MuJoCo's own repository (`build_check.txt`: the head's changed lines are run 043's `pr3349.diff`'s, both
sha256 75f2248690ba6290...). Four arms on the elliptic cone: **june**, the commit the pull request branched from;
**off** and **on**, its head with the flag unset and set; **cfg**, Senua AI's configuration on its head.

| Rule | june | off | **on** (stiction) | **cfg** (Senua AI) |
|---|---|---|---|---|
| H every hold holds (worst, um/s) | failed (895) | failed (895) | **held (0)** | **held (0)** |
| T moved 2 mm from outside, it stays (creep after, um/s) | failed (565) | failed (565) | **failed (29)** | **held (0)** |
| S a restored state replays, at each step | held, held | held, held | **failed, failed** | **held, held** |
| D the pull request's own demos hold (ramp, gripper, um/s) | failed (8,020, 17,276) | failed (8,020, 17,276) | **held (0, 0)** | **held (0, 0)** |
| V the solver, no limit, no warning | held | held | held | held |
| Lines held | 4 of 7 | 4 of 7 | **4 of 7** | **7 of 7** |
| Most iterations | 4 | 4 | 4 | 8 |

- **Moved from outside.** With stiction, the cube moved 2 mm is pulled back toward the pose the pull request stored, at
  up to 3.1 mm a second at 1.65 ms (0.77 mm a second at 0.4125 ms), for about a tenth of a second, then creeps at 29
  um/s to the end (`B/on/teleport_*.txt`). Under Senua AI's configuration it does not move after the move.
- **A restored state.** With stiction the restored play is not the original: the cube's height up to 120 um apart (38
  um at the fine step), 8,222 um summed over the play (7,542), its speed 604 mm/s summed (734); the replayed shove
  brings it to the same end (0 nm, 0 um/s). Under Senua AI's configuration, and without stiction, the restored play is
  the original byte for byte.
- **The pull request's demos.** Its ramp and gripper hold under stiction (moved 0.40 mm and 1.37 mm in 6 s, all of it
  at the start) and under Senua AI's configuration (0.15 mm and 1.57 mm); without either the block slides 47.8 mm down
  the ramp and the box drops 104 mm out of the grip.

**The pull request, safe when off (E1, E2, held).** With its flag unset it plays all 20 hold and demo files byte for
byte as the commit it branched from. MuJoCo's own suite passed in full on both builds: 1,679 tests and then the two
memory-heavy `LargeTexture` tests on their own, on june; 1,692 and the same two on the pull request's head
(`progress.txt`, `ctest_*.txt`). The test-by-test re-read (`suite_compare.txt`) found no test reading differently and
the pull request's 13 added tests, all passing (`StictionTest`'s nine, and its two scene files in MuJoCo's two
whole-model tests).

One slip in that re-read, found after the run: in the separate run of the two `LargeTexture` tests ctest pads one name,
`XMLReaderTest.LargeTextureAddressTest`, with three dots instead of four, so `suite_reread.sh` kept its duration in its
name and could not pair it across the builds (it is listed once as only on the pull request and once as only on june).
Both builds passed it (`ctest_june_large.txt`, `ctest_pr_large.txt`: "Passed"), so every one of the 1,681 tests of
the earlier build reads the same on the pull request's head, and E2's decision stands. The script is left as
registered and run.

## Not ruled

The iterations: Senua AI's configuration took 6 (release) and 8 (pull request's head) at most, against 2 to 4 for the
others but noslip under the default cone (10).
