# Run 095: noslip re-solving the equality rows, a first design

17 October 2026 (08:52 to 09:04 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays, with its plumbing run first ([`dry/`](dry/), Study 21's build standing
in for the patched one). It finds where to look and decides nothing. Its readings, scenes, plays, solver statistics and
MuJoCo's suite results are kept.

## Why

Run 094 reproduced MuJoCo's issue [#2430](https://github.com/google-deepmind/mujoco/issues/2430) (issue 14): with
noslip, a joint its friction holds stays still, and a joint coupled to it by an equality moves and stays moved. Noslip
re-solves the friction rows only (`engine_solver.c`), keeping every other force, the equality's among them, as the main
solver left it, when the main solver let the held joint creep.

## The design

[`patches/in_design/noslip_equality.diff`](../../patches/in_design/noslip_equality.diff) (sha256 `ad0baec31bb13bc4`;
off unless `MUJOCO_NOSLIP_EQUALITY=1`), applied after Senua AI's five validated patch files: each noslip iteration also
sweeps the equality rows, each solved as MuJoCo's own PGS solves an equality row (its regularization kept, no bound),
given the friction forces the pass sets. Kept regularized, the equality rows add no problem the main solver did not
already solve. With no equality rows, nothing changes. In this first version the equality sweep comes before the
friction sweeps.

Built from MuJoCo's source at `UPSTREAM_COMMIT` with the five patch files and this one (p95; checksums in
[`patch_check.txt`](patch_check.txt)), with its tests. set5: the five switches set; set6: the six.

## What it found

**Where the friction holds, the equality is kept, from 5 noslip iterations on.** In run 094's scenes and one after
#2430's second model ([`reading_equality.txt`](reading_equality.txt)), how far the coupled body moved in 1 s, while
the friction holds the other still:

| Scene | No noslip | Noslip 1, set5 / set6 | Noslip 5, set5 / set6 | Noslip 100, set5 / set6 |
|---|---|---|---|---|
| Step 2's held body, 10, 100, 1,000 kg | both creep 10.24 mm | 386,666 / 386,666 nm | 386,666 / 0 to 31 nm | 386,666 / 0 to 31 nm |
| After #2430's second model | both slide 31.3 m | 1.14 / 1.14 m | 1.14 m / 53.4 mm | 1.14 m / 287 nm |
| Step 1 at 20 N, the force on the free joint | both creep, 0.56 mm apart | 0.80 / 0.80 mm | 0.80 / 0.57 mm | 0.80 / 0.56 mm |

- With one noslip iteration this version changes nothing: its equality sweep comes before the friction sweep, so in a
  single iteration the equality is re-solved against the main solver's friction, not noslip's.
- In step 1 at 20 N the patched play keeps the equality as the soft equality keeps it without noslip (0.56 mm, the
  equality's own give under A's weight), with the friction holding B exactly.
- Where the friction slides (step 1 at 0.5 and 9 N) the patch changes nothing at 0.5 N and moves the fall by up to 1.1%
  at 9 N (205.1 to 202.8 mm).

**An arm held by an equality with joint friction comes to rest, at a cost in iterations.** Study 15's arm in two poses,
its tip held by a weld or a connect, joint friction 5.15 N m, in the air, 2 s at 1.71 ms
([`reading_arm.txt`](reading_arm.txt)):

| | No noslip | Noslip 100, set5 | Noslip 100, set6 |
|---|---|---|---|
| The ball against where it starts, at 2 s | 37 um above to 317 um below, at rest | 3.2 to 8.0 um below, sinking at 2 to 5 um/s | 21 to 42 um below, at rest |
| Most iterations a step, the two solvers together | 1 | 11 to 18 | 101 |
| Steps with 100 or more | 0 | 0 | 234 to 497 of 1,170 |

- Without the patch the ball sinks under noslip: the #2430 mechanism, the friction held exactly and the equality's force
  left as the main solver set it. With it the ball is at rest, and noslip's pass runs to its limit on a fifth to two
  fifths of the steps.

**Nothing else changes.** The set's plays with no equality (Study 15's arm set down and dropped, the cube Study 19 held,
Study 15's grip, MuJoCo's box and Study 19's box 1, run 093's offset stacks): 24 play files and their solver statistics
the same bytes in Study 21's build, in p95 with set5 and in p95 with set6 ([`identity.txt`](identity.txt)). MuJoCo's
suite on p95: every test passes with every switch unset; set5 and set6 give the same results, the one failure
`SolverTest.ZeroToleranceDisablesTermination`, as in Study 21 (M1) ([`suite_set5_against_set6.txt`](suite_set5_against_set6.txt)
empty).

## What it means

- The design fixes #2430's mechanism where noslip runs two iterations or more. MuJoCo's documentation says one to three
  noslip iterations are "usually sufficient", so a version that works in one is wanted: the equality sweep after the
  friction sweeps, the next design to try.
- Its cost is iterations where an equality and friction share a load: the arm's pass runs to its limit on up to two
  fifths of its steps. That cost has to be measured in any study of it.
- The rigs' count of steps at the iteration limit adds noslip's iterations to the main solver's
  ([how it works](../../docs/how-it-works.md)).
