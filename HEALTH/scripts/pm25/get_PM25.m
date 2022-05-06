%NACR Analysis
function [MORT,MORT_L,MORT_U] = get_PM25(CDC,PopGrid,PM25,DiseaseIN,AgeIN,year,Type,Input)
%Edit function for central estimate

% Directories
base_dir = '/Users/omar/Desktop/Research/Projects/HEALTH/';
data_dir = [base_dir,'data/'];
rate_dir = [data_dir,'adjusted_rates/'];
othe_dir = [data_dir,'other/'];

        data = readtable([othe_dir,'parameter_draws.csv']);
        data2 = table2array(data(:,[1:5,7]));
        Disease = data{:,6};
        
        if AgeIN>0
            ind = find( (data2(:,6)==AgeIN) .* strcmp(DiseaseIN,Disease));
        else
            ind = find(strcmp(DiseaseIN,Disease));
        end
        
        alpha = (data2(ind,2));
        beta  = (data2(ind,3));
        rho   = (data2(ind,4));
        zcf   = (data2(ind,5));
        
        Concentration = linspace(0,max(PM25(:)),1000);
        
        RRt       = ones(1000,length(Concentration));
        for k = 1:1000
        for l = 1:length(Concentration)
        if Concentration(l) < zcf(k); continue; end
        RRt(k,l) = 1 + alpha(k) .* ( 1 - exp( -beta(k) .* ( Concentration(l) - zcf(k) ) .^ rho(k) ) );
        end
        end
        RR = squeeze(mean(RRt,1));

        RRs = sort(RRt);
        RR_L = RRs(25,:);
        RR_U = RRs(975,:);

% Assignment
[r,s] = size(PM25); 

%Initialization
MORT = zeros(r,s);
MORT_L = zeros(r,s);
MORT_U = zeros(r,s);

if Type == 3
    
if Input == 1; v = 1; elseif Input == 2; v = 11; elseif Input == 3; v = 1; elseif Input == 4; v = 2; end

load([rate_dir,'RE_CRUDE_',num2str(v+1998),'_',num2str(AgeIN),'_',DiseaseIN],'CRUDE');
load([rate_dir,'RE_POP_',num2str(v+1998),'_',num2str(AgeIN)],'POP');

else
    
load([rate_dir,'RE_CRUDE_',num2str(year+1998),'_',num2str(AgeIN),'_',DiseaseIN],'CRUDE');
load([rate_dir,'RE_POP_',num2str(year+1998),'_',num2str(AgeIN)],'POP');

end

%Calculates Mortality
for dx = 1:r
    for dy = 1:s
        if POP(dx,dy) == 0; continue; end
        if CRUDE(dx,dy) == 0; continue; end
        [~,y] = min(abs(PM25(dx,dy)-Concentration));
        AF = 1 - 1/RR(y);
        MORT(dx,dy)= CRUDE(dx,dy).*AF.*POP(dx,dy);
        AF = 1 - 1/RR_L(y);
        MORT_L(dx,dy)= CRUDE(dx,dy).*AF.*POP(dx,dy);
        AF = 1 - 1/RR_U(y);
        MORT_U(dx,dy)= CRUDE(dx,dy).*AF.*POP(dx,dy);
    end
end



end
