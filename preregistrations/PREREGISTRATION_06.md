# Sixth pre-registration: the slip-aligned pyramid's third version, against MuJoCo's own cone in the same run

Registered 15 October 2026, after Studies 3 and 4 (runs 023, 024). Registered before any play of this registration
existed. To be played once, as run 031.

## Why a sixth registration

Studies 3 and 4 ([`PREREGISTRATION_03.md`](PREREGISTRATION_03.md), [`PREREGISTRATION_04.md`](PREREGISTRATION_04.md))
each held 29 of 32 rule lines and did not hold; their registrations and verdicts stand. Everything the patch is for held
in both. Apart from Study 3's accounting, every rule that failed did so by a fixed bound that MuJoCo's own direction-free cone
does not keep on the scenes played:

- **R9, the moving floor.** Study 3 allowed 1 step from MuJoCo's elliptic cone and Study 4, from run 023's diagnostic,
  3. On Study 4's scenes MuJoCo's own pyramid and elliptic cone, sliding the cube along x on a still floor where the
  pyramid has no direction, were 4 and 5 steps apart at 0.375 ms (its reported control), and the aligned pyramid 3 and 4
  from the elliptic cone.
- **R11, the free cube.** Study 4 allowed 1% between directions and 1,000 um of drift. MuJoCo's elliptic cone spreads
  the same free cube by 3.7% and drifts it 917 um (run 024's diagnostic); the aligned pyramid 1.23% and 1,176 um.

Run 023's README proposed, before Study 4's data existed, to bound the moving floor by the two cones' own difference
along an axis measured in the same run. This registration does that for R9, and for R11 takes MuJoCo's elliptic cone on
the same free cube in the same run as the reference. These references are measured in the run, not numbers chosen
here: on Study 4's numbers R11's drift line would have failed (1,176 um against 917). Every other rule is Study 4's,
worded as there, on fresh scenes; the patch file, its switch, the arms and the builds are Study 4's.

## The question

On fresh scenes: does MuJoCo as released still give friction a direction, on a still floor and on a moving one; with
the switch on, is the slide and the hold the same along every direction played and Coulomb's; does a moving floor stop
a sliding cube no further from MuJoCo's direction-free cone than MuJoCo's own pyramid is along its axis; does a free
cube spread and drift no more than under MuJoCo's direction-free cone; is the frame as released and does nothing else
change, in this record's plays and in MuJoCo's own test suite; and with the switch unset, is the patched MuJoCo the
release, byte for byte and test for test?

The lift is not corrected by this version and is not a rule. It is measured and reported.

## Engines and arms

- **release**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
  139577c541d43716...), MuJoCo's own defaults (pyramidal cone, Euler, 100 iterations).
- **off**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with
  `patches/in_design/slip_aligned_pyramid_v3.diff` (sha256 58a65674e1c61dd9...) applied, as in runs 022 to 024, rebuilt by
  the runner from the patch file; switch unset.
- **on**: the same build, `MUJOCO_SLIP_ALIGNED_PYRAMID=1`.
- **reference**: the release, in a folder of its own: under `cone="elliptic"` on the moving floor (R9's and R10's
  reference); its pyramid and its elliptic cone sliding the cube along x on a still floor at the moving floor's slip
  speeds (R9's bound); and the free cube under `cone="elliptic"` along the five directions (R11's reference).

MuJoCo's own test suite is run on the release's test build (run 020's) and on the patched test build, switch unset and
set. Rigs as committed at this registration (`tools/mjc_contact.c`, `tools/mjc_pair.c`); measured by Senua AI's
`sx_contact` (source sha256 87e921cd4d2c03bf..., built for Linux) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the record before, except the first deep dive's two contact suites, played with their
own registered parameters. The plays' durations and the hold's timing are Study 4's.

- **The cube**: 1.05 kg, half-size 0.042 m, friction 0.48, held level (`lock=1`) unless a line says free.
- **The slide**: set sliding at 0.95 m/s along 0, 12, 33, 57 and 78 degrees from x, 1 s, at 1.2 ms and 0.3 ms.
  Coulomb's distance: 0.95^2 / (2 x 0.48 x 9.8) = 95,929 um.
- **The hold**: pushed from 0.35 s along the same five directions with 0.74 and 0.91 of what friction can hold
  (0.48 x 1.05 x 9.8 = 4.9392 N: 3.655008 N and 4.494672 N), 1.4 s, at 1.2 ms. The release's diamond holds along a
  direction t only up to 1 / (|cos t| + |sin t|) of the limit: 0.84 along 12, 0.72 along 33 and 57, 0.84 along 78.
- **The moving floor**: the cube set sliding at 0.95 m/s along x on a floor moving along y at 0.3457717226 m/s and at
  0.8553838421 m/s, so that it slips at 20 and 42 degrees to the frame's axes, 0.8 s, at 1.2 ms and 0.3 ms; each also
  played in the reference folder under the elliptic cone; and, there, the cube slid along x on a still floor at the
  two slip speeds, 0.95 / cos 20 = 1.0109688839 m/s and 0.95 / cos 42 = 1.2783510931 m/s, under the pyramid and the
  elliptic cone, at both steps.
- **The free cube**: the slide with the cube on a free joint (`lock=0`), along the five directions, at 1.2 ms; and, in
  the reference folder, the same under the elliptic cone.
- **Nothing else**: the first deep dive's two contact suites, MuJoCo's defaults; and MuJoCo's own test suite.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. R9 and R11 are new; the others are
Study 4's.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off, plays | Every file the off arm plays is byte-identical to the release arm's, its statistics file included | eq |
| R2 safe when off, MuJoCo's suite | Switch unset: every one of MuJoCo's tests gives the release's result | eq (tests that differ, 0) |
| R3 the defect is there | Release, 1.2 ms: the slides along 33 and 57 degrees each go at least 15% further than along 0 | share |
| R4 no direction, slide | On, each step: the slides along 12, 33, 57 and 78 degrees within 1 part in 10,000 of the slide along 0 | all_within |
| R5 no drift | On, both steps: the drift across the line at most 10 um along every direction | all_le |
| R6 Coulomb | On, 0.3 ms: every direction's distance within 1 part in 100 of 95,929 um | all_within |
| R7 no direction, hold | On, at 0.74 and at 0.91: the creep along 12, 33, 57 and 78 degrees each within 1 part in 100 of the creep along 0 at the same push | all_within |
| R8 the release hold lets go | Release, at 0.91 along 33 degrees: its creep at least 10 times the creep along 0 at 0.91 | share |
| R9 the moving floor, on | On, each slip angle and step: the step at which the cube's speed along x reaches 0 is no further from the elliptic cone's on the same floor than the release's pyramid and elliptic cone are from each other on a still floor along x at the same slip speed and step, in the same run | near (tolerance: that difference) |
| R10 the moving floor, release | Release, each slip angle and step: at least two steps from the elliptic cone's | ge |
| R11 free cube | On: the free slides' spread across the five directions (the longest less the shortest) no more than the elliptic cone's free slides' spread in the same run; and the largest drift across the line no more than the elliptic cone's largest | le, le |
| R12 the frame and the turned-contact tests | On: MuJoCo's `SensorTest.ContactStage`, `SensorTest.ContactVelocity`, `SleepTest.SleepingUnaffectedByWaking`, `IpcTest.FoldDenseBlocksSolveMatches` and `ForwardTest.DiscreteStiffLegPress` pass | eq, each |
| R13 nothing else changes | On: every play of both contact suites byte-identical to the release; and in MuJoCo's suite, switch set against unset, no test changes but `InverseTest.DiscreteInverseFreeBody`, which the stated lift fails | eq, eq |
| R14 the solver | On, over every play: no step at the iteration limit, no warning, and the most iterations of any step no more than the release arm's most plus 2 | eq, eq, le_plus |

The study holds if every rule holds. A rule that fails is reported as failed, with its numbers, and the patch stays in
design. If every rule holds, the third version is validated for what this registration asks; its lift stays as stated.

## Reported, not judged

The lift: the highest the cube's lowest face rises while it slides (`sx_contact hover`), along every direction, release
and on.

## Dry run

The runner, [`validation/run_031_study_06/play.sh`](../validation/run_031_study_06/play.sh), is new: before the study it
is played once with `DRY=1` on throwaway parameters (a 1 kg cube, half-size 0.05 m, friction 0.4, 1 m/s, the release and
reference folders only, no build, no MuJoCo suite), only to check that it runs to the end and writes every measured
line; no rule is read from it, and its files are kept apart from the study's, in `dry/`.
