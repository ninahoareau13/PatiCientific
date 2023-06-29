%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ... Data Processing of CTD tram file ...
% .........................................
% ... Nina Hoareau, March 2022 ...
% .........................................

clear all
close all

addpath('/home/nina/Escritorio/WORK/Programs/matlab_prog/');

% ... Give the Date of the file to be processed (format: YYYYMMDD) ...
cdate = '20230627'


%% ... Open data file ...
% ...
ifile = sprintf('%s%s%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/SPV/SeaWater/Surface/CastAwayCTD/RAW/collocated_surface_sections/SPV_',cdate,'_collocated_raw.dat')
if ~exist(ifile,'file')
   disp('CTD file does not exist')
   ifile
   return
end

[msg,head,data,ini]= read_sbe(ifile);
[msg,ini,str] = read_par(ifile);

%% ... Get data ...
% Assign variables to each data column
%tt = data(:,1);   % sec from Cast time info (UTC)
dd = abs(data(:,1));
mm = abs(data(:,2));
yy = abs(data(:,3));
hh = abs(data(:,4));
min = abs(data(:,5));
ss = abs(data(:,6));

T = datenum(yy,mm,dd,hh,min,ss);
Time = datetime(T,'convertfrom','datenum');

Lon = data(:,7);    % East
Lat = data(:,8);    % North
Speed = data(:,9);  % Kts
%Speed2 = data(:,10); % Kts
Pres = data(:,11);   % dBar
Temp = data(:,12);  % deg C
Cond = data(:,13)./1000;   % uS/cm -> mS/cm
FlagT = T * zeros;
FlagC = T * zeros;
FlagS = T * zeros;
FlagP = T * zeros;

% ... Calcul Salinity value from C,T,P (using conduc2sali.m funcion)
% ... TEOS-10
[Sal]= conduc2sali(Cond,Temp,Pres);

% ... Create CTD structure of RAW data...
CTDr = timetable(Time,T,Pres,Lon,Lat,Speed,FlagP,Temp,FlagT,Cond,FlagC,Sal,FlagS);

% 
% %% ... Check Raw data ...
% % ...

% ...
% ... Check Salinity conversion from Temp & Cond & Pressure ...
% ...
figure(1);
set(gcf,'Position', get(0, 'Screensize'),'color','w');
% ... Temperature
plot(CTDr.Time,CTDr.Temp,'color',[0 0.4470 0.7410],'Markersize',10,'Marker','.','LineStyle','none');
%xlabel('Temperature [ \circC ]')
hold on
% ... Conductivity
plot(CTDr.Time,CTDr.Cond,'color',[1 0.4 0.4],'Markersize',10,'Marker','.','LineStyle','none');
%xlabel('Conductivity [ mS/cm ]')
% ... Salinity 
plot(CTDr.Time,CTDr.Sal,'color',[0.4660 0.6740 0.1880],'Markersize',10,'Marker','.','LineStyle','none');
% ... Pressure
plot(CTDr.Time,-CTDr.Pres,'color',[0.4 0.4 1],'Markersize',10,'Marker','.','LineStyle','none');
% ... Speed
plot(CTDr.Time,CTDr.Speed,'color',[0.5 0.5 0.5],'Markersize',8,'Marker','.','LineStyle','none');

grid on
legend('Temperature [C]','Conductivity [mS/cm]','Salinity [PSU]','Pressure [dBar]','Speed [kts]','Location','bestoutside')
title(sprintf('%s%s','CastAway CTD data - SPV - ',cdate));
set(gca,'FontWeight','Bold','FontSize',18)


% ......................................................
% ... A. Plot Campain information ...
% ... Define SPV stations ...
% ... ['TD1'; 'TD2' ;'TD3' ;'TD4'; 'TD5'; 'TD6'];
% ...
SPV_Lon = [41.3856; 41.3798; 41.3749; 41.3806; 41.3785; 41.3757];
SPV_Lat = [2.2099; 2.1986; 2.1951; 2.2029; 2.2084; 2.2162];

% ...
% ... A. Compare Time/Pressure/Speed/Temp/Cond/Salinity depending on the vessel position  ...
% ...
figure(2);
set(gcf,'position',get(0, 'Screensize'),'color','w');
ax = gca;
set(ax,'YColor','k','XColor','k','linewidth',1,'fontsize',16);

% 1. Time
ax1 = subplot(2,3,1);
scatter(CTDr.Lat,CTDr.Lon,[],CTDr.T,'filled')
ylim([41.37 41.39])
ylabel('Latitude [ \circN ]')
xlim([2.19 2.22])
xlabel('Longitude [ \circE ]')
colorbar
set(colorbar,'YTickLabel',{'Start' '' '' '' '' '' 'End'})
colormap (ax1,flipud(gray))
grid on
% ... Add SPV stations ...
hold on
scatter(SPV_Lat,SPV_Lon,200,'filled','p','k')
% ... Title 
title(sprintf('%s%s','Time [Sec] - ',cdate));
set(gca,'fontsize',14,'FontWeight','normal')


% 2. Speed
ax2 = subplot(2,3,2);
scatter(CTDr.Lat,CTDr.Lon,[],CTDr.Speed,'filled')
ylim([41.37 41.39])
ylabel('Latitude [ \circN ]')
xlim([2.19 2.22])
xlabel('Longitude [ \circE ]')
colorbar
caxis([0 3]);
colormap(ax2,flipud(gray))
grid on
% ... Add SPV stations ...
hold on
scatter(SPV_Lat,SPV_Lon,200,'filled','p','k')
% ... Title 
title(sprintf('%s%s','Speed - ',cdate));
set(gca,'fontsize',14,'FontWeight','normal')


% 3. Pressure
ax3 = subplot(2,3,3)
scatter(CTDr.Lat,CTDr.Lon,[],CTDr.Pres,'filled')
ylim([41.37 41.39])
ylabel('Latitude [ \circN ]')
xlim([2.19 2.22])
xlabel('Longitude [ \circE ]')
colorbar
caxis([0 0.6]);
colormap (ax3,parula)
grid on
% ... Add SPV stations ...
hold on
scatter(SPV_Lat,SPV_Lon,200,'filled','p','k')
% ... Title 
title(sprintf('%s%s','Pressure - ',cdate));
set(gca,'fontsize',14,'FontWeight','normal')


% 4. Temperature 
ax4 = subplot(2,3,4)
scatter(CTDr.Lat,CTDr.Lon,[],CTDr.Temp,'filled')
ylim([41.37 41.39])
ylabel('Latitude [ \circN ]')
xlim([2.19 2.22])
xlabel('Longitude [ \circE ]')
colorbar
caxis([20 30])
colormap(ax4,jet)
grid on
% ... Add SPV stations ...
hold on
scatter(SPV_Lat,SPV_Lon,200,'filled','p','k')
% ... Title 
title('Temperature (raw)');
set(gca,'fontsize',14,'FontWeight','normal')


% 5. Conductivity
ax5 = subplot(2,3,5)
scatter(CTDr.Lat,CTDr.Lon,[],CTDr.Cond,'filled')
ylim([41.37 41.39])
ylabel('Latitude [ \circN ]')
xlim([2.19 2.22])
xlabel('Longitude [ \circE ]')
colorbar
caxis([50 60])
colormap(ax5,jet)
grid on
% ... Add SPV stations ...
hold on
scatter(SPV_Lat,SPV_Lon,200,'filled','p','k')
% ... Title 
title('Conductivity (raw)');
set(gca,'fontsize',14,'FontWeight','normal')

% 6. Salinity
ax6 = subplot(2,3,6)
scatter(CTDr.Lat,CTDr.Lon,[],CTDr.Sal,'filled')
ylim([41.37 41.39])
ylabel('Latitude [ \circN ]')
xlim([2.19 2.22])
xlabel('Longitude [ \circE ]')
colorbar
caxis([37.5 39])
colormap(ax6,jet)
grid on
% ... Add SPV stations ...
hold on
scatter(SPV_Lat,SPV_Lon,200,'filled','p','k')
% ... Title 
title('Salinity (raw)');
set(gca,'fontsize',14,'FontWeight','normal')

% .............................................................
% ...
% ... B. Temp & Salinity time serie ...
% ...
figure(3);
set(gcf,'Position', get(0, 'Screensize'),'color','w');
yyaxis left % ... Temperature on Left
plot(CTDr.Time,CTDr.Temp,'color',[0 0.4470 0.7410],'Markersize',10,'Marker','.','LineStyle','none');
ylabel('Temperature [ \circC ]')
hold on
yyaxis right % ... Salinity on Right
plot(CTDr.Time,CTDr.Sal,'color',[0.4660 0.6740 0.1880],'Markersize',10,'Marker','.','LineStyle','none');
ylabel('Salinityty [ psu ]')
grid on
% ... Control color of yaxis ...
ax = gca;
ax.YAxis(1).Color = [0 0.4470 0.7410];
ax.YAxis(2).Color = [0.4660 0.6740 0.1880];
legend('Temperature [C]','Salinity [psu]','Location','bestoutside')
title(sprintf('%s%s','CastAway CT data - SPV - ',cdate));
set(gca,'FontWeight','Bold','FontSize',18)

% % ...
% % ... C. Pressure & Depth time serie ...
% % ...
% figure;
% set(gcf,'Position', get(0, 'Screensize'),'color','w');
% plot(CTDr.Time,CTDr.Pres,'color',[0.4 0.4 1],'Markersize',10,'Marker','.','LineStyle','none');
% ylabel('Pressure [ dBar ]')
% grid on
% set(gca,'Ylabel','Reverse');
% % ... Control color of yaxis ...
% title(sprintf('%s%s',' SPV cruise - ',cdate));
% set(gca,'FontWeight','Bold','FontSize',18)
% return


%% ... Start Quality Control for the data ...
% ...
% ... Quality Flag values comes from SeaDataNet information
% ... Flag = 0 -> No check
% ... Flag = 1 -> Good data
% ... Flag = 2 -> Probably good data
% ... Flag = 3 -> Suspect data
% ... Flag = 4 -> Bad Temperature or Conductivity or Salinity data
% ... Flag = 9 -> Missing data
% ...

% ...
% ... 1. When missing data put Flag=9...
% ...
indNan = isnan(CTDr.Temp); CTDr.FlagT(indNan) = 9; clear indNan
indNan = isnan(CTDr.Cond); CTDr.FlagC(indNan) = 9; clear indNan
indNan = isnan(CTDr.Sal); CTDr.FlagS(indNan) = 9;

% ...
% ... 2. Flag as BAD data (Flag=4) first & last 30 sec of each data transect
% ... Find the index of each transect (from Temperature data)
% ... Because need 30sec for sensor stabilizacion
% ... And 30 sec to shut down the CTD 
% ...
indtrans = find(CTDr.FlagT~=9);
indtrans1 = circshift(indtrans,-1);
inddiff = indtrans1 - indtrans;

pp = find(abs(inddiff)>1);
ncast = size(pp)

m = 1;
castI = zeros(ncast); 
castI(1) = indtrans(1);
castE(ncast) = indtrans(end);
for i = 1:length(indtrans)-1
    if(abs(inddiff(i))>1)
        castE(m) = indtrans(i);
        m = m+1;
        castI(m) = indtrans(i+1);
    end
end



for i = 1:ncast
    ii = castI(i);
    fi = castE(i);
    CTDr.FlagT(ii:ii+30) = 4;  % 30 sec at the biginning
    CTDr.FlagC(ii:ii+30) = 4;
    CTDr.FlagS(ii:ii+30) = 4;

    CTDr.FlagT(fi-30:fi) = 4;  % 30 sec at the end
    CTDr.FlagC(fi-30:fi) = 4;
    CTDr.FlagS(fi-30:fi) = 4;
end



% ...
% ... 3. Check geophysical values ...
% ... if no geophysical values, Flag = 4

% ... Check Temperature to be in geophysical values (10 < Temp < 30)
% ...
pp = CTDr.Temp > 30 | CTDr.Temp < 10; % & CTDr.FlagT~=9;
CTDr.FlagT(pp) = 4;

% ... Check Conductivity to be in Sea water values (20 < Cond < 60)
% ...
clear pp
pp = CTDr.Cond > 60 | CTDr.Cond < 20; % & CTDr.FlagC~=9;
CTDr.FlagC(pp) = 4; 

% ... Check Salinity to be in Sea water values (32 < Cond < 40)
% ...
clear pp
pp = CTDr.Sal > 40 | CTDr.Sal < 32; % & CTDr.FlagS~=9;
CTDr.FlagS(pp) = 4; 

% ... Check Pressure for surface data (0.02 < Pres < 1.5)
% ...
clear pp
pp = CTDr.Pres <= 0.02;
CTDr.FlagC(pp) = 3;  % Flag for position instrument -> BAD Conductivity -> Salinity
CTDr.FlagS(pp) = 3;

% ...
% ... 4. Quality Control in function of Pati Vela Speed ...
% ... Speed data from eStela file 
% ... FlagP -> Flag Position
% ... 2 cases: - Speed higher than 5 kts (create emulsion in CTD inducing bad conductivity data)
% ...          - Speed smaller than 0.5 kts (SPV drift during CTD profil measurement or SPV tack)
% clear pp
% pp = CTDr.Speed > 5; %& CTDr.FlagP~=9;
% CTDr.FlagC(pp) = 3; 
% CTDr.FlagS(pp) = 3;

clear pp
pp = CTDr.Speed < 0.3 & CTDr.Pres > 4; %& CTDr.FlagP~=9;
CTDr.FlagC(pp) = 3;
CTDr.FlagS(pp) = 3;


%% ... Figures: Checking the Quality Control process 
% ...
ppT = find(CTDr.FlagT>=3);   % ... Only BAD data due to BAD position (pressure or Speed)
ppS = find(CTDr.FlagS>=3);
ppP = find(CTDr.FlagS==3);

% ... I. Time serie Figures
% ...
% ... All parameters: Temp, Pres, Speed, Cond, Sal
figure;
set(gcf,'Position', get(0, 'Screensize'),'color','w');
% ... Temperature
plot(CTDr.Time,CTDr.Temp,'color',[0 0.4470 0.7410],'Markersize',10,'Marker','.','LineStyle','none');
hold on
plot(CTDr.Time(ppT),CTDr.Temp(ppT),'r.');
% ... Conductivity
% plot(CTDr.Time,CTDr.Cond,'color',[1 0.4 0.4],'Markersize',10,'Marker','.','LineStyle','none');
% ... Salinity 
plot(CTDr.Time,CTDr.Sal,'color',[0.4660 0.6740 0.1880],'Markersize',10,'Marker','.','LineStyle','none');
plot(CTDr.Time(ppS),CTDr.Sal(ppS),'r.')
% ... Pressure
plot(CTDr.Time,-CTDr.Pres,'color',[0.4 0.4 1],'Markersize',10,'Marker','.','LineStyle','none');
plot(CTDr.Time(ppP),-CTDr.Pres(ppP),'r.');
% ... Speed
plot(CTDr.Time,CTDr.Speed,'color',[0.5 0.5 0.5],'Markersize',8,'Marker','.','LineStyle','none');
plot(CTDr.Time(ppP),CTDr.Speed(ppP),'r.');
grid on
legend('Temperature [C]','Bad Temp','Salinity [PSU]','Bad Sal','Pressure [dBar]','Bad Pres','Speed [m/s]','Bad Velocity','Location','bestoutside')
title(sprintf('%s%s','CastAway CTD data - SPV - ',cdate));
set(gca,'FontWeight','Bold','FontSize',18)

% ... Only Temp and Salinity
figure;
set(gcf,'Position', get(0, 'Screensize'),'color','w');
yyaxis left % ... Temperature on Left
plot(CTDr.Time,CTDr.Temp,'color',[0 0.4470 0.7410],'Markersize',10,'Marker','.','LineStyle','none');
hold on
plot(CTDr.Time(ppT),CTDr.Temp(ppT),'color','r','Markersize',8,'Marker','.','LineStyle','none');
ylabel('Temperature [ \circC ]')
yyaxis right % ... Salinity on Right
plot(CTDr.Time,CTDr.Sal,'color',[0.4660 0.6740 0.1880],'Markersize',10,'Marker','.','LineStyle','none');
plot(CTDr.Time(ppS),CTDr.Sal(ppS),'color','r','Markersize',8,'Marker','.','LineStyle','none');
ylabel('Salinityty [ psu ]')
grid on
% ... Control color of yaxis ...
ax = gca;
ax.YAxis(1).Color = [0 0.4470 0.7410];
ax.YAxis(2).Color = [0.4660 0.6740 0.1880];
title(sprintf('%s%s','CastAway CTD data - SPV - ',cdate));
set(gca,'FontWeight','Bold','FontSize',18)

% ... II. Trajectory figure
% ...
% ... Define SPV stations ...
% ... ['TD1'; 'TD2' ;'TD3' ;'TD4'; 'TD5'; 'TD6'];
% ...
SPV_Lon = [41.3856; 41.3798; 41.3749; 41.3806; 41.3785; 41.3757];
SPV_Lat = [2.2099; 2.1986; 2.1951; 2.2029; 2.2084; 2.2162];

figure;
set(gcf,'position',get(0, 'Screensize'),'color','w');
ax = gca;
set(ax,'YColor','k','XColor','k','linewidth',1,'fontsize',16);

% 1. Time
ax1 = subplot(2,3,1);
scatter(CTDr.Lat,CTDr.Lon,[],CTDr.T,'filled')
ylim([41.37 41.39])
ylabel('Latitude [ \circN ]')
xlim([2.19 2.22])
xlabel('Longitude [ \circE ]')
colorbar
set(colorbar,'YTickLabel',{'Start' '' '' '' '' '' 'End'})
colormap (ax1,flipud(gray))
grid on
hold on
scatter(SPV_Lat,SPV_Lon,200,'filled','p','k') % ... Add SPV stations ...
title(sprintf('%s%s','Time [Sec] - ',cdate));
set(gca,'fontsize',14,'FontWeight','normal')

% 2. Speed
ax2 = subplot(2,3,2);
scatter(CTDr.Lat,CTDr.Lon,[],CTDr.Speed,'filled')
ylim([41.37 41.39])
ylabel('Latitude [ \circN ]')
xlim([2.19 2.22])
xlabel('Longitude [ \circE ]')
colorbar
caxis([0 5]);
colormap(ax2,flipud(gray))
grid on
hold on
scatter(SPV_Lat,SPV_Lon,200,'filled','p','k') % ... Add SPV stations ...
title(sprintf('%s%s','Speed - ',cdate));
set(gca,'fontsize',14,'FontWeight','normal')

% 3. Pressure
ax3 = subplot(2,3,3);
scatter(CTDr.Lat,CTDr.Lon,[],CTDr.Pres,'filled')
hold on
scatter(CTDr.Lat(pp),CTDr.Lon(pp),[],CTDr.Pres(pp),'r.')
ylim([41.37 41.39])
ylabel('Latitude [ \circN ]')
xlim([2.19 2.22])
xlabel('Longitude [ \circE ]')
colorbar
caxis([0 2]);
colormap (ax3,parula)
grid on
hold on
scatter(SPV_Lat,SPV_Lon,200,'filled','p','k') % ... Add SPV stations ...
title(sprintf('%s%s','Pressure - ',cdate));
set(gca,'fontsize',14,'FontWeight','normal')

% 4. Temperature 
ax4 = subplot(2,3,4);
scatter(CTDr.Lat,CTDr.Lon,[],CTDr.Temp,'filled')
hold on
scatter(CTDr.Lat(pp),CTDr.Lon(pp),[],CTDr.Temp(pp),'r.')
ylim([41.37 41.39])
ylabel('Latitude [ \circN ]')
xlim([2.19 2.22])
xlabel('Longitude [ \circE ]')
colorbar
caxis([12.5 14])
colormap(ax4,jet)
grid on
hold on
scatter(SPV_Lat,SPV_Lon,200,'filled','p','k') % ... Add SPV stations ...
title('Temperature (raw)');
set(gca,'fontsize',14,'FontWeight','normal')

% 5. Conductivity
ax5 = subplot(2,3,5);
scatter(CTDr.Lat,CTDr.Lon,[],CTDr.Cond,'filled')
hold on
scatter(CTDr.Lat(pp),CTDr.Lon(pp),[],CTDr.Cond(pp),'r.')
ylim([41.37 41.39])
ylabel('Latitude [ \circN ]')
xlim([2.19 2.22])
xlabel('Longitude [ \circE ]')
colorbar
caxis([40 50])
colormap(ax5,jet)
grid on
hold on
scatter(SPV_Lat,SPV_Lon,200,'filled','p','k') % ... Add SPV stations ...
title('Conductivity (raw)');
set(gca,'fontsize',14,'FontWeight','normal')

% 6. Salinity
ax6 = subplot(2,3,6);
scatter(CTDr.Lat,CTDr.Lon,[],CTDr.Sal,'filled')
hold on
scatter(CTDr.Lat(pp),CTDr.Lon(pp),[],CTDr.Sal(pp),'r.')
ylim([41.37 41.39])
ylabel('Latitude [ \circN ]')
xlim([2.19 2.22])
xlabel('Longitude [ \circE ]')
colorbar
caxis([37 39])
colormap(ax6,jet)
grid on
hold on
scatter(SPV_Lat,SPV_Lon,200,'filled','p','k')
title('Salinity (raw)');
set(gca,'fontsize',14,'FontWeight','normal')


%% ... Average mean every 10 sec
% ...
clear pp
pp = CTDr.FlagT==0; CTDr.FlagT(pp) = 1;
pp = CTDr.FlagC==0; CTDr.FlagC(pp) = 1;
pp = CTDr.FlagS==0; CTDr.FlagS(pp) = 1;
pp = CTDr.FlagP==0; CTDr.FlagP(pp) = 1;

TT = CTDr;
pp = find(CTDr.FlagT>=2); % get only Good or Probably good 
TT.Temp(pp) = NaN;
TT.FlagT(pp) = NaN;
pp = find(CTDr.FlagC>=2); % get only Good or Probably good 
TT.Cond(pp) = NaN;
TT.FlagC(pp) = NaN;
pp = find(CTDr.FlagS>=2); % get only Good or Probably good 
TT.Sal(pp) = NaN;
TT.FlagS(pp) = NaN;
pp = find(CTDr.FlagP>=2); % get only Good or Probably good 
TT.Pres(pp) = NaN;
TT.Speed(pp) = NaN;
TT.FlagP(pp) = NaN;

% ...
% RETIME funcion only in Matlab 2019 -> CTDm = retime(TT,'minutely','mean');
% ... If version older, FOR loop ...
% ...

%clear T Pres Lon Lat Speed Temp Cond Flag

% ... Define time to be averaged in seconds
msec = 10;

n = round(length(TT.T)/msec)

TT2.Time = nan(n,1);
TT2.T = nan(n,1);
TT2.Pres = nan(n,1);
TT2.Lon = nan(n,1);
TT2.Lat = nan(n,1);
TT2.Speed = nan(n,1);
TT2.FlagP = nan(n,1);
TT2.Temp = nan(n,1);
TT2.FlagT = nan(n,1);
TT2.Cond = nan(n,1);
TT2.FlagC = nan(n,1);
TT2.Sal = nan(n,1);
TT2.FlagS = nan(n,1);

m = 1;
for i = 1:msec:length(TT.T)
    ii = length(TT.T) - i;
    if (ii<msec)   % ... Last tram of data contain less than msec number
        disp('Last tram')
        nn = length(TT{i:length(TT.T),1});
        sum1 = sum(TT{i:length(TT.T),:});
        % ... T,Pres,Lon,Lat,Speed,FlagP,Temp,FlagT,Cond,FlagC,Sal,FlagS
        TT2.T(m) = sum1(1)/nn;
        TT2.Pres(m) = sum1(2)/nn;
        TT2.Lon(m) = sum1(3)/nn;
        TT2.Lat(m) = sum1(4)/nn;
        TT2.Speed(m) = sum1(5)/nn;
        TT2.FlagP(m) = sum1(6)/nn;
        TT2.Temp(m) = sum1(7)/nn;
        TT2.FlagT(m) = sum1(8)/nn;
        TT2.Cond(m) = sum1(9)/nn;
        TT2.FlagC(m) = sum1(10)/nn;
        TT2.Sal(m) = sum1(11)/nn;
        TT2.FlagS(m) = sum1(12)/nn;
        
        m = m+1;
    else
        %sum1 = nansum(TT{i:(i+msec-1),:})
        sum1 = sum(TT{i:(i+msec-1),:});
        TT2.T(m) = sum1(1)/msec;
        TT2.Pres(m) = sum1(2)/msec;
        TT2.Lon(m) = sum1(3)/msec;
        TT2.Lat(m) = sum1(4)/msec;
        TT2.Speed(m) = sum1(5)/msec;
        TT2.FlagP(m) = sum1(6)/msec;
        TT2.Temp(m) = sum1(7)/msec;
        TT2.FlagT(m) = sum1(8)/msec;
        TT2.Cond(m) = sum1(9)/msec;
        TT2.FlagC(m) = sum1(10)/msec;
        TT2.Sal(m) = sum1(11)/msec;
        TT2.FlagS(m) = sum1(12)/msec;
        m = m+1;
    end
end

TT2.Time = datetime(TT2.T,'convertfrom','datenum');
pp = isnan(TT2.FlagT);TT2.FlagT(pp) = 9;
pp = isnan(TT2.FlagC);TT2.FlagC(pp) = 9;
pp = isnan(TT2.FlagS);TT2.FlagS(pp) = 9;
pp = isnan(TT2.FlagP);TT2.FlagP(pp) = 9;

CTD = table2timetable(struct2table(TT2));

% ... Time serie
figure;
set(gcf,'Position', get(0, 'Screensize'),'color','w');
plot(CTDr.Time,CTDr.Temp,'color',[0 0.4470 0.7410],'Markersize',10,'Marker','.','LineStyle','none');
hold on
plot(CTD.Time,CTD.Temp,'r.');
plot(CTDr.Time,CTDr.Sal,'color',[0.4660 0.6740 0.1880],'Markersize',10,'Marker','.','LineStyle','none');
plot(CTD.Time,CTD.Sal,'r.');
plot(CTDr.Time,-CTDr.Pres,'color',[0.4 0.4 1],'Markersize',10,'Marker','.','LineStyle','none');
plot(CTD.Time,-CTD.Pres,'r.');
plot(CTDr.Time,CTDr.Speed,'color',[0.5 0.5 0.5],'Markersize',8,'Marker','.','LineStyle','none');
plot(CTD.Time,CTD.Speed,'r.');
grid on
legend('Temperature [C]','Ave Temp','Salinity [PSU]','Ave Sal','Pressure [dBar]','Ave Pres','Speed [kts]','Ave Speed','Location','bestoutside')
title(sprintf('%s%s','CastAway CT data - SPV - ',cdate));
set(gca,'FontWeight','Bold','FontSize',18)

return
%% ... Write output Files
% ...

ofile = sprintf('%s%s%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/CastAway_CTD/Collocated/SPV_',cdate,'_collocated_proc.dat')
writetable(timetable2table(CTDr), ofile); 

ofile2 = sprintf('%s%s%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/CastAway_CTD/Collocated/SPV_',cdate,'_collocated_ave.dat')
writetable(timetable2table(CTD), ofile2);


return


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
