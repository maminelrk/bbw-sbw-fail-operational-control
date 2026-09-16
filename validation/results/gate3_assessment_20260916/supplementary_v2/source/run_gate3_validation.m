function results = run_gate3_validation()
% Diagnostic fault campaign. It NEVER automatically closes Gate 3.
root=fileparts(mfilename('fullpath')); oldPath=path;
cleanup=onCleanup(@() path(oldPath)); %#ok<NASGU>
addpath(root,fullfile(root,'validation'));
assert(exist('quadprog','file')==2,'Optimization Toolbox (quadprog) is required.');
folder=fullfile(root,'validation','results','gate3');
if ~isfolder(folder), mkdir(folder); end
started=datetime('now','TimeZone','UTC');
write_manifest(folder,struct('Status','RUNNING','Gate3Closed',false,'StartedUTC',char(started)));
cases=gate3_fault_cases(); results=struct();
results.units=runtests(fullfile(root,'tests'),'IncludeSubfolders',true);
unitTable=table(string({results.units.Name})',[results.units.Passed]', ...
    [results.units.Incomplete]','VariableNames',{'Test','Passed','Incomplete'});
writetable(unitTable,fullfile(folder,'unit_tests.csv'));
assert(all(unitTable.Passed & ~unitTable.Incomplete), ...
    'run_gate3_validation:UnitTests','Unit tests must pass before the fault campaign.');
keys=unique(string({cases.ReferenceKey}),'stable'); references=cell(numel(keys),1);
for j=1:numel(keys)
    candidate=find(string({cases.ReferenceKey})==keys(j),1);
    nominal=cases(candidate); nominal.FaultScenario="nominal"; nominal.ID="G3-NOM-"+keys(j);
    nominal.Duration=nominal.Duration+1; % Coast extension covers slightly faster fault paths.
    references{j}=run_integrated_maneuver(nominal,folder);
end
rows=cell(numel(cases),1);
for k=1:numel(cases)
    fprintf('Gate 3 diagnostics %d/%d: %s\n',k,numel(cases),cases(k).ID);
    out=run_integrated_maneuver(cases(k),folder);
    nominal=references{find(keys==cases(k).ReferenceKey,1)};
    [metrics,comparison]=evaluate_fault_result(out,nominal);
    caseFolder=fullfile(folder,cases(k).ID);
    writetable(struct2table(metrics),fullfile(caseFolder,'fault_metrics.csv'));
    writetable(comparison,fullfile(caseFolder,'comparison.csv'));
    plot_fault_comparison(out,nominal,comparison,caseFolder);
    rows{k}=struct2table(metrics);
end
results.faults=vertcat(rows{:});
writetable(results.faults,fullfile(folder,'fault_summary.csv'));
p=get_params(); [gitCode,commit]=system(sprintf('git -C "%s" rev-parse HEAD',root));
[dirtyCode,dirty]=system(sprintf('git -C "%s" status --porcelain',root));
metadata=struct('Status','PRELIMINARY_EVIDENCE_REVIEW_REQUIRED','Gate3Closed',false, ...
    'AllRequirementsPassed',false,'Protocol','G3-PREP-01','ScenarioCount',numel(cases), ...
    'StartedUTC',char(started),'MATLABVersion',version,'Release',version('-release'),'Products',ver, ...
    'Parameters',p,'GitCommit',strtrim(commit),'GitWorkingTreeStatus',dirty, ...
    'GitReadSucceeded',gitCode==0 && dirtyCode==0, ...
    'NumericalFailureCount',sum(~results.faults.NumericalChecksPass), ...
    'DBBSManeuverFailureCount',sum(results.faults.IsDBBS & ~results.faults.DBBSManeuverPass), ...
    'Pending','REQ-02 applicability/oracle; REQ-03 authority; sensor/path semantics; REQ-04 independence; supervisor review');
write_manifest(folder,metadata);
save(fullfile(folder,'gate3_results.mat'),'results','metadata','cases');
fprintf('Gate 3 remains open. Review fault_summary.csv and all failed diagnostics.\n');
end

function write_manifest(folder,metadata)
fid=fopen(fullfile(folder,'run_manifest.json'),'w','n','UTF-8');
assert(fid>=0,'Cannot create Gate 3 manifest.');
closeFile=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(metadata,'PrettyPrint',true));
end
