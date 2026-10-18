# Run 005: past the stiffness guard, the hold along 22.5 degrees, and a cube free to turn

15 October 2026. Not registered: a design probe following run 003, on the same Linux machine, by
[`probe.sh`](probe.sh); reading `reading.txt`. MuJoCo 3.16.0 as shipped, its options at their defaults unless a line
names one. The solver took at most 6 iterations on any step of any play, and raised no warning.

## 1. Steps past the stiffness guard

MuJoCo holds a contact's time constant at no less than twice the step (refsafe). With the default time constant of
0.02 s that starts to act past 10 ms, where run 003 stopped.

| Step | up to 10 ms (run 003) | 12 ms | 15 ms | 20 ms | 30 ms | 40 ms |
|---|---|---|---|---|---|---|
| Depth at rest, the rig's last line, nm (corrected in run 006) | 17,055 | 24,550 | 38,319 | 67,868 | 149,983 (still settling, 7 um/s) | 269,269 (still settling, 163 um/s) |
| Ground force at rest, mean, mN (weight 9,800) | 9,800 | 9,800 | 9,800 | 9,799 | 9,798 | 9,777 |
| Rebound from a 100 mm drop, per 10,000 | 0 | 0 | 0 | 0 | 0 | 0 |

## 2. The hold, pushed along 22.5 degrees

Friction 0.5, pushed from 0.5 s with a share of what friction can hold, 2 ms. Across the push: how far the cube went
across the push's line by the end.

| Push, share of the limit | Pyramidal: creep | Pyramidal: friction over normal, per 10,000 | Pyramidal: across the push | Elliptic: creep | Elliptic: across |
|---|---|---|---|---|---|
| 0.6 | 1,132 um/s | 3,000 | 100 um | 766 um/s | 0 |
| 0.69 | 1,526 um/s | 3,450 | 253 um | 881 um/s | 0 |
| 0.72 | 1,657 um/s | 3,600 | 304 um | 919 um/s | 0 |
| 0.8 | **148,461 um/s: slides** | 3,848 | **57,931 um** | 1,021 um/s | 0 |
| 0.85 | **362,471 um/s: slides** | 3,880 | **142,259 um** | 1,085 um/s | 0 |
| 0.9 | **577,163 um/s: slides** | 3,911 | **225,362 um** | 1,149 um/s | 0 |

## 3. The slide that ends, the cube free to turn

1 m/s, friction 0.4, 2 ms, the cube on a free joint (run 003 held it level). Coulomb's distance: 127,551 um.

| Direction from x | Pyramidal | Across the line | Elliptic | Across the line |
|---|---|---|---|---|
| 0 degrees | 126,772 um | 0 | 126,719 um | 0 |
| 22.5 degrees | 152,658 um | 31,874 um | 129,091 um | 1,086 um |
| 45 degrees | 179,485 um | 0 | 126,789 um | 0 |

## What the probe shows

- **Past the guard, the contact softens with the square of the step.** The depth at rest grows from 17 um at 10 ms to
  68 um at 20 ms, 4.0 times deeper for twice the step, as a time constant of twice the step gives (stiffness falls
  with the square of the time constant); at 30 and 40 ms the cube is 8.8 and 15.8 times deeper (against 9 and 16) and
  still settling when the play ends. The contact stays stable: no rebound, the weight carried within 0.3%. MuJoCo
  trades accuracy for stability here, as its documentation says it does.
- **Along 22.5 degrees the default cone holds up to 0.72 of the limit and lets go by 0.8**, where the diamond of run
  003 predicts 0.765 (1 over cos 22.5 degrees plus sin 22.5 degrees). Once the cube slides it does not slide along the
  push: at 0.9 of the limit it went 225 mm across the push's line in 1.5 s. Even while it holds, it creeps across the
  push (up to 0.3 mm). A gripper pushing along 22.5 degrees to the axes loses its part at three quarters of the
  friction it is rated for, and the part leaves sideways.
- **The elliptic cone holds every push up to 0.9 along 22.5 degrees** with the same creep as along x, and nothing
  across.
- **Free to turn, the cube shows the same direction in the default cone** (40.7% further along 45 degrees, 32 mm off
  its line along 22.5 degrees). With the elliptic cone a free cube along 22.5 degrees goes 1.2% further than Coulomb's
  distance and 1.1 mm off its line, where the level cube of run 003 went neither: small, and to be looked at with the
  cube's turn recorded.

## Corrected after run 006

The contact files under `runs/` were written by the rig before run 006 corrected it: their height column is each
step's start, one step behind the other columns. The numbers on this page are the corrected ones (run 006 lists what
changed: the depths at 20, 30 and 40 ms and the distances across the push once the cube slides); the corrected plays
are under run 006's `runs/`.

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 126,719 um | 126,732 um |
| 126,772 um | 126,791 um |
| 126,789 um | 126,804 um |
| 129,091 um | 129,105 um |
| 152,658 um | 152,680 um |
| 179,485 um | 179,505 um |

What this page concludes does not change: the largest of these corrections is 0.01%.
