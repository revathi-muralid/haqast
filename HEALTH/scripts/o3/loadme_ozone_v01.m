%% Documentation

%loadme_o3_v01.m

% M. Omar Nawaz
% July 14, 2020

% Notes: This script loads in the relevant input data to calculate the
% health impacts.

%% Section One - Assignments, Initializations, Directories, Filenames

% (1) Assignments
CRF = [1.040 1.010  1.067];
if Input == 1; year_0 = 2010; else; year_0 = 2009; end
    
% (2) Initializations
COPDMORT  = zeros(265,442,8); 
RESPMORT  = zeros(265,442,8);
COPDSTATE = zeros(56,7); 
RESPSTATE = zeros(56,7); 
POPWEIGHT = zeros(1,7);
CDCCOPD   = cell(8,1);
CDCRESP   = cell(8,1);
PopGrid   = cell(8,1);
xt        = cell(8,1);
Ozone     = cell(8,1);

% (3) Directories
base_dir = '/Users/omar/Desktop/Research/Projects/HEALTH/';
data_dir = [base_dir,'data/'];
cdc_dir  = [data_dir,'CDC/'];
pop_dir  = [data_dir,'population/'];
othe_dir = [data_dir,'other/'];
o3_dir   = [data_dir,'o3/'];


%% Section Two - Load CDC + General Data

% (1) General Data
% (a) .mat files
load([othe_dir,'in.mat'],'in');

% Load CDC Mortality Rates
% COPD
load([cdc_dir,'COPD/COPDDATA.mat'])

for i = 1:8
    
    if Type == 3
        x = find(CDCDATA.Year==year_0);
    else
        x = find(CDCDATA.Year==2008+i);
    end
    
    xt{i} = x;
    
    CDCCOPD{i} = [CDCDATA.County(x) CDCDATA.Population(x) ...
                  CDCDATA.CrudeRate(x) CDCDATA.Deaths(x)];
end

load([cdc_dir,'RESP/RESPDATA.mat'])
% RESP
for i = 1:8
    
    if Type == 3
        x = find(CDCDATA.Year==year_0);
    else
        x = find(CDCDATA.Year==2008+i);
    end
    
    xt{i} = x;
    
    CDCRESP{i} = [CDCDATA.County(x) CDCDATA.Population(x) ...
                  CDCDATA.CrudeRate(x) CDCDATA.Deaths(x)];
end

%Load Population Data
for i = 1:8
     ystr = num2str(2010+i-2);
     if Type == 3
        filename = [pop_dir,'v2_USLS',num2str(year_0),'Agg5Pop.nc'];
     else
        filename = [pop_dir,'v2_USLS',ystr,'Agg5Pop.nc'];
     end
     PopGrid{i} = ncread(filename,'population');
end

%% Load In Ozone Data

if Input == 1 % BME
    
    for i = 2:7
        
        if Type == 2
            filename = [o3_dir,'BME/2010MAP.nc'];
        else
            filename = [o3_dir,'BME/',num2str(i+2008),'MAP.nc'];
        end
        
        Ozone{i} = ncread(filename,'concentration') * 1E6;
        
    end
    
    Ozone{1} = zeros(265,442); Ozone{8} = zeros(265,442);
    
else % NACR
    
        for i = 1:8
        
        if Type == 2
            filename = [o3_dir,'NACR/ozone6m2009.nc'];
        else
            filename = [o3_dir,'NACR/ozone6m',num2str(i+2008),'.nc'];
        end
        
        Ozone{i} = ncread(filename,'Ozone')';
        
        end
    
end
