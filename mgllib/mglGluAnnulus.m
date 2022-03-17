% mglGluAnnulus - draw annulus/annuli at location x,y
%
%        $Id$
%      usage: [ackTime, processedTime] = mglGluAnnulus(x, y, isize, osize, color, antialiasing)
%         by: Benjamin Heasly
%       date: 03-17-2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     inputs: x,y - position
%             isize - inner radius
%             osize - outer radius
%             color - rgb or rgba
%             antialiasing - width of edge to smooth with alpha
%
%             Note: old params nslices and nloops are no longer used.
%             See also mglMetalArcs with additional functionality.
%
%mglOpen(0);
%mglVisualAngleCoordinates(57,[16 12]);
%x = zeros(4, 1);
%y = zeros(4, 1);
%isize = linspace(1, 8, 4);
%osize = isize+linspace(0.1, 2, 4);
%colors = jet(4)';
%mglGluAnnulus(x, y, isize, osize, colors);
%mglFlush();
function [ackTime, processedTime] = mglGluAnnulus(x, y, isize, osize, color, antialiasing)

persistent mglGluAnnulusDeprecationWarning
if (nargin > 5) && isempty(mglGluAnnulusDeprecationWarning)
    mglGluAnnulusDeprecationWarning = true;
    fprintf("(mglGluAnnulus) nslices and nloops are longer supported, the last param is for antialiasing now.\n")
end

nDots = numel(x);
if ~isequal(numel(y), nDots)
    fprintf('(mglGluAnnulus) Number of y values must match number of x values (%d)', nDots);
    help mglGluAnnulus
    return;
end
xyz = zeros([3, nDots], 'single');
xyz(1,:) = x;
xyz(2,:) = y;

if nargin < 3
    isize = 0;
end
if nargin < 4
    osize = 10;
end
radii = zeros([2, nDots], 'single');
radii(1, :) = isize;
radii(2, :) = osize;

if nargin < 5
    color = [1 1 1 1];
end
if numel(color) == 3
    color = [color, 1];
end
if numel(color) < 3
    color = [color(1), color(1), color(1), 1];
end
rgba = zeros(4, nDots, 'single');
rgba(1,:) = color(1);
rgba(2,:) = color(2);
rgba(3,:) = color(3);
rgba(4,:) = color(4);

if nargin < 6
    antialiasing = 0;
end
border = zeros(1, nDots, 'single');
border(:) = antialiasing;

wedge = zeros(2, nDots, 'single');
wedge(2,:) = 2*pi;
[ackTime, processedTime] = mglMetalArcs(xyz, rgba, radii, wedge, border);
