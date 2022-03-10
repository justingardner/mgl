% mglTestLines: an automated and/or interactive test for rendering.
%
%      usage: mglTestLines(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering some lines.
%      usage:
%             % You can run it by hand with no args.
%             mglTestLines();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestLines(false);
%
function mglTestLines(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

x0 = [-0.1 0];
y0 = [0 -0.1];
x1 = [0.1 0];
y1 = [0 0.1];
size = 5;
color = [1.0 0.8 0.6];
mglLines2(x0, y0, x1, y1, size, color);

disp('There should be 2 orange-yellow lines crossed in the center.')

mglFlush();

if (isInteractive)
    pause();
end
