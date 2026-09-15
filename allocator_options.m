function opts=allocator_options()
% Shared production QP settings, explicit for reproducible MATLAB campaigns.
% The grip reserve keeps the nonlinear plant away from zero lateral budget.
% Retain interior-point-convex: an active-set trial cycled on moving bounds.
% Solver-only MATLAB comparison selected 1e-12: the prior 1e-9 tolerance
% admitted null-space asymmetries amplified by the saturated vehicle loop.
opts=optimoptions('quadprog','Algorithm','interior-point-convex','Display','off', ...
    'OptimalityTolerance',1e-12,'ConstraintTolerance',1e-9);
end
