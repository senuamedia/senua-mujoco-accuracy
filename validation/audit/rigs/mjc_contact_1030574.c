// mjc_contact.c: the one-cube rig for MuJoCo, the adapter between Senua AI and the engine under test. It plays one
// cube on a plane and writes what happened, in exactly the format of the first deep dive's sdx_contact rig, so the
// same measuring programs read MuJoCo's runs unchanged. MuJoCo is z-up; the record's columns are the same quantities.
// usage: mjc_contact <out.txt> dt=<seconds> [h0=M] [vx0=V] [mu=X] [lock=0|1] [mass=KG] [radius=M] [secs=S] [push=N]
//          [pushat=S] [lift=N] [liftat=S] [integ=euler|implicit|implicitfast|rk4] [cone=pyramidal|elliptic]
//          [iterations=N] [tolerance=X] [noslip=N] [impratio=X] [dir=DEGREES]
//   h0      the gap between the cube's lowest face and the plane at the start (default 0.05 m)
//   lock    1 (default) = the cube cannot turn (three slide joints); 0 = a free joint
//   radius  the cube's half-size (default 0.05 m); mass in kg (default 1)
//   push    a force along x from pushat on; lift a force up from liftat on (newtons)
//   integ, cone, iterations, tolerance, noslip, impratio: MuJoCo's own options; unset = MuJoCo's defaults
//   dir     the slide's direction in the ground plane, degrees from x toward y (unset: along x, as before): the
//           starting velocity and the push point along it, the vx and Fx columns are along it, and the STATS line adds
//           how far the cube went across it (side_um, at the end) and the fastest it moved across it (most_side_ums)
// gravity is 9.8 m/s2, as in the first deep dive's known-answer suite. Both geoms carry the friction mu (MuJoCo takes
// the larger of the two); torsional and rolling friction are MuJoCo's defaults and play no part with condim 3.
// writes <out.txt>: a header line "CONTACT dt_ns <n> h0_nm <n> vx0_ums <n> mu_ppm <n> mass_g <n> steps <n>", then one
//   line a step: "<step> <height of the lowest face, nm> <vx, um/s> <vz, um/s> <contact force up, mN> <contact
//   force along x, mN>"
// prints one STATS line: the solver's iterations, the steps at the iteration limit, MuJoCo's warnings. Exit 0.
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

int main(int argc, char** argv) {
  if (argc < 3) {
    fprintf(stderr, "usage: mjc_contact <out.txt> dt=<seconds> [h0=M] [vx0=V] [mu=X] [lock=0|1] [mass=KG] [radius=M] "
                    "[secs=S] [push=N] [pushat=S] [lift=N] [liftat=S] [integ=NAME] [cone=NAME] [iterations=N] "
                    "[tolerance=X] [noslip=N] [impratio=X]\n");
    return 2;
  }
  double dt = 0.0, h0 = 0.05, vx0 = 0.0, mu = 0.0, mass = 1.0, radius = 0.05, secs = 1.0;
  double push = 0.0, pushAt = 0.0, lift = 0.0, liftAt = 0.3;
  int lock = 1, haveDir = 0;
  double dirDeg = 0.0;
  const char *integ = NULL, *cone = NULL, *iterations = NULL, *tolerance = NULL, *noslip = NULL, *impratio = NULL;
  char extra[512] = "";
  for (int i = 2; i < argc; ++i) {
    const char* v;
    const char* a = argv[i];
    if (Arg(a, "dt", &v)) dt = atof(v);
    else if (Arg(a, "h0", &v)) h0 = atof(v);
    else if (Arg(a, "vx0", &v)) vx0 = atof(v);
    else if (Arg(a, "mu", &v)) mu = atof(v);
    else if (Arg(a, "lock", &v)) lock = atoi(v);
    else if (Arg(a, "mass", &v)) mass = atof(v);
    else if (Arg(a, "radius", &v)) radius = atof(v);
    else if (Arg(a, "secs", &v)) secs = atof(v);
    else if (Arg(a, "push", &v)) push = atof(v);
    else if (Arg(a, "pushat", &v)) pushAt = atof(v);
    else if (Arg(a, "lift", &v)) lift = atof(v);
    else if (Arg(a, "liftat", &v)) liftAt = atof(v);
    else if (Arg(a, "dir", &v)) { dirDeg = atof(v); haveDir = 1; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "integ", &v)) { integ = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "cone", &v)) { cone = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "iterations", &v)) { iterations = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "tolerance", &v)) { tolerance = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "noslip", &v)) { noslip = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "impratio", &v)) { impratio = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else { fprintf(stderr, "mjc_contact: unknown setting %s\n", a); return 2; }
  }
  if (dt <= 0.0) { fprintf(stderr, "mjc_contact: dt must be given\n"); return 2; }

  // the scene: a plane and one cube, as MJCF; MuJoCo's own options only where a setting asks for them
  char opt[512];
  snprintf(opt, sizeof opt, "timestep=\"%.17g\" gravity=\"0 0 -9.8\"%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", dt,
           integ ? " integrator=\"" : "", integ ? integ : "", integ ? "\"" : "",
           cone ? " cone=\"" : "", cone ? cone : "", cone ? "\"" : "",
           iterations ? " iterations=\"" : "", iterations ? iterations : "", iterations ? "\"" : "",
           tolerance ? " tolerance=\"" : "", tolerance ? tolerance : "", tolerance ? "\"" : "",
           noslip ? " noslip_iterations=\"" : "", noslip ? noslip : "", noslip ? "\"" : "",
           impratio ? " impratio=\"" : "", impratio ? impratio : "", impratio ? "\"" : "");
  char joints[256];
  if (lock) snprintf(joints, sizeof joints, "<joint name=\"x\" type=\"slide\" axis=\"1 0 0\"/><joint name=\"y\" type=\"slide\" "
                                             "axis=\"0 1 0\"/><joint name=\"z\" type=\"slide\" axis=\"0 0 1\"/>");
  else snprintf(joints, sizeof joints, "<freejoint name=\"free\"/>");
  char xml[4096];
  snprintf(xml, sizeof xml,
           "<mujoco model=\"cube\"><option %s/><worldbody>"
           "<geom name=\"floor\" type=\"plane\" size=\"0 0 1\" friction=\"%.17g 0.005 0.0001\"/>"
           "<body name=\"cube\" pos=\"0 0 %.17g\">%s"
           "<geom name=\"box\" type=\"box\" size=\"%.17g %.17g %.17g\" mass=\"%.17g\" friction=\"%.17g 0.005 0.0001\"/>"
           "</body></worldbody></mujoco>",
           opt, mu, radius + h0, joints, radius, radius, radius, mass, mu);
  mjVFS vfs;
  mj_defaultVFS(&vfs);
  if (mj_addBufferVFS(&vfs, "cube.xml", xml, (int)strlen(xml)) != 0) { fprintf(stderr, "mjc_contact: vfs\n"); return 1; }
  char err[1024] = "";
  mjModel* m = mj_loadXML("cube.xml", &vfs, err, sizeof err);
  mj_deleteVFS(&vfs);
  if (!m) { fprintf(stderr, "mjc_contact: %s\n", err); return 1; }
  mjData* d = mj_makeData(m);
  int const body = mj_name2id(m, mjOBJ_BODY, "cube");
  int const box = mj_name2id(m, mjOBJ_GEOM, "box");
  d->qvel[0] = vx0;  // the x slide joint, or the free joint's linear x: the same first entry
  // a direction, only when asked for, so every play without one runs exactly as before
  double const rad = dirDeg * 3.14159265358979323846 / 180.0;  // C11 has no M_PI
  double const cd = cos(rad), sd = sin(rad);
  if (haveDir) { d->qvel[0] = vx0 * cd; d->qvel[1] = vx0 * sd; }  // the y slide joint, or the free joint's linear y
  mj_forward(m, d);
  double const x0 = d->xpos[3 * body], y0 = d->xpos[3 * body + 1];
  double mostSide = 0.0;

  FILE* f = fopen(argv[1], "w");
  if (!f) { fprintf(stderr, "mjc_contact: cannot write %s\n", argv[1]); return 1; }
  long const steps = (long)llround(secs / dt);
  fprintf(f, "CONTACT dt_ns %lld h0_nm %lld vx0_ums %lld mu_ppm %lld mass_g %lld steps %ld\n", Round(dt * 1e9),
          Round(h0 * 1e9), Round(vx0 * 1e6), Round(mu * 1e6), Round(mass * 1e3), steps);
  long atLimit = 0;
  int mostIters = 0;
  for (long i = 0; i < steps; ++i) {
    double const tmid = ((double)i + 0.5) * dt;
    mjtNum* xf = d->xfrc_applied + 6 * body;
    xf[0] = (push != 0.0 && (pushAt <= 0.0 || tmid >= pushAt)) ? push : 0.0;
    if (haveDir) { xf[1] = xf[0] * sd; xf[0] *= cd; }
    xf[2] = (lift != 0.0 && tmid >= liftAt) ? lift : 0.0;
    mj_step(m, d);
    int const it = d->solver_niter[0];
    if (it > mostIters) mostIters = it;
    if (it >= m->opt.iterations) ++atLimit;
    // the contact force on the cube, in world coordinates: each contact's force in its own frame, whose normal points
    // from geom1 to geom2, acts on geom2
    double fw[3] = {0.0, 0.0, 0.0};
    for (int c = 0; c < d->ncon; ++c) {
      mjContact const* con = d->contact + c;
      if (con->geom[0] != box && con->geom[1] != box) continue;
      mjtNum cf[6];
      mj_contactForce(m, d, c, cf);
      double const s = (con->geom[1] == box) ? 1.0 : -1.0;
      for (int j = 0; j < 3; ++j)
        fw[j] += s * (cf[0] * con->frame[j] + cf[1] * con->frame[3 + j] + cf[2] * con->frame[6 + j]);
    }
    double const z = d->xpos[3 * body + 2];
    double vx = lock ? d->qvel[0] : d->qvel[0];
    double const vz = lock ? d->qvel[2] : d->qvel[2];
    double fx = fw[0];
    if (haveDir) {  // along the direction, and across it
      vx = d->qvel[0] * cd + d->qvel[1] * sd;
      fx = fw[0] * cd + fw[1] * sd;
      double const across = fabs(-d->qvel[0] * sd + d->qvel[1] * cd);
      if (across > mostSide) mostSide = across;
    }
    fprintf(f, "%ld %lld %lld %lld %lld %lld\n", i, Round((z - radius) * 1e9), Round(vx * 1e6), Round(vz * 1e6),
            Round(fw[2] * 1e3), Round(fx * 1e3));
  }
  fclose(f);
  char side[128] = "";
  if (haveDir)
    snprintf(side, sizeof side, " side_um %lld most_side_ums %lld",
             Round((-(d->xpos[3 * body] - x0) * sd + (d->xpos[3 * body + 1] - y0) * cd) * 1e6), Round(mostSide * 1e6));
  int warnings = 0;
  for (int w = 0; w < mjNWARNING; ++w) warnings += d->warning[w].number;
  printf("STATS contact dt %g h0 %g vx0 %g mu %g lock %d mass %g radius %g steps %ld most_iterations %d "
         "at_iteration_limit %ld iteration_limit %d warnings %d%s engine mujoco %s extra%s\n",
         dt, h0, vx0, mu, lock, mass, radius, steps, mostIters, atLimit, m->opt.iterations, warnings, side,
         mj_versionString(), extra[0] ? extra : " none");
  mj_deleteData(d);
  mj_deleteModel(m);
  return 0;
}
