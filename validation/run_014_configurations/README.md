# Run 014: MuJoCo's own options taken together

15 October 2026. Not registered: a design probe on run 002's Linux machine, by [`probe.sh`](probe.sh) (pushed before
its plays); reading `reading.txt`. Which of MuJoCo's own options, together, pass every known-answer test this record
plays, and at what cost? Three configurations, each playing both of the first deep dive's contact suites
(`suites/1/cfg_*`, `suites/2/cfg_*`), the hold at 0.6 and 0.8 of the limit and the slide along 0, 22.5 and 45 degrees
at 2 ms, and run 007's two-link chain at 10 ms over 1, 4 and 16:

- **A**: the elliptic cone with 10 noslip iterations (MuJoCo's default Euler integrator);
- **B**: the same with RK4;
- **C**: the same with implicitfast.

**A correction to the probe.** Its pattern for the integrator's name, `[A-Za-z]*`, cut RK4 to "RK", so B's six chain
plays stopped at loading ("invalid keyword"). The pattern was corrected and [`chain_B.sh`](chain_B.sh) played only those
six again; their readings are the last lines of `reading.txt`.

| | MuJoCo's defaults (runs 007, 008) | A: elliptic, noslip | B: and RK4 | C: and implicitfast |
|---|---|---|---|---|
| The first deep dive's ten tests | 9 of 10 (fails the hold) | **10 of 10** | 8 of 10 (T01, T08) | **10 of 10** |
| The hold at 0.6 and 0.8, along 0, 22.5, 45 degrees | creeps 1,293 to 2,263 um/s; lost at 0.72 along 45 | **0 everywhere** | **0 everywhere** | **0 everywhere** |
| The slide along 0, 22.5, 45 degrees (um; Coulomb 127,551) | 126,717, 151,762, 179,492 | **126,686 along each** | **126,734 along each** | **126,686 along each** |
| A free chain's kinetic energy after 2 s, 10 ms | +9.72% | +9.72% | **0.0001%** | +9.72% |
| A swinging chain's largest energy departure, 10 ms / 0.625 ms | 12.2% / 6.2% | 12.2% / 6.2% | **1.1% / 0.0001%** | 12.2% / 6.2% |
| Solver: most iterations, at the limit, warnings | 6, 0, 0 | 5, 0, 0 | 5, 0, 0 | 5, 0, 0 |

B's two failed tests are of two kinds. **T01** reads how much each halving of the step shrinks a free flight's error,
expecting the halving of a first-order integrator (5,000 per 10,000); RK4 integrates free flight under gravity
exactly, every gap is 0, and the ratio cannot be read (-1): the test's assumption, not a fault of MuJoCo. **T08** is
real: with contact, RK4's refinement chain does not fall at every step (9,329 um, then 13,740; 1,640, then 1,923).

## What it shows

- **No one configuration of MuJoCo's own options passes everything this record plays.** The elliptic cone with
  noslip, under Euler or implicitfast, passes all ten contact tests, holds at rest in every direction and slides the
  same along every direction, but leaves the chain gaining energy as Euler does. RK4 keeps the chain's energy and
  momentum and holds and slides as well, but its contact refinement is not in order.
- **The elliptic cone with noslip is a configuration a user can set today** that removes MuJoCo's two contact defects
  this record found (the creep at rest and the friction's direction) at no cost in solver iterations. It is the
  candidate for MuJoCo's recommended configuration; a registered study decides.
- implicitfast and Euler give the same bytes on every play here, as they should when nothing depends on velocity.

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 126,686 um | 126,701 um |
| 126,734 um | 126,751 um |

What this page concludes does not change: the largest of these corrections is 0.01%.
