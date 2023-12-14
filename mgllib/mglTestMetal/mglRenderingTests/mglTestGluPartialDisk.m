% mglTestGluPartialDisk: an automated and/or interactive test for rendering.
%
%      usage: mglTestGluPartialDisk(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering various sizes and shapes of vectorized arcs.
%      usage:
%             % You can run it by hand with no args.
%             mglTestGluPartialDisk();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestGluPartialDisk(false);
%
function mglTestGluPartialDisk(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

mglVisualAngleCoordinates(50, [20, 20]);

nRings = 5;
x = linspace(-5, 5, nRings);
y = linspace(5, -5, nRings);
isize = linspace(0, 1, nRings);
osize = linspace(1, 2, nRings);
startAngles = linspace(0, 270, nRings);
sweepAngles = linspace(45, 180, nRings);
color = [0.25, 0.5, 0.75, 1.0];
mglGluPartialDisk(x, y, isize, osize, startAngles, sweepAngles, color, 'ignored', 'ignored', 0);
disp('There shoud be 5 partial rings across the diagonal.')

mglFlush();

if (isInteractive)
    mglPause();
end
