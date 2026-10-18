# Twenty-second pre-registration: noslip keeping a joint equality, and a concave shape as convex parts

Registered 17 October 2026, after the probes of runs 092 and 094 to 098. Registered before any play of this
registration existed. To be played once, as run 099. Every reading is made by Senua AI's measure as corrected on 17
October 2026, with `fastest` added the same day.

## The questions

**Group 14, issue 14 (noslip's costs), the joint equality.** Run 094 reproduced MuJoCo's issue
[#2430](https://github.com/google-deepmind/mujoco/issues/2430): with noslip, a joint its friction holds stays still and a
joint coupled to it by an equality moves and stays moved. Noslip re-solves the friction rows only. Runs 095 and 097
found the design [`noslip_equality.diff`](../patches/in_design/noslip_equality.diff), noslip's pass also re-solving the
equality rows as MuJoCo's PGS solves them, keeping the coupling and changing nothing without an equality. On fresh
scenes, in Senua AI's set under the configuration: does the equality hold where the release breaks it, does the held
body stay held, does a loaded equality give as it does without noslip, does an arm held by a weld or a connect with
joint friction rest, and is everything else the set plays exactly as without the patch?

**Group 15, issue 15 (a mesh collides as its convex hull).** Run 092 found a ball dropped into a cup written as one mesh
resting on a lid that is not there, the hull's top, and the same cup as five convex parts, primitives or meshes,
resting on its floor. On fresh cups and balls, released and in Senua AI's set, under MuJoCo's defaults and under the
configuration: does that hold, and do convex meshes rest exactly as primitives?

## Engines and arms

- **rel**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256 139577c541d43716...).
- **The build**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with Senua AI's five validated patch
  files applied in this order: [`invweight_at_pose_v3.diff`](../patches/invweight_at_pose_v3.diff),
  [`desaxce_elliptic_v4.diff`](../patches/desaxce_elliptic_v4.diff), [`qcqp_reduced_v2.diff`](../patches/qcqp_reduced_v2.diff),
  [`boxbox_collinear.diff`](../patches/boxbox_collinear.diff),
  [`noslip_roll_kept_after_qcqp.diff`](../patches/noslip_roll_kept_after_qcqp.diff), then
  [`noslip_equality.diff`](../patches/in_design/noslip_equality.diff); with gcc, CMake and Ninja, a Release build, with
  its tests, rebuilt by the runner from the patch files.
- The four arms: **rel**; **off**, the build with every switch unset; **set5**, the five switches set; **set6**, the six.

Every arm makes every play. MuJoCo's own test suite runs on the release's test build (run 020's) and on the build's,
every switch unset and the six set. Played on the first cloud machine (AWS EC2 c7i.xlarge, Intel, 4 virtual CPUs, 8 GB).

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_099_study_22/play.sh`](../validation/run_099_study_22/play.sh) | 9039b1541da9c688... |
| Rigs | `tools/mjc_scene.c`, `tools/mjc_arm.c`, `tools/mjc_contact.c`, `tools/mjc_grip.c`, `tools/mjc_stack.c`, `tools/build_rig.sh` | 90368f280c6e948e..., d52885fb08c646ff..., ee2cbecb4023de01..., a57125297b421248..., d147f7f6d84775ae..., b6a93676e6aee763... |
| Scenes | MuJoCo's box ([`run_049`'s scene](../validation/run_049_desaxce_v4/step2/scene.xml)) and Study 19's six ([`run_085`'s scenes](../validation/run_085_study_19/scenes/)); group 14's and 15's written by the runner from the draw | b10dbf28fc9e6c37...; the six: 45344c18b49b1674... together, in name order |
| Senua AI's measures | `sx_contact`: `final`, `gap`, `creep`, `fastest` and `rule` | source b1047b84134afc4f... (built for Linux: 1e58d74b416b3c98...) |
| The patches | the six above | d3fd45cc3d3ecfb0..., 00cb8f8eb4a07535..., 37cde954b88306bb..., dcb3bfcef68fbb1c..., 1e0ecc589760e23e..., ad0baec31bb13bc4... |

The contact rig has two settings more than in Study 21 (`fwdinv`, run 094; `tracedir`, run 096); unset, it makes the
same bytes as before. Neither is used here.

## The numbers, and how they were drawn

By Study 10's procedure, from x(0) = 22. A value the record already used for a quantity of the same kind was drawn
again: Study 21's lists, the values it drew and derived, the settings of runs 092 to 098, and any value this draw had
already given that kind; none was. `DRAW=1 bash validation/run_099_study_22/play.sh` prints the draw.

| Group | The numbers |
|---|---|
| 14 | Step 0.957 ms. Held bodies: 58.496 kg with its joint's friction 1.901 times its weight; 294.858 kg, 2.29; 465.417 kg, 1.499. After #2430's second model: joint friction 46,365 N pushed by 0.369 of it; 48,307 N, 0.893. Loads: the friction 1.623 and 2.049 times the falling body's weight. The arm's joint friction 7.218 N m |
| 15 | Step 1.243 ms. Cup 1: outer half-width 0.0478 m, 0.046 m high, walls and floor 0.0059 m, a ball of radius 0.0119 m and 0.431 kg. Cup 2: 0.0788 m, 0.0455 m, 0.0099 m, a ball of 0.0233 m and 0.077 kg |

The ranges: a step of 0.5 to 2 ms; a held body of 5 to 500 kg, its friction 1.2 to 3 times its weight; a joint friction
of 20,000 to 100,000 N pushed by 0.3 to 0.9 of it; a load's friction 1.2 to 3 times the falling body's weight; the
arm's joint friction 3 to 8 N m; a cup 40 to 80 mm in outer half-width and 40 to 100 mm high, walls 3 to 10 mm, a ball
of radius 10 to 25 mm and 0.05 to 0.5 kg, so the ball always falls clear of the walls. Not drawn: the arm and its
poses (Study 15's), and the plays of the set kept for the comparisons (their studies' own).

## The scenes

Each arm, every scene of group 14 played 1 s under the implicit integrator, as #2430's models, with no noslip, noslip 5
and noslip 100 (the configuration), under the elliptic cone:

- **held**: a body on a vertical slide joint with joint friction, falling under its weight, which the friction holds;
  a 1 kg body on a horizontal slide joint without friction, coupled to it by a joint equality (3 scenes);
- **after #2430's second model**: two 1 kg bodies on horizontal slide joints, the first with joint friction pushed by a
  constant force below it (a general actuator, in place of the issue's motor and its control), the second coupled to it
  (2 scenes);
- **load**: a 1 kg body falling on a vertical slide joint, coupled to a 1 kg body on a horizontal slide joint whose
  friction is above the falling body's weight (2 scenes);
- **the arm**: Study 15's arm in its two poses, in the air, joint friction on both hinges, its tip held by a weld or by
  a connect, 2 s at 1.71 ms, under the configuration (4 plays);
- **the set's own plays, with no equality**: Study 21's arms of Studies 10, 13, 14 and 15 set down and dropped (48),
  Study 15's grip (8), MuJoCo's box and Study 19's six (14), the cube Study 19 held at 0.5 and 0.95 of its limit at 1.71
  and 0.4275 ms (4), run 093's stacks offset 1 and 17 mm (2), under the configuration;
- **group 15**: each cup as one mesh (its outer and inner corners, so its hull is the closed box), as five box
  primitives, and as five convex meshes placed as the primitives; a ball dropped from rest 10 mm above the rim over the
  cup's centre, 2 s, under MuJoCo's defaults and under the configuration (12 plays).

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. A body's motion is `final`'s last
displacement along its joint; a coupling's gap is `gap`'s largest difference between the two bodies' motions, in
micrometres; a creep is `creep`'s mean speed over the second half; a box or a cup at rest is `fastest` over its last
160 steps. In a cup the ball's centre comes down by the cup's inner depth and 10 mm when it rests on the floor, and by
10 mm when it rests on the hull's top.

| Rule | Statement | From |
|---|---|---|
| E1 safe when off | Every play file off makes byte-identical to rel's | Studies 5 to 21 |
| M0 every suite read | Each of the three readings of MuJoCo's suite lists all 3,492 tests | Study 16 |
| E2 safe when off, MuJoCo's suite | Every switch unset: every one of MuJoCo's tests gives the release's result | their R2 |
| M1 MuJoCo's suite, the six switches set | No test changes but `ForwardTest.DiscreteImplicitRowNoslip` and `SolverTest.ZeroToleranceDisablesTermination` | Study 21 |
| P0 every play measured | In every arm, all 159 readings are numbers | Study 21 |
| G14 Q1 the release breaks the coupling | rel, noslip 100: in every held scene and every scene after #2430, the gap at least 100 um | run 094 |
| G14 C1 the coupling kept | set6, noslip 100: in those 5 scenes, the gap at most 10 um | runs 095, 097 |
| G14 C2 the held body held | set6, noslip 100: in those 5 scenes, the held body moves at most 10 um | Studies 2 and 15 |
| G14 C3 a load as without noslip | set6: in each load scene, the gap at noslip 100 within 1 part in 100 of the gap with no noslip (2 lines) | run 095 |
| G14 R1 the held arm rests | set6: each arm held by a weld or a connect with joint friction at most 10 um/s | Studies 2 and 15 |
| G14 N1 nothing else changes | set6 against set5: every play file of the set's own plays and of group 15 byte-identical | Studies 12 to 21 |
| G14 R2, G2, B2, H2 | set6: every arm, grip and hold of the set at most 10 um/s; every box at rest, at most 10 um/s (4 lines) | Studies 15, 19, 21 |
| G14 V1 | set6: no step at the iteration limit in the plays without an equality; no warning in any play (2 lines) | Studies 5 to 21 |
| G15 Q1 one mesh rests on its hull | rel: each cup as one mesh, under the defaults and under the configuration, the ball within 1 mm of the hull's top (4 lines) | run 092 |
| G15 C0, C2 convex parts rest on the floor | rel and set6: each cup as primitives, both settings, the ball within 1 mm of the floor (8 lines) | run 092 |
| G15 C1 convex meshes as primitives | rel and set6: each cup as convex meshes, both settings, within 1 um of the primitives (8 lines) | run 092 |
| G15 S1 every cup at rest | rel and set6: every cup play at rest, at most 10 um/s over its last 160 steps | Study 19 |

There are 39 rule lines. Reported, not ruled: which of MuJoCo's tests change; the readings at noslip 5; the solver's
iterations in the plays with an equality.

## The decisions

Each group decides only its own issue, by its own rules with E1 and P0; group 14 also needs M0, E2 and M1.

- **Group 14**: if they hold, `noslip_equality.diff` is validated, moves to `patches/`, and joins Senua AI's set as its
  sixth patch file. Issue 14's equality part is fixed and validated; its inverse dynamics stays recorded as a limit of
  holding friction exactly (run 094), and noslip's multi-contact instability stays open.
- **Group 15**: if they hold, issue 15 is recorded as corrected by configuration: a shape that is not convex written as
  convex parts, primitives or meshes, MuJoCo's documented remedy.
- A rule that fails is recorded as measured, with its numbers, and its group's issue stays as it is.
- Not decided: noslip's multi-contact instability (issue 1's free cube, issue 9's turning stacks), issue 9's depth,
  anything against a real robot.

## Known risks, stated before the run

- **G14 V1 and the cost**: with an equality and joint friction, noslip runs to its limit of 100 iterations on many steps
  (run 095: up to 497 of 1,170 steps of an arm play; the dry run: 1,423 steps over its equality plays). It is the
  patch's cost, reported, and the reason V1 reads only the plays without an equality.
- **G14 Q1**: the release's gap was 386 um at 0.5 and 1 ms for frictions 1.2 to 3 times the weight (run 094, the dry
  run); at 0.957 ms it is expected the same.
- **G14 C1**: at 0.9 of a 100,000 N friction the dry run's coupled body moved 387 nm, the gap 0.
- **G14 C3**: run 095 measured it under the default integrator; the dry run, under the implicit, gave 583 against 582.
- **G15**: the ball rests 0.367 mm into the surface, the soft contact's depth, for 0.05 and 0.5 kg alike in the dry run,
  inside the 1 mm.

## What is not asked

Everything listed as not decided above.

## Dry run

`DRY=1` played the four arms on throwaway numbers at the edges of the ranges (held bodies of 5, 500 and 50 kg at 1.2, 3
and 2.5 times their weight; 100,000 N pushed by 0.9 and 20,000 N by 0.3; loads at 1.2 and 3 times; 8 N m; a step of 0.5
ms; cups at both edges of every range, a step of 3 ms) on run 095's build of the same six patch files, with no build and
no MuJoCo suite, to the end, in 26 s: every arm gave all 159 readings
([`validation/run_099_study_22/dry/`](../validation/run_099_study_22/dry/)). The dry run's per-step play files are not
kept; its measured lines, statistics, parameters and scenes are.

The rules were then judged on its lines in a scratch copy
([`dry/rules_plumbing.sh`](../validation/run_099_study_22/dry/rules_plumbing.sh)), Study 21's release and run 095's
suite results standing in for the three suites. By hand, one value in each rule group was changed so that its rule
must fail, and two play files were given one byte more. The 14 lines so changed failed, as they should: E1, M1, P0, N1,
Q1, C1, C2, C3 for load 1, R1, R2, V1's iteration limit, G15's Q1 for cup 1 under the configuration, its C1 for cup 2 in
set6 under the defaults, and S1. Every other line held, 25 of 39
([`dry/rules_plumbing.txt`](../validation/run_099_study_22/dry/rules_plumbing.txt)). No rule is read from the dry run.
