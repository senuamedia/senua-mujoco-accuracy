# Run 098: noslip re-solving the normal forces, a design for its multi-contact instability

17 October 2026 (09:34 to 09:51 UTC). Not registered: a design probe on the first cloud machine, in two steps, each
pushed before its plays: [`probe.sh`](probe.sh), with its plumbing run first ([`dry/`](dry/)), and
[`probe_2.sh`](probe_2.sh), written after step 1's readings. It finds where to look and decides nothing. Its readings,
solver statistics and MuJoCo's suite results are kept, the free cubes' plays and the trace compressed.

## Why

In Senua AI's set, a free cube pushed square to a face near its friction limit rocks on its front edge and slips each
swing (run 096, issue 1's open case), and stacks offset 1 or 5 mm a cube keep turning (run 093, issue 9). Without noslip
neither rocks. Noslip re-solves the friction with every normal force held as the main solver left it, and a body's
balance in pitch rests on both.

## The design

[`patches/in_design/noslip_normal.diff`](../../patches/in_design/noslip_normal.diff) (sha256 `17138dad91cc093e`; off
unless `MUJOCO_NOSLIP_NORMAL=1`; 32 lines added, none removed), applied after Senua AI's five validated patch files:
noslip's pass, at each elliptic contact, first re-solves the normal row as MuJoCo's PGS solves a scalar row (its
regularization kept, held at zero or above), given the friction as it stands, then solves the contact's friction in the
cone the new normal force gives. Pyramidal contacts are unchanged. Built with its tests (p98,
[`patch_check.txt`](patch_check.txt)); set5: the five switches, setn: the five and this one, under the configuration
(the elliptic cone, 100 noslip iterations).

## What it found

**Every free cube holds.** Study 20's two cubes, condim 3, 4 and 6, pushed along 0 degrees at 0.95 of the limit
([`reading_free.txt`](reading_free.txt)), creep in um/s (its size; the design's are backward):

| | set5, 1.277 ms | set5, 0.319 ms | setn, both steps |
|---|---|---|---|
| Cube a (1.572 kg), condim 3 / 4 / 6 | 613 / 698 / 699 | 173 / 299 / 299 | 2 / 0 / 0 |
| Cube b (0.819 kg), condim 3 / 4 / 6 | 1,098 / 1,124 / 1,124 | 482 / 763 / 763 | 1 / 0 / 0 |

- The set's numbers are Study 20's H1 failure, 173 to 1,124 um/s. With the design, the 36 other free plays (0.5 and 0.75
  of the limit, and 0.95 along 45 degrees) hold too, at 3 um/s or less.
- The rocking is gone: the traced cube (b, condim 3, 1.277 ms) keeps a steady tilt of 1.33 mrad and four contacts on
  every step, slipping at 2 um/s, where in the set it rocks between 3.28 and 3.84 mrad and has fewer than 4 contacts
  on 30 steps.
- The solver's iterations a step, the two together: at most 57 with the design, 21 without; none at 100.

**The offset stacks: better at 1 mm, worse at 5 mm, unless noslip is held to convergence.** The fastest any cube of a
stack of three turns at the end, urad/s, over run 078's and Study 16's cubes, 1.14 and 0.285 ms, 2, 4 and 6 s
([`reading_stacks.txt`](reading_stacks.txt), [`reading_stacks_2.txt`](reading_stacks_2.txt)):

| Offset | set5, noslip 100 | setn, noslip 100 | set5, noslip 1,000 at 1e-15 | setn, noslip 1,000 at 1e-15 |
|---|---|---|---|---|
| 1 mm | 38 to 31,538 | 1 to 31,874; at 4 and 6 s 1 to 20, one play 1,041 | 23 to 1,989 | 0 in every play |
| 5 mm | 8 to 85 | 2,344 to 37,357 | 54 to 1,596 | 0 to 408; at 6 s 0, 0, 11 and 212 |
| 17 mm | 21 to 217 | 16 to 76 | | |

- With noslip at 100 iterations and MuJoCo's tolerance, the design leaves the 5 mm stacks turning far faster than the
  set alone. Its stacks never reach 100 iterations (at most 51): noslip stops at its tolerance, not its limit.
- Held to convergence, it brings every 1 mm stack to rest and the 5 mm stacks to 0 in 5 of 12 plays, where the set
  alone keeps them all turning. Every play of both arms then runs 1,001 iterations on some step.
- The 17 mm stacks lean less with the design (5.2 to 6.1 mrad, against 7.0 to 8.1).

**The set's other plays** ([`reading_set.txt`](reading_set.txt)): Study 15's arm set down and dropped in two poses,
the cube Study 19 held at 0.5 and 0.95, MuJoCo's box and Study 19's box 1, the same readings (0 um/s, boxes at rest);
Study 15's grip creeps 3 um/s with box pads (1 without) and 1 um/s with mesh pads (0). **Safe when off**: the set's 12
play files at 1.71 ms and their statistics the same bytes in Study 21's build and in p98 with the five switches
([`identity.txt`](identity.txt)). **MuJoCo's suite**: with the design set, the same results as without it, the one
failure `SolverTest.ZeroToleranceDisablesTermination`, as in Study 21 (M1).

## What it means

- Re-solving the normal forces in noslip's pass stops the free cube's rocking, the case Study 20 failed on: in every
  play here the free cubes hold.
- It is not ready: under the configuration it makes stacks offset 5 mm turn faster, and it brings the stacks to rest
  only with noslip held to a tolerance of 1e-15, at a thousand iterations a step. The next question is why its pass
  stops short on stacks at MuJoCo's tolerance, before any registration.
