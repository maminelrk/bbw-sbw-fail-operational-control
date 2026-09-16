function p = get_params()
% Vehicle/actuator parameters -- single source of truth.
% Shared by the plant model, allocator, and validation campaigns.
%
% Parameter provenance is documented in:
%   docs/parameters.en.md
%   docs/parameters.fr.md
%
% This is a literature-based reference vehicle, not an identified physical
% test vehicle. Do not silently replace individual values without updating
% the provenance table and rerunning the plant validation campaign.

parameter_set_id = 'REF-2026-02';

% Published reference-vehicle inertial and geometric parameters.
m = 1590;                % kg
Iz = 2059.2;             % kg.m^2
lf = 1.05;               % m, CG to front axle
lr = 1.61;               % m, CG to rear axle
L = lf + lr;             % m, calculated wheelbase
wf = lr/L;               % calculated static front-axle load fraction

% Published surrogate geometry for quantities absent from the reference
% vehicle table. These must be replaced if target-vehicle data is supplied.
tw = 1.53;               % m, representative track width
hcg = 0.637;             % m, representative CG height

g = 9.80665;             % m/s^2, standard gravity
mu = 0.90;               % dry/high-adhesion reference condition

% The source reports 33 kN/rad per tire. This axle-lumped plant therefore
% uses twice that value at each axle.
Cf = 2*33000;            % N/rad, front axle
Cr = 2*33000;            % N/rad, rear axle

% Simplified Pacejka shape assumptions. Peak factor D is computed from
% mu*Fz and B is calculated to preserve the specified small-slip slope.
Cshape = 1.9;
Eshape = 0.97;

% Project assumptions and requirement-derived actuator limits.
delta_max = deg2rad(35);
delta_rate = deg2rad(400);
Fx_rate = 40000;

% Small regularization used by the best-effort control allocator. Demand
% tracking remains dominant; this makes the QP strictly convex.
allocation_effort_weight = 1e-6;
% Provisional controller reserve, not a change to physical tire friction.
% Keeping 2% of longitudinal capacity unused avoids the singular zero-
% lateral-budget boundary and leaves sqrt(1-0.98^2)=19.9% lateral budget.
allocation_friction_fraction = 0.98;
allocation_config_id = 'ALLOC-2026-03';

actuator_tau_delta = 0.02;
actuator_tau_Fx = 0.02;
vx_floor = 0.5;
validation_dt = 0.002;
reference_speed = 60/3.6;

% Functional common-rack model: independent motor velocity contributions.
% Both channels share one road-wheel angle; each can traverse its full range.
steering_channel_rate = 0.60*delta_rate*ones(2,1);
steering_motor_tau = 0.01;     % s, assumed inner velocity-loop time constant
yaw_tracking_tau = 0.25;      % s, nominal yaw-reference feedback tuning
allocation_output_scale = [5000; 1000]; % N / Nm, fixed tracking priorities
steering_trust_angle = deg2rad(0.5);    % local linearization trust region

p = struct('parameter_set_id',parameter_set_id, ...
    'm',m,'Iz',Iz,'L',L,'wf',wf,'lf',lf,'lr',lr, ...
    'tw',tw,'hcg',hcg,'mu',mu,'g',g,'Cf',Cf,'Cr',Cr, ...
    'Cshape',Cshape,'Eshape',Eshape, ...
    'delta_max',delta_max,'delta_rate',delta_rate,'Fx_rate',Fx_rate, ...
    'allocation_effort_weight',allocation_effort_weight, ...
    'allocation_friction_fraction',allocation_friction_fraction, ...
    'allocation_config_id',allocation_config_id, ...
    'actuator_tau_delta',actuator_tau_delta,'actuator_tau_Fx',actuator_tau_Fx, ...
    'vx_floor',vx_floor,'validation_dt',validation_dt, ...
    'reference_speed',reference_speed, ...
    'steering_channel_rate',steering_channel_rate, ...
    'steering_motor_tau',steering_motor_tau, ...
    'yaw_tracking_tau',yaw_tracking_tau, ...
    'allocation_output_scale',allocation_output_scale, ...
    'steering_trust_angle',steering_trust_angle);
end
