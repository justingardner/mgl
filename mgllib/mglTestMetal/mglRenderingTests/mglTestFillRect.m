% mglTestFillRect: an automated and/or interactive test for rendering.
%
%      usage: mglTestFillRect(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering some points.
%      usage:
%             % You can run it by hand with no args.
%             mglTestFillRect();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestFillRect(false);
%
function mglTestFillRect(isInteractive)

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
mglFillRect(x, y, [4, 3], [1 .25 .25], 5);
disp('There should be 5 wide, red rectangles clustered roughly near the center.')

mglFillRect(x, y, [1, 2], [.25 .5 .75], 5);
disp('Each red rectangle should have a tall, blue-gray rectangle in the middle.')

mglFlush();

if (isInteractive)
    mglPause();
end
