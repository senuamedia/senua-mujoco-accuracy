# The audit

An end-to-end audit of this record, 16 and 17 October 2026. Every run is played again by its own scripts and every file
it keeps compared byte for byte; every specific number on the pages is traced to the files it is read from; every
link, character and the vocabulary is checked.

**State, 18 October 2026: the re-make complete to run 106, the number trace to run 100.** Every run from 001 to 106
re-makes byte for byte; every number on every page written to run 100 is traced; every link resolves; the measure is
corrected and every reading it changes placed or bounded. Runs 107 and 108 and the pages written since are next.

## The whole record re-made

### Runs 001 to 018

[`validation/audit/remake.sh`](../validation/audit/remake.sh) plays every run from 001 to 018 again by its own
script, in order, in a clean copy of the repository on the cloud machine. Each run uses the build of MuJoCo its
README names and the rigs as they were when it was recorded. Then every file those runs and `suites/` keep is
compared byte for byte with a second clean copy, the record. It ran in under a minute (`remake_log.txt`).

**Result: every play, every reading, every measured value and every rule line of runs 001 to 018 re-makes byte for
byte.** Of the 2,851 files, 2,831 are the same. 20 differ, none is missing, and 342 files exist only in the re-made copy
(`remake_compare.txt`). Each difference has a cause in the scripts, not the plays:
| Files | Why they differ | Checked |
|---|---|---|
| 14: every `finished*.txt`, `progress.txt`, and the `out*.txt` files of runs 016 to 018 | Clock readings, and the `rc=` line the original runs' launcher appended to `out*.txt` | Nothing else differs in them |
| `run_001_design_probes/runs/stats.txt` | `probe_01.sh` appends to the statistics file instead of starting it afresh, so a second play in a copy that holds it doubles it | The 20 lines the re-make appended equal the record's 20 |
| `compare.txt` of runs 002 and 006 | Each compares run 001's statistics file, doubled above | Every other line the same; run 004's comparison, re-made against the source build (`run004_compare_remade.txt`), the same way |
| Run 014's `reading.txt`, `out.txt`, `runs_B/stats.txt` | The run's first play of configuration B's chain asked for "RK" (its pattern cut the 4) and was replayed by `chain_B.sh`, whose lines the record appends at the end. The probe, corrected after the run, plays them in place | The six re-made chain lines equal the record's six `chain_B.sh` lines |

The 342 files only the re-make has: run 018's off arm, which the record keeps as readings only because its 263
files are byte-identical to the release arm's (as `identity_off.txt` records), and the working copies run 015's
script plays its suites into (`suites/1/s15_*`). Those equal, file by file, the 82 plays the record keeps under each
arm's `suite1_plays/`.

### Runs 019 to 042

[`validation/audit/remake_019_042.sh`](../validation/audit/remake_019_042.sh) plays every run from 019 to 042 again by
its own scripts, in order, in a clean copy of the repository on the first cloud machine (4 virtual CPUs, 8 GB),
rebuilding MuJoCo from its source and each run's registered patch file as the run did. Then every file the record keeps
for those runs, but their scripts, READMEs, run 022's input and the studies' dry runs, is compared byte for byte with
a second clean copy, the record (`remake_019_042_log.txt`, `remake_019_042_compare.txt`). It took 2 hours 14 minutes.

**Result: every play, every measured value and every rule line of runs 019 to 042 re-makes byte for byte.** Of the
7,942 files the record keeps for them, 7,769 are the same; 137 differ and 36 are missing, each for a cause in how the
files were kept, not in the plays:

| Files | Why they differ | Checked |
|---|---|---|
| 53: every `finished.txt`, `progress.txt` and `played_at.txt` | Clock readings | Nothing else in them differs |
| 42 `ctest_*.txt` and 28 build logs | Test durations, and the build tools' output | The tests' results are read from them into `suite_results_*.txt` |
| 12: `suite_results_*.txt` of runs 024, 029, 030 and 040 | One of MuJoCo's tests, `XMLReaderTest.LargeTextureAddressTest`, was killed for memory in every arm on the 3.8 GB machine those runs were played on (each run's README says so); on 8 GB it passes | Every other of the 3,492 lines the same; in each run it read the same in all three arms, so no rule's reading changes |
| 2: run 020's `patch_check.txt` and `patch_check_diff.txt` | The re-make ran the check after the test suite had left a test log and Python caches in the patched source tree | The only differences listed are those untracked files |
| 24 missing: every `out.txt` | Console logs, which the re-make does not keep | |
| 9 missing: `off/stats.txt` of runs 023, 024, 029 to 031, 033, 035, 037 and 038 | The record keeps an off arm's statistics file and verdicts only, its plays byte-identical to the release arm's (each README says so) | Each kept file equals the re-made one; the 124 other kept off-arm files are the same |
| 3 missing: run 020's `junit_*.xml.gz` | The record keeps the test reports compressed; the re-make writes them uncompressed | 3,492 tests in each |

The 1,860 files only the re-make has are the off arms' plays the record does not keep (the studies' R1 lines, re-made
byte for byte, count them identical to the release arm's) and run 020's three uncompressed test reports.

### Runs 043 and 044

[`validation/audit/remake_043_044.sh`](../validation/audit/remake_043_044.sh) plays run 043 (the fixes in the wild, a
probe) and run 044 (Study 11) again by their own scripts, in a clean copy of the repository on the first cloud machine,
rebuilding MuJoCo at pull request #3349's two commits from its source as the runs did, and compares every file the record
keeps for them, but their scripts, READMEs, the pull request's diff and Study 11's dry run, byte for byte with a second
clean copy (`remake_043_044_log.txt`, `remake_043_044_compare.txt`). It took 28 minutes.

**Result: every play, every measured value and every rule line of runs 043 and 044 re-makes byte for byte.** Of the
640 files, 605 are the same and 35 differ, none missing, each for a cause in how the files were kept, not in the plays:

| Files | Why they differ | Checked |
|---|---|---|
| 6: every `finished.txt`, `progress.txt` and `played_at.txt` | Clock readings | Nothing else in them differs |
| 8 `ctest_*.txt` and 8 build logs | Test durations, and the build tools' output | The tests' results are read from them into `suite_results_*.txt` |
| 8: part B's `stats.txt` in both runs | The scene rig writes the path of the scene file it played, which holds the working copy's folder name | Every other field of every line the same |
| Run 043's `suite_results_pr.txt`, `suite_compare.txt` and the last line of `measured.txt` | Which of the two memory-heavy `LargeTexture` tests the system kills for memory, when the suite runs four at a time, varies from run to run (run 043's README); the last line of `measured.txt` is the probe's own comparison, which its README says is not the reading | Every other line the same; in the re-make no test reads differently between the builds |
| Run 044's `suite_results_june.txt` and `suite_compare.txt` | The re-read keeps one test's duration in its name (run 044's README): in the record the two builds' durations differed, so the test was not paired; in the re-make they were equal, and it was | Every other line the same; in both, no test reads differently |

### Runs 045 to 051

[`validation/audit/remake_045_051.sh`](../validation/audit/remake_045_051.sh) plays runs 045 to 050 (the design probes of
the de Saxce patch and finding F12) and run 051 (Study 12) again by their own scripts, in a clean copy of the repository
on the first cloud machine, rebuilding MuJoCo from its source and each version of the patch from its file as the runs
did, and compares every file the record keeps for them, but their scripts, READMEs and Study 12's dry run, byte for byte
with a second clean copy (`remake_045_051_log.txt`, `remake_045_051_compare.txt`). Run 048 is the record's second play
of it and run 050 its corrected probe, the plays the record keeps. It took 50 minutes.

**Result: every play, every measured value and every rule line of runs 045 to 051 re-makes byte for byte.** Of the
6,324 files, 6,265 are the same, 58 differ and 1 is missing, each for a cause in how the files were kept, not in the
plays:

| Files | Why they differ | Checked |
|---|---|---|
| 21: every `finished.txt`, `progress.txt` and `played_at.txt` | Clock readings | Nothing else in them differs |
| 17 `ctest_*.txt` and 11 build logs | Test durations, the build tools' output, and GoogleTest's printout of one test's parameters, which holds memory addresses | Every suite passes and fails the same tests, in the record and the re-make |
| 6: `suite_results_*.txt` of runs 047, 048 and 049 | Those runs' reading of the test output keeps that printout in 14 tests' names (Study 12's reading drops it) | With the printout removed, all 3,492 lines the same in every suite |
| 3: run 049 step 2's `stats.txt` and run 050's two | The scene rig writes the path of the scene file it played, which holds the working copy's folder name | With the folder named alike, every line the same |
| 1 missing: run 049's `step2_out.txt` | The re-make wrote step 2's printed output into this folder (`remake_045_051_out_049_2.txt`) | The two are the same (both empty) |

### Runs 052 to 056

[`validation/audit/remake_052_056.sh`](../validation/audit/remake_052_056.sh) plays runs 052 to 056 (design probes)
again by their own scripts, in a clean copy of the repository on the first cloud machine, with the rigs as they are in
the repository now, each of their later settings unset in these runs' plays; run 053 fetches MuJoCo's releases 3.11.0 to
3.15.0 again and checks each against its published sha256. Every file the record keeps for them, but their scripts and
READMEs, is compared byte for byte with a second clean copy (`remake_052_056_log.txt`, `remake_052_056_compare.txt`). It
took 11 minutes.

**Result: every play and every measured value of runs 052 to 056 re-makes byte for byte.** Of the 7,448 files, 7,431 are
the same and 17 differ, none missing and none new:

| Files | Why they differ | Checked |
|---|---|---|
| 15: every `finished.txt`, `progress.txt` and `played_at.txt` | Clock readings | Nothing else in them differs |
| 2: run 055's `box_rel/stats.txt` and `box_on/stats.txt` | The scene rig writes the path of the scene file it played, which holds the working copy's folder name | Every other field of every line the same |

### Runs 057 to 061

[`validation/audit/remake_057_061.sh`](../validation/audit/remake_057_061.sh) plays runs 057 to 061 (Study 13 and four
design probes) again by their own scripts, the same way, with Study 13's dry run kept (`remake_057_061_log.txt`,
`remake_057_061_compare.txt`). It took 4 minutes.

**Result: every play, every measured value and every rule line of runs 057 to 061 re-makes byte for byte.** Of the
3,201 files, 3,188 are the same and 13 differ, none missing and none new: every one of the 13 a `finished.txt`,
`progress.txt` or `played_at.txt`, clock readings, nothing else in them differing.

### Runs 062 to 065

[`validation/audit/remake_062_065.sh`](../validation/audit/remake_062_065.sh) plays runs 062 and 063 (design probes of
issue 1's open part), run 064 (Study 14) and run 065 (a probe of T08, both its steps) again by their own scripts, the
same way, rebuilding MuJoCo from its source and each patch from its file as the runs did, with Study 14's dry run kept
(`remake_062_065_log.txt`, `remake_062_065_compare.txt`). It took 23 minutes.

**Result: every play, every measured value and every rule line of runs 062 to 065 re-makes byte for byte.** Of the
1,753 files, 1,722 are the same and 31 differ, none missing and none new:

| Files | Why they differ | Checked |
|---|---|---|
| 13: every `finished.txt`, `progress.txt` and `played_at.txt` | Clock readings | Nothing else in them differs |
| 10 `ctest_*.txt` and 5 build logs | Test durations, the order four tests at a time finish in, and the build tools' output | Every suite passes the same 3,492 tests, in the record and the re-make; the `suite_results_*.txt` read from them are the same |
| 3: run 063's `stats.txt` of its three arms | The scene rig writes the path of the scene file it played, which holds the working copy's folder name | With the folder named alike, every line the same |

### Runs 066 to 076

[`validation/audit/remake_066_076.sh`](../validation/audit/remake_066_076.sh) plays runs 066 to 076 again by their own
scripts, the same way, rebuilding MuJoCo from its source and each patch from its file as the runs did. That covers Study
15 (run 071) and ten design probes, run 070 in both its steps. Study 15's dry run and run 069's copy of the stack rig as
it was before (an input) are kept (`remake_066_076_log.txt`, `remake_066_076_compare.txt`). It took 2 hours, sharing the
machine with other runs.

**Result: every play, every measured value and every rule line of runs 066 to 076 re-makes byte for byte.** Of the
10,738 files, 10,634 are the same and 104 differ, none missing and none new:

| Files | Why they differ | Checked |
|---|---|---|
| 36: every `finished.txt`, `progress.txt` and `played_at.txt` | Clock readings | Nothing else in them differs |
| 30 `ctest_*.txt` and 16 build logs | Test durations, the order four tests at a time finish in, and the build tools' output | Every suite passes and fails the same tests, in the record and the re-make; the 15 `suite_results_*.txt` read from them are the same |
| 22: the `stats.txt` of runs 066 and 068 and the scene rig's `*.stats` of runs 073 and 076 | The scene rig writes the path of the scene file it played, which holds the working copy's folder name | With the folder named alike, every line the same |

The record's copies of runs 066 to 083 had kept the host's home folder in 98 files where every earlier run writes `~`.
The compare was made against them as they were. They have since been written with `~`, as the re-make writes them.

The design probes of runs 025 to 036 that need no build of MuJoCo were also re-made on their own
([`remake_probes_025_036.sh`](../validation/audit/remake_probes_025_036.sh)): all 794 of their files are the same
(`remake_probes_compare.txt`).

### Runs 077 to 100

[`validation/audit/remake_077_100.sh`](../validation/audit/remake_077_100.sh) plays runs 077 to 100 again by their own
scripts, the same way, in three parts played at once on the three cloud machines, each a chain of runs whose MuJoCo
builds it makes itself: Studies 16, 19 and 20 and the probes that read their builds (part b); the probes that play the
release or build their own, with Studies 17 and 18 (part c); Studies 21 and 22 and the probes that read their builds
(part a). Each run plays with the measure it ran with: runs 077 to 090 with the measure as it was before the correction,
runs 091 to 097 with the corrected build, runs 098 to 100 with the build with `fastest`. The two machines new to the
re-make were given MuJoCo's source at `UPSTREAM_COMMIT` from Google DeepMind's repository, the release checked by its
sha256, and the release's test build made as run 020 made it (`remake_077_100_*_log.txt`, `_compare.txt`). It took 75
minutes.

**Result: every play, every measured value and every rule line of runs 077 to 100 re-makes byte for byte.** Of the
9,511 files, 9,213 are the same; 268 differ, 30 are missing and 26 are new, each with its cause:

| Files | Why they differ | Checked |
|---|---|---|
| 79 `finished*.txt`, `played_at*.txt` and `progress.txt` | Clock readings | Nothing else in them differs |
| 92 test and build logs | Test durations, the order tests finish in, the build tools' output | Every suite passes and fails the same tests: the `suite_results_*.txt` read from them are the same |
| 41 statistics files and run 085's `parameters.txt` | The scene rig writes the path of the scene file it played, which holds the working copy's folder name | With the path set aside, every line the same |
| 55 compressed play files of runs 098 and 099 | The record compressed its copies on another machine, whose gzip writes other bytes | The same contents, byte for byte, once decompressed |
| 26 missing and 26 new: run 086's 20, run 087's and run 091's 3 suite results each | The record keeps them compressed; the scripts write them plain | The same contents |
| 2 missing: run 088's `reading_slide_corrected.txt` and `reading_slide_set_corrected.txt` | Placed by the measure's correction, below, not by the run's scripts | |
| 2 missing: runs 093's and 096's `README.md.new` | Copies of two pages that are not part of the record | Not in the record |

### Runs 101 to 106

[`validation/audit/remake_101_106.sh`](../validation/audit/remake_101_106.sh) plays runs 101 to 106 again by their own
scripts, the same way, in one chain on the first cloud machine, each run's MuJoCo builds made by its own script, every
run with the measure with `fastest` (`remake_101_106_log.txt`, `_compare.txt`). It took 25 minutes.

**Result: every play, every measured value and every rule line of runs 101 to 106 re-makes byte for byte.** Of the
1,118 files, 1,077 are the same; 41 differ, none is missing and none is new, each with its cause:

| Files | Why they differ | Checked |
|---|---|---|
| 17 `finished.txt`, `played_at.txt` and `progress.txt` | Clock readings | Nothing else in them differs |
| 12 build and test logs of runs 101, 102 and 104 to 106 | Build durations and test times, the order tests finish in | Run 101's three suites pass and fail the same tests: its `suite_results_*.txt` are the same |
| 12 statistics files | The scene rig writes the path of the scene file it played, which holds the working copy's folder name | With that folder set aside, every line the same |

## The measure corrected, 17 October 2026

**Found by run 088.** At a step of 31.25 us, Senua AI's `accel` read a deceleration of 3,951 mm/s2 where the rig's
own columns, summed in double precision, give 3,919.99. Three faults in how the measure `sx_contact` used the time:

- `stop`, `accel`, `swing`, `swingq` and `grip` read the step in whole microseconds. A step with a fraction of a
  microsecond was read short: 427.5 us as 427 (0.12%), 31.25 us as 31 (0.8%). Whole microseconds were read exactly.
- `stop` cut each step's distance to 0.01 um before adding it up, so the more steps, the shorter the distance read
  (62 um short of the columns at 32,000 steps).
- `accel` divided by the times asked for, not the time between the two steps it read, which differ when the times are
  not whole numbers of steps.

**The correction.** The step is taken as the file gives it, in nanoseconds; `stop` adds its distance up exactly, in
whole micrometres, picometres and thousandths of a picometre, each carried every step; `accel` and `grip` divide by
long division, so no product leaves the arithmetic's range. The measure is published with the SuperDex deep dive, where
the same correction is recorded (its `measure/README.md`): as run, sha256 804d51e14d2ade30...; built for Linux,
b1d1b2906041219e.... Before the correction, built by the same compiler: 528080bef9b5a70e.... This record cited the
program by 87e921cd4d2c03bf..., SuperDex's `registered/sx_contact_registration22.sx`, which differs from the one before
the correction only by a measure this record does not use (`pairg`).

**Checked before any reading was re-made.** On run 088's slide at 2, 0.5, 0.125 and 0.03125 ms the corrected `stop`
reads the columns' sum to the micrometre and `accel` Coulomb's 3,920 mm/s2 at every step; so are the distances of a
cube thrown 487 m (run 049) and of a spinning joint (run 006). A first form of the correction overflowed on the 487 m
flight; it was found by this check and corrected before any reading below was made.

**Every play file read again.** [`remeasure_step.sh`](../validation/audit/remeasure_step.sh) read every play file of
the 45 runs whose scripts call `stop`, `accel` or `swing` by the measure before the correction and after it: 35,489
play files, 42,600 readings, of which 21,299 change ([`measure_correction/remeasure.txt.gz`](../validation/audit/measure_correction/remeasure.txt.gz)).
Most of those are plays no output reports.

**Written into the outputs.** [`correct_step.sh`](../validation/audit/correct_step.sh) and
[`correct_step_2.sh`](../validation/audit/correct_step_2.sh) placed every changed reading an output reports where its
play file is known: 719 whole reading lines and 1,270 fields of measured lines, in 50 output files
([`measure_correction/corrections.txt`](../validation/audit/measure_correction/corrections.txt)). Each output stays as
it was printed; its corrected copy is beside it as `<name>_corrected.txt`. The second pass reads the off arm of
Studies 3, 4 and 6 and of runs 021 and 022 from the release arm, which those studies proved byte-identical, and the
`axis` and `elliptic` lines of Studies 4 and 6 from their reference plays.

**Every rule judged again.** [`rejudge_step.sh`](../validation/audit/rejudge_step.sh) judged again, by `sx_contact
rule` with the corrected measure, every rule line of the record whose inputs the correction changes: 59 lines, in
Studies 1, 2, 3, 4, 6, 10, 12 and 15 and probe 041. **No verdict changes**
([`measure_correction/rejudge.txt`](../validation/audit/measure_correction/rejudge.txt)). Four rule lines of Studies 10
and 12 hold an old value that two plays of their run share with different corrections; they were judged again by hand
from the corrected measured lines, as their runners read them: none changes (Study 10's RK4 free cube fails as it
did). Three lines of a dry run's plumbing check, which decides nothing, were not.

**What the pages say.** Fifteen run READMEs list, under "Corrected 17 October 2026", every number they quote that
the correction changes; runs 001 and 088 have their findings written again. Every correction a page quotes is at most
0.03%, but three, all at a step with a fraction of a microsecond:

- run 001's slide at 1/64 of 2 ms: its deceleration reads 3,907 mm/s2, 0.3% under Coulomb's, where it read 3,957,
  0.9% over; its distance 127,727 um where it read 126,641. So finding F5 is corrected: the slide's distance settles as
  the step is refined;
- Study 15's Coulomb rule C1: 97,600 to 97,623 um where it read 97,472 to 97,493, still within 1 part in 100 of
  97,579;
- run 088's deceleration at 1/64, corrected on its page.

The probes' measured lines whose labels do not name their play file are left as printed: in runs 028, 041, 045 to
050, 052 to 054, 061, 066, 068, 070, 074, 075 and 084 (some of the lines counted there hold a corrected value that
equals another play's old one). The correction of any of their readings is at most 0.030% (run 045), as the
corrections their old values receive in their own runs show.

## Every number traced

[`validation/audit/trace_numbers.sh`](../validation/audit/trace_numbers.sh) reads every page, the front page, `docs/`, the
study pages and every run's README, and looks for every number of three or more significant digits, as written, in the
files of the runs its line cites (a line cites the runs it links or names, a study cites its run, a run's README its
own run). It reads text and measures nothing (`trace_numbers.txt`).

**Traced over every page, to run 100: of 4,888 numbers, 4,144 are in a cited run's files as
written.** 470 are only elsewhere in the record's files: step sizes written in milliseconds, figures that recur across
runs, and lines of the summary pages that cite no run; the 92 of them with four or more significant digits on a line
that cites a run were read by hand, and each is a right answer shared by several runs (Coulomb's 133,451 um), a
comparison with an earlier run the line names, a step size, a count of MuJoCo's tests, a checksum's or a commit's
digits, or a reading in nanometres written in micrometres whose digits happen to appear in another file. 274 are in no
file as written.

Each of the 274 was read by hand against its source. They are of five kinds, and each agrees with its source. Where a
figure was not plainly a conversion, a setting or a right answer, it was checked in the files: the times a dropped arm
last moves (run 066's 0.655 and 0.668 s, Study 15's 0.638 and 0.634 s) are the probes' `last_moving_s` (0.6545,
0.6676, 0.6378, 0.6340), the last time the ball's speed exceeds 10 um/s; the solver traces' figures (runs 062, 067,
072, 076) are rounded from the traces they keep (11.4408399 N as 11.44, 2.81725e-17 m as 2.8e-17); and the lift of 10.6
mm at 10 ms (Study 12) is run 016's under the elliptic cone (10,570 um), where 10.8 mm (the front page) is its default
cone's (10,848 um).

| Kind | Examples |
|---|---|
| A figure derived from the files | A share in per cent from a reading in parts per million (run 007's +9.72% from 1,097,162 per million); a length in micrometres or millimetres from one in nanometres (run 039's 57.0 um from 56,996 nm; Study 8's 25.6 mm from 25,643,794 nm); a ratio of two readings (run 003's 1.416, 179,492 over 126,717 um) |
| A right answer from its closed form | Coulomb's distance v^2 / (2 mu g); the joint limit's leaving speed, 1,434,131 and 369,401 urad/s, the first deep dive's right answers for the same arm |
| A step size in milliseconds | The files hold seconds (0.000625 for 0.625 ms) |
| A setting or an input of a play | The angles run 010 builds its rotations from (2e-15 rad); the inverse weights run 025's rig prints to nine digits, read to three |
| Not a reading | A checksum's digits, an operating system's or a compiler's version, a value cited from a paper (the known issues' sources) |

## Claims checked by hand

| Claim | Source | Result |
|---|---|---|
| MuJoCo plays the same bytes run after run, and on macOS and Linux on Intel processors | `run_002_linux_replay/compare.txt`; the re-makes above | Holds |
| A build from source plays as the release | `run_004_source_build/compare.txt`, re-made (`run004_compare_remade.txt`) | Holds |
| Each study's rule lines held: 17 of 17, 11 of 11, 29, 29 and 31 of 32, 86 of 86, 134 of 134, 154 of 154, 46 of 58, 290 of 298, 37 of 58, 43 of 43, 11 of 11 | Each study's `rules.txt` (runs 012, 015, 023, 024, 031, 030, 035, 038, 040, 042, 044, 051, 058) | Holds |
| MuJoCo passes 9 of the first deep dive's ten contact tests as released and 10 of 10 under the recommended configuration; SuperDex as released passes 6 | `run_015_study_02/rules.txt` R5, `run_042_study_10/rules.txt` K1; the first deep dive's record, "SUITE passed 6 of 10" | Holds |
| The patches add 25 (the friction pyramid), 104 (the inverse weight in the current pose, third version) and 103 (de Saxce's correction, fourth version) lines of MuJoCo's C and remove none | `patches/slip_aligned_pyramid.diff`, `patches/invweight_at_pose_v3.diff`, `patches/desaxce_elliptic_v4.diff` | Holds |
| With a patch's switch unset MuJoCo plays every file as released and passes MuJoCo's tests test for test | Every study's R1 and R2 (Study 10's and Study 12's E1 and E2) | Holds |
| With de Saxce's correction switched on, two of MuJoCo's 3,492 tests fail, the two named in Study 12's registration, and no other | Run 051's `suite_results_on.txt` and `rules.txt` (M1), and the re-make's | Holds |
| The plays ran on an Intel laptop and on cloud machines with 2 to 16 virtual CPUs | Each run's README | Holds |
| One of MuJoCo's tests ran out of memory on the 3.8 GB machine in runs 024, 029, 030 and 040, alike in every arm | Those runs' READMEs and `suite_results_*.txt`; it passes on 8 GB (the re-make) | Holds |
| Pull request #3349, its flag unset, plays every hold and demo file as the commit it branched from, and MuJoCo's whole suite passes on both, every test reading the same | Run 044's `measured.txt` (`safe_when_off`), `progress.txt`, `ctest_*_large.txt` and `suite_compare.txt`, and the re-make's | Holds |

## Mechanical checks

| Check | How | Result |
|---|---|---|
| Every link resolves | Each relative link on every page (`README.md`, `docs/`, the study pages, `patches/`, `measure/`, the registrations and every run's README) followed to its file ([`check_links.sh`](../validation/audit/check_links.sh)), 17 October 2026 | 1,163 of 1,163 |
| No em or en dashes | A byte search for the two dash characters | None |
| Nothing but ASCII | A byte search, every `.md`, `.sh`, `.sx`, `.c` and `.h` file, for any byte over 127 | None |
| No private paths | A search of every tracked file for a home folder | None: the cloud machine's is written as `~` in the recorded outputs |
| "Model" never describes Senua AI | Every use of the word read | Each names MuJoCo's own contact model, its scene file or a MuJoCo page; the front page uses it only to say Senua AI does not use models |
