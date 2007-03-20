% mglGluDisk - draw disk(s) at location x,y; alternative to glPoints for circular dots
%
%        $Id$
%      usage: [  ] = mglGluDisk( x, y, size, color, [nslices], [nloops] )
%         by: denis schluppeck
%       date: 2006-05-12
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     inputs: x, y, size, color
%         
%             nslices - number of wedges used in polygon->circle
%             approximation [default 8]
%                   
%             nloops - number of annuli used in polygon->circle
%             approximation [default 1]
% 
%             increasing nslices and nloops slows down performance
%             and is only useful for larger ovals/dots
%
%    purpose: for plotting circular (rather than square dots), use
%    this function. on slower machines, large number of dots may
%    lead to dropped frames. there may be a way to speed this up a
%    bit in future. 
%
%       e.g.:
%
%mglOpen(0);
%mglVisualAngleCoordinates(57,[16 12]);
%x = 16*rand(100,1)-8;
%y = 12*rand(100,1)-6; 
%mglGluDisk(x, y, 0.1,  [0.1 0.6 1], 24, 2);
%mglFlush();





