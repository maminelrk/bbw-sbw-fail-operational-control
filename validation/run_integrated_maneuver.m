function result = run_integrated_maneuver(scenario,outputRoot,dt,opts)
% Sampled allocation -> independent actuator channels -> nonlinear vehicle.
% Actual outputs ALWAYS come from vehicle_dynamics_quantities, not B*u.
p=get_params(); if nargin<3, dt=p.validation_dt; end
time=(0:dt:scenario.Duration)'; count=numel(time);
x=zeros(count,13); x(1,1)=scenario.InitialSpeed;
% Optional explicit initial condition for numerical-robustness regressions.
% Its longitudinal speed must agree with the scenario, and it is saved with it.
if isfield(scenario,'InitialState')
    initial=scenario.InitialState(:);
    assert(numel(initial)==13 && all(isfinite(initial)) && ...
        abs(initial(1)-scenario.InitialSpeed)<1e-12, ...
        'run_integrated_maneuver:InitialState','Expected 13 finite states with the scenario initial speed.');
    x(1,:)=initial';
end
command=zeros(count,5); demand=zeros(count,2); actual=zeros(count,2);
prediction=zeros(count,2); reference=zeros(count,3); forces=zeros(count,4);
loads=zeros(count,4); lateral=zeros(count,4); solver=zeros(count,1);
bounds=true(count,1); override=false(count,1); rackRate=zeros(count,1);
motorContribution=zeros(count,2); lower=zeros(count,5); upper=zeros(count,5);
if nargin<4 || isempty(opts), opts=allocator_options(); end
previous=zeros(5,1); physicalHistory=ones(count,6); knownHistory=ones(count,6);
isFault=isfield(scenario,'FaultScenario') && scenario.FaultScenario~="nominal";
oracle=NaN(count,2); oracleScale=NaN(count,2); oracleFlag=NaN(count,1);
for k=1:count
    state=x(k,:)'; ref=maneuver_reference(time(k),scenario,p);
    [mask,known]=fault_event_masks(time(k),scenario);
    physicalHistory(k,:)=mask'; knownHistory(k,:)=known';
    reference(k,:)=[ref.ax ref.yaw ref.yaw_dot];
    % Fx demand gives requested body longitudinal acceleration; Mz combines
    % analytical yaw acceleration feedforward with yaw-rate feedback.
    demand(k,:)=[p.m*(ref.ax-state(2)*state(3)), ...
        p.Iz*(ref.yaw_dot+(ref.yaw-state(3))/p.yaw_tracking_tau)];
    [u,flag,info]=allocator(demand(k,:)',state(7),opts,known,previous,dt,state);
    if isFault
        % Oracle uses the true fault on the SAME frozen state and previous
        % command. Its affine prediction is a diagnostic, never plant truth.
        [~,oracleFlag(k),best]=allocator(demand(k,:)',state(7),opts,mask,previous,dt,state);
        oracle(k,:)=best.achieved'; oracleScale(k,:)=best.output_scale';
    end
    q=vehicle_dynamics_quantities(state,p,mask);
    [rackRate(k),~,sd]=steering_actuator_dynamics(state(7),state(12:13),u(5),mask,p,known);
    motorContribution(k,:)=sd.contributions'; command(k,:)=u';
    actual(k,:)=[q.Fx_total q.Mz_total]; prediction(k,:)=info.achieved';
    loads(k,:)=q.Fz_raw'; lateral(k,:)=q.Fy_wheels'; forces(k,:)=q.Fx_actual';
    lower(k,:)=info.physical_lower_bounds'; upper(k,:)=info.physical_upper_bounds';
    bounds(k)=all(u>=lower(k,:)'-1e-6 & u<=upper(k,:)'+1e-6);
    override(k)=info.rate_override; solver(k)=flag; previous=u;
    if k<count, x(k+1,:)=plant_step(state,u,mask,dt,p,known)'; end
end
rates=[zeros(1,5);diff(command)/dt];
beta=atan2(x(:,2),x(:,1));
forceError=actual(:,1)-demand(:,1); yawError=x(:,3)-reference(:,2);
forceRMSE=sqrt(mean(forceError.^2)); yawRMSE=sqrt(mean(yawError.^2));
finitePass=all(isfinite([x actual command]),'all');
loadPass=min(loads,[],'all')>0;
frictionPass=all(forces.^2+lateral.^2 <= (p.mu*max(loads,0)).^2+1e-3,'all');
availableRate=min(p.delta_rate,physicalHistory(:,5:6)*p.steering_channel_rate);
ratePass=all(abs(rates(:,1:4))<=p.Fx_rate+1e-3 | physicalHistory(:,1:4)==0,'all') && ...
    all(abs(rates(:,5))<=availableRate+1e-8 | availableRate==0) && all(abs(rackRate)<=availableRate+1e-8) && ...
    all(abs(motorContribution)<=p.steering_channel_rate'+1e-8,'all');
operatingPass=min(x(:,1))>p.vx_floor && max(abs(beta))<=0.15;
capacityRatio=NaN;
if scenario.Kind=="capacity"
    hold=time>=1.5 & time<=1.9;
    capacityRatio=mean(-actual(hold,1))/(p.mu*p.m*p.g);
    recovered=abs(actual(time>=3.2,1));
    behaviorPass=capacityRatio>=0.95 && all(actual(:,1)<=1e-6) && ...
        max(recovered)<100 && max(abs(x(:,3)))<1e-4;
else
    behaviorPass=forceRMSE<=scenario.ForceRMSELimit && yawRMSE<=scenario.YawRMSELimit;
end
overall=finitePass && loadPass && frictionPass && ratePass && operatingPass && ...
    all(bounds) && all(solver>0) && ~any(override) && behaviorPass;
metrics=struct('ScenarioID',scenario.ID,'ForceRMSE_N',forceRMSE, ...
    'YawRMSE_radps',yawRMSE,'PeakSideslip_rad',max(abs(beta)), ...
    'MinimumWheelLoad_N',min(loads,[],'all'),'FinalSpeed_mps',x(end,1), ...
    'SaturatedBrakeRatio',capacityRatio,'FinitePass',finitePass, ...
    'LoadPass',loadPass,'FrictionPass',frictionPass,'RatePass',ratePass, ...
    'BoundsPass',all(bounds),'SolverPass',all(solver>0),'OperatingPass',operatingPass, ...
    'RateOverrideCount',sum(override),'BehaviorPass',behaviorPass,'OverallPass',overall);
series=array2table([time x reference demand actual prediction command forces loads lateral ...
    rackRate motorContribution solver double(override)],'VariableNames', ...
    {'Time_s','Vx_mps','Vy_mps','YawRate_radps','X_m','Y_m','Psi_rad','Delta_rad', ...
    'BrakeStateFL_N','BrakeStateFR_N','BrakeStateRL_N','BrakeStateRR_N', ...
    'MotorRateA_radps','MotorRateB_radps','AxReference_mps2','YawReference_radps', ...
    'YawAccelerationReference_radps2','FxDemand_N','MzDemand_Nm','FxActual_N','MzActual_Nm', ...
    'FxQPPrediction_N','MzQPPrediction_Nm','CmdFL_N','CmdFR_N','CmdRL_N','CmdRR_N', ...
    'CmdDelta_rad','FxFL_N','FxFR_N','FxRL_N','FxRR_N','FzFL_N','FzFR_N','FzRL_N','FzRR_N', ...
    'FyFL_N','FyFR_N','FyRL_N','FyRR_N','RackRate_radps','ContributionA_radps', ...
    'ContributionB_radps','SolverExitFlag','RateOverride'});
channels={'FL','FR','RL','RR','SA','SB'};
for j=1:6
    series.(['Physical_' channels{j}])=physicalHistory(:,j);
    series.(['Known_' channels{j}])=knownHistory(:,j);
end
series.OracleFx_N=oracle(:,1); series.OracleMz_Nm=oracle(:,2);
series.OracleScaleFx_N=oracleScale(:,1); series.OracleScaleMz_Nm=oracleScale(:,2);
series.OracleExitFlag=oracleFlag;
result=struct('scenario',scenario,'series',series,'metrics',metrics,'p',p,'dt',dt,'solver_options',opts);
if nargin>=2 && ~isempty(outputRoot)
    folder=fullfile(outputRoot,scenario.ID); if ~isfolder(folder), mkdir(folder); end
    writetable(series,fullfile(folder,'timeseries.csv'));
    writetable(struct2table(metrics),fullfile(folder,'metrics.csv'));
    save(fullfile(folder,'result.mat'),'result');
    plot_integrated_result(result,folder);
end
end
