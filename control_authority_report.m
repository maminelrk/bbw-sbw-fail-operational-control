function report = control_authority_report()
% Static authority ratios used by the provisional REQ-03 baseline.
%
% These are screening calculations based on the allocator's static bounds.
% Dynamic maneuver results remain necessary for Gate 3 validation.

p = get_params();
brake_capacity = p.mu*static_corner_loads(p)';
nominal_brake = sum(brake_capacity);

residual_brake = zeros(4,1);
for failed_corner = 1:4
    remaining = brake_capacity;
    remaining(failed_corner) = 0;
    residual_brake(failed_corner) = sum(remaining)/nominal_brake;
end

static_loads = static_corner_loads(p);
front_normal_load = sum(static_loads(1:2));
linear_steering_lateral_force = p.Cf*p.delta_max;
steering_lateral_force = min(linear_steering_lateral_force, ...
    p.mu*front_normal_load);
steering_yaw = p.lf*steering_lateral_force;
left_capacity = brake_capacity(1) + brake_capacity(3);
right_capacity = brake_capacity(2) + brake_capacity(4);
brake_yaw = (p.tw/2)*max(left_capacity, right_capacity);
combined_yaw = steering_yaw + brake_yaw;

report = struct( ...
    'brake_capacity_per_corner_N', brake_capacity, ...
    'nominal_brake_force_N', nominal_brake, ...
    'residual_brake_ratio_by_corner_loss', residual_brake, ...
    'worst_single_corner_brake_ratio', min(residual_brake), ...
    'linear_steering_lateral_force_N', linear_steering_lateral_force, ...
    'saturation_limited_steering_lateral_force_N', steering_lateral_force, ...
    'steering_yaw_authority_Nm', steering_yaw, ...
    'brake_only_yaw_authority_Nm', brake_yaw, ...
    'combined_nominal_yaw_authority_Nm', combined_yaw, ...
    'steering_loss_yaw_ratio', brake_yaw/combined_yaw);

end
