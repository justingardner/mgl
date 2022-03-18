% mglTestFillRect3D: an automated and/or interactive test for rendering.
%
%      usage: mglTestFillRect3D(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering some points.
%      usage:
%             % You can run it by hand with no args.
%             mglTestFillRect3D();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestFillRect3D(false);
%
function mglTestFillRect3D(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

mglVisualAngleCoordinates(50, [20, 20]);

x = [-5 -6 -3  4 5];
y = [ 5  1 -4 -2 3];
z = [ 0  0  0  0 0];
mglFillRect3D(x, y, z, [2, 5], [1 .25 .25]);
disp('There should be 5 red rectangles clustered roughly near the center.')

mglFillRect3D(x, y, z, [1.5 2.5], [.25 .25 1], [30 0 0 1]);
disp('There should be a smaller, rotated blue rectangle on top of each red square.')

mglFlush();

if (isInteractive)
    pause();
end
