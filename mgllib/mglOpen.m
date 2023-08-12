% mglOpen: Open an mgl window
%
%        $Id$
%      usage: mglOpen(whichScreen, screenWidth,screenHeight,frameRate,bitDepth)
%         by: justin gardner
%       date: 04/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Opens an a drawing window.
%      usage:
%             The first parameter, whichScreen, determines which display to
%             open on:
%              - mglOpen() - open up the last currently connected display fullscreen
%              - mglOpen(1) - open up the primary display fullscreen
%              - mglOpen(2) - open up the 2nd screen on a two display fullscreen
%              - mglOpen(0) - open up in a window
%
%             % Use last connected monitor.
%             mglOpen
%
%             % Open with resolution 800x600 60Hz 32bit fullscreen.
%             % (size, frameRate, and bitDepth for fullscreen not currently configurable in MGL v3 with Metal)
%             mglOpen(1,800,600,60,32);
%
%             Open in a window 800 x 600.
%             mglOpen(0, 800, 600);
%
function mglOpen(whichScreen,screenWidth,screenHeight,frameRate,bitDepth)

% check arguments
if ~any(nargin == [0 1 2 3 4 5])
  help mglOpen
  return
end

% check os
if ~mglCheckOS
  disp(sprintf('(mglOpen) mgl metal is not supported on your system. You might try using the OpenGL v2 mgl'));
  disp(sprintf('(mglOpen) If you want to force this to run type dbcont, but at your own risk! (dbquit to abort)'));
  keyboard
  mglSetParam('forceCheckOS',true);
end

% default arguments
if ~exist('whichScreen','var'), whichScreen = []; end
if ~exist('screenWidth','var'), screenWidth = []; end
if ~exist('screenHeight','var'), screenHeight = []; end
if ~exist('frameRate','var'), frameRate = []; end
if ~exist('bitDepth','var'), bitDepth = []; end

% don't need to set screen resolution with one or fewer arguments
if nargin <= 1, setResolution = 0; else setResolution = 1; end

% set whether the desktop is running
if usejava('desktop')
  mglSetParam('matlabDesktop',1);
end

% set verbose off
if isempty(mglGetParam('verbose'))
  mglSetParam('verbose',0);
end

% Give a name to this mgl state and config, the mgl "context".
% The name can be changed later with mglContextStash, if needed.
stashedNames = mglContextList();
newName = sprintf('default_%d', numel(stashedNames));
mglSetParam('contextName', newName);

openDisplay = 0;
% check to see if a display is already open
if mglGetParam('displayNumber') ~= -1
  openDisplay = 1;
end

% check if whichScreen < 0, then we set it so that it either
% opens a secondary display, or if none is available opens
% up a windowed context
displayResolution = mglResolution;
if ~isempty(whichScreen) && (whichScreen < 0)
  if displayResolution.numDisplays > 1
    whichScreen = displayResolution.displayNumber;
  else
    whichScreen = -whichScreen;
  end
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

% see if we are running for movie mode
if mglGetParam('movieMode')
  disp('(mglOpen) movieMode not implemented in mgl 3.0');
  keyboard
  % in this case, always use a windowed context
  % full screen mode is spoofed by making a windowed context that
  % is the same size as the screen and closing the task and menu
  % bar
  %%mglSetParam('transparentBackground',1);
  %%if isempty(whichScreen)
  %%  res = mglResolution;
  %%  mglSetParam('spoofFullScreen',res.displayNumber);
  %%else
  %%  mglSetParam('spoofFullScreen',whichScreen);
  %%end

  %%% close an open window if it is not a windowed context
  %%if openDisplay && ~isequal(mglGetParam('displayNumber'),0)
  %%  disp(sprintf('(mglOpen) Closing currently open mgl window which is not compatible with movie mode'));
  %%  mglClose;
  %%  openDisplay = 0;
  %%end
  %%whichScreen = 0;
end

%mglSetParam('verbose',1);
if ~openDisplay
  % clear the originalResolution
  mglSetParam('originalResolution',[]);
  % call the private mex function
  if setResolution == 0
    % if whichScreen has not been set then get the default
    % display from mglResolution
    displayResolution = mglResolution;
    % get frameRate and bitDepth
    frameRate = displayResolution.frameRate;
    bitDepth = displayResolution.bitDepth;
    % set whichScreen
    if isempty(whichScreen)
      if displayResolution.numDisplays == 1
         whichScreen = 0;
      else
        whichScreen = displayResolution.displayNumber;
      end
    end
    % check to make sure that the whichScreen is within bounds
    if (whichScreen < 0) || (whichScreen > displayResolution.numDisplays)
      disp(sprintf('(mglOpen) Display number %i is out of range [0:%i]',whichScreen,displayResolution.numDisplays));
      return
    end
    % if passed in with zero or one argument then use default settings
    mglMetalOpen(whichScreen);
  else % open, trying to set resolution
    % for full screen resolution
    if isempty(whichScreen) || (whichScreen>=1)
      % check to make sure that the whichScreen is within bounds
      if (whichScreen > displayResolution.numDisplays)
	      disp(sprintf('(mglOpen) Display number %i is out of range [0:%i]',whichScreen,displayResolution.numDisplays));
	      return
      end
      % get the current resolution, so we can return to it on close
      mglSetParam('originalResolution',mglResolution(whichScreen));
      % set the display resolution
      displayResolution = mglResolution(whichScreen,screenWidth,screenHeight,frameRate,bitDepth);
      if isempty(displayResolution),return,end
      whichScreen = displayResolution.displayNumber;
      frameRate = displayResolution.frameRate;
      bitDepth = displayResolution.bitDepth;
      % check to make sure that the whichScreen is within bounds
      if (whichScreen < 0) || (whichScreen > displayResolution.numDisplays)
	      disp(sprintf('(mglOpen) Display number %i is out of range [0:%i]',whichScreen,displayResolution.numDisplays));
	      return
      end
      % and call mglMetalOpen with the correct screen number
      mglMetalOpen(whichScreen);
    elseif ~isempty(mglGetParam('spoofFullScreen')) && (mglGetParam('spoofFullScreen') > 0);
      % get the current resolution, so we can return to it on close
      mglSetParam('originalResolution',mglResolution(whichScreen));
      % set the display resolution
      displayResolution = mglResolution(whichScreen,screenWidth,screenHeight,frameRate,bitDepth);
      frameRate = displayResolution.frameRate;
      bitDepth = displayResolution.bitDepth;
      % and call mglMetalOpen with the correct screen number
      mglMetalOpen(0);
    elseif whichScreen >= 0
      % open for a windowed mgl (i.e. whichScreen between 0 and 1
      mglMetalOpen(whichScreen, 100, 100, screenWidth, screenHeight);
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
if exist('mglInstallSound') == 2
  mglInstallSound('/System/Library/Sounds/');
end

% the displayID (used by mglSwitchDisplay defaults to the display number)
if isempty(mglGetParam('displayID'))
  mglSetParam('displayID',mglGetParam('displayNumber'));
end

if mglGetParam('matlabDesktop')
  % always show the cursor from the desktop.
  mglDisplayCursor(1);
end

% check if offscreenbuffer is set (this is used by the pRF code 
% to create stimulus images - in function: pRFGetStimImageFromStimfile.m )
if mglGetParam('offscreenContext')
  % then start up mglFrameGrab
  mglFrameGrab('init');
end

