# Fail-Operational Control Allocation for BbW and SbW

[Français](README.fr.md) | [Language index](README.md)

**Final reports now available:** [PDFs and complete LaTeX download](docs/final-report/README.en.md). Published with the authors' authorization; this supersedes the earlier privacy statements below for the final reports and their LaTeX sources only. Historical reports, the tested-source snapshot and raw evidence remain private.

## Overview

This internship project develops and documents an integrated Brake-by-Wire (BbW) and Steer-by-Wire (SbW) simulation. It distributes longitudinal force and yaw-moment requests across four wheel brakes and a shared steering rack driven by two independently masked actuator channels.

When the complete demand is physically infeasible, the allocator returns the closest bounded best-effort solution. When an effector fails, a binary fault mask removes its authority and the allocator redistributes the request among the remaining healthy effectors.

The backup concept is Differential-Braking Backup Steering (DBBS): asymmetric braking generates corrective yaw moment when commanded steering is unavailable. It does not model scrub-radius-induced rack steering. The corrected controller meets the selected pulse criteria in all eight assessed DBBS cases; wider operating conditions are future development.

## Development status

**Academic deliverable complete under revised scope SC-2026-01.** The author confirms the guarantor allows adapting CDC requirements to the internship deliverable. The [final scope record](docs/final_scope.en.md) defines completed work and future perspectives. The final English/French LaTeX reports and tested-source snapshot are private; no new MATLAB simulation or defense material was produced during final assembly.

The retained evidence includes the Gate 2 campaign, 45 unit tests, five nominal maneuvers, 30 original fault-case diagnostics and four refined checks for `ALLOC-2026-04`. The archive and 54 time histories were audited locally. Saturated-fault transition handling, continuous nonlinear envelope/recovery guarantees and hardware validation are outside final academic acceptance and remain documented future perspectives. Historical measurements and campaign flags are unchanged: scoped academic completion is distinct from universal requirements compliance or production certification. See [current status](docs/project_status.en.md) and the detailed [Task 2 audit](docs/task2_assessment.en.md).

Implemented:

- bounded best-effort quadratic-programming allocator;
- physical force and steering bounds;
- brake-force and steering-rate bounds;
- named single-effector fault masks;
- documented reference-vehicle parameter provenance;
- allocator-free open-loop plant validation campaign;
- two steering velocity loops driving one common rack, with A/B fault masks;
- allocator connected to the nonlinear 13-state vehicle through a sampled loop;
- five time-varying nominal maneuvers, paired French/English plots and run metadata;
- static residual-authority calculations;
- MATLAB unit tests;
- nominal, capacity-limit, brake-fault, and steering-loss validation scenarios;
- 30 Gate 3 fault cases separating physical failure from delayed diagnosis;
- matched nominal/faulted comparisons, recovery diagnostics and bilingual plotting;
- numerical baselines for REQ-02 and REQ-03;
- requirement-to-test traceability.

Remaining decisions and limitations:

- resolution of saturated-braking transition feasibility and independent recovery assessment;
- historical reporting retained for traceability; the current private reports use the audited corrected evidence;
- continuous nonlinear-envelope proof and global maxima are not claimed;
- sensor/path semantics, uncovered faults and physical independence remain limitations;
- student review of the final private deliverables and defense preparation.

## Control-allocation formulation

The requested generalized force is

```text
y_d = [Fx_d; Mz_d]
```

and the allocator command is

```text
u = [Fx_FL; Fx_FR; Fx_RL; Fx_RR; delta]
```

The allocator minimizes normalized tracking error and a small actuator-effort penalty:

```text
min 0.5 (c + B u - y_d)' Q (c + B u - y_d) + 0.5 rho u' R u
```

subject to physical bounds, a 2% nominal longitudinal grip reserve (increased to 8% at the rear after diagnosed single-front-brake loss with both rear brakes healthy), command-rate bounds, and six health flags `[FL FR RL RR A B]`. In integrated runs, `c` and `B` are recomputed from current vehicle state; actual performance is measured from nonlinear vehicle outputs. See the [Gate 2 guide](docs/gate2.en.md) and [corrected controller](docs/task1_control.en.md).

## Requirements

- Reference execution: MATLAB R2026a Update 5; older releases are not verified for the complete supplementary workflow
- Simulink only for the legacy block-model prototype
- Optimization Toolbox (`quadprog`, and `fmincon` for supplementary assessment)
- MATLAB Unit Test Framework

Reference execution: MATLAB Online R2026a Update 5 with Optimization Toolbox; detailed version, source identity and configuration are recorded with the evidence.

## Running the validation

Use a fresh project copy to preserve audited evidence: the runners write fixed results folders. Open MATLAB in that copy's root and run the Gate 2 campaign. See [safe reproduction](docs/handover.en.md).

```matlab
results = run_gate2_validation();
```

The command runs unit tests, plant-only cases, the steering bench, five integrated maneuvers and step convergence. CSV, MAT, French/English PNG figures and a run manifest are written to `validation/results/`. Failures prevent acceptance status. `run_project_validation()` additionally runs the older constant-demand allocator regressions. Generated evidence is excluded from Git.

To reproduce the already executed fault campaign in a new evidence directory:

```matlab
faultResults = run_gate3_validation();
```

This runs the unit tests, four matched nominal references and 30 delayed-fault cases. Its manifest always keeps Gate 3 open: passing maneuver diagnostics does not establish the full REQ-02/03 envelope or a safety case. See the [Gate 3 guide](docs/gate3.en.md) and [current gate register](docs/project_status.en.md).

To validate only the plant, without calling the allocator:

```matlab
plantSummary = run_plant_validation();
```

Individual static checks can be run with:

```matlab
authority = control_authority_report();
run("test_allocator_basic.m");
```

## Repository layout

```text
allocator.m                       Best-effort control allocator
fault_scenario_mask.m             Named health/fault masks
get_params.m                      Vehicle and allocator parameters
control_authority_report.m        Static residual-authority calculation
simulink_allocator_wrapper.m      Fault-mask-aware Simulink wrapper
wawaw.slx                         Archived 11-state Simulink prototype
steering_actuator_dynamics.m      Two-channel common-rack steering
plant_step.m                      Integrated nonlinear RK4 plant step
run_gate2_validation.m            Gate 2 evidence and acceptance entry point
run_gate3_validation.m            Gate 3 preliminary fault-evidence entry point
straight_braking_screening.m      Restricted zero-steer/zero-yaw authority screening
validation/                       Automated validation campaign
tests/                            MATLAB unit tests
docs/                             Bilingual technical documentation
run_project_validation.m          Repository-level validation entry point
run_plant_validation.m            Allocator-free plant validation entry point
```

## Documentation

- [Current internship gate and deliverable register](docs/project_status.en.md)
- [Gate 3 delayed-fault campaign](docs/gate3.en.md)
- [Shared glossary and notation](docs/glossary.en.md)
- [Current Gate 2 architecture, maneuvers and evidence](docs/gate2.en.md)
- [Verified Gate 2 evidence and presentation workflow](docs/gate2_evidence.en.md)

- [Numerical requirements baseline](docs/requirements_baseline.en.md)
- [Reference vehicle and plant parameters](docs/parameters.en.md)
- [Allocator-free open-loop plant validation](docs/plant_validation.en.md)
- [MATLAB/Simulink toolchain decision](docs/toolchain_decision.en.md)
- The workbooks under `docs/verification/` are REF-2026-01 snapshots; the Gate 2 guide supersedes their current implementation status.

The draft FMEA/FTA/DFA and bilingual LaTeX reports are retained locally under the ignored `reports/` directory; they are not distributed with the project source.

## Safety and scope notice

The numerical criteria and simulation results support project verification. They do not establish ISO 26262 compliance or prove vehicle safety. Requirements that depend on vehicle-level dynamics, hardware independence, fault detection, or human perception require additional analysis and physical evidence.

The CDC, Gate 1 report, internship workflow, and extracted copies are not part of this repository. Do not add them to commits.

## License

No open-source license has been assigned. Do not assume permission to reuse or redistribute the project. A license should be added only after ownership and publication rights are confirmed.
