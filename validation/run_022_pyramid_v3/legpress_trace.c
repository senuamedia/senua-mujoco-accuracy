// legpress_trace.c: MuJoCo's own test ForwardTest.DiscreteStiffLegPress (test/engine/engine_forward_test.cc of
// 3.16.0), played the way the test plays it, to find why it fails with the slip-aligned pyramid switched on. The test
// steps a stiff leg pressed onto the floor from its keyframe to t = 0.8 three times: implicitfast at 1e-4 (the
// reference), discrete at 0.01 (coarse) and at 0.005 (fine), and asserts err(fine, ref) < 0.7 err(coarse, ref), where
// err is the sum of absolute differences of the three joints' positions and velocities at the end.
// This prints those errors and their ratio, and for each play every contact at every step: its geoms, the release's
// tangent (frame row 1), and the patch's turn (mjContact.frictionrot, cos and sin; 1 0 when not turned).
// The model's sleep_tolerance can be given (the patch turns a contact only when its slip is at least that): a value
// of 1e9 means no contact is ever turned. It is a diagnostic setting, never a fix.
// usage: legpress_trace <log file> [sleep_tolerance]   (MUJOCO_SLIP_ALIGNED_PYRAMID as the caller sets it)
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

static FILE* g_log;

static void endpoint(mjModel* m, mjData* d, mjtIntegrator integ, mjtNum h, mjtNum out[6], const char* label) {
  m->opt.integrator = integ;
  m->opt.timestep = h;
  mj_resetDataKeyframe(m, d, 0);
  int nstep = (int)mju_round(0.8 / h);
  for (int i = 0; i < nstep; i++) {
    mj_step(m, d);
    if (g_log && integ == mjINT_DISCRETE) {
      for (int c = 0; c < d->ncon; c++) {
        const mjContact* con = d->contact + c;
        fprintf(g_log, "%s step %d contact %d geoms %d %d tangent %.6f %.6f %.6f frictionrot %.6f %.6f pos_x %.6f\n",
                label, i, c, con->geom[0], con->geom[1], con->frame[3], con->frame[4], con->frame[5],
                con->frictionrot[0], con->frictionrot[1], con->pos[0]);
      }
    }
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
  if (argc < 2) { fprintf(stderr, "usage: legpress_trace <log file> [sleep_tolerance]\n"); return 2; }
  char error[1024] = "";
  mjSpec* spec = mj_parseXMLString(kXml, NULL, error, sizeof error);
  if (!spec) { fprintf(stderr, "%s\n", error); return 1; }
  mjModel* m = mj_compile(spec, NULL);
  if (!m) { fprintf(stderr, "compile failed\n"); return 1; }
  if (argc > 2) m->opt.sleep_tolerance = atof(argv[2]);
  mjData* d = mj_makeData(m);
  g_log = fopen(argv[1], "w");
  mjtNum ref[6], coarse[6], fine[6];
  endpoint(m, d, mjINT_IMPLICITFAST, 1e-4, ref, "ref");
  endpoint(m, d, mjINT_DISCRETE, 0.01, coarse, "coarse");
  endpoint(m, d, mjINT_DISCRETE, 0.005, fine, "fine");
  const char* sw = getenv("MUJOCO_SLIP_ALIGNED_PYRAMID");
  printf("LEGPRESS switch %s sleep_tolerance %g err_coarse %.10f err_fine %.10f ratio %.6f passes %d\n",
         sw ? sw : "unset", m->opt.sleep_tolerance, err(coarse, ref), err(fine, ref),
         err(fine, ref) / err(coarse, ref), err(fine, ref) < 0.7 * err(coarse, ref));
  printf("ENDPOINTS ref %.9f %.9f %.9f %.9f %.9f %.9f\n", ref[0], ref[1], ref[2], ref[3], ref[4], ref[5]);
  printf("ENDPOINTS coarse %.9f %.9f %.9f %.9f %.9f %.9f\n", coarse[0], coarse[1], coarse[2], coarse[3], coarse[4], coarse[5]);
  printf("ENDPOINTS fine %.9f %.9f %.9f %.9f %.9f %.9f\n", fine[0], fine[1], fine[2], fine[3], fine[4], fine[5]);
  if (g_log) fclose(g_log);
  mj_deleteData(d);
  mj_deleteModel(m);
  mj_deleteSpec(spec);
  return 0;
}
