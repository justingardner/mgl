% mglTestScreenCoordinates: an automated and/or interactive test for rendering.
%
%      usage: mglTestScreenCoordinates(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test setting the rendering units to be pixels.
%      usage:
%             % You can run it by hand with no args.
%             mglTestScreenCoordinates();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestScreenCoordinates(false);
%
function mglTestScreenCoordinates(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

% Set the coordinate transform so the units are 1:1 with window pixels.
mglScreenCoordinates();

disp('There should be a big red circle at the origin, top-left.')
mglPoints2(0, 0, 100, [0.75 0.25 0.25], true);

disp('There should be 10 smaller squares, spanning the window.')
width = mglGetParam('screenWidth');
height = mglGetParam('screenHeight');
x = linspace(0, width, 10);
y = linspace(0, height, 10);
mglPoints2(x, y, 40, [0.5 0.75 0.5]);

mglFlush();

if (isInteractive)
    mglPause();
end
