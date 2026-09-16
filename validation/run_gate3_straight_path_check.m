function summary = run_gate3_straight_path_check(folder)
% G3-BRK-ALIGN-01: zero yaw acceleration AND constant velocity direction.
% Lacet nul ET accélération alignée avec la vitesse, sans retoucher l'allocateur.
assert(~isfolder(folder),'Preserve earlier evidence.'); mkdir(folder);
p=get_params(); F=p.mu*p.m*p.g; M=F*max(hypot([p.lf p.lr],p.tw/2));
names=["nominal" "brake_fl_loss" "brake_fr_loss" "brake_rl_loss" "brake_rr_loss"];
rows=cell(5,1); witnesses=cell(5,1);
for k=1:5
    mask=fault_scenario_mask(names(k));
    lower=[-ones(4,1);-1;-1]; upper=[zeros(4,1);1;1]; lower(mask(1:4)==0)=0;
    initial=zeros(6,1); seeds=[initial]; %#ok<NBRAK>
    % Prior zero-Fy point is only a seed, NOT accepted as straight-path proof.
    old=nonlinear_authority_point([p.reference_speed;zeros(12,1)],mask,struct('Mode',"trim_brake"),p);
    if old.Feasible
        seeds(:,end+1)=[old.State(8:11)/F;old.State(7)/p.delta_max;atan2(old.State(2),old.State(1))/.15];
    end
    for beta=[-.12 -.04 .04 .12]
        seeds(:,end+1)=[-.1*mask(1:4);beta/p.delta_max;beta/.15]; %#ok<AGROW>
    end
    options=optimoptions('fmincon','Algorithm','sqp','Display','off', ...
        'MaxIterations',300,'MaxFunctionEvaluations',6000, ...
        'ConstraintTolerance',1e-9,'OptimalityTolerance',1e-9,'StepTolerance',1e-11);
    bestValue=0; best=zeros(6,1); bestFlag=0;
    for j=1:size(seeds,2)
        [z,v,flag]=fmincon(@objective,min(max(seeds(:,j),lower),upper), ...
            [],[],[],[],lower,upper,@constraints,options);
        [c,eq]=constraints(z); violation=max([0;c;abs(eq);lower-z;z-upper]);
        if all(isfinite(z)) && violation<=1e-7 && v<bestValue
            best=z; bestValue=v; bestFlag=flag;
        end
    end
    x=state(best); q=vehicle_dynamics_quantities(x,p,mask); beta=atan2(x(2),x(1));
    [c,eq]=constraints(best); violation=max([0;c;abs(eq);lower-best;best-upper]);
    witnesses{k}=struct('State',x,'Mask',mask,'Output',[q.Fx_total;q.Mz_total], ...
        'Fy_N',q.Fy_total,'Parameters',p,'GlobalMaximumProven',false);
    row=struct('Fault',names(k),'BodyDeceleration_mps2',-q.Fx_total/p.m, ...
        'TravelDeceleration_mps2',-(q.Fx_total*cos(beta)+q.Fy_total*sin(beta))/p.m, ...
        'BodyRatioLowerBound',-q.Fx_total/F,'AtLeast60PercentWitness',-q.Fx_total/F>=.60, ...
        'Sideslip_rad',beta,'Steering_rad',x(7),'Fx_N',q.Fx_total,'Fy_N',q.Fy_total, ...
        'Mz_Nm',q.Mz_total,'ForceAlignmentResidual_N',q.Fy_total*cos(beta)-q.Fx_total*sin(beta), ...
        'ConstraintViolation',violation,'ExitFlag',bestFlag,'GlobalMaximumProven',false, ...
        'BrakeFL_N',x(8),'BrakeFR_N',x(9),'BrakeRL_N',x(10),'BrakeRR_N',x(11));
    rows{k}=struct2table(row); disp(rows{k});
end
summary=vertcat(rows{:}); writetable(summary,fullfile(folder,'straight_path_braking.csv'));
save(fullfile(folder,'straight_path_results.mat'),'summary','witnesses');
copyfile([mfilename('fullpath') '.m'],fullfile(folder,'run_gate3_straight_path_check.m'));

    function x=state(z)
        x=zeros(13,1); x(1)=p.reference_speed; x(2)=x(1)*tan(.15*z(6));
        x(7)=p.delta_max*z(5); x(8:11)=F*z(1:4);
    end
    function v=objective(z)
        q0=vehicle_dynamics_quantities(state(z),p,mask); v=q0.Fx_total/F;
    end
    function [c,eq]=constraints(z)
        x0=state(z); q0=vehicle_dynamics_quantities(x0,p,mask); b=.15*z(6);
        c=[(1e-6-q0.Fz_raw)/(p.m*p.g);(-.999*p.mu*q0.Fz_raw-x0(8:11))/F;q0.Fx_total/F];
        eq=[(q0.Fy_total*cos(b)-q0.Fx_total*sin(b))/F;q0.Mz_total/M];
    end
end
