function summary = run_gate3_convergence(baseline,folder)
% Separate RK4 integration refinement from controller-period refinement.
% Sépare le raffinement RK4 de celui de la période de commande.
assert(~isfolder(folder),'Preserve existing convergence evidence.'); mkdir(folder);
ids=["G3-DBBS-T1-D10" "G3-DBBS-NEG-T1-D10"];
keys=["dbbs_positive" "dbbs_negative"];
rows=cell(4,1); index=0;
for mode=1:2
    if mode==1, dt=.002; substeps=2; label="RK1_CTRL2";
    else, dt=.001; substeps=1; label="RK1_CTRL1"; end
    for direction=1:2
        fprintf('Convergence %s %s: nominal then fault\n',label,ids(direction));
        original=load(fullfile(baseline,ids(direction),'result.mat'));
        reference=load(fullfile(baseline,"G3-NOM-"+keys(direction),'result.mat'));
        nominal=run_integrated_maneuver(reference.result.scenario,[],dt,[],substeps);
        result=run_integrated_maneuver(original.result.scenario,[],dt,[],substeps);
        [metrics,comparison]=evaluate_fault_result(result,nominal);
        [coarse,~]=evaluate_fault_result(original.result,reference.result);
        target=fullfile(folder,label,ids(direction)); mkdir(target);
        writetable(result.series,fullfile(target,'timeseries.csv'));
        writetable(nominal.series,fullfile(target,'nominal_timeseries.csv'));
        writetable(comparison,fullfile(target,'comparison.csv'));
        writetable(struct2table(metrics),fullfile(target,'fault_metrics.csv'));
        save(fullfile(target,'result.mat'),'result','nominal','metrics');
        plot_fault_comparison(result,nominal,comparison,target);
        t=original.result.series.Time_s;
        yawDiff=max(abs(interp1(result.series.Time_s,result.series.YawRate_radps,t)-original.result.series.YawRate_radps));
        speedDiff=max(abs(interp1(result.series.Time_s,result.series.Vx_mps,t)-original.result.series.Vx_mps));
        pathDiff=abs(metrics.PeakPathDeviation_m-coarse.PeakPathDeviation_m);
        row=struct('Mode',label,'ScenarioID',ids(direction),'ControllerPeriod_s',dt, ...
            'IntegrationStep_s',dt/substeps,'BaselinePeakPath_m',coarse.PeakPathDeviation_m, ...
            'RefinedPeakPath_m',metrics.PeakPathDeviation_m,'PeakPathDifference_m',pathDiff, ...
            'MaxYawDifference_radps',yawDiff,'MaxSpeedDifference_mps',speedDiff, ...
            'NumericalChecksPass',metrics.NumericalChecksPass, ...
            'DBBSManeuverPass',metrics.DBBSManeuverPass, ...
            'RefinementScreenPass',pathDiff<=.001 && yawDiff<=.001 && speedDiff<=.03, ...
            'Gate3Closed',false);
        index=index+1; rows{index}=struct2table(row);
        disp(rows{index});
        writetable(vertcat(rows{1:index}),fullfile(folder,'convergence_summary.csv'));
    end
end
summary=vertcat(rows{:});
save(fullfile(folder,'convergence_results.mat'),'summary');
end
