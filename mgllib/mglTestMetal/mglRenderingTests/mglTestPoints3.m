% mglTestPoints3: an automated and/or interactive test for rendering.
%
%      usage: mglTestPoints3(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering some points.
%      usage:
%             % You can run it by hand with no args.
%             mglTestPoints3();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestPoints3(false);
%
function mglTestPoints3(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

mglVisualAngleCoordinates(50, [20, 20]);

x = linspace(-5, 5, 5);
y = linspace(-5, 5, 5);
z = linspace(0, 1, 5);
mglPoints3(x, y, z, 4, [1 .25 .25]);
disp('There should be 5 red squares along the x=y diagonal.')

x2 = x + 1;
y2 = y - 1;
z2 = [0.5 0.5 0.5 0.5 0.5];
mglPoints3(x2, y2, z2, 4, [.25 1 .25]);
disp('There should be 5 green squares slightly offset from the red squares.')
disp('Only the bottom two red squares should appear "on top" of the green ones.')

mglFlush();

if (isInteractive)
    mglPause();
end
