% mglMoveWindow.m
%
%        $Id$
%      usage: mglMoveWindow(leftPos,topPos)
%         by: Christopher Broussard
%       date: 10/23/07
%    purpose: Moves the current AGL window with the left edge of the window
%	      at 'leftPos', the top edge at 'topPos'.
%
%mglOpen(0);
%mglMoveWindow(100,100);
function mglMoveWindow(leftPos, topPos)

if nargin ~= 2
  help mglMoveWindow
  return
end

if ~isscalar(leftPos) || ~isscalar(topPos)
  help mglMoveWindow
  return
end

% Get the current window position.
[displayNumber, rect] = mglMetalGetWindowFrameInDisplay();

% Modify the position of the rect.
rect(1) = leftPos;
rect(2) = topPos - rect(4);
mglMetalSetWindowFrameInDisplay(displayNumber, rect);
