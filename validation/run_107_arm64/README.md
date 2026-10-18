# Run 107: MuJoCo on arm64 against Intel, and the cause of the difference

17 October 2026 (22:58 to 23:14 UTC). Not registered: a design probe on an arm64 machine (AWS EC2 c7g.xlarge, Graviton3,
Neoverse V1) and the first cloud machine (Intel Xeon Platinum 8488C), both Ubuntu 24.04 with gcc 13.3.0, pushed before
its plays in four steps: [`probe.sh`](probe.sh) and [`compare.sh`](compare.sh); then, written after step 1's
comparison, [`probe_2.sh`](probe_2.sh) and [`compare_2.sh`](compare_2.sh); [`probe_2b.sh`](probe_2b.sh) and
[`probe_2c.sh`](probe_2c.sh), after the clang builds' rigs failed to link (below). It finds where to look and decides
nothing. Every play file, solver statistic and comparison is kept.

## Why

MuJoCo documents determinism only within one version on one architecture (issue 18). The record had played Intel only,
on macOS and Linux. MuJoCo's x86-64 builds compile with `-mavx` and use hand-written AVX code for vector sums; on arm64
there is no AVX and the plain loops run. A compiler may also fuse a multiply and an add into one rounding (FMA) on arm64,
which x86-64 code built without `-mfma` never does.

## The builds

| Machine | Build | What it is |
|---|---|---|
| arm64 | relA | Google DeepMind's arm64 Linux release, `mujoco-3.16.0-linux-aarch64.tar.gz`, its sha256 checked ([`release_check.txt`](arm/release_check.txt)) |
| arm64 | srcA | MuJoCo from its source at the pinned commit, gcc, MuJoCo's own CMake options |
| arm64 | srcAnc | the same with `-ffp-contract=off` |
| arm64 | setAnc | Senua AI's set (the six validated patch files, every switch set), gcc, `-ffp-contract=off` |
| arm64 | clangA | MuJoCo from its source with clang 18.1.3, MuJoCo's own options |
| arm64 | clangAnc | the same with `-ffp-contract=off` |
| Intel | relX | Google DeepMind's x86-64 Linux release, the record's |
| Intel | srcXna | MuJoCo from its source, gcc, `MUJOCO_ENABLE_AVX` and `MUJOCO_ENABLE_AVX_INTRINSICS` off |
| Intel | setXna | Senua AI's set the same way |

Every build played the same 108 plays twice ([`probe.sh`](probe.sh)): under MuJoCo's defaults, Study 13's slide along
three directions at two steps, a held cube, Study 18's chain and tumbling body under Euler and RK4, a stack of ten,
MuJoCo's box; under Senua AI's configuration, the slides, the cubes Studies 19 and 20 held, Study 15's arm and grip,
stacks of three offset 5 mm and of ten, two boxes; under its hold form, the free cube and the stacks.

## What it found

Byte for byte ([`compare.txt`](compare.txt), [`compare_2.txt`](compare_2.txt)):

| Pair | Play files the same | Solver's statistics |
|---|---|---|
| Every build against its own second play, on both machines (9 builds) | 108 of 108 | the same |
| srcA (gcc, arm64) against relX (Intel release) | **108 of 108** | the same |
| srcAnc against relX; srcXna (Intel, no AVX) against relX; srcAnc against srcXna | 108 of 108 | the same |
| setAnc (Senua AI's set, arm64) against setXna (the set, Intel) | **108 of 108** | the same |
| **relA (Google's arm64 release) against relX** | **61 of 108** | different |
| clangA (clang, arm64) against relA | 108 of 108 | the same |
| clangA against relX | 61 of 108 | different |
| **clangAnc (clang, no FMA) against relX** | **108 of 108** | the same |

- MuJoCo built with clang on arm64 makes Google's arm64 release's bytes exactly, and with fused multiply-add turned
  off makes the Intel release's. MuJoCo built with gcc does both without a flag: MuJoCo's CMake builds its C as ISO
  C11 (`CMAKE_C_EXTENSIONS OFF`), and gcc does not fuse in a standard C mode. The hand-written AVX code changes
  nothing in these plays.
- The 47 files that differ are the stacks of three and of ten under the configuration, the stack of ten under its
  hold form, and Study 19's box; they first differ at step 234 to 1,435. Where the play comes to rest, the final
  state is the same to the nanometre ([`readings.txt`](readings.txt)); where it is still moving, the difference grows: MuJoCo as released (no
  patches) keeps a stack of ten turning at up to 37,833 urad/s under the configuration (issue 21's straight stack),
  and there the two machines end apart. In Senua AI's set those stacks are at rest, at 0 urad/s, and arm64 and Intel
  make the same bytes.

**The rigs and clang** ([`arm/progress.txt`](arm/progress.txt)): MuJoCo built with clang calls one of clang's own
runtime routines (`__muloti4`), which gcc's link does not supply, so step 2's rigs failed to link; step 2b added
clang's builtins archive to the rigs' link, which failed too (the routine is hidden there); step 2c linked MuJoCo's
library against clang's runtime (`-rtlib=compiler-rt`), as a clang toolchain links it, and built the rigs unchanged.

## What it means

- MuJoCo is deterministic on arm64 as on Intel, and the same bytes on both when built with gcc, or with clang and
  `-ffp-contract=off`. The difference is the release's compiler fusing a multiply and an add on arm64, a rounding the
  IEEE 754 standard allows; it shows where a play is still moving, as a chaotic motion amplifies any last digit.
- The next step is a registered study on plays no probe has made.
