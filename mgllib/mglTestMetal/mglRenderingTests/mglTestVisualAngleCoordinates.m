% mglTestVisualAngleCoordinates: an automated and/or interactive test for rendering.
%
%      usage: mglTestVisualAngleCoordinates(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test setting the rendering units to be degrees of visual angle.
%      usage:
%             % You can run it by hand with no args.
%             mglTestVisualAngleCoordinates();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestVisualAngleCoordinates(false);
%
function mglTestVisualAngleCoordinates(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

% Set the coordinate transform so the units are degrees of visual angle.
% This uses phoney display distance and size.
mglVisualAngleCoordinates(50, [20, 20]);

disp('There should be a big red circle at the origin, in the center.')
mglPoints2(0, 0, 100, [0.75 0.25 0.25], true);

disp('There should be 10 smaller squares, spanning the top-right quadrant.')
x = linspace(0, 10, 10);
y = linspace(0, 10, 10);
mglPoints2(x, y, 40, [0.5 0.75 0.5]);

mglFlush();

if (isInteractive)
    pause();
end
