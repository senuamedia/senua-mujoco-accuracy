# Run 008: the first deep dive's two contact suites, on MuJoCo

15 October 2026. Not registered: a design probe on run 002's Linux machine. The first deep dive's two contact suites
played on MuJoCo 3.16.0 with the same scenes, steps (10 ms over 1 to 64) and file names
([`tools/contact_suite.sh`](../../tools/contact_suite.sh), [`tools/contact_suite2.sh`](../../tools/contact_suite2.sh);
the new two-cube rig [`tools/mjc_pair.c`](../../tools/mjc_pair.c)), under two configurations: MuJoCo's defaults, and
the elliptic cone with 10 noslip iterations (the configuration that held in run 001). Measured by
[`measure.sh`](measure.sh): suite 1 by the first deep dive's own runner, `measure/runners/sx_contact_suite.sh`
(sha256 553d46ecdaf2bd95...), unchanged, which gives each T-numbered test its verdict; suite 2 by the measures the
first deep dive used on it (`stop`, `pair`, `accel`). The plays are under `suites/`. The solver never reached its
iteration limit and raised no warning.

## Suite 1: the ten known-answer tests (`suite1_defaults.txt`, `suite1_elliptic_noslip.txt`)

| Test | MuJoCo's defaults | Elliptic cone, noslip 10 |
|---|---|---|
| T01 nothing touches the cube: each refinement halves the gap | PASS | PASS |
| T02 steady sliding: friction over normal 4,000 per 10,000 | PASS (3,999, 3,999) | PASS |
| T03 at rest the ground carries the weight | PASS | PASS |
| T04 the bounce does not depend on the step | PASS (0 at every step) | PASS |
| T05 Coulomb at impact, every step | PASS (3,999 to 4,000) | PASS |
| **T06 held below the friction limit does not move** | **FAIL: 1,293 um/s at both steps** | PASS: 0 |
| T07 pushed above the limit, it accelerates at (push minus friction) over mass | PASS | PASS |
| T08 the refinement chain falls at every step | PASS | PASS |
| T09 the ground never pulls | PASS | PASS |
| T10 friction over the impact and the 0.1 s after it | PASS | PASS |
| **Passed** | **9 of 10** | **10 of 10** |

## Suite 2: a slide that ends, and two moving cubes (`suite2_defaults.txt`, `suite2_elliptic_noslip.txt`)

| Test | Right answer | Defaults, 10 ms | Defaults, 0.625 ms | Elliptic and noslip, 10 ms | Elliptic and noslip, 0.625 ms |
|---|---|---|---|---|---|
| Set sliding at 1.2 m/s, friction 0.4: distance (and stays stopped) | 183,673 um | 177,953 | 183,475 | 177,979 | 183,451 |
| B carried on A, A pushed gently: B's mean speed relative to A | 0 | **-3,631 um/s** | **-1,031 um/s** | 0 | 0 |
| A pushed hard: friction over normal on B while it slips | 0.5000 | 0.5000 | 0.5000 | 0.5000 | 0.5000 |
| The same: B's acceleration from 700 to 900 ms | 4,900 mm/s2 | 4,769 | 6,005 | 3,439 | 4,809 |
| B runs into A's side: largest change of momentum | 0 | 36 ppm | 50 ppm | 13 ppm | 53 ppm |
| B slides on top of A: largest change of momentum | 0 | 2,935 ppm | 1,250 ppm | 1,250 ppm | 1,250 ppm |

The slide that ends also stays stopped at every step, in both configurations (no speed in the last third).

## What the suites show

- **On the first deep dive's own ten tests, MuJoCo as shipped passes nine.** The one it fails is the hold, by the
  creep run 001 found. With the elliptic cone and noslip it passes all ten. The same runner, unchanged, read both
  engines.
- **A sliding body leaves the surface it slides on.** Friction while slipping is Coulomb's exactly (0.5000), yet B's
  acceleration over the window is 2% to 30% off, because B is not resting on A: while it slips it rises up to 2.7 mm
  above A and sinks 2.0 mm into it at 10 ms (8.3 mm and 3.4 mm with the elliptic cone and noslip), moving up and
  down at up to 0.43 m/s. A single cube slid on the ground does the same:

  | Set sliding at 1.2 m/s, friction 0.4 | 10 ms | 2.5 ms | 0.625 ms | 0.156 ms |
  |---|---|---|---|---|
  | Highest above the ground while sliding, defaults | 10,848 um | 823 um | 197 um | 32 um |
  | The same, elliptic and noslip | 10,571 um | 1,177 um | 148 um | 14 um |
  | Fastest upward, defaults | 433 mm/s | 115 mm/s | 61 mm/s | 24 mm/s |

  The cube is set sliding on the ground and leaves it by up to 10.8 mm at 10 ms; at 2 ms in run 001's slide it rose
  0.65 mm. The upward speeds at the largest step are close to the friction coefficient times the sliding speed, the
  separation MuJoCo's relaxed contact allows while sliding (known issue M5). The configuration that holds does not
  remove it.

  This table was read before Senua AI's measure had a reading for it. Its `hover` reading, added on 15 October
  (`sx_contact.sx`, sha256 87e921cd4d2c03bf... as run), re-makes it from the same plays ([`hover.sh`](hover.sh),
  `hover.txt`) to within 1 um: the measure truncates to the micrometre where the table rounded (822 for 823, 196 for
  197, 10,570 for 10,571, 1,176 for 1,177, 13 for 14), and the fastest upward speeds are 432.6, 115.1, 61.2 and
  24.4 mm/s.
- **Between two moving bodies, the hold creeps too**: B carried on A slides back at 3.6 mm/s at 10 ms and 1.0 mm/s at
  0.625 ms under the defaults; the elliptic cone with noslip carries it exactly.
- **Momentum between the cubes is kept within the measure's resolution** (run 009 explains: 36 to 80 ppm here is one
  unit of A's speed) when B strikes A's side. When B slides across A, the change
  is 1,250 ppm in three of the four plays, exactly what MuJoCo's least friction gives the ground under A: the rig
  gives the ground a friction of 0, which MuJoCo raises to 1e-5 (`mjMINMU`, `engine_core_constraint.c`), so the
  ground is not quite frictionless. MuJoCo makes a frictionless contact with condim 1; run 009 plays it so.

Next: the pair plays with a frictionless ground (condim 1); the lift against the friction coefficient and the speed.
