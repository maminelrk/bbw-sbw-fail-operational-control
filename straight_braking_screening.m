function result = straight_braking_screening(p)
% Analytical zero-steer, zero-yaw equilibrium with longitudinal load transfer.
% NOT the maximum capability with active steering, nor a dynamic REQ-03 test.
if nargin<1, p=get_params(); end
% Zero yaw requires equal left/right braking. After front loss the affected
% side only has a rear tire: m*a <= mu*(m*g*(1-wf)-m*a*h/L).
% After rear loss the affected side only has a front tire (opposite sign).
frontRatio=(1-p.wf)/(1+p.mu*p.hcg/p.L);
rearRatio=min(1,p.wf/(1-p.mu*p.hcg/p.L));
assert(1-p.mu*p.hcg/p.L>0,'Screening assumptions require positive denominator.');
Corner=["FL";"FR";"RL";"RR"];
ZeroSteerRatio=[frontRatio;frontRatio;rearRatio;rearRatio];
Deceleration_mps2=p.mu*p.g*ZeroSteerRatio;
RawStaticForceRatio=1-static_corner_loads(p)'/(p.m*p.g);
result=table(Corner,ZeroSteerRatio,Deceleration_mps2,RawStaticForceRatio);
end
