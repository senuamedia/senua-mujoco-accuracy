# Run 090: the leg press with run 022's patch, and what its turn changes

17 October 2026 (05:05 to 05:10 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh) (step 1) and [`probe_2.sh`](probe_2.sh) (step 2, written after step 1's readings), each pushed
before its plays. It finds where to look and decides nothing.

## Why

Issue 13 (F9) says MuJoCo's discrete integrator depends on the order of equivalent rows. It rests on run 022: with the
slip-aligned pyramid's second version switched on, which turns the leg press's contact by 180 degrees, the leg's
endpoint moved by 0.8 mm and the test's ratio went from 0.52 to 0.74. A pyramid turned by 180 degrees has the same four
rows, each pair swapped.

Run 089 played the release's leg press and its mirror image. Mirroring negates the contact's speed along the slip and
nothing else, so the mirrored problem is the original with each first pyramid pair swapped. The second pair's two rows
are equal in this flat scene, since the leg cannot move sideways. The two gave the same endpoints to 12 digits.

## Step 1: the patch, at MuJoCo's tolerance and at 1e-15

MuJoCo built from its source at `UPSTREAM_COMMIT` with
[`slip_aligned_pyramid_v2.diff`](../../patches/in_design/slip_aligned_pyramid_v2.diff) alone, as run 022 built it. The
leg press is played by run 089's [`legpress_order_2.c`](../run_089_order_free_cube_stacks/legpress_order_2.c)
([`reading.txt`](reading.txt)).

| The leg press, the patch's build | Coarse error | Fine error | Ratio (bound 0.7) |
|---|---|---|---|
| Switch unset, MuJoCo's tolerance and 1e-15 (1,000 iterations) | 0.010014872338 | 0.005198579143 | 0.519086 |
| Switch set, MuJoCo's tolerance and 1e-15 | 0.013300777864 | 0.009860936475 | 0.741380 |

The solver took at most 4 iterations on any step at either tolerance. The patch's effect is in the problem the solver
is given, not in where it stops.

## Step 2: what the patch turned

Run 022's own trace tool ([`legpress_trace.c`](../run_022_pyramid_v3/legpress_trace.c)) on the same build, the switch
set, with the patch's sleep tolerance (a contact turned only when its slip is at least that), counting in each play's
log the contact-steps turned by exactly 180 degrees and by any other angle ([`reading_2.txt`](reading_2.txt); the log at
the default in `log_default.txt.gz`):

| Sleep tolerance, m/s | Contact-steps turned by 180 degrees, of 240 | By another angle | Ratio |
|---|---|---|---|
| MuJoCo's default (0.001), 1e-4, 1e-3 | 238 | 0 | 0.741380 |
| 1e-2 | 64 | 0 | 0.821895 |
| 1e-1 | 0 | 0 | 0.519086 |

The patch turns the contact by exactly 180 degrees and by nothing else. On the other 2 contact-steps it does not turn
it at all; run 022's "238 of the 240" was read as two other turns. It changes the result whenever it turns, and with
no turn it is the release.

## What it means

In the release, a pure swap of each pyramid pair (run 089's mirror image) gives the leg press the same to 12 digits. The
patch's 180-degree turn gives the solver those same rows in that same swapped order, and yet moves the result by 0.8 mm.
So that change comes from something else the patch does when it turns a contact, not from the order of the rows. It was
not traced further: the patch is not in Senua AI's set, and its third version, the one Studies 3 and 4 played, does not
turn a contact whose slip lies along an edge.

**Issue 13's cause, as the record stated it, is not supported:** no dependence on the order of equivalent rows was
found in MuJoCo as released. F9 and the issue list are corrected to say so.
