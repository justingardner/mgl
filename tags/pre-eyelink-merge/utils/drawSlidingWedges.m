function t_elapsed=drawSlidingWedges( stimDuration, ...
				      wedgeRadialCoords, ...
				      wedgePolarCoords, ...
				      wedgeRadialWidths, ...
				      wedgePolarWidths, ...
				      minEccentricity, ...
				      maxEccentricity, ...
				      wrapEccentricity, ...
				      checkSizes, ...
				      wedgeColours, ...
				      backgroundColour, ...
				      slidingSpeed, ...
				      fixationParams );
% time_elapsed=drawSlidingWedges( stimDuration, ...
%		                  wedgeRadialCoords, wedgePolarCoords, wedgeRadialWidths, wedgePolarWidths, ...
%		                  minEccentricity, maxEccentricity, wrapEccentricity, checkSizes, ...
%		                  [wedgeColours, backgroundColour,
%		                  slidingSpeed, fixationParams] );
%
% Draws (optionally truncated) wedges containing radially sliding
% checkerboards on current mgl drawing context. 
% 
%    INPUT VARIABLE : DESCRIPTION
%      stimDuration : display duration of wedge (s). Can also be a 3-vector:
%                     [<total duration> <duty cycle 0..1> <number of cycles>]
% wedgeRadialCoords : (nWedges x 1) vector with centre coordinates 
%                     of wedges in radial dimension
%                     (current screen coordinates, normally degrees)
%  wedgePolarCoords : (nWedges x 1) vector with centre coordinates
%                     of wedges in polar dimension (degrees)
% wedgeRadialWidths : (nWedges x 1) or scalar; width of wedges in
%                     radial dimension (screen coords). Wraps
%                     around when > wrapEccentricity
%  wedgePolarWidths : (nWedges x 1) or scalar; width of wedges in polar dimension (degrees)
%  wrapEccentricity : eccentricity defining wrap around for radial
%                     stimuli [min max]. If empty, same as min, max display eccentricity.
%   maxEccentricity : max eccentricity to display.
%   minEccentricity : min eccentricity to display.
%        checkSizes : (nWedges x 2) matrix specifying size of 
%                     checks in each wedge [radialSize polarSize]. 
%                     Single row uses same check size for all wedges.
%      wedgeColours : (nColours x 6) matrix of wedge colours 
%                     Each row specifies high and low contrast
%                     colours (default=[] uses black and white)
%                     If multiple rows, colours drawn randomly.
%  backgroundColour : colour of background, default gray [0.5 0.5 0.5]
%      slidingSpeed : speed of sliding sectors (screen units/s),
%                     default 0
%    fixationParams : parameters for mglFixationCross. Use 0 for no
%                     fixation marker.
% (c) Jonas Larsson 20060621


t_zero=mglGetSecs;
if (length(stimDuration)==3)
  dutyCycle=stimDuration(2);
  nCycles=stimDuration(3); 
  stimDuration=stimDuration(1);
else
  dutyCycle=1;
  nCycles=1;  
end
timePerCycle=stimDuration/nCycles;
onTimePerCycle=dutyCycle*stimDuration/nCycles;
offTimePerCycle=timePerCycle-onTimePerCycle;

if (isempty(wrapEccentricity))
  wrapEccentricity=[minEccentricity maxEccentricity];
end
if (~exist('wedgeColours','var') || isempty(wedgeColours))
  wedgeColours=[0 0 0 1 1 1];
end
if (~exist('backgroundColour','var') || isempty(backgroundColour))
  backgroundColour=[0.5 0.5 0.5];
end

if (~exist('slidingSpeed','var'))
  slidingSpeed=0;
end

if (~exist('fixationParams') || isempty(fixationParams))
  fixationParams=[0.3 3 0 1 0 0 0];
elseif (fixationParams==0)
  fixationParams=[];
end

nWedges=size(wedgeRadialCoords,1);

if (length(wedgePolarWidths)<nWedges)
  wedgePolarWidths=wedgePolarWidths(1)*ones(nWedges,1);
end
if (length(wedgeRadialWidths)<nWedges)
  wedgeRadialWidths=wedgeRadialWidths(1)*ones(nWedges,1);
end
if (size(checkSizes,1)<nWedges)
  checkSizes=repmat(checkSizes(1,:),nWedges,1);
end

% convert to radians
wedgePolarCoords=wedgePolarCoords/180*pi;
wedgePolarWidths=wedgePolarWidths/180*pi;
checkSizes(:,2)=checkSizes(:,2)/180*pi;

TOL=1e-3;

if (any(wedgeRadialCoords>maxEccentricity))
  disp('Warning: stimulus radius outside display limits.')
  disp('Truncating - results may differ from specifications.')
  wedgeRadialCoords(wedgeRadialCoords>maxEccentricity)= ...
      maxEccentricity;
end
  
% number of sectors per wedge given by ratio of wedge polar size
% to check polar size
nSectorsPerWedge=round(wedgePolarWidths./checkSizes(:,2));
if (any( abs(nSectorsPerWedge-round(nSectorsPerWedge))>TOL))
  disp(['WARNING: check polar dimension is not an integer multiple' ...
	' of wedge polar width. Stimulus may differ from' ...
	 ' specifications.'])
  
end

% number of checks per sector given by ratio of wedge radial size
% to check radial size
nRadialChecksPerSector=round(wedgeRadialWidths./checkSizes(:,1));
if (any( abs(nRadialChecksPerSector-round(nRadialChecksPerSector))>TOL))
  disp(['WARNING: check radial dimension is not an integer multiple' ...
	' of wedge radial width. Stimulus may differ from' ...
	 ' specifications.'])
end

% initialize with random displacement -0.5..0.5 between sectors in fractions
% of radial check size
sectorRadialShift=cell(nWedges,1);
for nW=1:nWedges
  sectorRadialShift{nW}=(rand(nSectorsPerWedge(nW),1)-0.5)*checkSizes(nW,1);
end

% precompute radius and theta for all wedges
wedgeMaxRadius=zeros(nWedges,1);
wedgeMinRadius=zeros(nWedges,1);
wedgeMaxAngle=zeros(nWedges,1);
wedgeMinAngle=zeros(nWedges,1);
checkRadialCoords=cell(nWedges,1);
checkColourIndexes=cell(nWedges,1);
checkPolarCoords=cell(nWedges,1);
wrapRange=wrapEccentricity(2)-wrapEccentricity(1);
for nW=1:nWedges
  % Radial coords of checks: 2 extra checks on each side to allow 1
  % full cycle radial displacement
  wedgeMinRadius(nW)=wedgeRadialCoords(nW)-0.5*wedgeRadialWidths(nW);
  wedgeMaxRadius(nW)=wedgeRadialCoords(nW)+0.5*wedgeRadialWidths(nW);
  % wrap too large coordinates to display centre
  if (wedgeMaxRadius(nW)>wrapEccentricity(2))
    wedgeMaxRadius(nW)=wedgeMaxRadius(nW)-wrapRange;
  end
  % wrap negative coordinates to display edge
  if (wedgeMinRadius(nW)<wrapEccentricity(1))
    wedgeMinRadius(nW)=wedgeMinRadius(nW)+wrapRange;
  end
  % Now assign coordinates: one more than number of checks; 4
  % checks extra = total 5 more coordinates
  if (wedgeMinRadius(nW)>wedgeMaxRadius(nW))
    % if min>max (wraparound) then radial coords will have two rows, one for each
    % part, each drawn the same way as single row checks
    % calculate number of checks per part. For simplicity, let's
    % just use the same number as single part, ugly but
    % easy. It'll be truncated anyway in the drawing.
    % First row is inner part (wrapEccentricity(1) origin)
    % Second row is outer part (wedgeMinRadius origin)
    checkRadialCoords{nW}=[...
	[-2:nRadialChecksPerSector(nW)+2]*checkSizes(nW,1)+wrapEccentricity(1);...
	[-2:nRadialChecksPerSector(nW)+2]*checkSizes(nW,1)+wedgeMinRadius(nW)];
  else    
    checkRadialCoords{nW}=[-2:nRadialChecksPerSector(nW)+2]*checkSizes(nW,1)+wedgeMinRadius(nW);
  end

  % ok, now assign colour indexes to checks
  checkColourIndexes{nW}=[1:size(checkRadialCoords{nW},2)]+(rand>0.5);
  checkColourIndexes{nW}=mod(checkColourIndexes{nW},2);
  if (size(checkRadialCoords{nW},1)==2)
    checkColourIndexes{nW}=[checkColourIndexes{nW};checkColourIndexes{nW}];
  end
  
  % Yikes. Now we need to do the same magic for the polar
  % stuff... But wraparound is automatic so no need to worry about
  % it. and no sliding in polar direction, so this is very straighforward.
  wedgeMinAngle(nW)=wedgePolarCoords(nW)-0.5*wedgePolarWidths(nW);
  wedgeMaxAngle(nW)=wedgePolarCoords(nW)+0.5*wedgePolarWidths(nW);
  checkPolarCoords{nW}=[0:nSectorsPerWedge(nW)]*checkSizes(nW,2)+wedgeMinAngle(nW);
  
end

t_elapsed=mglGetSecs-t_zero;

moveSign=(rand>0.5)*2-1;
for nCyc=1:nCycles  
  t_cycle=0;
  t_cyclezero=mglGetSecs;
  moveSignPerCycle=moveSign*((mod(nCyc,2)>0)*2-1);
  % while time is less than onTimePerCycle, draw
  while (t_cycle<onTimePerCycle) 
    % clear screen: prepare to draw
    mglClearScreen(backgroundColour);
    if (~isempty(fixationParams))
      mglFixationCross(fixationParams);
    end
    % compute and draw each wedge
    for nW=1:nWedges
      % add radial shift
      %      sectorRadialShift{nW}=sectorRadialShift{nW}+ ...
      %	  (rand(nSectorsPerWedge(nW),1))*checkSizes(nW,1)* ...
      %	  slidingSpeed; 
      moveSignPerSector=repmat([-1;1],ceil(nSectorsPerWedge(nW)/2),1);
      moveSignPerSector=moveSignPerSector(1:nSectorsPerWedge(nW));
      moveSignPerSector=moveSignPerSector*moveSignPerCycle;
      sectorRadialShift{nW}=sectorRadialShift{nW}+ ...
	  checkSizes(nW,1)*slidingSpeed.*moveSignPerSector.*(rand(nSectorsPerWedge(nW),1));
      % wrap shifts larger than two checks
      wrapSize=2*checkSizes(nW,1);
       sectorRadialShift{nW}(sectorRadialShift{nW}>wrapSize)=...
 	sectorRadialShift{nW}(sectorRadialShift{nW}>wrapSize)-wrapSize;
       sectorRadialShift{nW}(sectorRadialShift{nW}<-wrapSize)=...
 	sectorRadialShift{nW}(sectorRadialShift{nW}<-wrapSize)+wrapSize;
       
      nParts=size(checkRadialCoords{nW},1);
      nSectors=nSectorsPerWedge(nW);
      for nP=1:nParts
	radius=checkRadialCoords{nW}(nP,:);
	% determine min,max radius for current part
	if (nParts==1)
	  minrad=max([minEccentricity wedgeMinRadius(nW)]);
	  maxrad=min([maxEccentricity wedgeMaxRadius(nW)]);
	elseif (nP==1) % inner part
	  minrad=minEccentricity;
	  maxrad=wedgeMaxRadius(nW);
	else % outer part
	  minrad=wedgeMinRadius(nW);	  
	  maxrad=maxEccentricity;
	end
	for nS=1:nSectors
 	  % add sector shift to radius
 	  sector_radius=radius+sectorRadialShift{nW}(nS);
	  sector_colinds=checkColourIndexes{nW}(nP,:);
 	  % replace coordinates smaller than minimum radius by minimum
 	  aboveMin=find(sector_radius>=minrad);
 	  if (length(aboveMin)<length(sector_radius))
 	    sector_radius=[minrad sector_radius(aboveMin)];
	    sector_colinds=sector_colinds(aboveMin);
	    % assign minrad opposite colour index of adjacent check
	    sector_colinds=[1-sector_colinds(1) sector_colinds]; 
 	  end
	  if (sector_radius(1)>minrad)
	    sector_radius=[minrad sector_radius];
	    sector_colinds=[1-sector_colinds(1) sector_colinds]; 
	  end
 	  % replace coordinates larger than maximum radius by maximum
 	  belowMax=find(sector_radius<=maxrad);
 	  if (length(belowMax)<length(sector_radius))
 	    sector_radius=[sector_radius(belowMax) maxrad];
	    sector_colinds=sector_colinds(belowMax);
	    % assign maxrad opposite colour index of adjacent check
	    sector_colinds=[sector_colinds 1-sector_colinds(end)]; 
 	  end
	  if (sector_radius(end)<maxrad)
	    sector_radius=[sector_radius maxrad];
	    sector_colinds=[sector_colinds 1-sector_colinds(end)]; 
	  end
	  
	  ccwTheta=ones(size(sector_radius))*checkPolarCoords{nW}(nS);
	  cwTheta=ones(size(sector_radius))*checkPolarCoords{nW}(nS+1);

	  % calculate cartesian coordinates
	  [ccwX,ccwY]=pol2cart(ccwTheta,sector_radius);
	  [cwX,cwY]=pol2cart(cwTheta,sector_radius);
	  
	  nChecks=length(sector_radius)-1;
	  
	  currcol=zeros(3,nChecks);
	  currX=zeros(4,nChecks);
	  currY=zeros(4,nChecks);
 	  for nC=1:nChecks
 	    if (sector_colinds(nC)<1)
 	      colidx=1:3;
 	    else
 	      colidx=4:6;
 	    end
 	    if (size(wedgeColours,1)==1)
 	      currcol(:,nC)=wedgeColours(colidx)';
 	    else
 	      currcol(:,nC)=wedgeColours(floor(rand*size(wedgeColours,1))+1,colidx);
 	    end
	    currX(:,nC)=[ccwX(nC);ccwX(nC+1); cwX(nC+1); cwX(nC) ];
	    currY(:,nC)=[ccwY(nC);ccwY(nC+1); cwY(nC+1); cwY(nC) ];
	  end	    
	  mglQuad(currX,currY,currcol,0);
	end
      end
    end
    
    % flush mgl buffer
    mglFlush;
    
    % measure elapsed time
    t_cycle=mglGetSecs-t_cyclezero;
    % add: subtract
    % repeat
  end
  % if DC<1, clear screen and wait
  if (dutyCycle<1)
    mglClearScreen(backgroundColour);
    if (~isempty(fixationParams))
      mglFixationCross(fixationParams);
    end
    mglFlush;
    while (t_cycle<timePerCycle) 
      t_cycle=mglGetSecs-t_cyclezero;      
    end
  end  
end  
t_elapsed=mglGetSecs-t_zero;

