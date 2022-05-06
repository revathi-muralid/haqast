
%% Create name based on input and type
base_dir  = '/Users/omar/Desktop/Research/Projects/HEALTH/output/';
input_dir = {'BME_O3/','NACR_O3/'};
type_dir  = {'Regular Run/','Concentration Change Excluded/','Concentration Change Only/'};
save_dir  = [base_dir,input_dir{Input},type_dir{Type}];

temp = {'R','E','O'};
in = input_dir{Input}(1);
ty = temp{Type};

%% Save regular data
save([save_dir,in,'_',ty,'_M_O3'],'O3MORT')
save([save_dir,in,'_',ty,'_SM_O3'],'O3STATE')

save([save_dir,in,'_',ty,'_M_O3_COPD'],'COPDMORT');
save([save_dir,in,'_',ty,'_M_O3_RESP'],'RESPMORT');

save([save_dir,in,'_',ty,'_SM_O3_COPD'],'COPDSTATE');
save([save_dir,in,'_',ty,'_SM_O3_RESP'],'RESPSTATE');

%% Save Lower Bound
save([save_dir,'L',in,'_',ty,'_M_O3'],'O3MORTLB')
save([save_dir,'L',in,'_',ty,'_SM_O3'],'O3STATELB')

save([save_dir,'L',in,'_',ty,'_M_O3_COPD'],'COPDMORTLB');
save([save_dir,'L',in,'_',ty,'_M_O3_RESP'],'RESPMORTLB');

save([save_dir,'L',in,'_',ty,'_SM_O3_COPD'],'COPDSTATELB');
save([save_dir,'L',in,'_',ty,'_SM_O3_RESP'],'RESPSTATELB');

%% Save Upper Bound
save([save_dir,'U',in,'_',ty,'_M_O3'],'O3MORTUB')
save([save_dir,'U',in,'_',ty,'_SM_O3'],'O3STATEUB')

save([save_dir,'U',in,'_',ty,'_M_O3_COPD'],'COPDMORTUB');
save([save_dir,'U',in,'_',ty,'_M_O3_RESP'],'RESPMORTUB');

save([save_dir,'U',in,'_',ty,'_SM_O3_COPD'],'COPDSTATEUB');
save([save_dir,'U',in,'_',ty,'_SM_O3_RESP'],'RESPSTATEUB');
