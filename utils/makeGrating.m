% makeGrating.m
%
%      usage: makeGrating(width,height,sf,angle,phase,<xDeg2pix>,<yDeg2pix>)
%         by: justin gardner
%       date: 09/14/06
%    purpose: This function *name* is deprecated. Use mglMakeGrating (same functionality)
%             instead.
function m = makeGrating(width,height,sf,angle,phase,xDeg2pix,yDeg2pix)

% check arguments
m = [];
if ~any(nargin == [3 4 5 6 7])
  help mglMakeGrating
  return
end

if ieNotDefined('sf'),sf = [];end
if ieNotDefined('angle'),angle = [];end
if ieNotDefined('phase'),phase = [];end
if ieNotDefined('xDeg2pix'),xDeg2pix=[];end
if ieNotDefined('yDeg2pix'),yDeg2pix=[];end

% figure out how many makeGrating's are in the path
whichMakeGrating = which('makeGrating','-ALL');

% if only one in path
if length(whichMakeGrating) == 1
  disp(sprintf('(makeGrating) Warning the name of this function has changed to mglMakeGrating. Please change your code appropriately. In a future release of mgl you will *have* to use the function name mglMakeGrating rather than makeGrating'));
  % then just run the new one with a warning
  m = mglMakeGrating(width,height,sf,angle,phase,xDeg2pix,yDeg2pix);
else
  whichMakeGratingString = whichMakeGrating{1};
  for i = 2:length(whichMakeGrating)
    whichMakeGratingString = sprintf('%s, %s',whichMakeGratingString,whichMakeGrating{i});
  end
  disp(sprintf('(makeGrating) You have multiple copies of the function makeGrating in your path. The version in mgl will run now. If this is what you want then you should change your mgl code to call the function mglMakeGrating instead of calling makeGrating. In a future release of mgl you will *have* to use the function name mglMakeGrating rather than makeGrating. The versions in your path are: %s',whichMakeGratingString));
  m = mglMakeGrating(width,height,sf,angle,phase,xDeg2pix,yDeg2pix);
end

