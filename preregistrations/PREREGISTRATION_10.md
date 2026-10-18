# Tenth pre-registration: MuJoCo's recommended configuration end to end, under its default integrator and under RK4

Registered 16 October 2026, after Study 9 and the design probe of run 041. Registered before any play of this
registration existed. To be played once, as run 042.

## The question

The record has validated each part of its recommended configuration on its own rules. The configuration, the elliptic
cone with 10 noslip iterations ([Study 2](../docs/studies/02-recommended-configuration.md)), holds every load it was
given, slides the same along every direction and slides Coulomb's distance. The inverse weight in the current pose, third
version (`patches/invweight_at_pose_v3.diff`, sha256 d3fd45cc3d3ecfb0..., switch `MUJOCO_INVWEIGHT_AT_POSE=1`), ends an
arm the same however its file is written, on contact, on a joint limit, held by joint friction and held by a `connect` or
a `weld` (Studies 8 and 9). [Study 9](../docs/studies/09-weld-and-tumbling-body.md) found that only RK4 keeps a free
tumbling body's energy and angular momentum, and finding F4 records that under RK4 the first deep dive's contact
refinement chain goes out of order (run 014). In run 041, a probe on throwaway numbers, the configuration with the patch
on held 123 of 133 rule lines under MuJoCo's default integrator and 130 of 133 under RK4.

On numbers no earlier study used: does MuJoCo's recommended configuration, with the third version's switch set, meet
every rule this record's studies carry that it can be put to, under MuJoCo's default integrator, and under RK4? With the
switch unset, is the patched MuJoCo the release, byte for byte and test for test, and does the switch change nothing
else?

## Engines and arms

- **rel_def**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
  139577c541d43716...), MuJoCo's own defaults.
- **rel_rec**: the release, with the configuration's options: `cone=elliptic`, `noslip_iterations=10`.
- **off_def**, **off_rec**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with the patch file of sha256
  d3fd45cc3d3ecfb0... applied (gcc, CMake and Ninja, a Release build; its tests built the same way), rebuilt by the
  runner from the patch file; switch unset; under MuJoCo's defaults and under the configuration's options.
- **config**: the same build, switch set, the configuration's options, MuJoCo's default integrator (Euler): **the
  recommended configuration**.
- **config_rk4**: the same, under RK4.

Each arm makes the same plays (below). MuJoCo's own test suite is run on the release's test build (run 020's recipe) and
on the patched test build, switch unset and set. Played on the first cloud machine (AWS EC2, Intel), changed for this
study to a c7i.xlarge (4 virtual CPUs, 8 GB), so that every one of MuJoCo's tests can run: in run 040, on 3.8 GB, one test
ran out of memory in every arm.

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_042_study_10/play.sh`](../validation/run_042_study_10/play.sh) | 1e7277e94e6e8028... |
| Rigs | `tools/mjc_contact.c`, `tools/mjc_pair.c` | e029215e31bfd95d..., 4cab45a77687adfd... |
| | `tools/mjc_arm.c`, `tools/mjc_stack.c` | 8553e8fe18c2be2e..., 9dd2ec778cac0012... |
| | `tools/mjc_grip.c`, `tools/mjc_tumble.c` | 5adac004412ef94b..., 881beecd23d66e0f... |
| | `tools/contact_suite.sh`, `tools/contact_suite2.sh`, `tools/build_rig.sh` | 8cda2ed242cad7df..., 8d3c42b648b7651c..., b6a93676e6aee763... |
| Senua AI's measures | `sx_contact` (`creep`, `stop`, `final`, `ends`, `rule`), source as run | 87e921cd4d2c03bf... (built for Linux: f09ea027cec7820d...) |
| | `sx_tumble` (`tumble`), source as run ([`measure/`](../measure/README.md)) | 21e07a0c3c3b21dc... (built for Linux: f64a96bf1bdbb3fd...) |
| | The first deep dive's suite runner, `sx_contact_suite.sh`, as run (its published copy differs in comments only) | 553d46ecdaf2bd95... |
| The patch | `patches/invweight_at_pose_v3.diff` | d3fd45cc3d3ecfb0... |

## The numbers, and how they were drawn

Every number of the plays that a probe or study could have chosen was drawn from one stream of whole numbers,
x(n+1) = (1103515245 x(n) + 12345) mod 2^31, from x(0) = 10, by the ninth registration's procedure: each number gives its
quantity the grid point floor(count x(n) / 2^31) counted up from the range's lowest value; the ranges are the span of the
values this record used for the same quantity, and the grids those of the ninth registration (a gram, a tenth of a
millimetre for a half-size, a thousandth of a radian, 0.01 ms for the step, 0.01 m/s, 0.001 for a friction, 0.01 N and
0.01 N m). A value this record already used for a quantity of the same kind (the lists are in the runner's draw), or one
this draw had already given that kind, was drawn again: three were (a grip cube of 0.200 kg, a ball of 0.0250 m and a
rest height of 0.50 mm). Four draws were repeated until a condition held: the grip's squeeze, until the two pads'
friction is 1.7 to 2 times the cube's weight (25 times); the joint friction, until it is more than gravity's torque on the
shoulder in both held poses (it held at the first draw); the three moments, until none is more than the sum of the other
two and no two are within 1 part in 10 of each other (5 times); and the spin, until its size is from 2 to 4 rad/s and each
component at least 0.5 rad/s in size (once). `DRAW=1 bash validation/run_042_study_10/play.sh` prints the draw.

| What | The numbers | Drawn from |
|---|---|---|
| The steps | 1.14 ms, and a quarter of it, 0.285 ms | 1 to 2 ms |
| The cube held and slid | 1.861 kg, half-size 0.0434 m, friction 0.39, slid at 1.01 m/s (Coulomb's distance 133,451 um) | 1 to 2 kg, 0.04 to 0.05 m, 0.35 to 0.5, 0.8 to 1.2 m/s |
| The first suite's cube | 0.881 kg, half-size 0.0392 m, dropped from 0.096 m, launched at 3.24 m/s and 1.47 m/s (the chain), friction 0.371, slid at 3.67 m/s, held at friction 0.421 | 0.8 to 2 kg, 0.03 to 0.045 m, 0.07 to 0.10 m, 2 to 4 and 0.9 to 1.5 m/s, 0.3 to 0.45, 2.5 to 5 m/s, 0.4 to 0.5 |
| The grip | a cube of 0.202 kg, half-size 0.0312 m, friction 0.772, squeezed with 2.48 N (the pads' friction 1.93 times its weight), and 9.3 mm off centre | 0.2 to 0.25 kg, 0.03 to 0.035 m, 0.68 to 0.8, 2.45 to 3.2 N, 7 to 10 mm |
| The stacks | cubes of 0.442 kg, half-size 0.0424 m, friction 0.524; the offset stack shifted 17 mm a cube; the slides at 1.16 m/s | 0.35 to 0.5 kg, 0.04 to 0.05 m, 0.5 to 0.6, 12 to 20 mm, 0.9 to 1.2 m/s |
| The arm | links of 0.271 m and 0.275 m, 1.113 kg and 0.524 kg, a ball of 0.0264 m and 0.176 kg, friction 0.717 | 0.26 to 0.30 m, 0.24 to 0.32 m, 0.9 to 1.2 kg, 0.35 to 0.6 kg, 0.025 to 0.03 m, 0.15 to 0.2 kg, 0.65 to 0.8 |
| On contact | poses (0.604, 1.158) and (1.149, -0.545) rad; set down from 0.59 mm, dropped from 12.1 mm | shoulder 0.5 to 0.7 and 1.1 to 1.3, elbow 0.9 to 1.2 and -0.6 to -0.3; 0.4 to 0.6 mm, 10 to 15 mm |
| Held 1 m up | poses (0.245, 0.831) and (0.223, 0.993) rad; the elbow's lower limits -2.026 and -2.003 rad; joint friction 5.96 N m | shoulder 0 to 0.4, elbow 0.6 to 1.0; -2.2 to -2.0 rad; 5 to 6 N m |
| The folded writing | (0, 2.463) rad | elbow 2.2 to 2.5 |
| The tumbling body | principal moments 0.007011, 0.005134 and 0.007883 kg m2; spin (-2.38, 0.92, -1.75) rad/s along its own axes, 3.09 rad/s in size | 0.003 to 0.012 kg m2; -3.5 to 3.5 rad/s |

Not drawn: the pushes, 0.5, 0.75 and 0.95 of the cube's friction limit (Study 2); the directions, 0, 22.5 and 45 degrees;
the stacks of 5 and 9; the ball 1 m above the ground when held, and the plays' lengths; the tumbling body's mass and the
record's step ladder, 10 ms over 1, 4, 16 and 64; the second contact suite, played with its own registered parameters.

## The scenes

Every arm plays, at both steps unless said:

- **The cube held**, pushed at 0.5, 0.75 and 0.95 of its friction limit along 0, 22.5 and 45 degrees, 1.6 s (18 plays);
  **slid** along each direction, kept from turning (6); and **slid free to turn** along each, at the coarse step (3).
- **The first deep dive's two contact suites**: the first on the fresh cube, the second with its registered parameters.
- **Stacks** of 5 and 9 cubes, the offset stack of 3, and one cube slid on the ground and on a box's face.
- **The grip**: the cube between two pads, box and mesh pads, at the centre and off it, at the coarse step (4).
- **The arm on contact**: set down and dropped, in each pose, written three ways: in its own pose (native), straight (0,
  0) and folded (0, 2.463).
- **The arm held 1 m up**: swinging onto an elbow limit, held by joint friction, by a `connect` and by a `weld`, in each
  pose, written the same three ways.
- **The tumbling body**, no gravity, nothing touching it, 2 s at each step of the ladder.
- **MuJoCo's own test suite**: the release's, and the patched build's with the switch unset and set.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. "Apart" is `sx_contact ends` between a
writing and the native writing of the same pose, scene and step: the ball's height at the last step (nm) and the larger
difference of its two speeds (um/s). A creep is `sx_contact creep`'s mean speed; a slide's distance `sx_contact stop`'s;
its drift across its line the rig's own `side_um`. A drift of the tumbling body is `sx_tumble tumble`'s largest over the
play, in parts per million of the start.

**Shared** (read once):

| Rule | Statement | From |
|---|---|---|
| Q1 the release creeps | rel_def: the hold at 0.5 along 0 degrees, coarse step, creeps at least 100 um/s | Study 2's R1 |
| Q2 the release has a direction | rel_def: the slide along 45 degrees, coarse step, goes at least 15% further than along 0 | Study 2's R1 |
| Q3 the release fails the hold | rel_def: the first suite's T06 fails | Study 2's R5 |
| Q4 the defect is there | rel_def: in each pose, scene and step the straight writing ends at least 1 um from the native (24 lines) | Studies 5, 7, 8 and 9's R3 |
| E1 safe when off, plays | Every file off_def plays is byte-identical to rel_def's, and every file off_rec plays to rel_rec's (2 lines) | their R1 |
| E2 safe when off, MuJoCo's suite | Switch unset: every one of MuJoCo's tests gives the release's result | their R2 |
| N1 nothing else changes, plays | config: every cube play, both suites and the tumbling body byte-identical to rel_rec's | their R7 |
| N2 nothing else changes, MuJoCo's suite | Switch set against unset: no test changes | their R8 |

**For each configuration arm**, config and config_rk4, the same rules:

| Rule | Statement | From |
|---|---|---|
| H1 every hold holds | All 18 holds creep at most 10 um/s | Study 2's R2 |
| G1 the grip holds | All four grips creep at most 10 um/s | new: Study 2's R2 for a load held between two pads, whose friction is 1.93 times the load |
| S1 no direction | Each step: the slides along 22.5 and 45 degrees within 1 part in 10,000 of the slide along 0 | Study 2's R3 |
| S2 no drift | Each step: every slide drifts across its line at most 10 um | Study 1's R4 |
| S3 Coulomb | Fine step: every slide within 1 part in 100 of 133,451 um | Study 2's R4 |
| S4 the free cube | Slid free to turn: along 22.5 and 45 degrees within 1 part in 100 of along 0, and drifting at most 1,000 um (2 lines) | Study 1's R8 |
| K1 the ten tests | The first suite: 10 of 10 | Study 2's R5 |
| A4 correct, place | Every straight and folded writing ends within 100 nm of the native, in every scene, pose and step (48 lines) | Studies 5, 7, 8 and 9's R4 |
| A5 correct, speed | The same, within 10 um/s (48 lines) | their R5 |
| A6 correct, creep | Resting on contact and held by joint friction: the creep of the straight and folded writings within 1 um/s of the native's (16 lines) | Studies 5, 7 and 8's R6, read here under the configuration |
| V1 the solver | Over every play: no step at the iteration limit, no warning (2 lines) | their R9 |
| V2 the solver's cost | The holds, the slides kept from turning and both suites: the most iterations of any step no more than rel_def's most on the same plays plus 3 | Study 2's R6, on the plays of its kind |
| T1 the energy | The tumbling body: the largest energy drift no more than 5,000 per million at 10 ms, 1,000 at 2.5 ms, 500 at 0.625 and 0.15625 ms (4 lines) | Study 9's T1 |
| T2 the angular momentum | The same, the angular momentum within 100 per million (4 lines) | Study 9's T2 |

There are 298 rule lines: 32 shared, and 133 for each configuration arm. The most iterations over every play is
reported, not ruled; the stacks and the slides on a box's face are played and their files kept, not read.

## The decisions

- **The recommended configuration**: if every shared rule and every rule of the config arm holds, MuJoCo's recommended
  configuration with the third version's switch set is recorded as **validated end to end**.
- **The same under RK4**: if every shared rule and every rule of the config_rk4 arm holds, the configuration under RK4
  is recorded as validated end to end.
- **The patch under the configuration**: for each arm, if Q4, E1, E2, N1, N2 and that arm's A4 to A6 and V1 hold, the
  third version is recorded as validated under the configuration with that integrator.
- **The configuration's contact**: for each arm, if Q1 to Q3 and that arm's H1, S1 to S3, K1 and V2 hold, Study 2's
  result is recorded as replicated on fresh numbers with that integrator.
- A rule that fails is recorded as measured, with its numbers, and what it concerns stays open.
- Nothing about MuJoCo's pyramidal cone or the slip-aligned pyramid (Study 1) is decided.

## Known risks, stated before the run

From run 041, on throwaway numbers, with the configuration's switch set:

- **Under the default integrator T1 and T2 failed on all eight lines** (the energy 34,145 to 507 per million, the angular
  momentum 12,677 to 188, from 10 ms to 0.156 ms), as Study 9 found. Under RK4 they held.
- **Under RK4 the first suite passed 7 of 10** (K1), as finding F4 records from run 014.
- **The free cube** slid along 22.5 degrees went 1.7% (default integrator) and 2.4% (RK4) further than along 0 and drifted
  996 and 970 um, against S4's 1 in 100 and 1,000 um. The release under the same options plays it byte for byte as the
  configuration's default-integrator arm: it is MuJoCo's, not the patch's.
- **The most iterations over every play** were 11 (default integrator) and 14 (RK4), against the release's 6 under its
  defaults, from the arm and the free cube; on the plays V2 reads, the dry run's release arms needed 4 (defaults) and 5
  (the configuration's options).

## What is not asked

The pyramidal cone and the slip-aligned pyramid; the stacks' sink with their load and the offset stack's lean (finding
F11); a sliding body's lift (F3); a bounce (F8); the cause of the tumbling body's drift (F4); the arm's own creep at rest
(F1); gradients; anything against a real robot.

## Dry run

`DRY=1` played the two release arms, rel_def and rel_rec, on throwaway numbers (Study 8's arm and cubes, Study 2's cube,
run 039's body), with no build and no MuJoCo suite, to the end: 220 measured lines, none empty
([`validation/run_042_study_10/dry/`](../validation/run_042_study_10/dry/)). No rule was read from it. The configuration
arms' plays and rules were read on throwaway numbers by run 041's probe.
