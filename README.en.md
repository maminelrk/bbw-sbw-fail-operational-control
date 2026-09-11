# Fail-Operational Control Allocation for BbW and SbW

[Français](README.fr.md) | [Language index](README.md)

## Overview

This project develops a fault-aware control allocator for an integrated Brake-by-Wire (BbW) and Steer-by-Wire (SbW) vehicle architecture. It distributes a requested longitudinal force and yaw moment across four independent wheel-brake effectors and one steering effector.

When the complete demand is physically infeasible, the allocator returns the closest bounded best-effort solution. When an effector fails, a binary fault mask removes its authority and the allocator redistributes the request among the remaining healthy effectors.

The project uses Brake-Actuated Steering (BAS) as the physical principle for degraded lateral control. The implemented backup function is described as Differential-Braking Backup Steering (DBBS): asymmetric braking generates corrective yaw moment when commanded steering is unavailable.

## Development status

This repository is a Gate 2 development and validation baseline, not a completed safety case.

Implemented:

- bounded best-effort quadratic-programming allocator;
- physical force and steering bounds;
- brake-force and steering-rate bounds;
- named single-effector fault masks;
- static residual-authority calculations;
- MATLAB unit tests;
- nominal, capacity-limit, brake-fault, and steering-loss validation scenarios;
- numerical baselines for REQ-02 and REQ-03;
- requirement-to-test traceability.

Still pending:

- execution of the validation campaign in a MATLAB installation;
- integration of the three-input fault-mask wrapper into `wawaw.slx`;
- vehicle-level nominal-versus-faulted yaw-continuity validation;
- an independently modelled dual-channel steering actuator;
- a closed-loop yaw/path controller for dynamic DBBS validation;
- FMEA, DFA, and architecture evidence for safety claims.

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
min 0.5 (B u - y_d)' Q (B u - y_d) + 0.5 rho u' R u
```

subject to physical bounds, command-rate bounds, and the active fault mask. Demand infeasibility therefore produces bounded best effort rather than a zero command.

## Requirements

- MATLAB
- Simulink
- Optimization Toolbox (`quadprog`)
- MATLAB Unit Test Framework

The exact MATLAB release used for the reference results must be recorded when the campaign is first executed.

## Running the validation

Open MATLAB in the repository root and run:

```matlab
summary = run_project_validation();
```

The command runs the class-based unit tests and all configured validation scenarios. Generated CSV, MAT, and PNG evidence is written to `validation/results/`. That directory is intentionally excluded from Git because the evidence is reproducible.

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
wawaw.slx                         Current vehicle simulation model
validation/                       Automated validation campaign
tests/                            MATLAB unit tests
docs/                             Bilingual technical documentation
run_project_validation.m          Repository-level validation entry point
```

## Documentation

- [Numerical requirements baseline](docs/requirements_baseline.en.md)
- [MATLAB/Simulink toolchain decision](docs/toolchain_decision.en.md)
- Traceability workbooks are stored under `docs/verification/` in English and French.

## Safety and scope notice

The numerical criteria and simulation results support project verification. They do not establish ISO 26262 compliance or prove vehicle safety. Requirements that depend on vehicle-level dynamics, hardware independence, fault detection, or human perception require additional analysis and physical evidence.

The CDC, Gate 1 report, internship workflow, and extracted copies are not part of this repository. Do not add them to commits.

## License

No open-source license has been assigned. Do not assume permission to reuse or redistribute the project. A license should be added only after ownership and publication rights are confirmed.
