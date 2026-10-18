# Run 019: the sliding lift under MuJoCo's documented solref and solimp

15 October 2026. Not registered: a design probe on Google DeepMind's Linux release of MuJoCo 3.16.0, played on the
cloud machine by [`probe.sh`](probe.sh). It finds where to look and decides nothing.

Run 016 found that friction makes a sliding cube leave the ground (finding F3, known issue M5), and that neither the
elliptic cone with noslip nor `impratio` removes the lift. It did not try MuJoCo's contact reference and impedance,
`solref` and `solimp`. This probe plays them, at the values MuJoCo's documentation gives (`modeling.rst` of 3.16.0)
and no others:

| Arm | Setting | Where the documentation gives it |
|---|---|---|
| def | `solref` "0.02 1", `solimp` "0.9 0.95 0.001 0.5 2" | The defaults |
| ref | `solref` "0.01 1" | The contact of its soft-body example |
| imp | `solimp` ".95 .99 .0001" | The same example's impedance |
| both | the two together | The example's contact as written |
| d0 | `solimp` "0 0.95 0.001 0.5 2" | Its advice for smooth dynamics: `solimp[0]` = 0 |
| direct | `solref` "-1000 0" | Its direct-format example, stiffness 1000 and no damping (a bouncing sphere) |

Each arm plays 15 of run 016's slides: friction 0.4 at 0.6, 1.2 and 2.4 m/s, and friction 0.1 and 0.8 at 1.2 m/s, at
10 ms, 2.5 ms and 0.625 ms. Everything else is MuJoCo's default cone and integrator. `solimp` is new to the rig, given
to both geoms and only when set. Each play is read by Senua AI's measure: `sx_contact hover` (the highest the cube's
lowest face rises above the ground while it slides, the fastest it moves up, the deepest it sinks) and `stop` (how far
it slid). The solver never reached its iteration limit and raised no warning.

**The rig is unchanged when `solimp` is not given** (`identity.txt`): the def arm's 15 files are byte-identical to
run 016's.

## The readings

The highest the cube rises above the ground while it slides, in um, at friction 0.4 and 1.2 m/s (every play is in
`reading.txt`):

| Arm | 10 ms | 2.5 ms | 0.625 ms |
|---|---|---|---|
| def | 10,848 | 822 | 196 |
| ref | 10,848 | 2,590 | 543 |
| imp | 9,851 | 970 | 202 |
| both | 9,851 | 2,570 | 299 |
| d0 | 10,845 | **0** | **0** |
| direct | 940 | 29 | 1 |

## What it shows

- **The documentation's contact example does not remove the lift.** At 10 ms its `solref` plays exactly as the default,
  because MuJoCo's stiffness guard raises a 0.01 s time constant to twice a 10 ms step. At 2.5 ms and 0.625 ms it
  lifts the cube higher than the default: up to 9,289 um against 3,040 at 2.4 m/s and 2.5 ms. Its `solimp` alone
  changes the lift by -45% to +113% across the 15 slides, and together they lift it more than the default at the finer
  steps.
- **`solimp[0]` = 0 keeps the cube from rising above the ground at 2.5 and 0.625 ms, at a cost.** The impedance is then
  zero where the contact begins, so the cube rides into the ground: 0.26 to 0.58 mm deep while it slides, against 0.03
  to 0.50 mm under the default. It slides 1.1% to 8.1% further than Coulomb's law, where the default stops within 1.3%
  short of it at the same steps. At 10 ms it lifts the cube as the default does. The probe reads the height above the
  ground; whether the cube still rises from where it rides in is not read here.
- **The direct-format example removes friction altogether.** With no damping, the cube never slows: it slides 972 mm
  in 0.81 s at 1.2 m/s, every play at its starting speed, and the ground's force along the slide is 0 at every step of every play. It still rises
  0.94 mm at 10 ms, from bouncing on an undamped contact. It is not a setting for anything that relies on friction.

## What it means for the finding

F3 stands with this added. Neither MuJoCo's cone, noslip, `impratio`, nor any `solref` or `solimp` value its
documentation gives removes the lift without a cost of its own. Those that keep the cube at the ground either let it
ride into the ground and slide up to 8% too far (`solimp[0]` = 0), or remove friction altogether (the direct example).

Coulomb's distance, v^2 / (2 mu g), for the slides played: 45,918 um at 0.6 m/s and 183,673 um at 1.2 m/s with
friction 0.4, 734,694 um at 2.4 m/s; 734,694 um at friction 0.1 and 91,837 um at 0.8, both at 1.2 m/s.
