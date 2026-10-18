# Fourth pre-registration: the slip-aligned pyramid's third version, on fresh scenes

Registered 15 October 2026, after Study 3 (run 023). Registered before any play of this registration existed. To be
played once, as run 024.

## Why a fourth registration

Study 3 ([`PREREGISTRATION_03.md`](PREREGISTRATION_03.md), run 023) held 29 of its 32 rule lines and so did not hold.
Its registration and its verdict stand unchanged. Of its two failed rules, run 023's README records:

- **R1 failed in the runner's accounting.** The release arm alone made the elliptic cone's reference plays on the
  moving floor, and the runner left their play files out of R1 but not their four lines in the release arm's
  statistics file. Every play file the off arm made was byte-identical to the release's, and so was every other line of
  the statistics file.
- **R9's bound was tighter than MuJoCo's two cones agree with each other.** The aligned pyramid stopped 2 steps after
  MuJoCo's elliptic cone on the moving floor at 0.375 ms, where the rule allowed 1. Run 023's diagnostic
  ([`diag_r9.txt`](../validation/run_023_study_03/diag_r9.txt), after the study, changing no verdict) slid the same
  cube on a still floor along x, the pyramid's own axis, where the pyramid has no direction, at the moving floor's two
  slip speeds: MuJoCo's own pyramid stopped 2, 1, 2 and 3 steps after its elliptic cone (200 and 198, 257 and 256 at
  1.5 ms; 815 and 813, 1,048 and 1,045 at 0.375 ms).

A failure is revisited only by a later study on fresh numbers. This one asks Study 3's question again on scenes never
used in the record, with exactly two changes, both made before any of its data exists:

1. **The runner's accounting.** The reference plays under the elliptic cone are made in a folder of their own
   (`reference/`, the release library), with their own statistics file. The release, off and on arms then make exactly
   the same plays, and R1 compares every file the release arm makes, its statistics file included. R14's figure for
   the release is read over the release arm's own plays; Study 3's runner also counted the elliptic reference plays in
   it.
2. **R9's bound is 3 steps**, the largest difference run 023's diagnostic measured between MuJoCo's own pyramid and its
   elliptic cone with no direction in play.

Every other rule is Study 3's, worded as there, on the fresh scenes' numbers. The patch file, its switch, the arms and
the builds are Study 3's.

## The question

On fresh scenes: does MuJoCo as released still give friction a direction, on a still floor and on a moving one; with
the switch on, is the slide and the hold the same along every direction played and Coulomb's, and does a moving floor
stop a sliding cube as MuJoCo's own direction-free cone does, within the two cones' own difference; is the frame as
released and does nothing else change, in this record's plays and in MuJoCo's own test suite; and with the switch
unset, is the patched MuJoCo the release, byte for byte and test for test?

The lift is not corrected by this version and is not a rule (runs 020 to 023). It is measured and reported.

## Engines and arms

- **release**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
  139577c541d43716...), MuJoCo's own defaults (pyramidal cone, Euler, 100 iterations).
- **off**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with
  `patches/in_design/slip_aligned_pyramid_v3.diff` (sha256 58a65674e1c61dd9...) applied, as in runs 022 and 023 (gcc,
  CMake and Ninja, a Release build; its tests built the same way), rebuilt by the runner from the patch file; switch
  unset.
- **on**: the same build, `MUJOCO_SLIP_ALIGNED_PYRAMID=1`.
- **reference**: the release, in a folder of its own: under `cone="elliptic"` on the moving floor, R9's and R10's
  reference; and on a still floor along x, reported only (below).

MuJoCo's own test suite is run on the release's test build (run 020's, from the release source) and on the patched
test build, switch unset and set. Rigs as committed at this registration (`tools/mjc_contact.c`, `tools/mjc_pair.c`);
measured by Senua AI's `sx_contact` (source sha256 87e921cd4d2c03bf..., as for Study 3, built for Linux) and judged by
its `rule`.

## The scenes, registered parameters

None of these physical numbers was used in the record before, except the first deep dive's two contact suites, played
with their own registered parameters. The two steps are Study 3's: they are the steps at which run 023's diagnostic
measured how far MuJoCo's two cones differ, from which R9's bound is taken. The plays' durations and the hold's timing
are Study 3's.

- **The cube**: 1.15 kg, half-size 0.038 m, friction 0.62, held level (`lock=1`) unless a line says free.
- **The slide**: set sliding at 0.85 m/s along 0, 25, 50, 70 and 85 degrees from x, 1 s, at 1.5 ms and 0.375 ms.
  Coulomb's distance: 0.85^2 / (2 x 0.62 x 9.8) = 59,455 um.
- **The hold**: pushed from 0.35 s along 0, 25, 50, 70 and 85 degrees with 0.76 and 0.93 of what friction can hold
  (0.62 x 1.15 x 9.8 = 6.9874 N: 5.310424 N and 6.498282 N), 1.4 s, at 1.5 ms. The release's diamond holds along a
  direction t only up to 1 / (|cos t| + |sin t|) of the limit: 0.75 along 25, 0.71 along 50, 0.78 along 70, 0.92
  along 85 degrees.
- **The moving floor**: the cube set sliding at 0.85 m/s along x on a floor moving along y at 0.3963615094 m/s and at
  1.0129905537 m/s (MuJoCo's `surfacevel`), so that it slips at 25 and 50 degrees to the frame's axes, 0.8 s, at
  1.5 ms and 0.375 ms; each also played in the reference folder under the elliptic cone.
- **The free cube**: the slide with the cube on a free joint (`lock=0`), along 0, 25, 50, 70 and 85 degrees, at 1.5 ms.
- **Nothing else**: the first deep dive's two contact suites, MuJoCo's defaults; and MuJoCo's own test suite.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off, plays | Every file the off arm plays is byte-identical to the release arm's, its statistics file included | eq |
| R2 safe when off, MuJoCo's suite | Switch unset: every one of MuJoCo's tests gives the release's result, `doc_test` included | eq (tests that differ, 0) |
| R3 the defect is there | Release, 1.5 ms: the slides along 25 and 50 degrees each go at least 15% further than along 0 | share |
| R4 no direction, slide | On, each step: the slides along 25, 50, 70 and 85 degrees within 1 part in 10,000 of the slide along 0 | all_within |
| R5 no drift | On, both steps: the drift across the line at most 10 um along every direction | all_le |
| R6 Coulomb | On, 0.375 ms: every direction's distance within 1 part in 100 of 59,455 um | all_within |
| R7 no direction, hold | On, at 0.76 and at 0.93: the creep along 25, 50, 70 and 85 degrees each within 1 part in 100 of the creep along 0 at the same push | all_within |
| R8 the release hold lets go | Release, at 0.93 along 50 degrees: its creep at least 10 times the creep along 0 at 0.93 | share |
| R9 the moving floor, on | On, each slip angle and step: the cube's speed along x reaches 0 within **three** steps of the elliptic cone's on the same floor | near |
| R10 the moving floor, release | Release, each slip angle and step: at least two steps from the elliptic cone's | ge |
| R11 free cube | On: the free slides along 25, 50, 70 and 85 degrees each within 1 part in 100 of the free slide along 0, and the drift at most 1,000 um | all_within, all_le |
| R12 the frame and the turned-contact tests | On: MuJoCo's `SensorTest.ContactStage`, `SensorTest.ContactVelocity`, `SleepTest.SleepingUnaffectedByWaking`, `IpcTest.FoldDenseBlocksSolveMatches` and `ForwardTest.DiscreteStiffLegPress` pass | eq, each |
| R13 nothing else changes | On: every play of both contact suites byte-identical to the release; and in MuJoCo's suite, switch set against unset, no test changes but `InverseTest.DiscreteInverseFreeBody`, which the stated lift fails | eq, eq |
| R14 the solver | On, over every play: no step at the iteration limit, no warning, and the most iterations of any step no more than the release arm's most plus 2 | eq, eq, le_plus |

The study holds if every rule holds. A rule that fails is reported as failed, with its numbers, and the patch stays in
design. If every rule holds, the third version is validated for what this registration asks; its lift stays as stated.

## Reported, not judged

- The lift: the highest the cube's lowest face rises while it slides (`sx_contact hover`), along every direction,
  release and on.
- The two cones on a still floor, as run 023's diagnostic: in the reference folder, the release's pyramid and its
  elliptic cone slide the cube along x on a still floor at the moving floor's two slip speeds (0.85 / cos 25 =
  0.9378712311 m/s and 0.85 / cos 50 = 1.3223652528 m/s), 0.8 s, at both steps; the steps at which each stops
  (`sx_contact stop`) and how far apart they are.

## Dry run

The runner, [`validation/run_024_study_04/play.sh`](../validation/run_024_study_04/play.sh), is new: before the study it
is played once with `DRY=1` on throwaway parameters (a 1 kg cube, half-size 0.05 m, friction 0.4, 1 m/s, the release
and reference folders only, no build, no MuJoCo suite), only to check that it runs to the end and writes every measured
line; no rule is read from it, and its files are kept apart from the study's, in `dry/`.
