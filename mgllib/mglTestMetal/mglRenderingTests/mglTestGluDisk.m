% mglTestGluDisk: an automated and/or interactive test for rendering.
%
%      usage: mglTestGluDisk(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering various sizes and shapes of disks.
%      usage:
%             % You can run it by hand with no args.
%             mglTestGluDisk();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestGluDisk(false);
%
function mglTestGluDisk(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

mglVisualAngleCoordinates(50, [20, 20]);

nDisks = 5;
x = linspace(-5, 5, nDisks);
y = linspace(5, -5, nDisks);
size = 0.5;
color = [0.25, 0.5, 0.75, 1.0];
mglGluDisk(x, y, size, color, 'ignored', 'ignored', 0);
disp('There shoud be 5 disks across the diagonal.')

mglFlush();

if (isInteractive)
    mglPause();
end
