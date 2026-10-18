# Run 058: Study 13, 100 noslip iterations for a joint held by friction

16 October 2026, 12:06 to 12:07 UTC, on the first cloud machine (AWS EC2 c7i.xlarge, Intel, 4 virtual CPUs, 8 GB).
Played once by [`play.sh`](play.sh), as registered in
[`PREREGISTRATION_13.md`](../../preregistrations/PREREGISTRATION_13.md), pushed with its runner, dry run and rules
plumbing check (commit 06a0e43) before this play. The study's page: [Study 13](../../docs/studies/13-noslip-joint-friction.md).

On Google DeepMind's Linux release of MuJoCo 3.16.0: **def**, MuJoCo's defaults; **n10**, Senua AI's configuration (the
elliptic cone, 10 noslip iterations); **n100**, the elliptic cone with 100 noslip iterations. Numbers drawn from seed 13
([`draw.txt`](draw.txt), [`parameters.txt`](parameters.txt)); every measured line in [`measured.txt`](measured.txt);
every rule, judged by `sx_contact rule`, in [`rules.txt`](rules.txt).

## The outcome

**11 of 11 rule lines held.** Issue 6 is fixed and validated by Senua AI's configuration with 100 noslip iterations, and
the record's recommended configuration becomes the elliptic cone with 100 noslip iterations.

## The readings

| | Released (defaults) | The configuration, 10 noslip iterations | 100 noslip iterations |
|---|---|---|---|
| The single joint held level by 8.79 N m (gravity's torque 5.62), turning at | 25,404 urad/s | 0 | **0** |
| The arm held 1 m up by 5.63 N m on each hinge, its ball creeping at, poses 1 and 2 | 28,257 and 40,534 um/s | 58 and 372 | **2 and 3** |
| The 18 holds; the 8 grips | | 0; 0 to 2 um/s | **the same, every file byte for byte** (85 of 85 play files) |
| The first suite's ten tests | 9 of 10 | 10 | **10** |
| The most iterations on a step (MuJoCo counts noslip's) | 6 | 11 | 23; none at 100, no warning |

The same at 1.68 and 0.42 ms. The single joint is held already by 10 noslip iterations; the arm, whose two hinges' friction
rows are coupled, is not.

## The arm set down on its ball (reported, not ruled)

In contact pose 1 the arm stands at 0 under the configuration with 10 or 100 noslip iterations. In pose 2 its ball slides
at its contact, 191 um/s, its sideways force 0.092 of its normal force against a friction of 0.778, under both; released,
it slides at 305 um/s. Issue 1's open part, seen on fresh numbers ([run 056](../run_056_resting_arm/README.md)): more
noslip iterations do not change it.

## Files

Each arm's plays in `def`, `n10`, `n100` (`joints`, `cubes`, `rest`, `suites`); the dry run in [`dry/`](dry/).
