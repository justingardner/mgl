% mglSwitchDisplay.m
%
%        $Id$
%      usage: mglSwitchDisplay(displayID,<displayNumber>)
%         by: Christopher Broussard
%       date: 10/16/07
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: switch displays when using mgl to display to multiple displays
% 
%             if you just want information on all open displays do:
%             mglSwitchDisplay(-2);
% 
%             if you want to shut down all open displays do:
%             mglSwitchDisplay(-1);
%
%       e.g.:
%
%mglOpen(1);
%mglClearScreen(0.5);
%mglFlush;
%mglSwitchDisplay;
%mglOpen(2);
%mglClearScreen(1);
%mglFlush;
%mglWaitSecs(2);
%mglSwitchDisplay(1);
%mglClearScreen(1);
%mglFlush;
%mglSwitchDisplay(2);
%mglClearScreen(0.5);
%mglFlush;
%mglWaitSecs(2);
%mglClose;
%mglSwitchDisplay(1);
%mglClose;
function retval = mglSwitchDisplay(displayID,displayNumber)

% check arguments
if ~any(nargin == [0 1 2])
  help mglSwitchDisplay
  return
end

global MGL
global MGLALL;

% default value for displayID
if ~exist('displayID','var'),displayID = [];end

% Make sure that there is at least 1 window open has been opened.
% Otherwise the MGL global hasn't been initialized and things will screw
% up.
if isempty(MGL)
  if ~isempty(displayID)
    MGL.displayNumber = -1;
    MGL.displayID = displayID;
  end
  return
end

% check to make sure this is a switchable context
if isfield(MGL,'context') && (MGL.context==0) && (MGL.displayNumber ~= -1) && (~isempty(displayID) || (displayID >= 0))
  disp(sprintf('(mglSwitchDisplay) This is not a full screen CGL context and can not be switched. You must use mglClose before switching'));
  return
end

% Save the current context in the MGLALL structure
if isfield(MGL,'displayNumber')
  if isempty(MGLALL)
    MGLALL = MGL;
  else
    % look to see if it is already in MGLALL
    currentIndex = find([MGLALL.displayID] == MGL.displayID);
    % If the current MGL is found, then store it.
    if ~isempty(currentIndex)
      MGLALL(currentIndex) = MGL;
    else
      MGLALL(end+1) = MGL;
    end
  end
end

% if the list has any displays that are closed, remove them
if ~isempty(MGLALL)
  openDisplays = find([MGLALL.displayNumber]~=-1);
  MGLALL = MGLALL(openDisplays);
end

% check for close all command
if displayID == -1
  % then close all the other contexts that are open
  for i = 1:length(MGLALL)
    MGL = MGLALL(i);
    mglPrivateSwitchDisplay;
    mglClose;
  end
  MGLALL = [];
  return
end

% display all command
if displayID == -2
  if isempty(MGLALL)
    disp(sprintf('(mglSwitchDisplay) No open contexts'));
  else
    for i = 1:length(MGLALL)
      if isequal(MGLALL(i),MGL)
	disp(sprintf('*displayID=%i displayNumber=%i: %ix%i %iHz (%i bits)',MGLALL(i).displayID,MGLALL(i).displayNumber,MGLALL(i).screenWidth,MGLALL(i).screenHeight,MGLALL(i).frameRate,MGLALL(i).bitDepth));
      else
	disp(sprintf('displayID=%i displayNumber=%i: %ix%i %iHz (%i bits)',MGLALL(i).displayID,MGLALL(i).displayNumber,MGLALL(i).screenWidth,MGLALL(i).screenHeight,MGLALL(i).frameRate,MGLALL(i).bitDepth));
      end
    end
  end
  return
end

% check for already open display
if displayID == -3
  if isempty(MGLALL)
    retval = [];
  else
    if ~exist('displayNumber','var'),displayNumber = [];end
    retval = find([MGLALL.displayNumber]==displayNumber);
    if ~isempty(retval)
      retval = MGLALL(retval).displayID;
    end
  end
  return
end


% Attempt to load the requested display.  If it doesn't exist, then just
% set the current trackerID value.
if ~isempty(displayID)
  newIndex = find([MGLALL.displayID] == displayID);
else
  newIndex = [];
  displayID = [];
end

% could not find the display
if isempty(newIndex)
  MGL.displayNumber = -1;
  MGL.displayID = displayID;
% otherwise switch to the correct display
else
  MGL = MGLALL(newIndex);
  mglPrivateSwitchDisplay;
end
