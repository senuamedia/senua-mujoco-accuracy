# Run 002: run 001 replayed on another machine and operating system

15 October 2026. Not registered: a check of the record before any study. Run 001's probe scripts were played again,
unchanged, by [`replay.sh`](replay.sh), and every run file and reading compared byte for byte with run 001's
(`compare.txt`).

| | Run 001 | Run 002 |
|---|---|---|
| Machine | MacBook, Intel Core i5-1038NG7 | AWS EC2 c7i.large, Intel Xeon Platinum 8488C |
| Operating system | macOS 26.6.2 | Ubuntu 24.04.5 LTS |
| MuJoCo 3.16.0 | Google DeepMind's macOS release (`mujoco-3.16.0-macos-universal2.dmg`, x86-64 slice) | Google DeepMind's Linux release (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256 139577c541d43716a63992ab698cbc7b09788b1d547fb82b682d59b40ef49b9d) |
| The rigs, built by | Apple clang 21.0.0 | gcc 13.3.0 |
| The measuring program | Senua AI's, built for macOS | the same program, built for Linux |

## The result

**95 of 95 files are byte-identical**: 90 run files (every step of every scene, and the solver's statistics) and 5
readings. MuJoCo's documentation promises determinism only within one version on one architecture; here two builds,
two operating systems and two processors of the same architecture gave the same bytes (the Linux release records clang
20.1.8 as its compiler; the macOS release names none, so this run does not show two compilers; run 004 does, against
a gcc build). Corrected in the audit (`docs/audit.md`).

## What the first replay found

The first replay matched 76 files and found 22 that did not. None was MuJoCo's: all were run 001's own.

- Eight limit plays and `reading_04.txt` had been made by the joint rig before its limit mapping was fixed, so the
  committed `probe_04.sh` and rig did not remake them. Played on this Mac with the committed rig, they are
  byte-identical to the Linux plays.
- Fourteen runs (`reading_04b.txt`, `reading_04c.txt`) came from commands that had no script.

Run 001 was corrected (its README says how): the stale plays are kept under `runs/before_fix/` as the record of the
error, the corrected plays replace them, and a new script, `probe_04c.sh`, remakes `reading_04c.txt` and its eight runs
byte for byte on both machines. The six plays behind `reading_04b_before_fix.txt` need the rig as first written and
are not remade. The replay was then played again, with `probe_04c.sh` added, giving the result above.

The integrator line of `probe_02.sh` that asks for `rk4` fails on both machines with MuJoCo's "invalid keyword", as
run 001 records: the keyword is `RK4`, in capitals.

## What it means for the record

From here on, studies may be played on either machine. Run 001's numbers stand as published.

## After run 006

Run 006 corrected the contact rig (its height column had run one step behind the other columns). This run was played
with the rig as it stood; played today with the corrected rig, `replay.sh` would find the contact files shifted by one
line in that column against run 001's.
