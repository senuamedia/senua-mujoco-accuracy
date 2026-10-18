# Run 009: the two-cube plays with a frictionless ground

15 October 2026. Not registered: a correction to run 008's two-cube scenes, on run 002's Linux machine, by
[`play.sh`](play.sh); reading `reading.txt`; plays under `suites/2/frictionless_ground_*`.

## Why

Run 008's "top" test (B slides across A, which stands on a frictionless ground) lost 1,250 ppm of its momentum. The
rig had given the ground a friction of 0 under condim 3, and MuJoCo raises any friction below 1e-5 to 1e-5
(`mjMINMU`, `engine_core_constraint.c`): 1e-5 of A and B's weight over the play is 1,250 ppm of B's momentum, exactly.
MuJoCo's own way to make a frictionless contact is a normal-only contact, condim 1. The two-cube rig
[`tools/mjc_pair.c`](../../tools/mjc_pair.c) now uses it when the ground's friction is 0, and suite 2 was played again
under both configurations.

## What changed

The plays with the ground under them changed (`compare_*.txt`: 16 of 28 files under the defaults, 12 under the
elliptic cone and noslip); the side plays, with no ground, are byte-identical to run 008's.

| Test | Right answer | Defaults, 10 ms | Defaults, 0.625 ms | Elliptic and noslip, 10 ms | Elliptic and noslip, 0.625 ms |
|---|---|---|---|---|---|
| B slides on top of A: largest change of momentum (the measure) | 0 | 80 ppm | 75 ppm | 75 ppm | 75 ppm |
| B carried on A: B's mean speed relative to A | 0 | **-916 um/s** | **-915 um/s** | 0 | 0 |
| A pushed hard: B's acceleration from 700 to 900 ms | 4,900 mm/s2 | 5,332 | 4,991 | 3,439 | 4,797 |

## Momentum, read at the measure's resolution

The pair measure counts momentum in units of 10 g times 10 um/s (`sx_contact.sx`, PAIR), so one unit of A's speed is
300 of its units, 75 ppm of B's momentum in these scenes. Every momentum change read in runs 008 and 009 apart from the
1,250 ppm above (36 to 80 ppm) is within about one such unit. Summed from the rig's files directly, the largest change
in the top and side plays at 0.625 ms is 1,600 g um/s, 4 ppm, within the rounding of the files themselves (each speed
to the nearest um/s): the two cubes keep their momentum. The first deep dive's rule for this test allowed 500 ppm for
the same reason. Run 008's sentence "kept within 53 ppm" reads, correctly, "kept within the measure's resolution".

## What it shows

- With a truly frictionless ground the two cubes keep their momentum, and the 1,250 ppm of run 008 was MuJoCo's least
  friction, as computed.
- Under the defaults the carried cube still slides back on A, now at 0.92 mm/s at both steps: the creep of run 001,
  between two moving bodies. The elliptic cone with noslip carries it exactly.
- B's acceleration while it slips stays off by up to 30% over the window because B hops while it slides (run 008).
