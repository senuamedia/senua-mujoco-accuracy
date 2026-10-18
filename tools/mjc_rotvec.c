// mjc_rotvec.c: the rotation vector of a small rotation, through MuJoCo's own quaternion functions, matching the first
// deep dive's sdx_rotvec rig case for case and column for column, so the same measuring program reads it. A rotation by
// an angle a about a unit axis n has the rotation vector a * n, whatever the size of a. The program builds MuJoCo's
// quaternion from the axis and the angle (mju_axisAngle2Quat), reads the rotation vector back (mju_quat2Vel over a
// time of 1 s, which MuJoCo uses wherever a change of orientation becomes a velocity, as in mj_differentiatePos), and
// writes both as whole numbers. Nothing is simulated: this asks MuJoCo's functions one question with a known answer.
// MuJoCo replaces an axis shorter than mjMINVAL (1e-15) with x in mju_normalize3; the first deep dive found SuperDex
// doing the same below about 2e-9 rad, which stalled its solver near rest (its patch E).
// usage: mjc_rotvec <out.txt> <case> [<case> ...]
//   a case is nx,ny,nz,mantissa,exponent: an axis (the program normalises it) and an angle of mantissa x 10^exponent
//   radians, for example 0,0,1,2.5,-9
// writes <out.txt>: a header line "ROTVEC cases <n> real_bits <b>", then one line a case:
//   "<case> <axis x> <axis y> <axis z> <angle mantissa in thousandths> <angle exponent> <read back x> <read back y>
//    <read back z> <distance>"
//   the axis in millionths; the rotation vector read back in millionths of the angle (so the right answer is the
//   axis); the distance of the vector read back from the right answer, in millionths of the angle
// Exit 0 on success.
#include <mujoco/mujoco.h>
#include <math.h>
#include <stdio.h>

static long long Round(double x) { return llround(x); }

int main(int argc, char** argv) {
  if (argc < 3) { fprintf(stderr, "usage: mjc_rotvec <out.txt> <case> [<case> ...]\n"); return 2; }
  FILE* f = fopen(argv[1], "w");
  if (!f) { fprintf(stderr, "mjc_rotvec: cannot write %s\n", argv[1]); return 1; }
  fprintf(f, "ROTVEC cases %d real_bits %d\n", argc - 2, (int)(8 * sizeof(mjtNum)));
  for (int c = 2; c < argc; ++c) {
    double nx = 0.0, ny = 0.0, nz = 0.0, mant = 0.0;
    int ex = 0;
    if (sscanf(argv[c], "%lf,%lf,%lf,%lf,%d", &nx, &ny, &nz, &mant, &ex) != 5) {
      fprintf(stderr, "mjc_rotvec: bad case %s\n", argv[c]);
      return 2;
    }
    double const len = sqrt(nx * nx + ny * ny + nz * nz);
    if (!(len > 0.0) || !(mant > 0.0)) { fprintf(stderr, "mjc_rotvec: bad case %s\n", argv[c]); return 2; }
    nx /= len; ny /= len; nz /= len;
    double const ang = mant * pow(10.0, (double)ex);
    mjtNum const axis[3] = {nx, ny, nz};
    mjtNum q[4], out[3];
    mju_axisAngle2Quat(q, axis, ang);
    mju_quat2Vel(out, q, 1.0);
    double const in[3] = {ang * nx, ang * ny, ang * nz};
    double const dx = out[0] - in[0], dy = out[1] - in[1], dz = out[2] - in[2];
    double const dist = sqrt(dx * dx + dy * dy + dz * dz);
    fprintf(f, "%d %lld %lld %lld %lld %d %lld %lld %lld %lld\n", c - 2, Round(nx * 1e6), Round(ny * 1e6), Round(nz * 1e6),
            Round(mant * 1e3), ex, Round(out[0] / ang * 1e6), Round(out[1] / ang * 1e6), Round(out[2] / ang * 1e6),
            Round(dist / ang * 1e6));
  }
  fclose(f);
  printf("STATS rotvec cases %d real_bits %d engine mujoco %s\n", argc - 2, (int)(8 * sizeof(mjtNum)), mj_versionString());
  return 0;
}
