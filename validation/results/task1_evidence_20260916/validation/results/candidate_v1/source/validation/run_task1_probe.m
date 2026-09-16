function summary=run_task1_probe(folder,mode)
% Explicit controller-design experiments; not final acceptance evidence.
% Essais explicites de conception; ne constituent pas la validation finale.
assert(~isfolder(folder),'Preserve earlier experiments.'); mkdir(folder);
p=get_params(); summary=table(); opts=allocator_options();
if mode=="brake"
    catalog=gate2_maneuvers(); s=catalog(5); s.Kind="authority_screen";
    s.FaultScenario="brake_fl_loss"; s.FaultTime=.25; s.DetectionDelay=0;
    for reserve=[.98 .96 .94 .92 .90 .88]
        p.fault_rear_friction_fraction=reserve;
        s.ID="PROBE-FL-"+string(round(reserve*100));
        out=run_integrated_maneuver(s,[],[],opts,1,p);
        t=out.series; hold=t.Time_s>=1.5 & t.Time_s<=1.9;
        ratio=min(-(t.FxActual_N(hold)/p.m+t.Vy_mps(hold).*t.YawRate_radps(hold)))/(p.mu*p.g);
        row=table(reserve,ratio,out.metrics.PeakSideslip_rad,max(abs(t.MzActual_Nm(hold))), ...
            out.metrics.RateOverrideCount,out.metrics.RatePass,out.metrics.SolverPass, ...
            'VariableNames',{'RearFraction','BrakingRatio','PeakBeta','PeakHoldMz','Overrides','RatePass','SolverPass'});
        summary=[summary;row]; %#ok<AGROW>
        save(fullfile(folder,s.ID+'.mat'),'out');
        writetable(summary,fullfile(folder,'summary.csv')); disp(row);
    end
elseif mode=="dbbs"
    cases=gate3_fault_cases(); ids=string({cases.ID});
    for compensation=[false true]
        for tau=[.25 .15]
            p.dbbs_speed_compensation=compensation; p.yaw_tracking_tau=tau;
            for id=["G3-DBBS-T1-D10" "G3-DBBS-T3-D10"]
                s=cases(ids==id); n=s; n.FaultScenario="nominal"; n.Duration=7;
                nominal=run_integrated_maneuver(n,[],[],opts,1,p);
                out=run_integrated_maneuver(s,[],[],opts,1,p);
                [m,comparison]=evaluate_fault_result(out,nominal);
                row=table(id,compensation,tau,m.PeakPathDeviation_m,m.PostFaultYawRMSE_radps, ...
                    m.PeakDeceleration_g,m.NumericalChecksPass,m.DBBSManeuverPass, ...
                    'VariableNames',{'ID','SpeedCompensation','YawTau','PeakPath','YawRMSE','Decel_g','NumericalPass','DBBSPass'});
                summary=[summary;row]; %#ok<AGROW>
                save(fullfile(folder,id+'-C'+string(compensation)+'-T'+string(tau)+'.mat'),'out','nominal','comparison');
                writetable(summary,fullfile(folder,'summary.csv')); disp(row);
            end
        end
    end
else
    error('run_task1_probe:Mode','Choose brake or dbbs.');
end
end
