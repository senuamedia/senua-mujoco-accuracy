// mjc_chain.c: two arms on two hinge joints, with nothing touching them, matching the first deep dive's sdx_chain rig
// scene for scene and column for column, so the same measuring programs read it. A first arm on a joint at the world's
// origin and a second arm on a joint carried by the first; both joints turn about +z and gravity, when it is on, is
// along -y, so the motion stays in the x-y plane: a double pendulum. Each arm is a cube of half-size `radius`. The
// first arm's centre is `arm1` metres from the first joint and the second joint is `len1` metres from the first, both
// along the first arm's +x; the second arm's centre is `arm2` metres from the second joint, along the second arm's +x.
// Things with a right answer, none of which depends on how small the step is:
//   - with no gravity nothing does work on the chain: its kinetic energy stays what it was, and so does its angular
//     momentum about the first joint;
//   - with gravity its total energy (kinetic plus mass x 9.8 x height) stays what it was.
// The program only plays the scene and writes, as whole numbers, what the joints did and where MuJoCo says each arm
// is and how it moves. The measuring is done elsewhere.
// usage: mjc_chain <out.txt> dt=<seconds> [mass1=KG] [mass2=KG] [radius=M] [arm1=M] [len1=M] [arm2=M] [angle1=RAD]
//                  [angle2=RAD] [omega1=RAD_S] [omega2=RAD_S] [secs=S] [gravity=0] [integ=NAME]
//   defaults as sdx_chain: 1 kg, 1 kg, 0.05 m, 0.2 m, 0.4 m, 0.2 m, at rest and straight, 2 s, gravity on
//   integ    MuJoCo's integrator: Euler (its default), implicit, implicitfast, RK4
// writes <out.txt>: a header line
//   "CHAIN dt_ns <n> mass1_g <n> mass2_g <n> radius_um <n> arm1_um <n> len1_um <n> arm2_um <n> gravity <0|1> steps <n>"
// then one line a step, 15 whole numbers:
//   <step>
//   <joint 1 angle, micro-radians> <joint 1 speed, micro-radians a second>
//   <joint 2 angle, micro-radians> <joint 2 speed, micro-radians a second>
//   <arm 1 centre x, y, micrometres> <arm 1 velocity x, y, micrometres a second> <arm 1 spin about z, micro-radians a second>
//   <arm 2 centre x, y, micrometres> <arm 2 velocity x, y, micrometres a second> <arm 2 spin about z, micro-radians a second>
// The first line after the header (step -1) is the state before any step; every line is the state a step ended in.
// prints one STATS line. Exit 0.
#include <mujoco/mujoco.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static long long Round(double x) { return llround(x); }

static int Arg(const char* a, const char* key, const char** val) {
  size_t const n = strlen(key);
  if (strncmp(a, key, n) == 0 && a[n] == '=') { *val = a + n + 1; return 1; }
  return 0;
}

static void WriteRow(FILE* f, mjModel const* m, mjData* d, long step, int const body[2]) {
  fprintf(f, "%ld %lld %lld %lld %lld", step, Round(d->qpos[0] * 1e6), Round(d->qvel[0] * 1e6),
          Round(d->qpos[1] * 1e6), Round(d->qvel[1] * 1e6));
  for (int k = 0; k < 2; ++k) {
    mjtNum v[6];  // (angular, linear) at the body's centre of mass, world orientation
    mj_objectVelocity(m, d, mjOBJ_BODY, body[k], v, 0);
    fprintf(f, " %lld %lld %lld %lld %lld", Round(d->xipos[3 * body[k]] * 1e6), Round(d->xipos[3 * body[k] + 1] * 1e6),
            Round(v[3] * 1e6), Round(v[4] * 1e6), Round(v[2] * 1e6));
  }
  fprintf(f, "\n");
}

int main(int argc, char** argv) {
  if (argc < 3) {
    fprintf(stderr, "usage: mjc_chain <out.txt> dt=<seconds> [mass1=] [mass2=] [radius=] [arm1=] [len1=] [arm2=] "
                    "[angle1=] [angle2=] [omega1=] [omega2=] [secs=] [gravity=0|1] [integ=]\n");
    return 2;
  }
  double dt = 0.0, mass1 = 1.0, mass2 = 1.0, radius = 0.05, arm1 = 0.2, len1 = 0.4, arm2 = 0.2, secs = 2.0;
  double angle1 = 0.0, angle2 = 0.0, omega1 = 0.0, omega2 = 0.0;
  int gravity = 1;
  const char* integ = NULL;
  char extra[512] = "";
  for (int i = 2; i < argc; ++i) {
    const char* v;
    const char* a = argv[i];
    int known = 1;
    if (Arg(a, "dt", &v)) dt = atof(v);
    else if (Arg(a, "mass1", &v)) mass1 = atof(v);
    else if (Arg(a, "mass2", &v)) mass2 = atof(v);
    else if (Arg(a, "radius", &v)) radius = atof(v);
    else if (Arg(a, "arm1", &v)) arm1 = atof(v);
    else if (Arg(a, "len1", &v)) len1 = atof(v);
    else if (Arg(a, "arm2", &v)) arm2 = atof(v);
    else if (Arg(a, "angle1", &v)) angle1 = atof(v);
    else if (Arg(a, "angle2", &v)) angle2 = atof(v);
    else if (Arg(a, "omega1", &v)) omega1 = atof(v);
    else if (Arg(a, "omega2", &v)) omega2 = atof(v);
    else if (Arg(a, "secs", &v)) secs = atof(v);
    else if (Arg(a, "gravity", &v)) gravity = atoi(v);
    else if (Arg(a, "integ", &v)) integ = v;
    else known = 0;
    if (!known) { fprintf(stderr, "mjc_chain: unknown setting %s\n", a); return 2; }
    if (strncmp(a, "dt=", 3) != 0) {
      strncat(extra, " ", sizeof extra - strlen(extra) - 1);
      strncat(extra, a, sizeof extra - strlen(extra) - 1);
    }
  }
  if (dt <= 0.0) { fprintf(stderr, "mjc_chain: dt must be given\n"); return 2; }

  char xml[4096];
  snprintf(xml, sizeof xml,
           "<mujoco model=\"chain\"><compiler angle=\"radian\"/><option timestep=\"%.17g\" gravity=\"0 %s 0\"%s%s%s/>"
           "<worldbody>"
           "<body name=\"arm1\" pos=\"0 0 0\"><joint name=\"j1\" type=\"hinge\" axis=\"0 0 1\"/>"
           "<geom type=\"box\" pos=\"%.17g 0 0\" size=\"%.17g %.17g %.17g\" mass=\"%.17g\" contype=\"0\" conaffinity=\"0\"/>"
           "<body name=\"arm2\" pos=\"%.17g 0 0\"><joint name=\"j2\" type=\"hinge\" axis=\"0 0 1\"/>"
           "<geom type=\"box\" pos=\"%.17g 0 0\" size=\"%.17g %.17g %.17g\" mass=\"%.17g\" contype=\"0\" conaffinity=\"0\"/>"
           "</body></body></worldbody></mujoco>",
           dt, gravity ? "-9.8" : "0", integ ? " integrator=\"" : "", integ ? integ : "", integ ? "\"" : "",
           arm1, radius, radius, radius, mass1, len1, arm2, radius, radius, radius, mass2);
  mjVFS vfs;
  mj_defaultVFS(&vfs);
  if (mj_addBufferVFS(&vfs, "chain.xml", xml, (int)strlen(xml)) != 0) { fprintf(stderr, "mjc_chain: vfs\n"); return 1; }
  char err[1024] = "";
  mjModel* m = mj_loadXML("chain.xml", &vfs, err, sizeof err);
  mj_deleteVFS(&vfs);
  if (!m) { fprintf(stderr, "mjc_chain: %s\n", err); return 1; }
  if (m->nv != 2) { fprintf(stderr, "mjc_chain: expected two degrees of freedom, found %d\n", (int)m->nv); return 1; }
  mjData* d = mj_makeData(m);
  int const body[2] = {mj_name2id(m, mjOBJ_BODY, "arm1"), mj_name2id(m, mjOBJ_BODY, "arm2")};
  d->qpos[0] = angle1;
  d->qpos[1] = angle2;
  d->qvel[0] = omega1;
  d->qvel[1] = omega2;
  mj_forward(m, d);

  FILE* f = fopen(argv[1], "w");
  if (!f) { fprintf(stderr, "mjc_chain: cannot write %s\n", argv[1]); return 1; }
  long const steps = (long)llround(secs / dt);
  fprintf(f, "CHAIN dt_ns %lld mass1_g %lld mass2_g %lld radius_um %lld arm1_um %lld len1_um %lld arm2_um %lld "
             "gravity %d steps %ld\n",
          Round(dt * 1e9), Round(mass1 * 1e3), Round(mass2 * 1e3), Round(radius * 1e6), Round(arm1 * 1e6),
          Round(len1 * 1e6), Round(arm2 * 1e6), gravity != 0 ? 1 : 0, steps);
  WriteRow(f, m, d, -1, body);
  for (long i = 0; i < steps; ++i) {
    mj_step(m, d);
    // mj_step leaves positions and velocities of the bodies at the step's start; recompute them for the state the
    // step ended in (the next mj_step recomputes them anyway: the play is the same)
    mj_kinematics(m, d);
    mj_comPos(m, d);
    mj_comVel(m, d);
    WriteRow(f, m, d, i, body);
  }
  fclose(f);
  int warnings = 0;
  for (int w = 0; w < mjNWARNING; ++w) warnings += d->warning[w].number;
  printf("STATS chain dt %g mass1 %g mass2 %g radius %g arm1 %g len1 %g arm2 %g gravity %d dofs %d steps %ld "
         "warnings %d engine mujoco %s extra%s\n", dt, mass1, mass2, radius, arm1, len1, arm2, gravity, (int)m->nv, steps,
         warnings, mj_versionString(), extra[0] ? extra : " none");
  mj_deleteData(d);
  mj_deleteModel(m);
  return 0;
}
