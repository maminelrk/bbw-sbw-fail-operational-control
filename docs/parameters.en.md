# Reference vehicle and plant parameters

Parameter set: `REF-2026-01`

This is a literature-based reference vehicle for simulation development. It is not a parameter identification of a physical target vehicle. Every entry is classified as **sourced**, **calculated**, **requirement-derived**, or **assumed**. Surrogate and assumed values must be replaced or calibrated when target-vehicle data becomes available.

## Vehicle and environment

| Symbol / field | Value | Unit | Classification | Basis |
|---|---:|---|---|---|
| `m` | 1590 | kg | Sourced | Reference 4WID-EV simulation vehicle, Table 1 [S1] |
| `Iz` | 2059.2 | kg·m² | Sourced | Reference 4WID-EV simulation vehicle, Table 1 [S1] |
| `lf` | 1.05 | m | Sourced | CG to front axle, Table 1 [S1] |
| `lr` | 1.61 | m | Sourced | CG to rear axle, Table 1 [S1] |
| `L` | 2.66 | m | Calculated | `lf + lr` |
| `wf` | 0.6053 | fraction | Calculated | Static front load fraction `lr/L` |
| `tw` | 1.53 | m | Sourced surrogate | Reference-vehicle width used as the model track-width surrogate, Table 6 [S2] |
| `hcg` | 0.637 | m | Sourced surrogate | Reference-vehicle CG height, Table 6 [S2] |
| `g` | 9.80665 | m/s² | Sourced | Standard gravity [S3] |
| `mu` | 0.90 | - | Assumed operating condition | High-adhesion robustness condition used in [S1]; not a measured tire-road value for this vehicle |
| `reference_speed` | 16.6667 | m/s | Requirement-derived | 60 km/h DBBS validation condition |
| `vx_floor` | 0.5 | m/s | Assumed numerical guard | Prevents division by very small longitudinal speed; the model is not validated below this speed |

## Tire model

| Symbol / field | Value | Unit | Classification | Basis |
|---|---:|---|---|---|
| Source tire cornering stiffness | 33000 | N/rad per tire | Sourced | Front and rear tire stiffness in Table 1 [S1] |
| `Cf` | 66000 | N/rad per axle | Calculated | Two front tires × 33000 N/rad |
| `Cr` | 66000 | N/rad per axle | Calculated | Two rear tires × 33000 N/rad |
| Peak factor `D` | `mu*Fz` | N | Calculated | Friction-limited axle peak |
| Stiffness factor `B` | `Caxle/(Cshape*D)` | - | Calculated | Preserves the published small-slip cornering stiffness |
| `Cshape` | 1.9 | - | Assumed | Generic simplified Magic-Formula shape value; requires tire-data calibration |
| `Eshape` | 0.97 | - | Assumed | Generic curvature value; requires tire-data calibration |

The combined-slip model reduces lateral capacity according to a friction ellipse. It does not model wheel rotational dynamics, slip-ratio transients, camber, temperature, or tire load sensitivity.

## Actuators and numerical settings

| Symbol / field | Value | Unit | Classification | Basis |
|---|---:|---|---|---|
| `delta_max` | 35 | deg at road wheel | Assumed | Conservative simulation bound pending steering-rack data |
| `delta_rate` | 400 | deg/s | Requirement-derived assumption | Current REQ-01 actuator-rate limit |
| `Fx_rate` | 40000 | N/s per brake | Requirement-derived assumption | Current REQ-01 actuator-rate limit |
| `actuator_tau_delta` | 0.020 | s | Calculated design assumption | A first-order response reaches 91.8% in 50 ms |
| `actuator_tau_Fx` | 0.020 | s | Calculated design assumption | A first-order response reaches 91.8% in 50 ms |
| `validation_dt` | 0.002 | s | Requirement-derived | Allocator and validation period |
| `allocation_effort_weight` | 1e-6 | - | Assumed numerical tuning | Makes the QP strictly convex while keeping tracking dominant |

Brake-force bounds are calculated at runtime from `mu*Fz` using the current estimated normal load. Static allocator authority still uses static corner loads; dynamic-load-aware allocation remains a later refinement.

## Sources

- **S1:** C. Wang, R. He, and Q. Xia, “Path following control for 4WID-EV based on extended state observer and sliding mode control considering yaw stability,” 2023. https://doi.org/10.1177/16878132221148271
- **S2:** “Estimation of Vehicle Dynamic Parameters Based on the Two-Stage Estimation Method,” *Sensors*, 2021, Table 6. https://doi.org/10.3390/s21113711
- **S3:** National Bureau of Standards, “Gravity Measurements and the Standards Laboratory,” standard gravity definition. https://nvlpubs.nist.gov/nistpubs/Legacy/TN/nbstechnicalnote491.pdf

## Required follow-up

Before presenting results as representative of a particular vehicle, replace the surrogate geometry and actuator assumptions with measured or manufacturer-provided data. At minimum, perform sensitivity sweeps for `Iz`, `hcg`, `mu`, `Cf`, and `Cr`.
