# Run 046: de Saxce's correction for MuJoCo's elliptic cone, a patch in design for F3 and F12 (a probe)

16 October 2026. Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh), pushed with the
patch before any play. It finds where to look and decides nothing.

[Run 045](../run_045_f12_free_cube_direction/README.md) traced finding F12, a free cube's direction under the elliptic
cone, to finding F3: the sliding cube hops, and free to turn it lands on its corners. F3's cause is the convex
relaxation of the friction cone ([run 016](../run_016_sliding_lift/README.md)). In MuJoCo's elliptic cone a contact
transmits force while its normal residual is below the scaled norm of its tangential residual, so a sliding contact
keeps pushing while it separates (`engine_solver.c`, the cone's top zone, N >= mu T). De Saxce and Feng (1991) showed
that exact Coulomb friction is the same cone complementarity in a velocity shifted along the normal by friction times
the slip; a fixed point on that shift recovers it with a convex solve at each pass (Acary, Cadoux, Lemarechal and
Malick 2011).

**The patch**, [`patches/in_design/desaxce_elliptic.diff`](../../patches/in_design/desaxce_elliptic.diff) (sha256
cb9f70831f208106..., against the record's upstream commit, `patch_check.txt`), changes `engine_forward.c` only: 69
lines added and 1 changed. With the switch set (`MUJOCO_DESAXCE=K`), after MuJoCo's solve it shifts each elliptic
contact's normal reference by the scaled norm of its tangential residual at the current solution and solves again from
that solution, K times. Nothing is kept between steps. The changed line is MuJoCo's island condition: with the switch
set the constraint problem is solved whole, not island by island; with it unset the condition is MuJoCo's own. The
pyramidal cone and every other constraint are untouched.

Arms: **rel**, MuJoCo 3.16.0 as released; **off**, the patched build with the switch unset; **on1**, **on2**, **on4**,
the switch at 1, 2 and 4 passes. Every reading is Senua AI's measure's (`sx_contact hover`, `stop`, `creep`), in
[`measured.txt`](measured.txt); the rig's statistics are in each arm's `stats.txt`. No play reached the solver's
iteration limit or raised a warning.

## Safe when off

With the switch unset the patched build plays all 53 files byte for byte as the release (`measured.txt`, last line).

## The lift (F3)

Run 016's cube kept from turning (1 kg, half-size 0.05 m, friction 0.4) set sliding at 1.2 m/s, under Senua AI's
configuration (the elliptic cone with 10 noslip iterations). The highest it rises while sliding, um (`hover`):

| Step | Released | 1 pass | 2 passes | 4 passes |
|---|---|---|---|---|
| 10 ms | 10,570 | 360 | 10 | **0** |
| 2.5 ms | 1,176 | 41 | 8 | **0** |
| 0.625 ms | 148 | 8 | 1 | **0** |

At 4 passes the cube never leaves the ground: no step without a contact, at every step, where the release has none on
22 of 100, 74 of 400 and 288 of 1,600 steps (the trace's contact count). The elliptic cone alone reads the same. The
slide's length changes by 0.13% at most: 177,755, 182,341 and 183,495 um at 4 passes against 177,979, 182,334 and 183,451
released (Coulomb's distance 183,673; the shortfall at the coarse step is finding F5). Study 10's cube kept from
turning: 97 and 32 um released at 1.14 and 0.285 ms, 0 and 0 at 4 passes. **With no friction (condim 1) every pass
count plays byte for byte as the release** (6 of 6 files each): the shift is zero where there is no friction.

## The direction (F12)

Study 10's cube free to turn (1.861 kg, 0.0434 m, friction 0.39, 1.01 m/s), under the configuration. Slid, um
(Coulomb's distance 133,451):

| | Along 0 | 11.25 | 22.5 | 33.75 | 45 |
|---|---|---|---|---|---|
| Released, 1.14 ms | 133,042 | 135,526 | 136,043 | 135,039 | 133,266 |
| 4 passes, 1.14 ms | **133,040** | **133,040** | **133,040** | **133,040** | **133,040** |
| Released, 0.285 ms | 133,491 | 135,636 | 135,734 | 135,143 | 133,605 |
| 4 passes, 0.285 ms | **133,481** | **133,481** | **133,481** | **133,481** | **133,481** |

**At 4 passes the slide is the same along every direction played, to the micrometre, and 0.02% from Coulomb's distance
at the fine step.** It drifts 0 um off its line (up to 1,026 released), never touches down on fewer than four corners
(68 to 707 steps released), and tilts a steady 1,074 to 1,081 urad in every play (1,249 to 9,188 released). One pass
leaves 0.03% to 0.04% between directions, two passes 2 um (0.002%). The elliptic cone alone at 4 passes: 133,045 um along 0 and
along 22.5 at 1.14 ms, 133,486 at 0.285 ms.

## Nothing held lets go

Study 10's cube held with 0.5, 0.75 and 0.95 of its friction limit along 0, 22.5 and 45 degrees, and its grip, box and
mesh pads, centred and 9.3 mm off, under the configuration at 1.14 ms: **every hold creeps 0 um/s and every grip 0 or
1 um/s at every pass count, as released.** The files are not byte-identical to the release's (the shift acts on every
contact with a tangential residual, held or sliding); the readings are the same.

## The cost

The most solver iterations on any step: 14 at 4 passes, against 10 released (the passes start from the last solution
and need few iterations each). At 4 passes on the free cube, 10 to 14 against 5 to 10 released.

## What it shows

- **One patch removes F3 and F12 together**, under the elliptic cone alone and under Senua AI's configuration, at every
  step played, with every hold and grip as released, and MuJoCo unchanged with it off.
- **The number of passes is a setting of this probe, not a constant to keep.** The fixed point converged by 4 passes in
  every play here; the version to register should run it to convergence, judged by MuJoCo's own solver, not by a count
  chosen here.
- **Not yet asked:** MuJoCo's own test suite with the switch set, the record's two contact suites, a stack, the arm,
  the bounce, the pyramidal cone (which the patch does not touch), inverse dynamics (`mj_inverse` does not apply the
  shift), and fresh numbers. A registered study decides.
