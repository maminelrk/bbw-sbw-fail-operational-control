function best = nonlinear_authority_point(state,mask,config,p)
% Allocator-independent feasible witnesses; local search is NOT a global proof.
% Témoins faisables indépendants de l'allocateur ; pas de preuve globale.
if nargin<4, p=get_params(); end
[mask,effectors]=normalize_actuator_mask(mask);
if ~isfield(config,'Mode'), config.Mode="yaw"; end
if ~isfield(config,'Sign'), config.Sign=1; end
% A strict interior margin avoids the square-root kink at zero lateral budget.
% This conservatively RESTRICTS witnesses; physical upper bounds stay unchanged.
if ~isfield(config,'Fraction'), config.Fraction=.999; end
if ~isfield(config,'DecelCap_g'), config.DecelCap_g=Inf; end
if ~isfield(config,'Target'), config.Target=zeros(2,1); end
if ~isfield(config,'Starts'), config.Starts=12; end
validateattributes(config.Fraction,{'numeric'},{'scalar','positive','<=',1});
validateattributes(config.Starts,{'numeric'},{'scalar','integer','positive'});
forceScale=p.mu*p.m*p.g;
momentScale=forceScale*max(hypot([p.lf p.lr],p.tw/2));
trim=config.Mode=="trim_brake";
lower=[-ones(4,1);-1;0]; upper=[zeros(4,1);1;0];
lower(mask(1:4)==0)=0;
if ~effectors(5), lower(5)=state(7)/p.delta_max; upper(5)=lower(5); end
if trim, lower(6)=-1; upper(6)=1; end
base=[state(8:11)/forceScale;state(7)/p.delta_max;0];
loads=static_corner_loads(p)'/sum(static_corner_loads(p));
seeds=[base zeros(6,1) [-.5*loads;0;0] [-.9*loads;0;0]];
for angle=[-.12 -.04 .04 .12]
    seeds(:,end+1)=[-.5*loads;angle/p.delta_max;0]; %#ok<AGROW>
end
seeds(:,end+1)=[-loads.*[1;0;1;0];0;0];
seeds(:,end+1)=[-loads.*[0;1;0;1];0;0];
seeds(:,end+1)=[-.7*loads;-.05/p.delta_max;.08];
seeds(:,end+1)=[-.7*loads;.05/p.delta_max;-.08];
count=min(config.Starts,size(seeds,2));
options=optimoptions('fmincon','Algorithm','sqp','Display','off', ...
    'MaxIterations',250,'MaxFunctionEvaluations',5000,'ConstraintTolerance',1e-9, ...
    'OptimalityTolerance',1e-9,'StepTolerance',1e-11);
best=struct('Feasible',false,'Objective',Inf,'ExitFlag',NaN,'Violation',Inf, ...
    'State',state,'Output',[NaN;NaN],'Fy_N',NaN,'Residual',Inf,'Starts',count, ...
    'AllExitFlags',zeros(count,1),'AllObjectives',NaN(count,1), ...
    'GlobalOptimalityProven',false,'WitnessSource',"none",'Config',config);
for k=1:count
    start=min(max(seeds(:,k),lower),upper);
    % Never lose an already feasible point because an optimizer later stalls.
    consider(start,objective(start),0,"seed");
    [z,value,flag]=fmincon(@objective,start,[],[],[],[],lower,upper,@constraints,options);
    best.AllExitFlags(k)=flag; best.AllObjectives(k)=value;
    consider(z,value,flag,"optimized");
end

    function consider(z,value,flag,origin)
        [c,ceq]=constraints(z); violation=max([0;c(:);abs(ceq(:));lower-z;z-upper]);
    % A feasible witness is useful even if the local optimality test stopped.
    if all(isfinite(z)) && violation<=1e-7 && value<best.Objective
        x=make_state(z); q=vehicle_dynamics_quantities(x,p,mask);
        best.Feasible=true; best.Objective=value; best.ExitFlag=flag;
        best.Violation=violation; best.State=x; best.Output=[q.Fx_total;q.Mz_total];
        best.Fy_N=q.Fy_total;
        best.Residual=norm((best.Output-config.Target)./[forceScale;momentScale],Inf);
        best.WitnessSource=origin;
    end
    end

    function x=make_state(z)
        x=state; x(8:11)=forceScale*z(1:4); x(7)=p.delta_max*z(5);
        if trim, x(2)=x(1)*tan(.15*z(6)); x(3)=0; end
    end
    function value=objective(z)
        q=vehicle_dynamics_quantities(make_state(z),p,mask);
        switch config.Mode
            case "trim_brake", value=q.Fx_total/forceScale;
            case "yaw", value=-config.Sign*q.Mz_total/momentScale;
            case "match"
                residual=([q.Fx_total;q.Mz_total]-config.Target)./[forceScale;momentScale];
                value=sum(residual.^2);
            otherwise, error('Unknown nonlinear assessment mode.');
        end
    end
    function [c,ceq]=constraints(z)
        x=make_state(z); q=vehicle_dynamics_quantities(x,p,mask);
        % Explicit contact-force consistency prevents exploiting plant clipping.
        c=[(1e-6-q.Fz_raw)/(p.m*p.g); ...
            (-config.Fraction*p.mu*q.Fz_raw-x(8:11))/forceScale; ...
            q.Fx_total/forceScale];
        if isfinite(config.DecelCap_g)
            c(end+1)=-(q.Fx_total/p.m+x(2)*x(3))/p.g-config.DecelCap_g;
        end
        ceq=[];
        if trim, ceq=[q.Fy_total/(p.m*p.g);q.Mz_total/momentScale]; end
    end
end
