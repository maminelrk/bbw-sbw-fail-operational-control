# Task 2 — local validation assessment and Task 3 decision

Final-report scope update: [SC-2026-01](final_scope.en.md) now defines academic completion following the author's confirmation of guarantor agreement. This audit remains a preserved numerical record; its earlier conditional report-readiness decision is historical. Broader conditions are future perspectives, not newly demonstrated capabilities.

[Français](task2_assessment.fr.md). Revision **TASK2-LOCAL-01**, 16 September 2026.

**Local assessment complete; technical validation remains partial. Proceed to Task 3 packaging, not to unconditional engineering closure.** No MATLAB Online session, new vehicle simulation, controller change or acceptance-threshold change was used for this assessment.

## 1. Purpose and evidence

The premise remains integrated, fault-aware BbW/SbW allocation with retained braking and steering/yaw capability, demonstrated on a nonlinear vehicle simulation. It has not been reduced to merely detecting a fault or stopping the vehicle. Nevertheless, preserving that premise does not mean every requirement has been achieved.

The project author has confirmed guarantor approval of the previously submitted issues. That confirmation is retained; it is not extended to the newly exposed saturated-transition conflict, nor treated as a numerical waiver. Additional academic supervisors are Pr Said Ben Alla and Pr Issam Amellal. No formal acceptance signature or date is invented.

Inputs: preserved Gate 2 and Gate 3 baselines; audited nonlinear authority/envelope witnesses; the Task 1 candidate `ALLOC-2026-04`, vehicle `REF-2026-02`; and its independently audited 54 time histories. Current quantitative outputs are in private `validation/results/task2_local_20260916_v2/`. The earlier `task2_local_20260916/` is a retained preliminary audit, not the current output. `audit.json` hashes every input read and the audit script. Sources and physical parameters are checked for compatibility before reusing older evidence. No raw report/CDC material is published.

## 2. Independent timing arithmetic — not an independent nonlinear oracle

The local implementation recomputes physical onset, delivered diagnosis, mask agreement, failed-brake isolation, the 10% error-band entry with a complete 100 ms dwell, and the nominal/faulted yaw difference in the first 200 ms. Eight Python unit tests cover timing boundaries, interrupted dwell, insufficient data, missing samples, nonfinite errors and invalid time grids.

- All **30** original fault cases pass the saved mask, affine recovery and yaw-continuity diagnostics; **22** concern single channels and **8** concern complete steering-drive-loss backup.
- Mask delay from delivered diagnosis is **0 ms** in this sampled implementation. Injected detection delays remain separate; ECU scheduling is not measured.
- All 30 cases are **already inside the affine oracle's band at the diagnosis sample**, and remain there for 100 ms. Their **0 ms band-entry delay is not an experimentally measured physical settling time**.
- Maximum first-200-ms yaw difference is **0.013688 rad/s**, below 0.05 rad/s.
- The output being checked is actual nonlinear plant output, but the comparison target and scales remain the archived affine allocator oracle. Recomputing arithmetic independently does not produce a new independent nonlinear best-achievable trajectory. The 90%/50 ms recovery claim and full REQ-02 therefore remain **not established** beyond the stated diagnostic.

Per-case evidence: `recovery.csv`. No pass is manufactured from a missing or truncated dwell window.

## 3. Operational envelope and evidence transfer

The original assessment contained **300 probes at 60 sampled states**, with 240 feasible frozen-state witnesses and 236 passing 50 ms endpoint screens. The other 60 searches found no witness; this is not proof of infeasibility.

The audit compares all 13 state components, demand, physical fault mask and preceding command at the original sample times. Only roundoff-level differences are accepted for reuse; an approximately similar maneuver is not enough.

| Evidence | Transfer to corrected controller |
|---|---|
| 44 sampled states from the 22 single-channel cases | Inputs match; 220 frozen-state witnesses can be reused |
| Corresponding 50 ms open-loop endpoint screens | 216/220 pass; four remain unsuccessful candidate rollouts |
| 16 DBBS sampled states | Inputs differ; no automatic transfer of the old 80 probe outcomes |
| Continuous 15% reserve along a trajectory | Not established by either campaign |
| Full 100 ms dwell against independent nonlinear best-achievable output | Not established by the 50 ms endpoint screens |

The four unsuccessful transferred endpoint constructions are one probe each at `G3-FR-D50` sample 1, `G3-RL-D50` sample 1, `G3-BRK-RL` sample 2 and `G3-BRK-RR` sample 2. They are not four demonstrated closed-loop recovery failures: each is one feasible-witness command ramp, not an optimal reachable-set calculation. Conversely, successful corners do not prove all interior points of a nonlinear image are feasible. Zero-demand axes have zero box width and provide no reserve coverage in that direction.

The justified domain is the **enumerated tested maneuvers**, not a rectangular certified envelope: initial speed 60 km/h, friction 0.90, fixed reference vehicle, ideal state feedback, fail-silent channel losses and injected diagnosis delays. State evolution during a run is not a parameter sweep across independently selected operating conditions.

Per-sample evidence: `envelope_transfer.csv`. Historical physical witnesses remain useful because the plant equations are unchanged, but do not prove the corrected controller reaches each witness.

## 4. Comparison and available robustness evidence

| Metric | Original controller | Corrected controller | Interpretation |
|---|---:|---:|---|
| Worst centred DBBS path deviation | 0.508632 m | 0.294527 m | Original failure corrected; limit 0.50 m |
| Worst DBBS yaw RMSE | 0.017640 rad/s | 0.011461 rad/s | Below 0.03 rad/s |
| Worst DBBS peak deceleration | 0.257737 g | 0.277080 g | Tracking improvement costs more braking; still below 0.35 g |
| Front-loss peak sideslip | 0.241615 rad | 0.060513 rad | Original domain failure corrected; limit 0.15 rad |
| Front-loss retained braking | 63.6789% | 61.1147% | Stability improvement costs 2.5642 percentage points; only 1.1147 points above 60% |
| Five nominal maneuver summary metrics | Reference | Match within audit tolerance | No detected regression in the selected saved metrics |

All eight corrected DBBS maneuver evaluations pass. The old-versus-new comparison is a **same-architecture controller-revision comparison**, not a comparison against an independently designed pseudoinverse or rule-based controller. No such alternative-controller results exist; none are fabricated or required merely to change the project title from study to demonstrator.

Both centred DBBS 1 ms checks pass the pre-existing refinement screen: maximum peak-path change **0.731 mm**, yaw-rate change **0.000157 rad/s**, and speed change **0.002193 m/s**. Front-loss refined checks retain the acceptance result; maximum sampled yaw/speed differences are **0.000589 rad/s / 0.002861 m/s**. This supports numerical consistency, not robustness to unknown parameters.

Available sensitivity evidence includes diagnosis delays 0/10/50 ms, both DBBS directions (negative direction at 10 ms only), centred/turning rack loss, symmetric brake-corner cases and the targeted time-step refinement. There is **no demonstrated robustness sweep** over friction, mass, CG, tire stiffness, actuator lag, sensor noise, estimation bias or other initial speeds. The narrow braking margin makes that limitation material. Do not interpret the six-value design-tuning sweep as an independent robustness study.

Evidence: `comparison.csv`, `braking_comparison.csv`, `nominal_regression.csv`, `refinement.csv`.

## 5. Saturated transitions — disposition without changing criteria

All six added front-loss transitions still fail healthy command-rate/no-override checks. At onset, the healthy front command is approximately -5614.37 N, the new physical lower bound is -5123.93 N, and only 80 N release is permitted per step. At least **490.44 N** release is required, so the instantaneous intervals do not intersect. This proves infeasibility **at that recorded state**, not that every possible anticipatory control design must fail.

The test asks for **120% of the nominal global braking bound** at onset. Thus its requested force is provably outside even the nominal physical outer bound, and cannot have 15% unused post-fault authority. The in-envelope yaw-continuity clause cannot be claimed applicable merely because this test exists. However, **REQ-01's healthy actuator limits are not waived by demand infeasibility**. The logged override remains a genuine engineering nonconformance under the current command-as-contact-force interpretation. The existing best-effort fallback prioritises physical bounds; it is not a rate-compliant actuator solution.

Additional descriptive results:

| Diagnosis delay | Maximum nominal/faulted yaw difference in 200 ms | First full 100 ms dwell meeting braking >=60% and yaw hold limit, after diagnosis |
|---|---:|---:|
| 0 ms | 0.050622 rad/s | 148 ms |
| 10 ms | 0.060137 rad/s | 182 ms |
| 50 ms | 0.105002 rad/s | No complete qualifying dwell before 1.9 s |

These are mirrored across FL/FR and **are not substituted for REQ-02's oracle-based recovery definition**. All exceed the 0.05 rad/s proxy numerically, outside its demonstrated applicability. The last row means insufficient qualifying plateau evidence, not “never recovers.” None allows a blanket bumpless-transition claim. All remain inside the 0.15 rad sideslip domain.

Defensible resolution routes, neither implemented here:

1. Separate rate-limited actuator demand/state from instantaneous tire-contact force saturation, and justify any needed load-transfer dynamics. Validate the revised model and allocator in a focused regression; do not merely exempt an offending sample.
2. Define an explicitly accepted operational scope and outside-envelope transition policy, retaining this failed stress test. Exclusion alone does not show that the current system enforces that scope, and does not demonstrate the original all-times rate requirement.

The first route best supports the user's objective of eliminating failures. The second supports an honestly limited academic deliverable only with an explicit acceptance decision. Existing approval of earlier issues is not recorded as approval of either route.

## 6. Current requirement-to-evidence matrix

This revision supersedes earlier outcome summaries and the historical pre-correction traceability workbooks for current status; original evidence remains immutable.

| Clause / claim | Evidence and verdict |
|---|---|
| REQ-01, nominal and original fault cases | Tested checks pass; five nominal cases and 30 original fault-case diagnostics |
| REQ-01, added saturated transitions | **FAIL**: six healthy command-rate conflicts; universal/all-times compliance not achieved |
| REQ-02 mask activation <=10 ms | **TESTED PASS** in original sampled cases; not ECU/detection latency validation |
| REQ-02 independent physical recovery <=50 ms +100 ms dwell | **PARTIAL / NOT ESTABLISHED**: affine diagnostics pass, independent nonlinear reference absent |
| REQ-02 continuity +15% reserve applicability | **PARTIAL**: yaw diagnostics pass in originals, 44 matching sampled states, no continuous envelope |
| REQ-03a braking >=60% with yaw condition | **TESTED PASS / PARTIAL parent claim**: minimum dynamic front-loss plateau 61.1147%; independent force-aligned static witness >=61.2636%; not arbitrary-state transient assurance |
| REQ-03b single steering channel | **FUNCTIONAL MODEL PASS**: prior bench retains full range and 60% rate; road-load torque/power independence remains assumed |
| REQ-03c tested DBBS pulse | **TESTED PASS**: 8/8; both centred directions retain pass at 1 ms |
| REQ-03c yaw authority >=15% | **FROZEN-CONDITION WITNESS**: 16.6900% conservative lower bound with 0.35 g cap; not universal reachable authority |
| REQ-04 architecture rationale | Existing paper-based FMEA/FTA/DFA is reusable with revised findings; no physical independence or ASIL certification established |
| Broad parameter robustness / simpler-controller comparison | **NOT DEMONSTRATED**; distinguish useful strengthening work from existing verified outcomes |
| Dual-fault extension / standardised maneuver | **DEFERRED EXTENSIONS**, not relabelled as completed core tests |

The static authority ratios use nominal **upper bounds**, making the retained ratios conservative at the evaluated conditions. They do not use the old unconstrained raw-braking percentage as straight-line capability evidence.

## 7. Decision for Task 3

**GO for reproducible packaging and report preparation; NO-GO for an unqualified “finished, fully compliant fail-operational system” declaration.** The project has a working simulated controller and meaningful demonstrated fault tolerance, not just a paper study. Its technical premise survives. Its full-compliance claim does not yet follow from the evidence.

Task 3 can now freeze the exact tested code/evidence, provide a local replay of saved figures, align bilingual documentation and safety analysis, list pass/fail/unverified clauses, and prepare the handover. It must retain `Task1Passed=false`, Gate 3 open, and a clearly visible saturated-transition issue. A replay must be labelled playback, not a live simulation. Historical report/deck packages must not be submitted unchanged.

For **academic completion with declared limitations**, the remaining local packaging/reporting work can proceed today without more MATLAB. For the user's stronger **all identified failures eliminated** target, an engineering correction and focused validation remain necessary. No evidence-only rewording can satisfy that target. If a future run becomes necessary, propose the exact model change and smallest discriminating cases first; no broad campaign is authorised or scheduled by this note.

## 8. Reproduce the local assessment

Python 3.10+ standard library; tested with local Python 3.12. No MATLAB licence, network or scientific libraries required:

```text
python validation/test_audit_task2.py
python validation/audit_task2.py validation/results/task2_local_new
```

Private prerequisite folders must be present as listed in section 1. Existing destination folders are rejected. The script reads saved CSV/JSON/source files and writes new audit products only; it never runs the plant, changes thresholds, calls MATLAB or modifies historical evidence. Its JSON distinguishes completed local work from requirement compliance.
