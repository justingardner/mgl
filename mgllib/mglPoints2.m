% mglPoints2.m
%
%        $Id$
%      usage: mglPoints2()
%         by: justin gardner & Jonas Larsson
%       date: 04/03/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: plot 2D points on an OpenGL screen opened with mglOpen
%      usage: mglPoints2(x,y,size,color)
%             x,y = position of dots on screen
%             size = size of dots (in pixels)
%             color of dots
%       e.g.:
%
%mglOpen;
%mglVisualAngleCoordinates(57,[16 12]);
%mglPoints2(16*rand(500,1)-8,12*rand(500,1)-6,2,1);
%mglFlush
function mglPoints2(x,y,size,color)

global mgl;

% create vertices
v = [x(:) y(:)];
v(:,3) = 0;
v = v';

% write dots command
mglProfile('start');
mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.dots));

% send number of vertices
nVertices = length(x);
mgl.s = mglSocketWrite(mgl.s,uint32(nVertices));

% send vertices
mgl.s = mglSocketWrite(mgl.s,single(v(:)));

% end profiling
mglProfile('end','mglPoints2');
