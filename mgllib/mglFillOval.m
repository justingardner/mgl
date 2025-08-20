% mglFillOval - draw filled oval(s) on the screen
%
%        $Id$
%      usage: results = mglFillOval(x, y, size, color, antialiasing)
%         by: Benjamin Heasly
%       date: 03-17.2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     inputs: x,y - vectors of x and y coordinates of center
%             size - [width height] of oval (device units, not pixels)
%             color - [r g b] triplet for color
%             antialiasing = size of border for antialiasing (default = 0)
%
%             See also mglMetalDots, with additional capability.
%
%    purpose: draw filled oval(s) centered at x,y with size [xsize
%    ysize] and color [rgb]. the function is vectorized, so if you
%    provide many x/y coordinates (identical) ovals will be plotted
%    at all those locations. 
%
%       e.g.: 
%mglOpen;
%mglVisualAngleCoordinates(57,[16 12]);
%x = [-1 -4 -3 0 3 4 1];
%y = [-1 -4 -3 0 3 4 1];
%sz = [.2 .4];
%mglFillOval(x, y, sz,  [1 0 0]);
%mglFlush();
% 
function results = mglFillOval(x, y, size, color, antialiasing)

nArcs = numel(x);
if ~isequal(numel(y), nArcs)
    fprintf('(mglFillOval) Number of y values must match number of x values (%d)', nArcs);
    help mglFillOval
    return;
end
xyz = zeros([3, nArcs], 'single');
xyz(1,:) = x;
xyz(2,:) = y;

% set radii - inner is always 0, outer is set to size values passsed in
% note input size refers to diameter
if nargin < 3
    size = [1, 1];
end
radii = zeros([4, nArcs], 'single');
radii(2,:) = size(1)/2;
radii(4,:) = size(2)/2;

% draw complete wedge from 0 to 2pi
wedge = repmat([0 2*pi]',1,nArcs);

% set color
if nargin < 4
    color = [1 1 1 1];
end
if numel(color) == 3
    color = [color, 1];
end
if numel(color) < 3
    color = [color(1), color(1), color(1), 1];
end
rgba = zeros(4, nArcs, 'single');
rgba(1,:) = color(1);
rgba(2,:) = color(2);
rgba(3,:) = color(3);
rgba(4,:) = color(4);

% set border
if nargin < 5
    antialiasing = 0;
end
border = zeros(1, nArcs, 'single');
border(:) = antialiasing;

results = mglMetalArcs(xyz, rgba, radii, wedge, border);
