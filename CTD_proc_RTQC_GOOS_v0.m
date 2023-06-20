%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ... Processing Pati Vela CTD data ...
% ...
% ... QC following CTD data following GOOS recomandation for Argo, CTD, XBT ...
% ... Nina H. May-2023
%% ...

%---------------------------------------------------------------
% ... Flag signification from SeaDataNet:
% ... Flag = 0 -> No check: raw data
% ... Flag = 1 -> Good data
% ... Flag = 2 -> Probably good data
% ... Flag = 3 -> Probably Bad
% ... Flag = 4 -> Bad data
% ....
%----------------------------------------------------------------

%--------------------------------------------------------------------------
% ... I. QC processing following GOOS recomandation for Argo, CTD, XBT ...
% ...
% RTQC1 : Platform indentification (only applied to Argo and GTS)
% RTQC2 : Impossible date test (alredy applied when convert file to ODV/SeaDataNet format)
% RTQC3 : Impossible location test (already applied when convert file to ODV/SeaDataNet format)
% RTQC4 : Position on land test (NOT applied)
% RTQC5 : Impossible speed test (specified for TD-SPV)
% RTQC6 : Global range test
% RTQC7 : Regional range test (Mediterranean Sea)
% RTQC8 : Pressure increasing test - Loop Edit
% RTQC9 : Spike test
% RTQC10 : Bottom spike test
% RTQC11 : Gradient test 
% RTQC12 : Digit rollover test (Not applied)
% RTQC13 : Stuck value test (for Pressure and Temperature)
% RTQC14 : Density inversion (Not possible, because only Temperature data)
% RTQC15 : Grey list (Argo only, NOT apllied)

%--------------------------------------------------------------------------
% ... II. Delayed Mode (DM) specific QC for Pati Cientific platform ...
% ...
% ... SPVQC1 : Remove first data as the sensors need time to stabilize
% ... SPVQC2 : Wild test (data > 4*std)
% ... SPVQC3 : Perfil speed down/up needs to be >0.2 m/s and <0.6m/s
% ... SPVQC4 : If 2 max depth, all data between are considered bad
% ... SPVQC5 : Visual last QC -> Check Pressure values, needs to be > 0 & Check data between 0-1m depth
% ... Right ODV/SeaDataNet output file with QC
% ...

%--------------------------------------------------------------------------
% ... III. Processing good data (PROC) ...
% ...
% ... 1. Split Up/Down
% ... 2. BinAverage profilte to 0.2 db
% ... 3. Interpolate missing data
% ... 4. Write output PROC SPV_TD files
% ...


%% Information related to SPV campaign station ...
% ... 	Latitude	Longitude	Mdept [m]
% TD1	41.3856 N	2.2099 E	23
% TD2	41.3798 N	2.1986 E	12
% TD3	41.3749 N	2.1951 E	10
% TD4	41.3806 N	2.2029 E	20
% TD5	41.3785 N	2.2084 E	28
% TD6	41.3757 N	2.2162 E	28

%% starting 
clear all
close all

addpath('/home/nina/Escritorio/WORK/Programs/matlab_prog/')
addpath('/home/nina/Escritorio/WORK/Programs/matlab_prog/teos10/')
addpath('/home/nina/Escritorio/WORK/Programs/matlab_prog/teos10/library/')
addpath('/home/nina/Escritorio/WORK/PatiCientific/programs/')

%% Open file and get raw data ...
% ...
type = 'CTDv1'
td_station = input('enter TD station file to be process (ex: 20210728_CTDX): ','s');
iyy = td_station(1:4);
imm = td_station(5:6);
numtd = td_station(13)

%ifile = sprintf('%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/SPV/Profile/TD_v00/RAW/',iyy,'/',imm,'/',td_station,'.DAT');
ifile = sprintf('%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/SPV/SeaWater/SeaDataNet_Format/Profile/RAW/CTD/',type,'/',iyy,'/',imm,'/',type,'_raw_',td_station,'.txt');
% ... check if input file to be processed exists ...
if exist(ifile,'file')
    fprintf('%s%s\n','Read data file : ',ifile)
else
    fprintf('%s%s%s\n',' Impossible to Open ',ifile,' DO NOT exist !!')
    return
end

LatitudeID = ['41.3856'; '41.3798'; '41.3749'; '41.3806'; '41.3785'; '41.3757'];
LongitudeID = ['002.2099'; '002.1986'; '002.1951'; '002.2029'; '002.2084'; '002.2162'];

Latitude = LatitudeID(str2num(numtd),:) 
Longitude = LongitudeID(str2num(numtd),:)

info = readtable(ifile);
oCruise = info.Cruise(1,:); Cruise = oCruise{1}
Station = info.Station(1,:)
oType = info.Type(1,:); Type = oType{1}
oTimeOK = info.YYYY_MM_DDThh_mm_ss; TimeOK = cell2mat(oTimeOK);
Longitude = info.Longitude_degrees_east_(1,:)
Latitude = info.Latitude_degrees_north_(1,:)
oLOCAL_CDI_ID = info.LOCAL_CDI_ID(1,:); LOCAL_CDI_ID = oLOCAL_CDI_ID{1}
EDMO_code = info.EDMO_code(1,:)
oBotDepth = info.Bot_Depth_m_(1,:); BotDepth = blanks(length(oBotDepth))

% ... Time ...
yy = str2num(TimeOK(:,1:4));
mm = str2num(TimeOK(:,6:7));
dd = str2num(TimeOK(:,9:10));
HH = str2num(TimeOK(:,12:13));
MM = str2num(TimeOK(:,15:16));
SS = str2num(TimeOK(:,18:19));
mTime=datenum(yy,mm,dd,HH,MM,SS);
Time = datetime(mTime,'convertfrom','datenum');

% ... Get variables with QC values ...
Depth = info.DEPTH_Metres_;
QC_Depth = info.QV_SEADATANET;
Pressure = info.PRESSURE_Decibars_;
QC_Pressure = info.QV_SEADATANET_4;
Temperature = info.TEMPERATURE_DegreesCelsius_;
QC_Temperature = info.QV_SEADATANET_1;
Conductivity = info.CONDUCTIVITY_SiemensPerMetre_;
QC_Conductivity = info.QV_SEADATANET_3;
Salinity = info.SALINITY_PartsPerThousand_;
QC_Salinity = info.QV_SEADATANET_2;

% ... Need the velocity of down/upcast profile ...
iSpeed = Pressure*zeros;
QC_iSpeed = iSpeed;
for i=2:length(iSpeed)
    iSpeed(i) =  Pressure(i) - Pressure(i-1);  % frequency of measurement is 1 sec.
end
idm0 = find(Pressure==max(Pressure));   % ... ID of Maximum depth

idm = idm0(1);

% ... Figures of RAW data ...
figure(1);clf;set(gcf,'Position', get(0, 'Screensize'),'color','w');
% ... Temperature & Salinity profile ...
ax1 = subplot(2,4,[1,5])
colorTempD=rgb('SteelBlue');
colorTempU=rgb('MediumBlue');
colorSalD=rgb('SeaGreen');
colorSalU=rgb('DarkGreen');
l1=plot(Temperature(1:idm),-Pressure(1:idm),'color',colorTempD,'Markersize',10,'Marker','.','LineStyle','none');
hold on
l2=plot(Temperature(idm+1:end),-Pressure(idm+1:end),'color',colorTempU,'Markersize',10,'Marker','.','LineStyle','none');
l3=plot(Temperature(idm),-Pressure(idm),'Markersize',18,'Marker','*','LineStyle','none','Color',rgb('OrangeRed'));
grid on
ax1.XLabel.String = 'Temperature [C]';
ax1.XAxisLocation = 'top';
ax1.YLabel.String = 'Pressure [dB]';
hleg=legend([l1 l2],'Location','Best');
hleg.String={'Downcast','Upcast'};
set(ax1,'FontSize',12,'FontWeight','bold','color',[0.9 0.9 0.9])

% ... Salinity profile ...
ax11 = subplot(2,4,[2,6])
l1=plot(Salinity(1:idm),-Pressure(1:idm),'color',colorSalD,'Markersize',10,'Marker','.','LineStyle','none');
hold on
l2=plot(Salinity(idm+1:end),-Pressure(idm+1:end),'color',colorSalU,'Markersize',10,'Marker','.','LineStyle','none');
l3=plot(Salinity(idm),-Pressure(idm),'Markersize',18,'Marker','*','LineStyle','none','Color',rgb('OrangeRed'));
grid on
%ax11.XLim = [37 40];
ax11.XLabel.String = 'Salinity [ppt]';
ax11.XAxisLocation = 'top';
ax11.YLabel.String = 'Pressure [dB]';
hleg=legend([l1 l2],'Location','Best');
hleg.String={'Downcast','Upcast'};
set(ax11,'FontSize',12,'FontWeight','bold','color',[0.9 0.9 0.9])

% ... Conductivity profile ...
ax11 = subplot(2,4,[3,7])
colorCondD=rgb('Lightcoral');
colorCondU=rgb('Darkred');
l1=plot(Conductivity(1:idm),-Pressure(1:idm),'color',colorCondD,'Markersize',10,'Marker','.','LineStyle','none');
hold on
l2=plot(Conductivity(idm+1:end),-Pressure(idm+1:end),'color',colorCondU,'Markersize',10,'Marker','.','LineStyle','none');
l3=plot(Conductivity(idm),-Pressure(idm),'Markersize',18,'Marker','*','LineStyle','none','Color',rgb('OrangeRed'));
grid on
ax11.XLabel.String = 'Conductivity [S/m]';
ax11.XAxisLocation = 'top';
ax11.YLabel.String = 'Pressure [dB]';
hleg=legend([l1 l2],'Location','Best');
hleg.String={'Downcast','Upcast'};
set(ax11,'FontSize',12,'FontWeight','bold','color',[0.9 0.9 0.9])

% ... Speed profile ...
ax2 = subplot(2,4,[4,8])
colorSpeedD=rgb('MediumOrchid');
colorSpeedU=rgb('Indigo');
l1=plot(iSpeed(1:idm),-Pressure(1:idm),'color',colorSpeedD,'Markersize',8,'Marker','.','LineStyle','none');
hold on
l2=plot(iSpeed(idm+1:end),-Pressure(idm+1:end),'color',colorSpeedU,'Markersize',8,'Marker','.','LineStyle','none');
l3=plot(iSpeed*zeros,-Pressure,'k--','LineWidth',1);
l4=plot(iSpeed(idm),-Pressure(idm),'Markersize',18,'Marker','*','LineStyle','none','Color',rgb('OrangeRed'));
grid on
ax2.XLabel.String = 'Speed [m/s]';
ax2.XAxisLocation = 'Top';
hleg=legend([l1 l2],'Location','Best');
hleg.String={'Downcast','Upcast'};
set(ax2,'FontSize',12,'FontWeight','bold','color',[0.9 0.9 0.9])
% ... Write general title for the figure ...
titleSettings = {'HorizontalAlignment','center','EdgeColor','none','FontSize',18,'FontWeight','bold'};
%gtitle = sprintf('%s%s%s',td_station(10:12),' of ',td_station(7:8),'-',td_station(5:6),'-',td_station(1:4));
gtitle = sprintf('%s%s','Station ', td_station(10:13));
annotation('textbox','Position',[0.83 0.93 0.2 0.05],'String',gtitle,titleSettings{:})

% ... Global Time serie information ...
figure(2); clf; set(gcf,'Position', get(0, 'Screensize'),'color','w');
%set(gcf,'Position', get(0, 'Screensize'),'color','w');
plot(datetime(mTime,'convertfrom','datenum'),double(Temperature),'color',[0 0.4470 0.7410],'Markersize',10,'Marker','.','LineStyle','none');
hold on
plot(datetime(mTime,'convertfrom','datenum'),double(Salinity),'color',[0.4660 0.6740 0.1880],'Markersize',10,'Marker','.','LineStyle','none');
plot(datetime(mTime,'convertfrom','datenum'),-double(Pressure),'color',[0.9290 0.6940 0.1250],'Markersize',10,'Marker','.','LineStyle','none');
plot(datetime(mTime,'convertfrom','datenum'),double(iSpeed),'color',[0.5 0.5 0.5],'Markersize',8,'Marker','.','LineStyle','none');
grid on
legend('Temperature [C]','Salinity [PSU]','Pressure [dBar]','Speed [m/s]','Location','best')
title(sprintf('%s%s','CTD data - SPV - Station ',td_station(10:13)));
set(gca,'FontWeight','Bold','FontSize',18)

% ... Only Temp and Salinity
figure(3); clf; set(gcf,'Position', get(0, 'Screensize'),'color','w');
%set(gcf,'Position', get(0, 'Screensize'),'color','w');
yyaxis left % ... Temperature on Left
plot(datetime(mTime,'convertfrom','datenum'),double(Temperature),'color',[0 0.4470 0.7410],'Markersize',10,'Marker','.','LineStyle','none');
hold on
ylabel('Temperature [ \circC ]')
yyaxis right % ... Salinity on Right
plot(datetime(mTime,'convertfrom','datenum'),double(Salinity),'color',[0.4660 0.6740 0.1880],'Markersize',10,'Marker','.','LineStyle','none');
ylabel('Salinityty [ psu ]')
grid on
% ... Control color of yaxis ...
ax = gca;
ax.YAxis(1).Color = [0 0.4470 0.7410];
ax.YAxis(2).Color = [0.4660 0.6740 0.1880];
title(sprintf('%s%s','CTD data - SPV - Sation',td_station(10:13)));
set(gca,'FontWeight','Bold','FontSize',18)


%ofig = sprintf('%s%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/SPV/SeaWater/SeaDataNet_Format/Figures/RAW_',td_station);
%saveas(gcf,ofig,'jpg')

%% I. start Quality Control processing following GOOS RTQC
% ......................................................

colorFlagT4=rgb('Red');
colorFlagT3=rgb('Orange');
colorFlagT2=rgb('SpringGreen');
colorFlagP4=rgb('Brown');
colorSpeedD=rgb('MediumOrchid');
colorSpeedU=rgb('Indigo');
colorPres=rgb('Gold');

% ...
% ... RTQC6: Global range test ...
% ... Temperature in range -2.5ºC to 40.0ºC
% ... Salinity in range from 2 to 41 PSU
% ... Pressure in positive range
% ...
% ... Temperature
clear ff
ff = find(Temperature<-2.5 | Temperature>40.0);
if (~isempty(ff))
    QC_Temperature(ff) = 4;
    QC_Salinity(ff) = 4;
end

% ... Salinity 
clear ff
ff = find(Salinity<2.0 | Salinity>41.0);
if (~isempty(ff))
    QC_Salinity(ff) = 4;
end

figure(1)
ax1 = subplot(2,4,[1,5]) % ... Temperature profile Flags ...
clear tt; tt=find(QC_Temperature==4);
if ~isempty(tt)
    l5=plot(Temperature(QC_Temperature==4),-Pressure(QC_Temperature==4),'color',colorFlagT4,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l5],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC6'};
end
ax11 = subplot(2,4,[2,6]) % ... Salinity profile Flags ...
clear tt; tt=find(QC_Salinity==4);
if ~isempty(tt)
    l5=plot(Salinity(QC_Salinity==4),-Pressure(QC_Salinity==4),'color',colorFlagT4,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l5],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC6'};
end

% ...
% ... Pressure Check ...
clear ff
ff = find(Pressure<=0);
if (~isempty(ff))
    QC_Pressure(ff) = 4;
    QC_Temperature(ff) = 3;
    QC_Salinity(ff) = 3;
end

figure(1)
ax1 = subplot(2,4,[1,5]) % ... Temperature profile Flags ...
clear tt; tt=find(QC_Temperature==3);
if ~isempty(tt)
    l5=plot(Temperature(QC_Temperature==3),-Pressure(QC_Temperature==3),'color',colorFlagT3,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l5],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC6'};
end 
ax11 = subplot(2,4,[2,6]) % ... Salinity profile Flags ...
clear tt; tt=find(QC_Salinity==3);
if ~isempty(tt)
    l4=plot(Salinity(QC_Salinity==3),-Pressure(QC_Salinity==3),'color',colorFlagT3,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l4],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC6'};
end

% ............................................
% ... RTQC7 : Regional range test
% ... Mediterranean -> Catalan/Barcelona coast
% ... Temperature range is from 10ºC to 33ºC
% ... Salinity range is from 2 to 40 psu
% ... Pressure range at SPV location if 0m to 50m maximum
% ...
% ... QC for Temperature ...
clear ff
ff = find(Temperature<10.0 | Temperature>33.0);
if (~isempty(ff))
    QC_Temperature(ff) = 4;
    QC_Salinity(ff) = 4;
end
% ... QC for Salinity ...
clear ff
ff = find(Salinity<2.0 | Salinity>40.0);
if (~isempty(ff))
    QC_Salinity(ff) = 4;
end

figure(1)
ax1 = subplot(2,4,[1,5]) % ... Temperature profile Flags ...
clear tt; tt=find(QC_Temperature==4);
if ~isempty(tt)
    l5=plot(Temperature(QC_Temperature==4),-Pressure(QC_Temperature==4),'color',colorFlagT4,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l5],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC7'};
end 
ax11 = subplot(2,4,[2,6]) % ... Salinity profile Flags ...
clear tt; tt=find(QC_Salinity==4);
if ~isempty(tt)
    l5=plot(Salinity(QC_Salinity==4),-Pressure(QC_Salinity==4),'color',colorFlagT4,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l5],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC7'};
end

% ... QC for Pressure ...
clear ff
ff = find(Pressure>50.0);
if (~isempty(ff))
    QC_Pressure(ff) = 4;
end

figure(1)
ax1 = subplot(2,4,[1,5]) % ... Temperature profile Flags ...
clear tt; tt=find(QC_Pressure==4);
if ~isempty(tt)
    l5=plot(Temperature(QC_Pressure==4),-Pressure(QC_Pressure==4),'color',colorFlagT4,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l5],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC7'};
end 
ax11 = subplot(2,4,[2,6]) % ... Salinity profile Flags ...
if ~isempty(tt)
    l5=plot(Salinity(QC_Pressure==4),-Pressure(QC_Pressure==4),'color',colorFlagT4,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l5],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC7'};
end



% ............................................
% ... RTQC8 : Pressure increasing test
% ... (Loop Edit)
% ... Use iSpeed data to check if TD is going up/down when should go only
% down/up due to wave at the surface ...
% ...
% ... 1. Downcast case ...
clear ff
ff = find(iSpeed(1:idm)<=0 & QC_Temperature(1:idm)<3);
if (~isempty(ff))
    QC_Temperature(ff) = 2;
    QC_Salinity(ff) = 2;
    QC_iSpeed(ff) = 4;
end

% ... Upcast case
% ... Use iSpeed data to check if TD is going up when should go only Up
% ... due to wave at the surface ...
clear ff
ff = find(iSpeed(idm:end)>=0 & QC_Temperature(idm:end)<3);
if (~isempty(ff))
    QC_Temperature(ff+idm-1) = 2;
    clear tt; tt = find(QC_Salinity(ff)<3);
    if (~isempty(tt)) 
        QC_Salinity(ff+idm-1)=2;
    end
    QC_iSpeed(ff+idm-1) = 4;
end

figure(1);
% ... Temperature profile ...
ax1 = subplot(2,4,[1,5]) % ... Temperature profile Flags ...
clear tt; tt=find(QC_Temperature==2);
if ~isempty(tt)
    l8=plot(Temperature(QC_Temperature==2),-Pressure(QC_Temperature==2),'color',colorFlagT2,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l8],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC8'};
end

ax11 = subplot(2,4,[2,6]) % ... Salinity profile Flags ...
clear tt; tt=find(QC_Salinity==2);
if ~isempty(tt)
    l8=plot(Salinity(QC_Salinity==2),-Pressure(QC_Salinity==2),'color',colorFlagT2,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l8],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC8'};
end

% ... Speed profile ...
ax2 = subplot(2,4,[4,8])
clear tt; tt=find(QC_iSpeed==4);
if ~isempty(tt)
    l4=plot(iSpeed(tt),-Pressure(tt),'color','r','Markersize',8,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l4],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC8'};
end


% ............................................
% ... RTQC9 : Spike test
% ... test value = |V2 - (V3+V1)/2|-|(V3-V1)/2|
% ... V2 is the measure tested as a spike
% ... V1 and V3 are the values before and after.
% ... Temperature V2 values is flagged when test exceed 6ºC
% ... Salinity V2 values is flagged when test exceed 0.9 psu
% ...
m=0;
for i =2:length(Temperature)-1
    test_valueT = abs(Temperature(i)-(Temperature(i+1)+Temperature(i-1))/2)-abs(Temperature(i+1)-Temperature(i-1))/2;
    if (abs(test_valueT)>=6.0)
        QC_Temperature(i) = 4;
        QC_Salinity(i) = 4;

        disp('------------------------------')
        disp('test_value T for spike test !!')
        i
        Temperature(i-1)
        Temperature(i)
        Temperature(i+1)
        m = m+1
    end
end

m=0;
for i =2:length(Salinity)-1
    test_valueS = abs(Salinity(i)-(Salinity(i+1)+Salinity(i-1))/2)-abs(Salinity(i+1)-Salinity(i-1))/2;
    if (abs(test_valueS)>=0.9)
        QC_Salinity(i) = 4;

        disp('------------------------------')
        disp('test_value T for spike test !!')
        i
        Salinity(i-1)
        Salinity(i)
        Salinity(i+1)
        m = m+1
    end
end

% ... Figures of QC test ...
figure(1); 
% ... Temperature profile ...
ax1 = subplot(2,4,[1,5]) % ... Temperature profile Flags ...
clear tt; tt=find(QC_Temperature==4);
if ~isempty(tt)
    l9=plot(Temperature(QC_Temperature==4),-Pressure(QC_Temperature==4),'color',colorFlagT4,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l9],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC9'};
end

ax11 = subplot(2,4,[2,6]) % ... Salinity profile Flags ...
clear tt; tt=find(QC_Salinity==4);
if ~isempty(tt)
    l9=plot(Salinity(QC_Salinity==4),-Pressure(QC_Salinity==4),'color',colorFlagT4,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l9],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC9'};
end

% ............................................
% ... RTQC10 : Bottom spike test
% ... Temperature at the bottom should not differ from the adjacent
% ... measurement by more than 1ºC.
% ... Not applied to Salinity measurements ...
% ...
m=0;
for i =idm-10:idm+10
    test_valueT = abs(Temperature(i)-(Temperature(i+1)+Temperature(i-1))/2)-abs(Temperature(i+1)-Temperature(i-1))/2;
    if (abs(test_valueT)>=1)
        QC_Temperature(i) = 4;
        QC_Salinity(i) = 4;

        disp('------------------------------')
        disp('test_value T for spike test !!')
        i
        Temperature(i-1)
        Temperature(i)
        Temperature(i+1)
        m = m+1
    end
end

% ... Figures of QC test ...
figure(1)
% ... Temperature profile ...
ax1 = subplot(2,4,[1,5]) % ... Temperature profile Flags ...
clear tt; tt=find(QC_Temperature==4);
if ~isempty(tt)
    l10=plot(Temperature(QC_Temperature==4),-Pressure(QC_Temperature==4),'color',colorFlagT4,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l10],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC10'};
end

ax11 = subplot(2,4,[2,6]) % ... Salinity profile Flags ...
clear tt; tt=find(QC_Salinity==4);
if ~isempty(tt)
    l10=plot(Salinity(QC_Salinity==4),-Pressure(QC_Salinity==4),'color',colorFlagT4,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l10],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC10'};
end


% ............................................
% ... RTQC11 : Gradient test
% ... test value = |V2-(V3+V1)/2|
% ... V2 is the measure tested as a spike
% ... V1 and V3 are the values before and after.
% ... Temperature V2 values is flagged when test exceed 9ºC for pressures
% ... (In case of SPV we use 4ºC)
% ... Salinity V2 values is flagged when test exceed 1.5 psu for pressures 
% ... less than 500 db.
% ... 
m=0;
for i =2:length(Temperature)-1
    test_valueT = abs(Temperature(i)-(Temperature(i+1)+Temperature(i-1))/2);
    if (abs(test_valueT)>=4.0)
        QC_Temperature(i) = 3;
        QC_Salintiy(i) = 3;
        disp('------------------------------')
        disp('test_value T for Gradient test !!')
        i
        Temperature(i-1)
        Temperature(i)
        Temperature(i+1)
        m = m+1
    end
end

m=0;
for i =2:length(Salinity)-1
    test_valueS = abs(Salinity(i)-(Salinity(i+1)+Salinity(i-1))/2);
    if (abs(test_valueS)>=1.5)
        QC_Salintiy(i) = 3;
        disp('------------------------------')
        disp('test_value S for Gradient test !!')
        i
        Salinity(i-1)
        Salinity(i)
        Salinity(i+1)
        m = m+1
    end
end

% ... Figures of QC test ...
figure(1);
% ... Temperature profile ...
ax1 = subplot(3,4,[1,5,9])
clear tt; tt=find(QC_Temperature==3);
if ~isempty(tt)
    l11=plot(Temperature(QC_Temperature==3),-Pressure(QC_Temperature==3),'color',colorFlagT3,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l11],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC11'};
end
ax11 = subplot(2,4,[2,6]) % ... Salinity profile Flags ...
clear tt; tt=find(QC_Salinity==3);
if ~isempty(tt)
    l11=plot(Salinity(QC_Salinity==3),-Pressure(QC_Salinity==3),'color',colorFlagT3,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l11],'Location','Best');
    hleg.String={'Downcast','Upcast','RTQC11'};
end


% ............................................
% ... RTQC13 : Stuck value test
% ... Flat line test
% ...
% EPS = 0.0D0; 
% for i=2:length(Temperature)
%     if abs(Temperature(i)-Temperature(i-1))<EPS
%         QC_Temperature(i)= 4;
%     end
%     
%     if abs(Pressure(i)-Pressure(i-1))<EPS
%         QC_Pressure(i)= 4;
%     end
% end
% 
% % ... Figures of QC test ...
% figure(1)
% % ... Temperature profile ...
% ax1 = subplot(3,4,[1,5,9])
% clear tt; tt=find(QC_Temperature==4);
% if ~isempty(tt)
%     l13=plot(Temperature(QC_Temperature==4),-Pressure(QC_Temperature==4),'color',colorFlagT4,'Marker','.','LineStyle','none');
%     hleg=legend([l1 l2 l13],'Location','Best');
%     hleg.String={'Downcast','Upcast','RTQC13'};
% end
% % ... Pressure time serie ...
% ax3 = subplot(3,4,[3,4])
% clear tt; tt=find(QC_Pressure==4);
% if ~isempty(tt)
%     l13=plot(datetime(mTime(tt),'convertfrom','datenum'),double(Temperature(tt)),'color',colorFlagT4,'Markersize',10,'Marker','.','LineStyle','none');
%     hleg=legend([l1 l2 l13],'Location','Best');
%     hleg.String={'Downcast','Upcast','RTQC13'};
% end
% % ... Temperature time serie ...
% ax5 = subplot(3,4,[11,12])
% clear tt; tt=find(QC_Temperature==4);
% if ~isempty(tt)
%     l13=plot(datetime(mTime(QC_Temperature==4),'convertfrom','datenum'),double(Temperature(QC_Temperature==4)),'color',colorFlagT4,'Markersize',10,'Marker','.','LineStyle','none');
%     hleg=legend([l1 l2 l13],'Location','Best');
%     hleg.String={'Downcast','Upcast','RTQC13'};
% end


%% II. Delayed Mode (DM) specific QC for Pati Cientific platform ...
% ...
% ... SPVQC1 : Remove first data as the sensors need time to stabilize
% ... SPVQC2 : Wild test (data > 4*std)
% ... SPVQC3 : Perfil speed down/up needs to be >0.2 m/s and <0.6m/s
% ... SPVQC4 :  If 2 max depth, all data between are considered bad
% ... SPVQC5 : Visual last QC -> Check data between 0-1m depth / Pressure
% values
% ... Right ODV/SeaDataNet output file with QC
% ...

% ...
% ... SPVQC1 : Remove first data as the sensors need time to stabilize ?
% ...
tinit = 38;
tend = 13;
QC_Temperature(1:tinit) = 4;
QC_Salinity(1:tinit) = 4;
QC_Temperature(end-tend:end) = 4;
QC_Salinity(end-tend:end) = 4;

% ... Figures of QC test ...
figure(1);
% ... Temperature profile ...
ax1 = subplot(3,4,[1,5,9])
clear tt; tt=find(QC_Temperature==4);
if ~isempty(tt)
    l21=plot(Temperature(QC_Temperature==4),-Pressure(QC_Temperature==4),'color',colorFlagT4,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l21],'Location','Best');
    hleg.String={'Downcast','Upcast','SPVQC1'};
end
ax11 = subplot(2,4,[2,6]) % ... Salinity profile Flags ...
clear tt; tt=find(QC_Salinity==4);
if ~isempty(tt)
    l21=plot(Salinity(QC_Salinity==4),-Pressure(QC_Salinity==4),'color',colorFlagT4,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l21],'Location','Best');
    hleg.String={'Downcast','Upcast','SPVQC1'};
end

figure(3);
clear tt; tt=find(QC_Temperature==4);
if ~isempty(tt)
    yyaxis left % ... Temperature on Left
    l21 = plot(datetime(mTime(QC_Temperature==4),'convertfrom','datenum'),double(Temperature(QC_Temperature==4)),'color',colorFlagT4,'Markersize',10,'Marker','.','LineStyle','none');
    hleg=legend([l21],'Location','Best');
    hleg.String={'SPVQC1'};
end

clear tt; tt=find(QC_Salinity==4);
if ~isempty(tt)
    yyaxis right % ... Salinity on Right
    l21 = plot(datetime(mTime(QC_Salinity==4),'convertfrom','datenum'),double(Salinity(QC_Salinity==4)),'color',colorFlagT4,'Markersize',10,'Marker','.','LineStyle','none');
    hleg=legend([l21],'Location','Best');
    hleg.String={'SPVQC1'};
end

return
% ...
% ... SPVQC2 : Wild Edit (get Mean and STD for all scans)
% ... Wrong data correspond to value > 4 times STD 
% ...
tmean = mean(Temperature(QC_Temperature<3)); 
tstd = std(Temperature(QC_Temperature<3));
tcheck = 4*tstd;
for i=2:length(Temperature)
    if(QC_Temperature(i)<3)
        ti = abs(Temperature(i)-tmean);
        if (ti>tcheck)
            QC_Temperature(i) = 3;
        end
    end
end

% ... Figures of QC test ...
figure(1);
% ... Temperature profile ...
ax1 = subplot(3,4,[1,5,9])
clear tt; tt=find(QC_Temperature==3);
if ~isempty(tt)
    l22=plot(Temperature(QC_Temperature==3),-Pressure(QC_Temperature==3),'color',colorFlagT3,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l22],'Location','Best');
    hleg.String={'Downcast','Upcast','SPVQC2'};
end
ax11 = subplot(2,4,[2,6]) % ... Salinity profile Flags ...
clear tt; tt=find(QC_Salinity==3);
if ~isempty(tt)
    l22=plot(Salinity(QC_Salinity==3),-Pressure(QC_Salinity==3),'color',colorFlagT3,'Marker','.','LineStyle','none');
    hleg=legend([l1 l2 l22],'Location','Best');
    hleg.String={'Downcast','Upcast','SPVQC2'};
end

% ... Temperature time serie ...
figure(3);
clear tt; tt=find(QC_Temperature==3);
if ~isempty(tt)
    l22 = plot(datetime(mTime(QC_Temperature==3),'convertfrom','datenum'),double(Temperature(QC_Temperature==3)),'color',colorFlagT3,'Markersize',10,'Marker','.','LineStyle','none');
    hleg=legend([l22],'Location','Best');
    hleg.String={'SPVQC2'};
end

clear tt; tt=find(QC_Salinity==3);
if ~isempty(tt)
    l22 = plot(datetime(mTime(QC_Salinity==3),'convertfrom','datenum'),double(Salinity(QC_Salinity==3)),'color',colorFlagT3,'Markersize',10,'Marker','.','LineStyle','none');
    hleg=legend([l22],'Location','Best');
    hleg.String={'SPVQC2'};
end

return

...
... SPVQC3: Specific SPV speed test 
% ... Speed < 0.1 m/s or > 0.6 m/s
% ...
SPVQC3 = false
    if SPVQC3
    Speed = abs(iSpeed);
    QC_Speed = Speed*zeros; % Speed flag initialized to 0
    clear ff
    %ff = find(Speed<0.03 | Speed>0.6);
    ff = find(Speed>0.7);
    if(~isempty(ff))
        QC_Temperature(ff)=3;
        QC_Speed(ff) = 5;
    end

    figure(1)
    % ... Temperature profile ...
    ax1 = subplot(3,4,[1,5,9])
    clear tt; tt=find(QC_Temperature==3);
    if ~isempty(tt)
        l23=plot(Temperature(QC_Temperature==3),-Pressure(QC_Temperature==3),'color',colorFlagT3,'Marker','.','LineStyle','none');
        hleg=legend([l1 l2 l23],'Location','Best');
        hleg.String={'Downcast','Upcast','SPVQC3'};
    end
    % ... Speed profile ...
    ax2 = subplot(3,4,[2,6,10])
    clear tt; tt=find(QC_Speed==5);
    if ~isempty(tt)
        l23=plot(iSpeed(tt),-Pressure(tt),'color','r','Markersize',8,'Marker','+','LineStyle','none');
        hleg=legend([l1 l2 l23],'Location','Best');
        hleg.String={'Downcast','Upcast','SPVQC3'};
    end
    ax4 = subplot(3,4,[7,8])
    clear tt; tt=find(QC_Speed==5);
    if ~isempty(tt)
        l23=plot(datetime(mTime(tt),'convertfrom','datenum'),iSpeed(tt),'r','Markersize',8,'Marker','+','LineStyle','none');
        hleg=legend([l1 l2 l23],'Location','Best');
        hleg.String={'Downcast','Upcast','SPVQC3'};
    end
    % ... Temperature time serie ...
    ax5 = subplot(3,4,[11,12])
    clear tt; tt=find(QC_Temperature==3);
    if ~isempty(tt)
        plot(datetime(mTime(QC_Temperature==3),'convertfrom','datenum'),double(Temperature(QC_Temperature==3)),'color',colorFlagT3,'Markersize',10,'Marker','.','LineStyle','none');
        hleg=legend([l1 l2],'Location','Best');
        hleg.String={'Downcast','Upcast'};
    end
end

% ...
% ... SPVQC4 : If 2 max depth, all data between are considered bad
% ...
SPVQC4 = false

if SPVQC4
    idmax1 = idm;   % find(Pressure==max(Pressure));
    idmax2 = find(Pressure>round(max(Pressure)));
    if ~isempty(idmax2)
        QC_Temperature(idmax2(1):idmax2(end))=3;
        if length(idmax1)~=1
            QC_Temperature(idmax1(2:end))=3;
            idud=idmax1(1);   % ID Position of maximum pressure to later Split Up/Down casts
        else
            if(idmax1<idmax2(end))
                QC_Temperature(idmax1:idmax2(end))=3;
            end
            idud = idmax1;
        end
    else
        idud = idmax1;
    end

    figure(1)
    % ... Temperature profile ...
    ax1 = subplot(3,4,[1,5,9])
    clear tt; tt=find(QC_Temperature==3);
    if ~isempty(tt)
        l24=plot(Temperature(QC_Temperature==3),-Pressure(QC_Temperature==3),'color',colorFlagT3,'Marker','.','LineStyle','none');
        hleg=legend([l1 l2 l24],'Location','Best');
        hleg.String={'Downcast','Upcast','SPVQC4'};
    end
    % clear tt; tt=find(QC_Temperature==4);
    % if ~isempty(tt)
    %     l244=plot(Temperature(QC_Temperature==4),-Pressure(QC_Temperature==4),'color',colorFlagT4,'Marker','.','LineStyle','none');
    %     hleg=legend([l1 l2 l244],'Location','Best');
    %     hleg.String={'Downcast','Upcast','SPVQC4'};
    % % end
    % ... Temperature time serie ...
    ax5 = subplot(3,4,[11,12])
    clear tt; tt=find(QC_Temperature==3);
    if ~isempty(tt)
        plot(datetime(mTime(QC_Temperature==3),'convertfrom','datenum'),double(Temperature(QC_Temperature==3)),'color',colorFlagT3,'Markersize',10,'Marker','.','LineStyle','none');
        hleg=legend([l1 l2],'Location','Best');
        hleg.String={'Downcast','Upcast'};
    end
    % clear tt; tt=find(QC_Temperature==4);
    % if ~isempty(tt)
    %     plot(datetime(mTime(QC_Temperature==4),'convertfrom','datenum'),double(Temperature(QC_Temperature==4)),'color',colorFlagT4,'Markersize',10,'Marker','.','LineStyle','none');
    %     hleg=legend([l1 l2],'Location','Best');
    %     hleg.String={'Downcast','Upcast'};
    % end

end

ofig = sprintf('%s%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/SPV/SeaWater/SeaDataNet_Format/Figures/DM_',td_station);
saveas(gcf,ofig,'jpg')

%% Actualization of Temperature QF
% ... In case QF of Speed/Pressure are bad -> QC_Temperature=3
% ... otherwise QC_Temperature=1
% ...

clear ff
ff = find(QC_iSpeed(tinit:tend)==4);
if (~isempty(ff))
    QC_Temperature(ff)=2;
end
% 
% clear ff
% ff = find(QC_Speed==4);
% if (~isempty(ff))
%     QC_Temperature(ff)=3;
% end

clear ff
ff = find(QC_Pressure==4);
if (~isempty(ff))
    QC_Temperature(ff)=3;
end

clear ff
ff = find(QC_Pressure==0);
if (~isempty(ff))
    QC_Pressure(ff) = 1;
end
QC_Depth = QC_Pressure;

clear ff
ff = find(QC_Temperature==0);
if (~isempty(ff))
    QC_Temperature(ff) = 1;
end

BotDepth = EDMO_code;
BotDepth(1) = blanks(length(BotDepth(1)));

%% CREATE Table to Write output in ODV .txt files
% ...
TD_DM = table(Cruise,Station,Type,sTimeOK,Longitude,Latitude,LOCAL_CDI_ID,EDMO_code,BotDepth,Depth,QC_Depth,Pressure,QC_Pressure,Temperature,QC_Temperature);

%% CREATE TimeTable to Write output in .mat/.csv/.txt files
% ...
dmfile = sprintf('%s%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/SPV/SeaWater/SeaDataNet_Format/Profile/DM/TD/TD_',td_station);
%writetable(TD_DM,sprintf('%s%s',dmfile,'.dat'));   % txt file with struct of matlab
writetable(TD_DM,sprintf('%s%s',dmfile,'.txt'),'Delimiter','\t');
%writetable(TD_DM,sprintf('%s%s',dmfile,'.csv'));

%mfile = sprintf('%s%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/SPV/SeaWater/matlab_format/Profile/DM/TD/',td_station,'_DM.mat');
%save(TD_DM,mfile)  % Mat file


return






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ... Split Down and up cast ...
% ... Get only downcast ...
% ... Get downcast ...
downcast.date = date_td(1:idud);
downcast.juldate = juliandate(datestr(downcast.date));
downcast.depth = rdepth(1:idud);
downcast.pres = rpres(1:idud);
downcast.temp = rtemp(1:idud); 
downcast.flag = flag(1:idud);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ... Bin Averaging ...
% ... Bin of 0.2 db values
% ...
proc.pres = (0:0.2:ceil(max(downcast.pres)))';  % Create vector of pres value every 0.2 db
proc.date = proc.pres*NaN;
proc.juldate = proc.pres*NaN;

proc.temp = proc.pres*NaN;
proc.nn = proc.pres*NaN;
proc.flag = proc.pres*0+1;

proc.temp2 = proc.pres*NaN;
proc.nn2 = proc.pres*NaN;
proc.flag2 = proc.pres*0+3;

ns = length(proc.pres);

for i = 1:ns
    % ... Get only Good data ...
   ind=find(downcast.pres>=proc.pres(i)-0.1 & downcast.pres<proc.pres(i)+0.1 & downcast.flag==1);
   proc.nn(i) = length(ind);
   proc.temp(i) = nanmean(downcast.temp(ind));
   proc.date(i) = nanmean(downcast.date(ind));
   proc.juldate(i) = nanmean(downcast.juldate(ind));
   %proc.depth(i) = nanmean(downcast.depth(ind));
    % ... Get Good and suspect data ...
   ind2=find(downcast.pres>=proc.pres(i)-0.1 & downcast.pres<proc.pres(i)+0.1 & downcast.flag ~= 4);
   proc.nn2(i) = length(ind2);
   proc.temp2(i) = nanmean(downcast.temp(ind2));
end

% ...
% ... Linear interpolation when no data in the bin average histogram
% ...
for i=2:length(proc.temp)-1
   if isnan(proc.temp(i))
       proc.flag(i) = 2;   % interpolated data
       proc.temp(i) = (proc.temp(i+1)+proc.temp(i-1))/2;
       proc.date(i) = (proc.date(i+1)+proc.date(i-1))/2;
       proc.juldate(i) = (proc.juldate(i+1)+proc.juldate(i-1))/2;
       
       proc.flag2(i) = 2; 
       proc.temp2(i) = (proc.temp2(i+1)+proc.temp2(i-1))/2;
   end
end 

% ... Figure ...
f1 = find(downcast.flag==1);
fok = find(downcast.flag~=4);

figure;set(gcf,'color','w','position',[600 1400 1200 1300]);
ax = gca;
plot(rtemp,flag,'+k')
hold on
plot(rtemp,velocity,'rp-','LineWidth',1)
plot(rtemp,-rpres,'*-','color',[0.5 0.5 0.5],'LineWidth',2)
plot(downcast.temp(fok),-downcast.pres(fok),'+','color',[0.8 0.3 0.1],'LineWidth',1.5)
plot(proc.temp2,-proc.pres,'color',[0.9 0.7 0.1],'LineWidth',1.5)
plot(downcast.temp(f1),-downcast.pres(f1),'o','color',[0 0.45 0.74],'LineWidth',1.5)
plot(proc.temp,-proc.pres,'color',[0.3 0.7 0.9],'LineWidth',1.5)
xlabel ('Temperature [C]')
set(ax,'XaxisLocation','Top');
ylabel ('Pressure [db]')
xlim([xmin xmax])
ylim([ymin ymax2])
grid on
legend('QC','Instrument velocity','Raw data','Delay Mode(QC no Bad)','BinAve(QC no Bad)','Delay Mode (QC=1)','BinAve (QC=1)','Location','best')
foutproc = sprintf('%s%s%s%s',dir_fig,'TD',td_station(10),'_',time_td);
title(sprintf('%s%s%s%s','TD',td_station(10),' ',time_td))
set(ax,'FontSize',16)
saveas(gcf,foutproc,'jpg')

figure;set(gcf,'color','w','position',[600 1400 1200 1300]);
ax = gca;
plot(downcast.temp,-downcast.pres,'*-','color',[0.5 0.5 0.5],'LineWidth',2)
hold on
plot(downcast.temp(fok),-downcast.pres(fok),'+','color',[0.8 0.3 0.1],'LineWidth',1.5)
plot(proc.temp2,-proc.pres,'color',[0.9 0.7 0.1],'LineWidth',1.5)
plot(downcast.temp(f1),-downcast.pres(f1),'o','color',[0 0.45 0.74],'LineWidth',1.5)
plot(proc.temp,-proc.pres,'color',[0.3 0.7 0.9],'LineWidth',1.5)
xlabel ('Temperature [C]')
set(ax,'XaxisLocation','Top');
ylabel ('Pressure [db]')
xlim([xmin xmax])
ylim([ymin ymax])
grid on
legend('Downcast','Delay Mode(QC no Bad)','BinAve(QC no Bad)','Delay Mode (QC=1)','BinAve (QC=1)','Location','best')
foutproc = sprintf('%s%s%s%s',dir_fig,'TD',td_station(10),'_Downcast_',time_td);
title(sprintf('%s%s%s%s','TD',td_station(10),' ',time_td))
set(ax,'FontSize',16)
saveas(gcf,foutproc,'jpg')

% ... Write output in dat file
% ... Downcast data ...
fout = sprintf('%s%s%s',dir_proc,'TD',td_station(10),'_DM_',time_td);
filename = sprintf('%s%s%s',fout,'_Downcast.dat');
out = struct2table(downcast);
writetable(out,filename);

% ... Average data ...
id = find(isnan(proc.temp));
proc.flag(id) = 9;
proc.temp(id) = -999.0D0;
proc.date(id) = -999.0D0;
proc.juldate(id) = -999.0D0;

id = find(isnan(proc.temp2));
proc.flag2(id) = 9;
proc.temp2(id) = -999.0D0;

filename = sprintf('%s%s%s',fout,'_BinAve.dat');
out = struct2table(proc);
writetable(out,filename);

datestr(downcast.date(1:5))

% ... Paper Figure ...
% ...
pp1 = find(downcast.flag==1);
pp3 = find(downcast.flag==3);
figure;
set(gcf,'color','w','position',[600 1400 1200 1300]);
ax = gca;
plot(rtemp,rpres,'*','color',[0.5 0.5 0.5],'LineWidth',4)
hold on
plot(downcast.temp(pp3),downcast.pres(pp3),'*','color',[0.8 0.3 0.1],'LineWidth',4)
plot(downcast.temp(pp1),downcast.pres(pp1),'b*','LineWidth',4)
%plot(rtemp(pp1),rpres(pp1),'*','color',[0 0.45 0.74],'LineWidth',4)
xlabel ('Temperature [C]')
set(ax,'XaxisLocation','Top');
ylabel ('Pressure [dbar]')
xlim([18 25])
ylim([-1 30])
grid on
set(gca, 'Ydir', 'reverse')
legend('Raw data','Suspect data','Good data','Location','Best')
title(sprintf('%s%s%s%s','TD',td_station(10),' ',time_td),'fontweight','bold')
set(ax,'FontSize',20,'fontweight','semibold')
% foutraw = sprintf('%s%s%s%s',dir_fig,'TD',td_station(10),'_raw_',time_td);
% saveas(gcf,foutraw,'jpg')

return
figure;
set(gcf,'color','w','position',[600 1400 1200 1300]);
plot(tdmin,rtemp)
hold on
plot(tdmin,rpres)
plot(tdmin,rdepth)
plot(tdmin,flag)
plot(tdmin,velocity)
legend('temp','pres','depth','velocity')
