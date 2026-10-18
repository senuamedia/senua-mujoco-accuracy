# How the Senua AI Robotics Core works on MuJoCo

The Senua AI Robotics Core has four parts. World is the simulator. Body is the real-time layer that runs on the robot.
Mind perceives and decides. Measure is an instrument that reads two sources of the same motion and reports whether they
differ, where, and by how much. A deep dive uses Measure, which has two halves: the **known-answer harness**, which
holds a physics engine to the answers physics gives on the smallest scenes that have one, and the **gap instrument**,
which reads two recordings of the same motion where there is no textbook answer. This deep dive so far uses the
known-answer harness.

## What is Senua AI's here, and what is MuJoCo's

| Part | Whose | What it does |
|---|---|---|
| MuJoCo 3.16.0 | Google DeepMind's, unchanged | The engine under test: Google DeepMind's prebuilt releases for macOS and Linux, and a build from its source at the pinned commit for the patch |
| The rigs (`tools/mjc_*.c`) | Written for this record | Thin adapters on MuJoCo's own C API. Each builds one scene, plays it and writes what every body did at every step, in the same plain text format the first deep dive's rigs write. A rig measures nothing |
| The measuring programs | **Senua AI Robotics Core** | Read a rig's file and hold the motion to its right answer: a bounce, a slide that ends, a hold, an impact, a chain's energy and momentum, a tumbling body's energy and angular momentum, a rotation. The same program measured SuperDex; one reading, `hover`, was added for this record and no other changed, and one new measure, `sx_tumble`, reads the tumbling body ([`measure/`](../measure/README.md)). Every reading is the program's, run 008's lift table included (`hover`) |
| The rules and the verdicts | **Senua AI Robotics Core** | A study's rules are judged by the measuring programs' `rule` command, from the measured numbers, and nowhere else |
| The suites | The first deep dive's | Ten known-answer contact tests and a second suite of two moving bodies, played here with the same scenes, steps and file names, and read by the first deep dive's own runner |
| The patches (`patches/`) | **Senua AI**, changes to MuJoCo's source | Each off unless its switch is set; with it unset, MuJoCo plays byte for byte as released |

## Measurement

Each finding starts on the smallest scene that has an answer that does not depend on the time step, an answer from
textbook physics ([the references](references.md)): Coulomb's law of friction ([Coulomb 1785](references.md#coulomb),
[Popov 2010](references.md#popov)), Newton's laws and the conservation of momentum, energy and angular momentum, with
Euler's equations for a rotating body ([Landau and Lifshitz](references.md#landau)), and the coefficient of
restitution ([Stronge 2018](references.md#stronge)):

- **One cube on the ground**: a drop (the bounce must not depend on the step), a set-down (the ground carries the
  weight), a hold below the friction limit (it must not move), a push above it (it accelerates at the push less
  friction, over the mass), a slide that ends (Coulomb's distance, along any direction), an oblique landing
  (Coulomb's friction over the impact).
- **Two cubes**: one carried on another, one slipping on another, one striking another's side (their momentum is
  kept).
- **One arm on a joint and a chain of two**: a free spin keeps its speed, a torque gives torque over inertia, a
  pendulum keeps its swing, a free chain keeps its energy and momentum, a limit pushes and never pulls.
- **One arm written several ways**: a two-link arm whose tip ball rests on the ground, in the same place, written in
  different poses, must do the same thing whatever pose its file was written in.
- **One body tumbling**: a free body with three different moments of inertia, spinning about a general axis with
  nothing acting on it, keeps its rotational energy and the magnitude of its angular momentum (Euler's equations,
  [Landau and Lifshitz](references.md#landau)).
- **A small rotation**: a quaternion read back as the rotation it was built from, down to 1e-18 rad.

Scenes are played at several steps, from MuJoCo's default 2 ms (or 10 ms, the first deep dive's step) down to as little as
1/64 of it, because an error that changes with the step comes from how the engine steps, and one that does not comes
from the physics it computes. The whole record has been played twice and gives the same bytes ([the audit](audit.md)),
and run 002 played run 001 again on a second machine and operating system, byte for byte.

## Validation

A finding becomes a claim only through a pre-registered study ([`preregistrations/`](../preregistrations/)):

1. The question, the arms, the scenes and every rule with its bound are written and pushed before any play exists.
   The scenes use numbers the design probes did not use.
2. The study is played once, by a runner pushed with the registration.
3. Every rule is judged by the measuring programs' `rule` command from the measured numbers. A rule that fails is
   reported as failed, and the claim it carried is withdrawn.

A correction is held to five checks: **required** (MuJoCo as released fails a test with a known answer), **correct**
(with the correction on, it passes), **nothing else gets worse** (every other test reads as before), **safe when off**
(with the correction's switch unset, MuJoCo's output is byte-identical to the release) and **the solver keeps
converging** (no step at the iteration limit, no warning). The rigs count a step at the limit when MuJoCo's own count of
its iterations (`solver_niter`), which with noslip adds noslip's to the main solver's, reaches the main solver's limit;
so a count of 0 means neither solver reached it, and a count above 0 with noslip on does not by itself say which did.

## Patching

A patch is a change to MuJoCo's own source, behind an environment variable. MuJoCo built from source unchanged plays
byte for byte as Google DeepMind's release ([run 004](../validation/run_004_source_build/README.md)), so every patched
build is checked against the release itself. [The patches](patches.md) and their evidence are published together.

## What the deep dive does not claim

Nothing here is measured against a real robot. A known-answer test shows where an engine departs from physics; how
much a robot's behaviour depends on it is a separate measurement, made by reading a recorded machine against its
simulation, which is where this work goes next.
