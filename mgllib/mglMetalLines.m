% mglMetalLines.m
%
%       usage: mglMetalLines(x0, y0, x1, y1, lineWidth, color)
%          by: ben heasly
%        date: 06/13/2022 adapted from mglLines2, updated for Metal
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%     purpose: Function to plot lines on a screen opened with mglOpen.
%     inputs: x0 - 1 x n matrix of line starting x-positions
%             y0 - 1 x n matrix of line starting y-positions
%             x1 - 1 x n matrix of line ending x-positions
%             y1 - 1 x n matrix of line ending y-positions
%             lineWidth - 1 x n matrix of line widths (device units, not pixels)
%             color -- 3 x n matrix of RGB colors for the lines
%       e.g.:
%
% Draw one line:
% mglOpen;
% mglVisualAngleCoordinates(57,[16 12]);
% mglMetalLines(-4, -1, 1, 4, 2, [1 0.6 1]');
% mglFlush;
%
% Draw multiple lines:
% mglOpen;
% mglVisualAngleCoordinates(57,[16 12]);
% mglMetalLines(rand(1,10)*5-2.5, rand(1,10)*10-5, rand(1,10)*5-2.5, rand(1,10)*3-1.5, 0.5, [0 0.6 1]');
% mglFlush;
function results = mglMetalLines(x0, y0, x1, y1, lineWidth, color)

nLines = numel(x0);
if ~isequal(numel(y0), nLines) || ~isequal(numel(x1), nLines) || ~isequal(numel(y1), nLines)
    fprintf('(mglMetalLines) Number of values for y0, x1, and y1 must match number of values for x0 (%d)', nLines);
    help mglMetalLines
    return;
end

if nargin < 5
    lineWidth = 1;
end
if numel(lineWidth) == 1
    lineWidth = ones(1, nLines) * lineWidth;
end

if nargin < 6
    color = [1 1 1]';
end
if size(color, 2) == 1
    color = repmat(color(1:3), [1, nLines]);
end

% Widen each line by its lineWidth, perpendicular to its start-end heading.
deltaX = x1 - x0;
deltaY = y1 - y0;
angle = atan2(deltaY, deltaX);
offsetX = 0.5 * lineWidth .* -sin(angle);
offsetY = 0.5 * lineWidth .* cos(angle);

% Pack up and draw the widened lines as quads.
quadX = cat(1, x0 + offsetX, x1 + offsetX, x1 - offsetX, x0 - offsetX);
quadY = cat(1, y0 + offsetY, y1 + offsetY, y1 - offsetY, y0 - offsetY);
results = mglQuad(quadX, quadY, color);
