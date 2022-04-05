% mglTestPolygon: an automated and/or interactive test for rendering.
%
%      usage: mglTestPolygon(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering a convex polygon.
%      usage:
%             % You can run it by hand with no args.
%             mglTestPolygon();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestPolygon(false);
%
function mglTestPolygon(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

mglVisualAngleCoordinates(50, [20, 20]);

% Polygons need to be convex.
% Vertices need to be "wound" sequentially around the perimeter.
x = [-5 -6 -3  4 5];
y = [ 5  1 -4 -2 3];
mglPolygon(x, y, [0.25 0.5 0]);
disp('There should be a green or green-blue, irregular pentagon near the center.')

mglFlush();

if (isInteractive)
    mglPause();
end
