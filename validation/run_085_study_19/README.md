# Run 085: Study 19, noslip leaving the rolling friction as it was, for the box that never rests

17 October 2026 (04:00 to 04:20 UTC). The nineteenth registered study,
[`PREREGISTRATION_19.md`](../../preregistrations/PREREGISTRATION_19.md), played once on the first cloud machine by
[`play.sh`](play.sh), the runner as registered (sha256 256f2b5ce52a0baa...), from an archive of the registration's commit
(65718ab). The rule lines are in [`rules.txt`](rules.txt), the readings in [`measured.txt`](measured.txt), the draw in
[`draw.txt`](draw.txt), the fresh boxes' scenes in `scenes/`.

## Result: 9 of 9 rule lines held

Over each play's last 160 steps, how many are faster than 1 mm/s:

| Box | Released | Senua AI's four validated switches | **The four and the rolling switch** |
|---|---|---|---|
| MuJoCo's own, as written and with 100 noslip iterations | 106, 106 | 106, 106 | **0, 0** |
| Box 1 (0.0509 m, 0.978 kg, 1.21 m/s), at 16 and 14.11 ms | 107, 108 | 107, 106 | **0, 0** |
| Box 2 (0.0416 m, 1.565 kg, 2.05 m/s) | 128, 106 | 128, 106 | **0, 0** |
| Box 3 (0.0491 m, 1.342 kg, 2.58 m/s) | 106, 106 | 106, 106 | **0, 0** |

With 100 noslip iterations each box reads as with the scene's 2. Released, and with the four validated switches, every
box rocks, up to 77 mm/s. With the rolling switch, in all 14 plays no step of the last 160 is faster than 10 um/s (R1).
The arm, the holds with condim 3 and 4 and the grips are byte for byte as with the four validated switches alone (N1,
32 of 32 files).

With every switch unset, all 46 play files are the release's, and every one of MuJoCo's 3,492 tests gives the release's
result (E1, E2). Each reading lists all 3,492 tests (M0). With the five switches set, the only test that changes is
`SolverTest.ZeroToleranceDisablesTermination`, one of the two Study 12 named (M1). No step reached the iteration limit,
and there was no warning (V1).

## What it decides

As registered: **issue 20, a box that should rest keeps moving under the discrete integrator with torsional and rolling
friction and noslip, is fixed and validated** by Senua AI's set with this patch,
[`noslip_roll_kept_after_qcqp.diff`](../../patches/noslip_roll_kept_after_qcqp.diff), which moves from
`patches/in_design/` to `patches/`.

Not decided: issue 1's open part (a body that cannot turn, with condim 4 or 6); rolling friction's effect on a rolling
body; the PGS solver; anything against a real robot.
