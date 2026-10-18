# Twentieth pre-registration: the friction solve dropping a direction at noslip's floor, for a cube that cannot turn

Registered 17 October 2026, after the probes of runs 079, 083, 084 and 086. Registered before any play of this
registration existed. To be played once, as run 087.

## The question

Issue 1 of [the issue list](../docs/issues.md), a held object creeps at a contact, is fixed and validated for condim 3
(Study 15). It is open for a cube that cannot turn (held on three slide joints) with torsional or rolling friction
(condim 4 or 6). Under Senua AI's configuration such a cube creeps at 498 and 946 um/s at 0.5 and 0.95 of its friction
limit, released and in Senua AI's set alike. A free cube with condim 4 or 6 holds (run 084).

Noslip takes a contact's block without its regularisation, and clamps each diagonal entry from below at 1e-10
(`extractBlock`, `engine_solver.c`). A cube that cannot turn has no give in its torsional and rolling directions, so
those entries sit at that floor. The friction-solve patch, [`qcqp_reduced.diff`](../patches/qcqp_reduced.diff), drops a
direction whose entry is at most 1e-10 of the block's largest. A cube of more than 1 kg has a largest entry below 1, so
the floor is kept. That is the patch's reasoning; the probes did not trace the entries step by step.

Its second version, [`patches/in_design/qcqp_reduced_v2.diff`](../patches/in_design/qcqp_reduced_v2.diff) (the same
switch, `MUJOCO_QCQP_REDUCED=1`), changes one condition: a direction is also dropped at noslip's floor of 1e-10.
Because no entry is below the floor, it differs from the first version only when the block's largest entry is below 1,
and then only in dropping the entries at the floor. In run 086, with Senua AI's set, it held every such cube at 0 um/s
with condim 4 and 6. Of 88 play files, it changed only those 8. Of MuJoCo's tests only one of the two Study 12 named
changed, and with every switch unset it was the release.

On numbers no earlier study or probe used: with the second version in Senua AI's set, does every hold hold, with
condim 3, 4 and 6, held from turning and free, along three directions? Is everything else the set plays exactly as with
the first version? Do the arms, grips and boxes the set holds still hold? With every switch unset, is the patched MuJoCo
the release? Do any of MuJoCo's tests change but the two Study 12 named?

## Engines and arms

- **rel**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256 139577c541d43716...).
- **v1**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with Senua AI's five validated patch files
  applied in this order: [`invweight_at_pose_v3.diff`](../patches/invweight_at_pose_v3.diff),
  [`desaxce_elliptic_v4.diff`](../patches/desaxce_elliptic_v4.diff), [`qcqp_reduced.diff`](../patches/qcqp_reduced.diff),
  [`boxbox_collinear.diff`](../patches/boxbox_collinear.diff),
  [`noslip_roll_kept_after_qcqp.diff`](../patches/noslip_roll_kept_after_qcqp.diff).
- **v2**: the same, with `qcqp_reduced_v2.diff` in place of `qcqp_reduced.diff`, its tests built too.
- Both are built with gcc, CMake and Ninja, a Release build, rebuilt by the runner from the patch files.
- The four arms: **rel**; **off**, v2 with every switch unset; **v1set** and **v2set**, each with the five switches set.

The holds, the arms and the grips play under Senua AI's configuration (the elliptic cone, 100 noslip iterations). The
boxes play with their scenes' own options. MuJoCo's own test suite runs on the release's test build (run 020's) and on
v2's, every switch unset and the five set. Played on the first cloud machine (AWS EC2 c7i.xlarge, Intel, 4 virtual
CPUs, 8 GB).

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_087_study_20/play.sh`](../validation/run_087_study_20/play.sh) | ad2bc4b824e541de... |
| Rigs | `tools/mjc_scene.c`, `tools/mjc_arm.c`, `tools/mjc_contact.c`, `tools/mjc_grip.c`, `tools/build_rig.sh` | 90368f280c6e948e..., d52885fb08c646ff..., 31ea6cc56a204143..., a57125297b421248..., b6a93676e6aee763... |
| Scenes | MuJoCo's box, [`validation/run_049_desaxce_v4/step2/scene.xml`](../validation/run_049_desaxce_v4/step2/scene.xml), and Study 19's six, [`validation/run_085_study_19/scenes/`](../validation/run_085_study_19/scenes/) | b10dbf28fc9e6c37...; the six: 45344c18b49b1674... together, in name order |
| Senua AI's measures | `sx_contact creep` and `sx_contact rule`, as run in Studies 10 to 19 | source 87e921cd4d2c03bf... (built for Linux: f09ea027cec7820d...) |
| The patches | the five above and `patches/in_design/qcqp_reduced_v2.diff` | d3fd45cc3d3ecfb0..., 00cb8f8eb4a07535..., 22f07ccf8abf316e..., dcb3bfcef68fbb1c..., 1e0ecc589760e23e..., 37cde954b88306bb... |

## The numbers, and how they were drawn

By Study 10's procedure, from x(0) = 20. A value the record already used for a quantity of the same kind was drawn
again. The lists: Study 19's and the values it drew; Study 16's friction list and the frictions Studies 16 and 19
played; the settings of runs 085 and 086; and any value this draw had already given that kind. Two were redrawn: a mass
of 1.1 kg and a friction of 0.762. `DRAW=1 bash validation/run_087_study_20/play.sh` prints the draw.

| What | The numbers |
|---|---|
| The holds' step | 1.277 ms, and a quarter of it, 0.31925 ms |
| Cube a, from 1 to 2.5 kg | 1.572 kg, half-size 0.0474 m, friction 0.61 |
| Cube b, from 0.3 to 1 kg | 0.819 kg, half-size 0.0316 m, friction 0.734 |

Not drawn: the hold fractions (0.5, 0.75, 0.95 of the friction limit, mass times friction times 9.8) and directions
(0, 22.5, 45 degrees), which are Study 15's. The arms, the grip and the boxes are their studies' own, played to compare
and to check that what the set held still holds.

## The scenes

Each arm:

- each cube held at each fraction along each direction, with condim 3, 4 and 6, held from turning and free, at both
  steps, pushed from 0.4 s for 1.6 s (216 plays);
- the arms of Studies 10, 13, 14 and 15 set down and dropped, in their poses, at their studies' two steps (48 plays);
- Study 15's grip, box and mesh pads, centred and offset, at Study 15's two steps (8 plays);
- MuJoCo's own box and Study 19's six, as written and with 100 noslip iterations (14 plays).

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. A hold's, an arm's and a grip's creep is
`sx_contact creep`'s mean speed over the play's second half. A box's is the fastest of its last 160 steps, as Study 19
read it.

| Rule | Statement | From |
|---|---|---|
| Q1 the release's cube creeps | rel: some cube held from turning, with condim 4 or 6, creeps at 11 um/s or more | run 084 |
| Q2 version 1's cube creeps | v1set: the same | runs 084, 086 |
| E1 safe when off | Every play file off makes byte-identical to rel's | Studies 5 to 19 |
| M0 every suite read | Each of the three readings of MuJoCo's suite lists all 3,492 tests | Study 16's M0 |
| E2 safe when off, MuJoCo's suite | Every switch unset: every one of MuJoCo's tests gives the release's result | their R2 |
| M1 MuJoCo's suite, the five switches set | Against every switch unset, no test changes but `ForwardTest.DiscreteImplicitRowNoslip` and `SolverTest.ZeroToleranceDisablesTermination` | Study 15's M1 |
| P0 every play measured | In every arm, all 286 readings are numbers (216 holds, 48 arms, 8 grips, 14 boxes) | Study 16's M0 |
| H1 every hold holds | v2set: every one of the 216 holds at most 10 um/s | Studies 2 and 15 |
| N1 nothing else changes | v2set against v1set: every play file byte-identical but the holds of a cube held from turning with condim 4 or 6 | Studies 12 to 19 |
| R1 every arm holds | v2set: every arm at most 10 um/s | Study 15's R1, R2 |
| G1 every grip holds | v2set: every grip at most 10 um/s | Study 15's G1 |
| B1 every box rests | v2set: no step of a box's last 160 faster than 10 um/s | Study 19's R1 |
| V1 the solver | v2set: no step at the iteration limit; no warning (2 lines) | Studies 5 to 19 |

There are 14 rule lines. Reported, not ruled: every arm's readings, and which of MuJoCo's tests change.

## The decisions

- **Issue 1, a held object creeps at a contact**: if every rule holds, it is recorded as **fixed and validated** for
  condim 3, 4 and 6, by Senua AI's set with the second version in place of the first. The second version moves from
  `patches/in_design/` to `patches/` and takes the first's place in the set. The first stays, as the patch Study 15
  validated.
- Where N1 holds, what Studies 15 and 19 found carries to the set with the second version for the plays N1 compares.
- A rule that fails is recorded as measured, with its numbers, and the issue stays fixed in part.
- Not decided: a body other than a cube or an arm; the PGS solver; anything against a real robot.

## Known risks, stated before the run

- **Q2**: cube b weighs less than 1 kg, so its block's largest entry may be above 1, and the first version may hold it.
  Q2 reads cube a too, which weighs more, like run 086's cube that crept.
- **H1**: the free cubes with condim 4 and 6 have not been pushed along 22.5 and 45 degrees before, and a free cube can
  tip or turn.
- **N1**: it excludes exactly the plays the second version is meant to change. If it changes a condim-3 hold or a free
  cube, N1 fails.

## What is not asked

Everything listed as not decided above.

## Dry run

`DRY=1` played the four arms on throwaway numbers (run 086's cube as both cubes, at 1.14 and 0.285 ms) on run 086's two
builds of the same patch files, with no build and no MuJoCo suite, to the end, in 84 s: 572 measured lines, every
reading a number ([`validation/run_087_study_20/dry/`](../validation/run_087_study_20/dry/)). Released and with the first
version, the cube held from turning crept at up to 946 um/s with condim 4 and 6; with the second it held at 0. The
dry run's per-step play files (106 MB) are not kept; its measured lines, its statistics and its parameters are.

The rules were then judged on its lines in a scratch copy
([`dry/rules_plumbing.sh`](../validation/run_087_study_20/dry/rules_plumbing.sh)). Run 064's release and run 086's suite
results stood in for the three suites. By hand, one test was changed in the five-switch suite, one hold of v2set
changed to 50 um/s, and one released arm's reading blanked. All 14 rule lines were judged, and M1, H1 and P0 failed as
they should ([`dry/rules_plumbing.txt`](../validation/run_087_study_20/dry/rules_plumbing.txt)). No rule is read from
the dry run.
