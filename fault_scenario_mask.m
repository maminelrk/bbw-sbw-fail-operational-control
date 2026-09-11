function mask = fault_scenario_mask(scenario)
% Named binary effector masks for allocator fault-injection studies.
%
% Order: [brake_FL brake_FR brake_RL brake_RR steering]'.
% Actuator, power-path, and communication-path losses that remove the same
% effector intentionally map to the same allocation-layer mask. Detection
% and architecture-level causes remain separate entries in the FMEA.

scenario = lower(strtrim(string(scenario)));

switch scenario
    case {"nominal", "none"}
        mask = [1; 1; 1; 1; 1];
    case {"brake_fl_loss", "fl_loss"}
        mask = [0; 1; 1; 1; 1];
    case {"brake_fr_loss", "fr_loss"}
        mask = [1; 0; 1; 1; 1];
    case {"brake_rl_loss", "rl_loss"}
        mask = [1; 1; 0; 1; 1];
    case {"brake_rr_loss", "rr_loss"}
        mask = [1; 1; 1; 0; 1];
    case {"steering_loss", "sbw_loss"}
        mask = [1; 1; 1; 1; 0];

    % Extended circuit-level cases. Keep these out of the mandatory
    % single-corner campaign until the vehicle circuit split is confirmed.
    case {"diagonal_fl_rr_loss", "circuit_fl_rr_loss"}
        mask = [0; 1; 1; 0; 1];
    case {"diagonal_fr_rl_loss", "circuit_fr_rl_loss"}
        mask = [1; 0; 0; 1; 1];
    case "front_circuit_loss"
        mask = [0; 0; 1; 1; 1];
    case "rear_circuit_loss"
        mask = [1; 1; 0; 0; 1];
    otherwise
        error('fault_scenario_mask:UnknownScenario', ...
            'Unknown fault scenario "%s".', scenario);
end

end
