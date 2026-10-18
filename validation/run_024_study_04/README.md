# Run 024: the fourth registered study, played once

Played 15 October 2026 (07:57 UTC, `played_at.txt`) on the cloud machine (2 virtual CPUs), by [`play.sh`](play.sh),
under [`preregistrations/PREREGISTRATION_04.md`](../../preregistrations/PREREGISTRATION_04.md), pushed before any play.
The slip-aligned pyramid's third version (`patches/in_design/slip_aligned_pyramid_v3.diff`, sha256 58a65674e1c61dd9...),
rebuilt by the runner from the registered patch file, on fresh scenes, against Google DeepMind's Linux release, with
MuJoCo's own test suite run on and off. Every measured number is in `measured.txt`, every rule's line in `rules.txt`.
The dry run (`dry/`, the release and reference folders only, throwaway parameters) ran to the end and wrote all 43
measured lines; no rule was read from it.

**The result: 29 of 32 rule lines held. The study does not hold, and the patch stays in design.** Both of Study 3's
failures were answered as registered: R1 held, every one of the off arm's 102 files byte-identical to the release's.
Two rules failed, R9 on one line of four and R11 on both of its lines, each by a bound tighter than MuJoCo's own
direction-free cone keeps on these scenes.

| Rule | Measured | |
|---|---|---|
| R1 safe when off, plays | 102 of 102 files byte-identical, the statistics file included | held |
| R2 safe when off, MuJoCo's suite | All 3,492 tests as the release (see below) | held |
| R3 the defect is there | Released, 1.5 ms: 73,248 um along 25 degrees and 82,913 along 50, against 59,065 along 0 (24% and 40% further) | held |
| R4 no direction, slide | On: 59,065 um along all five directions at 1.5 ms, 59,586 at 0.375 ms | held |
| R5 no drift | On: 0 um along every direction, both steps | held |
| R6 Coulomb | On, 0.375 ms: 59,586 um against 59,455 (0.22%) | held |
| R7 no direction, hold | On: 2,841 um/s at 0.76 and 3,973 at 0.93 of the limit, along all five directions | held |
| R8 the released hold lets go | Released at 0.93 along 50 degrees: 931,592 um/s against 3,973 along 0 | held |
| R9 the moving floor, on | On: 166 and 166, 206 and 206 steps at 1.5 ms, against the elliptic cone's; 844 and 841 at 0.375 ms with the floor slipping at 50 degrees; **685 and 681 with it slipping at 25 degrees**, 4 steps where the rule allowed 3 | **failed on one line** |
| R10 the moving floor, released | Released: 30 to 234 steps from the elliptic cone's | held |
| R11 free cube | On: 59,615, 60,167, 59,449 and 59,562 um along 25 to 85 degrees against 59,437 along 0, **within 1.23%** where the rule allowed 1%; drift **up to 1,176 um** where it allowed 1,000 | **failed** |
| R12 the frame and the turned-contact tests | On: `ContactStage`, `ContactVelocity`, `SleepingUnaffectedByWaking`, `FoldDenseBlocksSolveMatches`, `DiscreteStiffLegPress` pass | held |
| R13 nothing else changes | On: 72 of 72 suite files byte-identical; in MuJoCo's suite only `InverseTest.DiscreteInverseFreeBody` changes (the lift) | held |
| R14 the solver | On: no step at the limit, no warning, at most 7 iterations against 6 released | held |

**MuJoCo's suite on this machine.** One test, `XMLReaderTest.LargeTextureAddressTest`, was killed by the kernel for
memory in all three arms (the machine has 3.8 GB and no swap; the test reached 2.3 to 3.0 GB, `dmesg`), so it reads the
same in each and R2 and R13 compare like with like. On Study 3's 16-CPU machine it passed in all three.

## The two rules that failed

**R9, by one step on one line, where MuJoCo's two cones differ by more.** Its bound, 3 steps, was set before the study
from run 023's diagnostic, the largest difference between MuJoCo's own pyramid and elliptic cone on Study 3's scenes. On
these scenes the registration's reported control, the release's two cones sliding the cube along x on a still floor at
the moving floor's slip speeds, where the pyramid has no direction, finds them 1 step apart at 1.5 ms (167 and 166, 209
and 208) and **5 and 4 steps apart at 0.375 ms** (688 and 683, 856 and 852). The aligned pyramid on the moving floor is
4 and 3 steps from the elliptic cone there, within the two cones' own difference; the released pyramid is 30 to 234 away.

**R11, where MuJoCo's own direction-free cone spreads the free cube further.** A diagnostic after the study
([`diag_r11.sh`](diag_r11.sh), `diag_r11.txt`, pushed before its plays, changing no verdict) slid the same free cube along
the same five directions under the release's elliptic cone, which has no direction: it slides 59,611, 60,587, 60,054,
61,397 and 61,830 um along 0 to 85 degrees, **within 3.7%**, and drifts **up to 917 um**. The aligned pyramid keeps the
free cube within 1.23% and 1,176 um; the released pyramid spreads it by 39% (82,758 um along 50 degrees against 59,437
along 0) and drifts it up to 14.0 mm. A free cube turns as it slides and its contact moves over the face; neither cone
keeps it within 1%, and the rule's bound was tighter than MuJoCo's isotropic cone on this cube.

## What it shows

With the switch on, every direction slides, holds and stops alike: no direction, no drift, Coulomb's distance within
0.22%, the holds the release loses kept, a moving floor within 4 steps of MuJoCo's own direction-free cone where the
release is 30 to 234 away, the frame and its sensors as released, every one of MuJoCo's tests as before but the one the
lift explains. With it unset, every play and every test is as released, and Study 3's accounting failure is gone. Under
the registration the study does not hold, and the third version stays in design.

Two studies have now failed the third version only on bounds fixed from other scenes that MuJoCo's own cones do not
keep on the scenes played: a bound taken from one set of scenes did not carry to fresh ones. The right reference for "no
direction" is MuJoCo's own elliptic cone on the same scene in the same run, as run 023's README proposed; this study
measured it for the moving floor (reported) and, after the study, for the free cube.

**The lift, reported:** with the switch on the cube lifts as much along every direction as along x, 318 um at 1.5 ms
along all five against the release's 318, 236, 137, 140 and 299; 33 um at 0.375 ms against 33, 23, 51, 67 and 37.

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 59,065 um | 59,075 um |
| 59,437 um | 59,445 um |
| 59,449 um | 59,462 um |
| 59,562 um | 59,570 um |
| 59,586 um | 59,598 um |
| 59,611 um | 59,618 um |
| 59,615 um | 59,623 um |
| 60,054 um | 60,063 um |
| 60,167 um | 60,174 um |
| 60,587 um | 60,605 um |
| 61,397 um | 61,405 um |
| 61,830 um | 61,838 um |
| 73,248 um | 73,261 um |
| 82,758 um | 82,770 um |
| 82,913 um | 82,924 um |

Every rule line of the study whose inputs the correction changes was judged again by `sx_contact rule` with the
corrected readings ([`rejudge.txt`](../audit/measure_correction/rejudge.txt)): no verdict changes.
