# Run 007: the two-link chain under MuJoCo's four integrators

15 October 2026. Not registered: a design probe on run 002's Linux machine, by [`probe.sh`](probe.sh); reading
`reading.txt`. MuJoCo 3.16.0 as shipped. The new rig [`tools/mjc_chain.c`](../../tools/mjc_chain.c) is the first deep
dive's `sdx_chain` scene and format (two cube arms on two hinges, no contact; written for the state each step ended
in), read by the same measure, `sx_contact chain`. The scenes are the first deep dive's: Study 12's free chain (arms
of 1.2 and 0.6 kg, no gravity, set turning at 2.5 and 1.5 rad/s) and Study 15's swinging chain (gravity, released at
rest from 0.4 and -0.7 rad), each for 2 s at its steps, 10 ms over 1, 4, 16 and 64. MuJoCo raised no warning.

## The free chain: nothing acts on it, so its energy and its angular momentum must stay as they were

| Integrator | 10 ms | 2.5 ms | 0.625 ms | 0.156 ms |
|---|---|---|---|---|
| Euler (MuJoCo's default) and implicitfast: kinetic energy after 2 s | **+9.72%** | +2.48% | +0.61% | +0.15% |
| The same: angular momentum | **+6.60%** | +1.81% | +0.45% | +0.11% |
| implicit: kinetic energy | **-7.63%** | -2.13% | -0.55% | -0.14% |
| implicit: angular momentum | **-6.42%** | -1.57% | -0.39% | -0.10% |
| RK4: kinetic energy | -0.0001% | 0 | 0 | 0 |
| RK4: angular momentum | 0 (1 ppm at most along the way) | 0 | 0 | 0 |

For comparison, SuperDex at 10 ms as shipped kept 70.0% of the energy and 88.4% of the momentum, and 100.02% and
99.9994% with patch G and its Newton-Euler inertia (the first deep dive's Study 12).

## The swinging chain: gravity only, so its total energy must stay as it was

The largest departure of the total energy over the 2 s, as a share of the largest kinetic energy:

| Integrator | 10 ms | 2.5 ms | 0.625 ms | 0.156 ms |
|---|---|---|---|---|
| Euler and implicitfast | 12.2% | 17.0% | 6.2% | 1.7% |
| implicit | **blows up** | 13.6% | 3.3% | 1.8% |
| RK4 | 1.1% | 0.0012% | 0.0001% | 0.0001% |

Under the implicit integrator at 10 ms the joints reach 72 and 241 rad/s, against 15 and 51 rad/s under RK4 for the
same release (the largest joint speeds in the rig's files), and the kinetic energy reaches about 1,121 J against a
total of about 9 J. The measure's own figure for that play's largest departure is not a number to read: it overflowed.

## What the probe shows

- **MuJoCo's default integrator adds energy and momentum to a free chain.** With nothing acting on it, a two-link
  chain gains 9.7% of its kinetic energy and 6.6% of its angular momentum in 2 s at 10 ms, and 2.5% and 1.8% at
  2.5 ms, close to MuJoCo's default 2 ms. Both fall in proportion to the step: a first-order error, not noise. The
  implicitfast integrator is byte-identical to Euler here, as its documentation implies when nothing depends on
  velocity.
- **The implicit integrator loses them at the same rate, and on the swinging chain at 10 ms it is unstable.**
- **RK4 keeps a free chain's energy and momentum to the part per million at every step**, and the swinging chain's
  energy to 1.1% at 10 ms and 0.001% below it.
- A free joint (run 001) keeps its speed exactly under Euler; a chain of two does not. What differs is the chain's
  coupling: its inertia changes with its shape, which a single joint's does not, so velocity-dependent forces appear
  that a single joint never has. Which part of the step carries the error is for a study to find.

Next: the same at MuJoCo's own default step of 2 ms; the swinging chain with damping; the cube pair.
