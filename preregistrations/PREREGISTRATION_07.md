# Seventh pre-registration: the inverse weight in the current pose, second version

Registered 15 October 2026, after design probes (runs 032, 033, 034) and Study 5. Registered before any play of this
registration existed. To be played once, as run 035.

## The question

Study 5 validated the inverse weight in the current pose for contacts (86 of 86 rule lines). MuJoCo takes the softness
of joint limits and of joint friction from the joints' own inverse weights, `dof_invweight0`, also frozen in the pose a
model is written in: the same arm swinging on an elbow limit ends up to 1.24 mm apart by writing (run 032), and an arm
held by joint friction above its load creeps at 24 to 55 mm/s and ends 6 to 32 mm apart by writing (run 034). The
second version, `patches/in_design/invweight_at_pose_v2.diff` (sha256 0141e9bc36ff5bfc...), takes those in the current
pose too, by the formula `mj_setConst` uses, the stock lines kept (switch `MUJOCO_INVWEIGHT_AT_POSE=1`). In run 033 it
held all 74 of its check lines.

On scenes the probes did not use: does MuJoCo as released end the same arm differently for each pose its file is
written in, on contact, swinging on a joint limit and held by joint friction; with the switch on, does every writing end
in the same place, at the same speed, creeping alike; does nothing else change, in this record's cube scenes and in
MuJoCo's own test suite; and with the switch unset, is the patched MuJoCo the release, byte for byte and test for test?

## Engines and arms

- **release**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
  139577c541d43716...), MuJoCo's own defaults.
- **off**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with the patch file of sha256
  0141e9bc36ff5bfc... applied (gcc, CMake and Ninja, a Release build; its tests built the same way), rebuilt by the
  runner from the patch file; switch unset.
- **on**: the same build, `MUJOCO_INVWEIGHT_AT_POSE=1`.

The arm on contact is played under MuJoCo's defaults and under the elliptic cone with 10 noslip iterations; every other
scene under MuJoCo's defaults. MuJoCo's own test suite is run on the release's test build (run 020's recipe) and on the
patched test build, switch unset and set. Played on the second cloud machine, whose release, measuring program and
plays are the first machine's byte for byte (runs 031, 033). Rigs as committed at this registration (`tools/mjc_arm.c`,
`tools/mjc_stack.c`, `tools/mjc_grip.c`, `tools/mjc_contact.c`, `tools/mjc_pair.c`); measured by Senua AI's `sx_contact`
(source sha256 87e921cd4d2c03bf..., built for Linux) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes or the earlier studies, except the first deep dive's two contact suites,
played with their own registered parameters.

- **The arm**: links of 0.26 m and 0.32 m, 1.1 kg and 0.35 kg, a ball of 0.028 m and 0.18 kg at the tip, friction 0.65
  (`len1=0.26 len2=0.32 mass1=1.1 mass2=0.35 rb=0.028 mb=0.18 mu=0.65`). Every scene is written three ways: in its own
  pose (native), straight (0, 0), and folded (0, 2.3). At 1.25 ms and 0.3125 ms.
- **On contact**: poses (0.7, 0.9) and (1.2, -0.3); **rest**, the ball set down from 0.5 mm above the ground, 2 s;
  **drop**, from 15 mm, 1 s.
- **On a joint limit**: the arm released with its ball 1 m above the ground and its elbow on its upper limit, which
  gravity presses it against: pose (0.2, 0.7) with limits -2.2 and 0.7, and (0.35, 0.95) with limits -2 and 0.95
  (`elbowlimit`), 2 s.
- **Held by joint friction**: the arm released with its ball 1 m above the ground, both hinges with 5 N m of dry
  friction (`jointfriction=5`), more than gravity's torque on either (at most about 3.4 N m), poses (0.2, 0.7) and
  (0.35, 0.95), 2 s.
- **The cubes**: stacks of 5 and 6 cubes of 0.35 kg, half-size 0.04 m, friction 0.55, and 3 such cubes each 12 mm along
  x from the one below, 2 s; one such cube set sliding at 1.1 m/s on the ground and on a fixed box, 1 s; all at both
  steps. A cube of 0.22 kg, half-size 0.032 m, gripped by two pads with 2.8 N each, friction 0.75, box and mesh pads, at
  its centre and 9 mm off it, 2 s, at 1.25 ms.
- **Nothing else**: the first deep dive's two contact suites, MuJoCo's defaults; and MuJoCo's own test suite.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. "Apart" is `sx_contact ends` between a
writing and the native writing of the same scene, pose, step and configuration: the ball's height at the last step (nm)
and the larger difference of its two speeds (um/s).

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off, plays | Every file the off arm plays is byte-identical to the release arm's | eq |
| R2 safe when off, MuJoCo's suite | Switch unset: every one of MuJoCo's tests gives the release's result | eq (tests that differ, 0) |
| R3 the defect is there | Release, MuJoCo's defaults: in every scene, pose and step (and on contact, both scenes) the straight writing ends at least 1 um apart from the native | ge, each |
| R4 correct, place | On: every straight and folded writing ends within 100 nm of the native, in every scene, pose and step, and on contact under both configurations | le, each |
| R5 correct, speed | On: the same, within 10 um/s | le, each |
| R6 correct, creep | On, MuJoCo's defaults: the ball's creep (`sx_contact creep`) in the straight and folded writings within 1 um/s of the native's, the measure's resolution, on contact (the rest scene) and held by joint friction | near, each |
| R7 nothing else changes, plays | On: both suites and every cube play byte-identical to the release | eq |
| R8 nothing else changes, MuJoCo's suite | Switch set against unset: no test changes | eq (tests that differ, 0) |
| R9 the solver | On, over every play: no step at the iteration limit, no warning | eq, eq |

The study holds if every rule holds. A rule that fails is reported as failed, with its numbers, and the patch stays in
design. The bounds are Study 5's.

## What is not asked

The creep of an arm held by joint friction (finding F1) is not corrected by this patch and is not a rule beyond R6's
"alike in every writing". Equality constraints and tendons keep their weights from `qpos0`; no scene here has either.

## Dry run

The runner, [`validation/run_035_study_07/play.sh`](../validation/run_035_study_07/play.sh), is new: before the study it
is played once with `DRY=1` on throwaway parameters (the arms of runs 025, 032 and 034, and run 026's cubes, the release
only, no build, no MuJoCo suite), only to check that it runs to the end and writes every measured line; no rule is read
from it, and its files are kept apart from the study's, in `dry/`.
