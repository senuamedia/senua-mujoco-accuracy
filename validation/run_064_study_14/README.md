# Run 064: Study 14, the friction solved in the directions that can move, for an arm resting on a contact

16 October 2026, 13:07 to 13:18 UTC, on the first cloud machine (AWS EC2 c7i.xlarge, Intel, 4 virtual CPUs, 8 GB).
Played once by [`play.sh`](play.sh), as registered in
[`PREREGISTRATION_14.md`](../../preregistrations/PREREGISTRATION_14.md), pushed with its runner, dry run and rules
plumbing check (commit 0b98a08) before this play. The study's page: [Study 14](../../docs/studies/14-qcqp-reduced.md).

The patch, [`patches/in_design/qcqp_reduced.diff`](../../patches/in_design/qcqp_reduced.diff) (sha256
22f07ccf8abf316e...), built from MuJoCo's source at `UPSTREAM_COMMIT` ([`patch_check.txt`](patch_check.txt)); library
and tests built with exit 0. Numbers drawn from seed 14 ([`draw.txt`](draw.txt), [`parameters.txt`](parameters.txt));
every measured line in [`measured.txt`](measured.txt); every rule, judged by `sx_contact rule`, in [`rules.txt`](rules.txt).

## The outcome

**13 of 15 rule lines held. The study's decision does not hold**: R2 (every dropped arm holds) and K1 (the ten tests)
failed. Issue 1 is not recorded as fixed by it, and the patch stays in design. What the patch is for, an arm resting on a
contact, held on these fresh numbers: every resting play at 0 (R1).

## The readings

| | Released, the configuration | Switch set, the configuration |
|---|---|---|
| The arm set down on its ball, poses 1 to 4, as written and mirrored, the ball's creep | 497, 31, 102 and 22 um/s | **0 in every play, at both steps** (R1 held) |
| The arm dropped onto its ball, poses 1 to 4, mean speed over the play's second half, 1.19 ms; 0.2975 ms | 324, 25, 311, 119; 323, 9, 313, 109 um/s | 0, **50**, 0, 7; 0, **66**, 0, 2 (R2 failed) |
| Every other play file (the arm held by joint friction, the cubes, the grips, the suite) | | **byte for byte as released**, 89 of 89 (N1) |
| The arm held by joint friction; the 18 holds; the 8 grips | 2; 0; 0 or 1 um/s | the same (J1, H1, G1) |
| The first suite's ten tests | 9 of 10 (T08) | 9 of 10 (T08), the suite's files byte for byte as released (K1 failed) |
| MuJoCo's own tests | 3,492 passed | 3,492 passed, none changed (M1) |
| The most iterations on a step | 20 | 20; none at 100, no warning (V1) |

With the switch unset every file under both option sets is the release's (129 of 129, twice) and every one of MuJoCo's
tests gives the release's result; with it set, under MuJoCo's defaults, every file is the release's (P1).

## Why R2 and K1 failed

**R2.** Dropped in its second pose, the arm lands and its ball slides along the ground at up to 285 mm/s, its sideways
force at its friction limit (0.67 of the normal force, the friction 0.667): a real slide, in both arms alike. With the
switch set the ball comes to rest 0.61 s into the play and holds at 0 to its end; released it never comes to rest and
creeps at 89 um/s to the end. R2 read the second half of the play, from 0.5 s, and caught the last 0.11 s of the slide
(the registration named this risk).

**K1.** The first suite's T08, its refinement chain falling at every step, fails under the configuration on this
study's suite cube, released and patched alike (the suite's files are the release's): 83,213, 25,898, 11,754, 6,154,
2,928, 3,469 um. It is not this patch's. [Run 065](../run_065_suite_t08/README.md), a probe, found it the same under the
elliptic cone alone and with 10 or 100 noslip iterations, passing under MuJoCo's defaults, and passing with the de Saxce
patch (issue 4, a sliding body hops), under which the configuration passes all ten.

## Files

The arms' plays in `rel_*`, `off_*` and `on_*` (`resting`, `held`, `cubes`, `suites`); MuJoCo's test output in
`ctest_*.txt`, read into `suite_results_*.txt`; the dry run in [`dry/`](dry/).
