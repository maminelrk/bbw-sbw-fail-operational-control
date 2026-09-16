function style_report_figure(fig)
%STYLE_REPORT_FIGURE Explicit print-safe styling, independent of MATLAB theme.
% Mise en forme lisible sur fond blanc, indépendante du thème MATLAB.
set(fig,'Color','white','InvertHardcopy','off');
palette=[0.00 0.32 0.55; 0.80 0.25 0.05; 0.00 0.48 0.37; ...
    0.53 0.29 0.65; 0.65 0.43 0.00; 0.30 0.30 0.30];
axesList=findall(fig,'Type','axes');
for ax=reshape(axesList,1,[])
    set(ax,'Color','white','XColor',[.12 .12 .12],'YColor',[.12 .12 .12], ...
        'ZColor',[.12 .12 .12],'GridColor',[.55 .55 .55], ...
        'GridAlpha',.25,'FontName','Arial','FontSize',11,'ColorOrder',palette);
    lines=flipud(findobj(ax,'Type','line'));
    for k=1:numel(lines)
        set(lines(k),'Color',palette(mod(k-1,size(palette,1))+1,:),'LineWidth',1.3);
    end
end
set(findall(fig,'Type','text'),'Color',[.10 .10 .10],'FontName','Arial');
% Layout titles are not always returned as ordinary text under R2026a themes.
% Les titres de mise en page peuvent échapper au filtre de type texte.
for owner=reshape(findall(fig,'-property','Title'),1,[])
    heading=get(owner,'Title');
    if isscalar(heading) && isgraphics(heading) && isprop(heading,'Color')
        set(heading,'Color',[.10 .10 .10]);
    end
end
set(findall(fig,'Type','legend'),'Color','white','TextColor',[.10 .10 .10], ...
    'EdgeColor',[.70 .70 .70],'FontName','Arial','FontSize',10);
end
