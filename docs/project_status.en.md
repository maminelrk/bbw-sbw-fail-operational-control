# Internship deliverables and gate register

Updated 11 September 2026. Status is based on available evidence, not the original calendar dates. MATLAB is unavailable; source code and independent Python checks are not labelled as MATLAB results. No supervisor acceptance is recorded.

| Gate / deliverable | Work available | Gate status / remaining acceptance |
|---|---|---|
| G1 / D1 | Original architecture report plus bilingual LaTeX closure addendum; numerical baseline; fault semantics and D4 dependencies clarified | Decisions documented; supervisor review and sensor/path scope decisions pending |
| G2 / D2 | Nonlinear 13-state plant, nominal QP integration, plant/steering benches, five maneuvers, bilingual evidence runner | Implemented; MATLAB execution and results review pending |
| G3 / D3 | 30-case delayed-fault campaign, four matched nominal references, comparison metrics and bilingual figures; independent numerical cross-check | Preliminary work; MATLAB, operational-envelope/authority assessment and uncovered fault modes remain open |
| G3 / D4 | FMEA register, qualitative fault-tree logic and eight-entry dependency register | Draft complete for review; independence and hardware mappings not demonstrated |
| G4 / D5 | Bilingual report material, evidence plan and reproducibility instructions | Final results, discussion and defense slides pending |
| Extended / D6 | Candidate steering-plus-brake-circuit failure retained | Deferred; circuit split and standardized maneuver not chosen or validated |

Completed **work packages**, not formally closed gates: fault timing infrastructure; nominal/fault comparison protocol; draft D4; bilingual technical glossary; MATLAB handoff plan. There is no automatic conversion from a numerical pass to gate acceptance.

## Current requirement-to-evidence map

| Requirement | Implementation / test evidence | Remaining limit |
|---|---|---|
| REQ-01 | Allocator bounds; nonlinear tire/rate/load checks; TestGate2Integration and TestGate3Preparation; G2/G3 runners | MATLAB pending; no real torque or road-load validation |
| REQ-02 mask ≤10 ms | `fault_event_masks`; physical and known histories; G3 mask timing | Injected diagnosis only; actual detector/scheduler absent |
| REQ-02 response ≤50 ms + 100 ms dwell | `recovery_band_metric`; actual nonlinear output versus frozen-state QP oracle | 15% nonlinear envelope and oracle interpretation pending; diagnostic is not compliance |
| REQ-02 continuity | Matched yaw difference over 200 ms from physical onset | Provisional threshold; no driver-perception validation |
| REQ-03a ≥60% straight braking | Dynamic braking fault cases; `straight_braking_screening` distinguishes raw capacity from zero-yaw braking | Maximum active-steering-assisted braking authority not established |
| REQ-03b ≥60% angle/rate | A/B loss common-rack bench and integrated faults | Functional capacity assumptions; no loaded motor/rack evidence |
| REQ-03c DBBS | Positive/mirrored ±0.15 rad/s pulses, centered/turning rack losses; yaw/path/deceleration metrics | Tested maneuvers only; 15% maximum yaw authority and robustness not established |
| REQ-04 | FMEA F01–F18, FTA and DFA D01–D08 | Hardware dependencies, sensing, shared ECU and supervisor review open |
| REQ-05/06 | Explicit extended-scope register | Not implemented as accepted evidence; no ISO maneuver claim |

The old traceability workbooks are historical snapshots. This register and the Gate 2/Gate 3 catalogs are the current source of status until those workbooks are regenerated.

## Report assembly plan

1. Context, internship objectives, CDC scope and agreed MATLAB deviation.
2. Literature and corrected architecture: four brakes, two steering drives, one rack, DBBS meaning.
3. Mathematical plant, parameter provenance and explicit assumptions.
4. QP formulation, constraints, infeasible-demand behavior and numerical implementation.
5. Allocator-free and nominal tests: protocol, plots, metrics, timestep check.
6. Fault injection: physical onset versus diagnosis, matched references, degraded results and limitations.
7. FMEA/FTA/DFA and the conditional ASIL decomposition argument.
8. Discussion: what the simulations establish, what they do not, sensitivity and outstanding risks.
9. Conclusion and future work; extended work kept in a separate annex if eventually executed.

Use French and English sources for every chapter. Every figure caption must identify the execution engine, parameter/protocol revision, initial conditions and whether the result is preliminary. Do not use an independent Python plot with a MATLAB caption.

## When MATLAB is available

1. Run `run_gate2_validation()` in the repository root with Optimization Toolbox. Save all outputs, including failed cases. Review the unit tests, plant checks, steering bench, nominal maneuvers and convergence comparison.
2. Run `run_gate3_validation()`. Compare MATLAB results against the preliminary checks; inspect differences rather than assuming the solvers are equivalent.
3. Resolve the remaining nonlinear envelope/authority tests, sensor/path semantics and safety-analysis review. MATLAB availability alone does not close these engineering questions.
4. Replace or accompany preliminary figures with verified MATLAB evidence, then submit D2–D4 for review and assemble the final report and defense.

All source reports, generated evidence and PDFs remain local/ignored. No upload or publication is authorized by generating these deliverables.
