# Run 108: Study 24, MuJoCo across architectures, arm64 against Intel

17 October 2026 (23:27 to 23:31 UTC), on an arm64 machine (AWS EC2 c7g.xlarge, Graviton3) and the first cloud machine
(Intel). The twenty-fourth registered study ([`PREREGISTRATION_24.md`](../../preregistrations/PREREGISTRATION_24.md),
registered in commit d414376 before any play), played once by [`play.sh`](play.sh) (sha256 `d2afa7c86bb12c15`) on each
machine and judged by [`judge.sh`](judge.sh) (sha256 `fea9e78d07d93207`); its dry run and rules plumbing check in
[`dry/`](dry/). Every play file, solver statistic, comparison and rule line is kept.

**Outcome: 12 of 12 rule lines held** ([`rules.txt`](rules.txt)).

## The builds

| Machine | Build | What it is |
|---|---|---|
| arm64 | relA | Google DeepMind's arm64 Linux release, its sha256 checked ([`release_check.txt`](arm/release_check.txt)) |
| arm64 | srcA | MuJoCo from its source at the pinned commit, gcc 13.3.0, MuJoCo's own CMake options |
| arm64 | clangAnc | the same with clang 18.1.3, `-ffp-contract=off`, its library linked against clang's runtime |
| arm64 | setA | Senua AI's set (the six validated patch files, every switch set), gcc |
| Intel | relX | Google DeepMind's x86-64 Linux release, the record's |
| Intel | setX | Senua AI's set, gcc |

## The numbers

Drawn from seed 24 on each machine, the same on both ([`arm/draw.txt`](arm/draw.txt), [`x86/draw.txt`](x86/draw.txt)):
the slides at 0.999 ms and a quarter, a cube of 0.553 kg, 0.0389 m, friction 0.483, at 0.787 m/s; the held and free
cubes at 0.86 ms, 1.305 kg, 0.0452 m, 0.519, held at 0.354 of the limit; the chain and the body at 5.259 ms; the stacks
at 1.045 ms, a cube of 1.789 kg, 0.0599 m, 0.828, offset 0.135 of its half-size. 114 play files a build.

## What the rules read ([`compare.txt`](compare.txt))

| Pair | Play files the same | Rule |
|---|---|---|
| Each of the six builds against its own second play | 114 of 114 | D1, 6 of 6 |
| srcA (gcc, arm64) against relX (the Intel release) | **114 of 114** | X1 held |
| clangAnc (clang without fused multiply-add, arm64) against relX | **114 of 114** | X2 held |
| setA (Senua AI's set, arm64) against setX (the set, Intel) | **114 of 114** | X3 held |
| relA (Google's arm64 release) against relX | 64 of 114 | Q1 held: it departs |

- The 50 files where the release departs are the plays under Senua AI's configuration and its hold form that have many
  contacts: four of Study 19's boxes, the offset stack and both stacks of ten. Nothing under MuJoCo's defaults departs,
  nor under the inverse form. As in run 107, a clang build with MuJoCo's own options fuses a multiply and an add on
  arm64; the release is such a build.
- The solver's statistics are the same in every pair that holds, and differ where the release departs.
- Both machines played the same numbers (E0); every build made all 114 play files twice (P0).

## What it decides

- Issue 18 is fixed and validated by configuration: MuJoCo built from its source with gcc, MuJoCo's own options, or
  with clang and `-ffp-contract=off`, makes the same bytes on arm64 as on Intel, and so does Senua AI's set. Google's
  arm64 release, built with clang's default, departs on contact-rich plays: its compiler fuses a multiply and an add
  into one rounding, which IEEE 754 allows and gcc does not do in MuJoCo's ISO C build.
