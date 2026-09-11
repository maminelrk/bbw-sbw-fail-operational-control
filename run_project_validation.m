function summary = run_project_validation()
%RUN_PROJECT_VALIDATION Run the repository validation campaign.
%   SUMMARY = RUN_PROJECT_VALIDATION() adds the validation folder for this
%   call and returns the scenario summary table. Generated evidence is
%   written beneath validation/results.

projectRoot = fileparts(mfilename('fullpath'));
validationDirectory = fullfile(projectRoot, 'validation');

addpath(validationDirectory);
cleanup = onCleanup(@() rmpath(validationDirectory)); %#ok<NASGU>

summary = run_validation_campaign();

end
