% mglTestPoints: an automated and/or interactive test for rendering.
%
%      usage: mglTestPoints(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering some points.
%      usage:
%             % You can run it by hand with no args.
%             mglTestPoints();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestPoints(false);
%
function mglTestPoints(isInteractive)

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
mglPoints2(x, y, 100, [1 .25 .25]);
disp('There should be 5 red squares clustered roughly near the center.')

disp('Each square should have a smaller blue-gray disk in the middle.')
mglPoints2(x, y, 50, [.25 .5 .75], true);

mglFlush();

if (isInteractive)
    mglPause();
end
