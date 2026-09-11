function [u, exitflag, info] = allocator(demand, delta_act_lin, quadprog_opts, actuator_mask, u_prev, dt)
% Best-effort QP control allocation for the BbW/SbW plant.
%
% demand         : [Fx_demand; Mz_demand]
% delta_act_lin  : steering angle [rad] used to linearize the B-matrix
% quadprog_opts  : optional optimoptions object; pass [] for default
% actuator_mask  : binary health mask [FL FR RL RR steering]'. A zero
%                  removes that effector from the allocation problem.
% u_prev         : optional previous allocator command (5x1)
% dt             : optional allocation period [s]. When u_prev and dt are
%                  supplied, healthy-actuator command-rate bounds are
%                  included directly in the QP.
%
% u = [FxFL FxFR FxRL FxRR delta]'  (5x1)
%
% The allocator minimizes normalized generalized-force tracking error plus
% a small normalized actuator-effort penalty:
%
%   min 0.5*(B*u-demand)'*Q*(B*u-demand) + 0.5*rho*u'*R*u
%
% subject to actuator position/force bounds and optional command-rate
% bounds. Unlike the earlier equality-constrained formulation, this
% problem remains feasible when the requested force/moment is outside the
% post-fault attainable set. It then returns the closest best-effort
% command instead of returning zero and releasing all braking effort.

if nargin < 2 || isempty(delta_act_lin)
    delta_act_lin = 0;
end
if nargin < 3 || isempty(quadprog_opts)
    quadprog_opts = optimoptions('quadprog','Display','off');
end
if nargin < 4 || isempty(actuator_mask)
    actuator_mask = ones(5,1);
end
if nargin < 5
    u_prev = [];
end
if nargin < 6
    dt = [];
end

demand = demand(:);
actuator_mask = actuator_mask(:);
if numel(demand) ~= 2 || any(~isfinite(demand))
    error('allocator: demand must be a finite 2x1 vector [Fx; Mz].');
end
if numel(actuator_mask) ~= 5 || any(~ismember(actuator_mask, [0 1]))
    error('allocator: actuator_mask must be a binary 5x1 vector.');
end
if xor(isempty(u_prev), isempty(dt))
    error('allocator: u_prev and dt must be supplied together.');
end
if ~isempty(u_prev)
    u_prev = u_prev(:);
    if numel(u_prev) ~= 5 || any(~isfinite(u_prev)) || ~isscalar(dt) || ~isfinite(dt) || dt <= 0
        error('allocator: u_prev must be finite 5x1 and dt must be a positive scalar.');
    end
end

p = get_params();
Fz_static = static_corner_loads(p);   % [FL FR RL RR]

%% Nominal effectiveness matrix, linearized at delta_act_lin
c = cos(delta_act_lin);
Cf_eff = p.Cf * p.lf;
B = [ c,        c,        1,        1,       0;
     -p.tw/2,   p.tw/2,  -p.tw/2,   p.tw/2,  Cf_eff ];

% Removing the column as well as fixing the command to zero makes the
% allocation-layer meaning of a fault explicit in diagnostics.
B(:, actuator_mask == 0) = 0;

%% Physical force/angle bounds
u_min_physical = [ -p.mu*Fz_static(1); -p.mu*Fz_static(2); ...
                   -p.mu*Fz_static(3); -p.mu*Fz_static(4); -p.delta_max ];
u_max_physical = [0; 0; 0; 0; p.delta_max];
u_min = u_min_physical;
u_max = u_max_physical;

% A failed effector has no commanded authority.
u_min(actuator_mask == 0) = 0;
u_max(actuator_mask == 0) = 0;

%% Optional healthy-actuator command-rate bounds
if ~isempty(u_prev)
    max_step = [repmat(p.Fx_rate,4,1); p.delta_rate] * dt;
    healthy = actuator_mask == 1;
    u_min(healthy) = max(u_min(healthy), u_prev(healthy) - max_step(healthy));
    u_max(healthy) = min(u_max(healthy), u_prev(healthy) + max_step(healthy));
    if any(u_min(healthy) > u_max(healthy))
        error('allocator: u_prev lies outside the physical bounds used for rate limiting.');
    end
end

%% Normalize output tracking by the authority remaining after the fault
y_min = zeros(2,1);
y_max = zeros(2,1);
for row = 1:2
    row_at_min = B(row,:)'.*u_min;
    row_at_max = B(row,:)'.*u_max;
    y_min(row) = sum(min(row_at_min, row_at_max));
    y_max(row) = sum(max(row_at_min, row_at_max));
end
y_scale = max(max(abs(y_min), abs(y_max)), [1; 1]);
Q = diag(1./(y_scale.^2));

% The small effort term makes H positive definite and resolves redundant
% solutions without materially sacrificing achievable demand tracking.
u_scale = max(abs(u_min_physical), abs(u_max_physical));
u_scale(u_scale < 1e-6) = 1e-6;
R = diag(1./(u_scale.^2));
rho = p.allocation_effort_weight;

H = B'*Q*B + rho*R;
H = (H + H')/2;  % suppress numerical asymmetry
f = -B'*Q*demand;

%% Solve the always-feasible bounded best-effort problem
[u, ~, exitflag] = quadprog(H, f, [], [], [], [], u_min, u_max, [], quadprog_opts);

if isempty(u) || exitflag <= 0
    % This indicates a solver/numerical failure, not demand infeasibility.
    % Preserve the closest valid previous command when available.
    if isempty(u_prev)
        fallback = zeros(5,1);
    else
        fallback = u_prev;
    end
    u = min(max(fallback, u_min), u_max);
    warning('allocator:solverFailure', ...
        'QP solver failed (exitflag %d); returning the closest bounded fallback command.', exitflag);
end

u = u(:);
achieved = B*u;
info = struct( ...
    'achieved', achieved, ...
    'residual', demand-achieved, ...
    'normalized_tracking_error', norm((demand-achieved)./y_scale), ...
    'fault_mask', actuator_mask, ...
    'B', B, ...
    'lower_bounds', u_min, ...
    'upper_bounds', u_max, ...
    'output_scale', y_scale);

end
