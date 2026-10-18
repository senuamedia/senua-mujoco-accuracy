# Run 042: the tenth registered study, played once

Played 15 October 2026 (21:49 to 22:00 UTC, `played_at.txt`, `progress.txt`) on the first cloud machine, changed for
this study to 4 virtual CPUs and 8 GB, by [`play.sh`](play.sh), under
[`preregistrations/PREREGISTRATION_10.md`](../../preregistrations/PREREGISTRATION_10.md), pushed before any play. MuJoCo's
recommended configuration (the elliptic cone with 10 noslip iterations) with the inverse weight in the current pose, third
version (`patches/invweight_at_pose_v3.diff`, `patch_check.txt`), rebuilt by the runner from the registered patch file,
its switch set, under MuJoCo's default integrator (`config`) and under RK4 (`config_rk4`); beside them the release under
MuJoCo's defaults and under the configuration's options, and the patched build with the switch unset under each. The
numbers are drawn from seed 10 (`draw.txt`, `parameters.txt`). Every measured number is in `measured.txt`, every rule's
line in `rules.txt`. The dry run (`dry/`, the two release arms, throwaway numbers) ran to the end; no rule was read from
it.

**The result: 290 of 298 rule lines held: the 32 shared, 127 of 133 under the default integrator and 131 of 133 under
RK4. The configuration is not validated end to end under either. The third version is validated under the
configuration with both integrators, and Study 2's contact result is replicated under the default integrator.**

## Shared: 32 of 32

| Rule | Measured | |
|---|---|---|
| Q1 to Q3, the release's defects | Under MuJoCo's defaults the hold at 0.5 creeps 581 um/s; the slide along 45 degrees goes 188,261 um against 133,031 along 0 (42% further); the first suite's hold (T06) fails | held |
| Q4, the written pose (24 lines) | Released, the straight writing ends apart from the native: on contact 8.4 to 47.3 um, on a joint limit 39.6 to 181.5 um, held by joint friction 20.8 to 21.0 mm, by a `connect` 85 to 98 um, by a `weld` 66 to 85 um | held |
| E1, safe when off, plays | 261 of 261 files byte-identical to the release under MuJoCo's defaults, and 261 of 261 under the configuration's options | held |
| E2, safe when off, MuJoCo's suite | Switch unset: every test as released; all 3,492 passed in all three arms | held |
| N1, nothing else changes, plays | Switch set: 188 of 188 cube, suite and tumbling-body files byte-identical to the release under the same options | held |
| N2, nothing else changes, MuJoCo's suite | Switch set against unset: no test changes | held |

## Each configuration arm

| Rules | Default integrator (`config`) | RK4 (`config_rk4`) |
|---|---|---|
| H1, every hold holds (18) | Every hold 0 um/s | Every hold 0 um/s |
| G1, the grip holds (4) | 0 or 1 um/s, box and mesh pads, centred and 9.3 mm off | The same |
| S1, S2, no direction, no drift | Along 0, 22.5 and 45 degrees the same distance to the micrometre at both steps, 0 um drift | The same |
| S3, Coulomb | 133,471 um at the fine step against 133,451 (1.5 in 10,000) | 133,461 um |
| S4, the free cube | **Failed**: slid free to turn along 22.5 degrees, 136,043 um against 133,042 along 0, 2.3% further; along 45 degrees 133,266; the drift line held (231 um) | **Failed**: 134,897 against 133,051, 1.4% further; the drift line held (590 um) |
| K1, the ten tests | 10 of 10 | **Failed: 9 of 10** (T01, see below) |
| A4, A5, the written pose (96) | Every writing **0 nm and 0 um/s** from the native, on contact, on the limit, held by joint friction, by a `connect` and by a `weld` | The same |
| A6, the creep alike (16) | The same creep in every writing: on contact 713 and 11 um/s in the two poses, held by joint friction 93 and 25 um/s | The same |
| V1, V2, the solver | No step at the iteration limit, no warning; on the holds, the slides and the suites at most 5 iterations against the release's 4 under its defaults | The same |
| T1, T2, the tumbling body (8) | **Failed 5 of 8**: energy +5,027 and +1,254 per million at 10 and 2.5 ms (bounds 5,000 and 1,000), held at 0.625 and 0.156 ms (313 and 78); angular momentum +2,421, +604 and +150 at 10, 2.5 and 0.625 ms (bound 100), held at 0.156 ms (37) | 0 at every step |
| Lines held | **127 of 133** | **131 of 133** |

Reported, not ruled: the most iterations over every play, 12 (default integrator) and 15 (RK4), against the release's 7
under its defaults and 12 under the configuration's options, from the arm and the free cube.

## What the decisions record

- **The recommended configuration is not validated end to end**, under the default integrator (6 lines failed: the
  tumbling body's five and the free cube) or under RK4 (2: the free cube and the ten tests).
- **The third version is validated under the configuration, with both integrators**: Q4, E1, E2, N1, N2, A4 to A6 and V1
  all held.
- **Study 2's contact result is replicated on fresh numbers under the default integrator**: Q1 to Q3, H1, S1 to S3, K1
  and V2 held. Under RK4 it is not, as K1 failed.
- The failed lines are recorded as measured, and what they concern stays open.

## On the lines that failed

- **The tumbling body under the default integrator** gains energy and angular momentum at first order in the step, as
  Study 9 found (known issue M10, finding F4); RK4 keeps both at every step.
- **The free cube** slid along 22.5 degrees goes 2.3% (default integrator) or 1.4% (RK4) further than along 0 or 45. The
  release under the same options plays the same file byte for byte (N1), so it is MuJoCo's under its elliptic cone, not
  the patch's; under MuJoCo's defaults it goes 20% further and drifts 34.8 mm. Its cause has not been traced; it is a new
  finding, open.
- **The ten tests under RK4**: only T01 fails, a cube in free flight, whose test reads each gap between step sizes as a
  share of the gap before (right answer 5,000 per 10,000, a first-order integrator's). Under RK4 free flight under
  gravity is exact at every step, so every gap is 0 and the share cannot be read (-1). The rule failed as registered.
  On these numbers RK4's refinement chain (T08) passed, where in run 014 it went out of order.

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 133,031 um | 133,048 um |
| 133,042 um | 133,058 um |
| 133,051 um | 133,066 um |
| 133,051 um | 133,068 um |
| 133,266 um | 133,286 um |
| 133,461 um | 133,482 um |
| 133,471 um | 133,493 um |
| 133,471 um | 133,494 um |
| 134,897 um | 134,914 um |
| 136,043 um | 136,058 um |
| 188,261 um | 188,284 um |

Every rule line of the study whose inputs the correction changes was judged again by `sx_contact rule` with the
corrected readings ([`rejudge.txt`](../audit/measure_correction/rejudge.txt)): no verdict changes.
