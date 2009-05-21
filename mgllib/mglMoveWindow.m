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

% check arguments
if ~any(nargin == [2])
  help mglMoveWindow
  return
end

global MGL;

if nargin ~= 2
  help mglMoveWindow
  return
end

% Verify that the current display is an AGL window.
if MGL.displayNumber ~= 0
  disp('(mglMoveWindow) Current window is not an AGL window');
  return
end

mglPrivateMoveWindow(leftPos, topPos);
