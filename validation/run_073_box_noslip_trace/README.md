# Run 073: what MuJoCo's noslip computes for the box that never rests (a probe)

17 October 2026 (01:04 to 01:06 UTC). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh), pushed before its plays. It finds where to look and decides nothing. Readings in
[`measured.txt`](measured.txt), one line a noslip pass in `trace/*.steps`, and the trace itself in `trace/*.trace.gz`.

Issue 20 (F13) is MuJoCo's own test scene `DiscreteImplicitRowNoslip`: a box slid at 2 m/s on a plane, at a 16 ms step,
under the discrete integrator, the elliptic cone, impratio 10, condim 6 and 2 noslip iterations. It never comes to rest.
Run 050 found the cycle needs rolling friction and noslip. Run 055 found it the same with noslip run to a tolerance of
1e-12. Run 062's instrumentation patch, [`noslip_trace.diff`](../../patches/in_design/noslip_trace.diff), prints what
noslip computes for each elliptic contact. It is built from MuJoCo's source at `UPSTREAM_COMMIT`. The probe plays the
scene as written (run 049's copy, 16 s) and with 100 noslip iterations. With the switch unset the plays are byte for
byte the release's and print nothing; traced, byte for byte as untraced.

## What noslip computes

| | As written (2 noslip iterations) | 100 noslip iterations |
|---|---|---|
| Noslip's sweeps a pass, the last 160 | 2 every pass | 2 every pass |
| Zero friction returned | never | never |
| The play | | **byte for byte as written** |

Noslip stops on its own tolerance after its second sweep every step, so 100 iterations play exactly as 2. It never
returns zero friction for a contact. None of the arm's defect (run 062) is here.

## What the cycle is

The box's contacts with the plane go 4, 4, 4, 4, 2, 2 and repeat, from the first steps of the play. Over the last 12
steps:

| Contacts | 4 | 4 | 4 | 4 | 2 | 2 |
|---|---|---|---|---|---|---|
| The box's speed after the step, um/s | 13,651 | 3,830 | 564 | 54 | 58,832 | -76,978 |

For four steps the box sits on its four corners and its speed falls almost to rest. Then two corners leave the plane for
two steps, and the box is thrown forward and back at up to 77 mm/s. The contacts read as a rocking, the box on one edge
for two steps of every six (its tilt is not traced here).

## What it shows

Issue 20 is not noslip failing to converge, nor its friction solve rejecting a block. The box rocks onto an edge and
back on a fixed cycle. Run 050 found that it needs rolling friction (condim 6): with condim 4 it rests. The rolling
friction rows are where to look next: what noslip asks of them while the four corners carry the box, and whether that
tips it.
