# Run 055: actuators and tendons across MuJoCo's releases, and the box with noslip run further (a probe)

16 October 2026 (11:41 to 11:42 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Readings in
[`measured.txt`](measured.txt).

## 1. Actuators and tendons, 3.11.0 to 3.16.0 (issue 16)

A new rig, [`tools/mjc_act.c`](../../tools/mjc_act.c): the one-joint rig's arm (1 kg, 0.5 m from its hinge) driven by
MuJoCo's position, velocity, motor, filtered general, damper and muscle actuators, or held by a fixed or a spatial tendon
spring. Each scene at 2 and 0.5 ms, under MuJoCo's default integrator and implicitfast, 2 s, on Google DeepMind's Linux
releases 3.11.0 to 3.16.0 (as fetched and checked by [run 053](../run_053_releases/README.md)).

**The damper scene did not play in any release**: the rig gave MuJoCo's damper an attribute it does not take
(`ctrllimited`), and every release refused the scene. The other seven played, 28 files a release.

**Every one of the 28 files is byte for byte the same in all six releases.** Where the scenes have an answer, 3.16.0
(and so every release) gives it:

| Scene | The answer | MuJoCo, 2 s, at both steps and both integrators |
|---|---|---|
| Position servo (kp 50) to 0.5 rad under gravity | at rest where kp (0.5 - q) = m g arm cos q: q = 0.41013 rad | 410,127 urad, still; its force 4.4936 N m |
| Velocity servo (kv 5) to 1 rad/s, no load | 1 rad/s | 1,000,000 urad/s |
| Motor, gear 2, control 3 clipped to 1 | turns at 2 / I = 7.947 rad/s2: 15.894 rad/s after 2 s | 15,894,040 urad/s |
| Filtered general actuator, the same servo | at rest as the position servo | 410,127 urad, still |
| Two arms on a fixed tendon spring | their summed momentum stays 0 | 0 urad/s at every step |
| Spatial tendon spring; muscle on a spatial tendon | (no closed answer) | played; the same in every release |

The rig's statistics line prints MuJoCo's two size fields with the wrong format (the build's warning); the plays' files
do not use them.

## 2. The box that never rests, with noslip run further (issue 20)

MuJoCo's `DiscreteImplicitRowNoslip` scene (taken from its test file in run 049), 1,000 steps, at 2, 10, 100 and 1,000
noslip iterations with a noslip tolerance of 1e-12, on the release and with the de Saxce patch's switch set. The scene
rig gains `noslip_tolerance`, unchanged without it: run 049 step 2's `scene_rel.txt` made again, byte for byte.

**Nothing changes the cycle.** At every setting, released, the box is faster than 1 mm/s on 106 of steps 40 to 199 and
on 106 of steps 840 to 999, fastest 76,978 um/s, as with noslip's default tolerance (run 050); with the switch set, 108
and 106, fastest 76,903 um/s. At 100 and 1,000 iterations noslip runs to its cap without meeting the tolerance on 491
of the 1,000 steps released (166 with the switch set).

## What it shows

- From 3.11 to 3.16 these seven actuator and tendon scenes play byte for byte alike, and MuJoCo gives each answer they
  have. No change between releases found where measured; the damper, releases before 3.11, and other actuator types
  (cylinder, adhesion, plugins) are not asked here.
- The box's cycle is not noslip stopping too soon: run further, noslip does not converge on this scene, and the cycle is
  the same.
