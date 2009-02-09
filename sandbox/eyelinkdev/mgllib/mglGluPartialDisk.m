% mglGluPartialDisk - draw partial disk(s) at location x,y
%
%        $Id$ 
%      usage: [  ] = mglGluPartialDisk( x, y, isize, osize, startAngles, sweepAngles, color, [nslices], [nloops] )
%         by: denis schluppeck
%       date: 2007-03-19
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     inputs: x, y, size, color
%         
%             isize - inner radius
%             osize - outer radius
%
%             startAngles - start angle of partial disk (deg)
%             sweepAngles - sweep angle of partial disk (deg)
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
%    purpose: obvious
%
%       e.g.:
%
%mglOpen(0);
%mglVisualAngleCoordinates(57,[16 12]);
%x = zeros(10, 1);
%y = zeros(10, 1);
%isize = ones(10,1);
%osize = 3*ones(10,1);
%startAngles = linspace(0,180, 10)
%sweepAngles = ones(1,10).*10;
%colors = jet(10)';
%mglGluPartialDisk(x, y, isize, osize, startAngles, sweepAngles, colors, 60, 2);
%mglFlush();





