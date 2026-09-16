# Toolchain decision

The project execution toolchain is MATLAB, with Simulink available for block-diagram models. The user explicitly chose MATLAB instead of the original CDC's exclusively open-source prescription. This is an authorized implementation choice, not a recorded formal CDC amendment; supervisor/CDC-guarantor acceptance remains unrecorded (DEV-05 in the local deviation register).

Required products:

- MATLAB R2021a or later;
- Optimization Toolbox (`quadprog`);
- MATLAB Unit Test Framework, included with MATLAB.

The current Gate 2 reference implementation runs as MATLAB scripts and functions through `run_gate2_validation`; it does not require Simulink. Simulink is required only to open or execute `.slx` models. The existing `wawaw.slx` is a historical 11-state prototype, not the current 13-state Gate 2 integration.

The simulation repository and final project documentation must state these dependencies so that results are reproducible. Open-source parity is not part of the user-selected implementation scope and has not been demonstrated. Whether the written CDC toolchain deviation is accepted for submission remains a supervisor/CDC-guarantor decision; no migration is implied by this note.
