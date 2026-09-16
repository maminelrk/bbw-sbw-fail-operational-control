function summary=run_steering_bench(folder)
% Common-rack bench: both drives, A loss, B loss, and complete drive loss.
p=get_params(); dt=p.validation_dt; t=(0:dt:3)';
names=["nominal","steering_a_loss","steering_b_loss","steering_loss"];
rows=cell(4,1);
for j=1:4
    mask=fault_scenario_mask(names(j)); state=zeros(3,1);
    if j==4, state(1)=deg2rad(10); end
    history=zeros(numel(t),6);
    for k=1:numel(t)
        target=p.delta_max; if t(k)>=1.5, target=-p.delta_max; end
        [rate,~,d]=steering_actuator_dynamics(state(1),state(2:3),target,mask,p);
        history(k,:)=[state' rate d.contributions'];
        if k<numel(t)
            f=@(z) steering_rhs(z,target,mask,p);
            a=f(state); b=f(state+dt*a/2); c=f(state+dt*b/2); e=f(state+dt*c);
            state=state+dt*(a+2*b+2*c+e)/6;
            state(1)=min(max(state(1),-p.delta_max),p.delta_max);
        end
    end
    span=max(history(:,1))-min(history(:,1));
    rangeRatio=span/(2*p.delta_max); rateRatio=max(abs(history(:,4)))/p.delta_rate;
    contributionPass=all(abs(history(:,5:6))<=p.steering_channel_rate'+1e-9,'all');
    if j==4
        passed=max(abs(history(:,1)-deg2rad(10)))<1e-12 && max(abs(history(:,4)))<1e-12;
    else
        % The first-order velocity loop approaches its limit asymptotically.
        passed=rangeRatio>=0.60 && rateRatio>=0.60-0.001 && rateRatio<=1+1e-6 && contributionPass;
    end
    rows{j}={names(j),rangeRatio,rateRatio,contributionPass,passed};
    series=array2table([t history],'VariableNames',{'Time_s','Delta_rad', ...
        'MotorA_radps','MotorB_radps','RackRate_radps','ContributionA_radps','ContributionB_radps'});
    writetable(series,fullfile(folder,names(j)+".csv"));
    plot_steering_result(series,names(j),folder);
end
summary=cell2table(vertcat(rows{:}),'VariableNames', ...
    {'Fault','AngleRangeRatio','PeakRateRatio','ChannelBoundsPass','OverallPass'});
writetable(summary,fullfile(folder,'steering_summary.csv'));
end
function dz=steering_rhs(z,target,mask,p)
[rate,derivative]=steering_actuator_dynamics(z(1),z(2:3),target,mask,p);
dz=[rate;derivative];
end
