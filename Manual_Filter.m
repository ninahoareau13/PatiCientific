%% Manual Filter ???
% ...
% ... Start filtering ...
% ... Before running the lines below ... 
% ... 1. First plot the data to be filtered ...
% ... 2. Run coding part to initialize brush idex vector
% ... 3. In the figure push the "brush" bottom ...
% ... 4. Surline the data to be removed ...
% ... 5. Run the "for loop" to keep the index of bad data and change the associated flag
% ... 6. Start point 4 and 5 with the next points to be removed ...
% ...
% ... 1. First plot the data to be filtered ...
% ... ¡¡¡¡ Choose the data to be filtered !!!
%ii = find(CTDr.Flag==0);
toto = CTDr.Sal;
index_rm = false(size(1:length(toto)));
%index_rm(ii) = 1;

figure(10);clf;%set(gcf,'position',get(0, 'Screensize'),'color','w');
set(gca,'fontsize',16)
hLine = plot(CTDr.Time,toto,'b.','Markersize',10);
hold on
clear pp
pp = find(CTDr.FlagS==4);
plot(CTDr.Time(pp),toto(pp),'c.','Markersize',9)
pp = find(CTDr.FlagS==3);
plot(CTDr.Time(pp),toto(pp),'g.','Markersize',9)
ylim([32 40])
ax1 = gca;
set(ax1,'YColor','k','XColor','k','linewidth',1,'fontsize',16);
ylabel(ax1,'Salinity [psu]'); 
grid on; 
xlabel(ax1,'Time');

return
% ... 2. In the figure push the "brush" bottom ...
% ... 3. Surline the data to be removed ...

% ... 4. Run coding part to initialize brush idex vector ...
brushedIdx = logical(hLine.BrushData);  % logical array
brushedXData = hLine.XData(brushedIdx);
brushedYData = hLine.YData(brushedIdx);

% ... 5. Run the "for loop" to keep the index of bad data and change the associated flag ...
clear flag_tmp
for it=1:length(brushedYData)
    ind = find(CTDr.Time==brushedXData(it) & toto==brushedYData(it));
    flag_tmp(it) = ind;
end

index_rm(flag_tmp) = 1;   % index to be removed ..
CTDr.FlagS(index_rm) = 4;

% ... do it all the necessary time ...

% ... Once all bad data has been brush fix it in CTDr.Flag ...

return    

%% ... Figures ...
% ...

% ...
% ... Check Filtered data ...
% ...
figure(11);clf;
set(gcf,'position',get(0, 'Screensize'),'color','w');
set(gca,'FontWeight','Bold','FontSize',16)

% ... Plot all Temperature data ...
hLine = plot(CTDr.Time,toto,'color',[0 0.4470 0.7410],'Markersize',10,'Marker','.','LineStyle','none');
hold on

% ... Plot All bad data ...
pp = find(CTDr.FlagT>2);
plot(CTDr.Time(pp),toto(pp),'color',[0.5 0.5 0.5],'Markersize',10,'Marker','.','LineStyle','none')

% ... Only Bad temperature data
pp = find(CTDr.FlagT==4);
plot(CTDr.Time(pp),toto(pp),'r.','Markersize',10,'LineStyle','none');

% ... Figure tunning ...
grid on
legend('RAW','All bad data','Only bad Temp','Location','BestOutSide')
title(sprintf('%s%s','CastAway Temperature [C] - SPV - ',cdate));
ax1 = gca;
set(gcf,'position',[1250 708 1200 500],'color','w');set(gca,'fontsize',16)
set(ax1,'YColor','k','XColor','k','linewidth',1,'fontsize',16);
ylabel(ax1,'toto'); grid on; xlabel(ax1,'Time');

return
