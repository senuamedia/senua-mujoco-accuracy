# Twenty-first pre-registration: four groups, each deciding one issue

Registered 17 October 2026, after the probes of runs 086 and 088 to 090 and Study 20. Registered before any play of
this registration existed. To be played once, as run 091. Every reading is made by Senua AI's measure as corrected on
17 October 2026 ([the audit](../docs/audit.md#the-measure-corrected-17-october-2026)).

## The questions

**Group 1, issue 1 (a held object creeps), for a cube held from turning.** Study 20 found the friction solve's second
version, [`qcqp_reduced_v2.diff`](../patches/in_design/qcqp_reduced_v2.diff), holding every cube held from turning with
condim 4 or 6, where released and with the first version they creep. Its H1 failed only on a free cube pushed square
to a face at 0.95 of its limit, a case either version leaves creeping and no fix here addresses. On fresh cubes: with
the second version in Senua AI's set, does every cube held from turning hold, with condim 3, 4 and 6? Is everything
else the set plays exactly as with the first version? The free cubes are played and reported, not ruled.

**Group 7, issue 7 (sliding friction moves with the step).** Run 088 found the slide hopping, released, at every step,
and in Senua AI's set not hopping and decelerating at Coulomb's rate at every step. On fresh slides, started at the
depth they rest at, at a fresh step and a quarter, a sixteenth and a sixty-fourth of it, in Senua AI's validated set
under the configuration: does no slide hop, and does each decelerate and slide as Coulomb's law says?

**Group 8, issue 8 (the contact softens with the step past its stiffness guard).** Run 088 found the depth at rest the
same at every step up to half the contact's time constant, and past it exactly the guard's softer contact. On fresh
time constants and cubes, released, under MuJoCo's defaults: within half the time constant, is the depth the same at
every step? At the time constant, is it deeper?

**Group 10, issue 10 (a bounce depends on the step, and can create energy).** Run 088 found that with the step at
most half the time constant times the damping ratio, the bounce spread at most 446 parts of 10,000 across the steps in
all 9 settings, and never rose above the drop. On fresh time constants, damping ratios, cubes and drops, released,
under MuJoCo's default integrator: does that hold?

## Engines and arms

- **rel**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256 139577c541d43716...).
- **v1**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with Senua AI's five validated patch files
  applied in this order: [`invweight_at_pose_v3.diff`](../patches/invweight_at_pose_v3.diff),
  [`desaxce_elliptic_v4.diff`](../patches/desaxce_elliptic_v4.diff), [`qcqp_reduced.diff`](../patches/qcqp_reduced.diff),
  [`boxbox_collinear.diff`](../patches/boxbox_collinear.diff),
  [`noslip_roll_kept_after_qcqp.diff`](../patches/noslip_roll_kept_after_qcqp.diff).
- **v2**: the same, with `qcqp_reduced_v2.diff` in place of `qcqp_reduced.diff`, its tests built too.
- Both built with gcc, CMake and Ninja, a Release build, rebuilt by the runner from the patch files.
- The four arms: **rel**; **off**, v2 with every switch unset; **v1set** and **v2set**, each with the five switches set.

Every arm makes every play. Groups 1 and 7 play under Senua AI's configuration (the elliptic cone, 100 noslip
iterations); groups 8 and 10 under MuJoCo's defaults with the contact's `solref` given. MuJoCo's own test suite runs on
the release's test build (run 020's) and on v2's, every switch unset and the five set. Played on the first cloud
machine (AWS EC2 c7i.xlarge, Intel, 4 virtual CPUs, 8 GB).

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_091_study_21/play.sh`](../validation/run_091_study_21/play.sh) | fe2e81930a187c2b... |
| Rigs | `tools/mjc_scene.c`, `tools/mjc_arm.c`, `tools/mjc_contact.c`, `tools/mjc_grip.c`, `tools/build_rig.sh` | 90368f280c6e948e..., d52885fb08c646ff..., 1c44fc0478bdc6e5..., a57125297b421248..., b6a93676e6aee763... |
| Scenes | MuJoCo's box ([`run_049`'s scene](../validation/run_049_desaxce_v4/step2/scene.xml)) and Study 19's six ([`run_085`'s scenes](../validation/run_085_study_19/scenes/)) | b10dbf28fc9e6c37...; the six: 45344c18b49b1674... together, in name order |
| Senua AI's measures | `sx_contact` as corrected 17 October 2026: `creep`, `accel`, `stop`, `hover`, `final`, `bounce` and `rule` | source 804d51e14d2ade30... (built for Linux: b1d1b2906041219e...) |
| The patches | the five above and `patches/in_design/qcqp_reduced_v2.diff` | d3fd45cc3d3ecfb0..., 00cb8f8eb4a07535..., 22f07ccf8abf316e..., dcb3bfcef68fbb1c..., 1e0ecc589760e23e..., 37cde954b88306bb... |

## The numbers, and how they were drawn

By Study 10's procedure, from x(0) = 21. A value the record already used for a quantity of the same kind was drawn
again: Study 20's lists, the values it drew and derived, the settings of runs 088 to 090, and any value this draw had
already given that kind. Two were redrawn: speeds of 1.45 m/s and drop heights of 0.0563 m. `DRAW=1 bash
validation/run_091_study_21/play.sh` prints the draw.

| Group | The numbers |
|---|---|
| 1 | Steps 1.791 ms and a quarter of it; cube a 1.881 kg, half-size 0.0377 m, friction 0.663; cube b 0.836 kg, 0.0355 m, 0.777 |
| 7 | Steps 2.411 ms and a quarter, a sixteenth and a sixty-fourth of it; slide 1: 1.987 kg, half-size 0.0446 m, friction 0.255, given 1.67 m/s; slide 2: 1.051 kg, 0.0532 m, 0.357, 1.32 m/s |
| 8 | Setting 1: time constant 19.549 ms, 2.562 kg, half-size 0.0563 m; setting 2: 24.531 ms, 0.977 kg, 0.0234 m |
| 10 | Coarse step 9.131 ms and its halves down to a sixty-fourth; setting 1: time constant 16.946 ms, damping ratio 0.184, 1.495 kg, half-size 0.0423 m, dropped from 0.0761 m; setting 2: 20.116 ms, 0.251, 1.432 kg, 0.0302 m, 0.1109 m; setting 3: 47.65 ms, 0.407, 2.039 kg, 0.0411 m, 0.0812 m |

The ranges were set so each rule asks only what it means to ask. In group 7 each slide lasts at least 0.25 s (1 to 2
m/s, friction 0.2 to 0.4), so the step's own error in the distance stays under 0.6%. In group 10 the first setting's
spring is one the coarse step cannot resolve, and every setting has at least three steps that resolve it (4, 5 and 7
of the 7 steps here). Not drawn: group 1's fractions and directions (Study 15's), and the arms, grip and boxes played
for the comparisons (their studies' own).

## The scenes

Each arm:

- **group 1**: Study 20's plays: each cube held at 0.5, 0.75 and 0.95 of its friction limit along 0, 22.5 and 45
  degrees, with condim 3, 4 and 6, held from turning and free, at both steps (216 plays); the arms of Studies 10, 13,
  14 and 15 set down and dropped (48); Study 15's grip (8); MuJoCo's box and Study 19's six (14);
- **group 7**: each slide set down at each step for 1 s, then started at the depth that play rested at (`final`'s
  height), given its speed, for 1.5 times its stopping time and 0.2 s (16 plays);
- **group 8**: each setting's cube set down from 20 mm, friction 0.5, for 2 s, at a sixteenth, a quarter, a third and a
  half of the time constant, and at the time constant (10 plays);
- **group 10**: each setting's cube, held from turning, dropped, for 1.2 s, at each of the seven steps (21 plays).

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. A creep is `creep`'s mean speed over the
second half; a deceleration is `accel`'s mean over 0.2 to 0.8 of the slide's stopping time; a distance is `stop`'s; a
hop is `hover`'s highest point above the ground while sliding; a depth at rest is `final`'s last height; a bounce is
`bounce`'s rebound in parts of 10,000 of the drop. Coulomb's deceleration is the friction times 9,800 mm/s2, its
distance the speed squared over twice the friction times 9.8.

| Rule | Statement | From |
|---|---|---|
| E1 safe when off | Every play file off makes byte-identical to rel's | Studies 5 to 20 |
| M0 every suite read | Each of the three readings of MuJoCo's suite lists all 3,492 tests | Study 16 |
| E2 safe when off, MuJoCo's suite | Every switch unset: every one of MuJoCo's tests gives the release's result | their R2 |
| M1 MuJoCo's suite, the five switches set | No test changes but `ForwardTest.DiscreteImplicitRowNoslip` and `SolverTest.ZeroToleranceDisablesTermination` | Study 15 |
| P0 every play measured | In every arm, all 341 readings are numbers | Study 20 |
| G1 Q1, Q2 | rel, then v1set: cube a held from turning, condim 4, along 0 degrees, at 0.95 of its limit, at 1.791 ms, creeps at 11 um/s or more (2 lines) | Study 20 |
| G1 H1 every held cube holds | v2set: every hold of a cube held from turning, condim 3, 4 and 6, at most 10 um/s (108 holds) | Studies 2 and 15 |
| G1 N1 nothing else changes | v2set against v1set: every play file byte-identical but the holds of a cube held from turning with condim 4 or 6 | Studies 12 to 20 |
| G1 R1, G1, B1 | v2set: every arm and every grip at most 10 um/s; every box at rest (3 lines) | Studies 15, 19 |
| G1 V1 | v2set: no step at the iteration limit; no warning (2 lines) | Studies 5 to 20 |
| G7 Q1 the release's slide hops | rel: slide 1 at 2.411 ms rises 1 um or more above the ground | run 088 |
| G7 S1 no hop | v1set: no slide rises above the ground, at any step (8 slides) | Study 12 |
| G7 S2 Coulomb's deceleration | v1set: each slide's deceleration within 1 part in 100 of Coulomb's at every step (2 lines) | runs 001, 088 |
| G7 S3 Coulomb's distance | v1set: each slide's distance within 1 part in 100 of Coulomb's at every step (2 lines) | Study 15's C1 |
| G7 V1 | v1set: no step at the iteration limit | Studies 5 to 20 |
| G8 Q1 past the guard, deeper | rel: at the time constant, the depth at rest at least 1.01 times the depth at a sixteenth of it (2 lines) | runs 003, 005, 088 |
| G8 R1 within the guard, the same | rel: at a quarter, a third and a half of the time constant, the depth within 1 part in 10,000 of the depth at a sixteenth (2 lines) | run 088 |
| G10 Q1 the release creates energy | rel: setting 1 at the coarse step rebounds higher than it fell (10,001 or more) | runs 017, 088 |
| G10 P1 | rel: each setting has at least three steps that resolve its spring (the time constant times the damping ratio at least twice the step) (3 lines) | |
| G10 R1 one bounce | rel: for each setting, every two steps that resolve its spring rebound within 500 parts of 10,000 of each other (37 lines) | the first deep dive's T04 |
| G10 R2 never above the drop | rel: no step that resolves its spring rebounds higher than it fell | T04 |

There are 67 rule lines. Reported, not ruled: the free cubes' holds, and which of MuJoCo's tests change.

## The decisions

Each group decides only its own issue, by its own rules with E1 and P0; group 1 also needs M0, E2 and M1.

- **Group 1**: if they hold, the friction solve's second version is validated for a cube held from turning with
  condim 3, 4 and 6, moves to `patches/`, and takes the first version's place in Senua AI's set. Issue 1 stays fixed in
  part: the free cube pushed square to a face near its limit is still open.
- **Group 7**: if they hold, issue 7 is recorded as issue 4, the hop, seen through the deceleration: in Senua AI's set,
  which fixes the hop (Study 12), the slide decelerates and slides as Coulomb's law says at every step. It is counted
  once, with issue 4, and the list counts 20 issues.
- **Group 8**: if they hold, issue 8 is recorded as corrected by configuration: a step at most half the contact's time
  constant, inside MuJoCo's own guard.
- **Group 10**: if they hold, issue 10 is recorded as corrected by configuration: a step at most half the contact's time
  constant times its damping ratio, the spring MuJoCo's own discrete integrator calls resolved.
- A rule that fails is recorded as measured, with its numbers, and its group's issue stays as it is.
- Not decided: issue 9, issue 1's free cube, the PGS solver, anything against a real robot.

## Known risks, stated before the run

- **G10 R1**: in run 088 the spreads came to 446 of the 500 allowed; a fresh setting may spread further, and then issue
  10 stays open.
- **G7 S3**: at 2.411 ms the step's own error in the distance is about 0.2% for slide 1 and 0.3% for slide 2, inside the
  1% registered.
- **G1 Q1, Q2**: cube a weighs 1.881 kg, more than 1 kg, as Study 20's cube a that crept with either version.
- **G8 R1**: 1 part in 10,000 is about 1 nm on these depths; run 088 found them the same to the nanometre.
- **G7 Q1**: run 088's slides hopped, released, at every step.

## What is not asked

Everything listed as not decided above.

## Dry run

`DRY=1` played the four arms on throwaway numbers (run 087's cube as both cubes; run 088's slide, time constants and
drops) on run 087's two builds of the same patch files, with no build and no MuJoCo suite, to the end, in 92 s: every
arm gave all 341 readings ([`validation/run_091_study_21/dry/`](../validation/run_091_study_21/dry/)). Released, the
slides hopped (288 to 357 um); in the set they did not, and decelerated at 3,920 mm/s2, Coulomb's, at all four steps.
The dry run's per-step play files are not kept; its measured lines, statistics and parameters are.

The rules were then judged on its lines in a scratch copy
([`dry/rules_plumbing.sh`](../validation/run_091_study_21/dry/rules_plumbing.sh)), run 064's release and run 087's suite
results standing in for the three suites. By hand, one value in each group was changed so that its rule must fail: a
test in the five-switch suite, one held cube's creep, slide 1's deceleration at the coarse step, setting 1's depth at a
quarter of the time constant, setting 3's rebound at the finest step, and one released arm's reading blanked. M1, P0,
G1 H1, G7 S2 for slide 1, G8 R1 for setting 1, and the four G10 R1 lines that pair the finest step with steps more
than 500 apart from it failed, as they should; every other line held
([`dry/rules_plumbing.txt`](../validation/run_091_study_21/dry/rules_plumbing.txt)). No rule is read from the dry run.
