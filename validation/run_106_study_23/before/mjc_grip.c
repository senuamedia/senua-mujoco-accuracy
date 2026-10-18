// mjc_grip.c: two pads squeeze a cube from either side and hold it up against gravity by friction alone. The pads can
// be MuJoCo boxes or meshes of exactly the same shape (MuJoCo collides a mesh as its convex hull, with its general
// convex collider), and can grip the cube off its centre, so that gravity turns it about the squeeze. Things with a right
// answer whatever the time step:
//   - squeezed with 2 x friction x the squeeze above the cube's weight, the cube is held: it does not slip down and
//     does not turn;
//   - a pad does the same whatever it is written as: a box and a mesh of the same box hold the cube alike.
// The program only plays the scene and writes what the cube did, as whole numbers, in the contact rigs' format, so the
// same measuring programs read it. MuJoCo is z-up; the squeeze is along x.
// usage: mjc_grip <out prefix> dt=<seconds> [squeeze=N] [mass=KG] [radius=M] [mu=X] [pad=box|mesh] [offset=M]
//          [multiccd=0|1] [secs=S] [integ=NAME] [cone=NAME] [iterations=N] [tolerance=X] [noslip=N] [impratio=X]
//          [diagexact=1]
//   squeeze  the force each pad presses toward the cube with, newtons (default 2.45)
//   mass, radius   the cube's, kg and half-size in m (default 0.2, 0.03); mu the friction of every geom (default 0.8)
//   pad      box (default): each pad a MuJoCo box of half-sizes 0.01 x 0.02 x 0.02 m; mesh: a mesh of the same eight
//            corners
//   offset   the pads' centres sit this far along y from the cube's centre (default 0), so gravity turns the cube about
//            the squeeze unless the pads' contact resists it
//   multiccd 1: MuJoCo's multiccd flag (several contact points for convex collisions); default unset
//   integ, cone, iterations, tolerance, noslip, impratio: MuJoCo's own options; unset = MuJoCo's defaults
//   noslip_tolerance  MuJoCo's noslip_tolerance option; unset = MuJoCo's default (as before)
//   diagexact 1: MuJoCo's diagexact flag (the exact diagonal of the constraint inertia, in the current pose, in place
//            of the approximation frozen in the written pose); unset = MuJoCo's default (off)
// Each pad (0.1 kg) moves only along x, on a slide joint, pushed toward the cube; the cube is free. At the start the pads
// touch the cube's two faces and everything is at rest.
// writes <out prefix>.txt: a header line "CONTACT dt_ns <n> h0_nm 0 vx0_ums 0 mu_ppm <n> mass_g <n> steps <n>", then
//   one line a step: "<step> <the cube's height less where it started, nm> <its speed down, um/s> <its speed along x,
//   um/s> <the squeeze: the pads' normal forces on it, summed, mN> <the friction on it along the way down, mN>", so that
//   read as a hold, the cube's slip down is the creep and the friction against the squeeze its share of the limit;
//   and <out prefix>_tilt.txt in the joint rig's format: "<step> <the angle the cube has turned through from its start,
//   micro-radians> <its angular speed, micro-radians a second> 0 0 0".
// prints one STATS line: the solver's iterations, the steps at the iteration limit, MuJoCo's warnings, the most contacts
//   between the pads and the cube on any step. Exit 0.
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
    fprintf(stderr, "usage: mjc_grip <out prefix> dt=<seconds> [squeeze=] [mass=] [radius=] [mu=] [pad=box|mesh] "
                    "[offset=] [multiccd=] [secs=] [integ=] [cone=] [iterations=] [tolerance=] [noslip=] [impratio=]\n");
    return 2;
  }
  double dt = 0.0, squeeze = 2.45, mass = 0.2, radius = 0.03, mu = 0.8, offset = 0.0, secs = 2.0;
  int mesh = 0, multiccd = 0, diagexact = 0;
  const char *integ = NULL, *cone = NULL, *iterations = NULL, *tolerance = NULL, *noslip = NULL, *impratio = NULL,
             *nstol = NULL;
  char extra[512] = "";
  for (int i = 2; i < argc; ++i) {
    const char* v;
    const char* a = argv[i];
    int known = 1;
    if (Arg(a, "dt", &v)) dt = atof(v);
    else if (Arg(a, "squeeze", &v)) squeeze = atof(v);
    else if (Arg(a, "mass", &v)) mass = atof(v);
    else if (Arg(a, "radius", &v)) radius = atof(v);
    else if (Arg(a, "mu", &v)) mu = atof(v);
    else if (Arg(a, "pad", &v)) {
      if (strcmp(v, "mesh") == 0) mesh = 1;
      else if (strcmp(v, "box") == 0) mesh = 0;
      else known = 0;
    }
    else if (Arg(a, "offset", &v)) offset = atof(v);
    else if (Arg(a, "multiccd", &v)) multiccd = atoi(v);
    else if (Arg(a, "diagexact", &v)) diagexact = atoi(v);
    else if (Arg(a, "secs", &v)) secs = atof(v);
    else if (Arg(a, "integ", &v)) integ = v;
    else if (Arg(a, "cone", &v)) cone = v;
    else if (Arg(a, "iterations", &v)) iterations = v;
    else if (Arg(a, "tolerance", &v)) tolerance = v;
    else if (Arg(a, "noslip", &v)) noslip = v;
    else if (Arg(a, "noslip_tolerance", &v)) nstol = v;
    else if (Arg(a, "impratio", &v)) impratio = v;
    else known = 0;
    if (!known) { fprintf(stderr, "mjc_grip: unknown setting %s\n", a); return 2; }
    if (strncmp(a, "dt=", 3) != 0) {
      strncat(extra, " ", sizeof extra - strlen(extra) - 1);
      strncat(extra, a, sizeof extra - strlen(extra) - 1);
    }
  }
  if (dt <= 0.0) { fprintf(stderr, "mjc_grip: dt must be given\n"); return 2; }

  double const px = 0.01, py = 0.02, pz = 0.02;  // the pads' half-sizes
  char opt[640];
  snprintf(opt, sizeof opt, "timestep=\"%.17g\" gravity=\"0 0 -9.8\"%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", dt,
           integ ? " integrator=\"" : "", integ ? integ : "", integ ? "\"" : "",
           cone ? " cone=\"" : "", cone ? cone : "", cone ? "\"" : "",
           iterations ? " iterations=\"" : "", iterations ? iterations : "", iterations ? "\"" : "",
           tolerance ? " tolerance=\"" : "", tolerance ? tolerance : "", tolerance ? "\"" : "",
           noslip ? " noslip_iterations=\"" : "", noslip ? noslip : "", noslip ? "\"" : "",
           impratio ? " impratio=\"" : "", impratio ? impratio : "", impratio ? "\"" : "",
           nstol ? " noslip_tolerance=\"" : "", nstol ? nstol : "", nstol ? "\"" : "");
  char asset[1024] = "";
  if (mesh)
    snprintf(asset, sizeof asset,
             "<asset><mesh name=\"padmesh\" vertex=\"%.17g %.17g %.17g  %.17g %.17g %.17g  %.17g %.17g %.17g  %.17g %.17g %.17g  "
             "%.17g %.17g %.17g  %.17g %.17g %.17g  %.17g %.17g %.17g  %.17g %.17g %.17g\"/></asset>",
             -px, -py, -pz, px, -py, -pz, -px, py, -pz, px, py, -pz, -px, -py, pz, px, -py, pz, -px, py, pz, px, py, pz);
  char padgeom[2][512];
  for (int s = 0; s < 2; ++s) {
    if (mesh)
      snprintf(padgeom[s], sizeof padgeom[s], "<geom name=\"pad%d\" type=\"mesh\" mesh=\"padmesh\" mass=\"0.1\" "
               "friction=\"%.17g 0.005 0.0001\"/>", s, mu);
    else
      snprintf(padgeom[s], sizeof padgeom[s], "<geom name=\"pad%d\" type=\"box\" size=\"%.17g %.17g %.17g\" mass=\"0.1\" "
               "friction=\"%.17g 0.005 0.0001\"/>", s, px, py, pz, mu);
  }
  char flag[128] = "";  // MuJoCo's flags, one element, only when one is asked for
  if (multiccd || diagexact)
    snprintf(flag, sizeof flag, "<flag%s%s/>", multiccd ? " multiccd=\"enable\"" : "", diagexact ? " diagexact=\"enable\"" : "");
  double const zc = 0.5;  // the cube's centre, well above anything
  char xml[8192];
  snprintf(xml, sizeof xml,
           "<mujoco model=\"grip\"><option %s>%s</option>%s<worldbody>"
           "<body name=\"pad0\" pos=\"%.17g %.17g %.17g\"><joint type=\"slide\" axis=\"1 0 0\"/>%s</body>"
           "<body name=\"pad1\" pos=\"%.17g %.17g %.17g\"><joint type=\"slide\" axis=\"1 0 0\"/>%s</body>"
           "<body name=\"cube\" pos=\"0 0 %.17g\"><freejoint/><geom name=\"box\" type=\"box\" size=\"%.17g %.17g %.17g\" "
           "mass=\"%.17g\" friction=\"%.17g 0.005 0.0001\"/></body>"
           "</worldbody></mujoco>",
           opt, flag, asset,
           -(radius + px), offset, zc, padgeom[0], radius + px, offset, zc, padgeom[1], zc, radius, radius, radius, mass, mu);
  mjVFS vfs;
  mj_defaultVFS(&vfs);
  if (mj_addBufferVFS(&vfs, "grip.xml", xml, (int)strlen(xml)) != 0) { fprintf(stderr, "mjc_grip: vfs\n"); return 1; }
  char err[1024] = "";
  mjModel* m = mj_loadXML("grip.xml", &vfs, err, sizeof err);
  mj_deleteVFS(&vfs);
  if (!m) { fprintf(stderr, "mjc_grip: %s\n", err); return 1; }
  mjData* d = mj_makeData(m);
  int const pad[2] = {mj_name2id(m, mjOBJ_BODY, "pad0"), mj_name2id(m, mjOBJ_BODY, "pad1")};
  int const cube = mj_name2id(m, mjOBJ_BODY, "cube");
  int const box = mj_name2id(m, mjOBJ_GEOM, "box");
  int const cdof = m->body_dofadr[cube];
  int const cq = m->jnt_qposadr[m->body_jntadr[cube]];
  mj_forward(m, d);
  double const z0 = d->xpos[3 * cube + 2];
  double const q0[4] = {d->qpos[cq + 3], d->qpos[cq + 4], d->qpos[cq + 5], d->qpos[cq + 6]};

  char path[1024];
  snprintf(path, sizeof path, "%s.txt", argv[1]);
  FILE* f = fopen(path, "w");
  snprintf(path, sizeof path, "%s_tilt.txt", argv[1]);
  FILE* t = fopen(path, "w");
  if (!f || !t) { fprintf(stderr, "mjc_grip: cannot write %s\n", path); return 1; }
  long const steps = (long)llround(secs / dt);
  fprintf(f, "CONTACT dt_ns %lld h0_nm 0 vx0_ums 0 mu_ppm %lld mass_g %lld steps %ld\n", Round(dt * 1e9),
          Round(mu * 1e6), Round(mass * 1e3), steps);
  fprintf(t, "CONTACT dt_ns %lld h0_nm 0 vx0_ums 0 mu_ppm %lld mass_g %lld steps %ld\n", Round(dt * 1e9),
          Round(mu * 1e6), Round(mass * 1e3), steps);
  long atLimit = 0;
  int mostIters = 0, mostCon = 0;
  for (long i = 0; i < steps; ++i) {
    d->xfrc_applied[6 * pad[0]] = squeeze;   // pad 0 sits at -x and is pushed toward +x
    d->xfrc_applied[6 * pad[1]] = -squeeze;  // pad 1 at +x, pushed toward -x
    mj_step(m, d);
    // the state the step ended in, as the other rigs report it (the next mj_step recomputes it anyway)
    mj_kinematics(m, d);
    int const it = d->solver_niter[0];
    if (it > mostIters) mostIters = it;
    if (it >= m->opt.iterations) ++atLimit;
    if (d->ncon > mostCon) mostCon = d->ncon;
    double normal = 0.0, fdown = 0.0;
    for (int c = 0; c < d->ncon; ++c) {
      mjContact const* con = d->contact + c;
      if (con->geom[0] != box && con->geom[1] != box) continue;
      mjtNum cf[6];
      mj_contactForce(m, d, c, cf);
      double const s = (con->geom[1] == box) ? 1.0 : -1.0;
      double fw[3];
      for (int j = 0; j < 3; ++j) fw[j] = s * (cf[0] * con->frame[j] + cf[1] * con->frame[3 + j] + cf[2] * con->frame[6 + j]);
      normal += fabs(fw[0]);
      fdown += -fw[2];
    }
    // the angle turned through: twice the angle of the relative rotation's quaternion
    double const* q = d->qpos + cq + 3;
    double const w = q0[0] * q[0] + q0[1] * q[1] + q0[2] * q[2] + q0[3] * q[3];
    double const vx = q0[0] * q[1] - q0[1] * q[0] - q0[2] * q[3] + q0[3] * q[2];
    double const vy = q0[0] * q[2] + q0[1] * q[3] - q0[2] * q[0] - q0[3] * q[1];
    double const vz = q0[0] * q[3] - q0[1] * q[2] + q0[2] * q[1] - q0[3] * q[0];
    double const turned = 2.0 * atan2(sqrt(vx * vx + vy * vy + vz * vz), fabs(w));
    double const* om = d->qvel + cdof + 3;
    double const spin = sqrt(om[0] * om[0] + om[1] * om[1] + om[2] * om[2]);
    fprintf(f, "%ld %lld %lld %lld %lld %lld\n", i, Round((d->xpos[3 * cube + 2] - z0) * 1e9),
            Round(-d->qvel[cdof + 2] * 1e6), Round(d->qvel[cdof] * 1e6), Round(normal * 1e3), Round(fdown * 1e3));
    fprintf(t, "%ld %lld %lld 0 0 0\n", i, Round(turned * 1e6), Round(spin * 1e6));
  }
  fclose(f);
  fclose(t);
  int warnings = 0;
  for (int k = 0; k < mjNWARNING; ++k) warnings += d->warning[k].number;
  printf("STATS grip dt %g squeeze %g mass %g radius %g mu %g pad %s offset %g multiccd %d steps %ld most_iterations %d "
         "at_iteration_limit %ld iteration_limit %d most_contacts %d warnings %d engine mujoco %s extra%s\n",
         dt, squeeze, mass, radius, mu, mesh ? "mesh" : "box", offset, multiccd, steps, mostIters, atLimit,
         m->opt.iterations, mostCon, warnings, mj_versionString(), extra[0] ? extra : " none");
  mj_deleteData(d);
  mj_deleteModel(m);
  return 0;
}
