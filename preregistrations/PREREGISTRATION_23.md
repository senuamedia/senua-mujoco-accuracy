# Twenty-third pre-registration: impratio and the stiffest contact, with noslip and without it

Registered 17 October 2026, after the probes of runs 101 to 105. Registered before any play of this registration
existed. To be played once, as run 106. Every reading is made by Senua AI's measure as in Study 22.

## The questions

Noslip holds friction exactly, and three issues remain with it in Senua AI's set:

- **Issue 1's last case**: a free cube pushed square to a face at 0.95 of its friction limit rocks on its front edge and
  creeps (Study 20's H1 failure, 173 to 1,124 um/s).
- **Issue 9**: a stack sinks at every contact (a stack of ten 901 um at its deepest), an offset stack leans (up to 8.1
  mrad) and, under noslip, keeps turning.
- **Issue 14, noslip's costs**: inverse dynamics cannot agree with hard friction (MuJoCo's documented limit: up to
  43,138 N in run 105), and the many-contact cost above.

The probes found two configurations of MuJoCo's own options that answer them without changing MuJoCo's code. Run 103:
impratio, the ratio of the friction's impedance to the normal's under the elliptic cone, at 1,000 holds every contact
without noslip. Run 102: a contact's depth falls with the square of its time constant (solref), and at twice the step,
the stiffest MuJoCo's own guard allows, a stack of ten sinks 35 times less and offset stacks come to rest. Runs 104 and
105: with noslip, the two together hold every play; without noslip, and with every joint's friction made as stiff by
its own reference, inverse dynamics agrees to 1e-11 N, but friction is soft: a load it holds makes it creep at (1 - I)
dt a (I its impedance, 0.9999; dt the step; a the load over the mass), which run 105 measured to 0.01 per cent at 17
and 43 kN. On fresh numbers, in Senua AI's set: does each configuration hold the free cube, keep stacks from sinking
past 100 um, leaning past 1 mrad or turning, keep everything the set holds, and, without noslip, agree with inverse
dynamics, creep by that law and keep the joint equality?

## Engines and arms

- **The build**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with Senua AI's six validated patch
  files applied in this order: [`invweight_at_pose_v3.diff`](../patches/invweight_at_pose_v3.diff),
  [`desaxce_elliptic_v4.diff`](../patches/desaxce_elliptic_v4.diff), [`qcqp_reduced_v2.diff`](../patches/qcqp_reduced_v2.diff),
  [`boxbox_collinear.diff`](../patches/boxbox_collinear.diff),
  [`noslip_roll_kept_after_qcqp.diff`](../patches/noslip_roll_kept_after_qcqp.diff),
  [`noslip_equality.diff`](../patches/noslip_equality.diff); with gcc, CMake and Ninja, a Release build, rebuilt by the
  runner from the patch files, every switch set. No code changes in this study, so MuJoCo's own suite is not run.
- The three arms, every option MuJoCo's own:
  - **set**: the configuration as validated, the elliptic cone with 100 noslip iterations;
  - **hold**: and impratio 1,000, and every geom's solref at twice the step with damping ratio 1;
  - **inverse**: the elliptic cone, impratio 1,000, every geom's solref and every joint's solreffriction at twice the
    step with damping ratio 1, every joint's solimpfriction 0.9999 (MuJoCo's largest), and no noslip.

Every arm makes every play. The set's own plays are made again in set with the five rigs as Study 22 played them
([`before/`](../validation/run_106_study_23/before/)). Played on the first cloud machine (AWS EC2 c7i.xlarge, Intel, 4
virtual CPUs, 8 GB).

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_106_study_23/play.sh`](../validation/run_106_study_23/play.sh) | 6c9fc8dc1d9f18d2... |
| Rigs | `tools/mjc_scene.c`, `tools/mjc_arm.c`, `tools/mjc_contact.c`, `tools/mjc_grip.c`, `tools/mjc_stack.c`, `tools/build_rig.sh` | 07c71aabcaba5900..., 95d62875a35e6f1a..., ede2c01e51f69b6f..., ec91813ce6466ba8..., 3b378e25435dfd98..., b6a93676e6aee763... |
| The rigs as Study 22 played them | `before/`: the same five | 90368f280c6e948e..., d52885fb08c646ff..., ee2cbecb4023de01..., a57125297b421248..., d147f7f6d84775ae... |
| Scenes | MuJoCo's box ([`run_049`'s scene](../validation/run_049_desaxce_v4/step2/scene.xml)) and Study 19's six ([`run_085`'s scenes](../validation/run_085_study_19/scenes/)); group 14's written by the runner from the draw | b10dbf28fc9e6c37...; the six: 45344c18b49b1674... together, in name order |
| Senua AI's measure | `sx_contact`: `final`, `gap`, `creep`, `fastest`, `stop` and `rule` | source b1047b84134afc4f... (built for Linux: 1e58d74b416b3c98...) |
| The patches | the six above | d3fd45cc3d3ecfb0..., 00cb8f8eb4a07535..., 37cde954b88306bb..., dcb3bfcef68fbb1c..., 1e0ecc589760e23e..., ad0baec31bb13bc4... |

Since Study 22 the rigs gained `gsolref` (all five, run 102), and `jsolref`, `jsolimp` and `fwdinv` (the arm and scene
rigs, run 105), each set after the scene is loaded as a model's own attribute sets it; unset, they make the same bytes
as before, which rule E1 checks.

## The numbers, and how they were drawn

By Study 10's procedure, from x(0) = 23. A value the record already used for a quantity of the same kind was drawn
again: Study 22's lists, Study 20's friction list, the values Study 22 drew, the settings of runs 099 to 105, and any
value this draw had already given that kind; two were (a half-size of 0.0455 and one of 0.0509 m).
`DRAW=1 bash validation/run_106_study_23/play.sh` prints the draw.

| Group | The numbers |
|---|---|
| 1 | Step 1.729 ms and a quarter of it. Cube a: 1.369 kg, half-size 0.0387 m, friction 0.567. Cube b: 1.059 kg, 0.0382 m, 0.873 |
| 9 | Step 0.741 ms and a quarter of it. The cube 0.677 kg, half-size 0.054 m, friction 0.646. Offsets of 0.057, 0.123 and 0.395 of the half-size a cube |
| 14 | Step 1.819 ms. Held bodies: 131.88 kg with its joint's friction 1.975 times its weight; 48.302 kg, 1.5; 497.338 kg, 2.821. After #2430's second model: joint friction 58,361 N pushed by 0.558 of it; 88,578 N, 0.392. Loads: the friction 2.355 and 2.42 times the falling body's weight. The arm's joint friction 4.315 N m |
| The slides | Step 0.619 ms and a quarter of it. The cube 1.646 kg, half-size 0.0258 m, friction 0.522, set sliding at 0.537 m/s |

The ranges: group 1, a step of 0.5 to 2 ms, cubes of 0.3 to 2 kg, half-sizes of 25 to 60 mm, frictions of 0.3 to 0.9;
group 9, a step of 0.5 to 1.5 ms, the same cube ranges but half-sizes of 30 to 60 mm, offsets of 0.02 to 0.06, 0.1 to
0.15 and 0.3 to 0.4 of the half-size (so the cubes above always stand over the one below); group 14, Study 22's; the
slides, group 1's ranges and a speed of 0.5 to 1.5 m/s. Not drawn: the arms and poses (their studies'), and the plays
of the set kept for the comparisons (their studies' own).

## The plays

Each arm, under its configuration:

- **Group 1**: each cube free (a free joint), condim 3, 4 and 6, pushed from 0.4 s along 0 and 45 degrees at 0.5, 0.75
  and 0.95 of its friction limit, 1.6 s, at the step and a quarter of it, with MuJoCo's fwdinv flag (72 plays).
- **Group 9**: stacks of three cubes, each offset by the drawn fraction of the half-size from the one below, 6 s; and
  straight stacks of 3, 5 and 10, 2 s; at the step and a quarter of it (12 plays).
- **Group 14**: Study 22's scenes on this draw, 1 s at their step under the implicit integrator: three bodies held by
  their joint's friction, each coupled by a joint equality to another; two after #2430's second model; two loads; with
  fwdinv on the held body's play (14 plays). Study 22's arm in its two poses held by joint friction with a weld or a
  connect at its tip, 2 s at 1.71 ms, and Study 15's arm held in the air by joint friction (5.15 N m) at 1.71 and 0.4275
  ms, with fwdinv (8 plays).
- **The set's own plays**: Study 21's arms of Studies 10, 13, 14 and 15 set down and dropped (48), Study 15's grip
  (8), MuJoCo's box and Study 19's six at their own steps (7), the cube Study 19 held at 0.5 and 0.95 of its limit at
  1.71 and 0.4275 ms (4), and the slides: the cube set sliding along 0, 22.5 and 45 degrees, at the step and a quarter
  of it, under MuJoCo's default integrator (6).

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. A creep is `creep`'s mean speed over
the second half; a stacked cube's depth is `final`'s last height of its lowest face against the face below, its lean
and its turn `final`'s last angle and turning speed on its tilt file; a body's travel is `final`'s last displacement
along its joint and a coupling's gap `gap`'s largest difference between the two bodies; a box at rest is `fastest`
over its last 160 steps; a slide's distance is `stop`'s; inverse dynamics' difference is the rig's largest
`most_fwdinv_constraint` over the play (MuJoCo's own mj_compareFwdInv), in whole nanonewtons. Soft friction's law
predicts the held body's travel over 1 s: (1 - 0.9999) dt a, a = g for a held body, the push over 1 kg after #2430.
Coulomb's distance under MuJoCo's default integrator (semi-implicit Euler) is v^2 / (2 mu g) less half a step's
travel, v dt / 2, within a dt^2 / 8 (0.24 um here).

| Rule | Statement | From |
|---|---|---|
| E1 the rigs as before | set's own plays, every play file the rigs make now byte-identical to those Study 22's rigs make | Studies 5 to 22 |
| P0 every play measured | In every arm, all 339 readings are numbers | Study 22 |
| G1 Q1 the issue, fresh | set: some cube pushed along 0 at 0.95 of its limit creeps at least 10 um/s, the largest of the 12 plays | Study 20, run 101 |
| G1 C1, C2 every free cube holds | hold, and inverse: every free-cube play at most 10 um/s (2 lines) | Studies 2 and 15 |
| G9 Q1 the set sinks | set: every contact of each stack of ten at least 100 um deep | runs 026, 102 |
| G9 Q2 the set leans | set: cubes 2 and 3 of the stack offset most lean at least 2 mrad | runs 078, 093 |
| G9 D, L, T | hold, and inverse: every contact of every straight stack at most 100 um deep; every cube of every offset stack leaning at most 1 mrad and turning at most 10 urad/s at the end (6 lines) | runs 102, 104 |
| G14 I1 inverse dynamics agrees | inverse: in every play with fwdinv, at most 1e-3 N | run 105 |
| G14 L1 soft friction's law | inverse: in each held scene and each scene after #2430, the held body's travel within 1 part in 100 of the law (5 lines) | run 105 |
| G14 C1, C2 the equality kept | inverse: in the held scenes, the gap at most 10 um and the held body's travel at most 10 um (2 lines) | Study 22 |
| G14 C3 a load as in the set | inverse: in each load scene, the gap within 1 part in 100 of set's (2 lines) | Study 22 |
| G14 R1 the held arms rest | inverse: each arm held by joint friction, with or without a weld or a connect, at most 10 um/s | Studies 15, 22 |
| G14 N1 nothing without a contact changes | hold against set: every play file of group 14 byte-identical | Studies 12 to 22 |
| G14 V1 | inverse: no step at the iteration limit; no warning (2 lines) | Studies 5 to 22 |
| S R, G, H, B | hold, and inverse: every arm, grip and hold of the set at most 10 um/s; every box at rest, at most 10 um/s (8 lines) | Studies 15, 19, 21, 22 |
| S K the slides | hold, and inverse: each slide within 10 um of Coulomb's distance less half a step's travel (12 lines) | Study 2, run 104 |
| V2 | hold: no step at the iteration limit in the plays without an equality; no warning (2 lines) | Studies 5 to 22 |

There are 49 rule lines. Reported, not ruled: set's and hold's inverse dynamics; the gaps after #2430 under inverse;
set's offset stacks and slides; the solver's iterations.

## The decisions

Each decides with E1 and P0.

- **Group 1**: if Q1 holds and C1 holds, issue 1's last case is fixed and validated by configuration, hold; if C2
  holds, by inverse too. If Q1 fails, the case is not reproduced on these numbers and the group decides nothing.
- **Group 9**: for each arm whose D, L and T lines hold, with Q1 and Q2, issue 9 is fixed and validated by that
  configuration.
- **Group 14**: if I1, L1, C1, C2, C3, R1 and V1 hold, inverse is validated as the configuration for inverse dynamics,
  with soft friction's law as its stated limit; with groups 1 and 9 holding in hold, noslip's many-contact cost is
  fixed and validated by configuration. Inverse dynamics under noslip stays MuJoCo's documented limit.
- **The set's own plays**: an arm keeps them if its S lines hold (and V2, for hold).
- If both arms hold everything, Senua AI's configuration is recorded in two forms: hold, friction exact under any load;
  inverse, inverse dynamics exact and friction soft by the law.
- A rule that fails is recorded as measured, with its numbers, and its issue stays as it is.
- Not decided: a bounce (a contact the model authors with its own solref), issue 18, anything against a real robot.

## Known risks, stated before the run

- **Condim 4 and 6, and Studies 10, 13 and 14's arms**, were not played under hold or inverse in the probes (runs 102
  to 105 used condim 3 and Study 15's arm).
- **G1 Q1**: Study 20 and run 101 found every push along 0 at 0.95 creeping, 173 to 1,124 um/s; in the dry run, the
  heavy cube with friction 0.3 did not creep at all, the reason Q1 reads the largest of the 12 plays.
- **G9 Q2**: run 104's stack offset 0.4 of its half-size leaned 6.7 to 7.0 mrad in set; this cube is larger.
- **G9 D**: depth goes with the square of the step; from run 104 (25.5 um at 1.14 ms), about 11 um is expected here.
- **G14 L1**: the law held to 0.01 per cent in run 105, at 0.957 ms.
- **G14 V1 and V2**: with noslip and an equality, noslip runs to its limit on many steps (Study 22), the reason V2 reads
  only the plays without an equality.

## What is not asked

Everything listed as not decided above.

## Dry run

`DRY=1` played the three arms on throwaway numbers at the edges of the ranges (group 1's cubes 0.3 kg, 25 mm, friction
0.9 and 2 kg, 60 mm, 0.3, at 2 ms; group 9's cube 2 kg, 30 mm, 0.3, offsets of 0.06, 0.15 and 0.4 of its half-size, at
1.5 ms; group 14 at 2 ms, held bodies of 5, 500 and 50 kg at 1.2, 3 and 2.5 times their weight, 100,000 N pushed by 0.9
and 20,000 N by 0.3, loads at 1.2 and 3 times, 8 N m; the slides' cube 0.3 kg, 60 mm, 0.3, at 1.5 m/s and 2 ms) on Study
22's build of the same six patch files, with no build, to the end, in 1 minute 45 s: every arm gave all 339 readings
([`validation/run_106_study_23/dry/`](../validation/run_106_study_23/dry/)). The dry run's per-step play files are not
kept; its measured lines, statistics, parameters and scenes are.

On it, G1 Q1 as first written, every cube pushed along 0 at 0.95 creeping in set, failed: the 0.3 kg cube crept 1,374
to 1,503 um/s, the 2 kg cube with friction 0.3 not at all. Study 20 found the case, not that every cube shows it, so Q1
reads the largest of the 12 plays; nothing else was changed. The rules were then judged on the dry run's lines in a
scratch copy ([`dry/rules_plumbing.sh`](../validation/run_106_study_23/dry/rules_plumbing.sh), the runner's rules
section word for word, run by [`dry/rules_changed.sh`](../validation/run_106_study_23/dry/rules_changed.sh)): all 49
held ([`dry/rules_plumbing_unchanged.txt`](../validation/run_106_study_23/dry/rules_plumbing_unchanged.txt)). By hand,
one value in each rule group was changed so that its rule must fail, and two play files were given one byte more. The
19 lines so changed failed, as they should: E1, P0, G1 Q1 and C1, G9 Q1 and Q2, D for hold, L for inverse, T for
hold, G14 I1, L1 for held body 1, C1, C3 for load 1, R1, N1, V1's iteration limit, S K for hold's slide along 0 at 2
ms, S B for inverse, and V2's warnings. Every other line held, 30 of 49
([`dry/rules_plumbing_changed.txt`](../validation/run_106_study_23/dry/rules_plumbing_changed.txt)). No rule is read
from the dry run.
