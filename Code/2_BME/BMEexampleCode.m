
% create the soft data using soft data values & associated variance
% can also use probaUniform or probaStudentT depending on desired distribution
[softpdftype,nl,limi,probdens]=probaGaussian(softdata,softdata_var); 

% get the lons and lats from the Tong WRF grid



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
