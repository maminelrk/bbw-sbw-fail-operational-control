function assessment = run_gate3_authority_assessment(baseline,folder)
% Bounded G3-AUTH-01 assessment, with separate steady/frozen/dynamic claims.
% Étude bornée : distinguer équilibre, état figé et réponse dynamique.
assert(~isfolder(folder),'Preserve existing authority evidence.'); mkdir(folder);
p=get_params(); x=zeros(13,1); x(1)=p.reference_speed;
F=p.mu*p.m*p.g; Mupper=F*max(hypot([p.lf p.lr],p.tw/2));
names=["nominal" "brake_fl_loss" "brake_fr_loss" "brake_rl_loss" "brake_rr_loss"];
assessment=struct('Protocol','G3-AUTH-01','Parameters',p,'ForceUpperBound_N',F, ...
    'YawUpperBound_Nm',Mupper,'BaselineFolder',baseline, ...
    'Gate3Closed',false,'GlobalOptimalityProven',false);
rows=cell(5,1); trimPoints=cell(5,1);
for k=1:5
    fprintf('Straight-braking nonlinear trim %d/5: %s\n',k,names(k));
    a=nonlinear_authority_point(x,fault_scenario_mask(names(k)),struct('Mode',"trim_brake"),p);
    assert(a.Feasible,'No feasible straight-braking trim found.'); trimPoints{k}=a;
    row=struct('Fault',names(k),'FeasibleDeceleration_mps2',-a.Output(1)/p.m, ...
        'RatioLowerBoundToNominalUpper',-a.Output(1)/F, ...
        'AtLeast60PercentWitness',-a.Output(1)/F>=.60, ...
        'ResidualYaw_Nm',a.Output(2),'ResidualLateralForce_N',a.Fy_N, ...
        'Sideslip_rad',atan2(a.State(2),a.State(1)),'Steering_rad',a.State(7), ...
        'ConstraintViolation',a.Violation,'ExitFlag',a.ExitFlag,'GlobalMaximumProven',false);
    rows{k}=struct2table(row); disp(rows{k});
end
assessment.trim=vertcat(rows{:}); assessment.trimPoints=trimPoints;
writetable(assessment.trim,fullfile(folder,'braking_trim.csv'));
yawRows=cell(6,1); yawPoints=cell(6,1); index=0;
for condition=1:3
    mask=ones(6,1); cap=Inf; label="nominal";
    if condition>=2, mask(5:6)=0; label="DBBS_centered"; end
    if condition==3, cap=.35; label="DBBS_centered_035g"; end
    for direction=[-1 1]
        index=index+1; fprintf('Yaw authority %s sign %+d\n',label,direction);
        a=nonlinear_authority_point(x,mask,struct('Mode',"yaw",'Sign',direction,'DecelCap_g',cap),p);
        assert(a.Feasible,'No feasible yaw witness found.'); yawPoints{index}=a;
        row=struct('Condition',label,'Sign',direction,'FeasibleYaw_Nm',direction*a.Output(2), ...
            'RatioLowerBoundToNominalUpper',direction*a.Output(2)/Mupper, ...
            'AtLeast15PercentWitness',direction*a.Output(2)/Mupper>=.15, ...
            'Deceleration_g',-a.Output(1)/(p.m*p.g),'ConstraintViolation',a.Violation, ...
            'ExitFlag',a.ExitFlag,'GlobalMaximumProven',false);
        yawRows{index}=struct2table(row); disp(yawRows{index});
    end
end
assessment.yaw=vertcat(yawRows{:}); assessment.yawPoints=yawPoints;
writetable(assessment.yaw,fullfile(folder,'yaw_authority.csv'));
save(fullfile(folder,'authority_results.mat'),'assessment');

% Current-controller high-demand tests: these do not maximize physical capacity.
catalog=gate2_maneuvers(); base=catalog(5); base.Kind="authority_screen";
dynamic=cell(5,1); nominalYawLower=min(assessment.yaw.FeasibleYaw_Nm(1:2));
for k=1:5
    s=base; s.ID="G3-AUTH-BRK-"+names(k); s.FaultScenario=names(k);
    s.FaultTime=.25; s.DetectionDelay=0;
    fprintf('Dynamic braking allocation %d/5: %s\n',k,names(k));
    result=run_integrated_maneuver(s,[],p.validation_dt);
    target=fullfile(folder,s.ID); mkdir(target);
    save(fullfile(target,'result.mat'),'result'); writetable(result.series,fullfile(target,'timeseries.csv'));
    plot_integrated_result(result,target);
    t=result.series; hold=t.Time_s>=1.5 & t.Time_s<=1.9;
    a=-(t.FxActual_N/p.m+t.Vy_mps.*t.YawRate_radps);
    m=result.metrics;
    numerical=m.FinitePass && m.LoadPass && m.FrictionPass && m.RatePass && ...
        m.BoundsPass && m.SolverPass && m.OperatingPass && m.RateOverrideCount==0;
    row=struct('Fault',names(k),'MeanDeceleration_mps2',mean(a(hold)), ...
        'MinimumHoldDeceleration_mps2',min(a(hold)), ...
        'RatioLowerBoundToNominalUpper',min(a(hold))/(p.mu*p.g), ...
        'PeakHoldYawMoment_Nm',max(abs(t.MzActual_Nm(hold))), ...
        'YawMomentLimit_Nm',.05*nominalYawLower, ...
        'PeakHoldYawRate_radps',max(abs(t.YawRate_radps(hold))), ...
        'NumericalChecksPass',numerical,'Demonstrated60PercentAndYawBound', ...
        numerical && min(a(hold))/(p.mu*p.g)>=.60 && max(abs(t.MzActual_Nm(hold)))<=.05*nominalYawLower, ...
        'MaximumCapabilityProven',false);
    dynamic{k}=struct2table(row); disp(dynamic{k});
    writetable(vertcat(dynamic{1:k}),fullfile(folder,'braking_dynamic.csv'));
end
assessment.dynamic=vertcat(dynamic{:});
save(fullfile(folder,'authority_results.mat'),'assessment');
end
