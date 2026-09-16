# Internship handover and reproduction guide

[Français](handover.fr.md). Revision HANDOVER-01, 16 September 2026.

## Status

**Historical handover below.** The current completed academic deliverable is defined by [SC-2026-01](final_scope.en.md), following the author's confirmation that the guarantor permits adapting the CDC. Use the private `reports/pfa_final_20260916/` English/French reports and tested-source snapshot. Earlier report, deck and workbook packages are historical. The final package contains no new slides or defense scripts; original numerical records remain unchanged.

The simulation study and reporting work package are prepared for supervisor review. Gate 2 numerical checks passed. Gate 3 is partially validated, with centered DBBS path failures and front-brake-loss heavy-braking domain failures retained. The safety rationale is conditional. No supervisor acceptance or full CDC compliance is asserted. See [current status](project_status.en.md).

MATLAB is **not required to read, review or submit the saved report and evidence**. MATLAB with Optimization Toolbox (`quadprog` and `fmincon`) is required to rerun or change the reference simulations. The recorded reference environment is MATLAB Online R2026a Update 5. Do not claim every earlier MATLAB release has been tested; the supplementary plotting setup uses the recorded release's figure-theme property. Simulink is required only for the legacy `.slx` prototype, not the reference scripted campaigns.

## Private deliverables

The local `reports/final_report/` directory contains the FR/EN final technical report in PDF/LaTeX, FR/EN editable defense decks, and its bilingual README. `reports/final_preparation/` contains the current requirements matrix, deviations and final safety review. These folders are deliberately absent from a public checkout. The private package manifest identifies local source and evidence files by SHA-256. Historical tested-run manifests take precedence over the later handover snapshot when identifying what actually ran.

Reports, CDC/workflow documents, generated evidence and private manifests must remain out of public Git. Preparing them does not authorize publication. A private archive is for local transfer to the supervisor only, subject to the user's choice of recipient.

## Optional MATLAB reproduction

**Use a fresh copy of the project in a new folder.** Gate 2 and Gate 3 entry points write fixed relative results folders and can overwrite earlier results. Do not run them over the audited evidence. Their unit counts may increase with the source revision; preserve the new manifest instead of rewriting historical counts.

From the fresh project root:

```matlab
addpath(pwd, fullfile(pwd,'validation'));
gate2 = run_gate2_validation();
gate3 = run_gate3_validation();
baseline = fullfile(pwd,'validation','results','gate3');
run_gate3_convergence(baseline, ...
    fullfile(pwd,'validation','results','convergence'));
run_gate3_supplementary(baseline, ...
    fullfile(pwd,'validation','results','supplementary'));
run_gate3_straight_path_check( ...
    fullfile(pwd,'validation','results','straight_path'));
```

The convergence folder is intentionally a sibling of `supplementary`; the supplementary runner copies that existing refinement evidence. The three assessment destination folders must not already exist. Expected outcome includes failures, not an all-green Gate 3. Compare numeric results with saved evidence and retain source/version differences.

For a plant-only check: `run_plant_validation()`. For unit tests: `runtests('tests','IncludeSubfolders',true)`. Failed checks or solver errors must remain visible. Do not alter thresholds merely to obtain a pass.

## Report rebuilding

The private master is `reports/final_report/report.tex` with `final_report.en.tex` and `final_report.fr.tex` wrappers. Build from their directory with Tectonic or a compatible LaTeX installation. The master intentionally reuses private Gate 1 logo assets and verified Gate 2/Gate 3 figures through relative paths, so preserve the folder layout. The private transfer archive includes those dependencies.

The current technical entry points remain `allocator.m`, `vehicle_derivatives_block.m`, `vehicle_dynamics_quantities.m`, `steering_actuator_dynamics.m`, `get_params.m` and the validation runners. No model/controller change was made in the report-finalization step.

## Human submission checklist

1. Students read the report and slides, verify identities and institutional formatting, and confirm they can explain the implementation and limitations.
2. Supervisor decides on the numerical baseline, MATLAB deviation, fault scope and whether declared failures are acceptable study outcomes.
3. Rehearse the 13-slide defense and review its speaker notes.
4. Keep the frozen private package and original archives. Full MAT/log for the final straight-path witness remain in MATLAB Drive; the exact hashed CSV and local independent audit are available. Download the remaining MAT/log for long-term archival completeness when convenient; no new simulation is necessary.

Only if the supervisor requires improved performance or a broader scope should a new technical iteration and MATLAB campaign begin. An accepted limitation never changes the historical test result from FAIL to PASS.
