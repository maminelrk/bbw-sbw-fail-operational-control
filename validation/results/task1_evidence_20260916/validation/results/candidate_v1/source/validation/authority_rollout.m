function out = authority_rollout(state,previous,witness,mask,target,p)
% Allocator-free, rate-limited 50 ms witness rollout, not an optimal reach set.
% Simulation témoin sur 50 ms, sans allocateur ni preuve de portée optimale.
dt=.002; time=(0:dt:.05)'; n=numel(time); x=state(:); u=previous(:);
[mask,effectors]=normalize_actuator_mask(mask);
effectors=logical(effectors);
desired=[witness.State(8:11);witness.State(7)];
states=zeros(n,13); commands=zeros(n,5); outputs=zeros(n,2); valid=true;
rate=[repmat(p.Fx_rate,4,1);min(p.delta_rate,sum(mask(5:6).*p.steering_channel_rate))];
for k=1:n
    q=vehicle_dynamics_quantities(x,p,mask);
    lower=[-p.mu*q.Fz;-p.delta_max]; upper=[zeros(4,1);p.delta_max];
    lower(~effectors)=0; upper(~effectors)=0;
    if ~effectors(5), lower(5)=x(7); upper(5)=x(7); end
    lo=max(lower,u-dt*rate); hi=min(upper,u+dt*rate);
    lo(~effectors)=lower(~effectors); hi(~effectors)=upper(~effectors);
    if any(lo>hi+1e-9), valid=false; lo=lower; hi=upper; end
    next=min(max(desired,lo),hi);
    valid=valid && all(abs(next(effectors)-u(effectors))<=dt*rate(effectors)+1e-8) && ...
        all(q.Fz_raw>0) && x(1)>p.vx_floor && abs(atan2(x(2),x(1)))<=.15 && ...
        all(q.Fx_actual.^2+q.Fy_wheels.^2<=(p.mu*q.Fz).^2+1e-3);
    u=next; states(k,:)=x'; commands(k,:)=u'; outputs(k,:)=[q.Fx_total q.Mz_total];
    if k<n, x=plant_step(x,u,mask,dt,p,mask); end
end
F=p.mu*p.m*p.g; M=F*max(hypot([p.lf p.lr],p.tw/2));
scale=max(abs(target),.05*[F;M]);
out=struct('Time',time,'States',states,'Commands',commands,'Outputs',outputs, ...
    'PhysicalAndCommandChecksPass',valid,'Target',target, ...
    'EndpointNormalizedError',norm((outputs(end,:)'-target)./scale,Inf), ...
    'DynamicOptimalityProven',false);
end
