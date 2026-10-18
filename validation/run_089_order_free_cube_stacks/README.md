# Run 089: row order, the free cube that creeps, and the stacks (one probe, two steps)

17 October 2026. Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh) (step 1, 04:57
UTC) and [`probe_2.sh`](probe_2.sh) (step 2, written after step 1's readings, 05:02 UTC), each pushed before its plays.
It finds where to look and decides nothing. One disclosure: before step 2 was pushed, a check that
[`legpress_order_2.c`](legpress_order_2.c) compiles on the machine ran it once (the floor turned 180 degrees, MuJoCo's
default tolerance); its line was the same as step 2's.

## Issue 13: no dependence on row order found in the release

[`legpress_order.c`](legpress_order.c) plays MuJoCo's own leg-press test (`ForwardTest.DiscreteStiffLegPress`) and its
mirror image: every x reversed, and the hinge axes with it, so in exact arithmetic the joints move the same. The leg's
contact then slides along +x where it slid along -x, and each first pyramid pair meets the slip in the other order.

| The leg press, released ([`reading_legpress.txt`](reading_legpress.txt), [`reading_legpress_2.txt`](reading_legpress_2.txt)) | Coarse error | Fine error | Ratio (the test's bound 0.7) |
|---|---|---|---|
| As written, and its mirror image, at MuJoCo's default tolerance, at 1e-12 and at 1e-15 (1,000 iterations) | 0.010014872338 | 0.005198579143 | 0.519086 |
| The floor turned 0, 90, 180 and 270 degrees, at the default tolerance and at 1e-15 | 0.010014872338 | 0.005198579143 | 0.519086 |

Every play gives the same endpoints to 12 digits. The solver took at most 4 iterations on any step, at every tolerance.
So the release is not moved by the slip's direction against the first pyramid pair. The floor's turn may not reach
the contact's frame at all, so it decides nothing about the second pair. Run 022's 0.8 mm came with the slip-aligned
pyramid's second version, which turned both pairs; that patch is not in Senua AI's set. The test that would decide it
is run 022's own build, played at a tighter tolerance.

## Issue 1's new case: the free cube that creeps at 0.95 of its limit

[`reading_free_cube.txt`](reading_free_cube.txt), [`reading_free_cube_2.txt`](reading_free_cube_2.txt). Study 20's cube
b (0.819 kg, half-size 0.0316 m, friction 0.734, condim 3), pushed at 0.95 of its limit, at 1.277 ms, under the
configuration.

| Creep, um/s | Along 0 degrees | Along 22.5 degrees |
|---|---|---|
| Released: free / free to tilt but not to turn / held from turning | 2,368 / 2,367 / 0 | 548 / 475 / 0 |
| Senua AI's set: free / free to tilt but not to turn / held from turning | 1,098 / 1,124 / 0 | 0 / 0 / 0 |

- It needs the cube to tilt: held from turning and tilting it holds, and free to tilt but not to turn it creeps as when
  free. In the set it tilts 3.8 mrad, onto its front edge, and keeps all 4 contacts on all but 30 of its 1,253 steps.
- The contact trace (`p/free_set_free_0.trace`) shows how the friction is shared. The two back contacts carry 646 mN
  each and sit at their friction limit, ratio 1.000000, so they slide. The two front contacts carry 3,434 mN each, at
  0.92 and 0.94 of theirs. The front contacts have room, so a sharing that holds exists.
- It is not where noslip stops. With noslip's tolerance at 1e-6 (MuJoCo's default), 1e-9, 1e-12 and 1e-15, with 100
  iterations and with 1,000, the cube creeps at 1,098 um/s in every play, and the back contacts stay at their limit.
- Not traced: why noslip converges to a sharing that slides. The trace records each contact's friction as a size, not
  a direction. Friction pushing sideways in pairs that cancel would never show as slip, and would use up the back
  contacts' room. That would need the directions.

## Issue 9: the depth is MuJoCo's pyramid; the offset stacks that keep turning are noslip stopping short

[`reading_depth.txt`](reading_depth.txt): a cube (1 kg, half-size 0.05 m) set down from 20 mm, at 1 ms, released, its
depth at rest by each cone:

| Friction | 0.2 | 0.4 | 0.7 | 1 | 1.414 | 2 |
|---|---|---|---|---|---|---|
| The pyramidal cone (MuJoCo's default), nm | 2,271 | 10,132 | 39,783 | 107,649 | 293,669 | 636,821 |
| The elliptic cone, nm | 107,649 | 107,649 | 107,649 | 107,649 | 107,649 | 107,649 |

- The elliptic cone's depth is the same at every friction: the softness the model authors (`solref`, `solimp`).
- The pyramid's depth moves with the friction, by 280 times from 0.2 to 2, and equals the elliptic cone's at a
  friction of 1. MuJoCo gives the pyramid's four edges one softness, chosen to match the elliptic cone's friction rather
  than its normal. Its source says so (`engine_core_constraint.c`: "D0_el = 2*mu^2*D_py: friction match").
- So "the elliptic cone sinks deeper" (runs 026, 069) has the cause the wrong way round. Below a friction of 1 the
  pyramid sinks less than the model authors; above 1, more.

[`reading_stacks.txt`](reading_stacks.txt), [`reading_stacks_2.txt`](reading_stacks_2.txt): run 078's offset stacks
(3 cubes of 0.442 kg, half-size 0.0424 m, friction 0.524, each 1 or 17 mm over from the one below), 2 s, in Senua AI's
set:

| Offset stack in the set, 1.14 ms | 1 mm: most tilt, urad | Turning at the end, urad/s | Contact changes | 17 mm: most tilt | Turning at the end | Changes |
|---|---|---|---|---|---|---|
| The configuration (noslip 100, MuJoCo's tolerance) | 2,126 | 594 | 107 | 9,363 | 180 | 51 |
| Noslip 1,000 iterations, tolerance 1e-15 | 1,699 | 23 | 1 | 9,141 | 0 | 2 |
| The elliptic cone, no noslip | 393 | 1 | 0 | 9,061 | 32 | 0 |

At 0.285 ms the configuration reads alike (2,202 and 9,528 urad, still turning at 511 and 171 urad/s). So in the set,
under the configuration, the offset stacks keep turning only because noslip stops short. Held to convergence it brings
them to rest, with one or two contact changes. At a 1 mm offset the stack then rests leaning about four times as far as
without noslip.

## What it means

- **Issue 13**: in the release, no dependence on row order was found where measured. Whether run 022's swap of both
  pairs moves the endpoint once the solver is held tighter is still to be played.
- **Issue 1's new case**: not the solver's tolerance. The mechanism is still open.
- **Issue 9**: the depth is the soft contact the model authors, and under the pyramid MuJoCo's own documented choice.
  The offset stacks' turning is noslip stopping short, and is gone with noslip held to convergence: a configuration
  candidate, MuJoCo's own options, still to be registered with what it changes elsewhere.
