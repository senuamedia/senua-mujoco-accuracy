# Run 101: noslip moving the normal force as MuJoCo's PGS does, the design's second version

17 October 2026 (13:24 to 13:38 UTC). Not registered: a design probe on the first cloud machine, pushed before its
plays ([`probe.sh`](probe.sh)), with its plumbing run first ([`dry/`](dry/)). It finds where to look and decides nothing.
Its readings, solver statistics and MuJoCo's suite results are kept, the free cubes' plays and traces compressed.

## Why

[Run 098](../run_098_noslip_normal/README.md)'s design, noslip's pass re-solving each contact's normal row alone before
its friction, held every free cube but left stacks offset 5 mm a cube turning faster than the set alone.

## The design

[`patches/in_design/noslip_normal_v2.diff`](../../patches/in_design/noslip_normal_v2.diff) (sha256 `94f6524d23edbe76`;
the same switch, off unless `MUJOCO_NOSLIP_NORMAL=1`; 55 lines added, none removed), applied after Senua AI's six
validated patch files: noslip's pass moves each elliptic contact's force as MuJoCo's own PGS moves an elliptic contact,
first a ray update (the whole force scaled along itself, so it stays in the cone), then the friction with the normal
fixed; in the ray update the normal row keeps its regularization and the friction rows go without theirs. Pyramidal
contacts are unchanged. Built with its tests (p101, [`patch_check.txt`](patch_check.txt)); set6: the six switches,
setn: the six and this one, under the configuration (the elliptic cone, 100 noslip iterations).

## What it found

**Every free cube holds.** Study 20's two cubes, condim 3, 4 and 6, pushed along 0 degrees at 0.5, 0.75 and 0.95 of
the limit and along 45 degrees at 0.95, at 1.277 ms and a quarter of it, 48 plays in each arm
([`reading_free.txt`](reading_free.txt)): set6 creeps up to 1,124 um/s (Study 20's H1 failure, at 0.95 along 0), setn
at most 2 um/s. The traced cube (b, condim 3, 1.277 ms, 0.95 along 0) tilts at most 1,328 urad with four contacts on
every step, where in set6 it rocks up to 3,842 urad and has fewer than four contacts on 30 steps.

**The offset stacks: as the first version, better at 1 mm, worse at 5 mm.** The fastest any cube of a stack of three
turns at the end, urad/s, over run 078's and Study 16's cubes, 1.14 and 0.285 ms, 2, 4 and 6 s
([`reading_stacks.txt`](reading_stacks.txt)):

| Offset | set6 | setn | set6 at 6 s | setn at 6 s |
|---|---|---|---|---|
| 1 mm | 38 to 31,538 | 1 to 2,031 | 38 to 10,307 | 1 to 69 |
| 5 mm | 8 to 85 | 2,300 to 41,110 | 8 to 11 | 5,486 to 16,828 |
| 17 mm | 21 to 217 | 16 to 73 | 21 to 27 | 16 to 23 |

- The 17 mm stacks lean less with the design (5.2 to 6.1 mrad, against 7.0 to 8.1), as with the first version.
- The solver: at most 61 iterations a step with the design (21 without), none at 100.

**The set's other plays** ([`reading_set.txt`](reading_set.txt)): Study 15's arm set down and dropped in two poses,
the cube Study 19 held at 0.5 and 0.95, MuJoCo's box and Study 19's box 1, the same readings (0 um/s, boxes at rest);
Study 15's grip creeps up to 3 um/s with the design (1 without). **Safe when off**: the set's 12 play files at 1.71 ms
and their statistics the same bytes in Study 22's build and in p101 with the six switches
([`identity.txt`](identity.txt)). **MuJoCo's suite**: with the design set, the same results as without it, the one
failure `SolverTest.ZeroToleranceDisablesTermination`, as in Study 21
([`suite_set6_against_setn.txt`](suite_set6_against_setn.txt) is empty).

## What it means

- Moving the normal force in noslip's pass as MuJoCo's PGS does holds the free cube, as the first version did, and
  like it leaves stacks offset 5 mm turning far faster than the set alone.
- Not carried further: [runs 103](../run_103_impratio_without_noslip/README.md) to
  [105](../run_105_no_noslip/README.md) found configurations, MuJoCo's own options, that hold the free cube and bring
  every offset stack to rest without changing MuJoCo's code.
