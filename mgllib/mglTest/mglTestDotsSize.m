% mglTestDotsSize.m
%
%      usage: mglTestDotsSize
%         by: justin gardner
%       date: 08/23/2023
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: To test the dots in metal - same as arcs, for issue with radius size
%
%             The top and bottom half of the display should align, and everything
%             should be aligned to white tick marks.
%
%             The top half of the display shows dots that should be increasing in 
%             size by one tick mark (note that they are made into ovals, where the
%             y dimension is 1 tick mark longer than the x dimension - to make sure
%             that mglMetalDots - which allows for ovals is working in both dimensions).
%
%             The bottom half is made with mglMetalArcs (which only allow circles)
%
%
function retval = mglTestArcs

% set the tick spacing, everything should be aligned accordingly
tickSpacing = 1;
numRings = 10;
screenWidth = tickSpacing * numRings*2;
screenHeight = tickSpacing * (numRings+1)*2;

% open screen
mglClose;
mglOpen(0,800,800);
mglVisualAngleCoordinates(57,[screenWidth screenHeight]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% draw dots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set center
xyz = repmat(0,3,numRings);

% set color, make every other ring purple
for iRing = 1:numRings
  % check if even
  if floor(iRing/2)*2 == iRing;
    % then set to purple
    rgba(:,iRing) = [0.54 0.17 1 1];
  else
    % set to gray
    rgba(:,iRing) = [0.5 0.5 0.5 1]';
  end

  % set size, in descending order, so that the dots 
  % will not overlap each other
  wh(:,iRing) = tickSpacing * 2*[numRings-iRing+1 numRings-iRing+2]';
end

% set shape
shape = repmat(1,1,numRings);

% set border
border = repmat(0,1,numRings);

% draw dots
mglMetalDots(xyz,rgba,wh,shape,border);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% draw arcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now draw arcs in the bottom half
for iRing = 1:numRings
  % check if even
  if floor(iRing/2)*2 == iRing;
    % then set to gray
    rgba(:,iRing) = [0.5 0.5 0.5 1]';
  else
    % set to purple
    rgba(:,iRing) = [0.54 0.17 1 1];
  end

  % set radii
  % will not overlap each other
  radii(:,iRing) = tickSpacing * [numRings-iRing numRings-iRing+1]';
  
  % set wedge
  wedge(:,iRing) = [pi pi]';
end

% draw arcs
mglMetalArcs(xyz,rgba,radii,wedge,border);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% draw points for reference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
r = [0:tickSpacing:tickSpacing*numRings]';
z = zeros(1,length(r))';
mglPoints2([-r; r;z;r/sqrt(2);-r/sqrt(2);z;r/sqrt(2);-r/sqrt(2)],[z;z;r;r/sqrt(2);r/sqrt(2);-r;-r/sqrt(2);-r/sqrt(2)],0.1);

% and display
mglFlush