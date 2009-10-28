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
%% Open display 1 and draw
%mglSwitchDisplay(1);
%mglSetParam('useCGL',1);  % for now, cocoa displays don't switch very well
%mglOpen(1);
%mglClearScreen(0.5);
%mglVisualAngleCoordinates(57,[16 12]);
%mglTextDraw('Screen 1',[0 0]);
%mglFlush;
%
%% Open display 2 and draw
%mglSwitchDisplay(2);
%mglSetParam('useCGL',1);
%mglOpen(2);
%mglClearScreen(1);
%mglVisualAngleCoordinates(57,[16 12]);
%mglTextDraw('Screen 2',[0 0]);
%mglFlush;
%mglWaitSecs(2);
%
%% Switch back to display 1 and draw something else
%mglSwitchDisplay(1);
%mglClearScreen(1);
%mglTextDraw('Screen 1 update',[0 0]);
%mglFlush;
%
%% Switch back to display 2 and draw something else
%mglSwitchDisplay(2);
%mglClearScreen(0.5);
%mglTextDraw('Screen 2 update',[0 0]);
%mglFlush;
%mglWaitSecs(2);
%
%% Close the displays
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
%if isfield(MGL,'context') && (MGL.context==0) && (MGL.displayNumber ~= -1) && (~isempty(displayID) || (displayID >= 0))
%  disp(sprintf('(mglSwitchDisplay) This is not a full screen CGL context and can not be switched. You must use mglClose before switching'));
%  return
%end

% Save the current context in the MGLALL structure
if isfield(MGL,'displayNumber')
  if isempty(MGLALL)
    MGLALL{1} = MGL;
  else
    % look to see if it is already in MGLALL
    currentIndex = findMGLALLData('displayID', 'equal', MGL.displayID);
    
    % If the current MGL is found, then store it.
    if ~isempty(currentIndex)
      MGLALL{currentIndex} = MGL;
    else
      MGLALL{end+1} = MGL;
    end
  end
end

% if the list has any displays that are closed, remove them
if ~isempty(MGLALL)
  openDisplays = findMGLALLData('displayNumber', 'nequal', -1);
  MGLALL = MGLALL(openDisplays);
end

% check for close all command
if displayID == -1
  mglListener('quit');
  mglDigIO('quit');
  % then close all the other contexts that are open
  for i = 1:length(MGLALL)
    MGL = MGLALL{i};
    mglPrivateSwitchDisplay;
    mglClose;
  end
  clear global MGLALL;
  return
end

% display all command
if displayID == -2
  if isempty(MGLALL)
    disp(sprintf('(mglSwitchDisplay) No open contexts'));
  else
    for i = 1:length(MGLALL)
      mgla = MGLALL{i};
      if isequal(mgla, MGL)
	disp(sprintf('*displayID=%i displayNumber=%i: %ix%i %iHz (%i bits)',mgla.displayID,mgla.displayNumber,mgla.screenWidth,mgla.screenHeight,mgla.frameRate,mgla.bitDepth));
      else
	disp(sprintf('displayID=%i displayNumber=%i: %ix%i %iHz (%i bits)',mgla.displayID,mgla.displayNumber,mgla.screenWidth,mgla.screenHeight,mgla.frameRate,mgla.bitDepth));
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
    retval = findMGLALLData('displayNumber', 'equal', displayNumber);
    if ~isempty(retval)
      m = MGLALL{retval};
      retval = m.displayID;
    end
  end
  return
end


% Attempt to load the requested display.  If it doesn't exist, then just
% set the current trackerID value.
if ~isempty(displayID)
  newIndex = findMGLALLData('displayID', 'equal', displayID);
else
  newIndex = [];
  displayID = [];
end

% could not find the display
if isempty(newIndex)
  clear global MGL
  global MGL;
  MGL.displayNumber = -1;
  MGL.displayID = displayID;
  % otherwise switch to the correct display
else
  MGL = MGLALL{newIndex};
  mglPrivateSwitchDisplay;
end


%%%%%%%%%%%%%%%%%%%%%%%%
%%   findMGLALLData   %%
%%%%%%%%%%%%%%%%%%%%%%%%
% Looks through the cell array of MGLALL to find matches of an arbitary
% value to a specified field.
function indices = findMGLALLData(fieldName, operator, value)
global MGLALL;

indices = [];
for i = 1:length(MGLALL)
  s = MGLALL{i};

  switch lower(operator)
   case 'equal'
    if s.(fieldName) == value
      indices(end+1) = i;
    end

   case 'nequal'
    if s.(fieldName) ~= value
      indices(end+1) = i;
    end
  end
end
