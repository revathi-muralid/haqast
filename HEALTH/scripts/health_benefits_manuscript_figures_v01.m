%% Documentation

% health_benefits_manuscript_v1.m

clear; clc; close all; tic;

% M. Omar Nawaz
% July 12, 2020

% Notes: This script processes data from health benefit analysis and plots
% them for the figures in the manuscript.

%% Assignment, Initialization, Directories

% (1) Directories
base_dir = '/Users/omar/Desktop/Research/Projects/HEALTH/';
data_dir = [base_dir,'data/'];
pm25_dir = [data_dir,'pm25/'];
o3_dir   = [data_dir,'o3/'];
pop_dir  = [data_dir,'population/'];
othe_dir = [data_dir,'other/'];
mort_dir = [base_dir,'output/'];
out_dir  = [base_dir,'figures/'];

% (2) Assignment
ename = {'BME','NACR','NEWSAT','SAT'};
mname = {'Regular Run','Concentration Change Only', 'Concentration Change Excluded'};
i0    = [4; 6; 6; 3];

% (3) Initializations
PM25     = zeros(265, 442, 18, 4);
O3       = zeros(265, 442, 18, 4);
POP      = zeros(265, 442, 18);
PW_PM    = zeros(18, 4);
MORT_PM  = zeros(265, 442, 18, 4, 3);
MORT_PML = zeros(265, 442, 18, 4, 3);
MORT_PMU = zeros(265, 442, 18, 4, 3);
MORT_O3  = zeros(265, 442, 8, 4, 3);
MORT_O3L = zeros(265, 442, 8, 4, 3);
MORT_O3U = zeros(265, 442, 8, 4, 3);

%% Load Data

% (1) Load PM2.5 Data
% (a) .netcdf files
files = dir([pm25_dir,'*/*.nc']); flen = length(files);
for f = 1:flen
    eind     = find(strcmp(files(f).folder(56:end),ename));
    yr       = str2double(files(f).name(i0(eind):i0(eind)+3)) - 1998;
    filename = [files(f).folder,'/',files(f).name];
    I        = ncinfo(filename); iname = I.Variables.Name;
    temp = ncread(filename,iname); temp(isnan(temp)) = 0;
    try PM25(:,:,yr,eind) = temp'; catch; PM25(:,:,yr,eind) = temp; end
end
% (b) .mat files
files = dir([pm25_dir,'*/*.mat']); flen = length(files);
for f = 1:flen
    eind     = find(strcmp(files(f).folder(56:end),ename));
    yr       = str2double(files(f).name(i0(eind):i0(eind)+3)) - 1998;
    filename = [files(f).folder,'/',files(f).name]; load(filename);
    BME_Grid(isnan(BME_Grid)) = 0; PM25(:,:,yr,eind) = BME_Grid;
end

% (2) Load O3 Data
% (a) .netcdf files
files = dir([o3_dir,'*/*.nc']); flen = length(files); clear i0;
i0 = [1; 8];
for f = 1:flen
    eind     = find(strcmp(files(f).folder(54:end),ename));
    if eind == 1; fctr = 1E9; else fctr = 1E3; end
    yr       = str2double(files(f).name(i0(eind):i0(eind)+3)) - 1998;
    filename = [files(f).folder,'/',files(f).name];
    I        = ncinfo(filename); iname = I.Variables.Name;
    temp = ncread(filename,iname)*fctr; temp(isnan(temp)) = 0;
    try O3(:,:,yr,eind) = temp'; catch; O3(:,:,yr,eind) = temp; end
end

% (3) Load PM2.5 Mortality Data
ename = {'BME','NACR','NSAT','SAT'};
files = dir([mort_dir,'*/*/*PM.mat']); flen = length(files);
i0 = [1; 8];
for f = 1:flen
    names    = split(erase(erase(files(f).folder,...
        '/Users/omar/Desktop/Research/Projects/HEALTH/output/'),'_PM'),'/');
    eind     = find(strcmp(names{1},ename));
    mind     = find(strcmp(names{2},mname)); 
    filename = [files(f).folder,'/',files(f).name]; load(filename);
    if     files(f).name(1)=='L'
        MORT_PML(:,:,:,eind,mind) = PMMORTLB;
    elseif files(f).name(1)=='U'
        MORT_PMU(:,:,:,eind,mind) = PMMORTUB;
    else
        MORT_PM(:,:,:,eind,mind) = PMMORT;
    end
    
end

% (3) Load O3 Mortality Data
ename = {'BME','NACR'};
files = dir([mort_dir,'*/*/*O3.mat']); flen = length(files);
i0 = [2; 1];
for f = 1:flen
    names    = split(erase(erase(files(f).folder,...
        '/Users/omar/Desktop/Research/Projects/HEALTH/output/'),'_O3'),'/');
    eind     = find(strcmp(names{1},ename));
    mind     = find(strcmp(names{2},mname)); 
    filename = [files(f).folder,'/',files(f).name]; load(filename);
    if     files(f).name(1)=='L'
        MORT_O3L(:,:,:,eind,mind) = O3MORTLB;
    elseif files(f).name(1)=='U'
        MORT_O3U(:,:,:,eind,mind) = O3MORTUB;
    else
        MORT_O3(:,:,:,eind,mind) = O3MORT;
    end
    
end

% (3) Load Population Data
files = dir([pop_dir,'v2*.nc']); flen = length(files);
for f = 1:flen
    yr          = str2double(files(f).name(8:11)) - 1998;     
    filename    = [files(f).folder,'/',files(f).name];
    I           = ncinfo(filename); iname = I.Variables.Name;
    if yr > 18; continue; end
    POP(:,:,yr) = ncread(filename,iname)'; 
end

% (4) Load Other Files
load([othe_dir,'in.mat']);
LAT = double(ncread([othe_dir,'aqm.latlon.ncf'],'LAT'));
LON = double(ncread([othe_dir,'aqm.latlon.ncf'],'LON'));

%% General Processing

% no landscan population data is available for 1999, so replace with 2000
POP(:,:,1) = POP(:,:,2);
POP = POP .* sum(in,3)';
PM25 = PM25  .*sum(in,3)';
O3 = O3 .*sum(in,3)';

% calculate population weighted PM2.5
PW_PM           = squeeze(sum(POP .* PM25 ,1:2) ./ sum(POP,1:2));
M_PM            = sum(PW_PM')./sum(PW_PM'>0);
for yr = 1:18; for ds = 1:4; temp = PM25(:,:,yr,ds); ANN_PM(yr,ds) = mean(temp(temp>0)); end; end
MA_PM           = sum(ANN_PM') ./ sum(ANN_PM'>0);
ANN_PM(ANN_PM==0) = NaN; PW_PM(PW_PM==0) = NaN;

% calculate population weighted O3
PW_O3           = squeeze(sum(POP .* O3,1:2) ./ sum(POP,1:2));
M_O3            = sum(PW_O3')./sum(PW_O3'>0);
for yr = 1:18; for ds = 1:4; temp = O3(:,:,yr,ds); ANN_O3(yr,ds) = mean(temp(temp>0)); end; end
MA_O3           = sum(ANN_O3') ./ sum(ANN_O3'>0);
PW_O3(PW_O3==0) = NaN; ANN_O3(ANN_O3==0) = NaN;


%% Figure One - Annual Average PM25 Concentration

% (1) Create figure one and specify settings
f   = figure('Position',[100 100 1450 950],'color','w','visible','on');
% (a) axis settings
axs = {'box','linewidth','ticklength','fontsize','ylim','xlim'};
axv = {'on',10,[0 0],34,[4 14],[1998.9, 2016.1]};
% (b) plot settings
pls = {'linewidth','Marker','MarkerSize','linestyle'};
plv = {5,'.',40,'-.'}; colors = [0.7 0 0; 0 0.7 0; 0 0 0.7; 0.7 0 0.7];

% (2) Figure 1A
% (a) Set-Up axes
ax      = axes; hold on;
m       = get(ax, 'TightInset'); 
margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
nudge   = [0.06 margins(4)*0.537 -0.08 -margins(4)*0.55];
pl = plot(1999:2016,PW_PM);
%plot(1999:2016,M_PM,'k','linewidth',9)
set(pl,pls,plv); for p = 1:4; set(pl(p),'color',colors(p,:)); end
set(ax, 'Position', margins + nudge,axs,axv)
yl=ylabel('PM_2_._5 Conc. ( ug / m^3 )','fontsize',40); set(yl,'Position',yl.Position + [0.2 0 0])
text(2015.4,13.3,'A','fontsize',60,'fontweight','b')
text(2005.2,12.2,ename{1},'color',colors(1,:),'fontsize',36,'rotation',-25);
text(2009.4,10.7,ename{2},'color',colors(2,:),'fontsize',36,'rotation',-0);
text(2003.9,9.8,'SAT II','color',colors(3,:),'fontsize',36,'rotation',20);
text(1999.,9.7,'SAT I','color',colors(4,:),'fontsize',36,'rotation', -10);

% (2) Figure 1B
% (a) Set-Up axes
axv = {'on',10,[0 0],34,[3 12.5],[1998.9, 2016.1]};
ax      = axes; hold on;
m       = get(ax, 'TightInset'); 
margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
nudge   = [0.06 0.028 -0.08 -margins(4)*0.55];
pl = plot(1999:2016,ANN_PM);
%plot(1999:2016,MA_PM,'k','linewidth',9)
set(pl,pls,plv); for p = 1:4; set(pl(p),'color',colors(p,:)); end
set(ax, 'Position', margins + nudge,axs,axv)
text(2015.4,11.8,'B','fontsize',60,'fontweight','b')
yl=ylabel('PM_2_._5 Conc. ( ug / m^3 )','fontsize',40); set(yl,'Position',yl.Position + [0.2 0 0])
text(2005.2,10.6,ename{1},'color',colors(1,:),'fontsize',36,'rotation',-23);
text(2014.5,5.9,ename{2},'color',colors(2,:),'fontsize',36,'rotation',-32);
text(2003.9,8.2,'SAT II','color',colors(3,:),'fontsize',36,'rotation',15);
text(1999.,7.4,'SAT I','color',colors(4,:),'fontsize',36,'rotation', -10);

% (3) Save Figure
drawnow; frame = getframe(f); 
im = frame2im(frame); [imind,cm] = rgb2ind(im,256);
filename   = [out_dir,'Figure_One.tif'];
imwrite(imind,cm,char(filename),'tif','compression','none','resolution',600); 

%% Figure Two - Annual Average O3 Concentration

% (1) Create figure one and specify settings
f   = figure('Position',[100 100 1450 950],'color','w','visible','on'); clear pl;
% (a) axis settings
axs = {'box','linewidth','ticklength','fontsize','ylim','xlim'};
axv = {'on',10,[0 0],34,[46 56],[2008.9, 2016.1]};
% (b) plot settings
pls = {'linewidth','Marker','MarkerSize','linestyle'};
plv = {5,'.',40,'-.'}; colors = [0.7 0 0; 0 0.7 0; 0 0 0.7; 0.7 0 0.7];

% (2) Figure 1A
% (a) Set-Up axes
ax      = axes; hold on;
m       = get(ax, 'TightInset'); 
margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
nudge   = [0.06 margins(4)*0.537 -0.08 -margins(4)*0.55];
pl = plot(1999:2016,PW_O3(:,1:2));
%plot(1999:2016,M_O3,'k','linewidth',9)
set(pl,pls,plv); for p = 1:2; set(pl(p),'color',colors(p,:)); end
set(ax, 'Position', margins + nudge,axs,axv)
yl=ylabel('O_3 Conc. ( ppbv )','fontsize',40); set(yl,'Position',yl.Position + [0.05 0 0])
text(2015.8,55.2,'C','fontsize',60,'fontweight','b')
text(2012.4,50.2,ename{1},'color',colors(1,:),'fontsize',36,'rotation',-42);
text(2012.4,53.7,ename{2},'color',colors(2,:),'fontsize',36,'rotation',-45);

% (2) Figure 1B
% (a) Set-Up axes
axv = {'on',10,[0 0],34,[46 56],[2008.9, 2016.1]}; clear pl
ax      = axes; hold on;
m       = get(ax, 'TightInset'); 
margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
nudge   = [0.06 0.028 -0.08 -margins(4)*0.55];
pl = plot(1999:2016,ANN_O3);
%plot(1999:2016,MA_O3,'k','linewidth',9)
set(pl,pls,plv); for p = 1:2; set(pl(p),'color',colors(p,:)); end
set(ax, 'Position', margins + nudge,axs,axv)
text(2015.8,55.2,'D','fontsize',60,'fontweight','b')
yl=ylabel('O_3 Conc. ( ppbv )','fontsize',40); set(yl,'Position',yl.Position + [0.05 0 0])
text(2012.5,50.2,ename{1},'color',colors(1,:),'fontsize',36,'rotation',-34);
text(2012.5,53.7,ename{2},'color',colors(2,:),'fontsize',36,'rotation',-39);

% (3) Save Figure
drawnow; frame = getframe(f); 
im = frame2im(frame); [imind,cm] = rgb2ind(im,256);
filename   = [out_dir,'Figure_Two.tif'];
imwrite(imind,cm,char(filename),'tif','compression','none','resolution',600); 

%% Figure Three - Spatial Distibution of PM25

close all

% Initialize Figure Three Values
r = 0; c = 1;
x0 = -0.325; xd = 0.330;
y0 = -0.298; yd = 0.226;

 FIGNAMES = {'SAT I 1999','SAT II 2000','NACR 2009','BME 1999',...
             'SAT I 2011','SAT II 2016','NACR 2015','BME 2016'...
             'SAT I DIFF','SAT II DIFF','NACR DIFF','BME DIFF'};

% (1) Create figure one and specify settings
f   = figure('Position',[100 100 1200 1000],'color','w','visible','on');
% (a) axis settings
axs = {'box','linewidth','ticklength','fontsize','ylim','xlim'};
axv = {'on',3,[0 0],20,[4 13],[1998.9, 2016.1]};
clear ax;
cmap_dir = '/Users/omar/Desktop/Research/data/colormaps/';
cname = 'acton';
load([cmap_dir,cname,'/',cname,'.mat']);
actoff = flipud(acton);
cname = 'vik';
load([cmap_dir,cname,'/',cname,'.mat']); clear ax


data = { PM25(:,:,1,4) ; PM25(:,:,2,3) ; PM25(:,:,11,2); PM25(:,:,1,1);...
         PM25(:,:,13,4); PM25(:,:,18,3); PM25(:,:,17,2); PM25(:,:,18,1)};
data = [ data; data{5} - data{1}; data{6} - data{2}; data{7} - data{3}; data{8} - data{4} ];

Letter = 'DCBAHGFELKJIMNOP';

diver = [ 1 1 1 1 1 1 1 1 12 16 6 18];

for z = 1:12

Z = data{z}.*sum(in,3)'; Z(Z==0) = NaN;
subplot(4,3,z)
ax{z} = axesm('Mercator','MapLatLimit',[15 50],'MapLonLimit',[-125, -65]);
surfm(LAT',LON',Z,'linestyle','none'); 
bordersm('States','color','k','linewidth',2)
ax{z}.XLim = [-0.53, 0.52]; ax{z}.YLim = [0.42 1.01];
text(0.43,0.48,Letter(z),'fontsize',30,'fontweight','b')
text(-0.51,0.515,FIGNAMES{z},'fontsize',20,'fontweight','b')
if z < 9;text(-0.51,0.465,sprintf('%0.2f ug / m^3',mean(Z(~isnan(Z))) / diver(z)),'fontsize',20,'fontweight','b'); end
if z > 8;text(-0.51,0.465,sprintf('%0.2f ug / m^3 yr^-^1',mean(Z(~isnan(Z))) / diver(z)),'fontsize',20,'fontweight','b'); end

end


for z = 1:12
    
    r = r+1; if mod(z-1,4)==0; r = 1; c = c+1; end
    
    m       = get(ax{z}, 'TightInset'); 
    margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
    nudge   = [x0+xd*(c-1) y0+yd*(r-1) -margins(3)*0.671 0];
       
    if z < 9
        set(ax{z}, 'Position', margins + nudge,'linewidth',3,'Clim',[0   18])
        colormap(ax{z},actoff)
    else
        set(ax{z}, 'Position', margins + nudge,'linewidth',3,'Clim',[-10 10]);
        colormap(ax{z},vik)
    end
    
end

% Legend
%A-H
ax{13} = axes; plen = 10; dx  = 0.04 / plen ; number = linspace(0,18,plen);
actoff(end+1,:) = actoff(end,:); vik(end+1,:) = vik(end,:);
for p = 1:plen
    i_0 = (p-1)/plen; i_f = (p)/plen; ind = round((p-1) / (plen-1) * 256 + 1);
    patch([i_0+2*dx,i_0+2*dx,i_f-dx,i_f-dx],[0.6 0.9 0.9 0.6],actoff(ind,:),'linewidth',3);
    text((i_0+i_f)/2,0.5,sprintf('%0.0f',number(p)),'HorizontalAlignment','center','fontsize',16,'fontweight','b');
end
text(.5,0.225,'PM_2_._5 Concentration ( ug / m^3 )','HorizontalAlignment','center','fontsize',18,'fontweight','b')
set(ax{13},'Position',[0.0048 0.008 .66 .08],'xtick','','ytick','',...
    'linewidth',3,'box','on','XLIM',[0-dx*2 1+3*dx],'YLIM',[0,1])

%I-L
ax{14} = axes; plen = 9; dx  = 0.04 / plen ; number = linspace(-10,10,plen);
for p = 1:plen
    i_0 = (p-1)/plen; i_f = (p)/plen; ind = round((p-1) / (plen-1) * 256 + 1);
    patch([i_0+2*dx,i_0+2*dx,i_f-dx,i_f-dx],[0.6 0.9 0.9 0.6],vik(ind,:),'linewidth',3);
        text((i_0+i_f)/2,0.5,sprintf('%0.1f',number(p)),'HorizontalAlignment','center','fontsize',16,'fontweight','b');
end
text(.5,0.225,'PM_2_._5 Concentration ( ug / m^3 )','HorizontalAlignment','center','fontsize',18,'fontweight','b')
set(ax{14},'Position',[0.6648 0.008 .33 .08],'xtick','','ytick','',...
    'linewidth',3,'box','on','XLIM',[0-dx*3 1+4*dx],'YLIM',[0,1])

% (3) Save Figure
drawnow; frame = getframe(f); 
im = frame2im(frame); [imind,cm] = rgb2ind(im,256);
filename   = [out_dir,'Figure_Three.tif'];
imwrite(imind,cm,char(filename),'tif','compression','none','resolution',200); 


%% Figure Four - Spatial Distibution of O3
close all

% Initialize Figure Three Values
r = 0; c = 1;
x0 = -0.325; xd = 0.330;
y0 = -0.12; yd = 0.409;
FIGNAMES = {'BME 2009', 'NACR 2010', 'BME 2016', 'NACR 2015','BME DIFF', 'BME DIFF'};

diver = [ 1 1 1 1 5 7 ];

% (1) Create figure one and specify settings
f   = figure('Position',[100 100 1200 550],'color','w','visible','on');
% (a) axis settings
axs = {'box','linewidth','ticklength','fontsize','ylim','xlim'};
axv = {'on',3,[0 0],20,[4 13],[1998.9, 2016.1]};
clear ax;
cmap_dir = '/Users/omar/Desktop/Research/colormaps/';
cname = 'acton';
load([cmap_dir,cname,'/',cname,'.mat']);
actoff = flipud(acton);
cname = 'vik';
load([cmap_dir,cname,'/',cname,'.mat']);

clear data;
data = { O3(:,:,12,1) ; O3(:,:,11,2) ; O3(:,:,17,1); O3(:,:,18,2)};
data = [ data; data{3} - data{1}; data{4} - data{2}];

Letter = 'BADCFELKJIMNOP';

for z = 1:6

Z = data{z}.*sum(in,3)'; Z(Z==0) = NaN;
subplot(4,3,z)
ax{z} = axesm('Mercator','MapLatLimit',[15 50],'MapLonLimit',[-125, -65]);
surfm(LAT',LON',Z,'linestyle','none'); 
bordersm('States','color','k','linewidth',2)
ax{z}.XLim = [-0.53, 0.50]; ax{z}.YLim = [0.42 1.01];
text(0.42,0.48,Letter(z),'fontsize',30,'fontweight','b')
if z<5;text(-0.51,0.465,sprintf('%0.2f ppbv',mean(Z(~isnan(Z)))/diver(z)),'fontsize',20,'fontweight','b'); end
if z>4;text(-0.51,0.465,sprintf('%0.2f ppbv yr^-^1',mean(Z(~isnan(Z)))/diver(z)),'fontsize',20,'fontweight','b'); end
text(-0.51,0.515,FIGNAMES{z},'fontsize',20,'fontweight','b')

end


for z = 1:6
    
    r = r+1; if mod(z-1,2)==0; r = 1; c = c+1; end
    
    m       = get(ax{z}, 'TightInset'); 
    margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
    nudge   = [x0+xd*(c-1) y0+yd*(r-1) -margins(3)*0.670 0];
       
    if z < 5
        set(ax{z}, 'Position', margins + nudge,'linewidth',3,'Clim',[40   80])
        colormap(ax{z},actoff)
    else
        set(ax{z}, 'Position', margins + nudge,'linewidth',3,'Clim',[-10 10]);
        colormap(ax{z},vik)
    end
    
end

% Legend
%A-H
ax{7} = axes; plen = 10; dx  = 0.04 / plen ; number = linspace(0,18,plen);
actoff(end+1,:) = actoff(end,:); vik(end+1,:) = vik(end,:);
for p = 1:plen
    i_0 = (p-1)/plen; i_f = (p)/plen; ind = round((p-1) / (plen-1) * 256 + 1);
    patch([i_0+2*dx,i_0+2*dx,i_f-dx,i_f-dx],[0.6 0.9 0.9 0.6],actoff(ind,:),'linewidth',3);
    text((i_0+i_f)/2,0.5,sprintf('%0.0f',number(p)),'HorizontalAlignment','center','fontsize',16,'fontweight','b');
end
text(.5,0.225,'O_3 Concentration ( ppbv )','HorizontalAlignment','center','fontsize',18,'fontweight','b')
set(ax{7},'Position',[0.0048 0.034 .66 .14],'xtick','','ytick','',...
    'linewidth',3,'box','on','XLIM',[0-dx*2 1+3*dx],'YLIM',[0,1])

%I-L
ax{8} = axes; plen = 9; dx  = 0.04 / plen ; number = linspace(-10,10,plen);
for p = 1:plen
    i_0 = (p-1)/plen; i_f = (p)/plen; ind = round((p-1) / (plen-1) * 256 + 1);
    patch([i_0+2*dx,i_0+2*dx,i_f-dx,i_f-dx],[0.6 0.9 0.9 0.6],vik(ind,:),'linewidth',3);
        text((i_0+i_f)/2,0.5,sprintf('%0.1f',number(p)),'HorizontalAlignment','center','fontsize',16,'fontweight','b');
end
text(.5,0.225,'O_3 Concentration ( ppbv )','HorizontalAlignment','center','fontsize',18,'fontweight','b')
set(ax{8},'Position',[0.6648 0.034 .33 .14],'xtick','','ytick','',...
    'linewidth',3,'box','on','XLIM',[0-dx*3 1+4*dx],'YLIM',[0,1])

% (3) Save Figure
drawnow; frame = getframe(f); 
im = frame2im(frame); [imind,cm] = rgb2ind(im,256);
filename   = [out_dir,'Figure_Four.tif'];
imwrite(imind,cm,char(filename),'tif','compression','none','resolution',200); 

%% Figure Five - Temporal Mortality PM2.5
close all

% Variables
yrs = 1999:2016; x = [yrs, fliplr(yrs)];
letter = 'ABCD';

% (1) Create figure one and specify settings
f   = figure('Position',[100 100 1300 1200],'color','w','visible','on');
% (a) axis settings
axs = {'box','linewidth','ticklength','fontsize'};
axv = {'on',10,[0 0],38};
clear ax;

NAME = {'BME','NACR','SAT II', 'SAT I'};

for z = 1:4
        
    Z = [squeeze(sum(MORT_PM(:,:,:,z,1),1:2)), squeeze(sum(MORT_PM(:,:,:,z,2),1:2)),...
        squeeze(sum(MORT_PM(:,:,:,z,3),1:2)), squeeze(sum(MORT_PML(:,:,:,z,1),1:2)),...
        squeeze(sum(MORT_PMU(:,:,:,z,1),1:2))] / 1000; 
    
    ax{z} = axes; hold on; ind = Z(:,1)>0; yr = yrs(ind); dy = (yr(end)-yr(1))/5; n = length(yr);
    x2 = [yrs(ind), fliplr(yrs(ind))]; deaths = Z(ind,:);
    
        
    NZ = Z(ind,:);
   
    pl = plot(yr,Z(ind,:));
    set(pl(1),'color','k','linewidth',8,'markersize',20)
    set(pl(2),'color','b','linewidth',4,'markersize',20)
    set(pl(3),'color','r','linewidth',4,'markersize',20)
    set(pl(4:5),'color','k','linewidth',6,'linestyle',':')
    
    inBetween = [Z(ind,1)', flipud(Z(ind,2))'];
    fi = fill(x2', inBetween', [0.70 0.70 1.0]); hold on; uistack(fi,'bottom')
	inBetween = [Z(ind,2)', flipud(Z(ind,3))'];
    fi = fill(x2', inBetween', [1.00 0.70 0.7]); hold on; uistack(fi,'bottom')
    inBetween = [Z(ind,4)', flipud(Z(ind,5))'];
    fi = fill(x2', inBetween', [0.7 0.70 0.7]); hold on; uistack(fi,'bottom')

    % Text
    text(yr(1)+dy,9,'EXCLUDED','color','r','fontsize',34,'fontweight','b','HorizontalAlignment','center')
    text(mean(yr)+dy*0.3,9,'ONLY','color','b','fontsize',36,'fontweight','b','HorizontalAlignment','center')
    text(yr(end)-dy*0.8,9,'TOTAL','color','k','fontsize',34,'fontweight','b','HorizontalAlignment','center')
    text(mean(yr)+dy*0.1,150,NAME{z},'color','k','fontsize',36,'fontweight','b','HorizontalAlignment','center')
    text(yr(end)-dy/2,148,letter(z),'fontsize',60,'fontweight','b')
    text(yr(end)-dy*0.52,deaths(end,2)+3,sprintf('-%0.1f yr^-^1',(NZ(1,2) - NZ(end,2))/n),'color','b','fontsize',26,'fontweight','b','HorizontalAlignment','center')
    text(yr(end)-dy*0.52,deaths(end,1)-5,sprintf('-%0.1f yr^-^1',(NZ(1,1) - NZ(end,1))/n),'color','k','fontsize',26,'fontweight','b','HorizontalAlignment','center')
    text(yr(end)-dy*0.52,deaths(end,4)+12,sprintf('-%0.1f yr^-^1',(NZ(1,4) - NZ(end,4))/n),'color','k','fontsize',26,'fontweight','b','HorizontalAlignment','center')
    text(yr(end)-dy*0.52,deaths(end,5)+14,sprintf('-%0.1f yr^-^1',(NZ(1,5) - NZ(end,5))/n),'color','k','fontsize',26,'fontweight','b','HorizontalAlignment','center')
    if z ~= 2
        text(yr(end)-dy*0.49,deaths(end,3)+5,sprintf('-%0.1f yr^-^1',(NZ(1,3) - NZ(end,3))/n),'color','r','fontsize',26,'fontweight','b','HorizontalAlignment','center')
    else
        text(yr(end)-dy*0.49,deaths(end,3)+5,sprintf('+%0.1f yr^-^1',-(NZ(1,3) - NZ(end,3))/n),'color','r','fontsize',26,'fontweight','b','HorizontalAlignment','center')
    end


%     yticks([0:20:160]); xticks([2001:3:2015])
%     ylim([0 160]); xlim([1999 2015])

end

m       = get(ax{1}, 'TightInset'); 
margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
nudge   = [ 0.08 0.50 -margins(3)*0.61 -margins(4)*0.56];
set(ax{1},'position',margins + nudge,'xaxislocation','top',axs,axv,'ylim',[0 160],'xlim',[1998.8 2016.15])
yl = ylabel(ax{1},'PM_2_._5-related Premtaure Deaths'); set(yl,'Position',yl.Position + [ 0.5 -80.3 0]);

m       = get(ax{2}, 'TightInset'); 
margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
nudge   = [ 0.49 0.50 -margins(3)*0.61 -margins(4)*0.56];
set(ax{2},'position',margins + nudge,'xaxislocation','top',axs,axv,'ylim',[0 160],'xlim',[2008.96 2015.04],'yaxislocation','right')

m       = get(ax{3}, 'TightInset'); 
margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
nudge   = [ 0.08 0.04 -margins(3)*0.61 -margins(4)*0.56];
set(ax{3},'position',margins + nudge,'xaxislocation','bottom',axs,axv,'ylim',[0 160],'xlim',[1999.85 2016.15],'yaxislocation','left')

m       = get(ax{4}, 'TightInset'); 
margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
nudge   = [ 0.49 0.04 -margins(3)*0.61 -margins(4)*0.56];
set(ax{4},'position',margins + nudge,'xaxislocation','bottom',axs,axv,'ylim',[0 160],'xlim',[1998.9 2011.1],'yaxislocation','right')

% (3) Save Figure
drawnow; frame = getframe(f); 
im = frame2im(frame); [imind,cm] = rgb2ind(im,256);
filename   = [out_dir,'Figure_Five.tif'];
imwrite(imind,cm,char(filename),'tif','compression','none','resolution',200); 

%% Figure Six - Temporal Mortality O3
close all

% Variables
yrs = 2009:2016; x = [yrs, fliplr(yrs)];
letter = 'ABCD';

% (1) Create figure one and specify settings
f   = figure('Position',[100 100 1300 600],'color','w','visible','on');
% (a) axis settings
axs = {'box','linewidth','ticklength','fontsize'};
axv = {'on',10,[0 0],38};
clear ax;

NAME = {'BME','NACR','SAT II', 'SAT I'};

for z = 1:2
        
    Z = [squeeze(sum(MORT_O3(:,:,:,z,1),1:2)), squeeze(sum(MORT_O3(:,:,:,z,2),1:2)),...
        squeeze(sum(MORT_O3(:,:,:,z,3),1:2)), squeeze(sum(MORT_O3L(:,:,:,z,1),1:2)),...
        squeeze(sum(MORT_O3U(:,:,:,z,1),1:2))] / 1000; 
    
    ax{z} = axes; hold on; ind = Z(:,1)>0; yr = yrs(ind); dy = (yr(end)-yr(1))/5;  n = length(yr);
    x2 = [yrs(ind), fliplr(yrs(ind))]; deaths = Z(ind,:);
    
        
    NZ = Z(ind,:);
        
    pl = plot(yr,Z(ind,:));
    set(pl(1),'color','k','linewidth',8,'markersize',20)
    set(pl(2),'color','b','linewidth',4,'markersize',20)
    set(pl(3),'color','r','linewidth',4,'markersize',20)
    set(pl(4:5),'color','k','linewidth',6,'linestyle',':')
    
    inBetween = [Z(ind,1)', flipud(Z(ind,2))'];
    fi = fill(x2', inBetween', [0.70 0.70 1.0]); hold on; uistack(fi,'bottom')
	inBetween = [Z(ind,2)', flipud(Z(ind,3))'];
    fi = fill(x2', inBetween', [1.00 0.70 0.7]); hold on; uistack(fi,'bottom')
    inBetween = [Z(ind,4)', flipud(Z(ind,5))'];
    fi = fill(x2', inBetween', [0.7 0.70 0.7]); hold on; uistack(fi,'bottom')

    % Text
    text(yr(1)+dy,1.5,'EXCLUDED','color','r','fontsize',34,'fontweight','b','HorizontalAlignment','center')
    text(mean(yr)+dy*0.3,1.5,'ONLY','color','b','fontsize',36,'fontweight','b','HorizontalAlignment','center')
    text(yr(end)-dy*0.8,1.5,'TOTAL','color','k','fontsize',34,'fontweight','b','HorizontalAlignment','center')
    text(mean(yr)+dy*0.1,38,NAME{z},'color','k','fontsize',36,'fontweight','b','HorizontalAlignment','center')
    text(yr(end)-dy/2,37,letter(z),'fontsize',60,'fontweight','b')
    text(yr(end)-dy*0.42,deaths(end,3)+1.3,sprintf('+%0.1f yr^-^1',abs(NZ(1,3) - NZ(end,3))/n),'color','r','fontsize',26,'fontweight','b','HorizontalAlignment','center')
    text(yr(end)-dy*0.42,deaths(end,2)-0.3,sprintf('-%0.1f yr^-^1',(NZ(1,2) - NZ(end,2))/n),'color','b','fontsize',26,'fontweight','b','HorizontalAlignment','center')
    text(yr(end)-dy*0.42,deaths(end,1)+2,  sprintf('-%0.1f yr^-^1',(NZ(1,1) - NZ(end,1))/n),'color','k','fontsize',26,'fontweight','b','HorizontalAlignment','center')
    text(yr(end)-dy*0.42,deaths(end,4)+1.5,sprintf('-%0.1f yr^-^1',(NZ(1,4) - NZ(end,4))/n),'color','k','fontsize',26,'fontweight','b','HorizontalAlignment','center')
    text(yr(end)-dy*0.49,deaths(end,5)+1.9,sprintf('-%0.1f yr^-^1',(NZ(1,5) - NZ(end,5))/n),'color','k','fontsize',26,'fontweight','b','HorizontalAlignment','center')

%     yticks([0:20:160]); xticks([2001:3:2015])
%     ylim([0 160]); xlim([1999 2015])

end

m       = get(ax{1}, 'TightInset'); 
margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
nudge   = [ 0.08 0.01 -margins(3)*0.58 -margins(4)*0.1];
set(ax{1},'position',margins + nudge,'xaxislocation','top',axs,axv,'ylim',[0 40],'xlim',[2009.97 2015.03])
yl = ylabel(ax{1},'O_3-related Premtaure Deaths'); %set(yl,'Position',yl.Position + [ 0.5 -5.3 0]);

m       = get(ax{2}, 'TightInset'); 
margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
nudge   = [ 0.53 0.01 -margins(3)*0.58 -margins(4)*0.1];
set(ax{2},'position',margins + nudge,'xaxislocation','top',axs,axv,'ylim',[0 40],'xlim',[2008.97 2016.03],'yaxislocation','right')

% (3) Save Figure
drawnow; frame = getframe(f); 
im = frame2im(frame); [imind,cm] = rgb2ind(im,256);
filename   = [out_dir,'Figure_Six.tif'];
imwrite(imind,cm,char(filename),'tif','compression','none','resolution',200); 

%% Figure Seven - Spatial Mortality PM

% Initialize Figure Three Values
r = 0; c = 1;
x0 = -0.325; xd = 0.330;
y0 = -0.295; yd = 0.226;
jets = colormap(jet); 
jets = [interp(jets(:,1),4), interp(jets(:,2),4), interp(jets(:,3),4)]; 
jets(jets<0) = 0; jets(jets>1) = 1; jets(257,:) = jets(256,end);
 FIGNAMES = {'SAT I 1999','SAT II 2000','NACR 2009','BME 1999',...
             'SAT I 2011','SAT II 2016','NACR 2015','BME 2016'...
             'SAT I DIFF','SAT II DIFF','NACR DIFF','BME DIFF'};
 diver = [ 1 1 1 1 1 1 1 1 12 16 6 18];

% (1) Create figure one and specify settings
f   = figure('Position',[100 100 1200 1000],'color','w','visible','on');
% (a) axis settings
axs = {'box','linewidth','ticklength','fontsize','ylim','xlim'};
axv = {'on',3,[0 0],20,[4 13],[1998.9, 2016.1]};
clear ax;
cmap_dir = '/Users/omar/Desktop/Research/data/colormaps/';
cname = 'acton';
load([cmap_dir,cname,'/',cname,'.mat']);
actoff = flipud(acton);
cname = 'vik';
load([cmap_dir,cname,'/',cname,'.mat']);


data = { MORT_PM(:,:,1,4,1) ; MORT_PM(:,:,2,3,1) ; MORT_PM(:,:,11,2,1); MORT_PM(:,:,1,1,1);...
         MORT_PM(:,:,13,4,1); MORT_PM(:,:,18,3,1); MORT_PM(:,:,17,2,1); MORT_PM(:,:,18,1,1)};
data = [ data; data{5} - data{1}; data{6} - data{2}; data{7} - data{3}; data{8} - data{4} ];

Letter = 'DCBAHGFELKJIMNOP';

for z = 1:12
    
subplot(4,3,z)
ax{z} = axesm('Mercator','MapLatLimit',[15 50],'MapLonLimit',[-125, -65]);

Z = data{z}.*sum(in,3)'; Z(Z==0) = NaN; 
if z<9; text(-0.51,0.465,sprintf('%2.0f deaths',round(sum(Z(~isnan(Z))/diver(z)),-1)),'fontsize',20,'fontweight','b'); end;
if z>8; text(-0.51,0.475,sprintf('%2.0f deaths yr^-^1',round(sum(Z(~isnan(Z))/diver(z)),-1)),'fontsize',20,'fontweight','b'); end;
if z < 9; Z = real(log10(Z)); end

surfm(LAT',LON',Z,'linestyle','none'); 
bordersm('States','color','k','linewidth',2)
ax{z}.XLim = [-0.53, 0.50]; ax{z}.YLim = [0.43 1.02];
text(0.42,0.48,Letter(z),'fontsize',30,'fontweight','b')
text(-0.51,0.515,FIGNAMES{z},'fontsize',20,'fontweight','b')

end


for z = 1:12
    
    r = r+1; if mod(z-1,4)==0; r = 1; c = c+1; end
    
    m       = get(ax{z}, 'TightInset'); 
    margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
    nudge   = [x0+xd*(c-1) y0+yd*(r-1) -margins(3)*0.670 0];
       
    if z < 9
        set(ax{z}, 'Position', margins + nudge,'linewidth',3,'Clim',[-1 3])
        colormap(ax{z},jet)
    else
        set(ax{z}, 'Position', margins + nudge,'linewidth',3,'Clim',[-5 5]);
        colormap(ax{z},vik)
    end
    
end

% Legend
%A-H

ax{13} = axes; plen = 10; dx  = 0.04 / plen ; number = linspace(-1,3,plen);
actoff(end+1,:) = actoff(end,:); vik(end+1,:) = vik(end,:);
for p = 1:plen
    i_0 = (p-1)/plen; i_f = (p)/plen; ind = round((p-1) / (plen-1) * 256 + 1);
    patch([i_0+2*dx,i_0+2*dx,i_f-dx,i_f-dx],[0.6 0.9 0.9 0.6],jets(ind,:),'linewidth',3);
    text((i_0+i_f)/2,0.5,sprintf('%0.1f',10.^number(p)),'HorizontalAlignment','center','fontsize',16,'fontweight','b');
end
text(.5,0.225,'Premature Deaths','HorizontalAlignment','center','fontsize',16,'fontweight','b')
set(ax{13},'Position',[0.0048 0.008 .66 .08],'xtick','','ytick','',...
    'linewidth',3,'box','on','XLIM',[0-dx*2 1+3*dx],'YLIM',[0,1])

%I-L
ax{14} = axes; plen = 9; dx  = 0.04 / plen ; number = linspace(-5,5,plen);
for p = 1:plen
    i_0 = (p-1)/plen; i_f = (p)/plen; ind = round((p-1) / (plen-1) * 256 + 1);
    patch([i_0+2*dx,i_0+2*dx,i_f-dx,i_f-dx],[0.6 0.9 0.9 0.6],vik(ind,:),'linewidth',3);
        text((i_0+i_f)/2,0.5,sprintf('%0.1f',number(p)),'HorizontalAlignment','center','fontsize',16,'fontweight','b');
end
text(.5,0.225,'Difference','HorizontalAlignment','center','fontsize',16,'fontweight','b')
set(ax{14},'Position',[0.6648 0.008 .33 .08],'xtick','','ytick','',...
    'linewidth',3,'box','on','XLIM',[0-dx*3 1+4*dx],'YLIM',[0,1])

% (3) Save Figure
drawnow; frame = getframe(f); 
im = frame2im(frame); [imind,cm] = rgb2ind(im,256);
filename   = [out_dir,'Figure_Seven.tif'];
imwrite(imind,cm,char(filename),'tif','compression','none','resolution',200); 

%% Figure Eight - Spatial Distibution of O3 MORT
close all

% Initialize Figure Three Values
r = 0; c = 1;
x0 = -0.325; xd = 0.330;
y0 = -0.12; yd = 0.409;
jets = colormap(jet); 
jets = [interp(jets(:,1),4), interp(jets(:,2),4), interp(jets(:,3),4)]; 
jets(jets<0) = 0; jets(jets>1) = 1; jets(257,:) = jets(256,end);
FIGNAMES = {'BME 2009', 'NACR 2010', 'BME 2016', 'NACR 2015','BME DIFF', 'BME DIFF'};
diver = [ 1 1 1 1 5 7 ];


% (1) Create figure one and specify settings
f   = figure('Position',[100 100 1200 550],'color','w','visible','on');
% (a) axis settings
axs = {'box','linewidth','ticklength','fontsize','ylim','xlim'};
axv = {'on',3,[0 0],20,[4 13],[1998.9, 2016.1]};
clear ax;
cmap_dir = '/Users/omar/Desktop/Research/colormaps/';
cname = 'acton';
load([cmap_dir,cname,'/',cname,'.mat']);
actoff = flipud(acton);
cname = 'vik';
load([cmap_dir,cname,'/',cname,'.mat']);

clear data;
data = { MORT_O3(:,:,2,1,1) ; MORT_O3(:,:,1,2,1) ; MORT_O3(:,:,7,1,1); MORT_O3(:,:,8,2,1)};
data = [ data; data{3} - data{1}; data{4} - data{2}];

Letter = 'BADCFELKJIMNOP';

for z = 1:6
    
    subplot(4,3,z)
ax{z} = axesm('Mercator','MapLatLimit',[15 50],'MapLonLimit',[-125, -65]);

Z = data{z}.*sum(in,3)'; Z(Z==0) = NaN;
if z<5;text(-0.51,0.465,sprintf('%2.0f deaths',round(sum(Z(~isnan(Z))),-1)),'fontsize',20,'fontweight','b'); end
if z>4;text(-0.51,0.465,sprintf('%2.0f deaths yr^-^1',round(sum(Z(~isnan(Z)))/diver(z),-1)),'fontsize',20,'fontweight','b'); end
if z < 5; Z = real(log10(Z)); end

surfm(LAT',LON',Z,'linestyle','none'); 
bordersm('States','color','k','linewidth',2)
ax{z}.XLim = [-0.53, 0.50]; ax{z}.YLim = [0.42 1.01];
text(0.42,0.48,Letter(z),'fontsize',30,'fontweight','b')
text(-0.51,0.515,FIGNAMES{z},'fontsize',20,'fontweight','b')


end


for z = 1:6
    
    r = r+1; if mod(z-1,2)==0; r = 1; c = c+1; end
    
    m       = get(ax{z}, 'TightInset'); 
    margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
    nudge   = [x0+xd*(c-1) y0+yd*(r-1) -margins(3)*0.670 0];
       
    if z < 5
        set(ax{z}, 'Position', margins + nudge,'linewidth',3,'Clim',[-1  1.8])
        colormap(ax{z},jet)
    else
        set(ax{z}, 'Position', margins + nudge,'linewidth',3,'Clim',[-5 5]);
        colormap(ax{z},vik)
    end
    
end

% Legend
%A-H
ax{7} = axes; plen = 10; dx  = 0.04 / plen ; number = linspace(-1,1.8,plen);
actoff(end+1,:) = actoff(end,:); vik(end+1,:) = vik(end,:);
for p = 1:plen
    i_0 = (p-1)/plen; i_f = (p)/plen; ind = round((p-1) / (plen-1) * 256 + 1);
    patch([i_0+2*dx,i_0+2*dx,i_f-dx,i_f-dx],[0.6 0.9 0.9 0.6],jets(ind,:),'linewidth',3);
    text((i_0+i_f)/2,0.5,sprintf('%0.1f',10.^number(p)),'HorizontalAlignment','center','fontsize',16,'fontweight','b');
end
text(.5,0.225,'Premature Deaths','HorizontalAlignment','center','fontsize',16,'fontweight','b')
set(ax{7},'Position',[0.0048 0.034 .66 .14],'xtick','','ytick','',...
    'linewidth',3,'box','on','XLIM',[0-dx*2 1+3*dx],'YLIM',[0,1])

%I-L
ax{8} = axes; plen = 9; dx  = 0.04 / plen ; number = linspace(-5,5,plen);
for p = 1:plen
    i_0 = (p-1)/plen; i_f = (p)/plen; ind = round((p-1) / (plen-1) * 256 + 1);
    patch([i_0+2*dx,i_0+2*dx,i_f-dx,i_f-dx],[0.6 0.9 0.9 0.6],vik(ind,:),'linewidth',3);
        text((i_0+i_f)/2,0.5,sprintf('%0.1f',number(p)),'HorizontalAlignment','center','fontsize',16,'fontweight','b');
end
text(.5,0.225,'Difference','HorizontalAlignment','center','fontsize',16,'fontweight','b')
set(ax{8},'Position',[0.6648 0.034 .33 .14],'xtick','','ytick','',...
    'linewidth',3,'box','on','XLIM',[0-dx*3 1+4*dx],'YLIM',[0,1])

% (3) Save Figure
drawnow; frame = getframe(f); 
im = frame2im(frame); [imind,cm] = rgb2ind(im,256);
filename   = [out_dir,'Figure_Eight.tif'];
imwrite(imind,cm,char(filename),'tif','compression','none','resolution',200); 

%% Figure Nine - Mean State Decreases PM

%% Figure Ten - Mean State Decreases O3

%% Figure Eleven - Comparison With Other Studies PM

run('/Users/omar/Desktop/Research/Health_Impacts/Codes/Ozone/Analysis/EPA_data.m')
close all

% Variables
yrs = 1999:2016; x = [yrs, fliplr(yrs)];
% Cohen et al. 
LBC = [84.4 84.8 83.8 78.2 63.6 66.8];
UBC = [129.2 132.8 132.9 127.0 107.8 115.0];
MC = [106 107.2 106.2 100 83.4 88.4];


% (1) Create figure one and specify settings
f   = figure('Position',[100 100 1300 700],'color','w','visible','on');
% (a) axis settings
axs = {'box','linewidth','ticklength','fontsize','xlim','ylim'};
axv = {'on',8,[0 0],38,[1985 2020],[0 180]};
% (b) plot settings
pls = {'linewidth','Marker','MarkerSize','linestyle'};
plv = {5,'.',40,'-.'}; colors = [0.7 0 0; 0 0.7 0; 0 0 0.7; 0.7 0 0.7];
clear ax;

Z = squeeze(sum(MORT_PM(:,:,:,:,1),1:2)) / 1E3; Z(Z==0) = NaN;
ax = axes;
pl = plot(yrs, Z); set(pl,pls,plv); set(ax,axs,axv); hold on;
eb = errorbar([1990 1995 2000 2005 2010 2015],MC,MC-LBC,UBC-MC);colors(5,:) = eb.Color;
set(eb,pls,plv,'color','r')

for p = 1:4; set(pl(p),'color',colors(p,:)); end
pl = plot(YearY,SUM/1E3); set(pl,pls,plv); colors(6,:) = pl.Color;
pl = plot(1990:10:2010,[170,140,120],'color','k'); set(pl,pls,plv); colors(7,:) = pl.Color;
pl = plot(2005,66,'ks','MarkerSize',20,'MarkerFaceColor',[0.7 0.7 0.2],'linewidth',3); colors(8,:) = pl.MarkerFaceColor;
pl = plot(2005,130.0,'ks','MarkerSize',20,'MarkerFaceColor',[0.2 0.7 0.2],'linewidth',3); colors(9,:) = pl.MarkerFaceColor;
ylabel('Premature Deaths ( Thousands )')

% (2) Legend
patch([1985 1998 1998 1985],[0 0 40 40],'w','linewidth',8)
patch([1985 1998 1998 1985],[40 40 80 80],'w','linewidth',8)
% This Study
text(1991.5,74,'This Study','HorizontalAlignment','center','fontsize',36,'fontweight','b')
text(1986.9,63,'BME','HorizontalAlignment','center','fontsize',36,'color',colors(1,:))
text(1986.9,49,'NACR','HorizontalAlignment','center','fontsize',36,'color',colors(2,:))
text(1993.5,63,'SAT I','HorizontalAlignment','center','fontsize',36,'color',colors(3,:))
text(1993.5,49,'SAT II','HorizontalAlignment','center','fontsize',36,'color',colors(4,:))
x = 1989.2:0.9:1991.2; pl = plot(x,63 * ones(length(x),1),'color',colors(1,:)); set(pl,pls,plv);
x = 1989.2:0.9:1991.2; pl = plot(x,49 * ones(length(x),1),'color',colors(2,:)); set(pl,pls,plv);
x = 1995.5:0.9:1997.5; pl = plot(x,63 * ones(length(x),1),'color',colors(3,:)); set(pl,pls,plv);
x = 1995.5:0.9:1997.5; pl = plot(x,49 * ones(length(x),1),'color',colors(4,:)); set(pl,pls,plv);
% Other Studies
text(1991.5,35,'Other Studies','HorizontalAlignment','center','fontsize',36,'fontweight','b')
text(1986.9,26,'Cohen','HorizontalAlignment','center','fontsize',36,'color','r')
text(1986.9,17,'Zhang','HorizontalAlignment','center','fontsize',36,'color',colors(6,:))
text(1986.9,7,'Fann^a','HorizontalAlignment','center','fontsize',36,'color',colors(7,:))
text(1994.5,26,'Fann^b','HorizontalAlignment','center','fontsize',36,'color',colors(8,:))
text(1994.5,15.0,sprintf('Punger'),'HorizontalAlignment','center','fontsize',36,'color',colors(9,:))
text(1994.5,6.0,sprintf('& West'),'HorizontalAlignment','center','fontsize',36,'color',colors(9,:))
% text(1986.2,35,'NACR','HorizontalAlignment','center','fontsize',20,'color',colors(2,:))
% text(1991.0,41,'SAT I','HorizontalAlignment','center','fontsize',20,'color',colors(3,:))
% text(1991.0,35,'SAT II','HorizontalAlignment','center','fontsize',20,'color',colors(4,:))
x = 1989.2:0.9:1991.2; pl = plot(x,26 * ones(length(x),1),'color','r'); set(pl,pls,plv);
x = 1989.2:0.9:1991.2; pl = plot(x,17 * ones(length(x),1),'color',colors(6,:)); set(pl,pls,plv);
x = 1989.2:0.9:1991.2; pl = plot(x,7  * ones(length(x),1),'color',colors(7,:)); set(pl,pls,plv);
plot(1996.8,26,'ks','MarkerSize',20,'MarkerFaceColor',[0.7 0.7 0.2],'linewidth',3)
plot(1996.8,10.4,'ks','MarkerSize',20,'MarkerFaceColor',[0.2 0.7 0.2],'linewidth',3)

m       = get(ax, 'TightInset'); 
margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
nudge   = [0.0 0. -0.0 -margins(4)*0.01];
set(ax, 'Position', margins + nudge,axs,axv)

% (3) Save Figure
drawnow; frame = getframe(f); 
im = frame2im(frame); [imind,cm] = rgb2ind(im,256);
filename   = [out_dir,'Figure_Eleven.tif'];
imwrite(imind,cm,char(filename),'tif','compression','none','resolution',200); 


%% Figure Twelve - Comparison With Other Studies O3

% Variables
yrs = 2009:2016; x = [yrs, fliplr(yrs)];
% Cohen et al. 
LBC = [2.9 3.5 4.0 4.2 4.3 4.4];
UBC = [12.5 15.2 17.6 18.5 18.7 19.6];
MC = [7.5 9.2 10.6 11.1 11.2 11.7];


% (1) Create figure one and specify settings
f   = figure('Position',[100 100 1300 700],'color','w','visible','on');
% (a) axis settings
axs = {'box','linewidth','ticklength','fontsize','xlim','ylim'};
axv = {'on',8,[0 0],38,[1985 2020],[0 25]};
% (b) plot settings
pls = {'linewidth','Marker','MarkerSize','linestyle'};
plv = {5,'.',40,'-.'}; colors = [0.7 0 0; 0 0.7 0; 0 0 0.7; 0.7 0 0.7];
clear ax;

Z = squeeze(sum(MORT_O3(:,:,:,:,1),1:2)) / 1E3; Z(Z<=0) = NaN;
ax = axes;
pl = plot(yrs, Z); set(pl,pls,plv); set(ax,axs,axv); hold on;
eb = errorbar([1990 1995 2000 2005 2010 2015],MC,MC-LBC,UBC-MC);colors(5,:) = eb.Color;
set(eb,pls,plv,'color','r')

for p = 1:4; set(pl(p),'color',colors(p,:)); end
pl = plot(YearY,RESPY./1E3); set(pl,pls,plv); colors(6,:) = pl.Color;
pl = plot(2005,21.400,'ks','MarkerSize',20,'MarkerFaceColor',[0.7 0.7 0.2],'linewidth',3); colors(8,:) = pl.MarkerFaceColor;
pl = plot(2005,19.0,'ks','MarkerSize',20,'MarkerFaceColor',[0.2 0.7 0.2],'linewidth',3); colors(9,:) = pl.MarkerFaceColor;
ylabel('Premature Deaths ( Thousands )')

% (2) Legend
patch([1985 1998 1998 1985],[16 16 21.5 21.5],'w','linewidth',8)
patch([1985 1998 1998 1985],[21.5 21.5 25 25],'w','linewidth',8)
% This Study
text(1991.5,24.1,'This Study','HorizontalAlignment','center','fontsize',36,'fontweight','b')
text(1986.5,22.4,'BME','HorizontalAlignment','center','fontsize',36,'color',colors(1,:))
text(1993.5,22.4,'NACR','HorizontalAlignment','center','fontsize',36,'color',colors(2,:))
x = 1988.4:0.9:1990.4; pl = plot(x,22.4 * ones(length(x),1),'color',colors(1,:)); set(pl,pls,plv);
x = 1995.5:0.9:1997.5; pl = plot(x,22.4 * ones(length(x),1),'color',colors(2,:)); set(pl,pls,plv);
% Other Studies
text(1991.5,20.7,'Other Studies','HorizontalAlignment','center','fontsize',36,'fontweight','b')
text(1987.,19.3,'Cohen','HorizontalAlignment','center','fontsize',36,'color','r')
text(1987.,17.3,'Zhang','HorizontalAlignment','center','fontsize',36,'color',colors(6,:))
text(1994.5,19.7,'Fann^b','HorizontalAlignment','center','fontsize',36,'color',colors(8,:))
text(1994.5,18.2,sprintf('Punger'),'HorizontalAlignment','center','fontsize',36,'color',colors(9,:))
text(1994.5,17.0,sprintf('& West'),'HorizontalAlignment','center','fontsize',36,'color',colors(9,:))
x = 1989.3:0.9:1991.3; pl = plot(x,19.3 * ones(length(x),1),'color','r'); set(pl,pls,plv);
x = 1989.3:0.9:1991.3; pl = plot(x,17.3 * ones(length(x),1),'color',colors(6,:)); set(pl,pls,plv);
plot(1996.9,19.4,'ks','MarkerSize',20,'MarkerFaceColor',[0.7 0.7 0.2],'linewidth',3)
plot(1996.9,17.0,'ks','MarkerSize',20,'MarkerFaceColor',[0.2 0.7 0.2],'linewidth',3)

m       = get(ax, 'TightInset'); 
margins = [m(1), m(2), 1 - m(1) - m(3), 1 - m(2) - m(4) ];
nudge   = [0.0 0. -0.0 -margins(4)*0];
set(ax, 'Position', margins + nudge,axs,axv)

% (3) Save Figure
drawnow; frame = getframe(f); 
im = frame2im(frame); [imind,cm] = rgb2ind(im,256);
filename   = [out_dir,'Figure_Twelve.tif'];
imwrite(imind,cm,char(filename),'tif','compression','none','resolution',200); 
