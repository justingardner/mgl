% mglHFlip.m
%
%        $Id$
%      usage: mglHFlip()
%         by: justin gardner
%       date: 09/06/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: flips coordinate frame horizontally, useful for when
%             the display is viewed through a mirror
%       e.g.:
%
%mglOpen
%mglVisualAngleCoordinates(57,[16 12]);
%mglHFlip
%mglTextSet('Helvetica',32,1,0,0,0,0,0,0,0);
%mglTextDraw('Mirror reversed',[0 0]);
%mglFlush;
function mglHFlip()

% check arguments
if ~any(nargin == [0])
  help mglHFlip
  return
end

if mglGetParam('displayNumber') == -1
  disp(sprintf('(mglHFlip) No open display'));
  return
end

% flip the modelviews horizontal axis
mglTransform('GL_MODELVIEW','glScale',-1,1,1);
