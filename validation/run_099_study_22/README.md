# Run 099: Study 22, noslip keeping a joint equality, and a concave shape as convex parts

17 October 2026 (10:58 to 11:12 UTC), on the first cloud machine. The twenty-second registered study
([`PREREGISTRATION_22.md`](../../preregistrations/PREREGISTRATION_22.md), registered in commit 7db4c32 before any play),
played once by [`play.sh`](play.sh) (sha256 `9039b1541da9c688`), its dry run and rules plumbing check in [`dry/`](dry/).
Every play file, measured line, rule line, solver statistic and MuJoCo suite result is kept, the play files compressed.

**Outcome: 39 of 39 rule lines held** ([`rules.txt`](rules.txt)).

## The numbers

Drawn from seed 22 ([`draw.txt`](draw.txt), [`parameters.txt`](parameters.txt)): a step of 0.957 ms; held bodies of
58.496, 294.858 and 465.417 kg, their friction 1.901, 2.29 and 1.499 times their weight; after #2430's second model,
46,365 N pushed by 0.369 of it and 48,307 N by 0.893; loads at 1.623 and 2.049 times the falling body's weight; the
arm's joint friction 7.218 N m; cups 0.0478 and 0.0788 m in outer half-width, 0.046 and 0.0455 m high, walls 0.0059 and
0.0099 m, balls of 0.0119 and 0.0233 m and 0.431 and 0.077 kg, at 1.243 ms.

## What the rules read ([`measured.txt`](measured.txt))

**Group 14, the joint equality, under the configuration (noslip 100):**

| Scene | Released: the gap | Senua AI's set: the gap / the held body |
|---|---|---|
| Held bodies, 58 to 465 kg | 386 um in each | 0 um / 0 nm |
| After #2430's second model | 650 mm and 1.64 m | 0 um / 0 nm (the coupled body 363 and 412 nm) |
| Loads | 822 um | 581 um, as with no noslip (581) / 0 nm |

- The held body stays at 0 in both arms; released, the body coupled to it moves and stays moved, as #2430 reports.
  In Senua AI's set the coupling holds.
- Study 15's arm, held by a weld or a connect with joint friction 7.218 N m: released under the configuration it sinks
  at 2 to 5 um/s; in the set at 0 um/s.
- The set's own plays, which have no equality, are the same bytes with the patch's switch set and unset (N1); every arm,
  grip and hold of them at most 10 um/s and every box at rest.
- The cost, reported: in the plays with an equality noslip ran to its limit of 100 iterations on 1,423 steps (at most 18
  iterations a step released).

**Group 15, the cups, under MuJoCo's defaults and under the configuration, alike:**

| Cup | As one mesh: the ball comes down | As primitives and as convex meshes | Resting on the floor would be |
|---|---|---|---|
| 1 | 10,366,909 nm: on the hull's top, 10 mm down and 0.367 mm in | 50,466,909 nm, both | 50,100,000 nm and the soft depth |
| 2 | 10,366,910 nm: on the hull's top | 45,966,909 nm, both | 45,600,000 nm and the soft depth |

As one mesh the ball rests on a lid that is not there; as convex parts, primitives or meshes, on the floor, 0.367 mm
into it, the contact's own depth, the same to the nanometre either way, released and in the set. Every cup play at rest.

**Every arm**: off makes the release's bytes (E1); MuJoCo's suite with every switch unset gives the release's results,
all 3,492 tests read in each suite; with the six switches set only `SolverTest.ZeroToleranceDisablesTermination`
changes, as with the five (M1); all 159 readings in every arm (P0).

## What it decides

- **Group 14**: `noslip_equality.diff` is validated, copied to [`patches/`](../../patches/noslip_equality.diff), and
  joins Senua AI's set as its sixth patch file. Issue 14's broken equality is fixed and validated. Its inverse dynamics
  stays a limit of holding friction exactly (run 094), and noslip's multi-contact instability a measured limit of the
  configuration (runs 093, 096, 098, 100).
- **Group 15**: issue 15 is corrected by configuration: a shape that is not convex written as convex parts, primitives
  or meshes, MuJoCo's documented remedy.
