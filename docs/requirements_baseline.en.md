# Numerical baseline for REQ-02 and REQ-03

Status: proposed engineering baseline for Gate 2/3 validation. These values must be reviewed with the project supervisor before they are treated as approved safety requirements. They are simulation acceptance criteria, not evidence of ISO 26262 compliance.

## Scope and definitions

- Allocation period: `Ts = 2 ms`, matching the current Simulink configuration.
- Fault time `t_f`: time at which a validated fault flag is presented to the allocator. Fault-detection latency is measured separately and is not hidden inside the reconfiguration time.
- Allocation output: `y = [Fx, Mz]'`.
- `y_best(t)`: closest output achievable with the post-fault mask, current physical/rate bounds, and the same demand. For an infeasible demand, this is the best-effort QP solution rather than the original demand.
- Normalized tracking error: `e_y = norm((y - y_best) ./ y_scale, Inf)`, where `y_scale` is the post-fault force/yaw authority reported by the allocator.
- A demand is inside the post-fault operational envelope when it is achievable with at least 15% unused authority in every active output direction. The transient continuity criteria below apply to that envelope. Demands outside it must still produce bounded best effort and must never reverse the sign of a requested braking force.

## REQ-02 — reconfiguration time and continuity

Following presentation of any validated single-effector fault flag:

1. The new actuator mask shall be active within **10 ms** (five allocation periods).
2. The allocator/actuator response shall reach **90% of the post-fault best-achievable output within 50 ms** and shall remain within a **10% normalized error band for at least 100 ms**.
3. Every healthy brake-force command shall respect `|dFx/dt| <= 40 kN/s`, and the healthy steering command shall respect `|d(delta)/dt| <= 400 deg/s`.
4. As a provisional driver-discontinuity proxy, the faulted trajectory shall remain within **0.05 rad/s of the nominal yaw rate during the first 200 ms** after the fault for demands inside the post-fault operational envelope.

The 50 ms value is retained from the project target. With the current 20 ms first-order actuator constants, 50 ms corresponds to approximately 92% of a step response. The acceptance band is therefore defined at 90% rather than 95%. The yaw-rate criterion is a simulation proxy and must not be presented as a proven human-perception threshold without vehicle-test evidence.

## REQ-03 — minimum residual capability

REQ-03 is divided by safety function because brake-based yaw compensation cannot physically reproduce the full force and angle authority of normal steering.

### REQ-03a — braking capability

After loss of any one brake corner, power path, or communication path that removes one corner, the maximum achievable straight-line deceleration shall be at least **60% of nominal**, while maintaining:

- `|Mz| <= 5%` of nominal maximum yaw authority;
- all healthy actuator force and rate limits.

With the current static-load parameters, the predicted worst case is loss of a front brake, leaving approximately **70%** of nominal raw braking force.

### REQ-03b — single steering-channel loss

Once the dual-motor steering model exists, loss of either individual steering channel shall leave at least:

- **60% of nominal road-wheel angle range**;
- **60% of nominal steering rate**.

The present single-angle plant cannot verify this sub-requirement.

### REQ-03c — complete commanded-steering loss / DBBS

If the commanded steering effector is unavailable and Differential-Braking Backup Steering is activated, the remaining brakes shall provide:

- at least **15% of nominal maximum yaw-moment authority**;
- yaw-rate tracking for `|r_ref| <= 0.15 rad/s` at 60 km/h with `RMSE(r) <= 0.03 rad/s` over the maneuver;
- peak lateral-path deviation from the nominal trajectory `<= 0.50 m`;
- brake-induced deceleration no greater than `0.35 g` during that test.

For the current parameters, static brake-only yaw authority is approximately 4.33 kN·m, or about 17% of the combined nominal steer-plus-brake yaw authority. A blanket 60% steering-authority requirement would therefore be infeasible and would conceal the real limitation of the backup mechanism.

## Required Gate 3 evidence

Each single-fault test shall record the demand, mask transition, allocator command, achieved `[Fx, Mz]`, best-achievable `[Fx, Mz]`, actuator rates, yaw rate, lateral deviation, and pass/fail result for every applicable clause.
