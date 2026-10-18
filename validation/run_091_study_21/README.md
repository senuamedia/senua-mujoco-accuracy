# Run 091: Study 21, four groups, each deciding one issue

17 October 2026 (07:47 to 08:01 UTC). The twenty-first registered study,
[`PREREGISTRATION_21.md`](../../preregistrations/PREREGISTRATION_21.md), played once on the first cloud machine by
[`play.sh`](play.sh), the runner as registered (sha256 fe2e81930a187c2b...), from an archive of the registration's commit
(2cfa01e). Every reading by Senua AI's measure as corrected on 17 October 2026 (built for Linux, b1d1b2906041219e...).
The rule lines are in [`rules.txt`](rules.txt), the readings in [`measured.txt`](measured.txt), the draw in
[`draw.txt`](draw.txt).

## Result: 67 of 67 rule lines held

Shared by every group: all play files of the off arm are the release's (E1); every arm gave all 341 readings (P0).
MuJoCo's suite: each reading lists all 3,492 tests (M0); with every switch unset every test gives the release's result
(E2); with the five switches set only `SolverTest.ZeroToleranceDisablesTermination` changes (M1).

**Group 1, a cube held from turning.** Released and with the friction solve's first version, cube a (1.881 kg,
friction 0.663) held from turning with condim 4 creeps at 1,608 um/s at 0.95 of its limit (Q1, Q2). With the second
version in Senua AI's set, every one of the 108 holds of a cube held from turning, condim 3, 4 and 6, at three
fractions, three directions and two steps, holds at 10 um/s or less (H1). Every other play file is byte-identical to
the first version's (N1), every arm and grip holds, every box rests, no step at the iteration limit, no warning.

**Group 7, the slide.** Released, slide 1 rises 686 um above the ground at 2.411 ms (Q1). In Senua AI's validated set,
started at the depth it rests at, no slide rises above the ground at any step (S1), and:

| In the set | 2.411 ms | 0.603 ms | 0.151 ms | 0.0377 ms | Coulomb's |
|---|---|---|---|---|---|
| Slide 1 (friction 0.255, 1.67 m/s): deceleration, mm/s2 | 2,499 | 2,498 | 2,498 | 2,498 | 2,499 |
| Slide 1: distance, um | 556,075 | 557,605 | 557,990 | 558,085 | 558,003 |
| Slide 2 (friction 0.357, 1.32 m/s): deceleration, mm/s2 | 3,498 | 3,498 | 3,498 | 3,498 | 3,499 |
| Slide 2: distance, um | 247,542 | 248,764 | 249,070 | 249,147 | 249,014 |

Every deceleration and distance within 1 part in 100 of Coulomb's (S2, S3): the distances converge on Coulomb's as the
step is refined, from 0.35% and 0.59% short at the coarse step, the step's own error in where the slide starts and
stops.

**Group 8, the depth at rest.** Released, under MuJoCo's defaults:

| Depth at rest, nm | 1/16 of the time constant | 1/4 | 1/3 | 1/2 | the time constant |
|---|---|---|---|---|---|
| Setting 1 (19.549 ms, 2.562 kg) | 16,295 | 16,295 | 16,295 | 16,295 | 64,866 |
| Setting 2 (24.531 ms, 0.977 kg) | 25,647 | 25,647 | 25,647 | 25,647 | 101,382 |

Within half the time constant the depth is the same at every step, to the nanometre (R1); at the time constant,
where MuJoCo's guard doubles it, four times deeper (Q1).

**Group 10, the bounce.** Released, under MuJoCo's default integrator, setting 1 at the coarse step (9.131 ms) is
thrown 46.8 times as high as it fell (Q1). Each setting has 4, 5 and 7 steps that resolve its spring (P1). Their
rebounds, in parts of 10,000 of the drop:

| Setting | The steps that resolve the spring | Rebounds | Spread |
|---|---|---|---|
| 1 (16.946 ms, damping 0.184) | 1/8 to 1/64 | 3,006, 3,124, 3,399, 3,284 | 393 |
| 2 (20.116 ms, 0.251) | 1/4 to 1/64 | 2,238, 2,352, 2,400, 2,261, 2,272 | 162 |
| 3 (47.65 ms, 0.407) | all seven | 376, 464, 505, 614, 626, 608, 611 | 250 |

Every two of them within 500 of each other (R1, 37 lines), and none above the drop (R2).

## What it decides

As registered, each group its own issue:

- **Issue 1**: the friction solve's second version is validated for a cube held from turning with condim 3, 4 and 6;
  it moves to `patches/` and takes the first version's place in Senua AI's set. Issue 1 stays fixed in part: the free
  cube pushed square to a face near its limit (Study 20) is still open.
- **Issue 7**: it is issue 4, the hop, seen through the deceleration. In Senua AI's set, which fixes the hop, the slide
  decelerates and slides as Coulomb's law says at every step. It is counted once, with issue 4.
- **Issue 8**: corrected by configuration: a step at most half the contact's time constant.
- **Issue 10**: corrected by configuration: a step at most half the contact's time constant times its damping ratio.

One disclosure: group 1's box rule (B1) reads each box's fastest of its last 160 steps by an `awk` line in the runner,
as Studies 19 and 20 did, not by Senua AI's measure; that reading is to move into the measure.
