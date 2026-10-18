# The patches

## Senua AI's set, as validated

What to apply, validated together inside one set (Studies 15, 16, 19, 21, 22 and 23, each later patch and option
played inside the set as it then stood):

- **The configuration**, MuJoCo's own options, in one of two forms ([Study 23](studies/23-impratio-and-the-stiffest-contact.md)):
  - **for friction exact under any load**: the elliptic cone (`cone="elliptic"`) with 100 noslip iterations
    (`noslip_iterations="100"`), impratio 1,000 (`impratio="1000"`), and every contact's time constant at twice the
    step with damping ratio 1 (each geom's `solref="2dt 1"`, dt the step), the stiffest MuJoCo's own guard allows;
    inverse dynamics then cannot agree, MuJoCo's documented limit of hard friction;
  - **for inverse dynamics**: the same without noslip, and every joint's friction as stiff, its `solreffriction="2dt 1"`
    and `solimpfriction="0.9999 0.9999"`; inverse dynamics agrees with the forward step, and friction is soft by a
    measured law, creeping at (1 - 0.9999) dt a for a load a over the mass (F18): under 2 um/s at gravity's load up to
    a 2 ms step.
  
  In both: a step at most half the time constant times its damping ratio where a contact the model authors for a bounce
  matters (that contact keeps its own solref); RK4 where a free body's energy matters; condim 1 for a frictionless
  contact; a shape that is not convex written as convex parts.
- **Six patch files**, applied in this order to MuJoCo at `UPSTREAM_COMMIT`, each off unless its switch is set:
  [`invweight_at_pose_v3.diff`](../patches/invweight_at_pose_v3.diff) (`MUJOCO_INVWEIGHT_AT_POSE=1`),
  [`desaxce_elliptic_v4.diff`](../patches/desaxce_elliptic_v4.diff) (`MUJOCO_DESAXCE=1`),
  [`qcqp_reduced_v2.diff`](../patches/qcqp_reduced_v2.diff) (`MUJOCO_QCQP_REDUCED=1`),
  [`boxbox_collinear.diff`](../patches/boxbox_collinear.diff) (`MUJOCO_BOXBOX_COLLINEAR=1`),
  [`noslip_roll_kept_after_qcqp.diff`](../patches/noslip_roll_kept_after_qcqp.diff) (`MUJOCO_NOSLIP_ROLL_KEPT=1`),
  [`noslip_equality.diff`](../patches/noslip_equality.diff) (`MUJOCO_NOSLIP_EQUALITY=1`).
- **The build**, for the same bytes on arm64 as on Intel: MuJoCo from its source with gcc and MuJoCo's own CMake options,
  or with clang and `-ffp-contract=off`; Google DeepMind's arm64 release, built with clang's default, fuses a multiply
  and an add and departs at the last digit ([Study 24](studies/24-arm64-against-intel.md)).

The slip-aligned pyramid is validated for MuJoCo's default pyramidal cone, which the set does not use. What is left,
measured and stated: friction exact and inverse dynamics exact cannot both be had, so the configuration has a form for
each; without noslip friction creeps by its law ([the issues](issues.md), [the findings](findings.md)).

## How each came about

Seven patches to MuJoCo, several of them in more than one version, each off unless its switch is set. De Saxce's correction
for the elliptic cone, for a sliding body's lift and a free cube's direction, is validated in its fourth version by
Study 12. The slip-aligned pyramid is
validated by Study 1; MuJoCo's own test suite finds four side effects for its next version to answer (run 020); the second
version answers three but fails three checks (run 021); the third answers them but the lift and passes every check and
MuJoCo's whole suite (run 022), and held 29, 29 and 31 of 32 rules in three registered studies, so it stays in design
(Studies 3, 4 and 6). The stiffness guard extended to the damping failed its correctness check and stays in design. The
inverse weight in the current pose, for finding F10, is validated in all three of its versions: for contacts (Study 5),
joint limits and joint friction too (Study 7), and equality constraints too (Study 8). The friction solved in the
directions that can move (Studies 14 and 15, its second version Study 21), noslip leaving the rolling friction as it
was (Study 19), the box-on-box clip without its collinear vertices (Study 16) and noslip keeping a joint equality
(Study 22) are each validated, below.

## Friction without a direction: the slip-aligned pyramid

**Validated** by the first registered study ([Study 1](studies/01-friction-without-a-direction.md), 17 of 17 rules).
The file: [`patches/slip_aligned_pyramid.diff`](../patches/slip_aligned_pyramid.diff) (sha256 eeb0118d675d0435...),
against MuJoCo 3.16.0 at the commit in [`UPSTREAM_COMMIT`](../UPSTREAM_COMMIT). Switch: `MUJOCO_SLIP_ALIGNED_PYRAMID=1`.

### What it corrects

MuJoCo's default friction cone is a pyramid. Its four edges lie along the two tangents of the contact's frame, so
the friction it can give is a diamond, |f1| + |f2| <= mu N, not Coulomb's circle. Along a tangent it reaches mu N;
at 45 degrees to them, only 0.707 of it. A part sliding at an angle to the frame slides too far and leaves its line,
and a part held at an angle is lost below its rated friction ([findings](findings.md), F2).

### What it changes

25 lines in `src/engine/engine_core_constraint.c`, in `mj_instantiateContact`, before the contact's rows are built.
With the switch on, each pyramidal contact that is slipping has its two tangents turned about its normal so that the
first lies along its slip. The slip is the contact's relative velocity at that moment: its Jacobian difference, which
MuJoCo has just computed, times the joint velocities. The pyramid then reaches mu N along the slip, whatever its
direction. A contact that is not slipping keeps the frame collision gave it. Nothing else in MuJoCo changes, and with
the switch unset none of the new lines runs.

### What it was held to

| Check | Result |
|---|---|
| Required | MuJoCo as released slides 30% further along 30 degrees and loses a hold at 0.85 of its limit (Study 1, R2 and R7) |
| Correct | On: the same slide to the micrometre along 0, 15, 30, 60 and 75 degrees at two steps, no drift, within 0.05% of Coulomb's distance; the hold the same along every direction (R3 to R6); a cube free to turn within 0.13% (R8) |
| Nothing else gets worse | On: every play of both contact suites byte-identical to the release, 71 of 71 files (R9); every other reading of the probes unchanged (run 011) |
| Safe when off | The patched MuJoCo with the switch unset plays byte for byte as the release, 109 of 109 files in Study 1 and 146 of 146 in run 011 |
| The solver keeps converging | No step at the iteration limit and no warning; at most 7 iterations on any step, against 6 for the release (R10) |
| MuJoCo's own test suite ([run 020](../validation/run_020_mujoco_test_suite/README.md)) | Switch unset: all 3,492 tests give the release's result, test for test. Switch set: 6 fail. Two pin the contact frame the patch turns; four show side effects (below) |

### What it costs, and what it does not do

One more solver iteration, at most, on the busiest step seen. It does not touch the creep at rest (F1): the elliptic
cone with noslip removes that, and a correction for the default cone is open.

MuJoCo's own test suite, run with the switch set, finds what Study 1's rules did not ask ([run 020](../validation/run_020_mujoco_test_suite/README.md)):

- **The lift.** With the pyramid along the slip, a sliding body lifts as much in every direction as along an axis,
  the release's largest (finding F3): 143 um at 1 ms along every direction of Study 1's slides, against 62 to 91 um
  off axis released. A box spinning on a plane leaves it (`InverseTest.DiscreteInverseFreeBody`).
- **Noise.** The frame turns along any slip over 1e-15 m/s, so on a contact at rest it follows numerical noise. Three
  tests that need two equal computations to agree to the bit, or a settled body to converge, fail (sleeping, folded
  dense blocks, a stiff leg under the discrete integrator). Run 021 bore this out for the first two (they pass under
  the second version, which does not turn along noise); the leg press still fails, and its cause is open.
- **Moving surfaces.** The slip leaves out a surface's own velocity (`surfacevel`), which MuJoCo adds to every
  contact's velocity; no test or play here exercises it.
- **The frame as an output.** The patch turns `mjContact.frame` itself, which contact sensors read, and which then
  depends on velocity at the position stage.

So the patch is validated for what Study 1 registered and safe when off on MuJoCo's own suite, but not ready to merge
as it stands. Its next version must answer these four and pass the suite, then a fresh registered study.

### Using it

```
cd <mujoco source at the pinned commit>
git apply <this repository>/patches/slip_aligned_pyramid.diff
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build && cmake --install build --prefix <folder>
MUJOCO_SLIP_ALIGNED_PYRAMID=1 <your program, linked against <folder>>
```

The switch is read at each step, so a program can turn it on and off between plays.

## In design: the pyramid's third version, and Study 3

[`patches/in_design/slip_aligned_pyramid_v3.diff`](../patches/in_design/slip_aligned_pyramid_v3.diff) (sha256
58a65674e1c61dd9..., the same switch) is the second version (below) with two changes. The pyramid is turned only by
the part of the slip's angle that is not a multiple of 90 degrees, since the square pyramid turned by such a multiple
has the same edges in another order: [run 022](../validation/run_022_pyramid_v3/README.md) traced MuJoCo's stiff
leg-press failure to the second version turning a contact by exactly 180 degrees, which only swapped its rows and
moved MuJoCo's discrete integrator. And the new `mjContact` field is documented in `doc/includes/references.h`. 107
lines added, none removed. In run 022 it passed all five checks: no direction, no drift, the holds the release loses
kept, a moving floor within a step of MuJoCo's own elliptic cone, the frame as released, run 020's three
turned-contact tests passing, and with the switch unset all 3,492 of MuJoCo's tests as released, `doc_test`
included. With it set, the one test that changes is the spinning box, by the lift, which this version does not
correct: a sliding body lifts as much in every direction as along an axis (649 um at 2 ms along 0, 22.5 and 45
degrees, against the release's 649, 496 and 288).

**Study 3** ([run 023](../validation/run_023_study_03/README.md)), on fresh scenes, held 29 of its 32 rule lines and so
does not hold. Everything the patch is for held: no direction, no drift, Coulomb within 0.14%, the holds kept, a
moving floor within 2 steps of MuJoCo's elliptic cone where the release is 51 to 303 away, the frame as released, and
MuJoCo's whole suite as released when off. R1 failed because the runner compared the release's statistics file,
which alone carries the elliptic reference plays (every play file identical); R9 failed by one step at 0.375 ms, where
MuJoCo's two cones differ by 1 to 3 steps along an axis with no direction in play. The third version stays in design.

**Study 4** ([run 024](../validation/run_024_study_04/README.md)) asked the same question on fresh scenes, with the
runner's accounting corrected and R9's bound set to run 023's largest difference between MuJoCo's two cones, 3 steps.
It held 29 of its 32 rule lines and so does not hold either. R1 held: every play file and the statistics file as
released. R9 failed on one line of four, the moving floor 4 steps from MuJoCo's elliptic cone at 0.375 ms, where the
study's own control found MuJoCo's two cones 4 and 5 steps apart with no direction. R11 failed: the free cube within
1.23% and drifting 1,176 um, where the rule allowed 1% and 1,000 um and MuJoCo's own elliptic cone spreads the same
cube by 3.7% and drifts it 917 um (a diagnostic after the study). Everything the patch is for held again. The third
version stays in design; a bound taken from other scenes did not carry, and the reference for no direction is MuJoCo's
elliptic cone on the same scene in the same run.

**Study 6** ([run 031](../validation/run_031_study_06/README.md)) judged R9 and R11 that way, on fresh scenes: the moving
floor no further from the elliptic cone than MuJoCo's own pyramid is along its axis, and the free cube spreading and
drifting no more than under the elliptic cone. It held 31 of 32 rule lines. R11 held with room (a spread of 173 um
against the elliptic cone's 4,070). R9 held on three lines and failed on one, 4 steps from the elliptic cone at 0.3 ms
where MuJoCo's own two cones were 3 apart. Across three studies on fresh scenes everything the version is for has held;
it stays in design.

## Validated: the inverse weight in the current pose

**Validated** by the fifth registered study ([Study 5](studies/05-inverse-weight-current-pose.md), 86 of 86 rule lines).
The file: [`patches/invweight_at_pose.diff`](../patches/invweight_at_pose.diff), the same as the copy under `in_design/`.

[`patches/in_design/invweight_at_pose.diff`](../patches/in_design/invweight_at_pose.diff) (sha256 3f471edca6159277...,
switch `MUJOCO_INVWEIGHT_AT_POSE=1`) is Senua AI's correction for F10. MuJoCo sets each contact's regularisation from its
bodies' inverse weights, which it computes once in the pose a model is written in, so the same arm in the same place
sinks and creeps differently depending only on how its file was written (run 025). The patch takes each contact body's
weight in the pose the body is in, by exactly the formula MuJoCo uses at `qpos0`, and changes nothing else: one
regularisation for a pyramid's four edges, as released, which keeps the symmetric scenes that MuJoCo's own `diagexact`
flag turns (run 028). 45 lines added to `engine_core_constraint.c`, none removed; contacts only.

In [run 029](../validation/run_029_invweight_at_pose/README.md) it held 49 of its 50 check lines: every writing of the arm
ends within 2 nm and 1 um/s of every other, under MuJoCo's defaults and the elliptic cone with noslip, where the
release is 1.2 to 107 um apart; with the switch set every cube scene, both suites and all 3,492 of MuJoCo's tests are as
released; with it unset every play and test is as released; the solver converges. The one failed line is the creep
check's arithmetic: one writing crept at 851 um/s against 852, and the check's 1 part in 1,000 rounds to 0 in the
measure's whole numbers.

**Study 5** ([run 030](../validation/run_030_study_05/README.md)) played it once on an arm and cubes the probes never
used, with every writing started clearly above the ground and the creep bounded at the measure's resolution, both set
before its data: 86 of 86 rule lines held. Released, the same arm ends 2.0 to 97 um apart by writing; with the switch on,
every writing ends in exactly the same place at exactly the same speed, under MuJoCo's defaults and the elliptic cone
with noslip, and creeps alike; every cube scene, both suites and all 3,492 of MuJoCo's tests are as released with it on,
and every play and test with it off.

**What it does not cover.** Joint limits and joint friction take their softness from the joints' own weights, also
frozen at `qpos0`; run 032 found a swing on a joint limit ending up to 1.24 mm apart by writing. The second version,
[`patches/in_design/invweight_at_pose_v2.diff`](../patches/in_design/invweight_at_pose_v2.diff) (sha256
0141e9bc36ff5bfc...), takes those in the current pose too (90 lines added, none removed). In
[run 033](../validation/run_033_invweight_at_pose_v2/README.md) it held all 74 of its check lines: a swing on a joint limit ends
the same in every writing to the nanometre, contacts read exactly as under the first version, and every cube scene and
all of MuJoCo's tests are as released; with the switch unset every play and test is as released. A registered study is
next; run 034 found joint friction affected as well (an arm held by it ending 6 to 32 mm apart by writing).

**Study 7** ([run 035](../validation/run_035_study_07/README.md)) played the second version once on a new arm, on contact,
swinging on a joint limit and held by joint friction, each written three ways: 134 of 134 rule lines held. Released,
the same arm ends up to 89 um apart on contact, 1.9 mm on the limit and 21 mm held by friction, by writing alone; with
the switch on every writing ends to the nanometre in the same place at the same speed and creeps alike, with every cube
scene, both suites and all of MuJoCo's tests as released. **Validated**; the file:
[`patches/invweight_at_pose_v2.diff`](../patches/invweight_at_pose_v2.diff), the same as its copy under `in_design/`.

**The third version**, [`patches/in_design/invweight_at_pose_v3.diff`](../patches/in_design/invweight_at_pose_v3.diff)
(sha256 d3fd45cc3d3ecfb0...), adds `connect` and `weld` equalities, which run 036 found affected too (a held ball sagging
209 to 310 um by writing): 104 lines added, none removed. In
[run 037](../validation/run_037_invweight_at_pose_v3/README.md) it held all 94 of its check lines: the held ball ends the same in
every writing to the nanometre, everything else reads as under the second version, and every cube scene and all of
MuJoCo's tests are as released; with the switch unset every play and test is as released.

**Study 8** ([run 038](../validation/run_038_study_08/README.md)) played it once on a new arm on contact, on a joint limit,
held by joint friction and held by a `connect`: 154 of 154 rule lines held. Released, the arm ends up to 94 um, 113 um,
25.6 mm and 100 um apart by writing in the four; with the switch on every writing ends in the same place to the
nanometre at the same speed and creeps alike, with every cube scene, both suites and all of MuJoCo's tests as released.
**Validated**; the file: [`patches/invweight_at_pose_v3.diff`](../patches/invweight_at_pose_v3.diff), the same as its copy
under `in_design/`. It is the version to use: it does everything the first two do. A `weld` is changed by the same
helper as a `connect`, and [Study 9](studies/09-weld-and-tumbling-body.md) validated it there too, 26 of 26 rule lines: on
a fresh arm held by a weld, released, the writings end 39 and 80 um apart; with the switch set, 0 nm and 0 um/s, with
both suites, the tumbling body and all of MuJoCo's tests as released. [Study 10](studies/10-recommended-configuration-end-to-end.md) validated it under the recommended configuration, with the default integrator and with RK4: on fresh numbers every writing ends 0 nm and 0 um/s from the native in every constraint, and with the switch unset MuJoCo is the release, file for file and test for test.

## Validated: de Saxce's correction for the elliptic cone

**Validated** by the twelfth registered study ([Study 12](studies/12-desaxce-elliptic.md), 43 of 43 rule lines). The
file: [`patches/desaxce_elliptic_v4.diff`](../patches/desaxce_elliptic_v4.diff) (sha256 00cb8f8eb4a07535...), the same
as its copy under `in_design/`, against MuJoCo 3.16.0 at the commit in [`UPSTREAM_COMMIT`](../UPSTREAM_COMMIT). Switch:
`MUJOCO_DESAXCE=1`.

### What it corrects

MuJoCo's elliptic cone solves a convex relaxation of Coulomb friction. Under it a sliding contact keeps pushing while it
separates, at about friction times its slip ([Anitescu 2006](references.md#anitescu)): a sliding body hops off the surface (finding F3, issue 4;
run 016's cube rises 10.6 mm at a 10 ms step) and a cube free to turn lands on its corners, whose friction turns it
away from its line, so it slides a different distance along each direction, drifts and turns (F12, issue 5; run 045).
No MuJoCo setting removes either (run 045).

### What it changes

103 lines added to `src/engine/engine_forward.c`, none removed. [De Saxce and Feng (1991)](references.md#desaxce-1991): exact Coulomb friction is the
same cone condition in a velocity shifted along the normal by friction times the slip. With the switch set, after
MuJoCo's own solve, each elliptic contact's normal reference is lowered by friction times its slip, the part of its
tangential residual that the soft friction's own regularisation does not account for (zero for a contact that sticks),
and the step is solved again from that solution, until no shift moves by more than the solver's own tolerance, at most
`opt.iterations` passes (a fixed point, as [Acary, Cadoux, Lemarechal and Malick 2011](references.md#acary-2011)). Islands and the dual solver are
handled as MuJoCo handles them. Nothing is kept between steps; the pyramidal cone and every other constraint are
untouched, and with the switch unset none of the new lines runs.

### How it was found

Four versions, each a probe pushed before its plays. The first ([run 046](../validation/run_046_desaxce/README.md),
`in_design/desaxce_elliptic.diff`, a fixed number of passes) removed the lift and the direction; the second
([run 047](../validation/run_047_desaxce_v2/README.md), `_v2`, passes until a solve finds nothing to improve) changed
seven of MuJoCo's tests; the third ([run 048](../validation/run_048_desaxce_v3/README.md), `_v3`, only sliding contacts
shifted) cycled where a contact sits between sticking and sliding; the fourth
([run 049](../validation/run_049_desaxce_v4/README.md)) takes the slip itself, continuous at stick, and changed two
tests, each traced. [Run 050](../validation/run_050_stacks_box_and_limits/README.md) found it byte for byte the release
under the pyramidal cone and in a bounce.

### What it was held to (Study 12, fresh numbers)

| Check | Result |
|---|---|
| Required | Released, the cube slid kept from turning rises 4,442 um at 10 ms; free to turn it slides 88,051 to 89,432 um by direction, drifts up to 790 um and turns up to 36 mrad, on fewer than four corners on 2,867 steps |
| Correct | On, under the configuration and under the elliptic cone alone: no lift at any step; the same slide along every direction to the micrometre, no drift, no turn, four corners at every step; within 0.1% of Coulomb's distance at the fine step |
| Nothing else gets worse | Every hold and grip file byte for byte as released; the ten known-answer tests as released; the pyramidal cone byte for byte as released; two of MuJoCo's 3,492 tests fail, the two named in advance |
| Safe when off | Every file under three option sets byte for byte the release's, and all of MuJoCo's tests as released |
| The solver keeps converging | Never at the iteration limit, no warning; at most 16 iterations a step under the configuration (15 released) |

### What it costs, and what it does not do

- **Two of MuJoCo's tests fail with the switch set.** `SolverTest.ZeroToleranceDisablesTermination` pins one solve's
  iteration count, and the fixed point's passes are counted with it. `ForwardTest.DiscreteImplicitRowNoslip` checks a
  scene whose box, released, never comes to rest (finding F13): it passes released because its last step falls on the
  slow step of a six-step cycle, and the switch moves the cycle's phase.
- **A tall stack with noslip.** Under the configuration the switch tipped Study 12's stack of 9 at both steps (up to 6.5
  mrad, still moving at 3.2 to 5.2 mm/s at the end), where released it does not tilt; under the elliptic cone alone every
  stack stands with it. Recorded under finding F14 (issue 21), which stays open; probes since trace the stacks' tilt to
  MuJoCo's box-on-box clip (runs 067 to 072).
- **It acts on the elliptic cone only.** Under MuJoCo's default pyramidal cone a sliding body hops too (run 050), and
  this patch does not change it.
- Not validated here: inverse dynamics (`mj_inverse` does not apply the shift), RK4 and implicitfast (a probe, run 050,
  found the lift and direction gone under both), anything against a real robot.

### Using it

Apply the file to MuJoCo's source at the commit in `UPSTREAM_COMMIT` (`patch -p1`), build as usual, and set
`MUJOCO_DESAXCE=1` in the environment of the process that steps the model, with `cone="elliptic"`.

## Validated: the friction solved in the directions that can move

**Validated** by the fifteenth registered study ([Study 15](studies/15-the-set-together.md), 33 of 33 rule lines), with
the configuration and the other two patches of Senua AI's set. The file:
[`patches/qcqp_reduced.diff`](../patches/qcqp_reduced.diff) (sha256 22f07ccf8abf316e...), the same as its copy under
`in_design/`, against MuJoCo 3.16.0 at the commit in [`UPSTREAM_COMMIT`](../UPSTREAM_COMMIT). Switch:
`MUJOCO_QCQP_REDUCED=1`.

### What it corrects

Under the elliptic cone with noslip, a cube held or gripped holds, but an arm resting on its ball creeps in some poses
(issue 1's last part; Studies 10 and 13, 714 and 191 um/s). Run 062 traced it in MuJoCo's source. Noslip solves an
elliptic contact's friction with `mju_QCQP2` (or `mju_QCQP3`, `mju_QCQP`). That solver scales the contact's block of the
constraint inertia by the friction coefficients, then rejects it as not positive definite by an absolute threshold
(1e-10). When one friction direction cannot move, as across a planar arm, its entry is 1e-10 and the block is rejected
in some poses. The solve returns zero friction, MuJoCo's cost check puts the old friction back, and noslip leaves the
contact as the soft solve left it, creeping.

### What it changes

67 lines added to `src/engine/engine_solver.c`, none removed. A direction whose entry in the block is at most 1e-10 of
the block's largest is dropped: its friction is set to zero, since it does nothing to the motion. The other directions
are solved with MuJoCo's own solvers, in the same ellipsoid. A contact with no such direction is solved as released, so
with the switch set every other play is byte for byte as released (runs 063, 066, 068). With the switch unset none of
the new lines runs.

### What it was held to

| Check | Result |
|---|---|
| Required | Released, every resting play of Study 15's arm creeps, 134 to 482 um/s, and 6 of its 8 dropped plays, up to 688 um/s (Study 15) |
| Correct | With Senua AI's set, every resting and every dropped play at 0, under the default integrator and under RK4, on Study 15's fresh arm (registered), and on the arms of Studies 10, 13 and 14 (runs 066 and 068, probes) |
| Nothing else gets worse | Alone, every other play byte for byte as released and none of MuJoCo's tests changed (Study 14, runs 063, 066); in the set, every hold and grip held, de Saxce's fixes replicated, only the two tests Study 12 named changed (Study 15) |
| Safe when off | Every file under both option sets byte for byte the release's, and all of MuJoCo's tests as released (Studies 14 and 15) |
| The solver keeps converging | Never at the iteration limit, no warning; at most 30 iterations a step in the set (Study 15) |

### What it does not do

- Contacts with torsional or rolling friction (condim 4 and 6) go through the same solves and the patch covers them, but
  no play here uses them. MuJoCo's PGS solver calls the same solve and was not played.
- Not validated: anything against a real robot.

### Using it

Apply the file to MuJoCo's source at the commit in `UPSTREAM_COMMIT` (`patch -p1`), build as usual, and set
`MUJOCO_QCQP_REDUCED=1` in the environment of the process that steps the model, with `cone="elliptic"` and noslip on.

### Its second version, validated by Study 21

[`patches/qcqp_reduced_v2.diff`](../patches/qcqp_reduced_v2.diff), the same switch, changes one condition. Noslip
takes a contact's block without its regularisation and clamps each diagonal entry from below at 1e-10, so a direction
a body cannot move in sits at that floor; the first version dropped a direction at 1e-10 of the block's largest entry,
which keeps the floor when that entry is below 1, and a cube held from turning with condim 4 or 6 still crept. The
second version also drops a direction at the floor. It differs from the first only when the block's largest entry is
below 1. Run 086 found it holding that cube and changing nothing else; Study 20 confirmed it on fresh cubes, its H1
failing only on a free cube that creeps with either version; Study 21's group 1 validated it (9 of 9 rule lines). It
takes the first version's place in Senua AI's set; the first stays as the patch Study 15 validated.

## Validated: noslip leaving the rolling friction as it was

[`patches/noslip_roll_kept_after_qcqp.diff`](../patches/noslip_roll_kept_after_qcqp.diff), 45 lines added to
`engine_solver.c`, none removed, applied after the friction solve, switched on by `MUJOCO_NOSLIP_ROLL_KEPT=1`. For a
contact with torsional and rolling friction (condim 6), noslip keeps the rolling friction as the sweep found it and
solves the sliding and torsional friction in what the elliptic cone has left, through MuJoCo's own solve. Noslip
removes slip, and rolling is not slip. Without it, MuJoCo's own test scene `DiscreteImplicitRowNoslip` never comes to
rest: every contact's rolling torque fills the one ellipsoid all its friction shares, and the box rocks (runs 073, 076).
Validated by Study 19 (9 of 9 rule lines): MuJoCo's box and three fresh ones at rest in all 14 plays, nothing else
changed, of MuJoCo's tests only one of the two Study 12 named.

## Validated: noslip keeping a joint equality

[`patches/noslip_equality.diff`](../patches/noslip_equality.diff), 35 lines added to `engine_solver.c`, 3 removed (two
of them re-added as they were), applied after the five, switched on by `MUJOCO_NOSLIP_EQUALITY=1`. Noslip re-solves the
friction rows only and keeps every other force as the main solver left it. An equality coupling a joint that friction
holds then keeps the force it had while the main solver let that joint creep, and the joint it couples moves and stays
moved, where the held one does not (MuJoCo's issue [#2430](https://github.com/google-deepmind/mujoco/issues/2430), run
094). The patch adds a sweep over the equality rows to each noslip iteration, each solved as MuJoCo's own PGS solves an
equality row, its regularization kept, given the friction the pass sets. With no equality rows nothing changes. Found by
runs 095 and 097 (the sweep before the friction: never worse than noslip as it stands, at any number of iterations).
Validated by Study 22 (group 14 and the common rules, 18 lines held): on fresh scenes the coupling kept where the release
breaks it by 386 um to 1.64 m, the held body held, a loaded equality giving as without noslip, a welded or connected
arm with joint friction at rest, the set's own plays the same bytes, MuJoCo's tests as without it.

**What it costs**: with an equality and joint friction noslip runs to its limit of 100 iterations on many steps (Study
22: 1,423 steps over its equality plays; run 095: up to 497 of 1,170 steps of an arm play). **What it does not do**:
with one noslip iteration it changes nothing (MuJoCo calls one to three "usually sufficient"; it holds from two); it
does not make inverse dynamics agree with noslip, which holding friction exactly rules out (run 094).

## Validated: the box-on-box clip without its collinear vertices

**Validated** by the sixteenth registered study ([Study 16](studies/16-boxbox-collinear.md), 15 of 15 rule lines), in
Senua AI's set and alone. The file: [`patches/boxbox_collinear.diff`](../patches/boxbox_collinear.diff) (sha256
dcb3bfcef68fbb1c...), the same as its copy under `in_design/`, against MuJoCo 3.16.0 at the commit in
[`UPSTREAM_COMMIT`](../UPSTREAM_COMMIT). Switch: `MUJOCO_BOXBOX_COLLINEAR=1`.

### What it corrects

Under the elliptic cone with noslip, a straight stack of equal cubes tilts at some steps and tolerances and stands at
others (issue 21, F14). MuJoCo's box-on-box collision (`mjc_BoxBox`, `engine_collision_box.c`) clips the face of one box
against the side planes of the other's (`clipHalfPlane`). When equal cubes stand straight, the upper face's edges lie on
those planes. A turn or shift of the face makes the clip emit intersections part way along the edges: first by
rounding, the corners 1e-17 m out, then by the drift a kick leaves, 1e-11 m (runs 069, 072). Each such point lies on
the support polygon's edge and adds nothing to it. Yet each is a contact at the corners' depth, so a face's contacts go
from 4 to 6 or 8 and back, and with them the force the face carries.

### What it changes

35 lines added to `src/engine/engine_collision_box.c`, none removed. After the clip, a vertex is dropped when the sine of
the turn of the polygon's boundary at it is below the noise level the separation test already uses for parallel edges
(the sine squared under `mjBOXBOX_PAREPS`). The polygon is kept whole when fewer than 3 vertices would remain. A face
with real corners keeps them; only points on a straight edge go. With the switch unset none of the new lines runs. A
first design, the clip given the separation tests' rounding slack, removed the rounding trigger but not the drift, and
failed at MuJoCo's default tolerance (run 070).

### What it was held to

| Check | Result |
|---|---|
| Required | Released under the configuration, 8 of Study 16's 36 straight stacks tilt, up to 10,919 urad |
| Correct | In Senua AI's set, all 36 stand at three steps and three main tolerances, no face's contacts change, every cube at rest (Study 16); stacks of 3 to 12 at five steps and a stack on a fixed box, the same (run 075); every stack of run 052's grid (run 074) |
| Nothing else gets worse | The arm, holds, a slide on a box's face and grips with box and mesh pads byte for byte as without it, in the set and alone; of MuJoCo's tests, none changes alone, and in the set only the two de Saxce's correction changes |
| Safe when off | Every file under both option sets byte for byte the release's, and all of MuJoCo's tests as released |
| The solver keeps converging | Never at the iteration limit, no warning |

### What it does not do

- Stacks offset by a fraction of a cube still lean under the configuration, as released (issue 9; runs 075, 078): their
  contacts change for another reason.
- Under MuJoCo's defaults no straight stack played tilts, released or patched; there the patch harms nothing and fixes
  nothing played.
- Not validated: boxes of unequal size and plates, RK4, MuJoCo's PGS solver, anything against a real robot.

### Using it

Apply the file to MuJoCo's source at the commit in `UPSTREAM_COMMIT` (`patch -p1`), build as usual, and set
`MUJOCO_BOXBOX_COLLINEAR=1` in the environment of the process that steps the model.

## In design, not validated: the pyramid's second version

[`patches/in_design/slip_aligned_pyramid_v2.diff`](../patches/in_design/slip_aligned_pyramid_v2.diff) (sha256
cfdf5a60a3ca562b..., the same switch) answers run 020: it leaves `mjContact.frame` as released and turns only the
pyramid's rows (the turn kept in a new field, `mjContact.frictionrot`, and undone in `mj_contactForce`); it puts the
surfaces' own velocity in the slip; and it turns a contact only when its slip is at least MuJoCo's own rest speed,
`opt.sleep_tolerance`. 93 lines added, none removed. In [run 021](../validation/run_021_pyramid_v2/README.md) it removed
the direction, kept the holds the release loses, left the frame and its sensors as released, passed the sleeping and
folded-block tests, changed nothing else in this record's plays, and kept the solver converging. It **failed three
checks as written**: the belt check (MuJoCo's own elliptic cone fails it the same way; version 2 stops within a step of
the elliptic cone on the same moving floor), MuJoCo's stiff leg-press test (cause open), and, with the switch unset,
MuJoCo's documentation test (the new field is not in the documentation's copy of the headers). It still raises the
lift to the axis value in every direction (649 um at 2 ms along 0, 22.5 and 45 degrees, against the release's 649,
496 and 288). It is not registered.

## In design, not validated: the stiffness guard extended to the damping

[`patches/in_design/refsafe_dampratio.diff`](../patches/in_design/refsafe_dampratio.diff) (sha256
dfb862408c5d6e42..., switch `MUJOCO_REFSAFE_DAMPRATIO=1`) is Senua AI's candidate for F8. Under Euler, a bouncy
contact creates energy, and MuJoCo's stiffness guard holds only the time constant to two steps, not the spring's own
time constant (time constant times damping ratio). The patch holds that to the same two steps, keeping the damping
ratio: 18 lines added, none removed. In [run 018](../validation/run_018_refsafe_dampratio/README.md) it removed the
energy (no rebound above the drop at any step), left MuJoCo's default untouched, was byte-identical to the release when
off, and kept the solver converging. It **failed the correctness check**: the bounce still spreads 562 to 1,224 parts of
10,000 across the steps, over the 500 the known-answer test T04 allows. It is not registered and stays in design. A
tighter guard would need a factor this record would have to fit, and it does not fit constants.
