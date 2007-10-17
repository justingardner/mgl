% mglSwitchDisplay.m
%
%      usage: mglSwitchDisplay()
%         by: Christopher Broussard
%       date: 10/16/07
%    purpose: 
%
function retval = mglSwitchDisplay(displayID)

% check arguments
if ~any(nargin == [0 1])
  help mglSwitchDisplay
  return
end

global MGL
persistent MGLALL;

% Make sure that there is at least 1 window open has been opened.
% Otherwise the MGL global hasn't been initialized and things will screw
% up.
if isempty(MGL)
  disp('(mglSwitchDisplay) No displays open');
  return
end

% Find the current MGL in the tracker list.
currentIndex = find(MGLALL.trackerID == MGL.trackerID);

% Store the current MGL structure if it's a open display.  Closed
% displays are ignored.
if MGL.displayNumber ~= -1
  % If the current MGL tracker is found, then store it.
  if ~isempty(currentIndex)
    MGLALL.MGL{currentIndex} = MGL;
  end
end

% Attempt to load the requested display.  If it doesn't exist, then just
% set the current trackerID value.
if exist('displayID','var')
  newIndex = find(MGLALL.trackerID == displayID);
else
  newIndex = [];
  displayID = [];
end

if isempty(newIndex)
  MGL.displayNumber = -1;
  MGL.trackerID = displayID;
  MGL.context = 0;
else
  MGL = MGLALL.MGL{newIndex};
  mglPrivateSwitchDisplay;
end
