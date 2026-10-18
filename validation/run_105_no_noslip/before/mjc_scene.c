// mjc_scene.c: the scene rig for MuJoCo, the adapter between Senua AI and the engine under test for a scene someone
// else wrote, such as the demos shipped with a pull request. It plays the scene file as written and writes one body's
// motion along a given direction, in the format of the contact rig (mjc_contact), so the same measuring programs read
// it unchanged. Only the options a setting names are changed, after the scene is loaded; nothing else is.
// usage: mjc_scene <out.txt> scene=<file.xml> body=<name> axis=X,Y,Z [secs=S] [noslip=N] [cone=pyramidal|elliptic]
//          [impratio=X] [key=N]
//   scene     the scene file, played with its own time step and options
//   body      the body whose motion is written
//   axis      the direction it is read along (normalised by the rig), for example down a ramp or down under gravity
//   secs      how long to play (default 6 s)
//   noslip, cone, impratio, noslip_tolerance: MuJoCo's own options, set on the loaded scene; unset = the scene's own
//   key       start from the scene's keyframe N (mj_resetDataKeyframe), as the scene's own tests do; unset = qpos0
// writes <out.txt>: a header line "CONTACT dt_ns <n> h0_nm 0 vx0_ums 0 mu_ppm 0 mass_g <n> steps <n>", then one line a
//   step: "<step> <how far the body has moved along the axis since the start, nm> <its speed along the axis over the
//   step, um/s> 0 0 0" (the speed is the step's displacement over the step, from the positions the step ended in)
// prints one STATS line: the solver's iterations, the steps at the iteration limit, MuJoCo's warnings. Exit 0.
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
    fprintf(stderr, "usage: mjc_scene <out.txt> scene=<file.xml> body=<name> axis=X,Y,Z [secs=S] [noslip=N] "
                    "[cone=pyramidal|elliptic] [impratio=X]\n");
    return 2;
  }
  const char *scene = NULL, *bodyName = NULL, *noslip = NULL, *cone = NULL, *impratio = NULL, *key = NULL, *nstol = NULL;
  double ax[3] = {0.0, 0.0, 0.0}, secs = 6.0;
  int haveAxis = 0;
  char extra[512] = "";
  for (int i = 2; i < argc; ++i) {
    const char* v;
    const char* a = argv[i];
    if (Arg(a, "scene", &v)) scene = v;
    else if (Arg(a, "body", &v)) bodyName = v;
    else if (Arg(a, "axis", &v)) {
      if (sscanf(v, "%lf,%lf,%lf", &ax[0], &ax[1], &ax[2]) != 3) { fprintf(stderr, "mjc_scene: axis=X,Y,Z\n"); return 2; }
      haveAxis = 1;
    }
    else if (Arg(a, "secs", &v)) secs = atof(v);
    else if (Arg(a, "gsolref", &v)) gsolref = v;
    else if (Arg(a, "noslip", &v)) { noslip = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "noslip_tolerance", &v)) { nstol = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "cone", &v)) { cone = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "key", &v)) { key = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "impratio", &v)) { impratio = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else { fprintf(stderr, "mjc_scene: unknown setting %s\n", a); return 2; }
  }
  if (!scene || !bodyName || !haveAxis) { fprintf(stderr, "mjc_scene: scene, body and axis must be given\n"); return 2; }
  double const an = sqrt(ax[0] * ax[0] + ax[1] * ax[1] + ax[2] * ax[2]);
  if (an <= 0.0) { fprintf(stderr, "mjc_scene: the axis must not be zero\n"); return 2; }
  for (int j = 0; j < 3; ++j) ax[j] /= an;

  char err[1024] = "";
  mjModel* m = mj_loadXML(scene, NULL, err, sizeof err);
  if (!m) { fprintf(stderr, "mjc_scene: %s\n", err); return 1; }
  if (gsolref && SetGeomSolref(m, gsolref)) return 2;
  if (noslip) m->opt.noslip_iterations = atoi(noslip);
  if (nstol) m->opt.noslip_tolerance = atof(nstol);
  if (cone) {
    if (strcmp(cone, "elliptic") == 0) m->opt.cone = mjCONE_ELLIPTIC;
    else if (strcmp(cone, "pyramidal") == 0) m->opt.cone = mjCONE_PYRAMIDAL;
    else { fprintf(stderr, "mjc_scene: cone=pyramidal|elliptic\n"); return 2; }
  }
  if (impratio) m->opt.impratio = atof(impratio);
  int const body = mj_name2id(m, mjOBJ_BODY, bodyName);
  if (body < 0) { fprintf(stderr, "mjc_scene: no body %s\n", bodyName); return 1; }
  mjData* d = mj_makeData(m);
  if (key) {
    int const k = atoi(key);
    if (k < 0 || k >= m->nkey) { fprintf(stderr, "mjc_scene: no keyframe %s\n", key); return 1; }
    mj_resetDataKeyframe(m, d, k);
  }
  mj_forward(m, d);
  double p0[3], prev[3];
  for (int j = 0; j < 3; ++j) { p0[j] = d->xpos[3 * body + j]; prev[j] = p0[j]; }

  FILE* f = fopen(argv[1], "w");
  if (!f) { fprintf(stderr, "mjc_scene: cannot write %s\n", argv[1]); return 1; }
  double const dt = m->opt.timestep;
  long const steps = (long)llround(secs / dt);
  fprintf(f, "CONTACT dt_ns %lld h0_nm 0 vx0_ums 0 mu_ppm 0 mass_g %lld steps %ld\n", Round(dt * 1e9),
          Round(m->body_mass[body] * 1e3), steps);
  long atLimit = 0;
  int mostIters = 0;
  for (long i = 0; i < steps; ++i) {
    mj_step(m, d);
    mj_kinematics(m, d);  // the positions the step ended in, as the other rigs report
    int const it = d->solver_niter[0];
    if (it > mostIters) mostIters = it;
    if (it >= m->opt.iterations) ++atLimit;
    double moved = 0.0, step = 0.0;
    for (int j = 0; j < 3; ++j) {
      double const p = d->xpos[3 * body + j];
      moved += (p - p0[j]) * ax[j];
      step += (p - prev[j]) * ax[j];
      prev[j] = p;
    }
    fprintf(f, "%ld %lld %lld 0 0 0\n", i, Round(moved * 1e9), Round(step / dt * 1e6));
  }
  fclose(f);
  int warnings = 0;
  for (int w = 0; w < mjNWARNING; ++w) warnings += d->warning[w].number;
  printf("STATS scene %s body %s dt %g steps %ld most_iterations %d at_iteration_limit %ld iteration_limit %d "
         "warnings %d engine mujoco %s extra%s\n",
         scene, bodyName, dt, steps, mostIters, atLimit, m->opt.iterations, warnings, mj_versionString(),
         extra[0] ? extra : " none");
  mj_deleteData(d);
  mj_deleteModel(m);
  return 0;
}
