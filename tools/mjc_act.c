// mjc_act.c: the actuator and tendon rig for MuJoCo. The one-joint rig's arm (mjc_joint: a cube of half-size 0.05 m and
// 1 kg whose centre is 0.5 m from a hinge about -y, so a positive angle lifts it), driven by one of MuJoCo's actuators or
// held by one of its tendons, with nothing touching it. It plays the scene file it writes as written and records the
// joints and the actuator, so the same scene can be played on any MuJoCo release and the files compared. Things with a
// right answer: a position servo comes to rest where its spring balances gravity, kp (target - q) = m g arm cos q; a
// velocity servo with no load turns at its target speed; a motor's control is clipped to its range, and it turns the arm
// at gear x control / inertia; two arms coupled by a fixed tendon spring keep their summed momentum.
// usage: mjc_act <out.txt> dt=<seconds> scene=<name> [kp=] [kv=] [ctrl=] [angle0=] [stiffness=] [gravity=0|1] [secs=]
//          [integ=NAME]
//   scene   position: MuJoCo's position actuator (kp, kv) to the target angle ctrl, under gravity
//           velocity: its velocity actuator (kv) to the target speed ctrl, no gravity
//           motor: a motor of gear 2, its control range -1 to 1, given ctrl, no gravity
//           filter: a general actuator with first-order activation (time constant 0.05 s), gain kp, bias -kp q - kv qdot,
//             to the target angle ctrl, under gravity
//           damper: MuJoCo's damper actuator (kv), control ctrl, the arm released level under gravity
//           fixed: a second arm on its own hinge, the two coupled by a fixed tendon (q1 - q2) with a spring of
//             stiffness, released at angle0 and 0, no gravity, no actuator
//           spatial: a spatial tendon from a point 0.5 m above the arm's tip to the tip, its spring of stiffness and rest
//             length 0.3 m holding the arm up against gravity, no actuator
//           muscle: MuJoCo's muscle actuator on that spatial tendon (no spring), control ctrl, under gravity
//   kp, kv, ctrl, angle0, stiffness: as each scene says; defaults kp 50, kv 5, ctrl 0.5 (velocity 1, motor 3, damper 1),
//           angle0 0 (fixed 0.5), stiffness 20 (spatial 100)
//   gravity  overrides the scene's; secs how long to play (default 2); integ MuJoCo's integrator (unset: its default)
// writes <out.txt>: a header line "CONTACT dt_ns <n> h0_nm 0 vx0_ums 0 mu_ppm 0 mass_g 1000 steps <n>", then one line a
//   step: "<step> <joint angle, urad> <joint speed, urad/s> <second joint's angle, urad> <its speed, urad/s> <the
//   actuator's force, micro-N m, or with no actuator the tendon's length, um>", the state the step ended in
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
  if (argc < 4) {
    fprintf(stderr, "usage: mjc_act <out.txt> dt=<seconds> scene=<name> [kp=] [kv=] [ctrl=] [angle0=] [stiffness=] "
                    "[gravity=0|1] [secs=] [integ=]\n");
    return 2;
  }
  double dt = 0.0, secs = 2.0;
  const char *scene = NULL, *integ = NULL, *kpS = NULL, *kvS = NULL, *ctrlS = NULL, *angS = NULL, *stS = NULL, *gS = NULL;
  char extra[512] = "";
  for (int i = 2; i < argc; ++i) {
    const char* v;
    const char* a = argv[i];
    int known = 1;
    if (Arg(a, "dt", &v)) dt = atof(v);
    else if (Arg(a, "scene", &v)) scene = v;
    else if (Arg(a, "kp", &v)) kpS = v;
    else if (Arg(a, "kv", &v)) kvS = v;
    else if (Arg(a, "ctrl", &v)) ctrlS = v;
    else if (Arg(a, "angle0", &v)) angS = v;
    else if (Arg(a, "stiffness", &v)) stS = v;
    else if (Arg(a, "gravity", &v)) gS = v;
    else if (Arg(a, "secs", &v)) secs = atof(v);
    else if (Arg(a, "integ", &v)) integ = v;
    else known = 0;
    if (!known) { fprintf(stderr, "mjc_act: unknown setting %s\n", a); return 2; }
    if (strncmp(a, "dt=", 3) != 0) {
      strncat(extra, " ", sizeof extra - strlen(extra) - 1);
      strncat(extra, a, sizeof extra - strlen(extra) - 1);
    }
  }
  if (dt <= 0.0 || !scene) { fprintf(stderr, "mjc_act: dt and scene must be given\n"); return 2; }
  int const isPos = !strcmp(scene, "position"), isVel = !strcmp(scene, "velocity"), isMot = !strcmp(scene, "motor");
  int const isFil = !strcmp(scene, "filter"), isDam = !strcmp(scene, "damper"), isFix = !strcmp(scene, "fixed");
  int const isSpa = !strcmp(scene, "spatial"), isMus = !strcmp(scene, "muscle");
  if (!(isPos || isVel || isMot || isFil || isDam || isFix || isSpa || isMus)) {
    fprintf(stderr, "mjc_act: scene=position|velocity|motor|filter|damper|fixed|spatial|muscle\n");
    return 2;
  }
  double const kp = kpS ? atof(kpS) : 50.0, kv = kvS ? atof(kvS) : 5.0;
  double const ctrl = ctrlS ? atof(ctrlS) : (isVel || isDam) ? 1.0 : isMot ? 3.0 : 0.5;
  double const angle0 = angS ? atof(angS) : isFix ? 0.5 : 0.0;
  double const stiff = stS ? atof(stS) : isSpa ? 100.0 : 20.0;
  int const gravity = gS ? atoi(gS) : !(isVel || isMot || isFix);

  char opt[256];
  snprintf(opt, sizeof opt, "timestep=\"%.17g\" gravity=\"0 0 %s\"%s%s%s", dt, gravity ? "-9.8" : "0",
           integ ? " integrator=\"" : "", integ ? integ : "", integ ? "\"" : "");
  char second[512] = "", tendon[512] = "", act[512] = "";
  if (isFix) {
    snprintf(second, sizeof second,
             "<body name=\"arm2\" pos=\"0 0.3 0\"><joint name=\"hinge2\" type=\"hinge\" axis=\"0 -1 0\"/>"
             "<geom type=\"box\" pos=\"0.5 0 0\" size=\"0.05 0.05 0.05\" mass=\"1\" contype=\"0\" conaffinity=\"0\"/></body>");
    snprintf(tendon, sizeof tendon,
             "<tendon><fixed name=\"t\" stiffness=\"%.17g\"><joint joint=\"hinge\" coef=\"1\"/>"
             "<joint joint=\"hinge2\" coef=\"-1\"/></fixed></tendon>", stiff);
  }
  if (isSpa)
    snprintf(tendon, sizeof tendon, "<tendon><spatial name=\"t\" stiffness=\"%.17g\" springlength=\"0.3\">"
             "<site site=\"anchor\"/><site site=\"tip\"/></spatial></tendon>", stiff);
  if (isMus)
    snprintf(tendon, sizeof tendon, "<tendon><spatial name=\"t\"><site site=\"anchor\"/><site site=\"tip\"/></spatial>"
             "</tendon>");
  if (isPos) snprintf(act, sizeof act, "<actuator><position joint=\"hinge\" kp=\"%.17g\" kv=\"%.17g\"/></actuator>", kp, kv);
  if (isVel) snprintf(act, sizeof act, "<actuator><velocity joint=\"hinge\" kv=\"%.17g\"/></actuator>", kv);
  if (isMot)
    snprintf(act, sizeof act, "<actuator><motor joint=\"hinge\" gear=\"2\" ctrllimited=\"true\" ctrlrange=\"-1 1\"/>"
             "</actuator>");
  if (isFil)
    snprintf(act, sizeof act, "<actuator><general joint=\"hinge\" dyntype=\"filter\" dynprm=\"0.05\" gainprm=\"%.17g\" "
             "biastype=\"affine\" biasprm=\"0 %.17g %.17g\"/></actuator>", kp, -kp, -kv);
  if (isDam)
    snprintf(act, sizeof act, "<actuator><damper joint=\"hinge\" kv=\"%.17g\" ctrlrange=\"0 1\"/>"
             "</actuator>", kv);
  if (isMus) snprintf(act, sizeof act, "<actuator><muscle tendon=\"t\" ctrllimited=\"true\" ctrlrange=\"0 1\"/></actuator>");
  char xml[4096];
  snprintf(xml, sizeof xml,
           "<mujoco model=\"act\"><compiler angle=\"radian\"/><option %s/><worldbody>"
           "<site name=\"anchor\" pos=\"0.5 0 0.5\"/>"
           "<body name=\"arm\" pos=\"0 0 0\"><joint name=\"hinge\" type=\"hinge\" axis=\"0 -1 0\"/>"
           "<geom type=\"box\" pos=\"0.5 0 0\" size=\"0.05 0.05 0.05\" mass=\"1\" contype=\"0\" conaffinity=\"0\"/>"
           "<site name=\"tip\" pos=\"0.5 0 0\"/></body>%s</worldbody>%s%s</mujoco>",
           opt, second, tendon, act);
  mjVFS vfs;
  mj_defaultVFS(&vfs);
  if (mj_addBufferVFS(&vfs, "act.xml", xml, (int)strlen(xml)) != 0) { fprintf(stderr, "mjc_act: vfs\n"); return 1; }
  char err[1024] = "";
  mjModel* m = mj_loadXML("act.xml", &vfs, err, sizeof err);
  mj_deleteVFS(&vfs);
  if (!m) { fprintf(stderr, "mjc_act: %s\n", err); return 1; }
  mjData* d = mj_makeData(m);
  d->qpos[0] = angle0;
  if (m->nu > 0) d->ctrl[0] = ctrl;
  mj_forward(m, d);

  FILE* f = fopen(argv[1], "w");
  if (!f) { fprintf(stderr, "mjc_act: cannot write %s\n", argv[1]); return 1; }
  long const steps = (long)llround(secs / dt);
  fprintf(f, "CONTACT dt_ns %lld h0_nm 0 vx0_ums 0 mu_ppm 0 mass_g 1000 steps %ld\n", Round(dt * 1e9), steps);
  long atLimit = 0;
  int mostIters = 0;
  for (long i = 0; i < steps; ++i) {
    mj_step(m, d);
    int const it = d->solver_niter[0];
    if (it > mostIters) mostIters = it;
    if (it >= m->opt.iterations) ++atLimit;
    double const q2 = m->nq > 1 ? d->qpos[1] : 0.0, v2 = m->nv > 1 ? d->qvel[1] : 0.0;
    double const last = m->nu > 0 ? d->actuator_force[0] * 1e6 : m->ntendon > 0 ? d->ten_length[0] * 1e6 : 0.0;
    fprintf(f, "%ld %lld %lld %lld %lld %lld\n", i, Round(d->qpos[0] * 1e6), Round(d->qvel[0] * 1e6), Round(q2 * 1e6),
            Round(v2 * 1e6), Round(last));
  }
  fclose(f);
  int warnings = 0;
  for (int w = 0; w < mjNWARNING; ++w) warnings += d->warning[w].number;
  printf("STATS act scene %s dt %g steps %ld most_iterations %d at_iteration_limit %ld iteration_limit %d warnings %d "
         "nu %ld ntendon %ld engine mujoco %s extra%s\n", scene, dt, steps, mostIters, atLimit, m->opt.iterations, warnings,
         (long)m->nu, (long)m->ntendon, mj_versionString(), extra[0] ? extra : " none");
  mj_deleteData(d);
  mj_deleteModel(m);
  return 0;
}
