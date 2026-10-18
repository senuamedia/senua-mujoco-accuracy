# Run 067: what MuJoCo's noslip computes for the stacks that tilt (a probe)

17 October 2026 (00:07 to 00:09 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Readings in
[`measured.txt`](measured.txt), one line a noslip pass in `trace/*.steps`.

Issue 21 (F14): under Senua AI's configuration (the elliptic cone, 100 noslip iterations), at 0.285 ms, a straight
stack of 5 tilts up to 2.3 mrad and a stack of 9 up to 2.5 mrad. At 1.14 ms both stand (run 063), and without noslip no
stack moves (run 050). Run 062's instrumentation patch, [`noslip_trace.diff`](../../patches/in_design/noslip_trace.diff),
prints what noslip computes for each elliptic contact at each sweep. It is built from MuJoCo's source at
`UPSTREAM_COMMIT`. The probe plays run 063's stacks (Study 10's cube) of 5 and 9 under the configuration, 2 s, at 0.285
and 1.14 ms. The trace is read as it is printed, one line a pass, and never kept whole.

With the switch unset, all 56 files are byte for byte the release's and the build prints nothing. Traced, they are byte
for byte as untraced.

## What noslip computes

| Stack, step | Most tilt | Noslip's sweeps a pass | Contacts | Zero friction returned | At the cone's edge | Smallest scaled determinant |
|---|---|---|---|---|---|---|
| 5, 0.285 ms | 2,302 urad | 2.00 on average, never 100 | up to 32 | never | never | 5.26 |
| 9, 0.285 ms | 2,523 | 2.00 | up to 54 | never | never | 5.23 |
| 5, 1.14 ms | 0 | 2.00 | 20 | never | never | 5.26 |
| 9, 1.14 ms | 0 | 1.99 | up to 38 | never | never | 5.23 |

None of the arm's defect (run 062) is here. Every contact's friction block is well conditioned: its scaled determinant
is at least 5.2, against the 1e-10 that `mju_QCQP2` rejects. No sweep returns zero friction, and no contact's friction
is at its cone's edge. In the stacks that tilt, until the tilt starts, noslip converges each pass to round-off: its
second sweep improves by under 1e-25, and no friction changes by more than 3e-13 N. In the stacks that stand, the same
holds throughout (under 1e-24 and 7e-13 N).

## How the tilt starts

The trace counts one noslip pass for the rig's first forward computation. It also counts one a constraint island while
the cubes settle into one island, since MuJoCo runs noslip per island (`engine_forward.c`). So a pass number runs 4
ahead of the step in the stack of 5 at 0.285 ms, and 7 ahead in the stack of 9.

- **The stack of 5, 0.285 ms.** The stack settles with 20 contacts, four a face, and stands still until step 2770
  (0.789 s). Its top cube sits 207 um into the one below it. In that one step all five cubes start turning, and the top
  cube starts moving up, at 1.1 mm/s ten steps later. This is the first step since settling at which the number of
  contacts changes: 20 to 22, then 26 and 28 in the next steps. Noslip's largest friction change in a pass goes from
  2e-15 N in the step before to 5e-5 N. In all, the count changes 284 times after settling.
- **The stack of 9, 0.285 ms.** The count first changes at step 2416 (36 to 38). In that same step the top cube
  starts moving up. It is moving at 5.6 mm/s at step 2500, and the bounce dies away by step 3750 with no tilt. Through
  all of this noslip's friction changes stay at round-off. The count changes again at step 4677 (36 to 38), and again
  every cube starts moving up or down in that step. The tilt starts 37 steps later, at step 4714 (1.343 s), at an
  unchanged count. Then the count climbs to 54.
- **At 1.14 ms.** The stack of 5 keeps its 20 contacts throughout. The stack of 9's count changes four times, with no
  tilt.

## What it shows

Noslip is not where the stacks fail. It solves their contacts well conditioned, converges every pass, and never touches
a cone's edge. Each stack stands, with noslip converged to round-off, until a kick in a single step. In both stacks
every kick comes in the same step as a change in the number of contacts MuJoCo's box-on-box collision gives between two
cubes. The kick moves the cubes up or down. The stack of 9 shows that a kick is not enough by itself: its first did
not tip it, and its tilt began 37 steps after its second. The contacts themselves (where they are, and how deep) are not traced here. [Run
069](../run_069_stack_contacts/README.md) records them. The cubes sit 207 um deep in each other under the
configuration, against 34 um for a cube on a cube under MuJoCo's defaults (F11, issue 9).
