# Gate 3 supplementary assessment — G3-AUTH/ENV-01

This protocol supplements the preserved `93db2a5 + timegrid_v1` Gate 3 campaign. It does not change the controller, vehicle parameters, acceptance thresholds or existing failures. All generated evidence belongs under ignored `validation/results/`; reports remain private under `reports/`.

## Numerical refinement

Re-run centered positive/negative DBBS (`T1-D10`) and matched nominal references. Separate RK4 refinement (1 ms integration, unchanged 2 ms controller) from controller-period refinement (both 1 ms). Compare to the saved 2 ms baseline. The predeclared consistency screen is: peak-path difference <= 1 mm, maximum yaw-rate difference <= 0.001 rad/s, maximum speed difference <= 0.03 m/s. The maneuver limit stays **0.500 m**. These are discretization-sensitivity checks, not controller tuning or proof of exact convergence.

## Braking and yaw capability

Use `vehicle_dynamics_quantities` directly, independently of the allocator's affine prediction. Deterministic multistart SQP searches for feasible nonlinear witnesses with positive wheel loads, contact-consistent brake forces, tire friction, failed-channel masks, and steering range. `fmincon` is a local optimizer; multiple starts do not prove a global maximum ([MathWorks](https://www.mathworks.com/help/optim/ug/fmincon.html)). Save all exit flags and objective values. A normalized constraint violation <= 1e-7 is required; a feasible witness need not have a successful local-optimality flag.

For positive wheel loads, the tire-circle triangle inequality gives conservative nominal upper bounds:

Search revision 2 uses a strict brake-contact interior (`abs(Fx_i) <= 0.999*mu*Fz_i`) to avoid the square-root singularity at zero lateral-force budget. This restricts the witness search and does not relax physical constraints or acceptance thresholds. Feasible starting points are retained if optimization stalls. The first full-bound search stopped without a feasible optimized front-loss trim; its source/logs are preserved separately. A diagnostic interior search recovered a feasible trim. Use revision-2 source hashes for the completed campaign.

- Total body braking force: `F_upper = mu*m*g`.
- Absolute yaw moment: `M_upper = F_upper*max(hypot(lf,tw/2),hypot(lr,tw/2))`.

A post-fault feasible value divided by a nominal **upper** bound is a conservative lower bound on retained authority. Meeting 60% braking or 15% yaw by this method is sufficient for the assessed static/frozen condition; missing it is **not** proof of insufficient physical authority.

Braking: nominal and all four single-corner losses; optimize longitudinal force under `r=0`, `Fy=0`, `Mz=0`, allowing sideslip within +/-0.15 rad and steering within its range. This is an instantaneous straight-path trim, not proof that the controller reaches or sustains it while speed changes. Separately run the unchanged allocator on the G2 saturation profile, fault present before the demand, and evaluate the 1.5–1.9 s plateau. Require minimum plateau deceleration >= 0.6*mu*g, numerical/rate checks, and yaw moment <= 5% of a feasible nominal yaw witness (a conservative limit). Record yaw rate as well. These dynamic runs demonstrate delivered performance, not the maximum attainable performance.

Yaw: both signs at 60 km/h with zero initial yaw/sideslip, nominal steering or both steering drives disabled at centered rack. Also assess DBBS with deceleration capped at 0.35g. These are instantaneous physical witnesses; they do not replace maneuver tracking or actuator-transient tests.

### Straight-path interpretation addendum — G3-BRK-ALIGN-01

The archived zero-`Fy` trim is only a body-force probe when sideslip is nonzero; it must not be used alone to prove straight-line braking. Run `run_gate3_straight_path_check(folder)` separately. It enforces `r=0`, `Mz=0` and `Fy*cos(beta)-Fx*sin(beta)=0`, so force aligns with velocity and the instantaneous sideslip derivative is zero. Keep the same 0.999 contact margin, +/-0.15 rad sideslip bound and `Vx=60 km/h`. Optimize body-axis deceleration; dividing by `mu*g` conservatively lower-bounds the travel-direction retained capacity. Save the four brake forces, steering, sideslip, force-alignment residual and yaw residual for independent recomputation. This remains a per-state feasible witness, not sustained transient performance or a global maximum.

## Sampled operational envelope

For every saved fault case, assess actual states at `t_flag+50 ms` and `max(3 s,t_flag+150 ms)`. Evaluate the original `[Fx,Mz]` demand plus four corners of a box with half-width `(0.15/0.85)*abs(demand)` on each axis. This expresses a 15% outward reserve measured relative to the boundary. Zero demand gives zero width on that axis. Eight deterministic starts per point seek actual nonlinear force/moment matches; residual <= 0.001 of the conservative global force/moment scales is the declared numerical matching tolerance.

Report separately:

- Feasible frozen-state witness found.
- No witness found: inconclusive, **not** a proof of infeasibility.
- A conservative physical outer bound exceeded: proven outside that bound.

Even successful corner witnesses do not prove that the interior of a nonlinear image is feasible, nor that an entire trajectory has 15% reserve. These are **sampled box-corner checks**, not a certified operational envelope. Both-drive DBBS loss is reported separately from single-effector REQ-02 scope.

For each matched point, also apply a rate-limited command ramp toward the witness through the full actuator/vehicle plant for 50 ms, starting from the saved state and preceding command. This allocator-free open-loop construction is one achievable candidate, not an optimal reachable set. Check commands, tire circles, wheel loads, speed and sideslip. Report endpoint error normalized by `max(abs(target),0.05*[F_upper;M_upper])`; <=10% is only an endpoint screen, **not** REQ-02's 100 ms dwell or original affine-oracle recovery metric. A failed candidate does not establish lack of a better transient.

At centered zero-slip DBBS, `abs(Mz) <= (tw/2)*(-Fx)` exactly: yaw requires braking. Independent force/yaw maxima therefore cannot define a rectangular feasible region. Do not extend this formula to nonzero-slip/turning states with passive lateral tire forces.

## Closure rules

Preserve negative and inconclusive results. Do not mark Gate 3 closed solely from these studies. A controller maneuver failure needs an explicit corrective design and complete regression campaign. Supervisor agreement remains necessary for provisional numerical requirements and the intended operating domain; this is simulation evidence, not vehicle safety certification.
