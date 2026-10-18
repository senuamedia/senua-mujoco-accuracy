# Run 011: a patch in design, the friction pyramid turned along the slip

15 October 2026. Not registered: a patch in design, checked against the five checks before any study registers its
rules. Played on run 002's Linux machine by [`play.sh`](play.sh).

## The patch

[`patches/in_design/slip_aligned_pyramid.diff`](../../patches/in_design/slip_aligned_pyramid.diff) (sha256
eeb0118d675d0435...), 25 lines added to `src/engine/engine_core_constraint.c` of MuJoCo 3.16.0 at the commit in
`UPSTREAM_COMMIT`, in `mj_instantiateContact`. MuJoCo's default cone is a pyramid whose edges lie along the contact
frame's two tangents, so the friction it can give is a diamond, |f1| + |f2| <= mu N (runs 003, 005). With the switch on
(`MUJOCO_SLIP_ALIGNED_PYRAMID=1`), each pyramidal contact that is slipping has its two tangents turned about its normal
so the first lies along the slip, where the pyramid reaches mu N; the slip is the contact's relative velocity at that
moment, its Jacobian difference times `qvel`. A contact that is not slipping keeps the frame collision gave it. With
the switch unset nothing runs. MuJoCo was built from the patched source as in run 004 (the same compiler, options and
build files; both builds log the same 91 warnings, none from the patched file).

## The five checks

Three arms, each in its own scratch copy of the repository: the release (Google DeepMind's Linux build), the patched
build with the switch unset ("off"), the patched build with it on ("on"); each played run 003's probe, run 005's probe
and both of the first deep dive's contact suites under MuJoCo's defaults (`release/`, `off/`, `on/`).

**1. Required.** Runs 003 and 005 measured the direction the default cone gives friction.

**2. Correct.** With the switch on:

| | Release | On | Right answer |
|---|---|---|---|
| Slide along 0, 22.5, 45 degrees, 2 ms (um) | 126,717, 151,762, 179,492 | 126,717, 126,717, 126,717 | the same along every direction |
| The same at 1/16 of 2 ms | 127,655, 152,708, 180,420 | 127,655, 127,655, 127,655 | the same |
| Drift across the line along 22.5 degrees | 33,852 um | 0 | 0 |
| Hold along 45 degrees at 0.72 and 0.8 of the limit (creep, um/s) | 63,438 and 455,607: slides | 1,875 and 2,263 | as along x: 1,875 and 2,263 |
| Hold along 22.5 degrees at 0.8, 0.85, 0.9 (creep, um/s) | 148,461 to 577,163: slides | 2,263, 2,505, 2,748 | it holds; along x at 0.8: 2,263 |
| The same: across the push | up to 225,362 um | at most 4 um | 0 |
| A cube free to turn, slide along 0, 22.5, 45 degrees (um) | 126,772, 152,658, 179,485 | 126,772, 126,906, 127,130 | the same |
| The same: drift along 22.5 degrees | 31,874 um | 188 um | 0 |

With the switch on, a level cube slides and holds exactly as it does along x, whatever the direction. A cube free
to turn comes within 0.3% of its distance along x, with 0.19 mm of drift left where there were 32 mm.

**3. Nothing else gets worse.** Every other reading of runs 003 and 005 is unchanged, and every play of both contact
suites is byte-identical with the switch on: those slide along x, where the frame turned along the slip is the frame
collision gave. The ten-test suite still passes 9 of 10: the creep at rest (T06) is not what this patch addresses.

**4. Safe when off.** The patched build with the switch unset plays all 146 files byte for byte as the release does
(`identity_off.txt`).

**5. The solver keeps converging.** With the switch on, as in the release: at most 6 iterations on any step, never at
the iteration limit, no warning.

## What it shows

A 25-line change removes the direction MuJoCo's default friction cone gives friction, at no cost to anything else this
record plays, and changes nothing when it is off. It does not touch the creep at rest (run 001), which the elliptic
cone with noslip removes. The patch stays in design until a registered study states its rules and plays it once.

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 126,717 um | 126,732 um |
| 126,772 um | 126,791 um |
| 126,906 um | 126,926 um |
| 127,130 um | 127,146 um |
| 127,655 um | 127,681 um |
| 151,762 um | 151,782 um |
| 152,658 um | 152,680 um |
| 152,708 um | 152,739 um |
| 179,485 um | 179,505 um |
| 179,492 um | 179,513 um |
| 180,420 um | 180,454 um |

What this page concludes does not change: the largest of these corrections is 0.02%.
