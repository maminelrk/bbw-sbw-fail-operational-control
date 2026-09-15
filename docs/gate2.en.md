# Gate 2 implementation and evidence

Current model: `REF-2026-02`. Status: implemented, MATLAB execution pending.
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

At each 2 ms sample, commands are held during an RK4 plant step. Reported actual force/moment comes from the nonlinear tire model, **not** the QP prediction. The logs keep both. Brake-force bounds follow current wheel loads; a genuine empty intersection with a healthy command-rate bound is flagged and causes Gate 2 rejection. Moving bounds inside the available rate interval do not reset the previous command.

The plant retains raw wheel loads so wheel lift fails a check. Lateral load transfer satisfies `(Fz_right-Fz_left)*track/2 = m*ay_est*hcg`. Tire force is zero when the remaining friction budget is zero. Per-wheel longitudinal/lateral force pairs stay inside their circles. Quasi-static load transfer still uses estimated `ax` and `ay=vx*r`, rather than a coupled suspension solution.

## Maneuver catalog

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

## Checks performed in the authoring environment

MATLAB is unavailable. The MATLAB files were parsed with MISS_HIT. A separate equation-level implementation with SciPy bounded least squares passed all five maneuvers with the same tuning, thresholds and sample period. This checks the equations and intended QP behavior, not MATLAB execution or `quadprog` compatibility.

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
