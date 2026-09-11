function u = simulink_allocator_wrapper(demand, delta_act_lin, actuator_mask)
% MATLAB Function block wrapper with a fault-mask input and rate memory.
%
% Replace the current two-input allocator wrapper in wawaw.slx with this
% three-input function body, then connect a 5x1 mask signal ordered as:
% [brake_FL brake_FR brake_RL brake_RR steering]'.

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
