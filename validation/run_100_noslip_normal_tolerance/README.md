# Run 100: the normal re-solve with noslip's tolerance tightened, and the end of the designs for noslip's instability

17 October 2026 (10:59 to 11:07 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Its readings and solver
statistics are kept.

## Why

Run 098: with noslip re-solving the normal forces (`noslip_normal.diff`, setn) every free cube holds, but under the
configuration stacks offset 5 mm a cube turn faster than without it (set5). Its stacks stop at noslip's tolerance, and
held to 1e-15 at 1,000 iterations they come nearly to rest. Is the tolerance enough, at the configuration's 100
iterations?

## What was played

In run 098's build, set5 and setn, the elliptic cone with 100 noslip iterations at MuJoCo's `noslip_tolerance` of
1e-8, 1e-10, 1e-12 and 1e-15: run 093's stacks offset 1 and 5 mm, of run 078's cube and Study 16's, at 1.14 and 0.285 ms,
played 6 s; Study 20's free cube b, condim 3, pushed along 0 degrees at 0.95 of its limit, at 1.277 and 0.319 ms
([`reading.txt`](reading.txt), [`stats.txt`](stats.txt)). Read by Senua AI's measure: `final`, `creep`.

## What it found

The fastest any cube of a stack turns at 6 s, urad/s, over the 8 stacks, and the free cube's creep, um/s:

| Tolerance | set5 stacks | setn stacks | setn stacks at rest (0) | set5 free cube | setn free cube |
|---|---|---|---|---|---|
| 1e-8 | 6 to 3,074 | 307 to 6,223 | 0 of 8 | 1,098 and 483 | 1 and 1 |
| 1e-10 | 40 to 3,289 | 0 to 2,640 | 4 of 8 (every 5 mm stack) | 1,098 and 497 | 0 and 0 |
| 1e-12 | 10 to 9,091 | 0 to 859 | 6 of 8 | 1,098 and 497 | 0 and 0 |
| 1e-15 | 99 to 2,250 | 0 to 839 | 6 of 8 | 1,098 and 497 | 0 and 0 |

- Without the design, tightening the tolerance changes nothing that matters: the stacks keep turning and the free cube
  creeps at every tolerance.
- With it, the free cube holds at every tolerance. The stacks come to rest only in part: at 1e-12 and 1e-15 six of eight
  stand still, and Study 16's cube offset 5 mm still turns (81 to 859 urad/s). At 1e-10 the 5 mm stacks rest and the 1
  mm ones turn.
- The cost: at 1e-10 and tighter, noslip runs to its limit of 100 iterations on up to 21,052 of 21,053 steps a play.

## What it means

- No setting tried brings every offset stack to rest without harm. The normal re-solve holds the free cube, and with
  the tolerance tightened it steadies most stacks, at the cost of noslip at its limit on nearly every step; the stacks of
  one cube still turn.
- That ends the designs for noslip's multi-contact instability in this deep dive. It is recorded as a measured limit of
  Senua AI's configuration, as MuJoCo's own documentation records it: with noslip, a free body pushed close to its
  friction limit rocks and creeps (issue 1's last case), and stacks offset a few millimetres keep turning (issue 9).
  The two designs measured, and what each does, stay in `patches/in_design/` for further work.
