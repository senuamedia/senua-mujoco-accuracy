# Run 057: the damper actuator across MuJoCo's releases (a probe)

16 October 2026 (12:14 UTC). Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh), pushed
before its plays. It finds where to look and decides nothing. Readings in [`measured.txt`](measured.txt).

[Run 055](../run_055_actuators_and_box/README.md)'s damper scene did not play in any release: the actuator rig gave
MuJoCo's damper an attribute it does not take. The rig is corrected, and its statistics line prints MuJoCo's two size
fields as long (its build now gives no warning). Unchanged otherwise: run 055's seven other scenes made again on 3.16.0,
28 of 28 files byte for byte (`r3.16.0/id/identity.txt`).

The damper scene: MuJoCo's damper actuator (kv 5, control 1) on the arm released level under gravity, 2 s, at 2 and 0.5
ms, under MuJoCo's default integrator and implicitfast, on Google DeepMind's Linux releases 3.11.0 to 3.16.0. **Its
four files are byte for byte the same in all six releases.** The arm swings down against the damper and ends at -1.295
rad, turning at 0.281 rad/s, the damper's force 1.41 N m, kv times control times speed, as MuJoCo defines it.

With run 055, the eight actuator and tendon scenes the record plays are the same from 3.11 to 3.16.
