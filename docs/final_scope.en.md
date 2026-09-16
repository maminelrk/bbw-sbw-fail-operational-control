# Final academic scope and completion

[Français](final_scope.fr.md). SC-2026-01, 16 September 2026.

## Decision and authority

The project author confirms that the guarantor permits adapting the CDC requirements to the academic internship deliverable. The final scope is therefore a **completed, reproducible simulation demonstrator**, not an all-condition automotive product or a certification claim. This record reflects the author's confirmation; it does not invent signed minutes, a signature or formal industrial acceptance.

This scope decision supersedes earlier statements that report completion must await closure of every original CDC criterion. Numerical benchmarks remain unchanged as engineering references. Historical test records and their flags are not rewritten.

## Completed deliverables

- Four-brake, shared-rack/two-drive architecture and explicit actuator-availability masks.
- Nonlinear 13-state vehicle model with documented parameter provenance and plant checks.
- Bounded best-effort QP allocation with actuator constraints and corrected DBBS/front-loss tuning.
- Saved MATLAB evidence: 45 unit tests, five nominal maneuvers, 30 original fault-case diagnostics and four targeted refinement checks.
- All eight assessed DBBS pulses meet the chosen path, yaw-error and deceleration criteria. The assessed front-loss authority maneuvers retain at least 61.1% of the nominal upper-bound braking reference, with peak sideslip about 0.0605 rad.
- Local evidence audit, controller comparison, authority studies, conditional qualitative safety analysis and reproducibility package.
- Final English and French LaTeX reports, with acknowledgements, company context, methods, numerical results, scope and future perspectives. No new defense material is part of this deliverable.

## Explicit scope boundary and future perspectives

Completion applies to the documented reference model and assessed maneuver set. It does not establish a continuous safe operating envelope. Future development covers abrupt actuator loss during fully saturated braking, coordinated force/rate transition handling, independent nonlinear recovery verification, wider parameter/road/noise variation, hardware-loaded steering performance, sensor/diagnosis design, dependent-failure mitigation and vehicle-level validation.

The saved saturated-transition measurements are retained and quantified in the report's perspectives chapter. Moving them outside the final academic acceptance scope does not change those measured outcomes or extend the demonstrated operating domain.

## Handover

Task 3 is completed as local evidence consolidation and source freezing. Task 4 contains only two final report editions. Sources, PDFs and a SHA-256 manifest are in the private `reports/pfa_final_20260916/` folder; final PDF copies are in `output/pdf/`. These paths are deliberately absent from public Git. Earlier report/deck packages are historical and are not the current final submission.

No new MATLAB run was used for final assembly. The [Task 2 assessment](task2_assessment.en.md) remains the detailed numerical audit, read with this revised completion scope. Academic supervisors: Pr Said Ben Alla and Pr Issam Amellal. Project guarantor: Elmehdi Chokri.
