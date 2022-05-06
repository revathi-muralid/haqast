%% Documentation

% runme_PM25_v01.m

clear; clc; close all; tic;

% M. Omar Nawaz
% July 12, 2020

% Notes: This script is the driver function for the health impacts
% analysis from PM2.5, looping through different health outcomes and
% exposure datasets.

%% Input and Load

% Settings
%Type  = 1; % 1 - Regular Run, 2 - Concentration Excluded, 3 - Concentration Only
%Input = 4; % 1 - BME, 2 - NACR, 3 - Old Sat, 4 - New Sat

for Type = 3:3
    for Input = 1:4

loadme_PM25_v01

%% Mortality Analysis
for i = loop{Input}
    
    for k = 1:7
        [IHD(:,:,i,k)   , IHDLB(:,:,i,k)   , IHDUB(:,:,i,k)]    = get_PM25(CDCIHD{k,i},PopGrid{i},PM25{i},'cvd_ihd',Age(k),i,Type,Input);
        [STROKE(:,:,i,k), STROKELB(:,:,i,k), STROKEUB(:,:,i,k)] = get_PM25(CDCSTROKE{k,i},PopGrid{i},PM25{i},'cvd_stroke',Age(k),i,Type,Input);
    end
    
        [COPDMORT(:,:,i),COPDMORTLB(:,:,i),COPDMORTUB(:,:,i)] = get_PM25(CDCCOPD{i},PopGrid{i},PM25{i},'resp_copd',0,i,Type,Input);
        [LCMORT(:,:,i),LCMORTLB(:,:,i),LCMORTUB(:,:,i)] = get_PM25(CDCLC{i},PopGrid{i},PM25{i},'neo_lung',0,i,Type,Input);
    toc
end

IHDMORTUB    = sum(IHDUB,4);
IHDMORT      = sum(IHD,4); 
IHDMORTLB    = sum(IHDLB,4);
STROKEMORTUB = sum(STROKEUB,4);
STROKEMORT   = sum(STROKE,4);
STROKEMORTLB = sum(STROKELB,4);

PMMORT   = IHDMORT + STROKEMORT + COPDMORT + LCMORT;
PMMORTLB = IHDMORTLB + STROKEMORTLB + COPDMORTLB + LCMORTLB;
PMMORTUB = IHDMORTUB + STROKEMORTUB + COPDMORTUB + LCMORTUB;

%% State Calculation
for i = loop{Input}
for q = 1:51
    
% Regular
temp = IHDMORT(:,:,i);
IHDSTATE(q,i) = sum(temp((in(:,:,q)')==1));
temp = STROKEMORT(:,:,i);
STROKESTATE(q,i) = sum(temp((in(:,:,q)')==1));
temp = COPDMORT(:,:,i);
COPDSTATE(q,i) = sum(temp((in(:,:,q)')==1));
temp = LCMORT(:,:,i);
LCSTATE(q,i) = sum(temp((in(:,:,q)')==1));

% Upper
temp = IHDMORTUB(:,:,i);
IHDSTATEUB(q,i) = sum(temp((in(:,:,q)')==1));
temp = STROKEMORTUB(:,:,i);
STROKESTATEUB(q,i) = sum(temp((in(:,:,q)')==1));
temp = COPDMORTUB(:,:,i);
COPDSTATEUB(q,i) = sum(temp((in(:,:,q)')==1));
temp = LCMORTUB(:,:,i);
LCSTATEUB(q,i) = sum(temp((in(:,:,q)')==1));

% Lower
temp = IHDMORTLB(:,:,i);
IHDSTATELB(q,i) = sum(temp((in(:,:,q)')==1));
temp = STROKEMORTLB(:,:,i);
STROKESTATELB(q,i) = sum(temp((in(:,:,q)')==1));
temp = COPDMORTLB(:,:,i);
COPDSTATELB(q,i) = sum(temp((in(:,:,q)')==1));
temp = LCMORTLB(:,:,i);
LCSTATELB(q,i) = sum(temp((in(:,:,q)')==1));

end
end

PMSTATE = IHDSTATE + STROKESTATE + COPDSTATE + LCSTATE;
PMSTATELB = IHDSTATELB + STROKESTATELB + COPDSTATELB + LCSTATELB;
PMSTATEUB = IHDSTATEUB + STROKESTATEUB + COPDSTATEUB + LCSTATEUB;

saveme_PM25_v01

    end
end