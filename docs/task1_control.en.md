# Task 1 — correction of degraded-mode control

Protocol: `TASK1-CTRL-01`. Controller: `ALLOC-2026-04`. Vehicle: unchanged `REF-2026-02`.

Status: MATLAB campaign and local evidence audit completed on 16 September 2026. The original failures are corrected, but six additional saturated-braking fault transitions fail; `Task1Passed=false` and Gate 3 remains open.

Follow-up: the [completed Task 2 local assessment](task2_assessment.en.md) provides independent timing arithmetic, evidence-transfer checks, the current requirement matrix and the conditional Task 3 decision, without new MATLAB runs.

Project context: the project author has confirmed that the guarantor approved the outstanding decisions submitted to him. This confirmation is recorded without inventing a signature, approval date or formal minutes, and does not convert failed tests into passes. Additional academic supervisors: Pr Said Ben Alla and Pr Issam Amellal. The target is an academic, simulation-validated demonstrator, not a production-vehicle safety certification.

## Diagnosis and design

The original heavy-braking front-corner-loss cases exceeded 0.15 rad sideslip despite small yaw rate. Yaw balance alone did not preserve rear lateral support. With 98% longitudinal tire utilization, the ideal friction-circle lateral budget at the commanded limit is only `sqrt(1-0.98^2) = 19.9%` of `mu*Fz`. Actuator lag and load transfer further distinguish that command-level budget from actual tire capacity.

The candidate limits rear-brake commands to 92% of current longitudinal capacity when exactly one front brake is diagnosed failed and both rear brakes are available. The corresponding command-level lateral budget is 39.2%. Other channels retain the 98% policy. Physical friction, tire equations, actuator limits and vehicle parameters are unchanged. The fault mask remains the only trigger; the controller does not inspect scenario names, future faults or validation results.

The six-point MATLAB design sweep (rear fractions 0.98, 0.96, 0.94, 0.92, 0.90, 0.88) exposed the braking/stability trade-off. At 0.92, the preliminary front-left case retained 61.115% braking with 0.060513 rad peak sideslip, versus 63.679% and 0.241615 rad at 0.98. These are design-trial results, not the final regression verdict. The 60% criterion is unchanged; this limited margin is not a robustness guarantee.

A new reserve is approached within the existing command release-rate limit. The softer controller reserve may temporarily be exceeded during that transition; physical force bounds remain authoritative. An unavoidable physical-bound/rate conflict is still recorded as an override, not concealed.

The centred DBBS path failure was reduced in design trials by faster yaw feedback. The candidate changes the yaw time constant from 0.25 s to 0.15 s only after both steering-drive losses are diagnosed. Nominal operation and single-drive operation retain 0.25 s. The original time-based yaw reference and all evaluation thresholds are unchanged. This is yaw tracking, not a newly claimed path-feedback controller.

A speed-scaled yaw-reference alternative was tested and rejected: it worsened centred-case path error. Its results and original experimental source patch are retained privately. It is not part of the delivered controller.

## Reproduction and acceptance

From the project root in MATLAB with Optimization Toolbox:

```matlab
results = run_task1_validation();
```

The runner creates a new timestamped folder and archives its exact MATLAB sources. An explicitly supplied existing output folder is rejected to preserve evidence.

Coverage includes the full unit suite; five Gate 2 maneuvers; all 30 Gate 3 fault cases with four nominal references; five dynamic braking cases; six additional heavy-braking front-loss transitions; and 1 ms sampling/integration checks for both originally failing front-brake and centred-DBBS directions.

Unchanged principal limits: sideslip <= 0.15 rad; retained braking >= 60%; hold yaw moment <= 5% of a feasible nominal yaw witness; DBBS path <= 0.50 m, yaw RMSE <= 0.03 rad/s, and additional deceleration <= 0.35 g. Existing force, friction, load, rate, solver and masking checks remain active. Extra loaded-fault transition results are reported separately from the original authority maneuver's steady hold criterion.

`Task1Passed` is distinct from Gate 3 closure. The existing recovery oracle is still only a diagnostic; independent REQ-02 applicability/recovery, operational-envelope coverage, baseline comparison and broader robustness belong to Task 2.

## MATLAB results — candidate v1

All 45 unit tests, five nominal maneuvers, and the numerical/masking/recovery/continuity diagnostics of all 30 original fault cases pass. All eight DBBS maneuver evaluations pass: worst path deviation 0.294527 m (limit 0.50 m), worst yaw RMSE 0.011461 rad/s (0.03), and worst deceleration 0.277080 g (0.35). The original front-brake-loss authority maneuvers now peak at 0.060513 rad sideslip (0.15), retain at least 61.1147% braking (60%), and remain below the hold yaw limit. Both rear-loss authority maneuvers pass. All four 1 ms refinement cases pass; centred DBBS path deviation remains below 0.295254 m.

The six **additional** front-loss tests inject the fault at 1.5 s during saturated braking, with 0/10/50 ms diagnosis delays. Each reports one command-rate override. Across the onset-inclusive 1.5–1.9 s window, minimum braking is 49.587–50.592% and peak yaw moment about 3919.81 Nm, above 567.14 Nm. Peak sideslip remains below 0.060395 rad. These failed stress tests are preserved, not converted to passes or used to claim full compliance. Their instantaneous-onset checks must be distinguished from the original pre-faulted authority plateau; transition feasibility and recovery need separate assessment before closure.

### Remaining transition conflict

At the front-left fault with zero diagnosis delay, the healthy front-right command is -5614.4 N immediately before failure. The model's quasi-static wheel load drops to 5693.3 N at onset, making its physical lower force bound approximately -5124.0 N. The rate constraint permits only an 80 N release per 2 ms, i.e. a command no greater than approximately -5534.4 N at that step. The intervals do not intersect: no allocation can simultaneously satisfy those two instantaneous constraints at this state. The implemented bound-priority fallback commands -5021.5 N and explicitly logs the override. This is not evidence that a real actuator can jump at that rate.

For that trace, from 1.70 s onward through 1.90 s the retained braking is at least 60.258% and absolute yaw moment at most 238.662 Nm. This describes recovery, not a replacement acceptance window or an independent REQ-02 pass. The saturated onset must be resolved through an explicit model/command-semantics and operating-envelope decision; changing gains cannot remove an empty constraint intersection. No such new decision is attributed to the guarantor.

Usage constraint: the author requested reduced MATLAB consumption and completion prioritisation on the same day. No additional MATLAB campaigns are scheduled. Next work uses the saved evidence locally; any necessary new simulation must be narrowly justified before execution.

## Evidence archive

Completed archive: `validation/results/task1_evidence_20260916.zip`, SHA-256 `6821dcd9105ca9d5d5f961cb79b079c928c2f6e117a992fa8e89478f8b95550c`, verified against MATLAB Drive. It includes the completed candidate, exact sources, design trials and rejected alternatives. The local audit recomputed checks across 54 CSV time histories and matched all six changed MATLAB source files exactly. `task1_local_audit.json` records consistency, not a Task 1 pass. Two rear-loss braking ratios differ by approximately 1.6e-7 when CSV rounding includes the 1.9 s endpoint; excluding that endpoint reproduces MATLAB, and neither decision changes. During delayed saturated faults, commands also temporarily exceed true-state force bounds before diagnosis, although actual tire forces remain clipped within the friction circle. These are recorded limitations, not independent model-validation or REQ-02 claims. Four bilingual before/after PNG figures are saved in the extracted evidence's `validation/results/presentation` folder.

The pre-change local MATLAB source snapshot is `tmp/task1_baseline_20260916.zip`, SHA-256 `dad44b7625503f81ec32dafe34fde3b34e3de4de1277e80d6d9f37838fa26d94`. Original Gate 2, Gate 3 and supplementary evidence is untouched. MATLAB Online work is isolated in `task1_control_20260916`; original cloud sources/results are preserved. Raw archives, reports and source documents remain excluded from public GitHub.
