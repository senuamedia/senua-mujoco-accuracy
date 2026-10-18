# Run 016: the lift of a sliding cube, against its law

15 October 2026. Not registered: a design probe on Google DeepMind's Linux release of MuJoCo 3.16.0, played on the
cloud machine in 30 seconds by [`probe.sh`](probe.sh). It finds where to look and decides nothing.

Run 008 found that a cube set sliding on the ground leaves it while it slides: 10.8 mm off the ground at a 10 ms step,
rising at close to friction times speed (finding F3, known issue M5). Convex contact solvers relax the friction cone,
and the relaxation lets a sliding contact separate at friction times the sliding speed (Anitescu 2006; Le Lidec et
al. 2024, [arXiv 2304.06372](https://arxiv.org/abs/2304.06372)). This probe holds MuJoCo to that law. The law's
numbers are printed beside each reading, from the play's own settings: friction times speed, `mu v`, and friction
times speed times the step, `dt mu v`, the distance M5 records the contact acting at.

Each play is run 008's slide that ends: a 1 kg cube, half-size 0.05 m, that cannot turn, set down touching the ground
and set sliding. The probe plays:

- **The grid.** Friction 0.1, 0.2, 0.4 and 0.8, starting speed 0.3, 0.6, 1.2 and 2.4 m/s, and steps of 10 ms,
  2.5 ms and 0.625 ms. Each is played under MuJoCo's defaults and under the elliptic cone with noslip 10.
- **A control.** The same slide with no friction at all (`condim=1`, new to the rig: given to both geoms, and only
  when set).
- **MuJoCo's `impratio`.** This option sets how hard friction is relative to the normal force. Played at 1 (its
  default), 10 and 100, under both cones.

Each play is read by Senua AI's measure: `sx_contact hover` and `stop` (`reading.txt`). `hover` reads, while the cube
slides, the highest its lowest face rises above the ground, the fastest it moves up, and the deepest it sinks. The
plays and the rig's statistics are under `runs/`. The solver never reached its iteration limit and raised no warning.

**The rig is unchanged when `condim` is not given** (`identity.txt`): run 008's slide at 10 ms, made again with it,
is byte-identical to `suites/2/defaults/stop_1.txt`.

## What it shows

**Friction makes the lift.** With no friction the cube never rises above the ground, at any step, under either cone.
The only upward speed is its return from the first step's sink: 28 mm/s at 10 ms, 1.9 mm/s at 2.5 ms, 0 at 0.625 ms.
With friction, every play of the grid rises.

**At a 10 ms step the cube is thrown up, near friction times speed.** The fastest upward speed is 0.38 to 2.0 times
`mu v` over the grid. At a fixed friction it doubles with the speed: at friction 0.4, 216, 433 and 866 mm/s at
0.6, 1.2 and 2.4 m/s. It grows less than in proportion to friction: 154, 300, 433 and 546 mm/s at friction 0.1 to
0.8 and 1.2 m/s. For every start at 0.6 m/s or more, the highest point is within 17% of the height a body thrown up
at that speed reaches under gravity: 10,848 um against 9,546 um at friction 0.4 and 1.2 m/s, and 72,581 um against
67,710 um at friction 0.8 and 2.4 m/s. The cube hops.

**At finer steps the lift falls with the step, to the order of `dt mu v`.**

| Defaults, friction 0.4, 1.2 m/s | 10 ms | 2.5 ms | 0.625 ms |
|---|---|---|---|
| Highest above the ground | 10,848 um | 822 um | 196 um |
| `dt mu v` | 4,800 um | 1,200 um | 300 um |
| Fastest upward | 433 mm/s | 115 mm/s | 61 mm/s |

Over the grid, the highest point divided by `dt mu v` is 0.05 to 1.90 at 2.5 ms and 0.03 to 1.38 at 0.625 ms,
under the defaults; 0.06 to 2.11 and 0.07 to 1.28 under the elliptic cone with noslip. The fastest upward speed is
0.11 to 0.59 times `mu v` at 2.5 ms and 0.04 to 0.31 at 0.625 ms. So `dt mu v` sets the scale of the lift at fine
steps, between 0.03 and 2.1 times it. It is not a law the lift follows to the micrometre.

**Neither the elliptic cone with noslip nor `impratio` removes it.** MuJoCo's contact reference and impedance (`solref`, `solimp`) were not tried.
- **The elliptic cone with noslip**, which holds a cube at rest (Study 2), lifts it as much. At 10 ms it reaches
  0.10 to 4.26 times `dt mu v`, against 0.10 to 4.34 under the defaults.
- **`impratio` 10 or 100** changes it by about 1% at 10 ms (10,967 and 10,979 um against 10,848). At the finer steps it
  moves the highest point by 52% down to 17% up, depending on the cone and the step. `impratio` 1 plays byte for byte as
  the same configuration without it, as it should: it is MuJoCo's default.

**A smaller step is the only setting here that shrinks the lift a great deal**: 55 times from 10 ms to 0.625 ms at
friction 0.4 and 1.2 m/s. It still leaves 196 um at 0.625 ms.

## What it means for the finding

F3 stands, now with its law. The lift comes from friction; neither the elliptic cone with noslip nor `impratio` removes it. Its size follows
friction times speed at the largest step and friction times speed times the step at the finer ones, which is the
scale the cone relaxation in the cited work predicts. This probe shows the scale and that friction makes the lift.
It does not show that the relaxation is the only cause. A correction would have to change how MuJoCo's solver treats a
sliding contact; none is designed yet.
