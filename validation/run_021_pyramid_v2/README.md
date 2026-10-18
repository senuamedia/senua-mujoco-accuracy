# Run 021: the slip-aligned pyramid's second version, to the five checks and MuJoCo's own suite

15 October 2026. Not registered: a patch in design, held to the five checks and MuJoCo's own test suite before any
study registers its rules, by [`play.sh`](play.sh), which states every check before any play. Played on the cloud
machine (16 virtual CPUs).

**The result: the second version fails three checks as they were written, so no study is registered for it.** It
answers three of run 020's four side effects: the frame is the release's again, the two noise failures pass, and a
moving surface's velocity is in the slip. It does not answer the fourth (the lift), it still fails MuJoCo's stiff
leg-press test, and it adds a field MuJoCo's documentation test requires to be documented.

## The patch

[`patches/in_design/slip_aligned_pyramid_v2.diff`](../../patches/in_design/slip_aligned_pyramid_v2.diff) (sha256
cfdf5a60a3ca562b...), 93 lines added to four files of MuJoCo 3.16.0, none removed:

1. **The frame is left as released.** The pyramid's basis is turned only while its rows are built; the turn is kept in
   a new field, `mjContact.frictionrot` (cosine and sine); `mj_contactForce` turns the decoded forces back into the
   frame.
2. **The slip includes the surfaces' own velocity** (`surfacevel`), as `mj_addSurfaceVel` adds it to MuJoCo's contact
   velocity; `mj_addSurfaceVel` writes it into a turned pyramid's rows in the turned basis.
3. **A contact is turned only when its slip is at least `opt.sleep_tolerance`**: the speed below which MuJoCo treats a
   body as at rest (`treeCanSleep`, `engine_sleep.c`; 1e-3 by default, `engine_init.c` line 66). It is also turned only
   for isotropic sliding and rolling friction.
4. **The lift is measured, not tuned.**

Both builds compiled with no warning from the patched files (`progress.txt`). Step 0, `patch_check.txt`: the source
is the release's at the pinned commit with the patch applied.

## The five checks (`checks.txt`, every line a `sx_contact rule`)

| Check | Result |
|---|---|
| 1 Required | **Held.** The release slides 20% further along 22.5 degrees and 42% along 45; its belt plays stop 51 to 286 steps after their references |
| 2, C1 no direction | **Held.** 126,717 um along 0, 22.5 and 45 degrees at 2 ms; 127,655 at 0.125 ms |
| 2, C2 no drift | **Held.** 0 um |
| 2, C3 the holds the release loses | **Held.** At 0.72, 0.8 and 0.9 of the limit, along 22.5 and 45 degrees: 1,875, 2,263 and 2,748 um/s, as along 0 |
| 2, C4 the belt | **Failed as written.** Version 2's belt plays stop 1 to 6 steps before their still-floor references (223 against 225 at 2 ms, 45 degrees; 910 against 916 at 0.5 ms) |
| 2, C5 the frame | **Held.** MuJoCo's `ContactStage` and `ContactVelocity` tests pass: the frame and the velocity in it are the release's |
| 2, C6 the noise tests | **Two of three.** `SleepingUnaffectedByWaking` and `FoldDenseBlocksSolveMatches` pass; **`DiscreteStiffLegPress` still fails** |
| 3 Nothing else gets worse | **Held** on this record's plays: 75 of 75 suite and lift-slide files byte-identical to the release. MuJoCo's suite, switch set against unset: 2 tests change, examined below |
| 4 Safe when off | **Failed on MuJoCo's suite.** This record's plays are byte-identical to the release (108 of 108 files), but with the switch unset `doc_test` fails: the new `mjContact` field is not in `doc/includes/references.h`, the documentation's copy of the public headers, which the test requires to match |
| 5 The solver keeps converging | **Held.** No step at the iteration limit, no warning |

The rig is unchanged when `belt` is not given: the release arm's slides along x are byte-identical to run 016's.

## What failed, and what it shows

- **C4, the belt, measured MuJoCo's moving floor as well as the patch.** A diagnostic after the checks
  ([`diag_belt.sh`](diag_belt.sh), `diag_belt.txt`, pushed before its plays) played the same belt scenes under
  MuJoCo's own elliptic cone, which has no direction. Its belt plays also stop before their references: 223 against
  224, 909 against 916, 190 against 191, 780 against 783. Version 2's pyramid stops within one step of the elliptic
  cone's own belt plays (223, 910, 190, 781). So on a moving floor version 2 behaves as MuJoCo's isotropic cone does,
  where the release stops 30% late; but the check compared with a still floor, which MuJoCo does not treat as
  equivalent, and it failed as written. A registered study would compare with the elliptic cone on the same belt.
- **`DiscreteStiffLegPress` is not explained by noise.** Run 020 named numerical noise as the likely cause of three
  failures. Version 2 does not turn below MuJoCo's rest speed, and two of the three now pass. The leg press still fails
  under both versions, so its cause is open. Run 020's README is corrected to say so.
- **`doc_test`, with the switch unset**, is the cost of a new public field: a merge would add it to the documentation's
  copy of the headers in the same change. It is an omission of this version, not a change in what MuJoCo computes, but
  check 4 as written covers MuJoCo's whole suite, and it failed.

The two tests that change with the switch set:

| Test | What it asserts | Why it changes |
|---|---|---|
| `InverseTest.DiscreteInverseFreeBody` | A box spinning at 20 rad/s on a plane is still in contact after 70 steps | It leaves the ground: the lift (below) |
| `ForwardTest.DiscreteStiffLegPress` | Under the discrete integrator a stiff leg pressed onto the floor converges at first order | Open (above) |

Neither asserts the pyramid's friction rows or their forces directly, so neither is the kind of change check 3 allows.

## The lift, measured (4)

**Version 2 still raises the lift to the axis value in every direction.** Read with `sx_contact hover` from the
slides: 649 um at 2 ms along 0, 22.5 and 45 degrees, against the release's 649, 496 and 288; 15 um at 0.125 ms,
against 15, 9 and 9. Turning the pyramid along the slip removes the direction from the lift as from friction, at the
lift's largest. That is the cause of `DiscreteInverseFreeBody`, and it is F3's to answer, not a setting to tune here.

## Reported, not judged

- **The slow holds.** At 0.6 of the limit along 45 degrees the release creeps at 969 um/s, under MuJoCo's rest speed
  of 1 mm/s, so version 2 does not turn it and it stays at 969, against 1,293 along 0. Along 22.5 degrees, where the
  release creeps at 1,132, it is turned and creeps at 1,293. At 0.69 every direction creeps at 1,729. Below MuJoCo's
  rest speed the direction of the creep (finding F1) remains, by design.
- **A cube free to turn** slides 126,772, 126,906 and 127,130 um along 0, 22.5 and 45 degrees (within 0.28%), with
  188 um of drift along 22.5, as with the first version (run 011).

## Next

A third version would add the field to `doc/includes/references.h` and keep everything else. Before any study: find
the leg press's cause, and compare the belt with the elliptic cone on the same moving floor. The lift is F3's, and a
correction that keeps the pyramid aligned will keep it.

## Corrected 17 October 2026: the measure's step

Senua AI's `stop` and `accel` measures read the step in whole microseconds, and `stop` cut each step's distance
before adding it up ([the audit](../../docs/audit.md#the-measure-corrected-17-october-2026)). This run's outputs
stay as they were printed, and each one the correction changes has its corrected copy beside it,
`<name>_corrected.txt`. The numbers this page quotes that change:

| As printed | Corrected |
|---|---|
| 126,717 um | 126,732 um |
| 126,772 um | 126,791 um |
| 126,906 um | 126,926 um |
| 127,130 um | 127,146 um |
| 127,655 um | 127,681 um |

What this page concludes does not change: the largest of these corrections is 0.02%.
