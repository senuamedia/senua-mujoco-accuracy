# Run 006: the contact rig's height column, one step late, corrected

15 October 2026. Not registered: a correction to the record's own rig, found while writing the next rigs.

## What was wrong

The contact rig [`tools/mjc_contact.c`](../../tools/mjc_contact.c) read the cube's position after `mj_step`. MuJoCo
computes positions before it integrates, so after `mj_step` they are still the step's start. The height column (and
the drift across a direction, `side_um`) therefore ran one step behind the velocity and force columns, which are the
step's end. The first deep dive's rig and the Newton rig report the state the step ended in, so the column did not
mean the same thing across the three engines. The joint rig reads only the joint's own state and was never affected.

The rig now recomputes the positions after each step (`mj_kinematics`). That changes nothing in the play: the next
`mj_step` recomputes them before it uses them.

## How it was checked

[`replay.sh`](replay.sh) played runs 001, 003 and 005 again on run 002's Linux machine, unchanged but for the rig,
and compared every file with the record's (`compare.txt`; the new plays are under `runs/`):

| | Files |
|---|---|
| Byte-identical: the joint plays, and the solver statistics without a direction | 44 |
| Every step's columns 1 and 3 to 6 byte-identical, and each step's height the height the record has on the next line: every contact play | 120 |
| Different otherwise | 3 |

The three:

- `p3_hold_rk4.txt` (run 001): columns 1 and 3 to 6 byte-identical; the heights differ only over the first steps of
  the set-down. With the `RK4` integrator, MuJoCo leaves the positions at its last internal stage rather than at the
  step's start, so the old heights were not a one-step shift either. Its reading is unchanged.
- Run 005's statistics and reading: the plays still moving at their last step, where the step's start and end differ.

Every reading of runs 001 and 003 is byte-identical. Run 005's changed lines:

| Run 005 | In the record | Corrected |
|---|---|---|
| Depth at rest, 20 ms (the rig's last line) | 67,870 nm | 67,868 nm |
| Depth at rest, 30 ms | 150,180 nm | 149,983 nm (still settling, 7 um/s, at the end of the play) |
| Depth at rest, 40 ms | 275,789 nm | 269,269 nm (still settling, 163 um/s) |
| Pushed along 22.5 degrees at 0.8, 0.85, 0.9 of the limit: across the push | 57,774, 141,879, 224,760 um | 57,931, 142,259, 225,362 um |
| The drop's lowest point after the turn, 15, 20, 30, 40 ms (`rebound_nm`) | -5, -93, -17,146, -191,068 | -4, -72, -13,146, -146,326 |

No rebound changed (all 0), and no finding changed. Run 005's README carries the corrected numbers.
