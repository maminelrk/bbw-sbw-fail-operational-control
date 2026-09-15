function q = vehicle_dynamics_quantities(x, p, mask)
%VEHICLE_DYNAMICS_QUANTITIES Evaluate plant forces and moments from state.
%   Q = VEHICLE_DYNAMICS_QUANTITIES(X, P) contains the intermediate load,
%   slip, tire-force, and body-force quantities used by the plant ODE. This
%   separation lets open-loop tests inspect the plant without an allocator.

if nargin < 2 || isempty(p)
    p = get_params();
end
if nargin < 3, mask = ones(6,1); end
channels = normalize_actuator_mask(mask);

x = x(:);
if ~ismember(numel(x),[11 13]) || any(~isfinite(x))
    error('vehicle_dynamics_quantities:State', ...
        'x must be a finite 13x1 state (11x1 accepted for legacy plant calls).');
end

vx = max(x(1), p.vx_floor);
vy = x(2);
r = x(3);
delta_act = x(7);
Fx_act = x(8:11).*channels(1:4);

Fx_front_axle = Fx_act(1) + Fx_act(2);
Fx_rear_axle = Fx_act(3) + Fx_act(4);
ax_est = (Fx_front_axle*cos(delta_act) + Fx_rear_axle)/p.m;
ay_est = vx*r;

% Quasi-static longitudinal and lateral load transfer. Lateral transfer is
% distributed between axles according to their static normal-load shares.
Fzf_static = p.m*p.g*p.wf;
Fzr_static = p.m*p.g*(1-p.wf);
dFz_long = p.m*p.hcg*ax_est/p.L;
Fzf_dynamic = Fzf_static - dFz_long;
Fzr_dynamic = Fzr_static + dFz_long;

dFz_lateral_front = p.m*ay_est*p.hcg/p.tw * p.wf;
dFz_lateral_rear = p.m*ay_est*p.hcg/p.tw * (1-p.wf);

% dFz_lateral is the load MOVED from the inside wheel to the outside wheel.
Fz_raw = [Fzf_dynamic/2 - dFz_lateral_front; ...
          Fzf_dynamic/2 + dFz_lateral_front; ...
          Fzr_dynamic/2 - dFz_lateral_rear; ...
          Fzr_dynamic/2 + dFz_lateral_rear];
Fz = max(Fz_raw,0);
Fx_act = min(max(Fx_act,-p.mu*Fz),0);
Fx_front_axle = sum(Fx_act(1:2));
Fx_rear_axle = sum(Fx_act(3:4));

alpha_front = delta_act - atan2(vy + p.lf*r, vx);
alpha_rear = -atan2(vy - p.lr*r, vx);

% Sum wheel capacities, so an asymmetrically loaded axle cannot hide a
% single tire exceeding its friction circle. Allocate Fy by capacity share.
wheel_capacity = sqrt(max((p.mu*Fz).^2-Fx_act.^2,0));
front_capacity = sum(wheel_capacity(1:2));
rear_capacity = sum(wheel_capacity(3:4));
Fyf = lateral_force(alpha_front,front_capacity,p.Cf,p);
Fyr = lateral_force(alpha_rear,rear_capacity,p.Cr,p);
Fy_wheels = [Fyf*wheel_capacity(1:2)/max(front_capacity,eps); ...
             Fyr*wheel_capacity(3:4)/max(rear_capacity,eps)];

Fx_front_body = Fx_front_axle*cos(delta_act) - Fyf*sin(delta_act);
Fy_front_body = Fx_front_axle*sin(delta_act) + Fyf*cos(delta_act);
Fx_rear_body = Fx_rear_axle;
Fy_rear_body = Fyr;

Fx_total = Fx_front_body + Fx_rear_body;
Fy_total = Fy_front_body + Fy_rear_body;
Mz_direction = p.lf*Fy_front_body - p.lr*Fy_rear_body - ...
    (p.tw/2)*(Fy_wheels(2)-Fy_wheels(1))*sin(delta_act);
Mz_differential_brake = (p.tw/2)*((Fx_act(2)-Fx_act(1))*cos(delta_act) + ...
    (Fx_act(4)-Fx_act(3)));

q = struct( ...
    'vx',vx,'vy',vy,'yaw_rate',r,'delta_actual',delta_act, ...
    'Fx_actual',Fx_act,'ax_estimate',ax_est,'ay_estimate',ay_est, ...
    'Fz',Fz,'Fz_raw',Fz_raw,'Fy_wheels',Fy_wheels, ...
    'wheel_lateral_capacity',wheel_capacity,'front_normal_load',Fz(1)+Fz(2), ...
    'rear_normal_load',Fz(3)+Fz(4), ...
    'alpha_front',alpha_front,'alpha_rear',alpha_rear, ...
    'Fyf',Fyf,'Fyr',Fyr,'front_lateral_capacity',front_capacity, ...
    'rear_lateral_capacity',rear_capacity, ...
    'Fx_total',Fx_total,'Fy_total',Fy_total, ...
    'Mz_direction',Mz_direction, ...
    'Mz_differential_brake',Mz_differential_brake, ...
    'Mz_total',Mz_direction+Mz_differential_brake);

end

function force = lateral_force(alpha,capacity,stiffness,p)
if capacity <= eps, force = 0; return; end
B = stiffness/(p.Cshape*capacity);
force = capacity*sin(p.Cshape*atan(B*alpha- ...
    p.Eshape*(B*alpha-atan(B*alpha))));
end
