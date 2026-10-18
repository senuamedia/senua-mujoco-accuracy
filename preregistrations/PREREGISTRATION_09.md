# Ninth pre-registration: a weld under the third version, and a free tumbling body under each integrator

Registered 16 October 2026, after the design probe of run 039 and Study 8. Registered before any play of this
registration existed. To be played once, as run 040.

## The question

**Part A, the weld.** Study 8 validated the inverse weight in the current pose, third version
(`patches/invweight_at_pose_v3.diff`, sha256 d3fd45cc3d3ecfb0..., switch `MUJOCO_INVWEIGHT_AT_POSE=1`), for contacts,
joint limits, joint friction and a `connect` equality (154 of 154 rule lines). The patch changes a `weld` by the same
helper, and Study 8 did not ask it. In run 039, a probe, a body held by a weld ended up to 85 um apart by writing
released, and the same to the nanometre in every writing with the switch set. On an arm the probes did not use: does
MuJoCo as released end the same arm, held by a weld, differently for each pose its file is written in; with the switch
on, does every writing end in the same place at the same speed; does nothing else change; and with the switch unset, is
the patched MuJoCo the release, byte for byte and test for test?

**Part B, the free tumbling body (MuJoCo's reported issue M10).** A free rigid body with three different principal
moments, spinning about a general axis with nothing acting on it, must keep its rotational kinetic energy and the
magnitude of its angular momentum, whatever the step. In run 039, under MuJoCo's default integrator, a tumbling body
gained 3.4% of its energy and 1.3% of its angular momentum in 2 s at 10 ms; implicitfast and implicit lost them; RK4
kept both. On a body the probe did not use: under each of MuJoCo's four integrators, at each step of the record's ladder,
does the body keep its energy and its angular momentum within the bounds below?

## Engines and arms

- **release**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
  139577c541d43716...), MuJoCo's own defaults.
- **off**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with the patch file of sha256
  d3fd45cc3d3ecfb0... applied (gcc, CMake and Ninja, a Release build; its tests built the same way), rebuilt by the
  runner from the patch file; switch unset.
- **on**: the same build, `MUJOCO_INVWEIGHT_AT_POSE=1`.

Each arm plays the weld, the tumbling body under all four integrators, and both of the first deep dive's contact
suites, under MuJoCo's defaults (the tumbling body under each integrator in turn). MuJoCo's own test suite is run on the
release's test build (run 020's recipe) and on the patched test build, switch unset and set. Played on the cloud
machine of run 039 and of Studies 1 to 5 (AWS EC2 c7i.large, 2 virtual CPUs).

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_040_study_09/play.sh`](../validation/run_040_study_09/play.sh) | 54091099f1a5f0e4... |
| Rigs | `tools/mjc_arm.c` | 8553e8fe18c2be2e... |
| | `tools/mjc_tumble.c` | 881beecd23d66e0f... |
| | `tools/mjc_contact.c`, `tools/mjc_pair.c` | e029215e31bfd95d..., 4cab45a77687adfd... |
| | `tools/contact_suite.sh`, `tools/contact_suite2.sh`, `tools/build_rig.sh` | 8cda2ed242cad7df..., 8d3c42b648b7651c..., b6a93676e6aee763... |
| Senua AI's measures | `sx_contact` (`ends`, `rule`), source as run | 87e921cd4d2c03bf... (built for Linux: f09ea027cec7820d...) |
| | `sx_tumble` (`tumble`), source as run ([`measure/`](../measure/README.md)) | 21e07a0c3c3b21dc... (built for Linux: f64a96bf1bdbb3fd...) |
| The patch | `patches/invweight_at_pose_v3.diff` | d3fd45cc3d3ecfb0... |

## The numbers, and how they were drawn

Every number of the plays that a probe or study could have chosen was drawn from one stream of whole numbers,
x(n+1) = (1103515245 x(n) + 12345) mod 2^31, from x(0) = 9: the first deep dive's procedure (its twenty-first
registration). Each number gives its quantity the grid point floor(count x(n) / 2^31) counted up from the range's lowest
value, where count is the number of grid points in the range. The ranges are the span of the values this record used for
the same quantity, so each scene stays in the regime it was written for; the grids are a millimetre for an arm's
length, a tenth of a millimetre for the ball's radius, a gram for a mass, a thousandth of a radian for an angle,
0.01 ms for the step, 1e-6 kg m2 for a moment of inertia and 0.01 rad/s for a spin. A value this record already used for
a quantity of the same kind (every setting of that kind in its play, probe and runner scripts, and the rigs' defaults
where a study played them; the lists are in the runner's draw), or one this draw had already given that kind, was drawn
again: one was (a ball of 0.170 kg). Two draws were repeated until a condition held: the three moments, all three, until
none is more than the sum of the other two (as for any rigid body) and no two are within 1 part in 10 of each other (it
held at the first draw); and the spin, all three components, until its size is from 2 to 4 rad/s and each component is
at least 0.5 rad/s in size, a general axis away from every principal axis (six spins were drawn again).
`DRAW=1 bash validation/run_040_study_09/play.sh` prints the draw. Each value drawn was then looked for in the record's
play, probe and runner scripts and its registrations: none is there.

| What | The numbers | Drawn from |
|---|---|---|
| The steps | 1.63 ms, and a quarter of it, 0.4075 ms | 1 to 2 ms |
| The arm | links of 0.273 m and 0.267 m, 1.023 kg and 0.519 kg, a ball of 0.0271 m and 0.161 kg | 0.26 to 0.30 m, 0.24 to 0.32 m, 0.9 to 1.2 kg, 0.35 to 0.6 kg, 0.025 to 0.03 m, 0.15 to 0.2 kg |
| The weld's two poses | (0.197, 0.627) and (0.305, 0.961) rad | shoulder 0 to 0.4, elbow 0.6 to 1.0 |
| The folded writing | (0, 2.234) rad | elbow 2.2 to 2.5 |
| The tumbling body | principal moments 0.011372, 0.009324 and 0.007512 kg m2; spin (2.52, 2, -0.83) rad/s along its own axes, 3.32 rad/s in size | 0.003 to 0.012 kg m2; -3.5 to 3.5 rad/s |

Not drawn, as in the probes and Study 8: the ball 1 m above the ground and 2 s of play; the tumbling body's mass, 1 kg
(it does not enter the right answer), its 2 s and the record's step ladder, 10 ms over 1, 4, 16 and 64 (run 007); and
the first deep dive's two contact suites, played with their own registered parameters.

## The scenes

- **The weld**: the arm, released at rest with its ball 1 m above the ground, held there by a `weld` equality alone
  (`tipweld=1`: link 2 held in place and in orientation, between a site at the ball's centre on link 2 and one in the
  world where it starts, turned as link 2 starts), in each of the two poses, 2 s, written three ways: in its own pose
  (native), straight (0, 0) and folded (0, 2.234), at both steps.
- **The tumbling body**: `tools/mjc_tumble.c`, the drawn moments and spin, no gravity, nothing touching it, 2 s, under
  Euler, implicitfast, implicit and RK4, at 10, 2.5, 0.625 and 0.15625 ms.
- **Nothing else**: the first deep dive's two contact suites, MuJoCo's defaults; and MuJoCo's own test suite.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. "Apart" is `sx_contact ends` between a
writing and the native writing of the same pose and step: the ball's height at the last step (nm) and the larger
difference of its two speeds (um/s). A drift is `sx_tumble tumble`'s largest drift over the play, in parts per million
of the start.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off, plays | Every file the off arm plays (the weld, the tumbling body, both suites) is byte-identical to the release arm's | eq |
| R2 safe when off, MuJoCo's suite | Switch unset: every one of MuJoCo's tests gives the release's result | eq (tests that differ, 0) |
| R3 the defect is there | Release: in each pose and step the straight writing ends at least 1 um apart from the native | ge, each |
| R4 correct, place | On: every straight and folded writing ends within 100 nm of the native, in each pose and step | le, each |
| R5 correct, speed | On: the same, within 10 um/s | le, each |
| R7 nothing else changes, plays | On: both suites and the tumbling body byte-identical to the release | eq |
| R8 nothing else changes, MuJoCo's suite | Switch set against unset: no test changes | eq (tests that differ, 0) |
| R9 the solver | On, over every play: no step at the iteration limit, no warning | eq, eq |
| T1 the energy | Release, each integrator and step: the largest energy drift no more than 5,000 per million at 10 ms, 1,000 at 2.5 ms, and 500 at 0.625 and 0.15625 ms | le, each |
| T2 the angular momentum | Release, each integrator and step: the largest drift of the magnitude of the angular momentum no more than 100 per million | le, each |

R1 to R9 are Study 8's rules and bounds with the weld in place of its scenes; Study 8's R6 (the creep alike) has no
counterpart for a body held at rest. T1 and T2 are the first deep dive's bounds for a free chain, where nothing does work
either: its twelfth registration's G4 for the energy (5,000, 1,000 and 500 per million at its shipped step of 10 ms, a
quarter and a sixteenth of it; the finest of them, 500, at 1/64 here, which G4 did not play) and the largest drift of
its fifteenth registration's V2 for the angular momentum (100 per million). The same bounds hold for every integrator.
There are 58 rule lines: R1 to R9, 26; T1 and T2, 32.

## The decisions

- **Part A**: if R1 to R9 all hold, the third version is recorded as validated for a `weld` too. A rule that fails is
  reported as failed, with its numbers, and the third version is not recorded as validated for a weld.
- **Part B** decides no patch. It is a measurement of M10 against fixed bounds: each integrator whose eight lines all
  hold is recorded as keeping a free tumbling body's energy and angular momentum at every step of the ladder; each line
  that fails is recorded as measured, with its numbers, and stays open.

## What is not asked

The cause of a tumbling body's drift (finding F4 traces the chain's to the explicit Coriolis and centripetal force); a
correction for it, of which none is in design; the tumbling body with gravity, contact or damping. Tendons keep their
weights from `qpos0`; no scene here has one.

## Dry run

The runner is new: before the study it is played once with `DRY=1` on throwaway parameters (run 039's arm, poses and
body, the release only, no build, no MuJoCo suite), only to check that it runs to the end and writes every measured
line; no rule is read from it, and its files are kept apart from the study's, in `dry/`.
