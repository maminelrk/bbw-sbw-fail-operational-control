function [channels, effectors] = normalize_actuator_mask(mask)
% Six physical channels: FL FR RL RR steering-A steering-B.
% A legacy fifth entry disables/enables BOTH steering channels.
if nargin == 0 || isempty(mask), mask = ones(6,1); end
mask = mask(:);
if ~ismember(numel(mask),[5 6]) || any(~ismember(mask,[0 1]))
    error('normalize_actuator_mask:Invalid','Mask must contain five or six binary entries.');
end
if numel(mask) == 5, mask = [mask(1:4); mask(5); mask(5)]; end
channels = mask;
effectors = [mask(1:4); any(mask(5:6))];
end
