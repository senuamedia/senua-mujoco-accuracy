# Run 017: a bounce asked of MuJoCo's soft contact, at every step

15 October 2026. Not registered: a design probe on Google DeepMind's Linux release of MuJoCo 3.16.0, played on the
cloud machine in two steps of a few seconds each. It finds where to look and decides nothing.

Known issue M7: MuJoCo has no coefficient of restitution, and a user who asked for 0.75 got 0.820. A bounce comes from
the contact's reference, `solref`: a time constant and a damping ratio. MuJoCo's default is `0.02 1`, critically
damped, with no bounce (run 008's T04). A damping ratio under 1 lets the contact spring back. The first deep dive's
known-answer test T04 holds that a bounce does not depend on the step, and no body can bounce higher than it fell.

Each play is suite 1's drop: a 2 kg cube, half-size 0.04 m, that cannot turn, dropped from 0.08 m, played for 0.5 s.
It is played at the suite's seven steps (10 ms over 1, 2, 4, 8, 16, 32 and 64), with `solref` `0.02 D` for damping
ratios D of 1, 0.5, 0.2 and 0.1. The time constant, 0.02 s, is at least twice every step, so MuJoCo's stiffness guard
(`refsafe`) leaves it alone. `solref` is new to the rig: given to both geoms, and only when set.

- **Step 1** ([`probe.sh`](probe.sh), `reading.txt`, `runs/`): under MuJoCo's default integrator, Euler.
- **Step 2** ([`probe_discrete.sh`](probe_discrete.sh), `reading_discrete.txt`, `runs_discrete/`): written after
  step 1's readings and pushed before its plays. The same 28 drops under MuJoCo's opt-in `discrete` integrator.
  MuJoCo's documentation (the `refsafe` flag) says this integrator replaces a contact whose spring the step cannot
  resolve, where the time constant times the damping ratio is under the step, with the stiffest one that does not
  bounce, keeping the damping ratio.

Each play is read by Senua AI's measure, `sx_contact bounce`: the highest the cube rises after it turns, in parts of
10,000 of the drop height. The solver never reached its iteration limit and raised no warning.

**The rig is unchanged when `solref` is not given** (`identity.txt`): suite 1's drop at 10 ms, made again, is
byte-identical to `suites/1/defaults/drop_1.txt`. `solref` `0.02 1`, MuJoCo's default given explicitly, plays the
same bytes.

## The readings

The rebound in parts of 10,000 of the drop height (10,000 = as high as it fell):

| Damping ratio | Integrator | 10 ms | 5 ms | 2.5 ms | 1.25 ms | 0.625 ms | 0.3125 ms | 0.156 ms |
|---|---|---|---|---|---|---|---|---|
| 1 (default) | Euler | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 1 (default) | discrete | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 0.5 | Euler | 6,323 | 756 | 340 | 377 | 398 | 451 | 456 |
| 0.5 | discrete | 60 | 287 | 198 | 291 | 349 | 423 | 442 |
| 0.2 | Euler | **199,694 or more** | **11,624** | 2,720 | 2,763 | 2,826 | 3,057 | 3,068 |
| 0.2 | discrete | 682 | 1,366 | 766 | 1,372 | 1,931 | 2,537 | 2,791 |
| 0.1 | Euler | **1,037,671 or more** | **253,449 or more** | 5,230 | 4,771 | 5,005 | 5,433 | 5,441 |
| 0.1 | discrete | 1,005 | 1,741 | 778 | 1,156 | 2,173 | 3,619 | 4,414 |

"Or more": the cube was still rising when the 0.5 s play ended (at 2.6, 20.7 and 3.7 m/s), so the reading is its
height at the end, not its highest.

## What it shows

**Under MuJoCo's default integrator, a bouncy contact creates energy at the larger steps.** With a damping ratio of
0.2 at 5 ms, the cube rebounds 16% higher than it fell. With 0.2 and 0.1 at 10 ms, and 0.1 at 5 ms, it is thrown to 20 to 104
times its drop height or more. Every play that creates energy is one where the time constant times the damping ratio is
under the step (0.004 s and 0.002 s against 10 and 5 ms): the spring the step cannot resolve, in MuJoCo's own words.
The reverse does not hold: at 2.5 ms a ratio of 0.1 is under the step too, and rebounds to 0.52 of its drop. Under Euler,
MuJoCo's guard checks only the time constant against the step, and a damping ratio under 1 makes the spring stiffer by
one over its square.

**MuJoCo's own discrete integrator removes the energy it creates.** No play rebounds above 0.45 of its drop, as its
documentation says.

**Under either integrator, one setting does not give one bounce.** Across the seven steps the rebound of one damping
ratio spreads by:

| Damping ratio | Euler | discrete |
|---|---|---|
| 0.5 | 5,983 (6,323 to 340) | 382 (442 to 60) |
| 0.2 | 196,974 or more | 2,109 |
| 0.1 | 1,032,900 or more | 3,636 |

The first deep dive's T04 allows a spread of 500. Only the damping ratio 0.5 under the discrete integrator is inside
it, besides the default's no bounce. Under Euler the bounce settles at the finer steps: at 0.3125 and 0.156 ms each
ratio agrees to within 1.1%. Under the discrete integrator it is still growing at 0.156 ms with a ratio of 0.1 (3,619 to
4,414). At 0.156 ms the two integrators give different bounces for the same setting: 5,441 against 4,414 with a
ratio of 0.1.

**For a user asking for a coefficient of restitution**, the speed ratio is the square root of the rebound share. A
ratio of 0.1 under Euler gives 0.69 to 0.74 from 2.5 ms down; under the discrete integrator, 0.28 to 0.66. A bounce
tuned at one step is a different bounce at another. M7's user may have met this; their setup is not replicated here.

## What it means for the record

A new finding, F8: a bounce set the way MuJoCo documents depends on the step, and under the default integrator it
creates energy at the larger steps. MuJoCo's own discrete integrator removes the energy. It does not make the bounce
the same at every step. Nothing here is a correction. A setting that keeps one bounce at every step would have to be
designed and then validated in a registered study.
