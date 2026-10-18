# Run 079: noslip leaving the rolling friction as it was (a probe)

17 October 2026 (02:48 to 03:08 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Readings in
[`measured.txt`](measured.txt).

[Run 076](../run_076_box_rolling_trace/README.md) traced the box that never rests (issue 20) to noslip driving every
contact's rolling torque to the edge of the elliptic cone, which one ellipsoid shares across all of a contact's friction.
A patch in design, [`noslip_roll_kept.diff`](../../patches/in_design/noslip_roll_kept.diff) (switch
`MUJOCO_NOSLIP_ROLL_KEPT=1`, `engine_solver.c` only, 46 lines added, none removed), changes how noslip solves a condim-6
contact. It leaves the rolling friction as it was before the sweep, and solves the sliding and torsional friction, with
MuJoCo's own solver, in what the cone has left. It is built from MuJoCo's source at `UPSTREAM_COMMIT`, with its tests.

With the switch unset, all 35 files are byte for byte the release's, and all of MuJoCo's 3,492 tests give the release's
result. With it set, none of MuJoCo's tests changes.

## The box

| The box of run 049 (MuJoCo's test scene), 16 s | Released | With the switch set |
|---|---|---|
| As written: its last 160 steps faster than 1 mm/s; the fastest | 106; 77 mm/s | **0; 0** |
| With 100 noslip iterations | 106; 77 mm/s | **0; 0** |
| With condim 4 | 0 | 0, byte for byte |

With the switch set the box comes to rest. Its last step faster than 1 mm/s is step 16 (0.26 s), and it stays at rest
for the remaining 15.7 s.

## Everything else played

| Under Senua AI's configuration, run 063's cube | Released | With the switch set |
|---|---|---|
| condim 3: held at 0.5 and 0.95 of its limit | 0 and 0 um/s | the same, byte for byte |
| **condim 6: held at 0.5 and 0.95 of its limit** | **498 and 946 um/s** | **498 and 946 um/s** |
| condim 6: slid kept from turning; free to turn | 133,045 um; 134,901 um at 1.14 ms | 133,045; 134,902 |
| The grips (condim 3) | 0 or 1 um/s | the same, byte for byte |

Only the two boxes and the two condim-6 free slides change, the free slides by 1 um.

**A finding against issue 1.** Under the configuration, a cube with MuJoCo's rolling friction (condim 6), held at 0.5
of its friction limit, creeps at 498 um/s once pushed, and at 946 um/s at 0.95, at both steps. With condim 3 the same
cube holds at 0. Issue 1's fix was validated on MuJoCo's default contact, condim 3. Studies 2, 10, 13 and 15 played
nothing else, and Study 15 named condim 4 and 6 as not decided. The patch leaves the creep as it was. It keeps the
rolling friction as MuJoCo's main solve left it, and run 076 found the main solve's own friction on the cone's edge as
well.

## What it shows

- **Issue 20.** Leaving the rolling friction out of noslip's solve brings MuJoCo's test box to rest, and changes nothing
  else played but a 1 um free slide.
- **Issue 1, for condim 6.** A held object with rolling friction still creeps under the configuration, released and
  with this patch. Both this and issue 20 come from the rolling friction sharing one ellipsoid with the sliding
  friction. A design that gives the rolling friction a cone of its own in noslip may answer both, and is the next probe.
