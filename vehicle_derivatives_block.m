function dx = vehicle_derivatives_block(x, delta_cmd, Fx_cmd)
% x = [vx vy r X Y psi delta_act FxFL FxFR FxRL FxRR]  (11x1)
% delta_cmd : consigne angle volant [rad]  (scalaire)
% Fx_cmd    : consigne frein [FL FR RL RR] [N]  (4x1)
%
% Requires get_params.m, static_corner_loads.m, pacejka_axle.m, and
% vehicle_dynamics_quantities.m on the MATLAB path.

p = get_params();

vx_raw = x(1);
vy=x(2); r=x(3); psi=x(6);
delta_act = x(7);
Fx_act = x(8:11);

vx = max(vx_raw, p.vx_floor);

% Quantities at the current state are also used to set load-dependent
% brake-force bounds. This prevents a rear brake command based on static
% load from exceeding the reduced rear normal load during braking.
q = vehicle_dynamics_quantities(x, p);

%% Dynamique d'actionneur (saturation + limite de vitesse)
delta_cmd_sat = min(max(delta_cmd, -p.delta_max), p.delta_max);
ddelta = sign(delta_cmd_sat-delta_act)*min(abs(delta_cmd_sat-delta_act)/p.actuator_tau_delta, p.delta_rate);

% Brake-only actuator: command range is [-mu*Fz_dynamic, 0].
Fx_cmd_sat = min(max(Fx_cmd(:), -p.mu*q.Fz), 0);
dFx = sign(Fx_cmd_sat-Fx_act).*min(abs(Fx_cmd_sat-Fx_act)/p.actuator_tau_Fx, p.Fx_rate);

%% Forces, moments, tire saturation, and load transfer

%% Equations du mouvement
vx_dot = q.Fx_total/p.m + vy*r;
vy_dot = q.Fy_total/p.m - vx*r;
r_dot  = q.Mz_total/p.Iz;
X_dot  = vx*cos(psi) - vy*sin(psi);
Y_dot  = vx*sin(psi) + vy*cos(psi);
psi_dot= r;

if vx_raw <= p.vx_floor && vx_dot < 0
    vx_dot = 0;
end

dx = [vx_dot; vy_dot; r_dot; X_dot; Y_dot; psi_dot; ddelta; dFx(:)];

end
