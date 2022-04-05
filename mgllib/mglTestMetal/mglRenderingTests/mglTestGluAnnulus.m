% mglTestGluAnnulus: an automated and/or interactive test for rendering.
%
%      usage: mglTestGluAnnulus(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering various sizes and shapes of vectorized arcs.
%      usage:
%             % You can run it by hand with no args.
%             mglTestGluAnnulus();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestGluAnnulus(false);
%
function mglTestGluAnnulus(isInteractive)

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
isize = linspace(0, 50, nRings);
osize = linspace(50, 100, nRings);
color = [1.0, 0.5, 0.25, 1.0];
mglGluAnnulus(x, y, isize, osize, color);
disp('There shoud be 5 rings across the diagonal.')

mglFlush();

if (isInteractive)
    mglPause();
end
