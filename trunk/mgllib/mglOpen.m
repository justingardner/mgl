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
if ~exist('screenWidth','var'), screenWidth = []; end
if ~exist('screenHeight','var'), screenHeight = []; end
if ~exist('frameRate','var'), frameRate = []; end
if ~exist('bitDepth','var'), bitDepth = []; end

% get the MGL global
global MGL;

if usejava('desktop') & (whichScreen == 0)
  if ~isfield(MGL,'desktopWarning')
    warningStr = '(mglOpen) Using a windowed openGl context with the matlab desktop can be unstable due to some interactions with multiple threads. If you encounter crashing consider either using a full window context, (ie not mglOpen(0)) or run matlab using -nojvm or -nodesktop. Note that to improve stability mglClose will hide the window rather than destroy it.';
    uiwait(warndlg(warningStr,'mglOpen','modal'));
    % next time this is run it will allow the user to open the window
    MGL.desktopWarning = 1;
  end
end

if ~isfield(MGL,'verbose')
  MGL.verbose = 0;
end

openDisplay = 0;
% check to see if a display is already open
if isfield(MGL,'displayNumber') && ~isempty(MGL.displayNumber) && (MGL.displayNumber ~= -1)
  openDisplay = 1;
end

% check mglSwitchDisplay to make sure it is not already open
if ~openDisplay && ~isempty(whichScreen) && (whichScreen >= 1)
  switchNumber = mglSwitchDisplay(-3,floor(whichScreen));
  if ~isempty(switchNumber)
    disp(sprintf('(mglOpen) Display %i (displayID=%i) is already open, switching to that display',floor(whichScreen),switchNumber));
    mglSwitchDisplay(switchNumber);
    return
  end
end

if ~openDisplay
  % clear the originalResolution
  MGL.originalResolution = [];
  % call the private mex function
  if nargin <= 1 % 1 or less arguments then don't try to set screen resolution
    % if whichScreen has not been set then get the default
    % display from mglResolution
    displayResolution = mglResolution;
    % get frameRate and bitDepth
    frameRate = displayResolution.frameRate;
    bitDepth = displayResolution.bitDepth;
    % set whichScreen
    if isempty(whichScreen)
      whichScreen = displayResolution.displayNumber;
    end
    % check to make sure that the whichScreen is within bounds
    if (whichScreen < 0) || (whichScreen > displayResolution.numDisplays)
      disp(sprintf('(mglOpen) Display number %i is out of range [0:%i]',whichScreen,displayResolution.numDisplays));
      return
    end
    % if passed in with zero or one argument then use default settings
    mglPrivateOpen(whichScreen);
  else % open, trying to set resolution
    % for full screen resolution
    if isempty(whichScreen) || (whichScreen>=1)
      % get the current resolution, so we can return to it on close
      MGL.originalResolution = mglResolution;
      % set the display resolution
      displayResolution = mglResolution(whichScreen,screenWidth,screenHeight,frameRate,bitDepth);
      whichScreen = displayResolution.displayNumber;
      frameRate = displayResolution.frameRate;
      bitDepth = displayResolution.bitDepth;
      % check to make sure that the whichScreen is within bounds
      if (whichScreen < 0) || (whichScreen > displayResolution.numDisplays)
	disp(sprintf('(mglOpen) Display number %i is out of range [0:%i]',whichScreen,displayResolution.numDisplays));
	return
      end
      % and call mglPrivateOpen with the correct screen number
      mglPrivateOpen(whichScreen);
    elseif whichScreen >= 0
      % open for a windowed mgl (i.e. whichScreen between 0 and 1
      mglPrivateOpen(whichScreen,screenWidth,screenHeight);
      % get the frameRate and bitDepth
      displayResolution = mglResolution;
      frameRate = displayResolution.frameRate;
      bitDepth = displayResolution.bitDepth;
    else
      disp(sprintf('(mglOpen) Display number %i is out of range [0:%i]',whichScreen,displayResolution.numDisplays));
      return
    end
  end

  % remember the frameRate and bitDepth in the MGL global
  MGL.frameRate = frameRate;
  MGL.bitDepth = bitDepth;

  % clear screen to black
  mglClearScreen(0);
  mglFlush;
end

% round down to remove any decimal alpha request
whichScreen = floor(whichScreen);

% if this is an AGL screen then move it to 0,0
if whichScreen == 0
  if ~openDisplay
%    mglMoveWindow(10,30);
  end
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
    if ~isempty(soundNum)
      [soundPath MGL.soundNames{soundNum}] = fileparts(sounds(i).name);
    end
  end
end

% the displayID (used by mglSwitchDisplay defaults to the display number)
if ~isfield(MGL,'displayID') || isempty(MGL.displayID)
  MGL.displayID = MGL.displayNumber;
end

if usejava('desktop')
  % always show the cursor from the desktop.
  mglDisplayCursor(1);
end
