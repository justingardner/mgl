% mglGluAnnulus - draw annulus/annuli at location x,y
%
%        $Id$ 
%      usage: [  ] = mglGluAnnulus( x, y, isize, osize, color, [nslices], [nloops] )
%         by: denis schluppeck
%       date: 2007-03-19
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     inputs: x, y, size, color
%         
%             isize - inner radius
%             osize - outer radius
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
%mglOpen;
%mglVisualAngleCoordinates(57,[16 12]);
%x = zeros(10, 1);
%y = zeros(10, 1);
%isize = linspace(1, 8, 10);
%osize = isize+linspace(0.1, 2, 10);
%mglGluAnnulus(x, y, isize, osize,  [0.1 0.6 1], 60, 2);
%mglFlush();





