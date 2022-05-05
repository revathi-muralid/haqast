function grid=getEstimationGrid
% defines the estimation grid as center points of grid 
% 0.5 degree grid cells longitude -180 to 180, latitude -60 to 75
%
% SYNTAX:
%
% grid=getEstimationGrid
%
% INPUT:
%   no input needed
% OUTPUT:
%   grid = 1 by 2 vector of spatial coordinates of the grid
%          column 1 is longitude, column 2 is latitude
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input parameters.  Change these parameters to modify what this function is doing 
%    Resolution of global offset grid
incldatapts=0; 
inclvoronoi=0;     % 1 to include the voronoi vertices 
                   % 1 to include a grid, 0 otherwise
[nxpix,nypix]=getPixels;          % Number of pixels in the x-direction for the grid
                                  % Number of pixels in the y-direction for the grid
estGridArea=[-179.75 179.75 -59.75 74.75];  % [longmin lonmeax latmin latmax] of the estimation region
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

obs=getObs;
filename=['EstimationGrid.mat'];

if exist(filename)==2
    load(filename);
else
%    Set the regular estimation grid
    [xg yg]=meshgrid(estGridArea(1):diff(estGridArea(1:2))/(nxpix):estGridArea(2),...
      estGridArea(3):diff(estGridArea(3:4))/(nypix):estGridArea(4));
    sk=[xg(:) yg(:)];

    %    Add data to the estimation points if requested
    if incldatapts==1 & ~isempty(obs.sh)
      idx= (estGridArea(1)<=obs.sh(:,1)) & (obs.sh(:,1)<=estGridArea(2)) & (estGridArea(3)<=obs.sh(:,2)) & (obs.sh(:,2)<=estGridArea(4)) ;
      sk=unique([sk;obs.sh(idx,:)],'rows');
    end
    %     Add voronoi of data if requested
    if inclvoronoi==1 & ~isempty(obs.sh)
      [vx,vy] = voronoi(obs.sh(:,1),obs.sh(:,2));
      sv=unique([vx(:) vy(:)],'rows');
      idx= (estGridArea(1)<=sv(:,1)) & (sv(:,1)<=estGridArea(2)) & (estGridArea(3)<=sv(:,2)) & (sv(:,2)<=estGridArea(4)) ;
      sk=unique([sk;sv(idx,:)],'rows');
    end

    grid=sk;
    
%     %mask continents to only estimate in continent boundaries
%     load('coastlines.mat');
%     index1=inpolygon(grid(:,2),grid(:,1),coastlat,coastlon);
%     
%         cutoff_distance = 0.1;   %set as appropriate to set mask cutoff
%         idx=isnan(coastlon);
%         DT = delaunayTriangulation(coastlon(~idx),coastlat(~idx));%triangle interpolation
%         [vi, d] = nearestNeighbor(DT, grid(:,1), grid(:,2));
%         mask = d <= cutoff_distance; %set mask
%         %grid(mask,:) = nan; %maks away from values   
%     
%     grid(~index1 & ~mask,:)=NaN;
%     %mask to only look at model boundaries
    
    
    save(filename,'grid');
end

end
