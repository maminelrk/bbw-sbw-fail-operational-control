# First MATLAB Online Gate 2 execution

[Français](README.fr.md)

## Evidence identity

- Start: 2026-09-15 19:04:40 UTC; elapsed time: 297.134 s.
- Engine: MATLAB Online Basic, R2026a Update 5, version 26.1.0.3346908; Optimization Toolbox 26.1; Linux.
- Source: commit `a775806a5b877f8aad7e70e7baa1cc81a3e4e0ab`, branch `main`, clean working tree recorded in the run manifest.
- Entry point: `run_gate2_validation()`; no source or threshold changes made during this execution.
- Final recorded status: **CHECKS_FAILED**. This is an executed MATLAB campaign, not an independent Python cross-check. Gate 2 is not closed. Gate 3 was not run.

## Results

| Check group | Result |
|---|---|
| Unit tests | 31/31 passed |
| Allocator-free plant scenarios | 3/3 passed |
| Common-rack steering bench | 4/4 passed |
| Normal tracking maneuvers | G2-BRK, G2-STR, G2-CMB and G2-YAW passed |
| Saturation and release | G2-SAT failed behavior and operating-domain checks |
| Timestep convergence | Passed: peak yaw difference 0.0002676114 rad/s, speed difference 0.0005565032 m/s |

All five integrated cases passed the recorded finite-state, load, friction, rate, command-bound and solver-success checks; no rate overrides occurred. Those checks do not imply successful behavior or physical validity outside the operating domain.

| Maneuver | Force RMSE [N] | Yaw RMSE [rad/s] | Overall |
|---|---:|---:|---|
| G2-BRK | 44.645091 | 0.000000041319 | Pass |
| G2-STR | 20.619945 | 0.002130510 | Pass |
| G2-CMB | 28.631067 | 0.001793353 | Pass |
| G2-YAW | 6.276130 | 0.001721762 | Pass |
| G2-SAT | 5635.112433 | 0.023060951 | Fail |

Force RMSE is diagnostic, not the acceptance criterion for the intentionally infeasible saturation demand.

## Failed saturation case

- Capacity plateau: 0.9968786273 of nominal friction-limited braking, above the 0.95 target.
- Peak absolute yaw rate: 0.0792079558 rad/s, above the 0.0001 rad/s straight-line criterion.
- Maximum absolute longitudinal force from 3.2 s onward: 9172.1682 N, above the 100 N release criterion.
- Minimum speed: 0.4971831695 m/s, below the strict 0.5 m/s operating-domain floor.
- Peak absolute steering angle: 35 degrees (mechanical limit).

The time histories show asymmetric braking and unintended steering during a nominal straight saturation maneuver, followed by persistent front braking after release. This differs materially from the earlier independent numerical cross-check. Solver exit flags remained positive; solver success is not closed-loop validation. The root cause is not yet established. Results after crossing the low-speed floor must not be interpreted as validated low-speed vehicle behavior.

Next: diagnose the saturation/combined-slip allocation and release behavior, add a regression covering the discrepancy, and rerun Gate 2 without weakening the acceptance thresholds. Review Gate 2 before starting Gate 3.

## Where the raw evidence is preserved

MATLAB Drive project folder: `/MATLAB Drive/bbw-sbw-fail-operational-control`.

- `validation/results/gate2/`: manifest, unit tests, steering bench, all five maneuver time histories/metrics/MAT files and French/English figures, convergence results, `gate2_results.mat`.
- `validation/results/plant/`: three allocator-free cases and their summaries/figures.
- `validation/results/gate2_console_20260915_190440.txt`: saved execution log.
- `validation/results/gate2_execution_summary.json`, `gate2_saturation_diagnostic.json`, `gate2_saturation_samples.csv`: extracted diagnostic summaries.
- Complete archive: `/MATLAB Drive/gate2_matlab_20260915_190440.zip`.

The archive was created in MATLAB Drive and a browser download was requested, but a local downloaded copy was not verified. This local note records metrics read from the MATLAB UI; it does not substitute for the raw evidence archive. No reports or generated evidence were pushed to GitHub.
