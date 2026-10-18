# Run 093: the offset stacks over longer plays, and noslip held to convergence

17 October 2026 (08:01 to 08:09 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Its readings and solver
statistics are kept; the per-step play files, a few hundred MB, are not.

## Why

Issue 9 (F11): run 089 found the offset stacks in Senua AI's set still turning at 2 s under the configuration, and at
rest with noslip held to convergence (1,000 iterations, tolerance 1e-15): 23 and 0 urad/s, on one cube at one step. A
study needs to know whether that holds over longer plays and on other cubes, and what the converged setting does to the
set's other plays.

## What was played

In Senua AI's set (Study 20's build of its five validated patch files, every switch set), under the elliptic cone:

- **Part A**: stacks of 3 cubes, each 1, 5 and 17 mm over from the one below, of run 078's cube (0.442 kg, half-size
  0.0424 m, friction 0.524) and Study 16's (0.596 kg, 0.0405 m, 0.528), at 1.14 and 0.285 ms, played 2, 4 and 6 s,
  with noslip 100 at MuJoCo's tolerance, with noslip 1,000 at 1e-15, and with no noslip. Read by Senua AI's corrected
  measure, `final`, on each cube's tilt file: its tilt and its speed of turning at the last step
  ([`reading_stacks.txt`](reading_stacks.txt)).
- **Part B**: Study 15's arm set down and dropped, the cube Study 19 held at 0.5 and 0.95 of its limit, Study 15's
  grip, MuJoCo's box and Study 19's box 1, with noslip 100 and with noslip 1,000 at 1e-15
  ([`reading_set.txt`](reading_set.txt)).

## What it found

**Held to convergence, noslip does not bring the stacks to rest.** Its fastest turning at the end, over the three
cubes, in urad/s:

| Offset a cube | Noslip 100, MuJoCo's tolerance | Noslip 1,000, 1e-15 | No noslip |
|---|---|---|---|
| 1 mm | 38 to 31,538 | 23 to 1,989 | 1 |
| 5 mm | 8 to 85 | 54 to 1,596 | 5 to 6 |
| 17 mm | 21 to 217 | 0 to 6 | 32 to 42 |

- With noslip, at 1 and 5 mm the stacks do not settle: the turning comes and goes over 2, 4 and 6 s, up to 31,538
  urad/s, and held to convergence up to 1,989. Only the 17 mm stacks come to rest held to convergence.
- Held to convergence, noslip runs long: in each of the 36 stack plays at 1,000 iterations some step took 1,001
  iterations, MuJoCo's own count of the main solver's and noslip's together (`solver_niter`; noslip's limit is 1,000),
  and up to 21,044 steps of a play took 100 or more.
- With no noslip, the stacks lean and turn slowly: 349 to 388 urad at 1 mm, 1,861 to 2,074 at 5 mm, still turning at 1 and
  5 to 6 urad/s; at 17 mm 8,013 to 9,134 urad, the lean still growing at 32 to 42 urad/s.

This is the instability MuJoCo's own documentation names: noslip "is an ad-hoc correction that can occasionally cause
instabilities in models with complex multi-contact interactions". It is one of the costs of noslip that issue 14 lists.

**The set's other plays are not harmed by holding noslip to convergence.** Every arm, set down and dropped, every hold
and every grip at 0 or 1 um/s with either setting, both boxes at rest. With 1,000 iterations each box took 1,003
iterations, the two solvers together, on some step, and 100 or more on 2 steps.

## What it means

- Issue 9 is not closed by holding noslip to convergence: run 089's reading at 2 s does not last. Its depth is the
  soft contact the model authors (run 089); its lean, without noslip, follows from that depth.
- An offset stack under Senua AI's configuration is unstable at small offsets: noslip's documented multi-contact
  instability, recorded under issue 14 so it is counted once. No fix is designed.
