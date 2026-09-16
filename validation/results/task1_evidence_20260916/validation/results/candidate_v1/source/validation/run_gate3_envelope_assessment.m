function assessment = run_gate3_envelope_assessment(baseline,folder)
% G3-ENV-01: nonlinear sampled demand-box witnesses and 50 ms rollouts.
% Témoins non linéaires échantillonnés ; ni enveloppe continue ni preuve globale.
assert(~isfolder(folder),'Preserve existing envelope evidence.'); mkdir(folder);
p=get_params(); F=p.mu*p.m*p.g; M=F*max(hypot([p.lf p.lr],p.tw/2));
source=readtable(fullfile(baseline,'fault_summary.csv'),'TextType','string');
rows={}; points={}; rollouts={}; index=0;
for k=1:height(source)
    id=source.ScenarioID(k); saved=load(fullfile(baseline,id,'result.mat'));
    result=saved.result; s=result.scenario; t=result.series;
    times=[s.FaultTime+s.DetectionDelay+.05,max(3,s.FaultTime+s.DetectionDelay+.15)];
    for instant=1:2
        [~,at]=min(abs(t.Time_s-times(instant)));
        state=table2array(t(at,2:14))';
        mask=table2array(t(at,{'Physical_FL','Physical_FR','Physical_RL','Physical_RR','Physical_SA','Physical_SB'}))';
        previous=table2array(t(max(1,at-1),{'CmdFL_N','CmdFR_N','CmdRL_N','CmdRR_N','CmdDelta_rad'}))';
        demand=[t.FxDemand_N(at);t.MzDemand_Nm(at)];
        % A 15% reserve of boundary magnitude means outward scaling 1/0.85.
        % Corners only: a nonlinear feasible image need not contain their hull.
        offset=(.15/.85)*abs(demand);
        targets=[demand,demand+offset.*[-1;-1],demand+offset.*[-1;1], ...
            demand+offset.*[1;-1],demand+offset.*[1;1]];
        for probe=1:5
            target=targets(:,probe);
            a=nonlinear_authority_point(state,mask, ...
                struct('Mode',"match",'Target',target,'Starts',8),p);
            outer=abs(target(1))>F || abs(target(2))>M;
            matched=a.Feasible && a.Residual<=1e-3;
            status="NO_WITNESS_NOT_PROOF_OF_INFEASIBILITY";
            if matched, status="FROZEN_STATE_WITNESS"; end
            if outer, status="OUTSIDE_CONSERVATIVE_PHYSICAL_BOUND"; end
            rollout=[]; error50=NaN; valid=false;
            if matched
                rollout=authority_rollout(state,previous,a,mask,target,p);
                error50=rollout.EndpointNormalizedError;
                valid=rollout.PhysicalAndCommandChecksPass;
            end
            index=index+1; points{index,1}=a; rollouts{index,1}=rollout; %#ok<AGROW>
            row=struct('ScenarioID',id,'SampleIndex',instant,'Time_s',t.Time_s(at), ...
                'Probe',probe,'DemandFx_N',demand(1),'DemandMz_Nm',demand(2), ...
                'TargetFx_N',target(1),'TargetMz_Nm',target(2), ...
                'AchievedFx_N',a.Output(1),'AchievedMz_Nm',a.Output(2), ...
                'NormalizedResidual',a.Residual,'ConstraintViolation',a.Violation, ...
                'FrozenStateWitness',matched,'Status',status, ...
                'RolloutPhysicalPass',valid,'EndpointError50ms',error50, ...
                'EndpointWithin10Percent',valid && error50<=.10, ...
                'FullEnvelopeProven',false,'REQ02Certified',false);
            rows{index,1}=struct2table(row); %#ok<AGROW>
        end
        fprintf('Envelope %s sample %d: %d/5 frozen witnesses\n',id,instant, ...
            sum(cellfun(@(r) r.FrozenStateWitness,rows(end-4:end))));
        writetable(vertcat(rows{:}),fullfile(folder,'envelope_probes.csv'));
    end
end
assessment=struct('Protocol','G3-ENV-01','Parameters',p,'Rows',vertcat(rows{:}), ...
    'Points',{points},'Rollouts',{rollouts},'Gate3Closed',false, ...
    'BaselineFolder',baseline,'FullEnvelopeProven',false);
save(fullfile(folder,'envelope_results.mat'),'assessment');
end
