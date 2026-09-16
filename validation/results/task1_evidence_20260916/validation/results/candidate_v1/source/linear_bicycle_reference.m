function reference = linear_bicycle_reference(vx, delta, p)
%LINEAR_BICYCLE_REFERENCE Small-angle steady-state bicycle-model solution.
%   Used only as an independent analytical reference for open-loop plant
%   validation. Cf and Cr are axle-lumped cornering stiffnesses.

if nargin < 3 || isempty(p)
    p = get_params();
end
if ~isscalar(vx) || ~isfinite(vx) || vx <= p.vx_floor
    error('linear_bicycle_reference:Speed', ...
        'vx must be a finite scalar greater than vx_floor.');
end
if ~isscalar(delta) || ~isfinite(delta)
    error('linear_bicycle_reference:Steering', ...
        'delta must be a finite scalar steering angle.');
end

A = [-(p.Cf+p.Cr)/vx, ...
     (-p.Cf*p.lf+p.Cr*p.lr)/vx-p.m*vx; ...
     (-p.lf*p.Cf+p.lr*p.Cr)/vx, ...
     -(p.lf^2*p.Cf+p.lr^2*p.Cr)/vx];
b = [p.Cf; p.lf*p.Cf];
solution = -A\(b*delta);

reference = struct('lateral_velocity',solution(1), ...
    'yaw_rate',solution(2), ...
    'sideslip',atan2(solution(1),vx), ...
    'lateral_acceleration',vx*solution(2));

end
