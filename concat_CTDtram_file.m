% ......................................
% ... Concatenate all CTD tram files ...
% ... Write it in new file .dat ...
% ......................................
% ... N. Hoareau, Marz 2022 ...
% ......................................



clear all
close all

addpath('/home/nina/Escritorio/WORK/Programs/matlab_prog/m_map/');
addpath('/home/nina/Escritorio/WORK/Programs/matlab_prog/');

cdate = '20230517'
year = str2num(cdate(1:4));
month = str2num(cdate(5:6));
dd = str2num(cdate(7:8));

%% ... List of TRAM files ...
% ...
pathfile = sprintf('%s%s%s','/home/nina/Escritorio/WORK/PatiCientific/data/SPV/SeaWater/Surface/CastAwayCTD/RAW/surface_sections/',cdate(1:4),'/',cdate(5:6),'/')
lfile = [pathfile,'tram_list.txt']
if ~exist(lfile,'file')
   disp('list of TRAM files does not exist')
   lfile
   return
end

fid = fopen(lfile);
C   = textscan(fid,'%s');
fclose(fid);
C{1}

ii = 1;
fi = ii;

for it=1:numel(C{1})
    %% ... Get CastAway CTD data (from Excel file) ...
    % ... To get the correct size for the position data ...
    ifile = cell2mat(C{1}(it));
    if ~exist([pathfile,ifile],'file')
        disp('CTD file does not exist')
        ifile
        return
    end
    
    [msg,head,data,ini]= read_sbe([pathfile,ifile]);
    [msg,ini,str] = read_par(ifile);
    
    %% ... Get initial time to convert sec of the file in correct time ...
    ihour = str2num(ifile(20:21))
    imin = str2num(ifile(22:23))
    isec = str2num(ifile(24:25))
    
    tref = datenum(year,month,dd,ihour,imin,isec)
    datestr(tref);
    
    % Assign variables to each data column
    tt = data(:,1);   % sec from Cast time info (UTC)
    Temp = data(:,3);   % deg C
    Cond = data(:,4);   % uS/cm
    Pres = data(:,2);   % dBar
    
    %Flag = tt*zeros;    % initialized to 0 (no checking)
    T = tt*zeros;
    
    % ... Need to average data each seconds ...
    % ... CTD data frequency is 1/5 sec-1 ...
    for i = 1:length(tt)
        T(i) = addtodate(tref,floor(tt(i)),'second'); % add integer part of seconds of ctd time 
    end
    
    Time = datetime(datestr(T));
    out = timetable(Time,Pres,Temp,Cond);
    outs = retime(out,'secondly','mean');
    
    if it==1
        CTD = outs;
    else
        CTD = [CTD;outs];
    end
    
    clear data tt ifile out outs Time Temp Cond T;
end

ofile = [pathfile,'10J101601_',cdate,'_all_tram.csv'];
writetable(timetable2table(CTD),ofile);   % txt file with struct of matlab
