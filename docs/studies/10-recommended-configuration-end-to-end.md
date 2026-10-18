# Study 10: MuJoCo's recommended configuration end to end, under its default integrator and under RK4

| | |
|---|---|
| Question | On numbers no earlier study used, does MuJoCo's recommended configuration (the elliptic cone with 10 noslip iterations), with the inverse weight in the current pose, third version, switched on, meet every rule this record's studies carry that it can be put to, under MuJoCo's default integrator and under RK4? With the switch unset, is the patched MuJoCo the release, and does the switch change nothing else? |
| Outcome | **290 of 298 rule lines held.** The 32 shared held; the default integrator held 127 of 133 and RK4 131 of 133, so **the configuration is not validated end to end under either**. **The third version is validated under the configuration with both integrators**, and **Study 2's contact result is replicated** under the default integrator. Failed: a free cube slid along 22.5 degrees, 2.3% and 1.4% further than along 0 (MuJoCo's own, as the release plays it byte for byte); the tumbling body under the default integrator (5 lines, known issue M10); the ten tests under RK4, 9 of 10 (free flight is exact under RK4, so the test's ratio cannot be read) |
| Registered | [`PREREGISTRATION_10.md`](../../preregistrations/PREREGISTRATION_10.md), 16 October 2026, pushed with its runner and dry run before any play |
| Played | Once, as [run 042](../../validation/run_042_study_10/README.md), 15 October 2026 21:49 UTC, on Linux (the first cloud machine, 4 virtual CPUs and 8 GB) |
| Arms | MuJoCo 3.16.0 as released, under its defaults and under the configuration's options; the patched build with the switch unset under each; the configuration with the switch set, under the default integrator and under RK4 |
| Measured by | The Senua AI Robotics Core's measuring programs (`creep`, `stop`, `final`, `ends`, `tumble`), the first deep dive's suite runner, MuJoCo's own test suite, judged by `rule`; held to [Coulomb's law](../references.md#coulomb), [Popov 2010](../references.md#popov); MuJoCo's soft constraints, [Todorov 2014](../references.md#todorov-2014) |

## Why it was asked

Each part of the configuration was validated on its own rules: the elliptic cone with noslip by Study 2, the third
version by Studies 8 and 9. [Study 9](09-weld-and-tumbling-body.md) found that only RK4 keeps a free tumbling body's
energy and angular momentum, and finding F4 that RK4 can put the contact refinement chain out of order. Run 041, a probe
on throwaway numbers, put the whole configuration to the rules under both integrators and found neither passing every
line. This study asked it on fresh numbers, with a decision for each integrator fixed in advance.

## The scenes

Drawn from seed 10 (`draw.txt`): a 1.861 kg cube held at 0.5, 0.75 and 0.95 of its friction limit and slid at 1.01 m/s
along 0, 22.5 and 45 degrees, kept from turning and free to turn; the first deep dive's two contact suites; stacks, an
offset stack and slides on a box's face; a 0.202 kg cube gripped between two pads, box and mesh, with friction 1.93 times
its weight, centred and 9.3 mm off; an arm of links 0.271 and 0.275 m on contact, set down and dropped, and held 1 m up on
an elbow limit, by joint friction, by a `connect` and by a `weld`, each in two poses written three ways; a free body of
moments 0.007011, 0.005134 and 0.007883 kg m2 spinning at 3.09 rad/s; at 1.14 ms and 0.285 ms (the tumbling body at the
record's ladder); and MuJoCo's own test suite.

## The result

| Rules | Default integrator | RK4 |
|---|---|---|
| Shared: the release's defects, safe when off, the switch changing nothing else (Q, E, N) | 32 of 32: released, the hold creeps 581 um/s, a slide along 45 degrees goes 42% further, and the arm ends up to 47 um (contact), 182 um (limit), 21 mm (joint friction), 98 um (`connect`) and 85 um (`weld`) apart by writing; with the switch unset 261 of 261 files as released under each option set; with it set 188 of 188 as released; all 3,492 of MuJoCo's tests passed in all three arms | (shared) |
| Holds, grips, slides, Coulomb (H1, G1, S1 to S3) | Held: every hold 0 um/s, every grip 0 or 1 um/s, the slides the same to the micrometre along every direction with no drift, Coulomb's distance to 1.5 in 10,000 | Held |
| The free cube (S4) | **Failed**: along 22.5 degrees 2.3% further than along 0 | **Failed**: 1.4% further |
| The ten tests (K1) | 10 of 10 | **9 of 10** |
| The written pose (A4 to A6) | Held, 112 lines: every writing 0 nm and 0 um/s from the native, the creep alike | Held |
| The solver (V1, V2) | Held | Held |
| The tumbling body (T1, T2) | **3 of 8**: the energy +5,027 and +1,254 per million at 10 and 2.5 ms; the angular momentum +2,421, +604 and +150 at 10, 2.5 and 0.625 ms | 8 of 8: 0 at every step |
| Lines held | **127 of 133** | **131 of 133** |

## What the decisions record

- **The recommended configuration is not validated end to end**, under the default integrator or under RK4.
- **The third version is validated under the configuration with both integrators**: on contact, on a joint limit, held
  by joint friction, by a `connect` and by a `weld`, every writing of one arm in one place ends in one place, and with
  the switch unset MuJoCo is the release, file for file and test for test.
- **Study 2's contact result is replicated on fresh numbers under the default integrator**: every hold holds, the
  slides have no direction and go Coulomb's distance, all ten tests pass. Under RK4 it is not, as one test failed.

## What it means

- **No single configuration of MuJoCo passes every rule this record holds it to.** The default integrator keeps contact
  right and loses a free body's energy and angular momentum at first order; RK4 keeps the free body and fails a test
  written for a first-order integrator (T01: free flight under RK4 is exact, so its gaps are 0 and the test's ratio
  cannot be read). Which to use depends on the motion: contact-rich work under the default integrator, free and
  spinning bodies under RK4.
- **A free cube still has a direction under the elliptic cone**: slid free to turn along 22.5 degrees it goes 1.4% to
  2.3% further than along 0 or 45, against 20% under MuJoCo's defaults. The patch does not touch it (the release plays
  it byte for byte). Its cause has not been traced; it is open.
- It says nothing about MuJoCo's pyramidal cone, a stack's sink, a sliding body's lift, a bounce, gradients, or a real
  robot.
