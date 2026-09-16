function plot_fault_comparison(result,nominal,comparison,folder)
s=result.series; n=nominal.series(1:height(s),:); c=comparison;
for language=["en" "fr"]
    if language=="en"
        labels={'Nominal','Faulted'}; timeLabel='Time [s]';
        pathLabel='Equal-distance lateral deviation [m]'; speedLabel='Speed [m/s]';
        note='Preliminary fault evidence - not gate acceptance';
    else
        labels={'Nominal','Dégradé'}; timeLabel='Temps [s]';
        pathLabel='Écart latéral à distance égale [m]'; speedLabel='Vitesse [m/s]';
        note='Preuves préliminaires - sans acceptation du jalon';
    end
    f=figure('Visible','off','Color','white','Position',[50 50 1150 850]);
    layout=tiledlayout(3,2,'TileSpacing','compact');
    title(layout,result.scenario.ID+" - "+note);
    nexttile; plot(c.Time_s,[c.NominalYaw_radps c.FaultedYaw_radps]); ylabel('r [rad/s]'); legend(labels); grid on;
    nexttile; plot(c.Time_s,c.CrossTrack_m); yline(.5,'--'); yline(-.5,'--'); ylabel(pathLabel); grid on;
    nexttile; plot(c.Time_s,[n.Vx_mps s.Vx_mps]); ylabel(speedLabel); grid on;
    nexttile; plot(c.Time_s,c.Deceleration_g); yline(.35,'--'); ylabel('a_{brake}/g'); grid on;
    nexttile; plot(c.Time_s,c.OracleNormalizedError); yline(.1,'--'); ylabel('e_{oracle}'); xlabel(timeLabel); grid on;
    nexttile; plot(n.X_m,n.Y_m,s.X_m,s.Y_m); xlabel('X [m]'); ylabel('Y [m]'); legend(labels); axis equal; grid on;
    exportgraphics(f,fullfile(folder,'fault_comparison_'+language+'.png'),'Resolution',180); close(f);
end
end
