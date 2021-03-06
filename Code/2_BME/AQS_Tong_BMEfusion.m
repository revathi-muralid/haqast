
% get the lons and lats from the Tong WRF grid

filename='chaq/revathi/EPA_21yr_CMAQ/6moDaily1hrMaxO3/CMAQ_O3_monthly_Regridded_36km_to_12km_199005.nc';

gridfile='chaq/revathi/CONUS12_444x336.ncf' % this is the grid the estimates need to be on

ncdisp(filename);

o3_old=ncread(filename, 'O3');
lon=double(ncread(filename, 'lon2d'));
lat=double(ncread(filename, 'lat2d'));

o3 = double(o3_old);

% pk = estimation grid, or whatever XYT coords the final BME estimates are
% on
% soft_data_xyt_coords / softpdftype / nl / limi / probdens is EPA data in a 3D format
% xyt_coords/hard_data is from AQS
% [softpdftype,nl,limi,probdens] = probaGaussian(softdata,softdata_var) -
% function used to get variables above, where softdata = CMAQ values and
% softdata_var = variance/uncertainty associated with CMAQ values

hardname = '/nas/longleaf/home/revathi/HAQAST/thesis/BME_Final_withGrid/2_preprocessed/BMEAnalyticAQSHardData_NoDate.csv'
softname = '/nas/longleaf/home/revathi/HAQAST/thesis/BME_Final_withGrid/2_preprocessed/BMEAnalyticEPASoftData.csv'

% Code to convert data into BME-readable file
softtab = readtable(softname);
hardtab = readtable(hardname);

softarr=table2array(softtab);
hardarr=table2array(hardtab);
%writeGeoEAS(B,["state","county","ID","station_lon","station_lat","mda8_1990","mda8_1991","mda8_1992","mda8_1993","mda8_1994","mda8_1995","mda8_1996","mda8_1997","mda8_1998","mda8_1999","mda8_2000","mda8_2001","mda8_2002","mda8_2003","mda8_2004","mda8_2005","mda8_2006","mda8_2007","mda8_2008","mda8_2009","mda8_2010","mda8_2011","mda8_2012","mda8_2013","mda8_2014","mda8_2015","mda8_2016","mda8_2017"],'MDA8 O3 Annual Averages, 1999-2017, stg','MDA8_USA_O3_yearly_1999-2017.txt');

hard_data=hardarr(:,4);

% create the soft data using soft data values & associated variance
% can also use probaUniform or probaStudentT depending on desired distribution
[softpdftype,nl,limi,probdens]=probaGaussian(softdata,softdata_var); 

% create BME estimates using both hard data and soft data
[moments,info]=BMEprobaMoments(pk, xyt_coords,...
    soft_data_xyt_coords, hard_data, softpdftype, nl,...
    limi, probdens, covmodel,...
    covmodel, covparam, nhmax, nsmax, dmax, order, options);

zk=moments(:,1);    % Expected value of the estimated variable
vk=moments(:,2);    % Posterior variance of the estimated variable

% NOTE 1: you can also skip probaGaussian + BMEprobaMoments and use krigingME directly 
%         I have found this approach to be faster, but I think default assumes a gaussian distribution
%         zk = estimated value at pk, vk = associated variance
%   e.g. [zk,vk]=krigingME(pk,xyt_coords, soft_data_xyt_coords,...
%            hard_data,softdata,softdata_var,...
%            covmodel,covparam,nhmax,nsmax,dmax,...
%            order,options);

% NOTE 2: be sure to adjust nhmax, nsmax, and dmax depending on how much
%         influence you want the hard/soft data to have on the estimate

% NOTE 3: If you're using a global offset (so hard and soft data have a global offset removed)
%         you'll need to add the global offset back to zk and vk after BMEprobaMoments/krigingME


% run a leave-one-out cross-validation
[momentsXval,info,MSE,MAE,ME]=BMEprobaMomentsXvalidation(1,xyt_coords,...
    soft_data_xyt_coords, hard_data, softpdftype, nl,...
    limi, probdens, covmodel,...
    covmodel, covparam, nhmax, nsmax, dmax, order, options);

% NOTE 4: BMEprobaMomentsXvalidation can be modifed to use the quicker krigingME approach outlined above
%         I have this code, so let me know if you want it
