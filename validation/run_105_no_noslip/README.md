# Run 105: no noslip, joint friction made stiff by its own reference

17 October 2026 (13:42 to 13:43 UTC). Not registered: a design probe on the second cloud machine, pushed before its
plays ([`probe.sh`](probe.sh)). It finds where to look and decides nothing. Its readings and solver statistics are kept.

## Why

[Run 104](../run_104_impratio_and_time_constant/README.md): without noslip, impratio 1,000 and the stiffer contact
held every contact and inverse dynamics agreed, but joint friction fell; with noslip, everything held and inverse
dynamics could not agree. Joint friction has its own reference and impedance in MuJoCo, each joint's solreffriction
and solimpfriction, and its creep falls in proportion to the time constant ([run
052](../run_052_joint_friction_and_tolerance/README.md)).

## The settings

The arm and scene rigs gain `jsolref=T,D` and `jsolimp=I` (every joint's solreffriction, and the first two numbers of
its solimpfriction, set after the scene is loaded) and `fwdinv=1` (MuJoCo's flag; the STATS line then adds the largest
difference over the play). Unset, the rigs as they were ([`before/`](before/)) and as they are give the same bytes
([`identity.txt`](identity.txt)). In Senua AI's set (six validated patch files, every switch set,
[`patch_check.txt`](patch_check.txt)), three configurations, all under the elliptic cone: set (100 noslip
iterations); impnstc (run 104's: noslip, impratio 1,000, every geom's solref twice the step); nons (impratio 1,000,
every geom's solref and every joint's solreffriction twice the step with damping ratio 1, every joint's
solimpfriction 0.9999, MuJoCo's largest, and no noslip).

## What it found

Creep, um/s ([`reading.txt`](reading.txt)):

| Play | set | impnstc | nons |
|---|---|---|---|
| Study 20's free cubes a and b, 0.95 of the limit | 173 to 1,098 | 0 | 0 |
| The cube Study 19 held; Study 15's arm set down and dropped | 0 | 0 | 0 |
| Study 15's arm held by joint friction (5.15 N m), two poses, 1.71 / 0.4275 ms | 3 and 6 / 3 and 6 | 3 and 6 / 3 and 6 | 4 and 7 / 1 and 2 |
| Study 15's grip, box and mesh pads | 0 to 1 | 0 | 0 to 1 |
| Study 22's arm with a weld or a connect at its tip, joint friction 8 N m | 0 | 0 | 3 to 6 |
| MuJoCo's box, the fastest over its last 160 steps | 0 | 0 | 0 |

Run 093's offset stacks, a stack of ten and Study 13's slides read as in run 104, the same under nons as under
impnstc: every stack at rest, leaning 6, 34 and 145 urad at offsets of 1, 5 and 17 mm, the deepest contact of ten
25,523 nm, the slides Coulomb's distance less the integrator's half step, to 1 and 2 um.

**Study 22's joint equality scenes** (a body held by its joint's friction, coupled by an equality to another; 1 s at
their own step, 0.957 ms): the held body's travel, nm, and the largest gap between the two, um:

| Scene | set and impnstc: travel, gap | nons: travel, gap |
|---|---|---|
| Held 1, 2 and 3 | 0, 0 | 938, 0 |
| After issue 2430, 1 and 2 | 0, 0 | 1,637,407 and 4,128,589, 3 and 7 |
| Loaded 1 and 2 (the coupling carries a load) | 0, 581 | 938, 581 |

- Issue 2430's scenes drive a 1 kg body with 17,108 N, about 870 g. Without noslip, friction is soft: it creeps in
  proportion to its load, and at that load the held body creeps 1.6 and 4.1 mm/s. At gravity's load it creeps 1 to 7
  um/s here.

**Inverse dynamics** ([`stats.txt`](stats.txt), MuJoCo's fwdinv): the largest difference between the forward step's
constraint force and inverse dynamics', N:

| Plays | set | impnstc | nons |
|---|---|---|---|
| The free cubes | 9.36 | 8.95 | 1.2e-11 |
| The held cube | 6.37 | 6.37 | 9.9e-14 |
| The arm, all its plays | 4.79 | 96.1 | 6.6e-5 |
| The equality scenes | 43,138 | 43,138 | 1.5e-11 |

The solver: with noslip, 1,423 steps at its limit in the equality scenes and on one step of each tip-equality arm
play, as in Study 22; without it, at most 49 iterations a step, none at the limit. No warnings.

## What it means

- Without noslip (nons), every play here holds under the bound but one, inverse dynamics agrees to 1e-11 N, and
  noslip's costs go with it: the many-contact instability, the broken equality, the iteration limit. The exception is
  friction under an extreme load: soft friction creeps in proportion to it, about 1e-4 of the step times the load's
  acceleration, and issue 2430's 870 g load creeps by millimetres a second.
- With noslip (impnstc), friction holds whatever the load, and inverse dynamics cannot agree: MuJoCo's documented
  limit of hard friction.
- Two configurations, then, one for each use, both to be registered and played over the whole set before any claim.
