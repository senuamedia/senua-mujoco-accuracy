# Run 039: the weld, and a free tumbling body

15 October 2026. Not registered: a design probe on the cloud machine, by [`probe.sh`](probe.sh), pushed before any play.
It finds where to look and decides nothing. Two questions the record had not asked: does the inverse weight in the
current pose, third version, end a body held by a `weld` the same in every writing, as it does one held by a `connect`;
and does MuJoCo keep a free tumbling body's energy and angular momentum (known issue M10)?

## The weld

The arm rig gains `tipweld`: link 2 held where it starts, in place and in orientation, by MuJoCo's `weld` equality
between two sites, one at the ball's centre on link 2 and one in the world where the ball's centre starts, turned as
link 2 starts. With it unset the rig plays as before (`identity.txt`: run 038's 84 release plays of the arm on
contact, on a limit, held by joint friction and held by a `connect`, 84 of 84 byte-identical). Study 8's arm, released
at rest with its ball 1 m above the ground and held there by the weld alone, in poses (0.15, 0.75) and (0.3, 1.0), 2 s,
written in its own pose, straight and folded (0, 2.4), at 1.6 ms and 0.4 ms. Arms: the release under MuJoCo's defaults
and with its `diagexact` flag; the patched build (`patches/invweight_at_pose_v3.diff`, sha256 d3fd45cc3d3ecfb0...,
`patch_check.txt`), switch unset and set. Read by Senua AI's measure: `ends` between writings, and `final` (whose first
number, on an arm file, is the ball's height above the ground in nm).

| Arm | Pose | Ends apart from native: straight, folded (both steps) | The ball's sag at the end: native, straight, folded |
|---|---|---|---|
| release | (0.15, 0.75) | 57.0 um, 0.68 um | 248.5, 191.5, 247.9 um |
| release | (0.3, 1.0) | 84.9 um, 19.1 um | 288.5, 203.6, 269.4 um |
| release, `diagexact` | both | 0, 0 | 402.9 and 346.9 um, every writing |
| switch unset | both | as the release, every file byte-identical (12 of 12) | as the release |
| switch set | both | **0 nm, 0 um/s** | 248.4 and 288.4 um, every writing |

Finding F10 reaches a `weld` as it reaches a `connect`: the held body ends up to 85 um apart by writing, through the
same frozen body weights. With the switch set every writing ends in the same place to the nanometre at both steps; with
it unset the patched build plays the release byte for byte. The solver took one iteration a step and raised no warning.

## The free tumbling body

A new rig, [`tools/mjc_tumble.c`](../../tools/mjc_tumble.c): one free rigid body with principal moments 0.0045, 0.0072
and 0.0101 kg m2, set spinning at (2.2, 1.4, -3.1) rad/s along its own axes, no gravity and nothing touching it, 2 s,
under each of MuJoCo's integrators at the record's step ladder, 10 ms over 1, 4, 16 and 64. It tumbles: the spin
along its first two axes swings through zero and back, and along the third keeps its sign, between 2.76 and 3.21
rad/s in size (RK4 at the finest step). Nothing acts on it, so its rotational kinetic energy and the magnitude
of its angular momentum must stay what they were, at every step. The rig writes the body's angular velocity in its own
frame each step (MuJoCo's free joint carries it there; the rig checked it against `mj_objectVelocity` to 1e-14 rad/s);
Senua AI's new measure, [`measure/sx_tumble.sx`](../../measure/sx_tumble.sx), works out both from it and the principal
moments in exact whole-number arithmetic. The largest drift over the 2 s, in parts per million of the start:

| Integrator | Energy: 10 ms | 2.5 ms | 0.625 ms | 0.156 ms | Angular momentum: 10 ms | 2.5 ms | 0.625 ms | 0.156 ms |
|---|---|---|---|---|---|---|---|---|
| Euler (MuJoCo's default) | **+34,145** | +8,215 | +2,034 | +507 | **+12,677** | +3,062 | +758 | +188 |
| implicitfast | -30,868 | -8,010 | -2,021 | -506 | -11,585 | -2,995 | -755 | -190 |
| implicit | the same as implicitfast, byte for byte | | | | | | | |
| RK4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

- **Under MuJoCo's default integrator a tumbling body gains energy and angular momentum**, 3.4% and 1.3% in 2 s at
  10 ms, falling four times with every fourfold smaller step: a first-order error, as on the free chain (run 007).
- **implicitfast and implicit lose them at about the same rate**, and are byte-identical here: for a standalone free
  body MuJoCo's implicitfast keeps the gyroscopic derivative, as its documentation says.
- **RK4 keeps both** to the measure's resolution at every step.
- The patched build, switch unset and set, and with the elliptic cone and noslip, plays the body under Euler byte for
  byte as the release: with no constraint, the patch and the cone have nothing to act on.

Every reading is in [`reading.txt`](reading.txt); the solver raised no warning in any play.

## What it shows, and what it does not

A `weld` is changed by the third version as a `connect` is, and ends the same in every writing with it on: a registered
study can now ask it. The tumbling body shows M10's energy gain under the default integrator on a body with no joints
at all, which the free chain could not separate from its coupling; RK4 is MuJoCo's remedy here too. One arm, one body,
decided by no rule.
