# Run 045: a free cube's direction under the elliptic cone, traced (a probe)

16 October 2026. Not registered: a design probe on Google DeepMind's Linux release of MuJoCo 3.16.0, played on the first
cloud machine by [`probe.sh`](probe.sh) and [`probe_2.sh`](probe_2.sh), each pushed before its plays. It finds where
to look and decides nothing.

In [Study 10](../../docs/studies/10-recommended-configuration-end-to-end.md), under Senua AI's configuration (the elliptic
cone with 10 noslip iterations), a 1.861 kg cube slid at 1.01 m/s free to turn went 136,043 um along 22.5 degrees,
against 133,042 along 0 and 133,266 along 45; Coulomb's distance is 133,451 (the probe's header writes 133,450). Kept
from turning, it slid the same along every direction (finding F12). The question: where does the direction come from?

The contact rig gains two settings, each changing nothing unless set: `noyaw` (free to tilt, not to turn about the
vertical) and `trace` (a side file: every step's yaw, tilt and each contact's place, normal force, friction force and
its ratio to the friction limit). **Step 0, the rig unchanged without them** ([`identity.txt`](identity.txt)): Study
10's free cube under the release, its defaults and the configuration, played again with and without `trace`: 6 of 6
files byte-identical to run 042's.

## Step 1: is the turn about the vertical what carries it further?

The cube along 0, 11.25, 22.5, 33.75 and 45 degrees at 1.14 and 0.285 ms, under the configuration (rec), the elliptic
cone alone (ell) and MuJoCo's defaults (def), free, free to tilt but not to turn about the vertical (noyaw), and kept
from turning (locked) ([`measured.txt`](measured.txt), `plays/`). Slid, um (`sx_contact stop`), under the configuration:

| At 1.14 ms | Along 0 | 11.25 | 22.5 | 33.75 | 45 |
|---|---|---|---|---|---|
| Free | 133,042 | 135,526 | 136,043 | 135,039 | 133,266 |
| Free to tilt, not to turn | 133,042 | 135,237 | 134,633 | 134,641 | 133,239 |
| Kept from turning | 133,036 | 133,036 | 133,036 | 133,036 | 133,036 |

**No.** With the turn about the vertical locked the cube still goes 1.2% to 1.6% further off the axes; the turn adds a
little more (it turns up to 27 mrad at 1.14 ms and 53 mrad at 0.285 ms). The direction comes only with the freedom to tilt. The elliptic cone alone shows the same (136,051 along 22.5 against 133,047 along 0 at 1.14 ms).
The fine step shows it too (rec, free: 133,491, 135,636,
135,734, 135,143, 133,605). Under MuJoCo's defaults the pyramid's own direction (finding F2) is far larger (133,051 to
188,282) and hides this one.

**The friction along the slide falls short of friction times the normal force off the axes.** Over the sliding steps
of the noyaw plays at 1.14 ms (the play files' force columns, a diagnostic): 0.39000 along 0, 0.38332 along 22.5,
0.38782 along 45, where friction is 0.39; kept from turning, 0.39000 along every direction. Every contact in the trace
is at its full friction (ratio 1.000000): the friction is not weak; part of it points away from the slide.

## Step 2: does any of MuJoCo's contact settings remove it?

Under the configuration, free, along 0, 22.5 and 45 at both steps, with MuJoCo's contact reference (`solref`, time
constant and damping ratio) and `impratio` ([`measured_2.txt`](measured_2.txt), `plays_2/`):

| Free, slid along 22.5 against along 0, at 1.14 and 0.285 ms | 1.14 ms | 0.285 ms | Highest while sliding, 1.14 ms |
|---|---|---|---|
| MuJoCo's default (0.02 s, damping ratio 1) | +2.3% | +1.7% | 153 um |
| Damping ratio 2 | +1.1% | +1.8% | 168 um |
| Damping ratio 4 | +1.1% | +0.8% | 207 um |
| Time constant 0.01 s | +1.9% | +1.6% | 378 um |
| Time constant 0.005 s | +1.5% | +1.3% | 1,239 um |
| Time constant 0.005 s, damping ratio 2 | +1.1% | +1.2% | 1,233 um |
| `impratio` 10 | +1.1% | +1.7% | 184 um |

**None removes it**, and the steps with fewer than four contacts stay in every one (76 to 640 along 22.5 degrees). A stiffer
contact makes the cube rise higher while it slides: 1,239 um at 0.005 s against 153 at MuJoCo's default; kept from
turning, 1,497 against 97.

## What the trace shows

**The cube hops while it slides, and so does the cube kept from turning.** Set down touching the ground and set
sliding, the cube kept from turning has four contacts on the first step, none on the next five (its lowest face 20 to
45 um above the ground), lands on step 7 with 4.6 times its weight, and goes on hopping for the whole slide, with no
contact at all on 128 of the 254 steps it slides for
(`plays_2/locked_base_0_0.00114.trace` and `.txt`). This is finding F3, a sliding body leaves the surface, whose cause
the record traced in [run 016](../run_016_sliding_lift/README.md): the convex relaxation of the friction cone lets a
sliding contact separate at friction times the sliding speed (Anitescu 2006; Le Lidec et al. 2024).

**Free to turn, it lands on its corners.** The free cube touches the ground at 0, 1 or 2 corners on most steps, never
settling on four (`plays_2/base_0_0.00114.trace`), and tilts up to 3,216 urad along 0 and 9,188 along 45, where the
friction's moment needs a tilt of about 150 urad and leaves all four corners loaded (the friction's moment over the
four contacts' stiffness, from the cube's 17 um depth at rest). Each landing corner's friction tips it. Along 0 and 45
the cube's symmetry about the slide keeps the tips in the plane of the slide; off the axes it does not, the corners'
own motion turns their friction away from the slide, and the slide goes further.

## What it shows

- **F12 is a consequence of F3.** The hop the relaxed cone makes leaves the cube landing on its corners, and off the
  axes those landings turn part of the friction away from the slide. Kept from turning, the cube hops but has no
  direction.
- **No setting of MuJoCo's removes it**: not the cone, noslip, `impratio`, nor the contact's time constant or damping;
  a stiffer contact makes the hop higher.
- **Where to look next:** the relaxation itself. De Saxce and Feng (1991) showed that exact Coulomb friction is a cone
  complementarity in a velocity shifted by friction times the sliding speed, the term the convex relaxation leaves out;
  restoring it, by a fixed point on that shift, recovers Coulomb's law with a convex solve at each iteration (Acary,
  Cadoux, Lemarechal and Malick 2011). A patch in that form, for MuJoCo's elliptic cone, is the candidate for F3 and F12
  together.

The solver never reached its iteration limit and raised no warning in any play.
