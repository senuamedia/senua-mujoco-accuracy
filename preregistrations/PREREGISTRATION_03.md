# Third pre-registration: the slip-aligned pyramid's third version

Registered 15 October 2026, after design probes (runs 020, 021, 022). Registered before any play of this registration
existed. To be played once, as run 023.

## The question

The slip-aligned pyramid (validated by Study 1) turned `mjContact.frame` in place, turned contacts along numerical
noise, left a moving surface's velocity out of the slip, and swapped the rows of contacts it did not need to turn;
MuJoCo's own test suite found these (run 020). Its third version, `patches/in_design/slip_aligned_pyramid_v3.diff`
(sha256 58a65674e1c61dd9...), leaves the frame as released and turns only the pyramid's rows (the turn kept in a new
field, `mjContact.frictionrot`, and undone in `mj_contactForce`), puts the surfaces' own velocity in the slip, turns a
contact only when its slip is at least MuJoCo's own rest speed (`opt.sleep_tolerance`) and its friction is isotropic,
turns it only by the part of the slip's angle that is not a multiple of 90 degrees, and documents the new field (run
022). Switch: `MUJOCO_SLIP_ALIGNED_PYRAMID=1`.

On scenes the probes did not use: does MuJoCo as released still give friction a direction, on a still floor and on a
moving one; with the switch on, is the slide and the hold the same along every direction and Coulomb's, and does a
moving floor stop a sliding cube as MuJoCo's own direction-free cone does; is the frame as released and does nothing
else change, in this record's plays and in MuJoCo's own test suite; and with the switch unset, is the patched MuJoCo
the release, byte for byte and test for test?

The lift is not corrected by this version and is not a rule: an aligned pyramid lifts a sliding body as much in every
direction as along an axis (runs 020 to 022). It is measured and reported.

## Engines and arms

- **release**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
  139577c541d43716...), MuJoCo's own defaults (pyramidal cone, Euler, 100 iterations).
- **off**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with the patch file of sha256
  58a65674e1c61dd9... applied, as in run 022 (gcc, CMake and Ninja, a Release build; its tests built the same way);
  switch unset.
- **on**: the same build, `MUJOCO_SLIP_ALIGNED_PYRAMID=1`.
- **elliptic**: the release with `cone="elliptic"`, played only on the moving floor, as its reference.

MuJoCo's own test suite is run on the release's test build (run 020's, from the release source) and on the patched
test build, switch unset and set. Rigs as committed at this registration (`tools/mjc_contact.c`, `tools/mjc_pair.c`);
measured by Senua AI's `sx_contact` (sha256 87e921cd4d2c03bf... as run, built for Linux) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes or the earlier studies, except the first deep dive's two contact suites,
played with their own registered parameters.

- **The cube**: 1.3 kg, half-size 0.035 m, friction 0.55, held level (`lock=1`) unless a line says free.
- **The slide**: set sliding at 0.9 m/s along 0, 20, 40, 65 and 80 degrees from x, 1 s, at 1.5 ms and 0.375 ms.
  Coulomb's distance: 0.9^2 / (2 x 0.55 x 9.8) = 75,139 um.
- **The hold**: pushed from 0.35 s along 0, 20, 40, 65 and 80 degrees with 0.78 and 0.88 of what friction can hold
  (0.55 x 1.3 x 9.8 = 7.007 N: 5.46546 N and 6.16616 N), 1.4 s, at 1.5 ms. The release's diamond holds along a
  direction t only up to 1 / (|cos t| + |sin t|) of the limit: 0.78 along 20, 0.71 along 40, 0.75 along 65, 0.86
  along 80 degrees.
- **The moving floor**: the cube set sliding at 0.9 m/s along x on a floor moving along y at 0.6301867844 m/s and at
  1.2853332061 m/s (MuJoCo's `surfacevel`), so that it slips at 35 and 55 degrees to the frame's axes, 0.8 s, at
  1.5 ms and 0.375 ms; each also played under the elliptic cone.
- **The free cube**: the slide with the cube on a free joint (`lock=0`), along 0, 20, 40, 65 and 80 degrees, at 1.5 ms.
- **Nothing else**: the first deep dive's two contact suites, MuJoCo's defaults; and MuJoCo's own test suite.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off, plays | Every file the off arm plays is byte-identical to the release arm's | eq |
| R2 safe when off, MuJoCo's suite | Switch unset: every one of MuJoCo's tests gives the release's result, `doc_test` included | eq (tests that differ, 0) |
| R3 the defect is there | Release, 1.5 ms: the slides along 40 and 65 degrees each go at least 15% further than along 0 | share |
| R4 no direction, slide | On, each step: the slides along 20, 40, 65 and 80 degrees within 1 part in 10,000 of the slide along 0 | all_within |
| R5 no drift | On, both steps: the drift across the line at most 10 um along every direction | all_le |
| R6 Coulomb | On, 0.375 ms: every direction's distance within 1 part in 100 of 75,139 um | all_within |
| R7 no direction, hold | On, at 0.78 and at 0.88: the creep along 20, 40, 65 and 80 degrees each within 1 part in 100 of the creep along 0 at the same push | all_within |
| R8 the release hold lets go | Release, at 0.88 along 40 degrees: its creep at least 10 times the creep along 0 at 0.88 | share |
| R9 the moving floor, on | On, each slip angle and step: the cube's speed along x reaches 0 within one step of the elliptic cone's on the same floor | near |
| R10 the moving floor, release | Release, each slip angle and step: at least two steps from the elliptic cone's | ge |
| R11 free cube | On: the free slides along 20, 40, 65 and 80 degrees each within 1 part in 100 of the free slide along 0, and the drift at most 1,000 um | all_within, all_le |
| R12 the frame and the turned-contact tests | On: MuJoCo's `SensorTest.ContactStage`, `SensorTest.ContactVelocity`, `SleepTest.SleepingUnaffectedByWaking`, `IpcTest.FoldDenseBlocksSolveMatches` and `ForwardTest.DiscreteStiffLegPress` pass | eq, each |
| R13 nothing else changes | On: every play of both contact suites byte-identical to the release; and in MuJoCo's suite, switch set against unset, no test changes but `InverseTest.DiscreteInverseFreeBody`, which the stated lift fails | eq, eq |
| R14 the solver | On, over every play: no step at the iteration limit, no warning, and the most iterations of any step no more than the release's most plus 2 | eq, eq, le_plus |

The study holds if every rule holds. A rule that fails is reported as failed, with its numbers, and the patch stays in
design.

## Reported, not judged

The lift: the highest the cube's lowest face rises while it slides (`sx_contact hover`), along every direction, released
and on.

## Dry run

The patch and its builds are run 022's, rebuilt by the runner from the registered patch file. The runner,
[`validation/run_023_study_03/play.sh`](../validation/run_023_study_03/play.sh), is new: before the study it is played
once with `DRY=1` on throwaway parameters (a 1 kg cube, half-size 0.05 m, friction 0.4, 1 m/s, the release only, no
MuJoCo suite), only to check that it runs to the end and writes every measured line; no rule is read from it, and its
files are kept apart from the study's, in `dry/`.
