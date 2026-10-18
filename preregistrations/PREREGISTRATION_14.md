# Fourteenth pre-registration: the friction solved in the directions that can move, for an arm resting on a contact

Registered 17 October 2026, after the design probes of runs 054 and 056 to 063. Registered before any play of this
registration existed. To be played once, as run 064.

## The question

Issue 1 of [the issue list](../docs/issues.md), a held object creeps at a contact, is fixed for a cube held and a cube
gripped (Studies 2, 10, 11 and 13) and open for an arm resting on its ball: under Senua AI's configuration Study 10's arm
creeps at 714 um/s in one pose and Study 13's at 191 um/s, inside their friction cones. Run 062 traced it in MuJoCo's
source: noslip solves an elliptic contact's friction with `mju_QCQP2` (or `mju_QCQP3`, `mju_QCQP`), which rejects the
friction block by an absolute threshold when one friction direction cannot move (the arm's, across its plane), returns
zero friction, and MuJoCo puts the old friction back. The patch in design,
[`patches/in_design/qcqp_reduced.diff`](../patches/in_design/qcqp_reduced.diff) (switch `MUJOCO_QCQP_REDUCED=1`,
`engine_solver.c` only, 67 lines added and none removed), sets the friction in such a direction to zero, since it does
nothing to the motion, and solves the other directions with MuJoCo's own solvers in the same ellipsoid; any other contact
is solved as released. In run 063, on Study 10's numbers, it held every resting pose of both arms at 0, as written and
mirrored, and changed no other play and none of MuJoCo's 3,492 tests.

On numbers no earlier study or probe used: with the switch set, does Senua AI's configuration hold an arm resting on a
contact, set down or dropped, in every pose played, while everything else it plays is exactly as released? With the
switch unset, is the patched MuJoCo the release, file for file and test for test? With it set, does any of MuJoCo's tests
change?

## Engines and arms

- **rel_def**, **rel_rec**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
  139577c541d43716...), under MuJoCo's defaults and under Senua AI's configuration (`cone=elliptic`,
  `noslip_iterations=100`, Study 13).
- **off_def**, **off_rec**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with the patch file applied
  (gcc, CMake and Ninja, a Release build; its tests built the same way), rebuilt by the runner from the patch file; switch
  unset.
- **on_def**, **on_rec**: the same build, switch set.

MuJoCo's own test suite on the release's test build (run 020's) and on the patched one, switch unset and set. Played on the
first cloud machine (AWS EC2 c7i.xlarge, Intel, 4 virtual CPUs, 8 GB).

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_064_study_14/play.sh`](../validation/run_064_study_14/play.sh) | 87a4db1a5e95e3ec... |
| Rigs | `tools/mjc_arm.c` (with `trace`, `impratio`, `noslip_tolerance` and `fricsolref`, unchanged without them), `tools/mjc_contact.c`, `tools/mjc_grip.c` | d52885fb08c646ff..., 31ea6cc56a204143..., a57125297b421248... |
| | `tools/contact_suite.sh`, `tools/build_rig.sh` | 8cda2ed242cad7df..., b6a93676e6aee763... |
| Senua AI's measures | `sx_contact` (`creep`, `stop`, `rule`), as run in Studies 10 to 13 | source 87e921cd4d2c03bf... (built for Linux: f09ea027cec7820d...) |
| | The first deep dive's suite runner, `sx_contact_suite.sh`, as run | 553d46ecdaf2bd95... |
| The patch | `patches/in_design/qcqp_reduced.diff` | 22f07ccf8abf316e... |

## The numbers, and how they were drawn

By Study 10's procedure, from x(0) = 14, on Study 10's ranges and grids, with two contact poses drawn from each of Study
10's two contact pose ranges. A value the record already used for a quantity of the same kind (Study 13's lists, the
values Studies 10 to 13 drew, the settings of runs 043 to 063), or one this draw had already given that kind, was drawn
again: six were (masses of 1.113 and 0.209 kg, an angle of 0.993 rad, speeds of 3.19 and 1.15 m/s, an offset of 9.8
mm). `DRAW=1 bash validation/run_064_study_14/play.sh` prints the draw.

| What | The numbers |
|---|---|
| The steps | 1.19 ms, and a quarter of it, 0.2975 ms |
| The arm | links of 0.298 m and 0.269 m, 1.164 kg and 0.522 kg, a ball of 0.0273 m and 0.167 kg, friction 0.667 |
| On contact | poses (0.582, 1.117), (1.227, -0.516), (0.58, 0.969) and (1.276, -0.407) rad; set down from 0.54 mm, dropped from 14.6 mm |
| Held 1 m up | poses (0.156, 0.951) and (0.243, 0.637) rad, joint friction 5.12 N m on each hinge |
| The cube held and slid | 1.564 kg, half-size 0.0449 m, friction 0.411, slid at 1.15 m/s |
| The first suite's cube | 1.7 kg, half-size 0.0426 m, dropped from 0.07 m, launched at 3.36 and 1.45 m/s, friction 0.413, slid at 4.53 m/s, held at friction 0.443 |
| The grip | a cube of 0.225 kg, half-size 0.0326 m, friction 0.689, squeezed with 3.15 N (the pads' friction 1.97 times its weight), 7.7 mm off centre |

Not drawn: the mirror image of each contact pose, (pi - q1, -q2); the pushes, the directions and the plays' lengths, as in
Study 13.

## The scenes

Each arm, at both steps: the arm set down on its ball in each of the four contact poses, as written and mirrored, and
left at rest, 2 s, traced; dropped onto its ball in each pose, 1 s; held 1 m up by joint friction in each held pose, 2 s;
the cube held at 0.5, 0.75 and 0.95 of its friction limit along 0, 22.5 and 45 degrees (18 plays), slid along each kept
from turning and free to turn; the grip, box and mesh pads, at the centre and off it; and the first contact suite on the
fresh cube.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. A creep is `sx_contact creep`'s mean
speed over the play's second half: for the arm on contact and held, its ball's speed; for a cube, its speed.

| Rule | Statement | From |
|---|---|---|
| Q1 the release's arm creeps | rel_rec: some resting pose creeps more than 10 um/s | Studies 10 and 13, run 056 |
| E1 safe when off | Every play file off_def and off_rec make byte-identical to rel_def's and rel_rec's (2 lines; the files that record the settings left out, as in Study 13) | Studies 5 to 13 |
| E2 safe when off, MuJoCo's suite | Switch unset: every one of MuJoCo's tests gives the release's result | their R2 |
| P1 untouched where the solve is not used | Every play file on_def makes byte-identical to rel_def's (MuJoCo's defaults use neither noslip nor the elliptic cone) | new |
| M1 MuJoCo's suite, switch set | Against the switch unset, no test changes | Studies 5 to 10's R8 |
| R1 every resting pose holds | on_rec: every one of the 16 resting plays (4 poses, as written and mirrored, 2 steps) creeps at most 10 um/s | Study 2's R2 bound |
| R2 every dropped arm holds | on_rec: every one of the 8 dropped plays creeps at most 10 um/s over its second half | Study 2's R2 bound |
| N1 nothing else changes | on_rec: every play file of the arm held by joint friction, the cubes, the grips and the suite byte-identical to rel_rec's | run 063 |
| J1, H1, G1, K1 what the configuration holds | on_rec: the arm held by joint friction, every hold and every grip at most 10 um/s; the first suite 10 of 10 (4 lines) | Studies 2, 10 and 13 |
| V1 the solver | on_rec: no step at 100 iterations or more (MuJoCo counts noslip's with the main solver's); no warning (2 lines) | Studies 5 to 13 |

There are 15 rule lines. The most iterations on a step, the ball's slip and the force ratios are reported, not ruled.

## The decisions

- **Issue 1, a held object creeps at a contact**: if every rule holds, it is recorded as **fixed and validated**: for a
  cube held and gripped by Senua AI's configuration (Studies 2, 10, 11 and 13), and for an arm resting on a contact by the
  configuration with this patch's switch set. The patch moves from `patches/in_design/` to `patches/`.
- A rule that fails is recorded as measured, with its numbers, and what it concerns stays open.
- Not decided: MuJoCo's dual (PGS) solver, which calls the same solve (not played here); contacts with torsional or
  rolling friction (condim 4 and 6), whose solves the patch covers but no play here uses; the other patches, not played
  with this one; anything against a real robot.

## Known risks, stated before the run

- **Q1**: the defect needs a contact whose one friction direction cannot move and whose other is small enough for
  MuJoCo's threshold to reject the block; in runs 056 to 063 three of four resting poses of two arms met it, one did not.
  On a fresh arm none of the four poses might.
- **N1**: in run 063 every play but the resting arms' was byte for byte as released with the switch set; a cube or grip
  contact whose friction block has a direction 1e-10 of its largest would also change.
- **R2**: a dropped arm whose ball bounces or slides before it settles is read over its second half only. In the dry run,
  with the switch set, the dropped arm in two of its four poses still moved at 2 to 8 um/s over its second half.

## What is not asked

Everything listed as not decided above; the stacks (issue 21) and the box that never rests (issue 20).

## Dry run

`DRY=1` played the six arms on throwaway numbers (Study 10's arm in Study 10's and Study 13's contact poses, Study 10's
cubes and grip), the patched arms on run 063's build of the same patch file, with no build and no MuJoCo suite, to the
end: 408 measured lines, none empty ([`validation/run_064_study_14/dry/`](../validation/run_064_study_14/dry/)). The rules
were then judged on its lines in a scratch copy, with run 063's and Study 12's suite results standing in for the three
suites and one test changed by hand in the switch-set suite, to check the plumbing: 15 rule lines, each judged, M1 failing
on the changed test as it should ([`dry/rules_plumbing.txt`](../validation/run_064_study_14/dry/rules_plumbing.txt)). No
rule is read from the dry run.
