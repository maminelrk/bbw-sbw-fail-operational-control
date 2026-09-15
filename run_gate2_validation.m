function results=run_gate2_validation()
% Reproducible Gate 2 evidence. A failed check prevents acceptance status.
root=fileparts(mfilename('fullpath')); oldPath=path;
cleanup=onCleanup(@() path(oldPath)); %#ok<NASGU>
addpath(root,fullfile(root,'validation'));
assert(exist('quadprog','file')==2,'Optimization Toolbox (quadprog) is required.');
folder=fullfile(root,'validation','results','gate2');
if ~isfolder(folder), mkdir(folder); end
started=datetime('now','TimeZone','UTC'); p=get_params();
% Invalidate any previous acceptance before overwriting its evidence files.
write_manifest(folder,struct('Status','RUNNING','AllChecksPassed',false, ...
    'StartedUTC',char(started),'ParameterSet',p.parameter_set_id));
results=struct();
results.units=runtests(fullfile(root,'tests'),'IncludeSubfolders',true);
unitTable=table(string({results.units.Name})',[results.units.Passed]', ...
    [results.units.Failed]',[results.units.Incomplete]',[results.units.Duration]', ...
    'VariableNames',{'Test','Passed','Failed','Incomplete','Duration_s'});
writetable(unitTable,fullfile(folder,'unit_tests.csv'));
results.plant=run_plant_open_loop_validation();
benchFolder=fullfile(folder,'steering'); if ~isfolder(benchFolder), mkdir(benchFolder); end
results.steering=run_steering_bench(benchFolder);
scenarios=gate2_maneuvers(); rows=cell(numel(scenarios),1);
for k=1:numel(scenarios)
    out=run_integrated_maneuver(scenarios(k),folder);
    rows{k}=struct2table(out.metrics);
end
results.integrated=vertcat(rows{:});
writetable(results.integrated,fullfile(folder,'maneuver_summary.csv'));
% Discretization check on the transient combined maneuver, fixed tuning.
coarse=run_integrated_maneuver(scenarios(3),[],p.validation_dt);
fine=run_integrated_maneuver(scenarios(3),[],p.validation_dt/2);
yawDelta=max(abs(coarse.series.YawRate_radps-fine.series.YawRate_radps(1:2:end)));
speedDelta=max(abs(coarse.series.Vx_mps-fine.series.Vx_mps(1:2:end)));
convergence=struct('YawDifference_radps',yawDelta,'SpeedDifference_mps',speedDelta, ...
    'YawTolerance_radps',0.001,'SpeedTolerance_mps',0.03, ...
    'OverallPass',yawDelta<=0.001 && speedDelta<=0.03);
results.convergence=convergence;
writetable(struct2table(convergence),fullfile(folder,'step_convergence.csv'));
allPassed=all(unitTable.Passed & ~unitTable.Incomplete) && ...
    all(results.plant.OverallPass) && all(results.steering.OverallPass) && ...
    all(results.integrated.OverallPass) && convergence.OverallPass;
status="CHECKS_FAILED"; if allPassed, status="READY_FOR_SUPERVISOR_REVIEW"; end
[gitCode,commit]=system(sprintf('git -C "%s" rev-parse HEAD',root));
[dirtyCode,dirty]=system(sprintf('git -C "%s" status --porcelain',root));
metadata=struct('Status',status,'MATLABVersion',version,'Release',version('-release'), ...
    'Products',ver,'StartedUTC',char(started),'ParameterSet',p.parameter_set_id, ...
    'Parameters',p,'GitCommit',strtrim(commit),'GitReadSucceeded',gitCode==0 && dirtyCode==0, ...
    'GitWorkingTreeStatus',dirty,'AllChecksPassed',allPassed,'ScenarioCount',numel(scenarios));
write_manifest(folder,metadata);
save(fullfile(folder,'gate2_results.mat'),'results','metadata','scenarios');
fprintf('Gate 2: %s\nEvidence: %s\n',status,folder);
if ~allPassed
    error('run_gate2_validation:Failed','Gate 2 checks failed. Review saved metrics before closing the gate.');
end
end

function write_manifest(folder,metadata)
fid=fopen(fullfile(folder,'run_manifest.json'),'w','n','UTF-8');
assert(fid>=0,'Cannot create run manifest.');
closeFile=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(metadata,'PrettyPrint',true));
end
