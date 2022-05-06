%% Documentation

%loadme_PM25_v01.m

% M. Omar Nawaz
% July 12, 2020

% Notes: This script loads in the relevant input data to calculate the
% health impacts.

%% Section One - Assignments, Initializations, Directories, Filenames

% (1) Assignments
Age  = [25 35 45 55 65 75 85];
loop = {1:18,11:17,1:13,2:18};

% (2) Initializations
% (a) General
PM25       = cell(18,1);
% (b) Gridded Health Impacts
COPDMORT   = zeros(265,442,18); 
IHD        = zeros(265,442,18);
LCMORT     = zeros(265,442,18); 
STROKE     = zeros(265,442,18);
COPDMORTLB = zeros(265,442,18); 
IHDLB      = zeros(265,442,18);
LCMORTLB   = zeros(265,442,18); 
STROKELB   = zeros(265,442,18);
COPDMORTUB = zeros(265,442,18); 
IHDUB      = zeros(265,442,18);
LCMORTUB   = zeros(265,442,18); 
STROKEUB   = zeros(265,442,18);
% (c) State Health Impacts
COPDSTATE     = zeros(56,18); 
IHDSTATE      = zeros(56,18);
LCSTATE       = zeros(56,18); 
STROKESTATE   = zeros(56,18);
COPDSTATELB   = zeros(56,18); 
IHDSTATELB    = zeros(56,18);
LCSTATELB     = zeros(56,18); 
STROKESTATELB = zeros(56,18);
COPDSTATEUB   = zeros(56,18); 
IHDSTATEUB    = zeros(56,18);
LCSTATEUB     = zeros(56,18); 
STROKESTATEUB = zeros(56,18);

% (3) Directories
base_dir = '/Users/omar/Desktop/Research/Projects/HEALTH/';
data_dir = [base_dir,'data/'];
cdc_dir  = [data_dir,'CDC/'];
pop_dir  = [data_dir,'population/'];
pm_dir   = [data_dir,'pm25/'];
othe_dir = [data_dir,'other/'];

%% Section Two - Load CDC + General Data

% (1) General Data
% (a) .mat files
load([othe_dir,'in.mat'],'in');
data = readtable([othe_dir,'parameter_draws.csv']);

%Load CDC IHD data
for i = 1:7
    clear CDCDATA
    load([cdc_dir,sprintf('IHD/IHD%0.0fDATA.mat',Age(i))])
    for j = 1:18
        x=find(CDCDATA.Year==1998+j);
        CDCIHD{i,j} = [CDCDATA.County(x) CDCDATA.Population(x) CDCDATA.CrudeRate(x) CDCDATA.Deaths(x)];
    end
end

%Load CDC STROKE data
for i = 1:7
    clear CDCDATA
    load([cdc_dir,sprintf('STROKE/STROKE%0.0fDATA.mat',Age(i))])
    for j = 1:18
        x=find(CDCDATA.Year==1998+j);
        CDCSTROKE{i,j} = [CDCDATA.County(x) CDCDATA.Population(x) CDCDATA.CrudeRate(x) CDCDATA.Deaths(x)];
    end
end

%Load CDC COPD data
clear CDCDATA
load([cdc_dir,'COPD/COPDDATA.mat'])
CDCCOPD = cell(18,1);

for i = 1:18
      x=find(CDCDATA.Year==1998+i);
      xt{i} = x;
      CDCCOPD{i} = [CDCDATA.County(x) CDCDATA.Population(x) CDCDATA.CrudeRate(x) CDCDATA.Deaths(x)];
end

%Load CDC LC data
clear CDCDATA
load([cdc_dir,'LC/LCDATA.mat'])
CDCLC = cell(18,1);

for i = 1:18
      x=find(CDCDATA.Year==1998+i);
      CDCLC{i} = [CDCDATA.County(x) CDCDATA.Population(x) CDCDATA.CrudeRate(x) CDCDATA.Deaths(x)];
end


%% Load in landscan population for density

%Load Population Data
for i = 1:18
     if i == 1; ystr = '2000'; else; ystr = num2str(2000+i-2); end 
     filename = [pop_dir,'v2_USLS',ystr,'Agg5Pop.nc'];
     PopGrid{i} = ncread(filename,'population');
end

%% Load in PM2.5 Data

if     Input == 1
    
%BME
for i = 1999:2016
load(sprintf([pm_dir,'BME/BME%d'],i));
PM25{i-1998} = BME_Grid;
end

elseif  Input == 2

%NACR
for i = 2009:2015
PM25{10+i-2008} = ncread(sprintf([pm_dir,'NACR/PMavg%d.nc'],i),'PM25')';
end

elseif Input == 3

%SAT
PM25{1} = ncread([pm_dir,'SAT/PM1999Sat.nc'],'concentration');  
for i = 2:11
      filename = [pm_dir,sprintf('SAT/PM200%dSat.nc',i-2)]; %Normal
      PM25{i} = ncread(filename,'concentration');
end
for i = 12:13
      filename = [pm_dir,sprintf('SAT/PM20%dSat.nc',i-2)]; %Normal
      PM25{i} = ncread(filename,'concentration');
end

elseif Input == 4
    
% New SAT
for i = 2:18
      filename = [pm_dir,'NEWSAT/PM25_',num2str(i+1998),'_SAT.nc'];
      PM25{i} = ncread(filename,'concentration');
end

end

%% Control for different runs

if     Type == 1 % Regular Run
elseif Type == 2 % Excluded
    if     Input == 1
        for i = 2:18;  PM25{i} = PM25{ 1}; end
    elseif Input == 2
        for i = 12:17; PM25{i} = PM25{11}; end
    elseif Input == 3
        for  i = 2:13; PM25{i} = PM25{ 1}; end
    elseif Input == 4
        for i = 3:18;  PM25{i} = PM25{ 2}; end
    end
elseif Type == 3 % Only
    if     Input == 1
        for i = 2:18
        for j = 1:7
        CDCIHD{j,i}     = CDCIHD{j,1};
        CDCSTROKE{j,i}  = CDCSTROKE{j,1};
        end
        CDCCOPD{i}      = CDCCOPD{1};
        CDCLC{i}        = CDCLC{1};
        PopGrid{i}      = PopGrid{1};
        end
    elseif Input == 2
        for i = 12:17
        for j = 1:7
        CDCIHD{j,i}     = CDCIHD{j,11};
        CDCSTROKE{j,i}  = CDCSTROKE{j,11};        
        end
        CDCCOPD{i}      = CDCCOPD{ 11};
        CDCLC{i}        = CDCLC{ 11};
        PopGrid{i}      = PopGrid{11};
        end
    elseif Input == 3
        for i = 2:13
        for j = 1:7
        CDCIHD{j,i}     = CDCIHD{j,1};
        CDCSTROKE{j,i}  = CDCSTROKE{j,1};
        end
        CDCCOPD{i}      = CDCCOPD{1};
        CDCLC{i}        = CDCLC{1};
        PopGrid{i}      = PopGrid{1};        
        end
    elseif Input == 4
        for i = 3:18
        for j = 1:7
        CDCIHD{j,i}     = CDCIHD{j,2};
        CDCSTROKE{j,i}  = CDCSTROKE{j,2};
        end
        CDCCOPD{i}      = CDCCOPD{2};
        CDCLC{i}        = CDCLC{2};
        PopGrid{i}      = PopGrid{2};
        end
    end
end
    