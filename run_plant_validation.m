function summary = run_plant_validation()
%RUN_PLANT_VALIDATION Run allocator-free plant validation from project root.

projectRoot = fileparts(mfilename('fullpath'));
validationDirectory = fullfile(projectRoot,'validation');
addpath(validationDirectory);
cleanup = onCleanup(@() rmpath(validationDirectory)); %#ok<NASGU>

summary = run_plant_open_loop_validation();

end
