# Run 077: Study 16, the box-on-box clip without its collinear vertices, for a straight stack

17 October 2026 (02:14 to 02:48 UTC). The sixteenth registered study,
[`PREREGISTRATION_16.md`](../../preregistrations/PREREGISTRATION_16.md), played once on the first cloud machine by
[`play.sh`](play.sh), the runner as registered (sha256 884b1df3d15cc33e...). The rule lines are in [`rules.txt`](rules.txt),
the readings in [`measured.txt`](measured.txt), the draw in [`draw.txt`](draw.txt). The stacks' play files are kept
compressed.

## Result: 15 of 15 rule lines held

The fresh stack cube is 0.596 kg, half-size 40.5 mm, friction 0.528. Its straight stacks of 3, 5, 9 and 12 were played at
1.22, 0.305 and 0.1525 ms, each at MuJoCo's default main tolerance and at 1e-10 and 1e-12: 36 plays an arm.

| The 36 straight stacks | Plays tilting more than 100 urad | The most tilt | Contact changes after step 30, all plays |
|---|---|---|---|
| Released, the configuration (rel_rec) | 8 | 10,919 urad | 4,471 |
| The set's three patches (set_rec) | 9 | 9,022 urad | 3,864 |
| **The set with the collinear patch (set4_rec)** | **0** | **0** | **0** |
| Released, MuJoCo's defaults (rel_def) | 0 | 0 | 0 |
| The collinear patch alone, MuJoCo's defaults (col_def) | 0 | 0 | 0 |

With the four switches set, every straight stack stood, no face's contacts changed, and every cube was at rest at the
end (S1, S2, S3). Released, the stacks that tilted were 9 and 12 cubes high, at each of the three steps and each of the three tolerances. Under
MuJoCo's defaults no straight stack tilted, released or patched. There, S4 and N2 show the patch changes nothing that
stands; they do not show it fixing anything.

With every switch unset, all 576 play files under each option set are byte for byte the release's, and every one of
MuJoCo's 3,492 tests gives the release's result (E1, E2). With the four switches set, the only tests that change are the
two Study 12 named (M1). With the collinear switch alone, none changes (M2). Each of the four readings listed all 3,492
tests (M0). Study 15's arm, the held cube, the slide on a box's face and the grips are byte for byte the same with the
collinear switch as without it, in the set (N1, 32 of 32 files) and alone (N2, 32 of 32). No step reached the iteration
limit, and there was no warning (V1).

## What it decides

As registered:

- **Issue 21, a straight stack does not stand at a fine step under the recommended configuration: fixed and validated**
  by Senua AI's set with the collinear patch. The patch,
  [`boxbox_collinear.diff`](../../patches/boxbox_collinear.diff), moves from `patches/in_design/` to `patches/`.
- Under MuJoCo's defaults, the patch alone changes no stack that stands and nothing else.

Not decided: issue 9 (a stack sinks, and an offset stack leans); boxes of unequal size and plates; RK4; MuJoCo's PGS
solver; anything against a real robot.

## Reported, not ruled

| At 0.305 ms | Released, MuJoCo's defaults | Released, the configuration | The set | The set with the collinear patch |
|---|---|---|---|---|
| A stack of 3 offset by 1 mm a cube | 96 urad | 2,386 urad, 438 contact changes | 2,375, 376 | 2,313, 291 |
| Offset by 17 mm a cube | 2,208 urad | 10,682, 69 | 10,682, 69 | 10,592, 71 |
| A stack of 5 on a fixed box | 0 | 0, 4 changes | 0, 7 | 0, 0 |

The offset stacks lean in every arm, as runs 075 and 078 found (issue 9). The most iterations on a step were 25 with the
set's switches set, 6 released.

## Files

The seven arms' plays are in `rel_def`, `rel_rec`, `off_def`, `off_rec`, `set_rec`, `set4_rec` and `col_def` (`stacks`,
compressed, and `other`). MuJoCo's test output is in `ctest_*.txt`, read into `suite_results_*.txt`. The dry run and the
rules plumbing check are in [`dry/`](dry/).
