# Run 106: Study 23, impratio and the stiffest contact, with noslip and without it

17 October 2026 (14:12 to 14:16 UTC), on the first cloud machine. The twenty-third registered study
([`PREREGISTRATION_23.md`](../../preregistrations/PREREGISTRATION_23.md), registered in commit 7f644d3 before any play),
played once by [`play.sh`](play.sh) (sha256 `6c9fc8dc1d9f18d2`), its dry run and rules plumbing check in [`dry/`](dry/).
Every play file, measured line, rule line and solver statistic is kept, the play files compressed.

**Outcome: 49 of 49 rule lines held** ([`rules.txt`](rules.txt)).

## The arms

All in Senua AI's set (MuJoCo built from its source with its six validated patch files, every switch set,
[`patch_check.txt`](patch_check.txt)), every option MuJoCo's own:

- **set**: the configuration as validated, the elliptic cone with 100 noslip iterations;
- **hold**: and impratio 1,000, and every geom's solref at twice the step with damping ratio 1;
- **inverse**: the elliptic cone, impratio 1,000, every geom's solref and every joint's solreffriction at twice the step
  with damping ratio 1, every joint's solimpfriction 0.9999, and no noslip.

## The numbers

Drawn from seed 23 ([`draw.txt`](draw.txt), [`parameters.txt`](parameters.txt)): group 1 at 1.729 ms and a quarter of
it, cubes of 1.369 and 1.059 kg, half-sizes 0.0387 and 0.0382 m, frictions 0.567 and 0.873; group 9 at 0.741 ms and a
quarter, a cube of 0.677 kg, 0.054 m, 0.646, offsets of 0.057, 0.123 and 0.395 of its half-size; group 14 at 1.819 ms,
held bodies of 131.88, 48.302 and 497.338 kg at 1.975, 1.5 and 2.821 times their weight, 58,361 N pushed by 0.558 and
88,578 N by 0.392, loads at 2.355 and 2.42 times, the arm's joint friction 4.315 N m; the slides at 0.619 ms and a
quarter, a cube of 1.646 kg, 0.0258 m, friction 0.522, at 0.537 m/s.

## What the rules read ([`measured.txt`](measured.txt))

**Group 1, issue 1's free cube**, 72 plays an arm (two cubes, condim 3, 4 and 6, along 0 and 45 degrees at 0.5, 0.75
and 0.95 of the limit, two steps):

| | set | hold | inverse |
|---|---|---|---|
| Pushed along 0 at 0.95 | cube b 1,296 to 1,500 um/s (all three condims, both steps); cube a 0 | 0 | at most 1 |
| Every play | up to 1,500 um/s | 0 | at most 1 um/s |

**Group 9, issue 9's stacks:**

| | set | hold | inverse |
|---|---|---|---|
| Straight stacks of 3, 5 and 10: every contact's depth | 207 to 901 um | 0.075 to 10.8 um | the same |
| Stacks offset three ways, 6 s: the largest lean | 5,359 urad | 47 urad | the same |
| The same: the fastest turn at the end | up to 239 urad/s | 0 | 0 |

**Group 14, noslip's costs:**

| | set | hold | inverse |
|---|---|---|---|
| Inverse dynamics against the forward step, the free cubes | 3.8 to 9.6 N | 3.8 to 8.7 N | under 1 nN (0 in whole nanonewtons) |
| The same, the equality scenes and the arms held by joint friction | up to 34,723 N | up to 34,723 N | under 1 nN |
| A body held by joint friction under gravity's load, travel over 1 s | 0 | 0 | 1,783 nm in each, the law's 1,783 |
| After #2430, a 32,565 N and a 34,723 N push on 1 kg | 0 | 0 | 5,926,318 and 6,318,878 nm, the law's 5,923,653 and 6,316,037 |
| The coupling's gap: held scenes / after #2430 / loads | 0 / 0 / 579 um | the same | 0 / 10 / 579 um |
| The arms held by joint friction, with and without a tip weld or connect | 0 to 6 um/s | the same | 1 to 7 um/s |
| The solver in the equality plays | at its limit on 1,423 steps | the same | at most 2 iterations a step |

- Soft friction's law, (1 - I) dt a: without noslip a joint's friction creeps in proportion to its load, the held
  bodies at 1.783 um/s whatever their mass, the bodies after #2430, pushed at 32,565 and 34,723 m/s^2, at 5.9 and 6.3
  mm/s; the law within 0.05 per cent.
- hold's group-14 play files are byte-identical to set's, 22 of 22: impratio and a contact's time constant change
  nothing where there is no contact.

**The set's own plays**: Study 21's arms of Studies 10, 13, 14 and 15 set down and dropped (48), at 0 um/s in every
arm; Study 15's grip at most 1 um/s; the cube Study 19 held, 0; MuJoCo's box and Study 19's six at rest. The slides,
against Coulomb's distance less half a step's travel (28,019 and 28,144 um):

| Step | set | hold | inverse |
|---|---|---|---|
| 0.619 ms | 28,267 um, 248 long | 28,019, exact | 28,019, exact |
| 0.155 ms | 28,400 um, 256 long | 28,143, 1 short | 28,143, 1 short |

The same along 0, 22.5 and 45 degrees. Under MuJoCo's time constant the cube settles into its contact as it slides and
goes further.

**Every arm**: the rigs make the bytes Study 22's rigs make, 81 play files of 81 (E1); all 339 readings in every arm
(P0); no warning in any play; the solver at most 64 iterations a step outside the equality plays, none at the limit.

## What it decides

- **Group 1**: issue 1's last case, the free cube near its limit, is fixed and validated by configuration, in hold and
  in inverse. Issue 1 is fixed and validated.
- **Group 9**: issue 9 is fixed and validated by configuration, in hold and in inverse: every contact at most 100 um
  deep (at most 10.8 um here), every lean at most 1 mrad (47 urad), every offset stack at rest.
- **Group 14**: inverse is validated as the configuration for inverse dynamics, with soft friction's law as its stated
  limit, and noslip's many-contact cost is fixed and validated by configuration in hold. With the joint equality
  (Study 22), issue 14 is fixed and validated. Inverse dynamics under noslip stays MuJoCo's documented limit of hard
  friction.
- **The set's own plays**: both configurations keep them.
- Senua AI's configuration is recorded in two forms: hold, friction exact under any load; inverse, inverse dynamics
  exact and friction soft by the law.
