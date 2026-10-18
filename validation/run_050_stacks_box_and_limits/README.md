# Run 050: what the stacks and the box cycle follow, and the de Saxce patch's known limits (a probe)

16 October 2026 (10:13 to 10:16 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing.

**Launched twice.** The first launch (10:09 UTC, commit 3d1476f) gave MuJoCo's RK4 integrator in lower case; its five
RK4 plays failed, it was stopped after its first arm, and its outputs were discarded. The keyword was corrected and
pushed (a1af52b) and the probe played from the start; the files here are that play's.

Arms: **rel**, MuJoCo 3.16.0 as released; **on**, the de Saxce patch's fourth version
([`desaxce_elliptic_v4.diff`](../../patches/in_design/desaxce_elliptic_v4.diff), sha256 00cb8f8eb4a07535...) with its
switch set, built from MuJoCo's source at `UPSTREAM_COMMIT` ([`patch_check.txt`](patch_check.txt)). Readings in
[`measured.txt`](measured.txt); the files that differ between the arms in [`differ_rel_on.txt`](differ_rel_on.txt).

## 1. The stacks at the fine step (finding F14, issue 21)

Straight stacks of 5 and 9 cubes on Study 10's numbers, 2 s, at 0.285 ms unless a row says otherwise. The most tilt of
any cube over the play, and at the last step the largest speed (vx or vz) of any cube:

| Options | Released, 5 | Released, 9 | Switch set, 5 | Switch set, 9 |
|---|---|---|---|---|
| The configuration (elliptic cone, 10 noslip iterations) | 2,302 urad, 2,064 um/s | 2,523 urad, 6,801 um/s | 0, 0 | 3,181 urad, 6,136 um/s |
| The elliptic cone alone | 0, 0 | 0, 0 | 0, 0 | 0, 0 |
| MuJoCo's defaults (pyramidal cone) | 0, 0 | 0, 0 | 0, 0 | 0, 0 |
| The pyramidal cone, 10 noslip iterations | 0, 586 | 1,231, 823 | the same | the same |
| The configuration, 30 or 100 noslip iterations | byte for byte as with 10 | | byte for byte as with 10 | |
| The configuration, tolerance 1e-12, 1,000 iterations | 0, 0 | 0, 19 | 0, 0 | 0, 0 |
| The configuration, cubes kept from turning | 0, 0 | 0, 0 | 0, 0 | 0, 0 |
| The configuration, implicitfast | 0, 0 | 0, 0 | 2,816, 2,458 | 7,045, 8,956 |
| The configuration at 0.1425 ms | 4,450, 262 | 0, 64 | 3,489, 3,931 | 3,094, 2,588 |
| at 0.57 ms | 0, 37 | 0, 566 | 0, 38 | 1,073, 6,386 |
| at 0.855 ms | 0, 0 | 270, 12,863 | 0, 0 | 9,791, 2,320 |
| at 1.14 ms | 0, 0 | 0, 0 | 0, 0 | 0, 0 |

**What it shows.** No stack moves without noslip. With noslip they move under either cone, at some steps and not
others, with no order in the step. More noslip iterations change nothing (noslip stops on its own tolerance before 10),
and with the main solve run to a tolerance of 1e-12 no stack tilts at this step, released or with the switch set, and
only the released stack of 9 still moves, at 19 um/s at the end (at most 5 iterations a step against 4, never at the
limit). **Corrected by [run 052](../run_052_joint_friction_and_tolerance/README.md):** this reading was first taken here
as pointing at the main solver's tolerance. Played across tolerances from 1e-8 to 1e-14 and steps from 0.1425 to 1.14
ms, the stacks tilt and stand with no order in either, at 1e-12 too (up to 3.7 mrad at 1.14 ms); the tolerance is not
the cause, and the 0.285 ms reading here is one point of that. The patch does not cause the tilting and does not remove
it here; on Study 12's fresh numbers it tipped a stack of 9 the release keeps upright.

## 2. The box that never comes to rest (finding F13, issue 20)

MuJoCo's `DiscreteImplicitRowNoslip` scene (taken from its test file in run 049) from its keyframe, 1,000 steps, five
times the test's 200. Steps faster than 1 mm/s along the slide, of steps 40 to 199 and of steps 840 to 999:

| The scene | Released | Switch set |
|---|---|---|
| As written (condim 6, impratio 10, 2 noslip iterations) | 106 and 106; fastest 76,978 um/s | 108 and 106; fastest 76,903 um/s |
| 5, 10 or 50 noslip iterations | byte for byte as written | byte for byte as written |
| impratio 1 | 128 and 128 | 128 and 128 |
| The pyramidal cone | 107 and 106 | the same, byte for byte |
| condim 4 (torsional friction, no rolling friction) | 0 and 0, at rest | 0 and 0, at rest |

**What it shows.** The cycle lasts: it runs as fast at step 1,000 as at step 200. It needs rolling friction (condim 6;
run 049 found condim 3 and no noslip also rest) and noslip, under either cone, at either impratio. The patch moves its
phase, not the cycle.

## 3. The patch's known limits

- **The pyramidal cone is untouched.** Every play under the pyramidal cone, with and without noslip (the lift, the free
  cube along 0, 22.5 and 45 degrees, holds at 0.5 and 0.95 of the limit), is byte for byte as released. Those plays also
  show that **the lift is there under the pyramidal cone too**: run 016's cube rises 10,848 um at 10 ms, 822 at 2.5 and
  196 at 0.625 ms. This patch acts on the elliptic cone only, so whatever it fixes, it fixes there.
- **A bounce is untouched.** Run 017's drop under the configuration at 10 ms over 1, 4, 16 and 64, with a damping ratio
  of 1 and of 0.1, byte for byte as released: no rebound at a damping ratio of 1; at 0.1, released and with the switch
  set alike, the cube rebounds to 102 times its drop height at 10 ms and to about half its drop height at the finer steps (finding F8,
  issue 10).
- **RK4 and implicitfast.** With the switch set, the free cube slides 133,054 um (RK4) and 133,036 um (implicitfast)
  along 0, 22.5 and 45 degrees, with no drift, and run 016's cube does not leave the ground at 10 or 2.5 ms under either.
  Released: along 22.5 degrees 134,897 um with a drift of 590 um (RK4) and 136,043 um with -231 um (implicitfast);
  lifts of 938 and 114 um (RK4), and 10,570 and 1,176 um (implicitfast).
- **The cost.** At most 64 iterations on a step with the switch set, on the box scene at impratio 1 (57 as written),
  against at most 9 released on any play; never at the limit, no warning.

## Not asked here

Inverse dynamics (`mj_inverse` does not apply the shift); fresh numbers (Study 12 decides).
