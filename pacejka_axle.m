function Fy = pacejka_axle(alpha, Fz_axle, Cx_axle, p, Fx_axle)
% Simplified combined-slip Pacejka (axle-lumped) with friction-ellipse
% coupling to longitudinal force Fx_axle.
if nargin < 5
    Fx_axle = 0;
end
Fz_axle = max(Fz_axle, 1);
mu_budget = max(1 - (Fx_axle/(p.mu*Fz_axle))^2, 0);
D = p.mu * Fz_axle * sqrt(mu_budget);
D = max(D, 1);
B = Cx_axle / (p.Cshape * D);
Fy = D * sin(p.Cshape * atan(B*alpha - p.Eshape*(B*alpha - atan(B*alpha))));
end
