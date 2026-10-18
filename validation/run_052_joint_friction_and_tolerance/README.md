# Run 052: which of MuJoCo's options holds a joint by friction, and the stacks by the solver's tolerance (a probe)

16 October 2026 (10:37 to 10:42 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. On MuJoCo 3.16.0 as
released (**rel**), and for the stacks and the configuration's other plays also on the de Saxce patch's fourth version
with its switch set (**on**, Study 12's build). Study 10's numbers throughout. Readings in [`measured.txt`](measured.txt).

The arm rig gains `noslip_tolerance` (MuJoCo's option) and `fricsolref` (the hinges' `solreffriction`), unchanged
without them: Study 10's plays of the arm held by joint friction and at rest on contact, under MuJoCo's defaults and the
configuration, at both steps, made again and compared with run 042's files, 16 of 16 byte for byte
(`rel/id/identity.txt`).

## 1. A joint held by friction (issue 6)

The two-link arm held 1 m up by 5.96 N m of joint friction on each hinge, more than gravity's torque, in Study 10's two
poses, 2 s. The ball's mean speed over the second second (`sx_contact creep`; the right answer 0), the same at 1.14 and
0.285 ms to 1 um/s, and the most iterations on a step (MuJoCo counts noslip's with the main solver's: 1 without noslip,
11 with 10 noslip iterations):

| Options | Pose 1 | Pose 2 | Iterations |
|---|---|---|---|
| MuJoCo's defaults | 30,403 um/s | 24,461 | 1 |
| The configuration (elliptic cone, 10 noslip iterations) | 93 | 25 | 11 |
| 10 noslip iterations under the pyramidal cone | 93 | 25 | 11 |
| The configuration with a noslip tolerance of 1e-12 | 93 | 25 | 11 |
| The configuration with the main solve at 1e-12, 1,000 iterations | 93 | 25 | 11 |
| The elliptic cone, 100 or 1,000 noslip iterations | 2 | 2 | 18, 15 |
| **The elliptic cone, 1,000 noslip iterations, a noslip tolerance of 1e-12** | **0** | **0** | 31, 25 |
| MuJoCo's defaults, the friction rows' time constant 0.01 s or 0.005 s (default 0.02) | 15,812; 8,027 | 12,762; 6,503 | 1 |
| The configuration, the same time constants | 47; 23 | 12; 6 | 11 |

**What it shows.** Noslip holds the joint, given enough iterations: the configuration's 10 stop it before it converges
on the arm's two coupled friction rows. With MuJoCo's default noslip tolerance it stops after 14 to 17 noslip iterations, at 2 um/s;
with a tolerance of 1e-12 it converges in 24 to 30, to 0. Without noslip the creep is the friction rows' softness: it
halves with their time constant. A tighter main solve changes nothing. **A candidate for issue 6**: the configuration
with more noslip iterations and a tighter noslip tolerance, both MuJoCo's own options; to be probed across the record's
other scenes before it is registered.

## 2. The stacks by the main solver's tolerance (issue 21)

Straight stacks of 5 and 9 and the offset stack of 3 under the configuration, 2 s, at tolerances from MuJoCo's default
(1e-8) to 1e-14 and steps from 0.1425 to 1.14 ms. The most tilt of any cube (urad), released:

| Step | 1e-8 | 1e-9 | 1e-10 | 1e-11 | 1e-12 | 1e-14 |
|---|---|---|---|---|---|---|
| 5 cubes, 0.1425 ms | 4,450 | 2,322 | 2,528 | 0 | 0 | 0 |
| 0.285 | 2,302 | 2,375 | 0 | 2,738 | 0 | 0 |
| 0.57 | 0 | 0 | 1,828 | 0 | 0 | 0 |
| 0.855 | 0 | 0 | 0 | 0 | 0 | 0 |
| 1.14 | 0 | 0 | 0 | 2,754 | 3,696 | 0 |
| 9 cubes, 0.1425 ms | 0 | 0 | 817 | 0 | 0 | 0 |
| 0.285 | 2,523 | 0 | 0 | 0 | 0 | 0 |
| 0.57 | 0 | 0 | 4,241 | 1,146 | 0 | 0 |
| 0.855 | 270 | 2,687 | 8,562 | 0 | 3,052 | 0 |
| 1.14 | 0 | 0 | 2,272 | 1,527 | 3,302 | 0 |

With the switch set the pattern is as irregular (`measured.txt`): at 1e-14 one play tilts, the stack of 9 at 0.855 ms
(1,910 urad). The offset stack of 3 leans 9.4 to 9.9 mrad at every tolerance and step, released and patched (finding
F11). The main solver needs at most 5 iterations a step on the straight stacks at any tolerance.

**What it shows.** The main solver's tolerance does not order the stacks: they tilt and stand from one step and
tolerance to the next, with no trend. Run 050's single reading at 0.285 ms, no tilt at 1e-12, was one point of this, not
a fix ([run 050](../run_050_stacks_box_and_limits/README.md), corrected). The main solve converges in a few
iterations either way; what changes is the last digits of its solution, and with noslip a stack's outcome follows them.
Without noslip no stack moves (run 050).

## 3. The configuration's other plays at a tighter tolerance

Study 10's cube held at 0.5 and 0.95 of its limit and slid along 0, 22.5 and 45 degrees, kept from turning and free to
turn, and the box-pad grip, at 1.14 and 0.285 ms, at tolerances 1e-8, 1e-10 and 1e-12: every reading the same at every
tolerance (every hold 0 um/s, every grip 1 um/s, every slide to the micrometre), released and patched. The most
iterations on a step rise from 9 to 10 released and from 17 to 22 patched.

## The solver

Never at the iteration limit, no warning. The most iterations on a step: 31 released (the arm with 1,000 noslip
iterations and a noslip tolerance of 1e-12), 57 patched (the offset stack at 1e-14).
