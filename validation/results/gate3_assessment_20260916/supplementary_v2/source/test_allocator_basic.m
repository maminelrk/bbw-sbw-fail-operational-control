%% test_allocator_basic.m
% Nominal, best-effort, fault-mask, and rate-bound regression checks.

p = get_params();
Fz_static = static_corner_loads(p)';
brake_limit = p.mu*Fz_static;

%% Case 1: feasible straight-line braking
[u1, flag1, info1] = allocator([-6000; 0], 0);
assert(flag1 > 0, 'Case 1 QP did not converge.');
assert(abs(info1.achieved(1) + 6000) < 60, 'Case 1 Fx tracking error exceeds 1%%.');
assert(abs(info1.achieved(2)) < 10, 'Case 1 should not create material yaw moment.');

%% Case 2: nominal yaw demand is primarily handled by healthy steering
[u2, flag2, info2] = allocator([0; 800], 0);
assert(flag2 > 0, 'Case 2 QP did not converge.');
assert(abs(u2(5)) > deg2rad(0.5), 'Case 2 did not use the healthy steering effector.');
assert(abs(info2.achieved(2) - 800) < 8, 'Case 2 Mz tracking error exceeds 1%%.');

%% Case 3: unattainable braking demand returns maximum best effort, not zero
[u3, flag3, info3] = allocator([-1e6; 0], 0);
assert(flag3 > 0, 'Case 3 QP did not converge.');
assert(sum(u3(1:4)) < -0.95*sum(brake_limit), ...
    'Case 3 must retain near-maximum braking rather than return zero.');
assert(info3.achieved(1) < 0, 'Case 3 achieved force must remain braking.');

%% Case 4: physical bounds hold in all nominal cases
commands = [u1, u2, u3];
assert(all(commands(1:4,:) <= 1e-6, 'all'), 'A brake command became positive.');
assert(all(commands(1:4,:) >= -brake_limit-1e-6, 'all'), 'A brake command exceeded its limit.');
assert(all(abs(commands(5,:)) <= p.delta_max+1e-6), 'Steering angle exceeded its limit.');

%% Case 5: single-corner fault mask removes that brake from allocation
mask_fl = fault_scenario_mask('brake_fl_loss');
[u5, flag5] = allocator([-6000; 0], 0, [], mask_fl);
assert(flag5 > 0, 'Case 5 QP did not converge.');
assert(abs(u5(1)) < 1e-9, 'Failed FL brake received a nonzero command.');
assert(sum(u5(2:4)) < -1000, 'Healthy brakes were not used after FL loss.');

%% Case 6: total steering-effector loss invokes differential-braking yaw
mask_steer = fault_scenario_mask('steering_loss');
[u6, flag6, info6] = allocator([-3000; 800], 0, [], mask_steer);
assert(flag6 > 0, 'Case 6 QP did not converge.');
assert(abs(u6(5)) < 1e-9, 'Failed steering effector received a nonzero command.');
left_force = u6(1) + u6(3);
right_force = u6(2) + u6(4);
assert(abs(right_force-left_force) > 100, ...
    'Steering-loss case did not generate differential braking.');
assert(abs(info6.achieved(2)) > 100, ...
    'Steering-loss case generated insufficient corrective yaw moment.');

%% Case 7: optional allocator command-rate bounds
dt = 0.002;
[u7, flag7] = allocator([-6000; 800], 0, [], ones(5,1), zeros(5,1), dt);
assert(flag7 > 0, 'Case 7 QP did not converge.');
assert(all(abs(u7(1:4)) <= p.Fx_rate*dt+1e-6), 'Brake command-rate bound violated.');
assert(abs(u7(5)) <= p.delta_rate*dt+1e-9, 'Steering command-rate bound violated.');

%% Case 8: provisional REQ-03 static authority screening
authority = control_authority_report();
assert(authority.worst_single_corner_brake_ratio >= 0.60, ...
    'REQ-03a static residual braking ratio is below 60%%.');
assert(authority.steering_loss_yaw_ratio >= 0.15, ...
    'REQ-03c static brake-only yaw ratio is below 15%%.');

fprintf('All allocator regression checks passed.\n');
