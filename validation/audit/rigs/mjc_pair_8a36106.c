// mjc_pair.c: the smallest scene with contact between two moving bodies, matching the first deep dive's sdx_pair rig
// scene for scene and column for column, so the same measuring programs read it: a large cube A and a small cube B.
// Two layouts:
//   stack  A rests on the ground and B rests on top of A, under gravity
//   side   no ground and no gravity; B is beside A and moves towards it along x
// Rotation is held fixed on both (three slide joints each), so what passes between them is a force along the line of
// contact and friction across it and nothing else. What has a right answer whatever the time step:
//   - whatever B does to A, A does to B: with nothing else pushing along x, the total momentum along x of the two
//     cubes never changes;
//   - friction between them obeys Coulomb's law: B rides on A when A is pushed gently, and slips at the friction
//     limit when A is pushed hard.
// The friction of each contact is set on the contact itself (MuJoCo's explicit contact pairs): between A and B `mu`,
// between the ground and either cube `mug`, so the ground can be frictionless while the cubes are not, as in sdx_pair.
// The program only plays the scene and writes what each cube did at every step, as whole numbers. MuJoCo is z-up.
// usage: mjc_pair <out prefix> dt=<seconds> layout=stack|side [setting=value ...]
//   massa, ra    kg and half-size in metres of A (default 2, 0.1); massb, rb of B (default 0.5, 0.03)
//   mu           Coulomb friction between A and B (default 0); mug between the ground and a cube (default 0)
//   vxa, vxb     speeds along x at release, m/s (default 0, 0)
//   gap          side: the distance between the two facing faces at release, metres (default 0.02)
//   ha, hb       stack: the height of A's lowest face above the ground, and of B's above A's top (default 0, 0)
//   pusha, pushb a constant force along x on A, on B, newtons, from the time `pushat` on (default 0, 0)
//   pushat       seconds (default 0); secs: how long to play (default 1)
//   integ, cone, iterations, tolerance, noslip, impratio: MuJoCo's own options; unset = MuJoCo's defaults
// writes <out prefix>_a.txt and <out prefix>_b.txt, each: a header line "CONTACT dt_ns <n> h0_nm <n> vx0_ums <n>
//   mu_ppm <n> mass_g <n> steps <n>", then one line a step: "<step> <place, nm> <vx, um/s> <vz, um/s> <contact force
//   up, mN> <contact force along x, mN>", the state each step ended in. The place is, stack: for A the height of its
//   lowest face above the ground, for B the height of its lowest face above A's top; side: for A its centre along x,
//   for B the distance between the two facing faces. The contact force is the sum over every contact on that cube.
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

static void ContactForce(mjModel const* m, mjData const* d, int geom, double fw[3]) {
  // the contact force on one geom, in world coordinates: each contact's force in its own frame, whose normal points
  // from geom1 to geom2, acts on geom2 and, opposite, on geom1
  fw[0] = fw[1] = fw[2] = 0.0;
  for (int c = 0; c < d->ncon; ++c) {
    mjContact const* con = d->contact + c;
    if (con->geom[0] != geom && con->geom[1] != geom) continue;
    mjtNum cf[6];
    mj_contactForce(m, d, c, cf);
    double const s = (con->geom[1] == geom) ? 1.0 : -1.0;
    for (int j = 0; j < 3; ++j)
      fw[j] += s * (cf[0] * con->frame[j] + cf[1] * con->frame[3 + j] + cf[2] * con->frame[6 + j]);
  }
}

int main(int argc, char** argv) {
  if (argc < 4) {
    fprintf(stderr, "usage: mjc_pair <out prefix> dt=<seconds> layout=stack|side [massa=] [ra=] [massb=] [rb=] [mu=] "
                    "[mug=] [vxa=] [vxb=] [gap=] [ha=] [hb=] [pusha=] [pushb=] [pushat=] [secs=] [integ=] [cone=] "
                    "[iterations=] [tolerance=] [noslip=] [impratio=]\n");
    return 2;
  }
  double dt = 0.0, massA = 2.0, rA = 0.1, massB = 0.5, rB = 0.03, mu = 0.0, mug = 0.0, vxa = 0.0, vxb = 0.0;
  double gap = 0.02, ha = 0.0, hb = 0.0, pushA = 0.0, pushB = 0.0, pushAt = 0.0, secs = 1.0;
  int stack = -1;
  const char *integ = NULL, *cone = NULL, *iterations = NULL, *tolerance = NULL, *noslip = NULL, *impratio = NULL;
  char extra[512] = "";
  for (int i = 2; i < argc; ++i) {
    const char* v;
    const char* a = argv[i];
    int known = 1, option = 0;
    if (Arg(a, "dt", &v)) dt = atof(v);
    else if (Arg(a, "layout", &v)) stack = strcmp(v, "stack") == 0 ? 1 : (strcmp(v, "side") == 0 ? 0 : -1);
    else if (Arg(a, "massa", &v)) massA = atof(v);
    else if (Arg(a, "ra", &v)) rA = atof(v);
    else if (Arg(a, "massb", &v)) massB = atof(v);
    else if (Arg(a, "rb", &v)) rB = atof(v);
    else if (Arg(a, "mu", &v)) mu = atof(v);
    else if (Arg(a, "mug", &v)) mug = atof(v);
    else if (Arg(a, "vxa", &v)) vxa = atof(v);
    else if (Arg(a, "vxb", &v)) vxb = atof(v);
    else if (Arg(a, "gap", &v)) gap = atof(v);
    else if (Arg(a, "ha", &v)) ha = atof(v);
    else if (Arg(a, "hb", &v)) hb = atof(v);
    else if (Arg(a, "pusha", &v)) pushA = atof(v);
    else if (Arg(a, "pushb", &v)) pushB = atof(v);
    else if (Arg(a, "pushat", &v)) pushAt = atof(v);
    else if (Arg(a, "secs", &v)) secs = atof(v);
    else if (Arg(a, "integ", &v)) { integ = v; option = 1; }
    else if (Arg(a, "cone", &v)) { cone = v; option = 1; }
    else if (Arg(a, "iterations", &v)) { iterations = v; option = 1; }
    else if (Arg(a, "tolerance", &v)) { tolerance = v; option = 1; }
    else if (Arg(a, "noslip", &v)) { noslip = v; option = 1; }
    else if (Arg(a, "impratio", &v)) { impratio = v; option = 1; }
    else known = 0;
    if (!known) { fprintf(stderr, "mjc_pair: unknown setting %s\n", a); return 2; }
    if (option) { strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
  }
  if (dt <= 0.0) { fprintf(stderr, "mjc_pair: dt must be given\n"); return 2; }
  if (stack < 0) { fprintf(stderr, "mjc_pair: layout must be stack or side\n"); return 2; }

  char opt[512];
  snprintf(opt, sizeof opt, "timestep=\"%.17g\" gravity=\"0 0 %s\"%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", dt,
           stack ? "-9.8" : "0",
           integ ? " integrator=\"" : "", integ ? integ : "", integ ? "\"" : "",
           cone ? " cone=\"" : "", cone ? cone : "", cone ? "\"" : "",
           iterations ? " iterations=\"" : "", iterations ? iterations : "", iterations ? "\"" : "",
           tolerance ? " tolerance=\"" : "", tolerance ? tolerance : "", tolerance ? "\"" : "",
           noslip ? " noslip_iterations=\"" : "", noslip ? noslip : "", noslip ? "\"" : "",
           impratio ? " impratio=\"" : "", impratio ? impratio : "", impratio ? "\"" : "");
  // the cubes' places at release: stack, A on the ground (ha above it) and B on A (hb above it); side, B to A's -x
  double const ax = 0.0, az = stack ? rA + ha : 0.0;
  double const bx = stack ? 0.0 : -(rA + rB + gap), bz = stack ? 2.0 * rA + ha + hb + rB : 0.0;
  char const* slides = "<joint type=\"slide\" axis=\"1 0 0\"/><joint type=\"slide\" axis=\"0 1 0\"/>"
                       "<joint type=\"slide\" axis=\"0 0 1\"/>";
  // the ground's pairs, only in the stack layout, with the ground's own friction
  char ground[512] = "";
  if (stack)
    snprintf(ground, sizeof ground,
             "<pair geom1=\"floor\" geom2=\"a\" condim=\"3\" friction=\"%.17g %.17g 0.005 0.0001 0.0001\"/>"
             "<pair geom1=\"floor\" geom2=\"b\" condim=\"3\" friction=\"%.17g %.17g 0.005 0.0001 0.0001\"/>",
             mug, mug, mug, mug);
  char xml[8192];
  snprintf(xml, sizeof xml,
           "<mujoco model=\"pair\"><option %s/><worldbody>"
           "%s"
           "<body name=\"a\" pos=\"%.17g 0 %.17g\">%s<geom name=\"a\" type=\"box\" size=\"%.17g %.17g %.17g\" "
           "mass=\"%.17g\" contype=\"0\" conaffinity=\"0\"/></body>"
           "<body name=\"b\" pos=\"%.17g 0 %.17g\">%s<geom name=\"b\" type=\"box\" size=\"%.17g %.17g %.17g\" "
           "mass=\"%.17g\" contype=\"0\" conaffinity=\"0\"/></body>"
           "</worldbody><contact>"
           "<pair geom1=\"a\" geom2=\"b\" condim=\"3\" friction=\"%.17g %.17g 0.005 0.0001 0.0001\"/>"
           "%s"
           "</contact></mujoco>",
           opt,
           stack ? "<geom name=\"floor\" type=\"plane\" size=\"0 0 1\" contype=\"0\" conaffinity=\"0\"/>" : "",
           ax, az, slides, rA, rA, rA, massA, bx, bz, slides, rB, rB, rB, massB, mu, mu, ground);
  mjVFS vfs;
  mj_defaultVFS(&vfs);
  if (mj_addBufferVFS(&vfs, "pair.xml", xml, (int)strlen(xml)) != 0) { fprintf(stderr, "mjc_pair: vfs\n"); return 1; }
  char err[1024] = "";
  mjModel* m = mj_loadXML("pair.xml", &vfs, err, sizeof err);
  mj_deleteVFS(&vfs);
  if (!m) { fprintf(stderr, "mjc_pair: %s\n", err); return 1; }
  mjData* d = mj_makeData(m);
  int const bodyA = mj_name2id(m, mjOBJ_BODY, "a"), bodyB = mj_name2id(m, mjOBJ_BODY, "b");
  int const geomA = mj_name2id(m, mjOBJ_GEOM, "a"), geomB = mj_name2id(m, mjOBJ_GEOM, "b");
  int const va0 = m->jnt_dofadr[m->body_jntadr[bodyA]], vb0 = m->jnt_dofadr[m->body_jntadr[bodyB]];
  d->qvel[va0] = vxa;  // each body's first joint is its x slide
  d->qvel[vb0] = vxb;
  mj_forward(m, d);

  char name[1024];
  snprintf(name, sizeof name, "%s_a.txt", argv[1]);
  FILE* fa = fopen(name, "w");
  snprintf(name, sizeof name, "%s_b.txt", argv[1]);
  FILE* fb = fopen(name, "w");
  if (!fa || !fb) { fprintf(stderr, "mjc_pair: cannot write %s\n", argv[1]); return 1; }
  long const steps = (long)llround(secs / dt);
  fprintf(fa, "CONTACT dt_ns %lld h0_nm %lld vx0_ums %lld mu_ppm %lld mass_g %lld steps %ld\n", Round(dt * 1e9),
          Round(ha * 1e9), Round(vxa * 1e6), Round(mu * 1e6), Round(massA * 1e3), steps);
  fprintf(fb, "CONTACT dt_ns %lld h0_nm %lld vx0_ums %lld mu_ppm %lld mass_g %lld steps %ld\n", Round(dt * 1e9),
          Round((stack ? hb : gap) * 1e9), Round(vxb * 1e6), Round(mu * 1e6), Round(massB * 1e3), steps);
  long atLimit = 0;
  int mostIters = 0;
  for (long i = 0; i < steps; ++i) {
    int const on = (pushA != 0.0 || pushB != 0.0) && ((double)i + 0.5) * dt >= pushAt;
    d->xfrc_applied[6 * bodyA] = on ? pushA : 0.0;
    d->xfrc_applied[6 * bodyB] = on ? pushB : 0.0;
    mj_step(m, d);
    mj_kinematics(m, d);  // the positions of the state the step ended in (mj_step leaves them at its start)
    int const it = d->solver_niter[0];
    if (it > mostIters) mostIters = it;
    if (it >= m->opt.iterations) ++atLimit;
    double ca[3], cb[3];
    ContactForce(m, d, geomA, ca);
    ContactForce(m, d, geomB, cb);
    double const* pa = d->xpos + 3 * bodyA;
    double const* pb = d->xpos + 3 * bodyB;
    double const placeA = stack ? pa[2] - rA : pa[0];
    double const placeB = stack ? (pb[2] - rB) - (pa[2] + rA) : (pa[0] - rA) - (pb[0] + rB);
    fprintf(fa, "%ld %lld %lld %lld %lld %lld\n", i, Round(placeA * 1e9), Round(d->qvel[va0] * 1e6),
            Round(d->qvel[va0 + 2] * 1e6), Round(ca[2] * 1e3), Round(ca[0] * 1e3));
    fprintf(fb, "%ld %lld %lld %lld %lld %lld\n", i, Round(placeB * 1e9), Round(d->qvel[vb0] * 1e6),
            Round(d->qvel[vb0 + 2] * 1e6), Round(cb[2] * 1e3), Round(cb[0] * 1e3));
  }
  fclose(fa);
  fclose(fb);
  int warnings = 0;
  for (int w = 0; w < mjNWARNING; ++w) warnings += d->warning[w].number;
  printf("STATS pair dt %g layout %s massa %g ra %g massb %g rb %g mu %g mug %g steps %ld most_iterations %d "
         "at_iteration_limit %ld iteration_limit %d warnings %d engine mujoco %s extra%s\n",
         dt, stack ? "stack" : "side", massA, rA, massB, rB, mu, mug, steps, mostIters, atLimit, m->opt.iterations,
         warnings, mj_versionString(), extra[0] ? extra : " none");
  mj_deleteData(d);
  mj_deleteModel(m);
  return 0;
}
