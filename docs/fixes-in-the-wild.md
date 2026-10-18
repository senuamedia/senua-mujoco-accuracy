# The fixes in the wild, measured

MuJoCo's departures are not secrets. Its maintainers, its users and other engines have answers for several of them:
options in its documentation, a flag, a pull request, a workaround. Senua AI's Measure held each one it could play to
the same known answers as Senua AI's own fix, in the same scenes, and this page sets out what each does well and where
it falls short. **Where Senua AI's fix measures better, the page says so and links the proof; where it does not, the
page says that too.**

## At a glance

| The problem | The fix in the wild | Measured | Senua AI's fix, measured |
|---|---|---|---|
| **A held object creeps** (F1) | A larger `impratio` | Slows the creep, never stops it: a held cube 5 to 20 um/s at `impratio` 100, a grip 74 to 81 ([Study 11](studies/11-fixes-in-the-wild.md)) | **Holds: 0 um/s**, every hold and grip, in three studies ([Study 2](studies/02-recommended-configuration.md), [Study 10](studies/10-recommended-configuration-end-to-end.md), [Study 11](studies/11-fixes-in-the-wild.md)); with `impratio` 1,000 and the stiffest contact as part of Senua AI's configuration, a free cube near its limit too, 0 um/s ([Study 23](studies/23-impratio-and-the-stiffest-contact.md)) |
| | The elliptic cone alone | Removes the direction, not the creep: 471 to 895 um/s (Study 11) | |
| | Noslip under the default cone | Holds only the lightest push; a grip slips at 7.1 mm/s (Study 11) | |
| | **Stiction, pull request #3349** (646 lines, closed unmerged) | **Holds a held object, and its own demos.** But a body moved from outside is pulled back, and a restored state does not replay (Study 11) | **Holds, and a moved body stays put, and a restored state replays byte for byte**, with no new code (Study 11) |
| **Friction has a direction** (F2) | The elliptic cone | No direction in a slide kept from turning; not the default, and a free cube still goes 1.4% to 2.3% further along 22.5 degrees (Study 10) | For scenes on the default cone: **the same slide in every direction played**, 25 lines ([Study 1](studies/01-friction-without-a-direction.md)); under the elliptic cone, de Saxce's correction: **the same slide along every direction to the micrometre**, the free cube too ([Study 12](studies/12-desaxce-elliptic.md)) |
| **The written pose** (F10) | MuJoCo's `diagexact` flag | Removes the written pose (0 nm apart), but turns symmetric scenes and sinks stacks ([run 028](../validation/run_028_diagexact/README.md)) | **0 nm apart in every writing, and every other scene exactly as released**, 104 lines ([Studies 5, 7, 8, 9, 10](patches.md)) |
| | Write the scene in the pose it works in | Right in one pose only: the same arm ends up to 25.6 mm apart by writing ([Study 8](studies/08-inverse-weight-equalities.md)) | |
| **A free body gains energy** (M10) | implicitfast, as the documentation recommends | Stable, but loses energy and angular momentum at about the rate the default gains them ([Study 9](studies/09-weld-and-tumbling-body.md)) | **Fixed by configuration**: MuJoCo's own RK4 for a free or spinning body keeps its energy and angular momentum, a free chain's to 1 ppm ([Study 18](studies/18-rk4-free-body.md), 7 of 7) |
| **A bounce depends on the step** (F8) | Tune the contact per scene | One setting rebounds 0.03 to 0.63 of the drop across the steps ([run 017](../validation/run_017_bounce_setting/README.md)) | **Fixed by configuration**: a step at most half the contact's time constant times its damping ratio, and one setting gives one bounce at every step, within 0.05 of the drop ([Study 21](studies/21-four-groups.md)) |
| **Noslip's costs: a free cube near its limit, offset stacks, inverse dynamics** (F16) | A hardened configuration: the elliptic cone, the Newton solver, a high `impratio`, harder solref and solimp, optional noslip ([Yan et al. 2025](references.md#yan-2025)) | The direction of the answer, with no values given and no inverse dynamics | **Two validated forms of MuJoCo's own options**: with noslip, every hold, grip and stack holds or rests; without it, inverse dynamics agrees to under 1 nN and friction creeps by a measured law ([Study 23](studies/23-impratio-and-the-stiffest-contact.md), 49 of 49) |

## 1. A held object creeps

Coulomb's law: a load inside the friction cone does not move. Under MuJoCo's defaults it does (finding F1, known issue
M1). Every fix below was put to the same rules in [Study 11](studies/11-fixes-in-the-wild.md), registered before any
play and played once on numbers no earlier study used: a 1.381 kg cube held with 0.5, 0.75 and 0.95 of its friction
limit along 0, 22.5 and 45 degrees at two steps; a cube gripped between two pads; and, on the pull request's own
builds, a body moved from outside, a state saved and restored across a shove, and the pull request's own demo scenes.
The right answer for every creep is 0; the bound is 10 um/s.

### "Working as intended"

MuJoCo's documentation says its soft contact does not promise an exact stick, and a documentation change merged in
September 2026 ([pull request #3526](https://github.com/google-deepmind/mujoco/pull/3526)) explains the creep.

- **For:** honest about the behaviour; nothing to change.
- **Against:** the creep stays. Under the defaults the held cube creeps 542 to 2,006 um/s along an axis and a gripped
  cube slips out at 7.0 to 7.7 mm/s (Study 11). A robot trained on a grasp that slips learns that grasps fail, or to
  squeeze harder than a real hand would.

### A larger `impratio`

MuJoCo's option that weights friction more heavily in the solve.

- **For:** one setting; the creep falls in proportion: at half the limit 542, 54 and 5 um/s at `impratio` 1, 10 and
  100; grips 738 to 813 um/s at 10 and 74 to 81 at 100. It keeps the solver's iterations at 4.
- **Against:** it never reaches 0, and at 100 only the half-limit push is inside the bound. Under the default cone it
  leaves the direction: pushed along 45 degrees with 0.75 of the limit the cube slides away at 124 mm/s whatever the
  `impratio`.

### The elliptic cone alone

The Coulomb cone itself; one of MuJoCo's lead developers recommends it ([#1366](https://github.com/google-deepmind/mujoco/issues/1366)).

- **For:** no direction: the same creep along every direction played. The fewest iterations of any arm (2).
- **Against:** the creep stays: 471, 707 and 895 um/s at the three loads; grips 3.5 to 3.8 mm/s. With `impratio` 10,
  47 to 89 um/s and grips 354 to 382.

### Noslip under the default cone

MuJoCo's noslip post-solve, left on MuJoCo's default pyramidal cone.

- **For:** holds a light push: at half the limit, 0 um/s in every direction (Study 11 and run 043).
- **Against:** at 0.6 of the limit ([run 013](../validation/run_013_noslip_with_aligned_pyramid/README.md)), 0.75 and
  0.95 it changes nothing: 1,355 and 2,006 um/s along an axis, as under the defaults; the grips slip at 7.1 to 7.2
  mm/s; the default cone's direction stays. The reason is in MuJoCo's solver: its noslip pass for the pyramidal cone
  moves force only within each pair of opposing pyramid edges (run 013). It took the most iterations (10).

### Stiction: pull request #3349

[Pull request #3349](https://github.com/google-deepmind/mujoco/pull/3349), "Static friction for elliptic contacts",
June 2026, closed without being merged: it stores the relative pose of each pair of touching bodies and adds a spring
against slip from it, for the elliptic cone only, behind a flag. 646 lines added across 20 files, among them nine tests
of its own. Senua AI built it exactly as its author left it, on the June 2026 MuJoCo it was written for.

- **For:**
  - **It holds a held object**: every one of the 18 holds, 0 um/s.
  - **It holds its own demos**: a block on a 30 degree ramp and a box in a passive grip, 0 um/s, where without it they
    slide 47.8 mm and drop 104 mm in 6 s.
  - **It is safe when off**: with its flag unset it plays every file as the MuJoCo it branched from, and MuJoCo's whole
    test suite passes, every test reading the same; its own nine tests pass.
  - It costs no extra solver iterations (4).
- **Against:**
  - **A body moved from outside is pulled back.** Moved 2 mm, as a reset, a teleoperation correction or a domain
    randomiser moves a body, the cube is pulled back toward the pose the pull request stored, at up to 3.1 mm a second,
    then creeps at 29 um/s. A position set from outside does not reach its stored pose.
  - **A restored state does not replay.** Saved before a shove and restored after it, as a planner or a
    reinforcement-learning rollout restores a state, the play strays from the original by up to 120 um before it
    rejoins it. By its own documentation its stored poses are "not part of the serialized state"; by its code, a
    pair still touching at a restore keeps the pose stored at the moment restored from.
  - Elliptic cone only; 646 lines of new state to maintain in every place MuJoCo creates, copies or restores a
    simulation; not merged.

### Senua AI's fix: MuJoCo's own elliptic cone with 10 noslip iterations

- **For:**
  - **Holds every hold and every grip**: 0 um/s along every direction and load, grips 0 to 1, on MuJoCo's release and on
    the pull request's head.
  - **A body moved from outside stays put**: 0 um/s after the move.
  - **A restored state replays byte for byte.**
  - **Holds the pull request's own demos**: 0 um/s on the ramp and in the gripper.
  - **No new code**: two options MuJoCo already ships, chosen and proven by Senua AI's Measure; nothing to store, merge
    or maintain. Validated three times on fresh numbers (Studies 2, 10 and 11).
- **Against:** about twice the solver work: at most 6 iterations a step on the release and 8 on the pull request's
  head, against 3 to 4. A free cube under the elliptic cone alone has a small direction (finding F12, 1.4% to 2.3%),
  which de Saxce's correction removes ([Study 12](studies/12-desaxce-elliptic.md)).

**Measured better:** it is the only fix that held every rule of Study 11 it was put to, 11 of 11. Stiction comes
closest, and fails the two rules that matter for robot learning pipelines.

Since then, Senua AI's configuration gained two more of MuJoCo's own options, `impratio` 1,000 and every contact's
time constant at twice the step: a free cube pushed square to a face at 0.95 of its limit, which crept under noslip at
up to 1,500 um/s, holds at 0, every contact of a stack sinks at most 10.8 um and offset stacks rest ([Study 23](studies/23-impratio-and-the-stiffest-contact.md)).

## 2. Friction has a direction

MuJoCo's default friction cone is a pyramid with its edges on two fixed axes, so the friction it can give is a diamond,
not Coulomb's circle (finding F2): a cube slid at 45 degrees goes 42% further than along an axis.

### The elliptic cone

- **For:** no direction in a slide kept from turning: the same slide along every direction, to the micrometre (Study 2,
  Study 10). It is part of Senua AI's recommended configuration.
- **Against:** it is not the default, so every scene left on MuJoCo's defaults keeps the diamond. A cube free to turn
  still goes 1.4% to 2.3% further along 22.5 degrees than along 0 or 45 (finding F12, Study 10).

### Bullet's velocity-aligned friction direction

Bullet turns its first friction direction along the sliding velocity by default (`btSequentialImpulseConstraintSolver.cpp`).

- **For:** the right idea, proven in another engine.
- **Against:** not available in MuJoCo: it lives in Bullet's sequential solver; MuJoCo builds its pyramid differently
  and solves it with every other constraint at once. Not measured here.

### Senua AI's slip-aligned pyramid

Each slipping contact's pyramid turned along its slip, where MuJoCo builds it: 25 lines, off unless its switch is set
([the patches](patches.md)).

- **For:** the same slide in every direction played, to the micrometre, within 0.05% of Coulomb's distance; the hold the
  same along every direction; MuJoCo unchanged with it off, file for file and test for test (Study 1, 17 of 17).
- **Against:** with it on, MuJoCo's own tests show four side effects (run 020); a third version answers all but the lift and has
  held 29 to 31 of 32 rules in three studies, so it stays in design. It does not touch the creep.

**Measured better** for scenes that stay on the default cone; the elliptic cone remains the simpler answer where it can
be used.

## 3. The written pose

MuJoCo sets each constraint's softness from how heavy the bodies feel, worked out once in the pose the scene file is
written in (finding F10, known issue M12). The same arm, started in the same place, ends up to 25.6 mm apart depending
only on how its file was written (Study 8).

### Write the scene in the pose it works in

- **For:** no code; right in that pose.
- **Against:** a robot moves. The frozen weights are right in one pose and wrong in every other.

### The 3.5.0 weight change

MuJoCo 3.5.0 filled a body's missing translational weight with its rotational one. MuJoCo's maintainers decided to
revert it after it stopped a Rubik's cube's centre pieces turning their neighbours, and one of its lead developers named
the real problem as "the qpos0 approximation of the constraint inertia" ([#3163](https://github.com/google-deepmind/mujoco/issues/3163)).
Not measured here.

### MuJoCo's `diagexact` flag

The exact constraint diagonal in the current pose, added in May 2026. Played in [run 028](../validation/run_028_diagexact/README.md).

- **For:** the written pose no longer matters: every writing of the arm ends in the same place (0 nm in 28 of 32
  comparisons; the other four, 2 to 17 nm, from rounding at the start). One flag, in MuJoCo.
- **Against:** it changes scenes that have nothing to do with the written pose. Under the default cone a straight stack
  of ten tilts 4.6 mrad and is still turning at 2 s, a cube slid to a stop ends tilted, and a grip at a cube's centre
  turns 112 to 118 mrad in 2 s. With the elliptic cone and noslip, stacks sink far deeper (704 um under three cubes
  against 294; 3.5 mm at a contact of ten), and the arm in one pose creeps at 1,152 um/s against 309.

### Senua AI's inverse weight in the current pose

MuJoCo's own formula, evaluated where the bodies are, every step, for contacts, joint limits, joint friction, `connect`
and `weld`: 104 lines, off unless its switch is set ([the patches](patches.md)).

- **For:** every writing ends 0 nm apart; every cube scene, both contact suites and all 3,492 of MuJoCo's own tests play
  exactly as released, with it on and with it off; one regularisation for a pyramid's four edges, as released, so the
  symmetric scenes `diagexact` turns stay still. Validated in five studies (Studies 5, 7, 8, 9 and 10).
- **Against:** 104 lines of change to MuJoCo, not merged.

**Measured better:** it removes the written pose without moving anything else; `diagexact` removes it and moves stacks,
grips and slides.

## 4. A free body gains energy

Under MuJoCo's default integrator a free tumbling body gains energy and angular momentum (known issue M10).

### implicitfast, as MuJoCo's documentation recommends

With gyroscopic stabilisation extended to free bodies ([pull request #3554](https://github.com/google-deepmind/mujoco/pull/3554),
in MuJoCo 3.16.0).

- **For:** stable: a free body does not diverge.
- **Against:** it loses energy and angular momentum at about the rate the default gains them: -1,034 and -413 parts per
  million at 2.5 ms (Study 9). Stable is not the same as right. implicit reads the same on a free body.

### RK4

- **For:** keeps both at every step (Study 9, 8 of 8).
- **Against:** four evaluations a step, and one of the ten known-answer tests, written for a first-order integrator,
  cannot be read under it: free flight under RK4 is exact, so the test's ratio has nothing to divide (Study 10, 9 of
  10).

### Senua AI's position

No patch: no small change to the default integrator is grounded in the theory ([Hairer, Lubich and
Wanner](references.md#hairer-gni)). **Fixed by configuration and validated**: MuJoCo's own RK4 for free and spinning
bodies keeps a free chain's energy and angular momentum to 1 ppm and a tumbling body's exactly at four steps
([Study 18](studies/18-rk4-free-body.md), 7 of 7); the default for contact-rich work.

## 5. A bounce depends on the step

MuJoCo has no restitution setting; users tune the contact's damping per scene, and published work fits contact
settings per system to real tosses ([#3404](https://github.com/google-deepmind/mujoco/issues/3404), [Acosta et
al. 2022](references.md#acosta-2022)).

- **For:** it can match one scene at one step.
- **Against:** the bounce moves with the step: one setting rebounds 0.03 to 0.63 of the drop across the steps, and
  under the default integrator a bouncier one throws the cube 1.2 to 104 times higher than it fell at 10 and 5 ms. MuJoCo's
  discrete integrator removes the energy it creates, not the dependence on the step ([run 017](../validation/run_017_bounce_setting/README.md)).

**Fixed by configuration and validated.** Senua AI's first candidate, MuJoCo's stiffness guard extended to the damping,
removed the energy gain but failed its own check on the step dependence ([run 018](../validation/run_018_refsafe_dampratio/README.md)),
so it is not offered. What holds is a step at most half the contact's time constant times its damping ratio, the spring
MuJoCo's own discrete integrator calls resolved: then one setting gives one bounce, the same at every step to within
0.05 of the drop, never above it ([Study 21](studies/21-four-groups.md)); the restitution is the textbook one
([Stronge 2018](references.md#stronge)).

## Not measured here

Domain randomisation, widening the training over friction, mass and other settings as MuJoCo Playground does ([Zakka
et al. 2025](references.md#playground)), is a training method, not a change to MuJoCo. It cannot remove a departure that does not
depend on what is randomised: the creep happens at every friction, and the written pose depends on how a file is
written.
