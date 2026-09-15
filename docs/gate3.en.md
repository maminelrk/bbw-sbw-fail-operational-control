# Gate 3 fault-campaign preparation

Protocol **G3-PREP-01**, vehicle **REF-2026-02**. Implementation and preliminary analysis, not a closed validation gate. MATLAB remains the execution reference. No detection algorithm, production ECU or hardware independence is validated by this campaign.

## Fault semantics

The model distinguishes physical health `h_physical` from the health flags delivered to control `h_known`. The plant loses a channel at physical onset `t_p`; the allocator learns about it at `t_flag = t_p + detection_delay`, rounded up to the first simulation sample. Both histories are logged. Faults are permanent; no automatic recovery is modeled.

- Brake loss: the affected contact force becomes zero immediately; its internal actuator state decays. This is a fail-silent, released-brake assumption, not a stuck-on brake.
- Steering A/B loss: the failed motor contributes no rack velocity. Before diagnosis the surviving motor retains its former command share; after diagnosis the sharing is recomputed. The actual angle and healthy motor state remain continuous.
- Complete steering-drive loss: both contributions are zero and the rack holds its actual angle at onset. Tests distinguish a centered rack from loss during a turn. This is not a free rack, an arbitrary jam model or a sensor failure.
- A power-path or communication-path loss maps to a channel-loss test only **if local isolation produces the same fail-silent physical effect**. Packet hold, timeout behavior, bus corruption, common-bus loss and unintended actuation are not covered by changing the cause label.

Full-state feedback is ideal. Detection delay is an injected assumption, not an estimated diagnostic performance. The 0, 10 and 50 ms cases are sensitivity points, not sourced hardware timings or an approved fault-tolerant time interval.

## Catalog

`validation/gate3_fault_cases.m` creates 30 cases:

| Cases | Maneuver and fault | Timing |
|---|---|---|
| 18 | Each of FL/FR/RL/RR/steering A/steering B lost during combined braking/steering | Onset 2 s; diagnosis delay 0/10/50 ms |
| 6 | Both steering drives lost; positive DBBS yaw pulse | Onset 1 s (centered) or 3 s (turning); delay 0/10/50 ms |
| 4 | Each brake corner lost during progressive straight braking | Onset 2 s; ideal diagnosis |
| 2 | Negative/mirrored DBBS yaw pulse | Onset 1 or 3 s; delay 10 ms |

Four matched nominal references are generated: combined, braking, positive DBBS and negative DBBS. All start at 60 km/h. The DBBS reference rises smoothly from zero to ±0.15 rad/s between 1.5 and 2.5 s, holds to 4.5 s and returns to zero by 5.5 s; the record ends at 6 s. No propulsion or speed-restoration controller is added. Braking required for DBBS therefore reduces speed. The pulse is a project test, not an ISO lane-change maneuver and not exhaustive coverage of the yaw envelope.

Complete drive loss is an effector-level backup challenge, **not automatically a single independent motor fault**. It could follow a common-path failure, a mechanical condition, or two motor failures; architecture evidence must identify the actual cause. It is kept separate from the six single-channel classes.

## Metrics and limits of interpretation

Nominal paths include one extra second of coasting beyond the 6 s fault record. This gives slightly faster faulted vehicles a complete equal-distance reference without extrapolation; time-based comparisons still use the common first 6 s.

Precisely, the lateral comparison is expressed in the nominal vehicle-heading frame: `e_lat = -(X_f-X_n)*sin(psi_n) + (Y_f-Y_n)*cos(psi_n)` at matched travelled distance. With nonzero sideslip this is not exactly the shortest geometric distance to the path.

1. **Mask timing:** record onset, delivered diagnosis and applied mask. The 10 ms mask-reconfiguration target starts at the delivered diagnosis. Physical onset-to-response includes detection separately. The simulation currently applies an available flag in the same control sample; this says nothing about real ECU scheduling.
2. **REQ-02 recovery diagnostic:** solve a true-mask oracle on the same frozen vehicle state, demand and previous command. Compare actual nonlinear force/moment with its affine QP prediction, normalized by the oracle's force/yaw authority estimates. Measure the first entry into a 10% band sustained for a full 100 ms; compare its delay after diagnosis with 50 ms. Insufficient data cannot pass. This diagnostic includes actuator lag and model mismatch; the oracle is not an independent nonlinear reachable-set calculation.
3. **Continuity:** maximum nominal/faulted yaw-rate difference during the first 200 ms after *physical onset*, compared with the provisional 0.05 rad/s threshold. Both vehicles use the same initial state and reference.
4. **DBBS maneuver:** post-fault yaw RMSE ≤0.03 rad/s, peak lateral path deviation ≤0.50 m, and peak actual body-longitudinal deceleration ≤0.35g. Path error is signed normal deviation from the nominal path at equal cumulative travelled distance, not equal time; missing reference coverage is flagged, never extrapolated into a pass. Speed loss is reported separately. Thresholds are evaluated individually, even if a case fails.
5. **Numerical/physical checks:** finite states, positive raw loads, tire circles, healthy command rates, actual rack/motor limits, solver success, bounded commands, no healthy rate overrides, speed above the low-speed floor, and sideslip ≤0.15 rad.

**No automatic REQ-02 compliance:** the 15% post-fault operational-envelope margin has not yet been established against a nonlinear reachable set. `REQ02Status` therefore remains `PENDING_ENVELOPE_AND_ORACLE_REVIEW` even if the diagnostics pass. Using the allocator output itself as measured vehicle response would make the check circular; this code does not do that.

**No automatic REQ-03 authority claim:** a tracking maneuver does not measure maximum feasible straight-line deceleration or maximum yaw authority. `REQ03AuthorityStatus` remains `NOT_ASSESSED`. REQ-03b's common-rack bench remains functional evidence only. DBBS maneuver success, where observed, would cover only the tested pulse and rack condition, not its separate 15% yaw-authority clause.

## MATLAB handoff

```matlab
gate2 = run_gate2_validation();
gate3 = run_gate3_validation();
```

Review Gate 2 before interpreting Gate 3. The second command runs the unit tests, four nominal references and 30 fault cases. Its manifest **always** keeps `Gate3Closed=false` and `AllRequirementsPassed=false`. Failed behavioral diagnostics are retained for analysis, not silently dropped or converted into successful gate acceptance.

Generated evidence under `validation/results/gate3/` includes `fault_summary.csv`, per-case raw time series, `fault_metrics.csv`, `comparison.csv`, MAT files, French/English response and comparison figures, and a manifest with MATLAB release, products, parameter values and Git status. These outputs remain ignored by Git.

## Remaining decisions

- Validate nonlinear operational-envelope and authority definitions before claiming REQ-02/03 closure.
- Define a bounded degraded yaw/path strategy if the baseline allocator cannot meet DBBS criteria; keep current tuning as the comparison baseline.
- Resolve driver-request/rack-angle sensor failure behavior, frozen/unintended actuation, and actual power/communication domain mapping.
- Review the locally retained FMEA/FTA/DFA draft in the ignored `reports/` directory with the supervisor. Do not treat channel masks as independence evidence.
- Keep double-fault/circuit and standardized-maneuver extensions deferred until the core results are defensible.
