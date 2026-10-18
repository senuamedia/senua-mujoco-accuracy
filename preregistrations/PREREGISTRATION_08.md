# Eighth pre-registration: the inverse weight in the current pose, third version

Registered 15 October 2026, after design probes (runs 036, 037) and Studies 5 and 7. Registered before any play of this
registration existed. To be played once, as run 038.

## The question

Studies 5 and 7 validated the inverse weight in the current pose for contacts, joint limits and joint friction (86 of
86 and 134 of 134 rule lines). MuJoCo also takes the softness of `connect` and `weld` equalities from their bodies'
inverse weights frozen at `qpos0`: a ball held by a `connect` sags 209 to 310 um by writing, the writings ending 4 to 101
um apart (run 036). The third version, `patches/in_design/invweight_at_pose_v3.diff` (sha256 d3fd45cc3d3ecfb0...), takes
those in the current pose too, by the first version's helper, the stock lines kept (switch `MUJOCO_INVWEIGHT_AT_POSE=1`).
In run 037 it held all 94 of its check lines.

On scenes the probes did not use: does MuJoCo as released end the same arm differently for each pose its file is
written in, on contact, swinging on a joint limit, held by joint friction and held by a `connect`; with the switch on,
does every writing end in the same place, at the same speed, creeping alike; does nothing else change, in this record's
cube scenes and in MuJoCo's own test suite; and with the switch unset, is the patched MuJoCo the release, byte for byte
and test for test?

## Engines and arms

- **release**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
  139577c541d43716...), MuJoCo's own defaults.
- **off**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with the patch file of sha256
  d3fd45cc3d3ecfb0... applied (gcc, CMake and Ninja, a Release build; its tests built the same way), rebuilt by the
  runner from the patch file; switch unset.
- **on**: the same build, `MUJOCO_INVWEIGHT_AT_POSE=1`.

The arm on contact is played under MuJoCo's defaults and under the elliptic cone with 10 noslip iterations; every other
scene under MuJoCo's defaults. MuJoCo's own test suite is run on the release's test build (run 020's recipe) and on the
patched test build, switch unset and set. Played on the second cloud machine (runs 031, 033, 035, 037). Rigs as committed
at this registration (`tools/mjc_arm.c`, `tools/mjc_stack.c`, `tools/mjc_grip.c`, `tools/mjc_contact.c`,
`tools/mjc_pair.c`); measured by Senua AI's `sx_contact` (source sha256 87e921cd4d2c03bf..., built for Linux) and judged
by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes or the earlier studies, except the first deep dive's two contact suites,
played with their own registered parameters.

- **The arm**: links of 0.29 m and 0.27 m, 0.95 kg and 0.45 kg, a ball of 0.026 m and 0.17 kg at the tip, friction 0.72
  (`len1=0.29 len2=0.27 mass1=0.95 mass2=0.45 rb=0.026 mb=0.17 mu=0.72`). Every scene is written three ways: in its own
  pose (native), straight (0, 0), and folded (0, 2.4). At 1.6 ms and 0.4 ms.
- **On contact**: poses (0.65, 0.95) and (1.25, -0.45); **rest**, the ball set down from 0.6 mm above the ground, 2 s;
  **drop**, from 11 mm, 1 s.
- **On a joint limit**: the arm released with its ball 1 m above the ground and its elbow on its upper limit, which
  gravity presses it against: pose (0.15, 0.75) with limits -2.1 and 0.75, and (0.3, 1.0) with limits -2 and 1.0, 2 s.
- **Held by joint friction**: the arm released with its ball 1 m above the ground, both hinges with 5.5 N m of dry
  friction, more than gravity's torque on either (at most about 3.7 N m), poses (0.15, 0.75) and (0.3, 1.0), 2 s.
- **Held by a connect**: the arm released with its ball 1 m above the ground and held there by a `connect` equality to
  where it starts, given as two sites (`tipconnect=1`), poses (0.15, 0.75) and (0.3, 1.0), 2 s.
- **The cubes**: stacks of 4 and 8 cubes of 0.45 kg, half-size 0.043 m, friction 0.58, and 3 such cubes each 14 mm along
  x from the one below, 2 s; one such cube set sliding at 0.9 m/s on the ground and on a fixed box, 1 s; all at both
  steps. A cube of 0.24 kg, half-size 0.033 m, gripped by two pads with 3.2 N each, friction 0.68, box and mesh pads, at
  its centre and 7 mm off it, 2 s, at 1.6 ms.
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
design. The rules and bounds are Study 7's, with the held ball added to R3 to R5.

## What is not asked

A `weld` equality, which the patch also changes, is played by no rig of this record and is not asked. The creep of an
arm held by joint friction itself (finding F1) is not corrected and not asked beyond R6's "alike in every writing".
Tendons keep their weights from `qpos0`; no scene here has one.

## Dry run

The runner, [`validation/run_038_study_08/play.sh`](../validation/run_038_study_08/play.sh), is new: before the study it
is played once with `DRY=1` on throwaway parameters (the arms of runs 025, 032, 034 and 036, and run 026's cubes, the
release only, no build, no MuJoCo suite), only to check that it runs to the end and writes every measured line; no rule
is read from it, and its files are kept apart from the study's, in `dry/`.
