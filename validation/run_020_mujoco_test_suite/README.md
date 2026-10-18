# Run 020: MuJoCo's own test suite, with and without the slip-aligned pyramid

15 October 2026. The check a MuJoCo maintainer would run before merging the validated patch
([`patches/slip_aligned_pyramid.diff`](../../patches/slip_aligned_pyramid.diff), Study 1): MuJoCo's own googletest
suite, built by its own build files from its source at the commit in `UPSTREAM_COMMIT`, run on the cloud machine by
[`play.sh`](play.sh).

**The result: with the switch unset, the patched MuJoCo passes MuJoCo's own suite exactly as the release does, test
for test. With it set, 6 of 3,492 tests fail. Two pin the contact frame the patch is meant to turn; four show side
effects Study 1 did not look for.** The patch stays validated for what Study 1 registered, and is not ready to merge
as it stands.

## How it was run

- **Step 0**: the patched source is the release source with exactly the patch applied (`patch_check.txt`: SAME).
  The first start compared the two trees with the in-tree build folders an earlier build had left, and listed their
  artefacts. It was stopped at step 256 of 462 of its first build, the machine moved from 2 to 16 virtual CPUs
  (c7i.4xlarge, within the quota, as approved), and `play.sh` was corrected and pushed before it was started again.
  [`patch_check.sh`](patch_check.sh) is that correction run on its own.
- **Two builds**, with tests on and examples, simulate and the Python test utility off, as in run 004: the release
  source (its last 146 steps, 90 s, after the stop), and the release source with the patch (121 s, from the start). No
  compiler warning comes from the patched file.
- **ctest ran every test three times**: on the release build; on the patched build with `MUJOCO_SLIP_ALIGNED_PYRAMID`
  unset; and with it set to 1. Each took 17 s. ctest's own reports are kept (`ctest_*.txt`; the JUnit files, which
  hold each failure's message, gzipped after the run as `junit_*.xml.gz`).
- **The comparison** ([`compare.sh`](compare.sh), `compare.txt`, `results_*.txt`) reads each test's number, name and
  result from ctest's report. `play.sh`'s first comparison took the JUnit names whole; MuJoCo's parameterised tests
  print memory addresses in their names, which change from run to run, so it listed tests that had not changed. The
  corrected comparison cuts the names before their parameters.

## The result

| Arm | Tests | Passed | Failed | Skipped |
|---|---|---|---|---|
| Release | 3,492 | 3,491 | 0 | 1 |
| Patched, switch unset | 3,492 | 3,491 | 0 | 1 |
| Patched, switch set | 3,492 | 3,485 | **6** | 1 |

The skipped test, `XMLWriterLocaleTest.IgnoresLocale`, is skipped by MuJoCo itself in all three: the machine lacks
the locale it needs. **With the switch unset every test gives the same result as on the release**, which is check 4,
safe when off, on MuJoCo's own suite.

## The six tests that change with the switch set

| Test | What it asserts | Why it changes | Expected? |
|---|---|---|---|
| `SensorTest.ContactVelocity` | A contact sensor's velocity, in the contact frame, is the one written in the test | The frame is turned along the slip: the two tangential components, -0.655 and -1.299, become 1.4548 along the first tangent and 0 along the second (1.4548 is their combined length) | **Yes**: it pins the frame the patch turns |
| `SensorTest.ContactStage` | A contact sensor computed at the position stage reports the collision's frame | The frame is turned along the slip computed from the joint velocities, so the reported tangent is (0.455, 0.890, 0), not (0, 1, 0) | **Yes, with a note**: the patch makes the contact frame, a position-stage output, depend on velocity |
| `InverseTest.DiscreteInverseFreeBody` | A box spinning at 20 rad/s on a plane is still in contact after 70 steps | With the switch set it has left the ground (no contact). Turning the pyramid along the slip makes the lift of a sliding contact (finding F3) as large in every direction as along an axis: Study 1's own kept slides, read with `hover`, rise 143 um at 1 ms along every direction played with the patch, against 62 to 91 um off axis on the release (22 against 16 to 18 um at 0.25 ms) | **No: a finding.** The patch raises the lift of off-axis slips to the release's largest |
| `SleepTest.SleepingUnaffectedByWaking` | From the same state, a forward pass with sleeping enabled and one with it disabled give the same positions, forces and sensors, to the bit | A contact sensor in the contact frame and a force sensor at a site (world frame) differ between the two passes | **No: a finding** (cause below) |
| `IpcTest.FoldDenseBlocksSolveMatches` | Two ways of solving the same step (with and without folded dense blocks) agree to the solver's tolerance after 10 steps | The accelerations differ by 0.086 against an allowed 1e-5, the positions by up to 4e-7 against 1e-8 | **No: a finding** (cause below) |
| `ForwardTest.DiscreteStiffLegPress` | A stiff leg pressed onto the floor under the discrete integrator converges at first order: halving the step cuts the error to under 0.7 of it | The finer step's error, 0.0099, is not under 0.7 of the coarser's, 0.0093 | **No: a finding** (cause below) |

**The likely cause of the last three, from the patch's code.** The patch turns a contact's frame along its slip
whenever the slip is longer than MuJoCo's smallest number (`mjMINVAL`, 1e-15 m/s). On a contact at rest the slip is
numerical noise, and the direction of noise is arbitrary: two computations that MuJoCo makes agree to the last bits
(sleeping and not, folded blocks and not), or a settled leg, can then turn the frame by a finite angle, and the
pyramid with it. The three tests fail exactly where results must agree to the bit or settle. This is the explanation
the code and these three failures support; no play of this record has shown a frame following noise.

**Corrected after run 021.** The second version turns a contact only when its slip is at least MuJoCo's own rest speed,
so it does not turn along noise. Under it the sleeping and folded-block tests pass, as the explanation predicts, but
the stiff leg press still fails. Noise explains the first two; the leg press's cause is open.

**A seventh issue, found by reading MuJoCo's source during this run.** MuJoCo 3.16.0 lets a surface move (`surfacevel`:
a conveyor belt, a turntable), and adds that velocity to each contact's velocity (`mj_addSurfaceVel`). The patch takes
the slip from the joint velocities alone, so on a moving surface it turns the pyramid along the body's motion, not its
slip against the surface. MuJoCo's surface-velocity tests (conveyor, turntable and four others) still pass with the
switch set, so no test here shows it; no play of this record has used a moving surface.

## What it means for the patch

The patch is safe when off on MuJoCo's own suite, test for test. With it on, it does what Study 1 validated: friction
the same in every direction. But a maintainer's suite finds what Study 1's rules did not ask:

1. **The lift.** Aligning the pyramid with the slip removes the direction from friction and from the lift alike, at the
   lift's largest. Any correction has to answer F3 too.
2. **Noise.** The frame should turn only along a slip the step can resolve, not along numerical noise. The criterion
   must come from MuJoCo's own solver state or the physics, not a fitted threshold.
3. **Moving surfaces.** The slip must include the surface's velocity, as MuJoCo's own contact velocity does.
4. **The frame as an output.** Turning `mjContact.frame` in place changes what contact sensors and users read, and
   makes a position-stage output depend on velocity. A turned copy used only for the friction rows would not.

These go to the patch's next version, which would be held to the five checks and a fresh registered study again, with
MuJoCo's own suite as part of check 3.
