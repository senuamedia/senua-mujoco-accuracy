# Run 076: every friction component noslip computes for the box that never rests (a probe)

17 October 2026 (01:35 UTC). Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh),
pushed before its plays. It finds where to look and decides nothing. Readings in [`measured.txt`](measured.txt), one
line a noslip pass and contact in `trace/*.passes`, the trace itself in `trace/*.trace.gz`.

[Run 073](../run_073_box_noslip_trace/README.md) found the box of issue 20 (F13, MuJoCo's test scene
`DiscreteImplicitRowNoslip`, condim 6) rocking on a six-step cycle, with noslip converging every step. Run 050 found it
at rest with condim 4. An instrumentation patch, [`noslip_trace_all.diff`](../../patches/in_design/noslip_trace_all.diff)
(off unless `MUJOCO_NOSLIP_TRACE_ALL` is set; `engine_solver.c` only, 23 lines added, none removed), prints every
friction component of each elliptic contact with torsional or rolling friction, at each noslip sweep: before the sweep,
as the friction solve returns it, and as kept after MuJoCo's cost check. It is built from MuJoCo's source at
`UPSTREAM_COMMIT`. The probe plays the scene as written (run 049's copy, 16 s), and the same scene with `condim="4"` in
place of `condim="6"` and nothing else changed ([`scene_condim4.diff`](scene_condim4.diff)). With the switch unset the
plays are byte for byte the release's and print nothing; traced, byte for byte as untraced.

The scene gives the box MuJoCo's default friction: 1 sliding, 0.005 torsional, 0.0001 rolling.

## What noslip computes

| | condim 6, as written | condim 4 |
|---|---|---|
| The box over its last 160 steps | 106 steps faster than 1 mm/s, up to 77 mm/s | **at rest, 0 um/s at every step** |
| A contact's friction on the elliptic cone's edge, of all contact-passes | **3,288 of 3,292**, and every one of the last 160 passes | 10 of 3,948, all in the first 3 passes while the box slides; none after |
| MuJoCo's cost check put the old friction back | 824 of 3,292 contact-passes (133 of the last 532) | 4 of 3,948 |
| A contact's rolling torque, the last cycle | 1.5e-5 to 5.8e-4 N m, against normal forces of 0.36 to 7.2 N | none (condim 4 has no rolling rows) |
| Its sliding friction, the last cycle | up to 4.2 N, where a friction of 1 alone would allow 7.2 N | every component under 7.5e-11 N over the last 160 passes |

With rolling friction, every one of the box's contacts is at the edge of its elliptic cone at every step. MuJoCo's
elliptic cone is one ellipsoid over all of a contact's friction components, each over its own coefficient. With a
rolling coefficient of 0.0001 m, a rolling torque of 2.4e-4 N m against a normal force of 2.4 N fills the whole cone
by itself. So the rolling torques that noslip asks for leave the sliding friction no room, and the friction that holds
a contact takes what remains. Noslip solves friction with the normal forces held fixed. It asks the rolling rows to stop
the box's turning about its contacts, which on four corners only the normal forces can do. On a quarter of the passes
the cost check rejects its solve. Without rolling rows, noslip has nothing to ask of them, the friction stays inside the
cone, and the box rests.

## What it shows

Issue 20 is traced: under the elliptic cone, noslip drives the rolling friction of a box resting on its corners to the
cone's edge. Because one ellipsoid covers all of a contact's friction, that takes the sliding friction's room too, and
the box rocks. Where to look next is a design that keeps the rolling rows from emptying the cone's sliding part. One
option is to leave out of noslip the rolling rows of a contact whose body the other contacts already hold from turning.
Another is to solve the rolling part in a cone of its own, as Coulomb's law would treat two separate resistances.
Either is a change to MuJoCo's friction model and needs its own probes.

Read from the same trace afterwards (the friction before noslip's first sweep, which is MuJoCo's main solve): once the
cycle runs, the main solve's own friction is on the cone's edge in 1,968 of 3,290 contact-passes, with the rolling part
over half the cone in 1,634. So, in the cycle, the saturation is not noslip's alone. A design that only keeps noslip
from changing the rolling rows would start from friction already at the edge. Whether it keeps the cycle from starting
is for a probe.
