% mglGluPartialDisk - draw partial disk(s) at location x,y
%
%        $Id$ 
%      usage: results = mglGluPartialDisk(x, y, isize, osize, startAngles, sweepAngles, color, [nslices], [nloops], antialiasing)
%         by: Benjamin Heasly
%       date: 2022-03-17
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     inputs: x,y - position
%             isize - inner radius (device units, not pixels)
%             osize - outer radius (device units, not pixels)
%             startAngles - start angle of partial disk (deg)
%             sweepAngles - sweep angle of partial disk (deg)
%             color - rgb or rgba
%             nSlices - ignored, included for compatibility
%             nLoops - ignored, included for compatibility
%             antialiasing - width of edge to smooth with alpha
%
%             Note: old params nslices and nloops are no longer used.
%             See also mglMetalArcs with additional functionality.
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
function results = mglGluPartialDisk(x, y, isize, osize, startAngles, sweepAngles, color, nSlices, nLoops, antialiasing)

% These are no longer needed in Metal, but included for v2 code compatibility.
nSlices = [];
nLoops = [];

persistent mglGlupartialDiskDeprecationWarning
if (nargin > 7) && isempty(mglGlupartialDiskDeprecationWarning)
    mglGlupartialDiskDeprecationWarning = true;
    fprintf("(mglGluPartialDisk) nslices and nloops are longer supported, consider using mglMetalArcs instead.\n")
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
    startAngles = 0;
end
if nargin < 6
    sweepAngles = 360;
end
wedge = zeros([2, nDots], 'single');
wedge(1,:) = startAngles / 180 * pi;
wedge(2,:) = sweepAngles / 180 * pi;

if nargin < 7
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

if nargin < 10
    antialiasing = 0;
end
border = zeros(1, nDots, 'single');
border(:) = antialiasing;

results = mglMetalArcs(xyz, rgba, radii, wedge, border);
