# Study 23: impratio and the stiffest contact, with noslip and without it

| | |
|---|---|
| Question | On fresh numbers, in Senua AI's set, do two configurations of MuJoCo's own options answer the three issues noslip leaves? hold: impratio 1,000 and every contact's time constant at twice the step, with noslip. inverse: the same, every joint's friction as stiff, and no noslip. Does each hold the free cube near its limit (issue 1), keep stacks from sinking past 100 um, leaning past 1 mrad or turning (issue 9), keep everything the set holds, and, without noslip, agree with inverse dynamics, creep by soft friction's law and keep the joint equality (issue 14)? |
| Outcome | **49 of 49 rule lines held.** Issues 1, 9 and 14 fixed and validated by configuration. Senua AI's configuration in two forms: hold, friction exact under any load; inverse, inverse dynamics exact and friction soft by a measured law. |
| Registered | [`PREREGISTRATION_23.md`](../../preregistrations/PREREGISTRATION_23.md), pushed with its runner, dry run and rules plumbing check on 17 October 2026, before any play |
| Played | Once, as [run 106](../../validation/run_106_study_23/README.md), 17 October 2026, 14:12 to 14:16 UTC, on Linux (the first cloud machine) |
| Arms | Senua AI's set (six validated patch files, every switch set) under three configurations: set (the elliptic cone, 100 noslip iterations), hold, inverse |
| Measured by | Senua AI's measure as in Study 22 (`final`, `gap`, `creep`, `fastest`, `stop`), MuJoCo's own fwdinv statistics, file comparison, judged by the Senua AI Robotics Core's `rule`; held to [Coulomb's law](../references.md#coulomb), [Popov 2010](../references.md#popov); the soft constraint and its time constant, [Todorov 2014](../references.md#todorov-2014); inverse dynamics, [Featherstone 2008](../references.md#featherstone) |

## Why it was asked

Noslip holds friction exactly, and three issues remained with it: a free cube near its limit rocks and creeps (Study
20), a stack sinks at every contact and an offset stack leans and keeps turning (runs 026, 078, 093), and inverse
dynamics cannot agree with hard friction (run 094). Two designs that change noslip's pass held the free cube and left
offset stacks turning (runs 098, 101). The probes then found MuJoCo's own options answer all three: impratio at 1,000
holds every contact without noslip (run 103); a contact's depth falls with the square of its time constant, and at
twice the step offset stacks come to rest (run 102); together, with or without noslip (runs 104, 105). Without noslip
friction is soft, and run 105 found the law it creeps by. Each needed fresh numbers and registered rules.

## What it found

| Group | Reading | Rules |
|---|---|---|
| 1 | In the set, a free cube pushed along 0 at 0.95 of its limit creeps 1,296 to 1,500 um/s (the case, on a fresh cube); in hold every free cube creeps 0 um/s, in inverse at most 1, condim 3, 4 and 6, every direction and load, both steps | 3 of 3 |
| 9 | In the set a stack's contacts sink 207 to 901 um and offset stacks lean up to 5.4 mrad and turn up to 239 urad/s; in hold and in inverse every contact sinks at most 10.8 um, every lean is at most 47 urad and every offset stack is at rest | 8 of 8 |
| 14 | Inverse dynamics differs from the forward step by up to 9.6 N on the free cubes and 34,723 N in the equality scenes with noslip, and by under 1 nN without it (inverse). Without noslip a joint's friction creeps by the law, (1 - I) dt a, within 0.05 per cent: 1.783 um/s under gravity's load, 5.9 and 6.3 mm/s under #2430's 33 and 35 km/s^2; the equality kept (gaps 0 held, 579 um loaded as in the set); the held arms at 1 to 7 um/s; the solver never at its limit. hold changes nothing where there is no contact | 14 of 14 |
| The set's plays | In hold and in inverse every arm of Studies 10, 13, 14 and 15 rests at 0 um/s, the grip holds, the boxes rest, and a slide is Coulomb's distance less half a step's travel to 1 um, where the set goes 248 to 256 um further | 20 of 20 |
| All | The rigs make Study 22's bytes (81 of 81 files), every play measured, no warning, no step at the iteration limit outside the equality plays | 4 of 4 |

## What it decides

- **Issue 1 fixed and validated**: its last case, the free cube near its limit, by configuration, hold or inverse.
- **Issue 9 fixed and validated by configuration**: a contact's time constant at twice the step, the stiffest MuJoCo's
  own guard allows; every contact at most 10.8 um deep where it sank 901, leans of at most 47 urad, every offset stack
  at rest.
- **Issue 14 fixed and validated**: the joint equality by Senua AI's patch (Study 22); the many-contact cost by hold;
  inverse dynamics by inverse, with soft friction's law as its stated limit. With noslip, inverse dynamics stays
  impossible, MuJoCo's documented limit of hard friction.
- **Senua AI's configuration in two forms**: hold, for friction exact under any load; inverse, for inverse dynamics,
  with friction creeping at (1 - I) dt a: under 2 um/s at gravity's load up to a 2 ms step.
- Not decided: a bounce (a contact the model authors with its own solref), issue 18, anything against a real robot.
