function result = run_allocator_scenario(scenario, outputRoot)
% Execute one fixed-step allocator/actuator validation scenario.

p = get_params();
Ts = 0.002;
time = (0:Ts:scenario.Duration_s)';
sampleCount = numel(time);
opts = optimoptions('quadprog','Display','off');

uCommand = zeros(sampleCount,5);
uActual = zeros(sampleCount,5);
achieved = zeros(sampleCount,2);
bestAchievable = zeros(sampleCount,2);
trackingError = zeros(sampleCount,1);
solverExitFlag = zeros(sampleCount,1);
maskHistory = ones(sampleCount,5);

previousCommand = zeros(5,1);
actual = zeros(5,1);
demand = [scenario.DemandFx_N; scenario.DemandMz_Nm];

for index = 1:sampleCount
    if isnan(scenario.FaultTime_s) || time(index) < scenario.FaultTime_s
        mask = fault_scenario_mask('nominal');
    else
        mask = fault_scenario_mask(scenario.FaultScenario);
    end

    [command, exitflag, info] = allocator( ...
        demand, actual(5), opts, mask, previousCommand, Ts);

    % Mirror the plant's first-order/rate-limited actuator dynamics. A
    % failed effector's B-column is zero immediately; its internal state is
    % still allowed to decay toward the zero command.
    tau = [repmat(p.actuator_tau_Fx,4,1); p.actuator_tau_delta];
    rate = [repmat(p.Fx_rate,4,1); p.delta_rate];
    derivative = sign(command-actual).*min(abs(command-actual)./tau, rate);
    actual = actual + Ts*derivative;

    output = info.B*actual;
    scale = max(info.output_scale, [1;1]);

    uCommand(index,:) = command';
    uActual(index,:) = actual';
    achieved(index,:) = output';
    bestAchievable(index,:) = info.achieved';
    trackingError(index) = norm((output-info.achieved)./scale, Inf);
    solverExitFlag(index) = exitflag;
    maskHistory(index,:) = mask';
    previousCommand = command;
end

history = table(time, ...
    repmat(scenario.DemandFx_N,sampleCount,1), ...
    repmat(scenario.DemandMz_Nm,sampleCount,1), ...
    achieved(:,1), achieved(:,2), bestAchievable(:,1), bestAchievable(:,2), ...
    trackingError, solverExitFlag, ...
    uCommand(:,1), uCommand(:,2), uCommand(:,3), uCommand(:,4), uCommand(:,5), ...
    uActual(:,1), uActual(:,2), uActual(:,3), uActual(:,4), uActual(:,5), ...
    maskHistory(:,1), maskHistory(:,2), maskHistory(:,3), maskHistory(:,4), maskHistory(:,5), ...
    'VariableNames', {'Time_s','DemandFx_N','DemandMz_Nm','AchievedFx_N','AchievedMz_Nm', ...
    'BestFx_N','BestMz_Nm','NormalizedTrackingError','SolverExitFlag', ...
    'CmdFxFL_N','CmdFxFR_N','CmdFxRL_N','CmdFxRR_N','CmdDelta_rad', ...
    'ActFxFL_N','ActFxFR_N','ActFxRL_N','ActFxRR_N','ActDelta_rad', ...
    'MaskFL','MaskFR','MaskRL','MaskRR','MaskSteering'});

scenarioDirectory = fullfile(outputRoot, scenario.ScenarioID);
if ~isfolder(scenarioDirectory)
    mkdir(scenarioDirectory);
end
writetable(history, fullfile(scenarioDirectory, 'timeseries.csv'));
save(fullfile(scenarioDirectory, 'result.mat'), 'scenario', 'history');

plotScenario(history, scenario, scenarioDirectory);
metrics = calculateMetrics(history, scenario, p, Ts);

result = struct('scenario',scenario,'history',history,'metrics',metrics);
end

function metrics = calculateMetrics(history, scenario, p, Ts)
commands = history{:,10:14};
physicalMinimum = [-p.mu*static_corner_loads(p), -p.delta_max];
physicalMaximum = [0, 0, 0, 0, p.delta_max];

boundsPass = all(commands >= physicalMinimum-1e-6, 'all') && ...
             all(commands <= physicalMaximum+1e-6, 'all');
increments = diff(commands,1,1)/Ts;
ratesPass = all(abs(increments(:,1:4)) <= p.Fx_rate+1e-3, 'all') && ...
            all(abs(increments(:,5)) <= p.delta_rate+1e-6, 'all');
solverPass = all(history.SolverExitFlag > 0);

maskLatency_s = NaN;
settlingTime_s = NaN;
if ~isnan(scenario.FaultTime_s)
    afterFault = find(history.Time_s >= scenario.FaultTime_s, 1, 'first');
    expectedMask = fault_scenario_mask(scenario.FaultScenario)';
    applied = find(all(history{:,20:24} == expectedMask,2) & ...
                   history.Time_s >= scenario.FaultTime_s, 1, 'first');
    if ~isempty(applied)
        maskLatency_s = history.Time_s(applied)-scenario.FaultTime_s;
    end

    windowSamples = round(0.100/Ts);
    for index = afterFault:(height(history)-windowSamples+1)
        if all(history.NormalizedTrackingError(index:index+windowSamples-1) <= 0.10)
            settlingTime_s = history.Time_s(index)-scenario.FaultTime_s;
            break;
        end
    end
end

metrics = struct( ...
    'BoundsPass', boundsPass, ...
    'RatesPass', ratesPass, ...
    'SolverPass', solverPass, ...
    'MaskLatency_s', maskLatency_s, ...
    'SettlingTime_s', settlingTime_s, ...
    'FinalFx_N', history.AchievedFx_N(end), ...
    'FinalMz_Nm', history.AchievedMz_Nm(end), ...
    'FinalNormalizedTrackingError', history.NormalizedTrackingError(end));
end

function plotScenario(history, scenario, scenarioDirectory)
figureHandle = figure('Visible','off','Color','white','Position',[100 100 1100 780]);
layout = tiledlayout(3,1,'TileSpacing','compact','Padding','compact');
title(layout, scenario.ScenarioID + " - " + scenario.Name, 'Interpreter','none');

nexttile;
plot(history.Time_s, history.DemandFx_N, 'k--', 'LineWidth',1.2); hold on;
plot(history.Time_s, history.AchievedFx_N, 'b', 'LineWidth',1.4);
plot(history.Time_s, history.BestFx_N, 'Color',[0.2 0.65 0.45], 'LineWidth',1.0);
ylabel('F_x [N]'); grid on; legend('Demand','Actual','Best achievable','Location','best');

nexttile;
plot(history.Time_s, history.DemandMz_Nm, 'k--', 'LineWidth',1.2); hold on;
plot(history.Time_s, history.AchievedMz_Nm, 'r', 'LineWidth',1.4);
plot(history.Time_s, history.BestMz_Nm, 'Color',[0.2 0.65 0.45], 'LineWidth',1.0);
ylabel('M_z [N m]'); grid on;

nexttile;
plot(history.Time_s, history.NormalizedTrackingError, 'm', 'LineWidth',1.3); hold on;
yline(0.10, 'k--', '10% criterion');
xlabel('Time [s]'); ylabel('Normalized error'); grid on;

exportgraphics(figureHandle, fullfile(scenarioDirectory,'tracking.png'),'Resolution',160);
close(figureHandle);

figureHandle = figure('Visible','off','Color','white','Position',[100 100 1100 650]);
layout = tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
title(layout, scenario.ScenarioID + " - actuator commands", 'Interpreter','none');
nexttile;
plot(history.Time_s, history{:,10:13}, 'LineWidth',1.1);
ylabel('Brake force [N]'); grid on; legend('FL','FR','RL','RR','Location','best');
nexttile;
plot(history.Time_s, rad2deg(history.CmdDelta_rad), 'LineWidth',1.2);
xlabel('Time [s]'); ylabel('Steering [deg]'); grid on;
exportgraphics(figureHandle, fullfile(scenarioDirectory,'actuators.png'),'Resolution',160);
close(figureHandle);
end
