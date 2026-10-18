# Run 041: the configuration end to end, under the default integrator and under RK4 (a probe)

15 October 2026 (21:35 UTC). Not registered: a design probe on the first cloud machine, by [`probe.sh`](probe.sh),
pushed before any play. It finds where to look and decides nothing. The question: which integrator can MuJoCo's
recommended configuration, the elliptic cone with 10 noslip iterations (Study 2), with the inverse weight in the current
pose, third version, switched on, be put end to end with? The draft of the tenth registration's plays and rules, on
throwaway numbers (Study 8's arm and cubes, Study 2's cube, run 039's body), on four arms: the release under MuJoCo's
defaults (`rel_def`) and under the configuration's options (`rel_rec`), and Study 9's patched build, switch set, under
the configuration with MuJoCo's default integrator (`cfg_euler`) and with RK4 (`cfg_rk4`). No build and no MuJoCo test
suite. Every measured number is in `measured.txt`, every rule's line in `rules.txt`.

## What it found

| Arm | Rule lines held | The lines that did not hold |
|---|---|---|
| cfg_euler | 123 of 133 | The tumbling body, all eight (energy 34,145 to 507 per million, angular momentum 12,677 to 188, from 10 ms to 0.156 ms); the free cube along 22.5 degrees, 138,959 um against 136,610 along 0 (1.7%, bound 1 in 100); the most iterations, 11 against the release's 6 plus 3 |
| cfg_rk4 | 130 of 133 | The first suite, 7 of 10; the free cube along 22.5 degrees, 139,773 against 136,529 (2.4%); the most iterations, 14 |

Every other line held under both: every hold at most 10 um/s, the grips held, the slides with no direction and no drift
and at Coulomb's distance, and every written-pose line of the arm, on contact, on a limit, held by joint friction, by a
`connect` and by a `weld`, 0 nm and 0 um/s apart.

- **No integrator passes everything.** The default integrator fails the tumbling body (known issue M10, as Study 9
  found); RK4 fails the contact refinement chain (finding F4, run 014).
- **The free cube's direction is MuJoCo's, not the patch's.** Under the configuration's options the release plays every
  cube file byte for byte as the patched build with the switch set (188 of 188). Slid free to turn along 22.5 degrees,
  the cube goes 1.7% further than along 0 and drifts 996 um sideways; under MuJoCo's defaults, 20% further and 35,857 um.
- **The most iterations come from the arm and the free cube.** On the holds, the slides kept from turning and the suites,
  the plays Study 2's iteration rule was registered on, the release needs 4 iterations under its defaults and 5 under the
  configuration's options (run 042's dry run).

## What it shows

The tenth registration puts the configuration end to end under both integrators, each with a decision of its own, each
rule on the plays its own study registered it for, with these readings stated before its run as known risks.

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 136,529 um | 136,544 um |
| 136,610 um | 136,623 um |
| 138,959 um | 138,972 um |
| 139,773 um | 139,787 um |

What this page concludes does not change: the largest of these corrections is 0.01%.
