# Run 049: the de Saxce patch's fourth version (a probe)

16 October 2026 (07:33 to 07:44 UTC, step 2 at 07:50). Not registered: a design probe on the first cloud machine, by
[`probe.sh`](probe.sh) and [`probe_2.sh`](probe_2.sh), each pushed before its plays. It finds where to look and decides
nothing.

The fourth version, [`patches/in_design/desaxce_elliptic_v4.diff`](../../patches/in_design/desaxce_elliptic_v4.diff)
(sha256 00cb8f8eb4a07535..., switch `MUJOCO_DESAXCE=1`), changes `engine_forward.c` only, 103 lines added and none
removed. After MuJoCo's solve it lowers each elliptic contact's normal reference by friction times its slip, and solves
again from that solution until no shift moves by more than the solver's own tolerance (at most `opt.iterations`
passes). The slip is the part of the contact's tangential residual that the soft friction's own regularisation does
not account for, `jar + R f`: zero for a contact whose force is inside the cone (where `f = -jar / R`), growing
continuously as it slides. It replaces the third version's rule (shift only a contact in the primal cost's middle
zone), whose shift jumped at the line between sticking and sliding and made the fixed point cycle in run 048. Islands
are solved as MuJoCo solves them, and the dual solver's result is read after `mj_dualFinish`.

Arms: **rel**, MuJoCo 3.16.0 as released; **off** and **on**, the fourth version with its switch unset and set. Under
Senua AI's configuration (the elliptic cone with 10 noslip iterations), on Study 10's numbers (run 042's
`parameters.txt`): run 046's plays, both of the first deep dive's contact suites, stacks of 5 and 9 and an offset stack
of 3, slides on the ground and on a box face, the arm on contact and held by every constraint, written three ways, at
1.14 and 0.285 ms; and MuJoCo's own test suite on the fourth version, the switch unset and set
([`measured.txt`](measured.txt), `suite_changed.txt`, `differ_rel_on.txt`).

## Safe when off

All 309 files byte for byte as released; MuJoCo's suite, 3,492 tests, all passed.

## The lift and the direction

| | Released | Switch set |
|---|---|---|
| Run 016's sliding cube, highest above the ground at 10, 2.5, 0.625 ms | 10,570, 1,176, 148 um | **0, 0, 0** |
| Study 10's free cube, slid along 0, 11.25, 22.5, 33.75, 45 degrees, 1.14 ms | 133,042 to 136,043 um | **133,036 along every one** |
| The same at 0.285 ms (Coulomb's distance 133,451) | 133,491 to 135,734 um | **133,478 along every one** |
| Side drift; steps on fewer than four corners | up to 231 um; 68 to 707 | **0; 0** |

The elliptic cone alone reads the same: 133,041 um along every direction at 1.14 ms, 133,483 at 0.285.

**The slides are now the integrator's own exact answer.** With Coulomb friction and nothing else, MuJoCo's semi-implicit
step stops a body slid at v0 with deceleration a after a distance of dt times the sum of its velocities after each
step: 177,720 um for run 016's cube at 10 ms (v0 1.2 m/s, a 3.92 m/s2). Released, it slides 177,979; with the switch
set, 177,745. The shortfall from Coulomb's continuous distance (183,673) at coarse steps is the step itself, finding F5.

## Nothing held lets go

**Every hold creeps 0 um/s and every grip 0 or 1 um/s at both steps, and with the switch set every hold and grip file is
byte-identical to the release's** (`differ_rel_on.txt` lists none of them): a contact that sticks has no slip and no
shift. The ten known-answer tests: 10 of 10. The offset stack of 3 and the stacks at 1.14 ms end where they end released
released (heights to the 0.1 um, tilts to the urad, at rest); the stack of 9 at 1.14 ms jolts once in mid-play, released and with the switch set alike (its middle cube rises 7 um at 0.8 s released, 31.5 um at 1.61 s with the switch set). The arm held by every constraint and the arm in its first pose play byte for byte as released. The arm in its second pose, set down
and dropped, reads within 1 um/s of its released creep (-8 against -9 at rest) and 0.1 mrad of its released end, and
its writings end as far apart as released (21.0 to 21.6 and 7.0 to 7.3 um; finding F10, which this build does not patch).

## The stacks at the fine step: a departure of the release's, and what the patch does to it

**Released, under the configuration at 0.285 ms, straight stacks do not stand.** The stack of 5 tilts up to 2.3 mrad
and its top cube is still moving at 2.1 mm/s after 2 s; the stack of 9 tilts up to 2.5 mrad, its cubes moving at up to
5.8 mm/s. At 1.14 ms both stand, untilted and still. (The rig's `_tilt` files and the cubes' speed column, read here.)
**With the switch set, the stack of 5 at 0.285 ms stands**, untilted and still, its cubes at the same heights to the
0.1 um as at 1.14 ms. **The stack of 9 at 0.285 ms still does not**: it tilts up to 3.2 mrad and moves at up to 3.1
mm/s. This is new to the record and is open.

## The cost

The most iterations on any step: 21, against 12 released; never at the iteration limit, no warning. The free cube's
slides take 16 or 17.

## MuJoCo's own tests

**Two of MuJoCo's 3,492 tests read differently with the switch set** (`suite_changed.txt`), down from seven in run 047
and four in run 048:

- `SolverTest.ZeroToleranceDisablesTermination` pins one solve's iteration count to its limit (3). With a zero
  tolerance the fixed point also runs every pass, and the passes' iterations are counted (12). By design: the count
  includes the work the patch does.
- `ForwardTest.DiscreteImplicitRowNoslip` checks that a box slid at 2 m/s under the discrete integrator, with
  torsional and rolling friction (condim 6) and 2 noslip iterations, moves at under 5 mm/s after 200 steps. **Step 2
  played the test's own scene** ([`step2/`](step2/), the scene taken from MuJoCo's test file with only a body name
  added): **released, the box never comes to rest.** From step 31 it repeats a six-step cycle of speeds along the slide
  (564, 54, 58,832, -76,978, 13,651 and 3,830 um/s), faster than 1 mm/s on 106 of the last 160 steps; the test passes
  because its last step falls on the 54 um/s step. With the switch set the cycle is the same, two steps later in phase,
  and the last step falls on 3,854 um/s. With condim 3 or without noslip the box comes fully to rest, released and with
  the switch set. Under MuJoCo's default integrator the scene (its contact time constant an eighth of the step, MuJoCo's
  stiffness guard disabled) flies apart, released and patched alike. The test's slide also shows the step's exact
  answer: the semi-implicit step stops the box at 188,110 um; released 195,002, with the switch set 188,159.

The scene rig gains `key=N` (start from keyframe N), unchanged without it: run 043's two demo scenes, played with the
rig as it was and as it is, byte-identical (`step2/identity.txt`).

## What it shows

- **The fourth version removes the lift and the direction, leaves every hold and grip byte for byte as released, converges everywhere played, and
  changes two of MuJoCo's tests**: one by counting its own iterations, one whose released scene never comes to rest.
- **Two departures of the release are new to the record**: under the discrete integrator with condim 6 and noslip, a
  box that should rest cycles at up to 77 mm/s; under the configuration at 0.285 ms, straight stacks of 5 and 9 tilt and
  keep moving. The patch stands the stack of 5, not the stack of 9.
- **Not yet asked:** fresh numbers (a registered study decides), the pyramidal cone, inverse dynamics (`mj_inverse`
  does not apply the shift), the bounce.
