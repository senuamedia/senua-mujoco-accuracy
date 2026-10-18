# Fifth pre-registration: the inverse weight in the current pose

Registered 15 October 2026, after design probes (runs 025, 028, 029). Registered before any play of this registration
existed. To be played once, as run 030.

## The question

MuJoCo sets each contact's regularisation from its bodies' inverse weights, `body_invweight0`, which `mj_setConst`
computes once in the pose a model is written in (`qpos0`). So the same arm, in the same place, sinks and creeps by
different amounts depending only on the pose its file was written in, the creep in proportion to the frozen weight
(run 025, finding F10). MuJoCo's own `diagexact` flag removes that but makes symmetric scenes turn under the default
cone (run 028). The patch in design `patches/in_design/invweight_at_pose.diff` (sha256 3f471edca6159277...) takes each
contact body's weight in the pose the body is in, by the formula `mj_setConst` uses, keeping one regularisation for a
pyramid's four edges (switch `MUJOCO_INVWEIGHT_AT_POSE=1`). In run 029 it held 49 of its 50 check lines; the one that
failed, the creep, did so by one whole um/s in the writing that started, by rounding, a hair above the ground, where the
check's 1 part in 1,000 rounds to 0. This registration changes those two things before any of its data exists: every
writing starts clearly above the ground, and the creep's bound is the measure's resolution.

On scenes the probes did not use: does MuJoCo as released still give the same arm a different end for each pose its
file is written in; with the switch on, does every writing end in the same place, at the same speed, creeping alike;
does nothing else change, in this record's cube scenes and in MuJoCo's own test suite; and with the switch unset, is
the patched MuJoCo the release, byte for byte and test for test?

## Engines and arms

- **release**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
  139577c541d43716...), MuJoCo's own defaults.
- **off**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with the patch file of sha256
  3f471edca6159277... applied (gcc, CMake and Ninja, a Release build; its tests built the same way), rebuilt by the
  runner from the patch file; switch unset.
- **on**: the same build, `MUJOCO_INVWEIGHT_AT_POSE=1`.

Every arm plays every scene under MuJoCo's defaults, and the arm also under the elliptic cone with 10 noslip iterations
(`cone=elliptic noslip=10`). MuJoCo's own test suite is run on the release's test build (run 020's) and on the patched
test build, switch unset and set. Rigs as committed at this registration (`tools/mjc_arm.c`, `tools/mjc_stack.c`,
`tools/mjc_grip.c`, `tools/mjc_contact.c`, `tools/mjc_pair.c`); measured by Senua AI's `sx_contact` (source sha256
87e921cd4d2c03bf..., built for Linux) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes or the earlier studies, except the first deep dive's two contact suites,
played with their own registered parameters.

- **The arm**: links of 0.28 m and 0.24 m, 0.9 kg and 0.4 kg, a ball of 0.025 m and 0.15 kg at the tip, friction
  0.7 (`len1=0.28 len2=0.24 mass1=0.9 mass2=0.4 rb=0.025 mb=0.15 mu=0.7`). Two starting poses, C (shoulder 0.6,
  elbow 1.0 rad) and D (1.3 and -0.5), each written three ways: in its own pose (native), straight (0, 0), and folded
  (0, 2.2). Two scenes: **rest**, the ball set down from 0.4 mm above the ground, 2 s (so that no writing starts with
  the ball exactly on the ground, where rounding decides whether the first step has a contact, run 028); **drop**, from
  12 mm, 1 s. At 1 ms and 0.25 ms.
- **The cubes**: stacks of 4 and 7 cubes of 0.4 kg, half-size 0.045 m, friction 0.6, and 3 such cubes each 15 mm along
  x from the one below, 2 s; one such cube set sliding at 1.0 m/s on the ground and on a fixed box (half-size 0.5 m),
  1 s; all at 1 ms and 0.25 ms. A cube of 0.25 kg, half-size 0.035 m, gripped by two pads with 3.0 N each, friction 0.7,
  box pads and mesh pads, at its centre and 8 mm off it, 2 s, at 1 ms.
- **Nothing else**: the first deep dive's two contact suites, MuJoCo's defaults; and MuJoCo's own test suite.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. "Apart" is `sx_contact ends` between a
writing and the native writing of the same pose, scene, step and configuration: the ball's height at the last step
(nm) and the larger difference of its two speeds (um/s).

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off, plays | Every file the off arm plays is byte-identical to the release arm's | eq |
| R2 safe when off, MuJoCo's suite | Switch unset: every one of MuJoCo's tests gives the release's result | eq (tests that differ, 0) |
| R3 the defect is there | Release, MuJoCo's defaults: in every pose, scene and step the straight writing ends at least 1 um apart from the native | ge, each |
| R4 correct, place | On, both configurations: in every pose, scene and step the straight and the folded writing each end within 100 nm of the native | le, each |
| R5 correct, speed | On, both configurations: the same, within 10 um/s | le, each |
| R6 correct, creep | On, MuJoCo's defaults, the rest scene: in each pose and step the ball's creep (`sx_contact creep`) in the straight and folded writings within 1 um/s of the native's, the measure's resolution | near, each |
| R7 nothing else changes, plays | On: both suites and every cube play byte-identical to the release | eq |
| R8 nothing else changes, MuJoCo's suite | Switch set against unset: no test changes | eq (tests that differ, 0) |
| R9 the solver | On, over every play: no step at the iteration limit, no warning | eq, eq |

The study holds if every rule holds. A rule that fails is reported as failed, with its numbers, and the patch stays in
design. The bounds of R4 and R5 are run 029's checks, fixed before that run's plays; R6's is the measure's resolution (run 029's check asked 1 part in 1,000, which the measure rounds to 0 um/s for a creep under 1 mm/s).

## What is not asked

Joint limits and equality constraints keep their weights from `qpos0` under this patch; no scene here has either. The
other two sources of error MuJoCo's documentation names (the average over directions, and bodies treated as
independent) are not touched.

## Dry run

The runner, [`validation/run_030_study_05/play.sh`](../validation/run_030_study_05/play.sh), is new: before the study it
is played once with `DRY=1` on throwaway parameters (run 025's arm and run 026's cubes, the release only, no build, no
MuJoCo suite), only to check that it runs to the end and writes every measured line; no rule is read from it, and its
files are kept apart from the study's, in `dry/`.
