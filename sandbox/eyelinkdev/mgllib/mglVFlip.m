% mglVFlip.m
%
%        $Id$
%      usage: mglVFlip
%         by: justin gardner
%       date: 09/06/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: flips coordinate frame vertically,
%   see also: mglHFlip
%       e.g.:
%
%mglOpen
%mglVisualAngleCoordinates(57,[16 12]);
%mglVFlip
%mglTextSet('Helvetica',32,[1 1 1],0,0,0,0,0,0,0);
%mglTextDraw('Vertically flipped',[0 0]);
%mglFlush;
function mglVFlip()

% check arguments
if ~any(nargin == [0])
  help mglVFlip
  return
end

if mglGetParam('displayNumber') == -1
  disp(sprintf('(mglVisualAngleCoordinates) No open display'));
  return
end

% flip the modelviews horizontal axis
mglTransform('GL_MODELVIEW','glScale',1,-1,1);
