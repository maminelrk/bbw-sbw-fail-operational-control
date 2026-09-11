function summary = run_validation_campaign()
% Run automated unit tests and nominal/fault validation scenarios.
%
% Outputs are written beneath validation/results and are safe to regenerate.

validationDirectory = fileparts(mfilename('fullpath'));
projectRoot = fileparts(validationDirectory);
testsDirectory = fullfile(projectRoot,'tests');
resultsDirectory = fullfile(validationDirectory,'results');

addpath(projectRoot, validationDirectory);
cleanup = onCleanup(@() rmpath(projectRoot, validationDirectory)); %#ok<NASGU>

if ~isfolder(resultsDirectory)
    mkdir(resultsDirectory);
end

unitResults = runtests(testsDirectory, 'IncludeSubfolders', true);
unitTable = table(string({unitResults.Name})', [unitResults.Passed]', ...
    [unitResults.Failed]', [unitResults.Incomplete]', ...
    seconds([unitResults.Duration])', ...
    'VariableNames', {'TestName','Passed','Failed','Incomplete','Duration_s'});
writetable(unitTable, fullfile(resultsDirectory,'unit_test_results.csv'));

scenarios = validation_scenarios();
rows = cell(height(scenarios),1);
for index = 1:height(scenarios)
    result = run_allocator_scenario(scenarios(index,:), resultsDirectory);
    metric = result.metrics;

    if isnan(metric.MaskLatency_s)
        maskStatus = "Not applicable";
    elseif metric.MaskLatency_s <= 0.010
        maskStatus = "Pass";
    else
        maskStatus = "Fail";
    end

    if isnan(metric.SettlingTime_s)
        settlingStatus = "Not applicable";
    elseif metric.SettlingTime_s <= 0.050
        settlingStatus = "Pass";
    else
        settlingStatus = "Fail";
    end

    overallPass = metric.BoundsPass && metric.RatesPass && metric.SolverPass && ...
        maskStatus ~= "Fail" && settlingStatus ~= "Fail";
    rows{index} = {scenarios.ScenarioID(index), scenarios.Name(index), ...
        scenarios.RequirementIDs(index), metric.BoundsPass, metric.RatesPass, ...
        metric.SolverPass, metric.MaskLatency_s, maskStatus, ...
        metric.SettlingTime_s, settlingStatus, metric.FinalFx_N, ...
        metric.FinalMz_Nm, metric.FinalNormalizedTrackingError, overallPass};
end

summary = cell2table(vertcat(rows{:}), 'VariableNames', ...
    {'ScenarioID','Name','RequirementIDs','BoundsPass','RatesPass','SolverPass', ...
     'MaskLatency_s','MaskStatus','SettlingTime_s','SettlingStatus', ...
     'FinalFx_N','FinalMz_Nm','FinalNormalizedTrackingError','OverallPass'});
writetable(summary, fullfile(resultsDirectory,'validation_summary.csv'));
save(fullfile(resultsDirectory,'validation_campaign.mat'), ...
    'summary','scenarios','unitResults');

fprintf('Validation campaign complete: %d scenarios, %d unit tests.\n', ...
    height(summary), numel(unitResults));
fprintf('Results: %s\n', resultsDirectory);
end
