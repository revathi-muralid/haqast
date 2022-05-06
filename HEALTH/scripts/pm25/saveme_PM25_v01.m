% Saves out Relevant Data from health impact run

%% Create name based on input and type
base_dir  = '/Users/omar/Desktop/Research/Projects/HEALTH/output/';
input_dir = {'BME_PM/','NACR_PM/','SAT_PM/','NSAT_PM/'};
type_dir  = {'Regular Run/','Concentration Change Excluded/','Concentration Change Only/'};
save_dir  = [base_dir,input_dir{Input},type_dir{Type}];

temp = {'R','E','O'};
in = input_dir{Input}(1);
ty = temp{Type};

%% Save regular data
save([save_dir,in,'_',ty,'_M_PM'],'PMMORT')
save([save_dir,in,'_',ty,'_SM_PM'],'PMSTATE')

save([save_dir,in,'_',ty,'_M_PM_COPD'],'COPDMORT');
save([save_dir,in,'_',ty,'_M_PM_IHD'],'IHDMORT');
save([save_dir,in,'_',ty,'_M_PM_LC'],'LCMORT');
save([save_dir,in,'_',ty,'_M_PM_STROKE'],'STROKEMORT');

save([save_dir,in,'_',ty,'_SM_PM_COPD'],'COPDSTATE');
save([save_dir,in,'_',ty,'_SM_PM_IHD'],'IHDSTATE');
save([save_dir,in,'_',ty,'_SM_PM_LC'],'LCSTATE');
save([save_dir,in,'_',ty,'_SM_PM_STROKE'],'STROKESTATE');

%% Save Lower Bound
save([save_dir,'L',in,'_',ty,'_M_PM'],'PMMORTLB')
save([save_dir,'L',in,'_',ty,'_SM_PM'],'PMSTATELB')

save([save_dir,'L',in,'_',ty,'_M_PM_COPD'],'COPDMORTLB');
save([save_dir,'L',in,'_',ty,'_M_PM_IHD'],'IHDMORTLB');
save([save_dir,'L',in,'_',ty,'_M_PM_LC'],'LCMORTLB');
save([save_dir,'L',in,'_',ty,'_M_PM_STROKE'],'STROKEMORTLB');

save([save_dir,'L',in,'_',ty,'_SM_PM_COPD'],'COPDSTATELB');
save([save_dir,'L',in,'_',ty,'_SM_PM_IHD'],'IHDSTATELB');
save([save_dir,'L',in,'_',ty,'_SM_PM_LC'],'LCSTATELB');
save([save_dir,'L',in,'_',ty,'_SM_PM_STROKE'],'STROKESTATELB');

%% Save Upper Bound
save([save_dir,'U',in,'_',ty,'_M_PM'],'PMMORTUB')
save([save_dir,'U',in,'_',ty,'_SM_PM'],'PMSTATEUB')

save([save_dir,'U',in,'_',ty,'_M_PM_COPD'],'COPDMORTUB');
save([save_dir,'U',in,'_',ty,'_M_PM_IHD'],'IHDMORTUB');
save([save_dir,'U',in,'_',ty,'_M_PM_LC'],'LCMORTUB');
save([save_dir,'U',in,'_',ty,'_M_PM_STROKE'],'STROKEMORTUB');

save([save_dir,'U',in,'_',ty,'_SM_PM_COPD'],'COPDSTATEUB');
save([save_dir,'U',in,'_',ty,'_SM_PM_IHD'],'IHDSTATEUB');
save([save_dir,'U',in,'_',ty,'_SM_PM_LC'],'LCSTATEUB');
save([save_dir,'U',in,'_',ty,'_SM_PM_STROKE'],'STROKESTATEUB');
