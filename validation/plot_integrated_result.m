function plot_integrated_result(result,folder)
% Same data in French and English for direct insertion in the internship report.
s=result.series;
for language=["en" "fr"]
    if language=="en"
        name=result.scenario.NameEN; legends={'Reference','Actual'};
        timeLabel='Time [s]'; angleLabel='Road-wheel angle [deg]'; rateLabel='Rack rate [deg/s]';
    else
        name=result.scenario.NameFR; legends={'Consigne','Mesure simulée'};
        timeLabel='Temps [s]'; angleLabel='Angle de roue [deg]'; rateLabel='Vitesse crémaillère [deg/s]';
    end
    f=figure('Visible','off','Color','white','Position',[50 50 1100 850]);
    layout=tiledlayout(3,2,'TileSpacing','compact'); title(layout,result.scenario.ID+" - "+name);
    nexttile; plot(s.Time_s,[s.FxDemand_N s.FxActual_N],'LineWidth',1.1); ylabel('F_x [N]'); legend(legends); grid on;
    nexttile; plot(s.Time_s,[s.YawReference_radps s.YawRate_radps],'LineWidth',1.1); ylabel('r [rad/s]'); legend(legends); grid on;
    nexttile; plot(s.Time_s,s.Vx_mps,'LineWidth',1.1); ylabel('v_x [m/s]'); grid on;
    nexttile; plot(s.Time_s,[s.MzDemand_Nm s.MzActual_Nm],'LineWidth',1.1); ylabel('M_z [N m]'); legend(legends); grid on;
    nexttile; plot(s.X_m,s.Y_m,'LineWidth',1.1); xlabel('X [m]'); ylabel('Y [m]'); axis equal; grid on;
    nexttile; plot(s.Time_s,rad2deg([s.CmdDelta_rad s.Delta_rad]),'LineWidth',1.1); ylabel(angleLabel); xlabel(timeLabel); legend(legends); grid on;
    exportgraphics(f,fullfile(folder,'response_'+language+'.png'),'Resolution',180); close(f);
    f=figure('Visible','off','Color','white','Position',[50 50 1100 850]);
    tiledlayout(3,1,'TileSpacing','compact');
    nexttile; plot(s.Time_s,s{:,{'CmdFL_N','CmdFR_N','CmdRL_N','CmdRR_N'}},'LineWidth',1.1); ylabel('F_x [N]'); legend('FL','FR','RL','RR'); grid on;
    nexttile; plot(s.Time_s,s{:,{'FzFL_N','FzFR_N','FzRL_N','FzRR_N'}},'LineWidth',1.1); ylabel('F_z [N]'); grid on;
    nexttile; plot(s.Time_s,rad2deg(s{:,{'ContributionA_radps','ContributionB_radps','RackRate_radps'}}),'LineWidth',1.1); ylabel(rateLabel); xlabel(timeLabel); legend('A','B','A+B'); grid on;
    exportgraphics(f,fullfile(folder,'actuators_'+language+'.png'),'Resolution',180); close(f);
end
end
