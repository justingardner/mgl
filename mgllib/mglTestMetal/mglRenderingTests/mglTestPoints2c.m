% mglTestPoints2c: an automated and/or interactive test for rendering.
%
%      usage: mglTestPoints2c(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering some points.
%      usage:
%             % You can run it by hand with no args.
%             mglTestPoints2c();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestPoints2c(false);
%
function mglTestPoints2c(isInteractive)

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
r = linspace(0, 1, 5);
g = circshift(r, 1);
b = circshift(r, 2);
a = [1 1 1 1 1];
mglPoints2c(x, y, 4, r, g, b, a);
disp('There should be 5 squares of different colors.')

mglFlush();

if (isInteractive)
    mglPause();
end
