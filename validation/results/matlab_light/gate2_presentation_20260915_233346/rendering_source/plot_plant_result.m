function plot_plant_result(series,scenario,scenarioDirectory)
% Re-export saved allocator-free plant samples without rerunning dynamics.
% Réexport de la plante seule sans nouvelle intégration numérique.
time=series.Time_s;
state=series{:,{'Vx_mps','Vy_mps','YawRate_radps','X_m','Y_m', ...
    'YawAngle_rad','SteeringActual_rad','FxFL_N','FxFR_N','FxRL_N','FxRR_N'}};
deltaCommand=series.SteeringCommand_rad;
normalLoads=series{:,{'FzFL_N','FzFR_N','FzRL_N','FzRR_N'}};
alpha=series{:,{'AlphaFront_rad','AlphaRear_rad'}};
lateralForce=series{:,{'FyFront_N','FyRear_N'}};
lateralCapacity=series{:,{'FyFrontCapacity_N','FyRearCapacity_N'}};
for language=["en","fr"]
if language=="en"
    figureName=scenario.Name; timeLabel='Time [s]'; commandLabels={'Command','Actual'};
    axleLabels={'Front','Rear'};
else
    figureName=scenario.NameFR; timeLabel='Temps [s]'; commandLabels={'Consigne','Mesure simulée'};
    axleLabels={'Avant','Arrière'};
end
figure('Visible','off','Color','white','Position',[50 50 1100 850]);
tiledlayout(3,1);
nexttile; plot(time,state(:,1),'LineWidth',1.2); ylabel('v_x [m/s]'); grid on;
title(figureName);
nexttile; plot(time,state(:,3),'LineWidth',1.2); ylabel('r [rad/s]'); grid on;
nexttile; plot(state(:,4),state(:,5),'LineWidth',1.2); ...
    xlabel('X [m]'); ylabel('Y [m]'); axis equal; grid on;
style_report_figure(gcf);
exportgraphics(gcf,fullfile(scenarioDirectory,'vehicle_response_'+language+'.png'),'Resolution',180,'BackgroundColor','white');
close(gcf);

figure('Visible','off','Color','white','Position',[50 50 1100 850]);
tiledlayout(3,1);
nexttile; plot(time,rad2deg([deltaCommand,state(:,7)]),'LineWidth',1.2); ...
    ylabel('\delta [deg]'); legend(commandLabels,'Location','best'); grid on;
nexttile; plot(time,state(:,8:11),'LineWidth',1.1); ylabel('F_x [N]'); ...
    legend('FL','FR','RL','RR','Location','best'); grid on;
nexttile; plot(time,normalLoads,'LineWidth',1.1); ylabel('F_z [N]'); ...
    xlabel(timeLabel); legend('FL','FR','RL','RR','Location','best'); grid on;
style_report_figure(gcf);
exportgraphics(gcf,fullfile(scenarioDirectory,'actuators_and_loads_'+language+'.png'),'Resolution',180,'BackgroundColor','white');
close(gcf);

figure('Visible','off','Color','white','Position',[50 50 1100 850]);
tiledlayout(2,1);
nexttile; plot(time,lateralForce,'LineWidth',1.2); hold on; ...
    plot(time,lateralCapacity,'--','LineWidth',1.0); ...
    plot(time,-lateralCapacity,'--','LineWidth',1.0); ...
    ylabel('F_y [N]'); grid on;
nexttile; plot(time,rad2deg(alpha),'LineWidth',1.2); ...
    ylabel('\alpha [deg]'); xlabel(timeLabel); ...
    legend(axleLabels,'Location','best'); grid on;
style_report_figure(gcf);
exportgraphics(gcf,fullfile(scenarioDirectory,'tire_response_'+language+'.png'),'Resolution',180,'BackgroundColor','white');
close(gcf);
end

end

