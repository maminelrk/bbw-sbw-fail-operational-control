function summary=run_allocator_solver_diagnostic()
% Controlled solver-only comparison; never relaxes maneuver criteria.
root=fileparts(fileparts(mfilename('fullpath')));
folder=fullfile(root,'validation','results','solver_diagnostic_v6');
assert(~isfolder(folder),'Diagnostic folder already exists; preserve it before rerunning.');
mkdir(folder); p=get_params(); cases=gate2_maneuvers();
tolerances=[1e-9 1e-10 1e-12 1e-14]; rows=cell(numel(tolerances),1);
for k=1:numel(tolerances)
    opts=allocator_options(); opts.OptimalityTolerance=tolerances(k);
    out=run_integrated_maneuver(cases(5),[],p.validation_dt,opts);
    row=out.metrics; row.OptimalityTolerance=tolerances(k);
    row.PeakYaw_radps=max(abs(out.series.YawRate_radps));
    row.ReleaseForce_N=max(abs(out.series.FxActual_N(out.series.Time_s>=3.2)));
    row.PeakSteering_rad=max(abs(out.series.Delta_rad));
    row.SolverFailureCount=sum(out.series.SolverExitFlag<=0);
    rows{k}=struct2table(row);
    save(fullfile(folder,sprintf('case_%d.mat',k)),'out','row');
end
summary=vertcat(rows{:}); writetable(summary,fullfile(folder,'summary.csv'));
disp(summary(:,{'OptimalityTolerance','PeakYaw_radps','ReleaseForce_N', ...
    'SaturatedBrakeRatio','SolverFailureCount','OverallPass'}));
end
