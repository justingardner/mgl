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

if nargin ~= 2
  help mglMoveWindow
  return
end

% Verify that the current display is an AGL window.
if mglGetParam('displayNumber') ~= 0
  disp('(mglMoveWindow) Current openGL context is not windowed (i.e. must open with mglOpen(0))');
  return
end

% move the window
if isscalar(leftPos) && isscalar(topPos)
  mglPrivateMoveWindow(leftPos, topPos);
else
  disp(sprintf('(mglMoveWindow) leftPos and topPos must both be scalars'));
end
