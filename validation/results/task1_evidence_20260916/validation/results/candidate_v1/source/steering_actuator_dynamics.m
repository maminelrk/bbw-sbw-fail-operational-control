function [rackRate, motorRateDerivative, diagnostic] = steering_actuator_dynamics(delta, motorRates, command, mask, p, knownMask)
% Independent velocity loops acting on one common rack (functional model).
% A loss removes drive contribution. Loss of both holds the last rack angle.
% This does not model motor torque, rack inertia, road load or a floating rack.
channels = normalize_actuator_mask(mask);
if nargin < 6, knownMask=channels; end
known = normalize_actuator_mask(knownMask);
healthy = channels(5:6);
capacity = healthy.*p.steering_channel_rate;
aggregateLimit = min(p.delta_rate,sum(capacity));
knownCapacity = known(5:6).*p.steering_channel_rate;
requestedLimit = min(p.delta_rate,sum(knownCapacity));
command = min(max(command,-p.delta_max),p.delta_max);
requestedRate = min(max((command-delta)/p.actuator_tau_delta,-requestedLimit),requestedLimit);
target = zeros(2,1);
if sum(knownCapacity)>0, target=knownCapacity/sum(knownCapacity)*requestedRate; end
% Until diagnosis, the healthy motor keeps its original share. A physically
% failed drive cannot produce motion even when the allocator is unaware.
target=target.*healthy;
motorRateDerivative = (target-motorRates(:))/p.steering_motor_tau;
contribution = min(max(motorRates(:),-capacity),capacity).*healthy;
rackRate = min(max(sum(contribution),-aggregateLimit),aggregateLimit);
if (delta >= p.delta_max && rackRate > 0) || (delta <= -p.delta_max && rackRate < 0)
    rackRate = 0;
end
diagnostic = struct('target_rates',target,'contributions',contribution, ...
    'available_rate',aggregateLimit,'angle_limit',p.delta_max*any(healthy));
end
