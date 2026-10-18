# Eighteenth pre-registration: MuJoCo's RK4 integrator, for a free body's energy

Registered 17 October 2026, after runs 007, 014 and 039 and Study 9. Registered before any play of this registration
existed. To be played once, as run 081.

## The question

Issue 11 of [the issue list](../docs/issues.md) (F4): MuJoCo's integrators do not keep a free body's energy. With
nothing acting on it, a body's energy and angular momentum must stay what they were, whatever the step.
- **The free chain.** Under MuJoCo's default Euler, a free two-link chain gains 9.7% of its energy in 2 s at 10 ms, and
  implicit loses it at the same rate (run 007). MuJoCo's RK4 kept the free chain's energy to 1 ppm in runs 007 and 014, and its
  momentum to 1 ppm in run 007. Those were probes.
- **The tumbling body.** Study 9 found RK4 keeping a tumbling body's energy and momentum at every step, 8 of 8 rule
  lines, and the other three integrators not.

On numbers no earlier study or probe used: does RK4 keep a free chain's energy and angular momentum, and a tumbling
body's, at every step played, where MuJoCo's default integrator does not?

## Engine

Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256 139577c541d43716...), under
each of its four integrators: Euler (MuJoCo's default), implicitfast, implicit and RK4. No build and no patch: the
question is about MuJoCo's own option. Played on the first cloud machine (AWS EC2 c7i.xlarge, Intel, 4 virtual CPUs,
8 GB).

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_081_study_18/play.sh`](../validation/run_081_study_18/play.sh) | cbb464cf872771d2... |
| Rigs | `tools/mjc_chain.c` (run 007's scene), `tools/mjc_tumble.c` (Study 9's), `tools/build_rig.sh` | 568fa6d2beea3819..., 881beecd23d66e0f..., b6a93676e6aee763... |
| Senua AI's measures | `sx_contact` (`chain`, `rule`), as run in runs 007 and 014 and Studies 10 to 17; `sx_tumble`, as run in Study 9 | source 87e921cd4d2c03bf... (built for Linux: f09ea027cec7820d...); source 21e07a0c3c3b21dc... (built for Linux: f64a96bf1bdbb3fd..., as in Study 9) |

## The numbers, and how they were drawn

By Study 10's procedure, from x(0) = 18. The chain is drawn on ranges about run 007's scene, and the tumbling body by
Study 9's procedure: its moments drawn again until they can belong to a body and no two are within 1 part in 10, its
spin drawn again until its size is 2 to 4 rad/s and each component at least 0.5 rad/s. A value the record already used
for a quantity of the same kind was drawn again: Study 17's lists, the values Studies 9 and 17 drew, the chain of runs
007, 014 and 039, and any value this draw had already given that kind. Three spins were drawn again whole, and one
component once. `DRAW=1 bash validation/run_081_study_18/play.sh` prints the draw.

| What | The numbers |
|---|---|
| The steps | 6.25 ms, and a quarter, a sixteenth and a sixty-fourth of it: 1.5625, 0.390625 and 0.09765625 ms |
| The chain | arms of 0.915 kg and 0.587 kg, cubes of half-size 0.0329 m, centres 0.224 m and 0.181 m from their joints, the joints 0.462 m apart |
| Free, no gravity | the second joint at -0.616 rad, set turning at 2.73 and 1.86 rad/s |
| Swinging, reported only | from rest at 0.259 and -0.41 rad, under gravity |
| The tumbling body | principal moments 0.003484, 0.008062 and 0.009857 kg m2, spin (0.65, 1.98, -2.26) rad/s in its own frame |

Not drawn: the play's length (2 s) and the four integrators.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else. A drift is the largest departure over
the play, in parts per million. For the chain it is `sx_contact chain`'s `energy_largest_drift_ppm` and
`momentum_largest_drift_ppm` (its angular momentum about the first joint). For the tumbling body it is `sx_tumble`'s
`energy_largest_ppm` and `momentum_largest_ppm`.

| Rule | Statement | From |
|---|---|---|
| Q1, Q2 the default integrator drifts | Euler, at 6.25 ms: the free chain's and the tumbling body's energy drift at least 1,000 ppm (2 lines) | run 007, Study 9 |
| R1, R2 RK4 keeps the free chain | Its energy and its angular momentum within 100 ppm at every step (2 lines) | Study 9's momentum bound |
| R3, R4 RK4 keeps the tumbling body | Its energy and its angular momentum within 100 ppm at every step (2 lines) | Study 9's momentum bound |
| V1 no warning | MuJoCo raises no warning in any play | Studies 5 to 17 |

There are 7 rule lines. Reported, not ruled: implicitfast and implicit, and the swinging chain under every integrator.
RK4 kept a swinging chain's total energy only to 1.1% at 10 ms in run 007, and gravity does work on it, so it is not a
free body.

## The decisions

- **Issue 11, the integrators do not keep a free body's energy**: if every rule holds, it is recorded as **fixed and
  validated by configuration**: MuJoCo's own RK4 keeps a free body's energy and angular momentum, a free chain and a
  tumbling body, at every step played. MuJoCo's default integrator, implicitfast and implicit do not.
- A rule that fails is recorded as measured, with its numbers, and the issue stays open.
- Not decided: a body under gravity or in contact; RK4 with Senua AI's set beyond what Study 15 ruled (the arm, holds,
  grips); the costs of RK4 the record has seen, which stay as recorded (the first suite's T01 cannot be read under it,
  Study 10, and the stacks tilt under it at 1.14 ms, run 068); anything against a real robot.

## Known risks, stated before the run

- **R1 and R2**: the chain's joint angles are whole micro-radians in the rig's files, so the measure's own rounding sits
  near 1 ppm (run 007).
- **Q1**: at 6.25 ms, Euler's drift is expected near 6% from run 007's 9.7% at 10 ms.

## What is not asked

Everything listed as not decided above.

## Dry run

`DRY=1` played the four integrators on throwaway numbers (run 007's chain, Study 9's dry-run body) at 10, 2.5, 0.625 and
0.15625 ms to the end: 49 measured lines, none empty
([`validation/run_081_study_18/dry/`](../validation/run_081_study_18/dry/)). The rules were then judged on its lines in a
scratch copy ([`dry/rules_plumbing.sh`](../validation/run_081_study_18/dry/rules_plumbing.sh)): 7 rule lines, each
judged. Judged again with one RK4 chain reading changed by hand to 500 ppm, R1 failed as it should
([`dry/rules_plumbing.txt`](../validation/run_081_study_18/dry/rules_plumbing.txt)). No rule is read from the dry run.
