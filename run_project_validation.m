function results = run_project_validation()
%RUN_PROJECT_VALIDATION Run plant and control-allocation validation.
%   RESULTS contains separate plant and allocation campaign summaries.
%   Generated evidence is written beneath validation/results.

projectRoot = fileparts(mfilename('fullpath'));
validationDirectory = fullfile(projectRoot, 'validation');

originalPath=path;
cleanup=onCleanup(@() path(originalPath)); %#ok<NASGU>
addpath(projectRoot,validationDirectory);

results = struct();
results.gate2 = run_gate2_validation();
results.allocation = run_validation_campaign();

end
