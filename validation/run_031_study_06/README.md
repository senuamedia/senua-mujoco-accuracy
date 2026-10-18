# Run 031: the sixth registered study, played once

Played 15 October 2026 (09:46 UTC, `played_at.txt`) on the second cloud machine (4 of its 8 virtual CPUs; its MuJoCo
release, checksum 139577c541d43716..., and its measuring program the same files as the first machine's, and recorded
plays of runs 024 to 027 made there byte for byte before the dry run), by
[`play.sh`](play.sh), under [`preregistrations/PREREGISTRATION_06.md`](../../preregistrations/PREREGISTRATION_06.md),
pushed before any play. The slip-aligned pyramid's third version (sha256 58a65674e1c61dd9...), rebuilt by the runner from
the registered patch file, against Google DeepMind's Linux release, with MuJoCo's own test suite on and off; MuJoCo's
release source and its test build (run 020's recipe) made on that machine from the pinned commit. Every measured number
is in `measured.txt`, every rule's line in `rules.txt`. The dry run (`dry/`) ran to the end and wrote all 48 measured
lines; no rule was read from it.

**The result: 31 of 32 rule lines held. The study does not hold, and the patch stays in design.** R11, now judged
against MuJoCo's elliptic cone on the same free cube in the same run, held with room; R9, now bounded by MuJoCo's own
pyramid against its elliptic cone along an axis in the same run, held on three lines of four and failed on the fourth
by one step.

| Rule | Measured | |
|---|---|---|
| R1 safe when off, plays | 102 of 102 files byte-identical, the statistics file included | held |
| R2 safe when off, MuJoCo's suite | All 3,492 tests as the release (every test passed on this machine, `XMLReaderTest.LargeTextureAddressTest` included) | held |
| R3 the defect is there | Released, 1.2 ms: 128,114 um along 33 and along 57 degrees, against 95,567 along 0 (34% further) | held |
| R4 no direction, slide | On: 95,567 um along all five directions at 1.2 ms, 96,021 at 0.3 ms | held |
| R5 no drift | On: 0 um along every direction, both steps | held |
| R6 Coulomb | On, 0.3 ms: 96,021 um against 95,929 (0.10%) | held |
| R7 no direction, hold | On: 1,863 um/s at 0.74 and 2,642 at 0.91 of the limit, along all five directions | held |
| R8 the released hold lets go | Released at 0.91 along 33 degrees: 593,305 um/s against 2,642 along 0 | held |
| R9 the moving floor, on | On against the elliptic cone, with MuJoCo's own two cones along x as the bound: 258 and 258 (bound 1), 304 and 303 (1) at 1.2 ms; 1,050 and 1,048 (2) at 0.3 ms slipping at 20 degrees; **1,233 and 1,229 at 0.3 ms slipping at 42 degrees, 4 steps where MuJoCo's own cones were 3 apart** | **failed on one line** |
| R10 the moving floor, released | Released: 45 to 364 steps from the elliptic cone's | held |
| R11 free cube | On: spread 173 um across the five directions against the elliptic cone's 4,070; largest drift 93 um against its 365 | held |
| R12 the frame and the turned-contact tests | On: all five of MuJoCo's tests pass | held |
| R13 nothing else changes | On: 72 of 72 suite files byte-identical; in MuJoCo's suite only `InverseTest.DiscreteInverseFreeBody` changes (the lift) | held |
| R14 the solver | On: no step at the limit, no warning, at most 7 iterations against 6 released | held |

## The rule that failed

**R9, by one step on one line of four.** On the floor moving so the cube slips at 42 degrees, at 0.3 ms, the aligned
pyramid's cube stops at step 1,233, the elliptic cone's at 1,229: 4 steps apart, 1.2 ms in a slide of 0.37 s. On a still
floor along x at the same slip speed, MuJoCo's own pyramid and elliptic cone stop at 1,242 and 1,239, 3 apart, and the
rule allowed no more than that. On the other three lines the aligned pyramid was within MuJoCo's own difference (0
against 1, 1 against 1, 2 against 2). The released pyramid on the same floors is 45 to 364 steps away.

## What it shows

With the switch on, every direction slides, holds and stops alike: no direction, no drift, Coulomb's distance within
0.10%, the holds the release loses kept, a free cube spreading 24 times less than under MuJoCo's own elliptic cone, a
moving floor within 4 steps of the elliptic cone where the release is 45 to 364 away, the frame and its sensors as
released, and every one of MuJoCo's tests as before but the one the lift explains. With it unset, every play and every
test is as released. Under the registration the study does not hold, and the third version stays in design.

Across Studies 3, 4 and 6, on three sets of fresh scenes, everything the third version is for has held every time. What
has failed, after the runner's accounting, is the moving floor at the finer step and Study 4's free cube, each by a bound
of one or a few steps, or about 1%, that MuJoCo's own direction-free cone does not keep against its own pyramid on the
same scenes; in this study by one step beyond MuJoCo's own two cones' difference. Whether a fourth registration should
judge the moving floor at the finer step by any step bound at all is not a question this run answers, and none is made
here.

**The lift, reported:** with the switch on the cube lifts as much along every direction as along x, 212 um at 1.2 ms
along all five against the release's 212, 194, 190, 190 and 194; 61 um at 0.3 ms against 61, 46, 31, 31 and 46.

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 95,567 um | 95,579 um |
| 96,021 um | 96,034 um |
| 128,114 um | 128,131 um |

Every rule line of the study whose inputs the correction changes was judged again by `sx_contact rule` with the
corrected readings ([`rejudge.txt`](../audit/measure_correction/rejudge.txt)): no verdict changes.
