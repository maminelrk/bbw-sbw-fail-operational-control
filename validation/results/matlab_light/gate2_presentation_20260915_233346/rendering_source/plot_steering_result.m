function plot_steering_result(series,name,folder)
% Re-export saved steering samples; no dynamics or acceptance recomputation.
% Réexport des échantillons sauvegardés, sans nouvelle simulation.
for language=["en","fr"]
    f=figure('Visible','off','Color','white','Position',[50 50 1100 700]);
    tiledlayout(2,1,'TileSpacing','compact');
    nexttile; plot(series.Time_s,rad2deg(series.Delta_rad));
    ylabel('\delta [deg]'); title(name,'Interpreter','none'); grid on;
    nexttile; plot(series.Time_s,rad2deg(series{:, ...
        {'RackRate_radps','ContributionA_radps','ContributionB_radps'}}));
    ylabel('d\delta/dt [deg/s]'); legend('A+B','A','B'); grid on;
    if language=="fr", xlabel('Temps [s]'); else, xlabel('Time [s]'); end
    style_report_figure(f);
    exportgraphics(f,fullfile(folder,name+"_"+language+".png"), ...
        'Resolution',180,'BackgroundColor','white'); close(f);
end
end
