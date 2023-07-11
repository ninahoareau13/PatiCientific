%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ... Pati Vela data from CastAway CTD ...
% ...
% ... Nina Hoareau, Dec 2021
% ...

clear all
close all

addpath('/home/nina/Escritorio/WORK/Programs/matlab_prog/')
addpath('/home/nina/Escritorio/WORK/Programs/matlab_prog/m_map/');

%% ... Date of the SPV campagn -> cdate
% ...
cdate = '20230517'

%% ... POSITIONS eStela data (from Excel file) ...
% ...
ifile = sprintf('%s%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/SPV/SeaWater/estela_position/estela_',cdate,'.csv');
if ~exist(ifile,'file')
   disp('eStela position file does not exist')
   ifile
   return
end

[msg,head,data,ini]= read_sbe(ifile);
[msg,ini,str] = read_par(ifile);

year = data(:,1);
month = abs(data(:,2));
dd = abs(data(:,3));
hh = abs(data(:,4));
mm = abs(data(:,5));
ss = abs(data(:,6));
Lat = data(:,9);
Lon = data(:,10);
Speed = data(:,11);   %sog
Speed2 = data(:,12);

pos_time = datenum(year,month,dd,hh,mm,ss);
Time = datetime(datestr(pos_time));

eStelaT = timetable(Time,Lat,Lon,Speed,Speed2);
tsg_position = timetable(Time,Lat,Lon);

clear data tt ifile Time;

%% ... Get CastAway CTD data (from Excel file) ...
% ... To get the correct size for the position data ...
ifile = sprintf('%s%s%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/SPV/SeaWater/Surface/CastAwayCTD/RAW/aggregate_surface_sections/10J101601_',cdate,'_all_tram.csv')
if ~exist(ifile,'file')
   disp('CTD file does not exist')
   ifile
   return
end

[msg,head,data,ini]= read_sbe(ifile);
[msg,ini,str] = read_par(ifile);

% Assign variables to each data column
%tt = data(:,1);   % sec from Cast time info (UTC)
dd = data(:,1);
mm = data(:,2);
yy = abs(data(:,3));
hh = data(:,4);
min = data(:,5);
ss = data(:,6);

T = datenum(yy,mm,dd,hh,min,ss);
Time = datetime(T,'convertfrom','datenum');

Pres = data(:,7);   % [dB]
Temp = data(:,8);   % deg C
Cond = data(:,9);   % uS/cm

CTD = timetable(Time,Pres,Temp,Cond);

tsg_time = timetable(Time,yy,mm,dd,hh,min,ss);    % needed later to create TSGQC input file

tsg_gps = synchronize(tsg_time,tsg_position);

clear data tt ifile;

%% Create collocated data ...
% ...

pati = synchronize(eStelaT,CTD);

%% ... save output file
% ...
ofile = sprintf('%s%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/SPV/SeaWater/Surface/CastAwayCTD/RAW/collocated_surface_sections/SPV_',cdate,'_collocated_raw');
writetable(timetable2table(pati),sprintf('%s%s',ofile,'.dat'));   % txt file with struct of matlab

%% Create collocated data to be processed with TSGQC code which needs to follow this organisation columns:
%HEADER YEAR MNTH DAYX hh mi ss LATX LONX CNDC CNDC_CAL SSPS SSPS_QC SSPS_CAL SSPS_ADJUSTED SSPS_ADJUSTED_QC SSPS_ADJUSTED_ERROR SSJT SSJT_QC SSJT_CAL SSJT_ADJUSTED SSJT_ADJUSTED_QC SSJT_ADJUSTED_ERROR SSTP SSTP_QC SSTP_CAL SSTP_ADJUSTED SSTP_ADJUSTED_QC SSTP_ADJUSTED_ERROR CNDC_FREQ SSJT_FREQ FLOW
% ...

FlagT = Temp * zeros;
FlagC = FlagT;
FlagS = FlagT;
FlagP = FlagT;


% ... Calcul Salinity value from C,T,P (using conduc2sali.m funcion)
% ... TEOS-10
[Sal]= conduc2sali(Cond,Temp,Pres);
tsg_data = timetable(Time,Cond,FlagC,Sal,FlagS,Temp,FlagT,Pres,FlagP);

TSG_all = synchronize(tsg_gps,tsg_data);
TSGrm = rmmissing(TSG_all);
TSG = timetable2table(TSGrm);
TSG.Time = [];

ofile = sprintf('%s%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/SPV/SeaWater/Surface/CastAwayCTD/PROC/tsgqc_input_files/SPV_',cdate,'_collocated_raw_tsgqc_input');
writetable(TSG,sprintf('%s%s',ofile,'.dat'));   % txt file with struct of matlab
return

% % ... Check size of both table ...
% % ...
% s1 = length(CTD.Time);
% s2 = length(eStelaT.Time);
% if (s1 > s2)
%     disp('length of CTD > eStela')
%     t1 = datenum(eStelaT.Time);
%     t2 = datenum(CTD.Time);
% elseif (s1 < s2)
%     disp('lenght of CTD < eStela')
%     t1 = datenum(CTD.Time);
%     t2 = datenum(eStelaT.Time);
% elseif (s1==s2)
%     return
%     disp('Need to code this part of the program !!!')
% end
% 
% % ... Get the index of commun starting Date ...
% % ...
% [M, I] = min(abs(t2-t1(1)));   % ... Closer point from positionTXT file
% if M==0
%     disp('Initial index Time match found')
%     cast_i = I;        
% else
%     disp('No index found for initial time')
% end
% 
% % ... Get the index of commun end Date ...
% % ...
% tf = CTD.Time(end);
% [M, I] = min(abs(t2-t1(end)));   % ... Closer point from positionTXT file
% if M==0
%     disp('Final index of Time match found')
%     cast_f = I;        
% else
%     disp('No index found for final time')
% end
% 
% % ... Concatenate and collocate the 2 data set from Time ...
% if s1 < s2  % case when length of CTD < eStela
%     tt1 = eStelaT(cast_i:cast_f,:);
%     tt2 = CTD;
%     pati = synchronize(tt1,tt2);
% elseif s1 > s2   % case when length of CTD > eStela
%     tt1 = CTD(cast_i:cast_f,:);
%     tt2 = eStelaT;
%     pati = synchronize(tt2,tt1);
% else
%     disp('No index found for initial time')
% end

%% ... save output file
% ...
% ofile = sprintf('%s%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/CastAway_CTD/Collocated/SPV_',str(76:85),'_collocated_raw');
% writetable(timetable2table(pati),sprintf('%s%s',ofile,'.dat'));   % txt file with struct of matlab
%mfile = sprintf('%s%s',ofile,'.mat');
%save mfile pati  % Mat file


% % ... Figure of position TXT & interpolated WEB
% ...
% figure
% %pp = find(pati.Lon>=-200);
% m_proj('lambert','long',[40 45],'lat',[0 5]);   
% %m_proj('miller','lat',[0 5],'lon',[40 45]);   
% m_coast('patch',[.7 1 .7],'edgecolor','none'); 
% m_grid('box','fancy','linestyle','-','gridcolor','w','backcolor',[.2 .65 1]);
% hold on
% m_scatter(pati.Lon,pati.Lat,'k*','LineWidth',4)
% title('Pati Cientific')