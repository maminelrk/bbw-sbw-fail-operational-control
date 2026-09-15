function [u,exitflag,info] = allocator(demand,delta_act_lin,opts,mask,u_prev,dt,state)
% QP: four brakes + one shared rack angle; six health channels [FL FR RL RR A B].
% Optional 13-state input enables the affine map y ~= offset+B*u obtained
% from the nonlinear plant. Omit it for legacy static screening only.
if nargin < 2 || isempty(delta_act_lin), delta_act_lin=0; end
if nargin < 3 || isempty(opts)
    opts=allocator_options();
end
if nargin < 4, mask=[]; end
if nargin < 5, u_prev=[]; end
if nargin < 6, dt=[]; end
if nargin < 7, state=[]; end
[channels,effectors]=normalize_actuator_mask(mask);
p=get_params(); demand=demand(:);
if numel(demand)~=2 || any(~isfinite(demand))
    error('allocator:Demand','Demand must be finite [Fx; Mz].');
end
if xor(isempty(u_prev),isempty(dt))
    error('allocator:RateInput','u_prev and dt must be supplied together.');
end
if ~isempty(u_prev)
    u_prev=u_prev(:);
    if numel(u_prev)~=5 || any(~isfinite(u_prev)) || ~isscalar(dt) || ~isfinite(dt) || dt<=0
        error('allocator:RateInput','Invalid previous command or allocation period.');
    end
end
if isempty(state)
    loads=static_corner_loads(p)'; c=cos(delta_act_lin);
    B=[c c 1 1 0; -p.tw*c/2 p.tw*c/2 -p.tw/2 p.tw/2 p.Cf*p.lf];
    offset=zeros(2,1); anchor=zeros(5,1);
    angleLimit=min(p.delta_max,p.mu*sum(loads(1:2))/p.Cf);
else
    state=state(:);
    if numel(state)~=13 || any(~isfinite(state))
        error('allocator:State','Integrated allocation requires a finite 13-state vector.');
    end
    q=vehicle_dynamics_quantities(state,p,channels); loads=q.Fz;
    anchor=[q.Fx_actual;state(7)]; y0=[q.Fx_total;q.Mz_total]; B=zeros(2,5);
    % Brake decisions are contact forces, not actuator states to perturb
    % through load transfer and clipped combined-slip tire equations. Freeze
    % the measured loads/lateral forces for this local QP. Differentiating
    % their saturation boundary can reverse longitudinal brake effectiveness
    % and lock the controller into braking when the demand is released.
    c=cos(state(7)); s=sin(state(7));
    B(:,1:4)=[c c 1 1; p.lf*s-p.tw*c/2 p.lf*s+p.tw*c/2 -p.tw/2 p.tw/2];
    if effectors(5)
        h=1e-4; trial=state; trial(7)=anchor(5)+h;
        qt=vehicle_dynamics_quantities(trial,p,channels);
        % Steering still uses a local centered nonlinear secant. The QP
        % offset preserves actual tire forces exactly at the anchor.
        trial(7)=anchor(5)-h;
        qm=vehicle_dynamics_quantities(trial,p,channels);
        % Steering is assigned yaw authority only. Crediting its local Fx
        % derivative lets an infeasible braking request induce steering and
        % opposing differential braking, amplifying small asymmetries.
        % Actual longitudinal steering effects remain in the sampled offset.
        B(2,5)=(qt.Mz_total-qm.Mz_total)/(2*h);
    end
    offset=y0-B*anchor; angleLimit=p.delta_max;
end
B(:,effectors==0)=0;
physicalMin=[-p.mu*loads;-angleLimit]; physicalMax=[zeros(4,1);angleLimit];
physicalMin(effectors==0)=0; physicalMax(effectors==0)=0;
% Loss of both steering drives holds the rack. Passive tire forces stay in offset.
if ~isempty(state) && ~effectors(5)
    physicalMin(5)=state(7); physicalMax(5)=state(7);
end
lower=physicalMin; upper=physicalMax; rateOverride=false;
% Operational reserve is separate from the physical friction-circle limit.
% Static authority screening retains full theoretical capacity.
if ~isempty(state)
    lower(1:4)=p.allocation_friction_fraction*physicalMin(1:4);
end
allocationMin=lower; allocationMax=upper;
if ~isempty(u_prev)
    rate=[repmat(p.Fx_rate,4,1);min(p.delta_rate,sum(p.steering_channel_rate.*channels(5:6)))];
    lower=max(lower,u_prev-rate*dt); upper=min(upper,u_prev+rate*dt);
    conflict=lower>upper;
    rateOverride=any(conflict & effectors==1);
    % Only an actually empty intersection requires physical-bound priority.
    % A moving tire bound inside the rate interval must not re-center it.
    repair=min(max(u_prev,allocationMin),allocationMax);
    lower(conflict)=repair(conflict); upper(conflict)=repair(conflict);
end
if ~isempty(state) && effectors(5)
    trustLow=max(lower(5),anchor(5)-p.steering_trust_angle);
    trustHigh=min(upper(5),anchor(5)+p.steering_trust_angle);
    if trustLow<=trustHigh, lower(5)=trustLow; upper(5)=trustHigh; end
end
% Dimensionless variables avoid ill-conditioning from mixing N and radians.
scale=[max(p.mu*static_corner_loads(p)',1);p.delta_max];
W=diag(1./p.allocation_output_scale);
A=W*B*diag(scale); target=W*(demand-offset);
H=A'*A+p.allocation_effort_weight*eye(5); H=(H+H')/2; f=-A'*target;
[z,~,exitflag]=quadprog(H,f,[],[],[],[],lower./scale,upper./scale,[],opts);
if isempty(z) || exitflag<=0
    fallback=zeros(5,1); if ~isempty(u_prev), fallback=u_prev; end
    u=min(max(fallback,lower),upper);
    warning('allocator:SolverFailure','QP exit flag %d; bounded fallback used.',exitflag);
else
    u=min(max(scale.*z,lower),upper);
end
achieved=offset+B*u;
minimumOutput=sum(min(B.*physicalMin',B.*physicalMax'),2);
maximumOutput=sum(max(B.*physicalMin',B.*physicalMax'),2);
authorityScale=max(max(abs(minimumOutput),abs(maximumOutput)),[1;1]);
info=struct('achieved',achieved,'residual',demand-achieved, ...
    'normalized_tracking_error',norm((demand-achieved)./authorityScale), ...
    'fault_mask',channels,'effector_mask',effectors,'B',B,'offset',offset, ...
    'lower_bounds',lower,'upper_bounds',upper, ...
    'physical_lower_bounds',physicalMin,'physical_upper_bounds',physicalMax, ...
    'allocation_lower_bounds',allocationMin,'allocation_upper_bounds',allocationMax, ...
    'output_scale',authorityScale,'objective_scale',p.allocation_output_scale, ...
    'rate_override',rateOverride);
end
