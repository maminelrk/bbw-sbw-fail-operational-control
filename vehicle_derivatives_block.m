function dx = vehicle_derivatives_block(x, delta_cmd, Fx_cmd)
% x = [vx vy r X Y psi delta_act FxFL FxFR FxRL FxRR]  (11x1)
% delta_cmd : consigne angle volant [rad]  (scalaire)
% Fx_cmd    : consigne frein [FL FR RL RR] [N]  (4x1)
%
% Requires get_params.m, static_corner_loads.m, pacejka_axle.m on the
% MATLAB path (/functions folder). See change log for fix history.

p = get_params();

vx_raw = x(1);
vy=x(2); r=x(3); psi=x(6);
delta_act = x(7);
Fx_act = x(8:11);

vx = max(vx_raw, p.vx_floor);

%% Dynamique d'actionneur (saturation + limite de vitesse)
delta_cmd_sat = min(max(delta_cmd, -p.delta_max), p.delta_max);
ddelta = sign(delta_cmd_sat-delta_act)*min(abs(delta_cmd_sat-delta_act)/p.actuator_tau_delta, p.delta_rate);

Fz_static = static_corner_loads(p); Fz_static = Fz_static(:);
% Brake-only actuator: command range is [-mu*Fz, 0].
Fx_cmd_sat = min(max(Fx_cmd(:), -p.mu*Fz_static), 0);
dFx = sign(Fx_cmd_sat-Fx_act).*min(abs(Fx_cmd_sat-Fx_act)/p.actuator_tau_Fx, p.Fx_rate);

%% Estimation ax, ay pour le transfert de charge
FxF_tire_est = Fx_act(1) + Fx_act(2);
FxR_tire_est = Fx_act(3) + Fx_act(4);
ax_est = (FxF_tire_est*cos(delta_act) + FxR_tire_est) / p.m;
ay_est = vx*r;

%% Transfert de charge
Fzf_static = p.m*p.g*p.wf; Fzr_static = p.m*p.g*(1-p.wf);
dFz_long = p.m*p.hcg*ax_est/p.L;
Fzf_dyn = Fzf_static - dFz_long;
Fzr_dyn = Fzr_static + dFz_long;

dFz_lat_f = p.m*ay_est*p.hcg/p.tw * (Fzf_static/(p.m*p.g));
dFz_lat_r = p.m*ay_est*p.hcg/p.tw * (Fzr_static/(p.m*p.g));

FzFL = max(Fzf_dyn/2 - dFz_lat_f/2, 50);
FzFR = max(Fzf_dyn/2 + dFz_lat_f/2, 50);
FzRL = max(Fzr_dyn/2 - dFz_lat_r/2, 50);
FzRR = max(Fzr_dyn/2 + dFz_lat_r/2, 50);

%% Angles de derive et forces laterales pneu
alpha_f = delta_act - atan2(vy + p.lf*r, vx);
alpha_r = -atan2(vy - p.lr*r, vx);

Fx_f_axle = Fx_act(1) + Fx_act(2);
Fx_r_axle = Fx_act(3) + Fx_act(4);

Fyf = pacejka_axle(alpha_f, FzFL+FzFR, p.Cf, p, Fx_f_axle);
Fyr = pacejka_axle(alpha_r, FzRL+FzRR, p.Cr, p, Fx_r_axle);

%% Projection essieu avant dans le repere vehicule
FxF_tire = Fx_act(1)+Fx_act(2);
FxF_veh = FxF_tire*cos(delta_act) - Fyf*sin(delta_act);
FyF_veh = FxF_tire*sin(delta_act) + Fyf*cos(delta_act);

FxR_veh = Fx_act(3)+Fx_act(4);
FyR_veh = Fyr;

Fx_total = FxF_veh + FxR_veh;
Fy_total = FyF_veh + FyR_veh;

%% Moment de lacet : direction + freinage differentiel
Mz_direction = p.lf*FyF_veh - p.lr*FyR_veh;
Mz_diff_brake = (p.tw/2)*((Fx_act(2)-Fx_act(1))*cos(delta_act) + (Fx_act(4)-Fx_act(3)));
Mz_total = Mz_direction + Mz_diff_brake;

%% Equations du mouvement
vx_dot = Fx_total/p.m + vy*r;
vy_dot = Fy_total/p.m - vx*r;
r_dot  = Mz_total/p.Iz;
X_dot  = vx*cos(psi) - vy*sin(psi);
Y_dot  = vx*sin(psi) + vy*cos(psi);
psi_dot= r;

if vx_raw <= p.vx_floor && vx_dot < 0
    vx_dot = 0;
end

dx = [vx_dot; vy_dot; r_dot; X_dot; Y_dot; psi_dot; ddelta; dFx(:)];

end
