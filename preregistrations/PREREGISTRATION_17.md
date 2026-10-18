# Seventeenth pre-registration: MuJoCo's own frictionless contact, condim 1

Registered 17 October 2026, after runs 008 and 009. Registered before any play of this registration existed. To be
played once, as run 080.

## The question

Issue 12 of [the issue list](../docs/issues.md) (F7): a friction of 0 is raised to 1e-5. MuJoCo raises any friction
below 1e-5 to 1e-5 under its default contact, condim 3 (`mjMINMU`, `engine_core_constraint.c`). So a "frictionless"
ground in run 008 took 1,250 ppm of two cubes' momentum: exactly 1e-5 of their weight over the play (run 009). MuJoCo's
documented way to a frictionless contact is a normal-only contact, condim 1. In run 009 the two cubes then kept their
momentum to within the rounding of the files. That was a probe, on one scene.

On numbers no earlier study or probe used, under MuJoCo's defaults and under Senua AI's configuration: does a cube set
sliding on a condim-1 contact keep its speed and its line and stay on the ground, along every direction played, kept
from turning and free to turn? And does the same cube on a condim-3 ground of friction 0 lose speed to MuJoCo's least
friction, as the issue says?

## Engine and arms

- **rel_def**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
  139577c541d43716...), under MuJoCo's defaults.
- **rel_rec**: the same, under Senua AI's configuration (`cone=elliptic`, `noslip_iterations=100`).

No build and no patch: the question is about MuJoCo's own option. Played on the first cloud machine (AWS EC2
c7i.xlarge, Intel, 4 virtual CPUs, 8 GB).

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_080_study_17/play.sh`](../validation/run_080_study_17/play.sh) | 13220b628db1318e... |
| Rig | `tools/mjc_contact.c` (`condim`, `dir`, `lock`, as in Studies 10 to 16), `tools/build_rig.sh` | 31ea6cc56a204143..., b6a93676e6aee763... |
| Senua AI's measures | `sx_contact` (`hover`, `rule`), as run in Studies 10 to 16 | source 87e921cd4d2c03bf... (built for Linux: f09ea027cec7820d...) |

## The numbers, and how they were drawn

By Study 10's procedure, from x(0) = 17, on Study 10's ranges for the cube held and slid. A value the record already used
for a quantity of the same kind was drawn again: Study 16's lists, the values Study 16 drew, the settings of runs 077 to
079, and any value this draw had already given that kind. None was redrawn.
`DRAW=1 bash validation/run_080_study_17/play.sh` prints the draw.

| What | The numbers |
|---|---|
| The steps | 1.74 ms, and a quarter of it, 0.435 ms |
| The cube | 1.505 kg, half-size 0.0437 m, set sliding at 0.91 m/s |

Not drawn: the directions (0, 22.5 and 45 degrees), the play's length (2 s) and the ground's friction (0).

## The scenes

Each arm, at both steps, along each direction, kept from turning and free to turn: the cube set sliding on the ground,
2 s, once with condim 3 and once with condim 1 (24 plays an arm).

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. A slide's lost speed is its speed at the
start less its speed at the last step, from the rig's file (um/s). Its drift is the rig's `side_um`, how far it ends off
its line. Its height is `sx_contact hover`'s highest point of the cube's lowest face above the ground.

| Rule | Statement | From |
|---|---|---|
| Q1 the least friction slows it | Each arm: every condim-3 slide loses at least 98 um/s, half the 196 um/s that a friction of 1e-5 takes in 2 s (1e-5 times g times the time) (2 lines) | runs 008, 009 |
| F1 it keeps its speed | Each arm: every condim-1 slide loses at most 1 um/s, the rig's rounding (2 lines) | run 009 |
| F2 it keeps its line | Each arm: every condim-1 slide ends at most 1 um off its line (2 lines) | Study 12's D2, tighter |
| F3 it stays on the ground | Each arm: no condim-1 slide rises more than 1 um (2 lines) | Study 12's L1 |
| V1 the solver | Each arm: no step at the iteration limit; no warning (4 lines) | Studies 5 to 16 |

There are 12 rule lines. Reported, not ruled: how much each condim-3 slide loses along each direction, and how far it
drifts.

## The decisions

- **Issue 12, a friction of 0 is raised to 1e-5**: if every rule holds, it is recorded as **fixed and validated by
  configuration**: a frictionless contact is MuJoCo's own condim 1, under MuJoCo's defaults and under Senua AI's
  configuration. A friction of 0 under condim 3 stays 1e-5, by MuJoCo's design, and the record says so.
- A rule that fails is recorded as measured, with its numbers, and the issue stays open.
- Not decided: condim 1 between two moving bodies (run 009, a probe); the patches' arms; anything against a real robot.

## Known risks, stated before the run

- **F1**: a condim-1 contact has no friction rows, so nothing acts along the ground. A slide could still lose speed if
  the cube tipped onto an edge, which condim 1 does not resist by friction. The cube is set down flat and slid level.
- **Q1**: the slide must last the whole play. At 0.91 m/s for 2 s it covers 1.8 m on an unbounded plane.

## What is not asked

Everything listed as not decided above.

## Dry run

`DRY=1` played both arms on throwaway numbers (run 063's cube, at 1.14 and 0.285 ms) to the end: 50 measured lines,
none empty ([`validation/run_080_study_17/dry/`](../validation/run_080_study_17/dry/)). The rules were then judged on its
lines in a scratch copy ([`dry/rules_plumbing.sh`](../validation/run_080_study_17/dry/rules_plumbing.sh)): 12 rule lines,
each judged. Judged again with one condim-1 slide's lost speed changed by hand to 5 um/s, F1 failed as it should
([`dry/rules_plumbing.txt`](../validation/run_080_study_17/dry/rules_plumbing.txt)). No rule is read from the dry run.
