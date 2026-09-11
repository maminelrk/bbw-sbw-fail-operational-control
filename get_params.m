function p = get_params()
% Vehicle/actuator parameters -- single source of truth.
% Shared by vehicle_derivatives_block.m and allocator.m.
% Do NOT duplicate these values anywhere else.

m=1200; Iz=1650; L=2.54; wf=0.60;
lf=(1-wf)*L; lr=wf*L;
tw=1.55; hcg=0.53; mu=0.95; g=9.81;
Cf=35000; Cr=35000;   % [OPEN] reconcile vs. earlier Step-0 params.m (Cf=Cr=17000)
Bshape=10; Cshape=1.9; Eshape=0.97;
delta_max=deg2rad(35); delta_rate=deg2rad(400);
Fx_rate=40000;

% Small regularization used by the best-effort control allocator. Demand
% tracking remains dominant; this makes the QP strictly convex.
allocation_effort_weight = 1e-6;

actuator_tau_delta = 0.02;
actuator_tau_Fx = 0.02;
vx_floor = 0.5;

p = struct('m',m,'Iz',Iz,'L',L,'wf',wf,'lf',lf,'lr',lr, ...
    'tw',tw,'hcg',hcg,'mu',mu,'g',g,'Cf',Cf,'Cr',Cr, ...
    'Bshape',Bshape,'Cshape',Cshape,'Eshape',Eshape, ...
    'delta_max',delta_max,'delta_rate',delta_rate,'Fx_rate',Fx_rate, ...
    'allocation_effort_weight',allocation_effort_weight, ...
    'actuator_tau_delta',actuator_tau_delta,'actuator_tau_Fx',actuator_tau_Fx, ...
    'vx_floor',vx_floor);
end
