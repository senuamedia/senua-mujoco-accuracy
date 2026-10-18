# Run 010: small rotations through MuJoCo's quaternion functions

15 October 2026. Not registered: a design probe on run 002's Linux machine, by [`probe.sh`](probe.sh); reading
`reading.txt`. The first deep dive found that SuperDex replaced the axis of any rotation smaller than about 2e-9 rad
with x, which stalled its solver near rest (its Study 9; patch E). MuJoCo's own `mju_normalize3` replaces an axis
shorter than `mjMINVAL`, 1e-15, with x, and `mju_quat2Vel` uses it to turn a quaternion into a rotation vector. The new
rig [`tools/mjc_rotvec.c`](../../tools/mjc_rotvec.c) is the first deep dive's `sdx_rotvec` case for case: a rotation
built with `mju_axisAngle2Quat` and read back with `mju_quat2Vel`, written in the same format and read by the same
measure, `sx_contact rotvec`, with Study 9's bound of 1 ppm. MuJoCo 3.16.0, 64-bit.

## The result

| Rotations | Cases | Exact to 1 ppm |
|---|---|---|
| Study 9's 40 registered rotations (five axes, the last x; angles from 8e-4 to 2e-14 rad) | 40 | **40**, every one read back exactly (0 ppm) |
| The same five axes at 1e-14, 4e-15, 2.5e-15 and 2e-15 rad | 20 | 20 |
| The same five axes at 1.5e-15, 1e-15, 5e-16, 1e-16 and 1e-18 rad | 25 | 5 (the x axis); on the other four axes the vector read back points along x |

## What it shows

- **Every rotation the first deep dive registered is exact in MuJoCo**, including the 20 at or under 2e-9 rad that
  SuperDex as shipped got wrong.
- **MuJoCo has the same mechanism, a million times further down.** Below an angle of 2e-15 rad (where half the
  angle's sine falls under 1e-15) the axis read back is x, as its source says. At that size the quaternion's vector
  part is about 1e-15 against a scalar part of 1, close to what a 64-bit number near 1 can still tell apart. MuJoCo
  calls `mju_quat2Vel` where an orientation difference becomes a velocity (`mju_subQuat`, used for finite differences
  and inverse dynamics) and for a ball joint's limit, not in its forward step, which integrates with
  `mju_quatIntegrate`: there an axis that small would be replaced too, but it would turn the body by under 2e-15 rad.
  Nothing here asks for a correction.
