# Run 094: noslip's costs, a joint equality with joint friction, and inverse dynamics

17 October 2026. Not registered: a design probe on the first cloud machine, on Google DeepMind's Linux release of
MuJoCo 3.16.0, in two steps, each pushed before its plays: [`probe.sh`](probe.sh) (played at 08:22 UTC) and
[`probe_2.sh`](probe_2.sh), written after step 1's readings (played at 08:25 UTC). It finds where to look and decides nothing. Its readings,
scenes, plays and solver statistics are kept.

## Why

Issue 14 (M3) lists costs of noslip, the setting Senua AI's configuration recommends, that this record had cited but
not measured. MuJoCo's documentation says noslip "makes inverse dynamics ill-defined" (its modeling chapter, on
preventing slip), and MuJoCo's issue [#2430](https://github.com/google-deepmind/mujoco/issues/2430) reports a joint
equality broken under noslip when a joint it couples has joint friction (frictionloss).

## What was played

- **The rig**: the contact rig gains the setting `fwdinv=1`, MuJoCo's own fwdinv flag, which each step compares the
  forward dynamics with inverse dynamics (`mj_compareFwdInv`); its STATS line then adds the largest of the two
  comparisons over the play. With it unset, the rig before ([`mjc_contact_before.c`](mjc_contact_before.c)) and the rig
  now make the same bytes, plays and statistics, on a hold and a slide ([`identity.txt`](identity.txt)).
- **Step 1**: two bodies of 1 kg that touch nothing: A falls on a vertical slide joint, B on a horizontal slide joint
  with joint friction F, coupled by a joint equality that B moves as A does. F of 0.5, 2, 5, 9 and 20 N, played 1 s at
  2 ms, with noslip off, 5 and 100 iterations ([`reading_equality.txt`](reading_equality.txt)).
- **Step 2**: the force on the joint with the friction, as #2430's second model: B falls on a vertical slide joint
  with joint friction twice its weight, so the friction holds it; A, 1 kg, on a horizontal slide joint with no
  friction, coupled by the equality that A moves as B does. With the friction holding and the equality kept, neither
  moves. B of 10, 100 and 1,000 kg, played 1 s at 1 ms under the implicit integrator, as #2430's models, with noslip
  off, 1 and 5 iterations ([`reading_equality_2.txt`](reading_equality_2.txt)).
- **Inverse dynamics**: MuJoCo's comparison on the cube Study 19 held (1.561 kg, half-size 0.0489 m, friction 0.438),
  held from turning and pushed at 0.5 and 0.95 of its friction limit, and slid at 1 m/s, at 1.71 ms, under MuJoCo's
  defaults, under the elliptic cone, and under Senua AI's configuration (the elliptic cone, 100 noslip iterations)
  ([`reading_fwdinv.txt`](reading_fwdinv.txt)).

Read by Senua AI's corrected measure: `final` on each body's motion, `gap` between the two bodies, `creep` on the cube.

## What it found

**A joint equality with joint friction: #2430 reproduced.** Where the friction holds (step 2):

| B | Noslip | B moved | A moved | Largest difference |
|---|---|---|---|---|
| 10, 100, 1,000 kg | off | 10.24 mm | 10.24 mm | 7 to 8 um |
| 10, 100, 1,000 kg | 1 or 5 iterations | 0 | 0.387 mm | 386 um |

- Without noslip the friction does not hold: B creeps at 10.344 mm/s at every mass, the soft friction's own creep,
  and the equality holds to 8 um.
- With noslip the friction holds B exactly, and A, coupled to it, moves 0.387 mm within the first quarter second and stays
  there (386,636 nm by 0.25 s, 386,666 from 0.5 s on): the equality is broken by an offset that does not close, at every mass, with 1 or 5 iterations.
- Step 1's 20 N plays, where the friction is above A's weight, show the same: without noslip both creep at
  10.344 mm/s, 0.56 mm apart; with noslip B stays still and A moves 0.80 mm and stops. Where the friction slips (0.5 to
  9 N) noslip changes little: the largest difference is 381 to 566 um either way, the soft equality lagging the fall.
  Step 2's header says step 1 found the equality kept as well with noslip as without; that holds only where the
  friction slips.

**Inverse dynamics: without noslip MuJoCo's forward and inverse dynamics agree; with noslip they differ by the whole
force the friction holds.** The largest difference over the play in the constraint forces, in joint coordinates:

| | Held, 0.5 of its limit | Held, 0.95 | Slid at 1 m/s |
|---|---|---|---|
| MuJoCo's defaults | 3.3e-13 | 3.3e-13 | 1.2e-12 |
| The elliptic cone | 3.9e-14 | 3.9e-14 | 4.2e-13 |
| Senua AI's configuration | 3.35022 | 6.36541 | 6.29603 |

- The cube's friction limit is 0.438 x 1.561 x 9.8 = 6.70044 N, so the pushes are 3.35022 and 6.36542 N: with noslip
  the difference is the push the friction holds, to the six figures printed. The comparison of the applied forces is
  the same with noslip; without it, 4.7e-8 N, and 0.0063 N held at 0.5 under MuJoCo's defaults.
- Without noslip the held cube creeps (675 and 2,498 um/s under the defaults, 559 and 1,062 under the elliptic cone);
  with it, 0.
- This is the cost the documentation names, and it is in the nature of holding friction exactly, not of noslip's
  code. MuJoCo's computation chapter says why its inverse dynamics needs the soft contact: "With hard contacts this
  computation is impossible. Consider pushing against a wall without moving." A cube friction holds exactly is still
  under every push below its limit, so its motion does not give the force.

## What it means

- Both costs are measured, and both follow from what noslip is: a pass after the main solver that re-solves the
  friction rows only (the joint friction and the contact friction, `engine_solver.c`), keeping every other force, the
  equality's among them, as the main solver left it.
- The broken equality comes from that order: the main solver lets B creep and moves A with it; noslip then stops B and
  leaves A's equality force as it was. A fix is a design question: re-solve the equality rows in the same pass.
- Inverse dynamics under noslip has no fix inside noslip: it is a limit of holding friction exactly. With noslip, the
  force must be read from the forward step (`efc_force`, `qfrc_constraint`), not from inverse dynamics.
- Senua AI's set has joint friction (Study 15's arm) and no joint equality, so the broken equality does not arise in
  its plays; inverse dynamics is not part of it.
