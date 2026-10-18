// mjc_arm.c: a two-link arm whose tip, a ball, rests on or falls to the ground, written in any pose. MuJoCo computes
// some of its constants once, in the pose a scene is written in (qpos0): among them the diagonal approximation of each
// constraint's inverse inertia, which sets how soft a contact is (body_invweight0, engine_setconst.c, used by
// mj_diagApprox in engine_core_constraint.c). Physics has an answer that does not depend on how a scene is written: the
// same arm, in the same place, moving the same way, does the same thing whatever pose its file was written in. This rig
// plays one such scene and writes what the ball did, in the contact rigs' format, so the same measuring programs read
// it and two writings of one scene can be compared.
// The arm: a shoulder hinge fixed to the world, turning about +y (a positive angle turns the arm's +x down, toward -z),
// link 1 (a capsule of length len1, mass mass1), an elbow hinge at its end, also about +y, link 2 (a capsule of length
// len2, mass mass2), and at link 2's end a ball of radius rb and mass mb, the only geom that touches anything.
// usage: mjc_arm <out.txt> dt=<seconds> pose=<q1,q2> [pose0=<q1,q2>] [h0=M] [mu=X] [secs=S] [mass1=KG] [mass2=KG]
//          [mb=KG] [len1=M] [len2=M] [rb=M] [integ=NAME] [cone=NAME] [iterations=N] [tolerance=X] [noslip=N] [diagexact=1]
//          [elbowlimit=LO,HI] [jointfriction=NM] [tipconnect=1] [tipweld=1] [noslip_tolerance=X] [fricsolref=T,D]
//   pose    the joint angles the arm starts in, radians, at rest
//   pose0   the pose the scene is written in (unset: pose itself). The bodies are written turned by pose0's angles and
//           the joints start at pose - pose0, so the arm starts in the same place, at rest, either way
//   h0      the gap between the ball's lowest point and the ground at the start (default 0); the shoulder's height is
//           set from it
//   defaults: mass1 1, mass2 0.5, mb 0.2 kg; len1 0.3, len2 0.3, rb 0.03 m; mu 0.8; secs 1; gravity 9.8 m/s2 down
//   integ, cone, iterations, tolerance, noslip: MuJoCo's own options; unset = MuJoCo's defaults
//   diagexact  1: MuJoCo's diagexact flag (the exact diagonal of the constraint inertia, in the current pose, in place
//           of the approximation frozen in the written pose); unset = MuJoCo's default (off)
//   elbowlimit  the elbow's limits, as elbow angles of the arm itself (radians), so the same in every writing: the joint
//           is given MuJoCo's range LO - pose0 to HI - pose0, with MuJoCo's default soft limit; unset = no limit (as before)
//   jointfriction  MuJoCo's dry joint friction (frictionloss), N m, on both hinges; unset = none (as before)
//   noslip_tolerance, impratio  MuJoCo's noslip_tolerance and impratio options; unset = MuJoCo's defaults (as before)
//   fricsolref  the hinges' solreffriction, MuJoCo's reference for their dry friction rows, time constant and damping
//           ratio, given with jointfriction; unset = MuJoCo's default (as before)
//   trace   a file: one line a step, "<step> <the ball's contacts> <the slip of the ball's surface at its first contact,
//           along x and z, um/s> <link 2's spin about y, urad/s> <the shoulder's and the elbow's speeds, urad/s>", the
//           slip being the velocity of the ball's material point at the contact (the ground is still); unset = none
//   tipconnect  1: the ball's centre held to the point in the world where it starts, by MuJoCo's connect equality between
//           two sites (one on the arm, one in the world), so the scene is the same in every writing; unset = none (as before)
//   tipweld  1: link 2 held where it starts, in place and in orientation, by MuJoCo's weld equality between two sites: one
//           at the ball's centre on link 2, and one in the world at the point where the ball's centre starts, turned as
//           link 2 starts (the arm's own angles, so the same in every writing); MuJoCo aligns the two sites' frames.
//           Unset = none (as before); not with tipconnect
// writes <out.txt>: a header line "CONTACT dt_ns <n> h0_nm <n> vx0_ums 0 mu_ppm <n> mass_g <n> steps <n>" (mass_g the
//   ball's), then one line a step: "<step> <height of the ball's lowest point above the ground, nm> <the ball's speed
//   along x, um/s> <its speed along z, um/s> <contact force up on the ball, mN> <contact force along x on it, mN>", the
//   state each step ended in
// prints one STATS line: the solver's iterations, the steps at the iteration limit, MuJoCo's warnings, and, as context,
//   MuJoCo's frozen translational inverse weight of link 2 (body_invweight0, from the written pose) beside the same
//   quantity computed by MuJoCo's own formula in the pose the arm starts in. Exit 0.
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

static int Pair(const char* v, double* a, double* b) { return sscanf(v, "%lf,%lf", a, b) == 2; }

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
  if (argc < 4) {
    fprintf(stderr, "usage: mjc_arm <out.txt> dt=<seconds> pose=<q1,q2> [pose0=<q1,q2>] [h0=] [mu=] [secs=] [mass1=] "
                    "[mass2=] [mb=] [len1=] [len2=] [rb=] [integ=] [cone=] [iterations=] [tolerance=] [noslip=]\n");
    return 2;
  }
  double dt = 0.0, h0 = 0.0, mu = 0.8, secs = 1.0, mass1 = 1.0, mass2 = 0.5, mb = 0.2, len1 = 0.3, len2 = 0.3, rb = 0.03;
  double q1 = 0.0, q2 = 0.0, p1 = 0.0, p2 = 0.0;
  int havePose = 0, havePose0 = 0, haveLimit = 0;
  double lo = 0.0, hi = 0.0;
  const char *jfric = NULL, *nstol = NULL, *fsr = NULL, *trace = NULL, *impr = NULL;
  int tipconnect = 0, tipweld = 0;
  const char *integ = NULL, *cone = NULL, *iterations = NULL, *tolerance = NULL, *noslip = NULL;
  int diagexact = 0;
  char extra[512] = "";
  for (int i = 2; i < argc; ++i) {
    const char* v;
    const char* a = argv[i];
    int known = 1;
    if (Arg(a, "dt", &v)) dt = atof(v);
    else if (Arg(a, "pose", &v)) havePose = Pair(v, &q1, &q2);
    else if (Arg(a, "pose0", &v)) havePose0 = Pair(v, &p1, &p2);
    else if (Arg(a, "h0", &v)) h0 = atof(v);
    else if (Arg(a, "mu", &v)) mu = atof(v);
    else if (Arg(a, "secs", &v)) secs = atof(v);
    else if (Arg(a, "mass1", &v)) mass1 = atof(v);
    else if (Arg(a, "mass2", &v)) mass2 = atof(v);
    else if (Arg(a, "mb", &v)) mb = atof(v);
    else if (Arg(a, "len1", &v)) len1 = atof(v);
    else if (Arg(a, "len2", &v)) len2 = atof(v);
    else if (Arg(a, "rb", &v)) rb = atof(v);
    else if (Arg(a, "integ", &v)) integ = v;
    else if (Arg(a, "cone", &v)) cone = v;
    else if (Arg(a, "iterations", &v)) iterations = v;
    else if (Arg(a, "tolerance", &v)) tolerance = v;
    else if (Arg(a, "gsolref", &v)) gsolref = v;
    else if (Arg(a, "noslip", &v)) noslip = v;
    else if (Arg(a, "diagexact", &v)) diagexact = atoi(v);
    else if (Arg(a, "elbowlimit", &v)) haveLimit = Pair(v, &lo, &hi);
    else if (Arg(a, "jointfriction", &v)) jfric = v;
    else if (Arg(a, "noslip_tolerance", &v)) nstol = v;
    else if (Arg(a, "impratio", &v)) impr = v;
    else if (Arg(a, "fricsolref", &v)) fsr = v;
    else if (Arg(a, "trace", &v)) trace = v;
    else if (Arg(a, "tipconnect", &v)) tipconnect = atoi(v);
    else if (Arg(a, "tipweld", &v)) tipweld = atoi(v);
    else known = 0;
    if (!known) { fprintf(stderr, "mjc_arm: unknown setting %s\n", a); return 2; }
    if (strncmp(a, "dt=", 3) != 0) {
      strncat(extra, " ", sizeof extra - strlen(extra) - 1);
      strncat(extra, a, sizeof extra - strlen(extra) - 1);
    }
  }
  if (dt <= 0.0 || !havePose) { fprintf(stderr, "mjc_arm: dt and pose must be given\n"); return 2; }
  if (tipconnect && tipweld) { fprintf(stderr, "mjc_arm: tipconnect and tipweld are not played together\n"); return 2; }
  if (!havePose0) { p1 = q1; p2 = q2; }

  // the ball's centre below the shoulder in the starting pose, and the shoulder's height from it
  double const tipz = -(len1 * sin(q1) + len2 * sin(q1 + q2));
  double const shoulder = -tipz + rb + h0;

  char opt[640];
  snprintf(opt, sizeof opt, "timestep=\"%.17g\" gravity=\"0 0 -9.8\"%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", dt,
           integ ? " integrator=\"" : "", integ ? integ : "", integ ? "\"" : "",
           cone ? " cone=\"" : "", cone ? cone : "", cone ? "\"" : "",
           iterations ? " iterations=\"" : "", iterations ? iterations : "", iterations ? "\"" : "",
           tolerance ? " tolerance=\"" : "", tolerance ? tolerance : "", tolerance ? "\"" : "",
           noslip ? " noslip_iterations=\"" : "", noslip ? noslip : "", noslip ? "\"" : "",
           nstol ? " noslip_tolerance=\"" : "", nstol ? nstol : "", nstol ? "\"" : "",
           impr ? " impratio=\"" : "", impr ? impr : "", impr ? "\"" : "");
  char limit[128] = "";  // the elbow's range, only when asked for (the scene as before otherwise)
  if (haveLimit) snprintf(limit, sizeof limit, " limited=\"true\" range=\"%.17g %.17g\"", lo - p2, hi - p2);
  char jf[160] = "";  // both hinges' dry friction, and its reference, only when asked for
  if (jfric) snprintf(jf, sizeof jf, " frictionloss=\"%s\"", jfric);
  if (fsr) {
    double t = 0.0, d = 0.0;
    if (!jfric || !Pair(fsr, &t, &d)) { fprintf(stderr, "mjc_arm: fricsolref=T,D, with jointfriction\n"); return 2; }
    size_t const n = strlen(jf);
    snprintf(jf + n, sizeof jf - n, " solreffriction=\"%.17g %.17g\"", t, d);
  }
  char tipsite[128] = "", anchor[192] = "", equality[128] = "";  // only when asked for (the scene as before otherwise)
  if (tipconnect) {
    snprintf(tipsite, sizeof tipsite, "<site name=\"tip\" pos=\"%.17g 0 0\"/>", len2);
    snprintf(anchor, sizeof anchor, "<site name=\"anchor\" pos=\"%.17g 0 %.17g\"/>", len1 * cos(q1) + len2 * cos(q1 + q2), shoulder + tipz);
    snprintf(equality, sizeof equality, "<equality><connect site1=\"tip\" site2=\"anchor\"/></equality>");
  }
  if (tipweld) {
    snprintf(tipsite, sizeof tipsite, "<site name=\"tip\" pos=\"%.17g 0 0\"/>", len2);
    snprintf(anchor, sizeof anchor, "<site name=\"anchor\" pos=\"%.17g 0 %.17g\" axisangle=\"0 1 0 %.17g\"/>",
             len1 * cos(q1) + len2 * cos(q1 + q2), shoulder + tipz, q1 + q2);
    snprintf(equality, sizeof equality, "<equality><weld site1=\"tip\" site2=\"anchor\"/></equality>");
  }
  char xml[4096];
  snprintf(xml, sizeof xml,
           "<mujoco model=\"arm\"><compiler angle=\"radian\"/><option %s%s<worldbody>"
           "<geom name=\"floor\" type=\"plane\" size=\"0 0 1\" friction=\"%.17g 0.005 0.0001\"/>"
           "<body name=\"link1\" pos=\"0 0 %.17g\" axisangle=\"0 1 0 %.17g\"><joint name=\"shoulder\" type=\"hinge\" axis=\"0 1 0\"%s/>"
           "<geom type=\"capsule\" fromto=\"0 0 0 %.17g 0 0\" size=\"0.02\" mass=\"%.17g\" contype=\"0\" conaffinity=\"0\"/>"
           "<body name=\"link2\" pos=\"%.17g 0 0\" axisangle=\"0 1 0 %.17g\"><joint name=\"elbow\" type=\"hinge\" axis=\"0 1 0\"%s%s/>"
           "<geom type=\"capsule\" fromto=\"0 0 0 %.17g 0 0\" size=\"0.02\" mass=\"%.17g\" contype=\"0\" conaffinity=\"0\"/>"
           "<geom name=\"ball\" type=\"sphere\" pos=\"%.17g 0 0\" size=\"%.17g\" mass=\"%.17g\" friction=\"%.17g 0.005 0.0001\"/>"
           "%s</body></body>%s</worldbody>%s</mujoco>",
           opt, diagexact ? "><flag diagexact=\"enable\"/></option>" : "/>", mu, shoulder, p1, jf, len1, mass1, len1, p2, limit, jf,
           len2, mass2,
           len2, rb, mb, mu, tipsite, anchor, equality);
  mjVFS vfs;
  mj_defaultVFS(&vfs);
  if (mj_addBufferVFS(&vfs, "arm.xml", xml, (int)strlen(xml)) != 0) { fprintf(stderr, "mjc_arm: vfs\n"); return 1; }
  char err[1024] = "";
  mjModel* m = mj_loadXML("arm.xml", &vfs, err, sizeof err);
  mj_deleteVFS(&vfs);
  if (!m) { fprintf(stderr, "mjc_arm: %s\n", err); return 1; }
  if (gsolref && SetGeomSolref(m, gsolref)) return 2;
  if (m->nv != 2) { fprintf(stderr, "mjc_arm: expected two degrees of freedom, found %d\n", (int)m->nv); return 1; }
  mjData* d = mj_makeData(m);
  int const link2 = mj_name2id(m, mjOBJ_BODY, "link2");
  int const ball = mj_name2id(m, mjOBJ_GEOM, "ball");
  d->qpos[0] = q1 - p1;
  d->qpos[1] = q2 - p2;
  mj_forward(m, d);

  // context: link 2's translational inverse weight by MuJoCo's own formula (engine_setconst.c), frozen at the written
  // pose, and computed in the pose the arm starts in
  double atPose = 0.0;
  {
    mjtNum jac[6 * 2], tmp[6 * 2], A[36];
    mj_jacBodyCom(m, d, jac, jac + 3 * m->nv, link2);
    mj_solveM(m, d, tmp, jac, 6);
    mju_mulMatMatT(A, jac, tmp, 6, m->nv, 6);
    atPose = (A[0] + A[7] + A[14]) / 3;
  }
  double const frozen = m->body_invweight0[2 * link2];

  FILE* f = fopen(argv[1], "w");
  if (!f) { fprintf(stderr, "mjc_arm: cannot write %s\n", argv[1]); return 1; }
  long const steps = (long)llround(secs / dt);
  fprintf(f, "CONTACT dt_ns %lld h0_nm %lld vx0_ums 0 mu_ppm %lld mass_g %lld steps %ld\n", Round(dt * 1e9),
          Round(h0 * 1e9), Round(mu * 1e6), Round(mb * 1e3), steps);
  FILE* tf = NULL;
  if (trace) {
    tf = fopen(trace, "w");
    if (!tf) { fprintf(stderr, "mjc_arm: cannot write %s\n", trace); return 1; }
  }
  long atLimit = 0;
  int mostIters = 0;
  for (long i = 0; i < steps; ++i) {
    mj_step(m, d);
    // the state the step ended in, as the other rigs report it (the next mj_step recomputes these anyway)
    mj_kinematics(m, d);
    mj_comPos(m, d);
    mj_comVel(m, d);
    int const it = d->solver_niter[0];
    if (it > mostIters) mostIters = it;
    if (it >= m->opt.iterations) ++atLimit;
    double fw[3] = {0.0, 0.0, 0.0};
    for (int c = 0; c < d->ncon; ++c) {
      mjContact const* con = d->contact + c;
      if (con->geom[0] != ball && con->geom[1] != ball) continue;
      mjtNum cf[6];
      mj_contactForce(m, d, c, cf);
      double const s = (con->geom[1] == ball) ? 1.0 : -1.0;
      for (int j = 0; j < 3; ++j)
        fw[j] += s * (cf[0] * con->frame[j] + cf[1] * con->frame[3 + j] + cf[2] * con->frame[6 + j]);
    }
    mjtNum v[6];  // (angular, linear) at the ball's centre, world orientation
    mj_objectVelocity(m, d, mjOBJ_GEOM, ball, v, 0);
    double const z = d->geom_xpos[3 * ball + 2];
    fprintf(f, "%ld %lld %lld %lld %lld %lld\n", i, Round((z - rb) * 1e9), Round(v[3] * 1e6), Round(v[5] * 1e6),
            Round(fw[2] * 1e3), Round(fw[0] * 1e3));
    if (tf) {
      int nball = 0;
      double slip[3] = {0.0, 0.0, 0.0};
      for (int c = 0; c < d->ncon; ++c) {
        mjContact const* con = d->contact + c;
        if (con->geom[0] != ball && con->geom[1] != ball) continue;
        if (nball++ > 0) continue;
        double r[3];  // from the ball's centre to the contact point
        for (int j = 0; j < 3; ++j) r[j] = con->pos[j] - d->geom_xpos[3 * ball + j];
        slip[0] = v[3] + v[1] * r[2] - v[2] * r[1];
        slip[1] = v[4] + v[2] * r[0] - v[0] * r[2];
        slip[2] = v[5] + v[0] * r[1] - v[1] * r[0];
      }
      fprintf(tf, "%ld %d %lld %lld %lld %lld %lld\n", i, nball, Round(slip[0] * 1e6), Round(slip[2] * 1e6),
              Round(v[1] * 1e6), Round(d->qvel[0] * 1e6), Round(d->qvel[1] * 1e6));
    }
  }
  fclose(f);
  if (tf) fclose(tf);
  int warnings = 0;
  for (int w = 0; w < mjNWARNING; ++w) warnings += d->warning[w].number;
  printf("STATS arm dt %g pose %g,%g pose0 %g,%g h0 %g shoulder %.9g steps %ld most_iterations %d at_iteration_limit %ld "
         "iteration_limit %d warnings %d invweight0_link2 %.9g invweight_link2_at_start %.9g engine mujoco %s extra%s\n",
         dt, q1, q2, p1, p2, h0, shoulder, steps, mostIters, atLimit, m->opt.iterations, warnings, frozen, atPose,
         mj_versionString(), extra[0] ? extra : " none");
  mj_deleteData(d);
  mj_deleteModel(m);
  return 0;
}
