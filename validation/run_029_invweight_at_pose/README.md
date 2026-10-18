# Run 029: the inverse weight in the current pose, a patch in design

15 October 2026. Not registered: a patch in design, held to the five checks and MuJoCo's own test suite, every check
stated in [`play.sh`](play.sh) before any play. Played on the cloud machine (2 virtual CPUs).

**The result: 49 of the 50 check lines held, and the one that failed did so by the measure's rounding.** With the switch
set, the same arm ends in the same place whatever pose its file was written in (within 2 nm, where the release is 1.2 to
107 um apart), every cube scene and both suites play byte for byte as released, and MuJoCo's whole suite gives the same
results with the switch set and unset. The creep check failed on one line of four: one writing crept at 851 um/s against
852, where the check's "1 part in 1,000" of 852 rounds to 0 in the measure's whole-number arithmetic.

## The patch

[`patches/in_design/invweight_at_pose.diff`](../../patches/in_design/invweight_at_pose.diff) (sha256 3f471edca6159277...),
45 lines added to `src/engine/engine_core_constraint.c`, none removed; switch `MUJOCO_INVWEIGHT_AT_POSE=1`, read once.
With it set, `mj_diagApprox` takes each contact body's translational and rotational inverse weight in the pose the body
is in, by the formula `mj_setConst` uses for `body_invweight0` at `qpos0` (the average diagonal of J inv(M) J' at the
body's centre of mass, or 1/mass for a body that only slides). Everything else is as released: one regularisation for
a pyramid's four edges (MuJoCo's `diagexact` gives each its own, and turns symmetric scenes, run 028), and joint limits
and equality constraints keep their weights from `qpos0`. Of the three sources of error MuJoCo's documentation names, it
answers the first, the pose. Both builds compiled with no warning from the patched file (`patch_warnings.txt`, empty);
step 0, `patch_check.txt`: the source is the release's at the pinned commit with the patch applied.

## The five checks (`checks.txt`, every line a `sx_contact rule`)

Three arms (release, the patched build with the switch unset, set), each playing both contact suites, run 025's arm
under MuJoCo's defaults and with the elliptic cone and noslip, run 026's stacks and slides and run 027's grips.

| Check | Result |
|---|---|
| 1 Required | **Held.** Released, the arm written straight ends 13 to 65 um from the arm written in its own pose, in every pose, scene and step |
| 2 Correct, the place and the speed | **Held**, 32 of 32 lines. On, the straight and folded writings end within 2 nm and 1 um/s of the native, in every pose, scene and step |
| 2 Correct, the creep | **Failed on one line of four.** On: 852, 852 and 851 um/s in pose A at 2 ms (native, straight, folded), 852 at 0.5 ms, 607 and 606 in pose B. The check asked 1 part in 1,000 of the native's creep; the measure takes that as the whole number 852 / 1,000 = 0, so it asked for the same whole number, and the folded writing differed by 1 um/s, the measure's resolution |
| 3 Nothing else gets worse | **Held.** On: 171 of 171 files of both suites, the stacks, the slides and the grips byte-identical to the release; MuJoCo's suite, switch set against unset: no test changes |
| 4 Safe when off | **Held.** Off: 220 of 220 files byte-identical to the release; MuJoCo's suite test for test as the release |
| 5 The solver keeps converging | **Held.** On: no step at the iteration limit, no warning (at most 6 iterations a step) |

The folded writing of pose A set down touching the ground is the one run 028 found starting with the ball a hair
above the ground, by rounding: it has no contact on the first step and sinks 41 um on it. That start is the 2 nm and the
1 um/s. MuJoCo's suite on this machine: `XMLReaderTest.LargeTextureAddressTest` is killed by the kernel for memory in all
three arms (as in run 024), so every comparison sets like against like.

## What the readings show

- **The written pose no longer matters.** Under MuJoCo's defaults and under the elliptic cone with noslip, every
  writing of the arm ends within 2 nm and 1 um/s of every other (`checks.txt`; the elliptic lines are reported there).
- **The creep is the same in every writing**, and it is now the creep of the pose the arm is in. In pose A the arm
  stays where it was set, so its creep is the release's native writing's (852 um/s). In pose B the arm swings and
  settles in its first 0.3 s (the ball moves at up to 0.3 m/s, the files' early lines), so the weight taken where it is
  differs from the one frozen at its start, and it creeps at 607 um/s in every writing, against the release's 376 to 513.
- **Nothing else moves.** A free cube's or a sliding cube's translational weight does not depend on its pose, and every
  cube scene, both suites and every one of MuJoCo's 3,492 tests are as released with the switch set.

## Next

The patch is not registered by this run. Its one failed line is the check's arithmetic on a writing that starts by
rounding off the ground; a registered study would set the creep's bound at the measure's resolution and start every
writing clearly above the ground, before any of its data exists.
