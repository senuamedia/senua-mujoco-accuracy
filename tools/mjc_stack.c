// mjc_stack.c: a stack of cubes, each free to move and turn, on the ground or on a fixed box, so that every contact but
// the lowest is between two box faces. Things with a right answer whatever the time step:
//   - a stack set down at rest stays at rest: every cube carries its own weight on the one below (the net contact force
//     on each cube is its weight), none slides, none tilts, none is ever pulled;
//   - a cube set sliding on a box face slides Coulomb's distance, v^2 / (2 mu g), stays on the face and does not tilt,
//     as it does on the ground.
// The program only plays the scene and writes what each cube did, as whole numbers, in the contact rigs' format, so the
// same measuring programs read it. MuJoCo is z-up.
// usage: mjc_stack <out prefix> dt=<seconds> [n=N] [mass=KG] [radius=M] [mu=X] [shift=M] [base=M] [vx=V] [secs=S]
//          [lock=0|1] [integ=NAME] [cone=NAME] [iterations=N] [tolerance=X] [noslip=N] [impratio=X] [diagexact=1]
//   n       cubes in the stack (default 3); mass, radius: each cube's, kg and half-size in m (default 0.5, 0.05)
//   mu      friction of every geom (default 0.5)
//   shift   each cube's centre sits this far along x from the one below it (default 0: a straight stack)
//   base    0 (default): the stack stands on the ground plane; above 0: on a fixed box of this half-size whose top face
//           is at the ground's height, so the lowest contact is between two box faces too
//   vx      the top cube is set sliding along x at this speed (default 0: all at rest)
//   lock    0 (default): each cube on a free joint; 1: three slide joints each, so none can turn
//   integ, cone, iterations, tolerance, noslip, impratio: MuJoCo's own options; unset = MuJoCo's defaults
//   noslip_tolerance  MuJoCo's noslip_tolerance option; unset = MuJoCo's default (as before)
//   diagexact  1: MuJoCo's diagexact flag (the exact diagonal of the constraint inertia, in the current pose, in place
//           of the approximation frozen in the written pose); unset = MuJoCo's default (off)
//   contacts  a file: one line a contact a step, "<step> <geom 1> <geom 2> <position x y z, nm> <distance, nm> <normal
//           x y z, parts per billion>", the contacts the step was solved with (MuJoCo's d->contact after the step);
//           not listed in the STATS line; unset = none (as before)
// The cubes start touching: each lowest face exactly on the top face below it.
// writes, for cube k (1 the lowest), <out prefix>_<k>.txt: a header line "CONTACT dt_ns <n> h0_nm 0 vx0_ums <n>
//   mu_ppm <n> mass_g <n> steps <n>", then one line a step: "<step> <height of the cube's lowest face above the top of
//   what is below it, nm> <vx, um/s> <vz, um/s> <contact force up on the cube, mN> <contact force along x on it, mN>",
//   the state each step ended in, the forces summed over every contact on that cube (from below and from above);
//   and <out prefix>_<k>_tilt.txt in the joint rig's format: the same header, then one line a step: "<step> <the
//   cube's tilt from upright, micro-radians> <its angular speed, micro-radians a second> 0 0 0".
// prints one STATS line: the solver's iterations, the steps at the iteration limit, MuJoCo's warnings, the most
//   contacts on any step. Exit 0.
//   gsolref  T,D: every geom's solref, the contact's time constant (s) and damping ratio, set after the scene is loaded
//           as a model's own geom solref sets it; unset = the scene's own (as before)
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

#define MAXN 16

// gsolref=T,D: every geom's contact time constant and damping ratio (its solref), set after the scene is loaded, as a
// model's own geom solref sets them; two geoms with the same values give a contact those values
static int SetGeomSolref(mjModel* m, const char* v) {
  double tc = 0.0, dr = 0.0;
  if (sscanf(v, "%lf,%lf", &tc, &dr) != 2 || tc <= 0.0 || dr <= 0.0) { fprintf(stderr, "gsolref=T,D, both above 0\n"); return 1; }
  for (int g = 0; g < m->ngeom; ++g) { m->geom_solref[mjNREF * g] = tc; m->geom_solref[mjNREF * g + 1] = dr; }
  return 0;
}

int main(int argc, char** argv) {
  const char* gsolref = NULL;
  if (argc < 3) {
    fprintf(stderr, "usage: mjc_stack <out prefix> dt=<seconds> [n=] [mass=] [radius=] [mu=] [shift=] [base=] [vx=] "
                    "[secs=] [lock=] [integ=] [cone=] [iterations=] [tolerance=] [noslip=] [impratio=]\n");
    return 2;
  }
  double dt = 0.0, mass = 0.5, radius = 0.05, mu = 0.5, shift = 0.0, base = 0.0, vx = 0.0, secs = 1.0;
  int n = 3, lock = 0;
  const char *integ = NULL, *cone = NULL, *iterations = NULL, *tolerance = NULL, *noslip = NULL, *impratio = NULL,
             *nstol = NULL, *cpath = NULL;
  int diagexact = 0;
  char extra[512] = "";
  for (int i = 2; i < argc; ++i) {
    const char* v;
    const char* a = argv[i];
    int known = 1;
    if (Arg(a, "dt", &v)) dt = atof(v);
    else if (Arg(a, "n", &v)) n = atoi(v);
    else if (Arg(a, "mass", &v)) mass = atof(v);
    else if (Arg(a, "radius", &v)) radius = atof(v);
    else if (Arg(a, "mu", &v)) mu = atof(v);
    else if (Arg(a, "shift", &v)) shift = atof(v);
    else if (Arg(a, "base", &v)) base = atof(v);
    else if (Arg(a, "vx", &v)) vx = atof(v);
    else if (Arg(a, "secs", &v)) secs = atof(v);
    else if (Arg(a, "lock", &v)) lock = atoi(v);
    else if (Arg(a, "integ", &v)) integ = v;
    else if (Arg(a, "cone", &v)) cone = v;
    else if (Arg(a, "iterations", &v)) iterations = v;
    else if (Arg(a, "tolerance", &v)) tolerance = v;
    else if (Arg(a, "gsolref", &v)) gsolref = v;
    else if (Arg(a, "noslip", &v)) noslip = v;
    else if (Arg(a, "noslip_tolerance", &v)) nstol = v;
    else if (Arg(a, "impratio", &v)) impratio = v;
    else if (Arg(a, "diagexact", &v)) diagexact = atoi(v);
    else if (Arg(a, "contacts", &v)) cpath = v;
    else known = 0;
    if (!known) { fprintf(stderr, "mjc_stack: unknown setting %s\n", a); return 2; }
    if (strncmp(a, "dt=", 3) != 0 && strncmp(a, "contacts=", 9) != 0) {
      strncat(extra, " ", sizeof extra - strlen(extra) - 1);
      strncat(extra, a, sizeof extra - strlen(extra) - 1);
    }
  }
  if (dt <= 0.0) { fprintf(stderr, "mjc_stack: dt must be given\n"); return 2; }
  if (n < 1 || n > MAXN) { fprintf(stderr, "mjc_stack: n must be 1 to %d\n", MAXN); return 2; }

  char opt[640];
  snprintf(opt, sizeof opt, "timestep=\"%.17g\" gravity=\"0 0 -9.8\"%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", dt,
           integ ? " integrator=\"" : "", integ ? integ : "", integ ? "\"" : "",
           cone ? " cone=\"" : "", cone ? cone : "", cone ? "\"" : "",
           iterations ? " iterations=\"" : "", iterations ? iterations : "", iterations ? "\"" : "",
           tolerance ? " tolerance=\"" : "", tolerance ? tolerance : "", tolerance ? "\"" : "",
           noslip ? " noslip_iterations=\"" : "", noslip ? noslip : "", noslip ? "\"" : "",
           impratio ? " impratio=\"" : "", impratio ? impratio : "", impratio ? "\"" : "",
           nstol ? " noslip_tolerance=\"" : "", nstol ? nstol : "", nstol ? "\"" : "");
  static char xml[16384];
  int len = snprintf(xml, sizeof xml, "<mujoco model=\"stack\"><option %s%s<worldbody>", opt,
                     diagexact ? "><flag diagexact=\"enable\"/></option>" : "/>");
  if (base > 0.0)
    len += snprintf(xml + len, sizeof xml - len,
                    "<geom name=\"floor\" type=\"box\" pos=\"0 0 %.17g\" size=\"%.17g %.17g %.17g\" friction=\"%.17g 0.005 0.0001\"/>",
                    -base, base, base, base, mu);
  else
    len += snprintf(xml + len, sizeof xml - len,
                    "<geom name=\"floor\" type=\"plane\" size=\"0 0 1\" friction=\"%.17g 0.005 0.0001\"/>", mu);
  for (int k = 0; k < n; ++k) {
    char joints[256];
    if (lock) snprintf(joints, sizeof joints, "<joint type=\"slide\" axis=\"1 0 0\"/><joint type=\"slide\" axis=\"0 1 0\"/>"
                                               "<joint type=\"slide\" axis=\"0 0 1\"/>");
    else snprintf(joints, sizeof joints, "<freejoint/>");
    len += snprintf(xml + len, sizeof xml - len,
                    "<body name=\"c%d\" pos=\"%.17g 0 %.17g\">%s<geom name=\"g%d\" type=\"box\" size=\"%.17g %.17g %.17g\" "
                    "mass=\"%.17g\" friction=\"%.17g 0.005 0.0001\"/></body>",
                    k, shift * k, radius * (2 * k + 1), joints, k, radius, radius, radius, mass, mu);
  }
  len += snprintf(xml + len, sizeof xml - len, "</worldbody></mujoco>");
  if (len >= (int)sizeof xml) { fprintf(stderr, "mjc_stack: scene too long\n"); return 1; }
  mjVFS vfs;
  mj_defaultVFS(&vfs);
  if (mj_addBufferVFS(&vfs, "stack.xml", xml, (int)strlen(xml)) != 0) { fprintf(stderr, "mjc_stack: vfs\n"); return 1; }
  char err[1024] = "";
  mjModel* m = mj_loadXML("stack.xml", &vfs, err, sizeof err);
  mj_deleteVFS(&vfs);
  if (!m) { fprintf(stderr, "mjc_stack: %s\n", err); return 1; }
  if (gsolref && SetGeomSolref(m, gsolref)) return 2;
  mjData* d = mj_makeData(m);
  int body[MAXN], geom[MAXN], dof[MAXN];
  for (int k = 0; k < n; ++k) {
    char nm[16];
    snprintf(nm, sizeof nm, "c%d", k);
    body[k] = mj_name2id(m, mjOBJ_BODY, nm);
    snprintf(nm, sizeof nm, "g%d", k);
    geom[k] = mj_name2id(m, mjOBJ_GEOM, nm);
    dof[k] = m->body_dofadr[body[k]];
  }
  d->qvel[dof[n - 1]] = vx;  // the top cube's x: the free joint's linear x, or its x slide joint; the same first entry
  mj_forward(m, d);

  FILE* f[MAXN];
  FILE* t[MAXN];
  long const steps = (long)llround(secs / dt);
  for (int k = 0; k < n; ++k) {
    char path[1024];
    snprintf(path, sizeof path, "%s_%d.txt", argv[1], k + 1);
    f[k] = fopen(path, "w");
    snprintf(path, sizeof path, "%s_%d_tilt.txt", argv[1], k + 1);
    t[k] = fopen(path, "w");
    if (!f[k] || !t[k]) { fprintf(stderr, "mjc_stack: cannot write %s\n", path); return 1; }
    long long const v0 = (k == n - 1) ? Round(vx * 1e6) : 0;
    fprintf(f[k], "CONTACT dt_ns %lld h0_nm 0 vx0_ums %lld mu_ppm %lld mass_g %lld steps %ld\n", Round(dt * 1e9), v0,
            Round(mu * 1e6), Round(mass * 1e3), steps);
    fprintf(t[k], "CONTACT dt_ns %lld h0_nm 0 vx0_ums %lld mu_ppm %lld mass_g %lld steps %ld\n", Round(dt * 1e9), v0,
            Round(mu * 1e6), Round(mass * 1e3), steps);
  }
  FILE* cf = NULL;
  if (cpath) {
    cf = fopen(cpath, "w");
    if (!cf) { fprintf(stderr, "mjc_stack: cannot write %s\n", cpath); return 1; }
  }
  long atLimit = 0;
  int mostIters = 0, mostCon = 0;
  for (long i = 0; i < steps; ++i) {
    mj_step(m, d);
    if (cf) {
      for (int c = 0; c < d->ncon; ++c) {
        mjContact const* con = d->contact + c;
        fprintf(cf, "%ld %d %d %lld %lld %lld %lld %lld %lld %lld\n", i, con->geom[0], con->geom[1],
                Round(con->pos[0] * 1e9), Round(con->pos[1] * 1e9), Round(con->pos[2] * 1e9), Round(con->dist * 1e9),
                Round(con->frame[0] * 1e9), Round(con->frame[1] * 1e9), Round(con->frame[2] * 1e9));
      }
    }
    // the state the step ended in, as the other rigs report it (the next mj_step recomputes it anyway)
    mj_kinematics(m, d);
    int const it = d->solver_niter[0];
    if (it > mostIters) mostIters = it;
    if (it >= m->opt.iterations) ++atLimit;
    if (d->ncon > mostCon) mostCon = d->ncon;
    for (int k = 0; k < n; ++k) {
      double fw[3] = {0.0, 0.0, 0.0};
      for (int c = 0; c < d->ncon; ++c) {
        mjContact const* con = d->contact + c;
        if (con->geom[0] != geom[k] && con->geom[1] != geom[k]) continue;
        mjtNum cf[6];
        mj_contactForce(m, d, c, cf);
        double const s = (con->geom[1] == geom[k]) ? 1.0 : -1.0;
        for (int j = 0; j < 3; ++j)
          fw[j] += s * (cf[0] * con->frame[j] + cf[1] * con->frame[3 + j] + cf[2] * con->frame[6 + j]);
      }
      double const z = d->xpos[3 * body[k] + 2];
      double const below = (k == 0) ? 0.0 : d->xpos[3 * body[k - 1] + 2] + radius;
      double const* R = d->xmat + 9 * body[k];
      double const tilt = atan2(sqrt(R[2] * R[2] + R[5] * R[5]), R[8]);
      double spin = 0.0;
      if (!lock) {
        double const* w = d->qvel + dof[k] + 3;
        spin = sqrt(w[0] * w[0] + w[1] * w[1] + w[2] * w[2]);
      }
      fprintf(f[k], "%ld %lld %lld %lld %lld %lld\n", i, Round((z - radius - below) * 1e9), Round(d->qvel[dof[k]] * 1e6),
              Round(d->qvel[dof[k] + 2] * 1e6), Round(fw[2] * 1e3), Round(fw[0] * 1e3));
      fprintf(t[k], "%ld %lld %lld 0 0 0\n", i, Round(tilt * 1e6), Round(spin * 1e6));
    }
  }
  for (int k = 0; k < n; ++k) { fclose(f[k]); fclose(t[k]); }
  if (cf) fclose(cf);
  int warnings = 0;
  for (int w = 0; w < mjNWARNING; ++w) warnings += d->warning[w].number;
  printf("STATS stack dt %g n %d mass %g radius %g mu %g shift %g base %g vx %g lock %d steps %ld most_iterations %d "
         "at_iteration_limit %ld iteration_limit %d most_contacts %d warnings %d engine mujoco %s extra%s\n",
         dt, n, mass, radius, mu, shift, base, vx, lock, steps, mostIters, atLimit, m->opt.iterations, mostCon, warnings,
         mj_versionString(), extra[0] ? extra : " none");
  mj_deleteData(d);
  mj_deleteModel(m);
  return 0;
}
