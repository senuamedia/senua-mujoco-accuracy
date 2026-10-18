# References

The physics Senua AI's Measure holds MuJoCo to is textbook physics, and the models it measures are published work.
Each source below is cited where the record uses it; each entry says what for. Every DOI and arXiv number was checked
against the registry it names (Crossref, arXiv) on 18 October 2026, and every other link opened.

## The physics measured against

- <a id="coulomb"></a>**Coulomb, C.-A. (1785).** Theorie des machines simples, en ayant egard au frottement de leurs
  parties et a la roideur des cordages. The Academie royale des sciences' prize memoir of 1781, printed in *Memoires de
  mathematique et de physique presentes a l'Academie royale des sciences*, vol. 10; new edition, Paris, Bachelier, 1821
  (scan, HKUST Library: <https://doi.org/10.14711/spcol/b668151>). *Used for*: Coulomb's law of dry friction, the law
  every hold and slide is held to: no motion while the tangential load stays inside the friction limit, mu times the
  normal force; a constant friction force mu N while sliding.
- <a id="popov"></a>**Popov, V. L. (2010).** *Contact Mechanics and Friction: Physical Principles and Applications.*
  Springer. <https://doi.org/10.1007/978-3-642-10803-7>. *Used for*: Coulomb's law as the standard model of static and
  sliding friction, from which a body sliding under it decelerates at mu g and stops after v^2 / (2 mu g), Coulomb's
  distance.
- <a id="landau"></a>**Landau, L. D., and Lifshitz, E. M. (1976).** *Mechanics*, 3rd edition (Course of Theoretical
  Physics, vol. 1). Pergamon. <https://doi.org/10.1016/C2009-0-25569-3>. *Used for*: the conservation of energy and of
  angular momentum of a body or chain with nothing acting on it, and Euler's equations of a rigid body's rotation, the
  answers the tumbling body and the free two-link chain are held to.
- <a id="stronge"></a>**Stronge, W. J. (2018).** *Impact Mechanics*, 2nd edition. Cambridge University Press.
  <https://doi.org/10.1017/9781139050227>. *Used for*: the coefficient of restitution: a body rebounds with a fraction of
  its impact speed, never more, and with a restitution of 0 not at all.
- <a id="featherstone"></a>**Featherstone, R. (2008).** *Rigid Body Dynamics Algorithms.* Springer.
  <https://doi.org/10.1007/978-1-4899-7560-7>. *Used for*: forward and inverse dynamics of articulated bodies, the two
  MuJoCo's own forward-inverse comparison (fwdinv) sets against each other.

## Integrating the motion

- <a id="hairer-gni"></a>**Hairer, E., Lubich, C., and Wanner, G. (2006).** *Geometric Numerical Integration:
  Structure-Preserving Algorithms for Ordinary Differential Equations*, 2nd edition. Springer.
  <https://doi.org/10.1007/3-540-30666-8>. *Used for*: the semi-implicit (symplectic) Euler method, MuJoCo's default
  integrator, its first-order error and its energy behaviour (and so a slide's distance short by half a step's travel,
  v dt / 2); projection onto conserved quantities.
- <a id="hairer-ode"></a>**Hairer, E., Norsett, S. P., and Wanner, G. (1993).** *Solving Ordinary Differential
  Equations I: Nonstiff Problems*, 2nd edition. Springer. <https://doi.org/10.1007/978-3-540-78862-1>. *Used for*: the
  classical fourth-order Runge-Kutta method, MuJoCo's RK4 integrator.

## Contact, friction and constraint models

- <a id="todorov-2012"></a>**Todorov, E., Erez, T., and Tassa, Y. (2012).** MuJoCo: A physics engine for model-based
  control. *2012 IEEE/RSJ International Conference on Intelligent Robots and Systems*, 5026-5033.
  <https://doi.org/10.1109/IROS.2012.6386109>. *Used for*: MuJoCo itself, the engine every run plays, as its
  repository asks it to be cited.
- <a id="todorov-2014"></a>**Todorov, E. (2014).** Convex and analytically-invertible dynamics with contacts and
  constraints: Theory and implementation in MuJoCo. *2014 IEEE International Conference on Robotics and Automation
  (ICRA)*, 6054-6061. <https://doi.org/10.1109/ICRA.2014.6907751>. *Used for*: MuJoCo's soft, convex constraint model,
  each constraint's impedance, reference acceleration and regularization, behind the creep at rest (F1), the depth
  of a resting contact and its time constant (F17), friction's creep without noslip (F18), and its invertibility, which
  makes inverse dynamics agree without noslip.
- <a id="stewart-trinkle"></a>**Stewart, D. E., and Trinkle, J. C. (1996).** An implicit time-stepping scheme for rigid
  body dynamics with inelastic collisions and Coulomb friction. *International Journal for Numerical Methods in
  Engineering* 39(15), 2673-2691.
  <https://doi.org/10.1002/(SICI)1097-0207(19960815)39:15%3C2673::AID-NME972%3E3.0.CO;2-I>. *Used for*: the polyhedral
  approximation of Coulomb's friction cone, the form MuJoCo's default pyramidal cone takes (F2).
- <a id="anitescu"></a>**Anitescu, M. (2006).** Optimization-based simulation of nonsmooth rigid multibody dynamics.
  *Mathematical Programming* 105(1), 113-143. <https://doi.org/10.1007/s10107-005-0590-7>. *Used for*: the convex
  relaxation of Coulomb's cone and its artefact: a sliding contact acts at a distance of about dt mu v, so a sliding
  body rises off the surface (F3).
- <a id="desaxce-1991"></a>**De Saxce, G., and Feng, Z.-Q. (1991).** New inequality and functional for contact with
  friction: the implicit standard material approach. *Mechanics of Structures and Machines* 19(3), 301-325.
  <https://doi.org/10.1080/08905459108905146>. *Used for*: the bipotential that writes Coulomb's law as one complementarity
  condition, with the term mu times the sliding speed in the normal direction that Senua AI's patch restores
  (`desaxce_elliptic_v4.diff`).
- <a id="desaxce-1998"></a>**De Saxce, G., and Feng, Z.-Q. (1998).** The bipotential method: a constructive approach to
  design the complete contact law with friction and improved numerical algorithms. *Mathematical and Computer
  Modelling* 28(4-8), 225-245. <https://doi.org/10.1016/S0895-7177(98)00119-8>. *Used for*: the same law and its
  numerical treatment.
- <a id="acary-2011"></a>**Acary, V., Cadoux, F., Lemarechal, C., and Malick, J. (2011).** A formulation of the linear
  discrete Coulomb friction problem via convex optimization. *ZAMM, Journal of Applied Mathematics and Mechanics* 91(2),
  155-175. <https://doi.org/10.1002/zamm.201000073>. *Used for*: exact Coulomb friction reached as the fixed point of a
  sequence of convex problems, each with the normal velocity shifted by friction times the slip, the scheme
  `desaxce_elliptic_v4.diff` follows.
- <a id="acary-brogliato"></a>**Acary, V., and Brogliato, B. (2008).** *Numerical Methods for Nonsmooth Dynamical
  Systems: Applications in Mechanics and Electronics.* Springer. <https://doi.org/10.1007/978-3-540-75392-6>. *Used for*:
  Coulomb's cone, the Signorini condition and the complementarity formulations of frictional contact that the patches
  work within.
- <a id="le-lidec"></a>**Le Lidec, Q., Jallet, W., Montaut, L., Laptev, I., Schmid, C., and Carpentier, J. (2024).**
  Contact models in robotics: a comparative analysis. *IEEE Transactions on Robotics* 40(5), 3716-3733.
  <https://doi.org/10.1109/TRO.2024.3434208> (arXiv [2304.06372](https://arxiv.org/abs/2304.06372)). *Used for*: the
  pyramidal cone's anisotropy, which makes a sliding cube drift off its line (F2); the convex relaxation's interaction
  at a distance while sliding (F3); and the De Saxce correction, the term that relaxation drops.
- <a id="crisp"></a>**Lee, S., Park, S., Yun, J., An, S., and Lee, D. (2026).** CRISP: Contact-Rich Robotic Simulation
  Platform with Extensive Geometries and Contact Solvers. arXiv [2609.21761](https://arxiv.org/abs/2609.21761).
  *Used for*: users' reports that MuJoCo's joint limits are soft, its joint friction does not fully hold a torque, its
  contacts penetrate, and its convex contact glides while sliding.

## Floating point and compilers (issue 18)

- <a id="ieee-754"></a>**IEEE (2019).** *IEEE Standard for Floating-Point Arithmetic*, IEEE Std 754-2019.
  <https://doi.org/10.1109/IEEESTD.2019.8766229>. *Used for*: the fused multiply-add, a multiply and an add with one
  rounding, which the standard allows and which changes the last digit against two roundings.
- <a id="goldberg"></a>**Goldberg, D. (1991).** What every computer scientist should know about floating-point
  arithmetic. *ACM Computing Surveys* 23(1), 5-48. <https://doi.org/10.1145/103162.103163>. *Used for*: rounding, and why
  a different order or fusion of operations gives other bits.
- <a id="gcc-fp-contract"></a>**GCC manual**, Options That Control Optimization, `-ffp-contract`:
  <https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html>. "The default is -ffp-contract=off for C in a standards
  compliant mode (-std=c11 or similar), -ffp-contract=fast otherwise." MuJoCo builds its C as ISO C11.
- <a id="clang-fp-contract"></a>**Clang Compiler User's Manual**, `-ffp-contract`:
  <https://clang.llvm.org/docs/UsersManual.html>. Its default, `on`, fuses a multiply and an add within one statement.

## MuJoCo and Google DeepMind

- <a id="mujoco-repo"></a>**MuJoCo**, Google DeepMind: <https://github.com/google-deepmind/mujoco> ("This repository is
  maintained by Google DeepMind"); version 3.16.0 at the commit in [`UPSTREAM_COMMIT`](../UPSTREAM_COMMIT).
- <a id="mujoco-docs"></a>**MuJoCo documentation**: the [computation chapter](https://mujoco.readthedocs.io/en/latest/computation/index.html)
  (the soft constraint model, the friction cones, noslip, impratio, inverse dynamics), [modeling](https://mujoco.readthedocs.io/en/latest/modeling.html)
  (solref, solimp and refsafe, convex parts for a concave shape) and the [XML reference](https://mujoco.readthedocs.io/en/stable/XMLreference.html#option).
- <a id="deepmind-2021"></a>**Google DeepMind (2021).** Opening up a physics simulator for robotics, 18 October 2021:
  <https://deepmind.google/discover/blog/opening-up-a-physics-simulator-for-robotics/>. DeepMind acquired MuJoCo, "the
  physics simulator of choice for DeepMind's robotics team", and made it free for everyone.
- <a id="deepmind-2022"></a>**Tassa, Y., and Tunyasuvunakool, S. (2022).** Open-sourcing MuJoCo, Google DeepMind, 23 May
  2022: <https://deepmind.google/discover/blog/open-sourcing-mujoco/>. MuJoCo's whole codebase released as open source.
- <a id="playground"></a>**Zakka, K., Tabanpour, B., Liao, Q., Haiderbhai, M., Holt, S., et al. (2025).** MuJoCo
  Playground. arXiv [2502.08844](https://arxiv.org/abs/2502.08844). Google DeepMind, UC Berkeley, the University of
  Toronto and the University of Cambridge. *Used for*: how users train in MuJoCo across uncertain physics, by randomizing
  friction, masses, centres of mass, reflected inertia and actuator gains.

## Users' workarounds cited

- <a id="yan-2025"></a>**Yan, Q., Ding, Z., Zhou, X., and Spiers, A. J. (2025).** Variable-friction in-hand manipulation
  for arbitrary objects via diffusion-based imitation learning. arXiv [2503.02738](https://arxiv.org/abs/2503.02738).
  *Used for*: a configuration users harden MuJoCo with: the elliptic cone, the Newton solver, a high impratio, harder
  solref and solimp, optional noslip, multiccd.
- <a id="acosta-2022"></a>**Acosta, B., Yang, W., and Posa, M. (2022).** Validating robotics simulators on real-world
  impacts. *IEEE Robotics and Automation Letters* 7(3), 6471-6478. <https://doi.org/10.1109/LRA.2022.3174367> (arXiv
  [2110.00541](https://arxiv.org/abs/2110.00541)). *Used for*: contact stiffness, damping and friction fitted per system
  to real impacts, MuJoCo among the simulators.
- MuJoCo's issues and pull requests the record reproduces or plays (#2430, #3349 and the others): each linked from
  [the reported problems](known-issues.md).
