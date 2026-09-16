function [physical,known] = fault_event_masks(t,scenario)
% Permanent fail-silent fault; physical onset and delivered diagnosis differ.
% Events are applied on the first sample at or after their requested time.
physical=ones(6,1); known=physical;
if ~isfield(scenario,'FaultScenario') || scenario.FaultScenario=="nominal", return; end
assert(isfinite(scenario.FaultTime) && scenario.FaultTime>=0, ...
    'fault_event_masks:Time','FaultTime must be finite and nonnegative.');
assert(isfinite(scenario.DetectionDelay) && scenario.DetectionDelay>=0, ...
    'fault_event_masks:Delay','DetectionDelay must be finite and nonnegative.');
failed=fault_scenario_mask(scenario.FaultScenario);
if t+1e-12>=scenario.FaultTime, physical=failed; end
if t+1e-12>=scenario.FaultTime+scenario.DetectionDelay, known=failed; end
end
