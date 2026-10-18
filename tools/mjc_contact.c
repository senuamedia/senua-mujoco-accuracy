// mjc_contact.c: the one-cube rig for MuJoCo, the adapter between Senua AI and the engine under test. It plays one
// cube on a plane and writes what happened, in exactly the format of the first deep dive's sdx_contact rig, so the
// same measuring programs read MuJoCo's runs unchanged. MuJoCo is z-up; the record's columns are the same quantities.
// usage: mjc_contact <out.txt> dt=<seconds> [h0=M] [vx0=V] [mu=X] [lock=0|1] [mass=KG] [radius=M] [secs=S] [push=N]
//          [pushat=S] [lift=N] [liftat=S] [integ=euler|implicit|implicitfast|rk4] [cone=pyramidal|elliptic]
//          [iterations=N] [tolerance=X] [noslip=N] [impratio=X] [dir=DEGREES] [condim=N] [solref=T,D] [solimp=A,B,C[,D,E]]
//          [belt=VX,VY] [diagexact=1] [refsafe=0] [fwdinv=1]
//   h0      the gap between the cube's lowest face and the plane at the start (default 0.05 m)
//   lock    1 (default) = the cube cannot turn (three slide joints); 0 = a free joint
//   radius  the cube's half-size (default 0.05 m); mass in kg (default 1)
//   push    a force along x from pushat on; lift a force up from liftat on (newtons)
//   integ, cone, iterations, tolerance, noslip, impratio: MuJoCo's own options; unset = MuJoCo's defaults
//   noslip_tolerance  MuJoCo's noslip_tolerance option; unset = MuJoCo's default (as before)
//   condim  MuJoCo's contact dimensionality, given to both geoms (1 = frictionless); unset = MuJoCo's default (3)
//   solref  MuJoCo's contact reference, time constant and damping ratio, given to both geoms; unset = MuJoCo's default
//   solimp  MuJoCo's contact impedance, three or five numbers, given to both geoms; unset = MuJoCo's default
//   belt    the floor's own surface velocity along x and y (MuJoCo's surfacevel), a conveyor belt; unset = still
//   diagexact  1: MuJoCo's diagexact flag (the exact diagonal of the constraint inertia, in the current pose, in place
//           of the approximation frozen in the written pose); unset = MuJoCo's default (off)
//   refsafe    0: MuJoCo's refsafe flag disabled (its stiffness guard, which holds a time constant to at least twice
//           the step, off); unset = MuJoCo's default (on)
//   fwdinv     1: MuJoCo's fwdinv flag (each step, its own mj_compareFwdInv: the constraint force of the forward step
//           against that of inverse dynamics, and the applied force against inverse dynamics' result); the STATS line
//           then adds the largest of each over the play; unset = MuJoCo's default (off)
//   stiction   1: the stiction flag of MuJoCo pull request #3349 (a stored body-pair pose and a spring against slip from
//           it, elliptic cone only); for a MuJoCo built from that pull request; unset = not set
//   teleport   T,DX: at time T, move the cube DX metres along the slide's direction from outside (its position set
//           directly, as a script or a reset would); unset = never
//   restore    T1,T2: save MuJoCo's whole integration state (mj_getState, mjSTATE_INTEGRATION) at T1, play on to T2,
//           restore it there and play on from T1; nothing is written during the detour, so with a state that restores
//           exactly the file is byte-identical to the same play without it; unset = never
//   pulse      F,T1,T2: a further force F (newtons) along the slide's direction from T1 to T2, a shove that makes the
//           held cube slip and stop somewhere new; unset = none
//   noyaw   1, with lock=0: the cube free to tilt but not to turn about the vertical (three slide joints and two hinges,
//           about x and then y, in place of the free joint); unset = as lock says
//   trace   a file: one line a step with the cube's turn about the vertical (yaw) and its tilt, and each contact's
//           place relative to the cube's centre, normal force, friction force and their ratio to the friction limit;
//           the STATS line then adds yaw_end_urad, most_yaw_urad, most_tilt_urad and steps_under_4_contacts; unset = none
//   tracedir 1, with trace: each contact's entry also gives the friction force on the cube in the ground plane, along and
//           across the slide's direction (mN), and the velocity of the cube's material point at the contact, along and
//           across it (um/s; the ground is still, so this is the slip); unset = the trace as before
//   dir     the slide's direction in the ground plane, degrees from x toward y (unset: along x, as before): the
//           starting velocity and the push point along it, the vx and Fx columns are along it, and the STATS line adds
//           how far the cube went across it (side_um, at the end) and the fastest it moved across it (most_side_ums)
// gravity is 9.8 m/s2, as in the first deep dive's known-answer suite. Both geoms carry the friction mu (MuJoCo takes
// the larger of the two); torsional and rolling friction are MuJoCo's defaults and play no part with condim 3.
// writes <out.txt>: a header line "CONTACT dt_ns <n> h0_nm <n> vx0_ums <n> mu_ppm <n> mass_g <n> steps <n>", then one
//   line a step: "<step> <height of the lowest face, nm> <vx, um/s> <vz, um/s> <contact force up, mN> <contact
//   force along x, mN>"
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
    fprintf(stderr, "usage: mjc_contact <out.txt> dt=<seconds> [h0=M] [vx0=V] [mu=X] [lock=0|1] [mass=KG] [radius=M] "
                    "[secs=S] [push=N] [pushat=S] [lift=N] [liftat=S] [integ=NAME] [cone=NAME] [iterations=N] "
                    "[tolerance=X] [noslip=N] [impratio=X]\n");
    return 2;
  }
  double dt = 0.0, h0 = 0.05, vx0 = 0.0, mu = 0.0, mass = 1.0, radius = 0.05, secs = 1.0;
  double push = 0.0, pushAt = 0.0, lift = 0.0, liftAt = 0.3;
  int lock = 1, haveDir = 0;
  double dirDeg = 0.0;
  const char *integ = NULL, *cone = NULL, *iterations = NULL, *tolerance = NULL, *noslip = NULL, *impratio = NULL,
             *condim = NULL, *solref = NULL, *solimp = NULL, *belt = NULL, *nstol = NULL;
  int diagexact = 0, stiction = 0, haveTele = 0, haveRestore = 0, norefsafe = 0, fwdinv = 0;
  double teleAt = 0.0, teleDx = 0.0, rsA = 0.0, rsB = 0.0, pulseF = 0.0, pulseA = 0.0, pulseB = 0.0;
  int havePulse = 0, noyaw = 0;
  const char* tracePath = NULL;
  int traceDir = 0;
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
    else if (Arg(a, "gsolref", &v)) gsolref = v;
    else if (Arg(a, "noslip", &v)) { noslip = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "noslip_tolerance", &v)) { nstol = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "impratio", &v)) { impratio = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "condim", &v)) { condim = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "solref", &v)) { solref = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "solimp", &v)) { solimp = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "belt", &v)) { belt = v; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "diagexact", &v)) { diagexact = atoi(v); strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "fwdinv", &v)) { fwdinv = atoi(v); strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "refsafe", &v)) { norefsafe = atoi(v) == 0; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "noyaw", &v)) { noyaw = atoi(v); strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "trace", &v)) tracePath = v;
    else if (Arg(a, "tracedir", &v)) traceDir = atoi(v);
    else if (Arg(a, "stiction", &v)) { stiction = atoi(v); strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1); }
    else if (Arg(a, "teleport", &v)) {
      if (sscanf(v, "%lf,%lf", &teleAt, &teleDx) != 2) { fprintf(stderr, "mjc_contact: teleport=T,DX\n"); return 2; }
      haveTele = 1; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1);
    }
    else if (Arg(a, "restore", &v)) {
      if (sscanf(v, "%lf,%lf", &rsA, &rsB) != 2 || rsB <= rsA) { fprintf(stderr, "mjc_contact: restore=T1,T2 with T2 after T1\n"); return 2; }
      haveRestore = 1; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1);
    }
    else if (Arg(a, "pulse", &v)) {
      if (sscanf(v, "%lf,%lf,%lf", &pulseF, &pulseA, &pulseB) != 3 || pulseB <= pulseA) { fprintf(stderr, "mjc_contact: pulse=F,T1,T2\n"); return 2; }
      havePulse = 1; strncat(extra, " ", sizeof extra - strlen(extra) - 1); strncat(extra, a, sizeof extra - strlen(extra) - 1);
    }
    else { fprintf(stderr, "mjc_contact: unknown setting %s\n", a); return 2; }
  }
  if (dt <= 0.0) { fprintf(stderr, "mjc_contact: dt must be given\n"); return 2; }

  // the scene: a plane and one cube, as MJCF; MuJoCo's own options only where a setting asks for them
  char opt[640];
  snprintf(opt, sizeof opt, "timestep=\"%.17g\" gravity=\"0 0 -9.8\"%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", dt,
           integ ? " integrator=\"" : "", integ ? integ : "", integ ? "\"" : "",
           cone ? " cone=\"" : "", cone ? cone : "", cone ? "\"" : "",
           iterations ? " iterations=\"" : "", iterations ? iterations : "", iterations ? "\"" : "",
           tolerance ? " tolerance=\"" : "", tolerance ? tolerance : "", tolerance ? "\"" : "",
           noslip ? " noslip_iterations=\"" : "", noslip ? noslip : "", noslip ? "\"" : "",
           impratio ? " impratio=\"" : "", impratio ? impratio : "", impratio ? "\"" : "",
           nstol ? " noslip_tolerance=\"" : "", nstol ? nstol : "", nstol ? "\"" : "");
  char joints[256];
  if (lock) snprintf(joints, sizeof joints, "<joint name=\"x\" type=\"slide\" axis=\"1 0 0\"/><joint name=\"y\" type=\"slide\" "
                                             "axis=\"0 1 0\"/><joint name=\"z\" type=\"slide\" axis=\"0 0 1\"/>");
  else if (noyaw) snprintf(joints, sizeof joints, "<joint name=\"x\" type=\"slide\" axis=\"1 0 0\"/><joint name=\"y\" type=\"slide\" "
                                                   "axis=\"0 1 0\"/><joint name=\"z\" type=\"slide\" axis=\"0 0 1\"/>"
                                                   "<joint name=\"rx\" type=\"hinge\" axis=\"1 0 0\"/><joint name=\"ry\" type=\"hinge\" axis=\"0 1 0\"/>");
  else snprintf(joints, sizeof joints, "<freejoint name=\"free\"/>");
  char cdim[256] = "";  // extra geom attributes: empty unless condim, solref or solimp is given (the scene as before)
  if (condim) snprintf(cdim, sizeof cdim, " condim=\"%s\"", condim);
  if (solref) {  // "T,D" on the command line, "T D" in the scene
    char sr[64];
    snprintf(sr, sizeof sr, "%s", solref);
    for (char* p = sr; *p; ++p) if (*p == ',') *p = ' ';
    size_t const used = strlen(cdim);
    snprintf(cdim + used, sizeof cdim - used, " solref=\"%s\"", sr);
  }
  if (solimp) {  // "A,B,C" or "A,B,C,D,E" on the command line, spaces in the scene
    char si[96];
    snprintf(si, sizeof si, "%s", solimp);
    for (char* p = si; *p; ++p) if (*p == ',') *p = ' ';
    size_t const used = strlen(cdim);
    snprintf(cdim + used, sizeof cdim - used, " solimp=\"%s\"", si);
  }
  char fbelt[128] = "";  // the floor's surface velocity: empty unless belt is given (the scene as before)
  if (belt) {
    char bv[96];
    snprintf(bv, sizeof bv, "%s", belt);
    for (char* p = bv; *p; ++p) if (*p == ',') *p = ' ';
    snprintf(fbelt, sizeof fbelt, " surfacevel=\"%s 0 0 0 0\"", bv);
  }
  // MuJoCo's flags: none unless asked for (the option element then closes as before)
  char flags[160] = "/>";
  if (diagexact || stiction || norefsafe || fwdinv)
    snprintf(flags, sizeof flags, "><flag%s%s%s%s/></option>", diagexact ? " diagexact=\"enable\"" : "",
             stiction ? " stiction=\"enable\"" : "", norefsafe ? " refsafe=\"disable\"" : "",
             fwdinv ? " fwdinv=\"enable\"" : "");
  char xml[4096];
  snprintf(xml, sizeof xml,
           "<mujoco model=\"cube\"><option %s%s<worldbody>"
           "<geom name=\"floor\" type=\"plane\" size=\"0 0 1\" friction=\"%.17g 0.005 0.0001\"%s%s/>"
           "<body name=\"cube\" pos=\"0 0 %.17g\">%s"
           "<geom name=\"box\" type=\"box\" size=\"%.17g %.17g %.17g\" mass=\"%.17g\" friction=\"%.17g 0.005 0.0001\"%s/>"
           "</body></worldbody></mujoco>",
           opt, flags, mu, cdim, fbelt, radius + h0, joints, radius, radius, radius, mass, mu, cdim);
  mjVFS vfs;
  mj_defaultVFS(&vfs);
  if (mj_addBufferVFS(&vfs, "cube.xml", xml, (int)strlen(xml)) != 0) { fprintf(stderr, "mjc_contact: vfs\n"); return 1; }
  char err[1024] = "";
  mjModel* m = mj_loadXML("cube.xml", &vfs, err, sizeof err);
  mj_deleteVFS(&vfs);
  if (!m) { fprintf(stderr, "mjc_contact: %s\n", err); return 1; }
  if (gsolref && SetGeomSolref(m, gsolref)) return 2;
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
  double mostFwdC = 0.0, mostFwdA = 0.0;  // the largest forward-inverse differences, only when fwdinv is set
  FILE* tf = NULL;  // the trace, only when asked for
  if (tracePath) {
    tf = fopen(tracePath, "w");
    if (!tf) { fprintf(stderr, "mjc_contact: cannot write %s\n", tracePath); return 1; }
    fprintf(tf, "TRACE step yaw_urad tilt_urad ncon then per contact: x_um y_um (from the cube's centre, along and across "
                "the slide) fn_mN ft_mN ratio_ppm (friction over mu times normal)\n");
  }
  double yawEnd = 0.0, mostYaw = 0.0, mostTilt = 0.0;
  long under4 = 0;
  // the restore detour (only when asked for): the state saved at T1, played on unwritten to T2, restored there
  int const nstate = haveRestore ? mj_stateSize(m, mjSTATE_INTEGRATION) : 0;
  mjtNum* saved = haveRestore ? (mjtNum*)malloc(sizeof(mjtNum) * (size_t)(nstate > 0 ? nstate : 1)) : NULL;
  long savedAt = -1;
  int detour = 0, restored = 0, teleDone = 0;
  for (long i = 0; i < steps; ++i) {
    double const tmid = ((double)i + 0.5) * dt;
    if (haveRestore && !restored) {
      if (savedAt < 0 && tmid >= rsA) { mj_getState(m, d, saved, mjSTATE_INTEGRATION); savedAt = i; detour = 1; }
      else if (detour && tmid >= rsB) {
        mj_setState(m, d, saved, mjSTATE_INTEGRATION);
        restored = 1; detour = 0; i = savedAt - 1;
        continue;
      }
    }
    if (haveTele && !teleDone && tmid >= teleAt) {  // moved from outside: the position set directly
      d->qpos[0] += teleDx * cd;
      d->qpos[1] += teleDx * sd;
      teleDone = 1;
    }
    mjtNum* xf = d->xfrc_applied + 6 * body;
    xf[0] = (push != 0.0 && (pushAt <= 0.0 || tmid >= pushAt)) ? push : 0.0;
    if (havePulse && tmid >= pulseA && tmid < pulseB) xf[0] += pulseF;
    if (haveDir) { xf[1] = xf[0] * sd; xf[0] *= cd; }
    xf[2] = (lift != 0.0 && tmid >= liftAt) ? lift : 0.0;
    mj_step(m, d);
    // mj_step integrates after computing the positions, so they are the step's start; recompute them for the state
    // the step ended in, as the other engines' rigs report (the next mj_step recomputes them anyway: the play is the
    // same). Corrected in run 006: until then the height column ran one step behind the others.
    mj_kinematics(m, d);
    int const it = d->solver_niter[0];
    if (it > mostIters) mostIters = it;
    if (it >= m->opt.iterations) ++atLimit;
    if (fwdinv) {
      if (d->solver_fwdinv[0] > mostFwdC) mostFwdC = d->solver_fwdinv[0];
      if (d->solver_fwdinv[1] > mostFwdA) mostFwdA = d->solver_fwdinv[1];
    }
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
    if (!detour)
      fprintf(f, "%ld %lld %lld %lld %lld %lld\n", i, Round((z - radius) * 1e9), Round(vx * 1e6), Round(vz * 1e6),
              Round(fw[2] * 1e3), Round(fx * 1e3));
    if (tf && !detour) {
      mjtNum const* q = d->xquat + 4 * body;  // w, x, y, z
      double const yaw = atan2(2.0 * (q[0] * q[3] + q[1] * q[2]), 1.0 - 2.0 * (q[2] * q[2] + q[3] * q[3]));
      double const zz = d->xmat[9 * body + 8];
      double const tilt = acos(zz > 1.0 ? 1.0 : (zz < -1.0 ? -1.0 : zz));
      yawEnd = yaw;
      if (fabs(yaw) > mostYaw) mostYaw = fabs(yaw);
      if (tilt > mostTilt) mostTilt = tilt;
      // with tracedir, the velocities of the state the step ended in (cvel is left from the step's start; the next
      // mj_step recomputes both from qpos and qvel, so the play is the same)
      if (traceDir) { mj_comPos(m, d); mj_comVel(m, d); }
      int nc = 0;
      for (int c = 0; c < d->ncon; ++c)
        if (d->contact[c].geom[0] == box || d->contact[c].geom[1] == box) ++nc;
      if (nc > 0 && nc < 4) ++under4;
      fprintf(tf, "%ld %lld %lld %d", i, Round(yaw * 1e6), Round(tilt * 1e6), nc);
      for (int c = 0; c < d->ncon; ++c) {
        mjContact const* con = d->contact + c;
        if (con->geom[0] != box && con->geom[1] != box) continue;
        mjtNum cf[6];
        mj_contactForce(m, d, c, cf);
        double const rx = con->pos[0] - d->xpos[3 * body], ry = con->pos[1] - d->xpos[3 * body + 1];
        double const along = haveDir ? rx * cd + ry * sd : rx, across = haveDir ? -rx * sd + ry * cd : ry;
        double const ft = sqrt(cf[1] * cf[1] + cf[2] * cf[2]);
        double const lim = con->friction[0] * cf[0];
        fprintf(tf, " %lld %lld %lld %lld %lld", Round(along * 1e6), Round(across * 1e6), Round(cf[0] * 1e3),
                Round(ft * 1e3), lim > 0.0 ? Round(ft / lim * 1e6) : 0LL);
        if (traceDir) {
          // the friction on the cube in world coordinates (the contact frame's two tangent rows), and the velocity of
          // the cube's material point at the contact: its centre's linear velocity plus its angular velocity crossed
          // with the contact's place relative to the centre (mj_objectVelocity, world orientation: angular, linear)
          double const s = (con->geom[1] == box) ? 1.0 : -1.0;
          double fwc[3], vo[6], vp[3];
          for (int j = 0; j < 3; ++j) fwc[j] = s * (cf[1] * con->frame[3 + j] + cf[2] * con->frame[6 + j]);
          mj_objectVelocity(m, d, mjOBJ_BODY, body, vo, 0);
          double const rz = con->pos[2] - d->xpos[3 * body + 2];
          vp[0] = vo[3] + vo[1] * rz - vo[2] * ry;
          vp[1] = vo[4] + vo[2] * rx - vo[0] * rz;
          vp[2] = vo[5] + vo[0] * ry - vo[1] * rx;
          double const cdd = haveDir ? cd : 1.0, sdd = haveDir ? sd : 0.0;
          fprintf(tf, " %lld %lld %lld %lld", Round((fwc[0] * cdd + fwc[1] * sdd) * 1e3),
                  Round((-fwc[0] * sdd + fwc[1] * cdd) * 1e3), Round((vp[0] * cdd + vp[1] * sdd) * 1e6),
                  Round((-vp[0] * sdd + vp[1] * cdd) * 1e6));
        }
      }
      fputc('\n', tf);
    }
  }
  fclose(f);
  if (tf) fclose(tf);
  free(saved);
  char side[384] = "";
  if (haveDir)
    snprintf(side, sizeof side, " side_um %lld most_side_ums %lld",
             Round((-(d->xpos[3 * body] - x0) * sd + (d->xpos[3 * body + 1] - y0) * cd) * 1e6), Round(mostSide * 1e6));
  if (tracePath) {
    size_t const used = strlen(side);
    snprintf(side + used, sizeof side - used, " yaw_end_urad %lld most_yaw_urad %lld most_tilt_urad %lld steps_under_4_contacts %ld",
             Round(yawEnd * 1e6), Round(mostYaw * 1e6), Round(mostTilt * 1e6), under4);
  }
  int warnings = 0;
  for (int w = 0; w < mjNWARNING; ++w) warnings += d->warning[w].number;
  char fwd[128] = "";
  if (fwdinv) snprintf(fwd, sizeof fwd, " most_fwdinv_constraint %.6g most_fwdinv_applied %.6g", mostFwdC, mostFwdA);
  printf("STATS contact dt %g h0 %g vx0 %g mu %g lock %d mass %g radius %g steps %ld most_iterations %d "
         "at_iteration_limit %ld iteration_limit %d warnings %d%s%s engine mujoco %s extra%s\n",
         dt, h0, vx0, mu, lock, mass, radius, steps, mostIters, atLimit, m->opt.iterations, warnings, side, fwd,
         mj_versionString(), extra[0] ? extra : " none");
  mj_deleteData(d);
  mj_deleteModel(m);
  return 0;
}
