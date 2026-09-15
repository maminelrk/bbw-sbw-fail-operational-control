# Toolchain decision

The project execution toolchain is MATLAB, with Simulink available for block-diagram models. The earlier preference for an exclusively open-source toolchain is superseded for this project implementation.

Required products:

- MATLAB R2021a or later;
- Optimization Toolbox (`quadprog`);
- MATLAB Unit Test Framework, included with MATLAB.

The current Gate 2 reference implementation runs as MATLAB scripts and functions through `run_gate2_validation`; it does not require Simulink. Simulink is required only to open or execute `.slx` models. The existing `wawaw.slx` is a historical 11-state prototype, not the current 13-state Gate 2 integration.

The simulation repository and final project documentation must state these dependencies so that results are reproducible. Open-source parity is not a project acceptance criterion unless it is introduced later as a separate objective.
