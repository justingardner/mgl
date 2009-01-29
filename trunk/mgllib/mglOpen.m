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

% set whether the desktop is running
if usejava('desktop')
  mglSetParam('matlabDesktop',1);
  mglSetParam('useCGL',1);
else
  if isempty(mglGetParam('useCGL'))
    mglSetParam('useCGL',1);
  end
end

% set verbose off
if isempty(mglGetParam('verbose'))
  mglSetParam('verbose',0);
end

openDisplay = 0;
% check to see if a display is already open
if mglGetParam('displayNumber') ~= -1
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

mglSetParam('verbose',1);
if ~openDisplay
  % default to showing that cocoa is not running
  % mglPrivateOpen will later reset this if a 
  % cocoa window has been opened
  mglSetParam('isCocoaWindow',0);
  % clear the originalResolution
  mglSetParam('originalResolution',[]);
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
      mglSetParam('originalResolution',mglResolution(whichScreen));
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

  % remember the frameRate and bitDepth in the global
  mglSetParam('frameRate',frameRate);
  mglSetParam('bitDepth',bitDepth);

  % clear screen to black
  mglClearScreen(0);
  mglFlush;
end
mglSetParam('verbose',0);

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
  mglSetParam('initialGammaTable',mglGetGammaTable);
end

% set some other added global
mglSetParam('screenCoordinates',0);
mglSetParam('deviceHDirection',1);
mglSetParam('deviceVDirection',1);

% clear the number of textures we have
mglSetParam('numTextures',0);

% install sounds
if exist('mglInstallSound') == 3 
  sounddir = '/System/Library/Sounds/';
  sounds = dir(fullfile(sounddir,'*.aiff'));
  for i = 1:length(sounds)
    soundNum = mglInstallSound(fullfile(sounddir,sounds(i).name));
    if ~isempty(soundNum)
      soundNames = mglGetParam('soundNames');
      [soundPath soundNames{soundNum}] = fileparts(sounds(i).name);
      mglSetParam('soundNames',soundNames);
    end
  end
end

% the displayID (used by mglSwitchDisplay defaults to the display number)
if isempty(mglGetParam('displayID'))
  mglSetParam('displayID',mglGetParam('displayNumber'));
end

if mglGetParam('matlabDesktop')
  % always show the cursor from the desktop.
  mglDisplayCursor(1);
end
