function summary = run_plant_open_loop_validation()
%RUN_PLANT_OPEN_LOOP_VALIDATION Validate the plant without an allocator.
%   Runs fixed-step, open-loop braking, steering, and combined-input cases.
%   Evidence is written beneath validation/results/plant.

validationDirectory = fileparts(mfilename('fullpath'));
projectRoot = fileparts(validationDirectory);
resultsDirectory = fullfile(validationDirectory,'results','plant');

addpath(projectRoot, validationDirectory);
cleanup = onCleanup(@() rmpath(projectRoot, validationDirectory)); %#ok<NASGU>

if ~isfolder(resultsDirectory)
    mkdir(resultsDirectory);
end

p = get_params();
scenarios = plant_open_loop_scenarios();
rows = cell(numel(scenarios),1);

for index = 1:numel(scenarios)
    result = simulate_open_loop_scenario(scenarios(index), p, resultsDirectory);
    metric = result.metrics;
    rows{index} = {string(scenarios(index).ScenarioID), ...
        string(scenarios(index).Name), metric.FinitePass, ...
        metric.NormalLoadPass, metric.FrictionEllipsePass, ...
        metric.ActuatorRatePass, metric.BehaviorPass, ...
        metric.InitialSpeed_mps, metric.FinalSpeed_mps, ...
        metric.PeakAbsYawRate_radps, metric.FinalYawRate_radps, ...
        metric.PeakAbsSideslip_rad, metric.LinearYawReference_radps, ...
        metric.LinearYawRelativeError, metric.OverallPass};
end

summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'ScenarioID','Name','FinitePass','NormalLoadPass', ...
     'FrictionEllipsePass','ActuatorRatePass','BehaviorPass', ...
     'InitialSpeed_mps','FinalSpeed_mps','PeakAbsYawRate_radps', ...
     'FinalYawRate_radps','PeakAbsSideslip_rad', ...
     'LinearYawReference_radps','LinearYawRelativeError','OverallPass'});

writetable(summary, fullfile(resultsDirectory,'plant_validation_summary.csv'));
save(fullfile(resultsDirectory,'plant_validation.mat'), ...
    'summary','scenarios','p');

fprintf('Open-loop plant validation complete: %d scenarios.\n', height(summary));
fprintf('Results: %s\n', resultsDirectory);

end

function result = simulate_open_loop_scenario(scenario, p, resultsDirectory)
dt = p.validation_dt;
time = (0:dt:scenario.Duration_s)';
sampleCount = numel(time);
state = zeros(sampleCount,11);
state(1,1) = scenario.InitialSpeed_mps;

deltaCommand = zeros(sampleCount,1);
brakeCommand = zeros(sampleCount,4);
normalLoads = zeros(sampleCount,4);
alpha = zeros(sampleCount,2);
lateralForce = zeros(sampleCount,2);
lateralCapacity = zeros(sampleCount,2);
bodyForce = zeros(sampleCount,2);
yawMoment = zeros(sampleCount,1);

for sample = 1:sampleCount
    [deltaCommand(sample), brakeCommand(sample,:)] = ...
        commands_at_time(time(sample), scenario);
    q = vehicle_dynamics_quantities(state(sample,:)', p);
    normalLoads(sample,:) = q.Fz';
    alpha(sample,:) = [q.alpha_front, q.alpha_rear];
    lateralForce(sample,:) = [q.Fyf, q.Fyr];
    lateralCapacity(sample,:) = ...
        [q.front_lateral_capacity, q.rear_lateral_capacity];
    bodyForce(sample,:) = [q.Fx_total, q.Fy_total];
    yawMoment(sample) = q.Mz_total;

    if sample < sampleCount
        state(sample+1,:) = rk4_step(time(sample), state(sample,:)', ...
            dt, scenario)';
    end
end

actualRate = [zeros(1,5); diff(state(:,7:11))/dt];
sideslip = atan2(state(:,2), max(state(:,1),p.vx_floor));
lateralAcceleration = bodyForce(:,2)/p.m;

finitePass = all(isfinite([state, normalLoads, lateralForce, bodyForce]),'all');
normalLoadPass = min(normalLoads,[],'all') >= 49.9;
frictionEllipsePass = all(abs(lateralForce) <= lateralCapacity+1e-6,'all');
actuatorRatePass = all(abs(actualRate(:,1)) <= p.delta_rate+1e-6) && ...
    all(abs(actualRate(:,2:5)) <= p.Fx_rate+1e-3,'all');

linearYawReference = NaN;
linearYawRelativeError = NaN;
switch scenario.ScenarioID
    case "PLANT-BRK-01"
        behaviorPass = max(abs(state(:,3))) <= 1e-5 && ...
            max(abs(state(:,5))) <= 1e-4 && ...
            state(end,1) <= state(1,1)-2.0 && ...
            all(bodyForce(time >= scenario.BrakeStepTime_s,1) <= 1e-6);
    case "PLANT-STR-01"
        reference = linear_bicycle_reference( ...
            scenario.InitialSpeed_mps, scenario.Steering_rad, p);
        linearYawReference = reference.yaw_rate;
        linearYawRelativeError = abs(state(end,3)-linearYawReference) / ...
            max(abs(linearYawReference),1e-6);
        behaviorPass = state(end,3) > 0.02 && ...
            linearYawRelativeError <= 0.20 && ...
            max(abs(sideslip)) <= 0.15 && ...
            max(abs(lateralAcceleration)) <= 1.05*p.mu*p.g;
    case "PLANT-CMB-01"
        uncombinedCapacity = p.mu*[sum(normalLoads(:,1:2),2), ...
            sum(normalLoads(:,3:4),2)];
        couplingObserved = any(lateralCapacity(time >= scenario.BrakeStepTime_s,:) ...
            < 0.99*uncombinedCapacity(time >= scenario.BrakeStepTime_s,:),'all');
        behaviorPass = state(end,3) > 0.02 && ...
            state(end,1) <= state(1,1)-1.0 && couplingObserved && ...
            max(abs(sideslip)) <= 0.15 && ...
            max(abs(lateralAcceleration)) <= 1.05*p.mu*p.g;
    otherwise
        error('run_plant_open_loop_validation:Scenario', ...
            'Unsupported plant scenario %s.', scenario.ScenarioID);
end

overallPass = finitePass && normalLoadPass && frictionEllipsePass && ...
    actuatorRatePass && behaviorPass;

metrics = struct( ...
    'FinitePass',finitePass,'NormalLoadPass',normalLoadPass, ...
    'FrictionEllipsePass',frictionEllipsePass, ...
    'ActuatorRatePass',actuatorRatePass,'BehaviorPass',behaviorPass, ...
    'InitialSpeed_mps',state(1,1),'FinalSpeed_mps',state(end,1), ...
    'PeakAbsYawRate_radps',max(abs(state(:,3))), ...
    'FinalYawRate_radps',state(end,3), ...
    'PeakAbsSideslip_rad',max(abs(sideslip)), ...
    'LinearYawReference_radps',linearYawReference, ...
    'LinearYawRelativeError',linearYawRelativeError, ...
    'OverallPass',overallPass);

scenarioDirectory = fullfile(resultsDirectory,scenario.ScenarioID);
if ~isfolder(scenarioDirectory)
    mkdir(scenarioDirectory);
end

series = table(time,state(:,1),state(:,2),state(:,3),state(:,4), ...
    state(:,5),state(:,6),state(:,7),state(:,8),state(:,9), ...
    state(:,10),state(:,11),deltaCommand,brakeCommand(:,1), ...
    brakeCommand(:,2),brakeCommand(:,3),brakeCommand(:,4), ...
    normalLoads(:,1),normalLoads(:,2),normalLoads(:,3),normalLoads(:,4), ...
    alpha(:,1),alpha(:,2),lateralForce(:,1),lateralForce(:,2), ...
    lateralCapacity(:,1),lateralCapacity(:,2),bodyForce(:,1), ...
    bodyForce(:,2),yawMoment,sideslip,lateralAcceleration, ...
    'VariableNames',{'Time_s','Vx_mps','Vy_mps','YawRate_radps', ...
    'X_m','Y_m','YawAngle_rad','SteeringActual_rad','FxFL_N','FxFR_N', ...
    'FxRL_N','FxRR_N','SteeringCommand_rad','FxFLCommand_N', ...
    'FxFRCommand_N','FxRLCommand_N','FxRRCommand_N','FzFL_N','FzFR_N', ...
    'FzRL_N','FzRR_N','AlphaFront_rad','AlphaRear_rad','FyFront_N', ...
    'FyRear_N','FyFrontCapacity_N','FyRearCapacity_N','FxBody_N', ...
    'FyBody_N','YawMoment_Nm','Sideslip_rad','LateralAcceleration_mps2'});
writetable(series,fullfile(scenarioDirectory,'timeseries.csv'));
save(fullfile(scenarioDirectory,'result.mat'),'series','metrics','scenario','p');

figure('Visible','off');
tiledlayout(3,1);
nexttile; plot(time,state(:,1),'LineWidth',1.2); ylabel('v_x [m/s]'); grid on;
title(strrep(scenario.Name,'_',' '));
nexttile; plot(time,state(:,3),'LineWidth',1.2); ylabel('r [rad/s]'); grid on;
nexttile; plot(state(:,4),state(:,5),'LineWidth',1.2); ...
    xlabel('X [m]'); ylabel('Y [m]'); axis equal; grid on;
exportgraphics(gcf,fullfile(scenarioDirectory,'vehicle_response.png'));
close(gcf);

figure('Visible','off');
tiledlayout(3,1);
nexttile; plot(time,rad2deg([deltaCommand,state(:,7)]),'LineWidth',1.2); ...
    ylabel('\delta [deg]'); legend('Command','Actual','Location','best'); grid on;
nexttile; plot(time,state(:,8:11),'LineWidth',1.1); ylabel('F_x [N]'); ...
    legend('FL','FR','RL','RR','Location','best'); grid on;
nexttile; plot(time,normalLoads,'LineWidth',1.1); ylabel('F_z [N]'); ...
    xlabel('Time [s]'); legend('FL','FR','RL','RR','Location','best'); grid on;
exportgraphics(gcf,fullfile(scenarioDirectory,'actuators_and_loads.png'));
close(gcf);

figure('Visible','off');
tiledlayout(2,1);
nexttile; plot(time,lateralForce,'LineWidth',1.2); hold on; ...
    plot(time,lateralCapacity,'--','LineWidth',1.0); ...
    plot(time,-lateralCapacity,'--','LineWidth',1.0); ...
    ylabel('F_y [N]'); grid on;
nexttile; plot(time,rad2deg(alpha),'LineWidth',1.2); ...
    ylabel('\alpha [deg]'); xlabel('Time [s]'); ...
    legend('Front','Rear','Location','best'); grid on;
exportgraphics(gcf,fullfile(scenarioDirectory,'tire_response.png'));
close(gcf);

result = struct('metrics',metrics,'series',series);

    function nextState = rk4_step(t,currentState,step,activeScenario)
        k1 = plant_rhs(t,currentState,activeScenario);
        k2 = plant_rhs(t+step/2,currentState+step*k1/2,activeScenario);
        k3 = plant_rhs(t+step/2,currentState+step*k2/2,activeScenario);
        k4 = plant_rhs(t+step,currentState+step*k3,activeScenario);
        nextState = currentState + step*(k1+2*k2+2*k3+k4)/6;
    end

    function derivative = plant_rhs(t,currentState,activeScenario)
        [steering,braking] = commands_at_time(t,activeScenario);
        derivative = vehicle_derivatives_block(currentState,steering,braking');
    end
end

function [steering, braking] = commands_at_time(t, scenario)
if t >= scenario.SteeringStepTime_s
    steering = scenario.Steering_rad;
else
    steering = 0;
end
if t >= scenario.BrakeStepTime_s
    braking = scenario.BrakeForces_N(:)';
else
    braking = zeros(1,4);
end
end
