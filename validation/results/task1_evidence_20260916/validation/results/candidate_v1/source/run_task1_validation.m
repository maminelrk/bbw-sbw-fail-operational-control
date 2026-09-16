function results=run_task1_validation(folder)
% TASK1-CTRL-01: fixed acceptance criteria, complete prior-case regressions.
% Critères inchangés, non-régression; ne ferme pas automatiquement Gate 3.
root=fileparts(mfilename('fullpath')); oldPath=path;
cleanup=onCleanup(@() path(oldPath)); %#ok<NASGU>
addpath(root,fullfile(root,'validation'));
if nargin<1
    folder=fullfile(root,'validation','results',['task1_' char(datetime('now','Format','yyyyMMdd_HHmmss'))]);
end
assert(~isfolder(folder),'Preserve earlier evidence; choose a new output folder.'); mkdir(folder);
p=get_params(); results=struct(); started=char(datetime('now','TimeZone','UTC'));
manifest=struct('Protocol','TASK1-CTRL-01','StartedUTC',started,'Status','RUNNING', ...
    'MATLABVersion',version,'Parameters',p,'Gate3Closed',false,'Task1Passed',false);
write_json(fullfile(folder,'manifest.json'),manifest);
% Archive exact executed sources, including uncommitted changes.
source=fullfile(folder,'source'); mkdir(source);
copyfile(fullfile(root,'*.m'),source);
mkdir(fullfile(source,'validation')); copyfile(fullfile(root,'validation','*.m'),fullfile(source,'validation'));
copyfile(fullfile(root,'tests'),fullfile(source,'tests'));
units=runtests(fullfile(root,'tests'),'IncludeSubfolders',true);
results.units=table(string({units.Name})',[units.Passed]',[units.Incomplete]', ...
    'VariableNames',{'Name','Passed','Incomplete'});
writetable(results.units,fullfile(folder,'unit_tests.csv'));
assert(all(results.units.Passed & ~results.units.Incomplete),'Task 1 unit regression failed.');

catalog=gate2_maneuvers(); rows=cell(5,1);
for k=1:5
    fprintf('Task 1 nominal regression %d/5\n',k);
    out=run_integrated_maneuver(catalog(k),fullfile(folder,'nominal'));
    rows{k}=struct2table(out.metrics);
end
results.nominal=vertcat(rows{:}); writetable(results.nominal,fullfile(folder,'nominal_summary.csv'));

cases=gate3_fault_cases(); keys=unique(string({cases.ReferenceKey}),'stable');
references=cell(numel(keys),1);
for j=1:numel(keys)
    n=cases(find(string({cases.ReferenceKey})==keys(j),1));
    n.FaultScenario="nominal"; n.ID="NOM-"+keys(j); n.Duration=n.Duration+1;
    references{j}=run_integrated_maneuver(n,fullfile(folder,'faults'));
end
rows=cell(numel(cases),1);
for k=1:numel(cases)
    fprintf('Task 1 fault regression %d/%d: %s\n',k,numel(cases),cases(k).ID);
    out=run_integrated_maneuver(cases(k),fullfile(folder,'faults'));
    nominal=references{find(keys==cases(k).ReferenceKey,1)};
    [metrics,comparison]=evaluate_fault_result(out,nominal);
    target=fullfile(folder,'faults',cases(k).ID);
    writetable(comparison,fullfile(target,'comparison.csv'));
    writetable(struct2table(metrics),fullfile(target,'fault_metrics.csv'));
    plot_fault_comparison(out,nominal,comparison,target);
    rows{k}=struct2table(metrics);
    writetable(vertcat(rows{1:k}),fullfile(folder,'fault_summary.csv'));
end
results.faults=vertcat(rows{:});

% Unchanged dynamic authority denominator: mu*g is a nominal upper bound.
% Yaw tolerance uses a feasible nominal yaw witness (conservative denominator).
x=zeros(13,1); x(1)=p.reference_speed; yawWitness=cell(2,1);
for k=1:2
    direction=2*k-3;
    yawWitness{k}=nonlinear_authority_point(x,ones(6,1),struct('Mode',"yaw",'Sign',direction),p);
    assert(yawWitness{k}.Feasible,'Nominal yaw witness required.');
end
yawLimit=.05*min(abs([yawWitness{1}.Output(2) yawWitness{2}.Output(2)]));
save(fullfile(folder,'yaw_tolerance_witness.mat'),'yawWitness','yawLimit');
names=["nominal" "brake_fl_loss" "brake_fr_loss" "brake_rl_loss" "brake_rr_loss"];
rows=cell(5,1);
for k=1:5
    s=catalog(5); s.Kind="authority_screen"; s.ID="AUTH-"+names(k);
    s.FaultScenario=names(k); s.FaultTime=.25; s.DetectionDelay=0;
    fprintf('Task 1 dynamic braking %d/5\n',k);
    out=run_integrated_maneuver(s,fullfile(folder,'authority'));
    rows{k}=braking_row(out,yawLimit);
    writetable(vertcat(rows{1:k}),fullfile(folder,'braking_summary.csv'));
end
results.braking=vertcat(rows{:});

% Extra front-loss transition cases: reserve engages during heavy braking.
rows={}; index=0;
for name=names(2:3)
    for delay=[0 .01 .05]
        index=index+1; s=catalog(5); s.Kind="authority_screen";
        s.ID="TRANS-"+name+"-D"+string(round(delay*1000));
        s.FaultScenario=name; s.FaultTime=1.5; s.DetectionDelay=delay;
        fprintf('Task 1 loaded fault transition %d/6\n',index);
        out=run_integrated_maneuver(s,fullfile(folder,'transitions'));
        row=braking_row(out,yawLimit); rows{index}=row; %#ok<AGROW>
        writetable(vertcat(rows{:}),fullfile(folder,'transition_summary.csv'));
    end
end
results.transitions=vertcat(rows{:});

% Refine both sampling and integration for all originally failing families.
rows={}; index=0;
for id=["G3-DBBS-T1-D10" "G3-DBBS-NEG-T1-D10"]
    s=cases(string({cases.ID})==id); n=s; n.FaultScenario="nominal"; n.Duration=7;
    nominal=run_integrated_maneuver(n,[],.001);
    out=run_integrated_maneuver(s,fullfile(folder,'refined'),.001);
    [m,c]=evaluate_fault_result(out,nominal);
    writetable(c,fullfile(folder,'refined',id,'comparison.csv'));
    index=index+1; rows{index}=table(id,m.PeakPathDeviation_m,m.PostFaultYawRMSE_radps, ...
        m.PeakDeceleration_g,out.metrics.PeakSideslip_rad,NaN, ...
        m.NumericalChecksPass && m.DBBSManeuverPass,'VariableNames', ...
        {'ID','Path_m','YawRMSE_radps','Decel_g','PeakBeta_rad','BrakingRatio','Pass'}); %#ok<AGROW>
end
for name=names(2:3)
    s=catalog(5); s.Kind="authority_screen"; s.ID="AUTH-"+name;
    s.FaultScenario=name; s.FaultTime=.25; s.DetectionDelay=0;
    out=run_integrated_maneuver(s,fullfile(folder,'refined'),.001);
    b=braking_row(out,yawLimit); index=index+1;
    rows{index}=table(s.ID,NaN,NaN,NaN,b.PeakBeta_rad,b.BrakingRatio,b.Pass, ...
        'VariableNames',{'ID','Path_m','YawRMSE_radps','Decel_g','PeakBeta_rad','BrakingRatio','Pass'}); %#ok<AGROW>
end
results.refined=vertcat(rows{:}); writetable(results.refined,fullfile(folder,'refined_summary.csv'));
manifest.Status='COMPLETED';
manifest.Task1Passed=all(results.nominal.OverallPass) && ...
    all(results.faults.NumericalChecksPass & results.faults.MaskPass & ...
    results.faults.RecoveryDiagnosticPass & results.faults.ContinuityDiagnosticPass) && ...
    all(results.faults.DBBSManeuverPass(results.faults.IsDBBS)) && ...
    all(results.braking.Pass) && all(results.refined.Pass) && all(results.transitions.NumericalPass);
manifest.CompletedUTC=char(datetime('now','TimeZone','UTC'));
manifest.Pending='Task 2: independent REQ-02/envelope, comparative baseline, robustness; no certification claim.';
write_json(fullfile(folder,'manifest.json'),manifest);
save(fullfile(folder,'task1_results.mat'),'results','manifest');
disp(manifest); fprintf('TASK1_VALIDATION_COMPLETE\n');
end

function row=braking_row(out,yawLimit)
t=out.series; p=out.p; m=out.metrics; hold=t.Time_s>=1.5 & t.Time_s<=1.9;
a=-(t.FxActual_N/p.m+t.Vy_mps.*t.YawRate_radps);
ratio=min(a(hold))/(p.mu*p.g); yaw=max(abs(t.MzActual_Nm(hold)));
numerical=m.FinitePass && m.LoadPass && m.FrictionPass && m.RatePass && ...
    m.BoundsPass && m.SolverPass && m.OperatingPass && m.RateOverrideCount==0;
row=table(out.scenario.ID,ratio,m.PeakSideslip_rad,yaw,yawLimit,m.RateOverrideCount, ...
    numerical,numerical && ratio>=.60 && yaw<=yawLimit, ...
    'VariableNames',{'ID','BrakingRatio','PeakBeta_rad','PeakHoldMz_Nm','YawLimit_Nm','Overrides','NumericalPass','Pass'});
end

function write_json(file,value)
fid=fopen(file,'w','n','UTF-8'); assert(fid>=0); cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end
