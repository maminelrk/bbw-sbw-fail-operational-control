# Gate 3 MATLAB execution

Packaged UTC: 2026-09-16 01:26:32. Source base: 93db2a5c9e8cc522e93985af2bde151cfdfebf4d, plus the three files in source_delta.

37 unit tests, 4 nominal references, 30 fault cases. Numerical-check failures: 0. DBBS maneuver failures: 4/8.

This is preliminary simulation evidence, not Gate 3 closure or safety certification. REQ-02 operational-envelope/oracle review, REQ-03 authority and architecture independence remain open.

The initial attempt stopped because exact equality rejected a maximum time-grid difference of 8.881784197001252e-16 s between common samples of 6 s and 7 s records. It is preserved separately as validation/results/gate3_attempt1_timegrid. The corrected run was restarted in full. Only comparison roundoff handling and its regression test changed; controller, plant, sampling and acceptance thresholds did not.

Figures were generated natively in MATLAB using a temporary DefaultFigureCreateFcn that sets Theme=light. The previous callback was restored after execution. French and English exports accompany the raw CSV/MAT data.

To reproduce: use base commit 93db2a5c9e8cc522e93985af2bde151cfdfebf4d, overlay source_delta/validation and source_delta/tests, then run run_gate3_validation in MATLAB with Optimization Toolbox. Generated evidence is excluded from GitHub.
