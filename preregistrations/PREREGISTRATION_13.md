# Thirteenth pre-registration: 100 noslip iterations, for a joint held by friction

Registered 16 October 2026, after the design probes of runs 052 and 054. Registered before any play of this
registration existed. To be played once, as run 058.

## The question

Issue 6 of [the issue list](../docs/issues.md) (known issue M13): a joint held by dry friction larger than the load on
it creeps. Released, run 001's single joint creeps at 25,670 urad/s and Study 10's two-link arm, held 1 m up by joint
friction above gravity's torque, at 30 mm/s at its ball. Under Senua AI's configuration (the elliptic cone with 10 noslip
iterations) the arm still creeps, at 93 and 25 um/s in Study 10's poses: MuJoCo's noslip solver, which also acts on dry
friction rows, stops at its 10th iteration before the arm's two coupled rows converge. In run 054, a probe, 100 noslip
iterations held it to 2 um/s and changed no other file of the configuration's cube, grip and suite plays.

On numbers no earlier study or probe used: with 100 noslip iterations in place of 10, does Senua AI's configuration hold
a joint by friction within the record's bound for a hold, and leave everything else it plays exactly as it was?

## Engines and arms

Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256 139577c541d43716...),
three arms: **def**, MuJoCo's defaults; **n10**, the configuration (`cone=elliptic`, `noslip_iterations=10`); **n100**,
the elliptic cone with `noslip_iterations=100`. No patch: both are MuJoCo's own options. Played on the first cloud
machine (AWS EC2 c7i.xlarge, Intel, 4 virtual CPUs, 8 GB).

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_058_study_13/play.sh`](../validation/run_058_study_13/play.sh) | c440606c3e7692f4... |
| Rigs | `tools/mjc_joint.c` (with `noslip` and `cone`, unchanged without them), `tools/mjc_arm.c` (with `trace`, unchanged without it), `tools/mjc_contact.c`, `tools/mjc_grip.c` | 6cafd42bdeb5617c..., 61a11f17ebb81d4f..., 31ea6cc56a204143..., a57125297b421248... |
| | `tools/contact_suite.sh`, `tools/build_rig.sh` | 8cda2ed242cad7df..., b6a93676e6aee763... |
| Senua AI's measures | `sx_contact` (`creep`, `stop`, `rule`), as run in Studies 10 to 12 | source 87e921cd4d2c03bf... (built for Linux: f09ea027cec7820d...) |
| | The first deep dive's suite runner, `sx_contact_suite.sh`, as run | 553d46ecdaf2bd95... |

## The numbers, and how they were drawn

By Study 10's procedure, from x(0) = 13, on Study 10's ranges and grids, with two new quantities: the single joint's
cube, half-size and arm on the ranges of the values the record played (1 to 2 kg, 0.04 to 0.05 m, 0.4 to 0.5 m), and its
dry friction drawn again until it is from 1.2 to 2 times gravity's torque on the level arm (run 001: 1.53). A value the
record already used for a quantity of the same kind (Study 12's lists, the values Studies 10 to 12 drew, the settings of
runs 043 to 056), or one this draw had already given that kind, was drawn again: eight were (half-sizes of 0.0435 and 0.05 m, a torque of 5.50 N m, angles
of 1.000, 0.900 and 0.924 rad, squeezes of 3.02 and 2.45 N). The squeeze was drawn again four more times until the two
pads' friction was 1.7 to 2 times the grip cube's weight. `DRAW=1 bash validation/run_058_study_13/play.sh` prints the
draw.

| What | The numbers |
|---|---|
| The steps | 1.68 ms, and a quarter of it, 0.42 ms |
| The single joint | a cube of 1.423 kg, half-size 0.0485 m, 0.403 m from its hinge, held level by 8.79 N m (1.56 times gravity's 5.62) |
| The arm | links of 0.297 m and 0.302 m, 1.08 kg and 0.578 kg, a ball of 0.0295 m and 0.194 kg, friction 0.778 |
| Held 1 m up | poses (0.165, 0.924) and (0.146, 0.628) rad, joint friction 5.63 N m on each hinge |
| On contact (reported) | poses (0.516, 0.907) and (1.211, -0.464) rad, set down from 0.52 mm |
| The cube held and slid | 1.714 kg, half-size 0.0454 m, friction 0.44, slid at 0.86 m/s |
| The first suite's cube | 1.438 kg, half-size 0.0331 m, dropped from 0.071 m, launched at 2.97 and 0.96 m/s, friction 0.42, slid at 3.5 m/s, held at friction 0.468 |
| The grip | a cube of 0.209 kg, half-size 0.0349 m, friction 0.762, squeezed with 2.55 N (the pads' friction 1.90 times its weight), and 9.8 mm off centre |

## The scenes

Each arm, at both steps: the single joint held level, 2 s; the arm held 1 m up by joint friction in each pose, 2 s; the
cube held at 0.5, 0.75 and 0.95 of its friction limit along 0, 22.5 and 45 degrees (18 plays), slid along each kept from
turning and free to turn; the grip, box and mesh pads, at the centre and off it; the arm set down on its ball in each
contact pose, 2 s, traced (played and reported, not ruled); and the first contact suite on the fresh cube.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. A creep is `sx_contact creep`'s mean
speed over the play's second half: for the single joint its turning speed, for the arm its ball's speed, for a cube its
speed.

| Rule | Statement | From |
|---|---|---|
| Q1 the release's joint creeps | def: the single joint turns at least 100 urad/s at one step | run 001 |
| Q2 the release's arm creeps | def: the arm held by joint friction creeps at least 100 um/s in one pose at one step | Study 10, run 034 |
| Q3 the configuration's arm creeps | n10: the arm creeps more than 10 um/s in one pose at one step | Study 10, run 052 |
| J1 the joint holds | n100: the single joint turns at most 24 urad/s at both steps (10 um/s at the cube's centre, 0.403 m out) | Study 2's R2 bound, 10 um/s |
| J2 the arm holds | n100: the arm creeps at most 10 um/s in both poses at both steps | Study 2's R2 |
| N1 nothing else changes | Every file n100's cubes, grips and suite play byte-identical to n10's (not the files that record the settings: the rigs' statistics and the suite's CONFIG) | run 054 |
| H1 every hold holds | n100: all 18 holds creep at most 10 um/s | Study 2's R2 |
| G1 the grip holds | n100: all 8 grips creep at most 10 um/s | Study 10's G1 |
| K1 the ten tests | n100: the first suite 10 of 10 | Study 2's R5 |
| V1 the solver | n100: no step at 100 iterations or more (MuJoCo counts noslip's with the main solver's); no warning (2 lines) | Studies 5 to 12 |

There are 11 rule lines. The resting arm and the most iterations on a step are reported, not ruled.

## The decisions

- **Issue 6, a joint held by friction creeps**: if Q1 to Q3, J1, J2, N1, H1, G1, K1 and V1 hold, it is recorded as
  **fixed and validated by Senua AI's configuration with 100 noslip iterations**, and the record's recommended
  configuration becomes the elliptic cone with 100 noslip iterations. Studies 2, 10 and 11 were played with 10; N1 is
  what carries their contact results over, on this study's plays.
- If J1 and J2 hold and N1 does not, the files that differ are recorded with their readings, and the recommendation is
  not changed.
- A rule that fails is recorded as measured, with its numbers, and what it concerns stays open.
- Not decided: issue 1's resting arm (run 056: noslip under the elliptic cone does nothing for its contact); a joint
  equality with joint friction (issue 14); the inverse weight patch and the de Saxce patch, not played here.

## Known risks, stated before the run

- **V1**: MuJoCo counts noslip's iterations with the main solver's, so a step on which noslip runs all 100 counts as at
  the limit. In run 054, on Study 10's numbers, 100 noslip iterations reached at most 23 a step.
- **N1**: in run 054, with 100 noslip iterations, every cube, grip and suite file was byte-identical to 10's; only the
  offset stack at 0.1425 ms differed (not played here). On fresh numbers a contact on which 10 noslip iterations do not
  converge would differ.
- **J2**: run 054's arm crept 2 um/s at 100 iterations, against the bound's 10; another arm's coupled rows may need more.

## Dry run

`DRY=1` played the three arms on throwaway numbers (Study 10's arm, cubes and grip; run 001's joint) to the end: 150
measured lines, none empty ([`validation/run_058_study_13/dry/`](../validation/run_058_study_13/dry/)). It reproduced the
record's readings for the same scenes (the released joint 25,670 urad/s as in run 001; the arm 93 and 25 um/s with 10
noslip iterations and 2 with 100, as in run 054). The rules were then judged on its lines in a scratch copy to check the
plumbing ([`dry/rules_plumbing.txt`](../validation/run_058_study_13/dry/rules_plumbing.txt)): N1 at first counted the
suite's CONFIG file, which records the settings and so differs between the arms by design; the runner was corrected to
compare the play files only, as it already left out the rigs' statistics, and then judged all 11 lines. No rule is read
from the dry run.
