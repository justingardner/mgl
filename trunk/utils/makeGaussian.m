% makeGaussian.m
%
%      usage: makeGaussian
%         by: justin gardner
%       date: 09/14/06
%    purpose: This function *name* is deprecated. Use mglMakeGaussian (same functionality)
%             instead.
function m = makeGaussian(width,height,sdx,sdy,xCenter,yCenter,xDeg2pix,yDeg2pix)

% check arguments
m = [];
if ~any(nargin == [4 5 6 7 8])
  help mglMakeGaussian
  return
end

if ieNotDefined('xCenter'),xCenter=[];end
if ieNotDefined('yCenter'),yCenter=[];end
if ieNotDefined('xDeg2pix'),xDeg2pix=[];end
if ieNotDefined('yDeg2pix'),yDeg2pix=[];end

% figure out how many makeGaussian's are in the path
whichMakeGaussian = which('makeGaussian','-ALL');

% if only one in path
if length(whichMakeGaussian) == 1
  disp(sprintf('(makeGaussian) Warning the name of this function has changed to mglMakeGaussian. Please change your code appropriately. In a future release of mgl you will *have* to use the function name mglMakeGaussian rather than makeGaussian'));
  % then just run the new one with a warning
  m = mglMakeGaussian(width,height,sdx,sdy,xCenter,yCenter,xDeg2pix,yDeg2pix);
else
  whichMakeGaussianString = whichMakeGaussian{1};
  for i = 2:length(whichMakeGaussian)
    whichMakeGaussianString = sprintf('%s, %s',whichMakeGaussianString,whichMakeGaussian{i});
  end
  disp(sprintf('(makeGaussian) You have multiple copies of the function makeGaussian in your path. The version in mgl will run now. If this is what you want then you should change your mgl code to call the function mglMakeGaussian instead of calling makeGaussian. In a future release of mgl you will *have* to use the function name mglMakeGaussian rather than makeGaussian. The versions in your path are: %s',whichMakeGaussianString));
  m = mglMakeGaussian(width,height,sdx,sdy,xCenter,yCenter,xDeg2pix,yDeg2pix);
end

