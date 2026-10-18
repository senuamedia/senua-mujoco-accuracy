# Run 083: what noslip computes for a held cube with rolling friction (a probe)

17 October 2026 (03:34 to 03:36 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Readings in
[`measured.txt`](measured.txt), one line a noslip pass and contact in `trace/*.passes`, the trace in `trace/*.trace.gz`.

Runs 079 and 082 found a cube with rolling friction (condim 6), held under Senua AI's configuration at 0.5 of its
friction limit, creeping at 498 um/s. That is the elliptic cone's creep with no noslip at all; with condim 3 the cube
holds at 0. Run 076's instrumentation patch, [`noslip_trace_all.diff`](../../patches/in_design/noslip_trace_all.diff),
prints every friction component of each elliptic contact with torsional or rolling friction at each noslip sweep. The
probe plays run 063's cube held from 0.4 s, 0.6 s at 1.14 ms, with condim 6, condim 4 and condim 3. The contact rig holds
this cube from turning (three slide joints, its default). With the switch unset the plays are byte for byte the
release's and print nothing; traced, byte for byte as untraced.

## What noslip computes

| | condim 6 | condim 4 | condim 3 |
|---|---|---|---|
| The cube's speed at the last step | 498 um/s | 498 um/s | 0 |
| The friction solve's result for each of the 4 contacts, every sweep of every pass | **zero** | **zero** | (not traced) |
| Kept after MuJoCo's cost check | the old friction put back, in every pass after the push | the same | |

For a contact with torsional or rolling friction on this cube, noslip's friction solve (`mju_QCQP3` for condim 4,
`mju_QCQP` for condim 6) returns zero every time. MuJoCo's cost check then puts the old friction back, so noslip does
nothing and the cube creeps at the soft solve's rate. Before the push the old friction is zero, and zero is kept.

The cube cannot turn, so the torsional and rolling directions of its contacts cannot move: their entries in the
contacts' block are zero. The solve's factorization rejects such a block by its absolute threshold and returns zero.
That is the defect run 062 traced in the arm resting on its ball (issue 1), there in one friction direction across a
planar arm. The friction solved in the directions that can move, [`qcqp_reduced.diff`](../../patches/qcqp_reduced.diff),
validated in Study 15, drops such directions. Runs 079 and 082 were built without it.

## What it shows

Issue 1's fix was validated with condim 3 only. Under the configuration as released, a held cube with torsional or
rolling friction creeps, for issue 1's own reason. Whether Senua AI's set, which carries the friction-solve patch, holds
it is not yet played. [Run 084](../run_084_set_condim_holds/README.md) plays it, and the box that never rests, with the
set.
