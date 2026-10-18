# First pre-registration: friction without a direction, the slip-aligned pyramid

Registered 15 October 2026, after design probes (runs 003, 005, 011). Registered before any play of this registration
existed. Played once, as run 012.

## The question

MuJoCo's default friction cone is a pyramid whose edges lie along the contact frame's tangents, so the friction it can
give has a direction (runs 003, 005). The patch in design `patches/in_design/slip_aligned_pyramid.diff` turns each
slipping pyramidal contact's tangents about its normal so the first lies along its slip (switch
`MUJOCO_SLIP_ALIGNED_PYRAMID=1`). On scenes the probes did not use: does MuJoCo as shipped still give friction a
direction; with the switch on, is the slide and the hold the same along every direction and Coulomb's; does nothing
else change; and with the switch unset, is the patched MuJoCo the release byte for byte?

## Engines and arms

- **stock**: Google DeepMind's Linux release of MuJoCo 3.16.0 (`mujoco-3.16.0-linux-x86_64.tar.gz`, sha256
  139577c541d43716...), MuJoCo's own defaults (pyramidal cone, Euler, 100 iterations).
- **off**: MuJoCo built from source at the commit in `UPSTREAM_COMMIT` with the patch file of sha256
  eeb0118d675d0435... applied, as in run 011; switch unset.
- **on**: the same build, `MUJOCO_SLIP_ALIGNED_PYRAMID=1`.

Rigs as committed at this registration: `tools/mjc_contact.c`, `tools/mjc_pair.c`; measured by Senua AI's `sx_contact`
(the first deep dive's measuring program, built for Linux) and judged by its `rule`.

## The scenes, registered parameters

None of these numbers was used in the probes, except the first deep dive's two contact suites, played with their own
registered parameters.

- **The cube**: 1.4 kg, half-size 0.04 m, friction 0.35, held level (`lock=1`) unless a line says free.
- **The slide**: set sliding at 0.8 m/s along 0, 15, 30, 60 and 75 degrees from x, 1.2 s, at 1 ms and 0.25 ms.
  Coulomb's distance: 0.8^2 / (2 x 0.35 x 9.8) = 93,294.5 um.
- **The hold**: pushed from 0.4 s along 0, 30 and 60 degrees with 0.65 and 0.85 of what friction can hold (4.802 N:
  3.1213 N and 4.0817 N), 1.6 s, at 1 ms. The diamond of run 003 holds along 30 or 60 degrees only up to
  1 / (cos 30 + sin 30) = 0.732 of the limit.
- **The free cube**: the same slide with the cube on a free joint (`lock=0`), along 0, 30 and 60 degrees, at 1 ms.
- **Nothing else**: the first deep dive's two contact suites (`tools/contact_suite.sh`, `tools/contact_suite2.sh`),
  MuJoCo's defaults.

## The rules

Each is judged by `sx_contact rule`, from the measured lines, and nowhere else.

| Rule | Statement | Kind |
|---|---|---|
| R1 safe when off | Every file the off arm plays is byte-identical to the stock arm's | eq (identical files, files) |
| R2 the defect is there | Stock, level cube, 1 ms: the slides along 30 and 60 degrees each go at least 15% further than along 0 degrees | share |
| R3 no direction, slide | On, level cube, each step: the slides along 15, 30, 60 and 75 degrees are each within 1 part in 10,000 of the slide along 0 degrees | all_within |
| R4 no drift | On, level cube, both steps: the drift across the line is at most 10 um along every direction | all_le |
| R5 Coulomb | On, level cube, 0.25 ms: every direction's distance is within 1 part in 100 of 93,294.5 um (as 93,295) | all_within |
| R6 no direction, hold | On, the hold at 0.65 and at 0.85: the creep along 30 and along 60 degrees is each within 1 part in 100 of the creep along 0 degrees at the same push | all_within |
| R7 the stock hold lets go | Stock, the hold at 0.85 along 30 degrees: its creep is at least 10 times the creep along 0 degrees at 0.85 | share |
| R8 free cube | On, free cube: the slides along 30 and 60 degrees each within 1 part in 100 of the free slide along 0 degrees, and drift at most 1,000 um | all_within, all_le |
| R9 nothing else changes | On, every play of both contact suites is byte-identical to stock | eq (identical files, files) |
| R10 the solver | On, over every play: no step at the iteration limit, no warning, and the most iterations of any step no more than stock's most plus 2 | eq, eq, le_plus |

The study holds if every rule holds. A rule that fails is reported as failed, with its numbers, and the patch stays in
design.

## Dry run

The rigs, the patch and both builds are those of run 011, unchanged. The study's runner is new: it is played once
before the study on throwaway parameters (a 1 kg cube, half-size 0.05 m, friction 0.4, 1 m/s, the stock build only),
only to check that it runs to the end and writes every rule's line; no rule is read from it, and its files are kept
apart from the study's.
