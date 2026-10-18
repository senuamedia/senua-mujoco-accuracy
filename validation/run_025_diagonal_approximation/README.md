# Run 025: the solver's diagonal approximation, one arm written three ways

15 October 2026. Not registered: a design probe on Google DeepMind's Linux release of MuJoCo 3.16.0, played on the
cloud machine by [`probe.sh`](probe.sh), pushed before any play. It finds where to look and decides nothing.

MuJoCo sets how soft each contact is from an approximation of the constraint's inverse inertia (`mj_diagApprox`,
`engine_core_constraint.c`). For a contact it takes each body's average inverse weight, `body_invweight0`, which
`mj_setConst` computes once, in the pose the scene is written in (`qpos0`, `engine_setconst.c`), not in the pose the
bodies are in. MuJoCo's documentation says this approximation, frozen at `qpos0`, can cause divergence, penetration
or slip (known issue M12). Physics has an answer that does not depend on how a scene is written: the same arm, in the
same place, at rest, does the same thing whatever pose its file was written in.

## The scene

A new rig, [`tools/mjc_arm.c`](../../tools/mjc_arm.c): a two-link arm (links of 0.3 m, 1 kg and 0.5 kg) on two hinges,
with a ball of 0.03 m and 0.2 kg at its tip, the only part that touches the ground (friction 0.8). The same arm, in the
same place and at rest, is written three ways: **native**, in the pose it starts in; **straight**, both joints at 0,
the arm level; **folded**, the elbow at 2.5 rad. The rig writes the ball's height, speeds and contact forces in the
contact rigs' format, and, as context in its STATS line, MuJoCo's frozen inverse weight of the last link beside the
same quantity by MuJoCo's own formula in the pose the arm starts in.

Two starting poses (A: shoulder 0.5, elbow 1.2 rad; B: 1.1 and -0.6), two scenes (rest: the ball set down on the
ground, 2 s; drop: the ball 10 mm above it, 1 s), two steps (2 ms and 0.5 ms), and three configurations: MuJoCo's
**defaults**; **converged**, tolerance 1e-10 and 1,000 iterations; and **recommended**, the elliptic cone with 10 noslip
iterations (Study 2). Every play is read by Senua AI's measure: `rest` (the ground's mean force on the ball), `creep`
(the ball's mean speed along x over the second half), `bounce`, `pull`, and between two writings `ends` (how far
apart they end) and `gap`. All readings are in [`reading.txt`](reading.txt).

## The readings

**The same arm sinks and creeps by different amounts depending only on how its file was written.** MuJoCo's defaults,
the rest scene, the same at both steps:

| Pose | Writing | Frozen inverse weight of the last link | Ground's force on the ball, mN | The ball creeps at, um/s | Ends apart from native, um |
|---|---|---|---|---|---|
| A | native | 0.665 | 11,301 | 852 | |
| A | straight | 0.401 | 11,306 | 519 | 65 |
| A | folded | 0.552 | 11,303 | 711 | 27 |
| B | native | 0.540 | 4,136 | 503 | |
| B | straight | 0.401 | 4,134 | 376 to 377 | 13 |
| B | folded | 0.552 | 4,137 | 513 to 514 | 1.2 |

- **The load is the same; the contact's softness is not.** The ground carries the same force in every writing,
  within 5 mN of 11,301, but the ball rests at a different depth (65 um apart between native and straight in pose A;
  read from the files' last lines, 169 um into the ground native, 105 um straight) and creeps at a different speed.
- **The creep is in proportion to the frozen inverse weight**, within 1% in both poses (852, 519 and 711 um/s against
  0.665, 0.401 and 0.552), as MuJoCo's formula makes a contact's regularisation proportional to its diagonal
  approximation. Neither the step nor the writing changes the force; only the written pose changes the softness.
- **A tighter solve changes nothing.** With tolerance 1e-10 and 1,000 iterations every reading is the same as under the
  defaults, and 22 of the 24 plays are byte-identical. The solver had already converged (1 to 3 iterations a step, never
  at the limit, no warning): the dependence is in the problem MuJoCo sets the solver, not in how far it solves it.
- **The drop** (pose B) rebounds 590, 610 and 588 parts of 10,000 of the drop at 2 ms and 583, 556 and 581 at 0.5 ms,
  native, straight and folded: up to 27 parts apart with the writing. In pose A the arm does not rebound in any writing.
- **The recommended configuration** removes the creep in pose A (0 in every writing) but not the depth: there the ball
  ends 107 um apart between native and straight, more than under the defaults. In pose B the ball still creeps with
  noslip, at 309, 231 and 314 um/s, again in proportion to the frozen weight within 1.3%, though its friction is 0.13 of
  the normal force, far inside the cone. Study 2's holds were a cube; on this arm noslip does not hold pose B.

No play reached the iteration limit or raised a warning, so this probe saw the penetration and the slip MuJoCo's
documentation names, and no divergence.

## What it shows, and what it does not

A contact's softness in MuJoCo depends on the pose the scene was written in, through the inverse weights frozen at
`qpos0`, and with it how deep a resting body sinks, how fast a held one creeps, and how high one rebounds. The same
physical state gives a different motion when only the file is written differently. This is a probe on one arm in two
poses: it does not say how large the effect is for other bodies or chains, and it decides nothing. It is finding F10
and known issue M12's measurement. A registered study, and a correction grounded in MuJoCo's own formula (the same
inverse weight, taken in the pose the bodies are in), are the next steps.
