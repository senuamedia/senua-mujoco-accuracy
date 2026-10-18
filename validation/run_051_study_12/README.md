# Run 051: Study 12, the de Saxce patch's fourth version on fresh numbers

16 October 2026, 10:25 to 10:37 UTC, on the first cloud machine (AWS EC2 c7i.xlarge, Intel, 4 virtual CPUs, 8 GB).
Played once by [`play.sh`](play.sh), as registered in
[`PREREGISTRATION_12.md`](../../preregistrations/PREREGISTRATION_12.md), pushed with its runner, dry run and rules
plumbing check (commit 05d8b64) before this play. The study's page: [Study 12](../../docs/studies/12-desaxce-elliptic.md).

The patch, [`patches/in_design/desaxce_elliptic_v4.diff`](../../patches/in_design/desaxce_elliptic_v4.diff) (sha256
00cb8f8eb4a07535...), was built from MuJoCo's source at `UPSTREAM_COMMIT` ([`patch_check.txt`](patch_check.txt)); its
library and tests built with exit 0 ([`progress.txt`](progress.txt)). The numbers were drawn from seed 12
([`draw.txt`](draw.txt), [`parameters.txt`](parameters.txt)). Every measured line is in [`measured.txt`](measured.txt);
every rule, judged by `sx_contact rule`, in [`rules.txt`](rules.txt).

## The outcome

**43 of 43 rule lines held**: 12 shared, 17 under Senua AI's configuration (on_rec) and 14 under the elliptic cone alone
(on_ell). Every decision of the registration holds: issues 4 and 5 are fixed and validated under the elliptic cone, with
Senua AI's configuration and with the elliptic cone alone; nothing held is touched.

## The readings

| | Released, the configuration | Switch set, the configuration | Switch set, the elliptic cone alone |
|---|---|---|---|
| The cube slid kept from turning, highest above the ground at 10, 2.5, 0.625, 0.156 ms | 4,442, 359, 51, 9 um | **0, 0, 0, 0** | **0, 0, 0, 0** |
| The same at 1.16 and 0.29 ms | 109, 28 um | **0, 0** | **0, 0** |
| The cube free to turn, slid along 0 to 45 degrees, 1.16 ms | 88,051 to 89,432 um | **88,012 along every one** | **88,017 along every one** |
| The same at 0.29 ms (Coulomb's distance 88,323 um) | 88,386 to 90,079 um | **88,374 along every one** | **88,380 along every one** |
| Its largest drift across its line; its largest turn | 790 um; 36,325 urad | **0; 0** | **0; 0** |
| Its steps on fewer than four corners, over the ten slides | 2,867 | **0** | **0** |
| The 18 holds and 8 grips | 0 um/s, the grips 0 or 1 | **the same, every file byte for byte** (35 of 35) | as released, 484 to 4,170 um/s (finding F1: the elliptic cone alone does not hold) |
| The first suite's ten tests | 10 of 10 | **10 of 10** | 9 of 10, as released (T06, the hold) |
| The most iterations on a step; at the limit; warnings | 15; 0; 0 | 16; 0; 0 | 14 (7 released); 0; 0 |

The release under the elliptic cone alone reads as under the configuration on every slide: a lift of 4,442 um at 10 ms,
a drift up to 791 um, 2,812 steps on fewer than four corners.

**Safe when off**: with the switch unset every file of every option set is byte for byte the release's (164 of 164,
three times) and every one of MuJoCo's 3,492 tests gives the release's result (all passed). **The pyramidal cone is
untouched**: with the switch set under MuJoCo's defaults, 164 of 164 files the release's.

**MuJoCo's own tests with the switch set**: two of 3,492 fail, the two named in advance and no other
(`suite_results_on.txt`): `ForwardTest.DiscreteImplicitRowNoslip`, whose released scene never comes to rest (finding
F13; the test passes released because its last step falls on the slow step of a cycle, and the switch moves the
cycle's phase), and `SolverTest.ZeroToleranceDisablesTermination`, which pins one solve's iteration count while the
patch's fixed point adds its own passes' iterations.

## The stacks (reported, not ruled)

The most tilt of any cube over 2 s, and at the last step the largest speed of any cube:

| | 5 cubes, 1.16 ms | 9 cubes, 1.16 ms | 5 cubes, 0.29 ms | 9 cubes, 0.29 ms |
|---|---|---|---|---|
| Released, the configuration | 0, 0 | 0, 3 um/s | 0, 513 um/s | 0, 37 um/s |
| Switch set, the configuration | 0, 0 | **4,750 urad, 5,171 um/s** | 0, 141 um/s | **6,501 urad, 3,160 um/s** |
| Released or switch set, the elliptic cone alone; MuJoCo's defaults | 0, 0 | 0, 0 | 0, 0 | 0, 0 |

**Under the configuration the switch tips the stack of 9 at both steps, where released it does not tilt.** This was not
seen on Study 10's numbers at 1.14 ms (run 049, where both stood) and was not ruled; it is a cost of the patch with
noslip, recorded under finding F14 (issue 21), which stays open. Under the elliptic cone alone every stack stands,
released and with the switch set.

## Files

The arms' plays are in `rel_*`, `off_*` and `on_*` (`cubes`, `held`, `stacks`, `suites`); MuJoCo's test output in
`ctest_*.txt`, read into `suite_results_*.txt`; the dry run, played before the registration, in [`dry/`](dry/).

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 88,012 um | 88,024 um |
| 88,017 um | 88,029 um |
| 88,051 um | 88,063 um |
| 88,374 um | 88,390 um |
| 88,380 um | 88,395 um |
| 88,386 um | 88,402 um |
| 88,386 um | 88,403 um |
| 89,432 um | 89,446 um |
| 90,079 um | 90,095 um |

Every rule line of the study whose inputs the correction changes was judged again by `sx_contact rule` with the
corrected readings ([`rejudge.txt`](../audit/measure_correction/rejudge.txt)): no verdict changes.
