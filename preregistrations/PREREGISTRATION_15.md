# Fifteenth pre-registration: Senua AI's set together, the configuration with its three patches

Registered 17 October 2026, after the design probes of runs 066 and 068. Registered before any play of this
registration existed. To be played once, as run 071.

## The question

Senua AI's set is the configuration (the elliptic cone with 100 noslip iterations, MuJoCo's own options; Studies 2, 10
and 13) with three patches, each off unless its switch is set:

- the inverse weight in the current pose, third version
  ([`patches/invweight_at_pose_v3.diff`](../patches/invweight_at_pose_v3.diff), `MUJOCO_INVWEIGHT_AT_POSE=1`,
  `engine_core_constraint.c`), validated by Studies 8 to 10;
- de Saxce's correction ([`patches/desaxce_elliptic_v4.diff`](../patches/desaxce_elliptic_v4.diff),
  `MUJOCO_DESAXCE=1`, `engine_forward.c`), validated by Study 12;
- the friction solved in the directions that can move
  ([`patches/in_design/qcqp_reduced.diff`](../patches/in_design/qcqp_reduced.diff), `MUJOCO_QCQP_REDUCED=1`,
  `engine_solver.c`), in design.

Issue 1 of [the issue list](../docs/issues.md), a held object creeps at a contact, is fixed for a cube held and a cube
gripped and open for an arm resting on its ball. Study 14 held 13 of 15. The friction solve held every resting arm at 0
and changed nothing else. Its R2 failed: one dropped arm was still sliding from its landing in the window read, from
0.5 s of a 1 s play. Its K1 failed: T08 fails under the configuration, released and patched alike, from the elliptic
cone's hop, which de Saxce's correction removes (run 065). In runs 066 and 068 the three patches together held every
resting and every dropped arm of three arms at 0, under the default integrator and under RK4. Every landing slide ended
by 0.656 s. The first suite passed 10 of 10 on both its cubes, and of MuJoCo's tests only the two Study 12 traced in
advance changed.

On numbers no earlier study or probe used, with every switch set: does the set hold an arm resting on a contact, set
down or dropped, in every pose played, under the default integrator and under RK4? Does it hold the arm held by joint
friction, every hold and every grip? Under the default integrator, does it keep de Saxce's fixes (no lift, no
direction, four corners on the ground, Coulomb's distance) and pass the first suite's ten tests? With every switch
unset, is the patched MuJoCo the release, file for file and test for test? With every switch set, do any of MuJoCo's
tests change but the two Study 12 named?

## Engines and arms

- **rel_def**, **rel_rec**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
  139577c541d43716...), under MuJoCo's defaults and under the configuration.
- **off_def**, **off_rec**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with the three patch files
  applied (gcc, CMake and Ninja, a Release build; its tests built the same way), rebuilt by the runner from the patch
  files; every switch unset.
- **on_rec**: the same build, every switch set, under the configuration with MuJoCo's default integrator.
- **on_rk4**: the same, under RK4 (Study 10's second integrator).

MuJoCo's own test suite on the release's test build (run 020's) and on the patched one, every switch unset and every
switch set. Played on the first cloud machine (AWS EC2 c7i.xlarge, Intel, 4 virtual CPUs, 8 GB).

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_071_study_15/play.sh`](../validation/run_071_study_15/play.sh) | 91b60dfb86a18752... |
| Rigs | `tools/mjc_arm.c`, `tools/mjc_contact.c`, `tools/mjc_grip.c`, as in Study 14 | d52885fb08c646ff..., 31ea6cc56a204143..., a57125297b421248... |
| | `tools/contact_suite.sh`, `tools/build_rig.sh` | 8cda2ed242cad7df..., b6a93676e6aee763... |
| Senua AI's measures | `sx_contact` (`creep`, `stop`, `hover`, `rule`), as run in Studies 10 to 14 | source 87e921cd4d2c03bf... (built for Linux: f09ea027cec7820d...) |
| | The first deep dive's suite runner, `sx_contact_suite.sh`, as run | 553d46ecdaf2bd95... |
| The patches | `patches/invweight_at_pose_v3.diff`, `patches/desaxce_elliptic_v4.diff`, `patches/in_design/qcqp_reduced.diff` | d3fd45cc3d3ecfb0..., 00cb8f8eb4a07535..., 22f07ccf8abf316e... |

## The numbers, and how they were drawn

By Study 10's procedure, from x(0) = 15, on Study 10's ranges and grids, with two contact poses drawn from each of Study
10's two contact pose ranges. A value the record already used for a quantity of the same kind was drawn again: Study
14's lists, the values Study 14 drew, the settings of runs 064 to 070, and any value this draw had already given that
kind. Five draws were redrawn: an arm link of 0.269 m; set-down heights of 0.5 and 0.4 mm; a suite chain speed of
1.47 m/s, twice. `DRAW=1 bash validation/run_071_study_15/play.sh` prints the draw.

| What | The numbers |
|---|---|
| The steps | 1.71 ms, and a quarter of it, 0.4275 ms |
| The arm | links of 0.279 m and 0.286 m, 1.116 kg and 0.436 kg, a ball of 0.0284 m and 0.199 kg, friction 0.686 |
| On contact | poses (0.555, 0.905), (1.157, -0.378), (0.57, 1.123) and (1.296, -0.403) rad; set down from 0.43 mm, dropped from 12.9 mm |
| Held 1 m up | poses (0.312, 0.811) and (0.277, 0.796) rad, joint friction 5.15 N m on each hinge |
| The cube held and slid | 1.56 kg, half-size 0.041 m, friction 0.462, slid at 0.94 m/s |
| The first suite's cube | 1.704 kg, half-size 0.0314 m, dropped from 0.083 m, launched at 3.51 and 1.28 m/s, friction 0.416, slid at 3.62 m/s, held at friction 0.436 |
| The grip | a cube of 0.21 kg, half-size 0.0334 m, friction 0.69, squeezed with 2.61 N (the pads' friction 1.75 times its weight), 9.2 mm off centre |

Not drawn: the mirror image of each contact pose, (pi - q1, -q2); Study 12's ladder of steps for the lift (10, 2.5,
0.625 and 0.15625 ms); the pushes, the directions and the plays' lengths, as in Studies 12 and 14, but for the dropped
arm's.

**The dropped arm is played for 3 s, not 1 s as in Study 14,** and read over its second half, from 1.5 s, as every creep
is. The reason, stated before the run: in Study 14 a dropped arm slid on landing at its friction limit, a real slide,
and came to rest at 0.61 s, after the window read had begun at 0.5 s. In runs 066 and 068 the latest any of 8 dropped
poses of three arms moved, at two steps each, was 0.656 s. The longer play reads the arm at rest. It does not hide a
creep: a creeping arm creeps to the end of the play (released, 79 to 591 um/s at 3 s in run 066).

## The scenes

Each arm, at both steps:

- the arm set down on its ball in each of the four contact poses, as written and mirrored, and left at rest, 2 s;
- dropped onto its ball in each pose, 3 s;
- held 1 m up by joint friction in each held pose, 2 s;
- the cube held at 0.5, 0.75 and 0.95 of its friction limit along 0, 22.5 and 45 degrees (18 plays);
- slid kept from turning along 0, 22.5 and 45 degrees, and free to turn along 0, 11.25, 22.5, 33.75 and 45;
- the grip, box and mesh pads, at the centre and off it.

Then the cube slid along 0 at each step of the ladder, and the first contact suite on the fresh cube.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. A creep is `sx_contact creep`'s mean
speed over the play's second half: for the arm on contact and held, its ball's speed; for a cube, its speed. A lift is
`sx_contact hover`'s highest point of the cube's lowest face above the ground; a distance is `sx_contact stop`'s; the
drift, the turn and the steps on fewer than four corners are the contact rig's own STATS fields, as in Study 12.

| Rule | Statement | From |
|---|---|---|
| Q1 the release's arm creeps | rel_rec: some resting pose creeps more than 10 um/s | Studies 10, 13 and 14 |
| Q2 the release's cube lifts | rel_rec: the cube slid at 10 ms rises at least 100 um | Study 12's Q1 |
| Q3 the release's free cube leaves its corners | rel_rec: some step of a free slide has fewer than four contacts | Study 12's Q3 |
| E1 safe when off | Every play file off_def and off_rec make byte-identical to rel_def's and rel_rec's (2 lines; the files that record the settings left out) | Studies 5 to 14 |
| E2 safe when off, MuJoCo's suite | Every switch unset: every one of MuJoCo's tests gives the release's result | their R2 |
| M1 MuJoCo's suite, every switch set | Against every switch unset, no test changes but `ForwardTest.DiscreteImplicitRowNoslip` and `SolverTest.ZeroToleranceDisablesTermination` | Study 12's M1 |
| R1 every resting pose holds | on_rec and on_rk4: every one of the 16 resting plays (4 poses, as written and mirrored, 2 steps) creeps at most 10 um/s (2 lines) | Study 2's R2 bound |
| R2 every dropped arm holds | on_rec and on_rk4: every one of the 8 dropped plays creeps at most 10 um/s over its second half (2 lines) | Study 2's R2 bound |
| J1, H1, G1 what the set holds | on_rec and on_rk4: the arm held by joint friction, every hold and every grip at most 10 um/s (6 lines) | Studies 2, 10, 13 and 14 |
| V1 the solver | on_rec and on_rk4: no step at 100 iterations or more (MuJoCo counts noslip's with the main solver's); no warning (4 lines) | Studies 5 to 14 |
| L1 no lift | on_rec: the cube slid kept from turning rises at most 1 um, along every direction at both steps and along 0 at every step of the ladder | Study 12's L1 |
| L2 four corners | on_rec: no step of any free slide has fewer than four contacts | Study 12's L2 |
| D1 no direction | on_rec, each step: the free slides along 11.25 to 45 degrees within 1 part in 10,000 of along 0; the kept slides along 22.5 and 45 within 1 part in 10,000 of along 0 (4 lines) | Study 12's D1 |
| D2 no drift | on_rec, each step: every slide ends at most 10 um off its line (2 lines) | Study 12's D2 |
| D3 no turn | on_rec, each step: no free slide turns more than 1,000 urad (2 lines) | Study 12's D3 |
| C1 Coulomb | on_rec, the fine step: every slide, free and kept, within 1 part in 100 of Coulomb's distance, 97,579 um | Study 12's C1 |
| K1 the ten tests | on_rec: the first suite 10 of 10 | Studies 2, 10 and 12 |

There are 33 rule lines. Reported, not ruled: the most iterations on a step, the time each dropped arm last moves,
MuJoCo's tests that change, and the first suite under RK4.

## The decisions

- **Issue 1, a held object creeps at a contact**: if Q1, E1, E2, M1, and every R1, R2, J1, H1, G1 and V1 line hold, it is
  recorded as **fixed and validated**. That covers a cube held and gripped, an arm resting on a contact (set down and
  dropped) and an arm held by joint friction, by Senua AI's set with every switch set, under the default integrator and
  under RK4. The friction solve moves from `patches/in_design/` to `patches/`.
- **The set together**: if every rule holds, the configuration with its three patches is recorded as **validated
  together**, under the default integrator, for everything this study rules. Under RK4 that covers what R1, R2, J1, H1,
  G1 and V1 rule.
- **Issues 4 and 5** (de Saxce's): L1, L2, D1 to D3, C1 and K1 replicate Study 12's rules with the other two patches on.
  A failure is recorded against the set, not against Study 12.
- A rule that fails is recorded as measured, with its numbers, and what it concerns stays open.
- Not decided: the stacks (issue 21) and the box that never rests (issue 20), both open and played in other probes;
  the first suite under RK4 (its T01 cannot be read under RK4, Study 10); MuJoCo's dual (PGS) solver; contacts with
  torsional or rolling friction (condim 4 and 6); anything against a real robot.

## Known risks, stated before the run

- **R2**: a fresh arm whose landing slide lasts past 1.5 s would fail it. In runs 066 and 068 none lasted past 0.656 s.
- **Q1**: the defect needs a resting pose in which MuJoCo's friction solve rejects the block. In Study 14 and runs 056
  to 068 most poses met it, not all. On a fresh arm none of the four poses might.
- **The coarse step, 1.71 ms**, is the coarsest any study of the arm has played (Studies 10, 13 and 14: 1.14, 1.68 and
  1.19 ms). The probes of runs 066 and 068 played the three patches at 1.14 and 1.19 ms only.
- **M1**: with three patches on, a test Study 12 did not name could change. In run 068 none did.
- **V1 under RK4**: in run 068 the release under RK4 reached the iteration limit on a cube slid on a box's face, a play
  not in this study. With every switch set it did not.

## What is not asked

Everything listed as not decided above.

## Dry run

`DRY=1` played the six arms on throwaway numbers (Study 14's), with no build and no MuJoCo suite. The patched arms used
run 068's build of the same three patch files. It played to the end: 456 measured lines, none empty
([`validation/run_071_study_15/dry/`](../validation/run_071_study_15/dry/)).

Its first pass found the free slides' yaw and corner fields empty. The contact rig adds them to its STATS line only
with its `trace` setting, which Study 12's runner passed and this one had not. The runner was corrected and the dry run
played again, with every line filled.

The rules were then judged on its lines in a scratch copy
([`dry/rules_plumbing.sh`](../validation/run_071_study_15/dry/rules_plumbing.sh)) to check the plumbing. Run 064's
release and run 068's suite results stood in for the three suites, with one test changed by hand in the switch-set
suite. All 33 rule lines were judged, and M1 failed on the changed test as it should
([`dry/rules_plumbing.txt`](../validation/run_071_study_15/dry/rules_plumbing.txt)). No rule is read from the dry
run.
