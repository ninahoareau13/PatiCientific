%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Writing SPV-TD raw data profile as SEADATANET format
% ... Nina H. November 2022
% ...
% ........................................................................
% ... Format .txt as following this example ...
% 
% //
% //<sdn_reference xlink:href="https://www.seadatanet.org/urnurl/SDN:C17::29AH" xlink:role="isObservedBy" xlink:type="SDN:L23::NVS2CON"/>
% //<sdn_reference xlink:href="https://cdi.seadatanet.org/report/edmo/2489/ID/xml" xlink:role="isDescribedBy" xlink:type="SDN:L23::CDI" sdn:scope="2489:ID"/>
% //SDN_parameter_mapping
% //<subject>SDN:LOCAL:Depth</subject><object>SDN:P01::ADEPZZ01</object><units>SDN:P06::ULAA</units>
% //<subject>SDN:LOCAL:Temperature</subject><object>SDN:P01::TEMPPR01</object><units>SDN:P06::UPAA</units><instrument>SDN:L22::TOOL0667</instrument>
% //<subject>SDN:LOCAL:Salinity</subject><object>SDN:P01::PSLTZZ01</object><units>SDN:P06::UUUU</units><instrument>SDN:L22::TOOL0667</instrument>
% //
% Cruise  Station Type    yyyy-mm-ddThh:mm:ss.sss Longitude [degrees_east]        Latitude [degrees_north]        LOCAL_CDI_ID    EDMO_code       Bot. Depth [m]  Depth [m]       QV:SEADATANET   temperature [Degrees Celsius]   QV:SEADATANET   Salinity [Dimensionless]        QV:SEADATANET
% ID_campanya     1       *       2022-09-11T11:59:45     -9.3182015      38.3465165      ID      2489            4       1       20.0852 2       35.8275 2
% ...
% ... donde ID_campanya: pati-cientific_20210205 & ID: pati-cientific_20210205_ts
% ...

% 	Latitude	Longitude	Mdept [m]
% TD1	41.3856 N	2.2099 E	23
% TD2	41.3798 N	2.1986 E	12
% TD3	41.3749 N	2.1951 E	10
% TD4	41.3806 N	2.2029 E	20
% TD5	41.3785 N	2.2084 E	28
% TD6	41.3757 N	2.2162 E	28


clear all
close all

addpath('/home/nina/Escritorio/WORK/Programs/matlab_prog/')
addpath('/home/nina/Escritorio/WORK/Programs/matlab_prog/teos10/')
addpath('/home/nina/Escritorio/WORK/Programs/matlab_prog/teos10/library/')
addpath('/home/nina/Escritorio/WORK/PatiCientific/programs/')

%% ... Open file and get raw data ...
% ...
td_station = input('enter TD station file to be process (ex: 20210728_TDX): ','s');
iyy = td_station(1:4)
imm = td_station(5:6)
numtd = td_station(12)

ifile = sprintf('%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/SPV/SeaWater/Profile/TD_v00/RAW/',iyy,'/',imm,'/',td_station,'.DAT');
ofile = sprintf('%s%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/SPV/SeaWater/SeaDataNet_Format/Profile/RAW/TD/TD_raw_',td_station);

LatitudeID = ['41.3856'; '41.3798'; '41.3749'; '41.3806'; '41.3785'; '41.3757'];
LongitudeID = ['002.2099'; '002.1986'; '002.1951'; '002.2029'; '002.2084'; '002.2162'];

Latitude = LatitudeID(str2num(numtd),:) 
Longitude = LongitudeID(str2num(numtd),:)

% ... check if input file to be processed exists ...
if exist(ifile,'file')
    fprintf('%s%s\n','Read data file : ',ifile)
else
    fprintf('%s%s%s\n',' Impossible to Open ',ifile,' DO NOT exist !!')
    return
end

A = importdata(ifile);
dateA = cell2mat(A.textdata(4:end,:));
yy = str2num(dateA(:,1:4));
mm = str2num(dateA(:,6:7));
dd = str2num(dateA(:,9:10));
HH = str2num(dateA(:,11:12));
MM = str2num(dateA(:,14:15));
SS = str2num(dateA(:,17:18));

% ... In case of Time problemes ...
% yy=yy+21;
% mm=mm+6;
% dd=dd+16;
% HH = HH-12;

mTime=datenum(yy,mm,dd,HH,MM,SS);
Time = datetime(mTime,'convertfrom','datenum');
sTime = datestr(mTime,'yyyymmddTHHMMSS');


for i = 1:length(yy)
    sTimeOK(i,:) = sprintf('%s',sTime(i,1:4),'-',sTime(i,5:6),'-',sTime(i,7:8),sTime(i,9:11),':',sTime(i,12:13),':',sTime(i,14:end));
end

Pressure = A.data(:,1);
Temperature = A.data(:,3);   % Get the t_tsys01 sensor value
nm   = A.data(:,4);          % Number of measures from the sensor

% ... Calculate the depth associated to the Pressure value
% ...
Depth = Pressure*zeros;   % Initialize Depth to zero
for i=1:size(nm)
    z = gsw_z_from_p(Pressure(i),str2num(Latitude));   % ... funcion from TEOS 10
    Depth(i) = round(abs(z),4); % rounds to 4 decimal places
end

%% ... QC from SeaDataNet ...
% ... All value = 0 as their are still RAW data ...
% ...
QF_Pressure = abs(Pressure*zeros); % Pressure flag initialized to 0
QF_Temperature = abs(Temperature*zeros); % Temperature flag initialized to 0
QF_Depth = abs(Depth*zeros); % Depth Flag initialized to 0

%% ... Add SeaDataNet columns ...
% ... Cruise  Station Type Latitude Longitude
Cruise = sprintf('%s%s','pati-cientific_',td_station);
toto = blanks(length(Cruise));
for i = 1:length(mTime)-1
    Cruise = [Cruise; toto];
end

clear toto
Station = numtd;
toto = blanks(length(Station));
for i = 1:length(mTime)-1
    Station = [Station; toto];
end

clear toto
Type = 'TD_v00';
toto = blanks(length(Type));
for i = 1:length(mTime)-1
    Type = [Type; toto];
end

clear toto
toto = blanks(length(Latitude));
for i = 1:length(mTime)-1
    Latitude = [Latitude; toto];
end

clear toto
toto = blanks(length(Longitude));
for i = 1:length(mTime)-1
    Longitude = [Longitude; toto];
end

clear toto
LOCAL_CDI_ID = td_station;
toto = blanks(length(LOCAL_CDI_ID));
for i = 1:length(mTime)-1
    LOCAL_CDI_ID = [LOCAL_CDI_ID; toto];
end

clear toto
EDMO_code = num2str(2489);
toto = blanks(length(EDMO_code));
for i = 1:length(mTime) - 1
    EDMO_code = [EDMO_code; toto];
end

BotDepth = EDMO_code;
BotDepth(1) = blanks(length(BotDepth(1)));

%% CREATE TimeTable to Write output in ODV .txt files
% ...
TD_raw = table(Cruise,Station,Type,sTimeOK,Longitude,Latitude,LOCAL_CDI_ID,EDMO_code,BotDepth,Depth,QF_Depth,Pressure,QF_Pressure,Temperature,QF_Temperature);

writetable(TD_raw,sprintf('%s%s',ofile,'.txt'),'Delimiter','\t');   % txt file with struct of matlab

return