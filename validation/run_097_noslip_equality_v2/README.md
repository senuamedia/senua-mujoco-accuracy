# Run 097: the noslip-equality design's two versions, at one to a hundred iterations

17 October 2026 (09:13 to 09:26 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays, with its plumbing run first ([`dry/`](dry/)). It finds where to look
and decides nothing. Its readings, plays, solver statistics and MuJoCo's suite results are kept.

## Why

Run 095's design ([`noslip_equality.diff`](../../patches/in_design/noslip_equality.diff), v1) re-solves the equality
rows in noslip's pass before the friction sweeps, so with one noslip iteration it changes nothing, and MuJoCo's
documentation calls one to three iterations "usually sufficient". Its second version
([`noslip_equality_v2.diff`](../../patches/in_design/noslip_equality_v2.diff), v2, sha256 `42f9c0d980060d48`, the same
switch) sweeps the equality rows after the friction.

## What was played

Built from MuJoCo's source at `UPSTREAM_COMMIT` with Senua AI's five validated patch files and v2 (p97,
[`patch_check.txt`](patch_check.txt)), with its tests; v1 is run 095's build. Run 095's equality scenes and arm, with
noslip off, 1, 2, 3, 5 and 100 iterations (the arm at 3 and 100), in three arms: set5 (the five switches, p97), v1 and v2
(the six). The set's plays with no equality in Study 21's build and in p97 with set5 and set6, byte for byte; MuJoCo's
suite on p97. Read by Senua AI's corrected measure.

## What it found

**The two versions trade the equality for the friction while noslip has few iterations.** The held body (step 2 of
run 094, friction twice its weight) and the body coupled to it, how far each moved in 1 s, nm, held / coupled
([`reading_equality.txt`](reading_equality.txt)):

| | Iterations | 1 | 2 | 3 | 5 | 100 |
|---|---|---|---|---|---|---|
| 10 kg | v1 | 0 / 386,666 | 0 / 31,901 | 0 / 2,608 | 0 / 17 | 0 / 17 |
| | v2 | 755,187 / 755,187 | 61,291 / 61,291 | 5,011 / 5,011 | 410 / 410 | 410 / 410 |
| 100 kg | v1 | 0 / 386,666 | 0 / 3,500 | 0 / 31 | 0 / 31 | 0 / 31 |
| | v2 | 82,255 / 82,255 | 732 / 732 | 7 / 7 | 7 / 7 | 7 / 7 |
| 1,000 kg | v1 | 0 / 386,666 | 0 / 353 | 0 / 0 | 0 / 0 | 0 / 0 |
| | v2 | 8,299 / 8,299 | 7 / 7 | 7 / 7 | 7 / 7 | 7 / 7 |

Without the patch (set5) the held body stays at 0 and the coupled one moves 386,666 nm at every count; without noslip
both creep 10.24 mm.

- **v1 never lets the friction-held body move**, at any count; it breaks the equality as noslip does with one
  iteration, and closes it from two on.
- **v2 keeps the equality at every count**, and with few iterations lets the friction-held body slide: in the scene
  after #2430's second model, 12.8 m at one iteration (both bodies), 5.5 m at two, 2.5 m at three, 0.49 m at five and
  6.7 um at a hundred, where noslip without the patch holds it at 0 and without noslip it slides 31.3 m. v1 there: the
  coupled body 1.14 m, 517 mm, 240 mm, 53 mm and 287 nm.
- At 20 N in step 1 of run 094 (the force on the free joint), v1 holds B at 0 and A lags 0.80 to 0.56 mm, the soft
  equality's own give; v2 lets both move (4.86 and 4.29 mm at one iteration), 0.57 and 0.004 mm at a hundred.
- At a hundred iterations, Senua AI's configuration, both versions keep the coupling to 31 nm or better in the held
  scenes; v1 holds the friction-held body at 0, v2 lets it move 7 to 410 nm (and 6.7 um in #2430's scene). Both change
  a sliding fall (9 N) by up to 1.1%, alike.

**The arm**: at 100 iterations both bring the welded or connected ball to rest (at most 1 um/s); v2 has fewer steps
with 100 or more iterations, the two solvers together (157 to 274 of 1,170, against 234 to 497 for v1)
([`reading_arm.txt`](reading_arm.txt)). At 3 iterations v1 leaves the ball at rest in all four plays (0 um/s); v2
lets it sink at 2 um/s (welded) and 18 um/s (connected) in the second pose.

**Nothing else changes**: the set's 24 play files and their statistics the same bytes in Study 21's build and in p97
with set5 and set6 ([`identity.txt`](identity.txt)); MuJoCo's suite with v2 set gives the results it gives without it,
the one failure `SolverTest.ZeroToleranceDisablesTermination`, as in Study 21 (M1).

## What it means

- v1 is never worse than noslip as it stands, at any number of iterations: the friction-held body stays held, and the
  equality closes from two iterations on. v2 keeps the equality at the cost of the friction until noslip has
  iterations to spare, which is the cost noslip exists to remove. v1 is the version to register.
- At Senua AI's configuration (100 iterations) v1 holds the friction-held body exactly and the coupling within 31 nm.
