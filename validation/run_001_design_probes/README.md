# Run 001: design probes on MuJoCo 3.16.0 as shipped

15 October 2026. Not registered: design probes, to find where to look. Played on Google DeepMind's prebuilt release
(`mujoco-3.16.0-macos-universal2.dmg`, sha256 e31ab79c0a5e4280..., the x86-64 slice) with the one-cube rig
[`tools/mjc_contact.c`](../../tools/mjc_contact.c), which writes the first deep dive's format, so Senua AI's measuring
program for SuperDex reads these runs unchanged. MuJoCo's own options are its defaults unless a line says otherwise:
the Euler integrator, the pyramidal friction cone, 100 iterations, tolerance 1e-8, no noslip iterations. Gravity is
9.8 m/s2, as in the first deep dive's suite.

## Probe 01: the one-cube known-answer scenes at four steps

`probe_01.sh`, reading `reading.txt`. A cube of 1 kg, half-size 0.05 m, at MuJoCo's default step of 2 ms and at
1/4, 1/16 and 1/64 of it.

| Scene | 2 ms | 1/4 | 1/16 | 1/64 | Right answer |
|---|---|---|---|---|---|
| Held at 0.6 of the friction limit (0.5): creep, um/s | 1,293 | 1,293 | 1,293 | 1,293 | 0 |
| Set down from 20 mm: force on the ground, mN | 9,800 | 9,800 | 9,800 | 9,800 | 9,800, its weight |
| Dropped 100 mm, no friction: rebound, per 10,000 of the drop | 0 | 0 | 0 | 0 | the same at every step |
| Landing at 2 m/s from 50 mm, friction 0.3: friction over the impact, per 10,000 | 3,000 | 3,000 | 2,999 | 2,999 | 3,000 |
| Given 1 m/s at rest, friction 0.4: distance slid, um | 126,717 | 127,467 | 127,655 | 126,641 | 127,551 |

The same hold played twice is byte-identical: MuJoCo is deterministic on this machine. The solver took at most 4
iterations on any step of any play, and raised no warning.

## Probe 02: the hold, against the push and MuJoCo's own options

`probe_02.sh`, reading `reading_02.txt`. At 2 ms.

| The hold | Creep, um/s |
|---|---|
| Push at 0.2, 0.4, 0.6, 0.8, 0.95 of the limit | 323, 646, 1,293, 2,263, 2,990 |
| Mass 0.2 kg and 5 kg, at 0.6 | 1,293 and 1,293 |
| The implicit and implicitfast integrators | 1,293 and 1,293 |
| The noslip solver, 10 and 100 iterations | 1,293 and 1,293 |
| The elliptic friction cone | 766 |
| `impratio` 10 | 129 |
| The elliptic cone with `impratio` 10 | 77 |
| The elliptic cone with the noslip solver, 10 iterations | 0 |

The `RK4` line did not play: MuJoCo's keyword is `RK4`, in capitals. Played in probe 03: 1,293.

## Probe 03: the slide, and the configuration that removes the creep

`probe_03.sh`, reading `reading_03.txt`.

| | 2 ms | 1/4 | 1/16 | 1/64 | Right answer |
|---|---|---|---|---|---|
| The slide's deceleration from 50 to 200 ms, mm/s2 (friction 0.4) | 3,880 | 3,898 | 3,920 | 3,957 | 3,920 |
| Elliptic cone with 10 noslip iterations: the hold's creep, um/s | 0 | 0 | 0 | 0 | 0 |
| The same: friction over the oblique landing, per 10,000 | 2,999 | 2,999 | 2,999 | 2,999 | 3,000 |
| The same: distance slid, um | 126,686 | 127,476 | 127,639 | 126,629 | 127,551 |
| The same: rebound | 0 | 0 | 0 | 0 | the same at every step |

## Probe 04: the arm on one joint

`probe_04.sh`, reading `reading_04.txt`; `probe_04c.sh`, reading `reading_04c.txt`. The sixth and eighth
registrations' arm: 2 kg, half-size 0.04 m, 0.4 m from the joint (inertia 0.322133 kg m2, as MuJoCo computes it), on
the rig [`tools/mjc_joint.c`](../../tools/mjc_joint.c).

| The arm | 2 ms | 1/4 | 1/16 | 1/64 | Right answer |
|---|---|---|---|---|---|
| Spinning freely at 3 rad/s: speed after 1 s, urad/s | 3,000,000 | 3,000,000 | 3,000,000 | 3,000,000 | 3,000,000 |
| A torque of 1.5 N m for 1 s: speed, urad/s | 4,656,457 | 4,656,457 | 4,656,457 | 4,656,457 | 4,656,457 |
| The pendulum released level: every swing, per 10,000 | 10,000 | 9,999 | 9,999 | 9,999 | 10,000 |
| Held by joint friction of 12 N m against gravity's 7.84: creep, urad/s | 25,670 | 25,670 | 25,670 | 25,670 | 0 |
| Released 0.03 rad inside its limit, damping 20: speed on leaving, urad/s | 1,466,225 | 1,441,122 | 1,435,787 | 1,434,544 | 1,434,131 |
| The same, damping 150 | 388,860 | 371,997 | 370,010 | 369,551 | 369,401 |

The rig first gave MuJoCo the registered stiffness and damping as they stand: the arm left 31% and 8% slow, whatever
the limit's impedance. MuJoCo's direct form takes them per unit of inertia, so that was a different spring, a fault
of the rig, not of MuJoCo. Divided by the arm's inertia, the limit leaves within 0.04% of the right answer at 1/64
and converges as the step is refined.

Corrected after run 002: this record first kept the limit plays of `probe_04.sh` from the rig before its fix, so
`probe_04.sh` and the rig as committed did not remake them, and the plays behind `reading_04b.txt` and
`reading_04c.txt` had no script. Run 002 found it. The limit rows above are now from the corrected rig at every step
(`reading_04.txt`, the 2 ms and 1/64 values unchanged from `reading_04c.txt`), and `probe_04c.sh` remakes
`reading_04c.txt` and its runs byte for byte. The plays from the rig before its fix are kept as the record of the
error: `reading_04_before_fix.txt`, `reading_04b_before_fix.txt` (the limit's impedance, 1/64) and
`runs/before_fix/`. The current rig cannot remake them.

## What the probes point at

- **Nothing holds at rest, as shipped.** A cube pushed below its friction limit creeps at a speed in proportion to
  the push up to 0.6 of the limit, and faster beyond, whatever the step, the mass or the integrator. That is the
  signature of friction acting as a damper. MuJoCo documents its constraints as soft; this measures what that costs.
- **MuJoCo's own noslip solver does nothing with its default friction cone.** With the elliptic cone it removes the
  creep entirely. A user who turns on noslip and keeps the default cone is not protected.
- **Friction over an impact is Coulomb's**, within 1 in 10,000 at every step: where SuperDex needed a patch, MuJoCo
  is right as shipped.
- **The bounce does not depend on the step** (MuJoCo's default contact is critically damped, so there is none).
- **Sliding friction moves with the step**: the slide decelerates 1.0% less than Coulomb's law at the default step and 0.9% more at 1/64, so its distance does not settle as the step is refined. The configuration that removes the creep does not change it.
- **The elliptic cone with noslip removes the creep at every step**, and changes nothing else these scenes read.
- **Joint friction does not hold either.** An arm held by joint friction half again larger than gravity's torque
  creeps at 25,670 urad/s (1.5 degrees a second) at every step: MuJoCo's frictionloss is a soft constraint too.
- **Free joint motion is exact**: a free spin keeps its speed, a torque gives torque over inertia to the urad/s, and
  the pendulum keeps every swing. Where SuperDex needed patch G, MuJoCo is right as shipped.
- **Joint limits push and never pull**: released inside its limit, the arm leaves at the right speed.

Next: joint friction under MuJoCo's options; the remaining scenes of the first deep dive
(two cubes, the chain, the rotations, deformable bodies, a gripper) and the benchmark scenes.

## Corrected after run 006

The contact files under `runs/` were written by the rig before run 006 corrected it: their height column is each
step's start, one step behind the other columns. Run 006 played this run again with the corrected rig: every reading
on this page is unchanged, byte for byte, and the corrected plays are under run 006's `runs/`.

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). The step of 1/64 of 2 ms,
31.25 us, was read as 31. This run's readings stay as they were printed, and each one the correction changes has its
corrected copy beside it, `<name>_corrected.txt`. As corrected, the tables above read:

| | 2 ms | 1/4 | 1/16 | 1/64 | Right answer |
|---|---|---|---|---|---|
| Given 1 m/s at rest, friction 0.4: distance slid, um | 126,732 | 127,482 | 127,681 | **127,727** | 127,551 |
| The slide's deceleration from 50 to 200 ms, mm/s2 | 3,880 | 3,898 | 3,920 | **3,907** | 3,920 |
| Elliptic cone with 10 noslip iterations: distance slid, um | 126,701 | 127,491 | 127,664 | **127,713** | 127,551 |

So the finding above is corrected: **the slide decelerates 1.0% less than Coulomb's law at the default step and 0.3%
less at 1/64, not 0.9% more, and its distance does settle as the step is refined**, to 0.14% over Coulomb's at 1/64.
Run 088 found what is left of the step dependence: released, the sliding cube hops, so the deceleration read over a
window mixes flights and landings.
