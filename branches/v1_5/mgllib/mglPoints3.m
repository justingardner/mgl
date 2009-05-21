% mglPoints3.m
%
%        $Id$
%      usage: mglPoints3()
%         by: justin gardner & Jonas Larsson
%       date: 04/03/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: plot 2D points on an OpenGL screen opened with mglOpen
%      usage: mglPoints2(x,y,z,size,color)
%             x,y,z = position of dots on screen
%             size = size of dots (in pixels)
%             color of dots
%       e.g.:
%
%mglOpen;
%mglVisualAngleCoordinates(57,[16 12]);
%mglPoints3(16*rand(500,1)-8,12*rand(500,1)-6,zeros(500,1),2,1);
%mglFlush
