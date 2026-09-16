function next = plant_step(x,u,mask,dt,p,knownMask)
% RK4 with zero-order-held allocator commands over one sample.
if nargin < 6, knownMask=mask; end
f = @(z) vehicle_derivatives_block(z,u(5),u(1:4),mask,p,knownMask);
k1=f(x); k2=f(x+dt*k1/2); k3=f(x+dt*k2/2); k4=f(x+dt*k3);
next=x+dt*(k1+2*k2+2*k3+k4)/6;
% Common rack mechanical end stops; motor states remain continuous.
next(7)=min(max(next(7),-p.delta_max),p.delta_max);
end
