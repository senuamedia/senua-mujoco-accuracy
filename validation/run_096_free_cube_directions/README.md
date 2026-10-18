# Run 096: issue 1's free cube, its friction's directions, and the cycle it creeps in

17 October 2026. Not registered: a design probe on the first cloud machine, in two steps, each pushed before its plays:
[`probe.sh`](probe.sh) (played at 09:00 UTC) and [`probe_2.sh`](probe_2.sh), written after step 1's readings (09:03
UTC). It finds where to look and decides nothing. Its readings, plays, traces and solver statistics are kept.

## Why

Issue 1's one open case: Study 20's free cube b (0.819 kg, half-size 0.0316 m, friction 0.734, condim 3), pushed
square to a face at 0.95 of its friction limit at 1.277 ms, creeps in Senua AI's set. Run 089's trace found its two
back contacts at their friction limit and the two front ones with room, so a sharing that holds exists, and gave each
contact's friction as a size only: friction pushing sideways in pairs that cancel would never show as slip and would
use up the back contacts' room.

## What was played

- **The rig**: the contact rig's trace gains `tracedir=1`: each contact's entry also gives the friction on the cube in
  the ground plane, along and across the push (mN), and the velocity of the cube's material point at the contact,
  along and across (um/s, the slip; the ground is still), read in the state the step ended in. The rig before
  ([`mjc_contact_before.c`](mjc_contact_before.c)) and the rig now, the trace set and `tracedir` unset, make the same
  bytes (play, trace, statistics); with `tracedir=1` the play and statistics are the same bytes as without it
  ([`identity.txt`](identity.txt)).
- **Step 1**: the cube, free, pushed at 0.95, 0.75 and 0.5 of its limit along 0 degrees, under the configuration (the
  elliptic cone, 100 noslip iterations), in Study 21's build of the set (its five switches set) and in Google DeepMind's
  Linux release of MuJoCo 3.16.0 ([`reading.txt`](reading.txt), [`p/`](p/)).
- **Step 2**: the same cube at 0.95 and 0.75, in the set and released, under the elliptic cone with no noslip, and under
  the configuration at a quarter of the step, 0.31925 ms ([`reading_2.txt`](reading_2.txt), [`p2/`](p2/)).

Read by Senua AI's corrected measure, `creep`; the trace's columns are given in [`reading.txt`](reading.txt). The
steps quoted below are read from the traces as written.

## What it found

| Creep, um/s | 0.95 of the limit | 0.75 | 0.5 |
|---|---|---|---|
| Senua AI's set, the configuration | 1,098 | 0 | 0 |
| Senua AI's set, no noslip | 2,928 | 1,937 | |
| Senua AI's set, the configuration, a quarter of the step | 482 | 0 | |
| The release, the configuration | 2,368 | 601 | 0 |
| The release, no noslip | 4,076 | 1,938 | |
| The release, the configuration, a quarter of the step | 2,087 | 391 | |

**The friction points along the push.** At every contact, in the steps read (898, 1,198 and 1,251), the friction across the push is at most
33 mN, against 436 to 2,395 mN along it: no pairs that cancel. All four contacts slip at the same speed, to within
7 um/s: the cube moves as one body, without turning (its yaw at most 18 urad over the play, the rig's count).

**The creep is a cycle, not a steady slide.** In the set at 0.95 the cube rocks forward on its front edge, once each
300 steps (0.383 s). Its tilt swings from 3.28 to 3.84 mrad. Near the top of a swing the back corners lift off: 30 of
1,253 steps have fewer than 4 contacts (the rig's count), and on some the front edge alone carries the cube (step 355:
2 contacts, both at the front). In each swing the four contacts slip together in a pulse: at the steps read, from 27
um/s to 2,046 um/s (2,713 in the first). From the second cycle on, the readings repeat each cycle to within 1 in the
last figure printed. At the steps read the back contacts sit at their friction limit, the front ones at 0.92 to 0.96
of theirs. At 0.75 there is no cycle: the tilt stays at 3.26 mrad,
the slip at 0 or 1 um/s.

- **In the set, the cycle comes with noslip.** Without noslip the set's cube does not rock. It slides steadily at
  2,928 um/s, the soft friction's own creep, its tilt constant at 2.30 mrad, four contacts on every step.
- **At a quarter of the step the cycle remains**, less regular, and the creep falls from 1,098 to 482 um/s; 821 of
  5,012 steps have fewer than 4 contacts.
- **The release rocks with and without noslip.** With the configuration at 0.95 its cycle is 480 steps, with slip
  building to 5,570 um/s, and at its top both back corners lift (the cube on its front edge alone, 2 contacts). At 0.75
  its swings grow through the play. Without noslip, at 0.95, it rocks on the same 480 steps, its tilt swinging 1.82 to
  2.41 mrad.

## What it means

- Run 089's open question is answered: the friction is not shared sideways. The cube is rocking. Each forward swing
  unloads the back contacts and lifts one off; with the back contacts at their friction limit, each swing slips.
- In Senua AI's set this is noslip's documented multi-contact instability (MuJoCo's computation chapter: "it is an
  ad-hoc correction that can occasionally cause instabilities in models with complex multi-contact interactions"), as
  in run 093's offset stacks: without noslip the set's cube and stacks are steady, and with it they rock and turn. It
  is counted under issue 14, so it is counted once.
- Issue 1's open case therefore has the same cause as issue 9's turning stacks. Noslip re-solves the friction with the
  normal forces held as the main solver left them, and the cube's balance in pitch depends on both. That fits a cycle
  driven by the one-step lag between them. It is a hypothesis, not measured here. A design that re-solves the normal
  forces with the friction is the next thing to try.
