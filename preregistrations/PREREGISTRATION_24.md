# Twenty-fourth pre-registration: MuJoCo across architectures, arm64 against Intel

Registered 17 October 2026, after the probe of run 107. Registered before any play of this registration existed. To be
played once, as run 108. Every reading is made by Senua AI's measure as in Study 23.

## The question

MuJoCo documents determinism only within one version on one architecture (issue 18). Run 107 played 108 plays on an
arm64 machine and on Intel, each build twice: every build made the same bytes twice; MuJoCo built from its source with
gcc on arm64 made the Intel release's bytes in all 108, as did a build with clang and `-ffp-contract=off`, and Senua
AI's set the same bytes on both machines; Google DeepMind's arm64 release departed in 47, and a clang build with
MuJoCo's own options reproduced the release exactly: clang fuses a multiply and an add into one rounding on arm64 by
default. On plays no probe has made: is MuJoCo deterministic on each machine, does a build without fused
multiply-add make the same bytes on arm64 as on Intel, and does Google's arm64 release still depart?

## Machines, engines and builds

- **arm64**: AWS EC2 c7g.xlarge, Graviton3 (Neoverse V1), 4 virtual CPUs; **Intel**: the first cloud machine, AWS EC2
  c7i.xlarge, Xeon Platinum 8488C, 4 virtual CPUs. Both Ubuntu 24.04.5 with gcc 13.3.0; clang 18.1.3 on arm64.
- **relA**: Google DeepMind's arm64 Linux release (`mujoco-3.16.0-linux-aarch64.tar.gz`, sha256 2872f91a29dc4bb3...,
  checked by the runner). **relX**: the x86-64 Linux release (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
  139577c541d43716...), the record's.
- From MuJoCo's source at the commit in `UPSTREAM_COMMIT`, a Release build with MuJoCo's own CMake options, rebuilt by
  the runner: **srcA**, gcc on arm64; **clangAnc**, clang on arm64 with `-ffp-contract=off` and its library linked
  against clang's runtime (`-rtlib=compiler-rt`, as run 107 found it must be); **setA** and **setX**, Senua AI's set
  (its six validated patch files, applied in order, every switch set when played) with gcc on arm64 and on Intel.

Every build plays the whole list twice. The rigs are built by `tools/build_rig.sh` with gcc on each machine.

## What reads it

| Part | What | sha256 |
|---|---|---|
| The runner | [`validation/run_108_study_24/play.sh`](../validation/run_108_study_24/play.sh) | d2afa7c86bb12c15... |
| The judge | [`validation/run_108_study_24/judge.sh`](../validation/run_108_study_24/judge.sh) | fea9e78d07d93207... |
| Rigs | `tools/mjc_contact.c`, `mjc_chain.c`, `mjc_tumble.c`, `mjc_stack.c`, `mjc_scene.c`, `mjc_arm.c`, `mjc_grip.c`, `build_rig.sh` | ede2c01e51f69b6f..., 568fa6d2beea3819..., 881beecd23d66e0f..., 3b378e25435dfd98..., 07c71aabcaba5900..., 95d62875a35e6f1a..., ec91813ce6466ba8..., b6a93676e6aee763... |
| Scenes | MuJoCo's box ([`run_049`'s scene](../validation/run_049_desaxce_v4/step2/scene.xml)) and Study 19's six ([`run_085`'s scenes](../validation/run_085_study_19/scenes/)) | b10dbf28fc9e6c37...; the six: 45344c18b49b1674... together |
| Senua AI's measure | `sx_contact`: `final` and `rule` | source b1047b84134afc4f... (built for Linux: 1e58d74b416b3c98...) |
| The patches | Senua AI's six | d3fd45cc3d3ecfb0..., 00cb8f8eb4a07535..., 37cde954b88306bb..., dcb3bfcef68fbb1c..., 1e0ecc589760e23e..., ad0baec31bb13bc4... |

## The numbers, and how they were drawn

By Study 10's procedure, from x(0) = 24, on each machine (rule E0 checks the two draws are the same). A value the record
already used for a quantity of the same kind was drawn again: Study 22's lists, Study 20's friction list, Study 18's
chain and body, the values Study 23 drew, the settings of run 107, and any value this draw had already given that kind;
none was. `DRAW=1 bash validation/run_108_study_24/play.sh` prints the draw.

| Plays | The numbers |
|---|---|
| The slides | Step 0.999 ms and a quarter of it; a cube of 0.553 kg, half-size 0.0389 m, friction 0.483, set sliding at 0.787 m/s |
| The held and free cubes | Step 0.86 ms; a cube of 1.305 kg, half-size 0.0452 m, friction 0.519, held at 0.354 of its limit; the free cube at 0.95 |
| The chain and the body | Step 5.259 ms; links of 1.044 and 0.745 kg, radius 0.0497 m, the first 0.5375 m long with its centre 0.2702 m along, the second's centre 0.2157 m along; free, the elbow at -0.949 rad and the links at 2.467 and 1.329 rad/s; swinging from 0.346 and -0.362 rad; the body's inertias 0.005644, 0.006155 and 0.009399 kg m2, spinning at 1.891, 1.228 and -3.331 rad/s |
| The stacks | Step 1.045 ms; a cube of 1.789 kg, half-size 0.0599 m, friction 0.828; the offset stack 0.135 of the half-size a cube |

The ranges are in the runner's header. Not drawn: Study 15's arm, its poses and its grip; MuJoCo's box and Study 19's
six; the configurations (Study 23's).

## The plays

Every build, the same list (the runner's `plays`): under MuJoCo's defaults, the slide along 0, 30 and 45 degrees at the
step and a quarter of it, the held cube, the chain free and swinging and the body tumbling under Euler and RK4, a stack
of ten, MuJoCo's box; under Senua AI's configuration (the elliptic cone, 100 noslip iterations), the slides at the step,
the held cube, the free cube, Study 15's arm set down, dropped and held by joint friction, its grip with box and mesh
pads, the offset stack (6 s) and the stack of ten (2 s), MuJoCo's box and Study 19's six (16 s); under the hold form
(and impratio 1,000, every geom's solref at twice the step), the free cube and the two stacks; under the inverse form
(the elliptic cone, impratio 1,000, every geom's solref and every joint's solreffriction at twice the step, every
joint's solimpfriction 0.9999, no noslip), the free cube, the offset stack and the arm held by joint friction.

## The rules

Each is judged by `sx_contact rule` in [`judge.sh`](../validation/run_108_study_24/judge.sh), from files compared byte
for byte (`cmp`), and nowhere else.

| Rule | Statement | From |
|---|---|---|
| E0 the same numbers | The two machines' draws are the same file | Study 10's procedure |
| P0 every play made | Every build's two plays hold as many play files as relX's first | Study 22 |
| D1 deterministic on each machine | Each of the six builds makes every play file byte-identical the second time (6 lines) | run 107, MuJoCo's documentation |
| X1 gcc on arm64 as Intel | srcA's play files byte-identical to relX's, every one | run 107 |
| X2 clang without FMA as Intel | clangAnc's play files byte-identical to relX's, every one | run 107 |
| X3 the set on both | setA's play files byte-identical to setX's, every one | run 107 |
| Q1 the arm64 release departs | relA and relX differ in at least one play file | run 107 |

There are 12 rule lines. Reported, not ruled: which files differ between relA and relX, the first step each differs,
and both files' last state by `final`; the solver's statistics of each pair.

## The decisions

- If E0, P0, D1, X1, X2 and X3 hold, issue 18 is fixed and validated by configuration: MuJoCo built from its source with
  gcc, MuJoCo's own options, or with clang and `-ffp-contract=off`, makes the same bytes on arm64 as on Intel, and so
  does Senua AI's set. With Q1, Google's arm64 release is recorded as departing, by its compiler's fused multiply-add.
- If Q1 fails, the release made Intel's bytes on these plays, and that is recorded as measured.
- A rule that fails is recorded as measured, with its numbers, and issue 18 stays as it is.
- Not decided: other architectures, other compilers or versions, MuJoCo's GPU ports (issue 19).

## Known risks, stated before the run

- **Q1**: in run 107 the release departed only on stacks and one box under the elliptic cone with noslip, plays still
  moving where the last digit is amplified; on these numbers it may not depart at all.
- **X1**: gcc does not fuse in MuJoCo's ISO C11 build; MuJoCo's C++ parts build in ISO C++20 mode, where run 107 saw no
  difference.

## What is not asked

Everything listed as not decided above.

## Dry run

`DRY=1` played every build on both machines on throwaway numbers at the edges of the ranges (the slides' cube 0.3 kg,
60 mm, friction 0.9, 1.5 m/s at 2 ms; the held cube 2 kg, 25 mm, 0.3, at 0.9 of its limit and 0.5 ms; the chain at 10 ms
with links of 2 and 0.2 kg; the body's inertias 0.004, 0.006 and 0.0095; the stacks' cube 2 kg, 30 mm, 0.3, offset 0.15,
at 1.5 ms), with the same builds, to the end, in about 5 minutes: every build made 114 play files twice
([`validation/run_108_study_24/dry/`](../validation/run_108_study_24/dry/)). Its per-step play files are not kept; its
draws, statistics, comparisons and rule lines are. The judge then read it: all 12 rule lines held
([`dry/rules_plumbing.txt`](../validation/run_108_study_24/dry/rules_plumbing.txt)); Google's arm64 release departed in
50 of 114 files there, Study 19's boxes among them.

The rules were then judged on seven scratch copies of the dry run, each with one change made by hand so that one rule
must fail ([`dry/rules_changed.sh`](../validation/run_108_study_24/dry/rules_changed.sh)): a draw changed (E0), a
play file missing from both plays of a build (P0), one byte more in one file of a build's second play (D1), one byte
more in the same file of both plays of srcA, clangAnc and setA (X1, X2, X3), and relA's plays replaced by relX's (Q1).
Each change failed its own rule and no other, 11 of 12 held each time; the copy as it is held 12 of 12
([`dry/rules_changed.txt`](../validation/run_108_study_24/dry/rules_changed.txt)). No rule is read from the dry run.
