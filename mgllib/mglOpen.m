% mglOpen: Open an mgl window
%
%        $Id$
%      usage: mglOpen(whichScreen, screenWidth,screenHeight,frameRate,bitDepth)
%         by: justin gardner
%       date: 04/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
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

% get the MGL global
global MGL;

if isempty(javachk('desktop')) & (whichScreen == 0)
  if ~isfield(MGL,'desktopWarning')
    disp(sprintf('(mglOpen) Using a windowed openGl context with the matlab desktop'));
    disp(sprintf('          can be unstable due to some interactions with multiple'));
    disp(sprintf('          threads. If you encounter crashing consider either using'));
    disp(sprintf('          a full window context, (ie not mglOpen(0)) or run matlab'));
    disp(sprintf('          using -nojvm or -nodesktop. Note that to improve stability'));
    disp(sprintf('          mglClose will not close the window. If you are done using'));
    disp(sprintf('          mgl and want to force the window closed, use mglPrivateClose'));
    % next time this is run it will allow the user to open the window
    MGL.desktopWarning = 1;
  end
end

if ~isfield(MGL,'verbose')
  MGL.verbose = 0;
end

openDisplay = 0;
% check to see if a display is already open
if isfield(MGL,'displayNumber') && ~isempty(MGL.displayNumber)
  openDisplay = 1;
end

% call the private mex function
if nargin <= 1
  % if passed in with zero or one argument then use default settings
  mglPrivateOpen(whichScreen);
else
  % otherwise send all of the arguments
  mglPrivateOpen(whichScreen,screenWidth,screenHeight,frameRate,bitDepth);
end

% get gamma table
if ~openDisplay
  MGL.initialGammaTable = mglGetGammaTable;
end

% set some other added global
MGL.screenCoordinates = 0;
MGL.deviceHDirection = 1;
MGL.deviceVDirection = 1;

% clear the number of textures we have
MGL.numTextures = 0;

% install sounds
if exist('mglInstallSound') == 3 
  sounddir = '/System/Library/Sounds/';
  sounds = dir(fullfile(sounddir,'*.aiff'));
  for i = 1:length(sounds)
    soundNum = mglInstallSound(fullfile(sounddir,sounds(i).name));
    [soundPath MGL.soundNames{soundNum}] = fileparts(sounds(i).name);
  end
end
