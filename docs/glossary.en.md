# Shared glossary and notation

Companion: [Français](glossary.fr.md).

| Term / symbol | Meaning used in this project |
|---|---|
| BbW / SbW | Brake-by-Wire / Steer-by-Wire |
| DBBS | Differential-Braking Backup Steering: yaw correction through unequal brake forces; not scrub-radius-actuated rack steering |
| BAS | Historical literature term; not the name of the present implemented mechanism |
| Fail-operational | Continued specified functionality after a defined fault, within a stated envelope; not unlimited nominal performance |
| Fail-safe | Transition to a defined safe condition; not synonymous with continued functionality |
| Plant | Vehicle, tires and actuators receiving commands |
| Allocator / QP | Constrained optimization mapping requested force/moment to four brake commands and one rack-angle command |
| `h_physical`, `h_known` | Actual channel availability; availability known to control |
| `t_p`, `t_flag` | Physical fault onset; delivered validated fault flag |
| `Fx`, `Mz` | Body longitudinal force [N], yaw moment [N m]; braking is negative `Fx` |
| `delta` | Common road-wheel steering angle [rad], not steering-wheel angle |
| `omegaA`, `omegaB` | Motor-channel contributions before physical clipping, expressed as equivalent road-wheel angular velocities [rad/s], not rotor speeds |
| `r`, `beta` | Yaw rate [rad/s]; body sideslip `atan2(vy,vx)` [rad] |
| FL/FR/RL/RR | Front-left/front-right/rear-left/rear-right; positive lateral axis is left |
| Nominal / degraded | Fault-free / after the defined fault; matched initial conditions and reference |
| Best effort / oracle | Bounded allocation minimizing residual; a true-mask affine prediction used only for diagnostics |
| Residual authority | Feasible remaining control capacity under specified simultaneous constraints, not the sum of unrelated maxima |
| FMEA / FTA / DFA | Failure Mode and Effects Analysis / Fault Tree Analysis / Dependent Failure Analysis |
| ASIL B(D) | Candidate ASIL B allocation in support of an original ASIL D requirement; not a safety label earned by a simulation |
| Preliminary evidence | Explicitly identified independent numerical checks; not MATLAB validation, hardware proof or supervisor acceptance |
