# Reproduce it

Everything here plays on a CPU. The rigs, the scripts and the Senua AI Robotics Core's measuring programs are all in this
repository: every version of the measure a run used is in [`measure/`](../measure/README.md), with the checksum each
registration cites.

## 1. MuJoCo

Google DeepMind's prebuilt 3.16.0 release for your machine: `mujoco-3.16.0-linux-x86_64.tar.gz` (sha256
139577c541d43716...) on Linux, `mujoco-3.16.0-macos-universal2.dmg` (sha256 e31ab79c0a5e4280...) on macOS. For the
patches, MuJoCo's source at the commit in [`UPSTREAM_COMMIT`](../UPSTREAM_COMMIT), built as in
[run 004](../validation/run_004_source_build/README.md), with Senua AI's six patch files applied in the order
[the patches page](patches.md#senua-ais-set-as-validated) gives, each switched on by its own environment variable. The
runners of the later studies build it this way themselves (for example
[Study 22's](../validation/run_099_study_22/play.sh)).

## 2. The rigs

```
MUJOCO_DIR=<the release folder> tools/build_rig.sh mjc_contact      # Linux
MUJOCO_FRAMEWORK_DIR=<folder holding mujoco.framework> tools/build_rig.sh mjc_contact   # macOS
```

and the same for `mjc_pair`, `mjc_joint`, `mjc_chain`, `mjc_rotvec`, `mjc_arm`, `mjc_stack`, `mjc_grip` and `mjc_tumble`. Each rig's first lines say what it plays and
what it writes.

## 3. A run

Every run folder holds the script that played it, with its usage on its first lines; for example
`validation/run_003_cone_and_large_steps/probe.sh <sx_contact>` from the repository root. The suites:
`tools/contact_suite.sh <label> [rig settings]` and `tools/contact_suite2.sh`, read by
[`measure/runners/sx_contact_suite.sh`](../measure/runners/sx_contact_suite.sh).

## 4. Compare

A replay is compared byte for byte with the files the run kept (`cmp`); [run 002](../validation/run_002_linux_replay/replay.sh)
and [run 006](../validation/run_006_height_column/replay.sh) are two such replays, with their comparison scripts.
MuJoCo's own documentation promises determinism within one version on one architecture; this record found the same
bytes across macOS and Linux on Intel processors.

## 5. The whole record

[`validation/audit/remake.sh`](../validation/audit/remake.sh) plays every run again by its own script, in order, in a
clean copy of the repository, with the build of MuJoCo and the rigs each run used, and compares every file with the
record. On the cloud machine it takes under a minute; [the audit](audit.md) gives its result.
