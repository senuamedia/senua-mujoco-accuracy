# Run 018: a patch in design for F8, MuJoCo's stiffness guard extended to the damping

15 October 2026. Not registered: a patch in design, held to the five checks before any study registers its rules.
Played on the cloud machine by [`play.sh`](play.sh), which states the five checks and what passes before any play.

**The result: the patch fails check 2.** It removes the energy F8 found, but a bounce still depends on the step by
more than the first deep dive's T04 allows. As fixed in advance, it is recorded as a finding and goes no further: no
study is registered for it.

## The patch

[`patches/in_design/refsafe_dampratio.diff`](../../patches/in_design/refsafe_dampratio.diff) (sha256
dfb862408c5d6e42...), 18 lines added to `src/engine/engine_core_constraint.c` of MuJoCo 3.16.0 at the commit in
`UPSTREAM_COMMIT`, and none removed. It sits beside MuJoCo's own stiffness guard, `refsafe`. Under every integrator
but `discrete`, that guard holds a constraint's time constant to at least two steps, so the constraint is not too
stiff for the integrator (MuJoCo's XML reference).

In MuJoCo's standard format the stiffness is 1 / (d_width^2 timeconst^2 dampratio^2). A damping ratio under 1
therefore makes the spring's own time constant timeconst x dampratio, which the guard does not see. Under its
`discrete` integrator, MuJoCo already treats a row whose timeconst x dampratio is under the step as one the step
cannot resolve.

With the switch on (`MUJOCO_REFSAFE_DAMPRATIO=1`, read once), the guard also holds timeconst x dampratio to two
steps, keeping the authored damping ratio: timeconst >= 2 step / dampratio. The factor of two is the guard's own; no
constant is fitted. A damping ratio of 1 or more, MuJoCo's default among them, is never touched, and nothing changes
under the `discrete` integrator. With the switch unset nothing runs.

MuJoCo was built from the patched source as in run 004: the same compiler, options and build files, in 2 minutes. No
compiler warning comes from the patched file.

## The five checks

Three arms, each in its own scratch copy of the repository:
- **release**: Google DeepMind's Linux build.
- **off**: the patched build with the switch unset.
- **on**: the patched build with the switch set.

Each played both of the first deep dive's contact suites under MuJoCo's defaults, run 016's 120 slides and run
017's two steps (28 drops under Euler, the same 28 under `discrete`). Every judgment is a `sx_contact rule` line in
`checks.txt`.

**1. Required.** Run 017: under Euler, MuJoCo as released throws a cube with a damping ratio of 0.2 or 0.1 1.2 to 104
times higher than it fell, or more. The release arm repeats it: C1 fails for 0.2 and 0.1.

**2. Correct: failed.** The rebound in parts of 10,000 of the drop, under Euler:

| Damping ratio | Arm | 10 ms | 5 ms | 2.5 ms | 1.25 ms | 0.625 ms | 0.3125 ms | 0.156 ms | Spread |
|---|---|---|---|---|---|---|---|---|---|
| 1 | release, on | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 0.5 | release | 6,323 | 756 | 340 | 377 | 398 | 451 | 456 | 5,983 |
| 0.5 | on | **194** | 756 | 340 | 377 | 398 | 451 | 456 | 562 |
| 0.2 | release | 199,694 or more | 11,624 | 2,720 | 2,763 | 2,826 | 3,057 | 3,068 | 196,974 or more |
| 0.2 | on | **3,007** | **3,729** | **2,696** | 2,763 | 2,826 | 3,057 | 3,068 | 1,033 |
| 0.1 | release | 1,037,671 or more | 253,449 or more | 5,230 | 4,771 | 5,005 | 5,433 | 5,441 | 1,032,900 or more |
| 0.1 | on | **5,549** | **6,229** | **5,069** | **5,097** | 5,005 | 5,433 | 5,441 | 1,224 |

In bold, the plays the patch changed: exactly those whose timeconst x dampratio is under two steps.

- **C1 holds:** no rebound above the drop, at any step, for any damping ratio. The largest is 0.62 of the drop.
- **C2 holds:** MuJoCo's default damping ratio still gives no bounce at any step.
- **C3 fails** for every damping ratio under 1. T04 allows a spread of 500 across the seven steps; the spreads are 562,
  1,033 and 1,224.

What is left is a bounce that is right in kind but off in size where the guard's two steps decide it. With a ratio of
0.5 at 5 ms, where timeconst x dampratio is exactly two steps and the patch does not act, the release's 756 stands
against 456 at the finest step. The patch's 194 at 10 ms is under it. With 0.2 and 0.1 the largest departures are at
5 ms: 3,729 against 3,068, and 6,229 against 5,441.

**3. Nothing else gets worse: held.** With the switch on, 254 of the 263 files are byte-identical to the release.
The 9 that differ are the 8 changed drops and their readings. Every file outside the 21 Euler drops with a damping
ratio under 1 is the same, 240 of 240: both suites, run 016's slides, run 017's `discrete` drops, and the damping
ratio 1 drops. Suite 1 still passes 9 of 10, as released (T06, the creep at rest, is not what this patch addresses).

**4. Safe when off: held.** The off arm plays all 263 files byte for byte as the release (`identity_off.txt`). The
probes' finish times are clock readings and are not compared.

**5. The solver keeps converging: held.** With the switch on, no play is at the iteration limit and none raises a
warning.

## What it means

Holding the spring's own time constant to MuJoCo's own two steps removes the energy a bouncy contact creates under
Euler, as MuJoCo's `discrete` integrator does (run 017). It does not make the bounce the same at every step.
Neither does `discrete`: its spreads were 382, 2,109 and 3,636, against the patch's 562, 1,033 and 1,224. A bounce
within T04 would need the spring resolved more finely than the guard's two steps. A larger factor would be a fitted
constant, which this record does not use. The patch stays in design. F8 stays open, now with this finding: the guard
extended to the damping stops the energy, and the bounce's step dependence is its own problem.

Kept: the release and on arms in full (`release/`, `on/`). From the off arm, its readings only (`off/`), since all
of its files are byte-identical to the release's.
