# Twelfth pre-registration: the de Saxce patch's fourth version, for a sliding body's lift and a free cube's direction

Registered 16 October 2026, after the design probes of runs 046 to 050. Registered before any play of this registration
existed. To be played once, as run 051.

## The question

Issues 4 and 5 of [the issue list](../docs/issues.md). Under the elliptic cone a sliding body leaves the surface (finding
F3: run 016's cube, slid at 1.2 m/s, rises 10,570 um at a 10 ms step), and a cube free to turn, slid along different
directions, goes different distances, drifts across its line and turns (finding F12). Both trace to the elliptic cone's
convex relaxation of Coulomb friction, under which a sliding contact separates at about friction times its slip (runs
016 and 045; Anitescu 2006). The de Saxce patch's fourth version
([`patches/in_design/desaxce_elliptic_v4.diff`](../patches/in_design/desaxce_elliptic_v4.diff), switch
`MUJOCO_DESAXCE=1`, `engine_forward.c` only, 103 lines added and none removed) applies de Saxce and Feng's correction
(1991): after MuJoCo's solve it lowers each elliptic contact's normal reference by friction times its slip, and solves
again from that solution until no shift moves by more than the solver's own tolerance. In run 049, on Study 10's
numbers, it removed the lift and the direction, left every hold and grip byte for byte as released, and changed two of
MuJoCo's 3,492 tests, each traced. In run 050 every play under the pyramidal cone and every bounce was byte for byte as
released.

On numbers no earlier study or probe used: with the switch set, does a sliding cube stay on the ground and slide the same
along every direction, under Senua AI's configuration and under the elliptic cone alone, while everything held is held
as before? With the switch unset, is the patched MuJoCo the release, file for file and test for test? With the switch
set, does any of MuJoCo's tests change other than the two named below?

## Engines and arms

- **rel_def**, **rel_rec**, **rel_ell**: Google DeepMind's Linux release of MuJoCo 3.16.0
  (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256 139577c541d43716...), under MuJoCo's defaults (the pyramidal cone), under
  Senua AI's configuration (`cone=elliptic`, `noslip_iterations=10`), and under the elliptic cone alone.
- **off_def**, **off_rec**, **off_ell**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with the patch
  file of sha256 00cb8f8eb4a07535... applied (gcc, CMake and Ninja, a Release build; its tests built the same way),
  rebuilt by the runner from the patch file; switch unset; under the same three option sets.
- **on_def**, **on_rec**, **on_ell**: the same build, switch set.

Each arm makes the same plays. MuJoCo's own test suite is run on the release's test build (run 020's recipe) and on the
patched test build, switch unset and set, the two memory-heavy texture tests on their own. Played on the first cloud
machine (AWS EC2 c7i.xlarge, Intel, 4 virtual CPUs, 8 GB).

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_051_study_12/play.sh`](../validation/run_051_study_12/play.sh) | 0c71b4860342b5d4... |
| Rigs | `tools/mjc_contact.c` (with run 045's `trace` and `noyaw`, unchanged without them), `tools/mjc_stack.c`, `tools/mjc_grip.c` | e9f952c24189f702..., 9dd2ec778cac0012..., 5adac004412ef94b... |
| | `tools/contact_suite.sh`, `tools/build_rig.sh` | 8cda2ed242cad7df..., b6a93676e6aee763... |
| Senua AI's measures | `sx_contact` (`creep`, `stop`, `hover`, `rule`), as run in Studies 10 and 11 | source 87e921cd4d2c03bf... (built for Linux: f09ea027cec7820d...) |
| | The first deep dive's suite runner, `sx_contact_suite.sh`, as run | 553d46ecdaf2bd95... |
| The patch | `patches/in_design/desaxce_elliptic_v4.diff` | 00cb8f8eb4a07535... |

## The numbers, and how they were drawn

By Study 10's procedure, from x(0) = 12: the stream x(n+1) = (1103515245 x(n) + 12345) mod 2^31, each number giving its
quantity a point on its range's grid; Study 10's ranges and grids. A value the record already used for a quantity of the
same kind (Study 11's lists, the values Studies 10 and 11 drew, and the settings of runs 043 to 050), or one this draw
had already given that kind, was drawn again: five were (a half-size of 0.0435 m, speeds of 0.95 and 1.16 m/s, a height
of 0.090 m, a squeeze of 3.20 N). The squeeze was drawn again once more until the two pads' friction was 1.7 to 2 times
the grip cube's weight (2.50 N gave 1.51). `DRAW=1 bash validation/run_051_study_12/play.sh` prints the draw.

| What | The numbers | Drawn from |
|---|---|---|
| The steps | 1.16 ms, and a quarter of it, 0.29 ms | 1 to 2 ms |
| The cube held and slid | 1.903 kg, half-size 0.0499 m, friction 0.379, slid at 0.81 m/s (Coulomb's distance 88,323 um; the friction limit 7.0681 N) | 1 to 2 kg, 0.04 to 0.05 m, 0.35 to 0.5, 0.8 to 1.2 m/s |
| The first suite's cube | 0.908 kg, half-size 0.0431 m, dropped from 0.097 m, launched at 3.19 m/s and 0.98 m/s (the chain), friction 0.409, slid at 4.35 m/s, held at friction 0.432 | 0.8 to 2 kg, 0.03 to 0.045 m, 0.07 to 0.10 m, 2 to 4 and 0.9 to 1.5 m/s, 0.3 to 0.45, 2.5 to 5 m/s, 0.4 to 0.5 |
| The grip | a cube of 0.248 kg, half-size 0.0305 m, friction 0.732, squeezed with 3.02 N (the pads' friction 1.82 times its weight), and 9.7 mm off centre | 0.2 to 0.25 kg, 0.03 to 0.035 m, 0.68 to 0.8, 2.45 to 3.2 N, 7 to 10 mm |
| The stacks | cubes of 0.408 kg, half-size 0.0439 m, friction 0.534 | 0.35 to 0.5 kg, 0.04 to 0.05 m, 0.5 to 0.6 |

Not drawn: the pushes, 0.5, 0.75 and 0.95 of the cube's friction limit (Study 2); the directions, 0, 22.5 and 45 degrees
for the cube kept from turning and 0, 11.25, 22.5, 33.75 and 45 for the cube free to turn (run 045); the stacks of 5 and
9; the record's step ladder, 10 ms over 1, 4, 16 and 64; the plays' lengths.

## The scenes

Every arm plays, at both steps unless said:

- **The cube held**, pushed at 0.5, 0.75 and 0.95 of its friction limit along 0, 22.5 and 45 degrees, 1.6 s (18 plays).
- **The cube slid kept from turning** along 0, 22.5 and 45 degrees (6), and along 0 at each step of the ladder (4).
- **The cube slid free to turn** along 0, 11.25, 22.5, 33.75 and 45 degrees (10), each step's turn, tilt and contacts
  traced.
- **The grip**: the cube between two pads, box and mesh pads, at the centre and off it (8).
- **Stacks** of 5 and 9 cubes (4): played and reported, not ruled.
- **The first deep dive's first contact suite**, on the fresh cube.
- **MuJoCo's own test suite**: the release's, and the patched build's with the switch unset and set.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. A slide's distance is `sx_contact stop`'s;
its height above the ground `sx_contact hover`'s highest; a creep `sx_contact creep`'s mean speed; a slide's drift
across its line, its most turn about the vertical and its steps on fewer than four contacts the rig's own `side_um`,
`most_yaw_urad` and `steps_under_4_contacts`.

**Shared** (read once):

| Rule | Statement | From |
|---|---|---|
| Q1 the release lifts | rel_rec and rel_ell: the cube slid kept from turning at 10 ms rises at least 100 um (2 lines) | F3 (run 016) |
| Q2 the release has a direction | rel_rec and rel_ell: some slide free to turn drifts at least 10 um across its line (2 lines) | F12 (run 045) |
| Q3 the release loses a corner | rel_rec and rel_ell: over the slides free to turn, at least one step on fewer than four contacts (2 lines) | F3, F12 (run 045) |
| E1 safe when off, plays | Every file off_def, off_rec and off_ell play byte-identical to rel_def's, rel_rec's and rel_ell's (3 lines) | Studies 5 to 10's R1 |
| E2 safe when off, MuJoCo's suite | Switch unset: every one of MuJoCo's tests gives the release's result | their R2 |
| P1 the pyramidal cone untouched | Every file on_def plays byte-identical to rel_def's | new: the patch acts on elliptic contacts only |
| M1 MuJoCo's suite, switch set | Against the switch unset, no test changes but `SolverTest.ZeroToleranceDisablesTermination` and `ForwardTest.DiscreteImplicitRowNoslip` | their R8, with the two changes run 049 traced named in advance |

**For each switch-set elliptic arm**, on_rec and on_ell:

| Rule | Statement | From |
|---|---|---|
| L1 no lift | The cube slid kept from turning rises at most 1 um above the ground, along every direction at both steps and along 0 at every step of the ladder (one line over 10 plays) | F3: a body slid on a level floor does not leave it |
| L2 four corners | Every slide free to turn on four contacts at every step | F3, F12: no corner of a cube slid on a level floor leaves it |
| D1 no direction | Each step: the slides free to turn along 11.25, 22.5, 33.75 and 45 degrees within 1 part in 10,000 of the slide along 0; the slides kept from turning along 22.5 and 45 within 1 part in 10,000 of along 0 (4 lines) | Study 2's R3, applied to the free cube too |
| D2 no drift | Each step: every slide, free and kept, drifts across its line at most 10 um (2 lines) | Study 1's R4 |
| D3 no turn | Each step: no slide free to turn turns about the vertical more than 1,000 urad (2 lines) | new: a cube slid without spin on a uniform floor has nothing to turn it; a thousandth of a radian, the record's grid for an angle |
| C1 Coulomb | The fine step: every slide, free and kept, within 1 part in 100 of 88,323 um | Study 2's R4 |
| V1 the solver | Over every play: no step at the iteration limit, no warning (2 lines) | Studies 5 to 10's R9 |

**For on_rec only**, under the configuration:

| Rule | Statement | From |
|---|---|---|
| H1 every hold holds | All 18 holds creep at most 10 um/s | Study 2's R2 |
| G1 the grip holds | All 8 grips creep at most 10 um/s | Study 10's G1 |
| K1 the ten tests | The first suite: 10 of 10 | Study 2's R5 |
| N1 nothing held is touched | Every hold and grip file byte-identical to rel_rec's | run 049: a contact that sticks has no slip and no shift |

**For on_ell only**, under the elliptic cone alone, whose holds creep as released (finding F1):

| Rule | Statement | From |
|---|---|---|
| H2 held as released | Every hold's and grip's creep within 1 um/s of rel_ell's | new: the patch does not change what the elliptic cone holds |

There are 43 rule lines: 12 shared, 17 for on_rec and 14 for on_ell. The most iterations over every play and the
stacks are reported, not ruled.

## The decisions

- **Issue 4 (F3), a sliding body hops, under Senua AI's configuration**: if Q1 and Q3 (rel_rec), E1, E2, P1, M1 and
  on_rec's L1, L2, C1, H1, G1, K1 and V1 hold, it is recorded as **fixed and validated under the elliptic cone with
  Senua AI's configuration**.
- **Issue 5 (F12), a free cube has a direction, under the configuration**: if Q2 (rel_rec), E1, E2, P1, M1 and on_rec's
  D1, D2, D3, C1, H1, G1, K1 and V1 hold, it is recorded as **fixed and validated** the same way.
- **Under the elliptic cone alone**: the same two decisions with Q1 to Q3 (rel_ell), E1, E2, P1, M1, and on_ell's L1,
  L2, D1 to D3, C1, V1 and H2.
- **Nothing held is touched**: if N1 holds, recorded as such. N1 is not part of the decisions above, which read the
  holds and grips through H1, G1 and H2.
- If both decisions under the configuration hold, the patch moves from `patches/in_design/` to `patches/`.
- A rule that fails is recorded as measured, with its numbers, and what it concerns stays open.
- Not decided: the lift under the pyramidal cone (run 050: it is there, and this patch does not act on the pyramidal
  cone, so issue 4 can be recorded fixed only under the elliptic cone); the stacks at a fine step (F14) and the box that
  never comes to rest (F13); a bounce (F8); inverse dynamics (`mj_inverse` does not apply the shift); the RK4 and
  implicitfast integrators; Coulomb's distance at the coarse step, where the step itself falls short (F5).

## Known risks, stated before the run

- **M1.** In run 049, on the same source, two of MuJoCo's tests changed with the switch set.
  `ZeroToleranceDisablesTermination` pins one solve's iteration count at its limit, 3; with a zero tolerance the
  patch's fixed point also runs every pass, and the passes' iterations are counted (12): by design.
  `DiscreteImplicitRowNoslip` checks that a box slid under the discrete integrator with condim 6 and noslip moves at
  under 5 mm/s after 200 steps; released, the box never comes to rest (finding F13; run 050: still cycling at step
  1,000) and the test passes because its last step falls on the slow step of a six-step cycle; the switch moves the
  cycle's phase, and the last step falls on 3,854 um/s. Any other change fails M1.
- **N1.** In run 049 every hold and grip file was byte-identical with the switch set. The shift of a contact that
  sticks is computed from rounded numbers and may not be exactly zero on fresh numbers.
- **The stacks** (F14): released, under the configuration at 0.285 ms, stacks of 5 and 9 tilt and keep moving; with the
  switch set the stack of 5 stood and the stack of 9 did not (run 049). Run 050 points at noslip and the main
  solver's tolerance, not the patch. Reported, not ruled.
- **The cost.** The most iterations on a step with the switch set: 21 in run 049 (12 released), 64 on MuJoCo's own box
  scene in run 050 (9 released). Reported, not ruled; V1 rules only the limit and the warnings.

## What is not asked

Everything listed as not decided above; the arm and the constraints of Studies 5 to 10; the release's other open issues
([the issue list](../docs/issues.md)); anything against a real robot.

## Dry run

`DRY=1` played all nine arms on throwaway numbers (Study 10's, as run 049 played them), the patched arms on run 050's
build of the same patch file, with no build and no MuJoCo suite, to the end: 468 measured lines, none empty
([`validation/run_051_study_12/dry/`](../validation/run_051_study_12/dry/)). The rules were then judged on the dry run's
lines in a scratch copy, with Study 10's suite results standing in for the three suites and one named test changed by
hand in the switch-set suite, to check the plumbing: 43 rule lines, each judged
([`dry/rules_plumbing.txt`](../validation/run_051_study_12/dry/rules_plumbing.txt)). No rule is read from the dry run.
