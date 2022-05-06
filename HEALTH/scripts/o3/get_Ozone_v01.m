%NACR Analysis
function [MORT,MORTLB,MORTUB] = get_Ozone_v01(CDC,PopGrid,ozone,RRC,yr,Type,Input)

%Load surrogate file
Surrogate = dlmread('/Users/Omar/Desktop/Research/Health_Impacts/Surrogate_File.csv');
%Load 6-month 8 hour max Ozone Data
oz1850 = ncread('/Users/Omar/Desktop/Research/Health_Impacts/Ozone_Data/Background_Ozone.nc','Ozone');

%Assign surrogate data to appropriate variables
County = Surrogate(:,5);
Row = Surrogate(:,2);
Column = Surrogate(:,1);
Fraction = Surrogate(:,6);

%Assign CDC data to appropriate variables
CountyCDC = CDC(:,1);
PopulationCDC = CDC(:,2);
CrudeRate = CDC(:,3);
DeathsCDC = CDC(:,4);

%Crude Rate Calculation
CrudeRate = CrudeRate*1*10^-5;

%Reorient emission files
oz1850=rot90(oz1850,3); oz1850 = oz1850*10^-3; 
ozone=fliplr(rot90(ozone,3));

%Dimension, Assigning and Initialization
%Dimensions
UniqueCounty = unique(County);
[r,s] = size(ozone); 
t = length(County);
n = length(CountyCDC);
nx = length(UniqueCounty);

%Assignment
CRF = log(RRC)/10; %Assign concentration-response fraction

%Initialization
MORT   = zeros(r,s); 
MORTLB = zeros(r,s); 
MORTUB = zeros(r,s); 
CRUDE  = zeros(r,s);
COUNTY = zeros(r,s);
POP    = zeros(r,s);

%CDC Data Correction

CRUDE = CRUDE';

%Distributes Crude Rate
for i = 1:n
    x = CountyCDC(i);
    temp1 = Row(x==County);
    temp2 = Column(x==County);
    temp3 = Fraction(x==County);
    for j = 1:length(temp1)
        if temp3(j) == 1
            CRUDE(temp1(j),temp2(j)) = CrudeRate(i);
        else
            CRUDE(temp1(j),temp2(j)) = CRUDE(temp1(j),temp2(j)) + temp3(j).*CrudeRate(i);
        end
    end
end

if Type == 3
    
if Input == 1; v = 2; elseif Input == 2; v = 1; end

load(['/Users/omar/Desktop/Research/Projects/HEALTH/data/adjusted_rates/RE_POP_',num2str(v+2008),'.mat'])


else
    
load(['/Users/omar/Desktop/Research/Projects/HEALTH/data/adjusted_rates/RE_POP_',num2str(yr+2008),'.mat'])


end

CRUDE = CRUDE'; POP = POP';
DelX = (ozone-0.0376) * 10^3;

%Calculates Mortality

for dx = 1:r
    for dy = 1:s
        if POP(dx,dy)   ==  0; continue; end
        if CRUDE(dx,dy) ==  0; continue; end
        AF = 1-exp(-CRF(1)*(DelX(dx,dy)));
        MORT(dx,dy)= CRUDE(dx,dy)*AF*POP(dx,dy);
        AF = 1-exp(-CRF(2)*(DelX(dx,dy)));
        MORTLB(dx,dy)= CRUDE(dx,dy)*AF*POP(dx,dy);
        AF = 1-exp(-CRF(3)*(DelX(dx,dy)));
        MORTUB(dx,dy)= CRUDE(dx,dy)*AF*POP(dx,dy);
    end
end


MORT = MORT';
MORTLB = MORTLB';
MORTUB = MORTUB'; 

end
