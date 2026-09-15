# Gate 2 implementation and evidence

Current model: `REF-2026-02`; controller: `ALLOC-2026-03`. The corrected MATLAB run passed every Gate 2 check at 23:33:46 UTC on 15 September 2026. Status: `READY_FOR_SUPERVISOR_REVIEW`. The original failed run remains preserved.
The internship gate closes after the saved MATLAB results and figures have been reviewed. The source PDFs and the new LaTeX closure reports are kept in the ignored `reports/` directory.

## Execute

From the project root in MATLAB (R2021a or newer, Optimization Toolbox):

```matlab
results = run_gate2_validation();
```

Simulink is not required by this script campaign. `wawaw.slx` is an archived 11-state prototype and is not the current Gate 2 model. The current integrated simulation is `validation/run_integrated_maneuver.m` with `plant_step.m`. The old constant-demand campaign remains an allocator regression test; it is not the nominal vehicle evidence.

The runner executes unit tests, three plant-only cases, four steering bench cases, five integrated maneuvers and a 2 ms/1 ms convergence test. A failed check saves its metrics and raises an error. Passing all checks gives `READY_FOR_SUPERVISOR_REVIEW`, not automatic supervisor acceptance.

## Steering architecture

Two independently masked velocity servos drive one rack. The plant state is:

```text
x = [vx vy r X Y psi delta FxFL FxFR FxRL FxRR omegaA omegaB]'
u = [FxFL FxFR FxRL FxRR delta_command]'
h = [brakeFL brakeFR brakeRL brakeRR steeringA steeringB]'
```

One shared angle is correct for a common rack: two independent road-wheel angles must not be added. Healthy channels split the requested rack velocity in proportion to their available rate. Each is assumed to provide the full ±35° range and 240°/s, with the combined rack capped at 400°/s. This is a functional model, without motor torques, rack inertia or road-load forces. The single-channel bench checks these assumptions with a 0.001 ratio tolerance for an asymptotic velocity response.

Losing A leaves B; losing B leaves A. Complete drive loss holds the last rack angle and removes commanded rack authority. A floating rack, arbitrary mechanical jam and sensor faults require separate Gate 3 models. Brake actuator loss removes its contact force even while its internal state decays. Five-entry legacy masks are expanded by copying the steering flag to A and B.

## Integration

The reference generator supplies `ax_ref`, `r_ref` and its analytic derivative. A nominal yaw servo requests:

```text
Fx_d = m (ax_ref - vy*r)
Mz_d = Iz (dr_ref/dt + (r_ref-r)/0.25)
```

The QP uses a local affine map `y = c + B*u`, evaluated about the current nonlinear plant state. The offset retains passive front/rear tire forces and existing steering effects. A centered steering derivative preserves straight-line symmetry. Fixed output scales are 5000 N and 1000 N·m; actuator variables are dimensionless. The steering trust region is ±0.5° about actual angle when compatible with the rate bounds.

Brake columns now use direct contact-force geometry with measured loads and lateral forces held fixed for the local QP. For actual steering angle `delta`, the longitudinal row is `[cos(delta), cos(delta), 1, 1]`; the yaw row is `[lf*sin(delta)-tw*cos(delta)/2, lf*sin(delta)+tw*cos(delta)/2, -tw/2, tw/2]`. Failed-channel columns are zero. This is a local control-effectiveness approximation, not the full derivative of the coupled load-transfer/combined-slip model. The offset is recomputed every sample so the affine map agrees exactly with actual generalized forces at the anchor. Steering retains a centered nonlinear yaw secant; its local longitudinal column is zero, as detailed below. The independent nonlinear plant is unchanged.

The original brake finite differences perturbed actuator states through clipping, load transfer and a square-root lateral-capacity boundary. The first MATLAB run exposed negative longitudinal release gains and very large cross-coupled yaw gains near saturation. Direct force geometry avoids treating these nonsmooth algebraic effects as brake effectiveness. `TestAllocatorSaturation` checks the geometry, anchor consistency, fault masking and full saturation/release with mirrored small initial asymmetries. No maneuver acceptance thresholds were relaxed.

At each 2 ms sample, commands are held during an RK4 plant step. Reported actual force/moment comes from the nonlinear tire model, **not** the QP prediction. The logs keep both. Brake-force bounds follow current wheel loads; a genuine empty intersection with a healthy command-rate bound is flagged and causes Gate 2 rejection. Moving bounds inside the available rate interval do not reset the previous command.

The plant retains raw wheel loads so wheel lift fails a check. Lateral load transfer satisfies `(Fz_right-Fz_left)*track/2 = m*ay_est*hcg`. Tire force is zero when the remaining friction budget is zero. Per-wheel longitudinal/lateral force pairs stay inside their circles. Quasi-static load transfer still uses estimated `ax` and `ay=vx*r`, rather than a coupled suspension solution.

## Maneuver catalog

### Corrected controller configuration

`ALLOC-2026-03` assigns steering yaw authority only in the local QP (`B(1,5)=0`). The sampled affine offset still contains the actual longitudinal effects of steering; the independent plant is unchanged. This prevents the longitudinal objective from deliberately using steering and opposing differential braking to chase an infeasible brake demand.

Integrated command bounds retain a provisional 2% longitudinal grip reserve (`0.98*mu*Fz`), separate from physical bounds (`mu*Fz`). At the command limit this leaves a theoretical 19.9% lateral friction-circle budget. Actuator lag and moving loads mean this is not a transient guarantee. Static authority screening still uses full theoretical capacity. Sensitivity and faulted-operation review of this assumption remain open; the original ≥95% braking-capacity acceptance criterion is unchanged.

`allocator_options` retains `interior-point-convex`, with optimality tolerance `1e-12` and constraint tolerance `1e-9`. A controlled MATLAB solver-only comparison at tolerances `1e-9`, `1e-10`, `1e-12`, `1e-14` gave peak yaw approximately `2.3923e-4`, `1.1887e-5`, `4.3859e-7`, `3.6051e-10` rad/s respectively, all without solver failures. Thus the old numerical tolerance was insufficient for this closed-loop regression. An active-set trial was rejected after iteration-limit failures. Algorithm and tolerance semantics follow the [MathWorks quadprog reference](https://www.mathworks.com/help/optim/ug/quadprog.html).

`run_allocator_solver_diagnostic()` reproduces the solver-only comparison and preserves each result under `validation/results/solver_diagnostic_v6/`; it refuses to overwrite an existing diagnostic folder. The optional fourth argument of `run_integrated_maneuver` supplies explicit solver options and the result saves those options. No maneuver thresholds are changed by this diagnostic.

### Nominal cases

All maneuvers begin at 60 km/h with nominal health, zero lateral/yaw states and zero actuator states. Ramps use `3s²-2s³` on `s∈[0,1]`. This catalog supersedes the Gate 2 coverage in the earlier traceability workbooks, which remain REF-2026-01 snapshots.

| ID | Profile | Duration | Behavior criterion |
|---|---|---:|---|
| G2-BRK | -0.20g ramp, 0.5–1.5 s; release 3.5–4.25 s | 6 s | Force RMSE ≤250 N; yaw RMSE ≤0.012 rad/s |
| G2-STR | Yaw equivalent of 1° bicycle-model steering; rise 0.5–0.8 s; release 4–4.5 s | 6 s | Same tracking limits |
| G2-CMB | -0.12g pulse plus 0.06 rad/s yaw pulse | 6 s | Same tracking limits |
| G2-YAW | `0.08 sin(2πs) sin²(πs)`, `s=(t-0.5)/5` between 0.5 and 5.5 s | 6 s | Same tracking limits |
| G2-SAT | -1.2μg demand, rise 0.5–1.25 s; release 2–2.75 s | 4 s | ≥95% μmg at 1.5–1.9 s; <100 N after 3.2 s; straight yaw <1e-4 rad/s |

Every case must also pass force/angle/rate limits, both motor contribution limits, positive raw wheel loads, friction circles, finite states, successful QP solves, speed >0.5 m/s and sideslip ≤0.15 rad. No threshold is relaxed merely because demand exceeds authority. The saturation case has a capacity/recovery criterion instead of a demand-tracking criterion.

## Evidence and traceability

| Output | Purpose |
|---|---|
| `validation/results/gate2/run_manifest.json` | MATLAB release/products, timestamp, parameters, Git revision and dirty status, acceptance status |
| `unit_tests.csv` | Model, allocation and integration regressions |
| `steering/steering_summary.csv` | Nominal, A-loss, B-loss and complete-drive-loss bench |
| `maneuver_summary.csv` | One numeric pass/fail row per maneuver |
| `<ID>/timeseries.csv`, `metrics.csv`, `result.mat` | Demands, states, commands, actual forces, QP predictions, wheel loads and health-independent nominal metrics |
| `<ID>/response_en.png`, `response_fr.png` | Response figures for both report languages |
| `<ID>/actuators_en.png`, `actuators_fr.png` | Brake commands, loads and individual steering contributions |
| `step_convergence.csv` | Combined maneuver at 2 ms versus 1 ms; yaw difference ≤0.001 rad/s, speed difference ≤0.03 m/s |
| `validation/results/plant/` | Allocator-free plant evidence |

REQ-01 is covered by the integrated bounds/rates/friction diagnostics. REQ-03b has a functional bench but no loaded hardware validation. REQ-02, dynamic REQ-03a/c and REQ-04 remain Gate 3 work. A raw 69.7% remaining brake capacity and a 37.6% static brake-yaw screening ratio do not prove straight-line performance or simultaneously attainable steer-plus-brake authority.

## First MATLAB execution and correction status

On 15 September 2026 at 19:04:40 UTC, MATLAB Online R2026a Update 5 executed commit `a775806` with Optimization Toolbox. All 31 original unit tests, three plant-only scenarios, four steering bench cases, four normal tracking maneuvers and timestep convergence passed. G2-SAT failed: peak absolute yaw was 0.079208 rad/s, release-window force reached 9172.17 N, and speed fell below the 0.5 m/s model floor. Solver success and physical-bound checks did not establish successful closed-loop behavior. The failed run is preserved separately in MATLAB Drive and is not overwritten by a claim of acceptance. The subsequent corrected execution below supersedes this failed run for current numerical status; Gate 3 has not been executed.

## Corrected MATLAB execution

The corrected campaign started on **15 September 2026 at 23:33:46 UTC** and completed in **196.2076 s** on MATLAB Online R2026a Update 5. All **36 unit tests, 3 plant-only cases, 4 steering cases, 5 maneuvers and timestep convergence passed**. Status: `READY_FOR_SUPERVISOR_REVIEW`.

| Case | Force RMSE [N] | Yaw RMSE [rad/s] | Result |
|---|---:|---:|---|
| G2-BRK | 44.6455 | 3.90575e-9 | Pass |
| G2-STR | 20.6210 | 0.00213073 | Pass |
| G2-CMB | 28.5375 | 0.00178501 | Pass |
| G2-YAW | 6.27437 | 0.00172186 | Pass |
| G2-SAT | 1541.32 (infeasible request) | 5.03305e-8 | Capacity/recovery pass |

G2-SAT delivered **98.0% μmg**, peak yaw **4.38590e-7 rad/s**, maximum release-window force **0.00457908 N**, and minimum/final speed **2.75553 m/s**. All physical/operating checks passed without rate overrides. Timestep differences were **0.000128328 rad/s** in yaw and **0.000587633 m/s** in speed, below the unchanged 0.001 rad/s and 0.03 m/s limits.

The tested source is base commit `a775806` plus a seven-file uncommitted correction identified by `saturation_fix_source_manifest.json`; every SHA-256 was verified in MATLAB before execution. The run manifest records the working-tree delta. The corrected archive in MATLAB Drive is `gate2_corrected_20260915_233346.zip`, separate from the failed baseline. A verified local download is not yet recorded. Reports and generated evidence remain excluded from GitHub. The inspected response plot exposed dark-theme axes/text styling; light-theme re-export remains a report-formatting task. Supervisor acceptance, reserve sensitivity and Gate 3 remain open.

## Historical independent checks (not MATLAB results)

Before MATLAB access, the files were parsed with MISS_HIT. A separate equation-level implementation with SciPy bounded least squares passed all five maneuvers with the same tuning, thresholds and sample period. These historical values did not predict the MATLAB saturation failure and must not be used as MATLAB acceptance evidence.

| Maneuver | Force RMSE [N] | Yaw RMSE [rad/s] |
|---|---:|---:|
| G2-BRK | 44.64 | <1e-12 |
| G2-STR | 20.62 | 0.002131 |
| G2-CMB | 28.64 | 0.001778 |
| G2-YAW | 6.27 | 0.001722 |
| G2-SAT | 1400.14 (infeasible request) | 0.00000185 |

The saturation plateau reached approximately 100% μmg and recovered below 100 N. No rate overrides or solver failures occurred. The 1 ms comparison changed yaw by 0.000128 rad/s and speed by 0.000588 m/s. These figures must be replaced or accompanied by actual MATLAB evidence before closing Gate 2. They do not validate a physical vehicle.

## Next

The [Gate 3 campaign](gate3.en.md), local draft safety analysis and bilingual progress-report material are now prepared. Reports remain in the ignored `reports/` directory. Run MATLAB and inspect results; replace or accompany preliminary numerical figures with MATLAB evidence; review thresholds and assumptions with the supervisor. The [gate register](project_status.en.md) lists unresolved envelope, authority and fault-coverage items. Dual faults and standardized maneuvers remain extensions.
