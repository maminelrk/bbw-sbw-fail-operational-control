# Internship deliverables and gate register

## Current decision - completed academic scope SC-2026-01

The author confirms the guarantor permits adapting the CDC to the internship deliverable. The **simulation demonstrator and bilingual final-report deliverable are complete under the revised academic scope**. See the [final scope and completion record](final_scope.en.md) for delivered work and future perspectives. The current private report package is `reports/pfa_final_20260916/`; no new MATLAB simulations or defense materials were produced. This is not a universal technical-compliance or production-safety claim. All records below are historical; their measurements remain valid, but their prior report-readiness decisions are superseded.

## Historical decision — Task 2 local assessment

[TASK2-LOCAL-01](task2_assessment.en.md) is complete with **zero new MATLAB runs**. All 30 original timing/continuity diagnostics were independently recomputed; 220 old frozen-state witnesses and 216 endpoint screens transfer to 44 unchanged single-channel states. No continuous nonlinear envelope or independent nonlinear recovery guarantee is established. Six saturated transitions still fail REQ-01's healthy command-rate interpretation. The current requirement matrix and Task 3 decision are in that assessment; older matrices below are historical.

**Task 3 packaging/report preparation may proceed. Unqualified technical completion may not.** A working simulation demonstrator preserves the project premise, but eliminating all identified failures still requires a justified transition correction and focused validation. No new simulation is scheduled. Existing guarantor approval is not extended to newly discovered issues. Previous report/slide packages need revision before use.

## Historical continuation — Task 1

The project author confirms the guarantor's approval of the outstanding decisions submitted to him. Earlier references below to pending guarantor decisions describe the historical handover, not a renewed approval request. This confirmation does not waive numerical criteria or establish physical safety independence. Additional academic supervisors: Pr Said Ben Alla and Pr Issam Amellal.

Controller `ALLOC-2026-04` completed the [Task 1 correction campaign](task1_control.en.md): the original front-loss sideslip and centred-DBBS failures are corrected. All 45 unit tests, five nominal maneuvers, 30 original fault-case diagnostics and four refined checks pass. Six added saturated-braking fault transitions expose a physical-bound/rate conflict; `Task1Passed=false`, and Gate 3 remains open. The archive and 54 time histories have been audited locally. Further work prioritises local evidence analysis and bilingual reporting, with no additional MATLAB campaign scheduled under the author's usage constraint. Historical evidence is preserved. The previous private final-report package must be revised; it is not the final report of the improved demonstrator.

## Historical handover baseline

Updated 16 September 2026. Status is based on available evidence, not the original calendar dates. MATLAB Online is available. The corrected Gate 2 run passed every numerical check on 15 September 2026 at 23:33:46 UTC; the earlier saturation failure is preserved separately. Independent Python checks are not labelled as MATLAB results. No supervisor acceptance is recorded.

| Gate / deliverable | Work available | Gate status / remaining acceptance |
|---|---|---|
| G1 / D1 | Original architecture report plus bilingual LaTeX closure addendum; numerical baseline; fault semantics and D4 dependencies clarified | Decisions documented; supervisor review and sensor/path scope decisions pending |
| G2 / D2 | Nonlinear 13-state plant, nominal QP integration, plant/steering benches, five maneuvers, bilingual evidence runner; first MATLAB run preserved | 36 unit tests, 3 plant cases, 4 steering cases, 5 maneuvers and convergence passed; verified local archives, 46 report-ready bilingual figures and two 17-page LaTeX reports available; supervisor review pending |
| G3 / D3 | Baseline and supplementary MATLAB evidence audited locally; 41 supplementary unit tests; refinement, nonlinear authority, force-aligned braking and 300 envelope probes completed | Open: centered DBBS path failures, front-loss heavy-braking sideslip failure, continuous envelope and uncovered fault modes |
| G3 / D4 | Detailed FMEA, verified qualitative cut sets and final eight-dependency review, D4-FINAL-01 | Paper review complete; conditional rationale, independence and supervisor acceptance not demonstrated |
| G4 / D5 | Bilingual 21-page final technical reports, 13-slide editable defense decks, source/evidence manifest and handover guide | Reporting package prepared privately; student review, defense rehearsal and supervisor acceptance pending |
| Extended / D6 | Candidate steering-plus-brake-circuit failure retained | Deferred; circuit split and standardized maneuver not chosen or validated |

Completed **work packages**, not formally closed gates: fault timing infrastructure; nominal/fault comparison protocol; draft D4; bilingual technical glossary; MATLAB handoff plan. There is no automatic conversion from a numerical pass to gate acceptance.

## Historical requirement-to-evidence map (superseded by TASK2-LOCAL-01)

Report-preparation tasks 1 and 2 are complete as documentation: [detailed requirements/evidence matrix](../reports/final_preparation/requirements_evidence.en.md) and [deviation register](../reports/final_preparation/deviations.en.md), with French counterparts. These links target private, Git-ignored local reports and will not resolve in a public checkout. They refine the compact map below; they do not close Gate 3, waive failures or record supervisor acceptance. No MATLAB rerun was needed. The earlier XLSX workbooks remain historical snapshots. The [final safety review](../reports/final_preparation/safety_review.en.md) now completes task 3 at paper-study level. See the [handover guide](handover.en.md).

| Requirement | Implementation / test evidence | Remaining limit |
|---|---|---|
| REQ-01 | Allocator bounds; nonlinear tire/rate/load checks; TestGate2Integration, TestGate3Preparation and TestAllocatorSaturation; G2/G3 runners | Corrected G2 and all 30 baseline G3 numerical checks passed; additional high-demand cases and real torque/road-load validation remain separate |
| REQ-02 mask ≤10 ms | `fault_event_masks`; physical and known histories; G3 mask timing | Injected diagnosis only; actual detector/scheduler absent |
| REQ-02 response ≤50 ms + 100 ms dwell | `recovery_band_metric`; actual nonlinear output versus frozen-state QP oracle | 15% nonlinear envelope and oracle interpretation pending; diagnostic is not compliance |
| REQ-02 continuity | Matched yaw difference over 200 ms from physical onset | Provisional threshold; no driver-perception validation |
| REQ-03a ≥60% straight braking | Force-aligned nonlinear witnesses: worst retained-capacity lower bound 61.264%; heavy-braking allocator tests completed | Front-loss dynamics exceed sideslip domain (0.2416 versus 0.15 rad); static capacity does not close transient compliance |
| REQ-03b ≥60% angle/rate | A/B loss common-rack bench and integrated faults | Functional capacity assumptions; no loaded motor/rack evidence |
| REQ-03c DBBS | Capped 0.35g frozen-state yaw witness guarantees at least 16.690% of conservative nominal upper bound; centered failures persist after refinement | Path limit still failed; instantaneous yaw authority is not maneuver/transient compliance |
| REQ-04 | FMEA F01–F18, FTA and DFA D01–D08 | Hardware dependencies, sensing, shared ECU and supervisor review open |
| REQ-05/06 | Explicit extended-scope register | Not implemented as accepted evidence; no ISO maneuver claim |

The old traceability workbooks are historical snapshots. This register and the Gate 2/Gate 3 catalogs are the current source of status until those workbooks are regenerated.

Supplementary sampled-envelope audit: 240/300 frozen-state matches, 236/300 endpoint screens passed. All 220 single-channel probes match statically; four miss the chosen 50 ms endpoint screen. Twenty other matches are effectively zero-demand DBBS probes; 60 active DBBS probes remain inconclusive. No continuous 15%-reserve envelope or REQ-02 compliance is claimed. Protocol: [English](gate3_assessment.en.md) / [French](gate3_assessment.fr.md). Detailed bilingual assessment reports remain local in `reports/gate3_assessment/`.

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

## MATLAB continuation

1. Review the completed Gate 2 package from 15 September 2026, 23:33:46 UTC. Both downloaded archives, source hashes and raw data are verified. The final 46 bilingual figures display authentic MATLAB CSV data using Matplotlib, with no new simulation; the native MATLAB re-export is retained separately. Two 17-page LaTeX reports are ready locally. Supervisor acceptance remains pending.
2. The baseline MATLAB Gate 3 campaign and its independent local CSV audit are complete. Preserve its four centered DBBS failures; follow [the supplementary assessment protocol](gate3_assessment.en.md) for refinement, authority and sampled-envelope evidence.
3. Use the completed matrix and deviation register to state partial validation and the agreed implementation scope. The paper-based safety-analysis review is complete; seek supervisor decisions on the remaining deviations. Further controller work/tests are conditional on that decision, not prerequisites to begin report writing.
4. The final bilingual report and defense now use verified saved evidence. Review the private package and submit it for supervisor assessment. No further MATLAB run is needed for this documentary step.

All source reports, generated evidence and PDFs remain local/ignored. No upload or publication is authorized by generating these deliverables.
