# Nineteenth pre-registration: noslip leaving the rolling friction as it was, for the box that never rests

Registered 17 October 2026, after the design probes of runs 073, 076, 079, 082 and 084. Registered before any play of
this registration existed. To be played once, as run 085.

## The question

Issue 20 of [the issue list](../docs/issues.md) (F13): MuJoCo's own test scene `DiscreteImplicitRowNoslip` never
comes to rest. It is a box slid at 2 m/s on a plane, at a 16 ms step, under the discrete integrator, the elliptic cone,
impratio 10, condim 6 and 2 noslip iterations. The probes found:

- The box rocks on a six-step cycle, its contacts 4, 4, 4, 4, 2, 2, with noslip converging every step (run 073).
- Every contact's rolling torque sits at the edge of the elliptic cone, the one ellipsoid all of a contact's friction
  shares. With a rolling coefficient of 0.0001 that leaves the sliding friction no room. With condim 4 the box rests
  (run 076).

A patch in design, [`patches/in_design/noslip_roll_kept_after_qcqp.diff`](../patches/in_design/noslip_roll_kept_after_qcqp.diff)
(switch `MUJOCO_NOSLIP_ROLL_KEPT=1`, `engine_solver.c` only, 45 lines added, none removed, applied after
`qcqp_reduced.diff`), changes how noslip solves a condim-6 contact:

- it leaves the rolling friction as it was before the sweep, MuJoCo's main solve's on the first sweep;
- it solves the sliding and torsional friction in what the cone has left, through MuJoCo's `solveQCQP`, so the friction
  solved in the directions that can move applies to it.

In run 084, in Senua AI's set, it brought the box to rest where the set alone does not. It changed nothing else played
but condim-6 free cubes. Of MuJoCo's tests only one of the two Study 12 named changed.

On numbers no earlier study or probe used: with Senua AI's set and this switch, does every box come to rest? That is
MuJoCo's own box and three fresh ones written from its scene, at its step and a fresh one, with 2 and with 100 noslip
iterations. Is everything else the set plays exactly as without the switch? With every switch unset, is the patched
MuJoCo the release? Do any of MuJoCo's tests change but the two Study 12 named?

## Engines and arms

- **rel**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256 139577c541d43716...).
- **off**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with five patch files applied in this
  order: Senua AI's four validated patches ([`invweight_at_pose_v3.diff`](../patches/invweight_at_pose_v3.diff),
  [`desaxce_elliptic_v4.diff`](../patches/desaxce_elliptic_v4.diff), [`qcqp_reduced.diff`](../patches/qcqp_reduced.diff),
  [`boxbox_collinear.diff`](../patches/boxbox_collinear.diff)) and this one. Built with gcc, CMake and Ninja, a Release
  build, its tests built the same way, rebuilt by the runner from the patch files; every switch unset.
- **set4**: the four validated switches set.
- **set5**: those and this switch.

The boxes play with their scenes' own options. The arm, the holds and the grips play under Senua AI's configuration (the
elliptic cone, 100 noslip iterations). MuJoCo's own test suite runs on the release's test build (run 020's) and on the
patched one, every switch unset and the five set. Played on the first cloud machine (AWS EC2 c7i.xlarge, Intel, 4
virtual CPUs, 8 GB).

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_085_study_19/play.sh`](../validation/run_085_study_19/play.sh) | 256f2b5ce52a0baa... |
| Rigs | `tools/mjc_scene.c`, `tools/mjc_arm.c`, `tools/mjc_contact.c`, `tools/mjc_grip.c`, `tools/build_rig.sh` | 90368f280c6e948e..., d52885fb08c646ff..., 31ea6cc56a204143..., a57125297b421248..., b6a93676e6aee763... |
| MuJoCo's scene | [`validation/run_049_desaxce_v4/step2/scene.xml`](../validation/run_049_desaxce_v4/step2/scene.xml) | b10dbf28fc9e6c37... |
| Senua AI's measures | `sx_contact rule`, as run in Studies 10 to 18 | source 87e921cd4d2c03bf... (built for Linux: f09ea027cec7820d...) |
| The patches | the four above and `patches/in_design/noslip_roll_kept_after_qcqp.diff` | d3fd45cc3d3ecfb0..., 00cb8f8eb4a07535..., 22f07ccf8abf316e..., dcb3bfcef68fbb1c..., 1e0ecc589760e23e... |

## The numbers, and how they were drawn

By Study 10's procedure, from x(0) = 19, on ranges about MuJoCo's own box. A value the record already used for a
quantity of the same kind was drawn again: Study 18's lists, the values Studies 17 and 18 drew, the settings of runs
079 to 084, MuJoCo's own box, and any value this draw had already given that kind. One was redrawn: a speed of 2.4
m/s. `DRAW=1 bash validation/run_085_study_19/play.sh` prints the draw.

| What | The numbers |
|---|---|
| The fresh step | 14.11 ms, beside the scene's own 16 ms |
| Box 1 | half-size 0.0509 m, 0.978 kg, slid at 1.21 m/s |
| Box 2 | half-size 0.0416 m, 1.565 kg, slid at 2.05 m/s |
| Box 3 | half-size 0.0491 m, 1.342 kg, slid at 2.58 m/s |

Each fresh box's scene is MuJoCo's own with its half-size, its starting height (the half-size), its mass, its slide
speed and, at the fresh step, its timestep replaced, and nothing else (the runner writes them and counts the lines
changed). Not drawn: MuJoCo's own box, the plays' length (16 s), and the numbers of the arm, the held cube and the grip,
which are Study 15's and 16's, played only for the byte comparison N1.

## The scenes

Each arm:

- MuJoCo's own box as written, and with 100 noslip iterations;
- each fresh box at 16 ms and 14.11 ms, as written and with 100 noslip iterations (12 plays);
- and, under the configuration at Study 15's two steps: Study 15's arm set down and dropped in two poses, a cube held at
  0.5 and 0.95 of its limit with condim 3 and condim 4, free to turn, and Study 15's grip, box and mesh pads.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. A box's speed is the scene rig's speed
along its slide. Over a play's last 160 steps (2.56 s at 16 ms), the measured lines give how many steps are faster than
1 mm/s, and the fastest.

| Rule | Statement | From |
|---|---|---|
| Q1 the release's box keeps moving | rel: MuJoCo's own box, as written, faster than 1 mm/s on at least 10 of its last 160 steps | runs 049, 073 |
| E1 safe when off | Every play file off makes byte-identical to rel's | Studies 5 to 18 |
| M0 every suite read | Each of the three readings of MuJoCo's suite lists all 3,492 tests | Study 16's M0 |
| E2 safe when off, MuJoCo's suite | Every switch unset: every one of MuJoCo's tests gives the release's result | their R2 |
| M1 MuJoCo's suite, the five switches set | Against every switch unset, no test changes but `ForwardTest.DiscreteImplicitRowNoslip` and `SolverTest.ZeroToleranceDisablesTermination` | Study 15's M1 |
| R1 every box comes to rest | set5: in every one of the 14 box plays, no step of the last 160 faster than 10 um/s | Study 2's R2 bound |
| N1 nothing else changes | set5 against set4: every file of the arm, the holds (condim 3 and 4) and the grips byte-identical | Studies 12 to 16 |
| V1 the solver | set5: no step at the iteration limit; no warning (2 lines) | Studies 5 to 18 |

There are 9 rule lines. Reported, not ruled: the fresh boxes released and under set4, and which of MuJoCo's tests
change.

## The decisions

- **Issue 20, a box that should rest keeps moving under the discrete integrator with torsional and rolling friction and
  noslip**: if every rule holds, it is recorded as **fixed and validated** by Senua AI's set with this patch, which moves
  from `patches/in_design/` to `patches/`.
- A rule that fails is recorded as measured, with its numbers, and the issue stays open.
- Not decided: issue 1's open part (a body that cannot turn, with condim 4 or 6, still creeps: run 084); rolling
  friction's effect on a rolling body, which no rig here plays; the PGS solver; anything against a real robot.

## Known risks, stated before the run

- **Q1** reads MuJoCo's own box, which rocked in every play of the release from run 049 to run 084. The fresh boxes may or may not
  rock released, and are reported.
- **R1**: a fresh box at a fresh step might still be sliding after 13 s. The fastest of them, 2.58 m/s, stops in about
  0.3 s at a friction of 1.
- **M1**: in run 084, with the five switches, `DiscreteImplicitRowNoslip` passed as released, since its box rests, and
  only `ZeroToleranceDisablesTermination` changed.

## What is not asked

Everything listed as not decided above.

## Dry run

`DRY=1` played the four arms on throwaway numbers (MuJoCo's own box written three times, at 16 ms) on run 084's build of
the same five patch files, with no build and no MuJoCo suite, to the end: 60 measured lines, none empty
([`validation/run_085_study_19/dry/`](../validation/run_085_study_19/dry/)). Every box rocked released and under set4,
and rested under set5.

The rules were then judged on its lines in a scratch copy
([`dry/rules_plumbing.sh`](../validation/run_085_study_19/dry/rules_plumbing.sh)). Run 064's release and run 084's suite
results stood in for the three suites. One test was changed by hand in the five-switch suite, and one box's fastest
speed by hand to 50 um/s. All 9 rule lines were judged, and M1 and R1 failed as they should
([`dry/rules_plumbing.txt`](../validation/run_085_study_19/dry/rules_plumbing.txt)). No rule is read from the dry run.
