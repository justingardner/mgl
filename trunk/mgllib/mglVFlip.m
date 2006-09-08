% mglVFlip.m
%
%      usage: mglVFlip
%         by: justin gardner
%       date: 09/06/06
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

global MGL;

% flip the modelviews horizontal axis
mglTransform('GL_MODELVIEW','glScale',1,-1,1);
