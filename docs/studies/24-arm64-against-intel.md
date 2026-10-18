# Study 24: MuJoCo across architectures, arm64 against Intel

| | |
|---|---|
| Question | MuJoCo documents determinism only within one version on one architecture. On plays no probe has made, is MuJoCo deterministic on an arm64 machine as on Intel, does a build without fused multiply-add make the same bytes on both, and does Google DeepMind's arm64 release depart? |
| Outcome | **12 of 12 rule lines held.** Issue 18 fixed and validated by configuration: MuJoCo built from its source with gcc, or with clang and `-ffp-contract=off`, makes the same bytes on arm64 as on Intel, and so does Senua AI's set. Google's arm64 release departs on contact-rich plays, by its compiler's fused multiply-add. |
| Registered | [`PREREGISTRATION_24.md`](../../preregistrations/PREREGISTRATION_24.md), pushed with its runner, judge, dry run and rules plumbing check on 17 October 2026, before any play |
| Played | Once, as [run 108](../../validation/run_108_study_24/README.md), 17 October 2026, 23:27 to 23:31 UTC, on an arm64 machine (AWS EC2 c7g.xlarge, Graviton3) and the first cloud machine (Intel), both Ubuntu 24.04 with gcc 13.3.0 |
| Arms | arm64: Google DeepMind's arm64 release; MuJoCo from its source with gcc; with clang and no fused multiply-add; Senua AI's set with gcc. Intel: the x86-64 release; Senua AI's set with gcc |
| Measured by | Files compared byte for byte, Senua AI's measure (`final`), judged by the Senua AI Robotics Core's `rule` |

## Why it was asked

The record had played Intel only, on macOS and Linux. [Run 107](../../validation/run_107_arm64/README.md) played 108
plays on arm64 and Intel: built with gcc, MuJoCo made the Intel release's bytes in every one; Google's arm64 release
departed in 47, and a clang build reproduced the release exactly. Clang fuses a multiply and an add into one rounding
by default ([clang's manual](../references.md#clang-fp-contract)); gcc does not in a standard C mode such as MuJoCo's ISO
C11 build ([gcc's manual](../references.md#gcc-fp-contract)). IEEE 754 allows either ([references](../references.md#ieee-754)).

## What it found

| Pair, 114 fresh plays a build | The same | Rules |
|---|---|---|
| Every build against its own second play, on both machines | 114 of 114, all six | 6 of 6 |
| MuJoCo with gcc on arm64, and with clang without fused multiply-add, against the Intel release | 114 of 114 each | 2 of 2 |
| Senua AI's set on arm64 against the set on Intel | 114 of 114 | 1 of 1 |
| Google's arm64 release against the Intel release | 64 of 114: it departs on the contact-rich plays under the elliptic cone with noslip | 1 of 1 |
| Both machines drew the same numbers; every play made | | 2 of 2 |

## What it decides

- **Issue 18 fixed and validated by configuration**: build MuJoCo from its source with gcc and MuJoCo's own options, or
  with clang and `-ffp-contract=off`, and a play gives the same bytes on arm64 as on Intel.
- Google's arm64 release is recorded as departing from Intel by its compiler's fused multiply-add, at the last digit,
  which a play still moving amplifies (run 107).
- Not decided: other architectures, compilers or versions; MuJoCo's GPU ports (issue 19).
