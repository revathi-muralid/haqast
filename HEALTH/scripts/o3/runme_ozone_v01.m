%% Documentation

% runme_ozone_v01.m

clear; clc; close all; tic;

% M. Omar Nawaz
% July 12, 2020

% Notes: This script is the driver function for the health impacts
% analysis from O3, looping through different health outcomes and
% exposure datasets.

%% Settings

Type  = 1; % 1 - Regular, 2 - Excluded, 3 - Only
Input = 2; % 1 - BME, 2 - NACR

%% Load Data

loadme_ozone_v01

%% Mortality Analysis

% Calculate Health Impacts
for i = 1:8
    tic
    [COPDMORT(:,:,i),COPDMORTLB(:,:,i),COPDMORTUB(:,:,i)] ...
        = get_Ozone_v01(CDCCOPD{i},PopGrid{i},Ozone{i},CRF,i,Type,Input);
    [RESPMORT(:,:,i),RESPMORTLB(:,:,i),RESPMORTUB(:,:,i)] ...
        = get_Ozone_v01(CDCRESP{i},PopGrid{i},Ozone{i},CRF,i,Type,Input);
    toc
end

%% State Calculation
for i = 1:8
for q = 1:51
    
% Regular
temp = COPDMORT(:,:,i);
COPDSTATE(q,i) = sum(temp((in(:,:,q)')==1));
temp = RESPMORT(:,:,i);
RESPSTATE(q,i) = sum(temp((in(:,:,q)')==1));

% Upper
temp = COPDMORTUB(:,:,i);
COPDSTATEUB(q,i) = sum(temp((in(:,:,q)')==1));
temp = RESPMORTUB(:,:,i);
RESPSTATEUB(q,i) = sum(temp((in(:,:,q)')==1));

% Lower
temp = COPDMORTLB(:,:,i);
COPDSTATELB(q,i) = sum(temp((in(:,:,q)')==1));
temp = RESPMORTLB(:,:,i);
RESPSTATELB(q,i) = sum(temp((in(:,:,q)')==1));

end
end

O3MORT   = COPDMORT   + RESPMORT;   O3STATE   = COPDSTATE   + RESPSTATE;
O3MORTLB = COPDMORTLB + RESPMORTLB; O3STATELB = COPDSTATELB + RESPSTATELB;
O3MORTUB = COPDMORTUB + RESPMORTUB; O3STATEUB = COPDSTATEUB + RESPSTATEUB;

% Save Output
saveme_ozone_v01
