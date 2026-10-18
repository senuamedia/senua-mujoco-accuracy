// legpress_order_2.c (run 089, step 2): legpress_order.c with the floor's turn about the vertical as a fourth setting, in
// degrees, written as the plane's euler; unset = 0, the scene as before.
// MuJoCo's own test ForwardTest.DiscreteStiffLegPress (test/engine/engine_forward_test.cc of 3.16.0), played the way the test plays it, as run 022's legpress_trace.c, and its mirror image: the same leg with every x
// reversed and its hinge axes reversed with it, so the joints move exactly as in the original. The leg's one contact
// then slides along +x where it slid along -x, and the pyramid's rows meet the slip in the other order (run 022: the
// release's first tangent is +x at every step). In exact arithmetic the two give the same joints. The test steps from
// its keyframe to t = 0.8 three times: implicitfast at 1e-4 (the reference), discrete at 0.01 (coarse) and at 0.005
// (fine), and asserts err(fine, ref) < 0.7 err(coarse, ref), err being the sum of absolute differences of the three
// joints' positions and velocities at the end. MuJoCo's solver tolerance and iteration limit can be given; unset, the
// test's (MuJoCo's defaults).
// usage: legpress_order_2 <mirror 0|1> [tolerance] [iterations] [floor turn, degrees]
#include <mujoco/mujoco.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char kXml[] =
  "<mujoco>"
  "  <option timestep=\"0.01\" integrator=\"discrete\"/>"
  "  <worldbody>"
  "    <geom name=\"floor\" type=\"plane\" size=\"2 2 .1\"/>"
  "    <body name=\"upper\" pos=\"0 0 0.5532\">"
  "      <joint name=\"slide\" type=\"slide\" axis=\"0 0 1\" stiffness=\"10000\" springref=\"-0.05\" damping=\"50\"/>"
  "      <joint name=\"hip\" type=\"hinge\" axis=\"0 -1 0\" stiffness=\"4000\" damping=\"12\"/>"
  "      <geom name=\"upper\" type=\"capsule\" size=\"0.04\" fromto=\"0 0 0 0.3064 0 -0.2571\"/>"
  "      <body name=\"lower\" pos=\"0.3064 0 -0.2571\">"
  "        <joint name=\"knee\" type=\"hinge\" axis=\"0 -1 0\" stiffness=\"4000\" damping=\"12\"/>"
  "        <geom name=\"lower\" type=\"capsule\" size=\"0.04\" fromto=\"0 0 0 -0.3064 0 -0.2571\"/>"
  "      </body>"
  "    </body>"
  "  </worldbody>"
  "  <keyframe>"
  "    <key name=\"impact\" qvel=\"-2 0 0\"/>"
  "  </keyframe>"
  "</mujoco>";

// the mirror image: x reversed in every position, and each hinge axis, a pseudovector, reversed in y and z
static const char kMirror[] =
  "<mujoco>"
  "  <option timestep=\"0.01\" integrator=\"discrete\"/>"
  "  <worldbody>"
  "    <geom name=\"floor\" type=\"plane\" size=\"2 2 .1\"/>"
  "    <body name=\"upper\" pos=\"0 0 0.5532\">"
  "      <joint name=\"slide\" type=\"slide\" axis=\"0 0 1\" stiffness=\"10000\" springref=\"-0.05\" damping=\"50\"/>"
  "      <joint name=\"hip\" type=\"hinge\" axis=\"0 1 0\" stiffness=\"4000\" damping=\"12\"/>"
  "      <geom name=\"upper\" type=\"capsule\" size=\"0.04\" fromto=\"0 0 0 -0.3064 0 -0.2571\"/>"
  "      <body name=\"lower\" pos=\"-0.3064 0 -0.2571\">"
  "        <joint name=\"knee\" type=\"hinge\" axis=\"0 1 0\" stiffness=\"4000\" damping=\"12\"/>"
  "        <geom name=\"lower\" type=\"capsule\" size=\"0.04\" fromto=\"0 0 0 0.3064 0 -0.2571\"/>"
  "      </body>"
  "    </body>"
  "  </worldbody>"
  "  <keyframe>"
  "    <key name=\"impact\" qvel=\"-2 0 0\"/>"
  "  </keyframe>"
  "</mujoco>";

static void endpoint(mjModel* m, mjData* d, mjtIntegrator integ, mjtNum h, mjtNum out[6], int* most, int* atLimit) {
  m->opt.integrator = integ;
  m->opt.timestep = h;
  mj_resetDataKeyframe(m, d, 0);
  int nstep = (int)mju_round(0.8 / h);
  for (int i = 0; i < nstep; i++) {
    mj_step(m, d);
    if (d->solver_niter[0] > *most) *most = d->solver_niter[0];
    if (d->solver_niter[0] >= m->opt.iterations) ++*atLimit;
  }
  mju_copy(out, d->qpos, 3);
  mju_copy(out + 3, d->qvel, 3);
}

static mjtNum err(const mjtNum a[6], const mjtNum b[6]) {
  mjtNum e = 0;
  for (int i = 0; i < 6; i++) e += fabs(a[i] - b[i]);
  return e;
}

int main(int argc, char** argv) {
  if (argc < 2) { fprintf(stderr, "usage: legpress_order_2 <mirror 0|1> [tolerance] [iterations] [floor turn, degrees]\n"); return 2; }
  int const mirror = atoi(argv[1]);
  char error[1024] = "";
  // the floor turned about the vertical: its geom given euler="0 0 Y" (degrees, MuJoCo's default angle unit)
  static char xml[4096];
  const char* src = mirror ? kMirror : kXml;
  const char* at = strstr(src, "size=\"2 2 .1\"");
  if (argc > 4 && at) {
    int k = (int)(at - src);
    snprintf(xml, sizeof xml, "%.*seuler=\"0 0 %s\" %s", k, src, argv[4], at);
  } else {
    snprintf(xml, sizeof xml, "%s", src);
  }
  mjSpec* spec = mj_parseXMLString(xml, NULL, error, sizeof error);
  if (!spec) { fprintf(stderr, "%s\n", error); return 1; }
  mjModel* m = mj_compile(spec, NULL);
  if (!m) { fprintf(stderr, "compile failed\n"); return 1; }
  if (argc > 2) m->opt.tolerance = atof(argv[2]);
  if (argc > 3) m->opt.iterations = atoi(argv[3]);
  mjData* d = mj_makeData(m);
  mjtNum ref[6], coarse[6], fine[6];
  int most = 0, atLimit = 0;
  endpoint(m, d, mjINT_IMPLICITFAST, 1e-4, ref, &most, &atLimit);
  endpoint(m, d, mjINT_DISCRETE, 0.01, coarse, &most, &atLimit);
  endpoint(m, d, mjINT_DISCRETE, 0.005, fine, &most, &atLimit);
  printf("FLOOR turn %s\n", argc > 4 ? argv[4] : "0");
  printf("LEGPRESS mirror %d tolerance %g iterations %d err_coarse %.12f err_fine %.12f ratio %.6f passes %d most_iterations %d at_iteration_limit %d\n",
         mirror, m->opt.tolerance, m->opt.iterations, err(coarse, ref), err(fine, ref), err(fine, ref) / err(coarse, ref),
         err(fine, ref) < 0.7 * err(coarse, ref), most, atLimit);
  printf("ENDPOINTS ref %.12f %.12f %.12f %.12f %.12f %.12f\n", ref[0], ref[1], ref[2], ref[3], ref[4], ref[5]);
  printf("ENDPOINTS coarse %.12f %.12f %.12f %.12f %.12f %.12f\n", coarse[0], coarse[1], coarse[2], coarse[3], coarse[4], coarse[5]);
  printf("ENDPOINTS fine %.12f %.12f %.12f %.12f %.12f %.12f\n", fine[0], fine[1], fine[2], fine[3], fine[4], fine[5]);
  mj_deleteData(d);
  mj_deleteModel(m);
  mj_deleteSpec(spec);
  return 0;
}
