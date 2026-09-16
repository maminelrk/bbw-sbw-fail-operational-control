function u = simulink_allocator_wrapper(demand, delta_act_lin, actuator_mask)
% MATLAB Function block wrapper with a fault-mask input and rate memory.
%
% Legacy STATIC allocator adapter only. Current Gate 2 vehicle evidence uses
% run_gate2_validation.m. This adapter does not migrate wawaw.slx to 13 states.
% Connect [brake_FL brake_FR brake_RL brake_RR steering_A steering_B]' (6x1).

coder.extrinsic('allocator');
persistent u_prev

if isempty(u_prev)
    u_prev = zeros(5,1);
end

u = zeros(5,1);
u = allocator(demand(:), delta_act_lin, [], actuator_mask(:), u_prev, 0.002);
u = u(:);
u_prev = u;

end
