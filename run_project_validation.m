function results = run_project_validation()
%RUN_PROJECT_VALIDATION Run plant and control-allocation validation.
%   RESULTS contains separate plant and allocation campaign summaries.
%   Generated evidence is written beneath validation/results.

projectRoot = fileparts(mfilename('fullpath'));
validationDirectory = fullfile(projectRoot, 'validation');

addpath(validationDirectory);
cleanup = onCleanup(@() rmpath(validationDirectory)); %#ok<NASGU>

results = struct();
results.plant = run_plant_open_loop_validation();
results.allocation = run_validation_campaign();

end
