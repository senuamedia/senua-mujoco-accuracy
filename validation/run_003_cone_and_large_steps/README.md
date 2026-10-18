# Run 003: the friction cone at an angle, and the contact at large steps

15 October 2026. Not registered: a design probe, played on the Linux machine of run 002 (byte-identical to the Mac
for this engine), by [`probe.sh`](probe.sh); reading `reading.txt`. MuJoCo 3.16.0 as shipped, its options at their
defaults unless a line names one. The one-cube rig, the cube unable to turn, given a direction in the ground plane
(`dir=`, added to the rig for this run: off unless asked for). Checks before reading: the rig with `dir=0` gives run
001's slide byte for byte, and the run 002 replay still matches all 95 files with the rig as changed. The solver took
at most 4 iterations on any step of any play, and raised no warning.

## 1. The slide that ends, along three directions

A cube at rest on the ground given 1 m/s, friction 0.4: Coulomb's distance is 127,551 um in every direction, along a
straight line.

| Direction from x | Pyramidal cone (the default), 2 ms | 1/16 of it | Drift across the line | Elliptic cone, 2 ms | 1/16 of it |
|---|---|---|---|---|---|
| 0 degrees | 126,717 um | 127,655 um | 0 | 126,695 um | 127,648 um |
| 22.5 degrees | 151,762 um | 152,708 um | 33,852 um, at up to 184 mm/s | 126,695 um | 127,648 um |
| 45 degrees | 179,492 um | 180,420 um | 0 | 126,695 um | 127,648 um |

## 2. The hold, pushed along two directions

Friction 0.5, pushed from 0.5 s with a share of what friction can hold (4.9 N), at 2 ms. Creep is the cube's mean
speed under the push; friction over normal is the friction force the ground gave, over the cube's weight.

| Push, share of the limit | Pyramidal, 0 degrees | Pyramidal, 45 degrees | Elliptic, either direction |
|---|---|---|---|
| 0.6 | 1,293 um/s | 969 um/s | 766 um/s |
| 0.69 | 1,729 um/s | 1,115 um/s | 881 um/s |
| 0.72 | 1,875 um/s | **63,438 um/s: slides** | 919 um/s |
| 0.8 | 2,263 um/s | **455,607 um/s: slides** | 1,021 um/s |
| Friction over normal at 0.72 and 0.8 (per 10,000) | 3,600 and 4,000 | **3,535 and 3,535** | 3,600 and 4,000 |

## 3. The drop and the set-down at large steps

| Step | 1 ms | 2 ms | 4 ms | 6 ms | 8 ms | 10 ms |
|---|---|---|---|---|---|---|
| Rebound from a 100 mm drop, per 10,000 | 0 | 0 | 0 | 0 | 0 | 0 |
| Ground force at rest, mN (weight 9,800) | 9,800 | 9,800 | 9,800 | 9,800 | 9,800 | 9,800 |
| Depth at rest, the rig's last line, nm | 17,055 | 17,055 | 17,055 | 17,055 | 17,055 | 17,055 |

## What the probe shows

- **MuJoCo's default friction cone gives friction a direction.** Along 45 degrees to the cone's axes a slide goes
  40.7% further than Coulomb's law, and along 22.5 degrees it goes 19.0% further and leaves its line by 34 mm on a
  152 mm slide. Refining the step changes the distances by under 1%: it is the cone, not the step. The default cone's
  four edges lie along x and y, so the friction it can give is |fx| + |fy| <= mu N, a diamond: along 45 degrees that is
  mu N / sqrt(2), 0.707 of Coulomb's. The slide at 45 degrees goes 1.416 times as far as along x, as the diamond
  predicts (1.414).
- **The same diamond lets go of a hold early.** Pushed along 45 degrees, the cube holds at 0.69 of the limit and
  slides at 0.72, with the friction capped at 3,535 per 10,000 of the weight, 0.707 of 0.5. A part held at 45 degrees
  to the axes is lost at 71% of the friction it is rated for.
- **The elliptic cone has no direction**: the same distance, no drift and the same creep along every direction.
  Together with run 001 (the elliptic cone with noslip holds without creeping), it is the configuration every friction
  study will carry next to the default.
- **Up to 10 ms the contact does not change with the step**: no rebound, the weight carried exactly, the same 17 um
  depth at rest. MuJoCo's guard on stiffness at large steps (refsafe) acts only once twice the step passes the default
  time constant, 0.02 s, so it has not acted yet at 10 ms; the next probe goes past it.

Next: steps past 10 ms; the hold at 22.5 degrees (where the friction also turns); a cube free to turn.

## Corrected after run 006

The contact files under `runs/` were written by the rig before run 006 corrected it: their height column is each
step's start, one step behind the other columns. Run 006 played this run again with the corrected rig: every reading
on this page is unchanged, byte for byte, and the corrected plays are under run 006's `runs/`.

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 126,695 um | 126,710 um |
| 126,717 um | 126,732 um |
| 127,648 um | 127,674 um |
| 127,655 um | 127,681 um |
| 151,762 um | 151,782 um |
| 152,708 um | 152,739 um |
| 179,492 um | 179,513 um |
| 180,420 um | 180,454 um |

What this page concludes does not change: the largest of these corrections is 0.02%.
