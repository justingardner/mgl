% mglTestMetalLines: an automated and/or interactive test for rendering.
%
%      usage: mglTestMetalLines(isInteractive)
%         by: Benjamin Heasly
%       date: 06/13/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering some lines as quads in Metal.
%      usage:
%             % You can run it by hand with no args.
%             mglTestMetalLines();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestMetalLines(false);
%
function mglTestMetalLines(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

mglVisualAngleCoordinates(50, [20, 20]);

% Draw several lines at once.
nLines = 5;
x0 = linspace(-10, 10, nLines);
y0 = -5 * ones([1, nLines]);
x1 = 0.5 * x0;
y1 = 5 * ones([1, nLines]);
lineWidth = linspace(0.1, 4, nLines);
color = jet(nLines)';
mglMetalLines(x0, y0, x1, y1, lineWidth, color);

disp('There should be 5 lines of different colors and widths.')

mglFlush();

if (isInteractive)
    mglPause();
end
