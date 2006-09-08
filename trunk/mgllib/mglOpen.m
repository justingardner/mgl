% mglOpen: Open an mgl window
%
%      usage: mglOpen(whichScreen, screenWidth,screenHeight,frameRate,bitDepth)
%         by: justin gardner
%       date: 04/10/06
%    purpose: Opens an openGL window
%      usage: open last monitor in list wwith current window settings
%             mglOpen
% 
%             Open with resolution 800x600 60Hz 32bit fullscreen
%             mglOpen(1,800,600,60,32);
%
%             Open in a window
%             mglOpen(0);
%
function mglOpen(whichScreen,screenWidth,screenHeight,frameRate,bitDepth)

% check arguments
if ~any(nargin == [0 1 2 3 4 5])
  help mglOpen
  return
end

% default arguments
if ~exist('whichScreen','var'), whichScreen = []; end
if ~exist('screenWidth','var'), screenWidth = 800; end
if ~exist('screenHeight','var'), screenHeight = 600; end
if ~exist('frameRate','var'), frameRate = 60; end
if ~exist('bitDepth','var'), bitDepth = 32; end

% call the private mex function
if nargin <= 1
  % if passed in with zero or one argument then use default settings
  mglPrivateOpen(whichScreen);
else
  % otherwise send all of the arguments
  mglPrivateOpen(whichScreen,screenWidth,screenHeight,frameRate,bitDepth);
end

% get the MGL global
global MGL;

% and remember the initial gamma table setting
MGL.initialGammaTable = mglGetGammaTable;

% set some other added global
MGL.deviceHDirection = 1;
MGL.deviceVDirection = 1;