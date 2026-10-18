# Run 028: MuJoCo's own remedy for the frozen diagonal, the diagexact flag

15 October 2026. Not registered: a design probe on Google DeepMind's Linux release of MuJoCo 3.16.0, played on the
cloud machine by [`probe.sh`](probe.sh), pushed before any play. It finds where to look and decides nothing.

Run 025 found that a contact's softness depends on the pose its scene was written in (finding F10). MuJoCo's
documentation names the cause ("Diagonal approximation" in its computation chapter: the approximation is frozen at
`qpos0`, averaged into a scalar, and treats bodies as independent) and its remedy, an enable flag, `diagexact`, which
replaces the approximation with the exact diagonal of the constraint inertia, J inv(M) J', in the current pose. This
probe plays it. The contact, pair, arm, stack and grip rigs gain a setting, `diagexact=1`, that sets the flag and
nothing else.

## How it was played

- **Step 0, the rigs unchanged without it** ([`identity.txt`](identity.txt)): run 025's 24 plays, run 026's stack of
  ten and slides on a box, run 027's grip at 2 ms, and both of the first deep dive's contact suites, played again
  without the setting: **147 of 147 files byte-identical** to the record's. The suites are compared with Study 3's
  release plays (run 023). The first start compared suite 2 with the record's `suites/2/defaults`, which keeps run
  008's two-cube plays, made before run 009 corrected the pair rig's frictionless ground: its 16 two-cube files
  differed for that reason alone ([`identity_first_start.txt`](identity_first_start.txt)), and its grip plays did not
  run, the grip rig lacking the setting. Both were corrected and pushed, and the whole probe played again.
- **The arm, the stack and the grip** of runs 025 to 027, each with `diagexact`, under MuJoCo's defaults
  (**diagexact**) and with the elliptic cone and 10 noslip iterations (**recommended with diagexact**).
- **Both contact suites**, under the same two configurations.

Every play is read by Senua AI's measure as runs 008 and 025 to 027 read theirs ([`reading.txt`](reading.txt),
`suite1_*.txt`, `suite2_*.txt`). The solver never reached its iteration limit (at most 11 iterations a step) and raised
no warning ([`solver.txt`](solver.txt)).

## The readings

**The written pose no longer matters.** With `diagexact`, the arm written in its own pose, straight and folded ends
in the same place: 0 nm apart in 28 of the 32 comparisons, under both configurations. The other four are pose A set
down touching the ground and written folded, 2 to 17 nm apart at the end: written that way, rounding leaves the ball
a hair above the ground at the start, so it has no contact on the first step and sinks 41 um on it (the files' first
lines), as in run 025; the drop plays, which start 10 mm up, end 0 nm apart. Without the flag the writings ended 1 to 107
um apart (run 025). The ball creeps at the same speed in every writing: 735 um/s in pose A (852, 519 and 711 without
the flag) and 1,318 um/s in pose B (503, 376 and 513).

**Under the default cone, symmetric scenes turn.** With `diagexact` and MuJoCo's pyramidal cone:

| Scene | Without the flag (run 026, 027) | With `diagexact` |
|---|---|---|
| A straight stack of three | stands, no tilt; 51 um deep at the ground | tilts 1.1 mrad; 193 um deep at the ground |
| A straight stack of ten | stands, no tilt | the top cube tilts 4.6 mrad and is still turning at 1.6 mrad a second at 2 s |
| The offset stack | tilts up to 1.5 mrad, creeps up to 26 um/s | tilts up to 4.8 mrad, creeps up to 276 um/s |
| A cube slid to a stop | ends level | ends tilted 402 urad |
| A grip at the cube's centre | slips 6.1 mm/s, does not turn | slips 7.3 (box) and 8.1 (mesh) mm/s, turns 112 and 118 mrad in 2 s |
| A grip 10 mm off centre | turns 217 (box) and 201 (mesh) mrad | turns 173 (box) and 325 (mesh) mrad |

The same at both steps. The likely cause, from MuJoCo's formula and not traced in its source: the pyramid gives each
contact four edge rows, normal plus and minus friction times each tangent. The approximation gives the four the same
regularisation; the exact diagonal gives each its own, and when the contact point is off the body's centre the edges'
rotational parts differ, so the friction is regularised unevenly and turns the body.

**With the elliptic cone and noslip, the flag holds what that configuration held, but stacks sink and one does not
settle.** Recommended with `diagexact`: the arm in pose A is held (0 um/s) but in pose B creeps at 1,152 um/s (309
without the flag, run 025); the grip is held (1 um/s, at most 127 urad turned); straight stacks of three and ten stand
untilted but sink far deeper, 704 um at the ground under three cubes (294 without the flag) and 3.5 mm at the second
contact of ten; the stack of ten at 2 ms has not settled at 2 s (its contacts' depths out of order with their loads),
and the stack of five at 0.5 ms is not at rest: its top cube moves at 3.3 mm/s, tilted 10.7 mrad. The offset stack
tilts 12 mrad.

**The suites.** Suite 1, `diagexact` under the defaults: 9 of 10, the hold failing as released (1,293 um/s); with the
elliptic cone and noslip: 10 of 10. Suite 2 is kept as measured (`suite2_*.txt`).

## What it shows, and what it does not

MuJoCo's own remedy removes finding F10: with `diagexact` the same arm does the same thing however its file was
written. But it has costs this record had not seen: under MuJoCo's default cone a straight stack, a cube slid to a stop
and a centred grip turn where nothing should turn, and under the elliptic cone with noslip stacks sink millimetres and
one is not at rest, and with noslip the arm's creep in pose B is nearly four times as fast. As with the lift (finding F3), no configuration
of MuJoCo's own options played here removes F10 without a cost of its own. A probe, deciding nothing. A correction that
keeps MuJoCo's own approximation, one regularisation for the four edges, but takes it in the pose the bodies are in,
would answer the first of the documentation's three sources of error without the turning; it is the next design.
