# Sixteenth pre-registration: the box-on-box clip without its collinear vertices, for a straight stack

Registered 17 October 2026, after the design probes of runs 067 and 069 to 075. Registered before any play of this
registration existed. To be played once, as run 077.

## The question

Issue 21 of [the issue list](../docs/issues.md): under Senua AI's configuration (the elliptic cone with 100 noslip
iterations) a straight stack of equal cubes tilts at some steps and tolerances and stands at others, with no order
(runs 049, 050, 052). The probes traced it to MuJoCo's box-on-box collision:

- Noslip converges every step to round-off (run 067).
- Each stack stands until a kick in one step. The kick comes when the clip of the upper cube's face against the lower
  cube's face (`clipHalfPlane`, `engine_collision_box.c`) adds contacts along the face's edges, at the corners' depth
  (run 069).
- The clip does this when equal cubes stand straight, the upper face's edges on the lower face's side planes, and the
  face turns or shifts. The first time it is by rounding, corners 1e-17 m out; then by the kick's own drift, 1e-11 m
  (run 072). Each added point lies on the support polygon's edge and adds nothing to it, yet it is one more contact.

The patch in design, [`patches/in_design/boxbox_collinear.diff`](../patches/in_design/boxbox_collinear.diff) (switch
`MUJOCO_BOXBOX_COLLINEAR=1`, `engine_collision_box.c` only, 35 lines added, none removed), drops from the clipped
polygon every vertex that lies on a straight line with its two neighbours. "Straight" means to the noise level MuJoCo's
separation test already uses for parallel edges (`mjBOXBOX_PAREPS`). In run 074 it stood every stack of run 052's grid
(released, 20 of 60 tilt) with no contact change. It changed nothing else played, and none of MuJoCo's tests.
In run 075, with Senua AI's set in the same build, it stood every straight stack played. That was 3 to 12 cubes at
steps from 0.1425 to 1.71 ms, and a stack of 5 on a fixed box, with no contact change. Released, 8 of the 20 straight
stacks tilt, and with the set's three patches 9 do. Nothing else the set plays changed, and of MuJoCo's tests only the
two Study 12 named.

On numbers no earlier study or probe used, with Senua AI's set and this patch: does every straight stack stand, at three
steps and three main tolerances, with its contacts unchanged and its cubes at rest? With the patch alone, under MuJoCo's
defaults, does every straight stack stand? Is everything else the set plays exactly as without the patch? With every
switch unset, is the patched MuJoCo the release? Do any of MuJoCo's tests change?

## Engines and arms

- **rel_def**, **rel_rec**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
  139577c541d43716...), under MuJoCo's defaults and under the configuration.
- **off_def**, **off_rec**: MuJoCo built from its source at the commit in `UPSTREAM_COMMIT` with four patch files applied:
  Senua AI's three validated patches ([`invweight_at_pose_v3.diff`](../patches/invweight_at_pose_v3.diff),
  [`desaxce_elliptic_v4.diff`](../patches/desaxce_elliptic_v4.diff), [`qcqp_reduced.diff`](../patches/qcqp_reduced.diff))
  and this one. Built with gcc, CMake and Ninja, a Release build, its tests built the same way, rebuilt by the runner
  from the patch files; every switch unset.
- **set_rec**: Study 15's three switches set, under the configuration.
- **set4_rec**: those and the collinear switch, under the configuration.
- **col_def**: the collinear switch alone, under MuJoCo's defaults.

MuJoCo's own test suite on the release's test build (run 020's) and on the patched one: every switch unset, the four
set, and the collinear switch alone. Played on the first cloud machine (AWS EC2 c7i.xlarge, Intel, 4 virtual CPUs, 8 GB).

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_077_study_16/play.sh`](../validation/run_077_study_16/play.sh) | 884b1df3d15cc33e... |
| Rigs | `tools/mjc_stack.c` (with `contacts`, unchanged without it, run 069), `tools/mjc_arm.c`, `tools/mjc_contact.c`, `tools/mjc_grip.c` | d147f7f6d84775ae..., d52885fb08c646ff..., 31ea6cc56a204143..., a57125297b421248... |
| | `tools/build_rig.sh` | b6a93676e6aee763... |
| Senua AI's measures | `sx_contact rule`, as run in Studies 10 to 15 | source 87e921cd4d2c03bf... (built for Linux: f09ea027cec7820d...) |
| The patches | the three above and `patches/in_design/boxbox_collinear.diff` | d3fd45cc3d3ecfb0..., 00cb8f8eb4a07535..., 22f07ccf8abf316e..., dcb3bfcef68fbb1c... |

## The numbers, and how they were drawn

By Study 10's procedure, from x(0) = 16. The stack's cube is drawn on run 026's and Study 12's ranges for stacked cubes
(0.3 to 0.6 kg, half-size 35 to 50 mm, friction 0.4 to 0.7). The cube held and slid is drawn on Study 10's ranges. A
value the record already used for a quantity of the same kind was drawn again: Study 15's lists, the values Study 15
drew, the settings of runs 071 to 076, and any value this draw had already given that kind. Three draws were redrawn: a
half-size of 50 mm, and speeds of 0.95 and 0.85 m/s. `DRAW=1 bash validation/run_077_study_16/play.sh` prints the draw.

| What | The numbers |
|---|---|
| The steps | 1.22 ms, a quarter of it, 0.305 ms, and an eighth, 0.1525 ms |
| The stack's cube | 0.596 kg, half-size 0.0405 m, friction 0.528 |
| The cube held and slid on a box's face | 1.561 kg, half-size 0.0489 m, friction 0.438, slid at 1.09 m/s |

Not drawn: the stack sizes (3, 5, 9 and 12 cubes) and main tolerances (MuJoCo's default, 1e-10 and 1e-12), from run 052's
grid; the offsets (1 mm and 17 mm) and the base box (half-size 0.5 m), from runs 026 and 075; the plays' lengths. The arm
and the grip are Study 15's, played only for the byte comparisons N1 and N2, which no number of theirs decides.

## The scenes

Each arm:

- straight stacks of 3, 5, 9 and 12 cubes, 2 s, at each step and each main tolerance (36 plays), each with its contacts
  traced;
- at the quarter step, stacks of 3 offset by 1 mm and by 17 mm a cube, and a stack of 5 on a fixed box;
- at the coarse and the quarter step: Study 15's arm set down and dropped in two poses; the cube held at 0.5 and 0.95 of
  its friction limit; the same cube slid on a fixed box's face; Study 15's grip, box and mesh pads, at the centre and
  off it.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. A stack's tilt is the most any of its
cubes turns from upright over the play; its end speed is the fastest any cube moves at its last step; its contact
changes are the changes in the number of contacts between any two geoms after step 30, from its contacts trace.

| Rule | Statement | From |
|---|---|---|
| Q1 the release's stacks tilt | rel_rec: some straight stack tilts more than 100 urad | runs 049, 052, 070, 074 |
| E1 safe when off | Every play file off_def and off_rec make byte-identical to rel_def's and rel_rec's (2 lines) | Studies 5 to 15 |
| M0 every suite read | Each of the four readings of MuJoCo's suite lists all 3,492 tests | new: without it a missing reading would make E2, M1 and M2 compare nothing (found by the plumbing check) |
| E2 safe when off, MuJoCo's suite | Every switch unset: every one of MuJoCo's tests gives the release's result | their R2 |
| M1 MuJoCo's suite, the four switches set | Against every switch unset, no test changes but `ForwardTest.DiscreteImplicitRowNoslip` and `SolverTest.ZeroToleranceDisablesTermination` | Study 15's M1 |
| M2 MuJoCo's suite, the collinear switch alone | Against every switch unset, no test changes | runs 074 and 075 |
| S1 every stack stands | set4_rec: every one of the 36 straight stacks tilts at most 10 urad | new |
| S2 its contacts never change | set4_rec: no change in any straight stack's contacts after step 30 | new, from run 074 |
| S3 every stack at rest | set4_rec: every straight stack's cubes at most 10 um/s at its last step | Study 2's R2 bound |
| S4 the patch alone, under MuJoCo's defaults | col_def: every one of the 36 straight stacks tilts at most 10 urad | new |
| N1 nothing else changes, in the set | set4_rec against set_rec: every file of the arm, the holds, the slide on a box's face and the grips byte-identical | Studies 12 to 15 |
| N2 nothing else changes, alone | col_def against rel_def: the same files byte-identical | Studies 12 to 15 |
| V1 the solver | set4_rec: no step at 100 iterations or more; no warning (2 lines) | Studies 5 to 15 |

There are 15 rule lines. The stacks' play files are kept compressed (`gzip -n`), after every reading of them. Reported,
not ruled: the offset stacks and the stack on a base box (their faces overlap only in
part, finding F11), the stacks under set_rec, the most iterations on a step, and MuJoCo's tests that change.

## The decisions

- **Issue 21, a straight stack does not stand at a fine step under the recommended configuration**: if every rule
  holds, it is recorded as **fixed and validated** by Senua AI's set with the collinear patch, and the patch moves from
  `patches/in_design/` to `patches/`. Under MuJoCo's defaults, S4 and N2 validate the patch alone.
- A rule that fails is recorded as measured, with its numbers, and what it concerns stays open.
- Not decided: issue 9 (a stack sinks at every contact, and an offset stack leans). Stacks offset by 1 mm a cube lean
  about 2 mrad under the configuration, released and patched alike, with their contacts changing hundreds of times,
  against 86 urad and no change under MuJoCo's defaults (run 075 and the dry run); they are reported here and probed
  under issue 9. Also not decided: boxes of unequal size and plates, whose clipped polygons this study plays only
  through the base box; RK4; MuJoCo's PGS solver; anything against a real robot.

## Known risks, stated before the run

- **Q1**: whether a released stack tilts depends on the last digits of the solve (run 052). Of run 074's 60 plays, 20
  tilted. Of this study's 36, none might.
- **S1 and S4**: a stack can lean for a reason other than the clip's collinear points. The offset stacks lean for one
  (F11), and are reported only.
- **N1**: the grip with box pads is a box-on-box contact. Its pads and cube differ in size, so no edge lies on a side
  plane and nothing should change (runs 074 and 075). A collinear vertex in it would change it.
- **M1 and M2**: runs 074 and 075 changed no test with the collinear switch.

## What is not asked

Everything listed as not decided above.

## Dry run

`DRY=1` played the seven arms on throwaway numbers (run 063's cube, and steps of 1.14, 0.285 and 0.1425 ms), with no
build and no MuJoCo suite. The patched arms used run 075's build of the same four patch files. It played to the end: 280
measured lines, none empty ([`validation/run_077_study_16/dry/`](../validation/run_077_study_16/dry/)).

Its first pass kept the stacks' play files whole, 594 MB, so the runner now keeps them compressed after every reading
of them, and the dry run was played again with that ending.

The rules were then judged on its lines in a scratch copy
([`dry/rules_plumbing.sh`](../validation/run_077_study_16/dry/rules_plumbing.sh)) to check the plumbing. Run 064's
release and runs 068 and 074's suite results stood in for the four suites, with one test changed by hand in the
collinear-alone suite. All rule lines were judged, and M2 failed on the changed test as it should
([`dry/rules_plumbing.txt`](../validation/run_077_study_16/dry/rules_plumbing.txt)). A first plumbing check found that
with a suite reading missing, E2, M1 and M2 compared nothing and held. M0 was added for that, and judged again with one
reading removed, it fails. No rule is read from the dry run.
