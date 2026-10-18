// mjc_joint.c: the one-joint rig for MuJoCo, matching the first deep dive's sdx_joint rig scene for scene and column
// for column, so the same measuring programs read it. A base fixed to the world and one arm on a hinge, with nothing
// touching it. The arm is a cube of half-size `radius` whose centre is `arm` metres from the joint, along +x at joint
// angle zero; the hinge turns about -y, so a positive angle lifts the arm and gravity (along -z) pulls a level arm
// down with a torque of mass x 9.8 x arm, as in sdx_joint. Things with a right answer:
//   - with no joint friction the arm is a pendulum, and keeps its energy: released level, it comes up level on the
//     other side, every swing;
//   - with joint friction larger than gravity's torque, the arm stays where it was put;
//   - a constant joint torque with no gravity turns the arm at torque / inertia;
//   - a limit pushes and never pulls: released from inside its range the arm leaves as free motion would.
// usage: mjc_joint <out.txt> dt=<seconds> [setting=value ...]
//   mass, radius, arm   kg; the cube's half-size, m; joint to cube centre, m (default 1, 0.05, 0.5)
//   angle0, omega0      the joint angle (rad, 0 is level) and speed (rad/s) at release (default 0, 0)
//   secs                how long to play (default 2); gravity 0 = none (default 1)
//   coulomb             the joint's dry friction torque, N m (MuJoCo's frictionloss; default 0)
//   viscous             the joint's viscous damping, N m s (MuJoCo's damping; default 0)
//   torque, torqueat    a constant torque on the joint, N m, from torqueat s on (default 0, 0)
//   lo, hi              joint limits, rad (default: none); limitk, limitd their stiffness and damping, given to
//                       MuJoCo as solreflimit="-limitk/I -limitd/I", I the arm's inertia about the joint, since
//                       MuJoCo's direct form is per unit of inertia (unset: MuJoCo's default soft limit); limitimp is
//                       MuJoCo's solimplimit, three numbers separated by spaces, as one argument
//   integ, iterations, tolerance   MuJoCo's own options (unset: MuJoCo's defaults)
//   noslip, cone        MuJoCo's noslip_iterations and cone options (unset: MuJoCo's defaults, as before)
// writes <out.txt>: a header line "CONTACT dt_ns <n> h0_nm 0 vx0_ums 0 mu_ppm 0 mass_g <n> steps <n>", then one line a
//   step: "<step> <joint angle, micro-radians> <joint speed, micro-radians a second> 0 0 0"
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

int main(int argc, char** argv) {
  if (argc < 3) {
    fprintf(stderr, "usage: mjc_joint <out.txt> dt=<seconds> [mass=] [radius=] [arm=] [angle0=] [omega0=] [secs=] "
                    "[gravity=0|1] [coulomb=] [viscous=] [torque=] [torqueat=] [lo=] [hi=] [limitk=] [limitd=] "
                    "[integ=] [iterations=] [tolerance=]\n");
    return 2;
  }
  double dt = 0.0, mass = 1.0, radius = 0.05, arm = 0.5, angle0 = 0.0, omega0 = 0.0, secs = 2.0, coulomb = 0.0;
  double viscous = 0.0, torque = 0.0, torqueAt = 0.0, lo = 0.0, hi = 0.0, limitK = -1.0, limitD = -1.0;
  int gravity = 1, limited = 0;
  const char *integ = NULL, *iterations = NULL, *tolerance = NULL, *limitImp = NULL, *noslip = NULL, *cone = NULL;
  char extra[512] = "";
  for (int i = 2; i < argc; ++i) {
    const char* v;
    const char* a = argv[i];
    int known = 1;
    if (Arg(a, "dt", &v)) dt = atof(v);
    else if (Arg(a, "mass", &v)) mass = atof(v);
    else if (Arg(a, "radius", &v)) radius = atof(v);
    else if (Arg(a, "arm", &v)) arm = atof(v);
    else if (Arg(a, "angle0", &v)) angle0 = atof(v);
    else if (Arg(a, "omega0", &v)) omega0 = atof(v);
    else if (Arg(a, "secs", &v)) secs = atof(v);
    else if (Arg(a, "gravity", &v)) gravity = atoi(v);
    else if (Arg(a, "coulomb", &v)) coulomb = atof(v);
    else if (Arg(a, "viscous", &v)) viscous = atof(v);
    else if (Arg(a, "torque", &v)) torque = atof(v);
    else if (Arg(a, "torqueat", &v)) torqueAt = atof(v);
    else if (Arg(a, "lo", &v)) { lo = atof(v); limited = 1; }
    else if (Arg(a, "hi", &v)) { hi = atof(v); limited = 1; }
    else if (Arg(a, "limitk", &v)) limitK = atof(v);
    else if (Arg(a, "limitd", &v)) limitD = atof(v);
    else if (Arg(a, "limitimp", &v)) limitImp = v;
    else if (Arg(a, "integ", &v)) integ = v;
    else if (Arg(a, "iterations", &v)) iterations = v;
    else if (Arg(a, "tolerance", &v)) tolerance = v;
    else if (Arg(a, "noslip", &v)) noslip = v;
    else if (Arg(a, "cone", &v)) cone = v;
    else known = 0;
    if (!known) { fprintf(stderr, "mjc_joint: unknown setting %s\n", a); return 2; }
    if (strncmp(a, "dt=", 3) != 0) {
      strncat(extra, " ", sizeof extra - strlen(extra) - 1);
      strncat(extra, a, sizeof extra - strlen(extra) - 1);
    }
  }
  if (dt <= 0.0) { fprintf(stderr, "mjc_joint: dt must be given\n"); return 2; }

  char opt[640];
  snprintf(opt, sizeof opt, "timestep=\"%.17g\" gravity=\"0 0 %s\"%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", dt,
           gravity ? "-9.8" : "0",
           integ ? " integrator=\"" : "", integ ? integ : "", integ ? "\"" : "",
           iterations ? " iterations=\"" : "", iterations ? iterations : "", iterations ? "\"" : "",
           tolerance ? " tolerance=\"" : "", tolerance ? tolerance : "", tolerance ? "\"" : "",
           noslip ? " noslip_iterations=\"" : "", noslip ? noslip : "", noslip ? "\"" : "",
           cone ? " cone=\"" : "", cone ? cone : "", cone ? "\"" : "");
  char lim[256] = "";
  // the arm's inertia about the joint: the cube about its centre, (2/3) m r^2, moved out by m arm^2
  double const inertia = mass * (arm * arm + 2.0 / 3.0 * radius * radius);
  if (limited) {
    if (limitK >= 0.0 && limitD >= 0.0)
      // MuJoCo's direct form gives stiffness and damping on the constraint's acceleration, per unit of inertia; the
      // registered limits are a torque spring and damper, so each is divided by the arm's inertia about the joint
      snprintf(lim, sizeof lim, " limited=\"true\" range=\"%.17g %.17g\" solreflimit=\"%.17g %.17g\"%s%s%s", lo, hi,
               -limitK / inertia, -limitD / inertia, limitImp ? " solimplimit=\"" : "", limitImp ? limitImp : "",
               limitImp ? "\"" : "");
    else
      snprintf(lim, sizeof lim, " limited=\"true\" range=\"%.17g %.17g\"", lo, hi);
  }
  char xml[4096];
  snprintf(xml, sizeof xml,
           "<mujoco model=\"arm\"><compiler angle=\"radian\"/><option %s/><worldbody>"
           "<body name=\"arm\" pos=\"0 0 0\">"
           "<joint name=\"hinge\" type=\"hinge\" axis=\"0 -1 0\" damping=\"%.17g\" frictionloss=\"%.17g\"%s/>"
           "<geom name=\"cube\" type=\"box\" pos=\"%.17g 0 0\" size=\"%.17g %.17g %.17g\" mass=\"%.17g\" contype=\"0\" "
           "conaffinity=\"0\"/>"
           "</body></worldbody></mujoco>",
           opt, viscous, coulomb, lim, arm, radius, radius, radius, mass);
  mjVFS vfs;
  mj_defaultVFS(&vfs);
  if (mj_addBufferVFS(&vfs, "arm.xml", xml, (int)strlen(xml)) != 0) { fprintf(stderr, "mjc_joint: vfs\n"); return 1; }
  char err[1024] = "";
  mjModel* m = mj_loadXML("arm.xml", &vfs, err, sizeof err);
  mj_deleteVFS(&vfs);
  if (!m) { fprintf(stderr, "mjc_joint: %s\n", err); return 1; }
  mjData* d = mj_makeData(m);
  d->qpos[0] = angle0;
  d->qvel[0] = omega0;
  mj_forward(m, d);

  FILE* f = fopen(argv[1], "w");
  if (!f) { fprintf(stderr, "mjc_joint: cannot write %s\n", argv[1]); return 1; }
  long const steps = (long)llround(secs / dt);
  fprintf(f, "CONTACT dt_ns %lld h0_nm 0 vx0_ums 0 mu_ppm 0 mass_g %lld steps %ld\n", Round(dt * 1e9), Round(mass * 1e3), steps);
  long atLimit = 0;
  int mostIters = 0;
  for (long i = 0; i < steps; ++i) {
    double const tmid = ((double)i + 0.5) * dt;
    d->qfrc_applied[0] = (torque != 0.0 && tmid >= torqueAt) ? torque : 0.0;
    mj_step(m, d);
    int const it = d->solver_niter[0];
    if (it > mostIters) mostIters = it;
    if (it >= m->opt.iterations) ++atLimit;
    fprintf(f, "%ld %lld %lld 0 0 0\n", i, Round(d->qpos[0] * 1e6), Round(d->qvel[0] * 1e6));
  }
  fclose(f);
  int warnings = 0;
  for (int w = 0; w < mjNWARNING; ++w) warnings += d->warning[w].number;
  printf("STATS joint dt %g steps %ld most_iterations %d at_iteration_limit %ld iteration_limit %d warnings %d "
         "inertia %.9g engine mujoco %s extra%s\n", dt, steps, mostIters, atLimit, m->opt.iterations, warnings,
         m->dof_M0 ? m->dof_M0[0] : 0.0, mj_versionString(), extra[0] ? extra : " none");
  mj_deleteData(d);
  mj_deleteModel(m);
  return 0;
}
