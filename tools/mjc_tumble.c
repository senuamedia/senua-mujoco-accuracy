// mjc_tumble.c: one free rigid body tumbling in empty space, with nothing touching it and no gravity. Its three
// principal moments of inertia differ, and it is set spinning about a general axis, so it tumbles. Things with a right
// answer, none of which depends on how small the step is (Euler's equations for a torque-free body):
//   - its rotational kinetic energy, 1/2 (I1 w1^2 + I2 w2^2 + I3 w3^2), stays what it was;
//   - the magnitude of its angular momentum, |L|^2 = (I1 w1)^2 + (I2 w2)^2 + (I3 w3)^2, stays what it was.
// Both are read in the body's own frame from its angular velocity there and its principal moments, so no rotation is
// needed. The program only plays the scene and writes, as whole numbers, the body's angular velocity in its own frame
// at every step. The measuring is done elsewhere.
// The body: MuJoCo's free joint, its inertia given as diaginertia (so its principal axes are the body's own axes), no
// geom. MuJoCo's free joint carries the angular velocity in the body's local frame (qvel[3..5]); the program checks
// that against mj_objectVelocity in the local frame, in the pose the play ended in, and prints the difference.
// usage: mjc_tumble <out.txt> dt=<seconds> i1=KGM2 i2=KGM2 i3=KGM2 w1=RAD_S w2=RAD_S w3=RAD_S [mass=KG] [secs=S]
//          [integ=NAME] [cone=NAME] [noslip=N]
//   i1, i2, i3   the principal moments of inertia, kg m2
//   w1, w2, w3   the angular velocity at the start, along the body's own axes, rad/s
//   mass         kg (default 1; it does not enter the right answer); secs: how long to play (default 2)
//   integ        MuJoCo's integrator: Euler (its default), implicitfast, implicit, RK4
//   cone, noslip MuJoCo's own options (unset: MuJoCo's defaults); with nothing touching the body they have no
//                constraint row to act on
// writes <out.txt>: a header line "TUMBLE dt_ns <n> i1_nkgm2 <n> i2_nkgm2 <n> i3_nkgm2 <n> mass_g <n> steps <n>" (the
//   moments as MuJoCo holds them, in units of 1e-9 kg m2), then one line a step, 4 whole numbers: "<step> <angular
//   velocity along the body's x, y and z axes, micro-radians a second>". The first line after the header (step -1) is
//   the state before any step; every line is the state a step ended in.
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

static void WriteRow(FILE* f, mjData const* d, long step) {
  fprintf(f, "%ld %lld %lld %lld\n", step, Round(d->qvel[3] * 1e6), Round(d->qvel[4] * 1e6), Round(d->qvel[5] * 1e6));
}

int main(int argc, char** argv) {
  if (argc < 9) {
    fprintf(stderr, "usage: mjc_tumble <out.txt> dt=<seconds> i1= i2= i3= w1= w2= w3= [mass=] [secs=] [integ=] "
                    "[cone=] [noslip=]\n");
    return 2;
  }
  double dt = 0.0, mass = 1.0, secs = 2.0, in[3] = {0.0, 0.0, 0.0}, w[3] = {0.0, 0.0, 0.0};
  int have = 0;
  const char *integ = NULL, *cone = NULL, *noslip = NULL;
  char extra[512] = "";
  for (int i = 2; i < argc; ++i) {
    const char* v;
    const char* a = argv[i];
    int known = 1;
    if (Arg(a, "dt", &v)) dt = atof(v);
    else if (Arg(a, "i1", &v)) { in[0] = atof(v); have |= 1; }
    else if (Arg(a, "i2", &v)) { in[1] = atof(v); have |= 2; }
    else if (Arg(a, "i3", &v)) { in[2] = atof(v); have |= 4; }
    else if (Arg(a, "w1", &v)) { w[0] = atof(v); have |= 8; }
    else if (Arg(a, "w2", &v)) { w[1] = atof(v); have |= 16; }
    else if (Arg(a, "w3", &v)) { w[2] = atof(v); have |= 32; }
    else if (Arg(a, "mass", &v)) mass = atof(v);
    else if (Arg(a, "secs", &v)) secs = atof(v);
    else if (Arg(a, "integ", &v)) integ = v;
    else if (Arg(a, "cone", &v)) cone = v;
    else if (Arg(a, "noslip", &v)) noslip = v;
    else known = 0;
    if (!known) { fprintf(stderr, "mjc_tumble: unknown setting %s\n", a); return 2; }
    if (strncmp(a, "dt=", 3) != 0) {
      strncat(extra, " ", sizeof extra - strlen(extra) - 1);
      strncat(extra, a, sizeof extra - strlen(extra) - 1);
    }
  }
  if (dt <= 0.0 || have != 63) { fprintf(stderr, "mjc_tumble: dt, i1, i2, i3, w1, w2 and w3 must be given\n"); return 2; }

  char xml[2048];
  snprintf(xml, sizeof xml,
           "<mujoco model=\"tumble\"><option timestep=\"%.17g\" gravity=\"0 0 0\"%s%s%s%s%s%s%s%s%s/>"
           "<worldbody><body name=\"body\" pos=\"0 0 0\"><freejoint/>"
           "<inertial pos=\"0 0 0\" mass=\"%.17g\" diaginertia=\"%.17g %.17g %.17g\"/>"
           "</body></worldbody></mujoco>",
           dt, integ ? " integrator=\"" : "", integ ? integ : "", integ ? "\"" : "",
           cone ? " cone=\"" : "", cone ? cone : "", cone ? "\"" : "",
           noslip ? " noslip_iterations=\"" : "", noslip ? noslip : "", noslip ? "\"" : "", mass, in[0], in[1], in[2]);
  mjVFS vfs;
  mj_defaultVFS(&vfs);
  if (mj_addBufferVFS(&vfs, "tumble.xml", xml, (int)strlen(xml)) != 0) { fprintf(stderr, "mjc_tumble: vfs\n"); return 1; }
  char err[1024] = "";
  mjModel* m = mj_loadXML("tumble.xml", &vfs, err, sizeof err);
  mj_deleteVFS(&vfs);
  if (!m) { fprintf(stderr, "mjc_tumble: %s\n", err); return 1; }
  if (m->nv != 6) { fprintf(stderr, "mjc_tumble: expected six degrees of freedom, found %d\n", (int)m->nv); return 1; }
  int const b = mj_name2id(m, mjOBJ_BODY, "body");
  mjtNum const* iq = m->body_iquat + 4 * b;
  if (iq[0] != 1 || iq[1] != 0 || iq[2] != 0 || iq[3] != 0) {
    fprintf(stderr, "mjc_tumble: the inertial frame is not the body's own frame\n");
    return 1;
  }
  mjData* d = mj_makeData(m);
  for (int k = 0; k < 3; ++k) d->qvel[3 + k] = w[k];
  mj_forward(m, d);

  FILE* f = fopen(argv[1], "w");
  if (!f) { fprintf(stderr, "mjc_tumble: cannot write %s\n", argv[1]); return 1; }
  long const steps = (long)llround(secs / dt);
  mjtNum const* im = m->body_inertia + 3 * b;
  fprintf(f, "TUMBLE dt_ns %lld i1_nkgm2 %lld i2_nkgm2 %lld i3_nkgm2 %lld mass_g %lld steps %ld\n", Round(dt * 1e9),
          Round(im[0] * 1e9), Round(im[1] * 1e9), Round(im[2] * 1e9), Round(m->body_mass[b] * 1e3), steps);
  WriteRow(f, d, -1);
  for (long i = 0; i < steps; ++i) {
    mj_step(m, d);
    WriteRow(f, d, i);
  }
  fclose(f);
  // the free joint's angular velocity against the body's own, in its local frame, in the pose the play ended in
  mj_kinematics(m, d);
  mj_comPos(m, d);
  mj_comVel(m, d);
  double check = 0.0;
  {
    mjtNum v[6];
    mj_objectVelocity(m, d, mjOBJ_BODY, b, v, 1);
    for (int k = 0; k < 3; ++k) check = fmax(check, fabs(v[k] - d->qvel[3 + k]));
  }
  int warnings = 0;
  for (int k = 0; k < mjNWARNING; ++k) warnings += d->warning[k].number;
  printf("STATS tumble dt %g i %.9g,%.9g,%.9g w %g,%g,%g steps %ld local_frame_check %.3g warnings %d "
         "engine mujoco %s extra%s\n", dt, im[0], im[1], im[2], w[0], w[1], w[2], steps, check, warnings,
         mj_versionString(), extra[0] ? extra : " none");
  mj_deleteData(d);
  mj_deleteModel(m);
  return 0;
}
