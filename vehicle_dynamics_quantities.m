function q = vehicle_dynamics_quantities(x, p)
%VEHICLE_DYNAMICS_QUANTITIES Evaluate plant forces and moments from state.
%   Q = VEHICLE_DYNAMICS_QUANTITIES(X, P) contains the intermediate load,
%   slip, tire-force, and body-force quantities used by the plant ODE. This
%   separation lets open-loop tests inspect the plant without an allocator.

if nargin < 2 || isempty(p)
    p = get_params();
end

x = x(:);
if numel(x) ~= 11 || any(~isfinite(x))
    error('vehicle_dynamics_quantities:State', ...
        'x must be a finite 11x1 plant state.');
end

vx = max(x(1), p.vx_floor);
vy = x(2);
r = x(3);
delta_act = x(7);
Fx_act = x(8:11);

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

Fz = [Fzf_dynamic/2 - dFz_lateral_front/2; ...
      Fzf_dynamic/2 + dFz_lateral_front/2; ...
      Fzr_dynamic/2 - dFz_lateral_rear/2; ...
      Fzr_dynamic/2 + dFz_lateral_rear/2];
Fz = max(Fz, 50);

alpha_front = delta_act - atan2(vy + p.lf*r, vx);
alpha_rear = -atan2(vy - p.lr*r, vx);

Fyf = pacejka_axle(alpha_front, Fz(1)+Fz(2), p.Cf, p, Fx_front_axle);
Fyr = pacejka_axle(alpha_rear, Fz(3)+Fz(4), p.Cr, p, Fx_rear_axle);

Fx_front_body = Fx_front_axle*cos(delta_act) - Fyf*sin(delta_act);
Fy_front_body = Fx_front_axle*sin(delta_act) + Fyf*cos(delta_act);
Fx_rear_body = Fx_rear_axle;
Fy_rear_body = Fyr;

Fx_total = Fx_front_body + Fx_rear_body;
Fy_total = Fy_front_body + Fy_rear_body;
Mz_direction = p.lf*Fy_front_body - p.lr*Fy_rear_body;
Mz_differential_brake = (p.tw/2)*((Fx_act(2)-Fx_act(1))*cos(delta_act) + ...
    (Fx_act(4)-Fx_act(3)));

front_capacity = p.mu*(Fz(1)+Fz(2))*sqrt(max(1 - ...
    (Fx_front_axle/(p.mu*(Fz(1)+Fz(2))))^2, 0));
rear_capacity = p.mu*(Fz(3)+Fz(4))*sqrt(max(1 - ...
    (Fx_rear_axle/(p.mu*(Fz(3)+Fz(4))))^2, 0));

q = struct( ...
    'vx',vx,'vy',vy,'yaw_rate',r,'delta_actual',delta_act, ...
    'Fx_actual',Fx_act,'ax_estimate',ax_est,'ay_estimate',ay_est, ...
    'Fz',Fz,'front_normal_load',Fz(1)+Fz(2), ...
    'rear_normal_load',Fz(3)+Fz(4), ...
    'alpha_front',alpha_front,'alpha_rear',alpha_rear, ...
    'Fyf',Fyf,'Fyr',Fyr,'front_lateral_capacity',front_capacity, ...
    'rear_lateral_capacity',rear_capacity, ...
    'Fx_total',Fx_total,'Fy_total',Fy_total, ...
    'Mz_direction',Mz_direction, ...
    'Mz_differential_brake',Mz_differential_brake, ...
    'Mz_total',Mz_direction+Mz_differential_brake);

end
